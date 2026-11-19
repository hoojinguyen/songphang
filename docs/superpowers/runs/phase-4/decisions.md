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

## Stage 4C decisions

### D4C.1 — Bot API shapes, webhook envelope handling, and `botUsername` / `chatIdentities` surfaces (Task 4C.1)

- Problem: (a) `/groups/{groupId}/settings` needs `@{bot}` (`TELEGRAM_BOT_USERNAME`) for Spec 7.3 while `FeaturesResponse` has fixed keys verified by `task0_replay`; (b) `GET /me/chat-identities` returns `[{ platform, linkedAt }]` while Spec 7.3 displays `Đã liên kết với {name}`; (c) Hono's default JSON body validator rejects non-JSON payloads with 400 before route handlers run, whereas Telegram webhook must answer 200 `{}` on invalid JSON or validation failures.
- Options: (a) extend `FeaturesResponse` with `telegramBotUsername` or return `botUsername` on `GET /groups/{groupId}/chat-links` and `POST /groups/{groupId}/chat-links/code`; (b) add Telegram PII (`first_name`) to `chat_identities` or keep Spec 5.2's column list and display platform label (`"Telegram"`); (c) validate JSON via OpenAPI vs read raw text and `TelegramUpdate.safeParse` inside the webhook handler after secret verification.
- Choice: return `{ botUsername, chatLinks }` on `GET /groups/{groupId}/chat-links` (and `{ botUsername, command, expiresAt }` on code creation), keep `chat_identities` strictly matching Spec 5.2 columns (`{ chatIdentities: [{ platform, linkedAt }] }`, rendering `"Telegram"` for `{name}`), and verify `X-Telegram-Bot-Api-Secret-Token` first via `timingSafeEqual` before parsing raw text + `TelegramUpdate.safeParse` (invalid JSON or Zod failure returns `200 {}` with no side effects).
- Reason: keeps `FeaturesResponse` backwards-compatible, avoids storing unnecessary Telegram user PII, and prevents malformed webhook payloads from triggering 400 retries. Verified Bot API request shapes: `POST https://api.telegram.org/bot{token}/sendMessage` (`{ chat_id, text, reply_markup?: { inline_keyboard } }`, plain text without `parse_mode`), `POST .../answerCallbackQuery` (`{ callback_query_id, text? }`), and `setWebhook` (`url`, `secret_token` -> `X-Telegram-Bot-Api-Secret-Token` header, `allowed_updates: ["message", "callback_query"]`).

## Stage 4D decisions

### D4D.1 — Uncounted stream row opacity raised for WCAG AA contrast (Task 4D.3)

- Problem: Spec/Plan 4D.3 describes pending and rejected rows as dimmed (`opacity: 0.60`) with `chờ duyệt` (`bg-accent text-ink`) or `không được duyệt` (`bg-coral text-ink`) tags and instructs checking contrast on the live row and raising opacity if below WCAG AA (`4.5:1`). Over the page background `--color-bg` (`#f6f2fb`), applying `opacity-60` to the whole row yields `3.76:1` for `chờ duyệt`, `2.79:1` for `không được duyệt`, and `2.82:1` for `text-muted` on `bg-surface`, all below `4.5:1`.
- Options: (a) keep `opacity-60` and fail AA on tags/meta; (b) raise uncounted row/pill opacity to `0.85` (`opacity-85`).
- Choice: apply `opacity-85` on pending/rejected `ExpenseRow` bubbles and `LedgerPill` pills while rendering the explicit `chờ duyệt` / `không được duyệt` tag pill inside.
- Reason: at `0.85` over `#f6f2fb`, every contrast pair exceeds WCAG AA: `chờ duyệt` (`#1c1b22` on `#ffd84d`) = `8.21:1`, `không được duyệt` (`#1c1b22` on `#ff8a73`) = `5.35:1`, `text-muted` (`#5a5766` on `#ffffff`) = `4.90:1`, `on-ink-muted` (`#c9c5d6` on `#1c1b22`) = `7.01:1`, and primary text (`#1c1b22` on `#ffffff` / `#ffffff` on `#1c1b22`) = `10.86:1`.

### D4D.2 — Bell unread accessible name (Task 4D.3 / 4D.4)

