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
    func inspectDesign(_ document: Document)
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

    func onSelectionChanged(_ document: Document) {
        // We ignore the selection and the overview here, we just get the design object singleton.
    }
    
    func inspectDesign(_ document: Document) {
        guard let plane = document.world.plane
        else { return }
        
        if let infoObject = plane.first(type: .DesignInfo) {
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
    
    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
        ImGui.InputText("Title", buffer: titleBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            textAttributeChanged(document, attribute: "title", value: titleBuffer.string)
        }
        ImGui.InputTextMultiline("Abstract", buffer: abstractBuffer)
        if ImGui.IsItemDeactivatedAfterEdit() {
            textAttributeChanged(document, attribute: "abstract", value: abstractBuffer.string)
        }
//        ImGui.InputText("Author", buffer: authorBuffer)
//        if ImGui.IsItemDeactivatedAfterEdit() {
//            textAttributeChanged(document, attribute: "author", value: authorBuffer.string)
//        }
    }
    
    func textAttributeChanged(_ document: Document, attribute: String, value: String) {
        print("Design attribute changed: \(attribute) = '\(value)'")
        let trans = document.createOrReuseTransaction()
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
    static let DefaultTimeSettings = SimulationTimeSettings()
    
    var trait: Trait { Trait.SimulationTime }
    var category: InspectorPanel.Category { .properties }
    let title: String = "Design"
    let inspectedAttributes: [String] =
            ["title", "author", "abstract", "documentation"]

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .properties
    
    var infoObjectID: ObjectID?
    var startTime: Double = DefaultTimeSettings.startTime
    var timeStep: Double = DefaultTimeSettings.timeStep
    var steps: Int32 = Int32(DefaultTimeSettings.steps)
    var finalTime: Double = DefaultTimeSettings.finalTime
    
    // TODO: Audience level and keywords

    init() {
    }

    
    func onSelectionChanged(_ document: Document) {
        // We ignore the selection and the overview here, we just get the design object singleton.
    }
    
    func inspectDesign(_ document: Document) {
        guard let plane = document.world.plane
        else { return }
        
        if let infoObject = plane.first(type: .Simulation) {
            self.infoObjectID = infoObject.objectID
            let settings = SimulationTimeSettings(fromObject: infoObject)
            self.startTime = settings.startTime
            self.timeStep = settings.timeStep
            self.steps = Int32(settings.steps)
            self.finalTime = settings.finalTime
        }
        else {
            self.infoObjectID = nil // We will create a new object
            self.startTime = Self.DefaultTimeSettings.startTime
            self.timeStep = Self.DefaultTimeSettings.timeStep
            self.steps = Int32(Self.DefaultTimeSettings.steps)
            self.finalTime = Self.DefaultTimeSettings.finalTime
        }
    }
    
    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {

        ImGui.InputDouble("Time Step", &timeStep, 0.1, 10.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            changeAttribute(document, attribute: SimulationTimeSettings.TimeStepAttributeName, value: timeStep)
        }
        ImGui.InputInt("Steps", &steps, 1, 100)
        if ImGui.IsItemDeactivatedAfterEdit() {
            finalTime = startTime + Double(steps) * timeStep
            changeAttribute(document, attribute: SimulationTimeSettings.FinalTimeAttributeName, value: finalTime)
        }
        ImGui.InputDouble("Start Time", &startTime, 1.0, 100.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            changeAttribute(document, attribute: SimulationTimeSettings.StartTimeAttributeName, value: startTime)
        }
        ImGui.InputDouble("Final Time", &finalTime, 1.0, 100.0, "%.3f")
        if ImGui.IsItemDeactivatedAfterEdit() {
            if finalTime <= startTime {
                finalTime = startTime
                steps = 0
            }
            else {
                steps = Int32(((finalTime - startTime) / timeStep).rounded(.down))
            }
            changeAttribute(document, attribute: SimulationTimeSettings.FinalTimeAttributeName, value: finalTime)
        }
    }
    
    func changeAttribute(_ document: Document, attribute: String, value: Double) {
        let trans = document.createOrReuseTransaction()
        let mutable: TransientObject
        
        if let infoObjectID, let object = trans[infoObjectID] {
            if let currentValue: Double = object[attribute], currentValue == value {
                return // No change
            }
            
            mutable = trans.mutate(infoObjectID)
        }
        else {
            mutable = trans.create(.Simulation)
            self.infoObjectID = mutable.objectID
            
        }
        mutable.setAttribute(value: Variant(value), forKey: attribute)
    }
    
    func changeAttribute(_ document: Document, attribute: String, value: Int) {
        let trans = document.createOrReuseTransaction()
        let mutable: TransientObject
        
        if let infoObjectID, let object = trans[infoObjectID] {
            if let currentValue: Int = object[attribute], currentValue == value {
                return // No change
            }
            
            mutable = trans.mutate(infoObjectID)
        }
        else {
            mutable = trans.create(.Simulation)
            self.infoObjectID = mutable.objectID
            
        }
        mutable.setAttribute(value: Variant(value), forKey: attribute)
    }

}

