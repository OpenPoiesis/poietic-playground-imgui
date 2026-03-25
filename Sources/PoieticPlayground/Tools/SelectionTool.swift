//
//  SelectionTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming

class SelectionTool: CanvasTool {
    // TODO: Implement the tool (empty stub for now)

    override var name: String { "selection"}
    override var iconKey: IconKey { .select }

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
        case handleEngaged(RuntimeID)
        /// Dragging handle around.
        case handleMove(RuntimeID)
        /// Object part was hit, such as label or issue indicator.
        case objectPartHit(RuntimeID, CanvasHitTarget.ObjectPart)
    }
    
    var state: State = .idle
    var dragStartScreenPos: ImVec2 = ImVec2()
    
    // MARK: - Events

    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .pointerDown: return self.pointerDown(event)
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        default: return .pass
        }
    }
    
    func pointerDown(_ event: ToolEvent) -> EngagementResult {
        guard let canvas,
              let document,
              event.triggerButton == .left
        else { return .pass }
        dragStartScreenPos = event.screenPos
        
        // TODO: Close inline popup
        
        let target = canvas.hitTarget(screenPosition: event.screenPos)
        let selection = document.selection

        switch target {
        case .none:
            document.changeSelection(.removeAll)
            state = .objectSelect
            self.removeHandles()
            return .consumed
        case .object(let runtimeID, .body):
            // TODO: Defer opening of context menu on inputEnded or move context menu out of the tool
            guard let objectID = world.entityToObject(runtimeID)
            else { return .consumed } // Not a design object
            
            if event.modifiers.contains(.shift) {
                document.changeSelection(.toggle(objectID))
            }
            else {
                if selection.contains(objectID) {
                    // TODO: Implement context menu, at screenPosition
                    print("TODO: open popup for \(selection.ids) not implemented")
                }
                else {
                    document.changeSelection(.replaceAllWithOne(objectID))
                }
            }
            self.removeHandles()
            if let objectID = selection.selectionOfOne(),
               let runtimeID = world.objectToEntity(objectID)
            {
                createHandles(for: runtimeID)
            }
            state = .objectHit
        case .object(let runtimeID, .issueIndicator):
            self.removeHandles()
            state = .idle
            guard let objectID = world.entityToObject(runtimeID) else { break }
            self.document?.queueCommand(OpenIssuesCommand(objectID))
        case .object(let runtimeID, let part):
            self.removeHandles()
            state = .objectPartHit(runtimeID, part)
        case .handle(let runtimeID):
            state = .handleEngaged(runtimeID)
        }
        
        switch state {
        case .idle: return .consumed
        default: return .engaged
        }

    }
    func dragStart(_ event: ToolEvent) -> EngagementResult {
//        TODO: popupManager?.closeInlinePopup()
        switch state {
        case .idle, .objectSelect:
            return .pass
        case .objectHit, .objectMove, .objectPartHit:
//            Input.setDefaultCursorShape(.drag)
            document?.beginInteractivePreview()
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            
        case .handleEngaged(let runtimeID), .handleMove(let runtimeID):
            print("DRAG START WITHG HANDLE")
//            Input.setDefaultCursorShape(.drag)
//            dragHandle(byCanvasDelta: delta)
            state = .handleMove(runtimeID)
        }
        print("Drag started: \(state)")
        return .engaged
    }
    func dragMove(_ event: ToolEvent) -> EngagementResult {
//        TODO: popupManager?.closeInlinePopup()
        
        switch state {
        case .idle: break
        case .objectSelect: break
        case .objectHit,
                .objectMove,
                .objectPartHit:
//            Input.setDefaultCursorShape(.drag)
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            
        case .handleEngaged(let handleID),
                .handleMove(let handleID):
//            Input.setDefaultCursorShape(.drag)
            dragHandle(handleID, screenDelta: event.delta)
            state = .handleMove(handleID)
        }

        return .engaged
    }

    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        defer {
            state = .idle
        }
        // TODO: Mouse cursors
        guard let canvas,
              let document
        else { return .pass }

