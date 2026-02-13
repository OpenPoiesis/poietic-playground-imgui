//
//  Application+mainMenu.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
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
            
            // File menu
            if ImGui.BeginMenu("File") {
                if ImGui.MenuItem("New", "Cmd+N") {
                }
                if ImGui.MenuItem("Open", "Cmd+O") {
                    self.alert(title: "Info", message: "Not yet")
                }
                
                ImGui.Separator()
                
                if ImGui.MenuItem("Save", "Cmd+S") {
                }
                if ImGui.MenuItem("Save As...", "Cmd+Shift+S") {
                }
                
                ImGui.Separator()

                if ImGui.MenuItem("Export SVG...", "Cmd+Shift+S") {
                }

                if ImGui.MenuItem("Quit", "Cmd+Q") {
                    handleAction("quit")
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
                if ImGui.MenuItem("Show Inspector", nil, &inspector.isVisible) {
                    inspector.isVisible = !inspector.isVisible
                }
                if ImGui.MenuItem("Show Toolbar", nil) {
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
    
    func canUndo() -> Bool { session?.design.canUndo ?? false }
    func canRedo() -> Bool { session?.design.canRedo ?? false }
    func hasSelection() -> Bool { (session?.selection).map { !$0.isEmpty } ?? false }

}
