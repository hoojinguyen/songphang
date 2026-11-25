# Wave 5.5B — Settlement Proofs, Reconciliation Vault, Cycles & Low-Friction Sharing — Design

Date: 2026-11-25. Status: approved by the project owner on 2026-11-26. Read `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md` and `docs/superpowers/specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md` first.

## 1. Intent

Wave 5.5A shipped UI/UX v2 (Light/Dark tokens, `Be Vietnam Pro` `.ttf` on iOS, 4-tab app shell, 3-segment Group Detail, Full-Width Feed Cards, Web Desktop 2–3 column workspace, Cross-Group Overview, Personal Ledger, and Group Archive/Clone). In real-world Vietnamese group usage — especially recurring sports clubs (`G4 Badminton 2026` with 12–20+ members including non-app friends) and group trips (`Cần Thơ trip`) — closing out and collecting money still hits five practical pain points:

1. **Opaque debt totals:** When a member (or non-app friend) is told they owe `293.000 đ`, they cannot see *which sessions/expenses* and *what prior unpaid carry-over* produced that exact figure without asking the host.
2. **Cut-off screenshots & manual bank copy-paste:** Screenshotting a phone screen cuts off groups of 10–20 people and forces the host to type bank details separately into Zalo or Messenger.
3. **Long-running group clutter vs. late payers:** Recurring groups accumulate expenses in batches ("gom theo đợt"), then collect payments while new sessions continue. Some people pay days or weeks later, so unpaid balances must accumulate seamlessly across batches while the expense feed stays cleanly grouped by period.
4. **Unstructured transfer verification:** Members who transfer money via banking apps, MoMo, ZaloPay, or cash have no optional place to attach a banking screenshot (`transfer_proof`), payment channel, or short note — while hosts marking multiple friends paid at once still need a frictionless 1-tap fast path where proof is strictly optional.
5. **No dedicated reconciliation log:** Confirmed transfers, pending payment reports, and attached receipt proofs are scattered between pending rows and the general expense feed instead of living in one searchable/filterable **Sổ thanh toán** inside `Thanh toán`.

**Goals:**
- Add **strictly optional** `transfer_proof` image attachment, payment `channel` (`bank`, `momo`, `zalopay`, `cash`), and short `note` to both `POST /settlement-requests` ("Tôi đã chuyển") and direct `transfer` transactions ("Ghi nhận đã trả"), preserving 1-tap settlement when omitted and displaying a proof thumbnail badge on transfer cards.
- Add **Sổ thanh toán** (Settlement History & Receipt Proof Vault) inside the `Thanh toán` segment via a clean 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`).
- Add **Chốt đợt / Hồ sơ đã chốt** (`settlement_cycles`) with cumulative ledger continuity (unpaid balances carry forward automatically without synthetic zeroing entries) and a period filter chip on the `Chi tiêu` segment header.
- Add **server-computed per-member debt breakdowns** ("khoản nợ này từ đâu ra") usable both inside `Thanh toán` and on an opt-in, revocable **Guest Read-only Link** (`/share/{token}`) with server-generated **VietQR** and full expense drill-down.
- Add **1-tap Share Sheet image export** (Web & iOS parity, Light & Dark card themes, exact integer VND with zero rounding, auto-expanding height for 20+ members) supporting two modes on one preview sheet: **Tổng kết nhóm** and **Nhắc nợ khéo** (all unpaid members or a single debtor with itemized breakdown + exact-amount VietQR).

**Non-goals:**
- Making transfer proof images, payment channel, or payment notes mandatory.
- Resetting or zeroing unpaid ledger balances via synthetic adjustment transactions when closing a cycle.
- Unauthenticated writes on `/share/{token}` (guests cannot mark paid, comment, or edit via a guest link; they join via `/join/{token}` if they want an account).
- Manual-form VAT/shipping/discount extras, recurring expenses, household debt grouping, iOS Share Extension, or iOS Widgets (reserved for Wave 5.5C).
- Introducing any new third-party runtime dependency on Web, API, or iOS.

**Anti-goals:**
- Computing member debt breakdowns, carry-over balances, suggested transfers, or VietQR payloads on Web or iOS clients instead of reading authoritative server integers.
- Breaking existing `/api/v1` endpoints, deep links, or `pnpm db:check-balances` invariants.
- Exposing a group on `/share/{token}` without explicit `owner`/`editor` opt-in, or continuing to serve `/share/{token}` after revocation.
- Using emoji anywhere in UI copy, exported share cards, or source code (`AGENTS.md` §11).

## 2. Delivery Stages (`phase-5-5b`)

Run files live under `docs/superpowers/runs/phase-5-5b/` (`progress.md`, `decisions.md`, `manual-checks.md`).

| Stage | Scope | Branch Target |
|---|---|---|
| **5.5B.0** | Re-baseline `main`, verify Node/Postgres/Xcode gates and Wave 5.5A acceptance checks on a disposable database. | `phase-5-5b` |
| **5.5B.1** | Additive DB migration (`settlement_requests` proof/channel/note, `transactions` transfer channel/note + `cycle_id`, `settlement_cycles`, `groups` guest-link columns), attachment upload/cleanup rules for `transfer_proof`, settlement cycle closeout/reopen & `cycleId` feed filter, server-computed `memberBreakdowns`, guest-link endpoints (`POST/GET/DELETE /groups/{id}/guest-link`, public `GET /guest-links/{token}*`), and regenerated `packages/contract/openapi.json`. | `phase-5-5b` |
| **5.5B.2** | Web implementation: optional proof/channel/note in `Pay` & `Settle`, proof thumbnail badge on Transfer cards, `Thanh toán` 3-pill sub-navigation (`Cần thanh toán` \| `Sổ thanh toán` \| `Đợt đã chốt`), in-app per-member breakdown drawer, `Chi tiêu` cycle filter chip, Guest Link management + unauthenticated `/share/[token]` page with VietQR & expense detail modal, and 1-tap Canvas PNG Share/Download sheet (`Tổng kết nhóm` + `Nhắc nợ khéo` in Light/Dark). | `phase-5-5b` |
| **5.5B.3** | iOS (`SongPhangKit`) parity: `Domain` / `Repositories` / `PreviewSupport` mappings for 5.5B APIs, optional proof/channel/note in `PayView` & `SettleView` (`PhotosPicker` upload), proof badge on Transfer cards, `Thanh toán` 3-pill sub-navigation (`BalancesView` + Vault + Cycles + member breakdown sheet), `Chi tiêu` cycle chip, Guest Link management sheet (`S10` & `Thanh toán`) + `/share/{token}` route handling, and SwiftUI `ImageRenderer` (`scale = 3.0`) Share Sheet export (`Tổng kết nhóm` + `Nhắc nợ khéo` in Light/Dark). | `phase-5-5b` |
| **5.5B.4** | Standing docs & ADRs (`ADR-036`, `ADR-037`, `ADR-038`), `check-strings.sh` 100% parity check, `pnpm check`, `pnpm build`, `swift-format lint --strict`, Simulator Debug + unsigned Release `xcodebuild`, `pnpm db:check-balances`, permission matrix & Wave 5.5B acceptance scripts, and owner manual-check handoff. | `phase-5-5b` |

Note for `/swarm` execution: once **5.5B.1** locks `openapi.json` and the shared Vietnamese string keys in `vi.ts` / `Localizable.xcstrings`, **5.5B.2 (Web)** and **5.5B.3 (iOS)** have strictly disjoint file trees (`apps/web/` vs `apps/ios/`) and can execute in parallel worker worktrees.

## 3. Database Schema Changes (5.5B.1)

One additive Drizzle migration under `packages/db/drizzle/`:

### 3.1 `settlement_requests` (`packages/db/src/schema-settlements.ts`)

Add three nullable columns:
- `channel text NULL` — `CHECK (channel IS NULL OR channel IN ('bank', 'momo', 'zalopay', 'cash'))`
- `note text NULL` — `CHECK (note IS NULL OR char_length(note) BETWEEN 1 AND 120)`
- `proof_attachment_id uuid NULL REFERENCES attachments(id) ON DELETE SET NULL`
- Index `settlement_requests_proof_attachment_idx` on `(proof_attachment_id)` where `proof_attachment_id IS NOT NULL`.

### 3.2 `settlement_cycles` (new `packages/db/src/schema-cycles.ts`, exported in `schema.ts`)

```sql
CREATE TABLE settlement_cycles (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  cycle_number integer NOT NULL CHECK (cycle_number >= 1),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 80),
  started_at timestamptz NOT NULL,
  closed_at timestamptz NOT NULL CHECK (closed_at >= started_at),
  closed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  expense_count integer NOT NULL DEFAULT 0 CHECK (expense_count >= 0),
  total_expense_amount bigint NOT NULL DEFAULT 0 CHECK (total_expense_amount >= 0),
  snapshot jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (group_id, cycle_number)
);
CREATE INDEX settlement_cycles_group_closed_idx
  ON settlement_cycles (group_id, cycle_number DESC);
