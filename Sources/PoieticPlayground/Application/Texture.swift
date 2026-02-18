//
//  Texture.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

import CIimgui

class Texture {
//    let handle: TextureHandle
//
//    var width: UInt32  { handle.width }
//    var height: UInt32 { handle.height }
//    var imTextureID: ImTextureID { handle.imTextureID }

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