- Problem: Plan 4B.2 used `"Thông báo, {count} chưa đọc"`, while Plan 4D.4 accessibility verification specifies `"{count} thông báo chưa đọc"`.
- Options: leave the older format or align `vi.notifications.bellUnreadLabel` to `"{count} thông báo chưa đọc"`.
- Choice: update `vi.notifications.bellUnreadLabel` to `"{count} thông báo chưa đọc"`.
- Reason: matches Plan 4D.4's accessibility check character for character while staying natural Vietnamese for screen readers.

### D4D.3 — Rename Telegram bot command modules to English (Owner request)

- Problem: Plan `4c-telegram.md` specified Vietnamese filenames (`chi.ts`, `sodu.ts`, `huy.ts`, `trogiup.ts`, `lienket.ts`) matching the slash command names, whereas engineering artifacts in `AGENTS.md` use English identifiers.
- Options: leave the planned filenames in place or rename them and their handlers to English (`expense.ts`, `balances.ts`, `undo.ts`, `help.ts`, `link.ts`) while keeping the Telegram slash commands (`/chi`, `/sodu`, `/huy`, `/trogiup`, `/start`, `/lienket`) unchanged.
- Choice: renamed all five command files and handlers to English per project owner approval.
- Reason: aligns all Phase 4 TypeScript source filenames and identifiers with `AGENTS.md` English engineering policy without altering user-facing bot commands.

## Advisor Review Corrections Decisions (2026-11-19)

### DR1 — Two-sided Telegram identity pairing (`chat_identity_pairings`, R1)

