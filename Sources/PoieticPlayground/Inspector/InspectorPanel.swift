//
//  Inspector.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import CIimgui

class SelectionOverview {
    /// Number of objects from the selection actually contained in the current frame/world.
    var containedCount: Int
    /// Collection of distinct types of selected objects.
    var distinctTypes: [ObjectType]
    /// Collection of traits that are shared by all of the selected objects.
    var sharedTraits: [Trait]
    /// Collection of distinct names of selected objects.
    var distinctNames: [String]
    var distinctValues: [String:[Variant]]

    init() {
        self.containedCount = 0
        self.distinctTypes = []
        self.sharedTraits = []
        self.distinctNames = []
        self.distinctValues = [:]
    }
    
    func clear() {
        self.containedCount = 0
        self.distinctTypes = []
        self.sharedTraits = []
        self.distinctNames = []
        self.distinctValues = [:]
    }

    func update(_ selection: Selection, frame: DesignFrame) {
        self.containedCount = frame.contained(selection).count
        self.distinctTypes = frame.distinctTypes(selection)
        self.sharedTraits = frame.sharedTraits(selection)
        self.distinctNames = frame.distinctAttribute("name", ids: selection).compactMap { try? $0.stringValue() }
        self.distinctValues = [:]
    }
}


protocol InspectorSection: ApplicationObject {
    var trait: Trait { get }
    var category: InspectorPanel.Category { get }
    var title: String { get }
    
    func update(_ session: Session)
    func draw(_ session: Session)
    
}

extension InspectorSection {
    func shouldDisplay(overview: SelectionOverview) -> Bool { true }
    func update(_ timeDelta: Double) { /* Do nothing */ }
}

class InspectorPanel: Panel {
    enum Category {
        case overview
        case properties
    }
    
    weak var session: Session?
    internal var world: World {
        guard let session else { fatalError("InspectorPanel used before binding")}
        return session.world
    }
    var selection: Selection {
        guard let session else { fatalError("InspectorPanel used before binding")}
        return session.selection
    }
    var overview: SelectionOverview {
        guard let session else { fatalError("InspectorPanel used before binding")}
        return session.selectionOverview
    }

    var isVisible: Bool = true
    var sections: [InspectorSection] = []

    init() {
        sections.append(NameInspectorSection())
    }
    
    func bind(_ session: Session) {
        self.session = session
    }

    func update(_ timeDelta: Double) {
        guard let session else { return }
        for section in sections {
            section.update(session)
        }
    }
    
    func draw() {
        guard isVisible, let session else { return }

        ImGui.Begin("Inspector")
        
        drawTitle(session)

        let tabBarFlags = ImGuiTabBarFlags_None
        
        if (ImGui.BeginTabBar("MyTabBar", Int32(tabBarFlags.rawValue))) {
            if (ImGui.BeginTabItem("Overview")) {
                drawOverviewTab(session)
                ImGui.EndTabItem()
            }
            if (ImGui.BeginTabItem("Properties")) {
                drawPropertiesTab(session)
                ImGui.EndTabItem()
            }
            ImGui.EndTabBar()
        }
        
        // Nothing yet
        ImGui.End()
    }
    
    func drawTitle(_ session: Session) {
        let overview = session.selectionOverview
        let style = ImGui.GetStyle().pointee
        let titleFontSize = style.FontSizeBase * 1.5
        let title: String
        let typeName: String
        
        
        if overview.distinctTypes.count == 0 {
            typeName = "–"
        }
        else if overview.distinctTypes.count == 1 {
            typeName = overview.distinctTypes.first!.name
        }
        else {
            typeName = "multiple types"
        }

        if overview.distinctNames.count == 0 {
            if overview.containedCount == 0 {
                title = "(no name)"
            }
            else {
                title = "(empty selection)"
            }
        }
        else if overview.distinctNames.count == 1 {
            title = overview.distinctNames.first!
        }
        else {
            title = String(overview.containedCount) + " of " + typeName
        }

        ImGui.PushFont(nil, titleFontSize)
        ImGui.TextUnformatted(title)
        ImGui.PopFont()

        ImGui.TextUnformatted(typeName)
    }
    
    func drawOverviewTab(_ session: Session) {
        for section in sections where section.category == .overview {
            section.draw(session)
        }
    }
    func drawPropertiesTab(_ session: Session) {
        for section in sections where section.category == .properties {
            section.draw(session)
        }
    }

}
