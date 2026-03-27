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
        guard let document,
              let notation: Notation = document.world.singleton()
        else { return }

        self.checker = ConstraintChecker(document.design.metamodel)
        
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
    
    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        default: return .pass
        }
    }

    func dragStart(_ event: ToolEvent) -> EngagementResult{
        guard event.triggerButton == .left else { return .pass }
        guard let canvas,
              let document,
              let target = canvas.hitTarget(screenPosition: event.screenPos),
              case .object(let runtimeID, _) = target,
              let typeName = palette?.selectedIdentifier,
              let type = document.design.metamodel.objectType(name: typeName)
        else {
            state = .idle
            return .pass
        }
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        createDragConnector(type: type,
                            origin: runtimeID,
                            targetPoint: worldPosition,
                            targetID: nil,
                            targetAllowed: true)
        document.beginInteractivePreview()

        self.state = .connecting
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EngagementResult {
        guard let canvas,
              let document,
              state == .connecting,
              let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component()
        else { return .pass}
        
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let targetID: RuntimeID?
        let targetAllowed: Bool

        if let target = canvas.hitTarget(screenPosition: event.screenPos),
           case .object(let runtimeID, _) = target
        {
            targetID = runtimeID
            targetAllowed = canConnect(type: intent.type, from: intent.originID, to: runtimeID)
        }
        else {
            targetID = nil
            targetAllowed = true
        }
        
        updateDragConnector(targetPoint: worldPosition,
                            targetID: targetID,
                            targetAllowed: targetAllowed)
        document.queueInteractivePreviewUpdate()
        return .engaged
    }

    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        defer {
            self.state = .idle
            removeDragConnector()
        }

        guard let intendedConnector,
              let canvas,
              let document,
              let intent: ConnectorIntent = intendedConnector.component(),
              let target = canvas.hitTarget(screenPosition: event.screenPos),
              case .object(let runtimeID, _) = target
        else { return .pass }
        
        if canConnect(type: intent.type, from: intent.originID, to: runtimeID) {
            createConnection(type: intent.type, from: intent.originID, to: runtimeID)
        }

        document.endInteractivePreview()
        print("Drag concluded with: \(target)")
        return .consumed
    }
    
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        self.state = .idle
        removeDragConnector()
        document?.endInteractivePreview()
        return .consumed
    }

    func canConnect(type: ObjectType, from originID: RuntimeID, to targetID: RuntimeID) -> Bool {
        guard let document,
              let checker,
              let frame = document.world.frame,
              let originObjectID = document.world.entity(originID)?.objectID,
              let targetObjectID = document.world.entity(targetID)?.objectID
        else { return false }
        
        return checker.canConnect(type: type, from: originObjectID, to: targetObjectID, in: frame)
    }
    func createConnection(type: ObjectType, from originRuntimeID: RuntimeID, to targetRuntimeID: RuntimeID) {
        guard let document,
              let originObjectID = document.world.entity(originRuntimeID)?.objectID,
              let targetObjectID = document.world.entity(targetRuntimeID)?.objectID
        else { return }
        let trans = document.createOrReuseTransaction()
        trans.createEdge(type, origin: originObjectID, target: targetObjectID)
    }

    func createDragConnector(type: ObjectType,
                                    origin originID: RuntimeID,
                                    targetPoint: Vector2D,
                                    targetID: RuntimeID?,
                                    targetAllowed: Bool)
    {
        guard let world = document?.world,
              let originEntity = world.entity(originID),
              let block: DiagramBlock = originEntity.component()
        else { return }
        print("Creating drag connector of type \(type), origin: \(originID)")
        // FIXME: XXXXXXX USE OBJECT PALETTE XXXXXXXXXX

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        let originTouch = Geometry.touchPoint(shape: block.collisionShape.shape,
                                              position: block.position + block.collisionShape.position,
                                              from: targetPoint,
                                              towards: block.position)
        // TODO: [IMPORTANT] Use NotationRules
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
        guard let world = document?.world,
              let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component(),
              let originEntity = world.entity(intent.originID),
              let block: DiagramBlock = originEntity.component()
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
        guard let world = document?.world,
              let intendedConnector
        else { return }
        world.despawn(intendedConnector.runtimeID)
        self.intendedConnector = nil
        world.removeComponentForAll(TargetHighlight.self)
    }
    
}
