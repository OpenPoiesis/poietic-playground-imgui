//
//  Application+Session.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import Foundation
import PoieticCore

extension Application {
    /// Set a new design document and propagate the change through the application.
    ///
    func newSession(_ design: Design, designURL: URL? = nil) {
        if let designURL {
            self.log("Design URL: \(designURL.standardizedFileURL)")
        }
        
        let newSession = Session(design: design, url: designURL, notation: notation)
        newSession.updateWorld(force: true)

        self.session = newSession
        bindToSession(newSession)
        
        newSession.trigger(.designFrameChanged)
    }
    
    func connectObservers(_ session: Session) {
        session.removeAllObservers()
        session.addObserver(inspector.onSelectionChanged, on: .designFrameChanged)
        session.addObserver(inspector.onSelectionChanged, on: .selectionChanged)
        session.addObserver(inspector.onSimulationFinished, on: .simulationFinished)
        session.addObserver(canvas.onDesignFrameChanged, on: .designFrameChanged)
        session.addObserver(canvas.onSelectionChanged, on: .selectionChanged)
        session.addObserver(canvas.onInteractivePreviewChanged, on: .previewChanged)
        session.addObserver(canvas.onSimulationPlayerStep, on: .simulationPlayerStep)
        session.addObserver(controlBar.onDesignFrameChanged, on: .designFrameChanged)
        session.addObserver(controlBar.onSimulationPlayerStep, on: .simulationPlayerStep)
        session.addObserver(player.onDesignFrameChanged, on: .designFrameChanged)
        session.addObserver(player.onSimulationFailed, on: .simulationFailed)
        session.addObserver(dashboard.onDesignFrameChanged, on: .designFrameChanged)
    }
    
    func bindToSession(_ session: Session) {
        canvas.bind(session)
        inspector.bind(session)
        issuesPanel.bind(session)
        player.bind(session)

        for tool in canvasTools {
            tool.bind(canvas: canvas, session: session)
        }
        connectObservers(session)
    }
}
