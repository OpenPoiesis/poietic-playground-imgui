//
//  MetamodelPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/08/2026.
//
//  Drafted by an agent.

//  Reference panel displaying metamodel documentation — types, traits,
//  edge rules, and constraints.
//

import CIimgui
import PoieticCore
import PoieticFlows
import Diagramming

/// Panel that displays the metamodel structure for the current design.
///
/// Left: tree navigation (Nodes, Edges, Unstructured, Traits, Edge Rules, Constraints).
/// Right: detail content for the selected item.
///
/// Traits and object types are cross-linked — clicking a trait in an object
/// type's details navigates to that trait, and vice versa.
@MainActor
class MetamodelPanel: Panel {

    var isVisible: Bool = false {
        didSet { if !isVisible { selectedItem = nil } }
    }

    // MARK: - Navigation state

    private enum NavItem: Equatable {
        case nodes
        case nodeType(ObjectType)
        case edges
        case edgeType(ObjectType)
        case unstructured
        case unstructuredType(ObjectType)
        case traits
        case trait(Trait)
        case edgeRules
        case constraints

        var label: String {
            switch self {
            case .nodes:             "Blocks"
            case .nodeType(let t):   t.label
            case .edges:             "Connectors"
            case .edgeType(let t):   t.label
            case .unstructured:      "Other"
            case .unstructuredType(let t): t.label
            case .traits:            "Traits"
            case .trait(let t):      t.label
            case .edgeRules:         "Edge Rules"
            case .constraints:       "Constraints"
            }
        }

        static func == (lhs: NavItem, rhs: NavItem) -> Bool {
            switch (lhs, rhs) {
            case (.nodes, .nodes), (.edges, .edges), (.unstructured, .unstructured),
                 (.traits, .traits), (.edgeRules, .edgeRules), (.constraints, .constraints):
                return true
            case (.nodeType(let a), .nodeType(let b)):       return a === b
            case (.edgeType(let a), .edgeType(let b)):       return a === b
            case (.unstructuredType(let a), .unstructuredType(let b)): return a === b
            case (.trait(let a), .trait(let b)):             return a === b
            default: return false
            }
        }
    }

    private var selectedItem: NavItem?

    // MARK: - Data source

    private var metamodel: Metamodel? {
        document?.design.metamodel
    }

    weak var document: Document?

    // MARK: - Panel

    func bind(_ document: Document) {
        self.document = document
    }

    func update(_ timeDelta: Double) {}

    func draw() {
        guard let metamodel else { return }

        ImGui.Begin("Metamodel Reference", &isVisible)

        // -- Left: tree navigation --
        ImGui.BeginChild("##tree", ImVec2(220, 0), ImGuiChildFlags(ImGuiChildFlags_ResizeX.rawValue))

        drawTree(metamodel)

        ImGui.EndChild()
        ImGui.SameLine()

        // -- Right: content --
        ImGui.BeginChild("##content", ImVec2(0, 0), ImGuiChildFlags(ImGuiChildFlags_Borders.rawValue))

        if let selectedItem {
            drawContent(for: selectedItem, metamodel: metamodel)
        } else {
            ImGui.TextUnformatted("Select an item from the tree to view details.")
        }

        ImGui.EndChild()
        ImGui.End()
    }

    // MARK: - Tree

    private func drawTree(_ metamodel: Metamodel) {
        drawTreeCategory(.nodes, items: metamodel.nodeTypes) { .nodeType($0) }
        drawTreeCategory(.edges, items: metamodel.edgeTypes) { .edgeType($0) }
        drawTreeCategory(.unstructured, items: metamodel.unstructuredTypes) { .unstructuredType($0) }
        drawTreeCategory(.traits, items: metamodel.traits) { .trait($0) }

        ImGui.Separator()

        drawTreeLeaf(.edgeRules)
        drawTreeLeaf(.constraints)
    }

