# Phase 4 run — progress

## Status

Date: 2026-11-18. The owner approved the Phase 4 spec (including section 14, amendment 2026-11-18) and plan, and authorized continuous execution from Task 0 through Task 4D.4 on branch `phase-4`, created by the advisor from local `main` at `b3cf730`. Implementation agent: Antigravity. Advisor and reviewer: Claude. Checks with a real AI provider are deferred by the owner until all phases, including iOS, are done; use `AI_PROVIDER=fake` where the AI path is exercised.

## Task checklist

- [x] Task 0 — re-baseline (`docs(run): re-baseline phase 4`)
- [x] 4A.1 — API: comments
- [x] 4A.2 — API: disputes
- [x] 4A.3 — Web: the transaction view; stage gate
- [x] 4B.1 — Notification core
- [x] 4B.2 — Web: bell and notification list
- [x] 4B.3 — Mail: immediate, digest, unsubscribe
- [x] 4B.4 — Debt reminders
- [x] 4B.5 — Web: reminders and settings; stage gate
- [x] 4C.1 — Webhook, sender, identities and links
- [x] 4C.2 — Commands: `/chi`, `/sodu`, `/huy`, `/trogiup`
- [x] 4C.3 — Web: linking screens
- [x] 4C.4 — Stage gate 4C and the bot runbook
- [x] 4D.1 — Database and money path: the approval filter
- [x] 4D.2 — API: threshold, pending, approve, reject
- [x] 4D.3 — Web: approval
- [x] 4D.4 — README, non-functional checks, final gate

## Baseline failures

None.

## Not verified

- Real SMTP delivery, email client rendering, and mail-client one-click `List-Unsubscribe-Post` execution (no SMTP server/domain locally; exercised with console mailer).
- Real `TelegramChatSender` HTTP calls to `api.telegram.org`, `setWebhook` registration against a public HTTPS endpoint, and inline button/message rendering inside Telegram apps (no bot token or external calls locally; exercised with `TELEGRAM_PROVIDER=console`).

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

## Task 4A.1 — approach

- Files to create/modify: create `packages/db/src/schema-comments.ts`, `packages/db/src/comments.ts`, migration, `packages/contract/src/comment.ts`, `apps/api/src/services/comments.ts`, `apps/api/src/routes/comments.ts`; modify `packages/db/{drizzle.config.ts,src/index.ts}`, `packages/contract/src/{transaction,jobs,index}.ts`, `apps/api/src/{app,rate-limit}.ts`, `apps/api/src/services/transactions.ts`.
- Approach: store comments in `comments` with soft-delete (`deleted_at`) and `(transaction_id, created_at)` index, add `commentCount` to transaction list and detail DTOs via grouped counts, paginate comments oldest-first (50/page) with `{ createdAt, id }` keyset cursor, enforce 20 comments/minute/user rate limit and `Idempotency-Key` on `POST`, and verify transaction-in-group (including soft-deleted transactions) before reading or writing.
- Why simplest: reuses `lockGroup`, `getGroupAccess`, `runIdempotent`, and existing keyset cursor encoding without extra tables or streams.
- Rejected alternative: embedding comment bodies directly in transaction list responses, which would bloat feed pagination payloads.

### Task 4A.1 results

- `pnpm check`: passed (`Checked 406 files`, all 8 workspace typechecks Done). Migration `0014_funny_beast.sql` generated and applied to `songphang_phase4_gate`.
- `exercise_4a1.mts` against `songphang_phase4_gate` (API on port 4010):
  - `EXERCISE_4A1_PASSED`: Hùng (viewer) commented `201` (`authorName: "Hùng"`, `mine: true`), idempotent replay returned same comment ID, Lan listed (`mine: false`), Lan delete Hùng's comment -> `403`, Minh (owner) delete -> `204` (`commentCount: 0`), 1001 chars / `""` / whitespace -> `400` each, `<script>alert(1)</script>` -> `201` stored verbatim, comment on soft-deleted transaction -> `201`, outsider list & post -> `404`/`404`, Lan 21st comment in 1 min -> `429`, balances identical before and after.
  - `pnpm db:check-balances` -> `All groups balanced`.
- Security review: checked relevant items 1, 2, 3, 4, 5, 6, 8; no issues found.

## Task 4A.2 — approach

- Files to create/modify: create `packages/db/src/schema-disputes.ts`, `packages/db/src/disputes.ts`, migration, `apps/api/src/services/disputes.ts`; modify `packages/db/{drizzle.config.ts,src/index.ts}`, `packages/contract/src/{transaction,error}.ts`, `apps/api/src/services/{transactions,transaction-changes}.ts`, `apps/api/src/routes/{transactions,transaction-changes,comments}.ts`.
- Approach: add `transaction_disputes` with partial unique index `(transaction_id) WHERE resolved_at IS NULL`, expose `dispute: TransactionDisputeDto | null` on `TransactionDto` and `TransactionListItemDto` (computing `mine` from `viewerUserId`), implement `openDispute` (`409 DISPUTE_ALREADY_OPEN`) and `resolveDispute` (`409 DISPUTE_NOT_OPEN`, `403 FORBIDDEN` unless opener or owner) inside `lockGroup`, log `dispute_open`/`dispute_resolve` activity entries, and publish `["transactions", "activity"]`.
- Why simplest: enforces single-open-dispute invariant at both service lock and DB partial unique index without modifying balance/split paths.
- Rejected alternative: storing dispute state as columns on `transactions`, which would lose multi-round dispute history and conflict with optimistic locking `version` bumps.

### Task 4A.2 results

- `pnpm check`: passed (`Checked 410 files`, all 8 workspace typechecks Done). Migration `0015_colossal_ezekiel_stane.sql` generated and applied to `songphang_phase4_gate`.
- `exercise_4a2.mts` against `songphang_phase4_gate` (API on port 4010):
  - `EXERCISE_4A2_PASSED`: Hùng (viewer) opened dispute `201` (`openedByName: "Hùng"`, `mine: true`, `mine: false` for Minh), balances unchanged, duplicate open by Lan -> `409 DISPUTE_ALREADY_OPEN`, Lan resolve -> `403`, Lan edit amount -> `200` with dispute still open, Hùng resolve -> `200` (`dispute: null`), repeat resolve -> `409 DISPUTE_NOT_OPEN`, reopen by Hùng + resolve by Minh (owner) -> `201`/`200`, outsider open -> `404`, `GET .../activity` recorded all 4 dispute entries with actor names, invalid reasons (`""`, 501 chars) -> `400`.
  - `pnpm db:check-balances` -> `All groups balanced`.
- Security review: checked relevant items 1, 2, 3, 4, 5, 6, 8; no issues found.

## Task 4A.3 — approach

