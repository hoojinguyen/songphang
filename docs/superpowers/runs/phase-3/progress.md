# Phase 3 run — progress

## Status

Date: 2026-11-18. Owner explicitly authorized continuous execution of Phase 3 from Task 0 through Task 3D.4 on branch `phase-3`, created from clean local `main` at `6b36336` (which includes Phase 2B correction `257fc50` and Phase 3 advisor preparation `6b36336`). The separate `songphang-ios-ui` worktree was not touched.

## Task checklist

- [x] Task 0 — re-baseline (`docs(run): re-baseline phase 3`)
- [x] 3A.1 — worker process, queue, event bridge, features endpoint
- [x] 3A.2 — file storage and attachments API
- [x] 3A.3 — attachments on transactions; cleanup job
- [x] 3A.4 — web photos on the form and the stream; stage gate 3A
- [x] 3B.1 — receipt reading schema and arithmetic check
- [x] 3B.2 — receipt reader adapters, cost ledger, quotas
- [x] 3B.3 — receipt scans endpoint, job, stage gate 3B
- [x] 3C.1 — core items split
- [x] 3C.2 — API items split method and items preview
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

## Task 3A.2 — approach

- Files to create/modify: create `apps/api/src/storage/{file-store,disk-file-store,sniff}.ts`, `packages/db/src/{schema-attachments,attachments}.ts`, `packages/contract/src/attachment.ts`, `apps/api/src/services/attachments.ts`, `apps/api/src/routes/attachments.ts`, and a Drizzle migration; modify `apps/api/src/{config,app,server,rate-limit}.ts`, `packages/contract/src/{error,index}.ts`, `packages/db/{drizzle.config.ts,src/index.ts}`, `.env.example`, `.gitignore`.
- Approach: add `FileStore`, `diskFileStore` (enforcing `{groupId}/{uuid}` regex and resolved root prefix + atomic temp-file rename), and magic-byte `sniffImageType` (JPEG/PNG/WebP). Add `attachments` table with checks and `STORAGE_QUOTA_EXCEEDED` error code. Resolve `STORAGE_DIR` against the repo root in config. Bypass the global 100 KiB `bodyLimit` only for `POST .../attachments` and enforce a route-specific 6 MiB actual streaming body bound before `formData()` parsing (rejecting oversized `Content-Length` or actual streamed bytes with 413 regardless of header). Serialize group quota checks, storage write, DB insert, and deletion under `lockGroup` with a fresh role check. Serve content with stored `Content-Type`, `X-Content-Type-Options: nosniff`, `Content-Disposition: inline; filename="hoa-don.jpg"`, and `Cache-Control: private, no-store`.
- Why simplest: reuses `lockGroup`, `getGroupAccess`, `createRateLimiter`, and native `Request.formData()` without adding multipart dependencies.
- Rejected alternative: trusting Hono's built-in `bodyLimit`, which skips streaming byte counting whenever a client supplies a small `Content-Length` header.

### Task 3A.2 results

- `pnpm check`: passed (`Checked 344 files`, all 6 workspace typechecks Done). Migration `0010_mean_ben_grimm.sql` generated and applied.
- Real HTTP & storage exercises on isolated DB `songphang_phase3_gate` and API 4010:
  - Lan (editor) uploaded JPEG -> `201` (`contentType: image/jpeg`); `GET .../content` -> `200` with identical SHA-256, `X-Content-Type-Options: nosniff`, `Cache-Control: private, no-store`, `Content-Disposition: inline; filename="hoa-don.jpg"`.
  - Hùng (viewer) `GET .../content` -> `200`; Hùng upload -> `403`. After removing Hùng from group, `GET .../content` -> `404`.
  - Outsider `GET .../content` -> `404` matching random UUID; owner of another group `GET /groups/{theirGroup}/attachments/{thisId}/content` -> `404`.
  - PNG declared as `image/jpeg` -> `201` stored `image/png`; WebP -> `201` `image/webp`; `x.jpg` text -> `400 not_an_image`; 5.1 MB JPEG -> `400 too_large`; 7 MB Content-Length & chunked stream -> `413`; part named `photo` -> `400`; 120 KiB JSON to `/transactions` -> `400` (100 KiB global limit preserved).
  - Delete -> `204`, subsequent `GET` -> `404`, file removed from `STORAGE_DIR`; `diskFileStore.put("../../etc/x", ...)` threw.
  - Parallel 4×5 MiB uploads at 190 MiB group usage -> `[201, 201, 422, 422]` (`STORAGE_QUOTA_EXCEEDED`); 31st upload by user in an hour -> `429`.
