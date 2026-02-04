//
//  ResourceLoader.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui
import Cstb
import Csdl3
import Foundation

class ResourceLoader {
    let root: URL
    let app: Application
    
    init(_ rootPath: String, application: Application) {
        self.root = URL(fileURLWithPath: rootPath)
        self.app = application
    }
    func load(_ filename: String) {
        var fullPath = self.root.path + "/" + filename
        let manager = FileManager()
        print("CWD: \(manager.currentDirectoryPath)")
        let url = URL(fileURLWithPath: fullPath)
        let data = try? Data(contentsOf: url)
        print("Data: \(data, default: "(no data))")")

        var width: Int32 = 0
        var height: Int32 = 0
        var channels: Int32 = 0
        guard let imageData = stbi_load(fullPath, &width, &height, &channels, 4) else {
            print("Failed to load image: \(fullPath)")
            return
        }
        print("Image data: \(imageData)")

    }
    func resourceURL(_ resourcePath: String) -> URL {
        return root.appending(path: resourcePath)
    }
    
    func loadTexture(_ path: String) -> Texture? {
        let url = resourceURL(path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return loadTexture(data)
    }
    
    func loadTexture(_ data: Data) -> Texture? {
        var imageWidth: UInt32 = 0
        var imageHeight: UInt32 = 0
        var channels: Int32 = 0
        let dataSize = Int32(data.count)
        let imageData: UnsafeMutablePointer<stbi_uc>? = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: stbi_uc.self) else {
                return nil
            }

            return stbi_load_from_memory(pointer, dataSize, &imageWidth, &imageHeight, &channels, 4)
        }
        guard let imageData else { return nil }

        // Create texture
        var textureInfo: SDL_GPUTextureCreateInfo = SDL_GPUTextureCreateInfo()
        textureInfo.type = SDL_GPU_TEXTURETYPE_2D
        textureInfo.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM
        textureInfo.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER
        textureInfo.width = imageWidth
        textureInfo.height = imageHeight
        textureInfo.layer_count_or_depth = 1
        textureInfo.num_levels = 1
        textureInfo.sample_count = SDL_GPU_SAMPLECOUNT_1

        guard let texture = SDL_CreateGPUTexture(app.gpuDevice, &textureInfo) else {
            return nil
        }

        // Track if we succeed; if not, release the texture before returning.
        var uploadSuccess = false
        defer {
            if !uploadSuccess {
                SDL_ReleaseGPUTexture(app.gpuDevice, texture)
            }
        }

        // 3. Create transfer buffer
        var transferBufferInfo = SDL_GPUTransferBufferCreateInfo()
        transferBufferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
        transferBufferInfo.size = UInt32(imageWidth * imageHeight * 4)
        
        guard let transferBuffer = SDL_CreateGPUTransferBuffer(app.gpuDevice, &transferBufferInfo) else {
            return nil
        }

        
        var transferbuffer_info = SDL_GPUTransferBufferCreateInfo();
        transferbuffer_info.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
        transferbuffer_info.size = imageWidth * imageHeight * 4

        // Ensure the transfer buffer is released after the upload cycle
        defer {
            SDL_ReleaseGPUTransferBuffer(app.gpuDevice, transferBuffer)
        }

        // 4. Copy to transfer buffer
        let uploadPitch = Int(imageWidth * 4)
        
        guard let texturePtr = SDL_MapGPUTransferBuffer(app.gpuDevice, transferBuffer, true) else {
            return nil
        }

        // Perform the row-by-row copy
        // We bind the void* from stb to a raw pointer to perform arithmetic
        let rawImageData = UnsafeRawPointer(imageData)
        
        for y in 0..<Int(imageHeight) {
            let offset = y * uploadPitch
            
            // Calculate destination and source pointers for this row
            let destRow = texturePtr.advanced(by: offset)
            let srcRow = rawImageData.advanced(by: offset)
            
            // Swift's version of memcpy: copyMemory(from: byteCount:)
            // This is safer than the C-style cast + pointer arithmetic used in the original.
            destRow.copyMemory(from: srcRow, byteCount: uploadPitch)
        }
        
        SDL_UnmapGPUTransferBuffer(app.gpuDevice, transferBuffer)
        // 5. Upload
        var transferInfo = SDL_GPUTextureTransferInfo()
        transferInfo.offset = 0
        transferInfo.transfer_buffer = transferBuffer
        
        var textureRegion = SDL_GPUTextureRegion()
        textureRegion.texture = texture
        textureRegion.x = 0
        textureRegion.y = 0
        textureRegion.w = UInt32(imageWidth)
        textureRegion.h = UInt32(imageHeight)
        textureRegion.d = 1
        
        // Acquire command buffer and execute copy
        guard let cmd = SDL_AcquireGPUCommandBuffer(app.gpuDevice) else { return nil }
        
        guard let copyPass = SDL_BeginGPUCopyPass(cmd) else {
            // If we fail to begin the pass, we must submit the buffer to release it
            SDL_SubmitGPUCommandBuffer(cmd)
            return nil
        }
        
        SDL_UploadToGPUTexture(copyPass, &transferInfo, &textureRegion, false)
        SDL_EndGPUCopyPass(copyPass)
        SDL_SubmitGPUCommandBuffer(cmd)
        
        // 6. Finalize
        assert(MemoryLayout<ImTextureID>.size == MemoryLayout<OpaquePointer>.size)
        let textureID = unsafeBitCast(texture, to: ImTextureID.self)
        let result = Texture(width: imageWidth, height: imageHeight, textureID: textureID)
        
        uploadSuccess = true

        return result
    }
}
