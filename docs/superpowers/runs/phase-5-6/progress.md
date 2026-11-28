# phase-5-6 — Run Progress

- Plan: `docs/superpowers/plans/2026-11-28-phase-5-6/`
- Spec: `docs/superpowers/specs/2026-11-28-phase-5-6-ios-foundations-design.md`
- Starting `main` SHA: `6d8f398`
- Starting `phase-5-6` SHA: `6d8f398`

## Task 0 — Re-baseline

- [x] **Task 0 — Re-baseline and "before" captures** (commit `1bdf2e6`)
  - **Approach:**
    - Files to create/modify: `docs/superpowers/runs/phase-5-6/{progress,decisions}.md`, `docs/superpowers/runs/phase-5-6/screens/before/*.png`, and `apps/ios/SongPhangKit/Sources/AppShell/RootView.swift` (`#if DEBUG` `--route-groups` and `--route-tx-detail` launch flags, Decision D2).
    - Approach: Confirm clean git tree on `phase-5-6` at `6d8f398`, run the iOS gate and `pnpm check`, verify every plan-referenced file and spec count in `decisions.md`, capture 40 "before" screenshots (10 baseline screens across light, dark, and `accessibility-extra-extra-extra-large` on `iPhone 17 Pro`, plus all 10 screens on `SP-SE3-review` iPhone SE 3rd generation), and run the baseline 10-second `xctrace` scroll profile on `--scripted --scenario-large --route-feed --auto-scroll-large`.
    - Why this is the simplest approach: Reuses existing `#if DEBUG` route flags in `RootView.swift` with two additive branches (`--route-groups`, `--route-tx-detail`) so every baseline screen renders untouched in headless `simctl`.
    - Rejected alternative: Leaving `groups` and `transaction detail` uncaptured in headless `simctl` — rejected because B01 (`TransactionDetailView`) is a primary Phase 5.6 baseline screen.
    - Questions: none (Decisions D1 and D2 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `git branch --show-current`: `phase-5-6` (clean working tree at `6d8f398`, `main` at `6d8f398`).
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build` (with `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` on all 8 target configs in `project.pbxproj` and `.treatAllWarnings(as: .error)` on all 13 targets in `SongPhangKit/Package.swift`; see Decision D1): `** BUILD SUCCEEDED **`.
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output).
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: exit `0` (`Checked 595 files in 261ms. No fixes applied. Found 9 warnings.` pre-existing `<img>` warnings in `apps/web`; 8 workspace `tsc --noEmit` passed; `OpenAPI contract snapshot is up to date.`).
  - **Counts verified:** `17` `.navigationBarBackButtonHidden(true)`, `32` `.sheet`/`.fullScreenCover`, `17` animation calls (`4` files reading `accessibilityReduceMotion`), `22` `Haptics.` calls, `54` `.font(.system(size:` in `SongPhangKit/Sources/` (`55` across `apps/ios/` including `ShareExtensionView.swift`), `8` `SongPhangKit` files using `ProgressView(`, `963` catalog keys, `38` strings over 60 characters.
  - **"Before" captures (`docs/superpowers/runs/phase-5-6/screens/before/`):**
    - `iPhone 17 Pro` (`607AC652-2E92-4BE7-BA18-1B888D79684B`, iOS 26.5): `{overview,groups,group-feed,balances,transaction-detail,members,settings,account,expense-form,quick-entry}-{light,dark,ax5}.png` (30 files).
    - `iPhone SE (3rd generation)` (`SP-SE3-review`, `53C1604F-AB7D-45EB-BC7D-F6D68A0ACFF4`, iOS 26.5): `se-{overview,groups,group-feed,balances,transaction-detail,members,settings,account,expense-form,quick-entry}.png` (10 files).
  - **Baseline profile (`--scripted --scenario-large --route-feed --auto-scroll-large`, 10s on `iPhone 17 Pro`):**
    - `xcrun xctrace record --template 'SwiftUI'`: failed on Simulator with `* [Error] Hitches is not supported on this platform.`
    - `xcrun xctrace record --instrument 'SwiftUI'`: completed with `* [Warning] Trace file had no SwiftUI data` (SwiftUI view-body signposts require a physical iOS device; recorded under `Not verified`).
    - `xcrun xctrace record --instrument 'Hangs'` (`potential-hangs` threshold `100 ms` during 500-row load + rapid scroll): `16` intervals recorded (`2` Microhangs: `321.58 ms`, `426.46 ms`; `14` Brief Unresponsiveness: `103.48 ms`–`245.15 ms`).
  - **Security review:** checked relevant items 1, 2, 8 on `git diff`; `#if DEBUG`-only launch flag branches with hardcoded scenario IDs, no secrets, no new dependencies, no issues found.
  - **Findings closed:** none (baseline task).

## Stage A — Design system

- [x] **Task 5.6.A.1 — Motion tokens and Reduce Motion** (commit `bb20204`)
  - **Approach:**
    - Files to create/modify: `DesignSystem/Tokens/Motion.swift` (new), `DesignSystem/Components/{MoneyText,MoneyFormat,ControlsAndQR}.swift`, `AppShell/{GroupContainerView,RootView}.swift`, `GroupsFeature/CreateGroup/CreateGroupView.swift`, `LedgerFeature/Balances/{BalancesView,SettlementCyclesSectionView}.swift`, `LedgerFeature/ConfirmCard/ShareShapesView.swift`, `LedgerFeature/GroupFeed/{GroupFeedView,GroupFeedSubViews}.swift`, `LedgerFeature/QuickEntry/QuickEntryView.swift`, `LedgerFeature/Settle/SettleView.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift`, `OverviewFeature/Overview/OverviewView.swift`.
    - Approach: Introduce `Motion.quick`, `Motion.bounce`, and `Motion.smooth` springs plus `Motion.animation(_:reduceMotion:allowOpacityFade:)`, `Motion.withAnimation(...)`, and `.spAnimation(_:value:)` reading `\.accessibilityReduceMotion`; migrate all 17 existing animation call sites to `Motion` tokens; remove whole-screen fade on segment switches in `GroupContainerView` while sliding the selection pill via persistent `.matchedGeometryEffect(..., isSource: false)` in `SPSegmentedControl` and `GroupContainerView`; add `MoneyText` `.hero` style using `.contentTransition(.numericText(countsDown:))` (integer-only direction tracking, Decision D3) on Overview hero, Group Feed balance card, and Balances hero card.
    - Why this is the simplest approach: Centralizes Reduce Motion handling in one modifier/helper so individual screens never forget to check it, and avoids floating-point conversion on `Money`.
    - Rejected alternative: Wrapping `selectedSegment` changes in `withAnimation` — rejected because it cross-fades the entire screen content below the segment bar (`F2-56`).
    - Questions: none (Decision D3 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - `grep -rn "\bwithAnimation\b\|\.animation(" apps/ios/SongPhangKit/Sources/`: all 17 call sites routed through `Motion` (`Motion.swift`, `Motion.withAnimation`, `.spAnimation`); zero raw SwiftUI animation calls remain.
    - Simulator (`iPhone 17 Pro`, `--scripted --route-feed --exercise-segment-switch`): selection pill slid from `Chi tiêu` → `Thanh toán` → `Quỹ & Thống kê` with `Motion.quick` and zero screen fade (`screens/stage-a/a1-segment-payments.png`, `a1-segment-stats.png`).
    - Simulator (`--scripted --route-feed --exercise-record-payment`): recording Thu → Minh `210.000 đ` rolled hero balance from `500.001 đ` down to `290.001 đ` with `.numericText(countsDown: true)` (`screens/stage-a/a1-balance-before-roll.png`, `a1-balance-after-roll.png` capturing mid-roll `9`, `a1-balance-settled.png`).
    - Simulator Reduce Motion (`--reduce-motion`): OSLog verified `Motion.animation reduceMotion=true allowOpacityFade=false` returning `nil`; segment switches and `500.001 đ` → `290.001 đ` snapped immediately with no slide, scale, or digit roll (`screens/stage-a/a1-balance-reduce-motion.png`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; UI-only motion/formatting changes and `#if DEBUG` launch flags, no issues found.
  - **Findings closed:** `F2-132`, `F2-57`, `F2-58`, `F2-61`, `F2-62`, `F1-58`, `F1-74`, `F2-63`, `F4-53`, `F1-44`, `F2-59`, `F2-60`, `F2-56` (component part).

- [x] **Task 5.6.A.2 — Haptics, sound and the "Âm thanh và rung" setting** (commit `fc2ddd8`)
  - **Approach:**
    - Files to create/modify/delete: create `apps/ios/Scripts/generate-sounds.swift`, `DesignSystem/Resources/Sounds/{coin,ting,chord}.caf`, `DesignSystem/Components/{Feedback,SoundPlayer}.swift`; delete `DesignSystem/Components/Haptics.swift`; modify `DesignSystem/Components/ChannelPillPicker.swift`, `LedgerFeature/Balances/{ShareCardPreviewSheet,SettlementVaultSectionView}.swift`, `LedgerFeature/GroupFeed/GroupFeedView.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift`, `AppShell/{GroupContainerView,Debug/DebugGalleryView}.swift`, `GroupsFeature/GuestShare/{GuestLinkSheetView,GuestGroupView}.swift`, `AccountFeature/Account/AccountView.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`.
    - Approach: Synthesize `coin` (150 ms), `ting` (240 ms), and `chord` (360 ms) locally via `generate-sounds.swift` + `afconvert -f caff -d LEI16`; preload them in `SoundPlayer.shared` on an `AVAudioSession` `.ambient` category gated on `FeedbackSettings.isSoundEnabled`; implement `.spFeedback(_:trigger:)` over `SwiftUI.View.sensoryFeedback(trigger:_:)` gated on `FeedbackSettings.isHapticsEnabled`; migrate all 22 `Haptics.` call sites (removing the 2 plain navigation segment switches in `GroupContainerView`), delete `Haptics.swift`, and add the "Âm thanh và rung" card to `AccountView`.
    - Why this is the simplest approach: Uses `Package.swift`'s existing `.process("Resources")` rule, Apple's `AVAudioPlayer` + `sensoryFeedback(trigger:_:)`, and `@AppStorage` matching `AppearanceMode`.
    - Rejected alternative: System sound IDs (`AudioServicesPlaySystemSound`) — rejected by ADR-043 (undocumented IDs and no fine volume envelope).
    - Questions: none (Decision D4 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - `swift apps/ios/Scripts/generate-sounds.swift`: generated `coin.caf` (150 ms), `ting.caf` (240 ms), `chord.caf` (360 ms), each a few KB under `DesignSystem/Resources/Sounds/`.
    - `grep -rn "\bHaptics\b" apps/ios/SongPhangKit/Sources/`: 0 matches (`Haptics.swift` deleted).
    - Simulator (`--gallery-components --exercise-feedback`): OSLog verified `SoundPlayer played effect=coin started=true`, `effect=ting started=true`, `effect=chord started=true` and `spFeedback kind=selection enabled=true`.
    - Simulator with settings off (`--gallery-components --exercise-feedback --sound-off --haptics-off`): OSLog verified `SoundPlayer suppressed (sound off)` for all 3 sounds and `spFeedback kind=selection enabled=false` (returns `nil`).
    - Simulator (`--scripted --route-account`, light & dark): verified "Âm thanh và rung" card with "Âm thanh" and "Rung" toggles both ON by default (`screens/stage-a/a2-account-feedback-light.png`, `a2-account-feedback-dark.png`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; local `UserDefaults` booleans and bundled `.caf` assets only, no secrets or external calls, no issues found.
  - **Findings closed:** `F1-60`, `F4-55`, `F2-127`, `F1-54`, `F1-55`, `F1-56`, `F1-57`.

- [x] **Task 5.6.A.3 — Typography foundation** (commit `91af6b9`)
  - **Approach:**
    - Files to create/modify: `DesignSystem/Tokens/Typography.swift`, `DesignSystem/Components/AdaptiveStack.swift` (new), `docs/superpowers/runs/phase-5-6/{decisions,progress}.md`.
    - Approach: Replace `Typography.heroNumber`'s fixed-size fallback with `.system(.largeTitle, design: .default, weight: .black)`; add `Typography.displayNumber` (44 pt `.largeTitle`), `Typography.microBold` (11 pt `.caption2`), `Typography.micro` (11 pt `.caption2`), and `.spIconFont(size:weight:relativeTo:)` (`@ScaledMetric` modifier); configure `UINavigationBar.appearance()` inline (`BeVietnamPro-ExtraBold`, `.headline` metrics) and large (`BeVietnamPro-Black`, `.largeTitle` metrics) title attributes inside `registerFontsIfAvailable()`; add `AdaptiveStack` (`AnyLayout` switching from `HStackLayout` to `VStackLayout` at `dynamicTypeSize.isAccessibilitySize`) with default and `accessibility5` `#Preview`s; record the 55-entry fixed-font mapping table in `decisions.md` (D5).
    - Why this is the simplest approach: Keeps all typography tokens and `@ScaledMetric` icon scaling in `Typography.swift` and leaves iOS 26 Liquid Glass bar backgrounds untouched.
    - Rejected alternative: Replacing `UINavigationBar.appearance().standardAppearance` — rejected because resetting `UINavigationBarAppearance` would override iOS 26's system scroll-edge glass effect.
    - Questions: none (Decision D5 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - Verified in Simulator (`iPhone 17 Pro`, iOS 26.5) on a temporary `NavigationStack` wrapper (removed before commit) that both inline and large navigation titles render in `Be Vietnam Pro` (`screens/stage-a/a3-nav-title-font.png`).
    - Verified every `Typography` style uses `relativeTo:` with a Dynamic Type text-style fallback (`0` fixed-size `Typography` styles).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; `DesignSystem` typography/layout views only, no issues found.
  - **Findings closed:** part of `B07`, `F3-28` (foundation; sweep in `5.6.C.4`).

- [x] **Task 5.6.A.4 — Sheet system** (commit `c4c858b`)
  - **Approach:**
    - Files to create/modify: `DesignSystem/Components/SheetPresentation.swift` (new), `LedgerFeature/GroupFeed/{FilterSheetView,GroupFeedView}.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`.
    - Approach: Implement `SheetSize` (`.fitted`, `.half`, `.form`), `.spSheet(_:expandable:embedsNavigationStack:)` with intrinsic `fixedSize(vertical: true)` / `PreferenceKey` height measurement capped at `.large` and no custom `presentationBackground` so iOS 26 Liquid Glass applies; implement `.discardGuard(isDirty:onDiscard:)` with `interactiveDismissDisabled` and `"Bỏ thay đổi?"` / `"Bỏ"` / `"Huỷ"` confirmation dialog wired to `SheetCancelButton` and `SheetCloseButton` via `\.spSheetRequestDismiss`; switch `FilterSheetView` to `.spSheet(.half)` + `SheetCancelButton`.
    - Why this is the simplest approach: Measuring inside `fixedSize(vertical: true)` or inside a vertical `ScrollView` decouples content height from detent height so oscillation cannot occur, and `\.spSheetRequestDismiss` avoids per-sheet confirmation dialog boilerplate in `5.6.C.1`.
    - Rejected alternative: Measuring the outer sheet container directly — rejected because container height tracks the active detent and can loop.
    - Questions: none (Decision D6 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - Simulator (`--scripted --route-feed --open-filter-sheet`): `FilterSheetView` rendered at `.half` (`[.medium, .large]`) with drag indicator, `"Huỷ"` top-left via `SheetCancelButton`, and iOS 26 Liquid Glass chrome (`screens/stage-a/a4-filter-sheet-half.png`).
    - Simulator temporary `.fitted` short and long test sheets at default (`large`) and `accessibility-extra-extra-extra-large` (`AX5`): short sheet hugged content cleanly with Liquid Glass background (`screens/stage-a/a4-fitted-short.png`), long sheet at `AX5` capped cleanly at `.large` and scrolled without jitter or clipping (`screens/stage-a/a4-fitted-long-ax5.png`); temporary test sheet code removed before commit.
    - Security review: checked relevant items 1, 2, 8 on `git diff`; SwiftUI sheet presentation and confirmation dialog only, no issues found.
  - **Findings closed:** `F2-29`, `F2-30`, `F2-31`, `F2-32`, `F4-03`, `F4-04` (component part; applied to all 32 presentations in `5.6.C.1`), `F2-130` (reference).

- [x] **Task 5.6.A.5 — Selection and state components** (commit `25020e6`)
  - **Approach:**
    - Files to create/modify: `DesignSystem/Components/{MemberPicker,ChipRow,CountBadge,MemberShapeView,ShareCardCanvasView}.swift`, `DesignSystem/States/StateViews.swift`, `DesignSystem/Resources/Localizable.xcstrings`, plus `MemberShapeView`/`EmptyState` call sites across `AppShell`, `GroupsFeature`, `LedgerFeature`, and `PaymentsFeature`, and `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`.
    - Approach: Create `MemberPicker` (single/multiple selection, `MemberShapeView(member:size:)`, `"Bạn"` for current member, `.spFeedback(.selection)`, `Motion.quick`, vertical stack at accessibility Dynamic Type sizes, VoiceOver `"{name}, đã chọn"`), `ChipRow` (`<= 4` wrap layout, `> 4` untruncated horizontal scroll leaving ~half of the trailing boundary chip visible), and `CountBadge` (renders nothing when `<= 0`); require either `action:` or `noActionReason:` on `EmptyState` (updating `FundView.swift`); remove `showInitial` from `MemberShapeView` so plain dots cannot be rendered anywhere and add `isClaimed` dashed border (`Tokens.dashed`) + `init(member:size:)`.
    - Why this is the simplest approach: Making plain dots and silent actionless empty states unrepresentable at compile time prevents regression across all 13 targets.
    - Rejected alternative: Keeping `showInitial: Bool = true` — rejected because existing call sites could continue passing `false`.
    - Questions: none (Decision D7 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - Simulator (`--scripted --route-members` and `--scripted --route-feed` on `iPhone 17 Pro`): verified every `MemberShapeView` draws its member initial (`0` plain dots remaining across feed cards, compact transfer rows, and header pills) and unclaimed members render `Tokens.dashed` outlines (`screens/stage-a/a5-members-unclaimed.png`, `screens/stage-a/a5-feed-initials.png`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; UI selection/state components and avatar rendering only, no issues found.
  - **Findings closed:** `F4-01`, `F4-02` (component part), `F2-125`, `F2-44` (component part), `F2-123` (component part), `F2-122`, `F2-43`, `F1-01`.

- [x] **Task 5.6.A.6 — Feedback and money components, gallery, Stage A gate** (commit `16ee165`)
  - **Approach:**
    - Files to create/modify: `DesignSystem/Components/{CopyButton,ConfirmationToast,ShapeLoader,ShapeBurst,FieldShake,PersonName,MoneyText,MoneyFormat,MemberPicker}.swift`, `DesignSystem/States/SkeletonBlocks.swift`, `AppShell/Debug/{DebugGalleryView,DebugStageAGallerySection}.swift`, `DesignSystem/Resources/Localizable.xcstrings`, and `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`.
    - Approach: Build `CopyButton(value:label:)`, `ConfirmationToast` + `.confirmationToast(_:)`, `ShapeLoader` (4 bouncing brand shapes via `PhaseAnimator` + `Motion.bounce`, pulsing opacity under Reduce Motion), `ShapeBurst(members:trigger:)` (<= 1 s burst, still under Reduce Motion), `.fieldShake(trigger:)` (horizontal shake + `.spFeedback(.warning)`, red border only under Reduce Motion), `SkeletonBlocks` (`BalanceCardSkeleton`, `LinkRowSkeleton`, `SearchFieldSkeleton`, `TransactionRowSkeleton`, `MemberRowSkeleton` with `TimelineView` shimmer suppressed under Reduce Motion), explicit `MoneyText.Role` (`.hero`, `.primary`, `.secondary`), and `PersonName.display(name:isCurrentUser:)`; expose all Stage A components on `--gallery-components` (`DebugStageAGallerySection`).
    - Why this is the simplest approach: Preserving `MoneyText(style:)` alongside `MoneyText(role:)` keeps all feature targets compiling cleanly until Stage C migration (`5.6.C.4`), while `TimelineView`-backed shimmer/pulse avoids any raw `.animation` modifier bypassing `Motion`.
    - Rejected alternative: Adding `.animation(.repeatForever())` in `ShapeLoader` and `SkeletonBlocks` — rejected because every animation must respect `Motion.isReduced`.
    - Questions: none (Decision D8 recorded in `decisions.md`).
  - **Gates (verbatim — Task 5.6.A.6 + Stage A gate):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: `biome check .` (595 files, 0 errors, 9 pre-existing `noImgElement` warnings in `apps/web`), `pnpm -r typecheck` (8 workspace projects passed), `pnpm --filter @songphang/api contract:check` (`OpenAPI contract snapshot is up to date.`) — exit `0`.
  - **Exercise results:**
    - Simulator `--gallery-components` on `iPhone 17 Pro` (iOS 26.5): captured `screens/stage-a/gallery-components-light.png`, `screens/stage-a/gallery-components-dark.png`, and `screens/stage-a/gallery-components-ax5.png` at `accessibility-extra-extra-extra-large`; verified `MoneyText` `.hero`/`.primary`/`.secondary` roles (zero `"đồng"`), sound/haptic/sheet demo buttons, `CountBadge` (`0` hidden, `3` & `12` visible), `MemberPicker`, `ChipRow` wrap + horizontal peek, `CopyButton`, `ConfirmationToast`, `FieldShake`, `ShapeLoader`, `ShapeBurst`, and all 5 `SkeletonBlocks`.
    - Security review: checked relevant items 1, 2, 8 on `git diff`; `UIPasteboard.general.string` receives only explicit caller value on user tap, zero dynamic HTML/JS/logging of secrets, no issues found.
  - **Findings closed:** `F2-54` (component), `F4-06` (component), `F1-52` (component), `F1-59` (component), `F1-51` and `F2-55` (modifier), `F2-119`, `F2-120` (component part).
  - **Coordinator Stage A Gate (`16ee165`, verified while `ios` idle):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build` (target-level `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` per D1): `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: exit `0` (`Checked 595 files in 187ms. No fixes applied. Found 9 warnings.`; 8 workspace `tsc --noEmit` projects passed; `OpenAPI contract snapshot is up to date.`)
    - Stage A gallery captures (`screens/stage-a/gallery-components-{light,dark,ax5}.png`): verified on disk and visually inspected (light, dark, and `AX5` Dynamic Type).

## Stage B — Navigation

- [x] **Task 5.6.B.1 — Native navigation bars** (commit `93aae72`)
  - **Approach:**
    - Files modified: `ActivityView.swift`, `AccountView.swift`, `ForgotPasswordView.swift`, `RegisterView.swift`, `CreateGroupView.swift`, `GroupSettingsView.swift`, `MembersView.swift`, `BalancesView.swift`, `GroupFeedView.swift`, `QuickEntryView.swift`, `ExpenseFormView.swift`, `SplitEditorView.swift`, `SettleView.swift`, `ReceiptReviewView.swift`, `TransactionDetailView.swift`, `NotificationsView.swift`, `PersonalLedgerView.swift`, `StatsView.swift`, `FundView.swift`, `GroupContainerView.swift`, `RootView.swift`, `docs/superpowers/runs/phase-5-6/{decisions,progress}.md`.
    - Files deleted: `AppShell/PopGestureEnabler.swift`, `AppShell/StatusBarCover.swift`.
    - Approach: Converted `ActivityView` first (`screens/stage-b/b1-activity-{light,dark}.png`) and recorded Decision D9 in `decisions.md`, then applied the identical pattern across all remaining pushed screens, `TransactionDetailView` (removing duplicate back button), `NotificationsView`, and `SplitEditorView` (now pushed via `.navigationDestination(isPresented: $model.isSplitEditorOpen)`). Moved `GroupContainerView`'s title, member-shapes capsule, and overflow menu into the navigation bar; put Overview and Groups tab roots under `.navigationTitle("").navigationBarTitleDisplayMode(.inline)` alongside `.large` titles on `AccountView` and `NotificationsView`; deleted `PopGestureEnabler.swift` and `StatusBarCover.swift`.
    - Why this is the simplest approach: Using system `NavigationStack` chrome everywhere eliminates custom header spacing hacks, restores native edge-swipe back, and gives every screen iOS 26 Liquid Glass scroll-edge clock protection automatically.
    - Rejected alternative: Keeping `SPScreenHeader` on task forms or inline-swapping `SplitEditorView` — rejected because custom back buttons break system edge-swipe consistency.
    - Questions: none (Decision D9 recorded in `decisions.md`; `PayView` and `PaymentDetailsView` retain `SPScreenHeader` inside sheets until `5.6.C.1`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'id=607AC652-2E92-4BE7-BA18-1B888D79684B' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - Verified `grep -rn "navigationBarBackButtonHidden\|PopGestureEnabler\|StatusBarCover" apps/ios/SongPhangKit/Sources/` returns zero matches, and `SPScreenHeader` remains only on the two modal sheet views (`PayView`, `PaymentDetailsView`) scheduled for `5.6.C.1`.
    - Simulator (`iPhone 17 Pro`, iOS 26.5): captured light/dark `ActivityView` (`b1-activity-{light,dark}.png`), light/dark `GroupContainerView` (`b1-group-container{,-dark}.png`), default & AX5 `TransactionDetailView` (`b1-tx-detail{,-ax5}.png` — single native back button), `AccountView` (`b1-account.png`), `NotificationsView` (`b1-notifications.png`), `OverviewView` (`b1-overview.png`), `ExpenseFormView` (`b1-expense-form.png`), `SplitEditorView` (`b1-split-editor.png`), and `SettleView` (`b1-settle.png`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; navigation chrome and SwiftUI modifiers only, no issues found.
  - **Findings closed:** `B01` (`F2-01`), `B19` (`F4-40`), `F2-02`, `F2-03`, `F2-126`, `F2-129`.

- [x] **Task 5.6.B.2 — Tab bar visibility and in-tab navigation** (commit `c55a240`)
  - **Approach:**
    - Files modified: `AppShell/RouteDestination.swift`, `AppShell/RootView.swift`, `docs/superpowers/runs/phase-5-6/{decisions,progress}.md`.
    - Approach: Added exhaustive `RouteDestination.hidesTabBar` switch so the tab bar is visible on all content routes and hidden only on `.quickEntry`, `.newTransactionForm`, `.editTransaction`, `.settle`, `.receiptReview`. Added `RootView.appendToCurrentTab(_:)`, switched `OverviewView` callbacks (`onOpenGroup`, `onOpenBalances`, `onOpenTransaction`, `onOpenDueRecurring`) and `navigate(to:)` (used by `NotificationsView` tab root) to append onto the active tab's stack while keeping `openExternalRoute(_:)` (deep links/universal links), `applyPushTap`, and `--route-*` debug flags opening on `.groups` (and explicit tab links switching tabs). Also removed the redundant `onPop()` from `.notifications` `onBack` closure in `RouteDestination.swift` since `NotificationsView.onDisappear` now runs it on system pop.
    - Why this is the simplest approach: An exhaustive switch prevents future routes from defaulting to the wrong tab-bar visibility, and separating `navigate(to:)` from `openExternalRoute(_:)` keeps Back within the originating tab without breaking external links.
    - Rejected alternative: Per-view `.toolbar(.hidden, for: .tabBar)` modifiers — rejected because centralizing in `RouteDestination` guarantees consistent behavior across all tabs.
    - Questions: none (Decision D10 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'id=607AC652-2E92-4BE7-BA18-1B888D79684B' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - **Exercise results:**
    - Tab bar visibility verified in Simulator (`iPhone 17 Pro`): visible on `--route-tx-detail` (`b2-tx-detail-tabbar-visible.png`), `--route-ledger` (`b2-ledger-tabbar-visible.png`), and `--route-feed` (`b1-group-container.png`); hidden on `--route-new-tx` (`b1-expense-form.png`) and `--route-settle` (`b1-settle.png`).
    - In-tab vs external routes verified: `Overview` -> group/balances/transaction/due-recurring callbacks now call `appendToCurrentTab`, `Notifications` -> `navigate(to:)` calls `appendToCurrentTab`, and `openExternalRoute` / `applyPushTap` / `--route-*` continue targeting `.groups`. `xcrun simctl openurl` with `songphang://group/01a1e4bd-cc25-70c6-860e-275da20487f1/balances` on `SP-SE3-review` triggered iOS's `Open in "Sòng Phẳng"?` confirmation prompt (`b2-deeplink-balances.png`; tapping system dialog requires interactive UI, listed in `manual-checks.md`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; `LinkRouter` URL validation untouched, route dispatch strictly typed on `Route`, no issues found.
  - **Findings closed:** `F2-04`, `F2-05`, `F2-06`.

- [x] **Task 5.6.B.3 — Landing, unavailable screens and the categories entry, Stage B gate**
  - **Approach:**
    - Files created: `DesignSystem/States/GroupUnavailableView.swift`.
    - Files modified: `AppShell/{Route,RouteDestination,GroupContainerView,RootView}.swift`, `GroupsFeature/GroupSettings/GroupSettingsView.swift`, `GroupsFeature/GroupList/GroupListView.swift`, `GroupsFeature/GuestShare/GuestGroupView.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`.
    - Approach: Added `GroupUnavailableView(kind: .notFound | .forbidden, onBackToGroups:)` in `DesignSystem/States/` and wired both `GroupContainerView` and `GroupSettingsView` to render it full-screen with native Back button and zero group chrome/capsule/segments. Added `Route.associatedGroupId` and `RootView.onReplaceGroup`, `GroupListView.onCreatedGroup`, and `GroupSettingsView.onClonedGroup` so cloning from any of the three entry points replaces the source group in the active path (Back -> group list) and shows `ConfirmationToast` (`"Đã tạo {name}"`). Gated `"Danh mục của nhóm"` in `GroupContainerView.overflowMenu` with `if isOwner` and added `Route.SettingsSectionAnchor.categories` + `ScrollViewReader` scroll anchor on `CategoryManagementSection` in `GroupSettingsView`. Also moved `GuestGroupView`'s `NavigationStack` wrapper to `RootView`'s `.fullScreenCover` so pushed `.guestShare` routes render cleanly without a nested `NavigationStack`.
    - Why this is the simplest approach: Putting `GroupUnavailableView` in `DesignSystem` avoids module import cycles between `GroupsFeature` and `AppShell`, and `Route.associatedGroupId` guarantees replace-in-stack works uniformly regardless of stack depth.
    - Rejected alternative: Duplicating unavailable views per feature or manually walking UIKit view controllers — rejected for duplication and fragility.
    - Questions: none (Decision D11 recorded in `decisions.md`).
  - **Gates (verbatim — Task 5.6.B.3 + Stage B gate):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'id=607AC652-2E92-4BE7-BA18-1B888D79684B' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: `biome check .` (595 files, 0 errors, 9 pre-existing `noImgElement` warnings in `apps/web`), `pnpm -r typecheck` (8 workspace projects passed), `pnpm --filter @songphang/api contract:check` (`OpenAPI contract snapshot is up to date.`) — exit `0`.
    - `grep -rn "PopGestureEnabler\|StatusBarCover" apps/ios/SongPhangKit/Sources/`: `GREP_EMPTY_OK` (exit 0 with zero matches).
  - **Exercise results:**
    - Unavailable screens (`B09`, `B18`): `--scripted --unknown-group --route-feed` (`b3-unavailable-notfound.png`) renders `GroupUnavailableView(kind: .notFound)` with native Back, `"Không tìm thấy nhóm này."`, `"Về danh sách nhóm"`, and zero group header/capsule/segments; `--scripted --role-editor --route-settings` (`b3-unavailable-forbidden.png`) renders `.forbidden` cleanly.
    - Categories entry (`B18`): `--scripted --route-settings --settings-categories` (`b3-settings-categories.png`) opens `GroupSettingsView` scrolled directly to `Danh mục của nhóm`; `--role-editor` and `--role-viewer` omit the menu item (`if isOwner`).
    - Clone toast (`B10`, `F4-06`): `--scripted --route-feed --created-toast` (`b3-clone-toast.png`) shows `"Đã tạo Đà Lạt 3N2Đ (bản sao)"` in `ConfirmationToast` above the tab bar; all 3 clone entry points (`GroupListView`, `GroupContainerView`, `GroupSettingsView`) wired via `onCreatedGroup` / `onReplaceTop` / `onReplaceGroup` (`manual-checks.md` covers interactive 3-entry-point clone taps).
    - All 22 `Route.swift` cases opened and captured under `screens/stage-b/routes/` (`22` PNGs verified: `register`, `forgot-password`, `account`, `create-group`, `join-group`, `guest-share`, `group-feed`, `group-balances`, `group-stats`, `group-activity`, `group-members`, `group-fund`, `group-settings`, `quick-entry`, `new-tx`, `edit-tx`, `tx-detail`, `receipt-review`, `settle`, `notifications`, `personal-ledger`, `debug-gallery`).
    - Security review: checked relevant items 1, 2, 8 on `git diff`; server role enforcement unchanged, client gating (`if isOwner`) hides menu entry and `GroupUnavailableView` displays generic `"common.forbidden"` without exposing group internals, no issues found.
  - **Findings closed:** `B10` (`F4-10`), `B09` (`F3-48`, `F3-49`), `F3-47`, `B18` (`F4-36`, `F4-51`), `F4-05` and `F4-06` (clone part).
  - **Coordinator Stage B Gate (`c5565f8`, verified while `ios` idle):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: exit `0` (`Checked 595 files in 160ms. No fixes applied. Found 9 warnings.`; 8 workspace `tsc --noEmit` projects passed; `OpenAPI contract snapshot is up to date.`)
    - `grep -rn "PopGestureEnabler\|StatusBarCover" apps/ios/SongPhangKit/Sources/ apps/ios/SongPhang/ apps/ios/ShareExtension/ apps/ios/WidgetExtension/`: `GREP_EMPTY_OK` (zero matches).
    - Stage B captures (`screens/stage-b/routes/` = `22` route PNGs; `b1-tx-detail.png`, `b1-account.png`, `b3-unavailable-{notfound,forbidden}.png`, `b3-settings-categories.png`, `b3-clone-toast.png` visually inspected).

## Stage C — Apply

### Task 5.6.C.1: Sheets applied
- **Status:** Committed (Stage C)
- **Step 2 (Think):**
  - Files modified: `AccountFeature/Account/TelegramPairingSheetView.swift`, `AppShell/{Debug/DebugPanel,GroupContainerView,Push/PushPermissionSheet}.swift`, `GroupsFeature/{CloneGroup/CloneGroupSheetView,GroupSettings/GroupSettingsView,GuestShare/{GuestBreakdownSheet,GuestGroupView,GuestLinkSheetView,GuestTransactionDetailSheet},Members/HouseholdFormSheetView}.swift`, `LedgerFeature/{Balances/{BalancesView,CloseCycleSheetView,MemberBreakdownSheetView,ShareCardPreviewSheet},ExpenseForm/ExpenseFormView,ReceiptCapture/ReceiptCaptureSheet,TransactionDetail/{ApprovalBlockView,DisputeBlockView}}.swift`, `PaymentsFeature/{Fund/CreateFundSheetView,Pay/{PayModel,PayView},PaymentDetails/{PaymentDetailsModel,PaymentDetailsView}}.swift`, `StatisticsFeature/{Recurring/RecurringFormSheetView,Stats/StatsView}.swift`, `docs/superpowers/runs/phase-5-6/{decisions,progress}.md`.
  - Approach: Inventoried all 32 `.sheet`/`.fullScreenCover` presentations (Decision D12) and applied `.spSheet(.fitted | .half | .form)` across all non-camera/viewer sheets, replaced all sheet `SPScreenHeader` / back chevrons / `"Thôi"` (`members.removeCancel`) / `"Quay lại"` / `"Đóng"` / `"Xong"` dismiss controls with `SheetCloseButton` (view-only) or `SheetCancelButton` (action/editing), converted `PaymentDetailsView`'s bank picker from a nested `.sheet` to `.navigationDestination(isPresented: $isPickingBank)` inside its own `NavigationStack`, and attached `.discardGuard(isDirty:onDiscard:)` on all editing sheets (`ApprovalBlockView`, `DisputeBlockView`, `CloseCycleSheetView`, `CloneGroupSheetView`, `GroupSettingsView.deleteGroupSheet`, `CreateFundSheetView`, `PaymentDetailsView`, `PayView`, `HouseholdFormSheetView`, `RecurringFormSheetView`).
  - Why this is the simplest approach: Reuses Stage A's `SheetPresentation` helpers uniformly with zero extra wrapper types and lets SwiftUI's `NavigationStack` push `PaymentDetailsView`'s bank picker instead of stacking modal sheets.
  - Rejected alternative: Keeping custom `.presentationDetents` per view or leaving nested sheets in `PaymentDetailsView` — rejected per Spec §5.1–§5.3.
  - Questions: none (Decision D12 recorded in `decisions.md`).
- **Gates (verbatim):**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (no output)
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - `grep -rn "SPScreenHeader(\|presentationDetents\|members\.removeCancel" apps/ios/SongPhangKit/Sources`: only `SheetPresentation.swift:155` (`.presentationDetents`), `MembersView.swift:109` (member removal confirmation dialog), and `Localizable.xcstrings:4811` remain.
- **Exercise results:**
  - Verified in Simulator (`iPhone 17 Pro`, light, dark, and `AX5`) across `FilterSheetView`, `PayView`, `GuestLinkSheetView`, `CloneGroupSheetView`, `CloseCycleSheetView`, `deleteGroupSheet`, `MemberBreakdownSheetView`, and `ShareCardPreviewSheet` (`screens/stage-c/sheets/c1-*.png`, 15 PNGs visually inspected). Confirmed `.fitted` height hugs content cleanly at normal and `AX5` sizes, top-left `SheetCloseButton`/`SheetCancelButton` render without back chevrons or `"Thôi"`/`"Xong"`/`"Quay lại"`/`"Đóng"` labels. Interactive dirty typing + swipe-down discard alert tested in code and queued in `manual-checks.md`.
  - Security review: checked `git diff`; `deleteGroupSheet`, `PaymentDetailsView`, `DisputeBlockView`, and `ApprovalBlockView` trim/validate input identically to prior behavior with zero secrets or unchecked data paths.
- **Findings closed:** `F2-29`, `F2-30`, `F2-31`, `F2-32`, `F4-03`, `F4-04` (application), `F2-130`.

### Task 5.6.C.2: Loading and states
- **Status:** Committed (Stage C)
- **Step 2 (Think):**
  - Files modified: `AppShell/{GroupContainerView,RootView,RouteDestination}.swift`, `DesignSystem/{Components/PhotoAttachmentViews.swift,States/StateViews.swift}`, `GroupsFeature/GroupList/GroupListView.swift`, `LedgerFeature/{Balances/BalancesView,GroupFeed/GroupFeedSubViews,GroupFeed/GroupFeedView,ReceiptCapture/ReceiptCaptureSheet,ReceiptReview/ReceiptReviewView,TransactionDetail/CommentThreadView,TransactionDetail/TransactionDetailView}.swift`, `OverviewFeature/Overview/OverviewView.swift`, `apps/ios/ShareExtension/ShareExtensionView.swift`, `docs/superpowers/runs/phase-5-6/progress.md`.
  - Approach: Added `GroupHeaderHint` and a `groupSummaryLookup` closure passed from `RootView` (`groupListModel` / `overviewModel`) -> `RouteDestination` -> `GroupContainerView` so opening a group from Overview or Group List displays its real name and member shapes immediately without changing `Route` or deep links, while cold deep links show a `SkeletonBar` title in `.principal` and omit `memberCapsuleButton` until loaded (never an empty string or empty capsule). Moved `GroupFeedView`'s composer bar (`FeedEntryBarView` with `isPendingLoad: true`) to render disabled from frame 1 during `.loading`. Replaced `LoadingSkeleton` row blocks in `GroupFeedView`, `BalancesView`, `OverviewView`, and `GroupListView` with layout-shaped skeletons (`BalanceCardSkeleton`, `LinkRowSkeleton`, `SearchFieldSkeleton`, `TransactionRowSkeleton`, `MemberRowSkeleton`), updated `LoadingSkeleton` in `StateViews.swift` to use shimmered `SkeletonBar` cards, and replaced whole-area `ProgressView()` spinners across `PhotoAttachmentViews`, `ReceiptCaptureSheet`, `ReceiptReviewView`, `CommentThreadView`, `TransactionDetailView`, and `ShareExtensionView` with `ShapeLoader` (preserving inline button spinners in `SPButton`/`NotificationsView` and determinate bar gauges in `BalancesView`). Added `#if DEBUG` `--route-feed-from-list` flag in `RootView`.
  - Why this is the simplest approach: A read-only lookup closure from `RootView`'s existing loaded models avoids duplicating or caching group headers in `Route` parameters and leaves all deep-link URLs unchanged.
  - Rejected alternative: Passing full group snapshots inside `Route` — rejected because `Route` is `Hashable` and shared with deep-link/universal-link parsers.
  - Questions: none.
- **Gates (verbatim):**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (no output)
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - `grep -rn "ProgressView(" apps/ios/SongPhangKit/Sources apps/ios/ShareExtension`: only `SPButton.swift:49` (inline button), `NotificationsView.swift:90` (inline load-more button), and `BalancesView.swift:{1397,1400,1480,1488}` (determinate bars).
- **Exercise results:**
  - Verified with `--scripted --latency-2s --no-snapshot` on `iPhone 17 Pro`: cold deep-link (`--route-feed`, `c2-feed-deeplink-loading.png`) renders `SkeletonBar` title, zero empty capsule, layout-shaped feed skeleton, and disabled bottom composer; from-list open (`--route-feed-from-list`, `c2-feed-from-list-loading.png` -> `c2-feed-loaded.png`) shows `"Đà Lạt 3N2Đ"` + 3 member shapes immediately during loading and loads with zero composer jump; Balances (`c2-balances-loading.png`), Overview (`c2-overview-loading.png`), Group List (`c2-groups-loading.png`) render layout-shaped skeletons; TransactionDetail (`c2-txdetail-shape-loader.png`) shows centered `ShapeLoader` on full-screen `Tokens.bg`.
  - Verified with snapshot (`--scripted --latency-2s --route-feed`, no `--no-snapshot`, `c2-feed-with-snapshot.png`): stored snapshot content appears immediately before the 2s network refresh finishes (`F4-42`).
  - Security review: checked `git diff`; `groupSummaryLookup` reads only already-authorized in-memory models; `FeedEntryBarView` remains `.disabled(true)` while loading.
- **Findings closed:** `B20` (`F4-43`, `F4-44`, `F4-45`), `F4-42`, `F1-52` (adoption), `F2-57` (no entrance motion).

### Task 5.6.C.3: Feedback wiring and component adoption
- **Status:** Committed (Stage C)
- **Step 2 (Think):**
  - Files modified: `AccountFeature/Account/TelegramPairingSheetView.swift`, `AppShell/{GroupContainerView,RouteDestination}.swift`, `DesignSystem/Components/{ConfirmationToast,CopyButton}.swift`, `GroupsFeature/{CreateGroup/CreateGroupView,GroupSettings/TelegramGroupCardView,GuestShare/{GuestGroupView,GuestLinkSheetView},Members/MembersView}.swift`, `LedgerFeature/{Activity/{ActivityModel,ActivityView},Balances/{BalancesModel,BalancesView},ExpenseForm/{ExpenseFormModel,ExpenseFormSubViews,ExpenseFormView},GroupFeed/GroupFeedView,QuickEntry/{QuickEntryModel,QuickEntryView},ReceiptReview/{ReceiptItemsAssignmentView,ReceiptReviewView},Settle/{SettleModel,SettleView}}.swift`, `PaymentsFeature/Pay/PayView.swift`, `StatisticsFeature/Recurring/RecurringFormSheetView.swift`, `docs/superpowers/runs/phase-5-6/progress.md`.
  - Approach: Wired the three server-confirmed money moments (`coin` + `.success` in `ExpenseFormModel`/`QuickEntryModel`; `ting` + `.success` in `SettleModel`/`SettleView`; `chord` + three `.success` beats spaced 120 ms apart + `ShapeBurst` in `BalancesModel`/`BalancesView` guarded by `markOwnActionPendingCelebration` so opening an already-settled group or receiving another user's realtime update plays nothing). Added `.fieldShake` on invalid saves in `ExpenseFormView` (amount/description), `QuickEntryView` (empty send), and `CreateGroupView` (missing group name). Extended `CopyButton` with optional `onCopyImage:` and `ConfirmationToast` with `bottomPadding:`, replaced all 7 `UIPasteboard` copy sites with `CopyButton` (removing copy toasts), replaced feed/activity custom capsules with `ConfirmationToast`, replaced `MemberToggleGridView` / text chips / receipt payer & item grids with `MemberPicker`, added `matchedGeometryEffect` slide + `.selection` feedback to `TypeSwitchView` and `BalancesView.subTabBar`, and verified `GroupFeedView` uses system `.swipeActions` with zero custom swipe gestures in the codebase. Added `#if DEBUG` `--exercise-save-expense`, `--exercise-settle-submit`, `--exercise-all-settled` hooks.
  - Why this is the simplest approach: Extending `CopyButton` for images and `ConfirmationToast` for custom bottom padding keeps every copy site and toast on one shared component without introducing wrapper types.
  - Rejected alternative: Keeping a separate copy button for `ShareCardPreviewSheet` or leaving `MemberToggleGridView` alongside `MemberPicker` — rejected for component duplication.
  - Questions: none.
- **Gates (verbatim):**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (no output)
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 893 web keys verified, 0 missing, 0 differing.`
  - `grep -rn "UIPasteboard\|MemberToggleGridView" apps/ios/SongPhangKit/Sources`: only `CopyButton.swift:{85,87}`; zero `MemberToggleGridView` remaining. `grep -rn "DragGesture\|swipeActions"`: `GroupFeedView.swift` uses system `.swipeActions`; only `SplitEditorView.swift:238` uses `DragGesture` (slider bar scrub; zero custom swipe actions).
- **Exercise results (Simulator `iPhone 17 Pro` OSLog + screenshots):**
  - Expense double-tap save (`--route-new-tx --exercise-save-expense`): `SoundPlayer played effect=coin started=true` + `spFeedback kind=success enabled=true` logged ONCE (idempotency guard prevented duplicate request/feedback).
  - Settle submit (`--route-settle --exercise-settle-submit`): `SoundPlayer played effect=ting started=true` + `spFeedback kind=success enabled=true`.
  - All-settled celebration (`--route-balances --exercise-all-settled`, `c3-all-settled-burst.png`): `SoundPlayer played effect=chord started=true`, then 3 `spFeedback kind=success enabled=true` beats (`18:36:12.932`, `18:36:13.056` [+124 ms], `18:36:13.181` [+125 ms]), with `ShapeBurst` over the accent card.
  - Realtime update from another user (`--route-balances --exercise-record-payment`): `(no Feedback/Sound events)` confirmed.
  - Component screenshots inspected: `c3-all-settled-burst.png`, `c3-expense-form-pickers.png` (`MemberPicker` + sliding `TypeSwitchView`), `c3-receipt-review-pickers.png` (`MemberPicker` item assignment).
  - Security review: checked `git diff`; `idempotencyKey` preserved on concurrent save taps; `UIPasteboard` writes explicit values only on direct button tap.
- **Findings closed:** `F1-32`, `F1-59` (wiring), `F1-51`, `F2-55`, `F2-54`, `F4-05`, `F4-06`, `F4-01`, `F4-02`, `F2-56`, `F1-49`, `F1-50`.

### Task 5.6.C.4: Typography, VoiceOver labels, copy rules and Stage C gate
- **Status:** Committed (Stage C)
- **Step 2 (Think):**
  - Files modified: `apps/ios/Scripts/check-strings.sh`, `apps/ios/ShareExtension/ShareExtensionView.swift`, `AuthFeature/SignIn/SignInView.swift`, `DesignSystem/{Components/{ControlsAndQR,FundBlockView,LoginShapesAndHeader,NotificationBellButton,PhotoAttachmentViews,ProofBadgeView,TransferProofInputSection},Resources/Localizable.xcstrings,States/StateViews}.swift`, `GroupsFeature/{CreateGroup/CreateGroupView,GroupList/GroupListView,GuestShare/GuestGroupView,Members/{HouseholdFormSheetView,HouseholdsSectionView}}.swift`, `LedgerFeature/{Balances/{BalancesView,SettlementVaultSectionView},ConfirmCard/ConfirmationCardView,ExpenseForm/{ExpenseFormSubViews,ExpenseFormView,ManualExtrasCardView},GroupFeed/{CycleFilterChipView,GroupFeedSubViews,GroupFeedView},QuickEntry/QuickEntryView,ReceiptReview/ReceiptItemsAssignmentView,Settle/SettleView,SplitEditor/SplitEditorView,TransactionDetail/{CommentFieldView,TransactionSummaryView}}.swift`, `OverviewFeature/{Overview/OverviewView,PersonalLedger/PersonalLedgerView}.swift`, `PaymentsFeature/{Fund/FundView,Pay/PayView,PaymentDetails/PaymentDetailsView}.swift`, `StatisticsFeature/Recurring/RecurringSectionView.swift`, `docs/superpowers/runs/phase-5-6/{copy-changes,decisions,progress}.md`, plus `screens/stage-c/{b07-{before,after}-*-ax5.png,matrix/*.png}`.
  - Approach: Replaced all remaining non-avatar `.font(.system(size:` calls across `SongPhangKit` and `ShareExtension` with `Typography.displayNumber`, `Typography.microBold`, `.spIconFont(size:weight:relativeTo:)`, or `Typography.{captionBold,subheadlineBold}` inside nonisolated `PhotosPicker` labels (keeping `Typography.swift:174`'s `@ScaledMetric` helper and `MemberShapeView.swift:68`'s container-proportional initial as recorded in Decision D13). Removed all remaining `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` caps (`ExpenseFormView`, `ExpenseFormSubViews`, `SettleView`, `GroupFeedView`, `QuickEntryView`, `CreateGroupView`, `ControlsAndQR`) and switched dense rows (`BalancesView` hero/settlements/bars/recorded rows, `SettleView` party banner & day selector, `ExpenseFormView` sharers header & split date/time `DatePicker`s, `ExpenseFormSubViews` `AmountFieldView` & `PayerAmountsView` + horizontal `TypeSwitchView` scroll, `PhotoRowView`, `ControlsAndQR` `NewMemberInputRow`, `GroupFeedSubViews` hero/transaction/2-row AX5 `FeedEntryBarView` with `.fixedSize(horizontal: false, vertical: true)`, `OverviewView`, `GroupListView`) to `AdaptiveStack` / `GeometryReader` width bounds (`ExpenseFormView` `contentWidth`). Added missing VoiceOver labels (`PersonalLedgerView` clear button -> `ios.common.clear` `"Xoá"`, marked decorative glyphs hidden). Migrated inline `common.you` switches to `PersonName.display`, adopted `MoneyText(..., role:)`, removed `"đồng"` next to amounts (`groups.owedToYou`, `groups.youOwe`, `split.unitMoney` in `Localizable.xcstrings`), added `"Đà Lạt cuối tuần"` placeholder (`ios.newGroup.namePlaceholder`) to `CreateGroupView`, recorded all 5 copy deltas in `copy-changes.md`, inventoried all 38 strings >60 chars in Decision D13, and updated `apps/ios/Scripts/check-strings.sh` to enforce and report the `copy-changes.md` allowlist.
  - Why this is the simplest approach: Reuses existing `Typography`, `AdaptiveStack`, `PersonName`, and `MoneyText.Role` primitives with zero custom font scaling or parallel layout helpers.
  - Rejected alternative: Keeping `.dynamicTypeSize` caps or suppressing `vi.ts` differences in `check-strings.sh` — rejected per Spec §8, §11.2, and §11.4.
  - Questions: none (Decision D13 recorded in `decisions.md`).
- **Gates (verbatim — Task 5.6.C.4 + Stage C gate):**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
  - `./apps/ios/Scripts/check-strings.sh` (allowlist pass): `ALLOWED (copy-changes): split.unitMoney` / `groups.youOwe` / `groups.owedToYou` -> `OK: 893 web keys verified, 3 allowlisted via copy-changes.md, 0 missing, 0 differing.`
  - `./apps/ios/Scripts/check-strings.sh` (unrecorded change negative test on `groups.settled`, then reverted): exit `1`, `DIFFERING: groups.settled`, `FAILED: 893 web keys checked, 3 allowlisted, 1 failing.`
  - `pnpm check`: exit `0` (`Checked 595 files in 168ms. No fixes applied. Found 9 warnings.`; 8 workspace `tsc --noEmit` projects passed; `OpenAPI contract snapshot is up to date.`)
  - `rg -n '\.font\(\.system\(size:' apps/ios`: only `Typography.swift:174` and `MemberShapeView.swift:68` remain.
  - `rg -n 'dynamicTypeSize\(\.\.\.' apps/ios`: zero matches (`GREP_EMPTY_OK`).
  - `rg -n 'đồng' apps/ios/SongPhangKit apps/ios/ShareExtension`: zero matches (`GREP_EMPTY_OK`).
- **Exercise results & screenshots:**
  - B07 before/after AX5 (`iPhone 17 Pro`): `screens/stage-c/b07-before-{settle,balances,expense-form}-ax5.png` vs `screens/stage-c/b07-after-{settle,balances,expense-form}-ax5.png`. Settle stacks `Thu ↓ Bạn` and scales `"Ghi nhận 210.000 đ"` without truncation; Balances stacks hero label/amount over `"Xem giải trình khoản nợ"`; Expense Form (`GeometryReader` `contentWidth`, vertical-axis description field, split date/time `DatePicker`s) fits inside `20 pt` margins with zero horizontal clipping; `CreateGroupView` renders `"Đà Lạt cuối tuần"` and full-width `"Thêm"` (`matrix/create-group-ax5.png`); `GroupFeedView` renders clean two-row AX5 composer bar (`matrix/feed-ax5.png`).
  - Full Stage C Spec §13.1 matrix (`40` PNGs under `screens/stage-c/matrix/` + `6` B07 PNGs): covers `overview`, `groups`, `feed`, `balances`, `settle`, `expense-form`, `create-group`, `quick-entry`, `receipt-review`, `ledger` in `light`/`dark`, `AX5`, `--scenario-large`, and `iPhone SE (3rd generation)` (`SP-SE3-review`). Note: `matrix/settle-se3.png` was captured behind an OS `"Open in 'Sòng Phẳng'?"` system prompt lingering from Safari on `SP-SE3-review` (underlying SE3 Settle layout remains visible and unclipped).
  - Security review: checked `git diff`; `check-strings.sh` fails closed on any unallowlisted catalog change; all input validation, role gating, and `Money` integer paths unchanged.
- **Findings closed:** `B07` (`F3-27`, `F3-28`), `F4-54`, `F1-38`, `F2-09`, `F2-10` (Stage C foundation).
- **Coordinator Stage C Gate (`4b3dc99`, verified while `ios` idle):**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
  - `./apps/ios/Scripts/check-strings.sh`: `ALLOWED (copy-changes): split.unitMoney`, `groups.youOwe`, `groups.owedToYou` -> `OK: 893 web keys verified, 3 allowlisted via copy-changes.md, 0 missing, 0 differing.`
  - `pnpm check`: exit `0` (`Checked 595 files in 172ms. No fixes applied. Found 9 warnings.`; 8 workspace `tsc --noEmit` projects passed; `OpenAPI contract snapshot is up to date.`)
  - `rg -n '\.font\(\.system\(size:' apps/ios/SongPhangKit/Sources apps/ios/ShareExtension apps/ios/WidgetExtension`: only `Typography.swift:174` (`@ScaledMetric`) and `MemberShapeView.swift:68` (proportional avatar initial, D13).
  - `rg -n 'dynamicTypeSize\(\.\.\.' apps/ios/SongPhangKit/Sources`: `NONE`.
  - Stage C captures (`66` PNGs under `screens/stage-c/`; `c1-pay-light.png`, `c3-all-settled-burst.png`, `b07-after-{settle,balances,expense-form}-ax5.png`, `matrix/feed-ax5.png` visually inspected).

## Stage D — Data, checks and handoff

- [x] **Task 5.6.D.1 — Scripted scenarios for unreachable screens**
  - **Approach:**
    - Files modified: `apps/ios/SongPhangKit/Sources/AppShell/{RootView,SessionModel,Debug/DebugPanel}.swift`, `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeRepositories,FakeWorld,FakeWorld+Ledger,FakeWorld+Payments,FakeWorld+Stats}.swift`, `docs/superpowers/runs/phase-5-6/{decisions,progress}.md`.
    - Approach: Added `SessionModel.loadFeatures()` called at launch in `RootView` (including `.signedIn` scripted runs), wired `--with-payment-details`, `--with-pending-request`, `--with-fund`, `--with-pending-approval` (+ `--route-tx-pending-approval`), `--feature-telegram`, `--guest-token <token>`, `--upgrade-required`, and `--push-prompt` into `FakeWorld.init` and `RootView`, exposed matching launch-flag documentation and interactive seed actions in `DebugPanel`, and aligned `FakeWorld+Stats.swift` literals (`total = 1_599_999`, matching `1_200_000 + 300_000 + 99_999` across `byCategory`, `byBucket`, and `byMember`).
    - Why this is the simplest approach: Hydrating literal scenario data synchronously inside `FakeWorld.init` prevents race conditions with child `.task` loads while keeping `Money` arithmetic strictly out of fakes and apps.
    - Rejected alternative: Mutating `FakeWorld` asynchronously in `RootView.task` — rejected because child views start loading concurrently at launch.
    - Questions: none (Decision D14 recorded in `decisions.md`).
  - **Gates (verbatim):**
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' build`: `** BUILD SUCCEEDED **` (`SongPhangShareExtension.appex` and `SongPhangWidgetExtension.appex` embedded under `SongPhang.app/PlugIns/`)
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output)
    - `./apps/ios/Scripts/check-strings.sh`: `ALLOWED (copy-changes): split.unitMoney`, `groups.youOwe`, `groups.owedToYou` -> `OK: 893 web keys verified, 3 allowlisted via copy-changes.md, 0 missing, 0 differing.`
    - `pnpm check`: exit `0` (`biome check .`, `pnpm -r typecheck`, `pnpm --filter @songphang/api contract:check` -> `OpenAPI contract snapshot is up to date.`)
  - **Exercise results & screenshots (`docs/superpowers/runs/phase-5-6/screens/stage-d/scenarios/`):**
    - `--with-payment-details --route-balances --open-pay-sheet` (`d1-payment-details-pay-sheet.png`): renders `PayView` `.fitted` sheet with `Thu -> Bạn` (`210.000 đ`), VietQR code, `"Lưu mã QR"`, and `"Ngân hàng / Vietcombank / Sao chép"`.
    - `--with-pending-request --route-balances` (`d1-pending-request-balances.png`): renders `"Thu báo đã chuyển 210.000 đ"` pending confirmation card and `"1"` badge on `"Sổ thanh toán"`.
    - `--with-fund --route-fund` (`d1-fund.png`): renders `"Quỹ còn 350.000 đ"`, `"Giữ tiền: Minh"`, and `"Đã góp: Minh 200.000 đ, Lan 150.000 đ"`.
    - `--with-pending-approval --route-tx-pending-approval` (`d1-pending-approval.png`): renders `"Vé máy bay khứ hồi / 850.000 đ / Khoản này chờ duyệt. Chưa tính vào số dư."` with `"Duyệt"` / `"Không duyệt"`.
    - `--feature-telegram --route-account` (`d1-feature-telegram-account.png`) and `--feature-telegram --route-settings` (`d1-feature-telegram-settings.png`): loads `features.telegram == true` via `SessionModel.loadFeatures()`.
    - `--guest-token demo-guest-token` (`d1-guest-token-loaded.png`) & `--guest-token invalid` (`d1-guest-token-invalid.png`): loaded read-only `"Chế độ khách chỉ xem / Đà Lạt 3N2Đ"` vs invalid-token message `"Liên kết xem chung không tồn tại hoặc đã được thu hồi."`.
    - `--upgrade-required` (`d1-upgrade-required.png`): renders `UpgradeRequiredView` (`"Hãy cập nhật Sòng Phẳng để tiếp tục."`).
    - `--push-prompt` (`d1-push-prompt.png`): presents `PushPermissionSheet` (`"Nhận thông báo khi có khoản chi mới"`) over Overview.
    - `--route-stats` (`d1-stats-consistent.png`): renders total `1.599.999 đ` equal to `1.200.000 đ + 300.000 đ + 99.999 đ`.
    - Security review: checked `git diff` against relevant checklist items; `#if DEBUG`-only scenario flags with hardcoded local fake data, zero secrets, zero network calls, zero `Money` division/multiplication, no issues found.
  - **Findings closed:** `F4-32` (`FakeWorld+Stats` consistent literals), plus unblocked scripted Simulator access to all Stage D scenario screens.

## Findings record

## Not verified

- **Task 0 (`xctrace` `SwiftUI` and `Hitches` instruments on iOS Simulator):** `xcrun xctrace record --template 'SwiftUI'` fails on Simulator with `* [Error] Hitches is not supported on this platform.`, and `xcrun xctrace record --instrument 'SwiftUI'` completes with `* [Warning] Trace file had no SwiftUI data` because SwiftUI view-body signposts require a physical iPhone (per AD §8.3 and §11). `Hangs` instrument was recorded instead; physical-iPhone scrolling and SwiftUI profiling will be listed in `manual-checks.md`.
- **Task 5.6.A.2 (physical haptics, hardware Ring/Silent switch, and device music mixing):** Simulator has no Taptic Engine or hardware ringer switch; OSLog confirmed `spFeedback` trigger evaluation and `AVAudioPlayer` playback/suppression, while physical vibration feel, hardware mute switch silence, and live Apple Music/Spotify non-interruption require a physical iPhone (`manual-checks.md`).
- **Task 5.6.C.4 (live VoiceOver spoken traversal in Simulator):** Static audit confirmed zero unlabelled icon-only buttons (`CopyButton` and `NotificationBellButton` carry explicit `.accessibilityLabel`s, `PersonalLedgerView` clear button gained `"Xoá"`, decorative symbols are `.accessibilityHidden(true)`, `MemberShapeView` exposes `name`), while `osascript` AX inspection of the Simulator window failed (`execution error: System Events got an error: Can’t get process "Simulator". (-1728)`). Full spoken VoiceOver traversal on Group Feed, Settle, and Expense Form stays in `manual-checks.md` for physical iPhone verification.

## Gate not passed

## Out of scope
