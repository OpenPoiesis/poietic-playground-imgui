//
//  Application+init.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//

import CIimgui
import Csdl3

extension Application {
    
    @MainActor static func initializeBackend() throws {
        let backend = try SDL3GPUBackend.initialize(
            windowTitle: Application.MainWindowName,
            width: Application.DefaultWindowWidth,
            height: Application.DefaultWindowHeight
        )
        GraphicsBackend.register(backend)
    }

    @MainActor func initializeImGui() throws (GraphicsBackendError) {
        let backend = GraphicsBackend.shared
        let scale = backend.displayScale

        _ = ImGui.CreateContext()
        let io = ImGui.GetIO()
        io.pointee.ConfigFlags |= Int32(bitPattern: ImGuiConfigFlags_NavEnableKeyboard.rawValue)

        ImGui.StyleColorsDark()

        let style = ImGui.GetStyle()
        style.pointee.ScaleAllSizes(scale)
        style.pointee.FontScaleDpi = scale

        // TODO: Load Fonts

        try backend.initializeImGuiBackend()
    }

    @MainActor func shutdownImGui() {
        GraphicsBackend.shared.shutdownImGuiBackend()
        ImGui.DestroyContext()
    }
}
