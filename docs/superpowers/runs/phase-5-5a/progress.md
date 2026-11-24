# Wave 5.5A — Run Progress

- Branch: `phase-5-5a` (Stage 5.5A.0–5.5A.1 share branch: `swarm-api-backend-bd62656b`)
- Baseline `main`: `fbc0b7a` (`378df4d`, PR #2)
- Approved specs & plan commit: `7f4f782`
- Status: In progress (Swarm Batch 1: API/DB + Design System v2)

## Tasks

- [x] 0 — Re-baseline `main` and prepare Wave 5.5A run
- [x] 5.5A.1.1 — Database migration (`groups.archived_at`) and `GROUP_ARCHIVED` write guard
- [x] 5.5A.1.2 — Archive, Unarchive, Clone Group & additive `GET /groups` metadata
- [x] 5.5A.1.3 — Cross-Group Overview (`GET /me/overview`), Personal Ledger (`GET /me/transactions`), `myDelta` & OpenAPI
- [x] 5.5A.1.4 — Stage 5.5A.1 API Gate
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

### Task 5.5A.1.1 — Database migration (`groups.archived_at`) and `GROUP_ARCHIVED` write guard

**Approach**
- Files created/modified: `packages/db/src/schema-groups.ts`, `packages/db/drizzle/0030_needy_bug.sql`, `packages/db/drizzle/meta/*`, `packages/db/src/{groups,chat}.ts`, `packages/contract/src/error.ts`, `packages/contract/openapi.json`, `apps/api/src/services/group-guards.ts`, and write service modules across `apps/api/src/services/` and `apps/api/src/bot/`.
- Approach: Added `archivedAt` timestamp with index to `groups`; projected `archivedAt` from group reads; returned `{ id, archivedAt }` from `lockGroup`; added `GROUP_ARCHIVED` to `ErrorCode` and regenerated `openapi.json`; created `assertGroupRowNotArchived` guard and applied inside the group lock across every group write endpoint and Telegram bot webhook.
- Why this is the simplest approach: Reuses the existing row lock from `lockGroup` so race conditions between writes and concurrent archive calls are prevented without introducing additional distributed locks.
- Exercises: Verified on disposable DB `songphang_phase55a_1_1` with `T55A_1_1_ARCHIVED_GUARD_PASS: endpoints=22/22 outsider=404 tg_drafts=0` and `All groups balanced`.
- Commit: `1e37c68` (`feat(db): add group archival schema and write guard`).
- Security review: Archived groups reject writes with 409 without leaking internal group metadata; outsider returns 404 before reaching archive checks.

### Task 5.5A.1.2 — Archive, Unarchive, Clone Group & additive `GET /groups` metadata

**Approach**
- Files created/modified: `packages/contract/src/group.ts`, `packages/contract/openapi.json`, `packages/db/src/{groups,payment-methods,categories,settlement-requests,transactions}.ts`, `apps/api/src/services/pending-actions.ts`, `apps/api/src/services/groups.ts`, `apps/api/src/routes/groups.ts`.
- Approach: Added `GroupStatusFilter` (`all`, `active`, `archived`) to `GET /groups`; added additive `archivedAt`, `role`, and `pendingActionCount` to `GroupSummaryDto`; created `collectPendingActions` helper computing actionable confirmations and approvals; added `POST /groups/{id}/archive` and `unarchive` (owner only, idempotent, emitting SSE events); added `POST /groups/{id}/clone` (owner or editor, copying active person members, optional payment methods and categories, zero transactions or activity leaks).
- Why this is the simplest approach: Reuses existing authorization helpers and batch loaders (`listMembersForGroups`, `listBalancesForGroups`) in single transactions with `repeatable read`.
- Exercises: Verified on disposable DB `songphang_phase55a_1_2` with `T55A_1_2_LIST_GROUPS_PASS { minhCount: 2, lanCount: 1, hungCount: 0 }`, `T55A_1_2_ALL_PASS`, and `All groups balanced`.
- Commit: `cd6118d` (`feat(api): add group archive, unarchive, clone, and summary metadata`).
- Security review: Clone duplicates payment methods to new member IDs without recording account numbers in activity payloads or console logs.

### Task 5.5A.1.3 — Cross-Group Overview (`GET /me/overview`), Personal Ledger (`GET /me/transactions`), `myDelta` & OpenAPI

**Approach**
- Files created/modified: `packages/contract/src/{overview,transaction,index}.ts`, `packages/contract/openapi.json`, `packages/db/src/{overview,index}.ts`, `apps/api/src/services/{transactions,overview}.ts`, `apps/api/src/routes/me.ts`.
- Approach: Added `myDelta: z.int().nullable().optional()` on `BaseTransactionFields`; implemented `computeMyDelta` pure helper; added `GET /api/v1/me/overview` (`OverviewResponse`) aggregating `totalOwedToMe`, `totalIOwe`, `netBalance`, active/archived counts, top 20 pending actions, and non-zero group balances; added `GET /api/v1/me/transactions` (`PersonalTransactionsResponse`) with cursor pagination, Vietnamese accent-insensitive search, type filter, and group filter.
- Why this is the simplest approach: Computes authoritative integers server-side; ensures `myDelta` returns `null` on uncounted transactions so `sum(myDelta ?? 0) === myBalance` holds exactly.
- Exercises: Verified on disposable DB `songphang_phase55a_1_3` with `T55A_1_3_PASS`, exact balance matching on all member pairs, immediate removal exclusion, `All groups balanced`, and OpenAPI diff vs `33fe552` showing 0 breaking and 21 additive changes.
- Commit: `c0a5a0c` (`feat(api): add cross-group overview, personal ledger, and transaction myDelta`).
- Security review: Outsider `groupId` filter returns 404; removed users are immediately excluded from both overview and personal ledger queries.

### Task 5.5A.1.4 — Stage 5.5A.1 API Gate

**Approach**
- Files modified: `docs/superpowers/runs/phase-5-5a/{decisions,progress,parity-matrix}.md`.
- Approach: Replayed complete Stage 5.5A.1 API gate on clean disposable database `songphang_phase55a_1_4` with live worker:
  - Verified `/health` and `/features` (receiptReading, sentenceAi, telegram).
  - Verified Cookie and Bearer authentication across 4 users (owner, editor, viewer, outsider).
  - Executed complete Phase 1-5 replay (quick entry parse, background worker receipt scan completion, expense, comment, dispute open and resolve, approval threshold, pending expense, confirmed settlement, pending settlement, Telegram pairing and group linking).
  - Verified 34-point permission matrix across Cookie and Bearer callers (unauthenticated 401, outsider 404, viewer 403, editor 403, owner 200).
  - Verified 33-point `409 GROUP_ARCHIVED` sweep across 29 group write routes, multipart upload, and Telegram bot `/chi` draft insertion.
  - Verified permitted operations on archived groups (read endpoints, mute, clone with payment method copying and no secret leakage, unarchive).
  - Verified `sum(myDelta ?? 0) === myBalance` on every member.
  - Verified removed user is immediately excluded from `/me/overview` and `/me/transactions`.
  - Verified revoked bearer session is immediately rejected with 401.
  - Verified `pnpm db:check-balances` reports `All groups balanced`.
  - Verified `pnpm check` and `pnpm build` pass cleanly.
- Observed results:
  - Gate script output: `{"status":"T55A_1_4_GATE_PASS","permChecks":34,"archivedGuardChecks":33,"scanStatus":"done","clonedMembersCount":3,"viewerExcludedAfterRemoval":true,"revokedBearerRejected401":true}`
  - `check-balances.ts`: `01a20d8d-cd30-7da2-888b-0e485798fc10 Cổng Kiểm Định 5.5A: sum 0; mismatches 0` / `01a20d8d-d7b3-75dd-b4f2-8ad1be2bdb8d Chuyến Mới: sum 0; mismatches 0` / `All groups balanced`.
  - `pnpm check`: PASS (522 files checked, 3 pre-existing warnings in web `noImgElement`, all 8 workspace projects typecheck cleanly, `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (Next.js 16.4.6 compiled successfully, 14 static pages generated in 2.8s).
- Security review:
  - No secrets, real credentials, or payment account numbers in logs, git, or activity payloads.
  - Outsiders strictly receive 404 for group resources.
  - Removed users immediately lose group access and data from personal overview and ledger.
  - Session revocation takes immediate effect across bearer-authenticated calls.

## Gate Not Passed

None.

## Not Verified

- Static `Be Vietnam Pro` `.ttf` placement and font registration verification (deferred to `@design-system` in Task `5.5A.2.2`).

## Out of Scope

- Share worktree `swarm-api-backend-bd62656b` started with pre-existing dirty files outside Wave 5.5A scope (`docs/superpowers/runs/phase-4/{manual-checks,progress}.md` and untracked `docs/superpowers/plans/2026-11-19-*`, `2026-11-23-*`); left untouched.
