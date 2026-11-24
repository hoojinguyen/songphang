# Wave 5.5A — Run Progress

- Branch: `phase-5-5a` (Stage 5.5A.0–5.5A.1 share branch: `swarm-api-backend-bd62656b`)
- Baseline `main`: `fbc0b7a` (`378df4d`, PR #2)
- Approved specs & plan commit: `7f4f782`
- Status: In progress (Swarm Batch 1: API/DB + Design System v2)

## Tasks

- [x] 0 — Re-baseline `main` and prepare Wave 5.5A run
- [ ] 5.5A.1.1 — Database migration (`groups.archived_at`) and `GROUP_ARCHIVED` write guard
- [ ] 5.5A.1.2 — Archive, Unarchive, Clone Group & additive `GET /groups` metadata
- [ ] 5.5A.1.3 — Cross-Group Overview (`GET /me/overview`), Personal Ledger (`GET /me/transactions`), `myDelta` & OpenAPI
- [ ] 5.5A.1.4 — Stage 5.5A.1 API Gate
- [ ] 5.5A.2.1 — Web Design System v2, Dark Mode, Tabular Numerals & `TD-001` / `TD-004`
- [ ] 5.5A.2.2 — iOS Design System v2 (`Be Vietnam Pro` `.ttf`, Dynamic `Tokens`, `Haptics`, `TD-004` & String Parity)
- [ ] 5.5A.2.3 — Stage 5.5A.2 Design System Gate
- [ ] 5.5A.3.1 — iOS `Domain`, `Repositories`, `SnapshotStore` & `PreviewSupport` for Overview, Personal Ledger, Archive & Clone
- [ ] 5.5A.3.2 — iOS 4-Tab Shell, `OverviewFeature`, Segmented Group List & Archive/Clone UI
- [ ] 5.5A.3.3 — Web 4-Tab Mobile Shell, Overview (`/`), Groups (`/groups`), Personal Ledger (`/ledger`), Archive & Clone
- [ ] 5.5A.3.4 — Stage 5.5A.3 Shell & Overview Gate
- [ ] 5.5A.4.1 — iOS Group Screen v2 (`GroupContainerView` 3-Segment Shell), Full-Width Feed Cards (`TD-006`), Collapsible Filters & Swipe Actions
- [ ] 5.5A.4.2 — iOS Form/Quick-Entry Fixes (`TD-003`, `TD-005`, `TD-007`) & "Bơm hình"
- [ ] 5.5A.4.3 — Web Group Screen v2 (3-Segment Shell), Full-Width Feed Cards, Quick Entry Wrap & Web "Bơm hình"
- [ ] 5.5A.4.4 — Stage 5.5A.4 Group & Polish Gate
- [ ] 5.5A.5.1 — Web Desktop Multi-Column Responsive Shell (`>= 1024px` / `>= 1280px`)
- [ ] 5.5A.5.2 — Final Wave 5.5A Parity Gate & Owner Handoff

## Task Reports

### Task 0 — Re-baseline `main` and prepare Wave 5.5A run

**Approach**
- Files to create/modify: `docs/superpowers/runs/phase-5-5a/{decisions,progress}.md`.
- Approach: Confirm branch ancestry (`33fe552` on `phase-5-5a` above `main` `fbc0b7a` / `378df4d`), verify Node/pnpm/Postgres/Xcode/Simulator tooling, run baseline checks (`pnpm check`, `pnpm build`, `check-strings.sh`, `swift-format lint --strict`, Simulator Debug `xcodebuild`), inspect plan references for the Re-baseline table, and execute a representative Phase 1–5 smoke test on disposable database `songphang_phase55a_t0` with `check-balances.ts`.
- Why this is the simplest approach: Re-uses the exact local verification commands and an isolated disposable DB + clean-env API/worker on `:4111`.
- Rejected alternative: Running against a shared database or skipping the baseline smoke replay.
- Questions: None (recorded D1–D3 in `decisions.md`).

**Observed results (baseline SHA `33fe552`):**
- Toolchain & runtime: Node `v26.7.0`, pnpm `11.21.0`, Docker Postgres 17 (`songphang-db-1`, `127.0.0.1:54329`, healthy), `Xcode 27.2` (`27B52`), `Apple Swift version 6.4.2`, Simulator runtime `iOS 26.5 (26.5 - 23F77)`, booted `iPhone 17 Pro (607AC652-2E92-4BE7-BA18-1B888D79684B)`.
- `pnpm check`: PASS (`516` files checked by Biome with 3 pre-existing `noImgElement` warnings; 8 workspace typechecks clean; `OpenAPI contract snapshot is up to date.`).
- `pnpm build`: PASS (`apps/web` Next.js `16.4.6` production build succeeded cleanly across 14 static/dynamic pages).
- `./apps/ios/Scripts/check-strings.sh`: PASS (`OK: 670 web keys verified, 0 missing, 0 differing.`).
- `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0, no output).
- Simulator Debug `xcodebuild` (`-configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`, with `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` verified on all 4 project configs and `.treatAllWarnings(as: .error)` on all 13 targets): `** BUILD SUCCEEDED **`.
- Font asset check: `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` is absent on `33fe552`; deferred to `@design-system` in `5.5A.2.2` (D3).
- Disposable DB Phase 1–5 smoke (`songphang_phase55a_t0`, isolated API `:4111` + worker, `AI_PROVIDER=fake`, `TELEGRAM_PROVIDER=console`):
  - `T0_HEALTH_FEATURES_PASS {"receiptReading":true,"sentenceAi":true,"telegram":true,"push":false,"appleSignIn":false,"errorAlerts":false,"minAppVersion":{"ios":"0.0.0","android":"0.0.0"}}`
  - `T0_AUTH_PASS { bearerVerified: true, devUsers: 5 }` (register + console email verification + `POST /auth/token` Bearer + `GET /me` + `/dev/login`)
  - `T0_GROUP_INVITE_PASS` (group created, invite retrieved, Lan joined claiming `Lan`, `approvalThreshold` updated)
  - `T0_QUICK_ENTRY_APPROVAL_PASS` (`transactions/parse`, expense created, pending expense > threshold approved by owner)
  - `T0_SETTLEMENT_PASS` (settlement request created & confirmed)
  - `T0_RECEIPT_SCAN_PASS { scanStatus: 'done' }` (`POST /attachments` + `POST /receipt-scans` completed by live fake worker)
  - `T0_TELEGRAM_LINK_PASS { chatLinksCount: 1 }` (`/chat-links/code` redeemed via `/bots/telegram/webhook`)
  - `T0_ALL_SMOKE_PASS`
  - `check-balances.ts`: `01a20d53-5e1a-72ad-9bd1-e908ee62ab91 T0 Smoke Group: sum 0; mismatches 0` / `All groups balanced`
  - Disposable database `songphang_phase55a_t0` dropped and temporary upload directory removed.
- Security review: documentation-only commit; no credentials, secrets, or personal data included.

## Gate Not Passed

None.

## Not Verified

- Static `Be Vietnam Pro` `.ttf` placement and font registration verification (deferred to `@design-system` in Task `5.5A.2.2`).

## Out of Scope

- Share worktree `swarm-api-backend-bd62656b` started with pre-existing dirty files outside Wave 5.5A scope (`docs/superpowers/runs/phase-4/{manual-checks,progress}.md` and untracked `docs/superpowers/plans/2026-11-19-*`, `2026-11-23-*`); left untouched.
