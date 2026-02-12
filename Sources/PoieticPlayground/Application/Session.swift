//
//  ApplicationState.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

class Session {
    unowned let design: Design
    unowned var transaction: TransientFrame?
    var commandQueue: [any Command]

    unowned let world: World
    var selection: Selection
    var selectionChange: SelectionChange?
    var selectionOverview: SelectionOverview
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application frame.
    var requiresInteractivePreview: Bool
    
    init(design: Design, world: World) {
        self.design = design
        self.world = world
        self.transaction = nil
        self.selection = Selection()
        self.selectionChange = nil
        self.commandQueue = []
        self.requiresInteractivePreview = false
        self.selectionOverview = SelectionOverview()
    }
    
    func queueCommand(_ command: any Command) {
        self.commandQueue.append(command)
    }
    
    func runCommands(app: Application) {
        while !commandQueue.isEmpty {
            let command = commandQueue.removeFirst()
            app.runCommand(command, session: self)
        }
    }

    func flushCommands() {
        self.commandQueue.removeAll()
    }
    
    /// Clean-up and prepare for next update.
    func finalize() {
        precondition(transaction == nil) // Must be handled
        self.selectionChange = nil
    }
}
