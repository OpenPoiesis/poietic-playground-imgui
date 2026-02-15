//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation
import CIimgui

struct SwitchToolCommand: Command {
    let toolName: String
    var name: String { "delete" } // TODO: Use CanvasTool.Type
    
    init(_ toolName: String) {
        self.toolName = toolName
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        context.app.toolBar.setTool(name)
    }
}
