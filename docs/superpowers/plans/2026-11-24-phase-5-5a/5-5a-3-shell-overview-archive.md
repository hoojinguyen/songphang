# Wave 5.5A — Stage 5.5A.3: 4-Tab Shell, Overview, Personal Ledger, Archive & Clone

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md).

### Task 5.5A.3.1: iOS `Domain`, `Repositories`, `SnapshotStore` & `PreviewSupport` for Overview, Personal Ledger, Archive & Clone

**Files:**
- `apps/ios/SongPhangKit/Sources/Domain/AppError.swift`
- `apps/ios/SongPhangKit/Sources/Domain/Models/{ExpenseGroup,LedgerTransaction}.swift` and new `Overview.swift`
- `apps/ios/SongPhangKit/Sources/Domain/Repositories/GroupsRepository.swift` and new `OverviewRepository.swift`
- `apps/ios/SongPhangKit/Sources/Repositories/Errors/ErrorMapping.swift` (or existing error mapper under `Repositories/Transport/`)
- `apps/ios/SongPhangKit/Sources/Repositories/Groups/` and new `apps/ios/SongPhangKit/Sources/Repositories/Overview/`
- `apps/ios/SongPhangKit/Sources/Repositories/Transactions/`
- `apps/ios/SongPhangKit/Sources/Repositories/Snapshots/SnapshotStore.swift`
- `apps/ios/SongPhangKit/Sources/PreviewSupport/{Fakes,Samples,Scenarios}/`
- `apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift`

**Interfaces & Rules:**
- Extend `Domain` types purely with server-sent fields (all money remains `Money` integer):
  - `AppError.groupArchived` (mapped from HTTP `409` `"GROUP_ARCHIVED"`).
  - `ExpenseGroup.archivedAt: Date?` (and `var isArchived: Bool { archivedAt != nil }`).
  - `GroupSummary.archivedAt: Date?`, `role: GroupRole`, `pendingActionCount: Int`.
  - `LedgerTransaction.myDelta: Money?`.
  - New `OverviewSummary`, `OverviewPendingAction` (`settlementConfirmation` / `expenseApproval`), `OverviewGroupBalance`, `PersonalTransaction`, and `PersonalTransactionsPage`.
  - Add `archive(groupId:)`, `unarchive(groupId:)`, `clone(groupId:name:copyPaymentMethods:copyCategories:idempotencyKey:)`, and `list(status:)` on `GroupsRepository`.
  - Add `OverviewRepository` (`overview() throws(AppError) -> OverviewSummary`, `transactions(cursor:limit:type:groupId:query:) throws(AppError) -> PersonalTransactionsPage`).
- **`SnapshotStore.swift`:** Add user-scoped `overview.json` snapshot read/write methods matching existing security protection (`completeFileProtection`) and ensure `clearAll()` / session-invalidation / sign-out / account-deletion clears `overview.json` cleanly.
- **`PreviewSupport`:** Extend `FakeWorld` to implement `overview()`, `transactions(...)`, `archive`, `unarchive`, `clone`, and `myDelta` using transcribed literal payloads.

**Exercises:**
- [ ] Run `xcodebuild` Debug + `xcrun swift-format lint --strict --recursive apps/ios`.
- [ ] Exercise `LiveOverviewRepository` & `LiveGroupsRepository` against the local API (overview totals, personal ledger filtering, repeated idempotent archive returning `200`, write-guarded mutations returning `409 GROUP_ARCHIVED` while archived, clone, and `SnapshotStore` wipe on sign-out/revocation).
- [ ] Commit: `feat(ios): wire Wave 5.5A domain models, repositories, and overview snapshots`.

---

### Task 5.5A.3.2: iOS 4-Tab Shell, `OverviewFeature`, Segmented Group List & Archive/Clone UI

**Files:**
- `apps/ios/SongPhangKit/Package.swift` (add `OverviewFeature` target depending strictly on `Domain`, `DesignSystem`, `PreviewSupport`; link to `AppShell`)
- New `apps/ios/SongPhangKit/Sources/OverviewFeature/Overview/{OverviewModel,OverviewView}.swift`
- New `apps/ios/SongPhangKit/Sources/OverviewFeature/PersonalLedger/{PersonalLedgerModel,PersonalLedgerView}.swift`
- `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupList/{GroupListModel,GroupListView}.swift`
- `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupSettings/{GroupSettingsModel,GroupSettingsView}.swift` and new `CloneGroupSheetView.swift` (in `GroupsFeature`)
- `apps/ios/SongPhangKit/Sources/AppShell/{RootView,Route,RouteDestination,Routing/LinkRouter}.swift`

**Interfaces & Rules:**
- **Strict module isolation (`apps/ios/AGENTS.md` §3):** `OverviewFeature` imports only `Domain`, `DesignSystem`, `PreviewSupport`. Navigation actions from `OverviewView` / `PersonalLedgerView` accept closures (`onOpenGroup`, `onOpenTransaction`, `onOpenBalances`, `onOpenPersonalLedger`) wired inside `AppShell`.
- **4-Tab `TabView` (`RootView`):**
  - `.overview` (`Tổng quan`) -> `OverviewView` (net balance hero: `Tổng được nhận` / `Tổng cần trả` / `Chênh lệch ròng` or `Bạn đã sòng phẳng ở tất cả nhóm`; `Cần bạn xử lý` queue; `Số dư theo nhóm` list; `Giao dịch gần đây của bạn` + `Xem tất cả giao dịch` -> `PersonalLedgerView`).
  - `.groups` (`Nhóm`) -> `GroupListView` with segmented `Đang mở` / `Đã lưu trữ` toggle, `role` & `pendingActionCount` badges, swipe/context Archive/Unarchive (owner) & Clone (owner/editor).
  - `.notifications` (`Thông báo`) -> `NotificationsView` with live unread count `.badge(...)`.
  - `.account` (`Tài khoản`) -> `AccountView`.