```

- `snapshot` JSONB stores the immutable closeout record validated by Zod on write and read:
  - `balances`: `Array<{ memberId: string; name: string; shape: MemberShapeCode; color: MemberColorCode; balance: number }>` (person balances at the exact instant of closeout).
  - `transfers`: `Array<{ fromMemberId: string; fromName: string; toMemberId: string; toName: string; amount: number }>` (suggested settlement transfers at closeout).
  - `fundBalance`: `number | null` (shared fund balance at closeout if a fund exists, else `null`).

### 3.3 `transactions` (`packages/db/src/schema-transactions.ts`)

Add three nullable columns:
- `payment_channel text NULL` — `CHECK (payment_channel IS NULL OR (type = 'transfer' AND payment_channel IN ('bank', 'momo', 'zalopay', 'cash')))`
- `payment_note text NULL` — `CHECK (payment_note IS NULL OR (type = 'transfer' AND char_length(payment_note) BETWEEN 1 AND 120))`
- `cycle_id uuid NULL REFERENCES settlement_cycles(id) ON DELETE SET NULL`
- Partial index `transactions_group_cycle_feed_idx` on `(group_id, cycle_id, occurred_at DESC, id DESC) WHERE deleted_at IS NULL`.

**Why `transactions.cycle_id` instead of timestamp-range slicing (Builder Call / `ADR-036`):**
- All open ("current period") transactions have `cycle_id IS NULL`.
- Closing a cycle atomically stamps `SET cycle_id = <newCycleId>` on all **counted** non-deleted transactions in that group where `cycle_id IS NULL AND approval_status IN ('none', 'approved')` (unapproved `pending` or `rejected` rows retain `cycle_id = NULL` so if approved later they appear visibly in `Đợt hiện tại` rather than hiding inside an already-closed cycle).
- If the host enters a forgotten expense tomorrow with yesterday's `occurred_at` date, its `cycle_id` is `NULL`, so it stays visibly in **Đợt hiện tại** (where its balance will be settled) instead of silently disappearing into an already-closed cycle and contradicting that cycle's frozen closeout snapshot.
- **Direct editability of closed-cycle transactions (Owner Decision):** Transactions with `cycle_id IS NOT NULL` are **not** locked against `PATCH`, soft-`DELETE`, or `restore`. Authorized `owner`/`editor` members can edit or delete past expenses in closed cycles directly in place (`PATCH` preserves the transaction's existing `cycle_id`), recalculating live cumulative balances immediately while `settlement_cycles.snapshot` remains labeled **`Số liệu tại thời điểm chốt`**.
- Reopening (deleting) the most recent cycle triggers `ON DELETE SET NULL`, cleanly returning its transactions to `Đợt hiện tại` without altering a single đồng in `transaction_payers` or `transaction_shares`.
- **Ledger invariant untouched:** `transaction_payers`, `transaction_shares`, deferred balance triggers, and `pnpm db:check-balances` do not filter by `cycle_id`. Group net balances remain strictly cumulative across all cycles, and all member balances in a group still sum to `0`.

### 3.4 `groups` (`packages/db/src/schema-groups.ts`)

Add opt-in Guest Link columns (mirroring `invite_token` / `invite_active`, but **disabled and `NULL` by default**):
- `guest_token text NULL UNIQUE`
- `guest_link_active boolean NOT NULL DEFAULT false`
- `guest_link_created_at timestamptz NULL`
- Constraint `groups_guest_link_consistency_check`: `CHECK ((guest_link_active = false AND guest_token IS NULL) OR (guest_link_active = true AND guest_token IS NOT NULL AND char_length(guest_token) >= 32))`.

## 4. API & Contract Changes (Strictly Additive v1)

All schemas live in `packages/contract/src/` and regenerate `packages/contract/openapi.json` via `pnpm contract:write`.

### 4.1 Payment Channel, Proof & Note (`settlement-request.ts`, `transaction.ts`, `attachment.ts`, `balance.ts`)

1. **`PaymentChannel` enum (`packages/contract/src/payment.ts`):**
   - `z.enum(["bank", "momo", "zalopay", "cash"]).openapi("PaymentChannel")`.
2. **Attachment upload for `transfer_proof` (`POST /api/v1/groups/{groupId}/attachments`):**
   - Optional query parameter: `purpose?: "expense" | "transfer_proof"` (defaults to `"expense"`).
   - Authorization:
     - `purpose === "expense"`: existing `minimumRole: "editor"` unchanged.
     - `purpose === "transfer_proof"`: allows `minimumRole: "viewer"` **only when** `access.memberId !== null` (linked group member); unlinked viewers receive `403 FORBIDDEN`. Still enforces `assertGroupRowNotArchived`, verified email, write rate limit, same-origin, 5 MiB size cap, `image/jpeg | image/png | image/webp` sniffing, and 200 MiB group quota.
   - **Cleanup protection (`packages/db/src/attachments.ts`):** `listStaleUnattachedGroups` and `deleteStaleUnattachedForGroup` treat an attachment as orphaned **only** when `transaction_id IS NULL AND NOT EXISTS (SELECT 1 FROM settlement_requests sr WHERE sr.proof_attachment_id = attachments.id)`. `deleteAttachment` refuses (`409 REQUEST_ALREADY_PENDING` or `400 VALIDATION_FAILED`) if a `viewer` tries to delete someone else's attachment; `editor`/`owner` deletion follows existing rules (`ON DELETE SET NULL` clears `proof_attachment_id` if unbound to a transaction).
3. **`CreateSettlementRequest` & `SettlementRequestDto` (`packages/contract/src/settlement-request.ts`):**
   - `CreateSettlementRequest` adds optional fields:
     - `channel?: PaymentChannel`
     - `note?: z.string().trim().min(1).max(120)`
     - `proofAttachmentId?: z.uuid()`
   - Validation in `createSettlementRequest`:
     - If `proofAttachmentId` is provided, verify the attachment belongs to `groupId`, has `transactionId === null`, is not already linked to another `settlement_requests.proof_attachment_id`, and (when `access.role === "viewer"`) `attachment.uploadedBy === input.userId`.
   - `SettlementRequestDto` adds:
     - `channel: PaymentChannel.nullable()`
     - `note: z.string().nullable()`
     - `proofAttachment: AttachmentDto.nullable()`
     - `resolvedBy: z.object({ id: z.uuid(), name: z.string().max(80) }).nullable()`
   - `BalancesResponse.transfers[number].pendingRequest` (`packages/contract/src/balance.ts`) adds optional/nullable fields so `PendingRequestRow` can display proof & channel inline without an extra fetch:
     - `channel: PaymentChannel.nullable()`
     - `note: z.string().nullable()`
     - `proofAttachmentId: z.uuid().nullable()`
4. **Confirming a Settlement Request (`POST /api/v1/groups/{groupId}/settlement-requests/{id}/confirm`):**
   - Automatically forwards `attachmentIds: row.proofAttachmentId ? [row.proofAttachmentId] : []`, `paymentChannel: row.channel ?? undefined`, and `paymentNote: row.note ?? undefined` into `createTransactionIn` (`type: "transfer"`).
   - Once confirmed, the attachment row's `transaction_id` points to the created `transfer` transaction while `settlement_requests.proof_attachment_id` retains the reference for Vault history.
5. **Direct Transfer Transactions (`TransferRequest`, `TransactionDto`, `TransactionListItemDto`):**
   - `TransferRequest` (`POST` & `PATCH` transfer) adds optional fields:
     - `paymentChannel?: PaymentChannel.nullable()`
     - `paymentNote?: z.string().trim().min(1).max(120).nullable()`
     - (`attachmentIds` max 3 already exists on `TransferRequest`!)
   - `BaseTransactionFields` (`TransactionDto` & `TransactionListItemDto`) adds:
     - `paymentChannel: PaymentChannel.nullable().optional()`
     - `paymentNote: z.string().nullable().optional()`
     - `cycleId: z.uuid().nullable().optional()`
   - `TransactionListItemDto` adds:
     - `firstAttachmentId: z.uuid().nullable().optional()` — populated from the earliest attachment of each transaction in `mapTransactionListItems` so feed Transfer cards and Vault rows render proof thumbnails with zero N+1 fetches.
6. **Server-Built Static Account VietQR (`packages/core/src/vietqr.ts` & `packages/contract/src/balance.ts`, Builder Call):**
   - Add `buildStaticVietQrPayload({ bankBin, accountNumber, purpose? })` and `groupTransferPurpose(groupName)` (`"SP {plainGroupName}"` <= 25 ASCII chars) in `@songphang/core` using EMVCo static QR (`01 = "11"`, omitting tag `54` amount).
   - Add `accountQrPayload: z.string().min(1).max(512).nullable().optional()` to the `"bank"` variant of `PayTo` in `BalancesResponse` and `GuestGroupViewResponse` so multi-debtor share cards render a valid static bank QR with zero client-side VietQR calculation.

### 4.2 Sổ Thanh Toán — Settlement Vault Endpoint

While raw `GET /settlement-requests` and `GET /transactions?type=transfer` already exist, a confirmed settlement request creates a `transfer` transaction — stitching and deduplicating two cursor-paginated streams on clients is error-prone. Wave 5.5B adds one unified read endpoint:

`GET /api/v1/groups/{groupId}/settlement-vault`
- **Access:** `requireUser`, `getGroupAccess(..., minimumRole: "viewer")`. Allowed on active and archived groups.
- **Query (`SettlementVaultQuery`):**
  - `filter?: "all" | "pending" | "confirmed" | "with_proof"` (default `"all"`).
  - `cycleId?: "current" | uuid` (optional; filters confirmed transfers by `cycle_id` and pending/rejected requests by cycle window if specified).
  - `cursor?: string` (opaque base64url `(sortAt, kind, id)`).
  - `limit?: number` (`1..100`, default `50`).
- **Deduplication & Ordering Rules:**
  - Includes:
    1. All non-deleted `transactions` with `type = 'transfer'` (representing completed payments — both direct transfers and confirmed `settlement_requests`, enriched with `settlementRequestId` and request metadata if originated from a confirmed request).
    2. All `settlement_requests` whose `status IN ('pending', 'rejected', 'cancelled')` (confirmed requests are merged into item 1 via `settlement_requests.transaction_id` so each payment appears **once**; if a confirmed request's transfer was later soft-deleted, it falls back to showing as cancelled/deleted history only if needed, or excluded from confirmed).
  - Ordered by `sortAt DESC` (`pending` requests pinned first when `filter === "all"` ordered by `createdAt DESC`, followed by historical items ordered by `occurredAt / resolvedAt DESC`).
  - `with_proof` returns only entries with at least one attachment (`attachments.length > 0` or `proofAttachment !== null`).
- **Response (`SettlementVaultResponse`):**
  ```ts
  {
    items: Array<{
      id: string; // transaction.id for confirmed transfers; request.id for non-confirmed requests
      kind: "transfer" | "request";
      status: "pending" | "confirmed" | "rejected" | "cancelled";
      transactionId: string | null;
      settlementRequestId: string | null;
      fromMemberId: string;
      toMemberId: string;
      amount: number;
      channel: "bank" | "momo" | "zalopay" | "cash" | null;
      note: string | null;
      description: string | null;
      attachments: AttachmentDto[]; // 0..3 attachments (proof images)
      createdBy: { id: string; name: string } | null;
      resolvedBy: { id: string; name: string } | null;
      occurredAt: string; // transfer occurredAt or request createdAt
      resolvedAt: string | null;
      cycleId: string | null;
    }>;
    summary: {
      pendingCount: number;
      confirmedCount: number;
      confirmedTotalAmount: number; // integer VND sum of non-deleted transfers (within cycleId if filtered)
      proofCount: number;
    };
    nextCursor: string | null;
  }
  ```

### 4.3 Settlement Cycles (`settlement_cycles`) & Feed Filter

| Method & Path | Access & Guards | Behavior |
|---|---|---|
| `GET /api/v1/groups/{groupId}/settlement-cycles` | `requireUser`, `viewer+` | Returns `{ cycles: SettlementCycleDto[], currentPeriod: { startedAt: string, expenseCount: number, totalExpenseAmount: number, countedTransactionCount: number } }` ordered by `cycleNumber DESC`. Allowed on archived groups. |
| `POST /api/v1/groups/{groupId}/settlement-cycles` | `requireUser`, `editor+`, verified email, write limit, same-origin, `Idempotency-Key`, not archived | Locks group. Refuses with `422 CYCLE_EMPTY` (`"CYCLE_EMPTY"` added to `ErrorCode`) if there are `0` counted non-deleted transactions (`cycle_id IS NULL AND deleted_at IS NULL AND approval_status IN ('none','approved')`) in the group. Computes live balances & suggested transfers via `suggestGroupTransfers`, computes `expenseCount` & `totalExpenseAmount` of counted expenses (`type = 'expense' AND deleted_at IS NULL AND approval_status IN ('none','approved') AND cycle_id IS NULL`), inserts `settlement_cycles` (`cycleNumber = max + 1`, `startedAt = prevCycle?.closedAt ?? group.createdAt`, `closedAt = now`, `title = input.title ?? "Đợt {n}"`), updates `transactions SET cycle_id = cycle.id WHERE group_id = groupId AND cycle_id IS NULL AND deleted_at IS NULL AND approval_status IN ('none','approved')` (leaving any `pending` approval rows in `Đợt hiện tại`), logs activity `cycle.closed`, emits SSE `["group", "transactions", "activity", "settlementCycles"]`. Returns `201 SettlementCycleResponse`. |
| `DELETE /api/v1/groups/{groupId}/settlement-cycles/{cycleId}` | `requireUser`, `owner`, verified email, write limit, same-origin, not archived | Escape hatch if a cycle was closed prematurely: locks group, verifies `cycleId` is the **latest** cycle (`cycle_number = max(cycle_number)`); if not latest, refuses with `409 CYCLE_NOT_LATEST` (`"CYCLE_NOT_LATEST"` added to `ErrorCode`). Deletes the cycle row (`ON DELETE SET NULL` restores its transactions to `cycle_id = NULL`), logs activity `cycle.reopened`, emits SSE `["group", "transactions", "activity", "settlementCycles"]`. Returns `204`. |

- **Additive SSE resource (`packages/contract/src/jobs.ts`):** Add `"settlementCycles"` to `GroupEventResource` (clients in 5.5A ignore unknown resources or map safely; 5.5B Web & iOS invalidate cycles/feed/vault on `"settlementCycles"`).
- **`GET /api/v1/groups/{groupId}/transactions` (`TransactionsQuery`):**
  - Add optional `cycleId?: z.union([z.literal("current"), z.uuid()])`:
    - Omitted: returns all non-deleted transactions across all cycles (100% backward-compatible).
    - `"current"`: filters `transactions.cycle_id IS NULL`.
    - `<uuid>`: verifies cycle belongs to `groupId` (else `404 NOT_FOUND`) and filters `transactions.cycle_id = <uuid>`.

### 4.4 Per-Member Debt Breakdown Endpoint ("300k này từ đâu ra?")

`GET /api/v1/groups/{groupId}/balances/breakdowns`
- **Access:** `requireUser`, `viewer+`. Allowed on active and archived groups.
- **Query (`MemberBreakdownsQuery`):**
  - `cycleId?: "auto" | "current" | uuid` (defaults to `"auto"`).
- **Smart Focus Resolution (`Builder Call` — solves immediate post-`Chốt đợt` sharing):**
  - Under `cycleId = "auto"` (used by default on `Thanh toán`, `Xuất ảnh / Nhắc nợ`, and `/share/{token}`):
    - If `Đợt hiện tại` (`cycle_id IS NULL`) contains `>= 1` counted `expense` or `income`, focus resolves to `"current"`: `carryOverBalance` sums counted member deltas across all closed cycles (`cycle_id IS NOT NULL`), `lines` itemizes all counted rows with `cycle_id IS NULL`, and `postCycleDelta = 0`.
    - If `Đợt hiện tại` contains **`0` counted expenses/incomes** AND at least one closed cycle exists (`latestCycle`) — e.g., right after the host clicks **Chốt đợt** and shares the link/card to collect payments — focus automatically resolves to `latestCycle.id` **plus any post-closeout transfers**: `carryOverBalance` sums member deltas in cycles *older* than `latestCycle` (`cycle_number < latestCycle.cycleNumber`), `lines` itemizes all counted rows in `latestCycle` (`cycle_id = latestCycle.id`) followed by any counted `transfer` rows in `cycle_id IS NULL`, and `postCycleDelta = 0`!
  - Under explicit `cycleId = "current"`: itemizes `cycle_id IS NULL` only (`postCycleDelta = 0`).
  - Under explicit `cycleId = <uuid>`: `carryOverBalance` sums cycles with `cycle_number < target.cycleNumber`, `lines` itemizes `cycle_id = target.id`, and `postCycleDelta` sums counted deltas in newer cycles + `cycle_id IS NULL` so the total still reconciles to live `netBalance`.
- **Response (`MemberBreakdownsResponse`):**
  ```ts
  {
    hasClosedCycles: boolean;
    resolvedFocus: { kind: "all" | "current" | "cycle"; cycleId: string | null; label: string };
    breakdowns: Array<{
      memberId: string;
      memberName: string;
      shape: MemberShapeCode;
      color: MemberColorCode;
      carryOverBalance: number; // exact integer VND prior to resolvedFocus
      focusExpenseDelta: number; // exact integer VND sum of expense/income deltas in lines
      focusTransferDelta: number; // exact integer VND sum of transfer deltas in lines
      postCycleDelta: number; // 0 for "auto"/"current"; subsequent delta when inspecting an older cycle
      netBalance: number; // exact live integer VND === carryOverBalance + focusExpenseDelta + focusTransferDelta + postCycleDelta
      lines: Array<{
        transactionId: string;
        type: "expense" | "income" | "transfer";
        description: string;
        occurredAt: string;
        totalAmount: number;
        payerSummary: string; // e.g., "Hội trả" or "Khánh chuyển Hội"
        memberPaid: number;
        memberShare: number;
        delta: number; // non-zero signed integer contribution
        isPostCloseoutTransfer: boolean;
      }>; // ordered by occurredAt ASC, id ASC
    }>;
  }
  ```
- **Exact algebraic invariant:** `carryOverBalance + sum(lines.delta) + postCycleDelta === netBalance` holds to the exact integer đồng for every member under every split mode, partial transfer, late payment, post-closeout edit, or income refund.

### 4.5 Opt-In Revocable Guest Read-Only Link (`/share/{token}`)

| Method & Path | Access & Guards | Behavior |
|---|---|---|
| `GET /api/v1/groups/{groupId}/guest-link` | `requireUser`, `editor+` | Returns `{ guestLink: { active: boolean, url: string \| null, createdAt: string \| null } }`. (`viewer` receives `403 FORBIDDEN` so view-only members cannot inspect/copy management links unless shared by `owner`/`editor`.) |
| `POST /api/v1/groups/{groupId}/guest-link` | `requireUser`, `editor+`, verified email, write limit, same-origin, not archived | Body `{ rotate?: boolean }` (optional). Locks group. If `!guestLinkActive || rotate === true`, generates `randomBytes(32).toString("base64url")`, sets `guest_link_active = true`, `guest_token = token`, `guest_link_created_at = now`, logs activity `guest_link.enabled` or `guest_link.rotated` (**never** logging the token in `activity` or server logs!), emits SSE `["group", "activity"]`. If already active and `!rotate`, returns existing active `guestLink` idempotently (`200`). |
| `DELETE /api/v1/groups/{groupId}/guest-link` | `requireUser`, `editor+`, verified email, write limit, same-origin | **Allowed even when group is archived** so owners/editors can always revoke external read access. Locks group, sets `guest_link_active = false, guest_token = null, guest_link_created_at = null`, logs `guest_link.revoked`, emits SSE `["group", "activity"]`. Returns `200` with `{ guestLink: { active: false, url: null, createdAt: null } }`. |
| `GET /api/v1/guest-links/{token}` | Public (unauthenticated), IP rate-limited (`read` / dedicated public bucket) | Validates token format (`32..64` base64url chars); looks up `groups WHERE guest_token = token AND guest_link_active = true`. If missing/revoked, returns generic `404 NOT_FOUND` (`Cache-Control: private, no-store`). Optional query `cycleId?: "current" \| uuid` and `cursor?: string`. Returns `GuestGroupViewResponse` (below). |
| `GET /api/v1/guest-links/{token}/attachments/{attachmentId}` | Public (unauthenticated), IP rate-limited | Verifies active `guest_token`, verifies attachment belongs to that `group.id` and is attached to a non-deleted, non-rejected `expense` or `income` transaction in that group (**excludes** `transfer` banking proof images and unattached scans so personal banking screenshots stay inside authenticated group members). Streams image bytes with `Cache-Control: private, no-store` and `X-Content-Type-Options: nosniff`. |

**`GuestGroupViewResponse` payload:**
- `group`: `{ id, name, currency: "VND", minimized: boolean, archivedAt: string | null }`
- `members`: `Array<{ id, name, kind, active, shape, color }>` (no user IDs, no emails, no claim status)
- `cycles`: `SettlementCycleDto[]` + `selectedCycleId: "current" | string` (when `cycleId` query is omitted, auto-selects `latestCycle.id` if `currentPeriod.expenseCount === 0 && cycles.length > 0`, else `"current"`) + `currentPeriod` summary
- `balances`: `BalancesResponse["balances"]`
- `transfers`: `Array<{ fromMemberId, toMemberId, amount, purpose, payTo }>` (same server-built dynamic `qrPayload` + static `accountQrPayload` + `bank`/`momo`/`zalopay` receiver info as `BalancesResponse`, **without** internal `pendingRequest.createdByMe`)
- `breakdowns`: `MemberBreakdownsResponse["breakdowns"]` + `resolvedFocus` (computed with matching `cycleId` / `"auto"` so tapping any member or transfer on `/share/{token}` immediately expands their exact itemized debt explanation — even immediately after `Chốt đợt`!)
- `transactions`: `{ items: GuestTransactionDto[], nextCursor: string | null }` (non-deleted, counted `expense`, `income`, and `transfer` rows for `selectedCycleId`, up to 100 per page, including `payers`, `shares`, `split` items/weights, and `attachments` metadata for `expense`/`income` so tapping any expense opens its full per-person and itemized breakdown; omits internal `createdBy`/`updatedBy` user IDs, approval notes, disputes, and comments).

*(Builder Call note: keeping banking `transfer_proof` screenshots authenticated-only while exposing expense receipt photos + full expense/share breakdowns on `/share/{token}` satisfies the owner's transparency requirement for all host expenses & per-person shares without leaking personal bank app screenshots onto a semi-public URL.)*

## 5. Detailed UI/UX & Client Architecture (Web & iOS Parity)

### 5.1 Segment `Thanh toán` (`Balances`) — 3-Pill Sub-Navigation

At the top of segment `Thanh toán` (Web `/g/[groupId]/balances` & Group container tab; iOS `GroupContainerView` `.thanhToan` hosting `BalancesView`):

1. **Sub-navigation pills:** `Cần thanh toán` (default) | `Sổ thanh toán` (badge when `pendingCount > 0`) | `Đợt đã chốt` (badge with cycle count when `> 0`).
2. **Sub-view 1 — `Cần thanh toán`:**
   - **Personal Net Hero Card** (unchanged from 5.5A: `Bạn được nhận ...` / `Bạn cần trả ...` / `Bạn đã xong`).
   - **Quick Action Bar** directly beneath hero:
     - `Xuất ảnh / Nhắc nợ` (all roles when `transfers.length > 0` or `balances` non-zero; opens Share Card Preview Sheet).
     - `Link khách` (`owner`/`editor`; opens Guest Link sheet showing live toggle/status, `Sao chép link`, `Đổi link mới`, `Thu hồi link`).
     - `Chốt đợt` (`owner`/`editor`, hidden when archived; disabled when current period has 0 transactions; opens Close Cycle confirmation modal with editable cycle title pre-filled `"Đợt {N}"`, date span preview, current expense total, and explicit note: *"Số dư chưa thanh toán vẫn được giữ nguyên và cộng dồn sang đợt tiếp theo."*).
   - **Suggested Transfers (`N lượt chuyển là xong`):**
     - Each transfer card now has a tappable `"Xem giải trình khoản nợ"` action (or tapping the debtor row) opening the **Member Debt Breakdown Sheet/Drawer** (`carryOverBalance` + current-period itemized expense shares + transfers = `netBalance`).
     - When `pendingRequest` exists on a transfer: `PendingRequestRow` displays `channel` pill (`Ngân hàng` / `MoMo` / `ZaloPay` / `Tiền mặt`), optional `note` in quotes, and a tappable `38pt` proof thumbnail (opens full-screen image viewer) right alongside `Đã nhận` / `Chưa nhận`.
   - **Group Balance Bars (`Cán cân của nhóm`):** Tapping any member bar also opens that member's **Debt Breakdown Sheet**.
3. **Sub-view 2 — `Sổ thanh toán` (Settlement History & Receipt Proof Vault):**
   - Summary strip: `Đã thanh toán: {confirmedTotalAmount}` · `Chờ xác nhận: {pendingCount}` · `Có chứng từ: {proofCount}`.
   - Filter chips: `Tất cả` | `Chờ xác nhận` | `Đã thanh toán` | `Có chứng từ`.
   - Chronological list of Vault cards:
     - Shows `FromShape -> ToShape`, `"{From} -> {To}"`, right-aligned tabular `amount`, status pill (`Chờ xác nhận` in `warningSoft`/`warning`, `Đã thanh toán` in `creditSoft`/`credit`, `Từ chối` / `Đã huỷ` in `sunken`/`muted`), `channel` pill, `note`, timestamp, and `44pt` proof thumbnail(s) on the trailing/leading slot (tapping opens lightbox; tapping a confirmed transfer row can also open its `TransactionDetail`).
4. **Sub-view 3 — `Đợt đã chốt` (Closed Settlement Cycles):**
   - Lists closed `settlement_cycles` newest-first (`Đợt 3 · Tháng 11`, `10/11/2026 – 25/11/2026`, `{expenseCount} khoản chi · Tổng {totalExpenseAmount}`).
   - Expanding/tapping a cycle displays its frozen snapshot explicitly labeled **`Số liệu tại thời điểm chốt`** (`Ai cần chuyển cho ai lúc chốt` + `Số dư từng người lúc chốt`) + a shortcut button `"Xem các khoản chi đợt này"` (switches segment to `Chi tiêu` with `cycleId = cycle.id` selected, where `owner`/`editor` can still edit/delete past items if needed).
   - On the **most recent** cycle only, `owner` (when group is active) sees `"Mở lại đợt này"` with confirmation dialog (`DELETE /settlement-cycles/{id}`).

### 5.2 Optional Proof, Channel & Note in `Pay` & `Settle` + Feed Transfer Badge

1. **`Pay` (`Tôi đã chuyển` — `PayContent`/`PayFooter` on Web, `PayView` on iOS):**
   - Above the sticky `"Tôi đã chuyển"` CTA, a compact **optional** card (`Thông tin chuyển tiền (không bắt buộc)`):
     - Horizontal channel pills: `Ngân hàng`, `MoMo`, `ZaloPay`, `Tiền mặt` (tapping an active pill deselects back to `null`; auto-defaults to the currently viewed payment method tab `bank`/`momo`/`zalopay` if available, editable in 1 tap).
     - `[Đính kèm ảnh bill]` button (`<input type="file" accept="image/jpeg,image/png,image/webp">` on Web; `PhotosPicker` + JPEG compression `<= 5 MiB` reusing existing receipt image normalizer on iOS) showing instant thumbnail + remove (`X`) button once uploaded.
     - Single-line `Ghi chú ngắn` field (`max 120` chars, placeholder `"VD: CK VCB tối thứ 3"`).
   - **Zero-friction rule:** The user can ignore all three controls and tap `"Tôi đã chuyển"` immediately in 1 tap.
2. **`Settle` (`Ghi nhận đã trả` — `SettlementForm` on Web, `SettleView` on iOS):**
   - Adds the same optional `Kênh thanh toán` pills, optional proof photo upload (1–3 photos via `attachmentIds`), and optional `Ghi chú ngắn` (`paymentNote`), keeping the existing 1-tap `"Ghi nhận {amount}"` button immediately enabled without requiring any extra field.
3. **Feed Transfer Card Badge (`Chi tiêu` segment):**
   - When a `transfer` item has `attachmentCount > 0` (with `firstAttachmentId`) and/or `paymentChannel`:
     - Displays a compact `28pt` rounded proof thumbnail badge (`Có bill`) + subtle channel/note subtitle (`MoMo · "Gửi tiền sân T11"`) on the single-band Transfer card without wrapping the right-aligned tabular amount.

### 5.3 Segment `Chi tiêu` — Cycle Filter Chip

- When `cycles.length === 0`: **no cycle chip is rendered** (zero visual noise for one-off weekend trips that never close a cycle).
- When `cycles.length >= 1`:
  - Renders a compact capsule selector chip right below the search/filter bar: defaults to **`Đợt hiện tại ({count})`**!
  - Tapping opens a lightweight menu/sheet with:
    - `Đợt hiện tại` (`cycleId = "current"`)
    - `Tất cả các đợt` (`cycleId = undefined`)
    - Closed cycles newest-first (`Đợt 2 · ...`, `Đợt 1 · ...`).
  - Selecting a closed cycle displays a subtle info bar (`"Đang xem {cycle.title} — chuyển về Đợt hiện tại"`).

### 5.4 Guest Read-Only Web Page (`/share/[token]`) & iOS Universal Link Handling

- **Web (`apps/web/src/app/share/[token]/page.tsx`):**
  - Standalone responsive public shell (no login wall, `robots: { index: false, follow: false }`, respects Light/Dark theme switcher in header).
  - Header: `Sòng Phẳng · Chế độ khách chỉ xem` badge, Group title, cycle filter pill (if cycles exist, defaulting to `Đợt hiện tại`), total spend & member count.
  - **Section 1 — `Thanh toán đề xuất` (`Ai chuyển cho ai`):**
    - Lists every suggested transfer (`From -> To: Amount`).
    - Tapping any row (or `"Xem giải trình & mã QR"`) expands inline:
      1. **Giải trình khoản nợ của `{From}`:** `Số dư đợt trước` (if non-zero) + every current-period expense/transfer involving `{From}` with date, description, who paid, total bill, and `{From}`'s exact share/delta, summing to `netBalance`.
      2. **Thông tin nhận tiền của `{To}`:** Server-built **VietQR** (`QrCard` with exact transfer amount & purpose pre-filled!) + copy buttons for Bank BIN/short name, Account Number, Account Name, or MoMo/ZaloPay phone.
  - **Section 2 — `Chi tiêu của nhóm`:**
    - Full-width read-only transaction cards for the selected cycle (with `"Xem thêm"` cursor pagination if `> 100`).
    - Tapping any expense card opens a **Read-only Expense Detail Modal/Drawer** showing: full description, date/time, category, who paid how much, itemized receipt lines & extras (if `split.method === "items"`), every participating member's exact share (`ShareDto`), and expense receipt photos (loaded via `/api/v1/guest-links/{token}/attachments/{id}`).
  - **Invalid / Revoked state (`404`):** Clean card `"Liên kết xem chung không tồn tại hoặc đã được thu hồi."` with zero group metadata leaked.
- **iOS (`LinkRouter` + `GuestGroupView` in `GroupsFeature` or `LedgerFeature`):**
  - `Route` adds `.guestShare(token: String)` recognized by `LinkRouter` for `/share/{token}` URLs (works both when signed out and signed in!) rendering the native read-only `GuestGroupView` with identical sections, member breakdown sheet, VietQR display, and expense detail sheet.

### 5.5 1-Tap Share Sheet Image Export (`Summary` & `"Nhắc nợ khéo"`)

Opened from `Xuất ảnh / Nhắc nợ` in `Thanh toán` (`S4` Segment 2):

1. **Preview Sheet Controls (Web & iOS):**
   - **Mode segmented control:** `Tổng kết nhóm` | `Nhắc nợ khéo`
   - **Card theme pill:** `Nền sáng` | `Nền tối` (initialized from current app appearance; uses exact Design System v2 Light/Dark semantic palette tokens).
   - **Mode-specific controls:**
     - In `Tổng kết nhóm`: checkbox/toggle `Kèm tóm tắt các khoản chi` (default OFF for compact groups, toggleable ON to append up to 15 current-period expenses + `+N khoản khác` summary line).
     - In `Nhắc nợ khéo`:
       - Target picker: `Tất cả người chưa chuyển ({N})` (default) OR any single suggested transfer `{From} -> {To} ({Amount})`.
       - Caption selector (3 zero-emoji Vietnamese presets + custom text input up to 100 chars):
         1. `"Gửi nhẹ bảng tổng kết đợt này, rảnh tay chuyển khoản giúp mình nhé."`
         2. `"Nhắc nhẹ khoản chi chung của nhóm, kiểm tra chi tiết bên dưới nhé."`
         3. `"Còn vài khoản đợt này chưa tất toán, tiện tay chuyển giúp nhé."`
2. **Card Anatomy (`390pt` logical width rendered at `3x` = `1170px` PNG width, dynamic unbounded height):**
   - **Typography & Numbers:** `Be Vietnam Pro`, tabular digits, exact integer VND (`formatMoney` / `MoneyFormatter`, e.g. `292.810 đ`) — **never rounded to `k` or truncated with decimals**.
   - **Group Summary Card (`Tổng kết nhóm`):**
     - Brand header (`SÒNG PHẲNG`), Group name, Cycle label + date, Total current-period spend.
     - Full list of suggested transfers (`MemberShape` + `From -> To` + bold tabular `Amount`) — expands vertically to fit all 12–20+ rows cleanly without scrollbars or cutoffs.
     - Optional current-period expense digest block when toggled ON.
     - Receiver payment footer:
       - If all displayed transfers pay a **single receiver** who has a `bank` payment method: renders the server-built static account **VietQR** (`payTo.accountQrPayload`, no fixed amount so each person enters their row's amount) + Bank short name, Account Number, Account Name.
       - If multiple receivers exist: lists each receiver's primary bank/wallet line cleanly.
       - If Guest Link is active: displays `"Xem chi tiết từng khoản tại: {guestLinkUrl}"`.
   - **Polite Reminder Card (`Nhắc nợ khéo`):**
     - Group name + selected polite caption banner (`accent` / `sunken` styling).
     - **When targeting all unpaid (`Tất cả`):** renders all remaining transfers + receiver payment footer (same as above, framed with the polite reminder header).
     - **When targeting 1 debtor (`{From} -> {To}`):**
       - Prominent `{From} cần chuyển {To}: {Amount}` hero row.
       - **Itemized breakdown box** (from server `MemberDebtBreakdownDto` `"auto"` focus for `{From}`: `Số dư từ đợt trước` if non-zero + up to 12 period lines + summary if more, totaling `netBalance`). **Multi-creditor / pairwise reconciliation (`Builder Call`):** whenever `abs(netBalance) !== transfer.amount` (e.g., `{From}` owes two creditors or `minimizeDebts = false`), appends a compact `Phân bổ thanh toán` footer listing `{From}`'s suggested transfers and highlighting `{From} -> {To}: {Amount}` so `netBalance` and `{Amount}` reconcile visibly on both `/share/{token}` and the exported card.
       - **Exact-amount VietQR** (`transfer.payTo` `qrPayload` from server, pre-filled with exact `transfer.amount` and `transfer.purpose`!) + bank account details so `{From}` can scan straight from the image in Zalo!
3. **Rendering & Share Execution (Zero New Dependencies):**
   - **iOS (`DesignSystem` / `LedgerFeature`):** SwiftUI view rendered offscreen via `ImageRenderer(content: cardView.frame(width: 390).environment(\.colorScheme, selectedScheme))` with `renderer.scale = 3.0` producing a crisp `UIImage` / PNG `Transferable` item wired to native `ShareLink` / `UIActivityViewController` (`Chia sẻ ảnh`) + `"Lưu vào Ảnh"` shortcut.
   - **Web (`apps/web/src/lib/share-card-canvas.ts`):** Pure HTML5 2D `<canvas>` renderer (`width = 1170`, `dpr = 3`) awaiting `document.fonts.ready` (`Be Vietnam Pro`) and drawing exact rounded cards, geometric member shapes (`circle`, `diamond`, `squircle`, `leaf`), tabular text, and QR modules from the already-installed `qrcode` package (`create(payload, { errorCorrectionLevel: "M" }).modules`). Primary CTA `"Chia sẻ ảnh"` calls `navigator.share({ files: [pngFile], title })` when `navigator.canShare?.({ files: [pngFile] })` is supported (mobile Safari / Chrome), and automatically falls back to instant PNG download (`Tải ảnh PNG`) + `"Sao chép ảnh"` (`navigator.clipboard.write([new ClipboardItem({ "image/png": blob })])`) on desktop browsers.

## 6. iOS Architecture Placement (`apps/ios/AGENTS.md` Compliance)

- **`Domain`:** Add value types (`PaymentChannel`, `SettlementVaultItem`, `SettlementVaultSummary`, `SettlementCycle`, `MemberDebtBreakdown`, `GuestLink`, `GuestGroupView`) and extend `SettlementRepository` / `GroupRepository` / `TransactionRepository` protocols (or add `GuestLinkRepositoryProtocol`). `Money` remains a 64-bit integer with zero client-side split/balance math.
- **`Repositories`:** Map new OpenAPI operations generated in `GeneratedAPI` from `packages/contract/openapi.json`; add multipart/binary `purpose` query support on attachment upload and unauthenticated client calls for `GuestLinkRepository`.
- **`DesignSystem`:** Reusable `ProofBadgeView`, `ChannelPillView`, and `ShareCardCanvasView` (used by `ImageRenderer` in both Light and Dark `ColorScheme`).
- **`LedgerFeature` & `PaymentsFeature` & `GroupsFeature`:**
  - Feature modules **never** import each other (`apps/ios/AGENTS.md` §3).
  - `BalancesView` (`LedgerFeature`) hosts the 3 sub-pills (`Cần thanh toán`, `Sổ thanh toán`, `Đợt đã chốt`), the Member Breakdown sheet, Close Cycle modal, Guest Link management sheet, and Share Card Preview sheet.
  - `PayView` (`PaymentsFeature`) and `SettleView` (`LedgerFeature`) each use shared `DesignSystem` inputs + injected repository closures/protocols wired by `AppShell`.
  - `GroupContainerView` and `RouteDestination` in `AppShell` coordinate cross-segment actions (e.g., jumping from a closed cycle in `Đợt đã chốt` to `Chi tiêu` filtered by `cycleId`, and routing `/share/{token}` to `GuestGroupView`).

## 7. Vietnamese UI Strings (100% Web & iOS Parity)

All new strings are added identically to `apps/web/src/messages/vi.ts` and `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, verified by `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`). Zero emoji.

