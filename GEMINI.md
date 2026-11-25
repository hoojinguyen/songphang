# Sòng Phẳng

The project's working rules are in the root `AGENTS.md` and are shared by every agent. Read that entire file before doing anything and follow it.

Project-wide skills live in `.agents/skills/`. Antigravity-only orchestration skills live in `.agent/skills/`.

## Antigravity Auto-Routing (Natural-Language Workflow)

The project owner prefers prompting in natural language without manually naming skills or slash commands. Automatically select and read the relevant skill when a request matches:

- **New feature, non-trivial change, or wave design** (before a spec or plan is approved): read and follow `.agent/skills/sp-feature/SKILL.md` (which chains `superpowers:brainstorming` -> spec approval -> `superpowers:writing-plans` formatted for `/swarm`).
- **Writing an implementation plan from an approved spec**: read `.agent/skills/songphang-swarm-orchestrator/SKILL.md` and follow its `Swarm-Ready Plan Checklist` (`AGENTS.md` §6 exercise steps instead of automated tests; Antigravity `/swarm` as the supplied execution method).
- **Executing an approved plan with `/swarm` or `run_workflow`**: read `.agent/skills/songphang-swarm-orchestrator/SKILL.md` and its `references/swarm-briefs-and-workflow.md`, together with `.agents/skills/execute-task/SKILL.md`, `.agents/skills/security-review/SKILL.md`, and `.agents/skills/review-code/SKILL.md`. Never call `swarm` unless the user explicitly invoked `/swarm` or a swarm is already active.
- **Handling `429` quota exhaustion or resuming an active `/swarm`**: keep paused workers `waiting`/`stopped` (never `kill` unlanded worktrees and never auto-downgrade coding worker models without owner instruction). When the owner resumes (e.g., "tiếp tục", "quota đã hồi"), immediately run the `Quota & Recovery Protocol` in `.agent/skills/songphang-swarm-orchestrator/SKILL.md` (`status` -> check `progress.md`/worktree `git log` -> land finished commits -> `@mention` workers to resume; call `swarm` `action: "model"` only if the owner explicitly asks to switch models).
