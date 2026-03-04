//
//  IssuesPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import CIimgui
import PoieticCore

class IssuesPanel: Panel {
    var isVisible: Bool = true
    var session: Session?
//    var expandedObjects: Set<ObjectID> = []

    var selectedObject: ObjectSnapshot? = nil
    var selectedIssueIndex: Int? = nil

    func bind(_ session: Session) {
        self.session = session
    }

    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.Begin("Issues", &isVisible, ImGuiWindowFlags_None
                                        | ImGuiWindowFlags_AlwaysAutoResize)

        let tableFlags = ImGuiTableFlags_RowBg
                         | ImGuiTableFlags_BordersV
                         | ImGuiTableFlags_BordersOuterH
                         | ImGuiTableFlags_Resizable
                         | ImGuiTableFlags_SizingFixedFit
                         | ImGuiTableFlags_NoBordersInBody
        
        
        if ImGui.BeginTable("issues", 2, tableFlags, ImVec2()) {
            
            ImGui.TableSetupColumn("Message", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthStretch)
//            ImGui.TableSetupColumn("Actions", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthFixed)
//            ImGui.TableHeadersRow()

            if let issues = session?.world.issues {
                drawIssues(issues)
            }
            
            ImGui.EndTable()
        }
        
        // Hints for selected issue (if any)
        if let issues = session?.world.issues,
           let selectedObject,
           let selectedIssueIndex,
           let objectIssues = issues[selectedObject.objectID],
           selectedIssueIndex < objectIssues.count
        {
            let issue = objectIssues[selectedIssueIndex]
            drawHints(issue: issue, for: selectedObject)
        }

        ImGui.End()
    }
    func drawIssues(_ issues: [ObjectID: [Issue]]) {
        guard let frame = session?.world.frame else { return }
        for (objectID, objectIssues) in issues {
            guard let object = frame[objectID] else { continue }
            drawObjectNode(object, issues: objectIssues)
        }
        
    }
    
    func drawObjectNode(_ object: ObjectSnapshot, issues: [Issue]) {
        let name = object.name ?? "(unnamed object)"
        let type = object.type.label
        let idString = object.objectID.stringValue
        let nodeLabel = "\(name) (\(type)) \(issues.count) issue(s)###\(idString)"

        let flags = ImGuiTreeNodeFlags_DefaultOpen.rawValue
                    | ImGuiTreeNodeFlags_LabelSpanAllColumns.rawValue

        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        let open = ImGui.TreeNodeEx(nodeLabel, ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_SpanAllColumns.rawValue | flags))

        if open {
            for (i, issue) in issues.enumerated() {
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                let message = issue.message // + "###" + String(i)
                ImGui.TreeNodeEx(message, ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_SpanAllColumns.rawValue
                                                             | ImGuiTreeNodeFlags_Bullet.rawValue
                                                             | ImGuiTreeNodeFlags_Leaf.rawValue
                                                             | flags))
                if ImGui.IsItemClicked(0) {  // 0 = left mouse button
                    // Update selection
                    selectedObject = object
                    selectedIssueIndex = i
                    if let session {
                        session.changeSelection(.replaceAllWithOne(object.objectID))
                        session.queueCommand(CenterCanvasOnObjectCommand(object.objectID))
                    }
                }
//                ImGui.TableNextColumn()
//                ImGui.TextUnformatted("(no action)")
                ImGui.TreePop()
            }
            
            ImGui.TreePop()

        }
    }
    func drawHints(issue: Issue, for object: ObjectSnapshot) {
        if ImGui.CollapsingHeader("Hints", ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_None.rawValue)) {
            
            let name = object.name ?? "unnamed object"
            ImGui.TextUnformatted("Hints for \(name) (\(object.type.label))")
            ImGui.TextUnformatted("Issue: \(issue.message)")
            for hint in issue.hints {
                ImGui.Bullet()
                ImGui.TextWrappedUnformatted(hint)
            }
        }
    }
}