- Security review: checked items 1, 2, 3, 4, 5, 6, 8; no issues found.

## Task 3A.3 — approach

- Files to create/modify: create `packages/storage/{package.json,tsconfig.json,src/{index,file-store,disk-file-store,sniff}.ts}`, `apps/worker/src/jobs/{cleanup-attachments,delete-files}.ts`; remove `apps/api/src/storage/`; modify `apps/api/package.json`, `apps/worker/{package.json,src/{config,queue,main}.ts}`, `packages/contract/src/{transaction,jobs}.ts`, `packages/db/src/{attachments,groups}.ts`, `apps/api/src/services/{transactions,transaction-changes,groups}.ts`, `apps/web/src/components/{feed/{ExpenseRow,LedgerPill}.tsx,balances/AllSettled.tsx}`.
- Approach: extract `FileStore`, `diskFileStore`, and `sniffImageType` into `@songphang/storage` so API and worker share one implementation and storage root resolution (`STORAGE_DIR` resolved from repo root). Add `attachmentIds` (0–3 unique UUIDs) to transaction create/edit, returning `attachments` on `TransactionDto` and `attachmentCount` on `TransactionListItemDto`. Validate ownership and unattached/self-attached state inside `lockGroup`, delete removed attachment rows+files on edit, keep files across soft delete/restore, and enqueue `delete-files` inside `deleteGroup`'s transaction with keys read before cascade. Implement `cleanup-attachments` (03:30 Asia/Ho_Chi_Minh) coordinating with `lockGroup` and enforcing a 24-hour age floor before deleting unattached DB rows or untracked/temp disk files.
- Why simplest: shares `@songphang/storage` without duplicating disk path validation across apps, and coordinates DB/disk cleanup under the existing `lockGroup` advisory/row lock.
- Rejected alternative: duplicating `diskFileStore` in `apps/worker/src/storage.ts`, which risks storage path/validation drift between API and worker.

### Task 3A.3 results

- `pnpm check`: passed (`Checked 349 files`, all 7 workspace typechecks Done).
- Extracted `@songphang/storage` (`packages/storage`) and verified API + worker `loadConfig` resolve `./.data/uploads` identically to `<repoRoot>/.data/uploads`.
- Real HTTP & worker exercises on `songphang_phase3_gate` (API 4010 + worker):
  - Created expense with 2 uploaded attachments -> `201` (`attachments` length 2); `GET /transactions` returned `attachmentCount: 2` without `attachments`.
  - Reuse attached ID, 4 IDs, and cross-group ID each returned `400`.
  - Edited transaction keeping only first ID -> `200` (`version: 2`, 1 attachment), second attachment's DB row and disk file removed.
  - Soft-deleted then restored transaction -> attachment row and disk file remained intact (`1` attachment).
  - `runCleanupAttachments`: 25h unattached row+file deleted, 1h unattached row+file preserved, fresh untracked/temp files preserved, >24h untracked and `.tmp-*` files deleted.
  - Deleted group with attachments -> worker executed `delete-files` and removed all remaining files from disk.
- Security review: checked items 1, 2, 4, 5, 6, 8; no issues found.

## Task 3A.4 — approach

- Files to create/modify: create `apps/web/src/lib/{prepare-image,attachments}.ts`, `apps/web/src/components/ui/PhotoViewer.tsx`, `apps/web/src/components/expense-form/PhotoRow.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/components/ui/Icon.tsx`, `apps/web/src/lib/transaction-changes.ts`, `apps/web/src/components/expense-form/{use-expense-form,ExpenseForm}.tsx`, `apps/web/src/components/feed/{ExpenseRow,ExpenseStream}.tsx`, `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx`.
- Approach: add `prepareImage` (`createImageBitmap` with `imageOrientation: "from-image"`, longest side ≤ 2000 px, JPEG 0.85) and `uploadAttachment` preserving server error codes/details. Build `PhotoViewer` as a native modal `<dialog>` (`showModal()`, Escape, backdrop click, close button, focus restoration) and `PhotoRow` (64×64 thumbnails, add/remove controls, 3-photo limit `Tối đa 3 ảnh.`, uploading and error states). Wire `attachmentIds` into `useExpenseForm` and `transactionRequestOf` so edits detect photo-only changes and delete removed photos on save. Show a small photo icon on `ExpenseRow` when `attachmentCount > 0`, and allow viewers to open transactions with photos in read-only detail to view images without any add/remove/edit controls.
- Why simplest: reuses native `<dialog>`, existing `ApiError` error-parsing pattern, and existing `ExpenseForm` dirty/mutation lifecycle without extra client stores.
- Rejected alternative: uploading/deleting immediately on remove click before Save, which would destroy existing transaction photos if the user cancels editing.

