//
//  DiagramCanvas.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui
import Diagramming

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
struct InputState {
    enum PointerState: Equatable {
        /// Pointer or mouse is up – idle.
        case idle
        /// Pointer or mouse is pressed, not yet moved.
        ///
        /// The associated value is the first button that triggered the state.
        case pressed(MouseButton)
        /// Pointer or mouse has been moved.
        ///
        /// The associated value is the first button that triggered the state.
        case dragging(MouseButton)
    }

    var pointerState: PointerState = .idle

    var mousePos: ImVec2? = nil
    var previousModifiers: KeyModifiers = .none
    var wasMouseInViewport: Bool = false
}

class DiagramCanvas: View {
    
    var debugMessage: String = ""
    
    var inputState: InputState = InputState()
    
    unowned var app: Application?
    var canvasPos = ImVec2(0.0, 0.0)          // Screen position of canvas
    var canvasSize = ImVec2(0.0, 0.0)         // Screen size of canvas

    private var isDragging = false            // Are we currently panning?
    private var dragStartPos = ImVec2(0.0, 0.0) // Where did drag start?

    private var lines: [(ImVec2, ImVec2)] = [] // List of completed lines
    private var isDrawingLine = false         // Are we currently drawing a line?
    private var lineStart = ImVec2(0.0, 0.0)  // Start point of current line
    private var lineEnd = ImVec2(0.0, 0.0)    // Current mouse position for preview
    
    /// Canvas view offset in world coordinates.
    ///
    /// - SeeAlso: ``viewScale``
    var viewOffset = ImVec2(0.0, 0.0)

    /// Canvas view scale.
    ///
    /// - SeeAlso: ``viewOffset``
    ///
    var viewScale: Float = 1.0
    
    /// Grid spacing in world coordinates.
    var gridSize: Float = 50.0
    var showGrid = true                       // Whether to show the grid
    var gridColor = ImVec4(0.3, 0.3, 0.3, 0.2) // Grid line color

    /// Convert screen coordinates to world coordinates
    func screenToWorld(_ screenPos: ImVec2) -> ImVec2 {
        return ImVec2(
            (screenPos.x - canvasPos.x) / viewScale + viewOffset.x,
            (screenPos.y - canvasPos.y) / viewScale + viewOffset.y
        )
    }
   
    func screenToWorld(_ screenPos: ImVec2) -> Vector2D {
        return Vector2D(
            x: Double(screenPos.x - canvasPos.x) / Double(viewScale) + Double(viewOffset.x),
            y: Double(screenPos.y - canvasPos.y) / Double(viewScale) + Double(viewOffset.y)
        )
    }

