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
    // TODO: Implement the tool (empty stub for now)
    override var name: String { "placement"}
    override var hasObjectPalette: Bool { true }
    override var iconKey: IconKey { .place }
    
    var palette: ObjectPalette? = nil

    var intentShadow: RuntimeEntity? = nil
    
    override func activate() {
        guard let document,
              let notation: Notation = document.world.singleton()
        else { return }
        
        var items: [PaletteItem] = []
        
        for type in placeableBlockTypes() {
            let pictogram = notation.pictogram(type.name)
            let item = PaletteItem(identifier: type.name, image: .pictogram(pictogram), label: type.label)
            items.append(item)
        }

        self.palette = ObjectPalette(columns: 3, items: items)
    }
    
    override func deactivate() {
        removeIntentShadow()
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
            $0.hasTrait(.DiagramBlock)
        }
        return types
    }
    
    func createIntentShadow(position: Vector2D, typeName: String) {
        guard let document,
              let notation: Notation = world.singleton(),
              let type = document.design.metamodel.objectType(name: typeName)
        else { return }
        let world = document.world
        let pictogram = notation.pictogram(type.name)

        if intentShadow != nil {
            removeIntentShadow()
        }
        let component = BlockIntent(type: type, position: position, pictogram: pictogram)
        self.intentShadow = world.spawn(component)
    }
    
    func removeIntentShadow() {
        guard let intentShadow else { return }
        document?.world.despawn(intentShadow)
        self.intentShadow = nil
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
        removeIntentShadow()
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        createIntentShadow(position: worldPos, typeName: typeName)
        document?.requiresInteractivePreviewUpdate = true
        return .pass
    }
    
    func pointerMove(_ event: ToolEvent) -> EngagementResult {
        guard let canvas,
              let intentShadow
        else { return .pass }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        if var component: BlockIntent = intentShadow.component() {
            component.position = worldPos
            intentShadow.setComponent(component)
        }
        else if let typeName = palette?.selectedIdentifier {
            createIntentShadow(position: worldPos, typeName: typeName)
        }
        document?.requiresInteractivePreviewUpdate = true
        return .pass
    }
    
    func hoverEnd(_ event: ToolEvent) -> EngagementResult {
        removeIntentShadow()
        document?.requiresInteractivePreviewUpdate = true
        return .pass
    }
    func pointerUp(_ event: ToolEvent)  -> EngagementResult {
        guard let document,
              let canvas,
              let intentShadow,
              let shadow: BlockIntent = intentShadow.component()
        else { return .pass }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)

        print("Placing \(shadow.type.name) at \(worldPos)")
        if let objectID = placeObject(type: shadow.type, at: worldPos) {
            document.queueCommand(SwitchToolCommand("selection"))
            document.changeSelection(.replaceAllWithOne(objectID))
        }
        document.requiresInteractivePreviewUpdate = true
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
