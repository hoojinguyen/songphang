# Wave 5.5C — Stage 5.5C.3: iOS (`SongPhangKit`) Parity & System Extensions (`apps/ios/`)

> Runs in Wave 2 in parallel with Stage `5.5C.2` (`web`) **after** Stage `5.5C.1` is merged onto `phase-5-5c`. Touch **only** `apps/ios/**` (do not edit `Localizable.xcstrings`, which was locked in `5.5C.1.4` and verified by `check-strings.sh`). Obey every rule in `apps/ios/AGENTS.md` — features never import other features, `Repositories`, or `GeneratedAPI`; `Money` never multiplies, divides, or converts to floating-point; `SongPhangWidgetExtension` links only `Domain` and `DesignSystem`.

### Task 5.5C.3.1: `Domain` / `Repositories` / `PreviewSupport` for Wave 5.5C + App Group `ExtensionSharedStore` & Shared Keychain Migration

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/Domain/Models/{RecurringExpense,Household,ExtensionSharedModels}.swift`
- Create: `apps/ios/SongPhangKit/Sources/Domain/Repositories/{RecurringExpensesRepository,HouseholdsRepository}.swift`
- Create: `apps/ios/SongPhangKit/Sources/Domain/Extensions/ExtensionSharedStore.swift`
- Create: `apps/ios/SongPhangKit/Sources/Repositories/Transactions/LiveRecurringExpensesRepository.swift`
- Create: `apps/ios/SongPhangKit/Sources/Repositories/Groups/LiveHouseholdsRepository.swift`
- Create: `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeRecurringExpensesRepository,FakeHouseholdsRepository}.swift`
- Modify: `apps/ios/Config/{Debug,Release}.xcconfig`
- Modify: `apps/ios/App/{SongPhang.entitlements,Info.plist}`
- Modify: `apps/ios/Config/Info-Debug.plist`
- Modify: `apps/ios/SongPhangKit/Sources/Domain/Models/{Balance,ExpenseGroup,Member,MemberDebtBreakdown,GuestLink,LedgerTransaction,TransactionDraft,Overview,AppNotification,GroupEvent,AppError}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Domain/Repositories/TransactionsRepository.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Session/TokenStore.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Snapshots/SnapshotStore.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/{Transactions,Balances,Groups,Overview,Notifications,Realtime}/` (map 5.5C fields & SSE resources)
- Modify: `apps/ios/SongPhangKit/Sources/PreviewSupport/{Fakes,Samples,Scenarios}/`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift`

**Interfaces:**
- Consumes: Locked `packages/contract/openapi.json` (`GeneratedAPI` regenerates automatically during Xcode build).
- Produces:
  - Build settings `APP_GROUP_IDENTIFIER = group.vn.songphang.app` and `KEYCHAIN_ACCESS_GROUP = $(AppIdentifierPrefix)vn.songphang.app.shared`, `com.apple.security.application-groups` + `keychain-access-groups` in `SongPhang.entitlements`, and `CFBundleURLTypes` (`songphang` URL scheme) in `Info.plist` / `Info-Debug.plist`.
  - `TokenStore` shared Keychain access-group support with seamless 1-time migration from legacy ungrouped `vn.songphang.app.session` entry (plus clean fallback to ungrouped Keychain if Simulator returns `errSecMissingEntitlement` `-34018` under `CODE_SIGNING_ALLOWED=NO`).
  - `ExtensionSharedStore` (`Domain`, Foundation-only so `SongPhangWidgetExtension`, `SongPhangShareExtension`, and `AppShell` all share one type-safe store!) managing `SharedState/widget-snapshot.json`, `SharedState/share-groups.json`, and `SharedState/ShareInbox/{batchId}/manifest.json` with `.completeFileProtectionUntilFirstUserAuthentication`, `isExcludedFromBackup = true`, 24h inbox pruning, and immediate wipe on `TokenStore.clear()` / `SnapshotStore.clearAll()`.
  - `Domain` models & protocols for generalized `SplitExtra` (`shipping`, `ratePercent`, `ExtrasAllocation`), `PreviewExtrasResult`, `RecurringExpense` (`fixed`/`variable`, schedules, due actions), `Household` / `HouseholdBalance` / `HouseholdDebtBreakdown`, `"recurring_posted"` & `"recurring_due"` notifications, `"households"` & `"recurringExpenses"` SSE events, and `AppDependencies` wiring.

