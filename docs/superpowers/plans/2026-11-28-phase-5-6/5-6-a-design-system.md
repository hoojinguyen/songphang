# Phase 5.6 — Stage A: Design System

> Touch only `apps/ios/**` and the run directory. Paths below are relative to `apps/ios/SongPhangKit/Sources/` unless they start with `apps/` or `docs/`. Stage A adds building blocks; it changes no screen's structure. Adoption happens in Stage C.

### Task 0: Re-baseline and "before" captures

**Files:**
- Modify: `docs/superpowers/runs/phase-5-6/{progress,decisions}.md`
- Create: `docs/superpowers/runs/phase-5-6/screens/before/*.png`

- [ ] **Step 1: Confirm the branch and a clean tree.** `git status` clean on `phase-5-6`; record the starting SHA.
- [ ] **Step 2: Run the iOS gate and `pnpm check`.** Record the exact outputs (`BUILD SUCCEEDED`, empty lint, `check-strings.sh` line, `pnpm check` result).
- [ ] **Step 3: Re-baseline the names the plan uses.** In `decisions.md`, a table "Plan's name → real name and location → status" for: `AppShell/{RootView,RouteDestination,GroupContainerView,PopGestureEnabler,StatusBarCover,Route}.swift`, `DesignSystem/Tokens/{Tokens,Typography}.swift`, `DesignSystem/Components/{Haptics,LoginShapesAndHeader,MoneyText,MoneyFormat,MemberShapeView,ControlsAndQR}.swift`, `DesignSystem/States/StateViews.swift`, `AppShell/Debug/DebugGalleryView.swift`, `PreviewSupport/Fakes/*`, `apps/ios/Scripts/check-strings.sh`. Record the counts the spec relies on: 17 screens hiding the system back button, 32 `.sheet`/`.fullScreenCover`, 17 animation calls, 22 `Haptics.` calls, 54 `.font(.system(size:` calls, 963 catalog keys, 38 strings over 60 characters. If a count differs, record the real number and use it.
- [ ] **Step 4: "Before" captures.** In the iPhone 17 Pro simulator with `--scripted`, capture overview, groups, group feed, balances, transaction detail, members, settings, account, the expense form and quick entry — light, dark, and at the largest accessibility text size — and the same group screens on iPhone SE. Save under `screens/before/`.
- [ ] **Step 5: Baseline profile.** Profile the group feed of `--scripted --scenario-large` with the SwiftUI Instrument in the Simulator for 10 seconds of scrolling; record body-update counts of the feed row in `progress.md`.
- [ ] **Step 6: Commit.** `git commit -m "chore(ios): re-baseline phase 5.6"`

---

### Task 5.6.A.1: Motion tokens and Reduce Motion

Closes: F2-132, F2-57, F2-58, F2-61, F2-62, F1-58, F1-74, F2-63, F4-53, F1-44, F2-59, F2-60, F2-56 (component part).

**Files:**
- Create: `DesignSystem/Tokens/Motion.swift`
- Modify: `DesignSystem/Components/MoneyText.swift`, `DesignSystem/Components/ControlsAndQR.swift` (`SPSegmentedControl`)
- Modify: the files holding the 17 animation calls: `LedgerFeature/QuickEntry/QuickEntryView.swift`, `LedgerFeature/Settle/SettleView.swift`, `LedgerFeature/Balances/SettlementCyclesSectionView.swift`, `LedgerFeature/GroupFeed/GroupFeedView.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift`, `LedgerFeature/ConfirmCard/ShareShapesView.swift`, `AppShell/GroupContainerView.swift`, `GroupsFeature/CreateGroup/CreateGroupView.swift`

**Interfaces:**
- Produces: `Motion.quick`, `Motion.bounce`, `Motion.smooth` (SwiftUI springs; quick ≈ 0.25 s response, bounce with visible overshoot, smooth without), and a Reduce-Motion-aware way to apply them from views and from `withAnimation` call sites (for example `Motion.animation(_:reduceMotion:)` plus a `.spAnimation(_:value:)` modifier that reads `\.accessibilityReduceMotion`). Under Reduce Motion the result is `nil` (instant) or a short opacity animation for content swaps.
- Produces: `MoneyText` style `.hero` that applies `.contentTransition(.numericText(value:))` and animates only when the value changes; other styles never animate.
- Produces: `SPSegmentedControl` whose selection pill slides with `matchedGeometryEffect` and `Motion.quick`; the content below it is not faded.

