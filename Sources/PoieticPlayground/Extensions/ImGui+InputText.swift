//
//  ImGui+InputText.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/02/2026.
//

import CIimgui

final class InputTextBuffer: ExpressibleByStringLiteral {
    static let InitialInputTextBufferCapacity = 64

    internal private(set) var bufferPointer: UnsafeMutablePointer<UInt8>
    internal private(set) var bufferCapacity: Int

    var callback: ((String) -> Void)?
    var wasModified: Bool = false
    
    convenience init(stringLiteral: String) {
        self.init(stringLiteral)
    }
    
    init(_ string: String, callback: ((String) -> Void)? = nil) {
        self.callback = callback
        
        let capacity = max(string.utf8.count + 1, Self.InitialInputTextBufferCapacity)
        self.bufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        self.bufferCapacity = capacity

        bufferPointer.initialize(repeating: 0, count: capacity)
        
        var contiguousString = string
        contiguousString.withUTF8 { utf8 in
            let safeCount = min(utf8.count, capacity - 1)
            bufferPointer.update(from: utf8.baseAddress!, count: safeCount)
        }
    }
    
    deinit {
        bufferPointer.deallocate()
    }
    
    func resize(_ newSize: Int) {
        let newPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: newSize)
        let copyCount = min(bufferCapacity, newSize)
        newPointer.initialize(from: bufferPointer, count: copyCount)
        
        bufferPointer.deallocate()
        bufferPointer = newPointer
        bufferCapacity = newSize
    }

    func compact() {
        let actualLength = string.utf8.count + 1
        if actualLength < bufferCapacity / 2 {
            resize(actualLength)
        }
    }

    var string: String {
        get {
            // We rely on ImGui to not to write invalid data here and assume the string is properly
            // null-terminated.
            String(cString: bufferPointer)
        }
        set {
            let requiredCapacity = newValue.utf8.count + 1
            if requiredCapacity > bufferCapacity {
                resize(requiredCapacity)
            }

            var contiguousString = newValue
            contiguousString.withUTF8 { utf8 in
                let safeCount = min(utf8.count, bufferCapacity - 1)
                bufferPointer.update(from: utf8.baseAddress!, count: safeCount)
                bufferPointer[safeCount] = 0
            }
        }
    }
    
}

func ImGuiInputTextSwiftCallback(pointer: UnsafeMutablePointer<ImGuiInputTextCallbackData>?) -> Int32 {
    guard var data = pointer?.pointee else { return 0 }

    let unmanaged = Unmanaged<InputTextBuffer>.fromOpaque(data.UserData!)
    let context = unmanaged.takeUnretainedValue()
    
    if (data.EventFlag & Int32(ImGuiInputTextFlags_CallbackResize.rawValue) != 0) {
        let newSize = Int(data.BufSize)
        if newSize > context.bufferCapacity {
            context.resize(newSize)
            data.Buf = UnsafeMutablePointer<CChar>(OpaquePointer(context.bufferPointer))
            pointer?.pointee = data
        }
    }
    
    if (data.EventFlag & Int32(ImGuiInputTextFlags_CallbackEdit.rawValue) != 0) {
        context.wasModified = true
//        context.onChange?(context.buffer.string)
    }
    
    if (data.EventFlag & Int32(ImGuiInputTextFlags_CallbackCompletion.rawValue) != 0) {
        // Tab completion or other features
    }
    return 0
}

extension ImGui {
    static func InputText(_ label: String, buffer: InputTextBuffer) {
        let flags = ImGuiInputTextFlags_CallbackResize.rawValue // TODO: Add more
        
        let unmanaged = Unmanaged.passUnretained(buffer)
        let userData = unmanaged.toOpaque()
        let ccharPointer = UnsafeMutablePointer<CChar>(OpaquePointer(buffer.bufferPointer))
        ImGui.InputText(label, ccharPointer, buffer.bufferCapacity, Int32(flags), ImGuiInputTextSwiftCallback, userData)
    }
}
