//
//  OpenDesignCommand.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

let DefaultDesignPath = "Unnamed.poietic"

class NewDesignCommand: Command {
    var name: String { "new-design" }

    func run(_ context: CommandContext) throws (CommandError) {
        context.app.newDesign()
    }
}

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

class SaveDesignCommand: Command {
    var name: String { "save-design" }
    let url: URL?
    init(url: URL? = nil) {
        self.url = url
    }
    func run(_ context: CommandContext) throws (CommandError) {
        var targetURL = url ?? context.session.designURL
        if targetURL == nil {
            // TODO: Open save panel
                        targetURL = URL(fileURLWithPath: DefaultDesignPath)
        }
        
        do {
            try context.app.saveDesign(url: targetURL!)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}
