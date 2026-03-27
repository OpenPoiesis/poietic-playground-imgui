//
//  CanvasStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore

class LabelStyle {
    let color: Color
    let fontSize: Double
    // let fontStyle: ... bold/italics
    init(color: Color, fontSize: Double = 12.0){
        self.color = color
        self.fontSize = fontSize
    }
}

class ShapeStyle {
    let outline: Color?
    let fill: Color?
    let lineWidth: Double

    internal init(outline: Color? = nil, fill: Color? = nil, lineWidth: Double = 1.0) {
        self.outline = outline
        self.fill = fill
        self.lineWidth = lineWidth
    }
}

let WarmCharcoalColor = Color(red: 0.22, green: 0.20, blue: 0.18)
let WarmSlateBlueColor = Color(red: 0.25, green: 0.35, blue: 0.55)
let ErrorRedColor = Color(red: 0.85, green: 0.18, blue: 0.12)

let DefaultPictogramColor = WarmSlateBlueColor
let DefaultConnectorColor = WarmSlateBlueColor
let DefaultConnectorFillColor = WarmSlateBlueColor.withTransparency(0.5)
let DefaultIntentShadowColor = Color(gray: 0.3)
let DefaultBlockLabelColor: Color = .white

class CanvasStyle {
    var background: Color = Color(red: 0.97, green: 0.96, blue: 0.93)
    var gridColor = Color(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.2)

    var adaptableColors: [AdaptableColorKey:Color] = DefaultAdaptableColors
    
    // Block
    var lineWidths: [String:Float] = [:]
    var pictogramMaskColor: Color = .white.withTransparency(0.2)
    var pictogramColor: Color = DefaultPictogramColor

    var primaryLabelStyle: LabelStyle = LabelStyle(color: Color(red: 0.22, green: 0.20, blue: 0.18), fontSize: 12.0)
    var secondaryLabelStyle: LabelStyle = LabelStyle(color: .screenBlue, fontSize: 11.0)
    var invalidLabelStyle: LabelStyle = LabelStyle(color: .screenRed)
    var valueIndicatorStyle: LabelStyle = LabelStyle(color: Color(gray: 0.5), fontSize: 11.0)

    var intentShadowColor: Color = Color(red: 0.25, green: 0.35, blue: 0.55, alpha: 0.3)
    /// Color or highlight tint for objects that are accepting a drag session.
    var acceptingColor: Color = Color(red: 0.18, green: 0.68, blue: 0.40)
    /// Color or highlight tint for objects that are not accepting a drag session.
    var notAllowedColor: Color = Color(red: 0.88, green: 0.28, blue: 0.15)

    // Connector
    var defaultConnectorLineWidth: Double = 1.0
    var defaultConnectorColor: Color = DefaultConnectorColor
    var defaultConnectorFillColor: Color = DefaultConnectorFillColor

    // Per-type properties
    var connectorColors: [String:Color] = [:]
    var connectorFillColors: [String:Color] = [:]

    // Other visuals
    var selectionOutlineColor: Color = Color(red: 0.25, green: 0.50, blue: 0.85)
    var selectionFillColor: Color = Color(red: 0.35, green: 0.60, blue: 0.90, alpha: 0.18) // consider 60-80% opacity
    var handleColor: Color = Color(red: 0.90, green: 0.65, blue: 0.20)

//    var errorIndicatorBackground: Color = Color.white.withTransparency(0.5)
//    var errorIndicatorColor: Color = Color(red: 0.7, green: 0.2, blue: 0.2)
    var errorIndicatorColor: Color = Color.white
    var errorIndicatorBackground: Color = ErrorRedColor //Color(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8)

    // Indicator
    /// Style used to draw the indicator background, before the actual indicator content.
    var indicatorBackgroundStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .white)
    /// Style used to draw the indicator bar when the value is within bounds and when the negative
    /// style is not set.
    var indicatorNormalStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red:0.22, green:0.62, blue:0.48))
    /// If set, then the style is used to draw the value when the value is less than origin.
    var indicatorNegativeStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.85, green: 0.55, blue: 0.10))
    /// Value used to draw the indicator when the value is greater than max value.
    var indicatorOverflowStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.80, green: 0.22, blue: 0.10))
    /// Value used to draw the indicator when the value is less than min value.
    var indicatorUnderflowStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red:0.25, green:0.48, blue:0.72))
    /// Style of the indicator when the value is not set.
    var indicatorEmptyStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.72, green: 0.70, blue: 0.67))
    var indicatorLineColor: Color = .black

    init() { /* Empty init */ }
    
    func adaptableColor(_ key: AdaptableColorKey, default defaultColor: Color) -> Color {
        return adaptableColors[key, default: defaultColor]
    }
    func lineWidth(_ name: String, defaultWidth: Float = 1.0) -> Float {
        return lineWidths[name, default: defaultWidth]
    }
    
#if false
    enum ColorKey: CaseIterable {
        case background
        case stroke
        case grid
        case pictogram
        case intentShadow
        case accepting
        case notAllowed
        case defaultConnector
        case defaultConnectorFill
        case selectionOutline
        case selectionFill
        case handle
        case errorIndicator
        case errorIndicatorBackground
    }
    enum MetricKey: CaseIterable {
        case pictogramLineWidth
        case defaultConnectorLineWidth
        
        case handleSize
        case primaryLabelPadding
        case secondaryLabelPadding
        case colorSwatchSize
    }
#endif
    
}
