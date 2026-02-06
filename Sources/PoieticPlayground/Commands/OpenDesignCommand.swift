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
    
    func run(app: Application) throws (CommandError) {
        let store = DesignStore(url: url)
        do {
            let design = try store.load(metamodel: StockFlowMetamodel)
            app.setDesign(design)
        }
        catch {
            throw CommandError(message: error.description)
        }
//        selectionManager.clear()
//        designReset.emit()
//        run(schedule: FrameChangeSchedule.self)
//        simulate()
    }
}