- [ ] **Step 1: Write `Motion.swift`** with the three springs and the Reduce Motion helper. Comment only why a value was chosen.
- [ ] **Step 2: Move all 17 animation calls to `Motion`.** Replace `.easeInOut(duration:)` and `.linear(duration:)` with the matching token. Where a call fades a whole screen when switching segments (`GroupContainerView`), switch content without the fade.
- [ ] **Step 3: `MoneyText(.hero)` and the segmented control.** Use the hero style for the main balance figures that exist today (overview hero, group balance card, settle header); leave row amounts unchanged.
- [ ] **Step 4: Exercise.** In the Simulator: switch segments (pill slides, no screen fade); record a payment in `--scripted` and watch the balance roll; turn on Reduce Motion (Settings → Accessibility → Motion) and repeat — no slide, no roll. Record observations.
- [ ] **Step 5: Gate and commit.** `git commit -m "feat(ios): add motion tokens with reduce motion handling"`

---

### Task 5.6.A.2: Haptics, sound and the "Âm thanh và rung" setting

Closes: F1-60, F4-55, F2-127, F1-54, F1-55, F1-56, F1-57 (F1-32 is wired in 5.6.C.3).

**Files:**
- Create: `DesignSystem/Components/Feedback.swift` (the `.spFeedback(_:trigger:)` wrapper and the `FeedbackSettings` keys)
- Create: `DesignSystem/Components/SoundPlayer.swift`
- Create: `apps/ios/Scripts/generate-sounds.swift` (or `.sh` calling a Swift script) and `DesignSystem/Resources/Sounds/{coin,ting,chord}.caf`
- Modify: `SongPhangKit/Package.swift` only if the new resource folder must be declared (record it)
- Modify: the 8 files calling `Haptics.`: `DesignSystem/Components/ChannelPillPicker.swift`, `LedgerFeature/Balances/{ShareCardPreviewSheet,SettlementVaultSectionView}.swift`, `LedgerFeature/GroupFeed/GroupFeedView.swift`, `LedgerFeature/SplitEditor/SplitEditorView.swift`, `AppShell/GroupContainerView.swift`, `GroupsFeature/GuestShare/{GuestLinkSheetView,GuestGroupView}.swift`
- Delete: `DesignSystem/Components/Haptics.swift`
- Modify: `AccountFeature/Account/AccountView.swift` (new section), `DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-6/copy-changes.md`

**Interfaces:**
- Produces: `FeedbackKind` with exactly `.selection`, `.success`, `.warning` mapped to `SensoryFeedback`; `.spFeedback(_:trigger:)` that fires only when the per-device "Rung" setting is on.
- Produces: `SoundPlayer.shared.play(.coin | .ting | .chord)` that configures `AVAudioSession` category `.ambient` once, preloads the three files, does nothing when "Âm thanh" is off, and never throws to the caller. Playback is for the user's own actions; the call sites (Task 5.6.C.3) guarantee that.
- Produces: `FeedbackSettings` with two `@AppStorage` booleans ("Âm thanh", "Rung"), both default `true`, stored per device like `AppearanceMode`.
- Produces: an "Âm thanh và rung" section in Account with two toggles. New strings: section title "Âm thanh và rung", toggles "Âm thanh" and "Rung" (record in `copy-changes.md`).

- [ ] **Step 1: Sound script.** Write the generator: synthesise three short tones with an attack/decay envelope — coin (two quick high partials, ~150 ms), ting (single soft bell partial, ~250 ms), chord (three-note major chord with a quick fade, under 400 ms like the others, as spec section 7.2 requires) — at a low peak level; write PCM and convert with `afconvert -f caff -d LEI16`. Commit the script and the three outputs; each file is a few KB. Record the exact command in `decisions.md`.
- [ ] **Step 2: `SoundPlayer` and `FeedbackSettings`.** Confirm in the installed SDK how `.ambient` behaves with the ringer switch and with music, and record the source you read.
- [ ] **Step 3: `.spFeedback` and migration.** Replace all 22 `Haptics.` calls with `.spFeedback` triggered by the state change that caused them; map light/medium impacts on selection to `.selection`, success to `.success`, warning to `.warning`. Remove any haptic that fires on a plain tab or segment switch. Delete `Haptics.swift`.
- [ ] **Step 4: Setting UI.** Add the section to the current `AccountView` with the existing toggle style; no other Account change.
- [ ] **Step 5: Exercise.** In the Simulator: play each sound from the debug gallery (Task 5.6.A.6 adds the buttons; until then a temporary `#Preview` is enough); turn "Âm thanh" off and confirm silence; turn "Rung" off and confirm `.spFeedback` does not fire (log in DEBUG only). Record what the Simulator can and cannot show (haptics and the ringer switch need a device; list them under "Not verified" for the owner).
- [ ] **Step 6: Gate and commit.** `git commit -m "feat(ios): add sensory feedback wrapper, ambient sounds and sound and haptics setting"`

