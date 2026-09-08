//
//  ConnectTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming
import PoieticCore
import PoieticFlows

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
    /// Invisible scene node to serve as a connector target.
    ///
    /// Required to make connector intent valid so that we can compute connector geometry.
    var connectorHandle: RuntimeEntity? = nil
    
    var palette: ObjectPalette? = nil

    override func activate() {
        guard let document,
              let notation: Notation = document.world.singleton()
        else { return }

        document.changeSelection(.removeAll)
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

    override func deactivate() {
        removeDragConnector()
        document?.endInteractivePreview()
    }

    override func drawPalette() {
        guard let palette else { return }
        palette.draw()
    }
    
    func connectableTypes() -> [ObjectType] {
        // TODO: Read from metamodel
        // TODO: Use connector glyphs and make the object palette single column and wide
        return [StockFlowDomain.Types.Parameter, StockFlowDomain.Types.Flow]
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
              let scene = canvas.scene,
              let hitTarget = canvas.hitTarget(screenPosition: event.screenPos),
              world.contains(hitTarget.sceneNode),
              case .object(let originID, _) = hitTarget.kind,
              let typeName = palette?.selectedIdentifier,
              let type = document.design.metamodel.objectType(name: typeName)
        else {
            state = .idle
            return .pass
        }
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)
        
        // Clean-up, just to be safe
        self.removeDragConnector()

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        // TODO: Use notation rules
        // let rules: NotationRules = world.singleton() ?? NotationRules()
        let glyph = notation.connectorGlyph(type.name)

        // -- Handle --
        let handle = world.spawn(
            SceneNode(),
            PositionComponent(position: scenePosition)
        )
        handle.relate(ChildOf(), to: scene)
        self.connectorHandle = handle
        
        // -- Connector --
        let connector = world.spawn(
            SceneNode(),
            ConnectorSceneNode(),
            glyph,
            ConnectorIntent(type:type),
            CanvasNodeStyle(class: .connector, modifiers: .preview),
            DirtyContent.geometry,
        )
        connector.relate(ChildOf(), to: scene)
        connector.relate(MemberOf(), to: scene)
        connector.relate(ConnectorSceneNode.Origin(),to: hitTarget.sceneNode)
        connector.relate(ConnectorSceneNode.Target(),to: handle)

        self.intendedConnector = connector

        // -- Begin preview --
        document.beginInteractivePreview()

        self.state = .connecting
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EngagementResult {
        guard state == .connecting,
              let canvas,
              let document,
              let intendedConnector,
              let connectorHandle,
              let intent: ConnectorIntent = intendedConnector.component(),
              let originSceneNode = intendedConnector.target(ConnectorSceneNode.Origin.self)
        else { return .pass}
        
        // -- Handle --
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)

        connectorHandle.setComponent(PositionComponent(position: scenePosition))
        connectorHandle.setComponent(DirtyContent.geometry)
        intendedConnector.setComponent(DirtyContent.geometry)

        // -- Connector Intent --
        let newTargetID: RuntimeID?

        if let target = canvas.hitTarget(screenPosition: event.screenPos),
           case .object(_, .body) = target.kind,
           isValidTarget(target.sceneNode)
        {
            newTargetID = target.sceneNode
        }
        else {
            newTargetID = nil
        }

        let oldTarget: RuntimeEntity? = intendedConnector.target(ConnectorSceneNode.Target.self)
        if let newTargetID {
            intendedConnector.relate(ConnectorSceneNode.Target(), to: newTargetID)
        }
        else {
            intendedConnector.relate(ConnectorSceneNode.Target(), to: connectorHandle)
        }

        if let oldTarget {
            oldTarget.modify(CanvasNodeStyle.self) {
                $0.modifiers.subtract(.allowedMask)
            }
        }

        if let newTargetID,
           let newTarget = world.entity(newTargetID)
        {
            let targetAllowed = canConnect(type: intent.type)
            newTarget.modify(CanvasNodeStyle.self) {
                if targetAllowed {
                    $0.modifiers.insert(.allowed)
                    $0.modifiers.remove(.notAllowed)
                }
                else {
                    $0.modifiers.remove(.allowed)
                    $0.modifiers.insert(.notAllowed)
                }
            }
        }

        document.queueInteractivePreviewUpdate()
        return .engaged
    }

    func updateIntent() {
        guard let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component()
        else { return }
        
    }
    
    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        defer {
            self.state = .idle
            removeDragConnector()
            document?.endInteractivePreview()
        }

        guard let intendedConnector,
              let canvas,
              let intent: ConnectorIntent = intendedConnector.component(),
              let origin: RuntimeEntity = intendedConnector.target(ConnectorSceneNode.Origin.self),
              let hitTarget = canvas.hitTarget(screenPosition: event.screenPos),
              case .object(let targetID, _) = hitTarget.kind
        else { return .pass }
        
        if canConnect(type: intent.type) {
            createConnection(type: intent.type, from: origin.runtimeID, to: targetID)
        }

        print("Drag concluded.")
        return .consumed
    }
    
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        self.state = .idle
        removeDragConnector()
        document?.endInteractivePreview()
        return .consumed
    }

    /// Returns true whether given entity is a valid connector target – a block.
    ///
    /// - Note: This is a different flag from being allowed or not. Target can be valid (a block)
    ///   but can still be not allowed. Invalid target is another connector for example.
    ///
    func isValidTarget(_ runtimeID: RuntimeID) -> Bool {
        guard let entity = world.entity(runtimeID)
        else { return false }
        
        return entity.contains(BlockSceneNode.self)
    }
    
    func representedObjectsOfIntent() -> (origin: ObjectID, target: ObjectID)? {
        guard let intent = self.intendedConnector,
              let originSceneNode: RuntimeEntity = intent.target(ConnectorSceneNode.Origin.self),
              let origin = originSceneNode.target(RepresentationOf.self),
              let originID = origin.objectID,
              let targetSceneNode: RuntimeEntity = intent.target(ConnectorSceneNode.Target.self),
              let target = targetSceneNode.target(RepresentationOf.self),
              let targetID = target.objectID
        else {
            return nil
        }
        return (origin: originID, target: targetID)
    }
    
    func canConnect(type: ObjectType) -> Bool
    {
        guard let document,
              let checker,
              let plane = document.world.plane,
              let (originObjectID, targetObjectID) = representedObjectsOfIntent()
        else { return false }
        
        return checker.canConnect(type: type, from: originObjectID, to: targetObjectID, in: plane)
    }
    func createConnection(type: ObjectType, from originRuntimeID: RuntimeID, to targetRuntimeID: RuntimeID) {
        guard let document,
              let (originObjectID, targetObjectID) = representedObjectsOfIntent()
        else { return }
        let trans = document.createOrReuseTransaction()
        trans.createEdge(type, origin: originObjectID, target: targetObjectID)
    }

    func removeDragConnector() {
        if let intendedConnector {
            if let target: RuntimeEntity = intendedConnector.target(ConnectorSceneNode.Target.self) {
                target.modify(CanvasNodeStyle.self) {
                    $0.modifiers.subtract(.allowedMask)
                }
            }
            intendedConnector.despawn()
            self.intendedConnector = nil
        }
        if let connectorHandle {
            connectorHandle.despawn()
            self.connectorHandle = nil
        }
    }
    
}
