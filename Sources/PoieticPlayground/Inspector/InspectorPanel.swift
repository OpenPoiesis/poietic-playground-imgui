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
    
    func updateAttribute(_ attribute: String, selection: Selection, frame: DesignFrame) {
        let values = frame.distinctAttribute(attribute, ids: selection)
        self.distinctValues[attribute] = Array(values)
    }
}


protocol InspectorSection: ApplicationObject {
    var trait: Trait { get }
    var category: InspectorPanel.Category { get }
    var title: String { get }
    /// List of inspected attributes. This is required to be provided so that
    /// selection overview can be computed.
    var inspectedAttributes: [String] { get }

    func selectionChanged(selection: Selection, overview: SelectionOverview)
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
    private(set) var currentTab: Category = .overview
    var requestedTab: Category? = nil
    func selectTab(_ tab: Category) {
        requestedTab = tab
    }

    
    var allSections: [InspectorSection] = []
    var designSections: [InspectorSection] = []
    var activeSections: [InspectorSection] = []

    init() {
        allSections.append(NameInspectorSection())
        allSections.append(FormulaInspectorSection())
        
        designSections.append(DesignInfoInspectorSection())
        designSections.append(SimulationInspectorSection())
    }
    
    func bind(_ session: Session) {
        self.session = session
    }
    
    func selectionChanged(_ session: Session) {
        guard session.selectionOverview.containedCount > 0 else {
            inspectDesign(session)
            return
        }
        print("Inspector: Selection changed")
        let overview = session.selectionOverview
        var attributes: Set<String> = []
        
        activeSections.removeAll()
        for section in allSections {
            guard overview.sharedTraits.contains(where: { $0 === section.trait  }) else {
                continue
            }
            attributes.formUnion(section.inspectedAttributes)
            activeSections.append(section)
        }

        if let frame = session.world.frame {
            for attribute in attributes {
                overview.updateAttribute(attribute, selection: selection, frame: frame)
            }
        }
        
        for section in activeSections {
            section.selectionChanged(selection: session.selection, overview: overview)
        }
    }
    
    func inspectDesign(_ session: Session) {
        activeSections.removeAll()
        activeSections += self.designSections
        
        for section in activeSections {
            guard let section = section as? DesignInspectorSection else { continue }
            section.inspectDesign(session)
        }
    }

    func update(_ timeDelta: Double) {
        guard let session else { return }
        for section in activeSections {
            section.update(session)
        }
    }
    
    func draw() {
        guard isVisible, let session else { return }
        ImGui.Begin("Inspector")
        
        drawTitle(session)

        let tabBarFlags = ImGuiTabBarFlags_None

        // FIXME: Enable tab switching. We need "pending state"
        if ImGui.BeginTabBar("MyTabBar", Int32(tabBarFlags.rawValue)) {
            let overviewFlags: Int32
            if requestedTab == .overview {
                overviewFlags = Int32(ImGuiTabItemFlags_SetSelected.rawValue)
            } else {
                overviewFlags = Int32(ImGuiTabItemFlags_None.rawValue)
            }

//            let overviewFlags = self.currentCategory == .overview ? selectedFlags : emptyFlags
            if ImGui.BeginTabItem("Overview", nil, overviewFlags) {
                self.currentTab = .overview
                drawOverviewTab(session)
                ImGui.EndTabItem()
            }

            let propertiesFlags: Int32
            if requestedTab == .properties {
                propertiesFlags = Int32(ImGuiTabItemFlags_SetSelected.rawValue)
            } else {
                propertiesFlags = Int32(ImGuiTabItemFlags_None.rawValue)
            }
            if ImGui.BeginTabItem("Properties", nil, propertiesFlags) {
                self.currentTab = .properties
                drawPropertiesTab(session)
                ImGui.EndTabItem()
            }
            ImGui.EndTabBar()
            
            requestedTab = nil
        }
        
        ImGui.End()
    }
    
    func drawTitle(_ session: Session) {
        let overview = session.selectionOverview
        let style = ImGui.GetStyle().pointee
        let titleFontSize = style.FontSizeBase * 1.5
        let title: String
        let typeName: String
        
        if session.selectionOverview.containedCount > 0 {
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
        }
        else {
            title = "Design"
            typeName = session.design.metamodel.name ?? ""
        }
        
        

        ImGui.PushFont(nil, titleFontSize)
        ImGui.TextUnformatted(title)
        ImGui.PopFont()

        ImGui.TextUnformatted(typeName)
    }
    
    func drawOverviewTab(_ session: Session) {
        for section in activeSections where section.category == .overview {
            section.draw(session)
        }
    }
    func drawPropertiesTab(_ session: Session) {
        for section in activeSections where section.category == .properties {
            section.draw(session)
        }
    }
}
