//
//  DiagramCanvas.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui
import Diagramming
import PoieticCore
import PoieticFlows

/// View that draws a diagram and handles events to be dispatched to canvas tools.
///
/// Responsibilities:
/// - Owns overlays and Cairo drawing contexts
/// - Performs diagram scene rendering
///
/// The canvas draws a scene rooted in ``/Diagramming/DiagramCanvas``.
///
class DiagramCanvas: View {
    static let DefaultHitRadius: Double = 5.0

    var debugRendering: Bool = false
    
    weak var document: Document?
    internal var world: World {
        guard let document else { fatalError("DiagramCanvas used before binding")}
        return document.world
    }
    /// Diagram presented in this canvas view.
    ///
    /// Owned and managed by the ``Document``.
    ///
    /// - SeeAlso: ``scene`` – renderable representation of the diagram.
    var diagram: RuntimeEntity?

    /// Root entity for diagram canvas scene hierarchy presented in this canvas.
    ///
    /// Owned and managed by this diagram canvas view.
    ///
    /// When there is no canvas scene, it is created on the next ``update(_:)`` from
    /// the ``diagram``.
    ///
    /// - SeeAlso: ``diagram`` – source for the scene.
    var scene: RuntimeEntity?

    var style: CanvasStyle
    var showValueIndicators: Bool = true {
        didSet { self.indicatorOverlay.setNeedsRender() }
    }

    // TODO: Not fully implemented, only one overlay at the moment
    var overlays: OverlayStack
    /// Overlay for the main content – diagram blocks, connectors, labels.
    var mainOverlay: Overlay
    /// Interactive preview of connection, placement or other operations.
    var previewOverlay: Overlay
    var indicatorOverlay: Overlay
    var highlightOverlay: Overlay

    var isMouseInViewport: Bool = false
    var inputState: InputState = InputState()
    
    var canvasPos = ImVec2(0.0, 0.0)          // Screen position of canvas
    var canvasSize = ImVec2(0.0, 0.0)         // Screen size of canvas

    /// Canvas view offset in world coordinates.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``, ``zoomLevel``
    private(set) var viewOffset: Vector2D = .zero

    /// Canvas view scale.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``, ``viewOffset``
    ///
    private(set) var zoomLevel: Double = 1.0
    
    // TODO: Replace the viewOffset and zoomLevel variables with viewportState
    var viewportState: ViewportState { ViewportState(offset: viewOffset, zoom: zoomLevel)}
    
    /// Transformation from world coordinates to the drawing context/surface coordinates.
    ///
    /// The transform is derived from canvas view offset and zoom level.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``
    private(set) var toOverlayTransform: AffineTransform = .identity
    
    /// Grid spacing in world coordinates.
    var gridSize: Double = 50.0
    var showGrid = true

    var editorManager: InlineEditorManager? = nil

    init(document: Document? = nil) {
        self.document = document
        self.style = CanvasStyle.Default

        self.overlays = OverlayStack()
        
        self.mainOverlay = Overlay(name: "main", type: .main)
        self.overlays.add(self.mainOverlay)
        self.previewOverlay = Overlay(name: "preview", type: .preview)
        self.overlays.add(self.previewOverlay)
        self.indicatorOverlay = Overlay(name: "indicator", type: .indicator)
        self.overlays.add(self.indicatorOverlay)
        self.highlightOverlay = Overlay(name: "highlight", type: .highlight)
        self.overlays.add(self.highlightOverlay)

        self.editorManager = InlineEditorManager()
    }
    
    func bind(_ document: Document) {
        self.scene = nil
        self.diagram = nil
        self.document = document
        self.editorManager?.bind(document: document, canvas: self)
    }
    
    /// Convert screen coordinates to world coordinates
    func screenToWorld(_ screenPos: ImVec2) -> ImVec2 {
        let worldPos = Vector2D(screenPos - canvasPos) / Double(zoomLevel) + viewOffset
        return ImVec2(worldPos)
    }
    func screenToWorld(_ screenPos: ImVec2) -> Vector2D {
        let worldPos = Vector2D(screenPos - canvasPos) / Double(zoomLevel) + viewOffset
        return worldPos
    }

    /// Convert world coordinates to ImGui screen coordinates.
    ///
    /// - Note: For drawing use the ``toOverlayTransform``.
    ///
    func worldToScreen(_ worldPos: Vector2D) -> ImVec2 {
        let screenPos = (worldPos - viewOffset) * Double(zoomLevel)
        return ImVec2(screenPos) + canvasPos
    }
   
    /// Convert world coordinates to scene coordinates.
    func worldToScene(_ worldPos: Vector2D) -> Vector2D {
        return toOverlayTransform.apply(to: worldPos)
    }
    func sceneToWorld(_ scenePos: Vector2D) -> Vector2D {
        let worldPos = scenePos / zoomLevel + viewOffset
        return worldPos
    }
    
    var visibleWorldRect: Rect2D {
        Rect2D(origin: viewOffset, size: (Vector2D(canvasSize) / zoomLevel))
    }
    
    // MARK: - Update and Events
    
