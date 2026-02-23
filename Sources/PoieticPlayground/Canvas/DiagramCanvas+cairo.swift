//
//  DiagramCanvas+cairo.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import CIimgui

extension DiagramCanvas {
    func NEWdraw() {
        let viewport = ImGui.GetMainViewport()
        ImGui.SetNextWindowPos(viewport.pointee.WorkPos, ImGuiCond(ImGuiCond_Always.rawValue), ImVec2(0, 0))
        ImGui.SetNextWindowSize(viewport.pointee.WorkSize, ImGuiCond(ImGuiCond_Always.rawValue))

        ImGui.Begin("DiagramCanvas", nil,
            ImGuiWindowFlags_NoDecoration |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_NoNavFocus)
        
//        ImGui.Begin("Canvas Window")

        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        // Set a background colour
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ChildBg.rawValue), style.background.imIntValue)
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()

        canvasPos = ImGui.GetCursorScreenPos()
        canvasSize = ImGui.GetContentRegionAvail()
        
        // Used for processUnhandledInput(...)
        isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        )

        // Ensure all layers match canvas size
        let width = Int32(canvasSize.x)
        let height = Int32(canvasSize.y)
        layers.ensureSize(width: width, height: height)
        
        // Render dirty layers
        renderLayers()
        
        // Upload to GPU
        try! layers.uploadDirty()
        
        // Composite to screen
        compositeToScreen()
        
        ImGui.EndChild()
        ImGui.End()
    }
    
    func renderLayers() {
        if mainLayer.isDirty {
            // TODO: Handle exception
            try! mainLayer.render { context in
                drawToCairo(context)
            }
        }
    }
    
    func composeLayers() {
        let drawList = ImGui.GetWindowDrawList()

        for texture in layers.textures() {
            drawList?.pointee.AddImage(
                texture.imTextureRef,
                canvasPos,
                canvasPos + canvasSize,
                ImVec2(0, 0),
                ImVec2(1, 1),
                0xFFFFFFFF
            )
        }
    }
    private func compositeToScreen() {
        let drawList = ImGui.GetWindowDrawList()
        // Fallback if no textures
        guard !layers.textures().isEmpty else {
            drawTextureError()
            return
        }

        for texture in layers.textures() {
            drawList?.pointee.AddImage(
                texture.imTextureRef,
                canvasPos,
                canvasPos + canvasSize,
                ImVec2(0, 0),   // UV min
                ImVec2(1, 1),   // UV max
                0xFFFFFFFF      // White tint
            )
        }
        
    }
    
    private func drawTextureError() {
        let drawList = ImGui.GetWindowDrawList()
        let errorColor = Color.screenRed.withTransparency(0.3).imIntValue

        drawList?.pointee.AddRectFilled(canvasPos, canvasPos+canvasSize, errorColor)
        
        let errorText = "Texture Upload Failed"
        let textSize = ImGui.CalcTextSize(errorText)
        let textPos = ImVec2(
            canvasPos.x + (canvasSize.x - textSize.x) / 2,
            canvasPos.y + (canvasSize.y - textSize.y) / 2
        )
        drawList?.pointee.AddText(textPos, Color.white.imIntValue, errorText, nil)
    }

}
