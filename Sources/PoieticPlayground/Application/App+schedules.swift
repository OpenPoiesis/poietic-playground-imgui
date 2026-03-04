//
//  Schedules.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming

// Inherited schedules:
// - FrameChangeSchedule
// - SimulationSchedule

/// Result player step update.
//enum ReplayStepSchedule: ScheduleLabel { }

/// Systems run during interactive editing such as selection movement or handle dragging.
///
enum InteractivePreviewSchedule: ScheduleLabel { }

// Action-specific schedules
enum ParameterResolutionSchedule: ScheduleLabel { }

extension Application {
    
    static func setupSchedules(_ world: World) {
        world.addSchedule(Schedule(
            label: FrameChangeSchedule.self,
            systems:
                PoieticFlows.SimulationPlanningSystems
                + PoieticFlows.SimulationPresentationSystems
                + [
//                    FrameChangeSystem,
                    // From Diagramming
                    ErrorIndicatorSystem.self,
                    BlockCreationSystem.self,
                    TraitConnectorCreationSystem.self,
                    ConnectorGeometrySystem.self,
                ]
        ))
        
//        world.addSchedule(Schedule(
//            label: SelectionChangeSchedule.self,
//            systems: [
//            ]
//        ))
        world.addSchedule(Schedule(
            label: InteractivePreviewSchedule.self,
            systems: [
                // TODO: Remove error indicator system once we have relative placement
                ErrorIndicatorSystem.self,
                // From Diagramming
                ConnectorGeometrySystem.self,
            ]
        ))

        world.addSchedule(Schedule(
            label: SimulationSchedule.self,
            systems: [
                StockFlowSimulationSystem.self,
                ResultProcessingSystem.self,
            ]
        ))

        world.addSchedule(Schedule(
            label: ParameterResolutionSchedule.self,
            systems: [
                ComputationOrderSystem.self,
                NameResolutionSystem.self,
                ExpressionParserSystem.self,
                ParameterResolutionSystem.self,
                ParameterConnectionProposalSystem.self,
            ]
        ))
    }

    func setupEventSchedules() {
//        eventSchedules[.worldChanged] = nil
//        eventSchedules[.designFrameChanged] = FrameChangeSchedule.self
//        eventSchedules[.selectionChanged] = nil
//        eventSchedules[.playerStarted] = nil
//        eventSchedules[.playerStep] = nil
//        eventSchedules[.playerStopped] = nil
//        eventSchedules[.simulationStarted] = nil
//        eventSchedules[.simulationFinished] = nil
//        eventSchedules[.simulationFailed] = nil
//        eventSchedules[.previewChanged] = InteractivePreviewSchedule.self

    }
    

    /// Convenience runner of a schedule that handles errors and displays an error panel through
    /// the application.
    ///
    /// World runs a given schedule. If an error occurs then it is displayed to the user through
    /// the application.
    ///
    /// - Returns: `true` on successful run, `false` on error.
    ///
    @discardableResult
    func run(schedule: ScheduleLabel.Type, session: Session) -> Bool {
        let label = String(describing: schedule)
//        log("Running schedule: \(label)")
        do {
            try session.world.run(schedule: schedule)
        }
        catch {
            self.alert(title: "Internal System Error", message: String(describing: error))
            self.logError("Internal system error:" + String(describing: error))
            return false
        }
        return true
    }
}
