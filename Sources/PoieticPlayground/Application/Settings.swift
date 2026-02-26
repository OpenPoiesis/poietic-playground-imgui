//
//  Settings.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 19/02/2026.
//

import CIimgui

class SettingsPanel: Panel {
    weak var app: Application? = nil
    var isVisible: Bool = false
    var interfaceStyleSelection: Int32 = 0
    
    func bind(_ app: Application) {
        self.app = app
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.Begin("Settings", &isVisible, ImGuiWindowFlags_None | ImGuiWindowFlags_NoCollapse)
        drawInterfaceStyleSettings()
//        drawNotationSettings()
        ImGui.End()
    }
   
    func drawInterfaceStyleSettings() {
        ImGui.TextUnformatted("Interface Style")
        ImGui.SameLine()
        if ImGui.RadioButton("Dark", InterfaceStyle.current.scheme == .dark) {
            app?.setInterfaceColorScheme(.dark)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Light", InterfaceStyle.current.scheme == .light) {
            app?.setInterfaceColorScheme(.light)
        }

    }
    
    func drawNotationSettings() {
        ImGui.SeparatorText("Notation")
    }
    
    func setInterfaceColorScheme(_ scheme: InterfaceStyle.ColorScheme) {
        guard scheme != InterfaceStyle.current.scheme else { return }
        let style = InterfaceStyle(scheme: scheme)
        InterfaceStyle.current = style
    }

    func update(_ timeDelta: Double) {
    }
}
