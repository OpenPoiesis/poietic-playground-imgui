//
//  Session.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import Foundation
import Diagramming

/// Represents and controls the design document.
///
/// Responsibilities:
/// - Owns Design – the user created content, the model (Design)
/// - Owns World – derived and simulation data
/// - Manages file I/O
/// - Manages transactions, command queue
/// - Selection state
/// - Observer/event system
///
class Session {
    enum Event {
        /// Triggered on each ``Session/changeSelection(_:)``.
        case selectionChanged
        /// Triggered when world frame has been changed.
        ///
        /// For example: on a transaction or undo/redo action.
        ///
        case designFrameChanged
        case previewChanged
        
        case simulationFinished
        case simulationFailed

//        case simulationPlayerStarted
        case simulationPlayerStep
//        case simulationPlayerStopped
    }

    typealias EventObserver = ((Session) -> Void)

    var observers: [Event:[EventObserver]]
    
    let design: Design
    var designURL: URL? = nil
    
    var transaction: TransientFrame?
    var hasTransaction: Bool { transaction != nil }
    var commandQueue: [any Command]

    let world: World
    var selection: Selection
    var selectionOverview: SelectionOverview
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application frame.
    var requiresInteractivePreviewUpdate: Bool

    init(design: Design, url: URL? = nil, notation: Notation? = nil) {
        self.observers = [:]
        
        self.design = design
        self.designURL = url
        self.world = World(design: design)
        self.transaction = nil
        
        self.selection = Selection()
        self.selectionOverview = SelectionOverview()
        self.commandQueue = []

        // Flags
        self.requiresInteractivePreviewUpdate = false
        
        setupWorld(notation: notation)
    }
   
    func addObserver(_ observer: @escaping EventObserver, on event: Event) {
        observers[event, default: []].append(observer)
    }
    
    func trigger(_ event: Event) {
        guard let receivers = self.observers[event] else { return }
        for receiver in receivers {
            receiver(self)
        }
    }
    func queueCommand(_ command: any Command) {
        self.commandQueue.append(command)
    }
    
    
    func changeSelection(_ change: SelectionChange) {
        self.selection.apply(change)
        updateSelectionOverview()
        self.trigger(.selectionChanged)
    }

    /// Called on:
    /// - selection changed with ``changeSelection(_:)``
    /// - frame changed with ``Application/accept(_:)``
    func updateSelectionOverview() {
        if self.selection.isEmpty {
            self.selectionOverview.clear()
        }
        if let frame = world.frame {
            self.selectionOverview.update(selection, frame: frame)
        }
        else {
            self.selectionOverview.clear()
        }

        // Pass the selection through the world to the systems for rendering and other processing
        // (see DiagramCanvas drawing methods, for example)
        self.world.setSingleton(selection)
    }
}


// TODO: Use shared application logger
extension Session {
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}

// FIXME: Make a proper alert mechanism. This is a quick hack to silence the compiler after refactoring.
extension Session {
    func queueAlert(title: String, message: String) {
        Task { @MainActor in
            await Application.shared.queueAlert(title: title, message: message)
        }
    }
}
