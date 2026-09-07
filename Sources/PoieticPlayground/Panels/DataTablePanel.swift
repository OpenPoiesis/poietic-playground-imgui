//
//  DataTablePanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/08/2026.

//  Spreadsheet-style table displaying simulation result data.
//
//  Written by help of an agent.

import CIimgui
import PoieticCore
import PoieticFlows

/// Panel that displays the simulation result as a scrollable data table.
///
/// Columns: Step, Time, then one column per simulation object (ordered by
/// variable index, header = object name).
///
/// Features:
/// - All / Selected radio filter — limits columns to currently selected objects
/// - Current player step row highlighted
/// - Freeze-pane header (Step + Time always visible)
/// - Virtual scrolling via ImGui table
///
/// Designed to be extended: the name `DataTablePanel` is deliberately generic
/// so that future result-like data sources can reuse this panel.
@MainActor
class DataTablePanel: Panel {

    var isVisible: Bool = false
    
    var currentStepColor = Color(red: 0.7, green: 0.7, blue: 1.0)

    weak var document: Document?

    // MARK: - State

    private var showSelectedOnly: Bool = false

    // MARK: - Panel

    func bind(_ document: Document) {
        self.document = document
    }

    func update(_ timeDelta: Double) {}

    func draw() {
        guard let document,
              let plane = document.world.plane
        else {
            ImGui.Begin("Data Table", &self.isVisible)
            ImGui.TextUnformatted("No data available.")
            ImGui.End()
            return
        }

        let world = document.world
        guard let result: SimulationResult = world.singleton(),
              let plan: SimulationPlan = world.singleton()
        else {
            ImGui.Begin("Data Table")
            ImGui.TextUnformatted("No simulation result.")
            ImGui.End()
            return
        }

        // Resolve current step for highlighting
        let replayTime: SimulationReplayTime? = world.singleton()
        let currentStep = replayTime?.step ?? 0

        // Resolve selected object IDs
        let selectedIDs: Set<ObjectID> = showSelectedOnly ? Set(document.selection.ids) : []

        // Build ordered list of visible simulation objects
        var visibleObjects: [SimulationObject] = []
        for simObj in plan.simulationObjects {
            if showSelectedOnly && !selectedIDs.contains(simObj.objectID) {
                continue
            }
            visibleObjects.append(simObj)
        }

        // Resolve object names from the plane
        var objectNames: [ObjectID: String] = [:]
        
        for simObj in visibleObjects {
            if let object = plane[simObj.objectID],
               let name: String = object["name"] {
                objectNames[simObj.objectID] = name
            }
            else {
                objectNames[simObj.objectID] = "\(simObj.objectID)"
            }
        }

        drawContent(result: result,
                    visibleObjects: visibleObjects,
                    objectNames: objectNames,
                    currentStep: currentStep)
    }

    // MARK: - Content

    private func drawContent(result: SimulationResult,
                             visibleObjects: [SimulationObject],
                             objectNames: [ObjectID: String],
                             currentStep: Int)
    {
        let stepCount = result.sampleCount
        let columnCount = 2 + visibleObjects.count  // Step, Time, + data columns

        ImGui.Begin("Data Table", &isVisible)

        // -- Top controls --
        if ImGui.RadioButton("All", !showSelectedOnly) {
            showSelectedOnly = false
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Selected", showSelectedOnly) {
            showSelectedOnly = true
        }

        ImGui.SameLine()
        ImGui.TextDisabledUnformatted("Step: \(currentStep)/\(max(0, stepCount - 1))")

        ImGui.Separator()

        // Table flags: frozen first two columns (Step, Time), scrollable
        let tableFlags: ImGuiTableFlags =
            ImGuiTableFlags(ImGuiTableFlags_ScrollX.rawValue |
                            ImGuiTableFlags_ScrollY.rawValue |
                            ImGuiTableFlags_RowBg.rawValue |
                            ImGuiTableFlags_SizingFixedFit.rawValue |
                            ImGuiTableFlags_HighlightHoveredColumn.rawValue)

        guard ImGui.BeginTable("##data_table", Int32(columnCount), tableFlags, ImVec2(0, 0))
        else {
            ImGui.End()
            return
        }

        // -- Header --
        ImGui.TableSetupColumn("Step", ImGuiTableColumnFlags(ImGuiTableColumnFlags_NoReorder.rawValue), 0, 0)
        ImGui.TableSetupColumn("Time", ImGuiTableColumnFlags(ImGuiTableColumnFlags_NoReorder.rawValue), 0, 0)
        for simObj in visibleObjects {
            let name = objectNames[simObj.objectID] ?? "\(simObj.objectID)"
            ImGui.TableSetupColumn(name, ImGuiTableColumnFlags(ImGuiTableColumnFlags_None.rawValue), 0, 0)
        }
        ImGui.TableSetupScrollFreeze(0, 1)  // freeze header row, but not columns (ImGui freeze is unreliable with ScrollX)
        ImGui.TableHeadersRow()

        // -- Body (virtual scrolling) --
        var clipper = ImGuiListClipper()
        clipper.Begin(Int32(stepCount), -1)
        while clipper.Step() {
            let displayStart = Int(clipper.DisplayStart)
            let displayEnd = Int(clipper.DisplayEnd)

            for step in displayStart..<displayEnd {
                guard let sample = result.sample(at: step) else { continue }

                ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

                // Highlight current step
                if step == currentStep {
                    ImGui.TableSetBgColor(
                        ImGuiTableBgTarget(ImGuiTableBgTarget_RowBg0.rawValue),
                        currentStepColor.imIntValue)
                }

                // Step
                ImGui.TableNextColumn()
                ImGui.TextUnformatted("\(step)")

                // Time
                ImGui.TableNextColumn()
                let timeStr = formatTime(sample.time)
                ImGui.TextUnformatted(timeStr)

                // Data columns
                for simObj in visibleObjects {
                    ImGui.TableNextColumn()
                    let value: Variant = sample.value(for: simObj.variableReference) ?? Variant("")
                    let text = formatValue(value)
                    ImGui.TextUnformatted(text)
                }
            }
        }
        clipper.End()

        ImGui.EndTable()
        ImGui.End()
    }

    // MARK: - Formatting

    private func formatTime(_ time: Double) -> String {
        // Show up to 2 decimal places, strip trailing zeros
        let formatted = String(format: "%.2f", time)
        if formatted.hasSuffix(".00") {
            return String(formatted.dropLast(3))
        }
        if formatted.hasSuffix("0") {
            return String(formatted.dropLast())
        }
        return formatted
    }

    private func formatValue(_ value: Variant) -> String {
        if let dbl = try? value.doubleValue() {
            return String(format: "%.4f", dbl)
        }
        return String(describing: value)
    }
}
