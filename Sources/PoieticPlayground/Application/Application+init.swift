//
//  Application+init.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//

import CIimgui
import Csdl3

extension Application {
    func initializeSDL() -> Bool {
        // From: https://github.com/ocornut/imgui/blob/master/examples/example_sdl3_sdlgpu3/main.cpp
        
        guard SDL_Init(SDL_INIT_VIDEO) else {
            let err = String(cString: SDL_GetError())
            fatalError("SDL_Init Error: \(err)")
        }
        
        // Create SDL window graphics context
        let displayScale = SDL_GetDisplayContentScale(SDL_GetPrimaryDisplay())
        let windowFlags: SDL_WindowFlags =  .SDL_WINDOW_RESIZABLE | .SDL_WINDOW_HIDDEN | .SDL_WINDOW_HIGH_PIXEL_DENSITY
        
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
        return true
    }
    
    func initializeImGui() -> Bool {
        _ = ImGui.CreateContext()
        let io = ImGui.GetIO()
        io.pointee.ConfigFlags |= Int32(bitPattern: ImGuiConfigFlags_NavEnableKeyboard.rawValue)
        
        ImGui.StyleColorsDark()
        //ImGui::StyleColorsLight();
        
        // Setup scaling
        let style = ImGui.GetStyle()
        // Bake a fixed style scale. (until we have a solution for dynamic style scaling, changing this requires resetting Style + calling this again)
        style.pointee.ScaleAllSizes(displayScale)
        // Set initial font scale. (in docking branch: using io.ConfigDpiScaleFonts=true automatically overrides this for every window depending on the current monitor)
        style.pointee.FontScaleDpi = displayScale
        
        // Setup Platform/Renderer backends
        guard ImGui_ImplSDL3_InitForSDLGPU(mainWindow) else {
            fatalError("ImGui_ImplSDL3_InitForSDLGPU failed")
        }

        var initInfo = ImGui_ImplSDLGPU3_InitInfo(
            Device: gpuDevice,
            ColorTargetFormat: SDL_GetGPUSwapchainTextureFormat(gpuDevice, mainWindow),
            MSAASamples: SDL_GPU_SAMPLECOUNT_1,
            SwapchainComposition: SDL_GPU_SWAPCHAINCOMPOSITION_SDR,
            PresentMode: SDL_GPU_PRESENTMODE_VSYNC
        )
        
        guard ImGui_ImplSDLGPU3_Init(&initInfo) else {
            fatalError("ImGui_ImplSDLGPU3_Init failed")
        }
        
        // TODO: Load Fonts

        return true
    }

}
