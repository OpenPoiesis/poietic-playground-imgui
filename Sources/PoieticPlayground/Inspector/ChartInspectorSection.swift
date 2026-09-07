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
    var trait: Trait { SimulationDomain.Traits.NumericValue }
    var category: InspectorPanel.Category { .overview }
    let title: String = "Chart"
    let inspectedAttributes: [String] = []

    static let displayOrder: Int = 0
    static let inspectorCategory: InspectorPanel.Category = .overview

    static let ChartSize = ImVec2(100, 80)
    var chartView: ChartView
    var chartEntity: RuntimeEntity?
    
    init() {
        self.chartView = ChartView()
        self.chartEntity = nil
    }
    func bind(_ document: Document)  {
        chartEntity = nil
        chartView.chartEntity = nil
    }
 
    func onSelectionChanged(_ document: Document) {
        let selection = document.selection
        let world = document.world
        let chart: RuntimeEntity
        if let existing = chartEntity, existing.world === world
        {
            for child in existing.children { child.despawn() }
            chart = existing
        }
        else {
            // TODO: Use some default axis setup
            chart = world.spawn(Chart())
            self.chartEntity = chart
        }
        
        for objectID in selection {
            guard let target = world.entity(objectID) else { continue }
            // TODO: Pass nil and let the ChartView fetch the color
            let colorKey: AdaptableColorKey?
            if let color: AdaptableColor = target.component() {
                colorKey = color.key
            }
            else {
                colorKey = nil
            }
            let seriesEntity = world.spawn(
                ChartSeries(colorKey: colorKey, displayBounds: DisplayValueBounds())
            )
            seriesEntity.relate(ChildOf(), to: chart.runtimeID)
            seriesEntity.relate(RepresentationOf(), to: target.runtimeID)
        }

        chartView.chartEntity = chart
    }

    func update(_ document: Document) { /* Nothing for now */ }

    func draw(_ document: Document) {
        chartView.draw()
    }
}
