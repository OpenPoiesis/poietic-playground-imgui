//
//  Inspector.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

class InspectorSection: ApplicationObject {
    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    func draw() {
        // Nothing yet
    }
}

class InspectorPanel: Panel {
    var sections: [InspectorSection] = []
    
    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    func draw() {
        // 1. Draw self
        // 2. Draw sections
        
        for section in sections {
            section.draw()
        }
        // Nothing yet
    }
}
