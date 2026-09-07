//
//  PlacementTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import CIimgui
import Diagramming

class PlacementTool: CanvasTool {
    static let IconSize: ImVec2 = ImVec2(60, 40)
    static let PaletteCellSize: ImVec2 = ImVec2(60, 60)
    override var name: String { "placement"}
    override var hasObjectPalette: Bool { true }
    override var iconKey: IconKey { .place }
    
    var palette: ObjectPalette? = nil

    var blockIntent: RuntimeEntity? = nil
    
    override func activate() {
        guard let document,
              let notation: Notation = document.world.singleton()
        else { return }
        
        document.changeSelection(.removeAll)
        var items: [PaletteItem] = []
        
        for type in placeableBlockTypes() {
            let pictogram = notation.pictogram(type.name)
            let item = PaletteItem(identifier: type.name, image: .pictogram(pictogram), label: type.label)
            items.append(item)
        }

        self.palette = ObjectPalette(columns: 3, items: items)
    }
    
    override func deactivate() {
        removeBlockIntent()
        document?.endInteractivePreview()
    }
    
    override func drawPalette() {
        guard let palette else { return }
        palette.draw()
    }
    
    func placeableBlockTypes() -> [ObjectType] {
        guard let document
        else {
            return []
        }
        let types = document.design.metamodel.types.filter {
            $0.hasTrait(DiagramDomain.Traits.DiagramBlock)
        }
        return types
    }
    
//    func OLDcreateBlockIntent(position: Vector2D, typeName: String) {
//        guard let document,
//              let notation: Notation = world.singleton(),
//              let type = document.design.metamodel.objectType(name: typeName)
//        else { return }
//        let world = document.world
//        let pictogram = notation.pictogram(type.name)
//
//        if blockIntent != nil {
//            removeIntentShadow()
//        }
//        let component = BlockIntent(type: type, position: position, pictogram: pictogram)
//        self.intentShadow = world.spawn(component)
//    }
    
    func createBlockIntent(position: Vector2D, typeName: String) {
        guard let document,
              let canvas,
              let scene = canvas.scene,
              let notation: Notation = world.singleton(),
              let type = document.design.metamodel.objectType(name: typeName)
        else { return }

        let scenePos = canvas.worldToScene(position)
                                                                                                                                                                                                                
        removeBlockIntent()
                                                                                                                                                                                                                
        let blockNode = world.spawn(
            BlockIntent(type: type),
            SceneNode(),
            BlockSceneNode(),
            PositionComponent(position: scenePos),
            CanvasNodeStyle(class: .block, modifiers: .preview),
            DirtyContent.geometry,
            Visibility.visible,
        )
        blockNode.relate(ChildOf(), to: scene)
        blockNode.relate(MemberOf(), to: scene)

        let pictogram = notation.pictogram(type.name)

        let pictogramNode = world.spawn(
            SceneNode(),
            PictogramSceneNode(pictogram: pictogram),
            PositionComponent(position: .zero),
            Visibility.visible,
        )
        pictogramNode.relate(ChildOf(), to: blockNode)
        blockNode.relate(SceneNode.Pictogram(), to: pictogramNode)


        self.blockIntent = blockNode
    }

    func removeBlockIntent() {
        guard let blockIntent else { return }
        document?.world.despawn(blockIntent)
        self.blockIntent = nil
    }
    
    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .hoverStart: return self.hoverStart(event)
        case .pointerMove: return self.pointerMove(event)
        case .hoverEnd: return self.hoverEnd(event)
        case .pointerUp: return self.pointerUp(event)
        default: return .pass
        }
    }
    func hoverStart(_ event: ToolEvent) -> EngagementResult {
        guard let canvas,
              let typeName = palette?.selectedIdentifier
        else { return .pass }
        removeBlockIntent()
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        createBlockIntent(position: worldPos, typeName: typeName)
        document?.beginInteractivePreview()
        document?.queueInteractivePreviewUpdate()
        return .pass
    }
    
    func pointerMove(_ event: ToolEvent) -> EngagementResult {
        guard let canvas,
              let blockIntent
        else { return .pass }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        let canvasPos: Vector2D = canvas.worldToScene(worldPos)

        blockIntent.setComponent(PositionComponent(position: canvasPos))
        blockIntent.setComponent(DirtyContent.geometry)
        
        document?.queueInteractivePreviewUpdate()
        return .pass
    }
    
    func hoverEnd(_ event: ToolEvent) -> EngagementResult {
        removeBlockIntent()
        document?.queueInteractivePreviewUpdate()
        return .pass
    }
    
    func pointerUp(_ event: ToolEvent)  -> EngagementResult {
        guard let document,
              let canvas,
              let blockIntent,
              let intent: BlockIntent = blockIntent.component()
        else { return .pass }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)

        print("Placing \(intent.type.name) at \(worldPos)")
        if let objectID = placeObject(type: intent.type, at: worldPos) {
            document.queueCommand(SwitchToolCommand("selection"))
            document.changeSelection(.replaceAllWithOne(objectID))
        }
        document.queueInteractivePreviewUpdate()
        document.endInteractivePreview()
        return .consumed
    }
    
    func placeObject(type: ObjectType, at position: Vector2D) -> ObjectID? {
        guard let document else { return nil }
        
        let trans = document.createOrReuseTransaction()
        
        let count = trans.filter(type: type).count
        let name = type.name.toSnakeCase() + String(count)

        let node = trans.createNode(type)
        node.position = position
        node["name"] = Variant(name)
        return node.objectID
    }
}
