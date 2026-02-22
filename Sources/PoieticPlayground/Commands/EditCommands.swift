//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation
import CIimgui

extension Command {
    func copySelectionAsText(ids: [ObjectID], frame: DesignFrame) throws (CommandError) -> String {
        let design = frame.design
        let ids = frame.contained(ids)
        
        let extractor = DesignExtractor()
        let extract = extractor.extractPruning(objects: ids, frame: frame)
        let rawDesign = RawDesign(metamodelName: design.metamodel.name,
                                  metamodelVersion: design.metamodel.version,
                                  snapshots: extract)
        
        let writer = JSONDesignWriter()
        guard let text: String = writer.write(rawDesign) else {
            throw CommandError("Unable to get textual representation for pasteboard", severity: .fatal)
        }
        return text
    }
    
    func setPasteboardText(_ text: String) throws (CommandError) {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let setPasteboardFn = platformIO.Platform_SetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            throw CommandError("Backend pasteboard configuration error", severity: .fatal)
        }
        
        setPasteboardFn(imguiContext, text)
    }
    func getPasteboardText() throws (CommandError) -> String? {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let getPasteboardFn = platformIO.Platform_GetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            throw CommandError("Backend pasteboard configuration error", severity: .fatal)
        }
        
        guard let result = getPasteboardFn(imguiContext) else {
            return nil
        }
        guard let string = String(cString: result, encoding: .utf8) else {
            return nil
        }
        return string
    }

}

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

struct CopyToPasteboardCommand: Command {
    let ids: [ObjectID]
    var name: String { "copy" }
    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    func run(_ context: CommandContext) throws (CommandError) {
        guard let frame = context.world.frame else { return }
        let text = try copySelectionAsText(ids: ids, frame: frame)
        try setPasteboardText(text)
        
    }
    
}

struct CutToPasteboardCommand: Command {
    let ids: [ObjectID]
    var name: String { "cut" }
    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    func run(_ context: CommandContext) throws (CommandError) {
        guard let frame = context.world.frame else { return }
        let text = try copySelectionAsText(ids: ids, frame: frame)
        try setPasteboardText(text)

        let trans = context.session.createOrReuseTransaction()
        for objectID in ids {
            guard trans.contains(objectID) else { continue }
            trans.removeCascading(objectID)
        }
    }
}

struct PasteFromPasteboardCommand: Command {
    var name: String { "paste" }

    init() { /* Nothing */ }
    
    func run(_ context: CommandContext) throws (CommandError) {
        guard let text = try getPasteboardText() else {
            return
        }

        let trans = context.session.createOrReuseTransaction()

        guard let data = text.data(using: .utf8) else {
            throw CommandError("Can not get data from text")
        }

        let reader = JSONDesignReader()
        let rawDesign: RawDesign
        do {
            rawDesign = try reader.read(data: data)
        }
        catch {
            throw CommandError("Unable to process pasteboard content", underlyingError: error)
        }

        let loader = DesignLoader(metamodel: trans.design.metamodel)
        let ids: [PoieticCore.ObjectID]

        do {
            // TODO: Make the strategy configurable
            ids = try loader.load(rawDesign,
                                  into: trans,
                                  identityStrategy: .preserveOrCreate)
        }
        catch {
            context.session.discardTransaction()
            throw CommandError("Failed to paste content", underlyingError: error)
        }

        context.session.changeSelection(.replaceAll(ids))
    }

}



