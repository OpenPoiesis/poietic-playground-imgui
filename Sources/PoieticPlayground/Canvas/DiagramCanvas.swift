//
//  DiagramCanvas.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui
import Diagramming
import PoieticCore

/*
 Frame 1: Mouse button pressed at (100, 100)
   → PointerDown event
   → State machine: IDLE → PRESSED
   
 Frame 2-5: Mouse still pressed, no movement (or < 3px)
   → PointerMove events (minimal delta)
   → State machine: stays in PRESSED
   
 Frame 6: Mouse moved to (150, 100) - exceeds threshold!
   → DragStart event (first time!)
   → PointerMove event (still happens)
   → State machine: PRESSED → DRAGGING
   
 Frame 7-10: Mouse continues moving while pressed
   → DragMove events
   → PointerMove events
   → State machine: stays in DRAGGING
   
 Frame 11: Mouse button released
   → DragEnd event
   → PointerUp event
   → State machine: DRAGGING → IDLE
 */
class DiagramCanvas: View {
    static let DefaultHitRadius: Double = 5.0

    var editorManager: InlineEditorManager
    
    // TODO: Not fully implemented, only one overlay at the moment
    var overlays: OverlayStack
    var mainOverlay: Overlay
    
    weak var session: Session?
    internal var world: World {
        guard let session else { fatalError("DiagramCanvas used before binding")}
        return session.world
    }
    var style: CanvasStyle
    
    var debugMessage: String = ""
    
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
    
    /// Transformation from world coordinates to the drawing context/surface coordinates.
    ///
    /// The transform is derived from canvas view offset and zoom level.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``
    private(set) var toOverlayTransform: AffineTransform = .identity
    
    /// Grid spacing in world coordinates.
    var gridSize: Double = 50.0
    var showGrid = true

    init(session: Session? = nil) {
        self.session = session
        self.style = CanvasStyle()

        self.overlays = OverlayStack()
        
        self.mainOverlay = Overlay(name: "main")
        self.overlays.add(self.mainOverlay)
        
        self.editorManager = InlineEditorManager()
        
        self.editorManager.register(name: "name", editor: NameInlineEditor())
        self.editorManager.register(name: "formula", editor: FormulaInlineEditor())
        self.editorManager.register(name: "delay",
                                    editor: NumericValueInlineEditor(attribute: "delay_duration", iconKey: .timeWindow))
        self.editorManager.register(name: "smooth",
                                    editor: NumericValueInlineEditor(attribute: "window_time", iconKey: .timeWindow))
    }
    
    func onSelectionChanged(_ session: Session) {
        // TODO: Make only selection overlay dirty (once we have selection overlays)
        overlays.setAllNeedsRender()
    }

    func onDesignFrameChanged(_ session: Session) {
        overlays.setAllNeedsRender()
    }

    func onInteractivePreviewChanged(_ session: Session) {
        // TODO: Make only preview overlay dirty (once we have selection overlays)
        overlays.setAllNeedsRender()
    }

