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

- [x] **Task 5.6.A.1 — Motion tokens and Reduce Motion**
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

## Stage B — Navigation

## Stage C — Apply

## Stage D — Data, checks and handoff

## Findings record

## Not verified

- **Task 0 (`xctrace` `SwiftUI` and `Hitches` instruments on iOS Simulator):** `xcrun xctrace record --template 'SwiftUI'` fails on Simulator with `* [Error] Hitches is not supported on this platform.`, and `xcrun xctrace record --instrument 'SwiftUI'` completes with `* [Warning] Trace file had no SwiftUI data` because SwiftUI view-body signposts require a physical iPhone (per AD §8.3 and §11). `Hangs` instrument was recorded instead; physical-iPhone scrolling and SwiftUI profiling will be listed in `manual-checks.md`.

## Gate not passed

## Out of scope
