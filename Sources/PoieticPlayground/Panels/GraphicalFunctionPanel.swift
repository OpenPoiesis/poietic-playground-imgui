//
//  GraphicalFunctionPanel.swift
//  PoieticPlayground
//
//  Graphical function editor panel.
//
// Ported with help of an agent from Playground prototype written in Godot.

import CIimgui
import PoieticCore
import PoieticFlows
import Diagramming

/// Full-featured panel for editing a graphical function's control points and
/// interpolation method. Contains a curve view, an editable points table, range
/// controls, and Set / Reset action buttons.
///
/// Like the inspector, it reacts to selection changes: when exactly one
/// GraphicalFunction object is selected, the editor is populated; otherwise
/// the UI is disabled and shows only an empty grid.
///
/// Corresponds to `GraphicalCurvesEditorWindow` in the Godot prototype.
@MainActor
class GraphicalFunctionPanel: Panel {
    var isVisible: Bool = false
    
    // MARK: - State

    weak var document: Document?

    /// ObjectID currently being edited, if any.
    private var editingObjectID: ObjectID?

    /// The curve editor subview.
    private let curveView = CurveEditorControl()

    /// Points being edited — a working copy of the design object's data.
    private var workingPoints: [Vector2D] = []
    private var workingInterpolation: GraphicalFunction.InterpolationMethod = .linear

    /// Originals from the design object, for Reset.
    private var originalPoints: [Vector2D] = []
    private var originalInterpolation: GraphicalFunction.InterpolationMethod = .linear

    /// Whether the panel is active (exactly one GraphicalFunction selected).
    private var isActive: Bool = false

    // MARK: - Range fields (string buffers for ImGui input)

    private var minXStr = InputTextBuffer("0.0")
    private var maxXStr = InputTextBuffer("100.0")
    private var minYStr = InputTextBuffer("0.0")
    private var maxYStr = InputTextBuffer("100.0")

    // MARK: - Interpolation radio state

    private var interpolationLinear: Bool = true
    private var interpolationStep: Bool = false
    private var interpolationCubic: Bool = false

    // MARK: - Focus & tabs

    private var isFocused: Bool = false
    private var activeTab: Int32 = 0  // 0 = Graphical, 1 = Table

    // MARK: - Lifecycle

    func bind(_ document: Document) {
        self.document = document
    }
    
    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    func onSelectionChanged(_ document: Document) {
        let selection = document.selection
        guard selection.ids.count == 1,
              let objectID = selection.ids.first,
              let plane = document.world.plane,
              let object = plane[objectID],
              object.type.hasTrait(StockFlowDomain.Traits.GraphicalFunction)
        else {
            isActive = false
            editingObjectID = nil
            curveView.points = []
            return
        }

        isActive = true
        editingObjectID = objectID

        let rawPoints: [Vector2D] = object["graphical_function_points"] ?? []
        workingPoints = rawPoints
        originalPoints = rawPoints

        let methodName: String = object["interpolation_method"] ?? "linear"
        workingInterpolation = parseInterpolation(methodName)
        originalInterpolation = workingInterpolation

        curveView.points = workingPoints
        curveView.interpolation = workingInterpolation
        curveView.fitRange()

        syncRangeFieldsFromCurve()
        syncInterpolationRadio()
    }
    
    func handleAction(_ actionName: String) -> Bool {
        guard isVisible && isFocused else { return false }
        switch actionName {
        case "delete":
            if let pointIndex = curveView.selectedPointIndex {
                curveView.removePoint(at: pointIndex)
            }
            return true
        default:
            return false
        }
    }

    // MARK: - Drawing

