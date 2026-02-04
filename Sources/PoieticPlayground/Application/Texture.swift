//
//  Texture.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

import CIimgui

class Texture {
    let width: UInt32
    let height: UInt32
    let textureID: ImTextureID
    
    init(width: UInt32, height: UInt32, textureID: ImTextureID) {
        self.width = width
        self.height = height
        self.textureID = textureID
    }
    
}
