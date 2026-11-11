---
name: execute-task
description: Use when assigned a task, plan step, bug fix, or any code change in Sòng Phẳng. Defines the six required steps from reading and thinking through implementation, self-checking, reporting, and stopping for approval, including the report and manual-check template.
---

# Execute a task

Follow the six steps in order. Do not skip any, even for a small change.

## Step 1 — Read

1. Read the complete task and the plan's “Global Constraints” section.
2. Read the sections of `docs/` referenced by the task.
3. Read existing code at the places you will change and places doing similar work. Follow the existing approach.
4. If the task touches UI, read the corresponding section of `docs/06-ux-ui/user-flows.md`.

If you do not understand the task or find a conflict with the documents, ask immediately at this step.

## Step 2 — Think, then write it down

Before editing any file, write to the requester:

```
Approach
- Files to create/modify: …
- Approach: … (two to four lines)
- Why this is the simplest approach: …
- Rejected alternative: … (if there is a worthwhile alternative)
- Questions: … (write “none” if there are no questions)
```

Ask yourself before writing this section:

- Is there a solution with less code and fewer concepts that remains correct?
- Does the platform or an existing library already provide this?
- Am I doing anything the task does not require?

If “Questions” includes an item from the “Must ask” column in section 5 of `AGENTS.md`, stop and wait for an answer. Otherwise continue.

## Step 3 — Do

- Follow `docs/agents/quy-uoc-code.md`.
- Use the file names, function names, and types specified by the plan.
- Touch only files needed by the task. Do not reformat, rename, or clean up elsewhere.
- If unsure about a library API, read the documentation or source for the exact version in `node_modules`; do not guess.
- Do not write automated tests.

## Step 4 — Self-check

Do all four activities, in order:

1. `pnpm check` must pass completely. Fix the cause; do not disable rules.
2. Exercise the actual change: call endpoints with `curl`, run commands, or open the page. Try the normal path and at least two invalid cases (missing data, invalid format, unauthenticated, unauthorized, or duplicate submission). Keep the real results.
3. Run the `security-review` security review skill.
4. Read your entire diff (`git diff`) as if someone else wrote it: check for oversized files, unclear names, unnecessary sections, and out-of-scope changes.

If the same issue still fails after three fixes, stop and report it; do not keep trying.

## Step 5 — Report

Commit according to section 10 of `AGENTS.md`, then send a report using this template:

```
Task <number> — <name>
Commit: <short hash>
pnpm check: passed / failed

Completed
- <one line per significant change>

Files created/modified
- <path>

Exercise results
- <command or action> → <actual result; paste the important part verbatim>

Manual checks for the project owner
1. <what to do and where> → correct result is <what>
2. …
(include invalid cases: do <what> → must see <message/behavior>)

Decisions
- <open plan choice you made; “none”>

Deviations from plan
- <what and why; “none”>

Not checked
- <what was not run and why; “none”>

Out of scope
- <bug or concern noticed but not fixed; “none”>
```

Rules for “Manual checks for the project owner”:

- Each step is a concrete action a person who has not read the code can perform: a command to paste, a URL to open, or a button to click.
- Each step states what the correct result looks like.
- Include at least one normal-path step and one step for each important invalid case.
- Use no more than ten steps per task; if more are needed, the task is too large.

## Step 6 — Stop

Do not start the next task. Wait for the reviewer to reply “pass” or provide changes. When asked to fix something, fix exactly those points, repeat step 4, make a separate commit, and report the changes.

## Stop and ask immediately when

- The plan and documents conflict.
- The task cannot be completed without changing a name, type, or behavior specified by the plan.
- You need a library, directory, endpoint, table, column, or environment variable not in the plan.
- You need to change something users see.
- A change could weaken security.
