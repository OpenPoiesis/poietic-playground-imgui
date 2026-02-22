//
//  ToolBar.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui

// TODO: Use CanvasTool.Type or enum
let ApplicationTools = ["selection", "placement", "connect", "pan"]

@MainActor
class ToolBar: @MainActor Panel {
    var isVisible: Bool = true
    
    internal weak var app: Application? = nil
    var previousTool: CanvasTool? = nil
    var currentTool: CanvasTool? = nil
    var tools: [CanvasTool] { app?.canvasTools ?? [] }
    
    init() {
        self.currentTool = nil
    }
    func bind(_ application: Application) {
        self.app = application
    }
    
    @discardableResult
    func setTool(_ name: String) -> Bool {
        let tool = tools.first { $0.name == name }
        guard let tool else { return false }
        self.setTool(tool)
        return true
    }
    
    func setTool(_ tool: CanvasTool) {
        if let currentTool {
            currentTool.deactivate()
        }
        
        previousTool = currentTool
        currentTool = tool
                
        tool.activate()

        print("Tool: \(tool.name)")
    }
    
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        let style = InterfaceStyle.current
        let manager = ResourceManager.shared
        
        let buttonSize = ImVec2(32, 32)
        ImGui.Begin("Tools", &isVisible, ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse)
        
        for (index, tool) in tools.enumerated() {
            let isActive = (currentTool === tool)
            
            if isActive {
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Button.rawValue), ImVec4(0.7, 0.7, 0.7, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonHovered.rawValue), ImVec4(0.9, 0.9, 0.9, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonActive.rawValue), ImVec4(0.6, 0.6, 0.1, 1.0))
            }
            
            ImGui.PushID(Int32(index))

            let texture = style.texture(forIcon: tool.iconKey)
            let ref = ImTextureRef(texture.textureID)
            if ImGui.ImageButton("##\(tool.name)", ref, buttonSize, ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0), ImVec4(1, 1, 1, 1)) {
                if currentTool !== tool {
                    setTool(tool)
                }
            }
            ImGui.PopID()
            
            if ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue)) {
                ImGui.BeginTooltip()
                ImGui.TextUnformatted(tool.name)
                ImGui.EndTooltip()
            }
            
            if isActive {
                ImGui.PopStyleColor(3)
            }
            
            if index < tools.count - 1 {
                ImGui.Spacing()
            }
        }
        
        if let currentTool, currentTool.hasObjectPalette {
            drawObjectPalette(currentTool)
        }
        
        ImGui.End()
    }
    
    func drawObjectPalette(_ tool: CanvasTool) {
        let paletteSpacing: Float = 0.0
        let toolbarPos = ImGui.GetWindowPos()
        let toolbarSize = ImGui.GetWindowSize()
        let palettePos = ImVec2(toolbarPos.x, toolbarPos.y + toolbarSize.y + paletteSpacing)

        ImGui.SetNextWindowPos(palettePos, 0, ImVec2())
        ImGui.Begin("##object-palette", nil,
                    ImGuiWindowFlags_AlwaysAutoResize
                    | ImGuiWindowFlags_NoScrollbar
                    | ImGuiWindowFlags_NoCollapse
                    | ImGuiWindowFlags_NoTitleBar
                    | ImGuiWindowFlags_NoSavedSettings)

        tool.drawPalette()
        ImGui.End()
    }
    
    /// Placeholder method for getting tool icons
    /// - Parameter tool: Name of the tool
    /// - Returns: Placeholder image data (will be implemented later)
    private func getToolIcon(_ tool: String) -> UnsafeMutableRawPointer? {
        // TODO: Implement actual icon loading
        // For now, return nil or placeholder
        return nil
        
        // When implementing, you might use something like:
        // - Load image from resources
        // - Convert to ImTextureID
        // - Return as UnsafeMutableRawPointer
    }

}