---

### Task 5.6.A.3: Typography foundation

Closes: part of B07, F3-28 (the sweep is 5.6.C.4).

**Files:**
- Modify: `DesignSystem/Tokens/Typography.swift`
- Create: `DesignSystem/Components/AdaptiveStack.swift` (or equivalent name)

**Interfaces:**
- Produces: every `Typography` style scales with Dynamic Type (`relativeTo`), including fallbacks; an icon size helper based on `@ScaledMetric`.
- Produces: navigation bar title fonts set to Be Vietnam Pro through `UINavigationBar.appearance()` inside `registerFontsIfAvailable()`; if iOS 26 bars ignore it, record and keep the system font.
- Produces: `AdaptiveStack` (horizontal by default, vertical at accessibility sizes), generalising what `SPScreenHeader` does with `AnyLayout`.

- [ ] **Step 1: Audit `Typography`.** Every style has a `relativeTo`; fallbacks use text styles, not fixed sizes. Add any missing style needed to replace the 54 fixed sizes (record the mapping table in `decisions.md`; do not replace them yet).
- [ ] **Step 2: Navigation title appearance** (large and inline) with the brand font. Verify in the Simulator once Stage B adds bars; until then verify on one temporary screen and remove it.
- [ ] **Step 3: `AdaptiveStack`.** Add with a `#Preview` at default and largest size.
- [ ] **Step 4: Gate and commit.** `git commit -m "feat(ios): scale every typography style and add adaptive stack"`

---

### Task 5.6.A.4: Sheet system

Closes: F2-29, F2-30, F2-31, F2-32, F4-03, F4-04 (component part; application is 5.6.C.1), F2-130 (reference).

**Files:**
- Create: `DesignSystem/Components/SheetPresentation.swift`

**Interfaces:**
- Produces: `SheetSize` = `.fitted`, `.half`, `.form`; `.spSheet(_:)` applying detents (`.fitted` measures content with `onGeometryChange` and uses `.presentationDetents([.height(h)])` capped at `.large`; `.half` = `[.medium, .large]`; `.form` = `[.large]`), the drag indicator, and no custom background so iOS 26 glass applies.
- Produces: `.discardGuard(isDirty:onDiscard:)` — when dirty, `interactiveDismissDisabled(true)` and a confirmation "Bỏ thay đổi?" with "Bỏ" (destructive) and "Huỷ" before calling `onDiscard`. Record the exact wording in `copy-changes.md`.
- Produces: `SheetCloseButton` (X, VoiceOver "Đóng", placed top left) and `SheetCancelButton` ("Huỷ", top left). These are the only dismiss controls for sheets.

- [ ] **Step 1: Read the SDK.** Confirm how `presentationDetents`, `.height`, and the iOS 26 sheet background behave, and whether measuring content can oscillate (content height depends on detent). Pick the measuring approach that cannot loop (for example measure the intrinsic content inside a `fixedSize` container) and record it with the source.
- [ ] **Step 2: Implement** the modifier, the guard and the two buttons, each with `#Preview`s (short content, long content, largest Dynamic Type).
- [ ] **Step 3: Exercise** on the filter sheet (already `.medium/.large`) by switching it to `.spSheet(.half)` and confirming it looks the same; leave it there. Open a `.fitted` test sheet with short and long content at default and largest text size: no jitter, no clipping. Remove any test-only code.
- [ ] **Step 4: Gate and commit.** `git commit -m "feat(ios): add content-sized sheets, discard guard and sheet dismiss controls"`

---

### Task 5.6.A.5: Selection and state components

Closes: F4-01, F4-02 (component part), F2-125, F2-44 (component part), F2-123 (component part), F2-122, F2-43, F1-01.

