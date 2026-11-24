# Wave 5.5A — Task 0 and Stage 5.5A.1: Database & Additive v1 API

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md). API paths below are relative to `/api/v1`.

### Task 0: Re-baseline `main` and prepare Wave 5.5A run

**Files:** Create or populate `docs/superpowers/runs/phase-5-5a/{progress,decisions,manual-checks,parity-matrix}.md`. Read `apps/ios/AGENTS.md` and `docs/superpowers/runs/phase-5/progress.md`.

- [ ] Confirm branch is `phase-5-5a`, record starting `main` SHA (`378df4d` or later), verify local Node, `pnpm`, Docker Postgres 17, Xcode, and Simulator runtimes.
- [ ] Run baseline checks on clean environment: `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, and Simulator Debug `xcodebuild`.
- [ ] Check whether static `Be Vietnam Pro` `.ttf` weights (`400`–`900`) and `LICENSE.txt` exist in `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` and record exact presence in `decisions.md` (if absent and advisor has not yet placed them, follow `AGENTS.md` §12 "Decide and record" — document the exact source/license/size and verify SIL OFL 1.1 before bundling in Task `5.5A.2.2`, or stop if offline environment blocks retrieval).
- [ ] Verify every existing file/symbol named in this plan against `main` and write the Re-baseline table in `decisions.md`.
- [ ] On a disposable database (`songphang_phase55a_t0`), run migrations and replay a representative Phase 1–5 smoke check (auth, group, quick entry, settlement, receipt scan with `AI_PROVIDER=fake`, approval, Telegram console link, `pnpm db:check-balances` -> `All groups balanced`), then drop the disposable database.
- [ ] Commit run baseline: `docs(run): re-baseline phase 5.5a`.

---

### Task 5.5A.1.1: Database migration (`groups.archived_at`) and `GROUP_ARCHIVED` write guard

**Files:**
- `packages/db/src/schema-groups.ts`
- New Drizzle migration in `packages/db/drizzle/` (generated via Drizzle kit)
- `packages/db/src/groups.ts`
- `packages/contract/src/error.ts`
- New shared service helper `apps/api/src/services/group-guards.ts` (or in `apps/api/src/services/groups.ts`)
- All group write services: `apps/api/src/services/{transactions,transaction-changes,settlement-requests,comments,disputes,approval,members,payment-methods,invites,fund,budget,categories,reminders,attachments,receipt-scans,telegram-pairing,chat-links,groups}.ts`

**Interfaces & Rules:**
- Add `archivedAt: timestamp("archived_at", { withTimezone: true })` (nullable, default `NULL`) to `groups` in `packages/db/src/schema-groups.ts`, plus index `groups_archived_at_idx`.
- Project `archivedAt` in `findGroup` and `listUserGroups` in `packages/db/src/groups.ts`.
- Add `"GROUP_ARCHIVED"` to `ErrorCode` in `packages/contract/src/error.ts`.
- Provide a lock-safe guard helper `assertGroupNotArchived(executor, groupId)` (or inspect the row returned by `lockGroup` inside the service DB transaction) throwing `AppError(409, "GROUP_ARCHIVED", "Group is archived")` whenever `archivedAt !== null`.
- Enforce `409 GROUP_ARCHIVED` on **all** mutating group operations inside the group lock:
  - Creating, updating, deleting, restoring transactions; proposing/accepting/rejecting transaction changes.
  - Creating, confirming, rejecting, cancelling settlement requests.
  - Opening/resolving disputes; creating/deleting comments; approving/rejecting pending transactions.
  - Adding/updating/toggling active members; setting member payment methods; rotating/disabling invite tokens; joining via invite (`POST /invites/{token}/join`); updating group settings (`editGroup` — note `unarchive` and owner `DELETE /groups/{id}` remain permitted).
  - Setting up/modifying shared fund, budget limits, custom categories, debt reminders, attachments, receipt scans, and Telegram chat linking/pairing (including bot webhook expense creation when linked chat's group is archived).
- Keep permitted on archived groups: all `GET` read endpoints, CSV export, `unarchive`, `clone`, `mute/unmute`, `leave group` (under existing owner/balance rules), and owner `DELETE /groups/{groupId}`.

**Exercises:**
- [ ] Generate and apply the migration against a disposable database; confirm existing rows receive `archived_at = NULL` and `pnpm db:check-balances` passes.
- [ ] Mark a disposable test group `archived_at = now()` directly or via helper, then exercise representative write endpoints (`POST /transactions`, `PATCH /groups/{id}`, `POST /settlement-requests`, `POST /comments`, `POST /invites/{token}/join`, `POST /categories`) and verify every one answers HTTP `409` with `error.code === "GROUP_ARCHIVED"`.
- [ ] Run `pnpm check` and commit: `feat(db): add group archival schema and write guard`.

---

### Task 5.5A.1.2: Archive, Unarchive, Clone Group & additive `GET /groups` metadata

**Files:**
- `packages/contract/src/group.ts`
- `packages/db/src/{groups,members,payment-methods,categories}.ts`
- `apps/api/src/services/groups.ts`
- `apps/api/src/routes/groups.ts`

**Interfaces & Rules:**
- **Additive DTO additions (`packages/contract/src/group.ts`):**
  - `GroupDto`: add `archivedAt: z.iso.datetime().nullable()`.
  - `GroupSummaryDto`: add `archivedAt: z.iso.datetime().nullable()`, `role: GroupRole`, `pendingActionCount: z.int().nonnegative()` (actionable pending settlements + owner pending expense approvals in that group; `0` when archived).
  - `GroupsQuery` on `GET /api/v1/groups`: optional `status: z.enum(["active", "archived", "all"]).default("all")` so omitted query returns all groups cleanly for backwards compatibility.
- **`POST /api/v1/groups/{groupId}/archive`:**
  - Middleware: `requireUser`, `requireGroupRole("owner")`, `requireVerifiedEmail`, `requireWriteLimit`, `requireSameOrigin`.
  - Locks group; if `archivedAt === null`, sets `archivedAt = now`, `updatedAt = now`, records activity (`entityType: "group"`, `action: "group.archived"`, `summary: "archived"` or matching existing group activity format), emits SSE `["group", "activity"]`. Idempotent when already archived. Returns `200 GroupResponse`.
- **`POST /api/v1/groups/{groupId}/unarchive`:**
  - Middleware: same as `archive`.
  - Locks group; if `archivedAt !== null`, sets `archivedAt = null`, `updatedAt = now`, records activity (`action: "group.unarchived"`), emits SSE `["group", "activity"]`. Idempotent when already active. Returns `200 GroupResponse`.
- **`POST /api/v1/groups/{groupId}/clone`:**
  - Middleware: `requireUser`, `requireGroupRole("editor")` (allows `editor` and `owner`, `403` for `viewer`, `404` for outsider), `requireVerifiedEmail`, `requireWriteLimit`, `requireSameOrigin`, `Idempotency-Key` required (`runIdempotent`). Permitted whether source group is active or archived.
  - `CloneGroupRequest`: `{ name: GroupName, copyPaymentMethods: z.boolean().default(true), copyCategories: z.boolean().default(false) }`.
  - Transactional behavior (`201 GroupResponse`):
    1. Lock caller account (check deleted/Apple deletion pending just like `createGroup`).
    2. Create new active group (`archivedAt: null`, fresh `inviteToken`, `minimizeDebts` and `defaultRole` copied from source).
    3. Copy all **active `person` members** (`kind = 'person' AND active = true`) ordered by `position` (`1..N`), preserving `name`, `shape`, `color`, `defaultWeight`. Exclude `fund` members and inactive members.
    4. Insert `group_users` **only for the caller** with `role: "owner"`, linking `memberId` to the cloned member corresponding to caller's source `memberId` (if caller was unlinked or source member was inactive, insert a member for `user.name` at position `0` and link the caller).
    5. If `copyPaymentMethods` is `true`, duplicate `member_payment_methods` rows from source active person members to their cloned member IDs (never record bank/wallet details in activity `before`/`after` or logs).
    6. If `copyCategories` is `true`, duplicate non-archived `group_categories` rows into the new group.
    7. Copy zero transactions, invites, settlement requests, comments, or chat links. Write `group.created` activity on the new group.

**Exercises:**
- [ ] Exercise `GET /groups`, `GET /groups?status=active`, and `GET /groups?status=archived` verifying `archivedAt`, `role`, and `pendingActionCount`.
- [ ] Exercise `archive` and `unarchive` across `owner` (`200`, idempotent repeat `200`), `editor` (`403`), `viewer` (`403`), `outsider` (`404`), and `unauthenticated` (`401`). Verify SSE `"group"` + `"activity"` events fire and writes fail with `409 GROUP_ARCHIVED` until unarchived.
- [ ] Exercise `clone` from an archived group containing a fund, inactive member, payment methods, and custom categories; confirm `201`, confirm idempotency replay returns same group and reused key with modified body returns `409 IDEMPOTENCY_KEY_REUSED`, confirm new group has zero transactions, no fund, no inactive member, only caller as owner, payment methods copied without appearing in `activity` or console logs, and `403` for `viewer` / `404` for `outsider`.
- [ ] Run `pnpm check` and commit: `feat(api): add group archive, unarchive, clone, and summary metadata`.

---

### Task 5.5A.1.3: Cross-Group Overview (`GET /me/overview`), Personal Ledger (`GET /me/transactions`), `myDelta` & OpenAPI

**Files:**
- New `packages/contract/src/overview.ts`
- `packages/contract/src/{transaction,index}.ts`
- New `packages/db/src/overview.ts`
- `packages/db/src/transactions.ts`
- New `apps/api/src/services/overview.ts`
- `apps/api/src/services/transactions.ts`
- `apps/api/src/routes/me.ts`
- Regenerated `packages/contract/openapi.json`

**Interfaces & Rules:**
- **Additive `myDelta` (`BaseTransactionFields` in `packages/contract/src/transaction.ts`):**
  - Add `myDelta: z.int().nullable()`.
  - Compute server-side for the caller's `myMemberId` in the group (`null` if `myMemberId === null`, `deletedAt !== null`, `approvalStatus === "rejected"`, or `myPaid === 0 && myShare === 0`):
    - `expense` or `transfer`: `myPaid - myShare`
    - `income`: `myShare - myPaid`
- **`GET /api/v1/me/overview` (`OverviewResponse`):**
  - Return `totalOwedToMe` (sum of positive `myBalance`), `totalIOwe` (sum of `abs(myBalance)` for negative `myBalance`), `netBalance` (`totalOwedToMe - totalIOwe`), `activeGroupCount`, `archivedGroupCount`, `pendingSettlementCount`, `pendingApprovalCount`, `pendingActions` (newest `<= 20` across active groups `archivedAt IS NULL` matching Phase 2 confirmation & Phase 4 owner approval authorization rules), and `groupBalances` (groups where `myBalance !== 0`, sorted by `abs(myBalance)` desc then `groupName` asc).
- **`GET /api/v1/me/transactions` (`PersonalTransactionsQuery` / `PersonalTransactionsResponse`):**
  - Query params: `cursor`, `limit` (`1..50`, default `20`), `type`, `groupId`, `q`.
  - If `groupId` is provided and caller is not in `group_users` for `groupId`, return `404 NOT_FOUND`.
  - Scope strictly to non-deleted transactions in caller's current `group_users` groups where caller's `group_users.member_id` is present in `transaction_payers` or `transaction_shares`.
  - Compute `myDelta` using the exact balance sign rule above (`rejected` transactions either excluded or flagged clearly; spec notes non-deleted transactions — wait: ensure `myDelta` for rejected transactions follows the same `0`/counted rule so users aren't misled; better yet: include non-deleted transactions with `myDelta: 0` when rejected or exclude uncounted? Follow Wave 5.5A spec §4.1: `myDelta` is `number` in `PersonalTransactionDto` — if `approvalStatus === "rejected"`, `myDelta` is `0` or exclude rejected? Spec §4.5 says `myDelta: number; // exact signed integer` and `approvalStatus`, so returning `0` when `approvalStatus === "rejected"` guarantees `sum` consistency!).
