//
//  FilePickerPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/03/2026.
//

import CIimgui
import Cimguifd

class FilePickerPanel {
    enum Mode {
        case open
        case save
        case directory

        var asFDMode: ImGuiFDMode {
            switch self {
            case .open: ImGuiFDMode(ImGuiFDMode_LoadFile)
            case .save: ImGuiFDMode(ImGuiFDMode_SaveFile)
            case .directory: ImGuiFDMode(ImGuiFDMode_OpenDir)
            }
        }
    }
    
    var isOpen: Bool = false
    var mode: Mode = .save
    var callback: ((String) -> Void)? = nil

    func open(mode: Mode, filter: String? = nil, _ callback: @escaping ((String) -> Void)) {
        let path = "."
        
        self.callback = callback
        ImGuiFD.OpenDialog("Choose Dir",
                           mode.asFDMode,
                           path,
                           filter,
                           ImGuiFDDialogFlags(ImGuiFDDialogFlags_Modal))
        self.isOpen = true
    }
    func draw() {
        guard isOpen else { return }
        
        var pathPtr: UnsafePointer<CChar>? = nil
        var path: String? = nil
        if (ImGuiFD.BeginDialog("Choose Dir")) {
            if (ImGuiFD.ActionDone()) {
                if (ImGuiFD.SelectionMade()) {
                    pathPtr = ImGuiFD.GetSelectionPathString(0)
                }
                if let pathPtr {
                    path = String(cString: pathPtr)
                }
                ImGuiFD.CloseCurrentDialog()
                isOpen = false
            }

            ImGuiFD.EndDialog()
        }
        
        if let path, let callback {
            callback(path)
        }
        
        if !isOpen {
            callback = nil
        }
    }
}
