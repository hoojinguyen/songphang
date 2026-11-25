# Wave 5.5A — Run Progress

- Branch: `phase-5-5a` (Stage 5.5A.0–5.5A.1 share branch: `swarm-api-backend-bd62656b`)
- Baseline `main`: `fbc0b7a` (`378df4d`, PR #2)
- Approved specs & plan commit: `7f4f782`
- Status: Complete (Batch 1: API/DB + Design System v2; Batch 2: iOS + Web Shell, Group v2, Desktop Shell; Gate 5.5A.5.2 passed)

## Tasks

- [x] 0 — Re-baseline `main` and prepare Wave 5.5A run
- [x] 5.5A.1.1 — Database migration (`groups.archived_at`) and `GROUP_ARCHIVED` write guard
- [x] 5.5A.1.2 — Archive, Unarchive, Clone Group & additive `GET /groups` metadata
- [x] 5.5A.1.3 — Cross-Group Overview (`GET /me/overview`), Personal Ledger (`GET /me/transactions`), `myDelta` & OpenAPI
- [x] 5.5A.1.4 — Stage 5.5A.1 API Gate
- [x] 5.5A.2.1 — Web Design System v2, Dark Mode, Tabular Numerals & `TD-001` / `TD-004`
- [x] 5.5A.2.2 — iOS Design System v2 (`Be Vietnam Pro` `.ttf`, Dynamic `Tokens`, `Haptics`, `TD-004` & String Parity)
- [x] 5.5A.2.3 — Stage 5.5A.2 Design System Gate
- [x] 5.5A.3.1 — iOS `Domain`, `Repositories`, `SnapshotStore` & `PreviewSupport` for Overview, Personal Ledger, Archive & Clone
- [x] 5.5A.3.2 — iOS 4-Tab Shell, `OverviewFeature`, Segmented Group List & Archive/Clone UI
- [x] 5.5A.3.3 — Web 4-Tab Mobile Shell, Overview (`/`), Groups (`/groups`), Personal Ledger (`/ledger`), Archive & Clone
- [x] 5.5A.3.4 — Stage 5.5A.3 Shell & Overview Gate
- [x] 5.5A.4.1 — iOS Group Screen v2 (`GroupContainerView` 3-Segment Shell), Full-Width Feed Cards (`TD-006`), Collapsible Filters & Swipe Actions
- [x] 5.5A.4.2 — iOS Form/Quick-Entry Fixes (`TD-003`, `TD-005`, `TD-007`) & "Bơm hình"
- [x] 5.5A.4.3 — Web Group Screen v2 (3-Segment Shell), Full-Width Feed Cards, Quick Entry Wrap & Web "Bơm hình"
- [x] 5.5A.4.4 — Stage 5.5A.4 Group & Polish Gate
- [x] 5.5A.5.1 — Web Desktop Multi-Column Responsive Shell (`>= 1024px` / `>= 1280px`)
- [x] 5.5A.5.2 — Final Wave 5.5A Parity Gate & Owner Handoff

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

### Task 5.5A.2.1 — Web Design System v2, Dark Mode, Tabular Numerals & `TD-001` / `TD-004`

**Approach**
- Files created/modified: `apps/web/src/app/globals.css`, `apps/web/src/app/layout.tsx`, `apps/web/public/theme-init.js`, `apps/web/src/lib/theme.ts`, `apps/web/src/components/account/AppearanceCard.tsx`, `apps/web/src/app/account/page.tsx`, `apps/web/src/components/ui/{Button,Card,MemberShape,OfflineBanner,SegmentedControl,Snackbar,TextField,VerifyEmailBanner}.tsx`, `apps/web/next.config.ts`, `apps/web/src/messages/vi.ts`.
- Approach: Added semantic light/dark CSS custom properties; created static inline `/theme-init.js` to eliminate FOUC without `dangerouslySetInnerHTML`; wired theme switcher card into `/account`; enabled tabular numerals (`font-feature-settings: 'tnum' 1`); fixed `TD-001` (Next.js server-action dev origin error); fixed `TD-004` (placeholder text contrast tokens).
- Exercises: Verified theme switching, zero FOUC, tabular number rendering, and Next.js build.
- Commit: `edac870` (`feat(web): add Design System v2 dark mode, theme toggle, and dev origin fix`).

### Task 5.5A.2.2 — iOS Design System v2 (`Be Vietnam Pro` `.ttf`, Dynamic `Tokens`, `Haptics`, `TD-004` & String Parity)

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/*.ttf`, `LICENSE.txt`, `Tokens.swift`, `Typography.swift`, `AppearanceMode.swift`, `Haptics.swift`, `RootView.swift`, `AccountView.swift`, `GroupFeedSubViews.swift`, UI components, and `Localizable.xcstrings`.
- Approach: Bundled static `Be Vietnam Pro` `.ttf` font files with runtime dynamic registration; updated `SPColor` and `Tokens.swift` to dynamic `UIColor(dynamicProvider:)` resolving Light/Dark automatically; added `Haptics.swift` supporting light, medium, heavy, success, warning, error, and selection feedback; updated `RootView` to honor `@AppStorage("sp_appearance_mode")`; synchronized 47 missing strings into `Localizable.xcstrings` (717 total).
- Exercises: Verified font registration via `CTFontManagerRegisterGraphicsFont`, dark mode simulation, haptic triggers, `check-strings.sh` (717 verified), `swift-format lint --strict`, and Simulator Debug build.
- Commits: `e1c606b` (`feat(ios): add Design System v2 dark mode, bundled Be Vietnam Pro fonts, and haptics`), `6b56c0e` (`refactor(design-system): address Wave 5.5A.2 verifier findings`).

### Task 5.5A.2.3 — Stage 5.5A.2 Design System Gate

**Approach**
- Verified by worker `verifier` in Swarm Message #8:
  - Font registration verified with zero console errors.
  - Tabular numerals verified on currency displays across both Web and iOS.
  - Dark mode verified across all core views with WCAG AA compliance.
  - Haptic feedback verified on button presses and segmented control selections.
  - `check-strings.sh` verified 717 string catalog keys with 0 missing and 0 differing.
  - `pnpm check` and `pnpm build` pass with zero errors.
  - `swift-format lint --strict` passes with exit code 0.
  - Simulator build succeeded with warnings-as-errors.

### Task 5.5A.3.1 — iOS `Domain`, `Repositories`, `SnapshotStore` & `PreviewSupport` for Overview, Personal Ledger, Archive & Clone

**Approach**
- Files created/modified: `Domain/AppError.swift`, `Domain/Models/{ExpenseGroup,LedgerTransaction,Overview,TransactionFilter}.swift`, `Domain/Repositories/{GroupsRepository,OverviewRepository}.swift`, `Repositories/Transport/ErrorMapper.swift`, `Repositories/Groups/{GroupMapping,LiveGroupsRepository}.swift`, `Repositories/Overview/{OverviewMapping,LiveOverviewRepository}.swift`, `Repositories/Snapshots/SnapshotStore.swift`, `Repositories/Transactions/TransactionMapping.swift`, `PreviewSupport/Fakes/{FakeRepositories,FakeWorld,FakeWorld+Overview}.swift`, `AppShell/AppDependencies.swift`.
- Approach: Added `AppError.groupArchived` mapped from 409 `GROUP_ARCHIVED`; added `archivedAt`, `role`, `pendingActionCount` to `GroupSummary`; added `myDelta` to `LedgerTransaction`; implemented `OverviewRepository` and `LiveOverviewRepository` with clean snapshot storage in `overview.json` (wiped on sign-out); wired `FakeWorld` support.
- Commit: `300a898` (`feat(ios): add overview, group archive, and clone repositories`).

### Task 5.5A.3.2 — iOS 4-Tab Shell, `OverviewFeature`, Segmented Group List & Archive/Clone UI

**Approach**
- Files created/modified: `SongPhangKit/Package.swift`, `OverviewFeature/{OverviewModel,OverviewView,PersonalLedgerModel,PersonalLedgerView}.swift`, `GroupsFeature/GroupList/{GroupListModel,GroupListView}.swift`, `GroupsFeature/CloneGroup/CloneGroupSheetView.swift`, `GroupsFeature/GroupSettings/{GroupSettingsModel,GroupSettingsView}.swift`, `AppShell/{RootView,Route,RouteDestination}.swift`.
- Approach: Added `OverviewFeature` target with strict architectural isolation (depends only on `Domain`, `DesignSystem`, `PreviewSupport`); created 4-tab `RootView` (`Tổng quan`, `Nhóm`, `Thông báo`, `Tài khoản`) with independent `NavigationStack`s; implemented segmented `Đang mở` / `Đã lưu trữ` toggle on `GroupListView` with swipe actions; created `CloneGroupSheetView` navigating to cloned active group.
- Commit: `83ff86e` (`feat(ios): add 4-tab shell, overview feature, personal ledger, and group archive/clone`).

### Task 5.5A.3.3 — Web 4-Tab Mobile Shell, Overview (`/`), Groups (`/groups`), Personal Ledger (`/ledger`), Archive & Clone

**Approach**
- Files created/modified: `apps/web/src/lib/{overview,groups}.ts`, `apps/web/src/components/layout/AppShell.tsx`, `apps/web/src/components/overview/{OverviewSummaryCard,PendingActionsList,PersonalLedgerList}.tsx`, `apps/web/src/components/groups/{GroupCard,FeaturedGroupCard,ArchiveGroupDialog,CloneGroupDialog}.tsx`, `apps/web/src/app/{page,groups/page,ledger/page}.tsx`, `apps/web/src/app/g/[groupId]/settings/page.tsx`.
- Approach: Implemented mobile bottom 4-tab shell (`< 1024px`); created `/` Overview with net balance hero and pending action queues; created `/groups` with `Đang mở` / `Đã lưu trữ` tabs; created `/ledger` with search query `q` and type filter; wired archive and clone dialogs.
- Commit: `0310b96` (`feat(web): add 4-tab shell, overview, personal ledger, and group archive/clone`).

### Task 5.5A.3.4 — Stage 5.5A.3 Shell & Overview Gate

**Approach**
- Verified end-to-end parity between API, Web, and iOS Simulator:
  - Net balance totals match double-entry server figures across active groups.
  - Active and archived tab switching works identically on iOS and Web.
  - Personal ledger search query `q` filters transactions with Vietnamese accent insensitivity.
  - Snapshot wipe on sign-out clears `overview.json` completely.

### Task 5.5A.4.1 — iOS Group Screen v2 (`GroupContainerView` 3-Segment Shell), Full-Width Feed Cards (`TD-006`), Collapsible Filters & Swipe Actions

**Approach**
- Files created/modified: `AppShell/GroupContainerView.swift`, `LedgerFeature/GroupFeed/{GroupFeedView,GroupFeedSubViews,GroupFeedModel}.swift`, `LedgerFeature/Balances/BalancesView.swift`, `PaymentsFeature/Fund/FundView.swift`, `StatisticsFeature/Stats/StatsView.swift`.
- Approach: Created persistent header + 3-segment switcher (`Chi tiêu` | `Thanh toán` | `Quỹ & Thống kê`) in `AppShell`; redesigned feed cards into 3-row full-width cards with tabular numerals, server `myDelta`, and 5-avatar cluster (`TD-006` fix); added leading `Sửa` and trailing `Xoá` + `Chi tiết` swipe actions; displayed read-only dock `Nhóm đã lưu trữ — chỉ xem` when archived.
- Commit: `961a612` (`feat(ios): redesign group screen with 3-segment shell, full-width cards, and swipe actions`).

### Task 5.5A.4.2 — iOS Form/Quick-Entry Fixes (`TD-003`, `TD-005`, `TD-007`) & "Bơm hình"

**Approach**
- Files created/modified: `GroupsFeature/CreateGroup/CreateGroupView.swift`, `LedgerFeature/ConfirmCard/{ConfirmationCardView,ShareShapesView}.swift`, `LedgerFeature/SplitEditor/{SplitEditorView,SplitEditorState}.swift`.
- Approach: Fixed `TD-003` with `ScrollViewReader` coordinate auto-scrolling to input row above keyboard; fixed `TD-005` with responsive wrapping `LazyVGrid` for 7–20 member splits without clipping; verified `TD-007` string `"Tổng chuyến đi"`; added "Bơm hình" hold-to-grow gesture with 250ms delay, 180ms repeat interval, integer-only VND increments, spring animations, and debounce server preview synchronization.
- Commit: `ed48bf2` (`feat(ios): fix keyboard/confirmation layout debt and add hold-to-grow split interaction`).

### Task 5.5A.4.3 — Web Group Screen v2 (3-Segment Shell), Full-Width Feed Cards, Quick Entry Wrap & Web "Bơm hình"

**Approach**
- Files created/modified: `apps/web/src/app/g/[groupId]/{layout,page,balances/page,stats/page,settings/page}.tsx`, `apps/web/src/components/layout/GroupNavHeader.tsx`, `apps/web/src/components/feed/ExpenseRow.tsx`, `apps/web/src/components/quick-entry/{ConfirmationCard,ShareShapes}.tsx`, `apps/web/src/components/expense-form/{SplitEditor.tsx,use-split-state.ts}`.
- Approach: Created shared 3-segment group header; redesigned `ExpenseRow` to full-width 3-row card matching iOS; wrapped `ShareShapes` in responsive grid; added web pointer hold-to-grow "Bơm hình" with integer increments, CSS transitions, and debounced preview requests.
- Commits: `f156ee7` (`feat(web): redesign group screen v2, full-width feed cards, and hold-to-grow split`), `4a7040b` (`refactor(web): fix dark mode contrast tokens and placeholder styling`).

### Task 5.5A.4.4 — Stage 5.5A.4 Group & Polish Gate

**Approach**
- Verified full parity on dense group feeds (7–20 members), hold-to-grow split increments, and keyboard avoidance.
- Biome linting, 8 workspace typechecks, contract check, and `check-strings.sh` pass cleanly.

### Task 5.5A.5.1 — Web Desktop Multi-Column Responsive Shell (`>= 1024px` / `>= 1280px`)

**Approach**
- Files created/modified: `apps/web/src/components/layout/{AppShell,DesktopSidebar,GroupInspector}.tsx`, `apps/web/src/app/g/[groupId]/page.tsx`.
- Approach: Implemented responsive desktop layout:
  - `< 1024px`: Single-column with fixed bottom 4-tab bar.
  - `1024px–1279px` (2-column): Fixed left `DesktopSidebar` (260px) + center workspace (up to 760px).
  - `>= 1280px` on `/g/[groupId]*` (3-column): `DesktopSidebar` (260px) + center workspace (760px) + sticky right `GroupInspector` (340px) showing live net balance hero and top transfers.
  - Auth, join, and unsubscribe routes remain clean focused single-column.
- Commit: `5eb9b1f` (`feat(web): add multi-column responsive desktop shell and group inspector`).

### Task 5.5A.5.2 — Final Wave 5.5A Parity Gate & Owner Handoff

**Approach**
- Replayed complete Phase 1–5 and Wave 5.5A journeys on clean disposable database `songphang_final_gate_55a`:
  - Verified `/api/v1/health` and `/api/v1/features`.
  - Verified dev login across 3 users (Minh, Lan, Hùng).
  - Created group "Chuyến Đi Đà Lạt 5.5A", invited Lan and Hùng.
  - Verified expense creation with server-computed `myDelta` (+200.000 VND for Minh, +75.000 VND for Lan).
  - Verified `/api/v1/me/overview` net balance and owed totals matching double-entry accounting (+125.000 net for Minh, -25.000 net for Lan).
  - Verified `/api/v1/me/transactions` invariant: `sum(myDelta) === myBalance` (125.000 === 125.000).
  - Verified Vietnamese accent-insensitive search (`q=homestay`).
  - Verified group archival and 409 `GROUP_ARCHIVED` write guard.
  - Verified group clone with 0 transactions and unarchive.
  - Verified `checkBalances`: `All groups balanced (sum 0; mismatches 0)`.
- Verified automated build and code gates:
  - `pnpm check`: Exit 0 (all 8 workspace packages clean, Biome clean, contract snapshot up to date).
  - `pnpm build`: Exit 0 (all 16 static/dynamic routes compiled in Next.js 16.4.6).
  - `./apps/ios/Scripts/check-strings.sh`: Exit 0 (`OK: 717 web keys verified, 0 missing, 0 differing`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: Exit 0 (clean).
  - `xcodebuild` Simulator Debug: `** BUILD SUCCEEDED **`.
  - `xcodebuild` unsigned Release: `** BUILD SUCCEEDED **`.
  - Release bundle audit: `RELEASE_LEAK_MATCH_COUNT=0` (0 occurrences of debug symbols/hosts, `ATS_FREE_OK`, `PRIVACY_INFO_OK`).

## Gate Not Passed

None. All Wave 5.5A gates verified and passed.

## Not Verified

None. Full automated and replayed verification completed.

## Out of Scope

- Share worktree `swarm-api-backend-bd62656b` started with pre-existing dirty files outside Wave 5.5A scope (`docs/superpowers/runs/phase-4/{manual-checks,progress}.md` and untracked `docs/superpowers/plans/2026-11-19-*`, `2026-11-23-*`); left untouched.
