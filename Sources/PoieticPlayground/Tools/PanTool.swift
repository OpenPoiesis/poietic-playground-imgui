//
//  PanTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming

class PanTool: CanvasTool {
    enum State {
        case idle
        case panning
    }

    override var name: String { "pan"}
    override var iconKey: IconKey { .hand }
    
    var cursor: ImGuiMouseCursor_ = ImGuiMouseCursor_Arrow

    var startViewOffset: Vector2D = .zero
    var previousScreenPos: ImVec2 = ImVec2()
    
    var state: State = .idle
    
    override func handleEvent(_ event: ToolEvent) {
        switch event.type {
        case .dragStart: self.dragStart(event)
        case .dragMove: self.dragMove(event)
        case .dragEnd: self.dragEnd(event)
        case .dragCancel: self.dragCancel(event)
        default: break
        }
    }
    
    func dragStart(_ event: ToolEvent) {
        guard event.triggerButton == .left else { return }
        guard let canvas else { return }

        self.startViewOffset = canvas.viewOffset
        self.previousScreenPos = event.screenPos
        self.state = .panning
        self.cursor = ImGuiMouseCursor_Hand
    }

    func dragMove(_ event: ToolEvent) {
        guard state == .panning else { return }
        guard let canvas else { return }

        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) * Double(canvas.zoomLevel)
        canvas.viewOffset -= canvasOffset
        
        self.previousScreenPos = event.screenPos

        self.cursor = ImGuiMouseCursor_Hand
    }
    
    func dragEnd(_ event: ToolEvent) {
        guard state == .panning else { return }
        guard let canvas else { return }

        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) * Double(canvas.zoomLevel)
        canvas.viewOffset -= canvasOffset

        state = .idle
        cursor = ImGuiMouseCursor_Arrow

    }
    func dragCancel(_ event: ToolEvent) {
        cursor = ImGuiMouseCursor_Arrow
        state = .idle
    }
}