    /// Convert world coordinates to screen coordinates
    func worldToScreen(_ worldPos: ImVec2) -> ImVec2 {
        return ImVec2(
            (worldPos.x - viewOffset.x) * viewScale + canvasPos.x,
            (worldPos.y - viewOffset.y) * viewScale + canvasPos.y
        )
    }

    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        ImGui.Begin("Canvas Window")

        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        // Set a background colour
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ChildBg.rawValue), ImColor(Int32(50), 50, 80, 255).intValue)
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()

        canvasPos = ImGui.GetCursorScreenPos();      // ImDrawList API uses screen coordinates!
        canvasSize = ImGui.GetContentRegionAvail();   // Resize canvas to what's available

        let io = ImGui.GetIO().pointee
        let handled = handleInput(io)

        drawGrid()
        drawStatusInfo("H: \(handled)")
        renderContent()

        ImGui.EndChild()
        ImGui.End()
    }


    // MARK: - Drawing
    private func drawGrid() {
        guard showGrid,
              let drawList = ImGui.GetWindowDrawList()
        else { return }
        
        // Calculate visible area in world coordinates
        let worldTopLeft: ImVec2 = screenToWorld(canvasPos)
        let worldBottomRight: ImVec2 = screenToWorld(ImVec2(canvasPos.x + canvasSize.x,
                                                   canvasPos.y + canvasSize.y))
        
        // Draw vertical grid lines
        let startX = floor(worldTopLeft.x / gridSize) * gridSize
        let endX = ceil(worldBottomRight.x / gridSize) * gridSize
        
        for x in stride(from: startX, through: endX, by: gridSize) {
            let screenX = (x - viewOffset.x) * viewScale + canvasPos.x
            let p1 = ImVec2(screenX, canvasPos.y)
            let p2 = ImVec2(screenX, canvasPos.y + canvasSize.y)
            
            drawList.pointee.AddLine(p1, p2,
                ImGui.ColorConvertFloat4ToU32(gridColor), 1.0)
        }
        
        // Draw horizontal grid lines
        let startY = floor(worldTopLeft.y / gridSize) * gridSize
        let endY = ceil(worldBottomRight.y / gridSize) * gridSize
        
        for y in stride(from: startY, through: endY, by: gridSize) {
            let screenY = (y - viewOffset.y) * viewScale + canvasPos.y
            let p1 = ImVec2(canvasPos.x, screenY)
            let p2 = ImVec2(canvasPos.x + canvasSize.x, screenY)
            
            drawList.pointee.AddLine(p1, p2,
                ImGui.ColorConvertFloat4ToU32(gridColor), 1.0)
        }
    }

    private func renderContent() {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        let lineColor = ImGui.ColorConvertFloat4ToU32(ImVec4(1.0, 0.5, 0.2, 1.0))
        
        // Draw completed lines
        for (start, end) in lines {
            let screenStart = worldToScreen(start)
            let screenEnd = worldToScreen(end)
            drawList.pointee.AddLine(screenStart, screenEnd, lineColor, 2.0)
        }
        
        // Draw current line being created
        if isDrawingLine {
            let previewColor = ImGui.ColorConvertFloat4ToU32(ImVec4(0.2, 0.8, 1.0, 0.7))
            let screenStart = worldToScreen(lineStart)
            let screenEnd = worldToScreen(lineEnd)
            drawList.pointee.AddLine(screenStart, screenEnd, previewColor, 2.0)
            
            // Draw start and end points
            drawList.pointee.AddCircleFilled(screenStart, 4.0, previewColor, 0)
            drawList.pointee.AddCircleFilled(screenEnd, 4.0, previewColor, 0)
        }
    }

    private func drawStatusInfo(_ text: String) {
        // Draw view information in corner
        var infoText = "Zoom: \(viewScale * 100) | Pan: (\(viewOffset.x), \(viewOffset.y) | Lines: \(lines.count) | Win F/H: \(ImGui.IsWindowFocused())/\(ImGui.IsWindowHovered())"
        infoText += " \(text)"
        let padding: Float = 10.0
        let textSize = ImGui.CalcTextSize(infoText, nil, true, 0)
        
        let drawList = ImGui.GetWindowDrawList()
        let bgColor = ImGui.ColorConvertFloat4ToU32(ImVec4(0.0, 0.0, 0.0, 0.5))
        let textColor = ImGui.ColorConvertFloat4ToU32(ImVec4(1.0, 1.0, 1.0, 1.0))
        
        let bgPos1 = ImVec2(canvasPos.x + canvasSize.x - textSize.x - padding * 2,
                           canvasPos.y + canvasSize.y - textSize.y - padding * 2)
        let bgPos2 = ImVec2(canvasPos.x + canvasSize.x,
                           canvasPos.y + canvasSize.y)
        
        drawList?.pointee.AddRectFilled(bgPos1, bgPos2, bgColor, 5.0, 0)
        drawList?.pointee.AddText(ImVec2(bgPos1.x + padding, bgPos1.y + padding),
                                 textColor, infoText, nil)
    }


    // MARK: - Canvas Control Methods
    func resetView() {
        viewOffset = ImVec2(0.0, 0.0)
        viewScale = 1.0
    }
    
    func setView(offset: ImVec2, scale: Float) {
        viewOffset = offset
        viewScale = max(0.01, min(100.0, scale))
    }
    
    func centerOn(point: ImVec2) {
        viewOffset = ImVec2(
            point.x - canvasSize.x / (2 * viewScale),
            point.y - canvasSize.y / (2 * viewScale)
        )
    }
    
    func clearLines() {
        lines.removeAll()
    }
    
    func addLine(from start: ImVec2, to end: ImVec2) {
        lines.append((start, end))
    }
    
    func getViewInfo() -> (offset: ImVec2, scale: Float) {
        return (viewOffset, viewScale)
    }
}