- Files to create/modify: create `apps/web/src/lib/comments.ts`, `apps/web/src/components/transaction/{TransactionSummary,CommentThread,CommentField,DisputeBlock}.tsx`, `apps/web/src/app/g/[groupId]/tx/[transactionId]/view/page.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/components/ui/Icon.tsx`, `apps/web/src/lib/{use-group-events,activity-sentences}.ts`, `apps/web/src/components/feed/{ExpenseRow,LedgerPill,ExpenseStream}.tsx`, `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx`, `apps/web/src/components/expense-form/ExpenseForm.tsx`.
- Approach: route all stream row taps to `/g/${groupId}/tx/${transaction.id}/view` (S20) showing `TransactionSummary` (reusing `ConfirmationCard` card styling and `PhotoRow readOnly`), `DisputeBlock` (`bg-coral text-ink`, contrast 7.43:1, with `ConfirmDialog` for reason), `CommentThread` (plain text nodes with `whitespace-pre-wrap`), and fixed-bottom `CommentField` (`Enter` sends, `Shift+Enter` newline); link `Sửa` in the header to the existing edit page and update edit's back href to the view.
- Why simplest: reuses `ScreenHeader`, `ShareShapes`, `PhotoRow`, `ConfirmDialog`, `useTransaction`, and `useGroupEvents` without adding client state stores or extra routes.
- Rejected alternative: putting comments and disputes inside a modal drawer on the stream, which would diverge from S20's deep-linkable `/g/{id}/tx/{txId}/view` URL needed by Phase 4 notifications.

### Task 4A.3 — results
- `pnpm check` passed (416 files, 0 errors; 8 workspace typechecks Done) and `API_ORIGIN=http://localhost:4010 pnpm build` passed (S20 `/g/[groupId]/tx/[transactionId]/view` built).
- Contrast ratio check for `DisputeBlock` (`bg-coral` `#ff8a73` + `text-ink` `#1c1b22`): relative luminances 0.40675 and 0.01146 -> **7.43:1** (passes WCAG AA and AAA).
- Security review on diff: clean (plain React text rendering with `whitespace-pre-wrap`, zero `dangerouslySetInnerHTML`/`eval`/raw HTML, server-derived viewer vs editor visibility of `Sửa`).
- Live Chrome two-context browser exercise against disposable `songphang_phase4_gate` (Minh owner in `isolatedContext=minh-4a3`, Hùng viewer in `isolatedContext=hung-4a3`):
  1. Tapped `Bún chả 4A3` in both windows -> navigated to `/g/01a1ef33-65d4-76c6-8490-8539fc3c45d9/tx/01a1ef33-6612-7e9e-9e26-6108c9a60d0a/view`.
  2. Minh saw `Sửa` (click -> edit screen `/tx/...` loaded, `Quay lại` returned to `/view`); Hùng saw no `Sửa` link and had active comment box and `Khoản này chưa đúng`.
  3. Hùng sent `Hôm đó mình không ăn` via keyboard `Enter` and `<script>alert(1)</script>` via `Gửi` -> both appeared immediately in Minh's window via SSE without reload; `mainScriptTags: 0`, rendered as literal text.
  4. Hùng opened `Khoản này chưa đúng`, submitted `Mình không đi hôm đó` -> `DisputeBlock` (`Hùng cho rằng khoản này chưa đúng`) appeared live in Minh's window via SSE; group feed in Hùng's window showed `đang hỏi lại` and `2 bình luận`.
  5. Minh clicked `Đã giải quyết` -> snackbar `Đã giải quyết.` displayed, button reset to `Khoản này chưa đúng`, and `đang hỏi lại` disappeared live from Hùng's group feed via SSE without reload.
  6. Keyboard `Tab` traversed `Khoản này chưa đúng` -> `Xoá bình luận`; zero console errors in either window.

### Stage Gate 4A — results
- `pnpm check`: 416 files, 0 errors (3 pre-existing `noImgElement` warnings), 8/9 workspace typechecks Done.
- `API_ORIGIN=http://localhost:4010 pnpm build`: `next build` passed (`/g/[groupId]/tx/[transactionId]/view` built).
- Disposable database `songphang_phase4_gate` reset (`DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS drizzle CASCADE;`), migrated (`0000`–`0015`), seeded (`Development users seeded`).
- `task0_samples.mts`: `ALL_87_QUICK_ENTRY_SAMPLES_PASSED`
- `task0_replay.mts`: `DISABLED_FEATURES_CHECK_PASSED {"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false}` and `PHASE_1_2_3_BASELINE_REPLAY_PASSED {"groupId":"01a1ef39-d4f4-7ae9-a2f8-d1cc3ff0718c","tx1VersionAfterEdit":2,"vietqrPresent":true,"settlementConfirmed":"confirmed","budgetState":"near","statsTotal":200000,"scanStatus":"done","targetAdjustment":{"kind":"other","amount":8000},"parseAiReader":"ai"}`
- `exercise_4a1.mts`: `EXERCISE_4A1_PASSED {"c1Author":"Hùng","lanViewMine":false,"delLanStatus":403,"delMinhStatus":204,"scriptBody":"<script>alert(1)</script>","commentOnDeletedTxStatus":201,"outsiderStatuses":[404,404],"rateLimit429OnRequestNumber":21,"finalCommentCount":22,"balancesIdentical":true}`
- `exercise_4a2.mts`: `EXERCISE_4A2_PASSED {"openedBy":"Hùng","balancesIdenticalDuringDispute":true,"dupStatus":409,"lanResolveStatus":403,"stillOpenAfterEdit":true,"hungResolveStatus":200,"resolveAgainCode":"DISPUTE_NOT_OPEN","ownerResolveStatus":200,"outsiderStatus":404,"disputeActivityActions":["dispute_resolve:Minh","dispute_open:Hùng","dispute_resolve:Hùng","dispute_open:Hùng"]}`
- `pnpm db:check-balances`: `All groups balanced` (0 mismatches across 4 groups).

## Task 4B.1 — approach
- Approach: add `group_users.muted` and create `notifications` + `notification_settings` tables in Drizzle (`schema-notifications.ts`, migration `0016`), add discriminated-union `NotificationPayload` for all 12 kinds in `@songphang/contract`, implement `notify(tx, ...)` resolving non-muted non-actor `group_users` inside callers' existing DB transactions (`transactions`, `transaction-changes`, `comments`, `disputes`, `settlement-requests`, budget warnings), and expose `/me/notifications*` (inner-joining `group_users`) plus `PUT /groups/{groupId}/me/muted`.
- Why simplest: inserting notifications directly through the service's open `DbExecutor` avoids an outbox table or post-commit race condition and guarantees rollback atomicity.
- Rejected alternative: publishing internal domain events post-commit to create notification rows asynchronously, which breaks transactional atomicity when a write fails after queueing.

### Task 4B.1 — results
- `pnpm check`: 423 files, 0 errors (3 pre-existing `noImgElement` warnings), 8/9 workspace typechecks Done.
- Generated & applied `packages/db/drizzle/0016_illegal_cloak.sql` (`notifications`, `notification_settings`, `group_users.muted`, `notifications_user_created_index`).
- `exercise_4b1.mts`: `EXERCISE_4B1_PASSED {"unauthStatuses":[401,401,401],"row1Share":50000,"minhDisputeCount":1,"minhBudgetOver":true,"mutedHungDelta":0,"removedGroupHiddenFromList":true,"hungUnreadChange":"5->1","crossReadStatus":204,"lanUnreadCleared":"4->0"}` — verified all 9 table rows plus `dispute_resolved`, `settlement_requested`, `settlement_confirmed`, `budget_state` (`over`), outsider mute 404, and cross-user read 204 leaving Lan's row unread.
- Forced rollback test (temporary throw right after `notifyBudgetWarnings` inside `createTransactionIn`): `FORCED_ROLLBACK_4B1_PASSED {"status":500,"txBefore":4,"txAfter":4,"notifBefore":5,"notifAfter":5}`, then reverted and verified clean.
- `pnpm db:check-balances`: `All groups balanced` (0 mismatches across 8 groups).
- Security review: clean (strict Zod schemas on queries/bodies, inner join `group_users` enforces access on list & unread-count, `read` filtered by caller `userId`, outsider mute 404, parameterized Drizzle queries only).

