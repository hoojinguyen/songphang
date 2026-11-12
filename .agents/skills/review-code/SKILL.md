---
name: review-code
description: Use when asked to review a commit, completed task, or implementation-agent report in Sòng Phẳng. Defines how to compare the diff with the plan and project rules, the checking order, and the “pass” or changes-needed conclusion.
---

# Review a task

The reviewer reads the **actual code**, not only the report. The report says what the agent thinks it did; the diff says what happened.

## Preparation

1. Read the task in the plan and the “Global Constraints” section.
2. Get the diff: `git show <commit>` or `git diff <previous commit>..<commit>`.
3. Run `pnpm check` on that commit. If it fails, stop the review and return it.

## Checking order

Check in this order; an issue in an earlier section is more serious than one below it.

### 1. Correctness

- Everything required by the task is in the diff, with the exact file names, function names, and types stated in the plan.
- Behavior matches the specification: status codes, error format, field names, and database constraints.
- Re-run at least two items from the report's “Exercise it yourself” section and compare the results. A result that differs from the report is a serious issue.

### 2. No extras

- No file, endpoint, table, column, option, or library outside the task.
- In `package.json` and `pnpm-lock.yaml`, every new dependency has approval.
- No test files and no test library.
- No UI changes beyond what the task and design documents describe.
- No changes to `docs/`, `AGENTS.md`, lint configuration, or TypeScript configuration.

### 3. Safety

Run the `security-review` skill on the diff.

### 4. Readability

Follow `docs/agents/quy-uoc-code.md`:

- Function, variable, and file names are self-explanatory; no abbreviations; correct business vocabulary.
- For files over 200 lines, functions over 40 lines, more than 3 parameters, or nesting over 3 levels: is there a reason?
- Code is in the correct layer: routes have no logic, the web app does not calculate money, and queries are in `db`.
- No `any`, forced `as` casts, `!`, `@ts-ignore`, or disabled lint rules.
- Comments explain why, not what the code repeats; no commented-out code.
- No second approach to something the repository already does.

### 5. Simplicity

- Is there an abstraction, parameter, or configuration with no current use?
- Could any part use a built-in feature of the platform or an existing library instead?
- Is a deprecated library API used when the installed version has a newer approach?

## Conclusion

Reply using exactly one of these templates.

```
Task <number>: PASS
Notes (non-blocking): <optional>
```

```
Task <number>: CHANGES NEEDED

Must fix
1. <file:line> — <issue> — <how to fix>

Should fix
1. <file:line> — <issue> — <suggestion>

Questions for the project owner
1. <if the project owner must decide something>
```

- “Must fix”: incorrect plan or specification, security vulnerability, out-of-scope work, or violation of `AGENTS.md`.
- “Should fix”: more readable or simpler but not incorrect.
- Each item must identify exactly one code location and clearly state how to fix it. Do not write vague general comments.
- Do not fix code while reviewing unless the project owner asks.

## Reviewing a phase run

Use this order when asked to review the branch of a phase run (`AGENTS.md` section 12) instead of a single task.

1. **Read the run files first:** `decisions.md`, then “Gate not passed”, “Unresolved”, and “Not verified” in `progress.md`. Every decision is either confirmed, or becomes a finding or a question for the project owner.
2. **Re-run every gate yourself** on a reset database: `pnpm check`, `pnpm build`, each stage's acceptance script, `pnpm db:check-balances`, and the permission matrix. Do not trust recorded results; a result that differs from the record is a serious finding.
3. **Read the diff stage by stage** (`git log --oneline main..<branch>`, then per-task commits), applying the checking order above. Spend the most time where manual checking is weakest: the money layer (`packages/core`, database triggers, rounding), authorization on every `groupId` route, and accounts (password hashing, single-use tokens, no account enumeration, session revocation).
4. **Check the plan was followed, not improved:** strings character for character, expected numbers unchanged, no library beyond the approved ones without a `decisions.md` entry, no test files.
5. **Conclude per stage** with the templates above, using `Stage <id>` in place of `Task <number>` and giving each finding the commit hash as well as `file:line`. Add a final section “Decisions for the project owner” listing each `decisions.md` entry with confirm or change.

Findings are fixed by the implementation agent in new commits on the same branch; review those commits again before the project owner's manual check.