- **Unified Routing:**
  - Each tab keeps its own `NavigationStack(path:)`.
  - Deep links (`/join/{token}`), push notifications (`LinkRouter.pushDestination`), and Overview jumps replace/reset the target tab's navigation stack before pushing the destination route so stale screens never remain underneath.
  - `OfflineBanner` stays visible across all 4 tabs; mutating actions (`Tạo nhóm`, `Lưu trữ`, `Khôi phục`, `Nhân bản`) disable gracefully offline.
- **Clone Sheet:** Pre-fills `"{oldName} (bản sao)"`, `Sao chép thông tin nhận tiền` toggle (default `true`), `Sao chép danh mục tuỳ chỉnh` toggle (default `false`), enforces single-instance `IdempotencyKey`, and navigates straight into the newly cloned active group.

**Exercises:**
- [ ] Run Simulator walk-through across all 4 tabs: verify Overview totals, tap a `settlement_confirmation` / `expense_approval` pending item jumping to the right group screen, browse `PersonalLedgerView` with search & group filter, archive a group (verify moved to `Đã lưu trữ`), clone it (verify payment methods copied & zero transactions), unarchive it, and verify push & Universal Link tab switching.
- [ ] Run `xcodebuild` Debug, `xcrun swift-format lint --strict --recursive apps/ios`, `./apps/ios/Scripts/check-strings.sh`, and commit: `feat(ios): add 4-tab shell, overview feature, personal ledger, and group archive/clone`.

---

### Task 5.5A.3.3: Web 4-Tab Mobile Shell, Overview (`/`), Groups (`/groups`), Personal Ledger (`/ledger`), Archive & Clone

**Files:**
- New `apps/web/src/lib/overview.ts`
- `apps/web/src/lib/{groups,transactions}.ts`
- New `apps/web/src/components/layout/AppShell.tsx` (mobile bottom 4-tab bar `< 1024px`, wrapper shared across signed-in routes; Desktop sidebar arrives in `5.5A.5.1`)
- New `apps/web/src/components/overview/{OverviewSummaryCard,PendingActionsList,PersonalLedgerList}.tsx`
- `apps/web/src/components/groups/{GroupCard,FeaturedGroupCard}.tsx` and new `{ArchiveGroupDialog,CloneGroupDialog}.tsx`
- `apps/web/src/app/{page,notifications/page,account/page}.tsx` and new `apps/web/src/app/{groups/page,ledger/page}.tsx`
- `apps/web/src/app/g/[groupId]/settings/page.tsx`

**Interfaces & Rules:**
- Signed-in `/` renders **Tổng quan** (`Overview`); `/groups` renders **Nhóm** (`Đang mở` / `Đã lưu trữ`); `/ledger` renders **Giao dịch của bạn** (`PersonalLedgerList` with search, group dropdown, type filter, cursor Load More).
- `AppShell.tsx` renders the fixed bottom 4-tab navigation bar (`Tổng quan`, `Nhóm`, `Thông báo` with unread count badge, `Tài khoản`) on mobile/narrow viewports for all signed-in root pages (`< 1024px`), leaving auth/join pages (`/login`, `/register`, `/forgot-password`, `/reset-password`, `/verify-email`, `/join/[token]`) clean without the tab bar.
- Group settings & group cards expose Archive/Unarchive (`owner`) and Clone (`owner`/`editor`) dialogs with identical Vietnamese strings and behavior to iOS.

**Exercises:**
- [ ] Open Web at `390×844` in Light and Dark modes; verify `/` Overview totals match iOS Simulator and API `GET /me/overview` exactly.
- [ ] Exercise `/groups` `Đang mở` / `Đã lưu trữ` tabs, Archive -> confirm read-only notice, Clone -> confirm lands in new active group, Unarchive, and `/ledger` filtering + pagination.
- [ ] Run `pnpm check`, `pnpm build`, and commit: `feat(web): add 4-tab shell, overview, personal ledger, and group archive/clone`.

---

### Task 5.5A.3.4: Stage 5.5A.3 Shell & Overview Gate

**Files:** `docs/superpowers/runs/phase-5-5a/{progress,decisions}.md` and `screens/5-5a-3/`.

- [ ] Verify end-to-end parity between API, Web (`/` + `/groups` + `/ledger`), and iOS Simulator across two active groups + one archived group.
- [ ] Remove a member/user from a group while signed in and confirm both Web & iOS drop the removed group from Overview/Personal Ledger and clear iOS snapshots on sign-out.
- [ ] Run `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, Simulator Debug `xcodebuild`, and `pnpm db:check-balances`.
- [ ] Save screenshots under `screens/5-5a-3/` and commit: `docs(run): record Wave 5.5A.3 shell and overview gate`.
