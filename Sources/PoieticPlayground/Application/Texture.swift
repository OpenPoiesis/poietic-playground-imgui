//
//  Texture.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

import CIimgui

enum TexturePixelFormat {
    case RGBA
    case RGBAPreMultiplied
    
    /// Number of bytes per pixel
    var size: Int { 4 }
}

struct TextureHandle {
    let width: UInt32
    let height: UInt32
    let textureID: ImTextureID
    let format: TexturePixelFormat

    var size: ImVec2 { ImVec2(Float(width), Float(height)) }
    
    var imTextureRef: ImTextureRef { ImTextureRef(textureID) }

    init(width: UInt32, height: UInt32, textureID: ImTextureID, format: TexturePixelFormat = .RGBA) {
        self.width = width
        self.height = height
        self.textureID = textureID
        self.format = format
    }
}
