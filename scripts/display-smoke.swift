import AppKit
import CoreGraphics

// Creates only its own temporary test window; never moves existing user windows.
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
guard let target = NSScreen.screens.first(where: { $0.localizedName.contains("OpenDisplay") }),
      let source = NSScreen.screens.first else {
    fatalError("An active OpenDisplay screen is required")
}
for screen in NSScreen.screens {
    let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
    print("Display: \(screen.localizedName), desktop \(Int(screen.frame.width))x\(Int(screen.frame.height)), mirror=\(CGDisplayIsInMirrorSet(id) != 0)")
}
let window = NSWindow(contentRect: NSRect(x: source.visibleFrame.minX + 24,
    y: source.visibleFrame.minY + 24, width: 900, height: 620),
    styleMask: [.titled, .closable], backing: .buffered, defer: false)
window.title = "OpenDisplay iPad 2 — Live Acceptance Test"
window.isReleasedWhenClosed = false
window.backgroundColor = NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.15, alpha: 1)
let content = window.contentView!
func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor = .white) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    field.textColor = color
    field.frame = NSRect(x: x, y: y, width: 860-x, height: size+12)
    content.addSubview(field)
    return field
}
_ = label("iPad 2 / iOS 9.3.5", x: 32, y: 548, size: 32)
_ = label("Independent extended desktop over USB", x: 32, y: 506, size: 22)
_ = label("Existing external monitor stays connected.", x: 32, y: 466, size: 18)
_ = label("24 pt: The quick brown fox jumps over the lazy dog.", x: 32, y: 398, size: 24)
_ = label("16 pt: ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789", x: 32, y: 356, size: 16)
_ = label("12 pt: H.264 / 1024 x 768 / native UIKit receiver / no jailbreak", x: 32, y: 320, size: 12)
let clock = label("Preparing animated test…", x: 32, y: 256, size: 24, color: .systemTeal)
let bar = NSView(frame: NSRect(x: 32, y: 200, width: 28, height: 28))
bar.wantsLayer = true
bar.layer?.backgroundColor = NSColor.systemTeal.cgColor
content.addSubview(bar)
for (index, color) in [NSColor.systemRed, .systemGreen, .systemBlue, .white, .gray].enumerated() {
    let swatch = NSView(frame: NSRect(x: 32 + index * 160, y: 64, width: 142, height: 82))
    swatch.wantsLayer = true
    swatch.layer?.backgroundColor = color.cgColor
    content.addSubview(swatch)
}
window.orderFrontRegardless()
let started = Date()
var ticks = 0
Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { timer in
    ticks += 1
    clock.stringValue = "Live frame \(ticks)  |  \(String(format: "%.1f", Date().timeIntervalSince(started))) s"
    bar.setFrameOrigin(NSPoint(x: 32 + CGFloat(ticks % 220) * 3.5, y: 200))
    if Date().timeIntervalSince(started) > 45 {
        timer.invalidate(); window.close(); app.terminate(nil)
    }
}
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    window.setFrameOrigin(NSPoint(x: target.visibleFrame.minX + 50, y: target.visibleFrame.minY + 56))
    print("Moved test window to \(window.screen?.localizedName ?? "unknown")")
    fflush(stdout)
}
app.run()
