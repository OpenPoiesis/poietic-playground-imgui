//
//  SDL3GPUBackend.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 17/02/2026.
//

import Csdl3
import CIimgui

final class SDL3GPUBackend: GraphicsBackendProtocol {
    private static let SwapchainComposition = SDL_GPU_SWAPCHAINCOMPOSITION_SDR
    private static let PresentMode = SDL_GPU_PRESENTMODE_VSYNC

    let displayScale: Float
    private let window: OpaquePointer
    private let device: OpaquePointer

    private init(window: OpaquePointer, device: OpaquePointer, displayScale: Float) {
        self.window = window
        self.device = device
        self.displayScale = displayScale
    }

    func initializeImGuiBackend() throws (GraphicsBackendError) {
        guard ImGui_ImplSDL3_InitForSDLGPU(window) else {
            throw GraphicsBackendError("ImGui_ImplSDL3_InitForSDLGPU failed", backendError: Self.getError())
        }

        var initInfo = ImGui_ImplSDLGPU3_InitInfo(
            Device: device,
            ColorTargetFormat: SDL_GetGPUSwapchainTextureFormat(device, window),
            MSAASamples: SDL_GPU_SAMPLECOUNT_1,
            SwapchainComposition: Self.SwapchainComposition,
            PresentMode: Self.PresentMode
        )
        guard ImGui_ImplSDLGPU3_Init(&initInfo) else {
            throw GraphicsBackendError("ImGui_ImplSDLGPU3_Init failed", backendError: Self.getError())
        }
    }
    
    func shutdownImGuiBackend() {
        ImGui_ImplSDL3_Shutdown()
        ImGui_ImplSDLGPU3_Shutdown()
    }
    
    // MARK: - Main Loop
    
    func pollEvent() -> BackendEvent {
        var event = SDL_Event()

        while SDL_PollEvent(&event) {
            switch event.type {
            case SDL_EVENT_QUIT.rawValue:
                return .quit
            case SDL_EVENT_WINDOW_CLOSE_REQUESTED.rawValue
                    where event.window.windowID == SDL_GetWindowID(window):
                return .quit
            default:
                break
            }
            ImGui_ImplSDL3_ProcessEvent(&event)
        }

        if (SDL_GetWindowFlags(window) & .SDL_WINDOW_MINIMIZED) != 0 {
            SDL_Delay(10)
            return .skip
        }
        return .none
    }

    func render() {
        let drawData = ImGui.GetDrawData()
        let isMinimized = (drawData.pointee.DisplaySize.x <= 0.0 || drawData.pointee.DisplaySize.y <= 0.0)

        guard let commandBuffer = SDL_AcquireGPUCommandBuffer(device) else {
            fatalError("SDL_AcquireGPUCommandBuffer failed")
        }

        var swapchainTexture: OpaquePointer! = nil
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, window, &swapchainTexture, nil, nil)
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
    
    // MARK: - Startup/Shutdown
    
    func waitIdle() {
        SDL_WaitForGPUIdle(device)
    }

    func shutdown() {
        SDL_ReleaseWindowFromGPUDevice(device, window)
        SDL_DestroyGPUDevice(device)
        SDL_DestroyWindow(window)
        SDL_Quit()
    }

    static func initialize(windowTitle: String, width: Int, height: Int)
        throws (GraphicsBackendError) -> SDL3GPUBackend
    {
        guard SDL_Init(SDL_INIT_VIDEO) else {
            throw GraphicsBackendError("SDL_Init failed", backendError: getError())
        }
        let scale = displayScale()
        let window = try createWindow(title: windowTitle, width: width, height: height, scale: scale)
        let device = try createGPUDevice()
        try Self.claimWindow(device: device, window: window)
        SDL_SetGPUSwapchainParameters(device, window,
                                      Self.SwapchainComposition,
                                      Self.PresentMode)

        return SDL3GPUBackend(window: window, device: device, displayScale: scale)
    }
    
    private static func createWindow(title: String, width: Int, height: Int, scale: Float)
        throws (GraphicsBackendError) -> OpaquePointer
    {
        let flags: SDL_WindowFlags = .SDL_WINDOW_RESIZABLE | .SDL_WINDOW_HIDDEN | .SDL_WINDOW_HIGH_PIXEL_DENSITY
        guard let window = SDL_CreateWindow(title,
                                            Int32(Float(width) * scale),
                                            Int32(Float(height) * scale),
                                            flags)
        else {
            throw GraphicsBackendError("SDL_CreateWindow failed", backendError: getError())
        }
        SDL_SetWindowPosition(window, dSDL_WINDOWPOS_CENTERED.rawValue, dSDL_WINDOWPOS_CENTERED.rawValue)
        SDL_ShowWindow(window)
        return window
    }

