//
//  ResourceLoader.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

// TODO: Use enum for known icons/images
// FIXME: Convert fatalErrors to exceptions (if appropriate)

import CIimgui
import Cstb
import Csdl3
import Foundation

struct ResourceError: Error {
    enum ErrorType {
        case invalidData
        case loadingFailed
    }
    let type: ErrorType
    let resource: String
}

class ResourceManager {
    @MainActor static var shared: (ResourceManager) {
        guard let backend = _shared else {
            fatalError("ResourceManager not initialized")
        }
        return backend
    }
    @MainActor private static var _shared: (ResourceManager)?
    @MainActor static func registerShared(_ manager: ResourceManager) {
        precondition(_shared == nil, "Backend already registered.")
        _shared = manager
    }
    
    let root: URL
    var backend: any GraphicsBackendProtocol
    var textures: [String:Texture] = [:]
    
    init(_ rootPath: String, backend: any GraphicsBackendProtocol) {
        self.root = URL(fileURLWithPath: rootPath)
        self.backend = backend
    }
    
    func resourceURL(_ resourcePath: String) -> URL {
        return root.appending(path: resourcePath)
    }
    func resourceFilePath(_ resourcePath: String) -> URL {
        return root.appending(path: resourcePath)
    }
    
    func loadData(_ path: String) -> Data? {
        let url = resourceURL(path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data
    }
    
    @MainActor func loadTexture(_ path: String, as name: String) -> Texture? {
        // TODO: Consolidate API and error handling
        guard let data = loadData(path) else { return nil }
        return try? loadTexture(data: data, as: name)
    }
    
    @MainActor func loadTexture(data: Data, as name: String) throws -> Texture {
        let backend = GraphicsBackend.shared
        
        if let existing = textures[name] { return existing }
        
        let pixels = decodeImageData(data)
        defer { stbi_image_free(pixels.pointer) }
        
        let texture = try backend.createTexture(
            pixels: pixels.pointer,
            width:  pixels.width,
            height: pixels.height
        )
        textures[name] = texture
        return texture
    }
    
    private struct DecodedImage {
        let pointer: UnsafeMutableRawPointer
        let width: UInt32
        let height: UInt32
        let channels: UInt32
    }
    
    private func decodeImageData(_ data: Data) -> DecodedImage {
        var w: Int32 = 0
        var h: Int32 = 0
        var channels: Int32 = 0
        
        let raw = data.withUnsafeBytes { buffer -> UnsafeMutablePointer<stbi_uc> in
            guard let base = buffer.baseAddress?.assumingMemoryBound(to: stbi_uc.self) else {
                fatalError("Invalid image data buffer")
            }
            guard let decoded = stbi_load_from_memory(base, Int32(data.count), &w, &h, &channels, 4) else {
                fatalError("stbi_load_from_memory failed")
            }
            return decoded
        }
        
        return DecodedImage(pointer: UnsafeMutableRawPointer(raw),
                            width: UInt32(w),
                            height: UInt32(h),
                            channels: UInt32(channels))
    }
    
}
