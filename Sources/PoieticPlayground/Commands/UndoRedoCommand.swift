//
//  UndoRedoCommand.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct UndoCommand: Command {
    var name: String { "undo" }
    
    func run(app: Application) throws (CommandError) {
        guard app.design.undo() else { return }
        app.updateWorldFrame()
    }
}

struct RedoCommand: Command {
    var name: String { "redo" }
    
    func run(app: Application) throws (CommandError) {
        guard app.design.redo() else { return }
        app.updateWorldFrame()
    }
}
