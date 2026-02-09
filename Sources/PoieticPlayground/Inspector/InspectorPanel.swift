//
//  Inspector.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import CIimgui

class SelectionOverview: Component {
    /// Number of objects from the selection actually contained in the current frame/world.
    var containedCount: Int = 0
    /// Collection of distinct types of selected objects.
    var distinctTypes: [ObjectType] = []
    /// Collection of traits that are shared by all of the selected objects.
    var sharedTraits: [Trait] = []
    /// Collection of distinct names of selected objects.
    var distinctNames: [String] = []
    var distinctValues: [String:[Variant]] = [:]
    init() {
        
    }
}

func createSelectionOverview(_ selection: Selection, frame: DesignFrame) -> SelectionOverview {
    let overview = SelectionOverview()
    overview.containedCount = frame.contained(selection).count
    overview.distinctTypes = frame.distinctTypes(selection)
    overview.sharedTraits = frame.sharedTraits(selection)
    let names = frame.distinctAttribute("name", ids: selection).compactMap { try? $0.stringValue() }
    overview.distinctNames = names
    return overview
}

class InspectorSection: ApplicationObject {
    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    func draw(selection: Selection, overview: SelectionOverview) {
        // Nothing yet
    }
}

class InspectorPanel: Panel {
    var world: World?
    
    var isVisible: Bool = true
    var sections: [InspectorSection] = []
    
    func bind(_ world: World) {
        self.world = world
    }

    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    func draw() {
        guard isVisible,
              let world
        else { return }
        
        let selection: Selection? = world.singleton()
        let overview: SelectionOverview = world.singleton() ?? SelectionOverview()
        
        ImGui.Begin("Inspector")
        
        drawTitle(overview: overview)

        let tabBarFlags = ImGuiTabBarFlags_None
        if (ImGui.BeginTabBar("MyTabBar", Int32(tabBarFlags.rawValue))) {
            if (ImGui.BeginTabItem("Overview")) {
                drawOverviewTab(overview)
                ImGui.EndTabItem()
            }
            if (ImGui.BeginTabItem("Properties")) {
                drawPropertiesTab(overview)
                ImGui.EndTabItem()
            }
            ImGui.EndTabBar()
        }
        
        for section in sections {
//            section.draw()
        }
        // Nothing yet
        ImGui.End()
    }
    
    func drawTitle(overview: SelectionOverview) {
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

        ImGui.PushFont(nil, titleFontSize);
        ImGui.TextUnformatted(title)
        ImGui.PopFont()
        ImGui.TextUnformatted(typeName)
    }
    
    func drawOverviewTab(_ overview: SelectionOverview) {
        ImGui.TextUnformatted("(overview goes here)")
    }
    func drawPropertiesTab(_ overview: SelectionOverview) {
        ImGui.TextUnformatted("(properties go here)")
    }

}
