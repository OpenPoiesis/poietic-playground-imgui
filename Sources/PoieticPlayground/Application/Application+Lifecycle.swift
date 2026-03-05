//
//  Application+Lifecycle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import CIimgui

extension Application {
    func run() {
        loadResources()
        
        self.settingsPanel.bind(self)
        self.controlBar.bind(self)
        self.toolBar.bind(self)
        self.toolBar.currentTool = canvasTools[0]

        // New template design
        let templateURL = ResourceManager.shared.resourceURL(Self.NewDesignTemplatePath)
        do {
            try self.openDesign(url: templateURL)
        }
        catch {
            self.alert(title: "Error", message: "Unable to open template design '\(templateURL)'. Reason: \(error)")
            self.newDesign()
        }
        
        mainLoop()
    }

    func mainLoop() {
        let backend = GraphicsBackend.shared
        var lastTime = ImGui.GetTime()
        
        loop: while !quitRequested {
            switch backend.pollEvent() {
            case .quit: break loop
            case .skip: continue
            case .none: break
            }
            
            ImGui_ImplSDLGPU3_NewFrame()
            ImGui_ImplSDL3_NewFrame()
            ImGui.NewFrame()
            
            let newTime = ImGui.GetTime()
            let timeDelta = newTime - lastTime
            lastTime = newTime
            
            self.processInput()
            self.update(timeDelta)
            self.draw()
            self.processUnhandledInput()
            
            // BEGIN Debug
            applicationSessionDebugWindow()
            ImGui.ShowDebugLogWindow()
            ImGui.ShowIDStackToolWindow()
            ImGui.ShowDemoWindow()
            // END Debug
            
            ImGui.Render()
            backend.render()
        }
    }
    func processInput() {
        if let actionName = globalShortcutAction() {
            self.handleAction(actionName)
        }
    }
    
    func update(_ timeDelta: Double) {
        guard let session else {
            logError("No session!")
            return
        }
        // Update UI components
        inspector.update(timeDelta)
        toolBar.update(timeDelta)
        alertPanel.update(timeDelta)
        issuesPanel.update(timeDelta)
        controlBar.update(timeDelta)

        if player.isRunning {
            player.update(timeDelta)
        }
        
        // Run the Command Queue
        while !session.commandQueue.isEmpty {
            let command = session.commandQueue.removeFirst()
            self.runCommand(command, session: session)
        }
        
        do {
            try session.consumeAndAcceptTransaction()
        }
        catch {
            // This is not user's fault and never should be.
            // The application failed to make sure structural integrity is assured
            Application.shared.alert(title: "Frame validation error (report to developers)", message: String(describing: error))
            return
        }
    }
    
    func draw() {
        mainMenu()
        settingsPanel.draw()
        inspector.draw()
        toolBar.draw()
        canvas.draw()
        alertPanel.draw()
        issuesPanel.draw()
        controlBar.draw()
    }
    
    func processUnhandledInput() {
        let io = ImGui.GetIO().pointee
        
        if let currentTool {
            let events = canvas.recognizeEvents(io)
            for event in events {
                currentTool.handleEvent(event)
            }
        }
    }
}
