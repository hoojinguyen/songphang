# Sòng Phẳng — Phase 5 (iOS) Implementation Plan — Overview

> **For the implementation agent:** read `AGENTS.md` of **both** repositories, the spec, `../2026-11-15-common.md`, then this file. Work through the stage files in order without stopping between tasks.

**Goal:** A native iPhone application with every feature the web application has when the run starts, signing in with Apple, Google or email, receiving push notifications, and opening invite links directly.

**Architecture:** The server stays the only place with logic. Stage 5A freezes the API contract into a committed OpenAPI file and adds what native clients need. The application is SwiftUI over a client generated from that file; it keeps no database, computes no official amount, and stores its session token in the Keychain.

**Tech Stack:** this repository unchanged (no new library; Apple tokens and APNs use `node:crypto` and `node:http2`). iOS repository: Swift 6, SwiftUI, iOS 17 minimum, `swift-openapi-generator`, `swift-openapi-runtime`, `swift-openapi-urlsession`.

**Spec:** `docs/superpowers/specs/2026-11-15-phase-5-ios-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-phase-5`; `<BRANCH>` `phase-5`; `<LAST TASK>` `5E.2`.

## Stage files

| Order | File | Tasks | Where |
|---|---|---|---|
| 0 | `../2026-11-15-common.md` | 0 | This repository |
| 1 | `5a-api.md` | 5A.1–5A.6 | This repository |
| 2 | `5b-5e-app.md` | 5B.1–5B.7, 5C.1–5C.2, 5D.1–5D.3, 5E.1–5E.2 | iOS repository (and this one for 5C) |

## Two repositories

- API work is committed here on `phase-5`. Application work is committed in `../songphang-ios` on its `main` branch (a new repository has no other), one commit per task, never pushed.
- Run files stay here. Each application task's entry in `progress.md` records the iOS repository's commit hash.
- The application's automated gate replaces `pnpm check`: `xcodebuild -scheme SongPhang -destination 'generic/platform=iOS Simulator' build` with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, and `swift format lint --strict --recursive .`. Never silence a warning with an attribute or a force unwrap.
- If Xcode or a simulator runtime is not installed, the run does stage 5A, records everything from 5B on as "Not built: no Xcode", and stops. Do not install Xcode.

## Constraints for this phase

- **Additive API only** from task 5A.1 on (spec 4.1). `pnpm contract:check` is part of `pnpm check`.
- The application never calculates a share, a balance, a settlement or a QR payload. The only arithmetic on money in Swift is integer addition and subtraction for display hints that the web also shows ("Còn dư", the overdraft amount).
- Strings: `Localizable.xcstrings` holds exactly the strings of `apps/web/src/messages/vi.ts`, plus the iOS-only ones of spec 5.3. Task 5B.2 writes a script (in the iOS repository, `Scripts/check-strings.sh`) that lists web strings missing from the catalog; it reports, it does not assert, and its output is recorded at every gate.
- The token is read from and written to the Keychain in one file. It is never printed, never put in a URL, never stored in `UserDefaults`.
- No analytics, no crash-reporting SDK, no third-party SDK of any kind.
- Screens: when a web screen exists, the iOS screen has the same content, order and strings; platform conventions replace only navigation chrome and controls (navigation stack, sheets, system pickers).
- Screenshots recorded in `progress.md` are taken with the iOS Simulator tool or `xcrun simctl io booted screenshot`, saved under `docs/superpowers/runs/phase-5/screens/`.

## Review Focus

1. **The application shows a number the server did not send.** → 5B.5, 5B.6.
2. **A session token leaks** into logs, a URL, a backup, or another application through the URL scheme. → 5A.2, 5B.3.
3. **A contract change breaks the installed application.** → 5A.1.
4. **A push shows private data on a lock screen against the user's wish, or reaches a signed-out device.** → 5A.5, 5C.1.
5. **A forged Apple token signs in.** → 5A.3.