    func update(_ timeDelta: Double) {
        // TODO: Move to bind(), once we are sure we have diagram at that time.
        if scene == nil {
            createScene()
        }
    }

    func onSelectionChanged(_ document: Document) {
        highlightOverlay.setNeedsRender()
    }

    /// Update renderable scene and mark the whole canvas as needing to be rendered.
    ///
    func onDesignPlaneChanged(_ document: Document) {
        self.diagram = document.mainDiagram
        updateScene()
        self.scene?.setComponent(LayoutDirty())
    }
    
    func onSimulationPlayerStep(_ document: Document) {
        indicatorOverlay.setNeedsRender()
    }

    func onPreviewStarted(_ document: Document) {
        self.mainOverlay.setNeedsRender()
        self.previewOverlay.setNeedsRender()
    }

    func onInteractivePreviewChanged(_ document: Document) {
        mainOverlay.setNeedsRender()
        highlightOverlay.setNeedsRender()
        indicatorOverlay.setNeedsRender()
    }
    
    func onPreviewEnded(_ document: Document) {
//        self.overlays.setAllNeedsRender()
        self.mainOverlay.setNeedsRender()
        self.highlightOverlay   .setNeedsRender()
        self.previewOverlay.setNeedsRender()
    }

    // MARK: - Scene
    
    private func createScene() {
        guard let diagram else {
            self.scene = nil
            return
        }

        let composer = DiagramSceneComposer(world: world)

        let scene = composer.createScene(diagram: diagram, viewport: viewportState)

        let provider = CairoLayoutProvider(context: mainOverlay.context!, style: style)
        scene.setComponent(SceneLayoutProvider(provider: provider))
        composer.layout(scene: scene, layout: provider)
        
        self.scene = scene
        overlays.setAllNeedsRender()
    }
    private func updateScene() {
        guard let scene else { return }
        let composer = DiagramSceneComposer(world: world)

        composer.syncScene(scene)

        let provider = CairoLayoutProvider(context: mainOverlay.context!, style: style)
        scene.setComponent(SceneLayoutProvider(provider: provider))
        composer.layout(scene: scene, layout: provider)
        
        self.scene = scene
        overlays.setAllNeedsRender()
    }


    // MARK: - Drawing
    
