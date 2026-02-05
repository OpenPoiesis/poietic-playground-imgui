//
//  Alert.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import CIimgui

class AlertPanel: Panel {
    var isVisible: Bool = false
    var title: String = "Alert"
    var message: String = "Probably nothing"
   
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.OpenPopup("##alert_panel")
        if ImGui.BeginPopupModal("##alert_panel"){
            ImGui.TextUnformatted(title)
            ImGui.Separator()
            ImGui.TextWrappedUnformatted(message);
            if (ImGui.Button("Dismiss", ImVec2(120, 0))) {
                ImGui.CloseCurrentPopup()
                self.isVisible = false
            }
            
            ImGui.EndPopup();
        }
    }
}
