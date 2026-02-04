//
//  ToolBar.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui

let ApplicationTools = ["selection", "placement", "connect", "pan"]

class ToolBar {
    unowned var app: Application! = nil
    var currentTool: CanvasTool? = nil
    var tools: [CanvasTool] { app?.canvasTools ?? [] }
    
    init() {
        self.currentTool = nil
    }
    
    func draw() {
        // Start a new ImGui window for the toolbar
        ImGui.Begin("Tools", nil, ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse)
        
        // Set a fixed size for the toolbar
        ImGui.SetWindowSize(ImVec2(60, 300))
        
        // Add some vertical spacing
        ImGui.Spacing()
        
        // Draw buttons for each tool
        for (index, tool) in tools.enumerated() {
            let isActive = (currentTool === tool)
            
            // Get icon for the tool (will be implemented later)
            // Style active button differently
            if isActive {
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Button.rawValue), ImVec4(0.3, 0.5, 0.8, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonHovered.rawValue), ImVec4(0.4, 0.6, 0.9, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonActive.rawValue), ImVec4(0.2, 0.4, 0.7, 1.0))
            }
            
            // Draw button with fixed size
            ImGui.PushID(Int32(index))

            if let texture = self.app?.textures[tool.iconName] {
                let ref = ImTextureRef(texture.textureID)
                if ImGui.ImageButton("##\(tool.name)", ref, ImVec2(30, 30), ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0), ImVec4(1, 1, 1, 1)) {
                    if currentTool !== tool {
                        currentTool = tool
                        toolChanged(tool)
                    }
                }
            }
            else {
                if ImGui.Button("##\(tool)", ImVec2(40, 40)) {
                    if currentTool !== tool {
                        currentTool = tool
                        toolChanged(tool)
                    }
                }
            }
            ImGui.PopID()
            
            // Add tooltip
            if ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue)) {
                ImGui.BeginTooltip()
                ImGui.TextUnformatted(tool.name)
                ImGui.EndTooltip()
            }
            
            // Restore style for active button
            if isActive {
                ImGui.PopStyleColor(3)
            }
            
            // Add spacing between buttons
            ImGui.Spacing()
        }
        
        ImGui.End()
    }
    
    func toolChanged(_ tool: CanvasTool) {
        // Handle tool change (not yet).
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
