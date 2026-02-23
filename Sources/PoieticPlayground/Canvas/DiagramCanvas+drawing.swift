//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//
import CIimgui
import Diagramming
import PoieticCore

import Ccairo

extension DiagramCanvas {
    static let HandleSize: Float = 15.0
    static let PrimaryLabelPadding: Double = 0.0
    static let SecondaryLabelPadding: Double = 4.0
    static let ColorSwatchSize: Vector2D = Vector2D(10.0, 10.0)

    func drawToCairo(_ cairoContext: OpaquePointer) {
        let context = DrawingContext(cairoContext)
//        dcontext.setColor(style.background)
        cairo_set_antialias(cairoContext, CAIRO_ANTIALIAS_DEFAULT)
        drawGrid(context)
        drawBlocks(context)
        drawConnectors(context)
    }
    func drawContent() {
        // Layer 1: Highlights
        
        // Layer 2: Blocks and Connectors
//        drawBlocks()
//        drawConnectors()
        // Layer 3: Intents
        drawIntents()
        // Layer 4: Handles
        drawHandles()
    }
    
    func drawHandles() {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        let color = style.handleColor
        let radius = Self.HandleSize / 2

        for (_, handle) in world.query(CanvasHandle.self) {
            let screenPos = worldToScreen(handle.position)
            drawList.pointee.AddCircle(screenPos, radius, color.imIntValue, 0, 4)
        }
    }
    
    func drawIntents() {
        for (runtimeID, component) in world.query(BlockIntent.self) {
            drawBlockIntent(runtimeID: runtimeID, block: component)
        }
    }
    
    func drawBlocks(_ context: DrawingContext) {
        let selection: Selection? = world.singleton()
        
        for (runtimeID, component) in world.query(DiagramBlock.self) {
            guard let objectID = world.entityToObject(runtimeID) else { continue }

            let isSelected = selection?.contains(objectID) ?? false
            drawBlock(context, runtimeID: runtimeID, isSelected: isSelected, block: component)
        }
    }

    func drawBlockIntent(runtimeID: RuntimeID, block: BlockIntent) {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        let color = style.intentShadowColor
        let screenTransform = toScreenTransform()
        let transform = screenTransform.translated(block.position)
        drawList.pointee.StrokePath(block.pictogram.path, color: color, transform: transform)
    }

    func drawBlock(_ context: DrawingContext, runtimeID: RuntimeID, isSelected: Bool, block: DiagramBlock) {
        let screenTrans = toScreenTransform()
        let blockPosition: Vector2D
        
        if let preview: BlockPreview = world.component(for: runtimeID) {
            blockPosition = preview.position
        }
        else {
            blockPosition = block.position
        }
        
        let screenPos = Vector2D(worldToScreen(blockPosition))
        var swatchCenter: Vector2D
        var labelCenter: Vector2D
        
        if let pictogram = block.pictogram {
            let blockTrans = screenTrans.translated(blockPosition)

            if isSelected {
                context.setColor(style.selectionFillColor)
                context.fillPath(pictogram.mask, transform: blockTrans)
                context.setColor(style.selectionOutlineColor)
                context.strokePath(pictogram.mask, transform: blockTrans)
            }
            
            if let highlight: TargetHighlight = world.component(for: runtimeID) {
                switch highlight {
                case .accepting:
                    context.setColor(style.acceptingColor)
                    context.strokePath(pictogram.mask, transform: blockTrans)
                case .notAllowed:
                    context.setColor(style.notAllowedColor)
                    context.strokePath(pictogram.mask, transform: blockTrans)
                case .none:
                    break
                }
            }

            context.setColor(style.pictogramColor)
            context.strokePath(pictogram.path, transform: blockTrans)
            
            let screenBBMin = screenTrans.apply(to: pictogram.pathBoundingBox.topLeft + blockPosition)
            labelCenter = Vector2D(screenPos.x, screenBBMin.y)
        }
        else {
            labelCenter = screenPos
        }

        swatchCenter = labelCenter
        labelCenter.y += Self.PrimaryLabelPadding
      
        if let label = block.label {
            context.setFontSize(style.primaryLabelStyle.fontSize)
            let size = context.textSize(label)
            let te = context.textExtents(label)
            let position = Vector2D(labelCenter.x - (te.width / 2) - te.x_bearing,
                                    labelCenter.y + (te.height) - te.y_bearing)

            context.setColor(style.primaryLabelStyle.color)
            context.showText(label, at: position)

            labelCenter.y = position.y + Self.SecondaryLabelPadding
            swatchCenter = Vector2D(position.x - Self.ColorSwatchSize.x, position.y - size.y/2)
        }

        if let label = block.secondaryLabel {
            context.setFontSize(style.secondaryLabelStyle.fontSize)
            let size = context.textSize(label)
            let position = Vector2D(labelCenter.x - (size.x / 2), labelCenter.y + size.y)

            context.setColor(style.secondaryLabelStyle.color)
            context.showText(label, at: position)
        }

        if let colorName = block.accentColorName {
            let color = style.adaptableColor(colorName, default: .white)
            let swatchOrigin = swatchCenter - (Self.ColorSwatchSize / 2.0)
            context.setColor(color)
            context.fillRect(origin: swatchOrigin, size: Self.ColorSwatchSize)
        }
        
    }
    