- [ ] **Step 1: Add `Domain` models, `ExtensionSharedStore`, repository protocols, and `AppError` cases (`householdMemberConflict`, `householdRepresentativeActiveRequired`, `recurringMemberInactive`)**
  Keep `Domain` importing `Foundation` only (`apps/ios/AGENTS.md` §3).
- [ ] **Step 2: Configure App Group & Shared Keychain in `.xcconfig` / `.entitlements` / `Info.plist` and upgrade `TokenStore.swift` + `SnapshotStore.swift`**
  Migrate legacy Keychain items on first read; ensure `clear()` deletes both shared and legacy Keychain items and wipes `ExtensionSharedStore`.
- [ ] **Step 3: Implement `Repositories` mappings (`previewExtras`, `LiveRecurringExpensesRepository`, `LiveHouseholdsRepository`, household/overview/notification mappings) and `PreviewSupport` literal fakes**
  Keep fakes strictly literal (`apps/ios/AGENTS.md` §5 — zero client math).
- [ ] **Step 4: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  `git commit -m "feat(ios): add wave 5.5c domain, live repositories, app group store, and shared keychain"`

---

### Task 5.5C.3.2: Manual-form `extras` (`S8`, `S20`, `GuestTransactionDetailSheet`) and Recurring Expenses (`S8`, `StatsView`, `OverviewView`, `NotificationsView`)

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/LedgerFeature/ExpenseForm/{ManualExtrasCardView,RecurringInlineCardView}.swift`
- Create: `apps/ios/SongPhangKit/Sources/StatisticsFeature/Recurring/{RecurringSectionView,RecurringFormSheetView,RecurringExpensesModel}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/ExpenseForm/{ExpenseFormModel,ExpenseFormView,ExpenseFormSubViews}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/SplitEditor/{SplitEditorState,SplitEditorView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/ReceiptReview/{ReceiptItemsAssignmentView,ReceiptReviewModel}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/Shared/ItemsSplitDraft.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/TransactionDetail/TransactionSummaryView.swift`
- Modify: `apps/ios/SongPhangKit/Sources/GroupsFeature/GuestShare/GuestTransactionDetailSheet.swift`
- Modify: `apps/ios/SongPhangKit/Sources/StatisticsFeature/Stats/{StatsModel,StatsView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/OverviewFeature/Overview/{OverviewModel,OverviewView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/NotificationsFeature/` (render `"recurring_posted"` & `"recurring_due"` rows)
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/{Route,RouteDestination,GroupContainerView}.swift`

**Interfaces:**
- Consumes: `TransactionsRepository.previewExtras`, `RecurringExpensesRepository`, `Overview.dueRecurringActions`, and locked `Localizable.xcstrings` keys.
- Produces:
  - `ManualExtrasCardView` + quick chips (`VAT 8%`, `+ VAT 10%`, `+ Phí DV 5%`, `+ Phí ship`, `- Giảm giá`, `+ Phụ phí khác`) in `ExpenseFormView` (`300 ms` debounced `previewExtras` with task cancellation per `apps/ios/AGENTS.md` §6, `Chia đều` default | `Theo tỷ lệ`, `%` | `đ` mode), plus `TransactionSummaryView` and `GuestTransactionDetailSheet` breakdown rows across all 5 split methods.
  - `RecurringInlineCardView` in `ExpenseFormView`, pre-filled `ExpenseForm` route when completing a due `"variable"` recurring item (`recurringExpenseId`), `RecurringSectionView` + `RecurringFormSheetView` inside `StatsView` (`Quỹ & Thống kê`), and due recurring action taps in `OverviewView` (`AppShell` coordinates navigation from `OverviewView` / `StatsView` -> `ExpenseFormView` so `StatisticsFeature` and `OverviewFeature` never import `LedgerFeature`).

- [ ] **Step 1: Build `ManualExtrasCardView` and integrate debounced server `previewExtras` into `ExpenseFormModel`, `SplitEditorState`, and `ReceiptReviewModel`**
  Ensure zero client-side percentage multiplication; keep all amounts single-line `.monospacedDigit()` up to largest accessibility Dynamic Type.
- [ ] **Step 2: Render `extras` breakdown across all split methods in `TransactionSummaryView` and `GuestTransactionDetailSheet`**
  Display `Tiền hàng`, signed extras, allocation label, and `Tổng thanh toán`.
- [ ] **Step 3: Build `RecurringInlineCardView` (`S8`), `RecurringSectionView` & `RecurringFormSheetView` (`StatisticsFeature`), and due-action routing in `OverviewFeature` / `NotificationsFeature` / `AppShell`**
  Include `#Preview` states (`loading`, `loaded`, `empty`, `failed`) on new views.
- [ ] **Step 4: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  `git commit -m "feat(ios): add manual-form extras and recurring expenses across ledger, stats, and overview"`

---

### Task 5.5C.3.3: Household / Couple Debt Grouping (`MembersView`, `BalancesView`, `GroupListView`, `GuestGroupView`, `ShareCardCanvasView`)

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/GroupsFeature/Members/{HouseholdsSectionView,HouseholdFormSheetView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/GroupsFeature/Members/{MembersModel,MembersView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupList/GroupListView.swift`
- Modify: `apps/ios/SongPhangKit/Sources/GroupsFeature/GuestShare/{GuestGroupView,GuestBreakdownSheet}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/{BalancesModel,BalancesView,MemberBreakdownSheetView,ShareCardPreviewSheet}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/GroupFeedSubViews.swift`
- Modify: `apps/ios/SongPhangKit/Sources/OverviewFeature/Overview/OverviewView.swift`
- Modify: `apps/ios/SongPhangKit/Sources/DesignSystem/Components/ShareCardCanvasView.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/{GroupContainerView,RouteDestination}.swift`

**Interfaces:**
- Consumes: `HouseholdsRepository`, household fields on `BalancesResult`, `MemberBreakdownsResult`, `GuestGroupView`, `ExpenseGroup`, and `Overview`.
- Produces:
  - `HouseholdsSectionView` & `HouseholdFormSheetView` in `MembersView` (`S10`) + household badges on member rows.
  - Household-consolidated Hero Card, non-representative partner (`fromHousehold`) outgoing `"Tôi đã chuyển"` eligibility, `Đại diện {name}` transfer labels, `Theo hộ / cặp đôi` balance bars, and `Tổng hợp hộ {name}` breakdowns across `BalancesView`, `MemberBreakdownSheetView`, `GuestGroupView`, `GroupListView`, `OverviewView`, and `ShareCardCanvasView` (`3x` PNG export).

- [ ] **Step 1: Build `HouseholdsSectionView` and `HouseholdFormSheetView` in `GroupsFeature/Members/`**
  Surface VietQR/payment-method indicator on candidate representatives; handle `409 HOUSEHOLD_MEMBER_CONFLICT` and `422 HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED` cleanly.
- [ ] **Step 2: Update `BalancesView`, `MemberBreakdownSheetView`, `GuestGroupView`, `GroupListView`, `OverviewView`, and `ShareCardCanvasView` for households**
  Allow any linked member in `fromHousehold` to trigger `PayView` (`"Tôi đã chuyển"` for `representativeMemberId`) while restricting `"Đã nhận"` confirmation to the representative / `owner` (or `editor` when unlinked).
- [ ] **Step 3: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  `git commit -m "feat(ios): add household debt grouping across members, balances, guest view, and share cards"`

---

### Task 5.5C.3.4: `LinkRouter` `songphang://` routing, Quick Actions, `SongPhangShareExtension`, `SongPhangWidgetExtension` & Stage 5.5C.3 Gate

**Files:**
- Create: `apps/ios/ShareExtension/{Info.plist,SongPhangShareExtension.entitlements,ShareViewController.swift,ShareExtensionView.swift,ShareImageNormalizer.swift}`
- Create: `apps/ios/WidgetExtension/{Info.plist,SongPhangWidgetExtension.entitlements,SongPhangWidgets.swift,OverviewWidgetView.swift}`
- Modify: `apps/ios/SongPhang.xcodeproj/project.pbxproj`
- Modify: `apps/ios/App/SongPhangApp.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AccountFeature/Account/{AccountModel,AccountView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/{Route,RootView,SessionModel,GroupContainerView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/Routing/LinkRouter.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/Push/PushEventBridge.swift`

**Interfaces:**
- Consumes: `ExtensionSharedStore`, shared Keychain `TokenStore`, `LiveAttachmentsRepository`, `LiveReceiptScansRepository`, `DesignSystem` `Tokens` & `Typography`.
- Produces:
  - `LinkRouter.appActionRoute(for: URL) -> Route?` strictly validating `songphang://overview`, `songphang://group/{uuid}/{quick-entry|expense-new|balances}`, and `songphang://share-import/{batchUuid}`.
  - `"Ẩn số tiền trên Widget"` toggle in `AccountView`, live `ExtensionSharedStore` sync + `WidgetCenter.shared.reloadAllTimelines()` + dynamic `UIApplication.shared.shortcutItems` (`Ghi chi tiêu nhanh`, `Nhập tay / Quét hoá đơn`, `Xem cần thanh toán`) in `SessionModel`/`AppShell`, and `SongPhangAppDelegate` `UIApplicationShortcutItem` handling.
  - Embedded target `SongPhangShareExtension` (`vn.songphang.app.ShareExtension`, max 3 images, `ImageIO` thumbnail normalization `<= 5 MiB`, group picker defaulting to `recentGroupId`, `Chi tiêu mới` | `Chứng từ trả nợ`, direct upload + `POST /receipt-scans` when applicable, `ShareInbox` manifest + `songphang://share-import/{batchId}` open + `RootView` `scenePhase == .active` automatic inbox pickup).
  - Embedded target `SongPhangWidgetExtension` (`vn.songphang.app.WidgetExtension`, linking **only** `Domain` and `DesignSystem`, registering `Be Vietnam Pro`, rendering `.systemSmall` & `.systemMedium` in Light & Dark modes, respecting signed-out & `hideAmounts` states).

- [ ] **Step 1: Extend `LinkRouter` (`songphang://`), add `"Ẩn số tiền trên Widget"` in `AccountView`, wire `ExtensionSharedStore` + `WidgetCenter` + `UIApplicationShortcutItem` in `AppShell`/`SongPhangApp.swift`, and add `ShareInbox` consumption in `RootView`**
  Ensure `RootView` consumes pending `ShareInbox` batches both on `onOpenURL` (`songphang://share-import/{batchId}`) and on `scenePhase == .active` (when host apps suppress `extensionContext?.open`), routing straight to `ReceiptReviewView`, `ExpenseFormView` (with uploaded `Attachment`s), or `BalancesView`/`PayView`.
- [ ] **Step 2: Create `SongPhangShareExtension` target & SwiftUI sheet with `ImageIO` memory-safe normalization**
  Link `Domain`, `DesignSystem`, `Repositories`; enforce `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` and Swift 6 concurrency; block cleanly when signed out.
- [ ] **Step 3: Create `SongPhangWidgetExtension` target (`.systemSmall` & `.systemMedium`)**
  Link **only** `Domain` and `DesignSystem`; register `Typography.registerFontsIfAvailable()`; use `.containerBackground(for: .widget)` with Design System v2 Light/Dark semantic tokens and `.monospacedDigit()` tabular numerals.
- [ ] **Step 4: Run Stage 5.5C.3 iOS Gate & Simulator exercises**
  Run `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, Simulator Debug `xcodebuild`, and unsigned Simulator Release `xcodebuild` (`CODE_SIGNING_ALLOWED=NO`). Boot iOS Simulator against local API, exercise and capture screenshots of: (a) `S8` Three Koala `346k + VAT 8% = 373.680 đ`, (b) `StatsView` `Giao dịch định kỳ` + `OverviewView` due recurring prompt, (c) `MembersView` & `BalancesView` `Nhà Minh & Lan` consolidated transfer, (d) `xcrun simctl openurl booted songphang://group/<id>/quick-entry` + `ShareInbox` import pickup into `ExpenseFormView`, and (e) Widget previews / Home Screen rendering in Light, Dark, and `"Ẩn số tiền trên Widget"` modes + verify sign-out wipes `SharedState/`.
- [ ] **Step 5: Commit**
  `git commit -m "feat(ios): add share extension, home screen widgets, quick actions, and deep-link routing"`
