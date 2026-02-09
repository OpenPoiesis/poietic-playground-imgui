//
//  HitTarget.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore

class CanvasHitTarget {
    enum TargetType {
        case object
        case primaryLabel
        case secondaryLabel
        case errorIndicator
        case handle
    }
    let runtimeID: RuntimeID
    let type: TargetType
    
    init(runtimeID: RuntimeID, type: TargetType) {
        self.runtimeID = runtimeID
        self.type = type
    }
}