| Key Group | Exact Vietnamese Strings |
|---|---|
| `Thanh toán` Sub-pills | `Cần thanh toán`, `Sổ thanh toán`, `Đợt đã chốt` |
| Proof, Channel & Note | `Kênh thanh toán (tuỳ chọn)`, `Ngân hàng`, `MoMo`, `ZaloPay`, `Tiền mặt`, `Ảnh chứng từ (tuỳ chọn)`, `Đính kèm ảnh chuyển khoản`, `Xoá ảnh chứng từ`, `Ghi chú ngắn (tuỳ chọn)`, `VD: Chuyển khoản VCB tối thứ 3`, `Có chứng từ`, `Xem ảnh chứng từ` |
| Sổ thanh toán (Vault) | `Chờ xác nhận`, `Đã thanh toán`, `Từ chối`, `Đã huỷ`, `Tất cả`, `Chưa có lịch sử thanh toán nào`, `Tổng đã thanh toán` |
| Chốt đợt (Cycles) | `Chốt đợt`, `Tên đợt`, `Đợt {number}`, `Đợt hiện tại`, `Tất cả các đợt`, `Chốt đợt chi tiêu này`, `Số dư chưa thanh toán vẫn được giữ nguyên và cộng dồn sang đợt tiếp theo.`, `Chưa có giao dịch mới để chốt đợt.`, `Số liệu tại thời điểm chốt`, `Xem các khoản chi đợt này`, `Mở lại đợt này`, `Mở lại đợt vừa chốt? Các giao dịch trong đợt sẽ quay về Đợt hiện tại.`, `Đang xem {title}`, `Về đợt hiện tại` |
| Debt Breakdown | `Xem giải trình khoản nợ`, `Giải trình khoản nợ`, `Số dư từ đợt trước`, `Chi tiêu trong đợt`, `Đã chuyển / nhận trong đợt`, `Phát sinh sau đợt này`, `Số dư hiện tại`, `Phân bổ thanh toán` |
| Guest Link (`/share/{token}`) | `Link khách`, `Link khách chỉ xem`, `Bật link khách chỉ xem`, `Người có link xem được bảng kê chi tiêu, giải trình khoản nợ và mã VietQR mà không cần đăng nhập.`, `Sao chép link khách`, `Đã sao chép link khách`, `Đổi link mới`, `Thu hồi link`, `Chế độ khách chỉ xem`, `Liên kết xem chung không tồn tại hoặc đã được thu hồi.` |
| Share Card Export | `Xuất ảnh / Nhắc nợ`, `Tổng kết nhóm`, `Nhắc nợ khéo`, `Nền sáng`, `Nền tối`, `Kèm tóm tắt các khoản chi`, `Đối tượng nhắc`, `Tất cả người chưa chuyển`, `Lời nhắn trên thẻ`, `Gửi nhẹ bảng tổng kết đợt này, rảnh tay chuyển khoản giúp mình nhé.`, `Nhắc nhẹ khoản chi chung của nhóm, kiểm tra chi tiết bên dưới nhé.`, `Còn vài khoản đợt này chưa tất toán, tiện tay chuyển giúp nhé.`, `Chia sẻ ảnh`, `Tải ảnh PNG`, `Sao chép ảnh`, `Đã sao chép ảnh` |

