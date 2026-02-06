//
//  CanvasStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

let DefaultPictogramColor = Color.white
let DefaultConnectorColor = Color(gray: 0.8)
let DefaultConnectorFillColor = Color(gray: 0.3)
let DefaultIntentShadowColor = Color(gray: 0.3)
let DefaultBlockLabelColor: Color = .white

class LabelStyle {
    let color: Color
    // let size: Float
    // let fontStyle: ... bold/italics
    init(color: Color){
        self.color = color
    }
}

class CanvasStyle {
    var adaptableColors: [String:Color] = DefaultAdaptableColors
    
    // Block
    var lineWidths: [String:Float] = [:]
    var pictogramColor: Color = DefaultPictogramColor

    var primaryLabelStyle: LabelStyle = LabelStyle(color: .white)
    var secondaryLabelStyle: LabelStyle = LabelStyle(color: .screenCyan)
    var invalidLabelStyle: LabelStyle = LabelStyle(color: .white)

    var intentShadowColor: Color = Color(gray: 0.5)

    // Connector
    var defaultConnectorLineWidth: Float = 1.0
    var defaultConnectorColor: Color = DefaultConnectorColor
    var defaultConnectorFillColor: Color = DefaultConnectorFillColor

    // Per-type properties
    var connectorColors: [String:Color] = [:]
    var connectorFillColors: [String:Color] = [:]

    // Other visuals
    var selectionOutlineColor: Color = Color.white
    var selectionFillColor: Color = Color.white
    var handleColor: Color = DefaultConnectorColor

    init() {
        
    }
    
    func adaptableColor(_ name: String, default: Color) -> Color {
        return adaptableColors[name, default: `default`]
    }
    func lineWidth(_ name: String, defaultWidth: Float = 1.0) -> Float {
        return lineWidths[name, default: defaultWidth]
    }
}
