# Phase 5.6 — Stage C: Apply

> Paths are relative to `apps/ios/SongPhangKit/Sources/` unless they start with `apps/` or `docs/`. Stage C adopts the Stage A pieces across the existing screens. It does not reorder screen content, remove sections, or change flows that 5.7 and 5.8 redesign; when a change would, record it under "Out of scope" with the owning phase.

### Task 5.6.C.1: Sheets applied

Closes: F2-29, F2-30, F2-31, F2-32, F4-03, F4-04 (application), F2-130.

**Files:**
- Modify: every file presenting a `.sheet` or `.fullScreenCover` (32 at the re-baseline), among them `AppShell/{GroupContainerView,RouteDestination,RootView}.swift`, `GroupsFeature/{GroupList/GroupListView,GroupSettings/GroupSettingsView,Members/HouseholdsSectionView,GuestShare/GuestGroupView}.swift`, `LedgerFeature/{ExpenseForm/ExpenseFormView,TransactionDetail/ApprovalBlockView,TransactionDetail/DisputeBlockView,ReceiptReview/ReceiptReviewView,ReceiptCapture/ReceiptCaptureSheet,Balances/BalancesView,GroupFeed/GroupFeedView}.swift`, `PaymentsFeature/PaymentDetails/PaymentDetailsView.swift`, `StatisticsFeature/{Stats/StatsView,Recurring/RecurringSectionView}.swift`, `AccountFeature/Account/TelegramAccountCardView.swift`, `DesignSystem/Components/PhotoAttachmentViews.swift`, `AppShell/Push/PushPermissionSheet.swift`, `PaymentsFeature/Fund/CreateFundSheetView.swift`
- Modify: the sheet views whose dismiss controls change (back arrows, "Thôi", visible "Đóng", "Quay lại")
- Modify: `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/{decisions,copy-changes}.md`

**Interfaces:**
- Consumes: `.spSheet`, `.discardGuard`, `SheetCloseButton`, `SheetCancelButton` (5.6.A.4).
- Produces: an inventory table in `decisions.md` — presentation, file, current height, new `SheetSize`, dismiss control, discard guard yes/no. Targets from spec section 5.3 are binding; others are classified by the rules of spec section 5.1.

- [ ] **Step 1: Inventory** all presentations and classify them.
- [ ] **Step 2: Apply sizes.** `.fitted` for small confirmation and info sheets (pay and "Đã nhận", guest link, close cycle, delete group, clone group); `.half` for debt explanation, create fund, payment details; `.form` for the recurring and household forms; camera stays full screen; the filter sheet keeps its current behaviour through `.half`.
- [ ] **Step 3: Dismiss controls.** View-only sheets: `SheetCloseButton`. Sheets that change data: `SheetCancelButton` and the main action at the bottom. Remove back arrows inside sheets (payment details, pay sheet); steps inside a sheet push inside the sheet's own `NavigationStack`. Replace visible "Thôi", "Đóng" and "Quay lại" in sheets; keep "Để sau" on the push-permission pre-prompt only. Record every string change.
- [ ] **Step 4: Discard guard** on sheets with entered data (recurring form, household form, dispute, payment details, and any other sheet the inventory marks as editing).
- [ ] **Step 5: Exercise.** Open every sheet at default and largest text size, light and dark; type into each form sheet and swipe down (asks first); capture to `screens/stage-c/sheets/`.
- [ ] **Step 6: Gate and commit.** `git commit -m "feat(ios): size sheets to content and unify sheet dismiss controls"`

---

### Task 5.6.C.2: Loading and states

Closes: B20 (F4-43, F4-44, F4-45), F4-42, F1-52 (adoption), F2-57 (no entrance motion).

**Files:**
- Modify: `AppShell/GroupContainerView.swift`, `AppShell/RootView.swift`, `AppShell/RouteDestination.swift`
- Modify: `LedgerFeature/GroupFeed/GroupFeedView.swift`, `LedgerFeature/Balances/BalancesView.swift`, `OverviewFeature/Overview/OverviewView.swift`, `GroupsFeature/GroupList/GroupListView.swift`, and the 8 files using `ProgressView(` found at re-baseline
- Modify: `DesignSystem/States/StateViews.swift` (`LoadingSkeleton` built from skeleton blocks)