- **OpenAPI Snapshot (`packages/contract/openapi.json`):**
  - Run `pnpm contract:write` and run `diff` via `apps/api/src/openapi/cli.ts` against baseline `main` snapshot confirming **0 breaking changes** (only additive paths/schemas/fields).

**Exercises:**
- [ ] Create 2 groups (one active, one archived) with expenses (single payer + multi-payer + uninvolved member), income, transfer, rejected pending expense, soft-deleted expense, and pending settlement confirmation.
- [ ] Verify for every member-linked user that `sum(myDelta ?? 0)` over non-deleted group transactions equals `myBalance` from `/balances` (`0` discrepancy).
- [ ] Exercise `GET /me/overview` and `GET /me/transactions` (with pagination cursor, `q` Vietnamese accent-insensitive search, `type`, and outsider `groupId` returning `404`). Verify removing a user from a group immediately drops that group's items and totals from `/me/overview` and `/me/transactions`.
- [ ] Verify `pnpm contract:check` passes and OpenAPI diff shows 0 breaking changes.
- [ ] Run `pnpm check` and commit: `feat(api): add cross-group overview, personal ledger, and transaction myDelta`.

---

### Task 5.5A.1.4: Stage 5.5A.1 API Gate

**Files:** `docs/superpowers/runs/phase-5-5a/{progress,decisions}.md`.

- [ ] Run complete permission matrix (signed-out `401`, outsider `404`, `viewer`, `editor`, `owner`) across all new Wave 5.5A routes and existing group routes (both Cookie and Bearer callers).
- [ ] Sweep every group write endpoint against an archived group confirming `409 GROUP_ARCHIVED`.
- [ ] Replay Phase 1–5 + Wave 5.5A API scenarios on a reset disposable database; run `pnpm db:check-balances` (`All groups balanced`); run `pnpm check` and `pnpm build`.
- [ ] Record observed results in `progress.md` and commit: `docs(run): record Wave 5.5A.1 API gate`.
