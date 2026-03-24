//
//  FormulaInlineEditor.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//


import CIimgui
import PoieticCore
import Diagramming

class FormulaInlineEditor: InlineEditor {
    static let PopupID = "##formula_inline_editor"
    var worldPosition: Vector2D = .zero

    var currentEntity: RuntimeEntity?
    var currentObjectID: ObjectID?
    
    var formulaIcon: TextureHandle?
    var formulaBuffer: InputTextBuffer?

    private var grabFocus: Bool = false
    
    override func open(for entity: RuntimeEntity) -> Bool {
        guard let object = entity.designObject,
              object.type.hasTrait(.Formula),
              let block: DiagramBlock = entity.component()
        else { return false }

        self.currentEntity = entity
        self.currentObjectID = object.objectID
        self.grabFocus = true
        
        self.worldPosition = block.labelAnchorPosition
        
        let text = object["formula"] ?? ""
        self.formulaBuffer = InputTextBuffer(text)
        
        let style = InterfaceStyle.current
        self.formulaIcon = style.texture(forIcon: .formula)
        
        return true
    }
    
    override func draw() -> Bool {
        guard currentObjectID != nil,
              let currentEntity,
              let block: DiagramBlock = currentEntity.component(),
              let formulaBuffer,
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

            if let formulaIcon {
                ImGui.Image(formulaIcon.imTextureRef, ImVec2(20, 20), ImVec2(0,0), ImVec2(1,1))
                ImGui.SameLine()
            }
            if grabFocus {
                ImGui.SetKeyboardFocusHere()
            }
            
            let inputFlags: ImGuiInputTextFlags =
                                ImGuiInputTextFlags_EnterReturnsTrue
                                | ImGuiInputTextFlags_AutoSelectAll
            
            let enterPressed = ImGui.InputText("##formula", buffer: formulaBuffer, flags: inputFlags)
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
        self.formulaBuffer = nil
    }

    func cancel() {
        // Nothing (for now)
    }

    func accept() {
        guard let formulaBuffer,
              let document,
              let currentObjectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        guard trans.contains(currentObjectID) else { return }
        
        let object = trans.mutate(currentObjectID)
        
        object["formula"] = Variant(formulaBuffer.string)
    }
}
