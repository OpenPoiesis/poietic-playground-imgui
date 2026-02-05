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
class CanvasTool {
    unowned var world: World?
    unowned var canvas: DiagramCanvas?
    
    var name: String { "default"}
    var iconName: String { self.name }
    
    /// Called before tool activation.
    final func bind(world: World, canvas: DiagramCanvas) {
        self.world = world
        self.canvas = canvas
    }

    /// Function called when tool was set active.
    func activate() { /* Implementation in subclasses */ }
    /// Function called when tool was released and set inactive.
    func deactivate() { /* Implementation in subclasses */ }
    /// Function called for frame update.
    func update() { /* Implementation in subclasses */ }
    /// Function called when tool operation was cancelled.
    func cancel() { /* Implementation in subclasses */ }

//    func renderOverlay()
// func getCursorType()
   
    func handleEvent(_ event: ToolEvent) {
        print("Tool event: \(event)")
    }
    // TODO: Implement in subclasses. Just debug stub
    func downBegan(_ event: ToolEvent) {
        print("Tool event: \(event)")
    }
    func inputMoved(_ event: ToolEvent) {
        print("Tool event: \(event)")
    }
    func inputEnded(_ event: ToolEvent) {
        print("Tool event: \(event)")
    }
    func inputBegan(_ event: ToolEvent) {
        print("Tool event: \(event)")
    }
}
