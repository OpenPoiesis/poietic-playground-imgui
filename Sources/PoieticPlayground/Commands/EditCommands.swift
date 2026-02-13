//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct DeleteObjectsCommand: Command {
    let ids: [ObjectID]
    var name: String { "delete" }
    
    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        let trans = context.session.createOrReuseTransaction()
        for objectID in ids {
            guard trans.contains(objectID) else { continue }
            trans.removeCascading(objectID)
        }
    }
}

