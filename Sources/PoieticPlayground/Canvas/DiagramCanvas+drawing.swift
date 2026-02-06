//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//
import CIimgui
import Diagramming
import PoieticCore

extension DiagramCanvas {
    func drawContent() {
        drawBlocks()
        drawConnectors()
    }
    
    func drawBlocks() {
        for (id, component) in world.query(DiagramBlock.self) {
            drawBlock(runtimeID: id, block: component)
        }
    }
    
    func drawBlock(runtimeID: RuntimeID, block: DiagramBlock) {
        if let pictogram = block.pictogram {
            let transform = AffineTransform(translation: block.position)
            let path = pictogram.path.transform(transform)
            strokePath(path)
        }
        if let label = block.label {
            
        }
        
    }
    
    func drawConnectors() {
        for (id, component) in world.query(DiagramConnectorGeometry.self) {
            drawConnector(runtimeID: id, geometry: component)
        }
    }
    func drawConnector(runtimeID: RuntimeID, geometry: DiagramConnectorGeometry) {
        // DEBUG wire
        strokePath(geometry.wire, color: Color(red: 1.0, green: 0.5, blue: 0.0))

        // Open curves
        if let path = geometry.linePath {
            strokePath(path)
        }
        if let path = geometry.headArrowhead {
            strokePath(path)
        }
        if let path = geometry.tailArrowhead {
            strokePath(path)
        }
        // Filled curves
        if let path = geometry.fillPath {
            fillPath(path)
        }
    }
    func strokePath(_ path: BezierPath, color: Color = .white, lineWidth: Float = 1.0) {
        guard let drawList = ImGui.GetWindowDrawList() else {
            return
        }

        let strokeColor: ImU32 = color.imIntValue

        var hadStroke: Bool = false
        var wasClosed: Bool = false
        
        for element in path.elements {
            switch element {
            case .moveTo(let point):
                let screenPoint = worldToScreen(point)
                if hadStroke {
                    drawList.pointee.PathStroke(strokeColor, 0, lineWidth)
                }
                drawList.pointee.PathClear()
                drawList.pointee.PathLineTo(screenPoint)
                wasClosed = false
                hadStroke = false

            case .lineTo(let point):
                let screenPoint = worldToScreen(point)
                drawList.pointee.PathLineTo(screenPoint)
                wasClosed = false
                hadStroke = true

            case .curveTo(let end, let control1, let control2):
                let scrEnd = worldToScreen(end)
                let scrControl1 = worldToScreen(control1)
                let scrControl2 = worldToScreen(control2)
                drawList.pointee.PathBezierCubicCurveTo(scrControl1, scrControl2, scrEnd)
                wasClosed = false
                hadStroke = true

            case .quadCurveTo(let control, let end):
                let scrEnd = worldToScreen(end)
                let scrControl = worldToScreen(control)
                drawList.pointee.PathBezierQuadraticCurveTo(scrControl, scrEnd)
                hadStroke = true
                wasClosed = false

            case .closePath:
                drawList.pointee.PathStroke(strokeColor, 0, lineWidth)
                wasClosed = true
                hadStroke = false
            }
        }
        if hadStroke && !wasClosed {
            drawList.pointee.PathStroke(strokeColor, 0, lineWidth)
        }
    }
    
    func fillPath(_ path: BezierPath, color: Color = .white) {
        guard let drawList = ImGui.GetWindowDrawList() else {
            return
        }

        let fillColor: ImU32 = color.imIntValue
        let debugColor: ImU32 = Color(red: 1.0, green: 0.0, blue: 0.0).imIntValue
        for segment in path.subpaths() {
            let points = segment.tessellate()
            let screenPoints = points.map { worldToScreen($0) }
            drawList.pointee.AddConcavePolyFilled(screenPoints, Int32(screenPoints.count), fillColor)
            drawList.pointee.AddPolyline(screenPoints, Int32(screenPoints.count), debugColor, 0, 1)
        }
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
        let blockCount = world.query(DiagramBlock.self).count
        let connectorCount = world.query(DiagramConnectorGeometry.self).count
        var infoText = "Blocks: \(blockCount) "
                        + "Conns: \(connectorCount) "
                        + "| Zoom: \(zoomLevel * 100) Offset: (\(viewOffset.x)x\(viewOffset.y)"
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