    func draw() {
        guard document != nil else { return }
        ImGui.Begin("Graphical Function Editor", &isVisible)
        isFocused = ImGui.IsWindowFocused(ImGuiFocusedFlags(ImGuiFocusedFlags_RootAndChildWindows.rawValue))

        if !isActive {
            ImGui.TextUnformatted("Select a single Graphical Function object to edit.")
            ImGui.End()
            return
        }

        // -- Tab bar: Graphical | Table --
        if ImGui.BeginTabBar("##editor_tabs") {
            if ImGui.BeginTabItem("Graphical") {
                activeTab = 0

                let curveSize = ImVec2(Float(ImGui.GetContentRegionAvail().x), 350)
                ImGui.BeginChild("##curve_area", curveSize, ImGuiChildFlags(ImGuiChildFlags_Borders.rawValue))
                curveView.draw(size: curveSize)
                ImGui.EndChild()

                if ImGui.Button("Remove", ImVec2(120, 0)) {
                    if let index = curveView.selectedPointIndex {
                        curveView.removePoint(at: index)
                    }
                }

                ImGui.EndTabItem()
            }
            if ImGui.BeginTabItem("Table") {
                activeTab = 1
                drawPointsTable()
                ImGui.EndTabItem()
            }
            ImGui.EndTabBar()
        }

        drawRangeControls()
        drawInterpolationControls()
        drawActionButtons()

        ImGui.End()
    }

    // MARK: - Points table

    private func drawPointsTable() {
        guard ImGui.BeginTable("##points_table", 2,
            ImGuiTableFlags(ImGuiTableFlags_Borders |
                            ImGuiTableFlags_RowBg), ImVec2())
        else { return }

        ImGui.TableSetupColumn("X", ImGuiTableColumnFlags(ImGuiTableColumnFlags_None.rawValue), 0, 0)
        ImGui.TableSetupColumn("Y", ImGuiTableColumnFlags(ImGuiTableColumnFlags_None.rawValue), 0, 0)
        ImGui.TableHeadersRow()

        let sorted = curveView.sortedPoints()
        for (index, point) in sorted.enumerated() {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

            var x = point.x
            var y = point.y

            ImGui.TableNextColumn()
            ImGui.PushID(Int32(index * 2))
            ImGui.PushItemWidth(-1)
            ImGui.InputDouble("##x", &x, 0, 0, "%.2f")
            if ImGui.IsItemDeactivatedAfterEdit() {
                curveView.replacePoint(oldValue: point, newValue: Vector2D(x: x, y: point.y))
                curveView.fitRange()
            }
            ImGui.PopItemWidth()
            ImGui.PopID()

            ImGui.TableNextColumn()
            ImGui.PushID(Int32(index * 2 + 1))
            ImGui.PushItemWidth(-1)
            ImGui.InputDouble("##y", &y, 0, 0, "%.2f")
            if ImGui.IsItemDeactivatedAfterEdit() {
                curveView.replacePoint(oldValue: point, newValue: Vector2D(x: point.x, y: y))
                curveView.fitRange()
            }
            ImGui.PopItemWidth()
            ImGui.PopID()
        }
        ImGui.EndTable()

        // Buttons: [Add] [Remove]
        if ImGui.Button("Add Point", ImVec2(120, 0)) {
            let midX = (curveView.minX + curveView.maxX) / 2
            let midY = (curveView.minY + curveView.maxY) / 2
            curveView.addPoint(Vector2D(x: midX, y: midY))
        }
        ImGui.SameLine()
        if ImGui.Button("Remove", ImVec2(120, 0)) {
            if let pointIndex = curveView.selectedPointIndex {
                curveView.removePoint(at: pointIndex)
            }
        }
    }
    
    // MARK: - Range controls

    private func drawRangeControls() {
        ImGui.TextUnformatted("View Range")
        let fieldWidth: Float = 80

        ImGui.PushItemWidth(fieldWidth)
        if ImGui.InputText("Min X", buffer: minXStr) { applyRange(.minX) }
        ImGui.SameLine()
        if ImGui.InputText("Max X", buffer: maxXStr) { applyRange(.maxX) }
        ImGui.SameLine()
        if ImGui.InputText("Min Y", buffer: minYStr) { applyRange(.minY) }
        ImGui.SameLine()
        if ImGui.InputText("Max Y", buffer: maxYStr) { applyRange(.maxY) }
        ImGui.PopItemWidth()
    }