//        Input.setDefaultCursorShape(.arrow)
        let screenDelta = event.screenPos - self.dragStartScreenPos
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel

        switch state {
        case .objectMove:
            finalizeSelectionMove(document.selection, by: worldDelta)

        case .handleMove(let handleID):
            guard let handle = document.world.entity(handleID) else { break }
            let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
            finalizeHandleMove(handle, finalPosition: worldPosition, totalDelta: worldDelta)
            state = .handleMove(handleID)

        case .idle, .objectHit, .objectSelect, .handleEngaged: break

        case .objectPartHit:
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
        return .consumed
    }
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        cleanUp()
        return .consumed
    }
    
    // MARK: - Object Move
    
    func previewSelectionMove(screenDelta: ImVec2) {
        guard let canvas,
              let document,
              let frame = document.world.frame
        else { return }
        let selection = document.selection

        var dependentEdges: Set<PoieticCore.ObjectID> = Set()
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel

        for objectID in selection {
            guard let entity = world.entity(objectID),
                  let block: DiagramBlock = entity.component()
            else { continue }
            var preview: BlockPreview = entity.component() ?? BlockPreview(position: block.position)
            preview.position += worldDelta
            entity.setComponent(preview)
            
            let deps = frame.dependentEdges(objectID)
            dependentEdges.formUnion(deps)
        }
        
        for objectID in selection {
            guard let entity = world.entity(objectID),
                  let connector: DiagramConnector = entity.component(),
                  !connector.midpoints.isEmpty
            else { continue }

            var preview: ConnectorPreview = entity.component()
                        ??  ConnectorPreview(midpoints: connector.midpoints)
            
            preview.midpoints = preview.midpoints.map { $0 + worldDelta }
            entity.setComponent(preview)
        }
        
        for id in dependentEdges {
            // FIXME: Implement this
        }
        document.queueInteractivePreviewUpdate()
    }
    
    func finalizeSelectionMove(_ selection: Selection, by designDelta: Vector2D) {
        guard let document
        else { return }

        let trans = document.createOrReuseTransaction()

        for id in selection {
            guard trans.contains(id) else { continue }
            let object = trans.mutate(id)
            moveObject(object, by: designDelta)
        }
        cleanUp()
        document.endInteractivePreview()
    }

    func moveObject(_ object: TransientObject, by designDelta: Vector2D) {
        if object.type.hasTrait(.DiagramBlock) {
            object.position = (object.position ?? .zero) + designDelta
        }
        else if object.type.hasTrait(.DiagramConnector) {
            guard let midpoints: [Point] = object["midpoints"],
                  !midpoints.isEmpty
            else { return }
            
            let movedMidpoints = midpoints.map { $0 + designDelta }
            object["midpoints"] = Variant(movedMidpoints)
        }
    }
    

    // MARK: - Handle Drag
    func createHandles(for runtimeID: RuntimeID) {
        guard let world = document?.world,
              let entity = world.entity(runtimeID)
        else { return }
        
        if entity.contains(DiagramConnector.self) {
            createMidpointHandles(entity)
        }
        // ... create other handle types
    }
    
    func createMidpointHandles(_ entity: RuntimeEntity) {
        guard let connector: DiagramConnector = entity.component()
        else { return }
        
        let preview: ConnectorPreview? = entity.component()
        let midpoints = preview?.midpoints ?? connector.midpoints
        
        if midpoints.isEmpty {
            guard let origin = world.entity(connector.originID),
                  let originBlock: DiagramBlock = origin.component(),
                  let target = world.entity(connector.targetID),
                  let targetBlock: DiagramBlock = target.component()
            else { return }

            let segment = LineSegment(from: originBlock.position, to: targetBlock.position)
            let midpoint = segment.midpoint
            
            let component = CanvasHandle(owner: entity.runtimeID,
                                         position: midpoint,
                                         kind: .midpoint(0))
            
            let _: RuntimeEntity = world.spawn(component, OwnedBy(entity.runtimeID))
        }
        else {
            for (index, point) in midpoints.enumerated() {
                let component = CanvasHandle(owner: entity.runtimeID,
                                          position: point,
                                          kind: .midpoint(index))
                let _: RuntimeEntity = world.spawn(component, OwnedBy(entity.runtimeID))
            }
        }
    }
    
    func dragHandle(_ handleRuntimeID: RuntimeID, screenDelta: ImVec2) {
        guard let document,
              let canvas,
              let handle = document.world.entity(handleRuntimeID),
              var component: CanvasHandle = handle.component()
        else { return }
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel
        component.position += worldDelta
        handle.setComponent(component)
        
        switch component.kind {
        case .midpoint(let index):
            guard let owner = document.world.entity(component.owner) else { break }
            dragMidpointHandle(owner, index: index, currentPosition: component.position, currentDelta: worldDelta)
        }
        
        document.requiresInteractivePreviewUpdate = true
    }
    
    /// Reflect handle position to connector preview.
    ///
    func dragMidpointHandle(_ owner: RuntimeEntity, index: Int, currentPosition: Vector2D, currentDelta: Vector2D) {
        var midpoints: [Vector2D]
        
        if let preview: ConnectorPreview = owner.component() {
            if preview.midpoints.isEmpty {
                midpoints = [currentPosition]
            }
            else {
                midpoints = preview.midpoints

                if index < preview.midpoints.count {
                    midpoints[index] = currentPosition
                }
            }
        }
        else {
            midpoints = [currentPosition]
        }
        
        let newPreview = ConnectorPreview(midpoints: midpoints)
        owner.setComponent(newPreview)
    }

    /// Parameters:
    ///     - handleRuntimeID:
    
    func finalizeHandleMove(_ handle: RuntimeEntity, finalPosition: Vector2D, totalDelta: Vector2D) {
        guard let document,
              let component: CanvasHandle = handle.component()
        else { return }

        switch component.kind {
        case .midpoint(let index):
            guard let owner = document.world.entity(component.owner) else { break }
            finalizeMidpointMove(owner: owner, index: index, finalPosition: finalPosition)
        }
        document.requiresInteractivePreviewUpdate = true
    }

    func finalizeMidpointMove(owner: RuntimeEntity, index: Int, finalPosition: Vector2D) {
        guard let document,
              let objectID = owner.objectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        guard trans.contains(objectID) else { return }
        
        let object = trans.mutate(objectID)
        guard object.type.hasTrait(.DiagramConnector) else { return }
        
        if var midpoints: [Point] = object["midpoints"] {
            guard index < midpoints.count else { return }
            midpoints[index] = finalPosition
            object["midpoints"] = Variant(midpoints)
        }
        else {
            object["midpoints"] = Variant([finalPosition])
        }

    }
    // MARK: - Clean-up
    
    func cleanUp() {
        world.removeComponentForAll(BlockPreview.self)
        world.removeComponentForAll(ConnectorPreview.self)
    }
    
    func removeHandles() {
        for (runtimeID, _) in world.query(CanvasHandle.self) {
            world.despawn(runtimeID)
        }
    }

}
