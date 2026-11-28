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

- [x] **Task 5.6.A.4 — Sheet system**
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

## Stage B — Navigation

## Stage C — Apply

## Stage D — Data, checks and handoff

## Findings record

## Not verified

- **Task 0 (`xctrace` `SwiftUI` and `Hitches` instruments on iOS Simulator):** `xcrun xctrace record --template 'SwiftUI'` fails on Simulator with `* [Error] Hitches is not supported on this platform.`, and `xcrun xctrace record --instrument 'SwiftUI'` completes with `* [Warning] Trace file had no SwiftUI data` because SwiftUI view-body signposts require a physical iPhone (per AD §8.3 and §11). `Hangs` instrument was recorded instead; physical-iPhone scrolling and SwiftUI profiling will be listed in `manual-checks.md`.
- **Task 5.6.A.2 (physical haptics, hardware Ring/Silent switch, and device music mixing):** Simulator has no Taptic Engine or hardware ringer switch; OSLog confirmed `spFeedback` trigger evaluation and `AVAudioPlayer` playback/suppression, while physical vibration feel, hardware mute switch silence, and live Apple Music/Spotify non-interruption require a physical iPhone (`manual-checks.md`).

## Gate not passed

## Out of scope
