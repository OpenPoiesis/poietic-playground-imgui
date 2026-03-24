//
//  AboutPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 19/02/2026.
//

import CIimgui

let PlaygroundProjectHomeURL = "https://github.com/OpenPoiesis/poietic-playground-imgui"
let PlaygroundProjectIssuesURL = "https://github.com/OpenPoiesis/poietic-playground-imgui/issues"
let ContactEmailURL = "mailto:stefan@agentfarms.net"

let AcknowledgementList: [(String, String, String)] = [
    ("ImGUI", "https://github.com/ocornut/imgui", "Graphical user interface library"),
    ("SDL", "https://libsdl.org", "Simple DirectMedia Layer, a cross-platform development library"),
    ("Cairo", "https://cairographics.org", "2D graphics library"),
    ("ImGuiFD", "https://github.com/Julianiolo/ImGuiFD", "Dear ImGui based File Dialog"),
    ("stb_image", "https://github.com/Angluca/stb", "Image loading from single-file public domain (or MIT licensed) libraries for C/C++"),
]

class AboutPanel: Panel {
    var isVisible: Bool = false
    func draw() {
        guard isVisible else { return }

        let style = ImGui.GetStyle().pointee
        let titleFontSize = style.FontSizeBase * 1.5
        
        // TODO: Use OpenPopup?
        ImGui.Begin("About", &isVisible, ImGuiWindowFlags_None
                    | ImGuiWindowFlags_AlwaysAutoResize)

        ImGui.PushFont(nil, titleFontSize)
        ImGui.TextUnformatted("Poietic Playground")
        ImGui.PopFont()
        ImGui.TextWrappedUnformatted("Prototype of a virtual laboratory for modelling and simulation.")
        ImGui.Spacing()
        ImGui.Separator()

        ImGui.TextUnformatted("Links:")
        ImGui.Indent()
        ImGui.Bullet()
        ImGui.TextLinkOpenURL("Project Home", PlaygroundProjectHomeURL)
        ImGui.Bullet()
        ImGui.TextLinkOpenURL("Report Issue", PlaygroundProjectIssuesURL)
        ImGui.Unindent()

        ImGui.TextUnformatted("Author:")
        ImGui.SameLine()
        ImGui.TextLinkOpenURL("Stefan Urbanek", ContactEmailURL)
        ImGui.Spacing()
        
        ImGui.Separator()
        drawAcknowledgements()

        if (ImGui.Button("Dismiss", ImVec2(0, 0))) {
            self.isVisible = false
        }
        ImGui.End()
    }
    
    func drawAcknowledgements() {
        if ImGui.CollapsingHeader("Acknowledgements", ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_None.rawValue)) {
            ImGui.TextWrappedUnformatted("The application depends on the following software")


            let tableFlags = ImGuiTableFlags_None
                                | ImGuiTableFlags_NoBordersInBody
            
            
            if ImGui.BeginTable("acknowledgements", 2, tableFlags, ImVec2()) {
                ImGui.TableSetupColumn("Dependency", 0)
                ImGui.TableSetupColumn("Description", 0)

                for (name, link, desc) in AcknowledgementList {
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    ImGui.TextLinkOpenURL(name, link)
                    ImGui.TableNextColumn()
                    ImGui.TextUnformatted(desc)
                }

                ImGui.EndTable()
            }
        }

    }
    
    func update(_ timeDelta: Double) {
        // Do nothing
    }
}
