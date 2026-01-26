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
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800

    var displayScale: Float = 1.0
    var gpuDevice: OpaquePointer!
    var mainWindow: OpaquePointer!
    
    var design: Design?
    var world: World?
    
    init() {
        self.design = Design(metamodel: StockFlowMetamodel)
        self.world = World(design: design!)
    }
    
    func run() {
        guard initializeSDL() else { fatalError("Unable to init SdL") }
        mainLoop()
        cleanUp()
    }
    
    func initializeSDL() -> Bool {
        // From: https://github.com/ocornut/imgui/blob/master/examples/example_sdl3_sdlgpu3/main.cpp
        
        guard SDL_Init(SDL_INIT_VIDEO) else {
            let err = String(cString: SDL_GetError())
            fatalError("SDL_Init Error: \(err)")
        }
        
        // Create SDL window graphics context
        let displayScale = SDL_GetDisplayContentScale(SDL_GetPrimaryDisplay())
        let windowFlags: SDL_WindowFlags =
            .SDL_WINDOW_RESIZABLE
        | .SDL_WINDOW_HIDDEN
        | .SDL_WINDOW_HIGH_PIXEL_DENSITY
        
        let window = SDL_CreateWindow(Application.MainWindowName,
                                      Int32(Float(Application.DefaultWindowWidth) * displayScale),
                                      Int32(Float(Application.DefaultWindowHeight) * displayScale),
                                      windowFlags);
        guard let window else {
            fatalError("Error: SDL_CreateWindow(): \(String(cString: SDL_GetError()))")
        }
        self.mainWindow = window
        
        SDL_SetWindowPosition(window, dSDL_WINDOWPOS_CENTERED.rawValue, dSDL_WINDOWPOS_CENTERED.rawValue);
        SDL_ShowWindow(window);
        
        // Create GPU Device
        
        guard let gpuDevice = SDL_CreateGPUDevice(.SDL_GPU_SHADERFORMAT_SPIRV
                                                  | .SDL_GPU_SHADERFORMAT_DXIL
                                                  | .SDL_GPU_SHADERFORMAT_MSL
                                                  | .SDL_GPU_SHADERFORMAT_METALLIB,
                                                  true, nil)
        else {
            fatalError("Error: SDL_CreateGPUDevice(): \(String(cString: SDL_GetError()))")
        }
        self.gpuDevice = gpuDevice
        
        // Claim window for GPU Device
        if (!SDL_ClaimWindowForGPUDevice(gpuDevice, window))
        {
            fatalError("Error: SDL_ClaimWindowForGPUDevice(): \(String(cString: SDL_GetError()))")
        }
        SDL_SetGPUSwapchainParameters(gpuDevice, window, SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL_GPU_PRESENTMODE_VSYNC);
        
        // Setup Dear ImGui context
        _ = ImGui.CreateContext()
        let io = ImGui.GetIO()
        io.pointee.ConfigFlags |= Int32(bitPattern: ImGuiConfigFlags_NavEnableKeyboard.rawValue)
        
        // Setup Dear ImGui style
        ImGui.StyleColorsDark()
        //ImGui::StyleColorsLight();
        
        // Setup scaling
        let style = ImGui.GetStyle()
        style.pointee.ScaleAllSizes(displayScale);        // Bake a fixed style scale. (until we have a solution for dynamic style scaling, changing this requires resetting Style + calling this again)
        style.pointee.FontScaleDpi = displayScale;        // Set initial font scale. (in docking branch: using io.ConfigDpiScaleFonts=true automatically overrides this for every window depending on the current monitor)
        
        // Setup Platform/Renderer backends
        ImGui_ImplSDL3_InitForSDLGPU(window);
        var initInfo = ImGui_ImplSDLGPU3_InitInfo(
            Device: gpuDevice,
            ColorTargetFormat: SDL_GetGPUSwapchainTextureFormat(gpuDevice, window),
            MSAASamples: SDL_GPU_SAMPLECOUNT_1,
            SwapchainComposition: SDL_GPU_SWAPCHAINCOMPOSITION_SDR,
            PresentMode: SDL_GPU_PRESENTMODE_VSYNC
        )
        
        ImGui_ImplSDLGPU3_Init(&initInfo)
        
        // TODO: Load Fonts

        return true
    }
    
    func mainLoop() {
        var done: Bool = false
        
        while !done {
            var event: SDL_Event = SDL_Event()
            while SDL_PollEvent(&event) {
                ImGui_ImplSDL3_ProcessEvent(&event);
                if (event.type == SDL_EVENT_QUIT.rawValue) {
                    done = true
                }
                if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED.rawValue && event.window.windowID == SDL_GetWindowID(mainWindow)) {
                    done = true
                }
            }
            
            if (SDL_GetWindowFlags(mainWindow) & .SDL_WINDOW_MINIMIZED) != 0
            {
                SDL_Delay(10)
                continue
            }

            // Start the Dear ImGui frame
            ImGui_ImplSDLGPU3_NewFrame()
            ImGui_ImplSDL3_NewFrame()
            ImGui.NewFrame()

            ImGui.Begin("Hello, world!")
            ImGui.TextUnformatted("This is some useful text.")
            ImGui.End()

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
    
}
