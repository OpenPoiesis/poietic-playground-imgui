//
//  Color.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui


let DefaultAdaptableColors: [String:Color] = [
    "purple": Color(red: 0.61176, green: 0.15294, blue: 0.6902),
    "red": Color(red: 0.95686, green: 0.26275, blue: 0.21176),
    "pink": Color(red: 0.91373, green: 0.11765, blue: 0.38824),
    "brown": Color(red: 0.47451, green: 0.33333, blue: 0.28235),
    "orange": Color(red: 1, green: 0.59608, blue: 0),
    "yellow": Color(red: 1, green: 0.92157, blue: 0.23137),
    "lime": Color(red: 0.76471, green: 0.96863, blue: 0.2549),
    "green": Color(red: 0.29804, green: 0.68627, blue: 0.31373),
    "cyan": Color(red: 0, green: 0.73725, blue: 0.83137),
    "teal": Color(red: 0, green: 0.58824, blue: 0.53333),
    "blue": Color(red: 0.12941, green: 0.58824, blue: 0.95294),
    "indigo": Color(red: 0.24706, green: 0.31765, blue: 0.7098),
]

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
    
    // Screen colors
    static let screenRed = Color(red: 1.0, green: 0.0, blue: 0.0)
    static let screenGreen = Color(red: 0.0, green: 1.0, blue: 0.0)
    static let screenBlue = Color(red: 0.0, green: 0.0, blue: 1.0)
    
    static let screenYellow = Color(red: 1.0, green: 1.0, blue: 0.0)
    static let screenCyan = Color(red: 0.0, green: 1.0, blue: 1.0)
    static let screenMagenta = Color(red: 1.0, green: 0.0, blue: 1.0)
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
