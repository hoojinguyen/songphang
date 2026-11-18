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
- [x] 3C.3 — web camera in entry bar and receipt review screen
- [x] 3C.4 — stage gate 3C
- [x] 3D.1 — sentence AI and parse fallback
- [x] 3D.2 — core category suggestion
- [x] 3D.3 — web AI readings on the confirmation card
- [x] 3D.4 — README, non-functional checks, final gate 3D

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

## Task 3C.3 — approach

- Files to create/modify: create `apps/web/src/lib/{features,receipt-scans}.ts`, `apps/web/src/components/feed/CameraButton.tsx`, `apps/web/src/components/receipt/{ItemRow,ExtrasFields,MismatchNotice,ItemsAssignmentPanel,ReceiptReview}.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/components/ui/Icon.tsx`, `apps/web/src/lib/use-group-events.ts`, `apps/web/src/components/feed/{EntryBar,ExpenseRow}.tsx`, `apps/web/src/app/g/[groupId]/tx/new/page.tsx`, `apps/web/src/components/expense-form/{SplitModeTabs,use-split-state,SplitEditor,use-expense-form,ExpenseForm}.tsx`.
- Approach: add `useFeatures` (`GET /features` cached per session), extend `useGroupEvents` to invalidate `receiptScans`, and add `useReceiptScan` (SSE invalidation + 3s fallback while pending + 60s timeout) and 300ms-debounced `usePreviewItems` (`POST .../transactions/items/preview`). Add accessible `CameraButton` menu (`Chụp ảnh`, `Chọn từ thư viện`, `Escape` focus restore) shown only when `features.receiptReading` is true. Implement `ReceiptReview` on `/tx/new?scan=` (including total-only initialization, `MismatchNotice` choices respecting the 6-extra cap, `Chia đều các món còn lại`, inline item/extra editing, `PhotoViewer`, `Chụp lại`/`Thử lại`/`Nhập tay` error paths, `Lưu` with one idempotency key per instance) and extract `ItemsAssignmentPanel` so `ExpenseForm`'s `Theo món` tab shares the same preview-backed editor.
- Why simplest: reuses `ItemsAssignmentPanel` and existing `prepareImage`/`uploadAttachment`/`PhotoViewer` components without duplicating item math in the browser.
- Rejected alternative: computing item shares client-side or keeping two separate item editors for receipt review and manual `Theo món`.

### Task 3C.3 results

- `pnpm check` (`380 files`, 7 workspace typechecks) and `API_ORIGIN=http://127.0.0.1:4010 pnpm build` passed cleanly after final edits (`ReceiptReview` occurredAt `.toISOString()` UTC fix caught during browser verification).
- Live Chrome DevTools verification on production Next.js `3010` + API `4010` + worker (`Quán 3C` group):
  - `AI_FAKE_RECEIPT_FIXTURE=clean`: `Chụp hoá đơn` menu opened (`Chụp ảnh` / `Chọn từ thư viện`), `Escape` restored focus to `Chụp hoá đơn`; uploaded canvas JPEG -> `?scan=...` loaded `Lẩu thái` (`350000`) & `Bia` (`90000`) with `Đọc bằng AI. Hãy xem lại trước khi lưu.` and `Còn 2 món chưa có ai.`; `Chia đều các món còn lại` -> `146.667, 146.667, 146.666`; edited item amount & added/removed 3rd item; assigned `Bia` to Minh -> `206.667, 116.667, 116.666`; double-tapped `Lưu` -> created 1 expense (`440.000`, `Có ảnh hoá đơn`) and returned to stream.
  - `AI_FAKE_RECEIPT_FIXTURE=mismatch`: displayed `MismatchNotice` (`442.000 đ` vs `450.000 đ`), clicking `Dùng 450.000 đ` appended `Chênh lệch` (`8000` `Khác`), preview recomputed `450.000 đ` (`150.001, 150.000, 149.999`), saved cleanly.
  - `AI_FAKE_RECEIPT_FIXTURE=not-a-receipt`: showed `Không đọc được hoá đơn trong ảnh này.` with `Chụp lại` and `Nhập tay`; clicking `Nhập tay` carried `?attachmentId=...` into `ExpenseForm` (`Xem ảnh hoá đơn` visible) and opening `đổi cách chia` -> `Theo món` rendered `ItemsAssignmentPanel`.
  - `AI_PROVIDER` unset: verified `Chụp hoá đơn` absent from `EntryBar`. Zero console errors.
