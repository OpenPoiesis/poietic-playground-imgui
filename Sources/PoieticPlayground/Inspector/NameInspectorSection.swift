//
//  NameInspectorSection.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui


class NameInspectorSection: InspectorSection {
    
    var trait: Trait { Trait.Name }
    var category: InspectorPanel.Category { .properties }
    let title: String = "Name"
    let inspectedAttributes: [String] = ["name"]

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    let nameBuffer: InputTextBuffer

    init() {
        nameBuffer = "unnamed"
    }

    func onSelectionChanged(_ document: Document) {
        let overview = document.selectionOverview

        if overview.distinctNames.count == 0 {
            nameBuffer.string = ""
        }
        if overview.distinctNames.count == 1 {
            nameBuffer.string = overview.distinctNames.first!
        }
        else {
            nameBuffer.string = "(multiple)"
        }
    }
    func onSimulationFinished(_ document: Document) {
        for objectID in document.selection {
            guard let entity = document.world.entity(objectID) else { continue }
        }
    }

    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
//        ImGui.SeparatorText("Name")

        ImGui.InputText("Name", buffer: nameBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            acceptChange(document)
            print("Entered: string: '\(nameBuffer.string)' buffer: \(nameBuffer.bufferPointer)")
        }
    }
    
    func acceptChange(_ document: Document) {
        let trans = document.createOrReuseTransaction()
        for id in document.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            mutable.setAttribute(value: Variant(nameBuffer.string), forKey: "name")
        }
    }
}
