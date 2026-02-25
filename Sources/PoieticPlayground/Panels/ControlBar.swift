//
//  ControlBar.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//

import CIimgui
import PoieticFlows

@MainActor
class ControlBar: @MainActor Panel {
    static let ButtonSize = ImVec2(32, 32)
    static let ButtonGroupOffset: Float = 20.0
    static let StepDisplayWidth: Float = 100.0
    
    var isEnabled: Bool = true
    var isVisible: Bool = true
    var currentStep: Int32 = 0
    var currentTime: Double = 0.0
    
    var settings: SimulationSettings = SimulationSettings()

    var currentStepBuffer: InputTextBuffer
    
    internal weak var app: Application? = nil
    
    init() {
        currentStepBuffer = InputTextBuffer("0")
    }

    func bind(_ application: Application) {
        self.app = application
    }
   
    func onDesignFrameChanged(_ session: Session) {
        guard let frame = session.world.frame
        else { return }
        
        if let infoObject = frame.first(type: .Simulation) {
            self.settings = SimulationSettings(fromObject: infoObject)
            print("GOT SETTINGS: \(settings)")
        }
        else {
            print("NEW SETTINGS: \(settings)")
            self.settings = SimulationSettings()
        }
        
        if currentStep >= settings.steps {
            currentStep = Int32(settings.steps)
        }
        self.currentTime = Double(currentStep) * settings.timeDelta

    }
    
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        let style = InterfaceStyle.current

        ImGui.Begin("Simulation", &isVisible,
                                        ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse
                                        | ImGuiWindowFlags_AlwaysAutoResize)
        ImGui.BeginDisabled(!isEnabled)
        drawControlButtons()
        drawStepDisplay()
        drawTimeDisplay()

        ImGui.PushItemWidth(ImGui.GetContentRegionAvail().x)
        let flags: ImGuiInputTextFlags = 0
        ImGui.SliderInt("##current_step_slider", &currentStep, 0, Int32(settings.steps), "")

        ImGui.EndDisabled()
        ImGui.End()
    }
    
    func drawControlButtons() {
        
        ImGui.BeginGroup()
        var flag: Bool = true
        if controlButton("Run", iconKey: .run, isEnabled: &flag) {
            
        }
        ImGui.SameLine()
        if controlButton("Stop", iconKey: .stop, isEnabled: &flag) {
            
        }
        ImGui.SameLine(0, Self.ButtonGroupOffset)
//        ImGui.Separator()
//        ImGui.SameLine()

        if controlButton("Previous", iconKey: .previousStep, isEnabled: &flag) {
            
        }
        ImGui.SameLine()
        if controlButton("Next", iconKey: .nextStep, isEnabled: &flag) {
            
        }
        ImGui.SameLine()
        if controlButton("Last", iconKey: .lastStep, isEnabled: &flag) {
            
        }
        ImGui.SameLine()
        ImGui.SameLine(0, Self.ButtonGroupOffset)
//        ImGui.Separator()
//        ImGui.SameLine()
        if controlButton("Loop", iconKey: .loop, isEnabled: &flag) {
            
        }

        ImGui.EndGroup()
        

    }
    func drawStepDisplay() {
        let inputFlags: ImGuiInputTextFlags = ImGuiInputTextFlags_None
                            | ImGuiInputTextFlags_CharsDecimal
                            | ImGuiInputTextFlags_CharsNoBlank

        let imStyle = ImGui.GetStyle().pointee
        let titleFontSize = imStyle.FontSizeBase * 2
        ImGui.SameLine()
        ImGui.BeginGroup()
        ImGui.PushFont(nil, titleFontSize)
        ImGui.SetNextItemWidth(Self.StepDisplayWidth)
        ImGui.InputInt("##current_step", &currentStep, 0, 0, 0)
//        ImGui.InputText("##boo", buffer: currentStepBuffer, flags: inputFlags)
        ImGui.PopFont()
        ImGui.TextUnformatted("step")
        ImGui.EndGroup()
    }
    
    func drawTimeDisplay() {
        let inputFlags: ImGuiInputTextFlags = ImGuiInputTextFlags_None
                            | ImGuiInputTextFlags_CharsDecimal
                            | ImGuiInputTextFlags_CharsNoBlank

        let imStyle = ImGui.GetStyle().pointee
        let titleFontSize = imStyle.FontSizeBase * 2
        ImGui.SameLine()
        ImGui.BeginGroup()
        ImGui.PushFont(nil, titleFontSize)
        ImGui.SetNextItemWidth(Self.StepDisplayWidth)
        ImGui.InputDouble("##current_time", &currentTime, 0, 0, "%0.2f")
//        ImGui.InputText("##boo", buffer: currentStepBuffer, flags: inputFlags)
        ImGui.PopFont()
        ImGui.TextUnformatted("time")
        ImGui.EndGroup()
    }

    func controlButton(_ label: String, iconKey: IconKey, isEnabled: inout Bool) -> Bool {
        let style = InterfaceStyle.current
        let result: Bool

        let icon = style.texture(forIcon: iconKey)

        result = ImGui.ImageButton(label, icon.imTextureRef, Self.ButtonSize, ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0), ImVec4(1, 1, 1, 1))
            
        if ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue)) {
            ImGui.BeginTooltip()
            ImGui.TextUnformatted(label)
            ImGui.EndTooltip()
        }
        return result
    }
}
