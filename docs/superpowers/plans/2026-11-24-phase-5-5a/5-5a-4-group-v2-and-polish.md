# Wave 5.5A — Stage 5.5A.4: Group Screen v2, Dense-Group Fixes, Haptics, Swipe & "Bơm hình"

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md).

### Task 5.5A.4.1: iOS Group Screen v2 (`GroupContainerView` 3-Segment Shell), Full-Width Feed Cards (`TD-006`), Collapsible Filters & Swipe Actions

**Files:**
- New `apps/ios/SongPhangKit/Sources/AppShell/GroupContainerView.swift`
- `apps/ios/SongPhangKit/Sources/AppShell/{Route,RouteDestination}.swift`
- `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/{GroupFeedView,GroupFeedSubViews,GroupFeedModel,FilterSheetView}.swift`
- `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/{BalancesView,BalancesModel}.swift`
- `apps/ios/SongPhangKit/Sources/PaymentsFeature/Fund/{FundView,FundModel}.swift`
- `apps/ios/SongPhangKit/Sources/StatisticsFeature/Stats/{StatsView,StatsModel}.swift`
- `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupSettings/BudgetSettingsCard.swift` (or embedded budget progress helper if reusable via `Domain`/`DesignSystem` — remember **no cross-feature imports** per `apps/ios/AGENTS.md` §3! Host/compose feature views inside `AppShell/GroupContainerView.swift`).

**Interfaces & Rules:**
- **Module boundary rule (`apps/ios/AGENTS.md` §3):** `LedgerFeature`, `PaymentsFeature`, `StatisticsFeature`, and `GroupsFeature` remain strictly isolated from each other. `GroupContainerView` lives in `AppShell` and renders:
  - Compact persistent header: Back button, group name + `Đã lưu trữ` pill (when `group.isArchived`), tappable member-shapes cluster (opens `MembersView`), and overflow menu (`...`: `Lịch sử thay đổi`, `Danh mục`, `Telegram`, `Nhân bản nhóm`, `Lưu trữ nhóm` / `Khôi phục nhóm`, `Cài đặt nhóm`).
  - 3-segment switcher (`Chi tiêu` | `Thanh toán` | `Quỹ & Thống kê`):
    - `Chi tiêu` (`GroupFeedView`): Collapsible search + `Lọc` pill (shows active count badge when filters applied), slim budget alert banner (only when near/over budget), full-width transaction feed grouped by date, pinned bottom Quick Entry bar (`Manual` + input + `Camera`). When `group.isArchived`, replace bottom entry bar with read-only notice `Nhóm đã lưu trữ — chỉ xem`.
    - `Thanh toán` (`BalancesView`): My net status hero, suggested transfers (VietQR, `Tôi đã chuyển`, `Đã nhận`, direct settle), `Cán cân của nhóm`.
    - `Quỹ & Thống kê`: Composed in `AppShell` from `FundView` (or setup card), budget limit progress card, and `StatsView` (`Tiền đi đâu` + CSV Export).
- **Full-Width Feed Cards (`TD-006` fix):**
  - Remove chat-bubble left/right `48pt` indent offsets and remove inline per-person split amount chips (`35.715` wrapped across 3 lines in `TD-006`) from `GroupFeedSubViews.swift`.
  - Render each expense/income as a 3-row full-width `surface` card (`24pt` corner radius):
    1. Top row: Payer `MemberShapeView` (`28pt`) + `"Bạn trả"` or `"{name} trả"` (or multi-payer/fund badge) + short timestamp + status indicators (`Đã sửa`, comment count, `Chờ duyệt`, `Đang phản đối`).
    2. Middle row: Description (max 2 lines) + category chip on the left; right-aligned numeric stack with **Total Amount** (`MoneyText`, single-line `monospacedDigit`) above **"Phần của bạn"** signed delta (`myDelta` from server: `+` in `Tokens.credit`, `-` in `Tokens.debt`, or `Không tham gia` in `Tokens.muted`).
    3. Bottom row: Overlapping cluster of up to 5 participant shapes + `+N` counter + split method label.
  - Render transfers as compact full-width cards (`From -> To`, `"{from} đã chuyển {to}"`, right-aligned tabular amount).
- **Haptics & Swipe Actions:**
  - Trigger `Haptics` on Quick Entry parse success, transaction save, settlement confirmation, and swipe triggers.
  - Enable `List` / card swipe actions in `Chi tiêu` only when `!group.isArchived && isOnline`:
    - Leading (`canEdit` & active & not rejected): `Sửa` -> opens `EditTransaction`.
    - Trailing: `Xoá` (destructive, `canEdit`, soft-delete + undo notice) and `Chi tiết` / `Phản đối`.

