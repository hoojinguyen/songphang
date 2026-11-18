# Phase 4 run — progress

## Status

Date: 2026-11-18. The owner approved the Phase 4 spec (including section 14, amendment 2026-11-18) and plan, and authorized continuous execution from Task 0 through Task 4D.4 on branch `phase-4`, created by the advisor from local `main` at `b3cf730`. Implementation agent: Antigravity. Advisor and reviewer: Claude. Checks with a real AI provider are deferred by the owner until all phases, including iOS, are done; use `AI_PROVIDER=fake` where the AI path is exercised.

## Task checklist

- [x] Task 0 — re-baseline (`docs(run): re-baseline phase 4`)
- [ ] 4A.1 — API: comments
- [ ] 4A.2 — API: disputes
- [ ] 4A.3 — Web: the transaction view; stage gate
- [ ] 4B.1 — Notification core
- [ ] 4B.2 — Web: bell and notification list
- [ ] 4B.3 — Mail: immediate, digest, unsubscribe
- [ ] 4B.4 — Debt reminders
- [ ] 4B.5 — Web: reminders and settings; stage gate
- [ ] 4C.1 — Webhook, sender, identities and links
- [ ] 4C.2 — Commands: `/chi`, `/sodu`, `/huy`, `/trogiup`
- [ ] 4C.3 — Web: linking screens
- [ ] 4C.4 — Stage gate 4C and the bot runbook
- [ ] 4D.1 — Database and money path: the approval filter
- [ ] 4D.2 — API: threshold, pending, approve, reject
- [ ] 4D.3 — Web: approval
- [ ] 4D.4 — README, non-functional checks, final gate

## Baseline failures

None.

## Not verified

## Gate not passed

## Task 0 — approach

- Confirm current branch is `phase-4`, run `pnpm check` and `API_ORIGIN=http://localhost:4010 pnpm build`.
- Reset disposable database `songphang_phase4_gate`, run `pnpm db:migrate` and `pnpm db:seed`.
- Replay representative baseline checks across Phases 1, 2, and 3 (including all 87 quick-entry samples from `docs/08-quick-entry-samples.md`, permission matrix, `GET /api/v1/features`, `pnpm db:check-balances`) against an isolated API/worker instance on port 4010 using `AI_PROVIDER=fake` where AI is exercised and unset for capability disabled checks.
- Map every file/function/table/route/component referenced by the Phase 4 plan against the actual repository in `docs/superpowers/runs/phase-4/decisions.md`, record outputs in `progress.md`, tick Task 0, and commit `docs(run): re-baseline phase 4`.

### Task 0 results

- Branch: `phase-4` (`git branch --show-current` confirmed).
- Earlier phases on `main` (`b3cf730`): Phase 0, Phase 1 (1A–1E), Phase 2 (2A–2D + `257fc50`), Phase 3 (3A–3D + `5c27dea`, `ed086fa`, `e70095b`, `c99a7fc`). Server step not merged (`infra/compose.prod.yml` absent).
- `pnpm check`: passed (`Checked 400 files`, all 8 workspace typechecks Done).
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`next build` compiled cleanly, 11 static pages + dynamic routes built).
- Disposable DB `songphang_phase4_gate` reset, migrated, and seeded: passed (`Migrations applied`, `Development users seeded`); owner `songphang` DB untouched.
- Disabled capabilities check (`AI_PROVIDER` and `TELEGRAM_PROVIDER` unset): `DISABLED_FEATURES_CHECK_PASSED {"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false}`; `POST /receipt-scans` returned `404`.
- Baseline replay on `songphang_phase4_gate` (API on port 4010 + worker with `AI_PROVIDER=fake`): `PHASE_1_2_3_BASELINE_REPLAY_PASSED` (dev login, invite/join, viewer 403 / outsider 404 / unauth 401, tx create/edit/409/delete/restore, VietQR, settlement confirm, categories, budget `near`, stats `200000`, `spendingOnly=true`, UTF-8 BOM CSV export, fund, attachment upload & magic-byte validation, fake receipt scan `done`, `items/preview` `targetAdjustment: { kind: "other", amount: 8000 }`, sentence AI parse `ai: false` -> `rules` & `ai: true` -> `ai`).
- Quick-entry baseline: `ALL_87_QUICK_ENTRY_SAMPLES_PASSED` (75 Phase 1 + 12 Phase 2 fund samples from `docs/08-quick-entry-samples.md`).
- `pnpm db:check-balances` on `songphang_phase4_gate`: `All groups balanced` (`Disabled Probe: sum 0; mismatches 0`, `Đà Lạt 12/2026: sum 0; mismatches 0`).
