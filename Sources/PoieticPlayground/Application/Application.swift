//
//  Application.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 26/01/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui
import Csdl3
import Diagramming
import Foundation

/// Main orchestrator
///
/// Responsibilities:
///
/// - Lifecycle and main loop orchestration
/// - UI panel ownership and binding orchestration
/// - Input routing (shortcuts → actions → commands)
/// - Resource management
/// - Glue between Document and UI
@MainActor
class Application {
    // Dumping ground of globals (for now)
    //    static let NewDesignTemplatePath = "designs/new_canvas.json"
    static let NewDesignTemplatePath = "designs/design-capital.poietic"
    static let DefaultStockFlowPictogramsPath = "stock_flow_pictograms.json"
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800
    static let PictogramAdjustmentScale = 0.5
    
    var showMetrics = false
    var quitRequested: Bool = false
    
    // -- Document --
    var canvas: DiagramCanvas
    var player: ResultPlayer

    // -- Views and Controller-likes --
    let inspector: InspectorPanel
    var alertPanel = AlertPanel()
    let settingsPanel: SettingsPanel
    
    let issuesPanel: IssuesPanel
    
    var canvasTools: [CanvasTool]
    var currentTool: CanvasTool? { toolBar.currentTool }
    let toolBar: ToolBar
    let controlBar: ControlBar
    
    // ## GUI
    //
    // ## The Document – Design and World
    var session: Session?
    var notation: Notation
    
    init() {
        self.notation = Notation.DefaultNotation
        
        // Document
        self.session = nil
        self.player = ResultPlayer()
        
        // User Interface
        self.inspector = InspectorPanel()
        self.toolBar = ToolBar()
        self.controlBar = ControlBar()
        self.canvas = DiagramCanvas()
        self.settingsPanel = SettingsPanel()
        self.issuesPanel = IssuesPanel()
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]
    }
    
    /// Set world singletons when the world changes.
    func setupWorld(_ world: World) {
        Self.setupSchedules(world)
        world.setSingleton(notation)
    }
    
    func updateWorld(_ session: Session, force: Bool = false) {
        // TODO: This method does multiple things that need to be decoupled
        let world = session.world
        
        if session.design.currentFrame !== world.frame || force {
            if let frame = session.design.currentFrame {
                world.setFrame(frame)
            }
            // TODO: [IMPORTANT] Remove components with frame lifetime (backing does not exist yet)
            self.run(schedule: FrameChangeSchedule.self, session: session)
            session.updateSelectionOverview()
            session.trigger(.designFrameChanged)
            session.trigger(.selectionChanged)

            if self.run(schedule: SimulationSchedule.self, session: session) {
                session.trigger(.simulationFinished)
            }
            else {
                session.trigger(.simulationFailed)
            }
            // TODO: Remove temporary components here (such as previews)
        }

        if session.requiresInteractivePreviewUpdate {
            self.run(schedule: InteractivePreviewSchedule.self, session: session)
            session.requiresInteractivePreviewUpdate = false
            session.trigger(.previewChanged)
        }
    }
    
    func accept(_ trans: TransientFrame) {
        self.log("Accept? Has changes: \(trans.hasChanges)")
        guard trans.hasChanges else {
            trans.design.discard(trans)
            return
        }
        self.log("Accepting frame changes")

        do {
            try trans.design.accept(trans, appendHistory: true)
            self.log("Transaction accepted. Current frame: \(trans.id), frame count: \(trans.design.frames.count)")
        }
        catch {
            // This is not user's fault and never should be.
            // The application failed to make sure structural integrity is assured
            self.alert(title: "Frame validation error (report to developers)", message: String(describing: error))
            return
        }
        
        if let session {
            updateWorld(session)
        }
    }
    
    func alert(title: String, message: String) {
        self.alertPanel.title = title
        self.alertPanel.message = message
        self.alertPanel.isVisible = true
    }
    
    func applicationSessionDebugWindow() {
        ImGui.Begin("Application Session")
        ImGui.TextUnformatted("Current tool: \(toolBar.currentTool?.name, default: "no tool")")
        if let session {
            let frame = session.world.frame
            let wFrameLabel: String = frame.map { String(describing: $0.id) } ?? "(no frame)"
            let cFrameLabel: String = session.design.currentFrame.map { String(describing: $0.id) } ?? "(no frame)"
            ImGui.TextUnformatted("Design frame: \(cFrameLabel)")
            ImGui.TextUnformatted("World frame: \(wFrameLabel)")
            ImGui.TextUnformatted("Has Transaction: \(session.hasTransaction)")
            ImGui.TextUnformatted("Selection count: \(session.selection.count)")
            ImGui.TextUnformatted("Interactive preview update: \(session.requiresInteractivePreviewUpdate)")
        }
        ImGui.End()
    }
    
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}
