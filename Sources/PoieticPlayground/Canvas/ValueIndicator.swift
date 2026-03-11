//
//  ValueIndicator.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 02/03/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming

enum Orientation {
    case horizontal
    case vertical
}

struct ValueIndicatorGeometry: Component {
    /// The full frame including padding/background
    let frame: Rect2D
    
    /// The actual indicator bar rectangle (after padding)
    let valueBar: Rect2D
    
    /// The baseline indicator line
    let baselineLine: LineSegment
    
    /// The bounded/clipped value being displayed
    let value: Double
    
    /// The state (overflow, underflow, positive, negative)
    let state: ValueBounds.State
}
