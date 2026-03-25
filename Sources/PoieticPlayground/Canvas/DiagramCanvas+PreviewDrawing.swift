//
//  DiagramCanvas+PreviewDrawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/03/2026.
//

import CIimgui
import Ccairo
import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

extension DiagramCanvas {
    func onPreviewStarted(_ document: Document) {
        self.mainOverlay.setNeedsRender()
        self.previewOverlay.setNeedsRender()
    }

    func onInteractivePreviewChanged(_ document: Document) {
        previewOverlay.setNeedsRender()
    }
    
    func onPreviewEnded(_ document: Document) {
        self.mainOverlay.setNeedsRender()
        self.previewOverlay.setNeedsRender()
    }

    func drawPreviewOverlay(_ context: DrawingContext) {
        drawBlockIntents(context)
        drawIntentConnectors(context)

        drawPreviewBlocks(context)
        drawPreviewConnectors(context)
    }
    
    func drawBlockIntents(_ context: DrawingContext) {
        for component: BlockIntent in world.query(BlockIntent.self) {
            drawBlockIntent(context, block: component)
        }
    }
    
    func drawBlockIntent(_ context: DrawingContext, block: BlockIntent) {
        let transform = AffineTransform(translation: toOverlayTransform.apply(to: block.position))
        context.save()
        context.setColor(style.intentShadowColor)
        context.addPath(block.pictogram.path, transform: transform)
        context.stroke()
        context.restore()
    }

    func drawIntentConnectors(_ context: DrawingContext) {
        context.save()
        for (entity, _) in world.query(ConnectorIntent.self) {
            guard let geometry: DiagramConnectorGeometry = entity.component() else { continue }
            drawConnector(context, geometry: geometry, isSelected: false, isIntent: true)
        }
        context.restore()
    }
    
    func drawPreviewBlocks(_ context: DrawingContext) {
        print("DRAW PREVIEW BLOCKS")
        context.save()
        let selection: Selection? = world.singleton()
        
        for (entity, block, preview) in world.query(DiagramBlock.self, BlockPreview.self) {
            guard let objectID = world.entityToObject(entity.runtimeID) else { continue }

            let isSelected = selection?.contains(objectID) ?? false
            drawBlock(context, entity: entity, block: block, preview: preview, isSelected: isSelected)
        }
        context.restore()
    }
    
    func drawPreviewConnectors(_ context: DrawingContext) {
        context.save()
        let selection: Selection? = world.singleton()
        for (entity, component, _) in world.query(DiagramConnectorGeometry.self, ConnectorPreview.self) {
            guard let objectID = entity.objectID else { continue }
            let isSelected = selection?.contains(objectID) ?? false
            drawConnector(context, geometry: component, isSelected: isSelected)
        }
        context.restore()
    }


}
