//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//
import CIimgui
import Diagramming

extension DiagramCanvas {
    func drawContent() {
        // TODO: To be done, from World
    }

    func drawGrid() {
        guard showGrid,
              let drawList = ImGui.GetWindowDrawList()
        else { return }
        
        // Calculate visible area in world coordinates
        let worldTopLeft: Vector2D = screenToWorld(canvasPos)
        let screenBottomRight = canvasPos + canvasSize
        let worldBottomRight: Vector2D = screenToWorld(screenBottomRight)
        
        // Draw vertical grid lines
        let startX = floor(worldTopLeft.x / gridSize) * gridSize
        let endX = ceil(worldBottomRight.x / gridSize) * gridSize
        
        for x in stride(from: startX, through: endX, by: gridSize) {
            let screenX = Float((x - viewOffset.x) * zoomLevel) + canvasPos.x
            let p1 = ImVec2(screenX, canvasPos.y)
            let p2 = ImVec2(screenX, canvasPos.y + canvasSize.y)
            
            drawList.pointee.AddLine(p1, p2,
                ImGui.ColorConvertFloat4ToU32(gridColor), 1.0)
        }
        
        // Draw horizontal grid lines
        let startY = floor(worldTopLeft.y / gridSize) * gridSize
        let endY = ceil(worldBottomRight.y / gridSize) * gridSize
        
        for y in stride(from: startY, through: endY, by: gridSize) {
            let screenY = Float((y - viewOffset.y) * zoomLevel) + canvasPos.y
            let p1 = ImVec2(canvasPos.x, screenY)
            let p2 = ImVec2(canvasPos.x + canvasSize.x, screenY)
            
            drawList.pointee.AddLine(p1, p2,
                ImGui.ColorConvertFloat4ToU32(gridColor), 1.0)
        }
    }

    func drawStatusInfo(_ text: String) {
        // Draw view information in corner
        var infoText = "Zoom: \(zoomLevel * 100) | Pan: (\(viewOffset.x), \(viewOffset.y) | Win F/H: \(ImGui.IsWindowFocused())/\(ImGui.IsWindowHovered())"
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


}
