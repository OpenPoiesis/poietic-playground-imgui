//
//  Application+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/02/2026.
//

import Foundation
import PoieticCore
import PoieticFlows
import CIimgui

extension Application {
    func runCommand(_ command: any Command, document: Document) {
        let context = CommandContext(app: self, document: document)
        do {
            self.log("Running command '\(command.name)'")
            try command.run(context)
        }
        catch {
            self.logError("Command '\(command.name)' failed: \(error.message)")
            if let underlyingError = error.underlyingError {
                self.logError("Underlying error: \(String(describing: underlyingError))")
            }
            let title: String
            switch error.severity {
            case .error: title = "Fatal Error"
            case .fatal: title = "Error"
            }
            
            self.alert(title: title, message: error.message)
        }
    }

    func openSettings() {
        settingsPanel.isVisible = true
    }
    
    func setInterfaceColorScheme(_ scheme: InterfaceStyle.ColorScheme) {
        guard scheme != InterfaceStyle.current.scheme else { return }
        let style = InterfaceStyle(scheme: scheme)
        InterfaceStyle.current = style
        
        switch scheme {
        case .light: ImGui.StyleColorsLight()
        case .dark: ImGui.StyleColorsDark()
        }
    }
    
    func newDesign() {
        let design = Design(metamodel: StockFlowDomain.StockFlowMetamodel)
        // Create a new plane, so we can undo first action (can't undo to no-plane)
        let plane = design.createPlane()
        try! design.accept(plane) // We can force, because empty plane must be always valid.
        self.newDocument(design)
    }
    // TODO: Move to Session (document)
    func openDesign(url: URL) throws (DesignStoreError) {
        let store = DesignStore(url: url)
        let design = try store.load(metamodel: StockFlowDomain.StockFlowMetamodel)
        self.newDocument(design, designURL: url)
    }
    
    // TODO: Move to Session (document)
    func saveDesign(url: URL) throws (DesignStoreError) {
        guard let document else { return }
        self.log("Saving design to: \(url.standardizedFileURL)")
        let store = DesignStore(url: url)
        try store.save(design: document.design)
        document.designURL = url
    }

    func selectAll() {
        guard let document,
              let plane = document.world.plane
        else { return }

        let allIDs: [ObjectID] = plane.filter(trait: DiagramDomain.Traits.DiagramBlock).map {$0.objectID}
                                 + plane.filter(trait: DiagramDomain.Traits.DiagramConnector).map {$0.objectID}
        document.changeSelection(.replaceAll(allIDs))
    }
}
