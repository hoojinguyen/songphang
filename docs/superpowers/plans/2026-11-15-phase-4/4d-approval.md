# Phase 4 — Stage 4D: Approval

> Part of the phase 4 plan. Read `00-overview.md` first.

**Stage goal:** when the owner sets a threshold, a large expense entered by someone else counts only after the owner approves it.

**Spec:** section 6, 7.5, 8.

## Decisions for this stage

1. "Counts" is one SQL fragment, `countedTransaction`, defined once in `packages/db/src/transactions.ts`: `deleted_at IS NULL AND approval_status IN ('none', 'approved')`. Every query that sums money uses it; none spells the condition itself.
2. The threshold compares with the expense's `amount`: `amount >= threshold` needs approval.
3. Approving or rejecting anything but a `pending` expense answers 409 `APPROVAL_NOT_PENDING`.
4. A pending or rejected expense is still listed, viewable, commentable and editable.
5. Suggested transfers, reminders and the bot's `/sodu` follow balances, so they ignore pending expenses without further work.

---

### Task 4D.1: Database and money path — the approval filter

**Files:**
- Create: a migration
- Modify: `packages/db/src/schema-transactions.ts`, `packages/db/src/schema-groups.ts`, `packages/db/src/transactions.ts`, `packages/db/src/balances.ts`, `packages/db/src/check-balances.ts`, and, when phase 2 is merged, `packages/db/src/stats.ts`, `packages/db/src/budgets.ts`, `packages/db/src/fund.ts`, the export query

**Interfaces — produces:**
- `transactions.approval_status text NOT NULL DEFAULT 'none' CHECK (… IN ('none', 'pending', 'approved', 'rejected'))`, `approval_decided_by uuid REFERENCES users ON DELETE SET NULL`, `approval_decided_at timestamptz`, `approval_note text` with a length check of 300.
- `groups.approval_threshold bigint CHECK (approval_threshold IS NULL OR approval_threshold > 0)`.
- `countedTransaction` (decision 1), used by: the balance query, the pairwise-debt loader, `check-balances`, and the phase 2 queries named above.
- `check-balances` still requires every group to sum to 0 over counted transactions, and still checks the payer and share totals of **every** live transaction, pending or not.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 5)** — a group with three counted expenses; in `psql` set one to `pending`.

| Check | Expected |
|---|---|
| `GET …/balances` | as if that expense did not exist; the sum is 0 |
| `minimizeDebts: false` | the same |
| statistics, budget `spent`, CSV rows (phase 2) | the expense is absent from each |
| `pnpm db:check-balances` | `All groups balanced` |
| set it to `rejected` | the same results |
| set it to `approved` | everything as before the change |
| the output of `rg "transaction_shares\|transaction_payers" packages/db/src` | listed in `progress.md`, each hit marked "filtered" or explained |

- [ ] **Step 4: Commit** — `feat(db): exclude pending and rejected expenses from every sum`

---

### Task 4D.2: API — threshold, pending, approve, reject

**Files:**
- Create: `apps/api/src/services/approval.ts`, `packages/core/src/approval.ts`
- Modify: `apps/api/src/services/transactions.ts`, `apps/api/src/routes/transactions.ts`, `apps/api/src/services/groups.ts`, `packages/contract/src/transaction.ts`, `packages/contract/src/group.ts`, `packages/contract/src/error.ts`, `packages/core/src/index.ts`

**Interfaces — produces:**
- `approvalStatusFor(input: { type; amount: number; threshold: number | null; actorIsOwner: boolean }): "none" | "pending"` in `core` — `pending` only when the type is `expense`, a threshold exists, `amount >= threshold`, and the actor is not the owner.
- Create: status from that function. Edit by a non-owner: recomputed from the new amount (so an approved or rejected expense that still meets the threshold becomes `pending`, and one below it becomes `none`). Edit by the owner: `none` when below the threshold, otherwise `approved` with the owner as decider. Decision fields are cleared whenever the status becomes `none` or `pending`.
- `POST …/transactions/{id}/approve` and `…/reject` (`{ note?: string (0–300) }`; owner). Each writes the activity log, calls `notify` with `approval_decided` for the creator, and emits `changed: ["transactions", "balances", "activity"]`.
- Creating or editing into `pending` calls `notify` with `approval_requested` for the owner.
- `TransactionDto` and list items gain `approval: { status, decidedByName: string | null, decidedAt: string | null, note: string | null }`.
- `PATCH /groups/{groupId}` accepts `approvalThreshold: MoneyAmount | null` (owner). Changing it does not touch existing transactions.
- `ErrorCode` gains `APPROVAL_NOT_PENDING` (409).
- The bot's "saved" reply (4C.2) appends ` Khoản này chờ {owner} duyệt.` when the saved transaction is pending.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — fresh group Minh (owner), Lan (editor), Hùng (viewer); threshold 1000000.

