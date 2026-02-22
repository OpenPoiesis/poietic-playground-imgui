//
//  ObjectPalette.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import CIimgui
import Diagramming

struct PaletteItem {
    // TODO: Use only texture, render pictograms into textures
    enum Image {
        case pictogram(Pictogram)
        case texture(TextureHandle)
    }
    
    let identifier: String
    let image: Image
    let label: String

    func draw(cellOrigin: ImVec2, cellSize: ImVec2, isSelected: Bool) {
        let drawList = ImGui.GetWindowDrawList()
        let textSize = ImGui.CalcTextSize(label)
        let textPadding: Float = 10.0

        let iconSize = ImVec2(cellSize.x, cellSize.y - textSize.y - textPadding)
        let center = ImVec2(
            cellOrigin.x + cellSize.x / 2.0,           // Horizontal center of cell
            cellOrigin.y + iconSize.y / 2.0            // Vertical center of icon area
        )

        let textPos = ImVec2(
            center.x - (textSize.x / 2),
            center.y + cellSize.y - textSize.y - textPadding
        )

        switch image {
        case .pictogram(let pictogram):
            drawList?.pointee.StrokePictogramIcon(pictogram,
                                                  center: center,
                                                  size: iconSize,
                                                  color: .white,
                                                  lineWidth: 1.0)
        case .texture(let texture):
            let scale = min(iconSize.x / Float(texture.width),
                            iconSize.y / Float(texture.height))
            let scaledHalfSize = texture.size * (scale / 2)

//            ImGui.Image(texture.imTextureRef, texture.size, ImVec2(), ImVec2())
            drawList?.pointee.AddImage(
                   texture.imTextureRef,
                   ImVec2(center.x - scaledHalfSize.x, center.y - scaledHalfSize.y),  // top-left
                   ImVec2(center.x + scaledHalfSize.x, center.y + scaledHalfSize.y),  // bottom-right
                   ImVec2(0, 0),  // UV top-left
                   ImVec2(1, 1)   // UV bottom-right
               )
        }

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
        var column: Int = 0
        
        if ImGui.BeginTable("grid", Int32(columns), tableFlags, ImVec2()) {
            for (index, item) in items.enumerated() {
                let isSelected = index == selectedIndex
                
                if column == 0 {
                    ImGui.TableNextRow(0, Self.PaletteCellSize.y)
                }
                column += 1
                if column >= columns { column = 0 }
        
                ImGui.TableNextColumn()
                ImGui.PushID(Int32(index))
                
                if ImGui.Selectable("##select", isSelected, 0, Self.PaletteCellSize) {
                    selectedIndex = index
                }

                let cellOrigin = ImGui.GetItemRectMin()
                let cellSize = ImGui.GetItemRectMax() - cellOrigin

                item.draw(cellOrigin: cellOrigin,
                          cellSize: cellSize,
                          // cellSize: Self.PaletteCellSize,
                          isSelected: isSelected)
                
                ImGui.PopID()
            }

            ImGui.EndTable()
        }
    }
}
