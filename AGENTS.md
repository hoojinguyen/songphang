# Sòng Phẳng — Agent Working Rules

This file applies to every agent working in this repository (Claude, Codex, Antigravity, and others). Read it completely before doing anything. It is intentionally short; details live in the files it references.

## Language policy

- Communicate with the project owner in Vietnamese.
- Use English for all engineering artifacts, including source code identifiers and comments, documentation, commit messages, branch names, pull request titles and descriptions, review comments, and repository metadata.
- Product-facing text and localized example data follow the approved Vietnamese product requirements.
- This policy takes precedence over older language guidance and examples in project documents.

## 1. Project

Sòng Phẳng is a group expense-splitting application for Vietnamese users: web first, native iOS and Android later, with a shared API. It is initially for internal use and will be released publicly later, so accounts, security, and UI quality are built to public-product standards from the beginning.

Current phase: **4 — Collaboration is merged on main** (`22a16fb`). **Phase 5 — iOS** design and implementation plan were approved on 2026-11-19. Antigravity implements the continuous run on `phase-5`; Codex is the advisor and reviewer. The 5B Simulator handoff is an early owner checkpoint, and full web parity remains the final acceptance goal. The owner verifies the product and decides merge. The owner has deferred checks with a real AI provider until all phases, including iOS, are done. This run uses the development machine and local adapters.

## 2. Who decides what

| Role | Authority |
|---|---|
| **Project owner** | Approves all requirement, UI, and library changes. Manually checks the product. The owner's words in the current session take precedence over every file. |
| **Advisor** | Decides technology and architecture, writes plans, reviews code, and updates `docs/` and this file. |
| **Implementation agent** (you, unless assigned another role) | Implements the assigned task exactly. May decide small matters in section 5; must ask about everything else. |

When sources conflict, priority is: the project owner's words in the current session → this file → the task plan → `docs/`. If you find a conflict, stop and report it; do not choose on your own.

## 3. Sources of truth

| To learn | Read |
|---|---|
| What to do in this task | The plan in `docs/superpowers/plans/` |
| Decisions behind the current plan | The spec in `docs/superpowers/specs/` |
| Progress, decisions, and manual checks of a phase run | `docs/superpowers/runs/` |
| Sentences the quick-entry reader must read or refuse | `docs/08-quick-entry-samples.md` |
| What the system must do exactly | `docs/03-srs.md` |
| Source structure, layers, and dependency rules | `docs/04-sad.md` |
| Chosen technologies and reasons | `docs/04-adr.md` |
| Tables, columns, and constraints | `docs/05-database-design.md` |
| Endpoints and error format | `docs/05-api-spec.md` |
| Screens, colors, typography, imagery, and behavior | `docs/06-ux-ui/user-flows.md` |
| Naming and code style | `docs/agents/quy-uoc-code.md` |

Do not modify anything in `docs/` or this file unless you are acting as the advisor. The one exception: during a phase run the implementation agent writes the run files under `docs/superpowers/runs/`.

## 4. Required workflow

Every task follows exactly six steps. Full instructions are in the `execute-task` skill (`.agents/skills/execute-task/SKILL.md`).

1. **Read.** Read the task, the documents it references, and existing code where you will work.
2. **Think.** Before writing code, write three to six lines stating which files will change, how, and why it is the simplest approach. If there are two worthwhile approaches, name both and choose one.
3. **Do.** Write code according to `docs/agents/quy-uoc-code.md`. Touch only what the task requires.
4. **Self-check.** Run `pnpm check`; exercise the feature; perform the security review using `security-review`.
5. **Report.** Follow the skill's report template, including manual-check steps for the project owner.
6. **Stop.** Do not move to the next task until it is approved.

In a phase run, steps 5 and 6 change as section 12 describes.

## 5. May decide and must ask

| May decide; record it in the report | Must ask and receive approval first |
|---|---|
| Local variable names and helper function names within one file | Add, remove, or make a major-version change to any library |
| How to split a long file into smaller files in the same directory | Add, rename, or move a directory; change package structure |
| Implementation details inside a function | Change anything users see: layout, color, text, wording, or behavior |
| Log messages | Add or change an endpoint, table, column, constraint, or environment variable |
| | Change the name, type, or behavior of anything specified by the plan |
| | Change tooling, lint configuration, TypeScript configuration, or a `package.json` script |
| | Anything outside the task scope, including incidental bug fixes |

When asking, state the problem, two or three options with each cost, and the option you prefer. A library proposal must include what it solves, why it cannot be written in a few dozen lines, its license, maintenance level, and the size it adds.

If you see an out-of-scope bug or concern, record it under “Out of scope” in the report. Do not fix it yourself.

In a phase run the “must ask” column becomes “decide and record”, as section 12 describes.

## 6. Checks: do not write automated tests

The project **does not write automated tests** (no unit, integration, end-to-end, or snapshot tests). The project owner manually checks after every task and milestone. Do not install a test library or create `*.test.*` or `*.spec.*` files, even if you think they would help.

Because there are no tests to rely on, these four activities are mandatory:

- **Automated gate.** `pnpm check` (type checking and linting) must pass completely before reporting completion. Do not use `any`, `@ts-ignore`, `@ts-expect-error`, `biome-ignore`, or `!` to make it pass.
- **Let the machine catch errors.** Use strict types, Zod schemas at every boundary (HTTP requests, environment variables, external data), and database constraints. Invalid states should be unrepresentable rather than checked everywhere.
- **Exercise it yourself.** Run the feature yourself (call endpoints with `curl`, open the page in a browser if available) and paste the real result into the report. “It should work” is not a result.
- **Manual-check list.** Every report has numbered steps for the project owner: what to do, where, and what should be correct. Include normal and invalid cases (missing input, invalid input, lost access, double-clicking).

