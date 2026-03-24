//
//  Dashboard.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/03/2026.
//

import CIimgui
import PoieticCore
import PoieticFlows

@MainActor
class Dashboard {
    static let ChartSize = ImVec2(100, 80)
    var isVisible: Bool = true
    var chartViews: [ChartView] = []
    
    func onDesignFrameChanged(_ session: Session) {
        // TODO: Reload all charts
        let world = session.world
        print("Dashboard here")
        
        chartViews.removeAll()
        for (chartEntity, _) in world.query(Chart.self) {
            let view = ChartView(chart: chartEntity)
            chartViews.append(view)
        }
    }
    
    func draw(session: Session?) {
        guard isVisible else { return }
        
        ImGui.Begin("Dashboard", &isVisible,
                                        ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_AlwaysAutoResize)

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
        
        ImGui.BeginGroup()
        let canCreate = !(session?.selection.isEmpty ?? true)
        if canCreate && ImGui.Button("Add", ImVec2()),
           let session
        {
            // TODO: Add chart
            print("ADD CHART")
            let command = CreateChartCommand(
                name: nil,
                series: Array(session.selection.ids)
            )
            session.queueCommand(command)
        }
        ImGui.EndGroup()
        
        ImGui.End()

    }
}
