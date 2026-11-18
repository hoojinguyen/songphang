# Phase 4 run — decisions

Each entry: problem, options, choice, reason; for a library also license, maintenance and added size.

## Baseline & authorization

- Owner authorized continuous execution of Phase 4 (`Task 0` through `Task 4D.4`) on branch `phase-4`, created from local `main` at `b3cf730` (`docs(phase-4): record owner approval and execution authorization`), including section 14 (amendment 2026-11-18).
- Earlier phases on `main`: Phase 0, Phase 1 (`1A`–`1E`), Phase 2 (`2A`–`2D` + `2B` drill-down correction `257fc50`), Phase 3 (`3A`–`3D` merged at `905cdf2` + advisor review & corrections `5c27dea`, `ed086fa`, `e70095b`, `c99a7fc`).
- Server step has not run (`infra/compose.prod.yml` is absent), so mail goes to the console mailer and `infra/compose.prod.yml` edits are skipped in Task 4D.4.
- Disposable database `songphang_phase4_gate` is used for all migrations, seeds, exercises, and stage gates; the owner's `songphang` database is never modified.

## Re-baseline

| Plan reference | Real name and location | Status / adaptation |
|---|---|---|
| `apps/api/src/app.ts` | `createApp`, `AppDeps`, `AppEnv` in `apps/api/src/app.ts` | Exists. Global 100 KiB `bodyLimit`; register new routes (`comments`, `notifications`, `unsubscribe`, `reminders`, `chatLinks`, `telegramWebhook`) here. |
| `apps/api/src/config.ts` | `loadConfig`, `Config` in `apps/api/src/config.ts` | Exists. Extend with `TELEGRAM_PROVIDER`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET`, `TELEGRAM_BOT_USERNAME` and production/console guards. |
| `apps/api/src/routes/features.ts` | `registerFeatureRoute` in `apps/api/src/routes/features.ts`; `FeaturesResponse` in `packages/contract/src/features.ts` | Exists (`receiptReading` and `sentenceAi` wired from `aiProvider`, others `false`). Wire `telegram: Boolean(deps.config.telegramProvider)` in 4C.1. |
| `apps/api/src/rate-limit.ts` | `createRateLimiter`, `requireUploadLimit` in `apps/api/src/rate-limit.ts` | Exists. Add `requireCommentLimit` (20/min/user), unsubscribe limit (30/min/IP), and webhook per-chat limit (30/min/chat). |
| `apps/api/src/events/hub.ts`, `packages/contract/src/jobs.ts` | `createEventHub`, `GroupEventResource` in `packages/contract/src/jobs.ts` | Exists. Add `"comments"` to `GroupEventResource` and `JOB_NAMES` entries for 4B.3, 4B.4, 4C.2. |
| `apps/api/src/mailer.ts`, `apps/api/src/mail-templates.ts` | `Mailer`, `createConsoleMailer` in `apps/api/src/mailer.ts`; templates in `apps/api/src/mail-templates.ts` | Exists. Extend with `List-Unsubscribe` header support and notification immediate/digest templates; share or mirror cleanly in `apps/worker`. |
| `apps/api/src/services/transactions.ts`, `transaction-changes.ts`, `warnings.ts` | `createTransaction`, `createTransactionIn`, `mapTransactions`, `mapTransactionListItems`, `editTransaction`, `setTransactionDeleted`, `transactionWarnings` | Exists. Extend for `commentCount`, `dispute`, `approval`, and `notify` calls inside transactions. |
| `apps/api/src/services/settlement-requests.ts` | `createSettlementRequest`, `resolveSettlement` | Exists (Phase 2 merged). Call `notify` inside transactions for `settlement_requested`, `settlement_confirmed`, `settlement_rejected`. |
| `apps/api/src/services/quick-entry.ts` | `parseSentence` in `apps/api/src/services/quick-entry.ts` | Exists (`ParseRequest` accepts `{ text, ai? }`). Bot `/chi` calls `parseSentence` with `ai: true` per spec 14.1. |
| `apps/api/src/services/balances.ts`, `groups.ts`, `group-users.ts` | `getBalances`, `getGroup`, `editGroup`, `removeGroupUser`, `leaveGroup` | Exists. Extend `GroupDto` / `UpdateGroupRequest` for `muted`, `reminderIntervalDays`, `approvalThreshold`, `ownerName`. |
| `apps/worker/src/main.ts`, `config.ts`, `queue.ts` | `apps/worker/src/{main,config,queue}.ts` (`PgBoss`, `registerJob`, `WorkerDeps`) | Exists (Phase 3 merged). Register 4B.3 (`send-notification-mail`, `send-digest`, `prune-notifications`), 4B.4 (`auto-reminders`), and 4C.2 (`prune-bot-data`) jobs here; add `WEB_ORIGIN` to `loadWorkerConfig`. |
| `packages/db/drizzle.config.ts`, `src/index.ts` | Explicit schema list in `packages/db/drizzle.config.ts`; barrel exports in `packages/db/src/index.ts` | Exists. Add each new `schema-*.ts` file to both `drizzle.config.ts` and `src/index.ts` before `drizzle-kit generate`. |
| `packages/db/src/schema-groups.ts`, `schema-transactions.ts` | `groups`, `members`, `groupUsers`; `transactions`, `transactionPayers`, `transactionShares` | Exists. Extend `groupUsers` (`muted`), `groups` (`reminderIntervalDays`, `approvalThreshold`), and `transactions` (`approvalStatus`, `approvalDecidedBy`, `approvalDecidedAt`, `approvalNote`). |
| `packages/db/src/transactions.ts`, `balances.ts`, `check-balances.ts`, `stats.ts`, `budgets.ts`, `fund.ts` | Money-reading queries in `packages/db/src/` | Exists (Phases 1 & 2 merged). Define `countedTransaction` in `transactions.ts` and apply in 4D.1 to every money-summing query including `stats.ts`, `budgets.ts`, `fund.ts`, `listExportTransactions`, `listGroupLivePayers`, `listGroupLiveShares`. |
| `packages/contract/src/transaction.ts`, `group.ts`, `error.ts`, `index.ts` | Contracts in `packages/contract/src/` | Exists. Add `comment.ts`, `notification.ts`, `chat-link.ts` and extend `transaction.ts`, `group.ts`, `error.ts`, `jobs.ts`. |
| `apps/web/src/app/g/[groupId]/tx/[txId]/view/page.tsx` | Edit page lives at `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx` | Parameter name in Next.js route folder is `[transactionId]`, not `[txId]`. Place S20 view page at `apps/web/src/app/g/[groupId]/tx/[transactionId]/view/page.tsx` so Next.js routes cleanly at `/g/{groupId}/tx/{txId}/view`. |
| Stream row (`ExpenseRow.tsx`, `LedgerPill.tsx`, `ExpenseStream.tsx`) | `apps/web/src/components/feed/{ExpenseRow,LedgerPill,ExpenseStream}.tsx` | Exists. Update `FeedLink` in `ExpenseStream.tsx` to route all roles to `/g/${groupId}/tx/${transaction.id}/view` and render dispute/comment/approval indicators. |
| `apps/web/src/app/g/[groupId]/tx/new/page.tsx`, `ComposeScreen.tsx`, `use-expense-form.ts` | `apps/web/src/app/g/[groupId]/tx/new/page.tsx`, `components/expense-form/use-expense-form.ts` | Exists. Extend `NewExpensePage` and `FormPrefill` for `?form&text=` in 4C.3 and pending approval snackbar in 4D.3. |
| S2, S4, S5, S11, S13 headers/pages | `apps/web/src/app/page.tsx`, `g/[groupId]/page.tsx`, `g/[groupId]/balances/page.tsx`, `g/[groupId]/settings/page.tsx`, `account/page.tsx` | Exist. Add `<Bell />` to S2 & S4; reminders to S5; reminder/Telegram/approval cards to S11; mail settings & Telegram identity card to S13. |
| Group menu (`Tắt thông báo nhóm này`) | No separate dropdown menu on S4; group actions/controls live on `apps/web/src/app/g/[groupId]/members/page.tsx` (which also holds `Rời nhóm`, `Lịch sử`, `Cài đặt nhóm`) | Adaptation: place the `Tắt thông báo nhóm này` switch in `apps/web/src/app/g/[groupId]/members/page.tsx` (and link cleanly from S4's members/group controls button) so every member/viewer can toggle it directly. |
| `apps/web/src/lib/money.ts` | `formatAmount`, `formatMoney` in `apps/web/src/lib/money.ts` | Exists in web only. Move/export shared integer VND formatter (`150.000 đ`) in `packages/core/src/` in 4C.1 so bot messages and web share one formatter. |
| `apps/web/src/lib/use-group-events.ts`, `messages/vi.ts` | `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts` | Exists. Add `"comments"` resource, invalidate `["notifications"]`, and add exact spec strings to `vi.ts`. |
| `infra/compose.prod.yml` | Missing | Server step has not run; skip Compose modifications in 4D.4 per plan ("if it exists"). |

## Stage 4A decisions

### D4A.1 — Comment and dispute response wrappers (Tasks 4A.1–4A.2)

- Problem: the Stage 4A plan names `CommentDto` and `{ id, reason, openedByName, openedAt }` for `POST .../comments` and `POST .../dispute`, while every existing resource endpoint in the API wraps single DTOs in a top-level object (`{ transaction }`, `{ attachment }`, `{ category }`, `{ request }`, `{ member }`).
- Options: return bare `CommentDto` / `TransactionDisputeDto`, or wrap as `{ comment: CommentDto }` and `{ dispute: TransactionDisputeDto | null }`.
- Choice: wrap as `CommentResponse = { comment: CommentDto }` for `POST .../comments` and `DisputeResponse = { dispute: TransactionDisputeDto | null }` for `POST .../dispute` and `POST .../dispute/resolve`.
- Reason: keeps every API endpoint consistent with the existing contract style and lets both `dispute` and `dispute/resolve` share one `DisputeResponse` schema.

## Stage 4B decisions

### D4B.1 — Unsubscribe token rotation with hash-only storage (Task 4B.3)

- Problem: Spec 4.3 requires storing only the SHA-256 hash of the unsubscribe token in Postgres (`notification_settings.unsubscribe_token_hash`), while Plan 4B.3 mentions creating on first mail and reusing it. Because SHA-256 is one-way, Postgres alone cannot reconstruct the raw token across worker restarts.
- Options: (a) store encrypted token or add a secret key not in `.env.example`; (b) use single-use rows in `auth_tokens`; (c) cache `userId -> rawToken` in memory in the worker so repeated mails in the same process reuse the same token and hash, generating a fresh 32-byte base64url token and updating `unsubscribe_token_hash` only when `unsubscribe_token_hash` is null or missing from cache, and keep the hash active across repeated `POST /notifications/unsubscribe` calls.
- Choice: option (c).
- Reason: guarantees only `sha256` ever touches the database, reuses the token within a worker process without extra env secrets, ensures links remain valid across process restarts, and handles link pre-fetches idempotently.

### D4B.2 — Digest incremental checkpoint table (`job_checkpoints`, Task 4B.3)

- Problem: `send-digest` must select unread digest-kind notifications created since the previous run and print nothing on an immediate second run, both via daily cron and when invoked manually.
- Options: query internal `pgboss.job` history (fails for direct manual runs), add a `digest_sent_at` column on `notifications`, or add a 2-column `job_checkpoints (name text PK, last_run_at timestamptz)` table.
- Choice: add `job_checkpoints`.
- Reason: keeps `notifications` schema identical to Spec 4.1 and makes manual invocations and scheduled 20:00 runs behave identically.

### D4B.3 — Worker mailer and shared notification line formatting (Task 4B.3)

- Problem: Plan 4B.3 notes creating `apps/worker/src/mailer.ts` or moving mailer/templates to `packages/mail` if both apps need them. Only `apps/worker` sends notification/digest emails while `apps/api` sends auth emails, whereas both `apps/web` and `apps/worker` render Spec 7.2 notification lines.
- Options: create a new `packages/mail` workspace package, or share pure formatting (`formatAmount`, `formatMoney`, `formatNotificationLine`) in `@songphang/core` while keeping mail rendering inside `apps/worker/src/{mailer,mail-templates}.ts`.
- Choice: place shared formatting in `@songphang/core` and keep notification mailers/templates in `apps/worker/src/`.
- Reason: avoids adding a new workspace package while guaranteeing zero duplicated Spec 7.2 copy between web and worker.

### D4B.4 — `debt_reminders` table for reminder cooldowns and automatic intervals (Task 4B.4)

- Problem: the collaboration spec defines a 24-hour cooldown per ordered `(from_member_id, to_member_id)` pair for manual reminders and a configurable `(3, 7, 14)` day interval for automatic reminders without specifying the storage table.
- Options: overload `notifications` rows with JSON queries, or add a dedicated `debt_reminders` table indexed by `(group_id, from_member_id, to_member_id, created_at DESC)`.
- Choice: add `debt_reminders` (`id`, `group_id`, `from_member_id`, `to_member_id`, `amount`, `sent_by` nullable for automatic reminders, `created_at`) plus `groups.reminder_interval_days` (`NULL | 3 | 7 | 14`).
- Reason: querying the latest reminder per ordered pair uses the composite B-tree index directly, avoids scanning JSONB notification payloads (which users could also lose if notifications are pruned after 90 days or if unlinked/muted), and records `sent_by = NULL` cleanly for daily automatic runs.
