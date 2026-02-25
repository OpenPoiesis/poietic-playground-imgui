//
//  IssuesPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import CIimgui
import PoieticCore

class IssuesPanel: Panel {
    var isVisible: Bool = false
    var session: Session?
    
    func bind(_ session: Session) {
        self.session = session
    }

    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.Begin("Issues")

        let tableFlags = ImGuiTableFlags_RowBg
                         | ImGuiTableFlags_BordersH
                         | ImGuiTableFlags_Resizable
                         | ImGuiTableFlags_SizingFixedFit
        
        
        ImGui.BeginTable("issues", 4, tableFlags, ImVec2())
//        ImGui.TableNextRow()
        ImGui.TableSetupColumn("ID", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthFixed)
        ImGui.TableSetupColumn("Name")
        ImGui.TableSetupColumn("Type")
        ImGui.TableSetupColumn("Issue", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthStretch)
        ImGui.TableHeadersRow()

        if let issues = session?.world.issues {
            drawIssues(issues)
        }


        ImGui.EndTable()

        ImGui.End()
    }
    func drawIssues(_ issues: [ObjectID: [Issue]]) {
        guard let frame = session?.world.frame else { return }
        
        for (objectID, objectIssues) in issues {
            for issue in objectIssues {
                guard let object = frame[objectID] else { continue }
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextUnformatted(objectID.stringValue)

                ImGui.TableNextColumn()
                ImGui.TextUnformatted(object.name ?? "(no name)")

                ImGui.TableNextColumn()
                ImGui.TextUnformatted(object.type.name)

                ImGui.TableNextColumn()
                ImGui.TextUnformatted(issue.message)
            }
        }
    }
}