## Task 4B.2 — approach
- Approach: add `notificationText(dto)` in `apps/web/src/lib/notification-text.ts` formatting all 12 kinds per Spec 7.2 (with `Có cập nhật trong nhóm {group}` fallback), add `Bell` (44px accessible button, `9+` cap above 9, window focus refetch + SSE refetch in `use-group-events.ts`) to S2 (`/`) and S4 (`/g/[groupId]`), add S19 `/notifications` with cursor loading & `Đánh dấu đã đọc`, and add `Tắt thông báo nhóm này` on `/g/[groupId]/members` (decision 4).
- Why simplest: reuses `useInfiniteQuery` / `useMutation` patterns and triggers `unread-count` invalidation directly from the existing `useGroupEvents` handler without opening a second SSE stream.
- Rejected alternative: creating a separate user-level `/me/events` SSE endpoint just for the bell, which violates Spec 4.3 ("No new stream").

### Task 4B.2 — results
- `pnpm check`: 428 files, 0 errors (3 pre-existing `noImgElement` warnings), 8/9 workspace typechecks Done.
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`/notifications` built cleanly).
- Live Chrome two-context browser exercise (`minh-4b2`, `hung-4b2` against disposable `songphang_phase4_gate`):
  1. Bell visible on S2 (`/`) and S4 (`/g/[groupId]`) as a 48×48px accessible link (`aria-label="Thông báo, 3 chưa đọc"`).
  2. While Minh had S4 open, Hùng commented on `Lẩu gà lá é 4B2` -> Minh's Bell updated live over SSE to `Thông báo, 4 chưa đọc` without reload.
  3. On S19 (`/notifications`), verified exact Spec 7.2 lines (`expense_added` with `phần bạn 50.000 đ`, `expense_changed`, `comment_added`, `dispute_opened`, `settlement_requested`, `budget_state`) and deep links (`/tx/.../view`, `/balances`, `/stats`).
  4. Tapping an unread row marked only that row read (`3 chưa đọc` -> `2 chưa đọc`) and navigated to S20; clicking `Đánh dấu đã đọc` cleared Minh's unread rows and reset Bell to `Thông báo`.
  5. With 10 unread notifications, Bell rendered `"9+"` badge and `aria-label="Thông báo, 10 chưa đọc"`, size `48x48`.
  6. On `/g/[groupId]/members`, toggled `Tắt thông báo nhóm này` on and off; zero console errors in both windows.
- Security review: clean (plain React text rendering, Zod-validated `NotificationPayload` with safe generic fallback on unknown kinds, no `dangerouslySetInnerHTML`/`eval`).

## Task 4B.3 — approach
- Approach: place pure `formatAmount`/`formatMoney` and `formatNotificationLine` in `@songphang/core` (shared by `apps/web` and `apps/worker`), add `job_checkpoints` + notification-settings/digest/prune DB helpers in `packages/db`, wire `send-notification-mail` enqueueing into `notify.ts` for immediate kinds, expose `/me/notification-settings` and public `/notifications/unsubscribe` (30/min/IP -> 204 or 404) in `apps/api`, register `send-notification-mail`, `send-digest` (`0 20 * * *` `Asia/Ho_Chi_Minh`), and `prune-notifications` (90 days) in `apps/worker`, and add `/notifications/unsubscribe` + S13 email toggles in `apps/web`.
- Why simplest: reuses `Mailer` console output (adding `List-Unsubscribe` / `List-Unsubscribe-Post` headers + non-PII `mail.sent` JSON log line) and `notification-settings` schema already created in migration `0016`, adding only `job_checkpoints` for reliable digest watermarks.
- Rejected alternative: adding a separate `packages/mail` workspace package or querying `pgboss` internal job tables (which would break manual `runSendDigest` verification).

### Task 4B.3 — results
- `pnpm check`: 439 files, 0 errors (3 pre-existing `noImgElement` warnings), 8/9 workspace typechecks Done.
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`/notifications/unsubscribe` and `/account` built cleanly).
- Generated & applied `packages/db/drizzle/0017_flimsy_vargas.sql` (`job_checkpoints`).
- `exercise_4b3.mts`: `EXERCISE_4B3_PASSED {"row1ImmediateSubjectMatched":true,"row1ListHeadersPresent":true,"row2SkippedWhenRead":true,"row3DigestFirstSent":3,"row3DigestSecondSent":0,"row4SkippedWhenDigestFalse":true,"row5UnsubscribeStatus":204,"row5MinhSettings":{"emailImmediate":false,"emailDigest":false},"row5LanSettings":{"emailImmediate":true,"emailDigest":true},"row6BadTokenStatuses":[404,404],"row6RateLimit429":true,"row7RemovedSkipped":true,"row8PrunedCount":1}` — verified live worker `send-notification-mail` with `List-Unsubscribe` / `List-Unsubscribe-Post` headers, skip when read or removed, manual `runSendDigest` grouping & incremental checkpoint (`3` sent -> `0` on immediate repeat), `emailDigest: false` skip, unauthenticated `POST /notifications/unsubscribe` (204 on match, 404 on altered/empty token, 429 after 30/min/IP), `runPruneNotifications` deleting 91-day-old row, and non-PII structured log `{"event":"mail.sent","template":...,"userId":...}`.
- Live Chrome check on `/notifications/unsubscribe` & `/account`: bad token rendered `Link này không còn dùng được.`; Lan's printed unsubscribe link unauthenticated rendered `Bạn sẽ không nhận thư thông báo nữa.` + `Bật lại trong Tài khoản`; logging in as Lan on `/account` showed both switches unchecked and allowed toggling both back on; 0 console errors.
- `pnpm db:check-balances`: `All groups balanced` (0 mismatches across 12 groups).
- Security review: clean (only SHA-256 hash stored in `notification_settings.unsubscribe_token_hash`, public unsubscribe route answers uniform 404 on invalid/missing token and limits 30/min/IP, audit log `mail.sent` contains only `template` and `userId`).
- Added real SMTP mail rendering / mail-client one-click header execution to `## Not verified` (local run uses console mailer only).

## Task 4B.4 — approach
- Approach: add `debt_reminders` table (`schema-reminders.ts`) + `groups.reminder_interval_days` (migration `0018`), extend `ErrorCode` (`REMINDER_TOO_SOON`, `MEMBER_NOT_LINKED`) and `GroupDto`/`UpdateGroupRequest`, extract shared `computeGroupTransfers` (reusing `suggestMinimizedSettlements` / `netPairwiseDebts` from `@songphang/core`), implement `POST /api/v1/groups/{groupId}/reminders` supporting `{ fromMemberId, toMemberId }` (429/422/403/400 on cooldown/unlinked/unauthorized/invalid-pair) and `{ all: true }` (`reminded` + `skipped`), and register daily `auto-reminders` cron (`0 9 * * *` `Asia/Ho_Chi_Minh`).
- Why simplest: reuses `notify(..., enqueue)` for `debt_reminder` immediate mails, `getGroupAccess` + `listGroupMembers` for role/linked checks, and shares one `core`-backed transfer calculation between `balances`, `reminders`, and `auto-reminders`.
- Rejected alternative: recomputing or duplicating settlement minimization logic inside `apps/worker`, which risks drift between displayed S5 transfers and reminder amounts.