- Security review: checked items 1, 2, 4, 7, 8; no issues found.

## Stage gate 3C — passed

- `pnpm check` (`380 files`, 7 workspace typechecks) and `API_ORIGIN=http://localhost:4010 pnpm build` passed cleanly.
- Isolated DB `songphang_phase3_gate` reset, migrated, and seeded cleanly.
- Cumulative gate replay (`baseline_gate.mjs`, `verify_87_samples.ts`, `exercise_3a2.mts`, `exercise_3a3.mts`, `exercise_3b1.mts`, `exercise_3b2.mts`, `exercise_3b3_spec15.mts`, `exercise_3b3_live.mts`, `exercise_3c1.mts`, `exercise_3c2.mts`): all passed.
- Timed fake-provider browser run from image selection in `CameraButton` -> `ReceiptReview` -> `Chia đều các món còn lại` -> double-tap `Lưu` -> saved expense visible in stream: `37,155 ms` (within 60s target on localhost fake provider).
- `check-balances.ts`: `All groups balanced`.

## Task 3D.1 — approach

- Files to create/modify: create `packages/ai/{package.json,tsconfig.json,src/{index,anthropic-client}.ts}` (moved `anthropic-client.ts` from worker), `packages/contract/src/sentence-ai.ts`, `apps/api/src/ai/{sentence-ai,anthropic-sentence-ai,fake-sentence-ai,prompts/sentence}.ts`; move `apps/worker/fixtures/sentences.json` -> `apps/api/fixtures/sentences.json`; modify `packages/contract/src/{quick-entry,index}.ts`, `apps/worker/{package.json,src/ai/anthropic-receipt-reader.ts,src/jobs/read-receipt.ts}`, `apps/api/{package.json,src/{app,routes/{features,transactions},services/quick-entry}.ts}`.
- Approach: add `SentenceAiAnswer` (using `RequestMemberRef` and `AiSplitInput` with zero UUIDs or `items`), add `category`/`categoryId`, `ParsedDraftResult`, `reader`, and `moreDrafts` to quick-entry contracts. Only when the rule reader returns `unparsed` and `sentenceAi` is configured does `parseSentence` open a short tx to reserve and claim `purpose: "sentence"`, generate fresh nonce-scoped active-person references (`<nonce>:pN`), call `SentenceAi` (8s timeout, no retry), map valid references back to UUIDs in API memory, discard unknown references while forcing non-`ok` status without shares, run `computeShares`, and return AI `draft` + `moreDrafts` (`spans: []`) or silently fall back to the rule answer on empty drafts, quota limit, timeout, or invalid shape.
- Why simplest: isolates provider transport in `@songphang/ai`, keeps DB quota transactions completely outside provider HTTP I/O, and reuses `computeShares` and ordinary draft validation.
- Rejected alternative: reusing UUID `SplitInput` at the provider boundary or holding a transaction across provider HTTP calls.

### Task 3D.1 results

- `pnpm check`: passed (`Checked 388 files`, all 8 workspace typechecks Done).
- `exercise_3d1.mts`:
  - Rule `ok` (`cà phê 180k chia 4`) and rule `needs_input` (`cà phê 180k chia 2`) returned `reader="rules"` with `0` `ai_calls` rows.
  - All 15 advisor fixtures verified (`AI01: ai/ok`, `AI02: ai/ok more=1`, `AI03: ai/needs_input`, `AI04: ai/needs_input`, `AI05–AI07: rules/unparsed`, `AI08: ai/needs_input`, `AI09–AI13: rules/unparsed`, `AI14: ai/needs_input` with `Nam` dropped & no shares, `AI15: ai/needs_input` with `confident:false` & no shares).
  - Unknown unparsed sentence preserved `reader="rules"`; `AI_SENTENCES_PER_USER_PER_DAY=1` silently fell back on the 2nd sentence; viewer returned `403`; `features.sentenceAi` reflected `AI_PROVIDER`.
  - Stubbed `SentenceAi` verified zero leaked UUIDs/emails, distinct nonce refs on repeat calls, `shares`/`percent` mapping through `computeShares`, invalid shape fallback (`ai_calls.ok=false`), and `8012ms` abort timeout with `1` fetch attempt.
