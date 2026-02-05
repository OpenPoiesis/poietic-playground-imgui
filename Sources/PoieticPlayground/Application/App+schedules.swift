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
enum UpdateVisualsSchedule: ScheduleLabel { }

/// Systems run during interactive editing such as selection movement or handle dragging.
///
enum InteractivePreviewSchedule: ScheduleLabel { }

// Action-specific schedules
enum ParameterResolutionSchedule: ScheduleLabel { }
enum DiagramExportSchedule: ScheduleLabel { }

extension Application {
    
    func setupSchedules() {
        world.addSchedule(Schedule(
            label: FrameChangeSchedule.self,
            systems:
                PoieticFlows.SimulationPlanningSystems
                + PoieticFlows.SimulationPresentationSystems
                + [
                    // From Diagramming
                    BlockCreationSystem.self,
                    TraitConnectorCreationSystem.self,
                    ConnectorGeometrySystem.self,
                ]
        ))
        world.addSchedule(Schedule(
            label: UpdateVisualsSchedule.self,
            systems: [
                    // From Diagramming
                    BlockCreationSystem.self,
                    TraitConnectorCreationSystem.self,
                    ConnectorGeometrySystem.self,
                ]
        ))

        world.addSchedule(Schedule(
            label: InteractivePreviewSchedule.self,
            systems: [
                // From Diagramming
                ConnectorGeometrySystem.self,
            ]
        ))

        world.addSchedule(Schedule(
            label: SimulationSchedule.self,
            systems: PoieticFlows.SimulationRunningSystems
        ))

        world.addSchedule(Schedule(
            label: DiagramExportSchedule.self,
            systems: [
                BlockCreationSystem.self,
                TraitConnectorCreationSystem.self,
                ConnectorGeometrySystem.self
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
    
    /// Convenience runner of a schedule that handles errors and displays an error panel through
    /// the application.
    ///
    /// World runs a given schedule. If an error occurs then it is displayed to the user through
    /// the application.
    ///
    /// - Returns: `true` on successful run, `false` on error.
    ///
    @discardableResult
    func run(schedule: ScheduleLabel.Type) -> Bool {
        let label = String(describing: schedule)
        log("Running schedule: \(label)")
        do {
            try self.world.run(schedule: schedule)
        }
        catch {
            self.alert(title: "Internal System Error", message: String(describing: error))
            self.logError("Internal system error:" + String(describing: error))
            return false
        }
        return true
    }
}
