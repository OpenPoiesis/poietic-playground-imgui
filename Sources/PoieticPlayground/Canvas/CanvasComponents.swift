//
//  CanvasComponents.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 16/02/2026.
//

import PoieticCore
import Diagramming

struct BlockIntent: Component {
    let type: ObjectType
    var position: Vector2D
    let pictogram: Pictogram
}

struct ConnectorIntent: Component {
    let type: ObjectType
    let originID: RuntimeID
    let glyph: ConnectorGlyph
    let targetID: RuntimeID?
    let targetAllowed: Bool
}

enum TargetHighlight: Component {
    case none
    case accepting
    case notAllowed
}

struct CanvasHandle: Component {
    enum Kind {
        /// Handle represents a connector mid-point.
        ///
        /// Moving the handle requires that the position is reflected in ``ConnectorPreview``.
        ///
        /// - SeeAlso: ``SelectionTool/dragMidpointHandle(_:index:currentPosition:currentDelta:)``,
        /// ``SelectionTool/finalizeHandleMove(_:finalPosition:totalDelta:)``
        /// 
        case midpoint(Int)
        // TODO: case connect(ObjectType)
    }
    // TODO: Use OwnedBy
    /// Runtime entity owning the handle, typically an entity corresponding to a design object.
    let owner: RuntimeID
    let kind: Kind
    /// Current position of the handle in world coordinates.
    ///
    /// Use this position for drawing the handle and for creating a transaction when dragging
    /// operation is concluded.
    var position: Vector2D
    
    init(owner: RuntimeID, position: Vector2D, kind: Kind) {
        self.owner = owner
        self.position = position
        self.kind = kind
    }
}
