//
//  ApplicationState.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

class Session {
    
    let design: Design
    var transaction: TransientFrame?
    var commandQueue: [any Command]

    let world: World
    var selection: Selection
    var selectionOverview: SelectionOverview
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application frame.
    var requiresInteractivePreviewUpdate: Bool
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
    
    /// Clean-up and prepare for next update.
    func cleanUp() {
        precondition(transaction == nil) // Must be handled
        self.selectionChanged = false
    }
    
    func createOrReuseTransaction() -> TransientFrame {
        if let transaction {
            return transaction
        }
        else {
            let transaction = design.createFrame()
            self.transaction = transaction
            return transaction
        }
    }
    
    func changeSelection(_ change: SelectionChange) {
        self.selection.apply(change)
        self.selectionChanged = true
    }
}
