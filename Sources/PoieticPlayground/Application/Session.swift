//
//  ApplicationState.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

class Session {
    var eventFlags: SessionEventFlags = .none
    
    let design: Design
    private var transaction: TransientFrame?
    var hasTransaction: Bool { transaction != nil }
    var commandQueue: [any Command]

    let world: World
    var selection: Selection
    var selectionOverview: SelectionOverview
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application frame.
    var requiresInteractivePreviewUpdate: Bool

    /// Selection changed, compared to the last application frame.
    var selectionChanged: Bool
    
    init(design: Design, world: World) {
        self.design = design
        self.world = world
        self.transaction = nil
        self.selection = Selection()
        self.selectionOverview = SelectionOverview()
        self.commandQueue = []

        // Flags
        self.requiresInteractivePreviewUpdate = false
        self.selectionChanged = false
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
    
    func consumeTransaction() -> TransientFrame? {
        guard let transaction else { return nil }
        self.transaction = nil
        return transaction
    }
    
    func changeSelection(_ change: SelectionChange) {
        self.selection.apply(change)
        self.selectionChanged = true
    }
}
