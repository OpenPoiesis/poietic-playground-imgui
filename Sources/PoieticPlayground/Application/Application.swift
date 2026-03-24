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
    // TODO: Temporary for prototyping
    static var shared: Application {
        guard let app = self._shared else { fatalError("Shared application is not set-up") }
        return app
    }
    internal static var _shared: Application? = nil
    
    // Dumping ground of globals (for now)
    //    static let NewDesignTemplatePath = "designs/new_canvas.json"
    static let DocumentFileExtension = "poietic"
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
    let filePicker: FilePickerPanel
    let inspector: InspectorPanel
    var alertPanel: AlertPanel
    let aboutPanel: AboutPanel
    let settingsPanel: SettingsPanel
    
    let issuesPanel: IssuesPanel
    
    var canvasTools: [CanvasTool]
    var currentTool: CanvasTool? { toolBar.currentTool }
    let toolBar: ToolBar
    let controlBar: ControlBar
    let dashboard: Dashboard
    
    // ## GUI
    //
    // ## The Document – Design and World
    var document: Document?
    var notation: Notation
    
    init() {
        self.notation = Notation.DefaultNotation
        
        // Document
        self.document = nil
        self.player = ResultPlayer()
        
        // User Interface
        self.inspector = InspectorPanel()
        self.toolBar = ToolBar()
        self.controlBar = ControlBar()
        self.canvas = DiagramCanvas()
        self.settingsPanel = SettingsPanel()
        self.issuesPanel = IssuesPanel()
        self.alertPanel = AlertPanel()
        self.aboutPanel = AboutPanel()
        self.dashboard = Dashboard()
        self.filePicker = FilePickerPanel()
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]
        Self._shared = self
    }
    
    func applicationSessionDebugWindow() {
        ImGui.Begin("Application Session")
        ImGui.TextUnformatted("Current tool: \(toolBar.currentTool?.name, default: "no tool")")
        if let document {
            let frame = document.world.frame
            let wFrameLabel: String = frame.map { String(describing: $0.id) } ?? "(no frame)"
            let cFrameLabel: String = document.design.currentFrame.map { String(describing: $0.id) } ?? "(no frame)"
            ImGui.TextUnformatted("Design frame: \(cFrameLabel)")
            ImGui.TextUnformatted("World frame: \(wFrameLabel)")
            ImGui.TextUnformatted("Has Transaction: \(document.hasTransaction)")
            ImGui.TextUnformatted("Selection count: \(document.selection.count)")
            ImGui.TextUnformatted("Interactive preview update: \(document.requiresInteractivePreviewUpdate)")
        }
        ImGui.End()
    }
    
    func alert(title: String, message: String) {
        self.alertPanel.title = title
        self.alertPanel.message = message
        self.alertPanel.isVisible = true
    }
    
    // FIXME: Make a proper alert mechanism. This is a quick hack to silence the compiler after refactoring. (see callers of this)
    func queueAlert(title: String, message: String) async {
        alert(title: title, message: message)
    }

    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}
