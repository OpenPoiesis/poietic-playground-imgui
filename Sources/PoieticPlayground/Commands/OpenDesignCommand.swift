//
//  OpenDesignCommand.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct OpenDesignCommand: Command {
    var name: String { "open-design" }
    let url: URL
    
    func run(_ context: CommandContext) throws (CommandError) {
        do {
            try context.app.openDesign(url: url)
        }
        catch {
            throw CommandError(message: error.description)
        }
    }
}
