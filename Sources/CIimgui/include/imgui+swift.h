//
//  imgui+swift_extensions.h
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

#include "imgui.h"
#include "imgui_impl_sdl3gpu3+Pipeline.h"
namespace ImGui {
    IMGUI_API void TextWrappedUnformatted(const char* text);
    const ImDrawCallback ImDrawCallback_ResetRenderState_D = ImDrawCallback_ResetRenderState;
}
