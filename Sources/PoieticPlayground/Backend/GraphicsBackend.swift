//
//  GraphicsBackend.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 17/02/2026.
//

import CIimgui

struct GraphicsBackendError: Error, CustomStringConvertible {
    let message: String
    let backendError: String?
    
    init(_ message: String, backendError: String? = nil) {
        self.message = message
        self.backendError = backendError
    }
    
    var description: String {
        if let backendError { message + ". Underlying error: " + backendError }
        else { message }
    }
}

protocol GraphicsBackendProtocol: AnyObject {
    var displayScale: Float { get }
    
    func initializeImGuiBackend() throws (GraphicsBackendError)
    func shutdownImGuiBackend()
    
    func pollEvent() -> BackendEvent
    func waitIdle()
    func shutdown()
    
    func newFrame()
    func render()
    
    func withBlendMode<T>(_ mode: TextureBlendMode,
                          drawList: UnsafeMutablePointer<ImDrawList>,
                          _ block: () -> T) -> T

    // Textures
    func createTexture(pixels: UnsafeRawPointer, width: UInt32, height: UInt32) throws (GraphicsBackendError)-> TextureHandle
    func destroyTexture(_ handle: TextureHandle)
}

extension GraphicsBackendProtocol {
    func withBlendMode<T>(_ mode: TextureBlendMode,
                         drawList: UnsafeMutablePointer<ImDrawList>,
                          _ block: () -> T) -> T
    {
        return block()
    }

}

enum BackendEvent {
    /// Proceed with frame processing
    case none
    /// Quit the application
    case quit
    /// Skip this frame
    case skip
}

enum TextureBlendMode {
    case premultiplied
    case straight
}


@MainActor
enum GraphicsBackend {
    static var shared: (any GraphicsBackendProtocol) {
        guard let backend = _shared else {
            fatalError("GraphicsBackend not initialized")
        }
        return backend
    }
    
    private static var _shared: (any GraphicsBackendProtocol)?
    
    @MainActor
    static func register(_ backend: any GraphicsBackendProtocol) {
        precondition(_shared == nil, "Backend already registered.")
        _shared = backend
    }
}