- `verify_87_samples.ts`: all 87 original rule-reader samples (75 Phase 1 + 12 Phase 2) passed.
- Security review: checked items 1, 2, 3, 4, 8; no real IDs sent to provider, Zod validation at AI boundary, atomic reservation/claim before HTTP; no issues found.

## Task 3D.2 — approach

- Files to create/modify: create `packages/core/src/suggest-category.ts`; modify `packages/core/src/index.ts`, `apps/api/src/services/quick-entry.ts`.
- Approach: add `suggestCategory(description, custom)` in `@songphang/core` using `foldVietnamese` and word-boundary matching so single- and multi-word live custom category `nameKey`s take precedence, followed by the longest word-boundary match in `CATEGORY_KEYWORDS` (`packages/core/src/category-keywords.ts`, ties broken in table order). Wire `listGroupCategories` (filtering `archivedAt === null`) into `parseSentence` so rule `ok`/`needs_input` drafts and AI drafts with null category receive a suggested `category` or `categoryId` while preserving explicit AI categories and keeping `unparsed` drafts uncategorized.
- Why simplest: keeps pure string/keyword matching in `@songphang/core` with zero database dependencies and applies it in one helper inside `parseSentence`.
- Rejected alternative: duplicating Vietnamese folding or keyword lookup inside the API service.

### Task 3D.2 results

- `pnpm check`: passed (`Checked 389 files`, all 8 workspace typechecks Done).
- `exercise_3d2.mts`:
  - Unit table checks (9 cases + custom multi-word + substring trap): `Phở bò` -> `food`, `grab ra sân bay` -> `transport`, `Khách sạn Đà Lạt` -> `lodging`, `tiền điện tháng 12` -> `bills`, `xyz` -> `null`, `phong` -> `null`, `Cà phê` & `Cà phê sáng` with custom `ca phe` -> `{ categoryId }`, `capheine` -> `null`.
  - Service/DB checks on `songphang_phase3_gate`: `"phở 60k chia 2"` -> `reader="rules"`, `draft.category="food"`, `draft.categoryId=null`; live custom category `"Cà phê"` -> `draft.categoryId`; archived custom category ignored and fell back to `food`; stub AI kept explicit `"entertainment"` on draft 1 and filled `"transport"` on null-category draft 2.
- `verify_87_samples.ts` (all 87 samples) and `exercise_3d1.mts` (all 15 fixtures + timeout/quota/boundary checks): passed.
- Security review: checked items 2, 4, 8; pure matching in core, live category filter enforced in API, no issues found.

## Task 3D.3 — approach

- Files to modify: `apps/web/src/messages/vi.ts`, `apps/web/src/components/quick-entry/ConfirmationCard.tsx`, `apps/web/src/components/quick-entry/QuestionCard.tsx`, `apps/web/src/components/expense-form/use-expense-form.ts`, `apps/web/src/app/g/[groupId]/tx/new/ComposeScreen.tsx`.
- Approach: add the Spec §8.4 Vietnamese strings (`Đang đọc…`, `Đọc bằng AI. Hãy xem lại.`, `Khoản {index}/{count}`, `Lưu và sang khoản sau`, `Bỏ khoản này`) to `vi.compose`. In `ComposeScreen`, display `Đang đọc…` (`role="status"`) when `query.isFetching` stays pending beyond 1000ms, suppress phrase highlighting (`spans: []`) whenever `reader === "ai"`, iterate `[first, ...moreDrafts]` with distinct `${sentence}:${activeIndex}` idempotency keys and category overrides, forward non-`ok` AI items (and `unparsed`) to `/tx/new?form` prefilled via `useDraft`, and preserve `category`/`categoryId` into `CreateTransactionRequest` preview, save, `QuestionCard`, and `useExpenseForm`. On `ConfirmationCard`, show the AI note for `reader === "ai"`, the `Khoản {index}/{count}` badge + `Bỏ khoản này` for multi-draft reads, and a tappable suggested category chip opening `CategoryPicker` inline.
- Why simplest: reuses `CategoryPicker`, `QuestionCard`, and `DraftProvider` rather than introducing a second quick-entry state store or modal category selector.
- Rejected alternative: nesting a modal category `<dialog>` inside `ConfirmationCard`, which would collide with `CategoryPicker`'s `+ Thêm danh mục` dialog.

