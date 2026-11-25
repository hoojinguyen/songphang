---
name: sp-feature
description: >-
  Use in Antigravity when the user proposes a new feature, non-trivial UX or
  backend change, or upcoming phase wave in Sòng Phẳng using natural language
  (Vietnamese or English) before a spec or plan is approved.
---

# Sòng Phẳng Natural-Language Feature Intake

Turn a natural-language feature idea into an approved spec and a Swarm-ready implementation plan without requiring the owner to invoke skill names manually.

**When NOT to use:**
- Small, clear fixes or single-area tasks → follow `.agents/skills/execute-task/SKILL.md` directly.
- Spec and plan are already approved and ready to implement → follow `.agent/skills/songphang-swarm-orchestrator/SKILL.md`.

## Stage 1 — Idea to Approved Spec (`superpowers:brainstorming`)

1. Read `AGENTS.md`, then immediately load and follow `superpowers:brainstorming` (do not write code, scaffold, or jump to planning yet).
2. Communicate with the owner in Vietnamese (`AGENTS.md` language policy); write the resulting design document in English at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
3. Surface Sòng Phẳng product invariants during discovery so the spec pins them down:
   - VND integer-only money computed on the server (`packages/core` / `apps/api`), never floating-point on clients.
   - Strictly additive `/api/v1` contract and `404` responses for group outsiders.
   - Web and iOS (`SongPhangKit`) parity, Light/Dark contrast, Vietnamese copy parity (`vi.ts` / `Localizable.xcstrings`), zero emoji.
4. Complete the brainstorming builder check, present the spec, and wait for explicit owner approval before moving to Stage 2.

## Stage 2 — Approved Spec to Swarm-Ready Plan (`superpowers:writing-plans`)

1. After the owner approves the spec, read:
   - `superpowers:writing-plans`
   - `docs/superpowers/plans/2026-11-15-common.md`
   - `.agent/skills/songphang-swarm-orchestrator/SKILL.md` ("Swarm-Ready Plan Checklist")
2. Treat Antigravity `/swarm` as the already-supplied execution method (`writing-plans` "When an execution method has already been supplied" path — do not ask the owner to choose between `subagent-driven-development` and `executing-plans`).
3. Structure the plan under `docs/superpowers/plans/YYYY-MM-DD-<feature>/` (`00-overview.md` + stage files):
   - Stage 1 locks DB migrations, `packages/core`, `apps/api`, and `packages/contract/openapi.json` (plus a disjoint `Design System` stage if needed) before parallel `Web` and `iOS` stages.
   - Give parallelizable tasks disjoint `Files:` lists, explicit `Interfaces` (`Consumes` / `Produces`), and a single named owner for hot files (`openapi.json`, `vi.ts`, `Localizable.xcstrings`, `Package.swift`, `RootView.swift`).
   - Follow `AGENTS.md` §6: replace unit-test steps with real `curl`/disposable-DB/`check-balances.ts`/`check-strings.sh`/`xcodebuild` exercises and stage gates (no `*.test.*` or `*.spec.*`).
4. Run the `writing-plans` self-review checklist, save the plan, and ask the owner to review and confirm it.

## Stage 3 — Phase-Run Prep & `/swarm` Handoff

Once the owner approves the plan (and confirms branch setup if starting on `main`):
1. Ensure working on `<BRANCH>` created from `main` (never run implementation directly on `main`) and initialize clean run logs via:
   ```sh
   bash .agent/skills/songphang-swarm-orchestrator/scripts/init-phase-run.sh <BRANCH>
   ```
2. Commit the approved spec, plan, and initial `docs/superpowers/runs/<BRANCH>/` headers cleanly so `git status --short` is clean before spawning `share` worktrees.
3. Give the owner a one-line `/swarm` starter for a fresh session on `<BRANCH>` (the owner must type `/swarm` explicitly to enable native Swarm mode):
   ```text
   /swarm Implement <FEATURE_OR_WAVE> in phase-run mode on `<BRANCH>` using `<SPEC_PATH>`, `<PLAN_DIR>/00-overview.md`, and `.agent/skills/songphang-swarm-orchestrator/SKILL.md`.
   ```
