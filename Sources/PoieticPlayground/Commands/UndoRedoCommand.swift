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
    
    func run(_ context: CommandContext) throws (CommandError) {
        context.design.undo() // The frame change will be detected and handled through Session
    }
}

struct RedoCommand: Command {
    var name: String { "redo" }
    
    func run(_ context: CommandContext) throws (CommandError) {
        context.design.redo() // The frame change will be detected and handled through Session 
    }
}
