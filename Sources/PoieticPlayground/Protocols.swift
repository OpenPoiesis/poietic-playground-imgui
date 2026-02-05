//
//  Protocols.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//
import CIimgui

protocol ApplicationObject {
    func update(_ timeDelta: Double)
}

protocol View: ApplicationObject {
    func draw()
}

protocol Controller: ApplicationObject {
    func processInput(_ io: ImGuiIO)
}
extension Controller {
    func processInput(_ io: ImGuiIO) {}
}

protocol Panel: View {
}