## 7. Writing code

Details and examples are in `docs/agents/quy-uoc-code.md`. These principles must not be violated:

- **Simplicity first.** Choose the approach with the fewest concepts that solves the problem correctly. Do not write for needs that do not exist; do not add abstractions, options, or configuration “for later.” Extract a shared function only after three similar sections exist.
- **Names replace comments.** Function, variable, and file names must be sufficient to understand the code without comments. Comments explain *why* (a constraint or unusual choice), not what the code does.
- **Small files and functions.** One responsibility per file. Reconsider when a file exceeds 200 lines, a function exceeds 40 lines, there are more than 3 parameters, or nesting exceeds 3 levels. Split it or explain the reason in the report.
- **Use patterns when justified.** Use a pattern when it makes today's code easier to read. Do not apply one just to look formal.
- **Follow existing code.** Before writing, search the repository for similar work and follow its approach. Do not create a second way to do the same thing.
- **Correct layers.** Routes contain no logic; business logic lives in services; queries live in `packages/db`; money logic lives only in `packages/core`; the web app does not calculate official figures itself.
- **Money is integer-only.** Do not use floating-point numbers anywhere along the money path.

## 8. Technology

- Use the **latest stable** versions of libraries already selected in `docs/04-adr.md`. Do not use beta, canary, or rc versions.
- **Do not rely on memory for library APIs.** Before using an API you are unsure about, read the documentation or source for the exact version installed in `node_modules`. Prefer the current approach; do not use APIs marked deprecated.
- Prefer built-in platform features (Web APIs, Node.js, Postgres, CSS) before considering a library.
- If you see a worthwhile new technology, propose it in the report with a concrete benefit for this project. Do not introduce it yourself.

## 9. Security

Security comes before speed and convenience. The full checklist is in `security-review`. Hard rules:

- **Secrets** (passwords, keys, session tokens, real connection strings) must not enter git, logs, error messages, or reports. Only `.env.example` with fake values may be committed.
- **All external data is untrusted:** request bodies, parameters, headers, cookies, and URL parameters. Validate with a Zod schema at the boundary before use.
- **Every endpoint with group data must authorize** through the shared authorization middleware. People outside the group receive 404, not 403.
- **Database queries** use Drizzle or parameterized statements only. Do not concatenate SQL strings.
- **Do not implement cryptography yourself.** Hash passwords, generate random values, and compare secrets with standard libraries or `node:crypto`.
- **Error responses** must not expose internal details (stack traces, SQL, file paths) or reveal whether an email has an account.
- **Web** must not use `dangerouslySetInnerHTML`, `eval`, or redirects to an unchecked address taken directly from a parameter.
- If you suspect a change weakens security, stop and ask.

## 10. Git

- One commit per task on the current branch, after `pnpm check` passes. Use the format `type(scope): short description`, where type is `feat`, `fix`, `chore`, `refactor`, or `docs`.
- Do not `push`, `--force`, rewrite history, use `--no-verify`, or change branches unless the project owner says so. A phase run happens on the branch its plan names; the advisor creates that branch and the project owner merges it.
- Do not commit build artifacts, `node_modules`, `.env`, or files outside the task scope.

## 11. Absolutely do not

- Do not report “done” when `pnpm check` has not passed or the feature has not been exercised.
- Do not invent results; clearly state when a step was not run and why.
- Do not delete or rewrite working code to “clean it up” when the task does not require it.
- Do not call external services, deploy, or create accounts anywhere.
- Do not use emoji in the UI or code.

## 12. Phase run

A phase run builds the phase named by its approved plan in one continuous agent run. Task 0 re-baselines all assumed interfaces and replays earlier acceptance gates before feature implementation. It applies only when the plan says so. The design and its reasons are in `docs/superpowers/specs/2026-11-12-phase-1-single-run-design.md` and ADR-018.

- **Roles.** The advisor writes the spec and the plan and reviews the finished branch. The implementation agent runs the plan from the first unticked task to the last without waiting for approval. The project owner approves the spec and the plan before the run, and checks by hand and merges after the review.
- **Per task.** The six steps of section 4 stay. The report is written into the run's `progress.md`, and the agent then continues with the next task instead of stopping. One commit per task; `pnpm check` passes before each commit.
- **Decide and record.** Whatever the spec and plan leave open, including the “must ask” column of section 5, the agent decides, records in the run's `decisions.md` (problem, options, choice, reason; for a library also license, maintenance, and added size), and continues. It never waits for an answer and never leaves a required piece unbuilt.
- **Not decisions.** Sections 6, 9, and 11, the integer-only money rule, and the rule that money is divided only in `packages/core` stay absolute. No external service, no account creation, no deployment, no push.
- **Stage gates.** After the last task of each stage the agent runs the gate defined in the plan: `pnpm check`, `pnpm build`, the acceptance scripts of this and all earlier stages on a reset database, `pnpm db:check-balances`, and the permission matrix. A failing gate is fixed until it passes; after three failed attempts on the same item it is recorded under “Gate not passed” and the run continues.
- **Honesty.** Anything the agent could not verify is listed under “Not verified”. A recorded result is the real output, never an expectation.
- **Review.** The advisor reads the decisions and failed gates first, re-runs every gate, reads the diff stage by stage, and returns findings by commit. Fixes are new commits on the same branch.
