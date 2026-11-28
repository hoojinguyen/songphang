# Phase 5.6 — iOS Foundations — Design

Date: 2026-11-28. Status: approved by the project owner on 2026-11-28. Read `docs/superpowers/specs/2026-11-28-ui-ux-v3-roadmap-overview-design.md` and `docs/superpowers/research/2026-11-28-ui-ux-v3-review/README.md` first.

## 1. Intent

Phase 5.6 builds the shared ground every later v3 screen stands on, and fixes the defects that come from that ground. It changes how the app navigates, presents sheets, moves, sounds, vibrates, scales text, loads and words things. It does **not** redesign screens: the 3-tab shell, the single group screen, the form sheet, the three-layer Settle flow and the secondary screens belong to 5.7 and 5.8.

Why first (D13): every 5.7 and 5.8 screen uses these pieces. Building them once, before the structural change, means no screen is animated or re-chromed twice.

**In scope**

- Native iOS navigation on every pushed screen; removal of the custom header and its two patches.
- One sheet system: content-sized heights, two dismiss words, no back arrow in sheets, an unsaved-changes guard.
- One motion system (tokens, Reduce Motion handling), one feedback system (haptics through `.sensoryFeedback`, three short sounds), and a "Âm thanh và rung" setting.
- Dynamic Type everywhere, to the largest accessibility size.
- Loading, empty, error, not-found and no-permission states that match the real layout.
- Shared components later phases need: member picker, chip row, copy button, confirmation toast, shape loader, shape burst, money text styles.
- Copy rules, the string policy for iOS-first changes, and an inventory of over-long strings.
- Fake data and launch flags so every screen of the review can be opened in the Simulator.
- Seven defects: B01, B07, B09, B10, B18, B19, B20.

**Out of scope** (owned by later phases; see section 16)

- Merging Overview and Groups, dropping the group segments, the "who pays whom" sheet, the group info page (5.7).
- The expense form as a large sheet, duplication, instant "Đã nhận" with undo, the three-layer Settle flow, debt simplification by default (5.7).
- Redesigning any secondary screen: clone, receipt, recurring, close cycle, fund, settings content, account content (5.8).
- Any API, database or Web change. Phase 5.6 writes only under `apps/ios/` and its run directory.

## 2. Owner decisions this phase relies on

From the roadmap overview, section 3: D2 (native navigation), D9 (iOS first, Web in 5.9), D12 (sound on by default at low volume), D13 (foundations before structure). This spec adds no new product decision; choices it makes are listed in section 14 as ADRs.

## 3. Stages and gates

Phase 5.6 is a phase run (`AGENTS.md` §12) on branch `phase-5-6`, in four stages. Each stage ends with its gate; a failing gate is fixed before the next stage.

| Stage | Content | Gate (in addition to the iOS gate below) |
|---|---|---|
| **A. Design system** | Motion tokens, feedback and sound, typography fixes, sheet modifiers, shared components (sections 6–10), the debug gallery pages that show them | Every new component visible in `--gallery-components`, light and dark, default and largest Dynamic Type |
| **B. Navigation** | Native bars on every pushed screen, tab bar rule, in-tab navigation, landing rules, not-found and no-permission screens, categories entry (section 4) | Every route in `Route.swift` opened in the Simulator; swipe-back works on each; `PopGestureEnabler` and `StatusBarCover` deleted |
| **C. Apply** | Sheet sizes and dismiss words on all 32 presentations, feedback wired to existing money moments, layout-shaped loading, Dynamic Type sweep, VoiceOver labels, copy rules (sections 5, 7, 8, 9, 11) | Screenshot set of section 13.1 recorded; no clipped text at the largest size |
| **D. Data and checks** | Fake scenarios and flags (section 12), Reduce Motion, VoiceOver, iPhone SE and dark-mode passes, profiling, findings coverage update (section 13) | Every screen of the roadmap's "not yet verified" list opened and captured; `findings.md` statuses updated for this phase |

