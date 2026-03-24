//
//  ColorsInspectorSection.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/03/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui


class ColorInspectorSection: InspectorSection {
    static let CellSize = ImVec2(24, 24)
    static let BorderWidth: Float = 4.0
    
    var trait: Trait { Trait.Color }
    var category: InspectorPanel.Category { .properties }
    let title: String = "Color"
    let inspectedAttributes: [String] = ["color"]

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties

    var selectedColorKey: AdaptableColorKey? = nil
    
    func onSelectionChanged(_ document: Document) {
        let overview = document.selectionOverview

        let values = overview.distinctValues["color"] ?? []
        
        if values.count == 0 {
            selectedColorKey = nil
        }
        if values.count == 1 {
            if let colorName = try? values.first!.stringValue() {
                selectedColorKey = AdaptableColorKey(rawValue: colorName)
            }
            else {
                selectedColorKey = nil
            }
        }
        else {
            selectedColorKey = nil
        }
    }

    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
        let tableFlags = ImGuiTableFlags_SizingFixedFit |
        ImGuiTableFlags_NoPadInnerX |
        ImGuiTableFlags_NoPadOuterX
        var newColorKey: AdaptableColorKey? = selectedColorKey

        if ImGui.BeginTable("ColorPalette", 6, tableFlags, ImVec2()) {
            for (index, colorKey) in AdaptableColorKey.allCases.enumerated() {
                let isSelected = (colorKey == selectedColorKey)
                let color = DefaultAdaptableColors[colorKey] ?? .white
                
                ImGui.TableNextColumn()
                
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Button.rawValue), color.imIntValue)
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonHovered.rawValue), color.imIntValue)
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonActive.rawValue), color.imIntValue)
                
                if isSelected {
                    let col = ImGui.GetStyleColor(ImGuiStyleVar(ImGuiCol_FrameBg.rawValue))
                    ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Border.rawValue), col.imVecValue)
                    ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_FrameBorderSize.rawValue), Self.BorderWidth)
                }
                
                let label: String
                if isSelected { label = "O" }
                else { label = "" }
                
                if ImGui.Button("\(label)##color\(index)", Self.CellSize) {
                    newColorKey = (selectedColorKey == colorKey) ? nil : colorKey
                }
                
                if isSelected {
                    ImGui.PopStyleVar()
                    ImGui.PopStyleColor()
                }
                ImGui.PopStyleColor(3)
            }
            
            ImGui.EndTable()
        }
        
        if newColorKey != selectedColorKey {
            selectedColorKey = newColorKey
            acceptChange(document)
        }

    }
    
    func acceptChange(_ document: Document) {
        let trans = document.createOrReuseTransaction()
        for id in document.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            if let colorName = selectedColorKey?.rawValue {
                mutable.setAttribute(value: Variant(colorName), forKey: "color")
            }
            else {
                mutable.removeAttribute(forKey: "color")
            }
        }
    }
}
