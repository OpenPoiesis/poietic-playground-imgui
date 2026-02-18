//
//  App+resources.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

let IconNames: [String] = [
    "add",
    "arrow-comment",
    "arrow-outlined",
    "arrow-parameter",
    "cancel",
    "chevrons-left",
    "chevrons-right",
    "connect",
    "delete",
    "empty",
    "error",
    "formula",
    "hand",
    "handle-flow",
    "last-step",
    "line-curved",
    "line-orthogonal",
    "line-straight",
    "loop",
    "menu",
    "next-step",
    "ok",
    "place",
    "previous-step",
    "redo",
    "restart",
    "run",
    "select",
    "stop",
    "time-window",
    "undo",
    "zoom-in",
    "zoom-out"
]

extension Application {
    @MainActor func loadResources() {
        let manager = ResourceManager.shared
        self.log("Loading textures...")
        let iconBase = "icons/black/"
        
        for iconName in IconNames {
            let path = iconBase + iconName + ".png" // TODO: Use oath concatenation
            _ = manager.loadTexture(path, as: iconName)
        }

        self.log("\(manager.textures.count) textures loaded")
        
        // Prepare world before design
        let notationURL = manager.resourceURL(Self.DefaultStockFlowPictogramsPath)
        self.loadNotation(url: notationURL)
    }
}
