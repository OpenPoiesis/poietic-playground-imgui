//
//  ResultStatisticsSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/03/2026.
//


import PoieticCore
import PoieticFlows

/// System that computes statistics from the simulation result.
///
/// Used to gather the following information:
///
/// - Ranges of numerical values: min, max
///
/// - **Input:** ``SimulationResult`` singleton – required.
/// - **Output:**
///     - Add ``RegularTimeSeries`` and ``NumericValueStats`` for each numeric simulation object,
///       removed of all objects for which there is no numeric series result.
/// - **Forgiveness:** Does nothing if there is no simulation plan neither simulation result.
/// - **Issues:** No issues created.
///
public struct TimeSeriesProcessingSystem: System {
    public static let dependencies: [SystemDependency] = [
        .after(StockFlowSimulationSystem.self),
    ]

    public static func update(_ world: World) throws (InternalSystemError) {
        guard let plan: SimulationPlan = world.singleton(),
              let result: SimulationResult = world.singleton()
        else { return }
        
        for simObject in plan.simulationObjects {
            guard let entity = world.entity(simObject.objectID) else { continue }
            guard let series = result.regularTimeSeries(simObject.variableReference) else {
                entity.removeComponent(RegularTimeSeries.self)
                entity.removeComponent(NumericValueStats.self)
                continue
            }

            let stats = NumericValueStats(min: series.dataMin, max: series.dataMax)
            entity.setComponent(stats)
            entity.setComponent(series)
        }
    }
}

