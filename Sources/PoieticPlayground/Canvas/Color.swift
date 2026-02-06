//
//  Color.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui

/// Screen colour representation.
///
struct Color {
    private let value: SIMD4<Float>
    
    var alpha: Float { value.w }
    
    init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.value = SIMD4(red, green, blue, alpha)
    }

    init(gray: Float, alpha: Float = 1.0) {
        self.value = SIMD4(gray, gray, gray, alpha)
    }
    
    static let black = Color(gray: 0.0)
    static let white = Color(gray: 1.0)
    static let clear = Color(gray: 0.0, alpha: 0.0)
}

extension Color {
    var imVecValue: ImVec4 {
        ImVec4(value.x, value.y, value.z, value.w)
    }
    var imIntValue: ImU32 {
        let vec = ImVec4(value.x, value.y, value.z, value.w)
        return ImGui.ColorConvertFloat4ToU32(vec)
    }

    init(_ imColor: ImColor) {
        let vec = imColor.Value
        self.value = SIMD4(vec.x, vec.y, vec.z, vec.w)
    }
    
    /// Create a colour from ImGui integer ImU32 value.
    init(_ intValue: ImU32) {
        let vec = ImGui.ColorConvertU32ToFloat4(intValue)
        let imColor = ImColor(vec)
        self.init(imColor)
    }

}
