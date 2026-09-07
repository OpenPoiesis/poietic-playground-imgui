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

    var timeSettings: SimulationTimeSettings = SimulationTimeSettings()

    /// Number of steps.
    var lastSampleIndex: Int = 0
    
    /// Remaining real time to next step.
    var timeToStep: Double = 0
    /// Real-time duration of a step in seconds.
    var stepDuration: Double = 0.1
    
    /// Number of currently replayed simulation step.
    var currentStep: Int = 0
    /// Current simulation time.
    var currentTime: Double {
        timeSettings.startTime + Double(currentStep) * timeSettings.timeStep
    }

    var document: Document? = nil

    func bind(_ document: Document) {
        self.document = document
    }
    
    func update(_ delta: Double) {
        guard isRunning else { return }
        if timeToStep <= 0 {
            nextStep()
            timeToStep = stepDuration
        }
        else {
            timeToStep -= delta
        }
    }
   
    func onDesignPlaneChanged(_ document: Document) {
        // We are assuming that simulation planning schedule was run.
        // Settings are set regardless whether we have a plan or not.
        let settings: SimulationTimeSettings = document.world.singleton() ?? SimulationTimeSettings()

        if !document.world.hasSingleton(SimulationPlan.self) {
            self.isRunning = false
        }

        self.lastSampleIndex = Int(settings.steps)
        self.currentStep = clampStep(self.currentStep)
    }

    func onSimulationFailed(_ document: Document) {
        self.isRunning = false
    }
    func onSimulationFinished(_ document: Document) {
        if let result: SimulationResult = document.world.singleton() {
            self.lastSampleIndex = result.sampleCount - 1
            self.currentStep = clampStep(self.currentStep)
        }
        stateChanged()
    }
    /// Run ``PlayerStepSchedule`` and then trigger the ``Document/Event/simulationPlayerStep``
    /// event.
    ///
    func stateChanged() {
        guard let document else { return }

        let component = SimulationReplayTime(step: currentStep, time: currentTime)
        document.world.setSingleton(component)
        do {
            try document.world.run(schedule: PlayerStepSchedule.self)
        }
        catch {
            document.queueAlert(title: "Player Schedule Failed",
                                message: "Please file an issue with developers")
        }
        document.trigger(.simulationPlayerStep)
    }
    
    /// Rewind the player to the first simulation step.
    func toFirstStep() {
        currentStep = 0
        stateChanged()
    }
    
    /// Forward the player to the last simulation step.
    func toLastStep() {
        currentStep = lastSampleIndex
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
    /// Clamp step to be in range between 0 and ``lastSampleIndex``
    func clampStep(_ step: Int) -> Int {
        return max(0, min(step, lastSampleIndex))
    }
    func setCurrentStep(_ step: Int) {
        let adjustedStep: Int = clampStep(step)
        guard adjustedStep != currentStep else { return }
        currentStep = adjustedStep
        stateChanged()
    }

    func setCurrentTime(_ time: Double) {
        let distance = time - timeSettings.startTime
        let step = Int((distance / timeSettings.timeStep).rounded())
        setCurrentStep(step)
    }

    func nextStep() {
        currentStep += 1
        if currentStep > lastSampleIndex {
            guard isLooping else {
                currentStep = lastSampleIndex
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
            currentStep = lastSampleIndex
        }
        stateChanged()
    }
}
