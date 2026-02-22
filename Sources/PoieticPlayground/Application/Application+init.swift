//
//  Application+init.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//

import CIimgui
import Csdl3

extension Application {
    @MainActor func loadResources() {
        let manager = ResourceManager.shared
        
        let notationURL = manager.resourceURL(Self.DefaultStockFlowPictogramsPath)
        self.loadNotation(url: notationURL)
    }
}
