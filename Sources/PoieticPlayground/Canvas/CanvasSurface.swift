//
//  CanvasSurface.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import Ccairo

enum CanvasSurfaceError: Error {
    case noContext
    case noSurface
    case noData
    case uploadFailed(any Error)
}

class CanvasSurface {
    /// Name of the surface for debugging purposes.
    let name: String
    
    private var surface: OpaquePointer? // cairo_surface_t*
    private var context: OpaquePointer? // cairo_t*
    private(set) var texture: TextureHandle?

    private var width: Int32 = 0
    private var height: Int32 = 0
    
    // rename to requiresUpload
    private(set) var isDirty: Bool = true
//    private(set) var requiresRedraw: Bool = true

    init(name: String) {
        self.name = name
    }
    
    @MainActor
    func ensureSize(width: Int32, height: Int32) {
        guard width > 0 && height > 0 else { return }
        
        if width != self.width || height != self.height {
            destroy()
            create(width: width, height: height)
            self.width = width
            self.height = height
            isDirty = true
        }
    }

    private func create(width: Int32, height: Int32) {
        precondition(surface == nil && context == nil)

        surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height)
        context = cairo_create(surface)
    }
    
    /// - Important: Must be called manually when disposing of the surface
    @MainActor
    func destroy() {
        if let texture {
            GraphicsBackend.shared.destroyTexture(texture)
            self.texture = nil
        }
        
        if let context {
            cairo_destroy(context)
            self.context = nil
        }

        if let surface {
            cairo_surface_destroy(surface)
            self.surface = nil
        }
        
        width = 0
        height = 0
    }

    func render(_ draw: (OpaquePointer) -> Void) throws (CanvasSurfaceError) {
        guard let context else {
            throw .noContext
        }
        
        cairo_save(context)
        cairo_set_operator(context, CAIRO_OPERATOR_CLEAR)
        cairo_paint(context)
        cairo_restore(context)
        cairo_set_operator(context, CAIRO_OPERATOR_OVER)
        draw(context)
        isDirty = true
    }
    
    @MainActor
    func uploadToGPU() throws (CanvasSurfaceError) {
        guard isDirty else { return }
        guard let surface = surface else {
            throw .noSurface
        }
        
        cairo_surface_flush(surface)
        
        guard let data = cairo_image_surface_get_data(surface) else {
            throw .noData
        }
        
        let w = UInt32(cairo_image_surface_get_width(surface))
        let h = UInt32(cairo_image_surface_get_height(surface))
        
        let backend = GraphicsBackend.shared
        
        if let oldTexture = texture {
            backend.destroyTexture(oldTexture)
        }
        
        do {
            texture = try backend.createTexture(pixels: data, width: w, height: h)
            isDirty = false
        }
        catch {
            throw .uploadFailed(error)
        }
    }
    
    func markDirty() {
        self.isDirty = true
    }
}

class SurfaceLayerStack {
    private var layers: [CanvasSurface] = []
    
    /// Add a layer to the stack (bottom to top order)
    func add(_ surface: CanvasSurface) {
        layers.append(surface)
    }
    
    /// Get first surface layer with given name
    func layer(named name: String) -> CanvasSurface? {
        layers.first { $0.name == name }
    }
    
    /// Ensure all layers match given size
    @MainActor
    func ensureSize(width: Int32, height: Int32) {
        for layer in layers {
            layer.ensureSize(width: width, height: height)
        }
    }
    
    /// Upload all dirty layers to GPU
    @MainActor
    func uploadDirty() throws (CanvasSurfaceError) {
        for layer in layers {
            guard layer.isDirty else { continue }
            try layer.uploadToGPU()
        }
    }
    
    /// Get textures in draw order (bottom to top)
    func textures() -> [TextureHandle] {
        layers.compactMap { $0.texture }
    }
    
    /// Mark all layers dirty
    func markAllDirty() {
        layers.forEach { $0.markDirty() }
    }
}
