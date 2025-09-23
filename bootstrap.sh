#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Chordinate"
BUNDLE_ID="com.example.chordinate"
APP_VERSION="0.1.0"
SWIFT_TOOLS="5.9"
MACOS_MIN="13.0"

# Create package skeleton
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Sources/$APP_NAME"
cat > "$APP_NAME/Package.swift" <<EOF
// swift-tools-version: $SWIFT_TOOLS
import PackageDescription

let package = Package(
    name: "$APP_NAME",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "$APP_NAME", targets: ["$APP_NAME"])],
    targets: [
        .executableTarget(
            name: "$APP_NAME",
            path: "Sources/$APP_NAME"
        )
    ]
)
EOF

# Minimal AppKit entry point that becomes active/key and focuses a text field
cat > "$APP_NAME/Sources/$APP_NAME/main.swift" <<'EOF'
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let tf = NSTextField(string: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 180),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Chordinate"
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 180))
        window.contentView = content

        tf.placeholderString = "Type here — your keys should land in THIS app"
        tf.frame = NSRect(x: 20, y: 80, width: 480, height: 24)
        content.addSubview(tf)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        tf.becomeFirstResponder()

        // NOTE: When you add global chord detection, use a passive monitor
        // so you don't steal or swallow events:
        //
        // _ = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        //     // detect your chord; DO NOT modify/return events here
        // }
        //
        // If you must use CGEventTap, prefer .listenOnly and don't return nil
        // unless you truly intend to block the event system-wide.
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
EOF

# Build the executable
pushd "$APP_NAME" >/dev/null
swift build -c release
popd >/dev/null

# Create a minimal .app bundle structure
APP_DIR="$APP_NAME/build/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
mkdir -p "$MACOS_DIR" "$RES_DIR"

# Copy executable
cp "$APP_NAME/.build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Create Info.plist (LSUIElement=false so the window can be key)
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$APP_VERSION</string>
  <key>CFBundleVersion</key><string>$APP_VERSION</string>
  <key>LSMinimumSystemVersion</key><string>$MACOS_MIN</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSUIElement</key><false/>
</dict>
</plist>
EOF

# Ad-hoc codesign (helps reduce some permission prompts)
codesign --force --deep --sign - "$APP_DIR"

echo
echo "Built: $APP_DIR"
echo "Run it with: open \"$APP_DIR\""