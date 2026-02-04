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

let clearColor = ImVec4(0.45, 0.55, 0.60, 1.00)

class Application {
    static let DefaultResourcesPath = "Sources/PoieticPlayground/Resources/"
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800

    var showMetrics = false
    var showInspector = false

    var displayScale: Float = 1.0
    var gpuDevice: OpaquePointer!
    var mainWindow: OpaquePointer!
   
    var canvasTools: [CanvasTool]
    var toolBar: ToolBar
    var currentTool: CanvasTool? { toolBar.currentTool }

    var canvas: DiagramCanvas
    
    var textures: [String:Texture] = [:]
    
    // ## GUI
    //
    // ## World
    var design: Design
    var world: World
    
    init() {
        self.toolBar = ToolBar()
        self.canvas = DiagramCanvas()
        
        self.design = Design(metamodel: StockFlowMetamodel)
        self.world = World(design: design)
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]
        for tool in canvasTools {
            tool.bind(world: world, canvas: canvas)
        }
        self.toolBar.currentTool = canvasTools[0]
    }
    
    func DEVEL_playground() {
        let root = "Sources/PoieticPlayground/Resources/"
        let loader = ResourceLoader(root, application: self)
        loader.load("icons/black/select.png")
        let texture = loader.loadTexture("icons/black/select.png")
        if let texture {
            print("Texture: \(texture.width)x\(texture.height) \(texture.textureID)")
        }
        else {
            print("NO TEXTURE")
        }
    }
    
    func run() {
        guard initializeSDL() else { fatalError("Unable to init SDL") }
        guard initializeImGui() else { fatalError("Unable to init ImGui") }
        loadResources()
        
        self.toolBar.app = self
        self.canvas.app = self
        
        DEVEL_playground()
        mainLoop()
        cleanUp()
    }
    
    func mainLoop() {
        var done: Bool = false
        while !done {
            var event: SDL_Event = SDL_Event()
            
            while SDL_PollEvent(&event) {
                switch event.type {
                case SDL_EVENT_QUIT.rawValue:
                    done = true
                case SDL_EVENT_WINDOW_CLOSE_REQUESTED.rawValue
                        where event.window.windowID == SDL_GetWindowID(mainWindow):
                    done = true
                default:
                    break
                }

                ImGui_ImplSDL3_ProcessEvent(&event);
            }
            
            if (SDL_GetWindowFlags(mainWindow) & .SDL_WINDOW_MINIMIZED) != 0
            {
                SDL_Delay(10)
                continue
            }

            let io = ImGui.GetIO().pointee
//            if !io.WantCaptureKeyboard {
//                processInput(io)
//            }
            
            // Start the Dear ImGui frame
            ImGui_ImplSDLGPU3_NewFrame()
            ImGui_ImplSDL3_NewFrame()
            ImGui.NewFrame()
            let shortcut: String = checkGlobalShortcuts() ?? "(none)"

            mainMenu()
            toolBar.draw()
            canvas.render()
            
            applicationStateDebugWindow()
            ImGui.ShowDebugLogWindow()
            ImGui.ShowIDStackToolWindow()
            ImGui.ShowDemoWindow()
            // Rendering
            ImGui.Render()
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

    func drawDebugInfo() {
        ImGui.Begin("Debug Info", nil, 0)
        
        let io = ImGui.GetIO().pointee
        
//        let device = SDL_GetTouchDeviceName(<#T##touchID: SDL_TouchID##SDL_TouchID#>)
        
        // Basic state
        ImGui.TextUnformatted("WantCaptureMouse: \(io.WantCaptureMouse)")
        ImGui.TextUnformatted("WantCaptureKeyboard: \(io.WantCaptureKeyboard)")
        ImGui.TextUnformatted("WantTextInput: \(io.WantTextInput)")
        
        // Mouse position and hover states
        ImGui.Separator()
        ImGui.TextUnformatted("Mouse Pos: (\(io.MousePos.x), \(io.MousePos.y))")
        ImGui.TextUnformatted("Mouse Delta: (\(io.MouseDelta.x), \(io.MouseDelta.y))")
        
        // Window states
        ImGui.Separator()
        ImGui.TextUnformatted("IsAnyItemActive: \(ImGui.IsAnyItemActive())")
        ImGui.TextUnformatted("IsAnyItemHovered: \(ImGui.IsAnyItemHovered())")
        ImGui.TextUnformatted("IsAnyItemFocused: \(ImGui.IsAnyItemFocused())")
        // Check specific windows
        ImGui.Separator()
        
        // Check if specific items are active
        ImGui.Separator()
        ImGui.TextUnformatted("Active IDs:")
        for i in 0..<5 {
            if ImGui.IsItemActive() {
                ImGui.TextUnformatted("  Item \(i) is active")
            }
        }
        
        ImGui.End()
    }


}