    private func applyRange(_ field: RangeField) {
        let buf: InputTextBuffer
        let current: Double
        switch field {
        case .minX: buf = minXStr; current = curveView.minX
        case .maxX: buf = maxXStr; current = curveView.maxX
        case .minY: buf = minYStr; current = curveView.minY
        case .maxY: buf = maxYStr; current = curveView.maxY
        }

        guard let value = Double(buf.string.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            // Revert to previous
            buf.string = String(format: "%.2f", current)
            return
        }

        var newMinX = curveView.minX
        var newMaxX = curveView.maxX
        var newMinY = curveView.minY
        var newMaxY = curveView.maxY

        switch field {
        case .minX: newMinX = value
        case .maxX: newMaxX = value
        case .minY: newMinY = value
        case .maxY: newMaxY = value
        }

        // Ensure max > min
        if newMinX >= newMaxX {
            if field == .minX { newMaxX = newMinX + 1 }
            else { newMinX = newMaxX - 1 }
        }
        if newMinY >= newMaxY {
            if field == .minY { newMaxY = newMinY + 1 }
            else { newMinY = newMaxY - 1 }
        }

        curveView.minX = newMinX
        curveView.maxX = newMaxX
        curveView.minY = newMinY
        curveView.maxY = newMaxY

        syncRangeFieldsFromCurve()
    }

    private enum RangeField { case minX, maxX, minY, maxY }

    // MARK: - Interpolation controls

    private func drawInterpolationControls() {
        ImGui.TextUnformatted("Interpolation")
        if ImGui.RadioButton("Linear", workingInterpolation == .linear) {
            setInterpolation(.linear)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Step", workingInterpolation == .step) {
            setInterpolation(.step)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Cubic", workingInterpolation == .cubic) {
            setInterpolation(.cubic)
        }
    }

    // MARK: - Action buttons

    private func drawActionButtons() {
        ImGui.Spacing()
        if ImGui.Button("Apply", ImVec2(120, 0)) {
            commitChanges()
        }
        ImGui.SameLine()
        if ImGui.Button("Reset", ImVec2(120, 0)) {
            resetToOriginals()
        }
    }

    // MARK: - Actions

    private func commitChanges() {
        guard let document,
              let editingObjectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        let mutable = trans.mutate(editingObjectID)

        let sorted = curveView.sortedPoints()
        mutable["graphical_function_points"] = Variant(sorted)
        mutable["interpolation_method"] = Variant(interpolationMethodName(curveView.interpolation))
    }

    private func resetToOriginals() {
        workingPoints = originalPoints
        workingInterpolation = originalInterpolation
        curveView.points = originalPoints
        curveView.interpolation = originalInterpolation
        curveView.fitRange()
        syncRangeFieldsFromCurve()
        syncInterpolationRadio()
    }

    // MARK: - Helpers

    private func parseInterpolation(_ name: String) -> GraphicalFunction.InterpolationMethod {
        switch name.lowercased() {
        case "step": return .step
        case "cubic": return .cubic
        default: return .linear
        }
    }

    private func interpolationMethodName(_ method: GraphicalFunction.InterpolationMethod) -> String {
        switch method {
        case .step: return "step"
        case .cubic: return "cubic"
        case .linear: return "linear"
        default: return "linear"
        }
    }

    private func syncRangeFieldsFromCurve() {
        minXStr = InputTextBuffer(String(format: "%.2f", curveView.minX))
        maxXStr = InputTextBuffer(String(format: "%.2f", curveView.maxX))
        minYStr = InputTextBuffer(String(format: "%.2f", curveView.minY))
        maxYStr = InputTextBuffer(String(format: "%.2f", curveView.maxY))
    }

    private func syncInterpolationRadio() {
        interpolationLinear = (curveView.interpolation == .linear)
        interpolationStep = (curveView.interpolation == .step)
        interpolationCubic = (curveView.interpolation == .cubic)
    }

    private func setInterpolation(_ method: GraphicalFunction.InterpolationMethod) {
        workingInterpolation = method
        curveView.interpolation = method
        syncInterpolationRadio()
    }
}
