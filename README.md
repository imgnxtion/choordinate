# Chordinate

Chordinate is a lightweight macOS utility for creating multi-step "chord" keyboard shortcuts and binding them to simple actions.

## Features

- Record chords made of sequential key combinations (e.g. `⌘K`, `⌘C`).
- Assign chords to running shell commands or opening URLs.
- Global key listener that fires even while other apps are active (Input Monitoring permission required).
- Persistent storage inside `~/Library/Application Support/Chordinate/bindings.json`.

## Building & Running

This repo now contains a single SwiftPM-based macOS app (no separate Xcode project, no CLI target). You can open the package in Xcode 15+ or run it from the command line with the Swift toolchain.

```bash
swift run
```

> **Note:** Running `swift build`/`swift run` from this CLI may require granting write access to SwiftPM cache directories or running outside the restricted sandbox. Xcode handles this automatically.

When launching the compiled app for the first time, macOS will prompt for **Input Monitoring** permission so it can observe global keyboard events. Grant permission via **System Settings → Privacy & Security → Input Monitoring**.

## Usage

1. Launch Chordinate.
2. Click the **+** toolbar button to add a new chord.
3. Select the new chord in the sidebar and provide a name.
4. Press **Record Chord**, enter the desired sequence, then press **Stop Recording** (or hit Escape to cancel).
5. Pick an action:
   - **Run Shell Command** executes the provided script with `/bin/zsh -lc`.
   - **Open URL** launches the supplied URL using `NSWorkspace`.
6. Ensure **Enable Detection** is checked in the **Chords** menu.
7. Trigger the chord globally to execute the bound action.

The status overlay in the lower-left corner of the window shows the most recent chord that fired.

## Testing

Basic model tests live under `Tests/ChordinateTests`. Run them with:

```bash
swift test
```

(Subject to the same sandbox considerations mentioned above.)

## Repo Structure

- `Package.swift` — SwiftPM package with a single executable target `Chordinate`.
- `Sources/Chordinate` — macOS SwiftUI app with WKWebView UI host and native logic.
- `Sources/Chordinate/Resources/Web` — bundled web UI entry (`index.html`).
- `Tests/` — unit tests for the models.

Legacy files from an Xcode project template and a CLI stub were removed to avoid multiple entry points.

## Helper Scripts

The repo includes executable wrappers that set sensible defaults for the Swift toolchain:

- `./dev` launches the app with `swift run` in debug mode.
- `./debug` starts the app under LLDB for interactive debugging sessions.
- `./build` invokes `swift build` to produce binary artifacts.
- `./test` runs the unit test suite via `swift test`.

Each script pins cache directories inside the workspace so they work in constrained environments and can be chained in CI.

## React UI (WKWebView)

You can build the UI in React and have the macOS app host it inside a WKWebView. The Swift side exposes a small JS bridge and pushes state updates.

### Dev workflow

- Dev server: run your React app at `http://localhost:5173` (e.g., Vite).
- Launch the app with the environment variable `WEB_DEV_SERVER_URL=http://localhost:5173` so the webview loads your dev server instead of bundled files.
  - Example: `WEB_DEV_SERVER_URL=http://localhost:5173 swift run`
- For production, build your React app and copy the built files into `Sources/Chordinate/Resources/Web/` (replace the sample `index.html`). The app will load the bundled `index.html`.

### JS bridge

Native creates `window.chordinate` with:

- `window.chordinate.on(handler)` to subscribe to events. The handler receives `{ type, payload }` objects. Returns an unsubscribe function.
- Native sends events:
  - `nativeReady` — WebView loaded. You should respond with a `ready` message (see below).
  - `bindingsChanged` — payload: `{ bindings: ChordBinding[] }`
  - `detectionChanged` — payload: `{ enabled: boolean }`
  - `lastTriggered` — payload: `{ binding: ChordBinding | null }`

JS can call native via `window.webkit.messageHandlers.bridge.postMessage({ type, payload })` with the following messages:

- `ready` — Ask native to send initial state.
- `setDetectionEnabled` (payload: `boolean`)
- `createBinding` (payload: `ChordBinding`)
- `updateBinding` (payload: `ChordBinding`)
- `removeBinding` (payload: `ChordBinding`)
- `recordStart` | `recordStop` | `recordCancel`

Where `ChordBinding`, `KeyStroke`, `ModifierFlags`, and `ChordAction` match the Codable Swift models in `Sources/Chordinate/Models`. `ModifierFlags` encode as `{ rawValue: number }` with bit flags (1=⌘, 2=⌥, 4=⌃, 8=⇧).

The repository includes a minimal placeholder at `Sources/Chordinate/Resources/Web/index.html` that demonstrates the bridge and renders the current state.

<!-- CLI removed; GUI is the primary app. -->
