//
//  App+World.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

extension Application {
    func loadNotation(url: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        }
        catch {
            logError("Unable to load notation from: \(url)")
            return
        }
        
        let decoder = JSONDecoder()
        let collection: PictogramCollection
        
        do {
            collection = try decoder.decode(PictogramCollection.self, from: data)
        }
        catch {
            logError("Unable to load pictograms from: \(url). Reason: \(error)")
            collection = PictogramCollection()
        }
        if collection.pictograms.isEmpty {
            logError("No pictograms found (empty collection)")
        }
        
        let scaled = collection.pictograms.map { $0.scaled(Self.PictogramAdjustmentScale) }
        
        let notation = Diagramming.Notation(
            pictograms: scaled,
            defaultPictogramName: "Unknown",
            connectorGlyphs: DefaultStockFlowConnectorGlyphs,
            defaultConnectorGlyphName: "default"
        )
        self.log("Notation loaded. \(notation.pictograms.count) pictograms, \(notation.connectorGlyphs.count) connector glyphs.")
        self.notation = notation
        // TODO: Update the world
    }
}
