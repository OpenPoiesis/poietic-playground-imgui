//
//  DiagramCanvas+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//
import CIimgui
import Diagramming

extension DiagramCanvas {
    // MARK: - Input Handling
    func handleInput(_ io: ImGuiIO) -> Bool {
        guard let app else { fatalError("No app")}
        guard let currentTool = app.currentTool else { return false }
        
        let events = translateImGuiToToolEvents(io)
        for event in events {
            currentTool.handleEvent(event)
        }
        
        return true
    }

    func translateImGuiToToolEvents(_ io: ImGuiIO) -> [ToolEvent] {
        var events: [ToolEvent] = []
        
        // Check if mouse is in viewport
        let isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        );

        // Current state
        let mousePos = io.MousePos
        let mouseDelta = io.MouseDelta
        let buttonsDown = MouseButtonMask(io.MouseDown)
        let currentModifiers = KeyModifiers(io.KeyMods)
        
        let eventBody = ToolEvent.Body(
            screenPos: mousePos,
            delta: mouseDelta,
            buttonsDown: .none,
            modifiers: currentModifiers
        )

        // # Viewport check and Hover Events
        //
        // Case 1: Mouse left viewport while idle - bail completely
        if !isMouseInViewport && (inputState.pointerState == .idle) {
            if inputState.wasMouseInViewport {
                let event = ToolEvent(.hoverEnd, body: eventBody)
                events.append(event)
            }
            inputState.wasMouseInViewport = false
            return events
        }

        // Case 2: Mouse left viewport during operation - continue but emit HoverEnd
        if !isMouseInViewport && inputState.wasMouseInViewport {
            let event = ToolEvent(.hoverEnd, body: eventBody)
            events.append(event)
            inputState.wasMouseInViewport = false
        }
        // Case 3: Mouse returned to viewport - emit HoverStart
        if isMouseInViewport && !inputState.wasMouseInViewport {
            let event = ToolEvent(.hoverStart, body: eventBody)
            events.append(event)
            inputState.wasMouseInViewport = true
        }
        
        // # Pointer Events
        // Pointer Down - ImGui tells us which buttons were clicked THIS FRAME
        let buttonsClicked = MouseButtonMask(io.MouseClicked)
        for button in buttonsClicked.buttons {
            let event = ToolEvent(.pointerDown,
                                  body: eventBody,
                                  triggerButton: button)
            events.append(event)
        }
        
        // Pointer Move - if mouse moved
        if mouseDelta.lengthSquared() > 0.0 {
            let event = ToolEvent(.pointerMove, body: eventBody)
            events.append(event)
        }
        
        // Pointer Up - ImGui tells us which buttons were released THIS FRAME
        let buttonsReleased = MouseButtonMask(io.MouseReleased)
        for button in buttonsReleased.buttons {
            let event = ToolEvent(.pointerUp,
                                  body: eventBody,
                                  triggerButton: button)
            events.append(event)
        }
        
        // # Modifier Change
        //
        if currentModifiers != inputState.previousModifiers {
            let event = ToolEvent(.modifierChange, body: eventBody)
            events.append(event)
        }
        inputState.previousModifiers = currentModifiers
        
        // === SCROLL EVENT ===
        if io.MouseWheel != 0.0 || io.MouseWheelH != 0.0 {
            let event = ToolEvent(.scroll,
                                  body: eventBody,
                                  scrollDelta: ImVec2(io.MouseWheelH, io.MouseWheel))
            events.append(event)
        }
        
        // # Escape Key Handling
        //
        let escapePressed = ImGui.IsKeyPressed(ImGuiKey_Escape)
        
        // # Input state machine and Gesture Recognition
        //
        switch inputState.pointerState {
        case .idle:
            for button in buttonsClicked.buttons {
                inputState.pointerState = .pressed(button)
                break // Track first button only
            }
            
        case .pressed(let dragButton):
            let distance = dragButton.unpackItem(io.MouseDragMaxDistanceSqr)
            // Button released - it's a click!
            if buttonsReleased.contains(dragButton.mask) {
                let clickCount = dragButton.unpackItem(io.MouseClickedCount)
                // ImGui already determined click count for us!
                let eventType: ToolEventType?
                if clickCount == 1 {
                    eventType = .click
                }
                else if clickCount == 2 {
                    eventType = .doubleClick
                }
                else if clickCount >= 3 {
                    eventType = .tripleClick
                }
                else {
                    eventType = nil
                }
                if let eventType {
                    let event = ToolEvent(eventType, body: eventBody, triggerButton: dragButton)
                    events.append(event)
                }
                inputState.pointerState = .idle
            }
                // Check if drag threshold exceeded (ImGui tracks this for us!)
            else if distance > io.MouseDragThreshold {
                inputState.pointerState = .dragging(dragButton)
                
                let event = ToolEvent(.dragStart, body: eventBody, triggerButton: dragButton)
                events.append(event)
            }
            // Escape cancels the press
            else if escapePressed {
                inputState.pointerState = .idle
            }

        case .dragging(let dragButton):
            // Continue dragging
            if buttonsDown.contains(dragButton.mask) {
                if mouseDelta.lengthSquared() > 0.0 {
                    let event = ToolEvent(.dragMove, body: eventBody, triggerButton: dragButton)
                    events.append(event)
                }
            }
            // Drag ended
            else if buttonsReleased.contains(dragButton.mask) {
                let event = ToolEvent(.dragEnd, body: eventBody, triggerButton: dragButton)
                events.append(event)
                inputState.pointerState = .idle
            }
            // Escape cancels drag
            if escapePressed {
                let event = ToolEvent(.dragCancel, body: eventBody, triggerButton: dragButton)
                events.append(event)
                inputState.pointerState = .idle
            }
        }
        
        return events
    }
}
