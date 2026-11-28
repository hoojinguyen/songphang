# Phase 5.6 — Stage B: Navigation

> Paths are relative to `apps/ios/SongPhangKit/Sources/` unless they start with `apps/` or `docs/`. Stage B changes navigation chrome and routing only. Screen content below the bar keeps its structure (segments, cards, rows stay until 5.7).

### Task 5.6.B.1: Native navigation bars

Closes: B01 (F2-01), B19 (F4-40), F2-02, F2-03, F2-126, F2-129.

**Files:**
- Modify (pushed screens that hide the system back button today): `AccountFeature/Account/AccountView.swift`, `AppShell/GroupContainerView.swift`, `AuthFeature/ForgotPassword/ForgotPasswordView.swift`, `AuthFeature/Register/RegisterView.swift`, `GroupsFeature/CreateGroup/CreateGroupView.swift`, `GroupsFeature/GroupSettings/GroupSettingsView.swift`, `GroupsFeature/Members/MembersView.swift`, `LedgerFeature/Activity/ActivityView.swift`, `LedgerFeature/Balances/BalancesView.swift`, `LedgerFeature/ExpenseForm/ExpenseFormView.swift`, `LedgerFeature/GroupFeed/GroupFeedView.swift`, `LedgerFeature/QuickEntry/QuickEntryView.swift`, `LedgerFeature/ReceiptReview/ReceiptReviewView.swift`, `LedgerFeature/Settle/SettleView.swift`, `OverviewFeature/PersonalLedger/PersonalLedgerView.swift`, `PaymentsFeature/Fund/FundView.swift`, `StatisticsFeature/Stats/StatsView.swift`
- Modify: `LedgerFeature/TransactionDetail/*` (the screen that showed two back buttons), `NotificationsFeature/Inbox/NotificationsView.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift` (custom chevrons found by the re-baseline)
- Modify: `AppShell/RouteDestination.swift`, `AppShell/RootView.swift`, `DesignSystem/Components/LoginShapesAndHeader.swift` (`SPScreenHeader` stays for the sign-in hero only)
- Delete: `AppShell/PopGestureEnabler.swift`, `AppShell/StatusBarCover.swift`

**Interfaces:**
- Consumes: Task 5.6.A.3 (title fonts), Task 5.6.A.1 (motion).
- Produces: every pushed screen sets `.navigationTitle` and display mode (inline for details and tasks; large for Account and Notifications) and puts trailing actions in `ToolbarItem`s. `SPScreenHeader`'s subtitle, where it carried information (for example a group name under a screen title), moves into the first line of content.
- Produces: the group container shows the group name as the inline title; the member-shapes capsule (opens members) and the overflow menu become trailing toolbar items. The segment control stays in the content for now.
- Produces: every tab root (Overview, Groups, Notifications, Account) inside a `NavigationStack` with a navigation bar, so the iOS 26 scroll edge effect keeps the status bar readable. Overview and Groups keep their greeting headers in content and use an empty inline title.

- [ ] **Step 1: One screen end to end.** Convert `ActivityView`: remove `.navigationBarBackButtonHidden(true)` and its `SPScreenHeader`, add title and toolbar. Run, swipe back, scroll under the bar, capture light and dark. Record the pattern in `decisions.md` so the rest follow it exactly.
- [ ] **Step 2: Convert the remaining pushed screens** and the screens with their own chevrons, following Step 1. Keep each screen's content order.
- [ ] **Step 3: Group container toolbar.** Title, capsule and menu in the bar; remove the in-content header. Confirm the menu's items and their order are unchanged (5.6.B.3 changes only the categories item).
- [ ] **Step 4: Remove the patches.** Delete `PopGestureEnabler` and `StatusBarCover` and their two uses in `RootView`. Put tab roots under navigation bars.
- [ ] **Step 5: Exercise.** For every case in `Route.swift` (use the `--route-*` flags and in-app taps): one back control, swipe-back from the left edge works, title readable, no content under the clock after scrolling, at default and largest text size. Transaction detail shows one back button (B01). Account scrolled to the bottom keeps the clock clear (B19). Save captures to `screens/stage-b/`.
- [ ] **Step 6: Gate and commit.** `git commit -m "feat(ios): use native navigation bars and remove custom header patches"`

