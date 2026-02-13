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
    static let DefaultResourcesPath = "Sources/PoieticPlayground/Resources/"
//    static let NewDesignTemplatePath = "designs/new_canvas.json"
    static let NewDesignTemplatePath = "designs/design-capital.poietic"
    static let DefaultStockFlowPictogramsPath = "stock_flow_pictograms.json"
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800
    static let PictogramAdjustmentScale = 0.5

    var showMetrics = false
    var showInspector = false

    var displayScale: Float = 1.0
    var gpuDevice: OpaquePointer!
    var mainWindow: OpaquePointer!
   
    // -- Resources --
    var resourceLoader: ResourceLoader
    var textures: [String:Texture] = [:]

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
        self.resourceLoader = ResourceLoader(Self.DefaultResourcesPath, application: nil)
        resourceLoader.app = self
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
        // self.session?.addObserver(dashboard.selectionChanged, on: .selectionChanged)

        updateWorldFrame()
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

    func updateWorldFrame() {
        guard let session else { return }
        guard let frame = session.design.currentFrame else {
            logError("No current design frame")
            return
        }
        // TODO: Add new-frame related clean-up here.
        session.world.setFrame(frame)
        self.run(schedule: FrameChangeSchedule.self, session: session)
    }
    
    func run() {
        guard initializeSDL() else { fatalError("Unable to init SDL") }
        guard initializeImGui() else { fatalError("Unable to init ImGui") }
        loadResources()
        
        self.toolBar.bind(self)

        // Prepare world before design
        let notationURL = resourceLoader.resourceURL(Self.DefaultStockFlowPictogramsPath)
        self.loadNotation(url: notationURL)
        
        // New template design
        let templateURL = resourceLoader.resourceURL(Self.NewDesignTemplatePath)
        do {
            try self.openDesign(url: templateURL)
        }
        catch {
            self.alert(title: "Error", message: "Unable to open template design '\(templateURL)'. Reason: \(error)")
            self.newEmptySession()
        }

        setupEventSchedules()
        mainLoop()
        cleanUp()
    }
    
    enum BackendEvent {
        /// Proceed with frame processing
        case none
        /// Quit the application
        case quit
        /// Skip this frame
        case skip
    }
    
    func pollBackendEvent() -> BackendEvent {
        var event: SDL_Event = SDL_Event()
        
        // TODO: See SDL_PeepEvents(...)
        while SDL_PollEvent(&event) {
            switch event.type {
            case SDL_EVENT_QUIT.rawValue:
                return .quit
            case SDL_EVENT_WINDOW_CLOSE_REQUESTED.rawValue
                    where event.window.windowID == SDL_GetWindowID(mainWindow):
                return .quit
            default:
                break
            }

            ImGui_ImplSDL3_ProcessEvent(&event);
        }
        
        if (SDL_GetWindowFlags(mainWindow) & .SDL_WINDOW_MINIMIZED) != 0
        {
            SDL_Delay(10)
            return .skip
        }
        return .none
    }
    
    func mainLoop() {
        var lastTime = ImGui.GetTime()
        loop: while true {
            switch pollBackendEvent() {
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
            self.backendRender()
        }
    }
    
    func processInput() {
        self.processGlobalShortcuts()
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
        updateWorldFrame()
        // TODO: Remove temporary components here (such as previews)
    }
   
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
    
    func backendRender() {
        let drawData = ImGui.GetDrawData()
        let isMinimized = (drawData.pointee.DisplaySize.x <= 0.0 || drawData.pointee.DisplaySize.y <= 0.0)

        let commandBuffer = SDL_AcquireGPUCommandBuffer(gpuDevice)

        var swapchainTexture: OpaquePointer! = nil
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, mainWindow, &swapchainTexture, nil, nil)
        if (swapchainTexture != nil && !isMinimized)
        {
            // This is mandatory: call ImGui_ImplSDLGPU3_PrepareDrawData() to upload the vertex/index buffer!
            ImGui_ImplSDLGPU3_PrepareDrawData(drawData, commandBuffer)

            // Setup and start a render pass
            var target_info = SDL_GPUColorTargetInfo()
            target_info.texture = swapchainTexture
            target_info.clear_color = SDL_FColor(r: clearColor.x, g: clearColor.y, b: clearColor.z, a: clearColor.w)
            target_info.load_op = SDL_GPU_LOADOP_CLEAR
            target_info.store_op = SDL_GPU_STOREOP_STORE
            target_info.mip_level = 0
            target_info.layer_or_depth_plane = 0
            target_info.cycle = false
            let render_pass = SDL_BeginGPURenderPass(commandBuffer, &target_info, 1, nil)

            // Render ImGui
            ImGui_ImplSDLGPU3_RenderDrawData(drawData, commandBuffer, render_pass)

            SDL_EndGPURenderPass(render_pass)
        }

        // Submit the command buffer
        SDL_SubmitGPUCommandBuffer(commandBuffer)

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
    
    func cleanUp() {
        SDL_WaitForGPUIdle(gpuDevice)
        ImGui_ImplSDL3_Shutdown()
        ImGui_ImplSDLGPU3_Shutdown()
        ImGui.DestroyContext()

        SDL_ReleaseWindowFromGPUDevice(gpuDevice, mainWindow)
        SDL_DestroyGPUDevice(gpuDevice)
        SDL_DestroyWindow(mainWindow)
        SDL_Quit()
    }
    
    func runCommand(_ command: any Command, session: Session) {
        let context = CommandContext(app: self, session: session)
        do {
            self.log("Running command '\(command.name)'")
            try command.run(context)
        }
        catch {
            self.logError("Command '\(command.name)' failed: \(error.message)")
            self.alert(title: "Error", message: error.message)
        }
    }
    
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}
