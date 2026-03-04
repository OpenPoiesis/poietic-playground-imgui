//
//  CanvasStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

let DefaultPictogramColor = Color.black
let DefaultConnectorColor = Color(gray: 0.8)
let DefaultConnectorFillColor = Color(gray: 0.3)
let DefaultIntentShadowColor = Color(gray: 0.3)
let DefaultBlockLabelColor: Color = .white

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

class CanvasStyle {
    var background: Color = Color(red: 0.97, green: 0.96, blue: 0.94)
    var gridColor = Color(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.2)

    var adaptableColors: [String:Color] = DefaultAdaptableColors
    
    // Block
    var lineWidths: [String:Float] = [:]
    var pictogramColor: Color = DefaultPictogramColor

    var primaryLabelStyle: LabelStyle = LabelStyle(color: .black, fontSize: 12.0)
    var secondaryLabelStyle: LabelStyle = LabelStyle(color: .screenBlue, fontSize: 11.0)
    var invalidLabelStyle: LabelStyle = LabelStyle(color: .screenRed)
    var valueIndicatorStyle: LabelStyle = LabelStyle(color: .screenGreen, fontSize: 11.0)

    var intentShadowColor: Color = Color(gray: 0.5)
    /// Color or highlight tint for objects that are accepting a drag session.
    var acceptingColor: Color = .screenGreen
    /// Color or highlight tint for objects that are not accepting a drag session.
    var notAllowedColor: Color = .screenRed

    // Connector
    var defaultConnectorLineWidth: Double = 1.0
    var defaultConnectorColor: Color = DefaultConnectorColor
    var defaultConnectorFillColor: Color = DefaultConnectorFillColor

    // Per-type properties
    var connectorColors: [String:Color] = [:]
    var connectorFillColors: [String:Color] = [:]

    // Other visuals
    var selectionOutlineColor: Color = Color.screenYellow.darkened(0.5).withTransparency(0.5)
    var selectionFillColor: Color = Color.screenYellow.darkened(0.2).withTransparency(0.2)
    var handleColor: Color = Color.screenBlue.darkened(0.9).withTransparency(0.8)

//    var errorIndicatorBackground: Color = Color.white.withTransparency(0.5)
//    var errorIndicatorColor: Color = Color(red: 0.7, green: 0.2, blue: 0.2)
    var errorIndicatorColor: Color = Color.white
    var errorIndicatorBackground: Color = Color(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8)

    // Indicator
    /// Style used to draw the indicator background, before the actual indicator content.
    var indicatorBackgroundStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .white)
    /// Style used to draw the indicator bar when the value is within bounds and when the negative
    /// style is not set.
    var indicatorNormalStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .screenGreen)
    /// If set, then the style is used to draw the value when the value is less than origin.
    var indicatorNegativeStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .screenYellow)
    /// Value used to draw the indicator when the value is greater than max value.
    var indicatorOverflowStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .screenRed)
    /// Value used to draw the indicator when the value is less than min value.
    var indicatorUnderflowStyle: ShapeStyle = ShapeStyle(outline: .black, fill: .screenMagenta)
    /// Style of the indicator when the value is not set.
    var indicatorEmptyStyle: ShapeStyle = ShapeStyle(outline: Color(gray: 0.8), fill: Color(gray: 0.5))

    init() { /* Empty init */ }
    
    func adaptableColor(_ name: String, default: Color) -> Color {
        return adaptableColors[name, default: `default`]
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
