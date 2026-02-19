//
//  OpenDesignCommand.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

class OpenDesignCommand: Command {
    var name: String { "open-design" }
    let url: URL
    init(url: URL) {
        self.url = url
    }
    func run(_ context: CommandContext) throws (CommandError) {
        do {
            try context.app.openDesign(url: url)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}
