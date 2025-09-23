import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let tf = NSTextField(string: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make this a normal, focusable app and become frontmost.
        NSApp.setActivationPolicy(.regular)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 180),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Chordinate"
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 180))
        window.contentView = content

        tf.placeholderString = "Type here — keys should land in THIS app"
        tf.frame = NSRect(x: 20, y: 80, width: 480, height: 24)
        content.addSubview(tf)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        tf.becomeFirstResponder()

        // Optional: observe keys globally without stealing focus
        // _ = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        //   // detect chord here; do NOT swallow keys
        // }
    }
}