### Task 3A.4 results

- `pnpm check`: passed (`Checked 353 files`, 2 `noImgElement` warnings for `<img>` content URLs as specified, all 7 workspace typechecks Done). `pnpm build`: passed.
- Browser exercise on production Next.js 3010 + API 4010 + worker (`Ảnh 3A.4` group):
  - Selecting `fake.jpg` (`"not an image"`) showed `Chỉ nhận ảnh JPG, PNG hoặc WebP.` without uploading.
  - Selecting a 4000×3000 (12MP) JPEG resized it via `prepareImage` to `2000×1500` (`f1RawSize: 106370` bytes) and rendered 64×64 thumbnails (`rounded-[16px]`).
  - Saved expense with 2 photos -> stream showed `Có ảnh hoá đơn` + `2`. Reopened -> added 3rd photo -> showed `Tối đa 3 ảnh.`; removed 2 -> saved -> stream showed 1 photo (`Có ảnh hoá đơn`, `đã sửa`).
  - In isolated viewer session (Hùng), live SSE updated stream; clicking the expense opened read-only detail with `Ảnh hoá đơn` and `Xem ảnh hoá đơn` buttons (no `Thêm ảnh`, remove, save, or delete controls); clicking opened `PhotoViewer` modal `<dialog>`; `Escape` closed it and restored focus.
- Security review: checked items 1, 2, 4, 6, 7, 8; no issues found.

## Stage gate 3A — passed

- `pnpm check` (353 files, 7 workspace typechecks) and `API_ORIGIN=http://localhost:4010 pnpm build` passed.
- Isolated DB `songphang_phase3_gate` reset, migrated, and seeded cleanly.
- `baseline_gate.mjs`: Phase 1 + Phase 2 acceptance + `GET /api/v1/features` all-false + disabled 404 probes + permission checks passed.
- `verify_87_samples.ts`: all 87 quick-entry samples (75 Phase 1 + 12 Phase 2) passed.
- `exercise_3a2.mts`: attachment upload/read/delete, magic-byte sniffing, chunked 7 MB 413, parallel 200 MiB quota serialization, access removal 404, 30/hr rate limit, cross-group 404 passed.
- `exercise_3a3.mts`: transaction `attachmentIds`, `TransactionListItemDto.attachmentCount`, attachment edit deletion, soft-delete/restore preservation, 24h cleanup grace period, group delete `delete-files`, shared `STORAGE_DIR` resolution passed.
- `test_pgboss_tx.mts`: `pg-boss@12.38.2` `fromDrizzle(tx, sql)` transactional enqueue & rollback proof passed (ready for Stage 3B).
- `check-balances.ts`: `All groups balanced`.

## Task 3B.1 — approach

- Files to create/modify: create `packages/contract/src/receipt.ts`, `packages/core/src/receipt.ts`; modify `packages/contract/src/index.ts`, `packages/core/src/index.ts`.
- Approach: define `ReceiptReading`, `ReceiptFlag`, `ReceiptScanDto`, `ReceiptScanResponse`, and `CreateReceiptScanRequest` in `packages/contract/src/receipt.ts` with integer bounds `0..999_999_999_999`, string trimming, and unknown-key stripping. Implement pure `checkReceipt(reading)` in `packages/core/src/receipt.ts` computing `computed = Σ items.amount + Σ extras(tax, service, other).amount − Σ extras(discount).amount` with safe integer arithmetic and emitting `NOT_A_RECEIPT`, `NO_ITEMS`, `TOTAL_MISSING`, and `TOTAL_MISMATCH` exactly per spec 5.4 and Stage 3B Decision 1.
- Why simplest: keeps `packages/core` dependency-free with one pure function and shares exact Zod schemas across contract, API, worker, and web.
- Rejected alternative: duplicating validation or arithmetic checks in worker job handlers.

