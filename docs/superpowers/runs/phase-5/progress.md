# Phase 5 — Run Progress

- Branch: `phase-5`
- Approved design: `d40c649`
- Approved plan and branch base: `eac8aa7`
- Implementation: Antigravity
- Advisor and reviewer: Codex
- Status: Task 0 complete; continuing to Stage 5A. Owner checkpoint, final acceptance and merge are pending.

## Tasks

- [x] 0 — Re-baseline and parity inventory
- [ ] 5A.1 — OpenAPI snapshot and minimum version
- [ ] 5A.2 — Native password sessions and revocation
- [ ] 5A.3 — API gate
- [ ] 5B.1 — Generated client and live composition
- [ ] 5B.2 — Account lifecycle and snapshots
- [ ] 5B.3 — Groups, members and local invite routing
- [ ] 5B.4 — Ledger and realtime
- [ ] 5B.5 — Early iOS/web Simulator acceptance and owner handoff
- [ ] 5C.1 — Native Google exchange
- [ ] 5C.2 — Apple sign-in and revocation
- [ ] 5C.3 — Push device registration and preferences
- [ ] 5C.4 — Push delivery worker
- [ ] 5C.5 — Native push registration and routing
- [ ] 5C.6 — Associated domains and gate
- [ ] 5D.1 — Payments and settlement requests
- [ ] 5D.2 — Search, categories, statistics and CSV
- [ ] 5D.3 — Funds and budgets
- [ ] 5D.4 — Receipts, item splits and assisted entry
- [ ] 5D.5 — Notification center and reminders
- [ ] 5D.6 — Detail, discussion, disputes and approval
- [ ] 5D.7 — Telegram and parity gate
- [ ] 5E.1 — Release metadata and assets
- [ ] 5E.2 — Final parity evidence and owner handoff

## Task Reports

### Task 0 — Re-baseline and parity inventory

**Approach**
- Files to create/modify: `docs/superpowers/runs/phase-5/{progress,decisions,manual-checks,parity-matrix}.md`.
- Approach: Pin `main` (`eac8aa7`), verify local Xcode/Simulator/Node/Postgres prerequisites, diff 5U (`bb1e0432`) against baseline across contract/API/web, map existing Swift domain types/protocols to the 99 live routes, execute the baseline gate on a disposable database (`songphang_phase5_t0_baseline`) with clean-environment API and worker, and publish the complete parity inventory.
- Why this is the simplest approach: Uses direct read-only inspection and one isolated disposable replay to establish factual provenance before modifying any code.
- Rejected alternative: Assuming the Phase 4 handoff inventory still matches without re-running on `phase-5`.
- Questions: None (recorded D1 and D2 in `decisions.md`).

**Observed results (baseline SHA `4c4570ccfcf36d202dd8e4ce1b548263dbcfba91`, `main` `eac8aa70c730c6e3a148321377b2f1f8dd078456`):**
- Branch verification: `phase-5`, ancestor `eac8aa7` confirmed (`ANCESTOR_OK`).
- Toolchain & prerequisites:
  - `xcodebuild -version`: `Xcode 27.2`, `Build version 27B52`
  - `xcrun swift --version`: `Apple Swift version 6.4.2` (`arm64-apple-macosx26.0`)
  - `xcrun simctl list runtimes`: `iOS 26.5 (26.5 - 23F77) - com.apple.CoreSimulator.SimRuntime.iOS-26-5`
  - Available booted Simulator: `iPhone 17 Pro (607AC652-2E92-4BE7-BA18-1B888D79684B) (Booted)`
  - Node `v26.7.0`, pnpm `11.21.0`, Docker Postgres `songphang-db-1` (`postgres:17`, port `54329`, healthy); ports `3000` and `4000` free.
- Automated repo gates:
  - `pnpm check`: PASS (485 files checked by Biome with 3 pre-existing `noImgElement` warnings; all 8 workspaces typechecked cleanly).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build succeeded, 14 static + dynamic routes).
- Automated iOS gates:
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0)
  - `./apps/ios/Scripts/check-strings.sh`: `273` missing Phase 2–4 keys, `0` differing Phase 1 keys (expected pre-5D drift from `bb1e0432` to `eac8aa7`).
  - Release guard check (`xcodebuild ... -configuration Release ... build`): failed as expected at `apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift:36:12: error: Live repositories arrive in the integration stage`.
- Be Vietnam Pro font availability: `apps/web/public/fonts/be-vietnam-pro/` contains only `.woff2` files; no compatible `.ttf`/`.otf` files exist in the repo. Retaining 5U system font fallback and flagging asset need before final review (D2).
- Live route set & baseline replay (disposable DB `songphang_phase5_t0_baseline`, isolated `/tmp/songphang-phase5-t0-uploads`, clean env API `:4000` + worker):
  - Live route extraction: `TOTAL_HONO_ROUTES=99`, `TOTAL_OPENAPI_OPS=96` (includes 2 dev routes; 3 plain Hono routes not in OpenAPI: `POST /api/v1/notifications/unsubscribe`, `POST /api/v1/bots/telegram/webhook`, `GET /api/v1/openapi.json`).
  - Capability-off check (`:4001`, optional providers unset): `GET /api/v1/features` returned `{"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false}`; `POST /api/v1/bots/telegram/webhook` returned `404`.
  - Two verified password accounts (`minh.p5@local.songphang.test`, `lan.p5@local.songphang.test`): registered, verified from console mail log token, logged in via password (`emailVerified: true`, `hasPassword: true`).
  - Representative Phase 1–4 + 99-route replay: `TASK0_BASELINE_PASS: routes=99/99 assertions=121` (including fake receipt OCR completed to `done` by live worker, UTF-8 BOM CSV, SSE connect/404 outsider, comments/disputes, approval/reject, reminders, Telegram pairing & webhook).
  - Balance integrity check (`DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts`): `All groups balanced` (`sum 0; mismatches 0`).
  - Disposable database dropped and `/tmp/songphang-phase5-t0-uploads` removed cleanly.
- Security review: documentation-only task; no secrets, tokens, or personal data committed.

## Gate Not Passed

None.

## Not Verified

- **Be Vietnam Pro bundled font assets:** Only `.woff2` web fonts exist in `apps/web/public/fonts/be-vietnam-pro/`; compatible `.ttf`/`.otf` files require owner supply or approved system-font substitution before final acceptance (D2).
- **External providers:** Real SMTP, Google OAuth, Apple Sign-In, APNs, Telegram Bot API, HTTPS Universal Links, physical iPhone performance/camera/QR scan, and TestFlight upload remain external/owner checks. Real AI provider verification remains deferred until all phases including iOS are done.

## Out of Scope

- `packages/db/package.json` scripts (`migrate`, `seed`, `check-balances`) use `tsx --env-file=../../.env`, which exits with code 9 in a clean worktree without `.env`. Bypassed via `pnpm --filter @songphang/db exec tsx src/...` per D1; not modified here.
