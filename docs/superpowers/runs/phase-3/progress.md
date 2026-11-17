# Phase 3 run — progress

## Status

Date: 2026-11-18. Owner explicitly authorized continuous execution of Phase 3 from Task 0 through Task 3D.4 on branch `phase-3`, created from clean local `main` at `6b36336` (which includes Phase 2B correction `257fc50` and Phase 3 advisor preparation `6b36336`). The separate `songphang-ios-ui` worktree was not touched.

## Task checklist

- [x] Task 0 — re-baseline (`docs(run): re-baseline phase 3`)
- [x] 3A.1 — worker process, queue, event bridge, features endpoint
- [ ] 3A.2 — file storage and attachments API
- [ ] 3A.3 — attachments on transactions; cleanup job
- [ ] 3A.4 — web photos on the form and the stream; stage gate 3A
- [ ] 3B.1 — receipt reading schema and arithmetic check
- [ ] 3B.2 — receipt reader adapters, cost ledger, quotas
- [ ] 3B.3 — receipt scans endpoint, job, stage gate 3B
- [ ] 3C.1 — core items split
- [ ] 3C.2 — API items split method and items preview
- [ ] 3C.3 — web camera in entry bar and receipt review screen
- [ ] 3C.4 — stage gate 3C
- [ ] 3D.1 — sentence AI and parse fallback
- [ ] 3D.2 — core category suggestion
- [ ] 3D.3 — web AI readings on the confirmation card
- [ ] 3D.4 — README, non-functional checks, final gate 3D

## Baseline failures

None.

## Task 0 — approach

Create `phase-3` from clean local `main` (`6b36336`), verify advisor fixture hashes and inventory, map every existing file/interface referenced in the Phase 3 plan against the actual repository, and verify baseline `pnpm check`, `pnpm build`, representative Phase 1 + Phase 2 API acceptance checks, all 87 quick-entry samples, and `pnpm db:check-balances` on an isolated disposable database (`songphang_phase3_gate`) without modifying the owner's normal `songphang` database.

### Task 0 results

- Branch: `phase-3` created from `main` at `6b36336` (`257fc50` present in ancestry).
- Fixture SHA-256 verification:
  - `clean.jpg`: `bc85e8c5552a75663623313b0b39338f5f5c8f28adaa08651559d61882c29488`
  - `tax-service.jpg`: `2b9ffd2dd8727f349423e2d235497b29f8afbc67a59ea4865db7a50287103d15`
  - `mismatch.jpg`: `c74553a4087925e1fc370de6986128aaa8adb88d986428435f631f018112a113`
  - `not-a-receipt.jpg`: `bd894f40e6e8ecab5e4de335f166ed19774f1472d3129ffa25283e2d90715be4`
- `pnpm check`: passed (`Checked 324 files`, all 5 workspace typechecks Done).
- `pnpm build`: passed (`next build` compiled cleanly, all 11 static pages + dynamic routes built).
- Isolated DB `songphang_phase3_gate` migrate + seed: passed (`Migrations applied`, `Development users seeded`).
- Baseline API replay on port 4010 against `songphang_phase3_gate`: `GET /api/v1/features` returned 200 with all 6 booleans `false`; `/receipts` and `/auth/apple` returned 404; Phase 1 group/transaction/edit/409/settle, Phase 2A payment-methods/VietQR/settlement-request, Phase 2B categories/stats/`spendingOnly`/CSV BOM, Phase 2C fund create/parse, Phase 2D budget `near`, and permission checks (`403`/`404` matching random UUID/`401`) passed.
- Quick-entry baseline: all 87 samples (75 Phase 1 + 12 Phase 2 fund samples from `docs/08-quick-entry-samples.md`) passed against `@songphang/core`.
- `check-balances.ts` on `songphang_phase3_gate`: `All groups balanced`.

## Task 3A.1 — approach

- Files to create/modify: create `apps/worker/{package.json,tsconfig.json}`, `apps/worker/src/{main.ts,config.ts,queue.ts,notify.ts,jobs/heartbeat.ts}`, `packages/contract/src/jobs.ts`, `apps/api/src/{queue.ts,events/listen.ts}`; modify `packages/contract/src/index.ts`, `apps/api/src/{app.ts,server.ts,config.ts,routes/features.ts}`, `packages/db/drizzle.config.ts`, `package.json` (`dev`), `.env.example`, `README.md`.
- Approach: install `pg-boss` (latest stable) in `apps/worker` and `apps/api`. Define Zod job payload schemas (`JOB_NAMES`) in `packages/contract/src/jobs.ts`. Implement worker `PgBoss` startup, `registerJob`, `heartbeat` minute schedule, and `notifyGroup` (`SELECT pg_notify('songphang_events', $1)`). Implement API `enqueue(executor, name, data, options)` using `boss.send(..., { db })` bound to the caller's Drizzle `DbExecutor` transaction, and `listenForGroupEvents` on a dedicated `postgres` connection with 1s–30s exponential backoff reconnect forwarding validated payloads to `createEventHub`. Extend `GET /api/v1/features` from config (still returning all false at 3A.1).
- Why simplest: keeps queue contracts shared in `packages/contract`, uses `pg-boss`'s native custom `db` adapter (`executeSql`) with the existing `DbExecutor` transaction without introducing a separate outbox table unless the installed adapter fails transaction rollback verification.
- Rejected alternative: building a custom polling outbox table before testing `pg-boss` transactional `db` adapter support.

### Task 3A.1 results

- `pnpm check`: passed (`Checked 334 files`, all 6 workspace typechecks Done). `pnpm build`: passed.
- `pg-boss@12.38.2` `fromDrizzle(tx, sql)` test on `songphang_phase3_gate`: forced rollback left 0 rows in `pgboss.job`; committed tx persisted 1 job row.
- Live API + worker exercise: `GET /api/v1/features` returned `200` with all 6 booleans `false`; valid `SELECT pg_notify('songphang_events', ...)` delivered `event: changed` (`["transactions"]`, `["balances"]`) via SSE; malformed JSON and invalid schema triggered `Ignoring malformed group event notification` / `Ignoring invalid group event notification` without forwarding; after `docker compose restart db`, listener reconnected and delivered `["activity"]` via SSE; worker logged `{"event":"worker.heartbeat","at":"2026-11-17T17:09:29.836Z"}`; stopping worker left `GET /api/v1/features` answering `200`.
- Security review: checked items 1, 2, 4, 5, 6, 8; no secrets/raw payloads logged, Zod validation at `NOTIFY` boundary, parameterized `pg_notify`, approved `pg-boss@12.38.2` MIT with lockfile updated; no issues found.

## Not verified

- Real Anthropic API calls (forbidden by policy).
- Real phone camera chooser and real receipt accuracy/latency/cost (owner manual checks after implementation).

## Gate not passed

None.