`approvalStatusFor`: expense 1000000 / threshold 1000000 / not owner → `pending`; 999999 → `none`; owner → `none`; threshold null → `none`; transfer 5000000 → `none`; income 5000000 → `none`.

| # | Caller | Request | Expected |
|---|---|---|---|
| 1 | Lan | expense 1200000, Lan pays, equal for Minh, Lan, Hùng | 201; `approval.status` `pending`; balances all 0; Minh has an `approval_requested` notification |
| 2 | Lan | expense 999999, Lan pays, equal for the three | `none`; balances Lan +666666, Minh −333333, Hùng −333333 |
| 3 | Lan | approve #1 | 403 |
| 4 | Minh | approve #1 | 200; balances Lan +1466666, Minh −733333, Hùng −733333; Lan has `approval_decided` |
| 5 | Minh | approve #1 again | 409 `APPROVAL_NOT_PENDING` |
| 6 | Lan | edit #1 to 1500000 | `pending` again; balances back to row 2's |
| 7 | Minh | reject #1 with the note `Chưa có hoá đơn` | `rejected`; balances unchanged from row 2's; the note is returned |
| 8 | Lan | edit #1 to 900000 | `none`; balances Lan +1266666, Minh −633333, Hùng −633333 |
| 9 | Minh | expense 5000000, Minh pays, equal for the three | `none`; counts at once |
| 10 | Lan | transfer 2000000 Lan → Minh | `none` |
| 11 | Minh | set the threshold to null; Lan adds 3000000 | `none` |
| 12 | Lan | set the threshold | 403 |
| 13 | Minh | a note of 301 characters | 400 |

`pnpm db:check-balances` after rows 1, 4, 7 → `All groups balanced` each time.

- [ ] **Step 4: Commit** — `feat(api): add approval of expenses above a threshold`

---

### Task 4D.3: Web — approval

**Files:**
- Create: `apps/web/src/components/transaction/ApprovalBlock.tsx`, `apps/web/src/components/settings/ApprovalCard.tsx`
- Modify: the transaction view, the stream row (tags), the settings page, the save confirmation of the form and the confirmation card, `apps/web/src/messages/vi.ts`

Strings: spec section 7.5 and the approval lines of 7.3.

Behavior: a pending or rejected row in the stream is drawn at 60 % opacity with its tag, so it reads as not counted; the tag text carries the meaning, not the opacity. `ApprovalBlock` shows the two buttons to the owner only. The settings card is a switch plus the money input.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in two browser windows** — rows 1, 4, 6, 7 of 4D.2 through the screens; the owner's bell line opens the view; the pending row's tag is readable at 60 % opacity (record the contrast ratio; raise the opacity if below AA).
- [ ] **Step 4: Commit** — `feat(web): add expense approval`

**Manual checks for the project owner**
1. S11 → `Duyệt khoản chi lớn` from 1.000.000 → as an editor add 1.200.000 → it shows `chờ duyệt` and S5 does not change → as the owner `Duyệt` → S5 changes.
2. `Không duyệt` with a note → the note shows on the expense; S5 does not change.

---

### Task 4D.4: README, non-functional checks, final gate

**Files:**
- Modify: `README.md` (notifications, jobs and their schedules, the Telegram variables and the console sender, approval), `infra/compose.prod.yml` if it exists (nothing new beyond the worker; confirm)

- [ ] **Step 1: README.**
- [ ] **Step 2: Non-functional checks.** Keyboard-only walk through the transaction view, the notification list and the settings cards; the bell's badge has an accessible name `{count} thông báo chưa đọc`; with 1,000 notifications seeded for one user the list's first page answers in under 300 ms (record the query plan).
- [ ] **Step 3: Stage gate 4D** — acceptance script: 4D.2 rows 1, 2, 4, 6, 7 with the balances. Then the full gate of the common file, replaying 4A–4C and every earlier phase. Every earlier acceptance script must give its old numbers, since none of their groups has a threshold.
- [ ] **Step 4: Finish the run files.** `manual-checks.md` by screen (S20, S19, S5, S11, S13, Telegram), with a section "After the Telegram bot exists".
- [ ] **Step 5: Commit** — `docs(repo): document phase 4`
