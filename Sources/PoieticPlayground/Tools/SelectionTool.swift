//
//  SelectionTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

class SelectionTool: CanvasTool {
    // TODO: Implement the tool (empty stub for now)

    override var name: String { "selection"}
    override var iconName: String { "select"}

    enum State {
        /// Nothing hit, initial state
        case idle
        /// Direct hit of a single object, typically a block or a connector.
        case objectHit
        /// Object selection initiated.
        case objectSelect
        /// Dragging selection around.
        case objectMove
        /// Handle that can be moved was hit.
        case handleHit
        /// Dragging handle around.
        case handleMove
        /// Some other object child was hit, such as label or issue indicator.
        case childHit
    }
    var state: State = .idle
    override func handleEvent(_ event: ToolEvent) {
        switch event.type {
        case .pointerDown: self.pointerDown(event)
        case .dragStart: self.dragStart(event)
        case .dragMove: self.dragMove(event)
        case .dragEnd: self.dragEnd(event)
        case .dragCancel: self.dragCancel(event)
        default: break
        }
    }
    func pointerDown(_ event: ToolEvent) {
        guard let canvas,
              let world
        else { return }

        // TODO: Close inline popup
        
        guard let target = canvas.hitTarget(screenPosition: event.screenPos) else {
            world.setSingleton(SelectionChange.removeAll)
            state = .objectSelect
            return
        }

        let selectionChange: SelectionChange?
        let selection: Selection? = world.singleton()
        
        //        initialCanvasPosition = canvas.toLocal(globalPoint: globalPosition)
//        previousCanvasPosition = initialCanvasPosition
        switch target.type {
        case .object:
            // TODO: Defer opening of context menu on inputEnded or move context menu out of the tool
            guard let objectID = world.entityToObject(target.runtimeID)
            else { return } // Not a design object
            
//            TODO: canvas.removeHandles()
            if event.modifiers.contains(.shift) {
                selectionChange = .toggle(objectID)
            }
            else {
                if let selection, selection.contains(objectID) {
                    // TODO: Implement context menu, at screenPosition
                    print("TODO: open popup for \(selection.ids) not implemented")
                    selectionChange = nil
                }
                else {
                    selectionChange = .replaceAllWithOne(objectID)
                }
            }
            if let selection,
               let objectID = selection.selectionOfOne(),
               let entityID = world.objectToEntity(objectID)
            {
                // TODO: createHandles(canvas: canvas, for: entityID)
            }
            state = .objectHit
        case .handle:
//            hitTarget = target
            state = .handleHit
            selectionChange = .removeAll
        case .primaryLabel,
                .secondaryLabel,
                .errorIndicator:
//            canvas.removeHandles()
//            hitTarget = target
            state = .childHit
            selectionChange = nil
        }
        if let selectionChange {
            print("SELECTION: \(selectionChange)")
            world.setSingleton(selectionChange)
        }

    }
    func dragStart(_ event: ToolEvent) {
        
    }
    func dragMove(_ event: ToolEvent) {
        
    }
    func dragEnd(_ event: ToolEvent) {
        
    }
    func dragCancel(_ event: ToolEvent) {
        
    }
}
