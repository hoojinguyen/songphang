# Sòng Phẳng — Phase 1 Implementation Plan — Overview

> **For the implementation agent:** read the root `AGENTS.md` first, then `docs/superpowers/specs/2026-11-12-phase-1-single-run-design.md`, then this file. Work through the stage files in order, task by task, without stopping between tasks. The project does not write automated tests.

**Goal:** Phase 1 of the roadmap ("Lõi chia tiền") working on the local machine: groups, members, every kind of transaction and split, balances and settlements, accounts, invites and roles, realtime, the sentence reader, editing and history.

**Architecture:** As `docs/04-sad.md`. A dependency-free `packages/core` holds all money arithmetic and the sentence reader. The API has routes (no logic), one group-authorization middleware, services (one function per operation, one database transaction), and typed queries in `packages/db`. The web app is a thin client of the API.

**Tech Stack:** TypeScript, Node.js, pnpm workspaces, Hono + `@hono/zod-openapi`, Zod, PostgreSQL 17, Drizzle ORM + drizzle-kit, Next.js (App Router) + React, TanStack Query, Tailwind CSS v4, Biome. New in this phase: `arctic` (API) and `uqr` (web).

**Spec:** `docs/superpowers/specs/2026-11-12-phase-1-single-run-design.md`. It ranks above `docs/` and below `AGENTS.md`.

## Stage files

| Order | File | Tasks | Adds |
|---|---|---|---|
| 1 | `1a-core-ledger.md` | 1A.1–1A.12 | Groups, members, equal-split expenses, balances, settlements |
| 2 | `1b-accounts-and-sharing.md` | 1B.1–1B.12 | Accounts, invites, roles, realtime |
| 3 | `1c-splits-and-settlements.md` | 1C.1–1C.6 | All split methods, several payers, transfers, income, settling |
| 4 | `1d-quick-entry.md` | 1D.1–1D.5 | Sentence reader and confirmation card |
| 5 | `1e-history-and-polish.md` | 1E.1–1E.6 | Edit, delete, restore, history, offline, motion |

Do not build ahead of a stage. A later task defines its own interfaces; earlier guesses create conflicts.

## Global Constraints

- Every rule in `AGENTS.md` applies. Where the "Phase run" section of `AGENTS.md` differs from sections 4 and 5, "Phase run" applies to this plan.
- **Branch:** all work is on `phase-1`. Never commit to `main`, never push, never rewrite history.
- **Libraries:** only `arctic` in `apps/api` and `uqr` in `apps/web` may be added, each in the task that names it. Any other new library is a decision to record in `decisions.md` with problem solved, why a few dozen lines cannot do it, license, maintenance state and added size. Latest stable versions only.
- No test library; no `*.test.*` or `*.spec.*` file; no committed script whose purpose is to assert expected outputs. Exercises are run by hand and their real output is recorded.
- Engineering artifacts are in English. User-visible strings are Vietnamese, live only in `apps/web/src/messages/vi.ts`, and match this plan and the spec character for character. No emoji.
- API root `/api/v1`; JSON with `camelCase` fields; times are ISO 8601 UTC strings; one error format `{ "error": { "code", "message", "details"?, "requestId" } }`.
- **Money** is a JavaScript `number` holding a safe integer of đồng, `1 ≤ amount ≤ 999_999_999_999`, stored as `bigint`. Division and rounding of money happen only in `packages/core`, with integer or `BigInt` arithmetic. No `Math.round`, `toFixed`, or fractional intermediate anywhere on the money path.
- Tables are plural `snake_case`; primary keys are UUID v7 generated on the server; timestamps are `timestamptz`; enumerations are `text` with a `CHECK`. Structure changes only through `drizzle-kit generate`; never edit a committed migration.
- Every route with `{groupId}` goes through `requireGroupRole`. A caller who is not in the group, or a `groupId` that is not a UUID, gets **404 `NOT_FOUND`**, identical to a group that does not exist. Insufficient role gets 403 `FORBIDDEN`.
- Every write route (`POST`, `PATCH`, `PUT`, `DELETE`) uses `requireSameOrigin`. From stage 1B every route that creates or changes data also uses `requireVerifiedEmail` and the write rate limit.
- Every endpoint that creates group data (a group, a member, a transaction, a join) requires an `Idempotency-Key` header and runs through `runIdempotent`. The `/auth/*` endpoints do not.
- Secrets never enter git, logs, error messages, or the run files. The only exception is NFR-1.14: in development the mailer prints mails, including their links, to the API console.
- Routes hold no logic; one service function per operation; queries live in `packages/db`; the current time comes from `deps.now()`.
- Dependency rules: `web → contract`; `api → contract, db, core`; `core → nothing`. The web app never computes an amount it shows as official.
- Design tokens only: no raw color value in a component. Minimum hit area 44 × 44. Page column max width 430px, centered. Every data screen has loading (skeleton), error (`LoadError`), and empty states.
- Follow existing code. When a stage changes an interface an earlier stage defined, change it in place and update every caller in the same task; do not keep two ways.