**Exercises:**
- [ ] On Simulator (compact portrait iPhone width + large accessibility Dynamic Type), load a group with a 7-person `250.000 đ` split and a 20-member group (`TD-006`): verify zero horizontal overflow, zero wrapped currency digits, and clean switching across all 3 segments (`Chi tiêu`, `Thanh toán`, `Quỹ & Thống kê`).
- [ ] Exercise swipe `Sửa` and swipe `Xoá` + undo on an active group; archive the group and confirm swipe actions and bottom Quick Entry dock are disabled with `Nhóm đã lưu trữ — chỉ xem`.
- [ ] Run `xcodebuild` Debug + `xcrun swift-format lint --strict --recursive apps/ios` and commit: `feat(ios): redesign group screen with 3-segment shell, full-width cards, and swipe actions`.

---

### Task 5.5A.4.2: iOS Form/Quick-Entry Fixes (`TD-003`, `TD-005`, `TD-007`) & "Bơm hình"

**Files:**
- `apps/ios/SongPhangKit/Sources/GroupsFeature/CreateGroup/CreateGroupView.swift`
- `apps/ios/SongPhangKit/Sources/LedgerFeature/ConfirmCard/{ConfirmationCardView,ShareShapesView}.swift`
- `apps/ios/SongPhangKit/Sources/LedgerFeature/SplitEditor/{SplitEditorView,SplitEditorState}.swift`
- `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/GroupFeedView.swift` (verify `feed.tripTotal` `"Tổng chuyến đi"` for `TD-007`)

**Interfaces & Rules:**
- **`TD-003` (`CreateGroupView.swift`):**
  - Wrap the form in `ScrollViewReader` with explicit row IDs on the `NewMemberInputRow`, last added member row, and validation error banner.
  - On `model.addedMembers.count` change and focus on the new-member input, smoothly scroll the input row into view above the keyboard.
  - Keep the primary submit button (`Tạo nhóm`) cleanly anchored in `.safeAreaInset(edge: .bottom)` with background material/surface, and remove/coordinate any conflicting keyboard toolbar so `Tạo nhóm` is never obscured by the software keyboard or its Done accessory across portrait iPhone sizes and large Dynamic Type.
- **`TD-005` (`ConfirmationCardView.swift` & `ShareShapesView.swift`):**
  - Replace the single horizontal `HStack` in `ShareShapesView` with a responsive wrapping `LazyVGrid` (`4` adaptive columns on compact iPhone width) inside a bounded scrollable container in `ConfirmationCardView`.
  - Keep total, description, participant amounts (`.monospacedDigit()`, `.lineLimit(1)`, `.minimumScaleFactor(0.75)`), `"Chưa có gì được lưu"`, and `Chỉnh tay` / `Lưu` buttons strictly inside the viewport on 7–20 participant splits (`375pt` width) and large Dynamic Type.
- **`TD-007`:** Verify `"Tổng chuyến đi"` renders cleanly where group statistics is opened (`Quỹ & Thống kê` / header link) and passes `check-strings.sh`.
- **"Bơm hình" (`SplitEditorView.swift` & `SplitEditorState.swift`):**
  - Available under `Theo phần` (`shares`), `Theo %` (`percent`), and `Số tiền` (`exact`) split modes.
  - Display selected participants in a wrapping grid of interactive `MemberShapeView` badges above/alongside the numeric input rows.
  - **Hold-to-grow gesture:** Pressing and holding a member shape triggers a repeating task (`250ms` initial press delay, then `180ms` step interval while pressed) that increments that member's allocation by a discrete step:
    - `Theo phần`: `+1` integer weight on held member.
    - `Theo %`: `+5%` on held member (clamped to `100%`), reducing other selected members in clean integer percentage steps while preserving `100%` sum.
    - `Số tiền`: increments the held member's integer `Money` amount by a fixed integer step (`+10.000 đ`, or `+1.000 đ` when `totalAmount < 100.000 đ`, clamped to `[0, totalAmount]`) using **integer addition/subtraction only** — never floating-point arithmetic, multiplication, or division on `Money` (`apps/ios/AGENTS.md` §5).
  - Animate the held shape scale (`300ms` spring; instant when `accessibilityReduceMotion` is true) and emit `Haptics.light()` on each increment.
  - On gesture release (or short debounce), call the existing server preview (`transactions.preview`) so all displayed split totals and status banners remain 100% server-authoritative.
  - Keep direct numeric text fields visible and wire `.accessibilityAdjustableAction` + `.accessibilityHint(L10n.tr("split.holdToGrowHint"))` (`"Nhấn giữ để tăng phần chia"`).

