//
//  HitTarget.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore

/// Hit targets:
/// - object directly
/// - primary/secondary label of object
/// - error indicator of object
/// - handle of object
///     - geometry
///     - action

enum CanvasHitTarget {
    enum ObjectPart {
        /// Direct object body hit. For blocks, the pictogram's collision shape is used. For
        /// connectors a practical distance from the connector wire (center curve) is used.
        case body
        case primaryLabel
        case secondaryLabel
        case issueIndicator
    }

    /// Canvas object or its part was hit, typically a design object.
    case object(RuntimeID, ObjectPart)
    case handle(RuntimeID)
}
