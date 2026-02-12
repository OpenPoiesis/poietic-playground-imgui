//
//  Application+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/02/2026.
//

import Foundation
import PoieticCore
import PoieticFlows

extension Application {
    func openDesign(url: URL) throws (DesignStoreError) {
        let store = DesignStore(url: url)
        let design = try store.load(metamodel: StockFlowMetamodel)
        self.newSession(design)
    }
}