### Task 4B.4 — results
- `pnpm check`: 445 files, 0 errors (3 pre-existing `noImgElement` warnings; fixed `auto-reminders.ts` optional chain suggestion cleanly), 8/9 workspace typechecks Done.
- Generated & applied `packages/db/drizzle/0018_wise_cerebro.sql` (`debt_reminders`, `groups.reminder_interval_days` CHECK `(3, 7, 14)`).
- `exercise_4b4.mts`: `EXERCISE_4B4_PASSED {"outsiderStatus":404,"row1Reminded":1,"row2Code":"REMINDER_TOO_SOON","row3Status":429,"row4Code":"MEMBER_NOT_LINKED","row5Status":403,"row6Reminded":1,"row6SkippedReasons":["MEMBER_NOT_LINKED","REMINDER_TOO_SOON"],"row7Status":400,"row8AutoRun1":2,"row8AutoRun2":0,"row9Status":403}` — verified all 9 rows, `nextAt` ~24h cooldown, automatic `auto-reminders` worker run sending to linked members (`sent_by = NULL`) with immediate email headers and 0 on immediate repeat, and `PATCH /groups/{groupId}` owner-only check (`403` for editor).
- `pnpm db:check-balances`: `All groups balanced` (0 mismatches across 13 groups).
- Security review: clean (`requireGroupRole` + pair permission check `access.role !== "viewer" || access.memberId === toMemberId`, outsider 404, server-derived transfer amounts from `suggestGroupTransfers`, unlinked member check 422).

## Task 4B.5 — approach

- Approach: add Spec 7.3 (`Tự nhắc nợ`) and 7.4 reminder strings in `vi.ts`, create `apps/web/src/lib/reminders.ts` (`useSendReminder`, `canRemindTransfer`, and Vietnam-time `formatReminderNextAt`), add `Nhắc` to eligible `TransferAction` rows (`SettlementCard` and `OtherSettlements`) and `Nhắc cả nhóm một lần` (when >= 2 pairs qualify) with `Snackbar` feedback on S5 (`balances/page.tsx`), and add the `Tự nhắc nợ` segmented control (`Tắt`, `Mỗi 3 ngày`, `Mỗi tuần`, `Mỗi 2 tuần`) on S11 (`settings/page.tsx`).
- Why simplest: reuses `Switch`/`SegmentedControl`, `Snackbar`, `useUpdateGroup`, and shared `canRemindTransfer` predicate so per-row eligibility and the >=2 group-remind threshold stay in sync.
- Rejected alternative: rendering `Nhắc` unconditionally and letting users hit 422 on unlinked members, which violates Plan 4B.5 ("hidden for them").

### Task 4B.5 results