- Problem: Review R1 [P1] showed that group-posted `/link/telegram?code=...` bearer codes could be claimed by any signed-in user without proving ownership of the Telegram sender ID (and an attacker could trick a signed-in user into claiming the attacker's code).
- Options: (a) keep `/link/telegram?code=` with an extra dialog; (b) replace bearer codes with a web-initiated two-sided pairing flow (`chat_identity_pairings`) bound to `(userId, sessionId)` with a private `/start <secret>` step, inline Telegram confirm/cancel (`pc:` / `px:`), and final initiating-session web confirmation.
- Choice: option (b) per the advisor's correction authorization. Group linking (`/lienket <code>`) stays unchanged.
- Standing doc amendments needed (advisor-owned):
  - `docs/05-database-design.md`: document `chat_identity_pairings` table (`id`, `platform`, `user_id`, `session_id`, `secret_hash`, `status`, `platform_user_id`, `platform_user_name`, `telegram_confirmed_at`, `expires_at`, `consumed_at`, `created_at`) and `chat_link_codes` `CHECK (purpose in ('group'))`.
  - `docs/05-api-spec.md`: document `POST /me/chat-identities/telegram/pairings`, `GET /me/chat-identities/telegram/pairings/{pairingId}`, `POST .../confirm`, `POST .../cancel`, and deprecation/rejection (`400 TOKEN_INVALID`) of `POST /me/chat-identities/claim`.
  - `docs/superpowers/specs/2026-11-15-phase-4-collaboration-design.md` (sections 5.2, 5.3, 5.5, 7.3) & `docs/06-ux-ui/user-flows.md`: replace the bearer-link user identity flow with two-sided pairing and new `/link/telegram` strings.
  - `docs/04-adr.md`: record ADR for two-sided web+Telegram pairing proving both account session and Telegram sender ownership before activating `chat_identities`.

### DR2_3 — Server-side RFC 8058 one-click unsubscribe and durable issued-token hashes (R2 & R3)

- **Problem:** (R2) `List-Unsubscribe` pointed to Next.js page `GET /notifications/unsubscribe?token=...`, so a mail provider's `POST` with `List-Unsubscribe=One-Click` and no session/Origin/JavaScript returned Next.js HTML without disabling email settings, while the API route also enforced `requireSameOrigin`. (R3) `apps/worker/src/mailer.ts` held issued raw tokens in an in-memory `Map`, rotating `notification_settings.unsubscribe_token_hash` after worker restart or across concurrent worker instances and invalidating previously emailed links.
- **Options:**
  1. Dedicated `notification_unsubscribe_tokens` table (hash-only, unique `token_hash`, FK `user_id -> users.id ON DELETE CASCADE`, backfilled from `notification_settings.unsubscribe_token_hash`) + Next.js 16 `apps/web/src/proxy.ts` rewriting `POST /notifications/unsubscribe` to `/api/v1/notifications/unsubscribe` while `GET /notifications/unsubscribe` continues to serve the browser page + canonical API handler accepting query/form/JSON without `requireSameOrigin` and retaining 30/min/IP rate limiting.
  2. Move unsubscribe URL to `/api/v1/notifications/unsubscribe` directly (breaks browser GET HTML page UX).
- **Choice:** Option 1.
- **Reason:** Preserves the exact advertised URL `/notifications/unsubscribe?token=...` for both mail-client RFC 8058 `POST` (no session/Origin/JS) and browser `GET`, keeps one canonical API service/DB path, stores only SHA-256 hashes durably across restarts and multiple workers, retains legacy `notification_settings.unsubscribe_token_hash` compatibility, and cleans up all issued hashes automatically on account deletion via `ON DELETE CASCADE`.
- **Retention & cleanup:** Issued token hashes remain valid until the account is deleted (cascaded via `notification_unsubscribe_tokens_user_id_users_id_fk`) so older emails in a user's inbox keep working. Re-enabling email switches in `/account` does not require deleting hashes; repeated unsubscribe remains idempotent (`204`).
- **Standing-doc amendments needed (advisor-owned):**
  - `docs/05-database-design.md`: document `notification_unsubscribe_tokens` (`id`, `user_id` FK cascade, `token_hash` unique, `created_at`).
  - `docs/05-api-spec.md`: document `POST /notifications/unsubscribe` (proxied to `POST /api/v1/notifications/unsubscribe`) accepting RFC 8058 `application/x-www-form-urlencoded` (`List-Unsubscribe=One-Click`), query `?token=`, or JSON `{ token }`, intentionally exempt from `requireSameOrigin` and protected by 256-bit token + 30/min/IP rate limit.
  - `docs/04-adr.md` and `docs/superpowers/specs/2026-11-15-phase-4-collaboration-design.md`: record durable multi-token hash retention replacing `D4B.1`'s in-memory rotation approach.

## Round 2 Review Corrections Decisions (2026-11-19)

### DR9 — Per-recipient send-time revalidation in `send-digest` (R9)

- **Problem:** `runSendDigest` loaded all eligible notifications for all recipients in one upfront query and sent emails from that snapshot. Removing a later recipient from a group (or changing opt-out/read/verification/email state) during an earlier recipient's send could leak private data from the removed group.
- **Options:** (a) check membership only against an in-memory snapshot; (b) query distinct candidate `userId`s up front and re-query each recipient's currently eligible rows via `listUnreadDigestNotifications(db, { since, until: now, userId })` immediately before building and sending that recipient's email.
- **Choice:** Option (b).
- **Reason:** Revalidates membership, unread state, verified email, current email address, and digest preference atomically against authoritative DB state for each recipient, rebuilds single/multi-group formatting and overflow counts cleanly without leaking removed-group data or counts, holds no DB transaction or lock across mailer I/O, and requires no schema change.

### DR10 — Comments and dispute resolution on soft-deleted transactions (R10)

- **Problem:** Commit `e2e4be7` rejected both `createComment` and `resolveDispute` on soft-deleted transactions (`404`), conflicting with Plan `4a-comments.md` Task 4A.1 (comments readable and writable on soft-deleted transactions) and preventing closure of an already-open dispute after transaction deletion.
- **Options:** (a) allow both `createComment` and `openDispute` on deleted transactions; (b) restore `createComment` and `resolveDispute` on soft-deleted transactions while keeping `openDispute` forbidden (`404`) on soft-deleted transactions.
- **Choice:** Option (b).
- **Reason:** Matches Plan 4A.1 ("Comments are readable and writable on a soft-deleted transaction") and Spec 3.2 ("Editing/deleting a transaction does not implicitly resolve a dispute; the opener or owner resolves it"), while preserving the narrow rule against opening a brand-new dispute on an already-deleted transaction and never auto-restoring the transaction.