### Task 3D.3 results

- `pnpm check` (`389 files`, all 8 workspace typechecks Done) and `API_ORIGIN=http://127.0.0.1:4010 pnpm --filter @songphang/web build` passed cleanly after all web edits.
- Live Chrome DevTools verification on production Next.js `3010` + API `4010` (`AI_PROVIDER=fake`, group `Nhóm 3D3`):
  - `lẩu 300k lan 100 lan 200` (`AI01`): rendered `Đọc bằng AI. Hãy xem lại.`, `Ăn uống` category chip, `0` `<mark>` highlights in sentence input, saved `lẩu` (`300.000`, `Ăn uống`) to feed.
  - `cà phê 180k và bánh 50k` (`AI02`): rendered `Khoản 1/2` (`cà phê`, `180.000 đ`) with `Lưu và sang khoản sau` and `Bỏ khoản này`; saving first advanced to `Khoản 2/2` (`bánh`, `50.000 đ`); clicking `Bỏ khoản này` returned to feed with only `cà phê` saved (`bánh` absent).
  - `cà phê 180k hôm qua` (`AI15` uncertain): navigated to `/tx/new?form` with `Mình chưa hiểu hết câu này`, `180000`, `cà phê`, and `Ăn uống` pressed.
  - `cà phê 180k chia 4` (rule): omitted `Đọc bằng AI. Hãy xem lại.` and rendered phrase highlights (`số tiền: 180k`, `phần chia: chia 4`).
  - `phở 60k chia 2` with a 1.3s delayed `/transactions/parse` response: displayed `Đang đọc…` (`role="status"`) after 1s, cleared it when `QuestionCard` resolved, opened `Ăn uống` chip into `CategoryPicker`, switched to `Đi lại`, selected Minh + Lan, saved `phở` (`60.000`, `Đi lại`) to feed. Zero console errors.
- Security review: checked items 1, 2, 7, 8; boundary Zod parsing intact before preview/save, no `dangerouslySetInnerHTML`, no secrets; no issues found.

## Task 3D.4 — approach

- Files to modify: `README.md`, `docs/superpowers/runs/phase-3/{progress,decisions,manual-checks}.md` (verified `infra/compose.prod.yml` does not exist yet so skipped per plan).
- Approach: document Phase 3 runtime services (`apps/worker`), `STORAGE_DIR`, AI environment variables, fake-provider switches, and fixture directories in `README.md`. Append Stage 3B–3D architectural decisions to `decisions.md`, owner manual checks plus `After the Anthropic key exists` and `The 30-receipt measurement` survey table to `manual-checks.md`, execute browser non-functional checks (keyboard-only `ReceiptReview`, accessible names, Fast 4G throttled large upload), and run the complete Final Cumulative Gate 3D on a freshly reset `songphang_phase3_gate` database.
- Why simplest: updates only the existing root documentation and Phase 3 run logs without touching source code or untracked Compose config.

### Task 3D.4 & Final Cumulative Gate 3D results

