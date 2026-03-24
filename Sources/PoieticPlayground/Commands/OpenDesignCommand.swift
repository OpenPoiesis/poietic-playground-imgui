//
//  OpenDesignCommand.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import Foundation
import PoieticCore
import PoieticFlows
import Diagramming

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
    init(url: URL? = nil, appendExtensionIfNeeded: Bool = false) {
        if appendExtensionIfNeeded,
           let url,
           url.pathExtension.isEmpty || url.pathExtension != Document.FileExtension
        {
            self.url = url.appendingPathExtension(Document.FileExtension)
        }
        else {
            self.url = url
        }
    }
    func run(_ context: CommandContext) throws (CommandError) {
        var targetURL = url ?? context.document.designURL
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

class ExportSVGCommand: Command {
    static let FileExtension = "svg"
    var name: String { "export-svg" }
    let url: URL
    init(url: URL, appendExtensionIfNeeded: Bool = false) {
        if appendExtensionIfNeeded,
           url.pathExtension.isEmpty || url.pathExtension != Self.FileExtension
        {
            self.url = url.appendingPathExtension(Self.FileExtension)
        }
        else {
            self.url = url
        }
    }
    func run(_ context: CommandContext) throws (CommandError) {
        let exporter = SVGDiagramExporter()

        do {
            try exporter.export(world: context.world, to: url.path())
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}
