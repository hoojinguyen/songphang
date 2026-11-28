# UI/UX v3 Review (2026-11-28)

The full record of the UI/UX review of the iOS app that led to the v3 roadmap. The roadmap overview (`docs/superpowers/specs/2026-11-28-ui-ux-v3-roadmap-overview-design.md`) summarises it; this folder keeps every detail, so that phase specs, implementation agents and reviews can check their work against what was actually found.

The review was run on `main@6839bbf` in the iOS Simulator (iPhone 17 Pro, iPhone SE 3rd generation) with scripted data, plus reading the SwiftUI source. Web was not reviewed.

## Files

| File | Content |
|---|---|
| [01-main-screens.md](01-main-screens.md) | Part 1. Main screens, five principles, the 3-tab structure, mockups, the motion, haptic and sound system, copy rewrite, first use |
| [02-detail-screens.md](02-detail-screens.md) | Part 2. Transitions, sheets, repetition, row buttons, the animation budget, keep / remove / change for 18 screens, ten small conventions |
| [03-direction.md](03-direction.md) | Part 3. Decisions on the form sheet and instant "Đã nhận", the three-layer model, 14 more screens and states, coverage |
| [04-remaining-screens.md](04-remaining-screens.md) | Part 4. Four recurring patterns, clone, receipt, recurring, close cycle, settings, account, slow network, iPhone SE, editor role, accessibility from code |
| [findings.md](findings.md) | The register: 316 findings and 21 defects, each with an ID, owning phase and status |
| `img/` | The 63 screenshots used by the four parts |

The parts are kept in the original Vietnamese because they quote the product's own wording. Each part was first published as a private claude.ai artifact; the Markdown copy here is the one to use, because agents cannot open those pages.

## How the register is used

1. **Phase spec.** Each v3 phase spec has a section "Findings coverage" with one row per finding and defect assigned to that phase in `findings.md`, saying how the spec handles it: built as proposed, built differently (and why), or deferred (to which phase, and why). A finding with phase `All` appears in every phase spec where it applies.
2. **Phase run.** The implementation agent records in the run's `progress.md` which finding IDs each task closes, and lists any it could not close under "Not verified".
3. **Review.** The advisor checks that every finding of the phase is closed, then updates `Status` in `findings.md` in the same branch: `Done (<phase>, <commit>)`, `Changed (<decision>)` or `Deferred (<reason>)`.
4. **Done.** A phase is not finished while a finding assigned to it is still `Open`. By the end of Phase 5.8 every iOS finding is closed; Phase 5.9 applies the iOS outcome to Web.

## Rules for editing the register

- IDs never change and are never reused. A finding that turns out to be wrong is closed as `Changed`, not deleted.
- A new finding (for example from a later review or the owner's own check) is appended at the end of the matching part with the next free number, or under a new heading for a new source.
- Moving a finding to another phase is allowed when the phase spec explains why; update the `Phase` column at the same time.
- Owner decisions in the roadmap overview (section 3) take precedence over proposals in the parts. Where a decision changes a proposal, close the finding as `Changed (D<n>)`.
