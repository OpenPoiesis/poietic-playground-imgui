//
//  ResultPlayer.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/03/2026.
//

import PoieticCore
import PoieticFlows

struct SimulationReplayTime: Component {
    let step: Int
    let time: Double
}

class ResultPlayer {
    var isRunning: Bool = false
    var isLooping: Bool = true

    /// Initial simulation time.
    var initialTime: Double = 0.0   // From result
    /// Time delta of simulation time.
    var timeDelta: Double = 1.0     // From result
    /// Number of steps.
    var lastStep: Int = 0           // From result
    
    /// Remaining real time to next step.
    var timeToStep: Double = 0
    /// Real-time duration of a step in seconds.
    var stepDuration: Double = 0.1
    
    /// Number of currently replayed simulation step.
    var currentStep: Int = 0
    /// Current simulation time.
    var currentTime: Double {
        initialTime + Double(currentStep) * timeDelta
    }

    var document: Document? = nil

    func bind(_ document: Document) {
        self.document = document
    }
    
    func update(_ delta: Double) {
        if isRunning {
            if timeToStep <= 0 {
                nextStep()
                timeToStep = stepDuration
            }
            else {
                timeToStep -= delta
            }
        }
    }
   
    func onDesignFrameChanged(_ document: Document) {
        guard let plan: SimulationPlan = document.world.singleton() else {
            self.isRunning = false
            return
            // TODO: Reset variables
        }
        updateFromSettings(plan.simulationSettings)
    }
    
    func updateFromSettings(_ settings: SimulationSettings) {
        print("Updating from settings: \(settings)")
        self.initialTime = settings.initialTime
        self.timeDelta = settings.timeDelta
        self.lastStep = Int(settings.steps)
        self.currentStep = max(0, min(self.currentStep, Int(settings.steps) - 1))
        stateChanged()
    }
    func onSimulationFailed(_ document: Document) {
        self.isRunning = false
    }
    func onSimulationFinished(_ document: Document) {
        // Nothing
    }
    /// Run the systems for player step and then notify Godot through a signal.
    ///
    func stateChanged() {
        guard let document else { return }

        let component = SimulationReplayTime(step: currentStep, time: currentTime)
        document.world.setSingleton(component)
        document.trigger(.simulationPlayerStep)
        //        world.run(schedule: ReplayStepSchedule.self) else { return }
//        simulationPlayerStep.emit()
    }
    
    /// Rewind the player to the first simulation step.
    func toFirstStep() {
        currentStep = 0
        stateChanged()
    }
    
    /// Forward the player to the last simulation step.
    func toLastStep() {
        currentStep = lastStep
        stateChanged()
    }

    func run() {
        self.isRunning = true
        stateChanged()
    }

    func stop() {
        guard isRunning else { return }
        self.isRunning = false
    }
    
    func setCurrentStep(_ step: Int) {
        let adjustedStep: Int = max(0, min(step, lastStep - 1))
        guard adjustedStep != currentStep else { return }
        currentStep = adjustedStep
        stateChanged()
    }

    func setCurrentTime(_ time: Double) {
        let distance = time - initialTime
        let step = Int((distance / timeDelta).rounded())
        setCurrentStep(step)
    }

    func nextStep() {
        currentStep += 1
        if currentStep > lastStep {
            guard isLooping else {
                currentStep = lastStep
                stop()
                return
            }
            currentStep = 0
        }
        stateChanged()
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
        if currentStep <= 0 {
            guard isLooping else {
                currentStep = 0
                stop()
                return
            }
            currentStep = lastStep
        }
        stateChanged()
    }
}
