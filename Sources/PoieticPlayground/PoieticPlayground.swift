// The Swift Programming Language
// https://docs.swift.org/swift-book

let DefaultResourcesPath = "Sources/PoieticPlayground/Resources/"

@main
struct PoieticPlayground {
    static func main() {
        let app: Application
        
        do {
            try Application.initializeBackend()
            app = Application()
            try app.initializeImGui()
        } catch {
            fatalError("Initialisation failed: \(error)")
        }
        let manager = ResourceManager(DefaultResourcesPath, backend: GraphicsBackend.shared)
        ResourceManager.registerShared(manager)
        app.run()
        app.shutdownImGui()
        GraphicsBackend.shared.waitIdle()
        GraphicsBackend.shared.shutdown()
    }
}