### Task 3B.1 results

- `pnpm check`: passed (`Checked 355 files`, all 7 workspace typechecks Done).
- `exercise_3b1.mts`: all 6 `checkReceipt` table rows matched (`442000 []`, `442000 ["TOTAL_MISMATCH"]`, `442000 ["TOTAL_MISSING"]`, `0 ["NO_ITEMS","TOTAL_MISMATCH"]`, `failed NOT_A_RECEIPT`, `110000 []`); invalid `12.5`, `"12000"`, 61 items, and `kind: "tip"` each failed Zod parsing; trimming and unknown-key stripping verified; all 4 advisor fixture JSONs (`clean`, `tax-service`, `mismatch`, `not-a-receipt`) matched `manifest.json`; `z.toJSONSchema(ReceiptReading, { unrepresentable: "any" })` produced valid object JSON Schema.
- Security review: checked items 1, 2, 8; strict integer bounds and safe-integer checks, no secrets or dependencies; no issues found.

## Task 3B.2 — approach

- Files to create/modify: create `packages/core/src/ai-quota.ts`, `packages/db/src/{schema-ai,ai-calls}.ts`, a Drizzle migration, `apps/worker/src/ai/{receipt-reader,anthropic-receipt-reader,fake-receipt-reader,anthropic-client,prompts/receipt}.ts`; modify `packages/core/src/index.ts`, `packages/db/{drizzle.config.ts,src/index.ts}`, `apps/worker/src/config.ts`, `apps/api/src/{config,routes/features}.ts`, `.env.example`.
- Approach: add `quotaWindowStarts` (Vietnam calendar day/month starts) in `core/ai-quota.ts`. Add `ai_calls` table with lifecycle states (`reserved`, `started`, `finished`), `started_at`, `finished_at`, and indexes, plus `countAiCalls`, `reserveAiCall` (serialized with `pg_advisory_xact_lock` inside a transaction/savepoint), `claimAiCall`, `finishAiCall`, and `recordAiCall`. Add `AI_*` config variables and production/fake-fixture startup guards in both API and worker configs, and expose `features.receiptReading` from API config. Implement `anthropicMessages` (single 30s attempt covering fetch and body JSON parse, no internal retry, safe status/type-only error logging), `anthropicReceiptReader` (base64 image block + forced `record_receipt` tool with `z.toJSONSchema(ReceiptReading)`), and `fakeReceiptReader` (SHA-256 lookup against `manifest.json` + `AI_FAKE_RECEIPT_FIXTURE` override + default 3-item fallback).
- Why simplest: keeps transport single-attempt so the job orchestrator controls every retry reservation, and enforces quota atomically across concurrent callers via `pg_advisory_xact_lock`.
- Rejected alternative: letting HTTP transport retry internally, which could trigger an unreserved second provider call past the daily or monthly ceiling.

### Task 3B.2 results

- `pnpm check`: passed (`Checked 364 files`, all 7 workspace typechecks Done). Migration `0011_fancy_maginty.sql` generated and applied to `songphang_phase3_gate`.
- `exercise_3b2.mts`:
  - Fake receipt reader verified all 4 advisor fixtures (`clean` -> `done` `440000 []`, `tax-service` -> `done` `110000 []`, `mismatch` -> `done` `442000 ["TOTAL_MISMATCH"]`, `not-a-receipt` -> `failed NOT_A_RECEIPT`), override selection, and 3-item fallback (`180000`).
  - Parallel 25 `reserveAiCall` calls with daily limit 20 produced `ok=20, user_limit=5`; monthly limit 10 across two users produced `ok=10, month_limit=2`.
  - Worker/API startup config guards rejected missing `ANTHROPIC_API_KEY` (without leaking secret values), `AI_PROVIDER=fake` in production, and `AI_FAKE_RECEIPT_FIXTURE` with `anthropic` or in production; `GET /api/v1/features` returned `receiptReading: false` when unset and `true` when `AI_PROVIDER=fake`.
  - Stubbed `fetch` Anthropic adapter sent single `POST` with `x-api-key`, `anthropic-version: 2023-06-01`, forced `record_receipt` tool schema, returned `50000` VND + usage counts, and surfaced 429 as `AnthropicTransportError` (`retryable: true`) with 1 attempt and no leaked API key.
