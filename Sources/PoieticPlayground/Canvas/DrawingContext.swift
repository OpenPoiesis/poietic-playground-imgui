//
//  DrawingContext.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import Ccairo
import Diagramming

struct DrawingContext {
    private let context: OpaquePointer
    
    init(_ context: OpaquePointer) {
        self.context = context
    }
    
    func setColor(_ color: Color) {
        cairo_set_source_rgba(context,
                              Double(color.red),
                              Double(color.green),
                              Double(color.blue),
                              Double(color.alpha))
    }
   
    func setFontSize(_ size: Double) {
        cairo_set_font_size(context, size)
    }
    func textSize(_ text: String) -> Vector2D {
        var extents: cairo_text_extents_t = cairo_text_extents_t()
        cairo_text_extents(context, text, &extents)
        return Vector2D(extents.width, extents.height)
    }
    
    func textExtents(_ text: String) -> cairo_text_extents_t {
        var extents: cairo_text_extents_t = cairo_text_extents_t()
        cairo_text_extents(context, text, &extents)
        return extents
    }
    
    func showText(_ text: String, at position: Vector2D) {
        cairo_move_to(context, position.x, position.y)
        cairo_show_text(context, text)
    }
    
    func showText(_ text: String, center: Vector2D) {
        var te: cairo_text_extents_t = cairo_text_extents_t()
        cairo_text_extents(context, text, &te)

        let position = Vector2D(center.x - (te.width / 2) - te.x_bearing,
                                center.y - (te.height / 2) - te.y_bearing)
        cairo_move_to(context, position.x, position.y)
        cairo_show_text(context, text)

    }
    
    func setLineWidth(_ width: Double) {
        cairo_set_line_width(context, width)
    }
    
    func strokeRect(origin: Vector2D, size: Vector2D) {
        cairo_rectangle(context, origin.x, origin.y, size.x, size.y)
        cairo_stroke(context)
    }
    
    func strokeDebugCircle(_ position: Vector2D) {
    }

    func fillRect(origin: Vector2D, size: Vector2D) {
        cairo_rectangle(context, origin.x, origin.y, size.x, size.y)
        cairo_fill(context)
    }

    func strokePath(_ path: BezierPath, transform: AffineTransform = .identity) {
        addPath(path, transform: transform)
        cairo_stroke(context)
    }

    func fillPath(_ path: BezierPath, transform: AffineTransform = .identity) {
        addPath(path, transform: transform)
        cairo_fill(context)
    }

    func addLine(from a: Vector2D, to b: Vector2D) {
        cairo_move_to(context, a.x, a.y)
        cairo_line_to(context, b.x, b.y)
    }
    
    func addCircle(center: Vector2D, radius: Double) {
        cairo_arc(context, center.x, center.y, radius, 0.0, Double.pi * 2)
    }

    func stroke() {
        cairo_stroke(context)
    }

    func fill() {
        cairo_fill(context)
    }
    
    func drawRect(_ rect: Rect2D, style: ShapeStyle) {
        cairo_save(context)
        setLineWidth(style.lineWidth)
        if let color = style.fill {
            setColor(color)
            fillRect(origin: rect.origin, size: rect.size)
        }
        if let color = style.outline {
            setColor(color)
            strokeRect(origin: rect.origin, size: rect.size)
        }
        cairo_restore(context)
    }
    
    func save() {
        cairo_save(context)
    }
    
    func restore() {
        cairo_restore(context)
    }

    func addPath(_ path: BezierPath, transform: AffineTransform = .identity) {
        var current: Vector2D = .zero
        for element in path.elements {
            switch element {
            case .moveTo(let point):
                let transPoint = transform.apply(to: point)
                cairo_move_to(context, transPoint.x, transPoint.y)
                current = transPoint
            case .lineTo(let point):
                let transPoint = transform.apply(to: point)
                cairo_line_to(context, transPoint.x, transPoint.y)
                current = transPoint
            case .curveTo(let end, let control1, let control2):
                let tEnd = transform.apply(to: end)
                let tCtrl1 = transform.apply(to: control1)
                let tCtrl2 = transform.apply(to: control2)
                cairo_curve_to(context,
                               tCtrl1.x, tCtrl1.y,
                               tCtrl2.x, tCtrl2.y,
                               tEnd.x, tEnd.y)
                current = tEnd
            case .quadCurveTo(let control, let end):
                let tEnd = transform.apply(to: end)
                let tCtrl = transform.apply(to: control)
                let (control1, control2) = Geometry.quadraticToCubicControls(start: current, control: tCtrl, end: tEnd)
                cairo_curve_to(context,
                               control1.x, control1.y,
                               control2.x, control2.y,
                               tEnd.x, tEnd.y)
                current = tEnd
            case .closePath:
                cairo_close_path(context)
            }
        }
    }
}