    private func drawTreeCategory<T: AnyObject>(
        _ category: NavItem,
        items: [T],
        leaf: (T) -> NavItem
    ) {
        let flags: ImGuiTreeNodeFlags = ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_None.rawValue)
        let opened = ImGui.TreeNodeEx(category.label, flags)
        if ImGui.IsItemClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
            selectedItem = category
        }
        if opened {
            for item in items {
                let itemFlags: ImGuiTreeNodeFlags =
                    ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_Leaf.rawValue |
                                       ImGuiTreeNodeFlags_NoTreePushOnOpen.rawValue)
                let leafItem = leaf(item)
                let isSelected = selectedItem == leafItem
                if isSelected { ImGui.TreeNodeEx(leafItem.label, itemFlags | ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_Selected.rawValue)) }
                else { ImGui.TreeNodeEx(leafItem.label, itemFlags) }
                if ImGui.IsItemClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
                    selectedItem = leafItem
                }
            }
            ImGui.TreePop()
        }
    }

    private func drawTreeLeaf(_ item: NavItem) {
        let flags: ImGuiTreeNodeFlags =
            ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_Leaf.rawValue |
                               ImGuiTreeNodeFlags_NoTreePushOnOpen.rawValue)
        let isSelected = selectedItem == item
        if isSelected { ImGui.TreeNodeEx(item.label, flags | ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_Selected.rawValue)) }
        else { ImGui.TreeNodeEx(item.label, flags) }
        if ImGui.IsItemClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
            selectedItem = item
        }
    }

    // MARK: - Content

    private func drawContent(for item: NavItem, metamodel: Metamodel) {
        switch item {
        case .nodes, .edges, .unstructured, .traits:
            // Category header — brief overview
            let label: String
            let abstract: String
            switch item {
            case .nodes:        label = "Block Types";        abstract = "Simulation blocks and other nodes."
            case .edges:        label = "Connector Types";        abstract = "Objects that connect blocks."
            case .unstructured: label = "Unstructured Types"; abstract = "Objects not participating in the design graph."
            case .traits:       label = "Traits";            abstract = "Reusable attribute groups adopted by object types."
            default: return
            }
            ImGui.TextUnformatted(label)
            ImGui.Separator()
            ImGui.TextWrappedUnformatted(abstract)

        case .nodeType(let type):
            drawObjectTypeDetail(type, metamodel: metamodel)
        case .edgeType(let type):
            drawObjectTypeDetail(type, metamodel: metamodel)
        case .unstructuredType(let type):
            drawObjectTypeDetail(type, metamodel: metamodel)

        case .trait(let trait):
            drawTraitDetail(trait, metamodel: metamodel)

        case .edgeRules:
            drawEdgeRulesTable(metamodel.edgeRules)
        case .constraints:
            drawConstraintsTable(metamodel.constraints)
        }
    }

    // MARK: - Object type detail

    private func drawObjectTypeDetail(_ type: ObjectType, metamodel: Metamodel) {
        ImGui.TextUnformatted(type.label)
        ImGui.Separator()

        if ImGui.BeginTable("##detail_layout", 2, ImGuiTableFlags(ImGuiTableFlags_None.rawValue), ImVec2()) {
            ImGui.TableSetupColumn("##left", ImGuiTableColumnFlags(ImGuiTableColumnFlags_WidthStretch.rawValue), 0, 0)
            ImGui.TableSetupColumn("##right", ImGuiTableColumnFlags(ImGuiTableColumnFlags_WidthFixed.rawValue), 0, 0)
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted("Identifier: "); ImGui.SameLine()
            ImGui.TextUnformatted(type.name)

            
            ImGui.TableNextColumn()
            if type.topologyType == .node,
               let notation: Notation = document?.world.singleton()
            {
                let pictogram = notation.pictogram(type.name)
                let size = ImVec2(50, 50)
                ImGui.SameLine()
                ImGui.Dummy(size)

                let position = ImGui.GetItemRectMin() + (size / 2)

                let drawList = ImGui.GetWindowDrawList()
                drawList?.pointee.StrokePictogramIcon(pictogram,
                                                      center: position,
                                                      size: size,
                                                      color: .black,
                                                      lineWidth: 1.0)
            }
            else {
                ImGui.Dummy(ImVec2())
            }

            ImGui.EndTable()
        }

        if let abstract = type.abstract {
            ImGui.Spacing()
            ImGui.TextWrappedUnformatted(abstract)
        }

        // Traits
        ImGui.Spacing()
        ImGui.TextUnformatted("Traits:")
        for trait in type.traits {
            ImGui.Bullet()
            ImGui.TextUnformatted(trait.label)
            ImGui.SameLine()
            ImGui.TextDisabledUnformatted("(\(trait.name))")
            if ImGui.IsItemClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
                selectedItem = .trait(trait)
            }
        }

        // Attributes table
        ImGui.Spacing()
        ImGui.TextUnformatted("Attributes:")
        if type.attributes.isEmpty {
            ImGui.TextDisabledUnformatted("  (none)")
        } else {
            drawAttributesTable(type.attributes)
        }

        // Edge rules
        ImGui.Spacing()
        switch type.topologyType {
        case .node:
            let rules = edgeRules(forNodeType: type, in: metamodel)
            if !rules.isEmpty {
                ImGui.TextUnformatted("Edge Rules:")
                // TODO: Render edge glyphs for edge types appearing in rules
                drawEdgeRulesTable(rules)
            }
        case .edge:
            let rules = metamodel.edgeRules.filter { $0.type === type }
            if !rules.isEmpty {
                ImGui.TextUnformatted("Edge Rules:")
                // TODO: Render pictograms for node types appearing in origin/target predicates
                drawEdgeRulesTable(rules)
            }
        default:
            break
        }
    }

    // MARK: - Trait detail

    private func drawTraitDetail(_ trait: Trait, metamodel: Metamodel) {
        ImGui.TextUnformatted(trait.label)
        ImGui.Separator()

        ImGui.TextUnformatted("Identifier: "); ImGui.SameLine()
        ImGui.TextUnformatted(trait.name)

        if let abstract = trait.abstract {
            ImGui.Spacing()
            ImGui.TextWrappedUnformatted(abstract)
        }

        // Attributes
        ImGui.Spacing()
        ImGui.TextUnformatted("Attributes:")
        if trait.attributes.isEmpty {
            ImGui.TextDisabledUnformatted("  (none)")
        } else {
            drawAttributesTable(trait.attributes)
        }

        // Object types adopting this trait
        let adopters = metamodel.types.filter { $0.hasTrait(trait.name) }
        if !adopters.isEmpty {
            ImGui.Spacing()
            ImGui.TextUnformatted("Adopted by:")
            for adopter in adopters {
                ImGui.Bullet()
                ImGui.TextUnformatted(adopter.label)
                ImGui.SameLine()
                ImGui.TextDisabledUnformatted("(\(adopter.name))")
                if ImGui.IsItemClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
                    switch adopter.topologyType {
                    case .node:         selectedItem = .nodeType(adopter)
                    case .edge:         selectedItem = .edgeType(adopter)
                    case .unstructured: selectedItem = .unstructuredType(adopter)
                    default: selectedItem = nil
                    }
                }
            }
        }
    }

    // MARK: - Edge rules table

    private func drawEdgeRulesTable(_ rules: [EdgeRule]) {
        guard ImGui.BeginTable("##edge_rules", 5,
                               ImGuiTableFlags_Borders |
                               ImGuiTableFlags_RowBg |
                               ImGuiTableFlags_Resizable,
                               ImVec2())
        else { return }

        ImGui.TableSetupColumn("Edge Type", 0, 0, 0)
        ImGui.TableSetupColumn("Origin", 0, 0, 0)
        ImGui.TableSetupColumn("Target", 0, 0, 0)
        ImGui.TableSetupColumn("Outgoing", 0, 0, 0)
        ImGui.TableSetupColumn("Incoming", 0, 0, 0)
        ImGui.TableHeadersRow()

        for rule in rules {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(rule.type.label)

            ImGui.TableNextColumn()
            if let pred = rule.originPredicate {
                ImGui.TextUnformatted(String(describing: pred))
            } else {
                ImGui.TextDisabledUnformatted("any")
            }

            ImGui.TableNextColumn()
            if let pred = rule.targetPredicate {
                ImGui.TextUnformatted(String(describing: pred))
            } else {
                ImGui.TextDisabledUnformatted("any")
            }

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(String(describing: rule.outgoing))

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(String(describing: rule.incoming))
        }

        ImGui.EndTable()
    }

    // MARK: - Constraints table

    private func drawConstraintsTable(_ constraints: [Constraint]) {
        guard ImGui.BeginTable("##constraints", 2,
                               ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg,
                               ImVec2())
        else { return }

        ImGui.TableSetupColumn("Name", 0, 0, 0)
        ImGui.TableSetupColumn("Description", 0, 0, 0)
        ImGui.TableHeadersRow()

        for constraint in constraints {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)
            ImGui.TableNextColumn()
            ImGui.TextUnformatted(constraint.name)
            ImGui.TableNextColumn()
            if let abstract = constraint.abstract {
                ImGui.TextWrappedUnformatted(abstract)
            } else {
                ImGui.TextDisabledUnformatted("(no description)")
            }
        }

        ImGui.EndTable()
    }

    // MARK: - Attributes table (shared)

    private func drawAttributesTable(_ attributes: [Attribute]) {
        guard ImGui.BeginTable("##attrs", 5,
            ImGuiTableFlags(ImGuiTableFlags_Borders.rawValue |
                            ImGuiTableFlags_RowBg.rawValue |
                            ImGuiTableFlags_Resizable.rawValue |
                            ImGuiTableFlags_ScrollY.rawValue),
            ImVec2(0, 200))
        else { return }

        ImGui.TableSetupColumn("Attribute", 0, 0, 0)
        ImGui.TableSetupColumn("Label", 0, 0, 0)
        ImGui.TableSetupColumn("Type", ImGuiTableColumnFlags(ImGuiTableColumnFlags_WidthStretch.rawValue), 0, 0)
        ImGui.TableSetupColumn("Required", ImGuiTableColumnFlags(ImGuiTableColumnFlags_WidthStretch.rawValue), 0, 0)
        ImGui.TableSetupColumn("Description", 0, 0, 0)
        ImGui.TableHeadersRow()

        for attr in attributes {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(attr.name)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(attr.label)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(String(describing: attr.type))

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(attr.optional ? "" : "yes")

            ImGui.TableNextColumn()
            if let abstract = attr.abstract {
                ImGui.TextWrappedUnformatted(abstract)
            }
        }

        ImGui.EndTable()
    }

    // MARK: - Helpers

    /// Edge rules where the given node type appears as origin or target predicate.
    private func edgeRules(forNodeType type: ObjectType, in metamodel: Metamodel) -> [EdgeRule] {
        metamodel.edgeRules.filter { rule in
            if let pred = rule.originPredicate, pred.refersTo(type: type) {
                return true
            }
            if let pred = rule.targetPredicate, pred.refersTo(type: type) {
                return true
            }
            return false
        }
    }
}

extension Predicate {
    /// Returns true if the predicate or any of the children refer to a given object type.
    func refersTo(type other: ObjectType) -> Bool {
        switch self {
        case .isType(let type):
            if type === other { return true }
        default: break
        }
        
        for child in children {
            if child.refersTo(type: other) { return true }
        }
        return false
    }

}
