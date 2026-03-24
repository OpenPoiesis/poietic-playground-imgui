//
//  DesignInspectorSections.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//


import PoieticCore
import PoieticFlows
import CIimgui

protocol DesignInspectorSection: InspectorSection {
    func inspectDesign(_ session: Session)
}

class DesignInfoInspectorSection: DesignInspectorSection {
    
    var trait: Trait { Trait.DesignInfo }
    var category: InspectorPanel.Category { .overview }
    let title: String = "Design"
    let inspectedAttributes: [String] =
            ["title", "author", "abstract", "documentation"]

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    
    var infoObjectID: ObjectID?
    let titleBuffer: InputTextBuffer
    let authorBuffer: InputTextBuffer
    let abstractBuffer: InputTextBuffer
    let documentationBuffer: InputTextBuffer
    // TODO: Audience level and keywords

    init() {
        self.titleBuffer = "unnamed"
        self.authorBuffer = ""
        self.abstractBuffer = ""
        self.documentationBuffer = ""
    }

    func onSelectionChanged(_ session: Session) {
        // We ignore the selection and the overview here, we just get the design object singleton.
    }
    
    func inspectDesign(_ session: Session) {
        guard let frame = session.world.frame
        else { return }
        
        if let infoObject = frame.first(type: .DesignInfo) {
            self.infoObjectID = infoObject.objectID
            self.titleBuffer.string = infoObject["title"] ?? ""
            self.authorBuffer.string = infoObject["author"] ?? ""
            self.abstractBuffer.string = infoObject["abstract"] ?? ""
            self.documentationBuffer.string = infoObject["documentation"] ?? ""
        }
        else {
            self.infoObjectID = nil // We will create a new object
            self.titleBuffer.string = "untitled"
            self.authorBuffer.string = ""
            self.abstractBuffer.string = ""
            self.documentationBuffer.string = ""

        }
    }
    
    func update(_ session: Session) { /* Nothing for now */ }

    func draw(_ session: Session) {
        ImGui.InputText("Title", buffer: titleBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            textAttributeChanged(session, attribute: "title", value: titleBuffer.string)
        }
        ImGui.InputTextMultiline("Abstract", buffer: abstractBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            textAttributeChanged(session, attribute: "abstract", value: abstractBuffer.string)
        }
//        ImGui.InputText("Author", buffer: authorBuffer)
//        if ImGui.IsItemDeactivatedAfterEdit() {
//            textAttributeChanged(session, attribute: "author", value: authorBuffer.string)
//        }
    }
    
    func textAttributeChanged(_ session: Session, attribute: String, value: String) {
        print("Design attribute changed: \(attribute) = '\(value)'")
        let trans = session.createOrReuseTransaction()
        let mutable: TransientObject
        
        if let infoObjectID, let object = trans[infoObjectID] {
            if let currentValue: String = object[attribute], currentValue == value {
                return // No change
            }
            
            mutable = trans.mutate(infoObjectID)
        }
        else {
            mutable = trans.create(.DesignInfo)
            self.infoObjectID = mutable.objectID
            
        }
        mutable.setAttribute(value: Variant(value), forKey: attribute)
    }
}

class SimulationInspectorSection: DesignInspectorSection {
    static let DefaultSettings = SimulationSettings()
    
    var trait: Trait { Trait.DesignInfo }
    var category: InspectorPanel.Category { .properties }
    let title: String = "Design"
    let inspectedAttributes: [String] =
            ["title", "author", "abstract", "documentation"]

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    
    var infoObjectID: ObjectID?
    var initialTime: Double = DefaultSettings.initialTime
    var timeDelta: Double = DefaultSettings.timeDelta
    var steps: Int32 = Int32(DefaultSettings.steps)
    var endTime: Double = DefaultSettings.endTime
    
    // TODO: Audience level and keywords

    init() {
    }

    
    func onSelectionChanged(_ session: Session) {
        // We ignore the selection and the overview here, we just get the design object singleton.
    }
    
    func inspectDesign(_ session: Session) {
        guard let frame = session.world.frame
        else { return }
        
        if let infoObject = frame.first(type: .Simulation) {
            self.infoObjectID = infoObject.objectID
            self.initialTime = infoObject["initialTime"] ?? Self.DefaultSettings.initialTime
            self.timeDelta = infoObject["time_delta"] ?? Self.DefaultSettings.timeDelta
            self.steps = infoObject["steps"] ?? Int32(Self.DefaultSettings.steps)
            self.endTime = initialTime + Double(steps) * self.endTime
        }
        else {
            self.infoObjectID = nil // We will create a new object
            self.initialTime = Self.DefaultSettings.initialTime
            self.timeDelta = Self.DefaultSettings.timeDelta
            self.steps = Int32(Self.DefaultSettings.steps)
            self.endTime = initialTime + Double(steps) * timeDelta
        }
    }
    
    func update(_ session: Session) { /* Nothing for now */ }

    func draw(_ session: Session) {

        ImGui.InputDouble("Time Delta", &timeDelta, 0.1, 10.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            changeAttribute(session, attribute: "time_delta", value: timeDelta)
        }
        ImGui.InputInt("Steps", &steps, 1, 100)
        if ImGui.IsItemDeactivatedAfterEdit() {
            self.endTime = initialTime + Double(steps) * timeDelta
            changeAttribute(session, attribute: "steps", value: Int(steps))
        }
        ImGui.InputDouble("Initial Time", &initialTime, 1.0, 100.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            changeAttribute(session, attribute: "initial_time", value: initialTime)
        }
        ImGui.InputDouble("End Time", &endTime, 1.0, 100.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            if endTime <= initialTime {
                endTime = initialTime
                steps = 0
            }
            else {
                steps = Int32(((endTime - initialTime) / timeDelta).rounded(.down))
            }
            changeAttribute(session, attribute: "steps", value: Int(steps))
        }
        
        self.endTime = initialTime + Double(steps) * timeDelta

    }
    
    func changeAttribute(_ session: Session, attribute: String, value: Double) {
        let trans = session.createOrReuseTransaction()
        let mutable: TransientObject
        
        if let infoObjectID, let object = trans[infoObjectID] {
            if let currentValue: Double = object[attribute], currentValue == value {
                return // No change
            }
            
            mutable = trans.mutate(infoObjectID)
        }
        else {
            mutable = trans.create(.DesignInfo)
            self.infoObjectID = mutable.objectID
            
        }
        mutable.setAttribute(value: Variant(value), forKey: attribute)
    }
    
    func changeAttribute(_ session: Session, attribute: String, value: Int) {
        let trans = session.createOrReuseTransaction()
        let mutable: TransientObject
        
        if let infoObjectID, let object = trans[infoObjectID] {
            if let currentValue: Int = object[attribute], currentValue == value {
                return // No change
            }
            
            mutable = trans.mutate(infoObjectID)
        }
        else {
            mutable = trans.create(.DesignInfo)
            self.infoObjectID = mutable.objectID
            
        }
        mutable.setAttribute(value: Variant(value), forKey: attribute)
    }

}

