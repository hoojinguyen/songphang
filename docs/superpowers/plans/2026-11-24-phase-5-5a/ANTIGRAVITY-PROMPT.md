# Antigravity Handoff — Sòng Phẳng Wave 5.5A (UI/UX v2 & Cross-Group Foundation)

You are the implementation agent for Sòng Phẳng Wave 5.5A. The project owner approved the Phase 5.5 overview design, the Wave 5.5A design spec, and this implementation plan on 2026-11-24. Codex is the advisor and reviewer. The project owner performs physical iPhone and Web Desktop acceptance and decides merge.

1. Read the root `AGENTS.md`, `apps/ios/AGENTS.md`, and repository skills `.agents/skills/execute-task/SKILL.md` and `.agents/skills/security-review/SKILL.md` in phase-run mode.
2. Read the approved design specs:
   - `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md`
   - `docs/superpowers/specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md`
   - `docs/superpowers/specs/2026-11-16-ios-codebase-architecture-design.md`
3. Read `docs/superpowers/plans/2026-11-15-common.md` and `docs/superpowers/plans/2026-11-24-phase-5-5a/00-overview.md`.
4. Verify `git branch --show-current` is `phase-5-5a` and `main` (`378df4d` or newer) is an ancestor. If the branch does not exist or is wrong, stop and report the workspace issue; do not create branches or modify `main`.
5. Open `docs/superpowers/runs/phase-5-5a/progress.md`. Start from the first unchecked task (initially `Task 0` in `5-5a-1-api-and-db.md`). Read each stage file completely before starting its first task. Implement, verify, record real observed results and decisions, and make one scoped commit per task after applicable checks pass.
6. Proceed continuously through `5.5A.1`, `5.5A.2`, `5.5A.3`, `5.5A.4`, and `5.5A.5`. At `5.5A.5.2`, complete the full parity replay, Release bundle audit, security review, and owner manual-check handoff in `docs/superpowers/runs/phase-5-5a/manual-checks.md`, then stop and report the final branch SHA, run evidence, any failed/unavailable checks, and owner verification steps.

Strict rules:
- No automated tests, test libraries, or committed test scripts (`AGENTS.md` §6).
- Strictly additive `/api/v1` contract (`pnpm contract:check` passes; `0` breaking OpenAPI changes).
- Integer-only VND money (`sum(myDelta ?? 0) === myBalance`; `pnpm db:check-balances` passes; no float/multiply/divide on `Money`, including in "Bơm hình").
- Enforce compiler module boundaries in `apps/ios/SongPhangKit/Package.swift` (`OverviewFeature` imports only `Domain`, `DesignSystem`, `PreviewSupport`; 3-segment `GroupContainerView` lives in `AppShell`).
- Never use `dangerouslySetInnerHTML` on Web (use static `apps/web/public/theme-init.js`).
- Zero emoji anywhere; `./apps/ios/Scripts/check-strings.sh` passes (`0 missing, 0 differing`).
- Never push, merge, deploy, or contact live external services. Do not modify standing docs owned by the advisor (`docs/03-srs.md`, `docs/05-*`, `docs/06-*`, `docs/07-roadmap.md`, `docs/tech-debt.md`); record needed updates in `decisions.md` and `manual-checks.md`.