- `pnpm check`: passed (`Checked 446 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed.
- Security review on diff: clean (plain React text rendering, Zod-validated client/API boundary, zero `dangerouslySetInnerHTML`/`eval`/unchecked redirects/`any`).
- Live Chrome two-context exercise against disposable `songphang_phase4_gate` (`4B5 Live cf05ba93`, `01a1ef5a-d235-7018-ac98-717fc75a3c36`):
  - S5 (`/balances`): `Nhắc` hidden for unlinked debtor `Thu`, rendered on `Lan` and `Hùng` rows, and `Nhắc cả nhóm một lần` rendered (2 linked pairs).
  - Clicked `Nhắc` on Hùng -> snackbar `"Đã nhắc Hùng."`; clicked again immediately -> `"Bạn vừa nhắc Hùng rồi. Nhắc lại được sau 22:51 ngày 19/11."`
  - Hùng's `/notifications` received `"Nhắc nhẹ: bạn cần trả Minh 100.000 đ trong nhóm 4B5 Live cf05ba93"`.
  - Clicked `Nhắc cả nhóm một lần` -> snackbar `"Đã nhắc 1 người."`
  - S5 viewport `485x812`: `scrollWidth === clientWidth === 485`, 0 console errors/warnings.
  - S11 (`/settings`): clicked `"Mỗi tuần"` under `"Tự nhắc nợ"` -> pressed state active and persisted across page reload; `"Tự nhắc nợ"` section width `390` (`scrollWidth: 390`), 0 console errors/warnings.
  - Out of scope: pre-existing `"Hạn mức"` `<MoneyInput>` section on `/settings` overflows (`scrollWidth: 818` inside `390` container at `485x812`); left untouched per `AGENTS.md` §5.

### Stage Gate 4B results

- `pnpm check`: passed (`Checked 446 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`2.3s`, all web routes built including `/notifications`, `/notifications/unsubscribe`, `/g/[groupId]/tx/[transactionId]/view`).
- Reset + migrate + seed on disposable `songphang_phase4_gate`, then replayed full gate suite sequentially (`task-1232`):
  - `ALL_87_QUICK_ENTRY_SAMPLES_PASSED`
  - `DISABLED_FEATURES_CHECK_PASSED {"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false}`
  - `PHASE_1_2_3_BASELINE_REPLAY_PASSED {"groupId":"01a1ef62-46c2-7a04-92c0-3b7ce0b3e4a9","tx1VersionAfterEdit":2,"vietqrPresent":true,"settlementConfirmed":"confirmed","budgetState":"near","statsTotal":200000,"scanStatus":"done","targetAdjustment":{"kind":"other","amount":8000},"parseAiReader":"ai"}`
  - `EXERCISE_4A1_PASSED` (`balancesIdentical: true`, `finalCommentCount: 22`, rate limit 429 on #21, outsider 404/404)
  - `EXERCISE_4A2_PASSED` (`balancesIdenticalDuringDispute: true`, `dupStatus: 409`, `lanResolveStatus: 403`, `resolveAgainCode: "DISPUTE_NOT_OPEN"`)
  - `EXERCISE_4B1_PASSED` (`unauthStatuses: [401,401,401]`, `mutedHungDelta: 0`, `removedGroupHiddenFromList: true`, `hungUnreadChange: "32->28"`, `lanUnreadCleared: "13->0"`)
  - `EXERCISE_4B3_PASSED` (`row1ImmediateSubjectMatched: true`, `row1ListHeadersPresent: true`, `row2SkippedWhenRead: true`, `row3DigestFirstSent: 3`, `row3DigestSecondSent: 0`, `row4SkippedWhenDigestFalse: true`, `row5UnsubscribeStatus: 204`, `row6BadTokenStatuses: [404,404]`, `row6RateLimit429: true`, `row7RemovedSkipped: true`, `row8PrunedCount: 1`)
  - `EXERCISE_4B4_PASSED` (`outsiderStatus: 404`, `row1Reminded: 1`, `row2Code: "REMINDER_TOO_SOON"`, `row3Status: 429`, `row4Code: "MEMBER_NOT_LINKED"`, `row5Status: 403`, `row6Reminded: 1`, `row7Status: 400`, `row8AutoRun1: 2`, `row8AutoRun2: 0`, `row9Status: 403`)
  - `pnpm db:check-balances` -> `All groups balanced` (all 7 groups sum 0, mismatches 0).

## Task 4C.1 — approach

- Files to create/modify: create `packages/db/src/schema-chat.ts`, `packages/db/src/chat.ts`, migration `0019_*.sql`, `packages/contract/src/chat-link.ts`, `apps/api/src/bot/{chat-sender,telegram-sender,console-sender,telegram-update,link-codes}.ts`, `apps/api/src/bot-messages.ts`, `apps/api/src/services/chat-links.ts`, `apps/api/src/routes/{chat-links,telegram-webhook}.ts`; modify `packages/db/{drizzle.config.ts,src/index.ts}`, `packages/contract/src/{error,index}.ts`, `apps/api/src/{config,app,server,rate-limit}.ts`, `apps/api/src/routes/features.ts`, `.env.example`.
- Approach: verify Bot API `sendMessage`, `answerCallbackQuery`, `InlineKeyboardMarkup`, and `setWebhook` schemas (`chat_id`, `text`, `reply_markup.inline_keyboard`, `callback_query_id`, `secret_token`, `allowed_updates`); store the 5 chat tables in `schema-chat.ts` with SHA-256 single-use 8-char codes (32-bit-safe `crypto.randomInt` over the 29-char alphabet), atomic `bot_updates` deduplication, `timingSafeEqual` secret comparison returning `404 NOT_FOUND` on mismatch or disabled feature, raw text parsing in webhook so invalid JSON or oversized updates return `200 {}`, and per-chat rate limiting returning `Chậm lại một chút nhé.` once per 1-minute window.
- Why simplest: isolates `TELEGRAM_BOT_TOKEN` inside `telegram-sender.ts`, decouples webhook rate limiting and deduplication before dispatching commands cleanly in `4C.2`, and avoids mutating `FeaturesResponse` shape by exposing `botUsername` on `GET /groups/{groupId}/chat-links`.
- Rejected alternative: registering Telegram body validation through Hono OpenAPI automatic JSON middleware, which returns 400 before our custom hook runs on malformed non-JSON payloads and could cause Telegram webhook retries.

### Task 4C.1 results

- Verified Telegram Bot API shapes (`core.telegram.org/bots/api`): `sendMessage` (`chat_id`, `text`, `reply_markup.inline_keyboard`), `answerCallbackQuery` (`callback_query_id`, `text`), and `setWebhook` (`url`, `secret_token`, `allowed_updates`).
- Migration `0019_sad_violations.sql` generated and applied (`bot_drafts`, `bot_updates`, `chat_identities`, `chat_link_codes`, `chat_links`).
- `pnpm check`: passed (`Checked 459 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `exercise_4c1.mts` against `songphang_phase4_gate`:
  - `EXERCISE_4C1_PASSED`: missing secret and equal-length wrong secret -> 404 with 0 `bot_updates` rows; valid secret unlinked chat -> 200 with Spec 5.5 reply; duplicate `update_id` -> 200 no-op; non-JSON body and 5,000-char text -> 200 no-op; 32 updates in 1 minute -> `"Chậm lại một chút nhé."` printed once; editor `POST .../chat-links/code` -> 403; outsider -> 404; owner code generated + `/lienket <code>` from chat `-1001` -> linked + listed; reuse & backdated expired code -> bad/expired reply; re-link `-1001` -> 1 row kept; user claim valid / 409 `CHAT_IDENTITY_TAKEN` / 400 `TOKEN_INVALID` / unbind verified; unset `TELEGRAM_PROVIDER` -> webhook 404 & `features.telegram: false`; `APP_ENV=production` + `TELEGRAM_PROVIDER=console` refused startup (`exit 1`).
  - `pnpm db:check-balances` -> `All groups balanced` (8 groups).
- Security review: checked `timingSafeEqual` secret comparison, non-exposure of `TELEGRAM_BOT_TOKEN`, SHA-256 link code hashing, `requireGroupRole("owner")` + `requireVerifiedEmail` + `requireSameOrigin` on link management routes, and plain-text `sendMessage` without `parse_mode`.

## Task 4C.2 — approach

- Files to create/modify: create `apps/api/src/bot/{resolve-actor,dispatch,callbacks}.ts`, `apps/api/src/bot/commands/{lienket,chi,sodu,huy,trogiup}.ts`, `apps/worker/src/jobs/prune-bot-data.ts`; modify `packages/contract/src/jobs.ts`, `packages/db/src/chat.ts`, `apps/api/src/bot-messages.ts`, `apps/api/src/routes/telegram-webhook.ts`, `apps/worker/src/main.ts`.
- Approach: route bot updates through `dispatchWebhookUpdate` (`dispatch.ts`) using `resolveActor` (`chat_links` -> verified `chat_identities` -> `group_users`), `/chi` invoking `parseSentence(..., { ai: true })` and saving JSON `bot_drafts`, callbacks `s:{id}` / `d:{id}` re-checking membership/role at tap time and calling `runIdempotent` + `createTransaction`, `/sodu` calling `getBalances` + formatting via `@songphang/core` `formatMoney`, `/huy` calling `setTransactionDeleted` within 10 minutes, `/trogiup` / `/start` sending command help, and an hourly `prune-bot-data` worker job.
- Why simplest: reuses `parseSentence`, `runIdempotent`, `createTransaction`, `getBalances`, and `setTransactionDeleted` directly with zero duplicated ledger/AI/notification logic and keeps `/chi` > 300 chars safely handled as "not understood" without crashing or storing drafts.
- Rejected alternative: parsing `/chi` or computing splits separately inside bot code, which would drift from quick-entry AI limits, member matching, and notification triggers.

### Task 4C.2 results

- `pnpm check`: passed (`Checked 469 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `exercise_4c2.mts` against `songphang_phase4_gate` (`TELEGRAM_PROVIDER=console`, `AI_PROVIDER=fake`):
  - `EXERCISE_4C2_PASSED`: verified all 17 table rows (`999` stranger link button without draft; Lan `111` `/chi cà phê 180k chia 4` draft matching `/transactions/preview` shares; `222` tap `s:` -> `"Chỉ Lan lưu được khoản này."`; Lan tap `s:` -> `"Đã lưu: cà phê · 180.000 đ."` with `createdBy: Lan`; repeat tap silent; viewer `222` `/chi` refused; empty `/chi`; unparsed `/chi abc xyz` with `Mở form` link; AI fallback `/chi lẩu 300k lan 100 lan 200` prefixed `"Đọc bằng AI."` + `d:` drop -> `"Đã bỏ."`; `/sodu` matching `GET .../balances` + `"Quỹ còn 200.000 đ"` with active fund; `/huy` soft-deleting + activity log, second `/huy` -> nothing; 11m expired draft -> expired reply; demoted viewer at tap time -> viewer reply; removed member `/sodu` -> not-in-group reply; `/chi@OtherBot` ignored; `/trogiup@songphangtestbot` help; bad callback `x:1` and cross-chat `s:` ignored; `/chi <script>` and 400-char sentence safely rejected with no drafts stored; `runPruneBotData` pruned `drafts: 2, codes: 9, updates: 1`).
  - `pnpm db:check-balances` -> `All groups balanced` (14 groups).
- Security review: every command and callback resolves caller via verified `chat_identities` + `group_users` and re-checks current role at `s:{id}` save time; no user-submitted bot text sent as HTML/Markdown; raw link code never logged outside `/link/telegram` URL generation.

## Task 4C.3 — approach

- Files to create/modify: create `apps/web/src/lib/chat-links.ts`, `apps/web/src/components/settings/TelegramCard.tsx`, `apps/web/src/components/account/TelegramIdentityCard.tsx`, `apps/web/src/app/link/telegram/page.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/app/g/[groupId]/settings/page.tsx`, `apps/web/src/app/account/page.tsx`, `apps/web/src/app/g/[groupId]/tx/new/page.tsx`, `apps/web/src/components/expense-form/use-expense-form.ts`.
- Approach: add Spec 7.3 Telegram strings to `vi.ts`, create TanStack Query hooks in `chat-links.ts`, guard `TelegramCard` and `TelegramIdentityCard` behind `features.telegram === true`, wrap `/link/telegram` in `<Suspense>` with `useSessionGuard` (redirecting through `/login?next=...` safely) and explicit `Liên kết` button claim, and accept `?form&text=` on `/g/[groupId]/tx/new` running `readSentence` first and falling back to prefilling `description` with `text`.
- Why simplest: mirrors existing `InviteLinkCard`, `NotificationSettingsCard`, `NotificationsPage` session guard, and `useExpenseForm` `FormPrefill` patterns without extra state stores or duplicate parsers.
- Rejected alternative: auto-claiming the code in a `useEffect` on `/link/telegram`, which violates CSRF-safe explicit confirmation (`Liên kết` button + showing signed-in email) and could consume a one-time code unintentionally on tab prefetch.

### Task 4C.3 results

- `pnpm check`: passed (`Checked 473 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`/link/telegram` built cleanly).
- Live Chrome two-context exercise against disposable `songphang_phase4_gate` (`TELEGRAM_PROVIDER=console`, `TELEGRAM_BOT_USERNAME=SongPhangTestBot`):
  - S11 (`/g/.../settings`) as Minh: displayed `Liên kết nhóm Telegram` and `@SongPhangTestBot`; generated `/lienket EMNPNQ2U` with `Sao chép` -> `Đã sao chép` and `Mã có hiệu lực 10 phút.`; linked chat `-1003` -> reload displayed `-1003` with `Bỏ liên kết` -> clicked `Bỏ liên kết` -> removed cleanly.
  - `?form&text=abc%20xyz` on `/g/.../tx/new`: rendered `<ExpenseForm>` directly with `Mô tả` prefilled `"abc xyz"`.
  - Signed-out Chrome opening `/link/telegram?code=VG73SN96` redirected to `/login?next=%2Flink%2Ftelegram%3Fcode%3DVG73SN96`.
  - Signed-in as Lan on `/link/telegram?code=VG73SN96`: rendered `"Liên kết Telegram với tài khoản lan@dev.songphang.local?"` -> clicked `Liên kết` -> `"Đã liên kết. Quay lại Telegram để tiếp tục."` -> reloaded same URL and clicked `Liên kết` -> `"Link này không còn dùng được."`.
  - S13 (`/account`) as Lan: rendered `Telegram` / `Đã liên kết với Telegram` / `Bỏ liên kết` -> clicked `Bỏ liên kết` -> card removed. Zero console errors or warnings across both tabs.
- Security review: `safeNext` / `loginPath` preserves safe relative redirects, explicit button triggers POST `/me/chat-identities/claim`, and `code` is never logged or sent elsewhere.

## Task 4C.4 — approach

- Files to create/modify: create `docs/runbooks/telegram.md`; update `docs/superpowers/runs/phase-4/{progress,manual-checks}.md`.
- Approach: author English Telegram setup/webhook/rotation runbook with copyable commands matching implemented env vars and endpoints, document unverified live Telegram integration items honestly under `## Not verified`, append real-bot manual checks to `manual-checks.md`, and run Stage Gate 4C on freshly reset `songphang_phase4_gate`.
- Why simplest: consolidates bot operations and verification in one self-contained runbook without modifying application code.
- Rejected alternative: automating live `setWebhook` verification from CI/local runner, which is forbidden by run constraints (`never call api.telegram.org`).

### Task 4C.4 & Stage Gate 4C results

- Created [docs/runbooks/telegram.md](file:///Users/hoojinguyen/Projects/songphang/docs/runbooks/telegram.md) covering `@BotFather` bot creation + `/setprivacy` `Enable`, `TELEGRAM_*` env variables, `setWebhook` (`secret_token`, `allowed_updates`), `getWebhookInfo`, group & user linking, 5 commands, and secret/token rotation.
- Updated `## Not verified` in `progress.md` and added `## After the Telegram bot exists` to `manual-checks.md`.
- Stage Gate 4C (`task-1602`):
  - `pnpm check`: passed (`Checked 473 files`, 3 pre-existing `noImgElement` warnings, 0 errors).
  - `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`2.7s`, all routes built).
  - Reset + migrated + seeded disposable `songphang_phase4_gate`, then ran full gate sequence:
    - `ALL_87_QUICK_ENTRY_SAMPLES_PASSED`
    - `DISABLED_FEATURES_CHECK_PASSED` (`telegram: false`, `receiptReading: false`, `sentenceAi: false`, others `false`)
    - `PHASE_1_2_3_BASELINE_REPLAY_PASSED`
    - `EXERCISE_4A1_PASSED`, `EXERCISE_4A2_PASSED`
    - `EXERCISE_4B1_PASSED`, `EXERCISE_4B3_PASSED`, `EXERCISE_4B4_PASSED`
    - `EXERCISE_4C1_PASSED`, `EXERCISE_4C2_PASSED`
    - `pnpm db:check-balances` -> `All groups balanced` (10 groups, sum 0, mismatches 0).

## Task 4D.1 — approach

- Files to create/modify: modify `packages/db/src/schema-transactions.ts`, `packages/db/src/schema-groups.ts`, `packages/db/src/transactions.ts`, `packages/db/src/balances.ts`, `packages/db/src/check-balances.ts`, `packages/db/src/stats.ts`, `packages/db/src/budgets.ts`, `packages/db/src/fund.ts`, `packages/db/src/groups.ts`; generate migration `0020_*.sql`.
- Approach: add `approval_status`, `approval_decided_by`, `approval_decided_at`, `approval_note` on `transactions` and `approval_threshold` on `groups` with DB check constraints; define one type-safe `countedTransaction(alias: "t" | "transactions")` SQL fragment in `packages/db/src/transactions.ts` (`deleted_at is null and approval_status in ('none', 'approved')`) and apply it to every balance, pairwise-ledger, stats, budget, fund, and export query while keeping `check-balances` mismatch integrity over all live transactions (`deleted_at is null`).
- Why simplest: one shared SQL fragment (`countedTransaction`) guarantees zero divergence across raw `sql` and Drizzle queries without duplicating status/deleted checks.
- Rejected alternative: filtering pending/rejected transactions in TypeScript services after loading rows, which would load unnecessary rows, duplicate balance summation outside Postgres, and fail SQL sum/budget/stat invariants.

### Task 4D.1 results

- Migration `0020_sour_sheva_callister.sql` generated and applied (`transactions.approval_status`, `approval_decided_by`, `approval_decided_at`, `approval_note`; `groups.approval_threshold` + DB check constraints).
- `pnpm check`: passed (`Checked 474 files`, 3 pre-existing `noImgElement` warnings, 0 errors).
- `exercise_4d1.mts` against `songphang_phase4_gate`:
  - `EXERCISE_4D1_PASSED`: with 3 counted expenses totaling 600.000 đ, toggling E3 (`300.000 đ`) to `pending` and `rejected` excluded it identically from `GET .../balances` (`minimizeDebts: true` & `false`, sum = 0, Minh balance `220000 -> 20000`), `GET .../stats` (`600000 -> 300000`), `GET .../budget` (`spent: 600000 -> 300000`), and `GET .../export.csv`, while `checkBalances` printed `All groups balanced`. Setting E3 to `approved` restored all baseline values identically.
- `rg -n "transaction_shares|transaction_payers" packages/db/src` (plus Drizzle table references):
  - `packages/db/src/balances.ts:26,33` (`listBalancesForGroups`) — **filtered** (`${countedTransaction("t")}`).
  - `packages/db/src/balances.ts:59,75` (`listLedgerSides`) — **filtered** (`countedTransaction("transactions")`).
  - `packages/db/src/check-balances.ts:20,23` (`totals`) — **filtered** (`${countedTransaction("t")}`).
  - `packages/db/src/check-balances.ts:28,29,31` (`mismatches`) — **intentionally unfiltered by approval status** (`t.deleted_at is null`): Plan 4D.1 explicitly requires checking payer/share integrity of every live transaction, pending or not.
  - `packages/db/src/stats.ts:104,110` (`sumByMember` CTE `counted`, plus `findCountedDateBounds`, `sumByCategory`, `sumByBucket`) — **filtered** (`${countedTransaction("t")}`).
  - `packages/db/src/budgets.ts` (`sumSpent`) — **filtered** (`${countedTransaction("t")}`).
  - `packages/db/src/fund.ts:36,37` (`fundCashAndContributions`) — **filtered** (`${countedTransaction("t")}`).
  - `packages/db/src/transactions.ts` (`listExportTransactions`, `listGroupLivePayers`, `listGroupLiveShares`) — **filtered** (`countedTransaction("transactions")`).
  - `packages/db/src/transactions.ts` (`listTransactionRows`, `listTransactionPayers`, `listTransactionShares`) — **intentionally unfiltered by approval status**: Decision 4 requires pending/rejected transactions to remain listed and viewable in the feed and S20.
  - `packages/db/src/transaction-changes.ts:40,43` (`clearTransactionSides`), `packages/db/src/transactions.ts` (`insertTransactionPayers/Shares`) — write helpers by single transaction id.
  - `packages/db/src/members.ts:109` (`hasTransactions`) — member deletion guard checking whether any transaction row (including pending/rejected/deleted) still references the member FK.
  - `packages/db/src/schema-transactions.ts:99,116`, `packages/db/src/index.ts:58,59` — schema definitions and exports.
- Security review: type-safe union parameter on `countedTransaction("t" | "transactions")`; DB CHECK constraints enforce valid enum and length bounds.

## Task 4D.2 — approach

- Files to create/modify: create `packages/core/src/approval.ts`, `apps/api/src/services/approval.ts`; modify `packages/core/src/index.ts`, `packages/contract/src/{error,transaction,group}.ts`, `packages/db/src/groups.ts`, `apps/api/src/services/{groups,transactions,transaction-changes,warnings}.ts`, `apps/api/src/routes/{transactions,transaction-changes}.ts`, `apps/api/src/bot/callbacks.ts`.
- Approach: define pure `approvalStatusFor` in `@songphang/core`; add `approval` DTO to transaction responses, `approvalThreshold` & `ownerName` to `GroupDto` (`UpdateGroupRequest` accepts `approvalThreshold`), and `APPROVAL_NOT_PENDING` (`409`); update create/edit/preview warnings so pending/rejected transactions never subtract/add uncounted amounts; add owner-only `approve`/`reject` service logging activity, firing `approval_decided` notifications, and re-evaluating budget warnings on approve; append ` Khoản này chờ {owner} duyệt.` in Telegram bot save confirmation when pending.
- Why simplest: reuses `lockGroup`, `lockTransaction`, `notify`, `notifyBudgetWarnings`, and `approvalStatusFor` across HTTP and Telegram creation paths with one set of rules.
- Rejected alternative: computing approval rules separately inside bot handlers or routes, which would duplicate owner lookups and risk differing threshold comparisons between web and Telegram.

### Task 4D.2 results

- `pnpm check`: passed (`Checked 476 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `exercise_4d2.mts` against `songphang_phase4_gate`:
  - `approvalStatusFor` unit assertions passed (1,000,000/1,000,000 non-owner -> `pending`; 999,999 -> `none`; owner -> `none`; threshold null -> `none`; transfer 5,000,000 -> `none`; income 5,000,000 -> `none`).
  - `EXERCISE_4D2_PASSED`: verified all 13 rows (`r1Status: "pending"` with balances 0 & `approval_requested` notification for Minh; `r2Balances` Lan +666,666 / Minh -333,333 / Hùng -333,333; Lan approve -> 403, outsider -> 404; Minh approve -> `r4Balances` Lan +1,466,666 / Minh -733,333 / Hùng -733,333 & `approval_decided` for Lan; repeat approve -> 409 `APPROVAL_NOT_PENDING`; Lan edit to 1,500,000 -> `pending` & balances back to Row 2; Minh reject with `"Chưa có hoá đơn"` -> rejected with note, balances unchanged; Lan edit to 900,000 -> `none` & balances Lan +1,266,666 / Minh -633,333 / Hùng -633,333; owner 5,000,000 -> `none`; transfer 2,000,000 -> `none`; threshold `null` then Lan 3,000,000 -> `none`; Lan threshold PATCH -> 403; reject 301-char note -> 400; Telegram bot pending save reply -> `"Đã lưu: máy in · 1.500.000 đ. Khoản này chờ Minh duyệt."`).
  - `pnpm db:check-balances` after rows 1, 4, 7 and at end -> `All groups balanced` (13 groups).
- Security review: `requireGroupRole("owner")` + `requireVerifiedEmail` + `requireWriteLimit` + `requireSameOrigin` on `/approve`, `/reject`, and threshold `PATCH`; outsider 404; Zod bounds note 0..300 and positive integer `approvalThreshold`.

## Task 4D.3 — approach

- Files to create/modify: create `apps/web/src/components/transaction/ApprovalBlock.tsx` and `apps/web/src/components/settings/ApprovalCard.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/lib/activity-sentences.ts`, `apps/web/src/lib/transaction-changes.ts`, `apps/web/src/components/feed/ExpenseRow.tsx`, `apps/web/src/components/feed/LedgerPill.tsx`, `apps/web/src/app/g/[groupId]/tx/[transactionId]/view/page.tsx`, `apps/web/src/app/g/[groupId]/settings/page.tsx`, `apps/web/src/components/expense-form/use-expense-form.ts`, `apps/web/src/app/g/[groupId]/tx/new/ComposeScreen.tsx`, `apps/web/src/components/receipt/ReceiptReview.tsx`.
- Approach: add Spec 7.3/7.5 strings and approval hooks (`useApproveTransaction`, `useRejectTransaction`) following `DisputeBlock` and `BudgetCard`; render `opacity-85` + `chờ duyệt`/`không được duyệt` tags on `ExpenseRow`/`LedgerPill` so all elements clear WCAG AA; mount `ApprovalBlock` on S20 and `ApprovalCard` on S11; surface `Đã lưu. Khoản này chờ {owner} duyệt.` via the group layout `SnackbarProvider` on every pending save (manual form, edit, quick-entry compose, receipt review).
- Why simplest: reuses `ConfirmDialog`, `AmountField`, `Switch`, `SnackbarProvider` (already wrapping `/g/[groupId]/*`), and React Query group invalidation without adding extra routes or state stores.
- Rejected alternative: passing query params (`?saved=pending`) across router redirects to render a separate banner on S4, which would linger across refreshes and browser history.

### Task 4D.3 results

- `pnpm check`: passed (`Checked 478 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
- `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`4.2s`, all web routes built).
- Live two-context Chrome check (`minh-4d3` and `lan-4d3` at `390x844` on `songphang_phase4_gate`):
  - Minh enabled `Duyệt khoản chi lớn` -> `1.000.000` on `/g/{id}/settings` (`Từ số tiền` + `Khoản chi từ mức này chỉ được tính sau khi bạn duyệt.`).
  - Lan saved `1.200.000` (`khách sạn`): snackbar displayed `Đã lưu. Khoản này chờ Minh duyệt.`, stream row dimmed (`opacity: 0.85`) with `chờ duyệt` (`rgb(255, 216, 77)` / `rgb(28, 27, 34)` over `#f6f2fb`, WCAG AA contrast `8.21:1`), and both balances stayed `0 đ`.
  - Minh clicked Bell (`1 thông báo chưa đọc`) -> navigated via `/notifications` (`Lan thêm khách sạn · 1.200.000 đ, cần bạn duyệt`) -> S20 displayed `Khoản này chờ Minh duyệt. Chưa tính vào số dư.` with `Duyệt` / `Không duyệt` -> clicked `Duyệt`: banner cleared, Minh's balance updated to `Bạn cần trả 400.000 đ`, and Lan's open window updated live via SSE to `Bạn được nhận 800.000 đ` without refreshing.
  - Lan edited `khách sạn` to `1.500.000` -> saw `Đã lưu. Khoản này chờ Minh duyệt.` and `chờ duyệt`; Minh opened S20 -> clicked `Không duyệt` -> entered `"Chưa có hoá đơn"` -> submitted `Không duyệt`: S20 displayed `Minh không duyệt khoản này.` + `Chưa có hoá đơn`, and both open S4 streams updated live to `không được duyệt` (`rgb(255, 138, 115)` / `rgb(28, 27, 34)` at `0.85` opacity = `5.35:1` WCAG AA) with balances back at `0 đ`.
  - Zero console errors (`list_console_messages`) in both contexts, `horizontalOverflow: 0`; closed Chrome pages and verified ports `3010`/`4010` free.
- Recorded `D4D.1` (`opacity-85` WCAG AA fix) and `D4D.2` (`bellUnreadLabel`) in [decisions.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/decisions.md).
- Security review: no `dangerouslySetInnerHTML`, `eval(`, `any`, or bypass annotations; owner-only actions gated behind `role === "owner" && verified` and API `ownerWrite`; note bounded `maxLength={300}`.

## Task 4D.4 — approach

- Files to create/modify: modify `README.md`, `docs/superpowers/runs/phase-4/progress.md`, and `docs/superpowers/runs/phase-4/manual-checks.md`.
- Approach: update `README.md` with Phase 4 collaboration features (comments, disputes, in-app & email notifications, reminders, Telegram bot, expense approval, worker schedules, and `TELEGRAM_*` configuration); benchmark `GET /api/v1/me/notifications?limit=30` against 1,000 rows (`< 300 ms`) with `EXPLAIN (ANALYZE, BUFFERS)`; verify keyboard navigation across S20/S19/S11 and Bell badge `aria-label` in Chrome; run Final Stage Gate 4D across all tasks from Task 0 through 4D.2 on reset `songphang_phase4_gate` + `pnpm db:check-balances`.
- Why simplest: reuses existing gate scripts (`task0_samples.mts`..`exercise_4d2.mts`) on a freshly reset database and consolidates all verified documentation and owner checks in one commit.
- Rejected alternative: modifying production Compose (`infra/compose.prod.yml`), which is absent on branch `phase-4` because server provisioning has not run yet.

### Task 4D.4 & Final Stage Gate 4D results

- Updated [README.md](file:///Users/hoojinguyen/Projects/songphang/README.md) with `## Phase 4 features` (S20 comments/disputes, notifications, debt reminders, expense approval), `### Worker jobs and schedules` (`send-notification-mail`, `send-digest` `0 20 * * *`, `auto-reminders` `0 9 * * *`, `prune-notifications` `15 3 * * *`, `prune-bot-data` `0 * * * *` in `Asia/Ho_Chi_Minh`), and `### Telegram bot configuration` (`TELEGRAM_PROVIDER`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET`, `TELEGRAM_BOT_USERNAME`, console mode, commands, and runbook link). (`infra/compose.prod.yml` does not exist yet on this branch.)
- **Performance check (1,000 notifications seeded for Lan in `songphang_phase4_gate`, `ANALYZE notifications`):**
  - `GET /api/v1/me/notifications?limit=30` cold: `5.56 ms`, warm: `4.14 ms`, cursor page 2: `3.92 ms` (all `< 300 ms`; `count: 30`, `nextCursor: true`).
  - `EXPLAIN (ANALYZE, BUFFERS)` execution time: `0.310 ms` (`top-N heapsort Memory: 27kB`, `shared hit=45`), and index verification with `enable_seqscan = off`: `Bitmap Index Scan on notifications_user_created_index` (`Execution Time: 1.045 ms`, `Buffers: shared hit=53`).
- **Keyboard & Bell accessibility walk (`minh-a11y` Chrome `390x844`):**
  - Header Bell link exposed accessible name `"3 thông báo chưa đọc"` with `outlineStyle: "solid"`, `outlineWidth: "2px"` on `Tab` focus; `Enter` opened `/notifications`.
  - On S19 (`/notifications`), `Tab` reached `Đánh dấu đã đọc` (`BUTTON`, `2px solid` outline) and notification links, and `Enter` navigated to S20.
  - On S20 (`/g/{id}/tx/{txId}/view`), `Tab` reached `Khoản này chưa đúng` (`2px solid` outline), `Enter` opened the modal dialog, and `Escape` closed it (`openDialogs: 0`) returning focus cleanly to the trigger button.
  - On S11 (`/g/{id}/settings`), all Phase 4 controls (`Tắt`/`Mỗi 3 ngày`/`Mỗi tuần`/`Mỗi 2 tuần`, `switch "Duyệt khoản chi lớn"`, `Từ số tiền`, `Tạo mã liên kết`) exposed accessible labels/roles with `tabIndex >= 0` (`switch "Gộp nợ"` `2px solid` outline verified); 0 console errors.
- **Final Stage Gate 4D (`songphang_phase4_gate` freshly reset, migrated, seeded):**
  - `pnpm check`: passed (`Checked 478 files`, 3 pre-existing `noImgElement` warnings, 0 errors; all 8 workspace typechecks Done).
  - `API_ORIGIN=http://localhost:4010 pnpm build`: passed (`2.1s`).
  - Acceptance replay: `ALL_87_QUICK_ENTRY_SAMPLES_PASSED`, `DISABLED_FEATURES_CHECK_PASSED` (`telegram: false`, `receiptReading: false`, `sentenceAi: false`), `PHASE_1_2_3_BASELINE_REPLAY_PASSED`, `EXERCISE_4A1_PASSED`, `EXERCISE_4A2_PASSED`, `EXERCISE_4B1_PASSED`, `EXERCISE_4B3_PASSED`, `EXERCISE_4B4_PASSED`, `EXERCISE_4C1_PASSED`, `EXERCISE_4C2_PASSED`, `EXERCISE_4D1_PASSED`, `EXERCISE_4D2_PASSED`, and `pnpm db:check-balances` -> `All groups balanced` across 12 groups (`sum 0; mismatches 0`).
