//
//  Dashboard.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/03/2026.
//

import CIimgui
import PoieticCore
import PoieticFlows

class NEWChartComponent {
    
}

struct _TimeSeriesWrapper {
    let series: RegularTimeSeries
}

func chartValueGetter(data: UnsafeMutableRawPointer?, index: Int32) -> Float {
    guard let data else { return 0 }
    let series = data.assumingMemoryBound(to: _TimeSeriesWrapper.self).pointee.series
    return Float(series.data[Int(index)])
}

// FIXME: Use ImPlot (https://github.com/epezent/implot)

@MainActor
class ChartView {
    
    var chartEntity: RuntimeEntity?
    var chartSeries: [ChartSeries] {
        guard let chartEntity else { return [] }

        var series: [ChartSeries] = []
        for child in chartEntity.children {
            guard let seriesComponent: ChartSeries = child.component()
            else { continue }

            series.append(seriesComponent)
        }
        return series
    }
    
    var world: World? { chartEntity?.world }
    var plotSize: ImVec2

    init(chart: RuntimeEntity? = nil) {
        chartEntity = chart
        plotSize = ImVec2(100.0, 80.0)
    }
    
    func draw() {
        guard let chartEntity else { return }
        // 1. Get series
        let cursor = ImGui.GetCursorPos()
        for child in chartEntity.children {
            ImGui.SetCursorPos(cursor)
            drawSeries(chart: chartEntity, seriesEntity: child)
        }
    }

    func drawSeries(chart: RuntimeEntity, seriesEntity: RuntimeEntity) {
        guard let world else { return }
        guard let chartSeries: ChartSeries = seriesEntity.component(),
              let target = world.entity(chartSeries.target),
              let timeSeries: RegularTimeSeries = target.component(),
              let stats: NumericValueStats = target.component()
        else { return }
        
        var wrap = _TimeSeriesWrapper(series: timeSeries)
        ImGui.PlotLines("##plot\(seriesEntity.runtimeID)",
                        chartValueGetter,
                        &wrap,
                        Int32(timeSeries.data.count),
                        0, // offset
                        nil, // overlay text,
                        Float.greatestFiniteMagnitude,
                        Float.greatestFiniteMagnitude,
                        plotSize)
    }
}

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
    
    func draw() {
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
        if ImGui.Button("Add", ImVec2()) {
            // TODO: Add chart
            print("ADD CHART")
        }
        ImGui.EndGroup()
        
        ImGui.End()

    }
}
