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
    override var iconName: String { "place"}
    
    var selectedItem: Int = 0
    var palette: ObjectPalette? = nil

    var intentShadowID: RuntimeID? = nil
    
    override func activate() {
        guard let session,
              let notation: Notation = session.world.singleton()
        else { return }
        
        var items: [PaletteItem] = []
        
        for type in placeableBlockTypes() {
            let pictogram = notation.pictogram(type.name)
            let item = PaletteItem(identifier: type.name, pictogram: pictogram, label: type.label)
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
        guard let session
        else {
            return []
        }
        let types = session.design.metamodel.types.filter {
            $0.hasTrait(.DiagramBlock)
        }
        return types
    }
    
    func createIntentShadow(position: Vector2D, typeName: String) {
        guard let session,
              let notation: Notation = world.singleton(),
              let type = session.design.metamodel.objectType(name: typeName)
        else { return }
        let world = session.world
        let pictogram = notation.pictogram(type.name)

        if intentShadowID != nil {
            removeIntentShadow()
        }
        let component = BlockIntentShadow(position: position, pictogram: pictogram, type: type)
        self.intentShadowID = world.spawn(component)
    }
    
    func removeIntentShadow() {
        guard let intentShadowID else { return }
        session?.world.despawn(intentShadowID)
        self.intentShadowID = nil
    }
    
    override func handleEvent(_ event: ToolEvent) {
        switch event.type {
        case .hoverStart: self.hoverStart(event)
        case .pointerMove: self.pointerMove(event)
        case .hoverEnd: self.hoverEnd(event)
        case .pointerUp: self.pointerUp(event)
        default: break
        }
    }
    func hoverStart(_ event: ToolEvent) {
        guard let world = session?.world,
              let canvas,
              let typeName = palette?.selectedIdentifier
        else { return }
        removeIntentShadow()
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        createIntentShadow(position: worldPos, typeName: typeName)
    }
    func pointerMove(_ event: ToolEvent) {
        guard let world = session?.world,
              let canvas,
              let intentShadowID
        else { return }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        if var component: BlockIntentShadow = world.component(for: intentShadowID) {
            component.position = worldPos
            world.setComponent(component, for: intentShadowID)
        }
        else if let typeName = palette?.selectedIdentifier {
            createIntentShadow(position: worldPos, typeName: typeName)
        }
    }
    func hoverEnd(_ event: ToolEvent) {
        removeIntentShadow()
    }
    func pointerUp(_ event: ToolEvent) {
        guard let world = session?.world,
              let canvas,
              let intentShadowID,
              let shadow: BlockIntentShadow = world.component(for: intentShadowID)
        else { return }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)

        print("Placing \(shadow.type.name) at \(worldPos)")
        placeObject(type: shadow.type, at: worldPos)
    }
    
    func placeObject(type: ObjectType, at position: Vector2D) {
        guard let session else { return }
        
        let trans = session.createOrReuseTransaction()
        
        let count = trans.filter(type: type).count
        let name = type.name.toSnakeCase() + String(count)

        let node = trans.createNode(type)
        node.position = position
        node["name"] = Variant(name)
    }
}

struct BlockIntentShadow: Component {
    var position: Vector2D
    let pictogram: Pictogram
    let type: ObjectType
}
