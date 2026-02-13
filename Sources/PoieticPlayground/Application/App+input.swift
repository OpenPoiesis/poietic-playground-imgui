//
//  App+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import CIimgui
import PoieticCore

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
    ShortcutAction("undo", key: ImGuiMod_Ctrl | ImGuiKey_Z),
    ShortcutAction("redo", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Z),

    ShortcutAction("cut", key: ImGuiMod_Ctrl | ImGuiKey_X),
    ShortcutAction("copy", key: ImGuiMod_Ctrl | ImGuiKey_C),
    ShortcutAction("paste", key: ImGuiMod_Ctrl | ImGuiKey_V),
    ShortcutAction("delete", key: ImGuiKey_Backspace),

    ShortcutAction("select_all", key: ImGuiMod_Ctrl | ImGuiKey_A),

    // File
    ShortcutAction("open", key: ImGuiMod_Ctrl | ImGuiKey_O),
    ShortcutAction("save", key: ImGuiMod_Ctrl | ImGuiKey_S),
    ShortcutAction("save_as", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_S),
    
    // Toolds
    ShortcutAction("switch_selection_tool", key: ImGuiKey_1),
    ShortcutAction("switch_placement_tool", key: ImGuiKey_2),
    ShortcutAction("switch_connect_tool", key: ImGuiKey_3),
    ShortcutAction("switch_pan_tool", key: ImGuiKey_Space),
]


extension Application {
    func globalShortcutAction() -> String? {
        for shortcut in GlobalShortcuts {
            if ImGui.Shortcut(shortcut.key, shortcut.flags) {
                return shortcut.name
            }
        }
        return nil
    }
    
    func handleAction(_ actionName: String) {
        switch actionName {
        // -- Tools --
        case "switch_selection_tool": toolBar.setTool("selection")
        case "switch_placement_tool": toolBar.setTool("placement")
        case "switch_connect_tool": toolBar.setTool("connect")
        case "switch_pan_tool":
            if let previousTool = toolBar.previousTool,
               toolBar.currentTool is PanTool
            {
                toolBar.setTool(previousTool)
            }
            else {
                toolBar.setTool("pan")
            }
        
        // -- Application --
        case "quit": self.quitRequested = true
        // -- Edit --
        case "undo": session?.queueCommand(UndoCommand())
        case "redo": session?.queueCommand(RedoCommand())
//        case "select_all": ???
        case "paste":
            session?.queueCommand(PasteFromPasteboardCommand())

        default:
            guard let session else { return }
            if !handleSelectionAction(actionName, session: session) {
                self.logError("Unhandled application action: " + actionName)
            }
        }
    }
    
    func handleSelectionAction(_ actionName: String, session: Session) -> Bool {
        let ids: [ObjectID] = Array(session.selection.ids)
        switch actionName {
        case "cut":
            session.queueCommand(CutToPasteboardCommand(ids))
        case "copy":
            session.queueCommand(CopyToPasteboardCommand(ids))
        case "delete":
            session.queueCommand(DeleteObjectsCommand(ids))

        default:
            return false
        }
        return true
    }
}
