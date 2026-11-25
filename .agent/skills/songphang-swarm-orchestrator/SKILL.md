---
name: songphang-swarm-orchestrator
description: >-
  Use in Antigravity when implementing an approved spec and plan (phase run or
  multi-layer feature) in Sòng Phẳng with `/swarm` or `run_workflow`, or when
  structuring a `writing-plans` plan for Swarm execution. Triggers for
  multi-worker coordination across API/DB, Web, and iOS, parallel parity or
  security fan-outs, and resolving worktree, OpenAPI contract, or hot-file
  contention.
---

# Sòng Phẳng Swarm & Orchestrator

Coordinate `/swarm` (persistent domain workers) and `run_workflow` (Python DAG orchestrator) without breaking Sòng Phẳng's OpenAPI contract lock, SwiftPM module boundaries, or disposable-DB stage gates.

**Required companion skills:** `.agents/skills/execute-task/SKILL.md` (phase-run mode when the plan says so), `.agents/skills/security-review/SKILL.md`, `.agents/skills/review-code/SKILL.md`, and Antigravity's `swarm_pane` (for `plan.json` and `Screenshot:` lines during `/swarm`).

## Choose the Mechanism

| Need | Use | Workspace |
|---|---|---|
| Multi-stage feature/wave across API/DB, Web, iOS | `/swarm` (only when user invokes `/swarm`) | `share` for writers; `inherit` for verifier |
| Structured fan-out (parity, security, diff audit) returning JSON | `run_workflow` (`parallel` / `pipeline` / `phase`) | `inherit` for readers; `branch`/`share` for disjoint writers |
| Single isolated task or lookup | `invoke_subagent` | `inherit` (or `branch` if isolated edit) |

**Hard constraints:**
- Never call `swarm` unless the user explicitly invoked `/swarm` or a swarm is already active.
- Never trigger actions inside `run_workflow` that require interactive user approval — unapproved calls are denied automatically.
- Never parallelize edits on the same file in `workspace: "inherit"`.

## Swarm-Ready Plan Checklist (With `superpowers:writing-plans`)

Keep global `superpowers` skills untouched; supply Antigravity `/swarm` upfront as the chosen execution method when running `superpowers:writing-plans` so the plan emits Swarm-safe stages:
- **Stage separation:** Put DB, `packages/core`, `apps/api`, and `packages/contract/openapi.json` (plus an optional disjoint `Design System` stage) ahead of parallel `Web` and `iOS` stages.
- **Disjoint file lists & interfaces:** Give every parallelizable task non-overlapping `Files:` and explicit `Interfaces` (`Consumes` / `Produces`), naming a single owner for hot files (`openapi.json`, `vi.ts`, `Localizable.xcstrings`, `Package.swift`, `RootView.swift`).
- **Exercise steps over TDD (`AGENTS.md` §6):** Replace unit-test steps with real API/DB/Web/iOS Simulator exercises, stage gates, and `check-balances.ts` checks.
- **Clean branch handoff:** Commit the approved spec, plan, and initial `docs/superpowers/runs/<branch>/` files onto `<BRANCH>` before invoking `/swarm`.

## Swarm Phase-Run Sequence

```text
Task 0 (clean tree + re-baseline)
  -> Wave 1: api-db [share] (+ design-system [share] ONLY if disjoint)
  -> Coordinator lands Wave 1 on <BRANCH>, runs Stage Gate, broadcasts SHA
  -> Wave 2: web [share] || ios [share]  (api-db stays waiting for fixes)
  -> Coordinator lands Wave 2 BEFORE kill, runs Stage Gate + run_workflow audit
```

### 1. Pre-Flight (Before Spawning `share` Workers)

1. Confirm `git branch --show-current` is the plan's `<BRANCH>` (never `main`) and inspect `git status --short`. Record or clean pre-existing dirty/untracked files first because `share` worktrees inherit workspace state.
2. Complete `Task 0` re-baseline and create/verify `docs/superpowers/runs/<branch>/{progress,decisions,manual-checks}.md`.
3. In `/swarm`, load `swarm_pane`, name the swarm (`title`), and maintain `.system_generated/swarm/plan.json` whenever workers or threads change.

### 2. Lock Contracts & Hot Files

Never run `web` or `ios` implementation in parallel with unmerged `packages/contract/openapi.json` changes.

| Hot File / Area | Single Owner Rule |
|---|---|
| `packages/contract/openapi.json` | `api-db` only; additive `.optional()`/`.nullable().optional()` fields only (`pnpm contract:check`) |
| `apps/web/src/messages/vi.ts` | `design-system` or `web` owns copy; `ios` mirrors exact strings in `Localizable.xcstrings` |
| `Localizable.xcstrings`, `Package.swift`, `AppShell/RootView.swift` | One designated iOS owner per wave (or Coordinator integration) |
| `docs/superpowers/runs/<branch>/{progress,decisions,manual-checks}.md` | Coordinator updates from landed results (avoids multi-worktree merge conflicts) |

