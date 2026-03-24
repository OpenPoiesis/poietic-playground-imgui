//
//  Dashboard.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/03/2026.
//

import CIimgui
import PoieticCore
import PoieticFlows

/// Makeshift dashboard.
@MainActor
class Dashboard {
    static let ChartSize = ImVec2(100, 80)
    var isVisible: Bool = true
    var chartViews: [ChartView] = []
    
    func onDesignFrameChanged(_ document: Document) {
        // TODO: Reload all charts
        let world = document.world
        print("Dashboard here")
        
        chartViews.removeAll()
        for (chartEntity, _) in world.query(Chart.self) {
            let view = ChartView(chart: chartEntity)
            chartViews.append(view)
        }
    }
    
    func draw(document: Document?) {
        guard isVisible else { return }
        
        ImGui.Begin("Dashboard", &isVisible,
                                        ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_AlwaysAutoResize)

        if chartViews.isEmpty {
            // TODO: Have a nicer indicator/default size
            ImGui.TextUnformatted("(empty)")
        }
        for (index, view) in chartViews.enumerated() {
            ImGui.PushID(Int32(index))
            ImGui.BeginGroup()
            view.draw()
            let entity = view.chartEntity
            let name = entity?.designObject?.name ?? "(unnamed)"
            ImGui.TextUnformatted(name)
            ImGui.EndGroup()
            ImGui.PopID()
        }
        // TODO: Context menu: delete, select targets, inspect
        
        let canCreate = !(document?.selection.isEmpty ?? true)
        if canCreate {
            ImGui.BeginGroup()
            if ImGui.Button("Add", ImVec2()),
               let document
            {
                // TODO: Add chart
                print("ADD CHART")
                let command = CreateChartCommand(
                    name: nil,
                    series: Array(document.selection.ids)
                )
                document.queueCommand(command)
            }
            ImGui.EndGroup()
        }
        
        ImGui.End()

    }
}
