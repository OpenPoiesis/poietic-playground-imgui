//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming
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

struct OpenIssuesCommand: Command {
    var name: String { "open-issues" }

    /// Object to open issues for. If nil - open for all.
    let objectID: ObjectID?
    
    init(_ objectID: ObjectID? = nil) {
        self.objectID = objectID
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        context.app.issuesPanel.isVisible = true
    }
}

struct CenterCanvasOnObjectCommand: Command {
    // TODO: Make it work with other objects, Works only with blocks for now
    var name: String { "center-canvas-on-object" }

    let objectID: ObjectID
    let zoomLevel: Double?
    
    init(_ objectID: ObjectID, zoomLevel: Double? = nil) {
        self.objectID = objectID
        self.zoomLevel = zoomLevel
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        print("CENTER ON: \(objectID), zoom: \(zoomLevel)")
        guard let entity = context.world.entity(objectID),
              let block: DiagramBlock = entity.component()
        else {return }
        context.app.canvas.centerView(at: block.position)
    }
}

struct ResetZoomCommand: Command {
    var name: String { "reset-zoom" }
    
    func run(_ context: CommandContext) throws (CommandError) {
        let canvas = context.app.canvas
        let worldSize: Vector2D = canvas.screenToWorld(canvas.canvasSize)
        let center = canvas.viewOffset + (worldSize / 2)
        context.app.canvas.centerView(at: center, zoom: 1.0)
    }
}
