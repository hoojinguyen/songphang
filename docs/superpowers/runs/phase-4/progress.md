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
