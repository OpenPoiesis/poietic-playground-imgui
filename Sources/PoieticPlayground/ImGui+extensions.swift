//
//  ImGui+extensions.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 29/01/2026.
//
import CIimgui
import Diagramming

extension ImGui {
//    static func PushID(_ idString: String) {
//        idString.withCString { cString in
//            ImGui.PushID(cString)
//        }
//    }
}

extension Vector2D {
    init(_ vec: ImVec2) {
        self = Vector2D(Double(vec.x), Double(vec.y))
    }
}

extension ImVec2 {
    init(_ vec: Vector2D) {
        self = ImVec2(Float(vec.x), Float(vec.y))
    }
    static func +(lhs: ImVec2, rhs: ImVec2) -> ImVec2 {
        return ImVec2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    static func -(lhs: ImVec2, rhs: ImVec2) -> ImVec2 {
        return ImVec2(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    func length() -> Float {
        let vec:SIMD2<Float> = SIMD2(self.x, self.y)
        return (vec * vec).sum().squareRoot()
    }

    func lengthSquared() -> Float {
        let vec:SIMD2<Float> = SIMD2(self.x, self.y)
        return (vec * vec).sum()
    }

    static func *(lhs: ImVec2, rhs: Float) -> ImVec2 {
        return ImVec2(lhs.x * rhs, lhs.y * rhs)
    }
    static func /(lhs: ImVec2, rhs: Float) -> ImVec2 {
        return ImVec2(lhs.x / rhs, lhs.y / rhs)
    }
}

extension ImVec2: @retroactive CustomStringConvertible {
    public var description: String {
        "(\(self.x),\(self.y))"
    }
}

extension ImColor {
    var intValue: UInt32 {
        ImGui.ColorConvertFloat4ToU32(self.Value)
    }
}

extension ImGuiKey {
    static func |(lhs: ImGuiKey, rhs: ImGuiKey) -> ImGuiKeyChord {
        ImGuiKeyChord(lhs.rawValue | rhs.rawValue)
    }
    static func |(lhs: ImGuiKeyChord, rhs: ImGuiKey) -> ImGuiKeyChord {
        ImGuiKeyChord(lhs | rhs.rawValue)
    }
}

extension ImGuiWindowFlags {
    static func |(lhs: ImGuiWindowFlags, rhs: ImGuiWindowFlags_) -> ImGuiWindowFlags {
        ImGuiWindowFlags(lhs | Int32(bitPattern: rhs.rawValue))
    }
}
extension ImGuiWindowFlags_ {
    static func |(lhs: ImGuiWindowFlags_, rhs: ImGuiWindowFlags_) -> ImGuiWindowFlags {
        ImGuiWindowFlags(Int32(bitPattern: lhs.rawValue) | Int32(bitPattern: rhs.rawValue))
    }
}


extension ImGuiButtonFlags {
    static func |(lhs: ImGuiButtonFlags, rhs: ImGuiButtonFlags_) -> ImGuiButtonFlags {
        ImGuiButtonFlags(lhs | Int32(bitPattern: rhs.rawValue))
    }
}
extension ImGuiButtonFlags_ {
    static func |(lhs: ImGuiButtonFlags_, rhs: ImGuiButtonFlags_) -> ImGuiButtonFlags {
        ImGuiButtonFlags(Int32(bitPattern: lhs.rawValue) | Int32(bitPattern: rhs.rawValue))
    }
}

extension ImGuiChildFlags {
    static func |(lhs: ImGuiChildFlags, rhs: ImGuiChildFlags_) -> ImGuiChildFlags {
        ImGuiButtonFlags(lhs | Int32(bitPattern: rhs.rawValue))
    }
}
extension ImGuiChildFlags_ {
    static func |(lhs: ImGuiChildFlags_, rhs: ImGuiChildFlags_) -> ImGuiChildFlags {
        ImGuiButtonFlags(Int32(bitPattern: lhs.rawValue) | Int32(bitPattern: rhs.rawValue))
    }
}

extension ImGuiHoveredFlags {
    static func |(lhs: ImGuiHoveredFlags, rhs: ImGuiHoveredFlags_) -> ImGuiHoveredFlags {
        ImGuiHoveredFlags(lhs | Int32(bitPattern: rhs.rawValue))
    }
}
extension ImGuiHoveredFlags_ {
    static func |(lhs: ImGuiHoveredFlags_, rhs: ImGuiHoveredFlags_) -> ImGuiHoveredFlags {
        ImGuiHoveredFlags(Int32(bitPattern: lhs.rawValue) | Int32(bitPattern: rhs.rawValue))
    }
}
