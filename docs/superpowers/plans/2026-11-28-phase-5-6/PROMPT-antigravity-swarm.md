# Prompt for Antigravity — Phase 5.6 (iOS foundations) with `/swarm`

Open Antigravity at the root of the main checkout (`songphang/`, the current workspace — no separate worktree). Type `/swarm`, then paste everything below the line. Paste the same text, unchanged, if a session ends before the run is complete: the run resumes from the first unticked task in `progress.md`.

---

You are the **Coordinator** of a Sòng Phẳng phase run: **Phase 5.6 — iOS foundations**, on branch `phase-5-6`. The spec and the plan are approved by the project owner; you work through the whole plan without waiting for approval between tasks (`AGENTS.md` §12). Communicate with the owner in Vietnamese; write every engineering artifact (code, comments, commits, run files except `manual-checks.md`) in English.

## Skills

Load and follow `.agent/skills/songphang-swarm-orchestrator/SKILL.md` and its `references/swarm-briefs-and-workflow.md`, with the workspace exception below. Companion skills: `.agents/skills/execute-task/SKILL.md` (phase-run mode), `.agents/skills/security-review/SKILL.md`, `.agents/skills/review-code/SKILL.md`, and `swarm_pane`.

## Workspace exception (owner's instruction)

Do **not** create worktrees. Work directly in the current workspace:

- Every worker uses `workspace: "inherit"`. Never `share` or `branch`.
- Because all workers share one checkout, there is **exactly one writer**: the `ios` worker. It runs every task in order, alone. Never run two writers at the same time and never parallelize edits.
- Readers (the final audit) use `run_workflow` with `workspace: "inherit"` and must not modify files.
- The worker's commits land on `phase-5-6` directly; there is nothing to cherry-pick. Still verify `git log` before any `kill`.

## Read first (you, then copy into the worker brief)

1. `AGENTS.md` (all of it, especially §5, §6, §9–§12) and `apps/ios/AGENTS.md` (all of it; it wins on Swift matters).
2. Spec: `docs/superpowers/specs/2026-11-28-phase-5-6-ios-foundations-design.md` — the source of truth for this run.
3. `docs/superpowers/plans/2026-11-15-common.md`, then the plan: `docs/superpowers/plans/2026-11-28-phase-5-6/00-overview.md` and the four stage files `5-6-a-design-system.md`, `5-6-b-navigation.md`, `5-6-c-apply.md`, `5-6-d-data-checks-and-handoff.md`.
4. Context only (read, do not change): `docs/superpowers/specs/2026-11-28-ui-ux-v3-roadmap-overview-design.md`, `docs/superpowers/research/2026-11-28-ui-ux-v3-review/README.md` and `findings.md`, ADR-042 to ADR-044 in `docs/04-adr.md`.

## Pre-flight (Coordinator)

1. `git status --short` must be empty. If not, stop and report the files to the owner in Vietnamese; do not stash, reset or delete anything.
2. `git switch phase-5-6`, then confirm `git branch --show-current` prints `phase-5-6`. Never work on `main`.
3. Confirm the run files exist: `docs/superpowers/runs/phase-5-6/{progress,decisions,manual-checks,copy-changes}.md`. If one is missing, run `bash .agent/skills/songphang-swarm-orchestrator/scripts/init-phase-run.sh phase-5-6` and create `copy-changes.md` with the table header the plan uses.
4. Confirm Xcode and an iOS 26 or newer Simulator runtime exist (`xcodebuild -version`, `xcrun simctl list runtimes`). If not, record "Not built: no Xcode" in `progress.md` and stop. Install nothing.
5. Open `progress.md`. If tasks are already ticked, this is a resume: reconcile `progress.md` with `git log main..phase-5-6`, and continue from the first unticked task.

## Swarm topology

```text
Coordinator (inherit, phase-5-6, owns pre-flight, stage gates, final audit, report)
  -> ios worker (inherit, the only writer)
       Task 0 -> 5.6.A.1 ... 5.6.A.6 -> Stage A gate
       -> 5.6.B.1 ... 5.6.B.3 -> Stage B gate
       -> 5.6.C.1 ... 5.6.C.4 -> Stage C gate
       -> 5.6.D.1 -> 5.6.D.2 (final gate, findings record, manual-checks.md)
  -> Coordinator re-runs each stage gate on phase-5-6 after the worker reports it
  -> Coordinator runs the read-only run_workflow audit, then reports to the owner
```

Name the swarm "Sòng Phẳng Phase 5.6 — iOS foundations" and keep `plan.json` with one task `ios` and threads per stage (A design system, B navigation, C apply, D data and checks). The worker owns all run files (`progress.md`, `decisions.md`, `manual-checks.md`, `copy-changes.md`); the Coordinator does not edit them while the worker is active.

## Worker brief (`ios`) — fill the skill's contract block with this

