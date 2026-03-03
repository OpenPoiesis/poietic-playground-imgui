//
//  ValueIndicator.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 02/03/2026.
//

import PoieticCore

enum Orientation {
    case horizontal
    case vertical
}

/// Defines bounds of possible values for a metric, including baseline.
/// Used for visual indicators, chart axes, and value normalisation.
struct ValueBounds {
    /// The minimum allowable value (underflow occurs below this)
    let min: Double
    
    /// The maximum allowable value (overflow occurs above this)
    let max: Double
    
    /// The reference point separating negative from positive values
    /// Defaults to midpoint between min and max if not explicitly set
    let baseline: Double
    
    /// Range of the bounds: `max - min`.
    var range: Double { max - min }
    
    /// Convenience computed variable for normalising baseline.
    ///
    /// Same as:
    ///
    /// ```swift
    /// let bounds: ValueBounds // Given
    /// let baselineScale = bounds.normalized(bounds.baseline)
    /// ```
    var normalizedBaseline: Double { normalized(baseline) }

    /// Creates value bounds with specified min, max and baseline
    /// - Parameters:
    ///   - min: Lower bound
    ///   - max: Upper bound
    ///   - baseline: Reference point (defaults to midpoint if nil)
    ///
    /// - Precondition: ``max`` must be greater or equal than ``min``.
    init(min: Double, max: Double, baseline: Double) {
        precondition(max >= min)
        self.min = min
        self.max = max
        self.baseline = baseline
    }
    
    /// The status of a value within this bounds domain
    enum State {
        /// Value > max
        case overflow
        /// Value < min
        case underflow
        /// Value ≥ baseline and ≤ max
        case positive
        /// Value < baseline and ≥ min
        case negative
        
        var isWithinBounds: Bool {
            switch self {
            case .overflow, .underflow: false
            case .positive, .negative: true
            }
        }
    }
    
    /// Determines the status of a given value within this domain
    /// - Parameter value: The value to check
    /// - Returns: The ``Status`` indicating where the value lies
    func state(of value: Double) -> State {
        if value > max { .overflow }
        else if value < min { .underflow }
        else if value >= baseline { .positive }
        else { .negative }
    }
    
    /// Clips a value to the domain bounds if necessary
    /// - Parameter value: The value to clip
    /// - Returns: The value clipped to [min, max]
    func clip(_ value: Double) -> Double {
        return Swift.max(self.min, Swift.min(self.max, value))
    }
    
    /// Normalizes a value to the 0-1 range based on domain bounds
    /// - Parameter value: The value to normalize
    /// - Returns: Normalized value between 0 and 1, with bounds clipping
    func normalized(_ value: Double) -> Double {
        let clipped = self.clip(value)
        return (clipped - min) / (max - min)
    }
    
//    /// Returns the relative position of a value along the domain,
//    /// with baseline mapping to 0.5 for symmetrical display
//    func relativePosition(_ value: Double) -> Double {
//        let clipped = clip(value)
//        
//        // For values below baseline, map to [0, 0.5]
//        if clipped <= baseline {
//            return 0.5 * (clipped - min) / (baseline - min)
//        }
//        // For values above baseline, map to [0.5, 1]
//        else {
//            return 0.5 + 0.5 * (clipped - baseline) / (max - baseline)
//        }
//    }
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
