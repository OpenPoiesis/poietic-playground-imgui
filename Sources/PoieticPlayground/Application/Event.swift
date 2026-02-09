//
//  Event.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 08/02/2026.
//
import PoieticCore


// Events before drawing vs. events after drawing?

enum ApplicationEvent: CaseIterable {
    // NOTE: We might consider changing the app event to a protocol, similar to schedule label.
    case worldChanged // design reset
    case designFrameChanged // from Command
        // -> Frame Change schedule
        // -> triggers Simulation schedule
    case selectionChanged

    case playerStarted
    case playerStep
    case playerStopped

    case simulationStarted
    case simulationFinished
    case simulationFailed
    
    case previewChanged
        // -> Update visuals schedule
        // -> Interactive preview
    
}
