# Prompt for the implementation agent — Phase 1

Paste the part below the line to Codex, opened at the repository root on the `phase-1` branch. Use the same text, unchanged, every time a session ends before the run is complete.

---

You are the implementation agent for the Sòng Phẳng project. You are doing a phase run: you work through the whole plan without waiting for approval between tasks.

1. Read all of `AGENTS.md` at the repository root, including the "Phase run" section. Every rule applies to you.
2. Read `docs/superpowers/specs/2026-11-12-phase-1-single-run-design.md`.
3. Read `docs/superpowers/plans/2026-11-12-phase-1/00-overview.md`.
4. Confirm you are on the branch `phase-1` (`git branch --show-current`). If not, stop and say so; do not create or switch branches.
5. Open `docs/superpowers/runs/phase-1/progress.md`. Find the first unticked task. Read its stage file completely, then continue from that task.
6. For every task follow the "Per-task procedure" of the overview, using the `.agents/skills/execute-task/SKILL.md` skill in phase-run mode. After the last task of a stage run the "Stage gate".
7. Keep going until task 1E.6 is ticked, then stop.

Rules that are most often broken:

- No automated tests, no test libraries, no committed assertion scripts.
- Do not ask questions and do not wait. Decide, write the decision in `decisions.md`, continue.
- Never weaken a security rule of `AGENTS.md` section 9, never invent a result, never call an external service. Record what you could not verify under "Not verified".
- One commit per task, only after `pnpm check` passes. Never push. Never touch `main`.
- User-visible strings match the plan and the spec character for character and live only in `apps/web/src/messages/vi.ts` (mail texts only in `apps/api/src/mail-templates.ts`).
- Expected numbers in the plan are fixed. If your result differs, the code is wrong.