**iOS gate (every commit):** the two commands of `apps/ios/AGENTS.md` §2 (`xcodebuild … SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `BUILD SUCCEEDED`; `xcrun swift-format lint --strict --recursive apps/ios` → no output). `pnpm check` runs unchanged at each stage gate because no TypeScript is touched.

## 4. Navigation (D2)

### 4.1 Native bars on every pushed screen

Today 17 screens hide the system back button and draw `SPScreenHeader` (a square back button, title and subtitle) inside their scroll content. `RouteDestination` then adds `StatusBarCover` (an opaque strip under the clock) and `PopGestureEnabler` (re-enables swipe-back). Transaction detail forgot to hide the system button and shows both (B01).

Target:

- Every pushed screen uses the system navigation bar: `.navigationTitle`, `.navigationBarTitleDisplayMode(.inline)` for detail screens and `.large` only where a screen is a destination of its own (Account, Notifications), and `ToolbarItem`s for trailing actions (Edit, the group overflow menu, share).
- `SPScreenHeader` is no longer used on pushed screens. It stays only where there is no navigation stack (sign-in hero). Its subtitle text, where useful, moves into the screen content's first line.
- `PopGestureEnabler.swift` and `StatusBarCover.swift` are deleted. iOS 26's scroll edge effect under a real bar keeps the clock readable; swipe-back is the system's.
- Navigation titles use Be Vietnam Pro through `UINavigationBar.appearance()` set once in `Typography.registerFontsIfAvailable()`, so the brand survives on Liquid Glass bars. If the installed SDK ignores the appearance on iOS 26 bars, the system font is accepted and recorded.
- Tab roots also live under a navigation bar (an empty inline title is allowed) so their content never scrolls under the clock (B19). Overview and Groups keep their current greeting header until 5.7 replaces them.

### 4.2 Tab bar

`RouteDestination` hides the tab bar on every pushed screen. Target: the tab bar stays visible on content screens (detail, members, history, settings, stats, fund, ledger). It is hidden only on focused-task screens that 5.7 turns into sheets anyway (quick entry, new and edit expense, settle, receipt review). Check on device that showing the bar does not cause a visible jump; if it does, record it and keep it hidden for that screen.

### 4.3 Navigate inside the current tab

Opening a group from Overview today switches to the Groups tab and replaces its stack; opening a transaction from Notifications switches tabs too, so Back lands somewhere the user never was. Target: `navigate(to:)` and every `onOpen…` callback append to the stack of the tab the user is in. The only tab switches left are the explicit ones (tapping a tab, "Xem tất cả thông báo" style links that name another tab). Deep links and push targets keep their current behaviour (they open in the Groups stack), because they start outside any tab.

### 4.4 Where a flow lands

Rule for every flow that ends (findings F4-05, F4-06): the user lands where they need to look next, and a short confirmation says what happened. In 5.6:

- **Clone group (B10):** after creation, the new group **replaces** the source group in the stack (Back returns to the list), its header sits below the bar, and a confirmation toast says "Đã tạo {name}". The broken header comes from the custom header and the stack push; native bars plus replace-in-stack remove both causes.
- **Confirmation toast:** one component (section 10.4) replaces the ad-hoc toasts (Activity, Members, others found by `toastMessage`). Close cycle adopts it in 5.8.

### 4.5 Not-found and no-permission screens (B09, B18)

- A group that cannot be loaded (404) shows a dedicated full-screen state with the native back button, the message that exists today and the "Về danh sách nhóm" button (keep, F3-47). It never draws the group header, the empty member capsule or the segments (B09).
- A screen the user may not open (403 mapped to `forbidden`) shows the same kind of state with the native back button (B18). These are built once as `GroupUnavailableView(kind:)` in the group container and reused by settings.

### 4.6 "Danh mục của nhóm" entry (B18)

The overflow menu shows "Danh mục của nhóm" only to roles that can manage categories, and it opens settings scrolled to the categories section (a `ScrollViewReader` anchor), not the top. Other roles do not see the item. The settings redesign itself is 5.8.

## 5. Sheets

### 5.1 Rules (F2-29 to F2-32, F4-03, F4-04, F2-130)

- **One sheet, one job.** A sheet is for something finished in seconds. A multi-step job is a full sheet or full screen. Never a sheet on top of a sheet.
- **Height follows content.** Small sheets size to their content; the filter sheet (drag indicator, about half height, Liquid Glass, background visible) is the reference. Only forms use the large detent; only the receipt camera is full screen.
- **Two dismiss words.** A view-only sheet closes with an X at the top left (VoiceOver label "Đóng"). A sheet that changes something has "Huỷ" at the top left and its main action at the bottom. "Thôi", "Đóng" as visible text and "Quay lại" are not used in sheets. The push-permission pre-prompt keeps "Để sau", because postponing is its action.
- **No back arrow in a sheet.** A left chevron means "pushed"; inside a sheet it is replaced by the X or "Huỷ". Steps inside a sheet push inside the sheet's own stack.
- **Unsaved changes.** A sheet with entered data blocks swipe-down (`interactiveDismissDisabled`) and asks before discarding.

### 5.2 Modifiers

In `DesignSystem`:

- `.spSheet(_ size: SheetSize)` with `SheetSize` = `.fitted` (measures the content with `onGeometryChange` and sets `.presentationDetents([.height(h)])`, capped at `.large`), `.half` (`.medium` plus `.large`), `.form` (`.large`), and full screen through `fullScreenCover` only for the camera. It also sets the drag indicator and leaves the background to the system so iOS 26 can apply its glass to fitted sheets.
- `.discardGuard(isDirty:onDiscard:)` for the unsaved-changes rule.
- `SheetCloseButton` (X) and `SheetCancelButton` ("Huỷ") as the only two dismiss controls.

The implementation agent must confirm in the installed SDK how detent height and glass background behave on iOS 26 before choosing the measuring approach (`AGENTS.md` §8), and record it.

### 5.3 Applying to the existing 32 presentations

Stage C classifies every `.sheet` and `.fullScreenCover` in the app (32 today) into `.fitted`, `.half`, `.form` or camera, applies the modifier and the dismiss rules, and records the inventory in the run's `decisions.md`. Known targets from the review: pay and "Đã nhận" sheet `.fitted` (expandable), guest link `.fitted`, debt explanation `.half`, share card full (preview first is 5.8), close cycle `.fitted`, create fund `.half` (keep), delete group `.fitted`, payment details `.half` with X instead of the arrow, recurring and household forms `.form`, clone group `.fitted`, receipt capture opens the camera directly (5.8 finishes the flow), filter sheet unchanged. Content inside these sheets is not redesigned here.

## 6. Motion

### 6.1 Principles (F2-132, F2-57 to F2-63, F1-58, F1-59, F1-74)

- Motion answers "what just changed?". Each screen has at most one main motion. Screen transitions are the system's.
- Animate position, scale and opacity only. Never animate the layout of a long list; to remove a row, fade it first, then collapse.
- Button response 100–150 ms, state change 200–300 ms, the celebration at most about 1 s. SwiftUI springs, not hand-made curves.
- No entrance animation when a screen or its data loads, no scroll-driven effects, no parallax.
- Only the main number of a screen rolls (`numericText`), and only when its value changes; numbers on rows change without motion.
- Exactly one large celebration in the app: when the whole group is settled. Everything else stays small and quick.
- No animation library; SwiftUI on iOS 26 has what is needed.

### 6.2 Tokens and Reduce Motion (F4-53, F2-63)

`DesignSystem/Tokens/Motion.swift` defines three springs: `quick` (select, switch), `bounce` (success), `smooth` (sheets and expanding content). A helper (`Motion.animate(_:reduceMotion:)` or an equivalent view modifier reading `accessibilityReduceMotion`) returns the spring normally and an instant change (or an opacity fade for content swaps) when Reduce Motion is on. With Reduce Motion: no bursts, no scaling, no sliding; colour changes and haptics stay.

All 17 existing `withAnimation` and `.animation` calls move to these tokens, so every motion in the app honours Reduce Motion (today only 4 files read it).

### 6.3 Motion moments built in 5.6

| Moment | Motion | Finding |
|---|---|---|
| Main money figure changes | `MoneyText(.hero)` rolls with `.contentTransition(.numericText(value:))` | F1-44, F2-59, F2-60 |
| Segmented control or chip selection | The selection pill slides (`matchedGeometryEffect`); content switches without fading the screen | F2-56, F1-49 |
| Invalid input on save | The field shakes twice horizontally; warning haptic | F1-51, F2-55 |
| Copy button | The icon turns into a checkmark for 1 s (`symbolEffect`); no toast | F2-54 |
| Loading | Four member shapes bounce in turn instead of a spinner; skeletons have a slow shimmer | F1-52 |
| Group settled | Member shapes burst once (Canvas or `PhaseAnimator`); sound and haptic per section 7 | F1-59 |
| Swipe actions | System `.swipeActions` (the system provides the threshold feedback) | F1-50 |
| Tab selection | System tab bar behaviour on iOS 26; no custom bounce unless the system has none | F1-49 |

Later phases add the screen-specific moments (expense saved, "Đã nhận", zoom from card to detail) with these tokens.

## 7. Feedback: haptics and sound

### 7.1 Haptics (F1-60, F4-55, F2-127)

- `Haptics.swift` (four imperative generators, 22 call sites) is replaced by `.sensoryFeedback` tied to state changes, through one wrapper modifier `.spFeedback(_:trigger:)` that respects the user's setting.
- Meaning is fixed: `.selection` when choosing (chips, people, segments), `.success` when money changes hands (expense saved, payment recorded, cycle closed, group settled), `.warning` on an error. Nothing on tab switches or navigation.

### 7.2 Sound (F1-54 to F1-57, D12)

- Three sounds in 5.6, at most four ever: **coin** (expense saved), **ting** (a payment recorded), **chord** (group settled). Each under 400 ms, low volume, a `.caf` file of a few KB in `DesignSystem/Resources/Sounds/`.
- The sounds are generated in the repository by a small script under `apps/ios/Scripts/` (synthesised tones with an envelope, converted with `afconvert`), so there is no licensing question and no download. The owner approves them by ear (manual check 15.6).
- Played through an `AVAudioSession` with category `.ambient`: silent with the ringer switch, never interrupts music.
- Only for the user's own action, never for realtime changes made by others.
- `SoundPlayer` lives in `DesignSystem`, preloads the three files, and is a no-op when the setting is off.

### 7.3 Wiring to existing moments (F1-32)

The three money moments already exist and get their feedback now, so 5.7 only restyles them: saving an expense (form and quick entry) → coin + success; recording a payment in Settle → ting + success; the all-settled state appearing after the user's own action → chord + three-beat haptic + the shape burst.

### 7.4 "Âm thanh và rung" setting (F1-56)

A section in the current Account screen with two toggles, "Âm thanh" and "Rung", both on by default, stored per device (`@AppStorage`, like the appearance mode). The Account redesign in 5.8 moves this section into its settings list unchanged.

## 8. Typography and Dynamic Type (B07, F3-27, F3-28)

- Every text style comes from `Typography`, whose fonts scale with Dynamic Type (`relativeTo`). The 54 hard-coded `.font(.system(size:))` calls are replaced by `Typography` styles, or by `@ScaledMetric` sizes for icons.
- Rows laid out horizontally switch to vertical at accessibility sizes (`ViewThatFits` or `AnyLayout`), as `SPScreenHeader` already does.
- The largest accessibility size is a required check for every screen in v3 (section 13.1). At that size no text is clipped and no control overlaps another.
- Settle (which breaks) and the expense form (which barely scales) are fixed in 5.6 as the defect's evidence screens; other screens are swept in stage C.

## 9. Loading, empty and error states

### 9.1 Loading that matches the layout (B20, F4-42 to F4-45)

- Keep showing the stored snapshot at once when there is one (F4-42).
- Opening a group shows its name and member shapes immediately, taken from the group list or overview already in memory (no change to `Route` or deep links). The composer is present from the first frame, disabled until data arrives, so nothing jumps.
- Skeletons follow the real layout of the screen (balance card, link row, search, rows), built from shared skeleton blocks, not three identical cards.
- The shape loader (section 6.3) replaces spinners.

### 9.2 Empty states (F2-123, F2-44)

- `EmptyState` requires a next action (a button or a hint that names the first thing to do). A screen with truly nothing to do passes an explicit reason.
- Counts of zero, filters with very few rows, and tabs without data are hidden (`CountBadge` hides 0). Screens adopt this as they are redesigned in 5.7 and 5.8.

### 9.3 Errors

Error text and `LoadError` stay; the invalid-field shake and warning haptic (section 6.3) mark where the error is.

## 10. Shared components

All in `DesignSystem`, all shown in the debug gallery, each with a `#Preview` per state.

### 10.1 Member picker (F4-01, F4-02)

One `MemberPicker` for every "choose people" task, with a title that says what the choice is for ("Ai trả?", "Chia cho ai?", "Món này của ai?"), member shapes with initials, single or multiple selection, selection haptic, and a vertical layout at accessibility sizes. Stage C replaces the picker cards in the expense form, the text chips in the recurring form and the person rows of the receipt review with it. The screens around them are redesigned later; only the picker changes now.

### 10.2 Chip row (F2-125)

A horizontally scrolling `ChipRow` that always leaves half of the last visible chip showing, so it reads as scrollable, and never truncates a chip label. Wraps instead of scrolling when there are four chips or fewer.

### 10.3 Copy button (F2-54)

`CopyButton(value:)`: copies, swaps its icon to a checkmark for 1 s, selection haptic, VoiceOver announcement "Đã sao chép". Replaces the existing copy buttons and their toasts.

### 10.4 Confirmation toast (F4-06)

One `ConfirmationToast` at the bottom, above the tab bar, auto-dismissing after about 3 s, announced to VoiceOver, with an optional action (5.7 uses it for "Hoàn tác"). Replaces the existing ad-hoc toasts.

### 10.5 Shape loader and shape burst (F1-52, F1-59)

`ShapeLoader` (the four brand shapes bouncing in turn) and `ShapeBurst` (one-time burst of member shapes). Both honour Reduce Motion: the loader becomes a static row of shapes with a pulsing opacity, the burst becomes a still arrangement.

### 10.6 Money text and names (F2-119, F2-120, F2-121, F2-122, F1-01)

- `MoneyText` gets explicit roles: `.hero` (rolls, with "đ"), `.primary` (with "đ"), `.secondary` (same row as a primary amount, without "đ"). One formatter remains (`apps/ios/AGENTS.md` §5). "đồng" is never written next to an amount.
- A display helper names people from the viewer's side: the current member is always "Bạn". Every "{name} trả" style label goes through it.
- `MemberShapeView` always draws the member's initial; a plain dot without a letter is not used anywhere. Unclaimed shapes use the dashed outline (F2-43).

## 11. Copy rules and string policy

### 11.1 Rules for all v3 copy (F1-30, F1-04, F1-75, F2-131, F1-28, F1-29, F2-45)

- Friend's voice, not accounting terms. Keep the existing good lines ("3 lượt chuyển là xong", "Mình chưa hiểu hết câu này").
- Labels at most 3 words; hints at most one line; any explanation over 60 characters moves behind a "Vì sao?" control or a help page.
- Say it once, at the highest place: shared information becomes a section header (date, group, person) instead of repeating on every row (F2-42); a repeated state is drawn (dashed outline, dimmed, dot) and explained once (F2-43); one question gets one answer, and the calculation opens on tap.
- One primary button per screen; answer first, calculation on tap.
- Destructive actions live in menus, in red, with a confirmation (F2-124).
- Placeholders are concrete examples in the app's voice (F2-128): the new-group name field gets "Đà Lạt cuối tuần".

### 11.2 Applied in 5.6

Only the copy that belongs to the foundations: dismiss words (5.1), money formatting (10.6), viewer-side names (10.6), the new-group placeholder, the "Âm thanh và rung" section, toast texts, not-found and no-permission texts. Screen copy changes belong to the phase that redesigns the screen.

### 11.3 Long-string inventory

The string catalog has 963 strings; 38 are over 60 characters. Stage C lists all 38 in the run's `decisions.md` with the screen and the phase that will shorten them (5.7 or 5.8). Nothing is shortened in 5.6 unless it belongs to a section 11.2 item.

### 11.4 iOS-first string policy (amends `apps/ios/AGENTS.md` §8)

`apps/ios/AGENTS.md` §8 requires every iOS string to match `apps/web/src/messages/vi.ts` character for character. In v3 iOS leads and Web follows in 5.9, so for Phases 5.6–5.8:

- iOS may add or change a string without the web file.
- Every added, changed or removed string is recorded in the run's `copy-changes.md` (key, old value, new value, reason).
- Phase 5.9 applies all `copy-changes.md` files to `vi.ts` and the rule returns to "identical".

The advisor updates `apps/ios/AGENTS.md` §8 with this exception when this spec is approved.

## 12. Fake data and launch flags (F4-32, roadmap section 6)

The review could not open seven iOS screens because the scripted data never reaches them. Phase 5.6 adds scripted scenarios, each reachable with a launch flag and each built from literals in the style of the existing fakes (`apps/ios/AGENTS.md` §5: fakes return literals transcribed from captured API responses):

| Flag (proposed name) | Shows |
|---|---|
| `--with-payment-details` | The current user and the payee have bank details, so the VietQR pay sheet opens |
| `--with-pending-request` | A settlement request waiting for the current user's confirmation |
| `--with-fund` | A shared fund with contributions and a balance |
| `--with-pending-approval` | A large expense waiting for approval |
| `--feature-telegram` | Server features with Telegram enabled, so the overflow entry and pairing sheet appear |
| `--guest-token` (fix) | The guest page with content for the scripted token, not only the broken-link state |
| `--upgrade-required` | The upgrade-required screen |
| `--push-prompt` | The push-permission pre-prompt |

Server features in scripted mode load at launch, not only on foreground, so feature-gated entries (receipt camera, Telegram) appear without the HOME-and-relaunch workaround. The stats fake is made consistent: its total equals the sum of its categories (F4-32). Widget and share-extension screens are captured from the Simulator's home screen and share sheet; if that is not possible in the Simulator, they stay under "Not verified".

## 13. Checks

### 13.1 Screenshot set (stage C and D)

For every screen touched in 5.6 and for every route in `Route.swift`: light, dark, largest accessibility text size, iPhone SE (3rd generation), and the large-group scenario (`--scenario-large`). Sheets and share cards are included in the dark set (F3-61; keep F3-59). Screenshots go to the run directory.

### 13.2 Reduce Motion and VoiceOver (F4-53, F4-54)

- With Reduce Motion on, walk every motion of section 6.3: none slides, scales or bursts.
- Every icon-only button has a VoiceOver label (about ten lack one today); every member shape reads the member's name. Run VoiceOver in the Simulator on the group, Settle and form screens and record what it reads.

### 13.3 Small screens (F4-07, F4-08)

iPhone SE is part of the gate from now on. Phase 5.6 does not move answers to the top (that is 5.7's structure), but no 5.6 change may push an answer further down, and the SE screenshots record the starting point.

### 13.4 Performance (F2-64)

Profile the group screen of `--scenario-large` with the SwiftUI Instrument in the Simulator before and after stage C, and record the body-update counts of the feed. The owner repeats the check on a physical iPhone (manual check 15.9). `drawingGroup` is used only where profiling shows a gain.

### 13.5 Findings

At stage D the agent records, per finding ID of section 16, what was done and where; the advisor updates `findings.md` at review.

## 14. ADRs and standing documents

- **ADR-042 — Native navigation bars on iOS.** Supersedes the custom header decision of 5.5A for pushed screens; removes `PopGestureEnabler` and `StatusBarCover`.
- **ADR-043 — Motion, feedback and sound system.** Motion tokens with Reduce Motion fallback; `.sensoryFeedback` through one wrapper; three generated `.caf` sounds on an `.ambient` session; per-device setting.
- **ADR-044 — iOS-first strings during v3.** The `copy-changes.md` exception of section 11.4 until Phase 5.9.
- `docs/06-ux-ui/user-flows.md` gains the navigation, sheet, motion, feedback and copy rules of sections 4–11 as the v3 interaction rules. `apps/ios/AGENTS.md` §8 gets the exception of section 11.4. No API, database or SRS change.

## 15. Manual checks for the owner

On a physical iPhone, after the branch is reviewed:

1. **Back everywhere.** Open a group, then expense detail, members, history, settings, stats. Each has one back button in the system bar and swipe-back from the left edge works. Expense detail shows one back button (B01).
2. **Clock is readable.** Scroll Account, a group and expense detail: no text passes under the clock or island (B19).
3. **Tab bar.** On detail, members, history and settings the tab bar stays; on quick entry, the expense form and Settle it is hidden; no visible jump when going back.
4. **Stay in your tab.** From Overview open a group, then Back: you are on Overview. From Notifications open an expense, then Back: you are in Notifications.
5. **Clone.** Clone a group: the new group opens with its header below the bar, a toast says it was created, Back goes to the group list (B10).
6. **Unavailable group.** Open a removed or unknown group link: a clean screen with a back button and "Về danh sách nhóm", no empty group header (B09). As an editor, the overflow menu has no "Danh mục của nhóm"; as owner it opens settings at the categories (B18).
7. **Sheets.** Open the filter, guest link, close cycle, delete group and clone sheets: each is as tall as its content. View-only sheets close with X, editing sheets with "Huỷ"; no sheet has a back arrow. Type something in a form sheet and swipe down: it asks before discarding.
8. **Feedback.** Save an expense: a short coin sound and a tap. Record a payment: a "ting". Settle the last debt of the scripted group: shapes burst with a short chord. Flip the ringer switch to silent: no sound, haptics stay. Turn off "Âm thanh" and "Rung" in Account: nothing plays or vibrates. Play music and save an expense: the music keeps playing.
9. **Motion and speed.** Turn on Reduce Motion: no slides, bursts or rolling numbers. In a large group, scrolling the feed stays smooth.
10. **Text size.** Set the largest accessibility text size: Settle and the expense form are readable with nothing cut or overlapping (B07).
11. **Loading.** With slow network (`--latency-2s --no-snapshot`), open a group: the name and member shapes are there at once, the composer is there from the start, the skeleton looks like the screen, nothing jumps when data arrives (B20).
12. **Pickers.** In the expense form, the recurring form and receipt review, choosing people looks and behaves the same, with a title saying what it is for.
13. **Invalid cases.** Save a form with a missing amount: the field shakes and the phone gives a warning tap. Double-tap Save: only one expense is created. Lose network during a save: the existing offline message appears and nothing is half-saved.

## 16. Findings coverage

Every finding and defect that `findings.md` assigns to Phase 5.6 or to all phases, and how this spec handles it. "Built" means 5.6 builds it; "Rule" means 5.6 records the rule and every later phase applies it; "Partly" means 5.6 builds the foundation and the named phase finishes it.

| ID | Spec section | Outcome |
|---|---|---|
| B01, F2-01 | 4.1 | Built: native bar removes the double back button |
| B07, F3-27, F3-28 | 8 | Built: Dynamic Type sweep; largest size required in every check |
| B09, F3-48, F3-49 | 4.5 | Built: `GroupUnavailableView` without group header |
| F3-47 | 4.5 | Built: "Về danh sách nhóm" kept |
| B10, F4-10 | 4.4 | Built: native bar plus replace-in-stack |
| B18, F4-36, F4-51 | 4.5, 4.6 | Built: role-gated menu item, anchor to categories, no-permission screen with back |
| B19, F4-40 | 4.1 | Built: tab roots under a navigation bar |
| B20, F4-43, F4-44, F4-45 | 9.1 | Built: known name and shapes at once, composer from the first frame, layout-shaped skeletons |
| F4-42 | 9.1 | Kept: snapshot shown at once |
| F2-02, F2-03, F2-126, F2-129 | 4.1 | Built: native navigation replaces the custom header and both patches |
| F2-04, F2-05 | 4.3 | Built: navigate inside the current tab |
| F2-06 | 4.2 | Built: tab bar hidden only on focused-task screens |
| F4-05, F4-06 | 4.4, 10.4 | Partly: landing rule and toast built; clone fixed; close cycle lands correctly in 5.8 |
| F2-29, F2-30, F2-31, F2-32, F4-03, F4-04 | 5 | Built: sheet modifiers and dismiss rules applied to all 32 presentations ("Để sau" kept on the push pre-prompt only) |
| F2-130 | 5.1 | Kept: the filter sheet is the reference sheet |
| F2-132, F2-57, F2-58, F2-61, F2-62, F1-58, F1-59, F1-74 | 6.1, 6.2 | Rule and built: motion principles and spring tokens; one celebration; no library |
| F2-63, F4-53 | 6.2, 13.2 | Built: every animation goes through the Reduce Motion helper |
| F1-44, F2-59, F2-60 | 6.3, 10.6 | Built: only `MoneyText(.hero)` rolls, only on change |
| F2-56 | 6.3 | Built: segmented and chip selection slide |
| F1-49 | 6.3, 7.1 | Built: selection spring and haptic; tab bar is the system's |
| F1-50 | 6.3 | Built: system swipe actions |
| F1-51, F2-55 | 6.3 | Built: field shake and warning haptic |
| F2-54 | 6.3, 10.3 | Built: `CopyButton` |
| F1-52 | 6.3, 10.5 | Built: `ShapeLoader` |
| F2-64 | 13.4 | Built: profiling in the Simulator; owner repeats on device |
| F1-60, F4-55, F2-127 | 7.1 | Built: `.sensoryFeedback` wrapper with fixed meanings |
| F1-54, F1-55, F1-56, F1-57 | 7.2, 7.4 | Built: three generated sounds, ambient session, own actions only, setting |
| F1-32 | 7.3 | Built: feedback wired to the three existing money moments |
| F4-01, F4-02 | 10.1 | Built: `MemberPicker` adopted in the expense form, recurring form and receipt review |
| F2-125 | 10.2 | Built: `ChipRow`; screens adopt it as redesigned |
| F2-44 | 9.2 | Partly: `CountBadge` hides zero; screens adopt it in 5.7 and 5.8 |
| F2-123 | 9.2 | Partly: `EmptyState` requires a next action; screens adopt it in 5.7 and 5.8 |
| F2-119, F2-120, F2-121 | 10.6 | Partly: formatter roles and viewer-side naming built; labels added per screen in 5.7 and 5.8 |
| F2-122, F2-43, F1-01 | 10.6 | Built: shapes always carry initials; unclaimed shapes dashed; shapes stay the brand asset |
| F1-30, F1-04, F1-75, F2-131 | 11.1, 11.3 | Rule: copy rules recorded; 38 long strings inventoried with their owning phase |
| F2-42, F2-45, F2-124, F1-28, F1-29 | 11.1 | Rule: applied by the screens of 5.7 and 5.8 |
| F2-128 | 11.1 | Built: new-group placeholder "Đà Lạt cuối tuần" |
| F4-32 | 12 | Built: stats fake made consistent |
| F4-54 | 13.2 | Built: VoiceOver labels on icon-only buttons; Simulator VoiceOver run |
| F3-59, F3-60, F3-61 | 13.1 | Built: dark-mode screenshots for every sheet and share card |
| F4-07, F4-08 | 13.3 | Rule: iPhone SE joins the gate; answers move up in 5.7 |
| F4-56 | 1, 3 | Rule: fixes are made per pattern, not per screen (this phase's structure) |

Items of other phases that this phase touches only as a foundation: B02 (pay sheet role) and B21 (SE note) stay with 5.7; B03, B04, B13, B14, B16, B17 stay with 5.8.