- **Role:** `ios`, the only writer, on `phase-5-6`, `workspace: "inherit"`.
- **Assigned tasks:** Task 0 through 5.6.D.2, strictly in plan order, one commit per task.
- **Allowed paths:** `apps/ios/**` and `docs/superpowers/runs/phase-5-6/**`.
- **Do not touch:** `apps/web/**`, `apps/api/**`, `apps/worker/**`, `packages/**`, root config files, `docs/` outside the run directory (specs, plans, ADRs, `findings.md`, `user-flows.md` are the advisor's).
- **Gate before every commit** (from `apps/ios/AGENTS.md` §2 and the plan):
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `BUILD SUCCEEDED` (add `-skipPackagePluginValidation` only if the build stops at plugin validation, and record it)
  - `xcrun swift-format lint --strict --recursive apps/ios` → no output
  - `./apps/ios/Scripts/check-strings.sh` → OK (after Task 5.6.C.4 it lists allowed keys from `copy-changes.md`)
- **Per task:** follow the execute-task skill in phase-run mode: approach note, real gate output, Simulator exercise results, screenshot paths, finding IDs closed, all written to `progress.md`; open questions decided and written to `decisions.md`; every string added, changed or removed written to `copy-changes.md` in the same commit.
- **Screenshots:** save under `docs/superpowers/runs/phase-5-6/screens/` (as the plan names them) and also post `Screenshot: <abs_path> | <summary <= 10 words>` lines for `swarm_pane`.
- **Done for each task:** one commit `type(ios): short description` (Task 0 and the final task use the messages the plan gives); post `@coordinator` with the commit hash, files changed, verbatim gate output, what was exercised, decisions, and "Not verified" items.

## Rules most often broken

- **No screen redesign.** Phase 5.6 builds foundations only. The 3-tab shell, removing group segments, the form as a sheet, duplication, instant "Đã nhận", the three-layer Settle flow and every secondary-screen redesign belong to 5.7 or 5.8: record them under "Out of scope", do not build them.
- **No automated tests**, no test targets, no `*.test.*` or `*.spec.*` files.
- **No new dependency** (SwiftPM or npm). No download of any kind, sounds included: the three sounds are generated by the script Task 5.6.A.2 writes.
- **Money:** only addition, subtraction and comparison on `Money`, in the app and in the fakes. Fakes return literals; the app computes no share, balance or QR payload.
- **Strings (ADR-044):** iOS strings may differ from `apps/web/src/messages/vi.ts` only when the key is recorded in `copy-changes.md`. Never edit `vi.ts`.
- **Reduce Motion:** every animation goes through the `Motion` helper of Task 5.6.A.1.
- **Never silence** a warning or the linter (`!`, `try!`, `as!`, `@unchecked Sendable`, `nonisolated(unsafe)`, attributes, comment directives).
- **Do not rely on memory** for SwiftUI/AVFoundation APIs on iOS 26: read the installed SDK interfaces or Apple's documentation first, and record the source in `decisions.md` where the plan asks.
- **No emoji** anywhere. No outside service, no account, no deployment, no `git push`, no `--force`, no history rewrite, never touch `main`.
- **Do not ask and do not wait.** Decide, record, continue. A failing gate is fixed; after three failed attempts on the same item, record it under "Gate not passed" and continue.
- **Never invent a result.** Anything not observed (haptics, the ringer switch, music interruption and device performance cannot be observed in the Simulator) goes under "Not verified" with the reason.
- **Simulators:** use iPhone 17 Pro for the main pass and an iPhone SE (3rd generation) simulator for small-screen captures; delete any simulator you create at the end.

## Stage gates (Coordinator, after the worker reports each stage)

Re-run on `phase-5-6` and record the verbatim output in `progress.md` once the worker is idle:

- The three gate commands above, plus `pnpm check` (no TypeScript change is expected; it must still pass).
- The stage's own gate from its stage file (gallery captures for A; every `Route` case opened and the two patches gone for B; the screenshot set for C; scenario captures and the final checks for D).
- Never trust a worker's claim without re-running it.

## Final read-only audit (Coordinator)

Before the report, run `run_workflow` with `workspace: "inherit"`, adapting the skill's audit script to three angles over `git diff main..phase-5-6` (read-only, no file changes):

1. **Security** (`security-review`): no token or secret in logs, `UserDefaults` or files; links still become routes through the single validated function; no new third-party SDK; sounds and settings store nothing sensitive.
2. **Money and module boundaries** (`apps/ios/AGENTS.md` §3 and §5): no arithmetic on `Money` beyond the allowed operations, fakes are literals, features import only `Domain`, `DesignSystem`, `PreviewSupport`; nothing slow on the main actor.
3. **iOS hygiene:** every animation honours Reduce Motion, no fixed font sizes left without a recorded reason, every icon-only button has a VoiceOver label, `check-strings.sh` allowed keys equal the rows of `copy-changes.md`, zero emoji, no test files. Web parity is **not** checked in this phase (ADR-044).

Fix every `must_fix` as its own `fix(ios): …` commit through the `ios` worker, re-run the gates, then continue.

## Quota and resume

Follow the skill's "Quota & Recovery Protocol": on a `429`, do not kill or replace the worker and do not downgrade its model; record which task is paused in `progress.md`. When the owner says "tiếp tục" or "quota đã hồi", check `swarm` status, reconcile `progress.md` with `git log main..phase-5-6`, and `@mention` the worker with the exact next task.

## Finish

When Task 5.6.D.2 is ticked, the final gate and the audit pass (or their failures are recorded), and `git status` is clean:

1. Confirm all commits are on `phase-5-6` (`git log --oneline main..phase-5-6`), then end the swarm.
2. Do not merge, do not push, do not switch back to `main`.
3. Report to the owner **in Vietnamese**: what was built per stage, the seven defects (B01, B07, B09, B10, B18, B19, B20) and how each was fixed, gate results, the audit result, everything under "Not verified", "Gate not passed" and "Out of scope", and the path of `docs/superpowers/runs/phase-5-6/manual-checks.md` for the owner's iPhone checks.
