# Prompt for the implementation agent — iOS interface stage (5U)

Paste the part below the line to the agent, opened at the root of the worktree `../songphang-ios-ui` (branch `ios-ui`), not at the main checkout. Use the same text, unchanged, every time a session ends before the run is complete.

---

You are the implementation agent for the Sòng Phẳng project. You are doing a phase run of the iOS interface stage: you work through the whole plan without waiting for approval between tasks.

1. Read all of `AGENTS.md` at the repository root, including the "Phase run" section, then all of `apps/ios/AGENTS.md`. Every rule applies to you; on Swift-specific matters the second file wins.
2. Read `docs/superpowers/specs/2026-11-16-ios-codebase-architecture-design.md` completely. Read sections 3, 5.2 and 5.3 of `docs/superpowers/specs/2026-11-15-phase-5-ios-design.md`.
3. Read `docs/superpowers/plans/2026-11-16-ios-ui.md` completely, and the section "Rules for every task from 5B.3 on" of `docs/superpowers/plans/2026-11-15-phase-5/5b-5e-app.md`. Do not run any task of that second file.
4. Read `docs/superpowers/runs/ios-ui/fixtures/README.md`.
5. Confirm you are on the branch `ios-ui` (`git branch --show-current`) and that `git rev-parse --show-toplevel` ends in `songphang-ios-ui`. If not, stop and say so; do not create or switch branches or worktrees.
6. Open `docs/superpowers/runs/ios-ui/progress.md`. Find the first unticked task and continue from it.
7. For every task follow the plan's "Per-task procedure". Write the approach note, the real gate output, the exercise results and the screenshot paths into `progress.md`; every decision the plan left open into `decisions.md`; the owner's checks into `manual-checks.md`.
8. Keep going until task U.8 is ticked, then stop and report in Vietnamese: what was built, what is under "Not verified", "Gate not passed" and "Domain guesses".

Rules that are most often broken:

- Write only under `apps/ios/` and `docs/superpowers/runs/ios-ui/`. Everything else is read-only, including `apps/web`, `apps/api`, `packages/`, the root configuration files, the specs and the plans. Another agent is changing them on another branch.
- No server and no network. Do not start `pnpm dev`, do not call the API, do not download anything (fonts included), do not add a package dependency.
- No automated tests and no test targets.
- No money arithmetic beyond addition, subtraction and comparison, in the application and in the fakes alike. Every amount a fake returns is transcribed from a file in `fixtures/`; input with no fixture is refused, never estimated. Never change a captured amount.
- `Package.swift` is the dependency rule. If code does not compile where it is, move the code; never add a dependency between existing modules.
- The gate is the two commands in `apps/ios/AGENTS.md` section 2 and must pass before every commit. Never silence a warning or the linter (`!`, `try!`, `as!`, `@unchecked Sendable`, `nonisolated(unsafe)`, attributes, comment directives).
- Do not rely on memory for Swift, SwiftUI or SwiftPM APIs. Read the installed toolchain's interfaces and Apple's documentation for the installed version before using an API you are unsure about.
- User-visible strings match `apps/web/src/messages/vi.ts` character for character. A web screen is ported with the same content and order.
- Do not ask questions and do not wait. Decide, write the decision in `decisions.md`, continue.
- Never invent a result. A screenshot or number you did not produce goes under "Not verified" with the reason.
- One commit per task, `type(ios): short description`. Never push. Never touch `main` or `phase-1`.
- If Xcode or an iOS 26-or-newer Simulator runtime is missing, record "Not built: no Xcode" in `progress.md` and stop. Do not install anything.
