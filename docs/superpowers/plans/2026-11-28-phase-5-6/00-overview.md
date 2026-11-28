# Sòng Phẳng Phase 5.6 (iOS Foundations) Implementation Plan

> **For agentic workers:** this is a phase run (`AGENTS.md` §12). Read the root `AGENTS.md`, `apps/ios/AGENTS.md`, the spec, `docs/superpowers/plans/2026-11-15-common.md`, then this file. Use `superpowers:executing-plans` for the continuous run, `.agents/skills/execute-task/SKILL.md` (phase-run mode) and `.agents/skills/security-review/SKILL.md` for every task. Steps use checkbox (`- [ ]`) syntax tracked in `docs/superpowers/runs/phase-5-6/progress.md`. The project writes no automated tests.
>
> **Status (2026-11-28):** spec and plan approved by the project owner. Ready to run on branch `phase-5-6`.

**Goal:** Give the iOS app the shared foundations of UI/UX v3 — native navigation, one sheet system, one motion system, haptics and sound with a setting, Dynamic Type everywhere, layout-shaped loading, shared components, copy rules, and fake data that opens every screen — and fix defects B01, B07, B09, B10, B18, B19, B20. No screen is redesigned; no API, database or Web change.

**Architecture:** Everything new lives in `DesignSystem` (tokens, modifiers, components, sounds) and `AppShell` (navigation, routing, presentation). Feature modules adopt the new pieces without changing their screen structure. Fakes and launch flags live in `PreviewSupport` and `AppShell/RootView.swift`. Dependency rules of `apps/ios/AGENTS.md` §3 are unchanged.

**Tech stack:** Swift 6, SwiftUI on iOS 26 (`navigationTitle`/`toolbar`, `presentationDetents`, `sensoryFeedback`, `contentTransition(.numericText)`, `symbolEffect`, `PhaseAnimator`, `Canvas`), AVFoundation (`AVAudioSession` `.ambient`, `AVAudioPlayer`), `afconvert` for sound files. No new package.

**Spec and inputs:**
- [Phase 5.6 design](../../specs/2026-11-28-phase-5-6-ios-foundations-design.md) (the source of truth for this run)
- [UI/UX v3 roadmap overview](../../specs/2026-11-28-ui-ux-v3-roadmap-overview-design.md)
- [Review record and findings register](../../research/2026-11-28-ui-ux-v3-review/README.md)
- [iOS codebase architecture](../../specs/2026-11-16-ios-codebase-architecture-design.md)
- ADR-042, ADR-043, ADR-044 in `docs/04-adr.md`

## Global constraints

- **Branch:** `phase-5-6`, created by the advisor from `main` at `c42055f` or later. Never touch `main`, never push, never deploy, never call an outside service.
- **Write boundary:** `apps/ios/**` and `docs/superpowers/runs/phase-5-6/**` only (`apps/ios/AGENTS.md` §1). Anything else seen is recorded under "Out of scope".
- **No automated tests** (`AGENTS.md` §6). Every task is verified by the iOS gate plus running the app in the Simulator and recording what was observed.
- **iOS gate before every commit:**
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `BUILD SUCCEEDED`
  - `xcrun swift-format lint --strict --recursive apps/ios` → no output
  - `./apps/ios/Scripts/check-strings.sh` → OK (after Task 5.6.C.4 it reports allowed differences from `copy-changes.md`)
- **No new dependencies.** No SwiftPM or npm package.
- **Money:** no arithmetic on `Money` beyond what `apps/ios/AGENTS.md` §5 allows; fakes return literals; the app computes no share, balance or QR payload.
- **Strings (ADR-044):** any added, changed or removed string is recorded in `docs/superpowers/runs/phase-5-6/copy-changes.md` in the same commit.
- **Reduce Motion:** every animation added or touched goes through the `Motion` helper of Task 5.6.A.1.
- **No emoji** anywhere.
- **Decide and record** (`AGENTS.md` §12): what the spec leaves open is decided and written to `decisions.md`. The spec's scope boundary (no screen redesign, section 1 "Out of scope") is not a decision to make: work that belongs to 5.7 or 5.8 is recorded under "Out of scope", not built.
- **Findings:** each task lists the finding IDs it closes. `progress.md` records, per task, the IDs closed and how. The advisor updates `findings.md` at review.

