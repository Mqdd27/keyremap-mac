// Draws the app icon: two keycaps (esc ⇄ caps lock). Usage: swift icon.swift out.png
import AppKit

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background squircle on Apple's icon grid (824pt body, 100pt margin).
let body = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(red: 0.20, green: 0.45, blue: 0.95, alpha: 1),
           ending: NSColor(red: 0.10, green: 0.14, blue: 0.32, alpha: 1))!.draw(in: body, angle: -90)

func keycap(x: CGFloat, label: String, size: CGFloat) {
    let r = NSRect(x: x, y: 360, width: 290, height: 290)
    NSColor(white: 0, alpha: 0.30).setFill()  // key side / shadow
    NSBezierPath(roundedRect: r.offsetBy(dx: 0, dy: -22), xRadius: 56, yRadius: 56).fill()
    NSGradient(starting: .white, ending: NSColor(white: 0.86, alpha: 1))!
        .draw(in: NSBezierPath(roundedRect: r, xRadius: 56, yRadius: 56), angle: -90)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: .semibold),
        .foregroundColor: NSColor(red: 0.12, green: 0.16, blue: 0.30, alpha: 1)]
    let t = NSAttributedString(string: label, attributes: attrs)
    t.draw(at: NSPoint(x: r.midX - t.size().width / 2, y: r.midY - t.size().height / 2))
}
keycap(x: 150, label: "esc", size: 104)
keycap(x: 584, label: "⇪", size: 150)

let arrow = NSAttributedString(string: "⇄", attributes: [
    .font: NSFont.systemFont(ofSize: 120, weight: .bold), .foregroundColor: NSColor.white])
arrow.draw(at: NSPoint(x: 512 - arrow.size().width / 2, y: 505 - arrow.size().height / 2))

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
