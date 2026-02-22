//
//  imgui+swift_extensions.h
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

#include "imgui.h"
#include "imgui+swift.h"

void ImGui::TextWrappedUnformatted(const char* text) {
    TextWrapped("%s", text);
}
