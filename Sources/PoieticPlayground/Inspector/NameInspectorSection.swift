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
    
    func update(_ timeDelta: Double) {
    }
    
    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    let nameContext: InputTextBuffer

    init() {
        nameContext = "unnamed"
    }
    func update(_ context: InspectionContext) {
        if context.overview.distinctNames.count == 0 {
            nameContext.string = ""
        }
        if context.overview.distinctNames.count == 1 {
            nameContext.string = context.overview.distinctNames.first!
        }
        else {
            nameContext.string = "(multiple)"
        }
    }

    func draw(_ context: InspectionContext) {
        ImGui.SeparatorText("Name")

        ImGui.InputText("Name", buffer: nameContext)
        if ImGui.IsItemDeactivatedAfterEdit() {
            acceptChange(context)
            print("Entered: string: '\(nameContext.string)' buffer: \(nameContext.bufferPointer)")
        }
    }
    
    func acceptChange(_ context: InspectionContext) {
        let trans = context.design.createFrame()
        for id in context.selection {
            guard trans.contains(id) else { continue }
            let mutable = trans.mutate(id)
            mutable.setAttribute(value: Variant(nameContext.string), forKey: "name")
        }
        context.world.setSingleton(trans)
    }
}
