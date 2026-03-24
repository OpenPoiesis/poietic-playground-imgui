//
//  App+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import CIimgui
import Foundation
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
    // Application
    ShortcutAction("settings", key: ImGuiMod_Ctrl | ImGuiKey_Comma),

    // Edit
    ShortcutAction("undo", key: ImGuiMod_Ctrl | ImGuiKey_Z),
    ShortcutAction("redo", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Z),

    ShortcutAction("cut", key: ImGuiMod_Ctrl | ImGuiKey_X),
    ShortcutAction("copy", key: ImGuiMod_Ctrl | ImGuiKey_C),
    ShortcutAction("paste", key: ImGuiMod_Ctrl | ImGuiKey_V),
    ShortcutAction("delete", key: ImGuiKey_Backspace),

    ShortcutAction("select_all", key: ImGuiMod_Ctrl | ImGuiKey_A),

    // File
    ShortcutAction("new", key: ImGuiMod_Ctrl | ImGuiKey_N),
    ShortcutAction("open", key: ImGuiMod_Ctrl | ImGuiKey_O),
    ShortcutAction("save", key: ImGuiMod_Ctrl | ImGuiKey_S),
    ShortcutAction("save_as", key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_S),
    
    // View
    ShortcutAction("toggle_inspector", key: ImGuiMod_Ctrl | ImGuiKey_I),
    ShortcutAction("toggle_issues_panel", key: ImGuiMod_Ctrl | ImGuiKey_5),
    ShortcutAction("reset_zoom", key: ImGuiMod_Ctrl | ImGuiKey_0),

    // Tools
    ShortcutAction("switch_selection_tool", key: ImGuiKey_1),
    ShortcutAction("switch_placement_tool", key: ImGuiKey_2),
    ShortcutAction("switch_connect_tool", key: ImGuiKey_3),
    ShortcutAction("switch_pan_tool", key: ImGuiKey_Space),
    
    // Inspector
    ShortcutAction("overview_inspector", key: ImGuiMod_Ctrl | ImGuiKey_1),
    ShortcutAction("properties_inspector", key: ImGuiMod_Ctrl | ImGuiKey_2),

    // Inline Editors
    ShortcutAction("name_inline_editor", key: ImGuiKey_Enter),
    ShortcutAction("secondary_inline_editor", key: ImGuiKey_Equal),
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
        case "settings": self.openSettings()
        case "quit": self.quitRequested = true
        // -- File --
        case "new": document?.queueCommand(NewDesignCommand())
        case "open":
            filePicker.open(mode: .open, filter: "*." + Document.FileExtension) { path in
                let url = URL(fileURLWithPath: path)
                let command = OpenDesignCommand(url: url)
                self.document?.queueCommand(command)
            }

        case "save":
            if let url = document?.designURL {
                let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                self.document?.queueCommand(command)
            }
            else {
                filePicker.open(mode: .save, filter: "*." + Document.FileExtension) { path in
                    let url = URL(fileURLWithPath: path)
                    let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                    self.document?.queueCommand(command)
                }
            }
        case "save_as":
            filePicker.open(mode: .save, filter: "*." + Document.FileExtension) { path in
                let url = URL(fileURLWithPath: path)
                let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                self.document?.queueCommand(command)
            }

        // -- Edit --
        case "undo": document?.queueCommand(UndoCommand())
        case "redo": document?.queueCommand(RedoCommand())
//        case "select_all": ???
        case "paste":
            document?.queueCommand(PasteFromPasteboardCommand())
        case "select_all":
            self.selectAll()

        // -- View ---
        case "toggle_inspector":
            self.inspector.isVisible = !self.inspector.isVisible
        case "toggle_issues_panel":
            self.issuesPanel.isVisible = !self.issuesPanel.isVisible
        case "reset_zoom":
            document?.queueCommand(ResetZoomCommand())

        // -- Inspector --
        case "overview_inspector":
            self.inspector.selectTab(.overview)
            self.inspector.isVisible = true
        case "properties_inspector":
            self.inspector.selectTab(.properties)
            self.inspector.isVisible = true

        case "name_inline_editor":
            self.canvas.openInlineEditorForSelection("name")
        case "secondary_inline_editor":
            self.canvas.openSecondaryInlineEditorForSelection()

        default:
            guard let document else { return }
            if !handleSelectionAction(actionName, document: document) {
                self.logError("Unhandled application action: " + actionName)
            }
        }
    }
    
    func handleSelectionAction(_ actionName: String, document: Document) -> Bool {
        let ids: [ObjectID] = Array(document.selection.ids)
        switch actionName {
        case "cut":
            document.queueCommand(CutToPasteboardCommand(ids))
        case "copy":
            document.queueCommand(CopyToPasteboardCommand(ids))
        case "delete":
            document.queueCommand(DeleteObjectsCommand(ids))

        default:
            return false
        }
        return true
    }
}
