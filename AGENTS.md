# AGENTS: Chordinate

Purpose: macOS keyboard chord system (sequences as modifiers) that can trigger shell commands or open URLs, with a SwiftUI host and WKWebView UI.

## Current stage and strength
- Agent strength: **10** (recorded in `.agent-strength`).
- Workflow stage: Intake/Plan. We've reviewed code and found a bridge dispatch bug; next step is to fix and verify end-to-end UI -> native events.

## Expectations for agents
- Follow the shared `WORKFLOW.md` (intake -> plan/design -> build -> verify -> release -> operate). Do not skip exit criteria.
- Keep USER-facing docs up to date in `USERS.md` when adding runnable changes or new flows.
- Prefer `swift run`/`./dev` for local runs; `./test` or `swift test` for validation. Respect Input Monitoring permission prompts.
- When editing the web UI, coordinate with `WEB_DEV_SERVER_URL` support and keep `Sources/Chordinate/Resources/Web` in sync for bundled builds.
- Capture regressions, known issues, and run/debug steps in this file or `USERS.md` before leaving.

## Progress log
- 2025-12-03: Repo scanned at strength 10. Identified JS bridge emit bug in `Sources/Chordinate/Web/WebBridge.swift` (dispatch string malformed; events not reaching JS listeners). Detection defaults to off until toggled. Recorder supports Escape to cancel. Persistence lives at `~/Library/Application Support/Chordinate/bindings.json`.
