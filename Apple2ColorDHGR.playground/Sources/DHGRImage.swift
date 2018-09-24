/*
 An instance of this class will convert the data passed into a 24-bit RGB raw bitmap.
 The caller can access the instantiated CGImage object through its "cgImage" property.
 */

import Cocoa
import PlaygroundSupport

public class DHGRConverter {
    public var cgImage: CGImage?

    var baseOffsets = [Int](repeating:0, count:192)

    func generateBaseOffsets() {
        var groupOfEight, lineOfEight, groupOfSixtyFour: Int

        // Both HGR and DHGR graphics have 192 vertical lines.
        // The screen lines of both types of graphics also have the same starting base offsets.
        for line in 0..<192 {
            lineOfEight = line % 8              // 8 lines
            groupOfEight = (line % 64) / 8      // 8 groups of 8 lines
            groupOfSixtyFour = line / 64        // 3 groups of 64 lines

            baseOffsets[line] = lineOfEight * 0x0400 + groupOfEight * 0x0080 + groupOfSixtyFour * 0x0028
        }
    /*
        for line in 0..<192 {
            let baseStr = String(format: "%04x", baseOffsets[line])
            print("\(line) $:\(baseStr)")
        }
    */
    }
    
    func reverseBits(_ bitPattern: UInt8) -> UInt8 {
        var newValue:UInt8 = 0
        for i:UInt8 in 0..<8 {
            if bitPattern & (1 << i) != 0 {
                newValue |= (1 << (7-i))
            }
        }
        newValue >>= 4
        return newValue
    }

    struct Pixel {
        var r: UInt8
        var g: UInt8
        var b: UInt8
    }

    let colorValues: [UInt8] = [
        0, 0, 0,        // 0 - Black
        206, 15, 49,    // 1 - Magenta      0x72, 0x26, 0x06 Deep Red
        156, 99, 1,     // 2 - Brown        0x40, 0x4C, 0x04
        255, 70, 0,     // 3 - Orange       0xE4, 0x65, 0x01
        0, 99, 49,      // 4 - Dark Green   0x0E, 0x59, 0x40
        82, 82, 82,     // 5 - Gray         0x80, 0x80, 0x80
        0, 221, 2,      // 6 - Green        0x1B, 0xCB, 0x01
        255, 253, 4,    // 7 - Yellow       0xBF, 0xCC, 0x80
        2, 19, 156,     // 8 - Dark Blue    0x40, 0x33, 0x7F
        206, 49, 206,   // 9 - Violet       0xE4, 0x34, 0xFE Purple
        173, 173, 173,  // A - Grey         0x80, 0x80, 0x80
        255, 156, 156,  // B - Pink         0xF1, 0xA6, 0xBF
        49, 49, 255,    // C - Blue         0x1B, 0x9A, 0xFE
        99, 156, 255,   // D - Light Blue   0xBF, 0xB3, 0xFF
        49, 253, 156,   // E - Aqua         0x8D, 0xD9, 0xBF
        255, 255, 255]  // F - White        0xFF, 0xFF, 0xFF

    var colorTable = [Pixel]()

    public init(data srcData: Data) {
        // Prepare the color table as an array of 16 RGB color entries for easier access.
        for i in stride(from: 0, to: 48, by: 3) {
            let color = Pixel(r: colorValues[i+0],
                              g: colorValues[i+1],
                              b: colorValues[i+2])
            colorTable.append(color)
        }
        generateBaseOffsets()

        // We assume the A2FC file is saved as 2 separate blobs of data
        // The data from aux bank ($2000-$3FFFF) is saved first
        // followed by data from the main bank ($2000-$3FFFF)
        let bir = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: 560,
                                   pixelsHigh: 384,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 3,
                                   hasAlpha: false,
                                   isPlanar: false,
                                   colorSpaceName: NSDeviceRGBColorSpace,
                                   bytesPerRow: 560 * 3,    // 1680 bytes
                                   bitsPerPixel: 24)

        // Get the pointer to the memory allocated.
        // The size of the memory block should be 560x3x384 bytes.
        let bm = bir?.bitmapData
        for row in 0..<192 {
            let lineOffset = baseOffsets[row]
            var srcPixels = [Pixel](repeating:Pixel(r: 0, g: 0, b: 0), count: 140)
            var pixelIndex = 0
            var destPixels = [Pixel](repeating:Pixel(r: 0, g: 0, b: 0), count: 560)

            // Each time thru the loop below, 4 bytes are consumed to produce 7 RGB pixels.
            // Since the loop executes 20 times, a total of 7x20=140 RGB pixels are produced
            // for every screen line of data.
            for col in stride(from: 0, to: 40, by: 2) {
                // Extract 2 bytes from Auxiliary bank & 2 from the Main bank.
                let aux0 = (srcData[lineOffset+col+0])
                let aux1 = (srcData[lineOffset+col+1])
                let main0 = (srcData[0x2000+lineOffset+col+0])
                let main1 = (srcData[0x2000+lineOffset+col+1])

                var bitPatterns = [UInt8](repeating: 0x00, count: 7)
 
                // Compute seven (4-bit) patterns from the 4 bytes.
                bitPatterns[0] = aux0 &  0x0f
                bitPatterns[1] = ((main0 & 0x01) << 3) | ((aux0 & 0x70) >> 4)
                bitPatterns[2] = ((main0 & 0x1E) >> 1)
                bitPatterns[3] = ((aux1 & 0x03) << 2) | ((main0 & 0x60) >> 5)
                bitPatterns[4] = ((aux1 & 0x3C) >> 2)
                bitPatterns[5] = ((main1 & 0x07) << 1) | ((aux1 & 0x40) >> 6)
                bitPatterns[6] = ((main1 & 0x78) >> 3)

                // Use the bit patterns to index the color table and obtain 7 RGB pixels.
                for i in 0..<7 {
                    let colorPixel = colorTable[Int(reverseBits(bitPatterns[i]))]
                    srcPixels[pixelIndex] = colorPixel
                    pixelIndex += 1
                }
            } // col

            // When we reach here, the 560 bits have been converted into a row of 140 RGB pixels.
            // Proceed convert the row into one with 560 RGB pixels.
            // Each color pixel is quadruple in size.
            for k in 0..<140 {
                let pixel = srcPixels[k]
                destPixels[4*k+0] = pixel
                destPixels[4*k+1] = pixel
                destPixels[4*k+2] = pixel
                destPixels[4*k+3] = pixel
            } // k

            // Double the number of rows.
            let evenIndex = 2 * row * 560 * 3
            let oddIndex = (2 * row + 1) * 560 * 3
            for k in 0..<560 {
                let pixel = destPixels[k]
                bm?[evenIndex+3*k+0] = pixel.r
                bm?[evenIndex+3*k+1] = pixel.g
                bm?[evenIndex+3*k+2] = pixel.b
                bm?[ oddIndex+3*k+0] = pixel.r
                bm?[ oddIndex+3*k+1] = pixel.g
                bm?[ oddIndex+3*k+2] = pixel.b
            }  // k
        } // row
        cgImage = bir?.cgImage
    }
}
