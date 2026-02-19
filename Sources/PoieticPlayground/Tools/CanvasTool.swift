//
//  CanvasTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 26/01/2026.
//
import CIimgui
import Diagramming
import PoieticCore



/// Abstract class for canvas tools.
///
/// Subclasses should implement:
///
/// - Input handling: ``inputBegan(_:in:)``, ``inputMoved(_:in:)``, ``inputEnded(_:in:)``.
/// - Optional activation/deactivation with ``activate()``, ``deactivate()``.
/// - Internal tool state management.
///
@MainActor
class CanvasTool {
    weak var canvas: DiagramCanvas?
    weak var session: Session?
    internal var world: World {
        guard let session else { fatalError("CanvasTool used before binding")}
        return session.world
    }
    
    var hasObjectPalette: Bool { false }
    var name: String { "default"}
    var iconKey: IconKey { .empty }
    
    /// Called before tool activation.
    final func bind(canvas: DiagramCanvas, session: Session) {
        self.session = session
        self.canvas = canvas
    }

    func drawPalette() { }
    
    /// Function called when tool was set active.
    func activate() { /* Implementation in subclasses */ }

    /// Function called when tool was released and set inactive.
    func deactivate() { /* Implementation in subclasses */ }

    /// Function called on frame update when the tool is active.
    func update() { /* Implementation in subclasses */ }

    /// Function called when tool operation was cancelled.
    func cancel() { /* Implementation in subclasses */ }

    // func renderOverlay()
    // func getCursorType()
   
    func handleEvent(_ event: ToolEvent) {
//        print("Tool event: \(event)")
    }
}
