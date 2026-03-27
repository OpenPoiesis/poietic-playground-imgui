//
//  Document+World.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import PoieticCore
import Diagramming

extension Document {
    func update(_ timeDelta: Double) {
        self.updateWorld()
    }
    
    /// Set world singletons when the world changes.
    func setupWorld(notation: Notation? = nil) {
        Self.setupSchedules(world)
        
        if let notation {
            world.setSingleton(notation)
        }
        else {
            world.setSingleton(Notation.DefaultNotation)
        }
    }
    
    func updateWorld(force: Bool = false) {
        // TODO: This method does multiple things that need to be decoupled
        if design.currentFrame !== world.frame || force {
            if let frame = design.currentFrame {
                world.setFrame(frame)
            }
            // TODO: [IMPORTANT] Remove components with frame lifetime (backing does not exist yet)
            self.run(schedule: FrameChangeSchedule.self)
            updateSelectionOverview()
            trigger(.designFrameChanged)
            trigger(.selectionChanged)
            
            if self.run(schedule: SimulationSchedule.self) {
                trigger(.simulationFinished)
            }
            else {
                trigger(.simulationFailed)
            }
            // TODO: Remove temporary components here (such as previews)
        }
        
        if requiresInteractivePreviewUpdate {
            self.run(schedule: InteractivePreviewSchedule.self)
            resetInteractivePreviewUpdate()
            trigger(.previewChanged)
        }
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
//        log("Running schedule: \(label)")
        do {
            try world.run(schedule: schedule)
        }
        catch {
            self.queueAlert(title: "Internal System Error", message: String(describing: error))
            self.logError("Internal system error:" + String(describing: error))
            return false
        }
        return true
    }
}
