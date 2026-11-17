# Phase 3 run — decisions

## Baseline & authorization

- Owner authorized continuous execution of Phase 3 (`Task 0` through `Task 3D.4`) on branch `phase-3` in the current session.
- Baseline commit on `main`: `6b36336` (`chore(phase-3): prepare advisor fixtures and standing documents`), containing `257fc50` (`fix(stats): preserve spending scope in feed drill-downs`) and `d12f622` (`merge: add phase 2 real-money features`).
- Earlier phases on `main`: Phase 0, Phase 1 (1A–1E), Phase 2 (2A–2D + 2B drill-down correction). Server step has not run (`infra/compose.prod.yml` does not exist).

## D1 — pg-boss version, license, size, and transactional enqueue adapter (Task 3A.1)

- Package: `pg-boss@12.38.2` (MIT, unpacked size `1,369,609` bytes, Node `>=22.12.0`).
- Transactional adapter: `pg-boss` exports `fromDrizzle(executor, drizzleSql)`. Exercised against `songphang_phase3_gate`: `boss.send(..., { db: fromDrizzle(tx, sql) })` inside `db.transaction` inserts into `pgboss.job` on commit and leaves zero rows on rollback.
- API queue initialization: API runs `PgBoss` with `{ supervise: false, schedule: false, registerInstance: false }` and calls `createQueue` for each `JOB_NAMES` entry so API can enqueue even while the worker is stopped.
- `drizzle.config.ts`: sets `schemaFilter: ["public"]` so `drizzle-kit` ignores `pgboss`.
- `listenPgChannel` in `packages/db/src/client.ts`: exposes `postgres.js` `LISTEN` with exponential backoff `(retries) => Math.min(2 ** Math.max(0, retries - 1), 30)` so `apps/api` does not duplicate a direct `postgres` dependency.

## D2 — Extract shared `packages/storage` workspace package (Task 3A.3)

- Problem: both `apps/api` and `apps/worker` need `FileStore`, `diskFileStore`, and `sniffImageType` with identical key/path-traversal validation and `STORAGE_DIR` resolution.
- Options: duplicate `diskFileStore` into `apps/worker/src/storage.ts`; extract `@songphang/storage` into `packages/storage`.
- Choice: extract `packages/storage` (`@songphang/storage`), explicitly permitted by spec section 15.1 and Stage 3A task 3A.3. No external dependency added.

## D3 — Anthropic Messages API documented request shape (Task 3B.2)

- Documentation consulted: `https://platform.claude.com/docs/en/api/messages` (vision and forced tool use), read on `2026-11-18`. Not called by the agent per `AGENTS.md` section 11.
- Endpoint: `POST https://api.anthropic.com/v1/messages`
- Headers: `content-type: application/json`, `x-api-key: <ANTHROPIC_API_KEY>`, `anthropic-version: 2023-06-01`
- Vision block: `{ type: "image", source: { type: "base64", media_type: contentType, data: base64 } }` inside `messages[0].content` alongside a `text` block.
- Forced tool use: `tools: [{ name, description, input_schema }]` with `tool_choice: { type: "tool", name }`; response parsed from `content` `tool_use` block `input` and `usage.input_tokens` / `usage.output_tokens`.
- `features.receiptReading` is wired from `Boolean(config.aiProvider)` in 3B.2; `features.sentenceAi` remains `false` until Task 3D.1 implements the sentence AI parse fallback.

## Re-baseline

