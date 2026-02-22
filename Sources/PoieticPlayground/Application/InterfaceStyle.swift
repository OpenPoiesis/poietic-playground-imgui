//
//  UIStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 18/02/2026.
//

enum IconKey: CaseIterable, Hashable {
    case add
    case arrowComment
    case arrowOutlined
    case arrowParameter
    case cancel
    case chevronsLeft
    case chevronsRight
    case connect
    case delete
    case empty
    case error
    case formula
    case hand
    case handleFlow
    case lastStep
    case lineCurved
    case lineOrthogonal
    case lineStraight
    case loop
    case menu
    case nextStep
    case ok
    case place
    case previousStep
    case redo
    case restart
    case run
    case select
    case stop
    case timeWindow
    case undo
    case zoomIn
    case zoomOut
    
    var name: String {
        String(describing: self).toSnakeCase(splitCharacter: "-")
    }
}

class InterfaceStyle {
    @MainActor
    static var current: InterfaceStyle {
        get {
            guard let style = self._current else {
                fatalError("Interface style not initialised")
            }
            return style
        }
        set(newValue) {
            _current = newValue
        }
    }
    @MainActor
    static var _current: InterfaceStyle?
    
    enum ColorScheme {
        case light
        case dark
    }
    enum Scale {
        case standard
        case hiDPI
        init(displayScale: Float) {
            self = displayScale >= 1.5 ? .hiDPI : .standard
        }
    }
    let scheme: ColorScheme
    let scale: Scale
    var icons: [IconKey:TextureHandle]
    
    init(scheme: ColorScheme = .dark, scale: Scale = .standard) {
        self.scheme = scheme
        self.scale = scale
        self.icons = [:]
    }
    @MainActor
    func texture(forIcon iconKey: IconKey) -> TextureHandle {
        if let texture = icons[iconKey] {
            return texture
        }
        let schemeDir: String = switch scheme {
        case .light: "black"
        case .dark: "white"
        }
        let manager = ResourceManager.shared
        let path = "icons/" + schemeDir + "/" + iconKey.name + ".png"
        let texture = manager.loadTexture(path)
        return texture
    }
}