**Interfaces:**
- Consumes: skeleton blocks and `ShapeLoader` (5.6.A.6).
- Produces: opening a group shows its name and member shapes from data already in memory (group list or overview models) through a lookup passed by `AppShell`; `Route` and deep links do not change. When nothing is in memory (cold deep link), the title shows a skeleton line, never an empty string or an empty capsule.
- Produces: the group composer is in the layout from the first frame, disabled until the group loads.
- Produces: per-screen skeletons for the group feed (balance card, link row, search, rows), balances, overview and group list that follow each screen's real layout.
- Produces: `ShapeLoader` replaces spinners where a whole area is waiting; small inline progress (inside a button) stays as the system's.

- [ ] **Step 1: Known group header** from memory; cold-start fallback.
- [ ] **Step 2: Composer from the first frame.**
- [ ] **Step 3: Layout-shaped skeletons** and spinner replacement. No entrance animation when data arrives.
- [ ] **Step 4: Exercise** with `--scripted --latency-2s --no-snapshot`: open a group from the list (name and shapes at once, composer present, no jump) and from a deep link (skeleton title); compare against the part 4 "slow" capture; save to `screens/stage-c/loading/`. With a snapshot present (no `--no-snapshot`), the stored content appears at once (F4-42).
- [ ] **Step 5: Gate and commit.** `git commit -m "feat(ios): show known group header at once and use layout-shaped loading"`

---

### Task 5.6.C.3: Feedback wiring and component adoption

Closes: F1-32, F1-59 (wiring), F1-51 and F2-55 (adoption), F2-54 (adoption), F4-05 and F4-06 (toast adoption), F4-01 and F4-02 (adoption), F2-56 and F1-49 (adoption), F1-50.

**Files:**
- Modify: `LedgerFeature/ExpenseForm/{ExpenseFormView,ExpenseFormModel,ExpenseFormSubViews}.swift`, `LedgerFeature/QuickEntry/QuickEntryView.swift`, `LedgerFeature/Settle/SettleView.swift`, `LedgerFeature/Balances/BalancesView.swift` (all-settled state)
- Modify (copy buttons): `AccountFeature/Account/TelegramPairingSheetView.swift`, `LedgerFeature/Balances/ShareCardPreviewSheet.swift`, `PaymentsFeature/Pay/PayView.swift`, `GroupsFeature/GuestShare/{GuestLinkSheetView,GuestGroupView}.swift`, `GroupsFeature/Members/MembersView.swift`, `GroupsFeature/GroupSettings/TelegramGroupCardView.swift`
- Modify (toasts): `LedgerFeature/Activity/{ActivityView,ActivityModel}.swift`, `LedgerFeature/GroupFeed/{GroupFeedView,GroupFeedModel}.swift`
- Modify (pickers): `LedgerFeature/ExpenseForm/ExpenseFormSubViews.swift` (`MemberToggleGridView` and the payer choice), `StatisticsFeature/Recurring/RecurringFormSheetView.swift` (text chips), `LedgerFeature/ReceiptReview/{ReceiptReviewView,ReceiptItemsAssignmentView}.swift`
- Modify: `GroupsFeature/CreateGroup/CreateGroupView.swift` (field shake on invalid save)