| Plan reference | Real name and location | Status / adaptation |
|---|---|---|
| `GET /api/v1/features` | `registerFeatureRoute` in `apps/api/src/routes/features.ts`; `FeaturesResponse` in `packages/contract/src/features.ts` | Exists with all 6 booleans (`receiptReading`, `sentenceAi`, `telegram`, `push`, `appleSignIn`, `errorAlerts`). Extend in place using config. |
| `apps/api/src/app.ts` | `apps/api/src/app.ts` (`createApp`, `AppDeps`, global 100 KiB `bodyLimit`) | Exists. Attachment upload route needs route-specific 6 MiB limit before global 100 KiB middleware. |
| `apps/api/src/server.ts` | `apps/api/src/server.ts` | Exists. Wire `listenForGroupEvents` and startup cleanup/guards here. |
| `apps/api/src/config.ts` | `apps/api/src/config.ts` (`loadConfig`) | Exists. Add `STORAGE_DIR`, `AI_*` variables, and production guards. |
| `apps/api/src/events/hub.ts` | `apps/api/src/events/hub.ts` (`createEventHub`, `GroupResource`) | Exists. Add `"receiptScans"` to `GroupResource`. |
| `apps/api/src/rate-limit.ts` | `apps/api/src/rate-limit.ts` | Exists. Reuse for 30 uploads/hour/user rate limit. |
| `apps/api/src/services/transactions.ts` | `apps/api/src/services/transactions.ts`, `transaction-input.ts`, `transaction-changes.ts` | Exists. Extend create/edit/preview/get/list for `attachmentIds`, `attachments`, `attachmentCount`, and `items` split method. |
| `apps/api/src/services/groups.ts` | `apps/api/src/services/groups.ts` (`deleteGroup`) | Exists. Read attachment keys before cascade delete and enqueue `delete-files` job. |
| `services/quick-entry.ts`, `contract/src/quick-entry.ts` | `apps/api/src/services/quick-entry.ts`, `packages/contract/src/quick-entry.ts` | Exists. Extend with `reader`, `moreDrafts`, `category`, `categoryId`, AI fallback, and `suggestCategory`. |
| `packages/contract/src/transaction.ts`, `error.ts`, `index.ts` | `packages/contract/src/{transaction,error,index}.ts` | Exists. Add `AttachmentDto`, `TransactionListItemDto`, `ItemsSplitInput`, `ItemsPreview*`, and error codes. |
| `packages/core/src/allocate.ts`, `split.ts`, `dates.ts`, `quick-entry/normalize.ts` | `packages/core/src/{allocate,split,dates}.ts`, `quick-entry/normalize.ts` | Exists. Add `receipt.ts`, `ai-quota.ts`, `split-items.ts`, `suggest-category.ts`. |
| `packages/core/src/category-keywords.ts` | `packages/core/src/category-keywords.ts` | Advisor-prepared 120 normalized entries; not yet exported or consumed until 3D.2. |
| `packages/db/drizzle.config.ts`, `src/client.ts`, `src/schema*.ts` | `packages/db/drizzle.config.ts`, `packages/db/src/client.ts`, `src/schema*.ts` | Exists. Ignore `pgboss` schema in Drizzle; add `attachments`, `receipt_scans`, `ai_calls` schemas/migrations. |
| `apps/worker/` | `apps/worker/fixtures/` only (advisor fixtures) | No `package.json`, `tsconfig.json`, or `src/` yet; scaffold in Task 3A.1. |
| `apps/web` typing box & confirmation card | `apps/web/src/app/g/[groupId]/tx/new/ComposeScreen.tsx`, `components/quick-entry/{SentenceInput,ConfirmationCard,QuestionCard}.tsx` | Exists. Update in 3D.3 for `Đang đọc…`, AI notice, `moreDrafts`, and category chip. |
| `apps/web` manual form & stream | `apps/web/src/components/expense-form/{ExpenseForm,use-expense-form,use-split-state,SplitModeTabs,SplitEditor}.tsx`, `components/feed/{EntryBar,ExpenseRow,ExpenseStream}.tsx`, `app/g/[groupId]/tx/new/page.tsx` | Exists. Update in 3A.4, 3C.3, 3D.3. |
| `apps/web/src/lib/use-group-events.ts` | `apps/web/src/lib/use-group-events.ts` | Exists. Add `"receiptScans"` to `Resources` schema and invalidation. |
| `apps/web/src/messages/vi.ts` | `apps/web/src/messages/vi.ts` | Exists. Single source of approved Vietnamese strings. |
| `infra/compose.prod.yml` | Missing | Server step has not run; Task 3D.4 skips Compose/backup edits per plan ("if it exists"). |
