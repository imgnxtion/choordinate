# Chordinate

Chordinate is a lightweight macOS utility for creating multi-step "chord" keyboard shortcuts and binding them to simple actions.

## Features

- Record chords made of sequential key combinations (e.g. `⌘K`, `⌘C`).
- Assign chords to running shell commands or opening URLs.
- Global key listener that fires even while other apps are active (Input Monitoring permission required).
- Persistent storage inside `~/Library/Application Support/Chordinate/bindings.json`.

## Building & Running

You can open the package in Xcode 15+ or run it from the command line with the Swift toolchain.

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

## Helper Scripts

The repo includes executable wrappers that set sensible defaults for the Swift toolchain:

- `./dev` launches the app with `swift run` in debug mode.
- `./debug` starts the app under LLDB for interactive debugging sessions.
- `./build` invokes `swift build` to produce binary artifacts.
- `./test` runs the unit test suite via `swift test`.

Each script pins cache directories inside the workspace so they work in constrained environments and can be chained in CI.
