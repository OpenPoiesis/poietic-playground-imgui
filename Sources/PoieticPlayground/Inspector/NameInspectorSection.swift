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

    func selectionChanged(selection: Selection, overview: SelectionOverview) {
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

    func update(_ session: Session) { /* Nothing for now */ }

    func draw(_ session: Session) {
//        ImGui.SeparatorText("Name")

        ImGui.InputText("Name", buffer: nameBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            acceptChange(session)
            print("Entered: string: '\(nameBuffer.string)' buffer: \(nameBuffer.bufferPointer)")
        }
    }
    
    func acceptChange(_ session: Session) {
        let trans = session.createOrReuseTransaction()
        for id in session.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            mutable.setAttribute(value: Variant(nameBuffer.string), forKey: "name")
        }
    }
}
