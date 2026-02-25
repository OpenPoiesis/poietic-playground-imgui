//
//  ApplicationState.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import Foundation

// TODO: Allow tool switching
class Session {
    // FIXME: [IMPORTANT] trigger selectionChanged on design change (undo/redo)
    enum Event {
        /// Triggered on each ``Session/changeSelection(_:)``.
        case selectionChanged
        /// Triggered when world frame has been changed.
        ///
        /// For example: on a transaction or undo/redo action.
        ///
        case designFrameChanged
        case previewChanged
    }

    typealias EventObserver = ((Session) -> Void)

    var observers: [Event:[EventObserver]]
    
    let design: Design
    var designURL: URL? = nil
    
    private var transaction: TransientFrame?
    var hasTransaction: Bool { transaction != nil }
    var commandQueue: [any Command]

    let world: World
    var selection: Selection
    var selectionOverview: SelectionOverview
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application frame.
    var requiresInteractivePreviewUpdate: Bool

    init(design: Design, world: World) {
        self.observers = [:]
        
        self.design = design
        self.world = world
        self.transaction = nil
        
        self.selection = Selection()
        self.selectionOverview = SelectionOverview()
        self.commandQueue = []

        // Flags
        self.requiresInteractivePreviewUpdate = false
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
    
    /// Creates a new transaction or reuses the existing one.
    ///
    /// The transaction is automatically accepted at the end of the update cycle.
    ///
    /// Transaction is non-cancellable. Canvas Tools must create a transaction only when their operation
    /// is concluded successfully.
    ///
    /// - ToDo:  Known issue: If there are multiple commands using the transaction, any of them can
    ///   discard and others in the queue will get a new one. At this stage of development it is
    ///   unlikely to happen, but it is important to acknowledge it.
    ///
    func createOrReuseTransaction() -> TransientFrame {
        if let transaction {
            return transaction
        }
        else {
            let transaction = design.createFrame(deriving: world.frame)
            self.transaction = transaction
            return transaction
        }
    }
    
    /// Commands call this when they fail to successfully complete the transaction.
    ///
    /// See note about discarding in ``createOrReuseTransaction()``
    ///
    func discardTransaction() {
        guard let transaction else { return }
        design.discard(transaction)
        self.transaction = nil
    }
    
    /// Called once the transaction was consumed in ``Application/accept(_:)``.
    /// 
    func consumeTransaction() -> TransientFrame? {
        guard let transaction else { return nil }
        self.transaction = nil
        return transaction
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
