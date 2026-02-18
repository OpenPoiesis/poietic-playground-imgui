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

let clearColor = ImVec4(0.45, 0.55, 0.60, 1.00)

class Application {
//    static let NewDesignTemplatePath = "designs/new_canvas.json"
    static let NewDesignTemplatePath = "designs/design-capital.poietic"
    static let DefaultStockFlowPictogramsPath = "stock_flow_pictograms.json"
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800
    static let PictogramAdjustmentScale = 0.5

    var showMetrics = false
    var showInspector = false

    var quitRequested: Bool = false
    
    // -- Events and Commands
//    var eventSchedules: [ApplicationEvent:ScheduleLabel.Type] = [:]
//    var events: Set<ApplicationEvent> = Set()

    // -- Document --
    var canvas: DiagramCanvas
    
    // -- Views and Controller-likes --
    var inspector: InspectorPanel
    var alertPanel = AlertPanel()

    var canvasTools: [CanvasTool]
    var currentTool: CanvasTool? { toolBar.currentTool }
    var toolBar: ToolBar

    // ## GUI
    //
    // ## The Document – Design and World
    var session: Session?
    var notation: Notation
    
    init() {
        self.notation = Notation.DefaultNotation
        
        // Document
        self.session = nil

        // User Interface
        self.inspector = InspectorPanel()
        self.toolBar = ToolBar()
        self.canvas = DiagramCanvas()
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]

        self.toolBar.currentTool = canvasTools[0]
    }

    @MainActor func run() {
        loadResources()
       
        self.toolBar.bind(self)

        
        // New template design
        let templateURL = ResourceManager.shared.resourceURL(Self.NewDesignTemplatePath)
        do {
            try self.openDesign(url: templateURL)
        }
        catch {
            self.alert(title: "Error", message: "Unable to open template design '\(templateURL)'. Reason: \(error)")
            self.newEmptySession()
        }

        setupEventSchedules()

        mainLoop()
    }
    

    func newEmptySession() {
        let design = Design(metamodel: StockFlowMetamodel)
        newSession(design)
    }
    
    /// Set a new design document and propagate the change through the application.
    ///
    func newSession(_ design: Design) {
        self.log("New session.")
        let world = World(design: design)
        setupWorld(world)
        let newSession = Session(design: design, world: world)
        self.session = newSession
        bindToSession(newSession)

        self.session?.addObserver(inspector.selectionChanged, on: .selectionChanged)
        self.session?.addObserver(inspector.selectionChanged, on: .designFrameChanged)

        // self.session?.addObserver(dashboard.selectionChanged, on: .selectionChanged)

        updateWorld(newSession)
    }
    
    func bindToSession(_ session: Session) {
        canvas.bind(session)
        
        for tool in canvasTools {
            tool.bind(canvas: canvas, session: session)
        }
        inspector.bind(session)
    }
    
    /// Set world singletons when the world changes.
    func setupWorld(_ world: World) {
        Self.setupSchedules(world)
        world.setSingleton(notation)
    }

    @MainActor func mainLoop() {
        let backend = GraphicsBackend.shared

        var lastTime = ImGui.GetTime()
        loop: while !quitRequested {
            switch backend.pollEvent() {
            case .quit: break loop
            case .skip: continue
            case .none: break
            }
            
            ImGui_ImplSDLGPU3_NewFrame()
            ImGui_ImplSDL3_NewFrame()
            ImGui.NewFrame()

            self.processInput()

            let newTime = ImGui.GetTime()
            let timeDelta = newTime - lastTime
            lastTime = newTime


            self.update(timeDelta)
            self.draw()
            self.processUnhandledInput()
            
            // BEGIN Debug
            applicationSessionDebugWindow()
            ImGui.ShowDebugLogWindow()
            ImGui.ShowIDStackToolWindow()
            ImGui.ShowDemoWindow()
            // END Debug

            ImGui.Render()
            backend.render()
        }
    }
    
    func processInput() {
        if let actionName = globalShortcutAction() {
            self.handleAction(actionName)
        }
    }
    
    func update(_ timeDelta: Double) {
        guard let session else {
            logError("No session!")
            return
        }
//        canvas.update(timeDelta)
        inspector.update(timeDelta)
        toolBar.update(timeDelta)
        alertPanel.update(timeDelta)

        // Run commands
        while !session.commandQueue.isEmpty {
            let command = session.commandQueue.removeFirst()
            self.runCommand(command, session: session)
        }

        if let trans = session.consumeTransaction() {
            accept(trans)
        }
        
        updateWorld(session)
        // scheduled
    }
    
    func updateWorld(_ session: Session) {
        let world = session.world
        
        if let maybeNewFrame = session.design.currentFrame,
           maybeNewFrame !== world.frame
        {
            world.setFrame(maybeNewFrame)
            self.run(schedule: FrameChangeSchedule.self, session: session)
            session.updateSelectionOverview()
            session.trigger(.designFrameChanged)
            // TODO: Remove temporary components here (such as previews)
        }
        
        if session.requiresInteractivePreviewUpdate {
            self.run(schedule: InteractivePreviewSchedule.self, session: session)
            session.requiresInteractivePreviewUpdate = false
        }
    }

    func accept(_ trans: TransientFrame) {
        self.log("Accept? Has changes: \(trans.hasChanges)")
        guard trans.hasChanges else {
            trans.design.discard(trans)
            return
        }
        
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
   
    @MainActor
    func draw() {
        mainMenu()
        inspector.draw()
        toolBar.draw()
        canvas.draw()
        alertPanel.draw()
    }
    
    func processUnhandledInput() {
        let io = ImGui.GetIO().pointee
        
        if let currentTool {
            let events = canvas.recognizeEvents(io)
            for event in events {
                currentTool.handleEvent(event)
            }
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
            let wFrameLabel: String = frame.map { String(describing: $0) } ?? "(no frame)"
            let cFrameLabel: String = session.design.currentFrame.map { String(describing: $0) } ?? "(no frame)"
            ImGui.TextUnformatted("Design frame: \(cFrameLabel)")
            ImGui.TextUnformatted("World frame: \(wFrameLabel)")
            ImGui.TextUnformatted("Has Transaction: \(session.hasTransaction)")
            ImGui.TextUnformatted("Selection count: \(session.selection.count)")
            ImGui.TextUnformatted("Interactive preview update: \(session.requiresInteractivePreviewUpdate)")
        }
        ImGui.End()
    }
    
    func runCommand(_ command: any Command, session: Session) {
        let context = CommandContext(app: self, session: session)
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
    
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}