### 3. Worktree Rules for Worker Briefs

New swarm workers see nothing from the coordinator's chat history unless `fork` is passed. Always include the contract block from [references/swarm-briefs-and-workflow.md](./references/swarm-briefs-and-workflow.md) in every worker's `brief`, especially:
- **No `.env` in `share` worktrees:** Pass `DATABASE_URL=...` directly to `pnpm --filter @songphang/db exec tsx src/...`; bind isolated API exercises to a non-default port (e.g. `:4111`) and isolated `STORAGE_DIR` outside the repo.
- **No automated tests (`AGENTS.md` §6):** Zero test libraries or `*.test.*` / `*.spec.*` files.
- **One scoped commit per task** after passing checks; never `git push` or touch `main`.
- **iOS boundaries (`apps/ios/AGENTS.md`):** Features import only `Domain`, `DesignSystem`, `PreviewSupport`; use `-skipPackagePluginValidation` on Xcode Simulator builds without overriding `SWIFT_TREAT_WARNINGS_AS_ERRORS` for remote packages.

### 4. Land, Verify, Audit with `run_workflow`, Then `kill`

1. Land (cherry-pick or merge) every worker's commits onto `<BRANCH>` **before** calling `swarm` `kill` (`kill` deletes the `share`/`branch` workspace permanently).
2. Run authoritative Stage Gates on `<BRANCH>` after landing:
   - `pnpm check` and `pnpm build`
   - `./apps/ios/Scripts/check-strings.sh` and `xcrun swift-format lint --strict --recursive apps/ios`
   - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`
   - Disposable-DB replay + `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` (`All groups balanced`)
3. Before final handoff, run a read-only `run_workflow` audit (`workspace: "inherit"`) fanning out `security-review`, money/layer-boundary checks, and Web/iOS parity using the template in [references/swarm-briefs-and-workflow.md](./references/swarm-briefs-and-workflow.md).

## Quota & Recovery Protocol (Quality-First Freeze & Resume)

- **Prevent burn upfront:** Cap active writer workers at 2–3 per wave (`api-db` in Wave 1; `web` + `ios` in Wave 2), require one commit per finished task, and set `model="flash"` for lightweight read-only `run_workflow` hygiene/parity audits while keeping `"inherit"`/`"pro"` for Security and Money audits.
- **When `429` hits mid-swarm:** Do **not** auto-downgrade coding worker models (`api-db`, `web`, `ios`) and do **not** `kill` or replace paused workers. Leave workers in `waiting`/`stopped` so conversations and `share` worktrees stay intact, land any already-completed commits onto `<BRANCH>`, and report clearly which tasks are paused waiting for quota.
- **When the owner resumes (`"tiếp tục"` / `"quota đã hồi"`):**
  1. Run `swarm` `action: "status"` to inspect live member states (`waiting`, `stopped`, `working`).
  2. Reconcile `docs/superpowers/runs/<branch>/progress.md` with `git status`/`git log` across `<BRANCH>` and unlanded `share` worktrees.
  3. Land any completed clean commits from `share` worktrees onto `<BRANCH>`.
  4. `@mention` paused `waiting`/`stopped` workers on the board with the exact next task/commit to resume (never start a duplicate swarm; only call `swarm` `action: "model"` if the owner explicitly asks to switch a member's model).

## Red Flags — Stop and Correct

| Mistake | Fix |
|---|---|
| Spawning `web` + `ios` before Wave 1 OpenAPI lands | Wait for `api-db` commit + `pnpm contract:check`, merge to `<BRANCH>`, then `@mention` clients |
| Calling `swarm` `kill` right after a worker says "done" | Inspect `git log`, land commits onto `<BRANCH>`, verify clean diff, *then* `kill` |
| Killing or replacing a `429`-paused worker | Keep `waiting`/`stopped` worktree intact, land finished commits, resume via `@mention` (or `action: "model"` only if owner asks) |
| Running `pnpm db:migrate` in a `share` worktree | Fails without `.env`; pass `DATABASE_URL=... pnpm --filter @songphang/db exec tsx ...` |
| Using `run_workflow` for interactive steps or overlapping edits | Keep `run_workflow` to read-only audits or strictly disjoint `share` slices |
| Trusting worker check claims without re-running on merged HEAD | Coordinator always runs the Stage Gate on the integrated `<BRANCH>` |
