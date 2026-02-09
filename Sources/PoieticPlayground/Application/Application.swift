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
    var eventSchedules: [ApplicationEvent:ScheduleLabel.Type] = [:]
    var events: Set<ApplicationEvent> = Set()
    var commandQueue: [any Command] = []

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
    var design: Design!
    var world: World!
    var notation: Notation
    
    init() {
        // Document
        self.design = Design(metamodel: StockFlowMetamodel)
        self.world = World(design: design)

        // User Interface
        self.inspector = InspectorPanel()
        self.toolBar = ToolBar()
        self.canvas = DiagramCanvas(world: world)
        self.notation = Notation.DefaultNotation
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]

        self.toolBar.currentTool = canvasTools[0]
        self.resourceLoader = ResourceLoader(Self.DefaultResourcesPath, application: nil)
        resourceLoader.app = self

        setupWorld(world)
    }

    /// Set a new design document and propagate the change through the application.
    ///
    func setDesign(_ design: Design) {
        self.log("Setting new design. Frame: \(design.currentFrameID)")
        guard design !== self.design else { return }
        self.design = design
        let newWorld = World(design: design)
        self.canvas.world = newWorld
        
        for tool in canvasTools {
            tool.bind(world: newWorld, canvas: canvas)
        }

        setupWorld(newWorld)
        self.world = newWorld
        updateWorldFrame()
    }
    
    /// Set world singletons when the world changes.
    func setupWorld(_ world: World) {
        Self.setupSchedules(world)
        world.setSingleton(notation)
        let selection = Selection()
        world.setSingleton(selection)
        
        self.inspector.bind(world)
    }

    func updateWorldFrame() {
        guard let frame = design.currentFrame else {
            logError("No current design frame")
            return
        }
        // TODO: Add new-frame related clean-up here.
        world.setFrame(frame)
        self.run(schedule: FrameChangeSchedule.self)
    }
    
    func run() {
        guard initializeSDL() else { fatalError("Unable to init SDL") }
        guard initializeImGui() else { fatalError("Unable to init ImGui") }
        loadResources()
        
        self.toolBar.app = self
        self.canvas.app = self

        // Prepare world before design
        let notationURL = resourceLoader.resourceURL(Self.DefaultStockFlowPictogramsPath)
        self.loadNotation(url: notationURL)
        
        // New template design
        let templateURL = resourceLoader.resourceURL(Self.NewDesignTemplatePath)
        self.queueCommand(OpenDesignCommand(url: templateURL))
        
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

            let newTime = ImGui.GetTime()
            let timeDelta = newTime - lastTime
            lastTime = newTime

            self.processInput()
            self.runCommands()
            self.updateWorld()
            self.update(timeDelta)
            self.draw()
            self.processUnhandledInput()
            
            applicationStateDebugWindow()
            ImGui.ShowDebugLogWindow()
            ImGui.ShowIDStackToolWindow()
            ImGui.ShowDemoWindow()

            ImGui.Render()
            self.backendRender()
        }
    }
    
    func processInput() {
        self.processGlobalShortcuts()
    }
    
    // FIXME: REMOVE – UNUSED
    func runEventSchedules() {
        // Run event schedules in their order, if scheduled
        for event in ApplicationEvent.allCases {
            guard events.contains(event),
                  let label = eventSchedules[event]
            else { continue }
            log("Running \(label) for event \(event)")
            run(schedule: label)
            events.remove(event)
        }
    }
    
    func updateWorld() {
        if let change: SelectionChange = world.singleton(),
           let selection: Selection = world.singleton()
        {
            selection.apply(change)
            world.removeSingleton(SelectionChange.self)
            
            if let frame = world.frame {
                let overview = createSelectionOverview(selection, frame: frame)
                world.setSingleton(overview)
            }
            else {
                world.removeSingleton(SelectionOverview.self)
            }
            
        }
        
        if world.hasSingleton(InteractivePreviewTag.self){
            world.removeSingleton(InteractivePreviewTag.self)
            self.run(schedule: InteractivePreviewSchedule.self)
        }
        
        if let trans: TransientFrame = world.singleton(){
            world.removeSingleton(TransientFrame.self)
            self.accept(trans)
            self.run(schedule: InteractivePreviewSchedule.self)
        }
    }

    func accept(_ trans: TransientFrame) {
        guard trans.hasChanges else {
            design.discard(trans)
            return
        }
        
        do {
            try design.accept(trans, appendHistory: true)
            self.log("Transaction accepted. Current frame: \(trans.id), frame count: \(design.frames.count)")
        }
        catch {
            // This is not user's fault and never should be.
            // The application failed to make sure structural integrity is assured
            self.alert(title: "Frame validation error", message: String(describing: error))
            return
        }
        updateWorldFrame()
        // TODO: Remove temporary components here (such as previews)
    }
   
    func update(_ timeDelta: Double) {
        toolBar.update(timeDelta)
        inspector.update(timeDelta)
        canvas.update(timeDelta)
        alertPanel.update(timeDelta)
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
        
        canvas.processUnhandledInput(io)
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
   
    func applicationStateDebugWindow() {
        ImGui.Begin("Application State")
        ImGui.TextUnformatted("Current tool: \(toolBar.currentTool?.name, default: "no tool")")
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
    
    func queueCommand(_ command: any Command) {
        self.commandQueue.append(command)
    }
    
    func runCommands() {
        let commands = commandQueue
        commandQueue.removeAll()

        for command in commands {
            runCommand(command)
        }
    }
    
    func runCommand(_ command: any Command) {
        do {
            self.log("Running command '\(command.name)'")
            try command.run(app: self)
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