---

### Task 5.6.B.2: Tab bar visibility and in-tab navigation

Closes: F2-04, F2-05, F2-06.

**Files:**
- Modify: `AppShell/RouteDestination.swift`, `AppShell/RootView.swift`

**Interfaces:**
- Produces: the tab bar is visible on content screens and hidden only on `quickEntry`, `newTransactionForm`, `editTransaction`, `settle`, `receiptReview` (decided per `Route` case in one place).
- Produces: `navigate(to:)` and the Overview, Notifications and Personal Ledger callbacks append to the path of the currently selected tab. `RootView` keeps one path per tab (it already does) and a helper "append to the current tab's path". Explicit tab changes remain only where the user taps a tab or a link that names another tab. Deep links, push targets and `--route-*` flags keep opening in the Groups stack (they start outside any tab).

- [ ] **Step 1: Tab bar rule** in one switch over `Route`. Check on the Simulator that going back from a hidden-bar screen to a visible-bar screen does not jump; if it does on a screen, keep the bar hidden there and record why.
- [ ] **Step 2: In-tab navigation.** Replace the `selectedTab = .groups; groupsPath = [...]` callbacks from Overview (`onOpenGroup`, `onOpenBalances`, `onOpenTransaction`) and the Notifications callbacks with appends to the current tab's path. Keep `navigate(to:)` for routes that must change tab (account, notifications) and record which.
- [ ] **Step 3: Exercise.** From Overview open a group, then Back → Overview. From Overview open a transaction → detail, Back → Overview. From Notifications open a transaction, Back → Notifications. Open a `songphang://` group link and a scripted push target → Groups stack as before. Record each path.
- [ ] **Step 4: Gate and commit.** `git commit -m "feat(ios): keep navigation inside the current tab and show the tab bar on content screens"`

---

### Task 5.6.B.3: Landing, unavailable screens and the categories entry, Stage B gate

Closes: B10 (F4-10), B09 (F3-48, F3-49), F3-47, B18 (F4-36, F4-51), F4-05 and F4-06 (clone part).

**Files:**
- Create: `AppShell/GroupUnavailableView.swift` (or in the group container's folder; record the choice)
- Modify: `AppShell/GroupContainerView.swift`, `AppShell/RootView.swift`, `AppShell/RouteDestination.swift`
- Modify: `GroupsFeature/GroupList/GroupListView.swift`, `GroupsFeature/GroupSettings/GroupSettingsView.swift`, `GroupsFeature/CloneGroup/*` (clone completion)
- Modify: `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/copy-changes.md` (toast text)

**Interfaces:**
- Consumes: `ConfirmationToast` (5.6.A.6).
- Produces: `GroupUnavailableView(kind: .notFound | .forbidden)` — full screen inside the current stack, native back button, the existing messages (`common.groupNotFound`, `common.forbidden`) and the existing "Về danh sách nhóm" action; never draws the group header, capsule or segments. The group container and group settings use it instead of their inline states.
- Produces: clone completion replaces the source group's route in the current path with the new group's route (Back returns to the list) and shows the toast "Đã tạo {name}". Applies to the three clone entry points (group list, group container, group settings).
- Produces: the overflow item "Danh mục của nhóm" shown only to roles allowed to manage categories (read the rule from the existing settings permission check), opening settings scrolled to the categories section through a `ScrollViewReader` anchor passed as an optional route parameter or initial-section value (record the shape; deep links stay compatible).

- [ ] **Step 1: `GroupUnavailableView`** and its use in the container and settings. Exercise with an unknown group id and with `--role-editor` opening settings.
- [ ] **Step 2: Clone landing** from all three entry points; exercise each: new group's title below the bar, toast shown, Back → group list.
- [ ] **Step 3: Categories entry.** Owner: item visible, settings opens at categories. Editor and viewer (`--role-editor`, `--role-viewer`): item absent.
- [ ] **Step 4: Stage B gate.** iOS gate; `pnpm check`; every `Route` case opened and captured in `screens/stage-b/`; confirm `PopGestureEnabler` and `StatusBarCover` no longer exist (`grep` shows nothing). Record in `progress.md`.
- [ ] **Step 5: Commit.** `git commit -m "feat(ios): land flows in place, add unavailable group screen and gate the categories entry"`
