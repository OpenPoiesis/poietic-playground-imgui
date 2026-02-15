//
//  PlacementTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

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
    
    override func activate() {
        let pictograms = placeablePictograms()
        let items = pictograms.map { pictogram in
            PaletteItem(pictogram: pictogram, label: pictogram.name)
        }
        self.palette = ObjectPalette(columns: 3, items: items)
    }
    override func drawPalette() {
        guard let palette else { return }
        palette.draw()
    }
    
    func placeablePictograms() -> [Pictogram] {
        guard let session,
              let notation: Notation = session.world.singleton()
        else {
            return []
        }
        let types = session.design.metamodel.types.filter {
            $0.hasTrait(.DiagramBlock)
        }
        
        let pictograms = types.map { type in
            notation.pictogram(type.name)
        }
        return pictograms
    }

}