- Security review: checked items 1, 2, 4, 8; no secrets logged or thrown, Zod validated env and response payloads, atomic advisory lock on quota checks; no issues found.

## Task 3B.3 — approach

- Files to create/modify: create `packages/db/src/{schema-scans,receipt-scans}.ts`, Drizzle migration `0012_clumsy_ravenous.sql`, `apps/api/src/{services,routes}/receipt-scans.ts`, `apps/worker/src/jobs/read-receipt.ts`; modify `packages/contract/src/{error,jobs}.ts`, `packages/db/{drizzle.config.ts,src/{schema-ai,ai-calls,index}.ts}`, `apps/api/src/app.ts`, `apps/worker/src/{queue,main}.ts`.
- Approach: add `receipt_scans` with `UNIQUE (attachment_id)`, `ai_calls.receipt_scan_id` FK (`ON DELETE SET NULL`), `AI_QUOTA_EXCEEDED`, and `JOB_NAMES.readReceipt`. Under `runIdempotent`, `lockGroup`, and a single DB transaction, return any existing scan (`200`) before reserving quota; otherwise reserve `ai_calls`, insert `queued` scan, link reservation, and enqueue atomically (`201` + `receiptScans` SSE event). Worker `read-receipt` atomically claims `reserved -> started` after verifying purpose/caller/group/scan ownership and current quota window, rejects expired or crashed attempts without calling the provider, performs at most one separately reserved retry on retryable transport errors, runs `checkReceipt`, stores `result`/`errorCode`, notifies via `NOTIFY`, and recovers stale `processing` scans.
- Why simplest: keeps admission, uniqueness, scan creation, and durable job enqueue in one `lockGroup`-ordered transaction without extra state tables.
- Rejected alternative: pre-reserving quota outside the scan uniqueness check, which would burn user/month quota on duplicate scan submissions.

### Task 3B.3 results & stage gate 3B — passed

- `pnpm check` (`370 files`, 7 workspace typechecks) and `API_ORIGIN=http://localhost:4010 pnpm build` passed cleanly after final edits.
- Migration `0012_clumsy_ravenous.sql` applied on reset isolated `songphang_phase3_gate`.
- `exercise_3b3_spec15.mts`: concurrent 5-key scan creations -> `1` created (`201`), `4` existing (`200`), `1` `ai_calls` row, `1` job; forced `enqueue` error -> full rollback; job redelivery -> `1` provider call; retry at quota boundary -> blocked without unreserved second request; sentence + receipt shared month ceiling verified; expired reservation (`READER_UNAVAILABLE`), crashed `started` claim (`READ_FAILED`), and stale `processing` recovery (`READ_FAILED`) verified with `0` provider calls.
- `exercise_3b3_live.mts`: live API + worker + SSE stream verified `clean.jpg` (`201 queued` -> `receiptScans` SSE -> `done 440000 []`), duplicate attachment (`200`, 1 `ai_calls`), `mismatch.jpg` (`done TOTAL_MISMATCH computed=442000 vs total=450000`), `not-a-receipt.jpg` (`failed NOT_A_RECEIPT`), unchanged transactions/balances, viewer `403`, outsider/cross-group `404`/`400`, worker stop->queue->start recovery, daily quota `2` -> 3rd `429 AI_QUOTA_EXCEEDED (scope=user)`, and unset `AI_PROVIDER` -> `features.receiptReading=false` + `POST 404`.
- Cumulative gate replay (`baseline_gate.mjs`, `verify_87_samples.ts`, `exercise_3a2.mts`, `exercise_3a3.mts`, `exercise_3b1.mts`, `exercise_3b2.mts`, `check-balances.ts`): all passed; `All groups balanced`.
- Security review: checked items 1, 2, 3, 4, 6, 8; no issues found.

## Task 3C.1 — approach

