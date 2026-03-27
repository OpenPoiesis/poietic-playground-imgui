//
//  ChartInspectorSection.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/03/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui

func unionBounds(entities: [RuntimeEntity]) -> ValueBounds? {
    guard !entities.isEmpty else { return ValueBounds(min:0, max:0, baseline: 0) }
    var result: ValueBounds? = nil
    var entities = entities
    while !entities.isEmpty {
        let current = entities.removeFirst()
        guard let series: RegularTimeSeries = current.component() else { continue }
        let seriesBounds = ValueBounds(min: series.dataMin, max: series.dataMax, baseline: 0.0)
        if let currentBounds = result {
            result = currentBounds.union(seriesBounds)
        }
        else {
            result = seriesBounds
        }
    }
    return result
}

class ChartInspectorSection: InspectorSection {
    var trait: Trait { Trait.NumericValue }
    var category: InspectorPanel.Category { .overview }
    let title: String = "Chart"
    let inspectedAttributes: [String] = []

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .overview

    static let ChartSize = ImVec2(100, 80)
    var chartView: FixedChartView
    
    init() {
        self.chartView = FixedChartView()
    }
 
    func onSelectionChanged(_ document: Document) {
        let selection = document.selection
        let world = document.world
        let chart = Chart() // TODO: Use some default axis setup
        var series: [ChartSeries] =  []
        for objectID in selection {
            guard let entity = world.entity(objectID) else { continue }
            let chartSeries = ChartSeries(
                target: entity.runtimeID,
                colorKey: nil,
                displayBounds: DisplayValueBounds()
            )
            series.append(chartSeries)
        }
        chartView.series = series
        chartView.chart = chart
        chartView.world = world
        // we need world and frame here
    }

    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
        chartView.draw()
    }
}
