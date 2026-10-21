import AppKit
import CoreGraphics

// Own test windows only; physical touches must arrive from the iPad receiver.
let logPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/evidence/touch-events.jsonl"
FileManager.default.createFile(atPath: logPath, contents: Data())
let log = FileHandle(forWritingAtPath: logPath)!
func record(_ device: String, _ action: String, _ value: Double) {
    let row: [String: Any] = ["display":device, "action":action, "value":value, "time":Date().timeIntervalSince1970]
    let data = try! JSONSerialization.data(withJSONObject: row, options: [.sortedKeys])
    log.write(data); log.write(Data([10])); log.synchronizeFile()
}
final class TouchProbe: NSView {
    let device: String
    var taps = 0, drags = 0, scrolls = 0
    var scrollOffset: CGFloat = 0
    var box = NSRect(x: 510, y: 340, width: 220, height: 100)
    let button = NSRect(x: 60, y: 340, width: 300, height: 100)
    let scrollArea = NSRect(x: 50, y: 45, width: 800, height: 225)
    var down: NSPoint?, dragging = false, tapped = false, moved = false
    init(device: String) { self.device=device; super.init(frame:NSRect(x:0,y:0,width:900,height:600)) }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 22) {
        (value as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:NSFont.monospacedSystemFont(ofSize:size,weight:.medium),.foregroundColor:NSColor.white])
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed:0.04,green:0.08,blue:0.15,alpha:1).setFill(); bounds.fill()
        text("Legacy Display — Touch Test",45,548,28)
        text("Tap: \(taps)     Drag: \(drags)     Scroll: \(scrolls)",45,505)
        NSColor.systemBlue.setFill(); button.fill(); text("1. TAP",button.minX+90,button.midY-12)
        NSColor.systemGreen.setFill(); box.fill(); text("2. DRAG",box.minX+45,box.midY-12)
        NSColor.darkGray.setFill(); scrollArea.fill()
        text("3. TWO-FINGER SCROLL",75,225)
        text("Offset: \(Int(scrollOffset))",75,185)
        let markerY = 70 + CGFloat((Int(scrollOffset) % 100 + 100) % 100)
        NSColor.systemOrange.setFill(); NSRect(x:550,y:markerY,width:200,height:15).fill()
        text("mini 2: hold TAP for 1s; settings should open",45,290,17)
    }
    override func mouseDown(with event: NSEvent) {
        let p=convert(event.locationInWindow,from:nil); down=p; dragging=box.contains(p); tapped=button.contains(p); moved=false
    }
    override func mouseDragged(with event: NSEvent) {
        let p=convert(event.locationInWindow,from:nil)
        if dragging, let previous=down {
            box.origin.x=max(400,min(660,box.origin.x+p.x-previous.x))
            box.origin.y=max(320,min(390,box.origin.y+p.y-previous.y))
            if hypot(p.x-previous.x,p.y-previous.y)>0 { moved=true }
            down=p; needsDisplay=true
        }
    }
    override func mouseUp(with event: NSEvent) {
        let p=convert(event.locationInWindow,from:nil)
        if event.clickCount > 0 {
            if dragging && moved { drags+=1; record(device,"drag",Double(drags)) }
            else if tapped && button.contains(p) { taps+=1; record(device,"tap",Double(taps)) }
        }
        down=nil; dragging=false; tapped=false; needsDisplay=true
    }
    override func scrollWheel(with event: NSEvent) {
        guard scrollArea.contains(convert(event.locationInWindow,from:nil)) else { return }
        scrolls+=1; scrollOffset+=event.scrollingDeltaY; record(device,"scroll",Double(event.scrollingDeltaY)); needsDisplay=true
    }
}
let app=NSApplication.shared
app.setActivationPolicy(.accessory)
var windows=[NSWindow]()
for screen in NSScreen.screens where screen.localizedName.contains("OpenDisplay") {
    let view=TouchProbe(device:screen.localizedName)
    let window=NSWindow(contentRect:NSRect(x:screen.visibleFrame.minX+40,y:screen.visibleFrame.minY+40,width:900,height:600),styleMask:[.titled,.closable],backing:.buffered,defer:false)
    window.title="Legacy Display — Touch Acceptance"
    window.isReleasedWhenClosed=false; window.contentView=view; window.orderFrontRegardless(); windows.append(window)
    DispatchQueue.main.asyncAfter(deadline:.now()+2) {
        window.setFrameOrigin(NSPoint(x:screen.visibleFrame.minX+40,y:screen.visibleFrame.minY+40))
        window.orderFrontRegardless()
        print("Touch test ready on \(window.screen?.localizedName ?? "unknown")")
        fflush(stdout)
    }
}
guard !windows.isEmpty else { fatalError("No active OpenDisplay screens") }
fflush(stdout)
Timer.scheduledTimer(withTimeInterval:600,repeats:false) { _ in
    for window in windows { window.close() }
    log.closeFile(); app.terminate(nil)
}
app.run()
