//
//  NameInspectorSection.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui



class FormulaInspectorSection: InspectorSection {
    
    var trait: Trait { Trait.Formula }
    var category: InspectorPanel.Category { .properties }
    let title: String = "Formula"
    let inspectedAttributes: [String] = ["formula"]
    
    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties

    let formulaBuffer: InputTextBuffer

    init() {
        formulaBuffer = "0"
    }

    func onSelectionChanged(_ document: Document) {
        let overview = document.selectionOverview
        let distinctValues = overview.distinctValues["formula", default: []]
        
        if distinctValues.count == 0 {
            formulaBuffer.string = ""
        }
        else if distinctValues.count == 1 {
            let first = distinctValues.first!
            formulaBuffer.string = (try? first.stringValue()) ?? ""
        }
        else {
            formulaBuffer.string = "(multiple)"
        }
    }

    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
//        ImGui.SeparatorText("Formula")

        ImGui.InputText("Formula", buffer: formulaBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            acceptChange(document)
        }
    }
    
    func acceptChange(_ document: Document) {
        let trans = document.createOrReuseTransaction()
        for id in document.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            mutable.setAttribute(value: Variant(formulaBuffer.string), forKey: "formula")
        }
    }
}
