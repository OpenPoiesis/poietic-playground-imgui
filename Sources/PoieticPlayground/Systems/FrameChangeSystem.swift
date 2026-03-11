//
//  FrameChangeSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import Diagramming
import PoieticFlows

struct IssueIndicator: Component {
//    var owner: RuntimeID
    // TODO: Use relative once rendering tree is implemented
    /// Absolute world position of the indicator
    var position: Vector2D
    var pictogram: Pictogram
    // TODO: Remove this once rendering tree is implemented
    /// Collision shape with absolute world position (not relative to the owner)
    var collisionShape: CollisionShape

    func collide(_ otherShape: CollisionShape) -> Bool {
        otherShape.collide(with: collisionShape)
    }
}

/// System that creates error indicators
///
/// - **Dependency:** no dependency
/// - **Input:** World issues.
/// - **Output:** Entities with ErrorIndicator component.
/// - **Forgiveness:** If the world's design does not have a current frame the system does nothing.
///
struct ErrorIndicatorSystem: System {
    let ErrorPictogramName: String = "Error"
    let DefaultErrorIndicatorSize: Double = 10.0
    
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(SimulationPlanningSystem.self),
        // TODO: Remove this system once we have relative visual objects
        .after(BlockCreationSystem.self),
    ]

    init(_ world: PoieticCore.World) {    }

    func update(_ world: PoieticCore.World) throws(PoieticCore.InternalSystemError) {
        let pictogram: Pictogram
        if let notation: Notation = world.singleton() {
            pictogram = notation.pictogram("Error")
        }
        else {
            pictogram = Notation.ReplacementPictogram
        }
        let shape: CollisionShape = pictogram.collisionShape
        // TODO: Make this clever, use reverse relationship (not yet implemented)
        // Despawn existing
        for entity: RuntimeEntity in world.query(IssueIndicator.self) {
            world.despawn(entity.runtimeID)
        }
        // Create new
        for (objectID, _) in world.issues {
            guard let objectEntity = world.entity(objectID) else { continue }
            
            // Create indicators only for objects that have visual representation
            let position: Vector2D
            guard let block: DiagramBlock = objectEntity.component() else { continue }
            if let preview: BlockPreview = objectEntity.component() {
                position = preview.position
            }
            else {
                position = block.position
            }

            let height = pictogram.maskBoundingBox.height
            let anchor = position + block.errorIndicatorAnchorOffset
            let offsetPosition = Vector2D(anchor.x, anchor.y - (height / 2))

            let translated = shape.translated(offsetPosition)
            let indicator = IssueIndicator(position: offsetPosition,
                                           pictogram: pictogram,
                                           collisionShape: translated)
            let owner = OwnedBy(objectEntity.runtimeID)
            let _: RuntimeEntity = world.spawn(indicator, owner)
        }
    }
}