## 8. Security & Authorization Matrix

| Action / Endpoint | Unauthenticated | Outsider | Viewer (unlinked) | Viewer (linked member) | Editor | Owner | Key Security Rules |
|---|---|---|---|---|---|---|---|
| `POST /groups/{id}/attachments?purpose=transfer_proof` | `401` | `404` | `403` | `201` | `201` | `201` | Verified email, write limit, same-origin, not archived, 5 MiB + image magic-byte check, 200 MiB group quota |
| `POST /groups/{id}/settlement-requests` (with optional proof/channel/note) | `401` | `404` | `403` | `201` (own `fromMemberId` & own uploaded proof only) | `201` | `201` | Proof attachment must belong to `groupId`, be unbound, and not belong to another request |
| `GET /groups/{id}/settlement-vault` | `401` | `404` | `200` | `200` | `200` | `200` | Scoped strictly to `groupId`; outsiders get `404` |
| `GET /groups/{id}/balances/breakdowns` | `401` | `404` | `200` | `200` | `200` | `200` | Server-computed integers only |
| `GET /groups/{id}/settlement-cycles` | `401` | `404` | `200` | `200` | `200` | `200` | Scoped strictly to `groupId` |
| `POST /groups/{id}/settlement-cycles` | `401` | `404` | `403` | `403` | `201` | `201` | Verified email, `Idempotency-Key`, write limit, same-origin, not archived, non-empty current period |
| `DELETE /groups/{id}/settlement-cycles/{cycleId}` | `401` | `404` | `403` | `403` | `403` | `204` | Latest cycle only, not archived |
| `GET/POST/DELETE /groups/{id}/guest-link` | `401` | `404` | `403` | `403` | `200` | `200` | 256-bit `base64url` token; token never written to `activity` or logs; `DELETE` allowed even when group is archived |
| `GET /guest-links/{token}` | `200` (if active) / `404` | `200` / `404` | `200` / `404` | `200` / `404` | `200` / `404` | `200` / `404` | IP rate-limited; `Cache-Control: private, no-store`; `robots: noindex`; omits user IDs, emails, comments, disputes, and transfer banking screenshots |
| `GET /guest-links/{token}/attachments/{attId}` | `200` / `404` | `200` / `404` | `200` / `404` | `200` / `404` | `200` / `404` | `200` / `404` | Serves **only** attachments of counted `expense`/`income` rows in that token's active group; `404` immediately when guest link is revoked or for `transfer` proof images |

## 9. Planned ADRs (`docs/04-adr.md`)

- **ADR-036: Cumulative Settlement Cycles via Nullable `transactions.cycle_id` Assignment** — Why closing a period stamps `cycle_id` on open transactions and records an immutable closeout snapshot while leaving `transaction_payers` / `transaction_shares` untouched so unpaid debts carry over automatically and late-entered backdated expenses never vanish into closed cycles.
- **ADR-037: Opt-In Revocable Guest Read-Only Links & Server-Authoritative Member Debt Breakdowns** — Why `/share/{token}` is off by default, uses 256-bit revocable group tokens with `no-store` headers, exposes full expense/share transparency + server VietQR while withholding personal banking proof screenshots, and shares one server-computed `MemberDebtBreakdown` model with the authenticated app.
- **ADR-038: Zero-Dependency Client-Side Share Card Rendering (`ImageRenderer` on iOS, 2D `<canvas>` on Web)** — Why high-DPI (`3x`) Light/Dark PNG cards are rendered directly on-device from authoritative server integers rather than headless browsers on the API or DOM-scraping libraries (`html2canvas`).
