//
//  InlineEditorManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 24/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming

@MainActor
class InlineEditorManager {
    weak var canvas: DiagramCanvas?
    weak var document: Document?
    
    private var editors: [String:InlineEditor] = [:]
    private(set) var currentEditor: (InlineEditor)? = nil
    private(set) var currentEntity: RuntimeEntity? = nil
    
    func register(name: String, editor: InlineEditor) {
        self.editors[name] = editor
    }
    
    func bind(document: Document, canvas: DiagramCanvas) {
        self.document = document
        self.canvas = canvas
    }
    
    func openEditor(_ editorName: String,
                    for entity: RuntimeEntity) {
        print("--- Open inline editor '\(editorName)' for \(entity) requested")
        close()
        
        guard let editor = editors[editorName],
              let document,
              let canvas
        else { return }
        
        let rect = editor.preferredBox(for: entity)
        editor.bind(canvas: canvas, document: document)
        
        if editor.open(for: entity) {
            currentEditor = editor
            currentEntity = entity
        }
    }

    func close() {
        guard let currentEditor else { return }
        currentEditor.close()
        self.currentEditor = nil
        self.currentEntity = nil
    }
    
    func draw() {
        guard let editor = currentEditor else { return }
        
        if editor.draw() {
            close()
        }
    }
}

@MainActor
class InlineEditor {
    weak var canvas: DiagramCanvas?
    weak var document: Document?

    final func bind(canvas: DiagramCanvas, document: Document) {
        self.document = document
        self.canvas = canvas
    }

    func open(for entity: RuntimeEntity) -> Bool {
        // Subclasses should override this.
        return false
    }
    /// Draw the editor and return `true` when finished (should be closed).
    func draw() -> Bool { return true }
    func close() { /* nothing */ }
}

extension InlineEditor {
    /// Get an empty box at design object's position, if present.
    func preferredBox(for entity: RuntimeEntity) -> Rect2D? {
        guard let object = entity.designObject,
              let position = object.position
        else { return nil }
        return Rect2D(origin: position, size: .zero)
    }
}

//class FormulaInlineEditor: InlineEditor {
//    func bind(_ document: Session) {}
//    func open(for objectID: ObjectID) -> Bool { false }
//    func close() {}
//    func draw() -> Bool { false }
//}
//
