//
//  Application+mainMenu.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import Foundation
import CIimgui

struct KeyModifier: OptionSet {
    let rawValue: UInt8
    static let cmd: KeyModifier = KeyModifier(rawValue: 1 << 0)
    static let shift: KeyModifier = KeyModifier(rawValue: 1 << 1)
    static let alt: KeyModifier = KeyModifier(rawValue: 1 << 2)
}
struct Menu {
    let label: String
    let items: [MenuItem]
}

struct MenuItem {
    let label: String
    let key: ImGuiKey
//    let modifier: KeyModifier
    let action: (() -> Void)
    
    init(_ label: String, key: ImGuiKey = ImGuiKey_None, action: @escaping (() -> Void)) {
        self.label = label
        self.key = key
        self.action = action
    }
}

extension Application {
    func mainMenu() {
        // In your main rendering loop, typically after ImGui.NewFrame()
        if ImGui.BeginMainMenuBar() {
            
            if ImGui.BeginMenu("Playground") {
                if ImGui.MenuItem("About", nil) {
                    aboutPanel.isVisible = true
                }
                if ImGui.MenuItem("Settings", "Cmd+,", &settingsPanel.isVisible) {
                    // Nothing
                }
                ImGui.Separator()
                if ImGui.MenuItem("Quit", "Cmd+Q") {
                    handleAction("quit")
                }
                ImGui.EndMenu()
            }
            // File menu
            if ImGui.BeginMenu("Design") {
                if ImGui.MenuItem("New", "Cmd+N") {
                    handleAction("new")
                }
                if ImGui.MenuItem("Open", "Cmd+O") {
                    filePicker.open(mode: .open, filter: "*." + Document.FileExtension) { path in
                        let url = URL(fileURLWithPath: path)
                        let command = OpenDesignCommand(url: url)
                        self.document?.queueCommand(command)
                    }
                }
                
                ImGui.Separator()
                
                if ImGui.MenuItem("Save", "Cmd+S") {
                    // TODO: Move to Application.save(...)
                    if let url = document?.designURL {
                        let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                        self.document?.queueCommand(command)
                    }
                    else {
                        filePicker.open(mode: .save, filter: "*." + Document.FileExtension) { path in
                            let url = URL(fileURLWithPath: path)
                            let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                            self.document?.queueCommand(command)
                        }
                    }
                }
                
                if ImGui.MenuItem("Save As...", "Cmd+Shift+S") {
                    filePicker.open(mode: .save, filter: "*." + Document.FileExtension) { path in
                        let url = URL(fileURLWithPath: path)
                        let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
                        self.document?.queueCommand(command)
                    }
                }
                
                ImGui.Separator()

                if ImGui.MenuItem("Export SVG...", "Cmd+Shift+S") {
                }

                
                ImGui.EndMenu()
            }
            
            // Edit menu
            if ImGui.BeginMenu("Edit") {
                if ImGui.MenuItem("Undo", "Cmd+Z", false, canUndo()) {
                    handleAction("undo")
                }
                if ImGui.MenuItem("Redo", "Cmd+Y", false, canRedo()) {
                    handleAction("redo")
                }
                
                ImGui.Separator()
                
                if ImGui.MenuItem("Cut", "Cmd+X", false, hasSelection()) {
                    handleAction("cut")
                }
                if ImGui.MenuItem("Copy", "Cmd+C", false, hasSelection()) {
                    handleAction("copy")
                }
                if ImGui.MenuItem("Paste", "Cmd+V") {
                    handleAction("paste")
                }
                if ImGui.MenuItem("Delete", "Delete") {
                    handleAction("delete")
                }
                ImGui.Separator()
                if ImGui.MenuItem("Select All", "Cmd+A") {
                    handleAction("select_all")
                }

               ImGui.EndMenu()
            }
            
            // View menu
            if ImGui.BeginMenu("View") {
                if ImGui.MenuItem("Show Value Indicators", nil) {
                }
                if ImGui.MenuItem("Show Inspector", "Cmd+I", &inspector.isVisible) {
                    // Nothing
                }
                if ImGui.MenuItem("Show Issues", nil, &issuesPanel.isVisible) {
                    // Nothing
                }
                ImGui.Separator()
                if ImGui.MenuItem("Show Toolbar", nil, &toolBar.isVisible) {
                    // Nothing
                }
                ImGui.Separator()
                if ImGui.MenuItem("Show Metrics", nil, &showMetrics) {
                    ImGui.ShowMetricsWindow()
                }
                
                ImGui.EndMenu()
            }
            
            // Window menu (for window management)
            if ImGui.BeginMenu("Simulation") {
                if ImGui.MenuItem("Run") {
                }
                ImGui.EndMenu()
            }
            
            // Help menu
            if ImGui.BeginMenu("Help") {
                if ImGui.MenuItem("Documentation") {
                }
                ImGui.EndMenu()
            }
            
            ImGui.EndMainMenuBar()
        }
    }
    
    func canUndo() -> Bool { document?.design.canUndo ?? false }
    func canRedo() -> Bool { document?.design.canRedo ?? false }
    func hasSelection() -> Bool { (document?.selection).map { !$0.isEmpty } ?? false }

}