    func bind(_ session: Session) {
        self.session = session
        self.editorManager.bind(session: session, canvas: self)
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
   
    /// Convert world coordinates to canvas overlay coordinates.
    func worldToOverlay(_ worldPos: Vector2D) -> Vector2D {
        return toOverlayTransform.apply(to: worldPos)
    }
    func overlayToWorld(_ overlayPos: Vector2D) -> Vector2D {
        let worldPos = overlayPos / zoomLevel + viewOffset
        return worldPos
    }
    
    var visibleWorldRect: Rect2D {
        Rect2D(origin: viewOffset, size: (Vector2D(canvasSize) / zoomLevel))
    }
    

    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        let viewport = ImGui.GetMainViewport()
        ImGui.SetNextWindowPos(viewport.pointee.WorkPos, ImGuiCond(ImGuiCond_Always.rawValue), ImVec2(0, 0))
        ImGui.SetNextWindowSize(viewport.pointee.WorkSize, ImGuiCond(ImGuiCond_Always.rawValue))

        ImGui.Begin("DiagramCanvas", nil,
            ImGuiWindowFlags_NoDecoration |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_NoNavFocus)
        
        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ChildBg.rawValue), style.background.imIntValue)
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()

        canvasPos = ImGui.GetCursorScreenPos()
        canvasSize = ImGui.GetContentRegionAvail()
        
        // Note: We need to do it here for processUnhandledInput(...) to correctly capture
        // the mouse events for canvas. If there is a better solution, I am open.
        isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        )

        // Ensure all layers match canvas size
        overlays.ensureSize(width: Int32(canvasSize.x),
                            height: Int32(canvasSize.y))
        
        drawOverlays()
        try! overlays.uploadIfNeeded()
        drawOverlayTextures()
       
        editorManager.draw()
        
        ImGui.EndChild()
        ImGui.End()
    }
    
    func drawOverlays() {
        if mainOverlay.needsRender {
            // TODO: Handle exception
            try! mainOverlay.render { context in
                drawMainOverlay(context)
            }
        }
    }

    private func drawOverlayTextures() {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        // Fallback if no textures
        guard !overlays.textures().isEmpty else {
            drawTextureError()
            return
        }

        for texture in overlays.textures() {
            drawList.pointee.AddImage(
                texture.imTextureRef,
                canvasPos, canvasPos + canvasSize,
                ImVec2(0, 0), ImVec2(1, 1), 0xFFFFFFFF
            )
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
        overlays.setAllNeedsRender()
    }
    
    func hitTarget(screenPosition: ImVec2) -> CanvasHitTarget? {
        var targets: [CanvasHitTarget] = []

        // TODO: This is expensive"
        print("HitTarget - screenPos: \(screenPosition), canvasPos: \(canvasPos)")
        let worldTouchPosition: Vector2D = screenToWorld(screenPosition)
        let touchShape = CollisionShape(position: worldTouchPosition, shape: .circle(Self.DefaultHitRadius))
        print("  → worldPos: \(worldTouchPosition)")

        // Blocks (collision shape) and Error indicators
        for (entity, block) in world.query(DiagramBlock.self) {
            let blockShape = block.collisionShape.translated(block.position)
            if blockShape.collide(with: touchShape) {
                let target: CanvasHitTarget = .object(entity.runtimeID, .body)
                targets.append(target)
            }
            
//            if let objectID = world.entityToObject(runtimeID),
//               objectHasIssues(objectID)
//            {
//                let indicatorPosition = block.position + errorIndicatorAnchorOffset
//                if worldTouchPosition.distance(to: indicatorPosition) <
//            }
        }
        
        // Connectors (distance to wire)
        for (entity, connector) in world.query(DiagramConnectorGeometry.self) {
            // TODO: Have the wire tessellated already
            let wire = connector.wire.tessellate()

            for i in 0..<(wire.count-1) {
                let segment = LineSegment(from: wire[i], to: wire[i + 1])
                if segment.distance(to: worldTouchPosition) < Self.DefaultHitRadius {
                    let target: CanvasHitTarget = .object(entity.runtimeID, .body)
                    targets.append(target)
                }
            }
        }

        // Handles
        for (entity, handle) in world.query(CanvasHandle.self) {
            let distance = worldTouchPosition.distance(to: handle.position)
            guard distance <= Self.DefaultHitRadius else { continue }
            let target: CanvasHitTarget = .handle(entity.runtimeID)
            targets.append(target)
        }
        print("--- Targets: ", targets)

        return targets.last
    }
    
    // MARK: - Inline Editors
    func openInlineEditorForSelection(_ editorName: String) {
        guard let session,
              let objectID = session.selection.selectionOfOne(),
              let entity = session.world.entity(objectID)
        else { return }
        
        self.editorManager.openEditor(editorName, for: entity)
    }

    func openSecondaryInlineEditorForSelection() {
        guard let session,
              let objectID = session.selection.selectionOfOne(),
              let entity = session.world.entity(objectID),
              let object = entity.designObject
        else { return }
       
        if object.type.hasTrait(.Formula) {
            self.editorManager.openEditor("formula", for: entity)
        }
        else if object.type.hasTrait(.Delay) {
            self.editorManager.openEditor("delay", for: entity)
        }
        else if object.type.hasTrait(.Smooth) {
            self.editorManager.openEditor("smooth", for: entity)
        }
        else if object.type.hasTrait(.GraphicalFunction) {
            // TODO: Implement graphical function editor
            self.editorManager.openEditor("graphical_function", for: entity)
        }
    }
}