- Browser non-functional checks on production Next.js `3010` + API `4010` + worker (`AI_PROVIDER=fake`, `AI_FAKE_RECEIPT_FIXTURE=clean`, group `Nhóm 3D3`):
  - Throttled upload (`Fast 4G` + `4x` CPU throttling via Chrome DevTools `emulate`): dispatched a `4,252,665`-byte noisy JPEG (`2200×2200` canvas), confirmed `Đang tải ảnh lên…` status (`role="status"`), button disabled state while uploading, and completion into `ReceiptReview` (`22,713 ms` end-to-end across upload + worker scan + screen load).
  - Accessible names: verified `button "Chụp hoá đơn"` and `0` empty `[role="img"]` member labels across both the feed and `ReceiptReview` item/payer rows (`Minh`, `Lan`, `Hùng`, `Thu`).
  - Keyboard-only `ReceiptReview` walk (`Tab`, `Enter`, `Space` only): tabbed onto `Chia đều các món còn lại`, activated with `Enter`, tabbed to `Bia`, selected with `Space`, tabbed to `Lan`, toggled off with `Space`, tabbed to `Lưu`, submitted with `Enter` -> saved `Bếp mẫu` (`440.000`, `Có ảnh hoá đơn`, `Minh/Hùng/Thu 117.500`, `Lan 87.500`) to feed with zero console errors.
- Final Cumulative Gate 3D on freshly dropped/recreated + migrated + seeded isolated DB `songphang_phase3_gate`:
  - `pnpm check`: passed (`Checked 389 files`, all 8 workspace typechecks Done).
  - `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`next build` compiled all 11 static pages + dynamic routes cleanly).
  - Phase 1 + Phase 2 + permission matrix + disabled-provider features (`baseline_gate.mjs`), `exercise_3a2.mts`, and `exercise_3a3.mts`: passed.
  - All 87 quick-entry rule samples (`verify_87_samples.ts`): passed.
  - Stage 3B (`test_pgboss_tx.mts`, `exercise_3b1.mts`, `exercise_3b2.mts`, `exercise_3b3_spec15.mts`, `exercise_3b3_live.mts`): all 4 receipt fixtures, quota/month caps, atomic reservation rollback/recovery, live worker + SSE, and unset `AI_PROVIDER` (`features.receiptReading: false`, `POST /receipt-scans` `404`) passed.
  - Stage 3C (`exercise_3c1.mts`, `exercise_3c2.mts`): all 9 item-split matrix rows, preview/create/edit/validation/balances, and `items/preview` passed.
  - Stage 3D (`exercise_3d1.mts`, `exercise_3d2.mts`): all 15 sentence fixtures (`AI01`–`AI15`), privacy nonces, 8s timeout + 0 retries, daily cap silent fallback, `features.sentenceAi`, and category keyword/custom matching passed.
  - `DATABASE_URL=.../songphang_phase3_gate pnpm db:check-balances`: all 11 groups summed to `0` with `0` mismatches -> `All groups balanced`.

## Post-review fixes (Codex review round 1)

- Findings addressed:
  1. Preserved multi-draft AI queue across `/tx/new?form` manual handoff (`DraftProvider.queue`, `useExpenseForm`, `ExpenseForm` showing `Khoản {index}/{count}`, `Lưu và sang khoản sau`, and `Bỏ khoản này`, resuming remaining drafts back at `/tx/new`).
  2. Snapshotted the accepted queue in `DraftProvider` per user-submitted sentence (plus `refetchOnWindowFocus: false` / `refetchOnReconnect: false` on `useParseSentence`) so background query refetches never reset `index`, category overrides, or idempotency keys.
  3. Blocked `ReceiptReview` save while `showMismatch` is unresolved (including when 6 extras prevent adding a mismatch adjustment), and stopped `onRemoveExtra` from auto-dismissing `MismatchNotice` when freeing an extra slot.
- Verified live on production Next.js `3010` + API `4010` + worker (`AI_PROVIDER=fake`, `AI_FAKE_RECEIPT_FIXTURE=mismatch`, `Nhóm 3D3`), followed by `pnpm db:check-balances` (`All groups balanced`) and `pnpm check` (`0` errors).

## Not verified

- Real Anthropic API calls (forbidden by policy; transport and forced-tool schemas tested against local fakes and stubbed `fetch` only).
- Real mobile phone camera picker and physical receipt accuracy, latency, and `cost_vnd` across 30 real receipts (owner manual checks in `manual-checks.md`).
- Production server deployment / `infra/compose.prod.yml` (does not exist on `main`/`phase-3`).

## Gate not passed

None.
