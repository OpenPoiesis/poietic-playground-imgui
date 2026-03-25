//
//  KeyboardShortcutsPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/03/2026.
//

import CIimgui

class KeyboardShortcutsPanel: Panel {
    var isVisible: Bool = false
    func draw() {
        guard isVisible else { return }

        // TODO: Use OpenPopup?
        ImGui.Begin("Keyboard Shortcuts",
                    &isVisible,
                    ImGuiWindowFlags_None
                    | ImGuiWindowFlags_AlwaysAutoResize)

        let tableFlags = ImGuiTableFlags_None
                            | ImGuiTableFlags_RowBg
            
            
        if ImGui.BeginTable("shortcuts", 2, tableFlags, ImVec2()) {
            ImGui.TableSetupColumn("Key", 0)
            ImGui.TableSetupColumn("Action", 0)
            ImGui.TableHeadersRow()

            for shortcut in GlobalShortcuts {
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextUnformatted(shortcut.keyLabel)
                ImGui.TableNextColumn()
                ImGui.TextUnformatted(shortcut.name)
            }

            ImGui.EndTable()
        }
        ImGui.End()

    }
    
    func update(_ timeDelta: Double) {
        // Do nothing
    }
}
