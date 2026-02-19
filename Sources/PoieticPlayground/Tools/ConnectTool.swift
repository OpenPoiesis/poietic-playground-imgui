//
//  ConnectTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming
import PoieticCore

// TODO: This tool is mostly hard-coded to the stock-flow metamodel

class ConnectTool: CanvasTool {
    // TODO: Implement the tool (empty stub for now)
    override var name: String { "connect"}
    override var iconKey: IconKey { .connect }
    override var hasObjectPalette: Bool { true }

    enum State {
        case idle
        case connecting
    }

    var state: State = .idle
    var checker: ConstraintChecker? = nil  // TODO: Not the best location for this
    var intendedConnector: RuntimeEntity? = nil
    
    var palette: ObjectPalette? = nil

    override func activate() {
        guard let session,
              let notation: Notation = session.world.singleton()
        else { return }

        self.checker = ConstraintChecker(session.design.metamodel)
        
        var items: [PaletteItem] = []
        
        for type in connectableTypes() {
            var texture: TextureHandle? = nil
            switch type.name {
            case "Parameter":
                texture = InterfaceStyle.current.texture(forIcon: .arrowParameter)
            case "Flow":
                texture = InterfaceStyle.current.texture(forIcon: .arrowOutlined)
            default:
                texture = nil
            }
            guard let texture else {
                print("NO TEXTURE FOR: \(type.name)")
                continue
            }
            let item = PaletteItem(identifier: type.name, image: .texture(texture), label: type.label)
            items.append(item)
        }

        self.palette = ObjectPalette(columns: 2, items: items)

    }
    
    override func drawPalette() {
        guard let palette else { return }
        palette.draw()
    }
    
    func connectableTypes() -> [ObjectType] {
        // TODO: Read from metamodel
        // TODO: Use connector glyphs and make the object palette single column and wide
        return [ObjectType.Parameter, ObjectType.Flow]
    }
    
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
        createDragConnector(type: .Parameter,
                            origin: target.runtimeID,
                            targetPoint: worldPosition,
                            targetID: nil,
                            targetAllowed: true)
        self.state = .connecting
    }
    func dragMove(_ event: ToolEvent) {
        guard let canvas,
              state == .connecting,
              let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component()
        else { return }
        
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let targetID: RuntimeID?
        let targetAllowed: Bool

        if let target = canvas.hitTarget(screenPosition: event.screenPos),
           let targetObjectID = canvas.world.entityToObject(target.runtimeID)
        {
            targetID = target.runtimeID
            targetAllowed = canConnect(type: intent.type, from: intent.originID, to: target.runtimeID)
        }
        else {
            targetID = nil
            targetAllowed = true
        }
        
        updateDragConnector(targetPoint: worldPosition,
                            targetID: targetID,
                            targetAllowed: targetAllowed)
    }

    func dragEnd(_ event: ToolEvent) {
        guard let intendedConnector,
              let canvas,
              let intent: ConnectorIntent = intendedConnector.component()
        else { return }
        defer {
            self.state = .idle
            removeDragConnector()
        }
        
        guard let target = canvas.hitTarget(screenPosition: event.screenPos) else {
            return
        }
        print("Drag concluded with: \(target)")
    }
    func dragCancel(_ event: ToolEvent) {
        self.state = .idle
        removeDragConnector()
    }

    func canConnect(type: ObjectType, from originID: RuntimeID, to targetID: RuntimeID) -> Bool {
        guard let session,
              let checker,
              let frame = session.world.frame,
              let originObjectID = session.world.entityToObject(originID),
              let targetObjectID = session.world.entityToObject(targetID)
        else { return false }
        
        return checker.canConnect(type: type, from: originObjectID, to: targetObjectID, in: frame)
    }

    func createDragConnector(type: ObjectType,
                                    origin originID: RuntimeID,
                                    targetPoint: Vector2D,
                                    targetID: RuntimeID?,
                                    targetAllowed: Bool)
    {
        guard let world = session?.world,
              let block: DiagramBlock = world.component(for:originID)
        else { return }
        print("Creating drag connector of type \(type), origin: \(originID)")
        // FIXME: XXXXXXX USE OBJECT PALETTE XXXXXXXXXX

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        let originTouch = Geometry.touchPoint(shape: block.collisionShape.shape,
                                              position: block.position + block.collisionShape.position,
                                              from: targetPoint,
                                              towards: block.position)
        // FIXME: [IMPORTANT] Use NotationRules
        let glyph = notation.connectorGlyph(type.name)

        let geometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                targetTouch: targetPoint,
                                                glyph: glyph)

        let intent = ConnectorIntent(type: type,
                                     originID: originID,
                                     glyph: glyph,
                                     targetID: targetID,
                                     targetAllowed: targetAllowed)
        let connector: RuntimeEntity = world.spawn(geometry, intent)
        self.intendedConnector = connector
    }
    
    func updateDragConnector(targetPoint: Vector2D, targetID: RuntimeID?, targetAllowed: Bool) {
        // TODO: Set color
        // TODO: Change color based on rules (we don't have way for coloring intents yet)
        // TODO: Snap to target block
        print("Update drag connector...")
        guard let world = session?.world,
              let canvas,
              let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component(),
              let geometry: DiagramConnectorGeometry = intendedConnector.component(),
              let block: DiagramBlock = world.component(for:intent.originID)
        else { return }
        print("... drag origin: \(intent.originID)")

        // FIXME: XXXXXXX USE OBJECT PALETTE XXXXXXXXXX
        
        let originTouch = Geometry.touchPoint(shape: block.collisionShape.shape,
                                              position: block.position + block.collisionShape.position,
                                              from: targetPoint,
                                              towards: block.position)

        let newGeometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                   targetTouch: targetPoint,
                                                   glyph: intent.glyph)
        let newIntent = ConnectorIntent(type: intent.type,
                                        originID: intent.originID,
                                        glyph: intent.glyph,
                                        targetID: targetID,
                                        targetAllowed: targetAllowed)

        intendedConnector.setComponent(newGeometry)
        intendedConnector.setComponent(newIntent)
        
        if let oldTargetID = intent.targetID,
           let entity = world.entity(oldTargetID)
        {
            entity.removeComponent(TargetHighlight.self)
        }
        if let targetID,
           let entity = world.entity(targetID)
        {
            let highlight: TargetHighlight = targetAllowed ? .accepting : .notAllowed
            entity.setComponent(highlight)
        }
    }
    
    func removeDragConnector() {
        guard let world = session?.world,
              let intendedConnector
        else { return }
        world.despawn(intendedConnector.runtimeID)
        self.intendedConnector = nil
        if let intent: ConnectorIntent = intendedConnector.component(),
           let targetID = intent.targetID,
           let target = world.entity(targetID)
        {
            target.removeComponent(TargetHighlight.self)
        }
    }
}
