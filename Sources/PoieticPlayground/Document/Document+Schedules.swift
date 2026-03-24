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

extension Document {
    static func setupSchedules(_ world: World) {
        world.addSchedule(Schedule(
            label: FrameChangeSchedule.self,
            systems:
                PoieticFlows.SimulationPlanningSystems
                + PoieticFlows.SimulationPresentationSystems
                + [
                    NewChartResolutionSystem.self,
                    // From Diagramming
                    ErrorIndicatorSystem.self,
                    BlockCreationSystem.self,
                    TraitConnectorCreationSystem.self,
                    ConnectorGeometrySystem.self,
                ]
        ))
        
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
                TimeSeriseProcessingSystem.self,
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

}
