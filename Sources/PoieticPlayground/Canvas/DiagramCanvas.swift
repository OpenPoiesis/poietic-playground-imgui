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

    var layers: SurfaceLayerStack
    var mainLayer: CanvasSurface

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
    /// - SeeAlso: ``viewScale``I a
    var viewOffset: Vector2D = .zero

    /// Canvas view scale.
    ///
    /// - SeeAlso: ``viewOffset``
    ///
    var zoomLevel: Double = 1.0
    
    /// Grid spacing in world coordinates.
    var gridSize: Double = 50.0
    var showGrid = true                       // Whether to show the grid
    var gridColor = ImVec4(0.3, 0.3, 0.3, 0.2) // Grid line color

    init(session: Session? = nil) {
        self.session = session
        self.style = CanvasStyle()

        self.layers = SurfaceLayerStack()
        
        self.mainLayer = CanvasSurface(name: "main")
        self.layers.add(self.mainLayer)

    }
    
    func bind(_ session: Session) {
        self.session = session
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

    /// Convert world coordinates to screen coordinates
    func worldToScreen(_ worldPos: Vector2D) -> ImVec2 {
        let screenPos = (worldPos - viewOffset) * Double(zoomLevel)
        return ImVec2(screenPos) + canvasPos
    }
    func toScreenTransform() -> AffineTransform {
        return AffineTransform(translation: Vector2D(canvasPos) - Vector2D(viewOffset)).scaled(Vector2D(zoomLevel, zoomLevel))
    }
   
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        NEWdraw()
        return
        
        let viewport = ImGui.GetMainViewport()
        ImGui.SetNextWindowPos(viewport.pointee.WorkPos, ImGuiCond(ImGuiCond_Always.rawValue), ImVec2(0, 0))
        ImGui.SetNextWindowSize(viewport.pointee.WorkSize, ImGuiCond(ImGuiCond_Always.rawValue))

        ImGui.Begin("DiagramCanvas", nil,
            ImGuiWindowFlags_NoDecoration |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_NoNavFocus)
        
//        ImGui.Begin("Canvas Window")

        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        // Set a background colour
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleVar()

        canvasPos = ImGui.GetCursorScreenPos()
        canvasSize = ImGui.GetContentRegionAvail()
        
        // Used for processUnhandledInput(...)
        isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        )

        drawGrid()
        drawContent()

        ImGui.EndChild()
        ImGui.End()
    }


    // MARK: - Canvas Control Methods
    func resetView() {
        viewOffset = .zero
        zoomLevel = 1.0
    }
    
    func setView(offset: Vector2D, zoom: Double) {
        viewOffset = offset
        zoomLevel = max(0.01, min(100.0, zoom))
    }
    
    func hitTarget(screenPosition: ImVec2) -> CanvasHitTarget? {
        var targets: [CanvasHitTarget] = []
        
        // TODO: This is expensive"
        let worldTouchPosition: Vector2D = screenToWorld(screenPosition)
        let touchShape = CollisionShape(position: worldTouchPosition, shape: .circle(Self.DefaultHitRadius))

        for (runtimeID, block) in world.query(DiagramBlock.self) {
            let blockShape = block.collisionShape.translated(block.position)
            if blockShape.collide(with: touchShape) {
                let target: CanvasHitTarget = .object(runtimeID, .body)
                targets.append(target)
            }
        }
        
        for (runtimeID, connector) in world.query(DiagramConnectorGeometry.self) {
            // TODO: Have the wire tessellated already
            let wire = connector.wire.tessellate()

            for i in 0..<(wire.count-1) {
                let segment = LineSegment(from: wire[i], to: wire[i + 1])
                if segment.distance(to: worldTouchPosition) < Self.DefaultHitRadius {
                    let target: CanvasHitTarget = .object(runtimeID, .body)
                    targets.append(target)
                }
            }
        }

        for (runtimeID, handle) in world.query(CanvasHandle.self) {
            let distance = worldTouchPosition.distance(to: handle.position)
            guard distance <= Self.DefaultHitRadius else { continue }
            let target: CanvasHitTarget = .handle(runtimeID)
            targets.append(target)
        }

        return targets.last
    }
}
