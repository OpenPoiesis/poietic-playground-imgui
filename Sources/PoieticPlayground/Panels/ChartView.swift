//
//  ChartView.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/03/2026.
//

import CIimgui
import PoieticCore
import PoieticFlows

//convenience init(entity: RuntimeEntity? = nil) {
//    var series: [ChartSeries] = []
//    let chart: Chart?
//    if let entity {
//        for child in entity.children {
//            guard let seriesComponent: ChartSeries = child.component()
//            else { continue }
//
//            series.append(seriesComponent)
//        }
//        chart = entity.component()
//    }
//    else {
//        chart = nil
//        series = []
//    }
//    self.init(world: entity?.world, chart: chart ?? Chart(), series: series)
//}
//
// FIXME: Use ImPlot (https://github.com/epezent/implot)


struct _TimeSeriesWrapper {
    let series: RegularTimeSeries
}

func chartValueGetter(data: UnsafeMutableRawPointer?, index: Int32) -> Float {
    guard let data else { return 0 }
    let series = data.assumingMemoryBound(to: _TimeSeriesWrapper.self).pointee.series
    return Float(series.data[Int(index)])
}


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
class FixedChartView {
    var world: World?

    var chart: Chart?
    var series: [ChartSeries]
    var plotSize: ImVec2

    init(chart: Chart? = nil, series: [ChartSeries] = [], world: World? = nil) {
        self.chart = chart
        self.series = series
        self.world = world
        plotSize = ImVec2(100.0, 80.0)
    }
    
    func draw() {
        guard let chart else { return }
        // 1. Get series
        let cursor = ImGui.GetCursorPos()
        for (index, series) in self.series.enumerated() {
            ImGui.SetCursorPos(cursor)
            drawSeries(series, id: String(index))
        }
    }

    func drawSeries(_ chartSeries: ChartSeries, id: String) {
        guard let world else { return }
        guard let target = world.entity(chartSeries.target),
              let timeSeries: RegularTimeSeries = target.component(),
              let stats: NumericValueStats = target.component()
        else { return }
        
        var wrap = _TimeSeriesWrapper(series: timeSeries)
        ImGui.PlotLines("##plot"+id,
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
