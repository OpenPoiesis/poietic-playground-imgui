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
    static let HandleSize: Double = 15.0
    static let PrimaryLabelPadding: Double = 0.0
    static let SecondaryLabelPadding: Double = 4.0
    static let ColorSwatchSize: Vector2D = Vector2D(10.0, 10.0)

    func drawMainOverlay(_ context: DrawingContext) {
//        context.setColor(style.background)
//        cairo_set_antialias(cairoContext, CAIRO_ANTIALIAS_DEFAULT)
        drawGrid(context)
        drawBlocks(context)
        drawConnectors(context)
        drawIntents(context)
        drawHandles(context)
    }
    
    func drawHandles(_ context: DrawingContext) {
        context.save()
        let radius = Self.HandleSize / 2

        for (_, handle) in world.query(CanvasHandle.self) {
            context.setColor(style.handleColor)
            let screenPos = toOverlayTransform.apply(to: handle.position)
            context.addCircle(center: screenPos, radius: radius)
            context.stroke()
        }
        context.restore()
    }
    
    func drawIntents(_ context: DrawingContext) {
        for (runtimeID, component) in world.query(BlockIntent.self) {
            drawBlockIntent(context, runtimeID: runtimeID, block: component)
        }
    }
    
    func drawBlocks(_ context: DrawingContext) {
        context.save()
        let selection: Selection? = world.singleton()
        
        for (runtimeID, component) in world.query(DiagramBlock.self) {
            guard let objectID = world.entityToObject(runtimeID) else { continue }

            let isSelected = selection?.contains(objectID) ?? false
            drawBlock(context, runtimeID: runtimeID, isSelected: isSelected, block: component)
        }
        context.restore()
    }

    func drawBlockIntent(_ context: DrawingContext, runtimeID: RuntimeID, block: BlockIntent) {
        let transform = toOverlayTransform.translated(block.position)
        context.save()
        context.setColor(style.intentShadowColor)
        context.addPath(block.pictogram.path, transform: transform)
        context.stroke()
        context.restore()
    }

    func drawBlock(_ context: DrawingContext, runtimeID: RuntimeID, isSelected: Bool, block: DiagramBlock) {
        let blockPosition: Vector2D
        
        if let preview: BlockPreview = world.component(for: runtimeID) {
            blockPosition = preview.position
        }
        else {
            blockPosition = block.position
        }
        
        let blockTrans = toOverlayTransform.translated(blockPosition)
        let blockSurfacePos = blockTrans.apply(to: blockPosition)
        var swatchCenter: Vector2D
        var labelCenter: Vector2D
        
        if let pictogram = block.pictogram {

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
            
            let screenBBMin = toOverlayTransform.apply(to: pictogram.pathBoundingBox.topLeft + blockPosition)
            labelCenter = Vector2D(blockSurfacePos.x, screenBBMin.y)
        }
        else {
            labelCenter = blockSurfacePos
        }

        swatchCenter = labelCenter
        labelCenter.y += Self.PrimaryLabelPadding
      
        if let label = block.label {
            context.setFontSize(style.primaryLabelStyle.fontSize)
            let te = context.textExtents(label)
            let position = Vector2D(labelCenter.x - (te.width / 2) - te.x_bearing,
                                    labelCenter.y + (te.height) - te.y_bearing)

            context.setColor(style.primaryLabelStyle.color)
            context.showText(label, at: position)

            labelCenter.y = position.y + Self.SecondaryLabelPadding
            swatchCenter = Vector2D(position.x - Self.ColorSwatchSize.x, position.y - te.height/2)
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
        context.save()
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
        context.restore()
    }
    
    func drawConnector(_ context: DrawingContext, runtimeID: RuntimeID, geometry: DiagramConnectorGeometry, isSelected: Bool, isIntent: Bool) {
        let transform = toOverlayTransform

        // Open curves
        // TODO: Use colors from CanvasStyle.connectorColors
        context.setLineWidth(style.defaultConnectorLineWidth)
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

        // DEBUG wire
        if isSelected {
            context.save()
            context.setColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            context.setLineWidth(4)
            context.strokePath(geometry.wire, transform: transform)

            context.setColor(Color(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.5))
            let outline = geometry.outline(inflatedBy: 10)
            context.fillPath(outline, transform: transform)

            context.restore()
        }
    }

    func drawGrid(_ context: DrawingContext) {
        guard showGrid else { return }
        context.save()
        
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
        context.restore()
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
