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
    static let PrimaryLabelPadding: Float = 0.0
    static let SecondaryLabelPadding: Float = 4.0
    static let ColorSwatchSize: ImVec2 = ImVec2(10.0, 10.0)

    func drawContent() {
        drawBlocks()
        drawConnectors()
        drawIntents()
    }
    
    func drawIntents() {
        for (runtimeID, component) in world.query(BlockIntentShadow.self) {
            drawBlockIntent(runtimeID: runtimeID, block: component)
        }
    }
    
    func drawBlocks() {
        let selection: Selection? = world.singleton()
        
        for (runtimeID, component) in world.query(DiagramBlock.self) {
            guard let objectID = world.entityToObject(runtimeID) else { continue }
            let isSelected = selection?.contains(objectID) ?? false
            drawBlock(runtimeID: runtimeID, isSelected: isSelected, block: component)
        }
    }
    func drawBlockIntent(runtimeID: RuntimeID, block: BlockIntentShadow) {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        let color = style.intentShadowColor
        let screenTransform = toScreenTransform()
        let transform = screenTransform.translated(block.position)
        drawList.pointee.StrokePath(block.pictogram.path, color: color, transform: transform)
    }

    func drawBlock(runtimeID: RuntimeID, isSelected: Bool, block: DiagramBlock) {
        let screenTransform = toScreenTransform()

        guard let drawList = ImGui.GetWindowDrawList() else { return }
        
        let blockPosition: Vector2D
        
        if let preview: BlockPreview = world.component(for: runtimeID) {
            blockPosition = preview.position
        }
        else {
            blockPosition = block.position
        }
        
        let screenPos = worldToScreen(blockPosition)
        var swatchCenter: ImVec2
        var labelCenter: ImVec2
        
        if let pictogram = block.pictogram {
            let transform = screenTransform.translated(blockPosition)
            drawList.pointee.StrokePath(pictogram.path, transform: transform)

            let screenBBMin = worldToScreen(pictogram.pathBoundingBox.topLeft + blockPosition)
            labelCenter = ImVec2(screenPos.x, screenBBMin.y)
            
            if isSelected {
                drawList.pointee.FillPath(pictogram.mask, color: style.selectionFillColor, transform: transform)
                drawList.pointee.StrokePath(pictogram.mask, color: style.selectionOutlineColor, transform: transform)
            }
        }
        else {
            labelCenter = screenPos
        }

        swatchCenter = labelCenter
        labelCenter.y += Self.PrimaryLabelPadding
       
        if let label = block.label {
            let color = style.primaryLabelStyle.color.imIntValue
            let size = ImGui.CalcTextSize(label)
            let position = ImVec2(labelCenter.x - (size.x / 2), labelCenter.y + size.y)
            drawList.pointee.AddText(position, color, label, nil)
            labelCenter.y += size.y + Self.SecondaryLabelPadding
            swatchCenter = ImVec2(position.x - Self.ColorSwatchSize.x, position.y + size.y/2)
        }

        if let label = block.secondaryLabel {
            let color = style.secondaryLabelStyle.color.imIntValue
            let size = ImGui.CalcTextSize(label)
            let position = ImVec2(labelCenter.x - (size.x / 2), labelCenter.y + size.y)
            drawList.pointee.AddText(position, color, label, nil)
        }

        if let colorName = block.accentColorName {
            let color = style.adaptableColor(colorName, default: .white)
            let pmin = swatchCenter - (Self.ColorSwatchSize / 2.0)
            let pmax = pmin + Self.ColorSwatchSize
            drawList.pointee.AddRectFilled(pmin, pmax, color.imIntValue)
        }
        
    }
    
    func drawConnectors() {
        let selection: Selection? = world.singleton()

        for (runtimeID, component) in world.query(DiagramConnectorGeometry.self) {
            guard let objectID = world.entityToObject(runtimeID) else { continue }
            let isSelected = selection?.contains(objectID) ?? false
            drawConnector(runtimeID: runtimeID, geometry: component, isSelected: isSelected)
        }
    }
    func drawConnector(runtimeID: RuntimeID, geometry: DiagramConnectorGeometry, isSelected: Bool) {
        guard var drawList = ImGui.GetWindowDrawList() else {
            return
        }
        let transform = toScreenTransform()
        // DEBUG wire
        if isSelected {
            drawList.pointee.StrokePath(geometry.wire, color: Color(red: 1.0, green: 0.5, blue: 0.0), lineWidth: 4, transform: transform)
        }

        // Open curves
        if let path = geometry.linePath {
            drawList.pointee.StrokePath(path, color: style.defaultConnectorColor, transform: transform)
        }
        if let path = geometry.headArrowhead {
            drawList.pointee.StrokePath(path, color: style.defaultConnectorColor, transform: transform)
        }
        if let path = geometry.tailArrowhead {
            drawList.pointee.StrokePath(path, color: style.defaultConnectorColor, transform: transform)
        }
        // Filled curves
        if let path = geometry.fillPath {
            // TODO: ImGui can not draw correctly concave polygons (they are expensive)
            drawList.pointee.StrokePath(path, color: style.defaultConnectorColor, transform: transform)
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
