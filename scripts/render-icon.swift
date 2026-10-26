import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func cgColor(_ hex: UInt32) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

func renderIcon(size: Int) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let scale = CGFloat(size)
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.translateBy(x: 0, y: scale)
    context.scaleBy(x: 1, y: -1)

    let background = CGGradient(
        colorsSpace: colorSpace,
        colors: [cgColor(0x1b2b42), cgColor(0x0c1422)] as CFArray,
        locations: [0, 1]
    )!
    let tile = CGPath(roundedRect: CGRect(x: 0, y: 0, width: scale, height: scale), cornerWidth: scale * 0.22, cornerHeight: scale * 0.22, transform: nil)
    context.addPath(tile)
    context.clip()
    context.drawLinearGradient(background, start: point(0.05, 0.02), end: point(0.94, 0.98), options: [])

    let cat = CGMutablePath()
    cat.move(to: point(0.24, 0.44))
    cat.addLine(to: point(0.19, 0.22))
    cat.addLine(to: point(0.43, 0.34))
    cat.addQuadCurve(to: point(0.57, 0.34), control: point(0.50, 0.31))
    cat.addLine(to: point(0.81, 0.22))
    cat.addLine(to: point(0.76, 0.44))
    cat.addCurve(to: point(0.78, 0.78), control1: point(0.91, 0.53), control2: point(0.91, 0.68))
    cat.addCurve(to: point(0.50, 0.91), control1: point(0.71, 0.91), control2: point(0.60, 0.93))
    cat.addCurve(to: point(0.22, 0.78), control1: point(0.40, 0.93), control2: point(0.29, 0.91))
    cat.addCurve(to: point(0.24, 0.44), control1: point(0.09, 0.68), control2: point(0.09, 0.53))
    cat.closeSubpath()
    let catGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [cgColor(0xa7f2dd), cgColor(0x62cfb1)] as CFArray,
        locations: [0, 1]
    )!
    context.saveGState()
    context.addPath(cat)
    context.clip()
    context.drawLinearGradient(catGradient, start: point(0.5, 0.26), end: point(0.5, 0.92), options: [])
    context.restoreGState()

    context.setFillColor(cgColor(0x142238))
    context.fillEllipse(in: CGRect(x: 0.365 * scale, y: 0.565 * scale, width: 0.043 * scale, height: 0.083 * scale))
    context.fillEllipse(in: CGRect(x: 0.592 * scale, y: 0.565 * scale, width: 0.043 * scale, height: 0.083 * scale))

    let nose = CGMutablePath()
    nose.move(to: point(0.5, 0.65))
    nose.addLine(to: point(0.47, 0.625))
    nose.addLine(to: point(0.53, 0.625))
    nose.closeSubpath()
    context.setFillColor(cgColor(0xff8c79))
    context.addPath(nose)
    context.fillPath()

    let faceLines = CGMutablePath()
    faceLines.move(to: point(0.5, 0.65))
    faceLines.addLine(to: point(0.5, 0.685))
    faceLines.move(to: point(0.5, 0.685))
    faceLines.addQuadCurve(to: point(0.443, 0.694), control: point(0.47, 0.72))
    faceLines.move(to: point(0.5, 0.685))
    faceLines.addQuadCurve(to: point(0.557, 0.694), control: point(0.53, 0.72))
    faceLines.move(to: point(0.30, 0.66))
    faceLines.addLine(to: point(0.19, 0.64))
    faceLines.move(to: point(0.30, 0.70))
    faceLines.addLine(to: point(0.185, 0.73))
    faceLines.move(to: point(0.70, 0.66))
    faceLines.addLine(to: point(0.81, 0.64))
    faceLines.move(to: point(0.70, 0.70))
    faceLines.addLine(to: point(0.815, 0.73))
    context.addPath(faceLines)
    context.setStrokeColor(cgColor(0x347b72))
    context.setLineWidth(scale * 0.012)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
    return context.makeImage()!
}

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: render-icon.swift output.png\n", stderr)
    exit(2)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, renderIcon(size: 1024), nil)
precondition(CGImageDestinationFinalize(destination), "Could not write icon PNG")
