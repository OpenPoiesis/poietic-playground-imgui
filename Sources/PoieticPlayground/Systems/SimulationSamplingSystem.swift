//
//  SimulationSamplingSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/07/2026.
//

import PoieticCore
import PoieticFlows


/// System that assigns current numeric value to the simulation objects.
///
/// - **Dependency:** no dependency
/// - **Input:**
///     - Singleton ``SimulationResult``
///     - Singleton ``SimulationReplayTime`` for current simulation step
///     - Singleton ``SimulationPlan`` for simulation object list
/// - **Output:** Assign ``NumericSimulationSample`` for entities which have current simulation
///     value, remove from entities where the value is missing in the current state.
/// - **Forgiveness:** Does nothing if any of the singletons are not present.
///
struct SimulationSamplingSystem: System {
    // TODO: This is using old way of storing simulation data - in their respective structures, instead of components.
    public static let dependencies: [SystemDependency] = []
    
    static func update(_ world: World) throws(InternalSystemError) {
        guard let result: SimulationResult = world.singleton(),
              let plan: SimulationPlan = world.singleton()
        else { return }
        
        let step: Int
        if let time: SimulationReplayTime = world.singleton() {
            step = time.step
        }
        else {
            step = 0
        }
        guard let sample = result.sample(at: step) else { return }
        
        for simObject in plan.simulationObjects {
            guard let entity = world.entity(simObject.objectID) else { continue }

            if let doubleValue = sample.doubleValue(for: simObject.variableReference) {
                entity.setComponent(NumericValueSample(value: doubleValue))
            }
            else {
                entity.removeComponent(NumericValueSample.self)
            }
        }
    }
}
