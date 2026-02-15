//
//  ConnectTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming
import PoieticCore

class ConnectTool: CanvasTool {
    // TODO: Implement the tool (empty stub for now)
    override var name: String { "connect"}
    override var iconName: String { "connect"}
    
    enum State {
        case idle
        case connecting
    }

    var state: State = .idle
    var intendedConnectorID: RuntimeID? = nil
    var originID: RuntimeID? = nil
    override func handleEvent(_ event: ToolEvent) {
        switch event.type {
        case .dragStart: self.dragStart(event)
        case .dragMove: self.dragMove(event)
        case .dragEnd: self.dragEnd(event)
        case .dragCancel: self.dragCancel(event)
        default: break
        }
    }

    func dragStart(_ event: ToolEvent) {
        guard let canvas,
              let session,
              let target = canvas.hitTarget(screenPosition: event.screenPos),
              let objectID = world.entityToObject(target.runtimeID),
              let object = world.frame?[objectID]
        else {
            state = .idle
            return
        }
        
        // TODO: Have a better method for bl
//        guard object.structure.type ==
        
//        print("Connect start at: \(objectID)")
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        createDragConnector(type: "Parameter", origin: target.runtimeID, targetPoint: worldPosition)

    }
    func dragMove(_ event: ToolEvent) {
        guard let canvas,
              state == .connecting
        else { return }
        
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        updateDragConnector(targetPoint: worldPosition)
    }

    func dragEnd(_ event: ToolEvent) {
        removeDragConnector()
    }
    func dragCancel(_ event: ToolEvent) {
        removeDragConnector()
    }

    public func createDragConnector(type: String,
                                    origin originID: RuntimeID,
                                    targetPoint: Vector2D)
    {
        guard let world = session?.world,
              let block: DiagramBlock = world.component(for:originID)
        else { return }

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        let originTouch = Geometry.touchPoint(shape: block.collisionShape.shape,
                                              position: block.position + block.collisionShape.position,
                                              from: targetPoint,
                                              towards: block.position)
        let glyph = notation.connectorGlyph(type)

        let geometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                targetTouch: targetPoint,
                                                glyph: glyph)

        let intent = ConnectorIntent(originID: originID, glyph: glyph)
        let connectorID = world.spawn(geometry, intent)
        self.intendedConnectorID = connectorID
        self.originID = originID
    }
    
    public func updateDragConnector(targetPoint: Vector2D) {
        // TODO: Set color
        // TODO: Change color based on rules (we don't have way for coloring intents yet)
        // TODO: Snap to target block
        guard let world = session?.world,
              let canvas,
              let originID,
              let block: DiagramBlock = world.component(for:originID),
              let intendedConnectorID,
              let geometry: DiagramConnectorGeometry = world.component(for: intendedConnectorID),
              let intent: ConnectorIntent = world.component(for: intendedConnectorID)
        else { return }

        let originTouch = Geometry.touchPoint(shape: block.collisionShape.shape,
                                              position: block.position + block.collisionShape.position,
                                              from: targetPoint,
                                              towards: block.position)

        let newGeometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                   targetTouch: targetPoint,
                                                   glyph: intent.glyph)

        world.setComponent(newGeometry, for: intendedConnectorID)
    }
    
    func removeDragConnector() {
        guard let world = session?.world,
              let intendedConnectorID
        else { return }
        world.despawn(intendedConnectorID)
        self.intendedConnectorID = nil
        self.originID = nil
    }

    
}

struct ConnectorIntent: Component {
    let originID: RuntimeID
    let glyph: ConnectorGlyph
}