    func drawConnectors(_ context: DrawingContext) {
        let selection: Selection? = world.singleton()

        for (runtimeID, component) in world.query(DiagramConnectorGeometry.self) {
            if let objectID = world.entityToObject(runtimeID) {
                let isSelected = selection?.contains(objectID) ?? false
                drawConnector(context, runtimeID: runtimeID, geometry: component, isSelected: isSelected, isIntent: false)
            }
            else if world.hasComponent(ConnectorIntent.self, for: runtimeID) {
                drawConnector(context, runtimeID: runtimeID, geometry: component, isSelected: false, isIntent: true)
            }
        }
    }
    
    func drawConnector(_ context: DrawingContext, runtimeID: RuntimeID, geometry: DiagramConnectorGeometry, isSelected: Bool, isIntent: Bool) {
        let transform = toScreenTransform()
        // DEBUG wire
        if isSelected {
            context.setColor(Color(red: 1.0, green: 0.5, blue: 0.0))
            context.setLineWidth(4)
            context.strokePath(geometry.wire, transform: transform)
        }

        // Open curves
        // TODO: Use colors from CanvasStyle.connectorColors
        context.setColor(style.defaultConnectorColor)
        if let path = geometry.linePath {
            context.addPath(path, transform: transform)
        }
        if let path = geometry.headArrowhead {
            context.addPath(path, transform: transform)
        }
        if let path = geometry.tailArrowhead {
            context.addPath(path, transform: transform)
        }
        context.stroke()
        // Filled curves
        if let path = geometry.fillPath {
            context.setColor(style.defaultConnectorColor)
            // TODO: ImGui can not draw correctly concave polygons (they are expensive)
            context.fillPath(path, transform: transform)
        }
    }

    func drawGrid(_ context: DrawingContext) {
        guard showGrid else { return }
        
        // Calculate visible area in world coordinates
        let worldTopLeft: Vector2D = screenToWorld(canvasPos)
        let screenBottomRight = canvasPos + canvasSize
        let worldBottomRight: Vector2D = screenToWorld(screenBottomRight)
        
        // Draw vertical grid lines
        let startX = floor(worldTopLeft.x / gridSize) * gridSize
        let endX = ceil(worldBottomRight.x / gridSize) * gridSize
        
        context.setColor(style.gridColor)
        
        for x in stride(from: startX, through: endX, by: gridSize) {
            let screenX = (x - viewOffset.x) * zoomLevel + Double(canvasPos.x)
            let p1 = Vector2D(screenX, Double(canvasPos.y))
            let p2 = Vector2D(screenX, Double(canvasPos.y + canvasSize.y))
            
            context.addLine(from: p1, to: p2)
        }
        
        // Draw horizontal grid lines
        let startY = floor(worldTopLeft.y / gridSize) * gridSize
        let endY = ceil(worldBottomRight.y / gridSize) * gridSize
        
        for y in stride(from: startY, through: endY, by: gridSize) {
            let screenY = ((y - viewOffset.y) * zoomLevel) + Double(canvasPos.y)
            let p1 = Vector2D(Double(canvasPos.x), screenY)
            let p2 = Vector2D(Double(canvasPos.x + canvasSize.x), screenY)
            
            context.addLine(from: p1, to: p2)
        }
        context.stroke()
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
