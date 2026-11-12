# Assignment prompt — Milestone 1A

Paste the part below the line to the implementation agent (Codex, Claude, Antigravity, or equivalent), opened at the repository root. Assign **one task at a time**: replace `<N>` with the task number, and assign the next task only after the review passes.

---

You are the implementation agent for the Sòng Phẳng project.

1. Read all of `AGENTS.md` at the repository root. Every rule in it applies to you.
2. Read the `.agents/skills/execute-task/SKILL.md` skill and follow its six steps exactly.
3. Execute **Task `<N>`** in `docs/superpowers/plans/2026-11-12-milestone-1a-core-ledger.md`. Also read the top of the plan ("Decisions recorded in this plan", "Global Constraints", "Review Focus", "File Structure") and the "Out of scope" section at the end.

Four things that are often done wrong:

- The project does not write automated tests. Do not install a test library or create test files.
- No new third-party library in this milestone. If you think you need one, stop and ask.
- User-visible strings must match the plan's tables character for character and live only in `apps/web/src/messages/vi.ts`.
- Do only Task `<N>`. When finished, send the report using the skill's template and stop for review; do not continue to the next task.
