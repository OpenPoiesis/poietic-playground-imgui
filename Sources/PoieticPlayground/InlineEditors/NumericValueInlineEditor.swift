//
//  NumericValueInlineEditor.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//


import CIimgui
import PoieticCore
import Diagramming

class NumericValueInlineEditor: InlineEditor {
    static let PopupID = "##numeric_value_inline_editor"
    var worldPosition: Vector2D = .zero

    var currentEntity: RuntimeEntity?
    var currentObjectID: ObjectID?
    
    var iconKey: IconKey
    var attributeName: String

    var icon: TextureHandle?
    var value: Double
    var initialValue: Double

    private var grabFocus: Bool = false
    
    init(attribute: String, iconKey: IconKey) {
        self.attributeName = attribute
        self.iconKey = iconKey
        self.value = 0
        self.initialValue = 0
    }
    
    override func open(for entity: RuntimeEntity) -> Bool {
        guard let object = entity.designObject,
              let attribute = object.type.attribute(self.attributeName),
              let block: DiagramBlock = entity.component()
        else { return false }

        self.currentEntity = entity
        self.currentObjectID = object.objectID
        self.grabFocus = true
        self.document = document
        
        self.worldPosition = block.labelAnchorPosition
        
        let defaultValue = (try? attribute.defaultValue?.doubleValue()) ?? 0
        self.value = object[attributeName] ?? defaultValue
        self.initialValue = self.value
        
        let style = InterfaceStyle.current
        self.icon = style.texture(forIcon: self.iconKey)
        
        return true
    }
    
    override func draw() -> Bool {
        guard currentObjectID != nil,
              let currentEntity,
              let block: DiagramBlock = currentEntity.component(),
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

            if let icon {
                ImGui.Image(icon.imTextureRef, ImVec2(20, 20), ImVec2(0,0), ImVec2(1,1))
                ImGui.SameLine()
            }
            if grabFocus {
                ImGui.SetKeyboardFocusHere()
            }
            
            let inputFlags: ImGuiInputTextFlags =
                                ImGuiInputTextFlags_None
                                | ImGuiInputTextFlags_AutoSelectAll
            
            let valueChanged = ImGui.InputDouble("##value", &self.value,
                                                 /* step:*/ 0.0,
                                                 /* step_fast:*/ 0.0,
                                                 /* format:*/ "%.4f",
                                                 /* flags:*/ inputFlags)

            let escapePressed = ImGui.IsKeyPressed(ImGuiKey(ImGuiKey_Escape.rawValue), false)
            
            if escapePressed {
                cancel()
                ImGui.CloseCurrentPopup()
                return true
            }
            else if ImGui.IsItemDeactivated() {
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
        self.value = 0
    }

    func cancel() {
        // Nothing (for now)
    }

    func accept() {
        guard value != initialValue,
              let document,
              let currentObjectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        guard trans.contains(currentObjectID) else { return }
        
        let object = trans.mutate(currentObjectID)
        
        object[attributeName] = Variant(self.value)
    }
}