    private static func createGPUDevice()
    throws (GraphicsBackendError) -> OpaquePointer
    {
        guard let device = SDL_CreateGPUDevice(
            .SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL
            | .SDL_GPU_SHADERFORMAT_MSL | .SDL_GPU_SHADERFORMAT_METALLIB,
            true, nil)
        else {
            throw GraphicsBackendError("SDL_CreateGPUDevice failed", backendError: getError())
        }
        return device
    }
    private static func claimWindow(device: OpaquePointer, window: OpaquePointer)
    throws (GraphicsBackendError)
    {
        guard SDL_ClaimWindowForGPUDevice(device, window) else {
            throw GraphicsBackendError("SDL_ClaimWindowForGPUDevice failed", backendError: getError())
        }
    }

    // MARK: - Texture
    func createTexture(pixels: UnsafeRawPointer, width: UInt32, height: UInt32)
    throws (GraphicsBackendError) -> TextureHandle
    {
        let texture = try allocateGPUTexture(width: width, height: height)
        var success = false
        defer {
            if !success { SDL_ReleaseGPUTexture(device, texture) }
        }

        try uploadPixels(pixels, width: width, height: height, to: texture)
        assert(MemoryLayout<ImTextureID>.size == MemoryLayout<OpaquePointer>.size)

        let textureID = unsafeBitCast(texture, to: ImTextureID.self)

        success = true
        return TextureHandle(width: width, height: height, textureID: textureID)
    }

    func destroyTexture(_ handle: TextureHandle) {
        let texture = unsafeBitCast(handle.textureID, to: OpaquePointer.self)
        SDL_ReleaseGPUTexture(device, texture)
    }

    // MARK: - Private

    private func allocateGPUTexture(width: UInt32, height: UInt32)
    throws (GraphicsBackendError) -> OpaquePointer
    {
        var info = SDL_GPUTextureCreateInfo()
        info.type         = SDL_GPU_TEXTURETYPE_2D
        info.format       = SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM
        info.usage        = SDL_GPU_TEXTUREUSAGE_SAMPLER
        info.width        = width
        info.height       = height
        info.layer_count_or_depth = 1
        info.num_levels   = 1
        info.sample_count = SDL_GPU_SAMPLECOUNT_1

        guard let texture = SDL_CreateGPUTexture(device, &info) else {
            throw GraphicsBackendError("SDL_CreateGPUTexture failed", backendError: Self.getError())
        }
        return texture
    }

    private func uploadPixels(_ pixels: UnsafeRawPointer,
                              width: UInt32,
                              height: UInt32,
                              to texture: OpaquePointer)
    throws (GraphicsBackendError)
    {
        let byteCount = width * height * 4

        var transferInfo = SDL_GPUTransferBufferCreateInfo()
        transferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
        transferInfo.size  = byteCount

        guard let transferBuffer = SDL_CreateGPUTransferBuffer(device, &transferInfo) else {
            throw GraphicsBackendError("SDL_CreateGPUTransferBuffer failed", backendError: Self.getError())
        }
        defer { SDL_ReleaseGPUTransferBuffer(device, transferBuffer) }

        guard let mapped = SDL_MapGPUTransferBuffer(device, transferBuffer, true) else {
            throw GraphicsBackendError("SDL_MapGPUTransferBuffer failed", backendError: Self.getError())
        }
        mapped.copyMemory(from: pixels, byteCount: Int(byteCount))
        SDL_UnmapGPUTransferBuffer(device, transferBuffer)

        guard let cmd = SDL_AcquireGPUCommandBuffer(device) else {
            throw GraphicsBackendError("SDL_AcquireGPUCommandBuffer failed", backendError: Self.getError())
        }
        guard let copyPass = SDL_BeginGPUCopyPass(cmd) else {
            SDL_SubmitGPUCommandBuffer(cmd)
            throw GraphicsBackendError("SDL_BeginGPUCopyPass failed", backendError: Self.getError())
        }

        var src = SDL_GPUTextureTransferInfo()
        src.transfer_buffer = transferBuffer
        src.offset = 0

        var dst = SDL_GPUTextureRegion()
        dst.texture = texture
        dst.w = width
        dst.h = height
        dst.d = 1

        SDL_UploadToGPUTexture(copyPass, &src, &dst, false)
        SDL_EndGPUCopyPass(copyPass)
        SDL_SubmitGPUCommandBuffer(cmd)
    }

    
    // MARK: - Misc
    static func getError() -> String {
        return String(cString: SDL_GetError())
    }
    static func displayScale(_ display: UInt32? = nil) -> Float {
        SDL_GetDisplayContentScale(display ?? SDL_GetPrimaryDisplay())
    }
}
