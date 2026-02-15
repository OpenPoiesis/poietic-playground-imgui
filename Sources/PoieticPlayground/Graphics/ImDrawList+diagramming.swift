//
//  PictogramDrawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/02/2026.
//

import CIimgui
import Diagramming

extension ImDrawList {
    
    mutating func StrokePath(_ path: BezierPath, color: Color = .white, lineWidth: Float = 1.0, transform: AffineTransform? = nil) {
        let actualPath: BezierPath
        if let transform {
            actualPath = path.transform(transform)
        }
        else {
            actualPath = path
        }
        let strokeColor: ImU32 = color.imIntValue

        var hadStroke: Bool = false
        var wasClosed: Bool = false
        
        for element in actualPath.elements {
            switch element {
            case .moveTo(let point):
                if hadStroke {
                    self.PathStroke(strokeColor, 0, lineWidth)
                }
                self.PathClear()
                self.PathLineTo(ImVec2(point))
                wasClosed = false
                hadStroke = false

            case .lineTo(let point):
                self.PathLineTo(ImVec2(point))
                wasClosed = false
                hadStroke = true

            case .curveTo(let end, let control1, let control2):
                self.PathBezierCubicCurveTo(ImVec2(control1), ImVec2(control2), ImVec2(end))
                wasClosed = false
                hadStroke = true

            case .quadCurveTo(let control, let end):
                self.PathBezierQuadraticCurveTo(ImVec2(control), ImVec2(end))
                hadStroke = true
                wasClosed = false

            case .closePath:
                self.PathStroke(strokeColor, 0, lineWidth)
                wasClosed = true
                hadStroke = false
            }
        }
        if hadStroke && !wasClosed {
            self.PathStroke(strokeColor, 0, lineWidth)
        }
    }
    
    mutating func FillPath(_ path: BezierPath, color: Color = .white, transform: AffineTransform? = nil) {
        let actualPath: BezierPath
        if let transform {
            actualPath = path.transform(transform)
        }
        else {
            actualPath = path
        }

        let fillColor: ImU32 = color.imIntValue
        for segment in actualPath.subpaths() {
            let points = segment.tessellate()
            let imPoints = points.map { ImVec2($0) }
            self.AddConcavePolyFilled(imPoints, Int32(imPoints.count), fillColor)
        }
    }
    
    /// Stroke a pictogram centered at `center`,
    /// so that it fits proportionally within a rectangle of `size`.
    ///
    mutating func StrokePictogramIcon(_ pictogram: Pictogram,
                                      center: ImVec2,
                                      size: ImVec2,
                                      color: Color = .white,
                                      lineWidth: Float = 1.0) {
        // TODO: Make bitmaps from all pictograms in Notation.
        
        let centerOffset = Vector2D(center) - (Vector2D(size) / 2)
        let transform = pictogram.transformToFit(size: Vector2D(size)).translated(centerOffset)
        let path = pictogram.path.transform(transform)

        self.StrokePath(path, color: color, lineWidth: lineWidth)
    }
}

extension Pictogram {
    /// Proportional scaling to fit centre of a rectangle of given size..
    func transformToFit(size requiredSize: Vector2D) -> AffineTransform {
        let bounds = self.pathBoundingBox
        
        let scaleX = requiredSize.x / bounds.width
        let scaleY = requiredSize.y / bounds.height
        
        let scaleFactor = min(scaleX, scaleY)
        let scaledSize = bounds.size * scaleFactor
        
        // Center within the target rectangle
        let centeringOffset = (requiredSize - scaledSize) / 2.0
        
        // Move pictogram's bottom-left to origin
        let originOffset = -bounds.bottomLeft
        
        let transform = AffineTransform(translation: -bounds.bottomLeft)
            .scaled(Vector2D(scaleFactor, scaleFactor))
            .translated(centeringOffset)

        return transform
    }
}