## Per-task procedure

The six steps of `.agents/skills/execute-task/SKILL.md` in phase-run mode:

1. **Read** the task, the constraints above, the documents it references, and the code it touches.
2. **Think.** Write the approach note into `progress.md` under the task. Any question you would have asked becomes an entry in `decisions.md`; then continue.
3. **Do.**
4. **Self-check:** `pnpm check`; exercise the change (the task's exercise steps plus at least two invalid cases); run the `security-review` skill; read your whole diff.
5. **Record:** commit (one commit per task, `type(scope): short description`); tick the task in `progress.md` with the commit hash and the real output of the exercises; copy the task's "Manual checks for the project owner" into `manual-checks.md` under the screen or flow they belong to.
6. **Continue** with the next task.

If the same check still fails after three fix attempts, record the failure exactly in `progress.md` under the task as "Unresolved", commit what works with `pnpm check` passing, and continue. Never use `any`, `@ts-ignore`, `biome-ignore` or `!` to get past a check.

If a browser tool is available, do the browser exercises. If not, do what `curl` can show and list the rest under "Not verified" in `progress.md`.

## Stage gate

After the last task of each stage:

1. `pnpm check` and `pnpm build` pass.
2. Reset the database (`docker compose down -v`, start again), then run the stage's acceptance script from its gate task, and again the acceptance scripts of every earlier stage. Record real outputs.
3. `pnpm db:check-balances` prints `All groups balanced`.
4. Replay the permission matrix below for every endpoint that exists so far. Record one line per endpoint and caller.
5. Write the gate result in `progress.md`.

A failing gate is fixed, in new commits, until it passes. After three failed fix attempts on the same gate item, record it under "Gate not passed" with the exact output and continue with the next stage.

### Permission matrix

From `docs/03-srs.md` section 2.4. "Outsider" is a signed-in user who is not in the group. Before stage 1B only owner and outsider can exist.

| Endpoint group | Owner | Editor | Viewer | Outsider |
|---|---|---|---|---|
| Read group, members, users, transactions, balances, activity, events | 200 | 200 | 200 | 404 |
| Create, edit, delete, restore a transaction; preview; parse | 2xx | 2xx | 403 | 404 |
| Create, edit, delete a member | 2xx | 2xx | 403 | 404 |
| Read the invite link | 200 | 200 | 403 | 404 |
| Toggle or rotate the invite link; change a role; remove a user; transfer ownership | 2xx | 403 | 403 | 404 |
| Edit group settings; delete the group | 2xx | 403 | 403 | 404 |
| Leave the group | 422 | 204 | 204 | 404 |
| Choose "tôi là người này" | 200 | 200 | 200 | 404 |

Every 404 body must be identical, apart from `requestId`, to the 404 for a random UUID. A signed-out caller gets 401 everywhere.

## Run files

In `docs/superpowers/runs/phase-1/`. They already exist with their headings.

| File | You write |
|---|---|
| `progress.md` | Per task: approach note, tick, commit hash, real exercise output, "Unresolved". Per stage: gate result, "Gate not passed", "Not verified" |
| `decisions.md` | One entry per decision the spec and plan did not make: problem, options, choice, reason |
| `manual-checks.md` | The owner's check list by screen and flow, including invalid cases. Google sign-in has its own section headed "After the Google OAuth app exists" |

Starting a session: read `progress.md` and continue from the first unticked task. If the working tree has uncommitted changes from an interrupted session, inspect them, finish or discard that task's work deliberately, and note what you did in `progress.md`.

## Review Focus

The failure modes most likely to reach a real user. Each stage file adds its own; these span the phase.

1. **A stranger reads a group.** Every `groupId` route answers 404 to outsiders, for every method, in every stage.
2. **A double tap stores two transactions.** Every create goes through `runIdempotent`; every form reuses one key per mounted instance.
3. **A đồng appears or disappears.** Every split and every settlement sums exactly; `pnpm db:check-balances` passes after every stage.
4. **A sign-up or reset form reveals who has an account.** Register and forgot-password answer identically for known and unknown emails, in body, status and timing class.
5. **A later stage quietly breaks an earlier one.** Every gate replays all earlier acceptance scripts.
