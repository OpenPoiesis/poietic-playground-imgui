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
        let world = World(design: design)
        setupWorld(world)
        let newSession = Session(design: design, world: world)
        newSession.designURL = designURL
        updateWorld(newSession, force: true)

        self.session = newSession
        bindToSession(newSession)
    }
    
    func connectObservers(_ session: Session) {
        self.session?.addObserver(inspector.selectionChanged, on: .designFrameChanged)
        self.session?.addObserver(inspector.selectionChanged, on: .selectionChanged)
        
        self.session?.addObserver(canvas.onDesignFrameChanged, on: .designFrameChanged)
        self.session?.addObserver(canvas.onSelectionChanged, on: .selectionChanged)
        self.session?.addObserver(canvas.onInteractivePreviewChanged, on: .previewChanged)
        self.session?.addObserver(canvas.onSimulationPlayerStep, on: .simulationPlayerStep)

        self.session?.addObserver(controlBar.onDesignFrameChanged, on: .designFrameChanged)
        self.session?.addObserver(controlBar.onSimulationPlayerStep, on: .simulationPlayerStep)

        self.session?.addObserver(player.onDesignFrameChanged, on: .designFrameChanged)
        self.session?.addObserver(player.onSimulationFailed, on: .simulationFailed)
//        self.session?.addObserver(player.onSimulationFinished, on: .simulationFinished)
//        self.session?.addObserver(dashboard.selectionChanged, on: .selectionChanged)
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