**Exercises:**
- [ ] Simulator test `CreateGroupView` (`TD-003`): add 10+ members with keyboard open; confirm newly added row and input stay visible and `Tạo nhóm` remains fully visible/tappable when keyboard is open and dismissed, at normal and accessibility Dynamic Type.
- [ ] Simulator test Quick Entry (`TD-005`): in a 7-person and a 15-person group, pick a sample splitting across all members; confirm zero edge clipping and full visibility of header, total, shares, and actions.
- [ ] Simulator test "Bơm hình": hold member shapes across `Theo phần`, `Theo %`, and `Số tiền`; verify smooth scale animation, server preview sync, exact saved shares matching server/API, and direct keyboard numeric override.
- [ ] Run `xcodebuild` Debug + `xcrun swift-format lint --strict --recursive apps/ios` and commit: `feat(ios): fix keyboard/confirmation layout debt and add hold-to-grow split interaction`.

---

### Task 5.5A.4.3: Web Group Screen v2 (3-Segment Shell), Full-Width Feed Cards, Quick Entry Wrap & Web "Bơm hình"

**Files:**
- `apps/web/src/app/g/[groupId]/{layout,page,balances/page,stats/page,fund/page}.tsx`
- `apps/web/src/components/feed/{ExpenseRow,ExpenseStream,StreamSearchBar,EntryBar,FilterSheet,BalanceBlock,BudgetBanner}.tsx`
- `apps/web/src/components/quick-entry/{ConfirmationCard,ShareShapes}.tsx`
- `apps/web/src/components/expense-form/{SplitEditor,use-split-state}.ts` (note `.tsx` for `SplitEditor.tsx`, `.ts` for `use-split-state.ts`)

**Interfaces & Rules:**
- **3-Segment Group Layout (`apps/web/src/app/g/[groupId]/layout.tsx` & `page.tsx`):**
  - Mirror iOS compact persistent header + 3-segment switcher (`Chi tiêu` | `Thanh toán` | `Quỹ & Thống kê`).
  - Keep existing Web sub-routes (`/balances`, `/stats`, `/fund`, `/members`, `/activity`, `/settings`, `/tx/*`) fully functional; visiting `/balances` or `/stats` or `/fund` highlights the active segment inside the shared group shell so direct URLs and browser history continue working seamlessly.
  - When `group.archivedAt !== null`, display `Đã lưu trữ` badge, show `Nhóm đã lưu trữ — chỉ xem` banner instead of bottom `EntryBar`, and disable edit/delete/settle mutation controls.
- **Full-Width Feed Cards (`ExpenseRow.tsx`):**
  - Replace chat bubbles and inline participant share chips with the identical 3-row Full-Width Card showing server `myDelta` (`+` `text-credit`, `-` `text-debt`, or `Không tham gia` `text-muted`), `tabular-nums`, and 5-shape + `+N` cluster.
- **Quick Entry Wrap (`ShareShapes.tsx` & `ConfirmationCard.tsx`):**
  - Use CSS Grid / wrapping flex layout so 7–20 participants wrap cleanly on `390px` mobile browser width with zero horizontal clipping.
- **Web "Bơm hình" (`SplitEditor.tsx` & `use-split-state.ts`):**
  - Mirror iOS hold-to-grow pointer/touch interaction (`onPointerDown` / `onPointerUp` / `onPointerCancel` / `onPointerLeave`) on `MemberShape` badges in `shares`, `percent`, and `exact` modes with discrete integer steps, `300ms` spring CSS transition (respecting `prefers-reduced-motion: reduce`), `aria-label` / `"Nhấn giữ để tăng phần chia"`, and server `/preview` sync on release/debounce.

**Exercises:**
- [ ] Verify Web mobile (`390×844`) Light & Dark modes across 7–20 member splits, Quick Entry sample confirmation, 3-segment switching, deep URL `/g/{id}/balances` + `/stats` + `/fund`, archived group read-only dock, and "Bơm hình" pointer hold saving exact shares matching DB.
- [ ] Run `pnpm check`, `pnpm build`, and commit: `feat(web): redesign group screen v2, full-width feed cards, and hold-to-grow split`.

---

### Task 5.5A.4.4: Stage 5.5A.4 Group & Polish Gate

**Files:** `docs/superpowers/runs/phase-5-5a/{progress,decisions}.md` and `screens/5-5a-4/`.

- [ ] Run `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, Simulator Debug `xcodebuild`, and `pnpm db:check-balances`.
- [ ] Capture Simulator & Web mobile screenshots under `screens/5-5a-4/` proving fixes for `TD-003`, `TD-005`, `TD-006` (Light + Dark + 7+ participants + Dynamic Type) and "Bơm hình".
- [ ] Commit: `docs(run): record Wave 5.5A.4 group v2 and polish gate`.