    func draw() {
        let viewport = ImGui.GetMainViewport()
        ImGui.SetNextWindowPos(viewport.pointee.WorkPos, ImGuiCond(ImGuiCond_Always.rawValue), ImVec2(0, 0))
        ImGui.SetNextWindowSize(viewport.pointee.WorkSize, ImGuiCond(ImGuiCond_Always.rawValue))

        ImGui.Begin("DiagramCanvas", nil,
            ImGuiWindowFlags_NoDecoration |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_NoNavFocus)
        
        // Canvas color
        let color: Color
        if let canvasStyle = style.shapeStyle(class: .canvas) {
            color = canvasStyle.fill ?? CanvasStyle.DefaultCanvasColor
        }
        else {
            color = CanvasStyle.DefaultCanvasColor
        }
        
        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ChildBg.rawValue), color.imIntValue)
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()

        // Note: We need to do it here for processUnhandledInput(...) to correctly capture
        // the mouse events for canvas. If there is a better solution, I am open.
        isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        )

        canvasPos = ImGui.GetCursorScreenPos()
        canvasSize = ImGui.GetContentRegionAvail()
        overlays.ensureSize(width: Int32(canvasSize.x), height: Int32(canvasSize.y))

        drawOverlays()
        try! overlays.uploadIfNeeded()
        drawOverlayTextures()
       
        editorManager?.draw()
        
        ImGui.EndChild()
        ImGui.End()
    }
    
    func drawOverlays() {
        guard let scene else { return }
        assert(scene.contains(DiagramScene.self))

        let renderer = CairoDiagramSceneRenderer(style: style,
                                                 showValueIndicators: showValueIndicators,
                                                 debug: debugRendering)
        
        if mainOverlay.needsRender {
            mainOverlay.render { context in
                drawGrid(context)
                renderer.render(scene, context: context)
            }
        }
        if previewOverlay.needsRender {
            previewOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
        if highlightOverlay.needsRender {
            highlightOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
        if indicatorOverlay.needsRender {
            indicatorOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
    }

    private func drawOverlayTextures() {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        guard !overlays.textures().isEmpty else {
            drawTextureError()
            return
        }
        let backend = GraphicsBackend.shared

        backend.withBlendMode(.premultiplied, drawList: drawList) {
            for texture in overlays.textures() {
                drawList.pointee.AddImage(
                    texture.imTextureRef,
                    canvasPos, canvasPos + canvasSize,
                    ImVec2(0, 0), ImVec2(1, 1), 0xFFFFFFFF
                )
            }
        }
    }
    
    private func drawTextureError() {
        let drawList = ImGui.GetWindowDrawList()
        let errorColor = Color.screenRed.withTransparency(0.3).imIntValue

        drawList?.pointee.AddRectFilled(canvasPos, canvasPos+canvasSize, errorColor)
        
        let errorText = "Texture Upload Failed"
        let textSize = ImGui.CalcTextSize(errorText)
        let textPos = ImVec2(
            canvasPos.x + (canvasSize.x - textSize.x) / 2,
            canvasPos.y + (canvasSize.y - textSize.y) / 2
        )
        drawList?.pointee.AddText(textPos, Color.white.imIntValue, errorText, nil)
    }

    // MARK: - Canvas Control Methods
    func resetView() {
        self.setView(offset: .zero, zoom: 1.0)
    }
    
    func setView(offset: Vector2D, zoom: Double) {
        viewOffset = offset
        zoomLevel = max(0.01, min(100.0, zoom))
        toOverlayTransform = AffineTransform(translation: -viewOffset)
                                .scaled(Vector2D(zoomLevel, zoomLevel))

        // Viewport Changed
        if let scene {
            scene.setComponent(self.viewportState)
            scene.setComponent(ViewportDirty())
            
            let composer = DiagramSceneComposer(world: self.world)
            composer.updateGeometry(scene: scene)
        }
        overlays.setAllNeedsRender()
    }
    
    func centerView(at worldPoint: Vector2D, zoom: Double? = nil) {
        let useZoom = zoom ?? self.zoomLevel
        let canvasCenter = Vector2D(canvasSize) / 2.0
        let offset = worldPoint - (canvasCenter / useZoom)
        setView(offset: offset, zoom: useZoom)
    }
    func hitTarget(screenPosition: ImVec2) -> CanvasHitTarget? {
        guard let scene else { return nil }
        
        let scenePosition = worldToScene(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel
        
        guard let hitEntity = hitTest(node: scene, scenePosition: scenePosition, radius: radius),
              let parent: RuntimeEntity = hitEntity.target(ChildOf.self)
        else { return nil }

        // Determine hit target type
        //
        if hitEntity.contains(CanvasHandle.self) {
            return CanvasHitTarget(sceneNode: hitEntity.runtimeID,
                                   kind: .handle(hitEntity.runtimeID))
        }
        
        // Resolve the design entity: for blocks/connectors it's the hit entity itself;
        // for labels/indicators it is the parent block.
        let designEntity: RuntimeEntity?
        if hitEntity.contains(BlockSceneNode.self) || hitEntity.contains(ConnectorSceneNode.self) {
            designEntity = hitEntity.target(RepresentationOf.self)
        }
        else {  // Label, indicator, etc. — parent is the block scene node
            designEntity = parent.target(RepresentationOf.self)
        }
        let designRuntimeID = designEntity?.runtimeID ?? hitEntity.runtimeID
        
        let kind: CanvasHitTarget.Kind
        
        if parent.relates(SceneNode.PrimaryLabel.self, to: hitEntity) {
            kind = .object(designRuntimeID, .primaryLabel)
        } else if parent.relates(SceneNode.SecondaryLabel.self, to: hitEntity) {
            kind = .object(designRuntimeID, .secondaryLabel)
        } else if hitEntity.contains(IssueIndicatorSceneNode.self) {
            kind = .object(designRuntimeID, .issueIndicator)
        } else if hitEntity.contains(BlockSceneNode.self) || hitEntity.contains(ConnectorSceneNode.self) {
            kind = .object(designRuntimeID, .body)
        }
        else {
            return nil
        }
        
        return CanvasHitTarget(sceneNode: hitEntity.runtimeID, kind: kind)
    }
    func hitTest(node: RuntimeEntity, scenePosition: Vector2D, radius: Double) -> RuntimeEntity? {
        // FIXME: This is temporary solution. We need z-index ordering
        for handle in node.children where handle.contains(CanvasHandle.self) {
            guard let region: TouchRegion = handle.component(),
                  region.isHit(at: scenePosition, radius: radius)
            else { continue }

            return handle
        }

        for child in node.children {
            if let region: TouchRegion = child.component(),
               region.isHit(at: scenePosition, radius: radius)
            {
                return child
            }
            if let found = hitTest(node: child, scenePosition: scenePosition, radius: radius) {
                return found
            }
        }
        return nil
    }
    
    // MARK: - Inline Editors
    func openInlineEditorForSelection(_ editorName: String) {
        guard let document,
              let objectID = document.selection.selectionOfOne(),
              let entity = document.world.entity(objectID)
        else { return }
        
        self.editorManager?.openEditor(editorName, for: entity)
    }

    func openSecondaryInlineEditorForSelection() {
        guard let document,
              let objectID = document.selection.selectionOfOne(),
              let entity = document.world.entity(objectID),
              let object = entity.designObject
        else { return }
       
        if object.type.hasTrait(SimulationDomain.Traits.Formula) {
            self.editorManager?.openEditor("formula", for: entity)
        }
        else if object.type.hasTrait(StockFlowDomain.Traits.Delay) {
            self.editorManager?.openEditor("delay", for: entity)
        }
        else if object.type.hasTrait(StockFlowDomain.Traits.Smooth) {
            self.editorManager?.openEditor("smooth", for: entity)
        }
        else if object.type.hasTrait(StockFlowDomain.Traits.GraphicalFunction) {
            self.editorManager?.openEditor("graphical_function", for: entity)
        }
    }
}
