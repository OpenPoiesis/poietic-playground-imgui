//
//  ResultStatisticsSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/03/2026.
//


import PoieticCore
import PoieticFlows

struct NumericValueStats: Component {
    let min: Double
    let max: Double
    
    var range: Double { max - min }
    
    init(min: Double, max: Double) {
        precondition(min <= max)
        self.min = min
        self.max = max
    }
}


/// System that computes statistics from the simulation result.
///
/// Used to gather the following information:
///
/// - Ranges of numerical values: min, max
///
/// - **Input:** ``SimulationResult`` singleton – required.
/// - **Output:** ``RegularTimeSeries`` and ``NumericValueStats`` for each numeric simulation object.
/// - **Forgiveness:** Does nothing if there is no simulation plan neither simulation result.
/// - **Issues:** No issues created.
///
public struct TimeSeriseProcessingSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(StockFlowSimulationSystem.self),
    ]
    public init(_ world: World) { }
    public func update(_ world: World) throws (InternalSystemError) {
        guard let plan: SimulationPlan = world.singleton(),
              let result: SimulationResult = world.singleton()
        else { return }
        
        for simObject in plan.simulationObjects {
            guard let entity = world.entity(simObject.objectID) else { continue }
            let series = result.unsafeTimeSeries(at: simObject.variableIndex)
            let stats = NumericValueStats(min: series.dataMin, max: series.dataMax)

            entity.setComponent(stats)
            entity.setComponent(series)
        }
    }
}

