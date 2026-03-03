//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

// TODO: [IMPORTANT] This whole file contains early prototype of all canvas drawing and needs to be split.

import CIimgui
import Ccairo
import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

/// Name of a pictogram for error indicators.
let ErrorPictogramName: String = "Error"

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
    func drawIndicatorOverlay(_ context: DrawingContext) {
        drawIssueIndicators(context)
        drawValueIndicators(context)
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
        for component: BlockIntent in world.query(BlockIntent.self) {
            drawBlockIntent(context, block: component)
        }
    }
    
    func drawBlocks(_ context: DrawingContext) {
        context.save()
        let selection: Selection? = world.singleton()
        
        for (entity, component) in world.query(DiagramBlock.self) {
            guard let objectID = world.entityToObject(entity.runtimeID) else { continue }

            let isSelected = selection?.contains(objectID) ?? false
            drawBlock(context, entity: entity, isSelected: isSelected, block: component)
        }
        context.restore()
    }

    func drawBlockIntent(_ context: DrawingContext, block: BlockIntent) {
        let transform = toOverlayTransform.translated(block.position)
        context.save()
        context.setColor(style.intentShadowColor)
        context.addPath(block.pictogram.path, transform: transform)
        context.stroke()
        context.restore()
    }

    func drawIssueIndicators(_ context: DrawingContext) {
        guard let session,
              let notation: Notation = session.world.singleton()
        else { return }
        
        let errorPictogram = notation.pictogram(ErrorPictogramName)
        
        for (objectID, _) in session.world.issues {
            // TODO: Add number of issues
            guard let entity = session.world.entity(objectID) else { continue }
            
            if let block: DiagramBlock = entity.component() {
                let position: Vector2D
                if let preview: BlockPreview = entity.component() {
                    position = preview.position + block.errorIndicatorAnchorOffset
                }
                else {
                    position = block.position + block.errorIndicatorAnchorOffset
                }
                drawIndicator(context,
                              pictogram: errorPictogram,
                              at: position)
            }
        }
    }

    func drawIndicator(_ context: DrawingContext, pictogram: Pictogram, at anchor: Vector2D) {
        let height = pictogram.maskBoundingBox.height
        let position = Vector2D(anchor.x, anchor.y - (height / 2))
        let trans = toOverlayTransform.translated(position)
        
        context.setColor(style.errorIndicatorBackground)
        context.addPath(pictogram.mask, transform: trans)
        context.fill()

        context.setColor(style.errorIndicatorColor)
        context.addPath(pictogram.path, transform: trans)
        context.stroke()

        context.addPath(pictogram.mask, transform: trans)
        context.stroke()

    }
    
    
    func drawBlock(_ context: DrawingContext, entity: RuntimeEntity, isSelected: Bool, block: DiagramBlock) {
        let blockPosition: Vector2D
        
        if let preview: BlockPreview = entity.component() {
            blockPosition = preview.position
        }
        else {
            blockPosition = block.position
        }
        
        let blockTrans = toOverlayTransform.translated(blockPosition)
        let blockSurfacePos = toOverlayTransform.apply(to: blockPosition)
        var swatchCenter: Vector2D
        var labelCenter: Vector2D
        
        if let pictogram = block.pictogram {

            if isSelected {
                context.setColor(style.selectionFillColor)
                context.fillPath(pictogram.mask, transform: blockTrans)
                context.setColor(style.selectionOutlineColor)
                context.strokePath(pictogram.mask, transform: blockTrans)
            }
            
            if let highlight: TargetHighlight = entity.component() {
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
        for (entity, component) in world.query(DiagramConnectorGeometry.self) {
            if let objectID = entity.objectID {
                let isSelected = selection?.contains(objectID) ?? false
                drawConnector(context, geometry: component, isSelected: isSelected, isIntent: false)
            }
            else if entity.contains(ConnectorIntent.self) {
                drawConnector(context, geometry: component, isSelected: false, isIntent: true)
            }
        }
        context.restore()
    }
    
    func drawConnector(_ context: DrawingContext, geometry: DiagramConnectorGeometry, isSelected: Bool, isIntent: Bool) {
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
        let worldViewSize = (Vector2D(canvasSize) / zoomLevel)
        let worldTopLeft = viewOffset
        let worldBottomRight = viewOffset + worldViewSize
        
        // Draw vertical grid lines
        let startX = floor(worldTopLeft.x / gridSize) * gridSize
        let endX = ceil(worldBottomRight.x / gridSize) * gridSize
        
        context.setColor(style.gridColor)
        context.setLineWidth(0.5)
        
        for x in stride(from: startX, through: endX, by: gridSize) {
            let screenX = (x - viewOffset.x) * zoomLevel
            let p1 = Vector2D(screenX, 0)
            let p2 = Vector2D(screenX, Double(canvasSize.y))
            
            context.addLine(from: p1, to: p2)
        }
        
        // Draw horizontal grid lines
        let startY = floor(worldTopLeft.y / gridSize) * gridSize
        let endY = ceil(worldBottomRight.y / gridSize) * gridSize
        
        for y in stride(from: startY, through: endY, by: gridSize) {
            let screenY = (y - viewOffset.y) * zoomLevel
            let p1 = Vector2D(0, screenY)
            let p2 = Vector2D(Double(canvasSize.x), screenY)
            
            context.addLine(from: p1, to: p2)
        }
        context.stroke()
        context.restore()
    }
    
    func drawValueIndicators(_ context: DrawingContext) {
        // TODO: Implement proper "indicator trait"
        context.save()
        
        for (entity, component) in world.query(DiagramBlock.self) {
            guard let objectID = world.entityToObject(entity.runtimeID) else { continue }

            drawValueIndicator(context, entity: entity, block: component)
        }
        context.restore()

    }
    func drawValueIndicator(_ context: DrawingContext, entity: RuntimeEntity, block: DiagramBlock) {
        // TODO: Make relevant data per-entity components
        // Assumption: result reflects plan
        guard let result: SimulationResult = world.singleton(),
              let plan: SimulationPlan = world.singleton(),
              let objectID: ObjectID = entity.objectID,
              let simObject = plan.simulationObject(objectID)
        else { return }
        
        let step: Int
        if let time: SimulationReplayTime = world.singleton() {
            step = time.step
        }
        else {
            step = max(0, Int(plan.simulationSettings.steps) - 1)
        }
        
        guard let state = result[step] else { return }
        let value: Variant = state[simObject.variableIndex]
        guard let doubleValue = try? value.doubleValue() else { return }
        let indicatorLabel = doubleValue.formatted(.number.precision(.significantDigits(1...4)))
        
        let trans = toOverlayTransform.translated(block.position)
        let anchor = trans.apply(to: block.valueIndicatorAnchorOffset)
        
        context.setFontSize(style.valueIndicatorStyle.fontSize)
        let te = context.textExtents(indicatorLabel)
        let position = Vector2D(anchor.x - (te.width / 2) - te.x_bearing,
                                anchor.y - (te.height) - te.y_bearing)

        context.setColor(style.valueIndicatorStyle.color)
        context.showText(indicatorLabel, at: position)
    }
    
    func drawValueIndicatorBar(_ context: DrawingContext,
                               frame: Rect2D,
                               value: Double?,
                               bounds: ValueBounds,
                               orientation: Orientation) {
        let ValueIndicatorBarPadding: Double = 2.0
//        let fullRect = Rect2D(position: -rect.size / 2, size: rect.size)
        let rect = frame.grown(by: -ValueIndicatorBarPadding)
        let size = rect.size // Adjusted size by padding
        
        context.drawRect(frame, style: style.indicatorBackgroundStyle)

        guard let value else {
            context.drawRect(rect, style: style.indicatorEmptyStyle)
            return
        }
        
        let boundedValue: Double = bounds.clip(value)

        let shapeStyle = switch bounds.state(of: value) {
        case .overflow: style.indicatorOverflowStyle
        case .underflow: style.indicatorUnderflowStyle
        case .negative: style.indicatorNegativeStyle
        case .positive: style.indicatorNormalStyle
        }

        guard bounds.range.magnitude > Double.standardEpsilon else {
            context.drawRect(rect, style: shapeStyle)
            return
        }

        let valueBar: Rect2D
        let line: LineSegment
        
        switch orientation {
        case .horizontal:
            let scaledOrigin = bounds.normalizedBaseline * size.x
            let scaledValue = bounds.normalized(value) * size.x

            valueBar = Rect2D(x: rect.origin.x + scaledOrigin,
                              y: rect.origin.y,
                              width: scaledValue - scaledOrigin,
                              height: size.y)
            
            line = LineSegment(
                from: Vector2D(x: rect.origin.x + scaledOrigin, y: rect.origin.y),
                to: Vector2D(x: rect.origin.x + scaledOrigin, y: rect.origin.y + size.y)
            )

        case .vertical:
            let scaledOrigin = bounds.normalizedBaseline * size.y
            let scaledValue = bounds.normalized(value) * size.y

            valueBar = Rect2D(x: rect.origin.x,
                              y: rect.origin.y + scaledOrigin,
                              width: size.x,
                              height: scaledValue - scaledOrigin)

            line = LineSegment(
                from: Vector2D(x: rect.origin.x, y: rect.origin.y + scaledOrigin),
                to: Vector2D(x: rect.origin.x + size.x, y: rect.origin.y + scaledOrigin)
            )
        }
        context.drawRect(valueBar, style: shapeStyle)
        context.addLine(from: line.start, to: line.end)
    }
}
