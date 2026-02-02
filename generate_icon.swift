#!/usr/bin/swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Icon sizes needed for iOS app
let sizes: [CGFloat] = [
    20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
]

func createWaterBottleIcon(size: CGFloat) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else { return nil }

    // Scale factor for drawing
    let scale = size / 1024.0

    // Fill background with gradient (approximation with solid color)
    context.setFillColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Draw top gradient
    context.setFillColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size * 0.3))

    // Bottle cap
    let capWidth = 180 * scale
    let capHeight = 80 * scale
    let capX = (size - capWidth) / 2
    let capY = 150 * scale
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
    let capRect = CGRect(x: capX, y: capY, width: capWidth, height: capHeight)
    let capPath = CGPath(roundedRect: capRect, cornerWidth: 15 * scale, cornerHeight: 15 * scale, transform: nil)
    context.addPath(capPath)
    context.fillPath()

    // Bottle neck
    let neckWidth = 150 * scale
    let neckHeight = 60 * scale
    let neckX = (size - neckWidth) / 2
    let neckY = capY + capHeight
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
    context.fill(CGRect(x: neckX, y: neckY, width: neckWidth, height: neckHeight))

    // Main bottle body (rounded rectangle)
    let bottleWidth = 400 * scale
    let bottleHeight = 650 * scale
    let bottleX = (size - bottleWidth) / 2
    let bottleY = neckY + neckHeight
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2)
    let bottleRect = CGRect(x: bottleX, y: bottleY, width: bottleWidth, height: bottleHeight)
    let bottlePath = CGPath(roundedRect: bottleRect, cornerWidth: 60 * scale, cornerHeight: 60 * scale, transform: nil)
    context.addPath(bottlePath)
    context.fillPath()

    // Water fill (70% of bottle)
    let waterWidth = 360 * scale
    let waterHeight = 455 * scale
    let waterX = (size - waterWidth) / 2
    let waterY = bottleY + bottleHeight - waterHeight - 15 * scale
    context.setFillColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 0.85)
    let waterRect = CGRect(x: waterX, y: waterY, width: waterWidth, height: waterHeight)
    let waterPath = CGPath(roundedRect: waterRect, cornerWidth: 50 * scale, cornerHeight: 50 * scale, transform: nil)
    context.addPath(waterPath)
    context.fillPath()

    // Highlight on left side
    let highlightWidth = 120 * scale
    let highlightHeight = 300 * scale
    let highlightX = bottleX + 50 * scale
    let highlightY = waterY + 50 * scale
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
    let highlightRect = CGRect(x: highlightX, y: highlightY, width: highlightWidth, height: highlightHeight)
    let highlightPath = CGPath(roundedRect: highlightRect, cornerWidth: 20 * scale, cornerHeight: 20 * scale, transform: nil)
    context.addPath(highlightPath)
    context.fillPath()

    // 70% text
    let fontSize = 140 * scale
    let text = "70%" as CFString
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

    var attributes: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ]

    let attributedString = CFAttributedStringCreate(kCFAllocatorDefault, text, attributes as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributedString)
    let bounds = CTLineGetBoundsWithOptions(line, [])

    let textX = (size - bounds.width) / 2
    let textY = (size - bounds.height) / 2 + 50 * scale

    context.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, context)

    return context.makeImage()
}

func saveIconImage(_ image: CGImage, to url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        print("Failed to create image destination for \(url)")
        return
    }

    CGImageDestinationAddImage(destination, image, nil)

    if !CGImageDestinationFinalize(destination) {
        print("Failed to write image to \(url)")
    } else {
        print("✓ Created: \(url.lastPathComponent)")
    }
}

// Create output directory
let outputPath = "/Users/chathunkurera/HydraTrack/HydraTrack/Assets.xcassets/AppIcon.appiconset"
let outputURL = URL(fileURLWithPath: outputPath)

print("Generating HydraTrack app icons...")
print("Output directory: \(outputPath)\n")

// Generate all icon sizes
for size in sizes {
    if let image = createWaterBottleIcon(size: size) {
        let filename: String
        if size == 1024 {
            filename = "icon_1024x1024.png"
        } else {
            let scale = size.truncatingRemainder(dividingBy: 1) == 0 ? Int(size) : size
            filename = "icon_\(scale)x\(scale).png"
        }

        let fileURL = outputURL.appendingPathComponent(filename)
        saveIconImage(image, to: fileURL)
    }
}

print("\n✅ All icons generated successfully!")
print("Icons saved to: \(outputPath)")
