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

