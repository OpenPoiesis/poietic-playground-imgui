//
//  AboutPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 19/02/2026.
//

import CIimgui

let PlaygroundProjectHomeURL = "https://github.com/OpenPoiesis/poietic-playground-imgui"
let PlaygroundProjectIssuesURL = "https://github.com/OpenPoiesis/poietic-playground-imgui/issues"
let ContactEmailURL = "mailto:stefan.urbanek@gmail.com"

class AboutPanel: Panel {
    var isVisible: Bool = false
    func draw() {
        guard isVisible else { return }

        let style = ImGui.GetStyle().pointee
        let titleFontSize = style.FontSizeBase * 1.5
        
        // TODO: Use OpenPopup?
        ImGui.Begin("About", &isVisible)

        ImGui.PushFont(nil, titleFontSize)
        ImGui.TextUnformatted("Poietic Playground")
        ImGui.PopFont()
        ImGui.TextWrappedUnformatted("Prototype of a virtual laboratory for modelling and simulation.")
        ImGui.Spacing()
        ImGui.Separator()
        ImGui.TextUnformatted("Author:")
        ImGui.SameLine()
        ImGui.TextLinkOpenURL("Stefan Urbanek", ContactEmailURL)
        ImGui.Spacing()
        
        ImGui.TextUnformatted("Links:")
        ImGui.Bullet()
        ImGui.TextLinkOpenURL("Project Home", PlaygroundProjectHomeURL)
        ImGui.Bullet()
        ImGui.TextLinkOpenURL("Report Issue", PlaygroundProjectIssuesURL)
        ImGui.Separator()

        if (ImGui.Button("Dismiss", ImVec2(0, 0))) {
            self.isVisible = false
        }
        ImGui.End()
    }
    
    func update(_ timeDelta: Double) {
        // Do nothing
    }
}
