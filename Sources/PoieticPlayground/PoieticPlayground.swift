// The Swift Programming Language
// https://docs.swift.org/swift-book

import CIimgui

@main
struct PoieticPlayground {
    static func main() {
        let backend: any GraphicsBackendProtocol
        
        do {
            backend = try Self.initializeBackend()
            GraphicsBackend.register(backend)
            try Self.initializeImGui(backend)
        } catch {
            fatalError("Initialisation failed: \(error)")
        }
        // Initialise Application Context (Globals)
        let style = InterfaceStyle(scheme: .light)
        InterfaceStyle.current = style
        let manager = ResourceManager(ResourceManager.DefaultResourcesPath, backend: backend)
        ResourceManager.registerShared(manager)
        let app: Application = Application()
        
        app.run()
        
        shutdownImGui(backend)
        backend.waitIdle()
        backend.shutdown()
    }
    
    @MainActor
    static func initializeBackend() throws (GraphicsBackendError) -> any GraphicsBackendProtocol {
        let backend = try SDL3GPUBackend.initialize(
            windowTitle: Application.MainWindowName,
            width: Application.DefaultWindowWidth,
            height: Application.DefaultWindowHeight
        )
        return backend
    }
   
    static func initializeImGui(_ backend: any GraphicsBackendProtocol) throws (GraphicsBackendError) {
        let scale = backend.displayScale

        _ = ImGui.CreateContext()
        let io = ImGui.GetIO()
        io.pointee.ConfigFlags |= Int32(bitPattern: ImGuiConfigFlags_NavEnableKeyboard.rawValue)

        ImGui.StyleColorsLight()

        let style = ImGui.GetStyle()
        style.pointee.ScaleAllSizes(scale)
        style.pointee.FontScaleDpi = scale

        // TODO: Load Fonts

        try backend.initializeImGuiBackend()
    }

    static func shutdownImGui(_ backend: any GraphicsBackendProtocol) {
        backend.shutdownImGuiBackend()
        ImGui.DestroyContext()
    }

}
