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
    
    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        case .scroll: return self.scroll(event)  // ← Add this
        default: return .pass
        }
    }
    
    func dragStart(_ event: ToolEvent) -> EngagementResult {
        guard event.triggerButton == .left else { return .pass }
        guard let canvas else { return .pass }

        self.startViewOffset = canvas.viewOffset
        self.previousScreenPos = event.screenPos
        self.state = .panning
        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }

    func dragMove(_ event: ToolEvent) -> EngagementResult {
        guard state == .panning else { return .pass }
        guard let canvas else { return .pass }

        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) * Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)
        
        self.previousScreenPos = event.screenPos

        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }
    
    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        guard state == .panning else { return .pass }
        guard let canvas else { return .pass }

        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) * Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)

        state = .idle
        cursor = ImGuiMouseCursor_Arrow
        return .consumed
    }
    
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        cursor = ImGuiMouseCursor_Arrow
        state = .idle
        return .consumed
    }
    
    func scroll(_ event: ToolEvent) -> EngagementResult {
        guard let canvas else { return .pass }
        
        // Get scroll delta (typically event.scroll.y for vertical scroll)
        let scrollDelta = Double(event.scrollDelta.y)
        
        // Define zoom sensitivity (adjust to taste)
        let zoomSensitivity = 0.1
        let minZoom = 0.1
        let maxZoom = 10.0
        
        // Calculate new zoom level
        // Positive scroll = zoom in, negative = zoom out
        let zoomFactor = 1.0 + (scrollDelta * zoomSensitivity)
        let newZoom = max(min((canvas.zoomLevel * zoomFactor), maxZoom), minZoom)
        
        // Optional: Zoom towards mouse position (like most design tools)
        let mouseScreenPos = event.screenPos
        let mouseWorldPosOld: Vector2D = canvas.screenToWorld(mouseScreenPos)
        
        // Update zoom
        canvas.setView(offset: canvas.viewOffset, zoom: newZoom)
        
        // Adjust offset so we zoom towards the mouse position
        let mouseWorldPosNew: Vector2D = canvas.screenToWorld(mouseScreenPos)
        let worldDelta = mouseWorldPosOld - mouseWorldPosNew
        canvas.setView(offset: canvas.viewOffset + worldDelta, zoom: newZoom)
        
        return .consumed
    }

//    // Alternative simpler version (zoom towards center):
//    func scrollSimple(_ event: ToolEvent) -> EngagementResult {
//        guard let canvas else { return .pass }
//        
//        let scrollDelta = event.scroll.y
//        let zoomSensitivity: Float = 0.1
//        let minZoom: Float = 0.1
//        let maxZoom: Float = 10.0
//        
//        let zoomFactor = 1.0 + (scrollDelta * zoomSensitivity)
//        let newZoom = (canvas.zoomLevel * zoomFactor).clamped(to: minZoom...maxZoom)
//        
//        canvas.setView(offset: canvas.viewOffset, zoom: newZoom)
//        
//        return .consumed
//    }

}

