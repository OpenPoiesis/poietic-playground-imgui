//
//  ToolEvent.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 03/02/2026.
//
import CIimgui
import Diagramming

/// Key modifiers for a tool event.
///
/// - SeeAlso: ``ToolEvent``
///
struct KeyModifiers: OptionSet, CustomStringConvertible {
    var rawValue: UInt8
    
    /// Command on MacOS or Control on other systems.
    static let none: KeyModifiers = []
    static let command = KeyModifiers(rawValue: 1)
    static let shift = KeyModifiers(rawValue: 2)
    static let alt = KeyModifiers(rawValue: 4)
    
    var description: String {
        var desc = ""
        if self.contains(.command) { desc += "⌘"}
        if self.contains(.shift) { desc += "⇧"}
        if self.contains(.alt) { desc += "⎇"}
        return desc
    }
}

extension KeyModifiers {
    /// Create a key modifiers structure from ImGui keyboard chord.
    ///
    init(_ chord: ImGuiKeyChord) {
        var value: KeyModifiers = .none
        
        if chord & ImGuiMod_Ctrl.rawValue != 0 {
            value.formUnion(.command)
        }
        if chord & ImGuiMod_Shift.rawValue != 0 {
            value.formUnion(.shift)
        }
        if chord & ImGuiMod_Alt.rawValue != 0 {
            value.formUnion(.alt)
        }

        self = value
    }
}

enum MouseButton: CaseIterable, CustomStringConvertible {
    case left
    case right
    case middle
    case other1
    case other2
    
    var mask: MouseButtonMask {
        switch self {
        case .left: .left
        case .right: .right
        case .middle: .middle
        case .other1: .other1
        case .other2: .other2
        }
    }
    var description: String {
        switch self {
        case .left: "L"
        case .right: "R"
        case .middle: "M"
        case .other1: "O₁"
        case .other2: "O₂"
        }
    }

    func unpackItem<T>(_ imGuiButtons: (T, T, T, T, T)) -> T {
        switch self {
        case .left: imGuiButtons.0
        case .right: imGuiButtons.1
        case .middle: imGuiButtons.2
        case .other1: imGuiButtons.3
        case .other2: imGuiButtons.4
        }
    }
}

struct MouseButtonMask: OptionSet, CustomStringConvertible {
    let rawValue: UInt8
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    var isDown: Bool { rawValue != 0 }
    
    static let none: MouseButtonMask = []
    static let left = MouseButtonMask(rawValue: 1 << 0)
    static let right = MouseButtonMask(rawValue: 1 << 1)
    static let middle = MouseButtonMask(rawValue: 1 << 2)
    static let other1 = MouseButtonMask(rawValue: 1 << 3)
    static let other2 = MouseButtonMask(rawValue: 1 << 4)
    
    var description: String {
        var desc: String = "["
        if self.contains(.left) { desc += "L" }
        if self.contains(.right) { desc += "R" }
        if self.contains(.middle) { desc += "M" }
        if self.contains(.other1) { desc += "O₁" }
        if self.contains(.other2) { desc += "O₂" }
        desc += "]"
        return desc

    }
    
    init(_ imGuiButtons: (Bool, Bool, Bool, Bool, Bool)) {
        var value: Self = .none
        if imGuiButtons.0 { value.insert(.left) }
        if imGuiButtons.1 { value.insert(.right) }
        if imGuiButtons.2 { value.insert(.middle) }
        if imGuiButtons.3 { value.insert(.other1) }
        if imGuiButtons.4 { value.insert(.other2) }

        self = value
    }
    // Make a Sequence by providing an iterator
    var buttons: some Sequence<MouseButton> {
        return sequence(state: UInt8(0)) { currentBit in
            while currentBit < 8 {
                let bitValue: UInt8 = 1 << currentBit
                currentBit += 1
                
                if rawValue & bitValue != 0 {
                    switch bitValue {
                    case 1 << 0: return .left
                    case 1 << 1: return .right
                    case 1 << 2: return .middle
                    case 1 << 3: return .other1
                    case 1 << 4: return .other2
                    default: break
                    }
                }
            }
            return nil
        }
    }
}

enum ToolEventType {
    /// Mouse button pressed this frame
    case pointerDown
    /// Mouse button moved this frame
    case pointerMove
    /// Mouse released this frame
    ///
    case pointerUp
    
    /// Movement exceeded threshold after button is already down
    case dragStart
    /// Continues while dragging
    case dragMove
    /// Button released while in drag state
    case dragEnd
    
    case dragCancel

    case click
    case doubleClick
    case tripleClick


    case hoverStart
//    case hoverMove // Not triggered, use pointerMove
    case hoverEnd

    case modifierChange
    
//    case contextMenu
    
    case scroll
}

/// Structure encapsulating information about a canvas tool event.
struct ToolEvent: CustomDebugStringConvertible {
    let type: ToolEventType
    
    let screenPos: ImVec2
    let delta: ImVec2

    /// Which button(s) are down
    let buttonsDown: MouseButtonMask
    let modifiers: KeyModifiers

    /// Which button(s) triggered this event
    let triggerButton: MouseButton?
    let scrollDelta: ImVec2

    var debugDescription: String {
        var desc = "\(type) P:\(screenPos) ∆:\(delta) B:\(buttonsDown) M:\(modifiers) T:\(triggerButton, default:"-")"
        return desc
    }
    
    struct Body {
        let screenPos: ImVec2
        let delta: ImVec2
        let buttonsDown: MouseButtonMask
        let modifiers: KeyModifiers
    }
    
    init(_ type: ToolEventType,
         screenPos: ImVec2 = ImVec2(),
         delta: ImVec2 = ImVec2(),
         buttonsDown: MouseButtonMask = .none,
         modifiers: KeyModifiers = .none,
         triggerButton: MouseButton? = nil,
         scrollDelta: ImVec2 = ImVec2())
    {
        self.type = type
        self.screenPos = screenPos
        self.delta = delta
        self.buttonsDown = buttonsDown
        self.modifiers = modifiers
        self.triggerButton = triggerButton
        self.scrollDelta = scrollDelta
    }
    
    init(_ type: ToolEventType,
         body: Body,
         triggerButton: MouseButton? = nil,
         scrollDelta: ImVec2 = ImVec2())
    {
        self.type = type
        self.screenPos = body.screenPos
        self.delta = body.delta
        self.buttonsDown = body.buttonsDown
        self.modifiers = body.modifiers
        self.triggerButton = triggerButton
        self.scrollDelta = scrollDelta
    }
}
