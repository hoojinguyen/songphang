# Phase 4 — Stage 4A: Comments and Disputes

> Part of the phase 4 plan. Read `00-overview.md` first.

**Stage goal:** anyone in the group can discuss an expense and mark it as wrong, without changing a number.

**Spec:** sections 3, 7.1, 8.

## Decisions for this stage

1. Comments are listed oldest first, 50 per page, with the usual cursor.
2. A deleted comment disappears from the list and from `commentCount`.
3. Opening a dispute on a transaction that already has an open one answers 409 `DISPUTE_ALREADY_OPEN`; resolving when none is open answers 409 `DISPUTE_NOT_OPEN`.
4. Comments and disputes are allowed on all three transaction types.

---

### Task 4A.1: API — comments

**Files:**
- Create: `packages/db/src/schema-comments.ts`, `packages/db/src/comments.ts`, `packages/contract/src/comment.ts`, `apps/api/src/services/comments.ts`, `apps/api/src/routes/comments.ts`, a migration
- Modify: `packages/db/src/transactions.ts` (`commentCount` in list and detail), `packages/contract/src/transaction.ts`, `apps/api/src/app.ts`, `apps/api/src/rate-limit.ts` (20 comments per minute per user)

**Interfaces — produces:**
- Table `comments` as spec 3.1; index `(transaction_id, created_at)`.
- `CommentDto`: `{ id, authorUserId: uuid | null, authorName, body, createdAt, mine: boolean }`.
- `GET …/transactions/{id}/comments` (viewer), `POST` (viewer; `{ body: string (1–1000, trimmed) }`; `Idempotency-Key`), `DELETE …/comments/{commentId}` (viewer + author or owner; soft delete; 204).
- Comments are readable and writable on a soft-deleted transaction. A transaction id of another group → 404.
- `TransactionDto` and list items gain `commentCount: number`.
- Emits `changed: ["comments", "transactions"]`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — fresh group with the role set-up; one expense by Minh.

| Caller | Request | Expected |
|---|---|---|
| Hùng (viewer) | comment `Hôm đó mình không ăn` | 201; `authorName` `Hùng` |
| Lan | list | one comment, `mine: false` |
| Lan | delete Hùng's comment | 403 |
| Minh (owner) | delete it | 204; `commentCount` 0 |
| Hùng | body of 1001 characters; empty body; body of only spaces | 400 each |
| Hùng | comment containing `<script>alert(1)</script>` | 201; stored and returned verbatim (the web renders text, 4A.3) |
| Minh | delete the transaction; Hùng comments | 201 |
| outsider | list, post | 404 |
| Hùng | 21 comments in a minute | the 21st answers 429 |
| — | balances before and after everything above | identical |

- [ ] **Step 4: Commit** — `feat(api): add comments on transactions`

---

### Task 4A.2: API — disputes

**Files:**
- Create: `packages/db/src/schema-disputes.ts`, `packages/db/src/disputes.ts`, `apps/api/src/services/disputes.ts`, a migration
- Modify: `apps/api/src/routes/comments.ts` (or a new `disputes.ts` route file), `packages/db/src/transactions.ts`, `packages/contract/src/transaction.ts`, `packages/contract/src/error.ts`

**Interfaces — produces:**
- Table `transaction_disputes` as spec 3.1 with its partial unique index.
- `POST …/transactions/{id}/dispute` (viewer; `{ reason: string (1–500) }`) → 201 `{ id, reason, openedByName, openedAt }`. `POST …/dispute/resolve` (viewer + opener or owner) → 200.
- `TransactionDto` and list items gain `dispute: { id, reason, openedByName, openedAt, mine: boolean } | null` (the open one only).
- Both write the activity log (`action` `dispute_open` / `dispute_resolve`, entity `transaction`) and emit `changed: ["transactions", "activity"]`.
- `ErrorCode` gains `DISPUTE_ALREADY_OPEN`, `DISPUTE_NOT_OPEN` (409).
- No query that sums money reads this table.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — same group; expense 600000 by Minh, equal for four.

| Caller | Request | Expected |
|---|---|---|
| Hùng | open `Mình không đi hôm đó` | 201; the transaction's `dispute` is set |
| — | `GET …/balances` | identical to before |
| Lan | open another on the same transaction | 409 `DISPUTE_ALREADY_OPEN` |
| Lan (editor) | resolve | 403 |
| Lan | edit the transaction's amount | 200; the dispute is still open |
| Hùng | resolve | 200; `dispute: null` |
| Hùng | resolve again | 409 `DISPUTE_NOT_OPEN` |
| Hùng | open again; Minh resolves | 201; 200 |
| outsider | open | 404 |
| — | `GET …/activity` | four dispute entries with the actor names |

- [ ] **Step 4: Commit** — `feat(api): add disputes on transactions`

---

### Task 4A.3: Web — the transaction view; stage gate

**Files:**
- Create: `apps/web/src/app/g/[groupId]/tx/[txId]/view/page.tsx`, `apps/web/src/components/transaction/TransactionSummary.tsx`, `apps/web/src/components/transaction/CommentThread.tsx`, `apps/web/src/components/transaction/CommentField.tsx`, `apps/web/src/components/transaction/DisputeBlock.tsx`, `apps/web/src/lib/comments.ts`
- Modify: the stream row (tap target, the tag `đang hỏi lại`, the comment count), the edit page (a back link to the view), `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`

Strings: spec section 7.1.

Behavior:
- Tapping a row in the stream opens the view for every role. `Sửa` in the header (owner and editors) opens the existing edit page. Deep links to the edit page keep working.
- `TransactionSummary` reuses the confirmation card's presentation with the stored shares.
- Comment and reason bodies are rendered as text nodes with `white-space: pre-wrap`. No HTML, no link detection.
- The comment field is fixed at the bottom like the entry bar; Enter sends, Shift+Enter breaks the line; it is enabled for viewers.
- The thread refetches on a `comments` event; a new comment from someone else appears without reload.
- `DisputeBlock` uses the coral token as background with the main text color (check contrast, record the ratio).

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in two browser windows** — viewer comments, owner sees it arrive; the script-tag comment shows as text; dispute, tag in the stream, resolve; keyboard-only: open, comment, dispute, resolve.
- [ ] **Step 4: Commit** — `feat(web): add transaction view with comments and disputes`
- [ ] **Step 5: Stage gate 4A.** Acceptance script: 4A.1 rows 1, 3, 4; 4A.2 rows 1–6. Then the gate of the common file.

**Manual checks for the project owner**
1. Tap an expense → the view opens with `Sửa` at the top. As a viewer: no `Sửa`, but the comment field works.
2. `Khoản này chưa đúng` → give a reason → the stream shows `đang hỏi lại`; the balances have not moved.
