# USERS: Chordinate

## What this app does
- Listens for multi-step keyboard chords globally on macOS (Input Monitoring permission required).
- Executes actions: shell commands (`/bin/zsh -lc`) or opening URLs.
- Stores bindings in `~/Library/Application Support/Chordinate/bindings.json`.

## How to run
- SwiftPM: `swift run` (or `./dev`) from repo root. First launch will prompt for **Input Monitoring**; approve in System Settings.
- Debug with LLDB: `./debug`.
- Tests: `swift test` or `./test`.
- React/WKWebView dev: set `WEB_DEV_SERVER_URL=http://localhost:5173` (or your dev server) before `swift run`; bundled assets live in `Sources/Chordinate/Resources/Web/`.

## VS Code
- Launch configs live in `.vscode/launch.json` (Debug/Release); build tasks in `.vscode/tasks.json`.
- Workspace root assumed to be this folder; builds rely on the Swift toolchain from PATH.

## Progress snapshot (2025-12-03)
- Initial audit complete at strength 10. Found JS bridge emit bug in `Sources/Chordinate/Web/WebBridge.swift` (events not delivered to JS). Detection defaults off until enabled. Recorder allows Escape cancel.
- Next suggested step: fix bridge dispatch and verify end-to-end event flow.