**Interfaces:**
- Consumes: `.spFeedback`, `SoundPlayer`, `ShapeBurst`, `.fieldShake`, `CopyButton`, `ConfirmationToast`, `MemberPicker`.
- Produces, money moments (user's own action only, after the server confirms):
  - expense saved from the form or quick entry → coin + `.success`;
  - payment recorded in Settle → ting + `.success`;
  - the group reaching "all settled" right after the user's own action → chord + three `.success` beats spaced ~120 ms + `ShapeBurst` over the all-settled card. Opening a group that was already settled plays nothing.
- Produces: invalid save (missing amount, missing name) → `.fieldShake` on the field.
- Produces: the 7 copy buttons use `CopyButton` and their copy toasts are removed; the feed and activity toasts use `ConfirmationToast`.
- Produces: `MemberPicker` replaces the payer choice and participant grid of the expense form, the text chips of the recurring form, and the people rows of receipt review ("Ai trả?" and the item assignment row), each with a title saying what it picks for. Multi-payer amount entry (`PayerAmountsView`) is unchanged.
- Produces: segmented controls and chips use the 5.6.A.1 slide and `.selection` feedback; swipe actions are the system's `.swipeActions` (convert any custom swipe found, or record none).

- [ ] **Step 1: Money moments.** Wire the three moments at the point where the model reports success; confirm no feedback on failure or on realtime updates from others (trigger an update through the fake realtime path if one exists, otherwise record "Not verified").
- [ ] **Step 2: Field shake** on the expense form, quick entry and create group invalid saves.
- [ ] **Step 3: Copy buttons and toasts.**
- [ ] **Step 4: Member picker adoption** in the three forms. Exercise: create an expense choosing payer and participants; create a recurring item; assign receipt items (receipt flow via `--scripted` with features loaded).
- [ ] **Step 5: Exercise all moments** and record per action: sound (Simulator audio), haptic (logged in DEBUG), motion. Double-tap Save on the expense form creates one expense (existing idempotency) and one feedback.
- [ ] **Step 6: Gate and commit.** `git commit -m "feat(ios): wire money feedback and adopt shared pickers, copy buttons and toasts"`

---

### Task 5.6.C.4: Dynamic Type, VoiceOver and copy, Stage C gate

Closes: B07 (F3-27, F3-28), F4-54, F2-119, F2-120, F2-121 (component part), F2-128, F1-30, F1-04, F1-75, F2-131, F2-42, F2-45, F2-124, F1-28, F1-29 (rules recorded).

**Files:**
- Modify: the files with `.font(.system(size:` (54 at re-baseline; the top ones are `LedgerFeature/GroupFeed/GroupFeedSubViews.swift`, `DesignSystem/Components/PhotoAttachmentViews.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift`, `GroupsFeature/GuestShare/GuestGroupView.swift`)
- Modify: `LedgerFeature/Settle/SettleView.swift`, `LedgerFeature/Balances/BalancesView.swift`, `LedgerFeature/ExpenseForm/*` (the B07 evidence screens)
- Modify: views with icon-only buttons lacking a VoiceOver label (found by search for `Image(systemName:` inside `Button` without `accessibilityLabel`)
- Modify: views writing "{name} trả" or similar person labels, views writing "đồng"
- Modify: `GroupsFeature/CreateGroup/CreateGroupView.swift` (placeholder)
- Modify: `apps/ios/Scripts/check-strings.sh`
- Modify: `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/{decisions,copy-changes}.md`

**Interfaces:**
- Produces: no fixed font sizes remain except where a size is decorative and scaled with `@ScaledMetric` (each such case recorded). Settle and the expense form read correctly at the largest accessibility size; horizontal rows use `AdaptiveStack`.
- Produces: every icon-only button has a Vietnamese VoiceOver label; every `MemberShapeView` reads the member's name.
- Produces: person labels go through `PersonName.display`; amounts go through `MoneyText` roles; "đồng" next to an amount is gone.
- Produces: the new-group name placeholder "Đà Lạt cuối tuần".
- Produces: in `decisions.md`, the inventory of all strings over 60 characters (38 at re-baseline) with key, screen and owning phase (5.7 or 5.8); none is shortened here unless it belongs to spec section 11.2.
- Produces: `check-strings.sh` accepts a key that is missing, differing or extra only when it is listed in a `docs/superpowers/runs/phase-5-*/copy-changes.md` table, prints those as `ALLOWED (copy-changes): <key>`, and still fails on any unlisted difference. The summary line reports verified, allowed and failing counts.

- [ ] **Step 1: Font sweep** with the mapping table recorded in 5.6.A.3.
- [ ] **Step 2: B07 screens** at the largest accessibility size: Settle and the expense form readable, nothing clipped or overlapping. Capture before/after.
- [ ] **Step 3: VoiceOver labels.** Search, label, then run VoiceOver in the Simulator (Accessibility Inspector) over the group screen, Settle and the expense form; record what is read.
- [ ] **Step 4: Copy rules in scope** (spec section 11.2): dismiss words already done in C.1, person labels, money roles, placeholder, toast and setting texts. Write every change to `copy-changes.md`.
- [ ] **Step 5: Long-string inventory** in `decisions.md`.
- [ ] **Step 6: `check-strings.sh` allowlist.** Implement; then prove it: change one catalog value without recording it → script fails; record it → script passes with `ALLOWED`. Revert the test change.
- [ ] **Step 7: Stage C gate.** iOS gate; `pnpm check`; the screenshot set of spec section 13.1 for every screen touched in Stage C (light, dark, largest text, iPhone SE, `--scenario-large`) into `screens/stage-c/`; record in `progress.md`.
- [ ] **Step 8: Commit.** `git commit -m "feat(ios): scale all text, label icon buttons and apply v3 copy rules"`
