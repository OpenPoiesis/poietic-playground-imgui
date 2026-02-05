//
//  App+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import CIimgui

struct ShortcutAction {
    let name: String
    let key: ImGuiKeyChord
    let flags: ImGuiInputFlags
    init(_ name: String, key: ImGuiKey, flags: ImGuiInputFlags = 0) {
        self.init(name, key: ImGuiKeyChord(key.rawValue), flags: flags)
    }
    init(_ name: String, key: ImGuiKeyChord, flags: ImGuiInputFlags = 0) {
        self.name = name
        self.key = key
        self.flags = ImGuiInputFlags(flags | Int32(ImGuiInputFlags_RouteGlobal.rawValue))
    }
}

let GlobalShortcuts: [ShortcutAction] = [
    // Edit
    ShortcutAction("cut", key: ImGuiMod_Ctrl | ImGuiKey_X),
    ShortcutAction("copy", key: ImGuiMod_Ctrl | ImGuiKey_C),
    ShortcutAction("paste", key: ImGuiMod_Ctrl | ImGuiKey_V),
    ShortcutAction("undo", key: ImGuiMod_Ctrl | ImGuiKey_Z),
    ShortcutAction("redo", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Z),

    // File
    ShortcutAction("open", key: ImGuiMod_Ctrl | ImGuiKey_O),
    ShortcutAction("save", key: ImGuiMod_Ctrl | ImGuiKey_S),
    ShortcutAction("save_as", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_S),
    
    // Toolds
    ShortcutAction("selection_tool", key: ImGuiKey_1),
    ShortcutAction("placement_tool", key: ImGuiKey_2),
    ShortcutAction("connect_tool", key: ImGuiKey_3),
    ShortcutAction("pan_tool", key: ImGuiKey_Space),
]


extension Application {
    func globalShortcut() -> String? {
        for shortcut in GlobalShortcuts {
            if ImGui.Shortcut(shortcut.key, shortcut.flags) {
                return shortcut.name
            }
        }
        return nil
    }

    func processGlobalShortcuts() {
        guard let shortcut = globalShortcut() else { return }
        
        switch shortcut {
        case "selection_tool": toolBar.changeTool("selection")
        case "placement_tool": toolBar.changeTool("placement")
        case "connect_tool": toolBar.changeTool("connect")
        case "pan_tool": toolBar.changeTool("pan")
        default:
            print("Unhandled global shortcut: ", shortcut)
        }
    }
}
