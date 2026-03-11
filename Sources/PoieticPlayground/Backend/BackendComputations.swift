//
//  BackendComputations.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

#if false
/// Convert pre-multiplied RGBA to straight values (un-premultiplied)
///
/// - Note: The Cairo surface `CAIRO_FORMAT_ARGB32` has pre-multiplied alpha, however the SDL3 ImGUI
///   backend uses straight non-premultiplied alpha. We need to revert the pre-multiplication.
///
func convertPremultipliedToStraight(from source: UnsafeRawPointer,
                                    to destination: UnsafeMutableRawPointer,
                                    pixelCount: Int)
{
    var srcPtr = source.assumingMemoryBound(to: SIMD4<UInt8>.self)
    var dstPtr = destination.assumingMemoryBound(to: SIMD4<UInt8>.self)
    let endPtr = srcPtr + pixelCount
    
    while srcPtr < endPtr {
        dstPtr.pointee = unpremultiplyPixel(srcPtr.pointee)
        srcPtr += 1
        dstPtr += 1
    }
}

@inline(__always)
func unpremultiplyPixel(_ pixel: SIMD4<UInt8>) -> SIMD4<UInt8> {
    let a = pixel[3]
    
    switch a {
    case 0:
        return SIMD4<UInt8>(0, 0, 0, 0)
    case 255:
        return pixel
    default:
        // Integer math for better performance and accuracy
        let r = (UInt16(pixel[0]) * 255 + UInt16(a/2)) / UInt16(a)
        let g = (UInt16(pixel[1]) * 255 + UInt16(a/2)) / UInt16(a)
        let b = (UInt16(pixel[2]) * 255 + UInt16(a/2)) / UInt16(a)
        
        return SIMD4<UInt8>(
            UInt8(min(r, 255)),
            UInt8(min(g, 255)),
            UInt8(min(b, 255)),
            a
        )
    }
}
#endif

// NOTE: The following code was written by a machine.

/// Precomputed table for unpremultiplication.
/// We store the value (255 << 16) / alpha.
/// By using 16.16 fixed-point math, we can replace division with multiplication.
private let unpremultiplyLUT: [UInt32] = {
    var table = [UInt32](repeating: 0, count: 256)
    
    // Alpha 0 is undefined for division, but we treat it as 0 result (black)
    table[0] = 0
    
    for a in 1...255 {
        // We calculate (255 / a) in fixed point 16.16 format.
        // (255 << 16) is 16711680.
        // We add 1 to handle integer division truncation bias.
        table[a] = (16711680 / UInt32(a)) + 1
    }
    
    return table
}()

/// Convert pre-multiplied RGBA to straight values (Optimized)
///
/// - Note: Uses a Lookup Table (LUT) to replace division with multiplication
///   and processes 4 pixels (SIMD16) at a time to reduce loop overhead.
///
func convertPremultipliedToStraight(from source: UnsafeRawPointer,
                                    to destination: UnsafeMutableRawPointer,
                                    pixelCount: Int)
{
    // Bind memory to SIMD16 (which holds 4 pixels of RGBA: 16 bytes)
    var srcPtr = source.assumingMemoryBound(to: SIMD16<UInt8>.self)
    var dstPtr = destination.assumingMemoryBound(to: SIMD16<UInt8>.self)
    
    // We process 4 pixels at a time
    let iterations = pixelCount / 4
    let remainder = pixelCount % 4
    
    var i = 0
    while i < iterations {
        i += 1
        let chunk = srcPtr.pointee
        
        // Convert the SIMD16 chunk to a tuple of 4 SIMD4 pixels to process them
        let pixels: (SIMD4<UInt8>, SIMD4<UInt8>, SIMD4<UInt8>, SIMD4<UInt8>) = (
            SIMD4(chunk[0], chunk[1], chunk[2], chunk[3]),
            SIMD4(chunk[4], chunk[5], chunk[6], chunk[7]),
            SIMD4(chunk[8], chunk[9], chunk[10], chunk[11]),
            SIMD4(chunk[12], chunk[13], chunk[14], chunk[15])
        )
        
        // Optimized processing for 4 pixels
        // Doing this inline avoids the function call overhead of unpremultiplyPixel
        let processed = (
            unpremultiplyPixelLUT(pixels.0),
            unpremultiplyPixelLUT(pixels.1),
            unpremultiplyPixelLUT(pixels.2),
            unpremultiplyPixelLUT(pixels.3)
        )
        
        // Reassemble into SIMD16
        dstPtr.pointee = SIMD16<UInt8>(
            processed.0[0], processed.0[1], processed.0[2], processed.0[3],
            processed.1[0], processed.1[1], processed.1[2], processed.1[3],
            processed.2[0], processed.2[1], processed.2[2], processed.2[3],
            processed.3[0], processed.3[1], processed.3[2], processed.3[3]
        )
        
        srcPtr += 1
        dstPtr += 1
    }
    
    // Handle remaining pixels (if pixelCount is not divisible by 4)
    if remainder > 0 {
        let tailSrc = UnsafeRawPointer(srcPtr)
        let tailDst = UnsafeMutableRawPointer(dstPtr)

        for i in 0..<remainder {
            let p = tailSrc.load(fromByteOffset: i * 4, as: SIMD4<UInt8>.self)
            let result = unpremultiplyPixelLUT(p)
            tailDst.storeBytes(of: result, toByteOffset: i * 4, as: SIMD4<UInt8>.self)
        }
    }
}

/// Helper function using the LUT
@inline(__always)
func unpremultiplyPixelLUT(_ pixel: SIMD4<UInt8>) -> SIMD4<UInt8> {
    let a = pixel[3]
    
    // Fast check for alpha 0 and 255
    // This is a branch, but it only triggers on solid black or fully opaque pixels,
    // and it saves a LUT lookup/multiplication for those very common cases.
    if a == 0 { return .zero }
    if a == 255 { return pixel }
    
    // Look up the precomputed multiplier
    let factor = unpremultiplyLUT[Int(a)]
    
    // The formula (val * 255) / a is equivalent to (val * factor) >> 16
    // We add (1 << 15) (which is 32768) to handle rounding.
    
    let r = (UInt32(pixel[0]) * factor + 32768) >> 16
    let g = (UInt32(pixel[1]) * factor + 32768) >> 16
    let b = (UInt32(pixel[2]) * factor + 32768) >> 16
    
    return SIMD4<UInt8>(UInt8(r), UInt8(g), UInt8(b), a)
}