**Files:**
- Create: `DesignSystem/Components/MemberPicker.swift`, `DesignSystem/Components/ChipRow.swift`, `DesignSystem/Components/CountBadge.swift`
- Modify: `DesignSystem/Components/MemberShapeView.swift`, `DesignSystem/States/StateViews.swift` (`EmptyState`)

**Interfaces:**
- Produces: `MemberPicker(title:members:selection:mode:)` — `mode` single or multiple; each option is a `MemberShapeView` with the initial and the name ("Bạn" for the current member through the helper of 5.6.A.6); selection uses `.spFeedback(.selection)` and `Motion.quick`; vertical list at accessibility sizes; VoiceOver reads "{name}, đã chọn".
- Produces: `ChipRow` — horizontal scroll that sizes chips so the last visible chip is half shown, never truncates labels, wraps instead when it has four chips or fewer.
- Produces: `CountBadge(count:)` — renders nothing for 0.
- Produces: `EmptyState` that requires either an action (button) or an explicit `noActionReason` parameter; update its 2 existing call sites to compile, keeping their current text.
- Produces: `MemberShapeView` always draws the initial; unclaimed members use the dashed outline (`Tokens.dashed`).

- [ ] **Step 1: Implement** the components with `#Preview`s (default, many members, largest text size, dark).
- [ ] **Step 2: Fix `MemberShapeView`** so no call site can render a plain dot; check every call site still compiles and looks right.
- [ ] **Step 3: Gate and commit.** `git commit -m "feat(ios): add member picker, chip row, count badge and stricter empty state"`

---

### Task 5.6.A.6: Feedback and money components, gallery, Stage A gate

Closes: F2-54 (component), F4-06 (component), F1-52 (component), F1-59 (component), F1-51 and F2-55 (modifier), F2-119, F2-120 (component part).

**Files:**
- Create: `DesignSystem/Components/CopyButton.swift`, `DesignSystem/Components/ConfirmationToast.swift`, `DesignSystem/Components/ShapeLoader.swift`, `DesignSystem/Components/ShapeBurst.swift`, `DesignSystem/Components/FieldShake.swift`, `DesignSystem/Components/PersonName.swift`, `DesignSystem/States/SkeletonBlocks.swift`
- Modify: `DesignSystem/Components/MoneyText.swift`, `DesignSystem/Components/MoneyFormat.swift`
- Modify: `AppShell/Debug/DebugGalleryView.swift`

**Interfaces:**
- Produces: `CopyButton(value:label:)` — copies, swaps the icon to a checkmark for 1 s with `symbolEffect`, `.spFeedback(.selection)`, posts a VoiceOver announcement "Đã sao chép".
- Produces: `ConfirmationToast` presented by a `.confirmationToast(_ message: Binding<ToastMessage?>)` modifier — bottom, above the tab bar, about 3 s, VoiceOver announcement, optional action label and closure.
- Produces: `ShapeLoader` (four brand shapes bouncing in turn, `Motion.bounce`; under Reduce Motion a static row with pulsing opacity) and `ShapeBurst(members:)` (one-time burst lasting at most about 1 s; under Reduce Motion a still arrangement).
- Produces: `.fieldShake(trigger:)` — two horizontal shakes plus `.spFeedback(.warning)`; under Reduce Motion only the haptic and a red outline.
- Produces: skeleton blocks (balance card, link row, search field, transaction row, member row) with a slow shimmer that stops under Reduce Motion.
- Produces: `MoneyText` roles `.hero`, `.primary` (with "đ"), `.secondary` (no "đ") through the single formatter in `MoneyFormat`; no API writes "đồng".
- Produces: `PersonName.display(name:isCurrentUser:)` returning "Bạn" for the current user, used by views (models format nothing).

- [ ] **Step 1: Implement** the components and modifiers with `#Preview`s per state.
- [ ] **Step 2: Gallery.** Add a page to `DebugGalleryView` (`--gallery-components`) showing every Stage A component: motion samples, the three sound buttons, haptic buttons, sheet sizes, member picker, chip row, count badge, empty state, copy button, toast, loader, burst, field shake, skeletons, money roles.
- [ ] **Step 3: Stage A gate.** iOS gate; `pnpm check`; capture the gallery in light, dark, and the largest accessibility size into `screens/stage-a/`; record in `progress.md`.
- [ ] **Step 4: Commit.** `git commit -m "feat(ios): add copy button, toast, shape loader and burst, skeletons and money roles"`
