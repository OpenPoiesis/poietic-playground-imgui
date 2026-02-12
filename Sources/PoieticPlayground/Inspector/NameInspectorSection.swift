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
    
    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    let nameContext: InputTextBuffer

    init() {
        nameContext = "unnamed"
    }
    func update(_ session: Session) {
        let overview = session.selectionOverview
        if overview.distinctNames.count == 0 {
            nameContext.string = ""
        }
        if overview.distinctNames.count == 1 {
            nameContext.string = overview.distinctNames.first!
        }
        else {
            nameContext.string = "(multiple)"
        }
    }

    func draw(_ session: Session) {
        ImGui.SeparatorText("Name")

        ImGui.InputText("Name", buffer: nameContext)
        if ImGui.IsItemDeactivatedAfterEdit() {
            acceptChange(session)
            print("Entered: string: '\(nameContext.string)' buffer: \(nameContext.bufferPointer)")
        }
    }
    
    func acceptChange(_ session: Session) {
        let trans = session.createOrReuseTransaction()
        for id in session.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            mutable.setAttribute(value: Variant(nameContext.string), forKey: "name")
        }
    }
}
