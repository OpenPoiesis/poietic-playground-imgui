//
//  SDL+extensions.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 26/01/2026.
//
import Csdl3

// NOTE: This is from SDL.h where it is defined as #define

extension SDL_WindowFlags {
    static let SDL_WINDOW_FULLSCREEN: UInt64 =           0x0000000000000001    /**< window is in fullscreen mode */
    static let SDL_WINDOW_OPENGL: UInt64 =               0x0000000000000002    /**< window usable with OpenGL context */
    static let SDL_WINDOW_OCCLUDED: UInt64 =             0x0000000000000004    /**< window is occluded */
    static let SDL_WINDOW_HIDDEN: UInt64 =               0x0000000000000008    /**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
    static let SDL_WINDOW_BORDERLESS: UInt64 =           0x0000000000000010    /**< no window decoration */
    static let SDL_WINDOW_RESIZABLE: UInt64 =            0x0000000000000020    /**< window can be resized */
    static let SDL_WINDOW_MINIMIZED: UInt64 =            0x0000000000000040    /**< window is minimized */
    static let SDL_WINDOW_MAXIMIZED: UInt64 =            0x0000000000000080    /**< window is maximized */
    static let SDL_WINDOW_MOUSE_GRABBED: UInt64 =        0x0000000000000100    /**< window has grabbed mouse input */
    static let SDL_WINDOW_INPUT_FOCUS: UInt64 =          0x0000000000000200    /**< window has input focus */
    static let SDL_WINDOW_MOUSE_FOCUS: UInt64 =          0x0000000000000400    /**< window has mouse focus */
    static let SDL_WINDOW_EXTERNAL: UInt64 =             0x0000000000000800    /**< window not created by SDL */
    static let SDL_WINDOW_MODAL: UInt64 =                0x0000000000001000    /**< window is modal */
    static let SDL_WINDOW_HIGH_PIXEL_DENSITY: UInt64 =   0x0000000000002000    /**< window uses high pixel density back buffer if possible */
    static let SDL_WINDOW_MOUSE_CAPTURE: UInt64 =        0x0000000000004000    /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
    static let SDL_WINDOW_MOUSE_RELATIVE_MODE: UInt64 =  0x0000000000008000    /**< window has relative mode enabled */
    static let SDL_WINDOW_ALWAYS_ON_TOP: UInt64 =        0x0000000000010000    /**< window should always be above others */
    static let SDL_WINDOW_UTILITY: UInt64 =              0x0000000000020000    /**< window should be treated as a utility window, not showing in the task bar and window list */
    static let SDL_WINDOW_TOOLTIP: UInt64 =              0x0000000000040000    /**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
    static let SDL_WINDOW_POPUP_MENU: UInt64 =           0x0000000000080000    /**< window should be treated as a popup menu, requires a parent window */
    static let SDL_WINDOW_KEYBOARD_GRABBED: UInt64 =     0x0000000000100000    /**< window has grabbed keyboard input */
    static let SDL_WINDOW_FILL_DOCUMENT: UInt64 =        0x0000000000200000    /**< window is in fill-document mode (Emscripten only), since SDL 3.4.0 */
    static let SDL_WINDOW_VULKAN: UInt64 =               0x0000000010000000    /**< window usable for Vulkan surface */
    static let SDL_WINDOW_METAL: UInt64 =                0x0000000020000000    /**< window usable for Metal view */
    static let SDL_WINDOW_TRANSPARENT: UInt64 =          0x0000000040000000    /**< window with transparent buffer */
    static let SDL_WINDOW_NOT_FOCUSABLE: UInt64 =        0x0000000080000000    /**< window should not be focusable */
}

extension SDL_GPUShaderFormat {
    static let SDL_GPU_SHADERFORMAT_INVALID: UInt32 =  0
    static let SDL_GPU_SHADERFORMAT_PRIVATE: UInt32 =  (1 << 0) /**< Shaders for NDA'd platforms. */
    static let SDL_GPU_SHADERFORMAT_SPIRV: UInt32 =    (1 << 1) /**< SPIR-V shaders for Vulkan. */
    static let SDL_GPU_SHADERFORMAT_DXBC: UInt32 =     (1 << 2) /**< DXBC SM5_1 shaders for D3D12. */
    static let SDL_GPU_SHADERFORMAT_DXIL: UInt32 =     (1 << 3) /**< DXIL SM6_0 shaders for D3D12. */
    static let SDL_GPU_SHADERFORMAT_MSL: UInt32 =      (1 << 4) /**< MSL shaders for Metal. */
    static let SDL_GPU_SHADERFORMAT_METALLIB: UInt32 = (1 << 5) /**< Precompiled metallib shaders for Metal. */

}
