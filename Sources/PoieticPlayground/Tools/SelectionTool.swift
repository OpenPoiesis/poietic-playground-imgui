//
//  SelectionTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming

struct InteractivePreviewTag: Component {}

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
    var dragStartScreenPos: ImVec2 = ImVec2()
    
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
        guard let canvas, let world else { return }

        // TODO: Close inline popup
        
        guard let target = canvas.hitTarget(screenPosition: event.screenPos) else {
            world.setSingleton(SelectionChange.removeAll)
            state = .objectSelect
            return
        }

        let selectionChange: SelectionChange?
        let selection: Selection? = world.singleton()

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
//        TODO: popupManager?.closeInlinePopup()
        dragStartScreenPos = event.screenPos

        switch state {
        case .idle: break
        case .objectSelect: break
        case .objectHit, .objectMove, .childHit:
//            Input.setDefaultCursorShape(.drag)
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            
        case .handleHit, .handleMove:
//            Input.setDefaultCursorShape(.drag)
//            dragHandle(canvas: canvas, byCanvasDelta: delta)
            state = .handleMove
        }
    }
    func dragMove(_ event: ToolEvent) {
//        TODO: popupManager?.closeInlinePopup()
        
        switch state {
        case .idle: break
        case .objectSelect: break
        case .objectHit, .objectMove, .childHit:
//            Input.setDefaultCursorShape(.drag)
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            
        case .handleHit, .handleMove:
//            Input.setDefaultCursorShape(.drag)
//            dragHandle(canvas: canvas, byCanvasDelta: delta)
            state = .handleMove
        }
    }
    func dragEnd(_ event: ToolEvent) {
        guard let canvas,
              let world,
              let frame = world.frame,
              let selection: Selection = world.singleton()
        else { return }

//        Input.setDefaultCursorShape(.arrow)
        let screenDelta = event.screenPos - self.dragStartScreenPos
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel

        switch state {
        case .objectMove:
            finalizeSelectionMove(selection, by: worldDelta)
            break
        case .handleMove:
//            self.finishDraggingHandle(globalPosition: globalPosition)
            break
        case .idle: break
        case .handleHit: break
        case .objectHit: break
        case .objectSelect: break
        case .childHit:
            break
//            guard let hitTarget,
//                  let block = hitTarget.object as? DiagramCanvasBlock,
//                  let entityID = block.runtimeID,
//                  let objectID = world?.entityToObject(entityID)
//            else {
//                break
//            }
//            let selectionManager = designController.selectionManager
//
//            switch hitTarget.type {
//            case .primaryLabel:
//                selectionManager.replaceAll([objectID])
//                popupManager?.openInlineEditor("name", rawEntityID: objectID.asGodotValue(), attribute: "name")
//            case .secondaryLabel:
//                selectionManager.replaceAll([objectID])
//                popupManager?.openInlineEditor("formula", rawEntityID: objectID.asGodotValue(), attribute: "formula")
//            case .errorIndicator:
//                selectionManager.replaceAll([objectID])
//                popupManager?.openIssuesPopup(objectID.asGodotValue())
//            case .object: break
//            case .handle: break
//            }
        }

    }
    func dragCancel(_ event: ToolEvent) {
        
    }
    
    func previewSelectionMove(screenDelta: ImVec2) {
        guard let canvas,
              let world,
              let frame = world.frame,
              let selection: Selection = world.singleton()
        else { return }

        var dependentEdges: Set<PoieticCore.ObjectID> = Set()
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel

        for objectID in selection {
            guard let block: DiagramBlock = world.component(for: objectID) else { continue }
            var preview: BlockPreview
            if let component: BlockPreview = world.component(for: objectID) {
                preview = component
            }
            else {
                preview = BlockPreview(position: block.position)
            }
            preview.position += worldDelta
            world.setComponent(preview, for: objectID)
            
            let deps = frame.dependentEdges(objectID)
            dependentEdges.formUnion(deps)
        }
        
        for objectID in selection {
            guard let connector: DiagramConnector = world.component(for: objectID) else { continue }
            guard !connector.midpoints.isEmpty else { continue }
            var preview: ConnectorPreview
            if let component: ConnectorPreview = world.component(for: objectID) {
                preview = component
            }
            else {
                preview = ConnectorPreview(midpoints: connector.midpoints)
            }
            
            preview.midpoints = preview.midpoints.map { $0 + worldDelta }
            world.setComponent(preview, for: objectID)
        }
        
        for id in dependentEdges {
            guard let entID = world.objectToEntity(id) else { continue }
            guard world.hasComponent(DiagramConnector.self, for: entID) else { continue }
            
        }
        
        world.setSingleton(InteractivePreviewTag())
    }
    
    func finalizeSelectionMove(_ selection: Selection, by designDelta: Vector2D) {
        guard let world,
              let currentFrame = world.frame
        else { return }
        let design = world.design
        let trans = design.createFrame(deriving: currentFrame)

        for id in selection {
            guard trans.contains(id) else { continue }
            let object = trans.mutate(id)
            moveObject(object, by: designDelta)
        }
        world.removeComponentForAll(BlockPreview.self)
        world.removeComponentForAll(ConnectorPreview.self)
        world.removeSingleton(InteractivePreviewTag.self)

        world.setSingleton(trans)
    }
    
    func moveObject(_ object: TransientObject, by designDelta: Vector2D) {
        print("MOVE OBJ \(object) D:\(designDelta)")
        if object.type.hasTrait(.DiagramBlock) {
            object.position = (object.position ?? .zero) + designDelta
        }
        else if object.type.hasTrait(.DiagramConnector) {
            guard let midpoints: [Point] = object["midpoints"],
                  !midpoints.isEmpty
            else { return }
            
            let movedMidpoints = midpoints.map { $0 + designDelta }
            object["midpoints"] = PoieticCore.Variant(movedMidpoints)
        }
    }

}