## Review focus

| Failure mode | Owning exercise |
|---|---|
| A pushed screen still shows a custom back button, two back buttons, or swipe-back does not work after removing `PopGestureEnabler` | 5.6.B.1: open every `Route` case and swipe back on each; screenshot each bar |
| Content scrolls under the clock on any tab root or pushed screen after removing `StatusBarCover` | 5.6.B.1: scroll each screen to the top edge in light and dark |
| Opening a group from Overview or a transaction from Notifications still switches tab; or a deep link / push target lands in the wrong tab | 5.6.B.2: tap paths from each tab; open `songphang://` links and a scripted push target |
| A content-sized sheet measures itself in a loop (jitter) or clips content at the largest text size | 5.6.A.4 and 5.6.C.1: open each sheet at default and largest Dynamic Type |
| Sound plays with the ringer switch silent, interrupts music, plays for someone else's realtime change, or plays with "Âm thanh" off | 5.6.A.2 and 5.6.C.3: Simulator audio checks; owner repeats on device |
| A haptic fires twice for one action, or fires on tab switches | 5.6.C.3: action-by-action check list in `progress.md` |
| Reduce Motion on, yet something slides, scales, bursts or rolls | 5.6.D.2: Reduce Motion pass over every moment of spec section 6.3 |
| A fake computes money instead of returning literals | 5.6.D.1: read every new fake for arithmetic on `Money` |
| `check-strings.sh` passes while an undocumented string differs from the web file | 5.6.C.4: change a string without recording it and confirm the script fails |

## Files and stage order

| Order | Stage file | Tasks |
|---|---|---|
| 0, A | [5-6-a-design-system.md](5-6-a-design-system.md) | Task 0 (re-baseline and "before" captures), 5.6.A.1 motion, 5.6.A.2 feedback and sound, 5.6.A.3 typography foundation, 5.6.A.4 sheet system, 5.6.A.5 selection and state components, 5.6.A.6 feedback and money components with the gallery and Stage A gate |
| B | [5-6-b-navigation.md](5-6-b-navigation.md) | 5.6.B.1 native bars, 5.6.B.2 tab bar and in-tab navigation, 5.6.B.3 landing, unavailable screens and categories entry with the Stage B gate |
| C | [5-6-c-apply.md](5-6-c-apply.md) | 5.6.C.1 sheets applied, 5.6.C.2 loading and states, 5.6.C.3 feedback and component adoption, 5.6.C.4 Dynamic Type, VoiceOver and copy with the Stage C gate |
| D | [5-6-d-data-checks-and-handoff.md](5-6-d-data-checks-and-handoff.md) | 5.6.D.1 fake scenarios and flags, 5.6.D.2 checks, findings and handoff |

**Handoff inputs:** `<SPEC>` = `docs/superpowers/specs/2026-11-28-phase-5-6-ios-foundations-design.md`; `<PLAN>` = `docs/superpowers/plans/2026-11-28-phase-5-6`; `<BRANCH>` = `phase-5-6`; `<LAST TASK>` = `5.6.D.2`. Run files: `docs/superpowers/runs/phase-5-6/{progress,decisions,manual-checks,copy-changes}.md`.

## Standard commands

```sh
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -destination 'generic/platform=iOS Simulator' \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun swift-format lint --strict --recursive apps/ios
./apps/ios/Scripts/check-strings.sh
pnpm check   # at each stage gate; no TypeScript changes are expected
xcrun simctl io booted screenshot docs/superpowers/runs/phase-5-6/screens/<name>.png
```

Launch flags used throughout: `--scripted`, `--route-*`, `--role-editor`, `--role-viewer`, `--latency-2s`, `--no-snapshot`, `--scenario-large`, `--scenario-empty`, `--all-settled`, `--with-closed-cycle`, plus the flags Task 5.6.D.1 adds. Use the iPhone 17 Pro simulator for the main pass and an iPhone SE (3rd generation) simulator for small-screen captures; delete any simulator you create at the end of the run.
