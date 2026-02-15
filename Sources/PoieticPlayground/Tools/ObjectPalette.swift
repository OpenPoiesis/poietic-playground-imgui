//
//  ObjectPalette.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import CIimgui
import Diagramming

struct PaletteItem {
    // TODO: Use texture
    let identifier: String
    let pictogram: Pictogram
    let label: String
    
    func draw(cellOrigin: ImVec2, cellSize: ImVec2, isSelected: Bool) {
        let drawList = ImGui.GetWindowDrawList()
        let textSize = ImGui.CalcTextSize(label)

        let iconSize = ImVec2(cellSize.x, cellSize.y - textSize.y)
        let center = ImVec2(
            cellOrigin.x + cellSize.x / 2.0,           // Horizontal center of cell
            cellOrigin.y + iconSize.y / 2.0            // Vertical center of icon area
        )

        let textPos = ImVec2(
            center.x - (textSize.x / 2),
            center.y + cellSize.y - textSize.y - 10
        )

        drawList?.pointee.StrokePictogramIcon(pictogram,
                                              center: center,
                                              size: iconSize,
                                              color: .white,
                                              lineWidth: 1.0)

        let textColor = ImGui.GetStyleColor(ImGuiCol_Text)

        drawList?.pointee.AddText(textPos, textColor.imIntValue, label)
        // Debug
//        drawList?.pointee.AddCircle(center, 10, Color.screenYellow.imIntValue)
        
    }
}

class ObjectPalette {
    static let PaletteCellSize: ImVec2 = ImVec2(80, 40)
    let items: [PaletteItem]
    let columns: Int
    var selectedIndex: Int = 0
    
    init(columns: Int, items: [PaletteItem]) {
        self.columns = columns
        self.items = items
    }

    var selectedIdentifier: String? {
        guard !items.isEmpty,
              selectedIndex < items.count
        else { return nil }
        return items[selectedIndex].identifier
    }
    
    func draw() {
        let tableFlags = ImGuiTableFlags(ImGuiTableFlags_SizingFixedFit.rawValue)
        if ImGui.BeginTable("grid", Int32(columns), tableFlags, ImVec2()) {
            defer { ImGui.EndTable() }
            
            for (index, item) in items.enumerated() {
                let isSelected = index == selectedIndex
                
                ImGui.TableNextColumn()
                ImGui.PushID(Int32(index))
                
                if ImGui.Selectable("##select", isSelected, 0, Self.PaletteCellSize) {
                    selectedIndex = index
                }

                let cellOrigin = ImGui.GetItemRectMin()
                let cellSize = ImGui.GetItemRectMax() - cellOrigin

                item.draw(cellOrigin: cellOrigin,
                          cellSize: Self.PaletteCellSize,
                          isSelected: isSelected)
                
                ImGui.PopID()
            }
        }
    }
}
