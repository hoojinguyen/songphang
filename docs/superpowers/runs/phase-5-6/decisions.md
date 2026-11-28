# phase-5-6 — Run Decisions

Each decision: problem, options, choice, reason (and for a library: license, maintenance, added size).

## Re-baseline

### Earlier phases on `main` (`6d8f398`)

- Phases 0–4, Phase 5 (`ios-ui` + live API integration), and Phase 5.5 Waves 5.5A–5.5C (`b6ad8cd`, PR #5) are merged on `main`, followed by the UI/UX v3 roadmap/review (`a2964a8`), Phase 5.6 spec and ADRs 042–044 (`c42055f`), Phase 5.6 plan (`f638cd5`), and swarm handoff prompt (`6d8f398`).
- Branch `phase-5-6` starts cleanly at `6d8f398` (matching `main`). No tasks in Phase 5.6 are skipped.

### File and symbol re-baseline

| Plan's name | Real name and location | Status |
|---|---|---|
| `AppShell/RootView.swift` | `apps/ios/SongPhangKit/Sources/AppShell/RootView.swift` | Exists |
| `AppShell/RouteDestination.swift` | `apps/ios/SongPhangKit/Sources/AppShell/RouteDestination.swift` | Exists |
| `AppShell/GroupContainerView.swift` | `apps/ios/SongPhangKit/Sources/AppShell/GroupContainerView.swift` | Exists |
| `AppShell/PopGestureEnabler.swift` | `apps/ios/SongPhangKit/Sources/AppShell/PopGestureEnabler.swift` | Exists |
| `AppShell/StatusBarCover.swift` | `apps/ios/SongPhangKit/Sources/AppShell/StatusBarCover.swift` | Exists |
| `AppShell/Route.swift` | `apps/ios/SongPhangKit/Sources/AppShell/Route.swift` | Exists |
| `AppShell/SessionModel.swift` | `apps/ios/SongPhangKit/Sources/AppShell/SessionModel.swift` | Exists |
| `AppShell/Push/PushPermissionSheet.swift` | `apps/ios/SongPhangKit/Sources/AppShell/Push/PushPermissionSheet.swift` | Exists |
| `AppShell/Debug/{DebugGalleryView,DebugPanel}.swift` | `apps/ios/SongPhangKit/Sources/AppShell/Debug/{DebugGalleryView,DebugPanel}.swift` | Exists |
| `DesignSystem/Tokens/{Tokens,Typography}.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/{Tokens,Typography}.swift` | Exists |
| `DesignSystem/Components/Haptics.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/Haptics.swift` | Exists |
| `DesignSystem/Components/LoginShapesAndHeader.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/LoginShapesAndHeader.swift` (`LoginShapesView`, `SPScreenHeader`) | Exists |
| `DesignSystem/Components/MoneyText.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/MoneyText.swift` | Exists |
| `DesignSystem/Components/MoneyFormat.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/MoneyFormat.swift` | Exists |
| `DesignSystem/Components/MemberShapeView.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/MemberShapeView.swift` | Exists |
| `DesignSystem/Components/ControlsAndQR.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/ControlsAndQR.swift` (`SPSegmentedControl`, `SPSwitch`, `SPQRCodeView`, `NewMemberInputRow`) | Exists |
| `DesignSystem/Components/{ChannelPillPicker,PhotoAttachmentViews}.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/Components/{ChannelPillPicker,PhotoAttachmentViews}.swift` | Exists |
| `DesignSystem/States/StateViews.swift` | `apps/ios/SongPhangKit/Sources/DesignSystem/States/StateViews.swift` (`LoadingSkeleton`, `LoadError`, `EmptyState`, `OfflineBanner`) | Exists |
| `DesignSystem/Resources/Localizable.xcstrings` | `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | Exists |
| `PreviewSupport/Fakes/*` | `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/` (`FakeWorld.swift` + 10 `FakeWorld+*.swift` extensions + 6 `Fake*Repository.swift` files, 17 files total) | Exists |
| `PreviewSupport/{Samples,Scenarios}/*` | `apps/ios/SongPhangKit/Sources/PreviewSupport/Samples/PreviewSamples.swift` and `Scenarios/{EmptyScenario,LargeScenario,QuickEntryFixtures,TripScenario}.swift` | Exists |
| `apps/ios/Scripts/check-strings.sh` | `apps/ios/Scripts/check-strings.sh` | Exists |
| Feature views & models named in Stages A–C (45 files across `AccountFeature`, `AuthFeature`, `GroupsFeature`, `LedgerFeature`, `NotificationsFeature`, `OverviewFeature`, `PaymentsFeature`, `StatisticsFeature`) | Same relative paths under `apps/ios/SongPhangKit/Sources/` (`GroupsFeature/CloneGroup/CloneGroupSheetView.swift` for `CloneGroup/*`; `LedgerFeature/TransactionDetail/{TransactionDetailView,TransactionDetailModel,TransactionSummaryView,ApprovalBlockView,DisputeBlockView,CommentThreadView,CommentFieldView}.swift` for `TransactionDetail/*`) | Exists (0 missing) |

### Spec and plan counts re-baseline

| Metric | Spec / Plan count | Real count at `6d8f398` | Notes |
|---|---|---|---|
| Screens hiding system back button (`.navigationBarBackButtonHidden(true)`) | 17 | **17** | Exact match. In addition: `TransactionDetailView` uses `SPScreenHeader` without hiding the system back button (defect B01); `NotificationsView` uses `SPScreenHeader(onBack:)` when pushed; `SplitEditorView`, `PayView`, `PaymentDetailsView` draw custom back chevrons. |
| `.sheet` / `.fullScreenCover` presentations | 32 | **32** | Exact match (`28` `.sheet` + `4` `.fullScreenCover` in `SongPhangKit/Sources/`). |
| Animation calls (`withAnimation` / `.animation(`) | 17 | **17** | Exact match across 8 files; `accessibilityReduceMotion` read in 4 files. |
| `Haptics.` calls | 22 | **22** | Exact match across 8 files. |
| Fixed font calls (`.font(.system(size:`) | 54 | **54** in `SongPhangKit/Sources/` (**55** across `apps/ios/` including `ShareExtension/ShareExtensionView.swift:212`) | Exact match for `SongPhangKit/Sources/`; `ShareExtensionView.swift:212` will also be swept in `5.6.C.4`. |
| Files using `ProgressView(` | 8 | **8** in `SongPhangKit/Sources/` (plus `ShareExtension/ShareExtensionView.swift`) | Exact match (`PhotoAttachmentViews`, `SPButton`, `BalancesView` [determinate bars], `ReceiptCaptureSheet`, `ReceiptReviewView`, `CommentThreadView`, `TransactionDetailView`, `NotificationsView`). |
| String catalog keys (`Localizable.xcstrings`) | 963 | **963** | Exact match (`893` web-mirrored keys + `70` `ios.*` keys). |
| Strings over 60 characters | 38 | **38** | Exact match (38 keys > 60 characters in `Localizable.xcstrings`). |
| `EmptyState(` call sites | 2 | **2** | Exact match (`FundView.swift:78`, `DebugGalleryView.swift:207`). |

## Decisions

### D1 — `xcodebuild` warnings-as-errors invocation on Xcode 27.2 (Task 0)

- **Problem:** Passing `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` as a global command-line override to `xcodebuild` overrides build settings on remote SwiftPM dependencies (`swift-collections`, `swift-http-types`) where Xcode 27.2 passes `-suppress-warnings`, failing with `error: Conflicting options '-warnings-as-errors' and '-suppress-warnings'` (documented in `apps/ios/README.md` line 77 and Phase 5 D5).
- **Options:**
  1. Disable warnings-as-errors in project settings.
  2. Keep `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` on all 8 build configurations in `apps/ios/SongPhang.xcodeproj/project.pbxproj` and `.treatAllWarnings(as: .error)` on all 13 targets in `apps/ios/SongPhangKit/Package.swift`, and run `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build` without the global CLI override so every first-party file still treats all warnings as errors.
- **Choice:** Option 2.
- **Reason:** Enforces warnings-as-errors across 100% of first-party app, extension, and package targets while avoiding Xcode 27.2's flag conflict on third-party SwiftPM dependencies.

### D2 — Add `#if DEBUG` `--route-groups` and `--route-tx-detail` launch flags in `RootView.swift` (Task 0)

- **Problem:** Task 0 Step 4 requires "before" Simulator screenshots of `groups` (`GroupListView` tab root) and `transaction detail` (`TransactionDetailView`, defect B01), and Stages B–D require opening every `Route` case deterministically via `--route-*` flags. `RootView.swift` already defines 20 `#if DEBUG` `--route-*` flags, but lacked `--route-groups` and `--route-tx-detail`, and `Simulator.app` GUI automation is unavailable in headless `simctl` mode.
- **Options:**
  1. Leave `groups` and `transaction detail` uncaptured in Task 0.
  2. Add `--route-groups` (`selectedTab = .groups`) and `--route-tx-detail` (`selectedTab = .groups; groupsPath = [.groupFeed(groupId: targetGroupId), .transactionDetail(groupId: targetGroupId, transactionId: TripScenario.t1Transaction.id)]`) inside `#if DEBUG` in `RootView.swift` without modifying any screen view or production code.
- **Choice:** Option 2.
- **Reason:** Zero change to production code or screen layout (preserves unmodified B01 double-back-button defect on `TransactionDetailView`), while enabling deterministic "before" and "after" Simulator captures across all 10 baseline screens.

### D3 — `MoneyText(.hero)` rolling via `.numericText(countsDown:)` and persistent `matchedGeometryEffect` segment pill (Task 5.6.A.1)

- **Problem:**
  1. `SwiftUICore` offers `ContentTransition.numericText(value: Double)` and `ContentTransition.numericText(countsDown: Bool)`. Passing `Double(money.amount)` to `.numericText(value:)` would convert `Money` to a floating-point number, which `apps/ios/AGENTS.md` §5 forbids ("never convert it to a floating-point number").
  2. Wrapping `selectedSegment = segment` in `withAnimation` in `GroupContainerView` previously cross-faded the entire screen content (`F2-56`).
- **Options:**
  1. Convert `Money` to `Double` for `.numericText(value:)` and wrap segment state changes in `withAnimation`.
  2. Track roll direction with pure integer `Money` comparison (`newValue < oldValue`) in `MoneyText`, passing `countsDown` to `.contentTransition(reduceMotion ? .identity : .numericText(countsDown: countsDown))` paired with `.spAnimation(Motion.smooth, value: money)`; and render one persistent selection pill with `.matchedGeometryEffect(..., properties: .frame, isSource: false)` + `.spAnimation(Motion.quick, value:)` inside `SPSegmentedControl` and `GroupContainerView` while mutating `selectedSegment` / `fundSubTab` without `withAnimation`.
- **Choice:** Option 2.
- **Reason:** Keeps `Money` 100% integer-only (`apps/ios/AGENTS.md` §5), rolls hero numbers in the right direction only when `money` changes (`F1-44`, `F2-59`, `F2-60`), slides the segment pill smoothly with `Motion.quick`, switches content below without fading (`F2-56`), and falls back to instant updates under Reduce Motion (`F2-63`, `F4-53`).
- **Debug launch helpers (`#if DEBUG`):** Added `--reduce-motion` (injects `\.accessibilityReduceMotion = true` at `RootView`), `--exercise-segment-switch`, and `--exercise-record-payment` so Reduce Motion and motion moments are deterministically verifiable in headless `simctl`.

### D4 — Sound synthesis, `AVAudioSession` `.ambient` behavior, and `Haptics.` migration (Task 5.6.A.2)

- **Problem:**
  1. Generate three short `.caf` sound files (`coin`, `ting`, `chord`) locally without downloads or new packages, bundle them in `DesignSystem`, and confirm `.ambient` session behavior in the installed iOS 27.2 SDK.
  2. Migrate all 22 `Haptics.` calls across 8 files to `.spFeedback(_:trigger:)` while honoring Spec §7.1 ("Nothing on tab switches or navigation") and Task 5.6.A.2 Step 3 ("Remove any haptic that fires on a plain tab or segment switch").
- **Options:**
  1. Keep imperative `UIImpactFeedbackGenerator` calls or add a new SwiftPM resource rule.
  2. Synthesize 22.05 kHz 16-bit mono PCM tones with exponential attack/decay envelopes in `apps/ios/Scripts/generate-sounds.swift` and convert via `/usr/bin/afconvert -f caff -d LEI16` (`coin.caf` 150 ms, `ting.caf` 240 ms, `chord.caf` 360 ms, peak `-14.9` to `-15.4 dBFS`, ~6.6–15.9 KB each) under `DesignSystem/Resources/Sounds/` (already covered by `Package.swift`'s `.process("Resources")`, resolved with `subdirectory: "Sounds"` fallback to `nil`); configure `AVAudioSession.sharedInstance().setCategory(.ambient)` once (confirmed in `iPhoneSimulator27.2.sdk/.../AVAudioSessionTypes.h`: `AVAudioSessionCategoryAmbient` mixes with background music without interrupting it and silences with the Ring/Silent switch); wrap `View.sensoryFeedback(trigger:_:)` (confirmed in `SwiftUI.swiftinterface:2807`) in `.spFeedback(_:trigger:)` gated on `FeedbackSettings`; remove the 2 plain navigation segment/sub-tab haptics in `GroupContainerView` and migrate the remaining 20 call sites to state-driven `.spFeedback`.
- **Choice:** Option 2.
- **Reason:** Zero external assets or dependencies, zero `Package.swift` change needed, declarative state-tied sensory feedback that respects the per-device "Rung" setting, and ambient audio playback that never throws or interrupts music.

### D5 — Typography Dynamic Type audit, fixed-font mapping table, and iOS 26 navigation bar appearance (Task 5.6.A.3)

- **Problem:**
  1. `Typography.heroNumber` previously used a fixed-size fallback `.system(size: 40, weight: .black, design: .default)`, and `Typography` lacked styles for 42–48 pt display amounts, 10–11 pt micro badges/tags, and `@ScaledMetric` SF Symbol icons needed to replace the 54 fixed `.font(.system(size:` calls in `SongPhangKit/Sources/` (plus 1 in `ShareExtensionView.swift`).
  2. Spec §4.1 and Task 5.6.A.3 require setting `UINavigationBar.appearance()` to `Be Vietnam Pro` inside `Typography.registerFontsIfAvailable()`, checking whether iOS 26 Liquid Glass bars honor or ignore it.
- **Options:**
  1. Keep scattered `@ScaledMetric` properties in dozens of view files or replace `UINavigationBar.appearance().standardAppearance` (which risks overriding iOS 26 Liquid Glass scroll-edge backgrounds).
  2. Change `heroNumber` fallback to `.system(.largeTitle, design: .default, weight: .black)`; add `Typography.displayNumber` (44 pt `.largeTitle`), `Typography.microBold` (11 pt `.caption2` bold), `Typography.micro` (11 pt `.caption2` semibold), and `.spIconFont(size:weight:relativeTo:)` (single `@ScaledMetric`-backed modifier in `Typography.swift`); set `UINavigationBar.appearance().titleTextAttributes` and `largeTitleTextAttributes` using `UIFontMetrics`-scaled `BeVietnamPro-ExtraBold` (17 pt) and `BeVietnamPro-Black` (34 pt) without touching bar background appearances.
- **Choice:** Option 2.
- **Reason:** Every `Typography` style and fallback scales to `accessibility5`; icons scale through one `@ScaledMetric` modifier; iOS 26 Liquid Glass bar backgrounds remain untouched. Verified in Simulator (`screens/stage-a/a3-nav-title-font.png`) that iOS 26.5 honors `UINavigationBar.appearance().titleTextAttributes` and `largeTitleTextAttributes` with `BeVietnamPro-ExtraBold` and `BeVietnamPro-Black` (temporary test screen removed before commit).

#### Mapping table for all 55 `.font(.system(size:` occurrences (applied in `5.6.C.4`)

| Location | Current call | Target in `5.6.C.4` |
|---|---|---|
| `ConfirmationCardView.swift:103` | `.font(.system(size: 48, weight: .black))` | `Typography.displayNumber` |
| `ExpenseFormSubViews.swift:193` | `.font(.system(size: 46, weight: .black))` | `Typography.displayNumber` |
| `SettleView.swift:291` | `.font(.system(size: 44, weight: .black))` | `Typography.displayNumber` |
| `TransactionSummaryView.swift:62` | `.font(.system(size: 44, weight: .black))` | `Typography.displayNumber` |
| `FundView.swift:111` | `.font(.system(size: 42, weight: .black))` | `Typography.displayNumber` |
| `PhotoAttachmentViews.swift:103` | `.font(.system(size: 40, weight: .bold))` | `.spIconFont(size: 40, weight: .bold, relativeTo: .largeTitle)` |
| `SettleView.swift:139` | `.font(.system(size: 24, weight: .bold))` | `.spIconFont(size: 24, weight: .bold, relativeTo: .title2)` |
| `NotificationBellButton.swift:17` | `.font(.system(size: 20, weight: .semibold))` | `.spIconFont(size: 20, weight: .semibold, relativeTo: .title3)` |
| `HouseholdFormSheetView.swift:133` | `.font(.system(size: 20, weight: .semibold))` | `.spIconFont(size: 20, weight: .semibold, relativeTo: .title3)` |
| `GroupFeedSubViews.swift:806, 824` | `.font(.system(size: 20, weight: .bold))` | `.spIconFont(size: 20, weight: .bold, relativeTo: .title3)` |
| `QuickEntryView.swift:250` | `.font(.system(size: 20, weight: .bold))` | `.spIconFont(size: 20, weight: .bold, relativeTo: .title3)` |
| `SignInView.swift:67`, `LoginShapesAndHeader.swift:87`, `StateViews.swift:138`, `SplitEditorView.swift:15, 137`, `PayView.swift:66` | `.font(.system(size: 18, weight: .bold))` | `.spIconFont(size: 18, weight: .bold, relativeTo: .headline)` |
| `PhotoAttachmentViews.swift:39`, `HouseholdFormSheetView.swift:173`, `ShareExtensionView.swift:212` | `.font(.system(size: 18, weight: .semibold))` | `.spIconFont(size: 18, weight: .semibold, relativeTo: .headline)` |
| `GroupContainerView.swift:410, 520` | `.font(.system(size: 16, weight: .semibold / .bold))` | Removed in `5.6.B.1` when native toolbar replaces `persistentHeader` (or `.spIconFont` if any icon stays) |
| `PhotoAttachmentViews.swift:111`, `CreateGroupView.swift:95`, `ExpenseFormSubViews.swift:32`, `CommentFieldView.swift:40` | `.font(.system(size: 16, weight: .bold))` | `.spIconFont(size: 16, weight: .bold, relativeTo: .callout)` |
| `ReceiptItemsAssignmentView.swift:168, 300` | `.font(.system(size: 16, weight: .semibold))` | `.spIconFont(size: 16, weight: .semibold, relativeTo: .callout)` |
| `TransferProofInputSection.swift:110`, `ManualExtrasCardView.swift:222` | `.font(.system(size: 15, weight: .semibold))` | `.spIconFont(size: 15, weight: .semibold, relativeTo: .subheadline)` |
| `FundBlockView.swift:52`, `SplitEditorView.swift:448`, `NotificationsView.swift:123`, `PaymentDetailsView.swift:133, 150`, `RecurringSectionView.swift:196` | `.font(.system(size: 14, weight: .bold))` | `.spIconFont(size: 14, weight: .bold, relativeTo: .subheadline)` |
| `HouseholdsSectionView.swift:172` | `.font(.system(size: 13, weight: .semibold))` | `.spIconFont(size: 13, weight: .semibold, relativeTo: .footnote)` |
| `ExpenseFormView.swift:478` | `.font(.system(size: 13, weight: .bold))` | `Typography.captionBold` (or `.spIconFont(size: 13, weight: .bold, relativeTo: .footnote)` if icon) |
| `GuestGroupView.swift:202`, `CycleFilterChipView.swift:59` | `.font(.system(size: 12, weight: .semibold))` | `.spIconFont(size: 12, weight: .semibold, relativeTo: .caption)` |
| `NotificationBellButton.swift:25` | `.font(.system(size: 11, weight: .black))` | `Typography.microBold` |
| `PhotoAttachmentViews.swift:192`, `TransferProofInputSection.swift:83`, `SettlementVaultSectionView.swift:182`, `GroupFeedSubViews.swift:410` | `.font(.system(size: 11, weight: .bold))` | `.spIconFont(size: 11, weight: .bold, relativeTo: .caption2)` / `Typography.microBold` |
| `ProofBadgeView.swift:32`, `GuestGroupView.swift:500`, `GroupFeedSubViews.swift:199, 209, 481` | `.font(.system(size: 11, weight: .semibold))` | `.spIconFont(size: 11, weight: .semibold, relativeTo: .caption2)` / `Typography.micro` |
| `GuestGroupView.swift:206`, `CycleFilterChipView.swift:63`, `GroupFeedSubViews.swift:631`, `PersonalLedgerView.swift:132` | `.font(.system(size: 10, weight: .bold))` | `Typography.microBold` / `.spIconFont(size: 10, weight: .bold, relativeTo: .caption2)` |
| `MemberShapeView.swift:48` | `.font(.system(size: size * 0.36, weight: .black))` | Geometric initial inside fixed `size` shape container (decorative avatar glyph proportional to `size`; recorded per `5.6.C.4`) |

### D6 — Non-oscillating `.spSheet(.fitted)` intrinsic height measurement and Liquid Glass background (Task 5.6.A.4)

- **Problem:** Inspecting `SwiftUI.swiftinterface` (`PresentationDetent.height(_:)`, `presentationDetents(_:)`, `presentationBackground(_:)`) and `SwiftUICore.swiftinterface` (`onGeometryChange(for:of:action:)`) shows that measuring a flexible root container (`ScrollView` or `NavigationStack`) feeds the sheet's own detent height back into `@State measuredHeight`, causing detent oscillation; meanwhile calling `.presentationBackground(Tokens.bg)` would replace iOS 26's floating Liquid Glass sheet surface (`F2-30`).
- **Options:**
  1. Hard-code fixed pixel heights per sheet or set `.presentationBackground(Tokens.bg)`.
  2. Measure intrinsic vertical height decoupled from the proposed detent height: for plain sheet content, wrap in `ViewThatFits(in: .vertical)` measuring `content.fixedSize(horizontal: false, vertical: true)` via `onGeometryChange` (falling back to a `ScrollView` when `accessibility5` exceeds the 86%-screen cap); for sheets with an inner `NavigationStack` + `ScrollView`, measure the inner `VStack` via `.spFittedSheetContent(chromeAllowance:)` (`PreferenceKey`, since vertical `ScrollView` proposes `.unspecified` height to its child); quantize changes with a `>= 2 pt` deadband, cap at `[.large]` when taller than `0.86 * screenHeight`, set `.presentationDragIndicator(.visible)`, and omit `.presentationBackground` so iOS 26 applies system Liquid Glass. Pair `.discardGuard(isDirty:onDiscard:)` with an `EnvironmentValues.spSheetRequestDismiss` closure consumed by `SheetCancelButton` and `SheetCloseButton`.
- **Choice:** Option 2.
- **Reason:** Intrinsic height depends only on content width and Dynamic Type size (never on the sheet detent), eliminating oscillation while preventing clipping at `accessibility5` and preserving iOS 26 Liquid Glass.

### D7 — `ChipRow` half-peek sizing, `MemberShapeView` unclaimed dashed outline, and `EmptyState` API (Task 5.6.A.5)

- **Problem:**
  1. `ChipRow` must wrap without horizontal scrolling when it has `<= 4` chips, and when scrolling horizontally (`> 4` chips) must never truncate chip labels and must position chips so the chip crossing the trailing edge is roughly half visible (not fully hidden behind a gutter gap).
  2. `MemberShapeView` previously accepted `showInitial: Bool = true` (with 21 call sites passing `showInitial: false`, rendering plain colored dots) and had no unclaimed visual treatment (`F1-01`, `F2-43`).
  3. `EmptyState` previously allowed callers to omit an action silently (`F2-122`).
- **Options:**
  1. Keep `showInitial` defaulted to `true` and inspect callers manually; use plain `HStack(spacing: 8)` inside `ChipRow` regardless of where the right edge lands.
  2. Remove `showInitial` from `MemberShapeView` altogether so plain dots are unrepresentable, add `isClaimed: Bool = true` + `init(member: Member, size: CGFloat)` drawing `Tokens.dashed` stroke and `0.45` fill opacity when `!isClaimed`, and migrate `Member`-backed call sites to `MemberShapeView(member:size:)`; implement `ChipWrapLayout` (`<= 4` items) and `PeekingChipHStackLayout` (`> 4` items, adjusting inter-chip spacing >= `spacing` when needed so the trailing boundary chip shows 35%–65% of its natural width); require either `action:` or `noActionReason:` on `EmptyState` initializers.
- **Choice:** Option 2.
- **Reason:** Making plain dots and silent actionless `EmptyState`s unrepresentable enforces `AGENTS.md` §6 ("Let the machine catch errors"), while `Layout` subviews keep every chip label untruncated (`fixedSize(horizontal: true)`).

### D8 — `TimelineView` shimmer/pulse under Reduce Motion and `MoneyText.Role` compatibility (Task 5.6.A.6)

- **Problem:**
  1. Every SwiftUI animation must go through `Motion` (`5.6.A.1`), which returns `nil` when Reduce Motion is enabled, yet `ShapeLoader` requires a gentle pulsing opacity under Reduce Motion and `SkeletonBlocks` requires a slow shimmer that stops completely under Reduce Motion.
  2. `MoneyText` gains explicit v3 roles (`.hero`, `.primary`, `.secondary`) in Stage A while feature call sites are migrated to those roles in Stage C (`5.6.C.4`).
- **Options:**
  1. Attach raw `.animation(.easeInOut.repeatForever())` in `ShapeLoader` and `SkeletonBlocks` (violating the `Motion`-only rule) or break existing `MoneyText(style:)` callers during Stage A.
  2. Drive `ShapeLoader`'s Reduce Motion opacity pulse and `SkeletonBlocks`'s normal-mode slow shimmer via `TimelineView(.animation(minimumInterval:))` (zero `.animation` modifiers bypassing `Motion`; `SkeletonBlocks` renders static content when `Motion.isReduced` is `true`, and `ShapeLoader` uses `PhaseAnimator` with `Motion.animation(Motion.bounce, reduceMotion: false)` when `Motion.isReduced` is `false`); add `MoneyText.Role` (`.hero`, `.primary`, `.secondary`) + `MoneyFormat.primary`/`MoneyFormat.secondary` alongside existing `Style` cases until `5.6.C.4`.
- **Choice:** Option 2.
- **Reason:** Zero animations bypass `Motion`, Reduce Motion behavior matches Spec §10.5 and §9.1 (`F1-52`, `F4-53`), and all 13 targets compile cleanly between Stage A and Stage C.

### D9 — Native navigation bar template (`ActivityView` -> remaining pushed screens) (Task 5.6.B.1)

- **Problem:** 17 pushed screens hid the system back button (`navigationBarBackButtonHidden(true)`) and drew `SPScreenHeader` in scroll content, `TransactionDetailView` forgot to hide the system button (`B01`), `NotificationsView` and `SplitEditorView` drew custom `chevron.left` buttons, `GroupContainerView` drew a custom `persistentHeader` with `chevron.backward`, tab roots had no navigation bar (`B19`), and `RootView` patched around these with `StatusBarCover` and `PopGestureEnabler`.
- **Options:**
  1. Keep custom `SPScreenHeader` on focused-task screens or keep `SplitEditorView` swapped inline inside `ExpenseFormView`'s `body`.
  2. Establish the uniform pattern proved in `ActivityView` (`screens/stage-b/b1-activity-{light,dark}.png`):
     - Remove `.navigationBarBackButtonHidden(true)` and `SPScreenHeader` (and custom `chevron.left`/`chevron.backward` buttons) on every pushed screen.
     - Apply `.navigationTitle(...)` and `.navigationBarTitleDisplayMode(.inline)` for detail/task screens or `.large` for `AccountView` and `NotificationsView`, placed on the outer screen container so `.loading`/`.failed`/`.loaded` states all retain the native bar and back button.
     - Move `SPScreenHeader` subtitles (group name, `"Chỉ chủ nhóm"`, member count, payer summary) to the first line inside content in `Typography.subheadlineBold` + `Tokens.muted`.
     - Move trailing actions (`TransactionDetailView` "Sửa", `NotificationsView` "Đọc hết", `GroupContainerView` member-shapes capsule + overflow menu) into `.toolbar { ToolbarItem(placement: .topBarTrailing) { ... } }`; move `ExpenseFormView`'s 3-option `TypeSwitchView` to the top of `scrollingForm` so inline nav bars stay uncrowded at AX5 and 375 pt width.
     - Push `SplitEditorView` via `.navigationDestination(isPresented: $model.isSplitEditorOpen)` inside `ExpenseFormView` so split editing gets the native Back button and swipe-back gesture.
     - Put Overview and Groups tab roots under `.navigationTitle("").navigationBarTitleDisplayMode(.inline)` so all 4 tab roots live under a navigation bar (`B19`), and delete `PopGestureEnabler.swift` and `StatusBarCover.swift`.
- **Choice:** Option 2.
- **Reason:** Every pushed route uses authentic system iOS 26 navigation bars, Liquid Glass scroll-edge protection under the clock, and system interactive edge-swipe without UIKit gesture/status-bar hacks. `PayView` and `PaymentDetailsView` keep `SPScreenHeader` inside sheets temporarily until `5.6.C.1` applies sheet dismiss controls across all 32 presentations.

### D10 — Tab bar visibility rule and in-tab vs external route handling (Task 5.6.B.2)

- **Problem:**
  1. `RouteDestination` previously applied `.toolbar(.hidden, for: .tabBar)` unconditionally to all pushed routes.
  2. Overview (`onOpenGroup`, `onOpenBalances`, `onOpenTransaction`, `onOpenDueRecurring`) and `navigate(to:)` (called from `NotificationsView`) previously forced `selectedTab = .groups` and overwrote `groupsPath`, stranding Back in a tab the user was not in.
- **Options:**
  1. Apply `.toolbar(.hidden, for: .tabBar)` piecemeal inside individual feature views and force `.groups` everywhere.
  2. Centralize tab-bar visibility in one exhaustive `RouteDestination.hidesTabBar` switch over `Route` (hidden only on `.quickEntry`, `.newTransactionForm`, `.editTransaction`, `.settle`, `.receiptReview`; visible on all content routes), add `RootView.appendToCurrentTab(_:)`, keep `navigate(to:)` for in-app navigation (switching tabs only when the route explicitly names `.account`, `.notifications`, or `.personalLedger`, otherwise appending to the active tab's stack), keep explicit tab links (`onOpenNotifications`, `onOpenAccount`) switching tabs, and keep external triggers (`openExternalRoute` from deep links/universal links, `applyPushTap`, `receiveAppAction`, `--route-*` debug flags) targeting `.groups`. Also removed the stale `onPop()` call from `RouteDestination`'s `.notifications` `onBack` closure since `NotificationsView.onDisappear` now runs it on system pop.
- **Choice:** Option 2.
- **Reason:** Exhaustive switching guarantees future routes make an explicit tab-bar choice at compile time, Back always returns to the tab where the user started, and external links/pushes continue landing cleanly on `.groups`.

### D11 — Placement of `GroupUnavailableView`, clone landing route, and categories scroll anchor (Task 5.6.B.3)

- **Problem:**
  1. Both `GroupContainerView` (`AppShell`) and `GroupSettingsView` (`GroupsFeature`) need `GroupUnavailableView`, while `GroupsFeature` cannot import `AppShell`.
  2. Clone completion can originate from `GroupListView`, `GroupContainerView`, or `GroupSettingsView` (stack depth 1 or 2+) and must replace the source group in the active path and show `"Đã tạo {name}"`.
  3. `"Danh mục của nhóm"` in `GroupContainerView`'s overflow menu must be shown only to roles allowed to manage categories and must scroll `GroupSettingsView` to the categories section.
- **Options:**
  1. Duplicate the unavailable view in `AppShell` and `GroupsFeature`, push cloned groups onto `groupsPath`, or scroll settings manually via `UIScrollView`.
  2. Place `GroupUnavailableView` in `DesignSystem/States/GroupUnavailableView.swift` (imported by both `AppShell` and `GroupsFeature`); add `Route.SettingsSectionAnchor.categories` (`initialSection: SettingsSectionAnchor? = nil`) on `.groupSettings` and `initialToast: String? = nil` on `.groupFeed` (defaulted to `nil` so deep links stay compatible); add `Route.associatedGroupId` + `RootView.onReplaceGroup` so cloning replaces from the earliest route referencing the source group (Back -> list) and displays `ConfirmationToast` (`"Đã tạo {name}"`); gate `"Danh mục của nhóm"` with `if isOwner` (matching `GroupSettingsView`'s permission rule) and scroll to `CategoryManagementSection` via `ScrollViewReader`.
- **Choice:** Option 2.
- **Reason:** Zero duplicated views, zero circular module imports, backwards-compatible `Route` parameters, and guaranteed single-hop Back return after cloning from any entry point.

### D12 — Sheet inventory, size classification, dismiss controls, and discard guards (Task 5.6.C.1)

- **Problem:** 32 `.sheet` and `.fullScreenCover` presentations existed across `SongPhangKit/Sources/` (excluding 3 `#if DEBUG` preview-only sheets in `SheetPresentation.swift` and `DebugStageAGallerySection.swift`), with inconsistent hardcoded `.presentationDetents`, back arrows (`SPScreenHeader`) inside sheets (`PayView`, `PaymentDetailsView`), a nested sheet inside `PaymentDetailsView` (`isPickingBank`), mixed dismiss labels (`"Thôi"`, `"Đóng"`, `"Quay lại"`, `"Xong"`), and no unsaved-changes discard guards on editing sheets.
- **Options:**
  1. Keep ad-hoc detents and nested sheets while wrapping only a few confirmation sheets.
  2. Classify every presentation against Spec §5.1–§5.3 and apply `.spSheet`, `SheetCloseButton` / `SheetCancelButton`, in-stack `.navigationDestination` for multi-step sheet subflows, and `.discardGuard` uniformly across all 32 presentations:

| # | Presentation | File | Old height / detent | New `SheetSize` | Dismiss control | Discard guard |
|---|---|---|---|---|---|---|
| 1 | `PhotoViewerSheet` | `DesignSystem/Components/PhotoAttachmentViews.swift:57` | `.fullScreenCover` | `.fullScreenCover` | Top-right X (`attachments.closePhoto`) | No |
| 2 | `TelegramPairingSheetView` | `AccountFeature/Account/TelegramAccountCardView.swift:77` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Đóng"`) | No |
| 3 | Category management sheet | `LedgerFeature/ExpenseForm/ExpenseFormView.swift:133` | `[.medium, .large]` | `.half` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Quay lại"`) | No |
| 4 | Reject transaction sheet | `LedgerFeature/TransactionDetail/ApprovalBlockView.swift:78` | `[.medium, .large]` | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` (replaces bottom `"Huỷ"`) | Yes (`!rejectNote.trimmed.isEmpty`) |
| 5 | Dispute transaction sheet | `LedgerFeature/TransactionDetail/DisputeBlockView.swift:63` | `[.medium, .large]` | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` (replaces bottom `"Huỷ"`) | Yes (`!disputeReason.trimmed.isEmpty`) |
| 6 | `CameraPickerView` (capture) | `LedgerFeature/ReceiptCapture/ReceiptCaptureSheet.swift:233` | `.fullScreenCover` | `.fullScreenCover` | System camera Cancel | No |
| 7 | `CameraPickerView` (retake) | `LedgerFeature/ReceiptReview/ReceiptReviewView.swift:75` | `.fullScreenCover` | `.fullScreenCover` | System camera Cancel | No |
| 8 | `CloseCycleSheetView` | `LedgerFeature/Balances/CloseCycleSheetView.swift:130` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (`title != defaultTitle`) |
| 9 | `MemberBreakdownSheetView` | `LedgerFeature/Balances/MemberBreakdownSheetView.swift:148` | Large default | `.half` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 10 | `FilterSheetView` | `LedgerFeature/GroupFeed/GroupFeedView.swift:154` | `.spSheet(.half)` (`5.6.A.4`) | `.half` | `SheetCancelButton` | No |
| 11 | Bank picker (`isPickingBank`) | `PaymentsFeature/PaymentDetails/PaymentDetailsView.swift:110` | Nested `.sheet` | Removed nested `.sheet` -> `.navigationDestination` inside `PaymentDetailsView` `NavigationStack` | System Back (removes `SPScreenHeader` close + `"Huỷ"`) | Covered by parent `PaymentDetailsView` |
| 12 | `FileShareSheet` | `StatisticsFeature/Stats/StatsView.swift:74` | `[.medium, .large]` | `.half` (UIKit `UIActivityViewController` requires medium/large detents rather than SwiftUI `.fitted` measurement) | System share sheet Close | No |
| 13 | `RecurringFormSheetView` (create) | `StatisticsFeature/Recurring/RecurringSectionView.swift:85` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (any field changed from defaults) |
| 14 | `RecurringFormSheetView` (edit) | `StatisticsFeature/Recurring/RecurringSectionView.swift:99` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (any field changed from initial) |
| 15 | `CloneGroupSheetView` (container) | `AppShell/GroupContainerView.swift:297` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (draft/toggles changed) |
| 16 | `ReceiptCaptureSheet` | `AppShell/GroupContainerView.swift:317` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` (replaces bottom `"Huỷ"`) | No |
| 17 | `GuestLinkSheetView` (container) | `AppShell/GroupContainerView.swift:371` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 18 | `ShareCardPreviewSheet` | `AppShell/GroupContainerView.swift:379` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 19 | `PayView` (Pay / "Đã nhận") | `AppShell/GroupContainerView.swift:390` | Large default (`SPScreenHeader`) | `.fitted` (`expandable: true, embedsNavigationStack: true`) | `SheetCancelButton` when creating report, else `SheetCloseButton` (removes `SPScreenHeader` back arrow) | Yes (`hasUnsavedProofDraft`) |
| 20 | `DebugPanel` (`#if DEBUG`) | `AppShell/RootView.swift:480` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCloseButton` | No |
| 21 | `PushPermissionSheet` | `AppShell/RootView.swift:512` | `[.medium]` | `.half` | Keeps `"Để sau"` (`ios.push.later`) | No |
| 22 | `GuestGroupView` | `AppShell/RootView.swift:538` | `.fullScreenCover` | `.fullScreenCover` | `SheetCloseButton` (replaces `"Quay lại"`) | No |
| 23 | `GuestLinkSheetView` (members) | `AppShell/RouteDestination.swift:499` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 24 | `CreateFundSheetView` | `AppShell/RouteDestination.swift:515` | `[.medium]` | `.half` (`embedsNavigationStack: true`) | `SheetCancelButton` (replaces bottom `"Huỷ"`) | Yes (`name != defaultName \|\| holderChanged`) |
| 25 | `PaymentDetailsView` | `AppShell/RouteDestination.swift:523` | Large default (`SPScreenHeader`) | `.half` (`embedsNavigationStack: true`) | `SheetCancelButton` (removes `SPScreenHeader` close) | Yes (`model.hasUnsavedChanges`) |
| 26 | `GuestBreakdownSheet` | `GroupsFeature/GuestShare/GuestGroupView.swift:67` | Large default | `.half` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 27 | `GuestTransactionDetailSheet` | `GroupsFeature/GuestShare/GuestGroupView.swift:91` | Large default | `.half` (`embedsNavigationStack: true`) | `SheetCloseButton` (replaces `"Xong"`) | No |
| 28 | `HouseholdFormSheetView` (create) | `GroupsFeature/Members/HouseholdsSectionView.swift:80` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (name/members/rep changed) |
| 29 | `HouseholdFormSheetView` (edit) | `GroupsFeature/Members/HouseholdsSectionView.swift:99` | Large default | `.form` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (name/members/rep changed) |
| 30 | `deleteGroupSheet` | `GroupsFeature/GroupSettings/GroupSettingsView.swift:139` | `[.medium]` | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` (replaces `"Thôi"`) | Yes (`!deleteConfirmationText.isEmpty`) |
| 31 | `CloneGroupSheetView` (settings) | `GroupsFeature/GroupSettings/GroupSettingsView.swift:154` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (draft/toggles changed) |
| 32 | `CloneGroupSheetView` (list) | `GroupsFeature/GroupList/GroupListView.swift:117` | Large default | `.fitted` (`embedsNavigationStack: true`) | `SheetCancelButton` | Yes (draft/toggles changed) |

- **Choice:** Option 2.
- **Reason:** Matches Spec §5.1–§5.3 and eliminates every nested sheet, sheet back chevron, `"Thôi"`/`"Đóng"`/`"Quay lại"`/`"Xong"` sheet dismiss inconsistency, and unguarded form dismissal while keeping `.fullScreenCover` for camera and photo viewers.

### D13 — Geometric avatar initial font exception, `check-strings.sh` allowlist, and >60-char copy inventory (Task 5.6.C.4)

- **Problem:**
  1. `MemberShapeView.swift:68` renders the single initial letter inside a fixed `size`-pt geometric avatar shape using `.font(.system(size: initialFontSize, weight: .black))`. Scaling that decorative glyph above the `size`-pt shape would overflow the avatar circle/diamond/squircle/leaf.
  2. Spec §11.2 removes redundant `"đồng"` next to formatted amounts (`groups.owedToYou`, `groups.youOwe`, `split.unitMoney`) without editing `apps/web/src/messages/vi.ts`, which previously caused `check-strings.sh` to fail on any non-`ios.*` difference.
  3. Task `5.6.C.4` requires auditing every string longer than 60 characters in `Localizable.xcstrings` and assigning an owning phase (`5.7` or `5.8`), without shortening unrelated copy early.
- **Options:**
  1. Wrap `MemberShapeView`'s initial letter in `.spIconFont` (overflowing its fixed `size` badge at AX5), ignore `vi.ts` mismatches in `check-strings.sh`, and leave >60-char strings untracked.
  2. Keep `MemberShapeView.swift:68` (paired with `.accessibilityHidden(true)` and parent `.accessibilityLabel(name)`) as the sole intentional proportional-to-container font alongside `Typography.swift`'s `@ScaledMetric` implementation; update `apps/ios/Scripts/check-strings.sh` to read `docs/superpowers/runs/phase-5-*/copy-changes.md` markdown tables so only explicitly recorded deltas pass (`ALLOWED (copy-changes): <key>`); and record all 38 strings >60 characters below for `5.7` / `5.8` follow-up without shortening them outside §11.2:

| # | Key | Length | Screen / Component | Owning phase |
|---|---|---|---|---|
| 1 | `account.deleteHint` | 106 | Account | 5.8 |
| 2 | `account.ownerRequired` | 79 | Account | 5.8 |
| 3 | `balances.pairwiseHint` | 64 | Balances | 5.8 |
| 4 | `compose.countReason` | 66 | Quick Entry | 5.7 |
| 5 | `compose.memberReason` | 79 | Quick Entry | 5.7 |
| 6 | `cycles.carryOverNote` | 73 | Close Cycle / Cycles | 5.8 |
| 7 | `cycles.reopenConfirmBody` | 69 | Settlement Cycles | 5.8 |
| 8 | `forgotPassword.submitted` | 83 | Auth / Forgot Password | 5.8 |
| 9 | `groups.archiveConfirmBody` | 91 | Group Settings | 5.8 |
| 10 | `guestLink.description` | 97 | Guest Link Sheet | 5.8 |
| 11 | `households.repActiveError` | 82 | Household Form | 5.8 |
| 12 | `households.sectionHint` | 85 | Group Members / Households | 5.8 |
| 13 | `households.ungroupConfirm` | 68 | Group Members / Households | 5.8 |
| 14 | `ios.notifications.recurringPostedGroup` | 62 | Notifications | 5.8 |
| 15 | `ios.push.promptBody` | 63 | Push Permission Sheet | 5.8 |
| 16 | `ios.shareExtension.signInRequired` | 62 | Share Extension | 5.8 |
| 17 | `join.isOwed` | 82 | Join Group | 5.8 |
| 18 | `join.owes` | 80 | Join Group | 5.8 |
| 19 | `login.googleUnverified` | 108 | Sign In | 5.8 |
| 20 | `members.deactivateWarning` | 70 | Group Members | 5.8 |
| 21 | `members.hasTransactions` | 67 | Group Members | 5.8 |
| 22 | `members.removeBody` | 70 | Group Members | 5.8 |
| 23 | `newGroup.hint` | 89 | Create Group | 5.8 |
| 24 | `receipts.mismatch` | 80 | Receipt Review | 5.7 |
| 25 | `register.submittedBody` | 90 | Auth / Register | 5.8 |
| 26 | `settings.deleteBody` | 89 | Group Settings | 5.8 |
| 27 | `settle.partialHint` | 61 | Settle | 5.8 |
| 28 | `shareCard.preset1` | 67 | Share Card | 5.8 |
| 29 | `shareCard.preset2` | 66 | Share Card | 5.8 |
| 30 | `shareCard.preset3` | 62 | Share Card | 5.8 |
| 31 | `telegram.confirmStepBody` | 107 | Telegram Pairing | 5.8 |
| 32 | `telegram.identityTaken` | 69 | Telegram Pairing | 5.8 |
| 33 | `telegram.privateStepHint` | 105 | Telegram Pairing | 5.8 |
| 34 | `telegram.privateStepHintNoBot` | 102 | Telegram Pairing | 5.8 |
| 35 | `telegram.settingsHint` | 62 | Group Settings / Telegram | 5.8 |
| 36 | `telegram.stagedWaitingConfirm` | 81 | Telegram Pairing | 5.8 |
| 37 | `telegram.startPairingHint` | 89 | Telegram Pairing | 5.8 |
| 38 | `unparsed.sumShort` | 85 | Quick Entry / Expense Form | 5.7 |

- **Choice:** Option 2.
- **Reason:** Keeps geometric avatars bounded cleanly while VoiceOver announces the full name, preserves ADR-044 mirror verification by failing on any unrecorded delta, and tracks every >60-char string for its screen redesign phase (`5.7` or `5.8`).

### D14 — Stage D fake scenario gaps, launch flags, and stats consistency (Task 5.6.D.1)

- **Problem:** Seven review screens/states were unreachable with existing `--scripted` fakes and launch flags, server features did not load on launch when starting `.signedIn` in scripted mode, and `FakeWorld+Stats.swift` reported `total: Money(1_399_999)` while its three categories summed to `1_599_999` (`F4-32`).
- **Missing literal audit by flag:**

| Flag | Missing literal / behavior found | Resolution |
|---|---|---|
| `--with-payment-details` | `TripScenario.members` (`Minh`, `Thu`) and `TripScenario.step4Balances.transfers` have `paymentMethods: []`, so `PayView` has no VietQR/bank methods | Added `sampleMinhPaymentMethods`, `sampleThuPaymentMethods`, and `seedSamplePaymentDetails(groupId:)` in `FakeWorld+Payments.swift` |
| `--with-pending-request` | `FakeWorld.settlementRequestsByGroup` starts empty (`[:]`) and `SuggestedTransfer.pendingSettlement` is `nil` | Added `seedSamplePendingSettlementRequest(groupId:)` with literal `SettlementRequest` (`Thu -> Minh`, `210_000`) and matching transfer `PendingSettlement` |
| `--with-fund` | `FakeWorld.init(hasFundAndBudget:)` existed in `FakeWorld+FundBudget.swift`, but `RootView` never exposed a launch flag for it | Wired `hasFundAndBudget: args.contains("--with-fund")` in `RootView` |
| `--with-pending-approval` | `TripScenario.group` has `approvalThreshold: nil` and all transactions have `approval.status == .none` | Added `seedSamplePendingApproval(groupId:)` in `FakeWorld+Ledger.swift` (`approvalThreshold = 500_000`, literal `850_000` pending expense `tx-pending-approval`, plus `--route-tx-pending-approval`) |
| `--feature-telegram` | `FakeAuthRepository.serverFeatures()` returned hardcoded `telegram: false`, and `RootView` skipped `SessionModel.loadSession()` when scripted state started `.signedIn` | Moved `ServerFeatures` onto `FakeWorld.features`, added `SessionModel.loadFeatures()` called at launch in `RootView`, and wired `--feature-telegram` |
| `--guest-token` | `FakeWorld.guestLinksByGroup` started empty (`[:]`), causing both `--route-guest-share` (`demo-guest-token`) and `--guest-token <token>` to return 404 | Seeded `"demo-guest-token"` in `FakeWorld.init` for `.tripStep4`/first group and added `seedGuestToken(_:)` for non-`"invalid"` `--guest-token` values |
| `--upgrade-required` | `FakeAuthRepository.serverFeatures()` returned `MinAppVersion(ios: "0.0.0")` and scripted launch did not load features | `--upgrade-required` sets `FakeWorld.features.minAppVersion.ios = "99.0.0"` so `SessionModel.loadFeatures()` triggers `UpgradeRequiredView` |
| `--push-prompt` | `FakeAuthRepository.serverFeatures()` returned `push: false` and `PushPermissionSheet` only appeared after saving an expense with `.notDetermined` permission | `--push-prompt` sets `features.push = true` and opens `pushCoordinator.isPermissionSheetPresented = true` at launch |

- **Options:**
  1. Seed scenarios asynchronously inside `RootView.task` after child views start loading.
  2. Seed scenarios synchronously inside `FakeWorld.init(...)` (with `public` seed helpers also callable from `DebugPanel`), load `SessionModel.loadFeatures()` at launch, and fix `FakeWorld+Stats.swift` literals (`total`, `byBucket`, `byMember` paid/share all equal `1_599_999` = `1_200_000 + 300_000 + 99_999`, matching `PreviewSamples.sampleCycle.totalExpenseAmount`).
- **Choice:** Option 2.
- **Reason:** Synchronous seeding inside `FakeWorld.init` prevents launch races between `RootView.task` and child view `.task` loads while keeping all fakes strictly literal with zero arithmetic on `Money`.
