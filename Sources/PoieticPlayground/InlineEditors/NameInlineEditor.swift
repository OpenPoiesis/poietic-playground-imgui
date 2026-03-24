//
//  NameInlineEditor.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming


class NameInlineEditor: InlineEditor {
    static let PopupID = "##name_inline_editor"
    var worldPosition: Vector2D = .zero

    var currentEntity: RuntimeEntity?
    var currentObjectID: ObjectID?
    
    var nameBuffer: InputTextBuffer?


    private var grabFocus: Bool = false
    
    override func open(for entity: RuntimeEntity) -> Bool {
        guard let object = entity.designObject,
              object.type.hasTrait(.Name),
              let block: DiagramBlock = entity.component()
        else { return false }

        self.currentEntity = entity
        self.currentObjectID = object.objectID
        self.grabFocus = true
        self.document = document
        
        self.worldPosition = block.labelAnchorPosition
        
        let name = object.name ?? ""
        self.nameBuffer = InputTextBuffer(name)
        return true
    }
    
    override func draw() -> Bool {
        guard currentObjectID != nil,
              let currentEntity,
              let block: DiagramBlock = currentEntity.component(),
              let nameBuffer,
              let canvas
        else { return false } // Cancelled
        
        let screenPos = canvas.worldToScreen(worldPosition)
        
        ImGui.SetNextWindowPos(screenPos, 0, ImVec2(0.5, 0))
        
        let flags: ImGuiWindowFlags =
                        ImGuiWindowFlags_NoTitleBar
                        | ImGuiWindowFlags_NoResize
                        | ImGuiWindowFlags_NoMove
                        | ImGuiWindowFlags_AlwaysAutoResize
        
        if !ImGui.IsPopupOpen(Self.PopupID) {
            ImGui.OpenPopup(Self.PopupID)
        }

        if ImGui.BeginPopup(Self.PopupID, flags) {
            defer {
                ImGui.EndPopup()
                grabFocus = false
            }
            
            if grabFocus {
                ImGui.SetKeyboardFocusHere()
            }
            
            let inputFlags: ImGuiInputTextFlags =
                                ImGuiInputTextFlags_EnterReturnsTrue
                                | ImGuiInputTextFlags_AutoSelectAll
            
            let enterPressed = ImGui.InputText("##name", buffer: nameBuffer, flags: inputFlags)
            let isDeactivated = !ImGui.IsItemActive() && !grabFocus
            let escapePressed = ImGui.IsKeyPressed(ImGuiKey(ImGuiKey_Escape.rawValue), false)
            
            if escapePressed {
                cancel()
                ImGui.CloseCurrentPopup()
                return true
            }
            else if enterPressed || isDeactivated {
                accept()
                ImGui.CloseCurrentPopup()
                return true
            }
        }

        return false
    }

    override func close() {
        self.currentEntity = nil
        self.currentObjectID = nil
        self.nameBuffer = nil
    }

    func cancel() {
        // Nothing (for now)
    }

    func accept() {
        guard let nameBuffer,
              let document,
              let currentObjectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        guard trans.contains(currentObjectID) else { return }
        
        let object = trans.mutate(currentObjectID)
        
        object["name"] = Variant(nameBuffer.string)
    }
}
