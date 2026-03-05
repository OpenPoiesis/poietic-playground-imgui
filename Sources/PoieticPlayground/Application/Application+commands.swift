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
        let design = Design(metamodel: StockFlowMetamodel)
        // Create a new frame, so we can undo first action (can't undo to no-frame)
        let frame = design.createFrame()
        try! design.accept(frame) // We can force, because empty frame must be always valid.
        self.newSession(design)
    }
    func openDesign(url: URL) throws (DesignStoreError) {
        let store = DesignStore(url: url)
        let design = try store.load(metamodel: StockFlowMetamodel)
        self.newSession(design, designURL: url)
    }
    
    func saveDesign(url: URL) throws (DesignStoreError) {
        guard let session else { return }
        self.log("Saving design to: \(url.standardizedFileURL)")
        let store = DesignStore(url: url)
        try store.save(design: session.design)
    }

    func selectAll() {
        guard let session,
              let frame = session.world.frame
        else { return }

        let allIDs: [ObjectID] =
                frame.filter(trait: .DiagramBlock).map {$0.objectID}
                + frame.filter(trait: .DiagramConnector).map {$0.objectID}
        session.changeSelection(.replaceAll(allIDs))
    }
}