- Files to create/modify: create `packages/core/src/split-items.ts`; modify `packages/core/src/{split,index}.ts` and update type narrowing in `apps/api/src/services/transaction-input.ts`.
- Approach: define `ItemsSplitInput`, `computeItemsNetTotal`, and `computeItemShares` using `BigInt` largest-remainder allocation (`allocateByWeights`). Validate member uniqueness/membership first, return `{ ok: false, code: "ITEM_UNASSIGNED", itemIndex }` on the first unassigned item, allocate each item in `memberIdsByPosition` order, verify `itemsTotal + net === amount`, allocate `net` extras proportionally to member subtotals (or equally among participating members when all subtotals are 0), and reject negative resulting shares.
- Why simplest: reuses `allocateByWeights` directly with zero floating point and no duplicate rounding logic.
- Rejected alternative: rounding extras per item before summing, which diverges from receipt-level proportional tax/discount distribution.

### Task 3C.1 results

- `pnpm check`: passed (`Checked 371 files`, all 7 workspace typechecks Done).
- `exercise_3c1.mts`: Row 1 intermediate subtotals `[206667, 116667, 116666]` and extra parts `[940, 530, 530]` verified; all 9 table rows (`[207607, 117197, 117196]`, `[206667, 116667, 116666]`, `[197273, 111364, 111363]`, `[33334, 33333, 33333]`, `[5455, 54545]`, `[15000, 15000]`, `ITEM_UNASSIGNED` index `1`, `SPLIT_TOTAL_MISMATCH` expected `450000` actual `442000`, `[55000, 55000]`) matched and summed to exact transaction totals with nonnegative shares.
- Security review: checked items 1, 2, 8; integer-only safe checks and strict membership validation, no dependencies; no issues found.

## Task 3C.2 — approach

- Files to create/modify: Drizzle migration `0013_lively_random.sql`; modify `packages/contract/src/{error,transaction}.ts`, `packages/db/src/schema-transactions.ts`, `apps/api/src/{routes/transactions,services/{transaction-input,transactions}}.ts`, and `apps/web/src/{components/expense-form/use-split-state,lib/activity-sentences}.ts` (safe narrowing until 3C.3 UI arrives).
- Approach: add `ITEM_UNASSIGNED`, `ItemsSplitInput` (1–60 items, 0–20 unique memberIds, 0–6 extras), and `PreviewItemsRequest`/`PreviewItemsResponse` to `@songphang/contract`. Extend `transactions_split_method_check` to include `'items'`. Wire `items` through `calculateShares` (expense-only, fund refusal `422`, foreign member refusal `400`, `ITEM_UNASSIGNED` `400` with `details.itemIndex`). Add `POST /api/v1/groups/{groupId}/transactions/items/preview` computing `computedAmount`, authoritative `shares`, and `issues` purely in `core`.
- Why simplest: stores items inside existing `split_input` JSONB with no extra tables and reuses existing transaction create/edit/preview/warning pipelines.
- Rejected alternative: creating normalized item tables, which violates ADR-023 and complicates versioned snapshots and undo/edit.

### Task 3C.2 results

- `pnpm check`: passed (`Checked 372 files`, all 7 workspace typechecks Done). Migration `0013_lively_random.sql` applied on `songphang_phase3_gate`.
- `exercise_3c2.mts`:
  - Rows 1–4: ordinary preview (`207607, 117197, 117196`), create with photo (`balances +234393/-117197/-117196`), `GET` preserving item order (`["Lẩu", "Bia"]`), `PATCH` edit moving Bia to Lan (`117197, 207607, 117196`; `balances +324803/-207607/-117196`) passed.
  - Rows 5–8: `memberIds: []` -> `400 ITEM_UNASSIGNED (itemIndex: 1)`, amount `450000` -> `400 SPLIT_TOTAL_MISMATCH`, 61 items / `1.5` / foreign member / fund member / income with `items` returned `400`/`400`/`400 MEMBER_NOT_IN_GROUP`/`422 FUND_CANNOT_SHARE`/`400`.
  - Spec 15.4 `POST .../transactions/items/preview`: valid complete state returned `200 computedAmount=442000` + shares; unassigned returned `200` with `issues=[{code:"ITEM_UNASSIGNED",itemIndex:1}]` and no shares; `0` and out-of-range `1.2e12` returned `200` with `INVALID_TOTAL`; empty items returned `400`; fund returned `422`; viewer returned `403`.
  - `check-balances.ts`: `All groups balanced`.
- Security review: checked items 1, 2, 3, 4, 8; no issues found.

## Not verified

- Real Anthropic API calls (forbidden by policy).
- Real phone camera chooser and real receipt accuracy/latency/cost (owner manual checks after implementation).

## Gate not passed

None.
