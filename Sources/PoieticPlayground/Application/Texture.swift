//
//  Texture.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

import CIimgui

struct TextureHandle {
    let width: UInt32
    let height: UInt32
    let textureID: ImTextureID

    var size: ImVec2 { ImVec2(Float(width), Float(height)) }
    
    var imTextureRef: ImTextureRef { ImTextureRef(textureID) }

    init(width: UInt32, height: UInt32, textureID: ImTextureID) {
        self.width = width
        self.height = height
        self.textureID = textureID
    }
}
