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
    /// Color or highlight tint for objects that are accepting a drag session.
    var acceptingColor: Color = .screenGreen
    /// Color or highlight tint for objects that are not accepting a drag session.
    var notAllowedColor: Color = .screenRed

    // Connector
    var defaultConnectorLineWidth: Float = 1.0
    var defaultConnectorColor: Color = DefaultConnectorColor
    var defaultConnectorFillColor: Color = DefaultConnectorFillColor

    // Per-type properties
    var connectorColors: [String:Color] = [:]
    var connectorFillColors: [String:Color] = [:]

    // Other visuals
    var selectionOutlineColor: Color = Color.screenYellow.darkened(0.5).withTransparency(0.5)
    var selectionFillColor: Color = Color.screenYellow.darkened(0.2).withTransparency(0.2)
    var handleColor: Color = Color.screenYellow.darkened(0.9).withTransparency(0.8)

    init() {
        
    }
    
    func adaptableColor(_ name: String, default: Color) -> Color {
        return adaptableColors[name, default: `default`]
    }
    func lineWidth(_ name: String, defaultWidth: Float = 1.0) -> Float {
        return lineWidths[name, default: defaultWidth]
    }
}
