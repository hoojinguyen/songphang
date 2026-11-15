# Phase 2 — Stage 2C: The Fund

> Part of the phase 2 plan. Read `00-overview.md` first.

**Stage goal:** a group keeps a shared fund: people contribute, expenses are paid from it, and everyone sees what is left and who put in what.

**Spec:** section 6, 9.2 (fund lines), 9.4, 10.

## Decisions for this stage

1. The fund's `position` is assigned like any member's. It is excluded from every "people" list by `kind`, never by position.
2. `MemberDto` gains `kind`. `GET …/members` returns the fund too; clients that list people filter on `kind`.
3. A fund counts toward the 100-member limit.
4. `contributions` lists only members with a non-zero net contribution, in `position` order.

## The fund ledger

Used by 2C.2 and the gate. Fresh group Minh, Lan, Hùng (three people); Minh signed in.

| # | Action | Fund balance | Cash | Minh | Lan | Hùng |
|---|---|---|---|---|---|---|
| F0 | create the fund, holder Lan | 0 | 0 | 0 | 0 | 0 |
| F1 | transfer Lan → fund 500000 | −500000 | 500000 | 0 | +500000 | 0 |
| F2 | expense "Ăn tối" 300000, payer fund, equal for the three people | −200000 | 200000 | −100000 | +400000 | −100000 |
| F3 | transfer fund → Lan 200000 | 0 | 0 | −100000 | +200000 | −100000 |

After F2, minimized suggestions: fund → Lan 200000; Minh → Lan 100000; Hùng → Lan 100000. Contributions after F2: Lan 500000; after F3: Lan 300000.

---

### Task 2C.1: Database and `core` — a member of kind `fund`

**Files:**
- Create: a migration
- Modify: `packages/db/src/schema-groups.ts` (or where `members` lives), the integrity trigger's SQL (a new migration replaces the function; never edit a committed one), `packages/db/src/members.ts`, `packages/db/src/check-balances.ts`, `packages/core/src/settlements.ts`, `packages/core/src/index.ts`

**Interfaces — produces:**
- `members.kind text NOT NULL DEFAULT 'person' CHECK (kind IN ('person', 'fund'))`; `members.fund_holder_member_id uuid REFERENCES members ON DELETE SET NULL` with `CHECK (kind = 'fund' OR fund_holder_member_id IS NULL)`; unique index on `(group_id) WHERE kind = 'fund'`.
- `group_users.member_id` may never point at a fund: enforced in the join and "tôi là người này" services and by a trigger on `group_users`.
- The deferred constraint trigger additionally raises when a `transaction_shares` row's member has `kind = 'fund'` and the transaction's `type` is `expense` or `income`. A transfer to the fund (one share row on the fund) stays allowed.
- `check-balances` additionally reports any share on a fund in an expense or income.
- `suggestSettlements` (real name from the re-baseline) is unchanged in arithmetic; its input rows gain nothing. The fund is simply one more participant.
- `listPeople(db, groupId)` and `findFund(db, groupId)` in `packages/db/src/members.ts`; every existing caller that means "the group's people" (default split, invite preview, participant chips, member count shown to users) moves to `listPeople`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — directly in `psql`, inside one transaction each, then rolled back:

| Statement | Expected |
|---|---|
| insert a second member of kind `fund` in a group that has one | unique violation |
| insert a `transaction_shares` row on the fund for an expense, with matching totals | the trigger raises at commit |
| insert a transfer whose share row is the fund | commits |
| set `group_users.member_id` to the fund | the trigger raises |
| a person with `fund_holder_member_id` set | check violation |

- [ ] **Step 4: Commit** — `feat(db): add fund members and their integrity rules`

---

### Task 2C.2: API — fund endpoints, balances block, warnings

**Files:**
- Create: `packages/contract/src/fund.ts`, `apps/api/src/services/fund.ts`, `apps/api/src/routes/fund.ts`, `packages/db/src/fund.ts`
- Modify: `packages/contract/src/member.ts`, `packages/contract/src/balance.ts`, `packages/contract/src/transaction.ts`, `packages/contract/src/error.ts`, `apps/api/src/services/balances.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/services/members.ts`, `apps/api/src/services/invites.ts`, `apps/api/src/app.ts`

**Interfaces — produces:**
- `POST /groups/{groupId}/fund` (editor; `{ name?: string (1–50), holderMemberId?: uuid }`; default name `Quỹ chung`; `Idempotency-Key`) → 201 `MemberDto` with `kind: "fund"`, `shape: "fund"`, `color: "sun"`. A second fund → 409 `FUND_EXISTS`.
- `PATCH /groups/{groupId}/fund` (editor; `{ name?, holderMemberId?: uuid | null, active?: boolean }`). `active: false` with non-zero cash → 422 `FUND_NOT_EMPTY`. The holder must be a person of the group.
- `DELETE /groups/{groupId}/fund` (editor): 204 when the fund has no transaction; otherwise 422 `MEMBER_HAS_TRANSACTIONS`.
- The generic member endpoints refuse a fund id: `PATCH`/`DELETE …/members/{fundId}` → 404; payment methods on a fund → 404.
- `ErrorCode` gains `FUND_CANNOT_SHARE` (422), `FUND_NOT_EMPTY` (422), `FUND_EXISTS` (409).
- Transactions: a fund in `split.members`, in exact, shares or percent entries, or as a share of an income → 422 `FUND_CANNOT_SHARE`, checked before the totals. A fund may be in `payers`, and may be `fromMemberId` or `toMemberId`.
- `warnings: Array<"FUND_OVERDRAWN" | "BUDGET_NEAR" | "BUDGET_OVER">` on the preview response and on the create and edit responses (always present, possibly empty). `FUND_OVERDRAWN` when, after this transaction, the fund's cash would be below 0. The preview computes it from the current balance and the draft; nothing is stored.
- `GET …/balances`: `balances` lists people only; `fund: { memberId, name, active, cash, holderMemberId, contributions: Array<{ memberId, amount }> } | null`; `transfers` may have the fund on either side. `fundCashAndContributions(db, groupId)` in `packages/db/src/fund.ts`: cash = −(fund balance from the existing balance query); contributions = Σ transfers person → fund − Σ transfers fund → person, live transactions only.
- The invite preview lists people only.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — the fund ledger, checking every cell of its table after each row, then:

| Request | Expected |
|---|---|
| after F2: `GET …/balances` | `fund.cash` 200000; `contributions` `[{ Lan, 500000 }]`; the three transfers listed above; `balances` has three entries summing to +200000 |
| expense with the fund in `split.members` | 422 `FUND_CANNOT_SHARE` |
| income received by the fund, equal for three people | 201 (the fund holds the money; cash rises) — then delete it |
| after F3: preview of an expense 50000 paid by the fund | `warnings: ["FUND_OVERDRAWN"]` |
| after F3: `PATCH` `active: false` | 200 |
| after F2 (before F3): `PATCH` `active: false` | 422 `FUND_NOT_EMPTY` |
| `DELETE …/fund` after F1 | 422 `MEMBER_HAS_TRANSACTIONS` |
| a second `POST …/fund` | 409 `FUND_EXISTS` |
| join through the invite choosing the fund's id | 400 |
| viewer: `POST …/fund` | 403 |
| default equal split of a new expense (no members sent, if the API supports a default; else the web's default in 2C.4) | three people |

`pnpm db:check-balances` → `All groups balanced`.

- [ ] **Step 4: Commit** — `feat(api): add the shared fund`

**Manual checks for the project owner**
1. Run F0–F3 with `curl` and read the balances after each → the table's numbers.

---

### Task 2C.3: `core` — the fund in the sentence reader

**Files:**
- Modify: the reader's files in `packages/core/src/` (real names from the re-baseline), `apps/api/src/services/transactions.ts` (pass the fund to the reader), `packages/contract/src/transaction.ts` (issue code)

**Interfaces — produces:**
- The reader's member input gains `kind`. In the payer position the phrases `quỹ trả`, `quy tra`, `từ quỹ`, `tu quy`, and the fund's own normalised name followed by `trả`, select the fund; span kind `payer`.
- Without a fund: issue `MEMBER_UNKNOWN` on the phrase. A person whose normalised name equals `quy`: `MEMBER_AMBIGUOUS` with both candidates.
- A fund named in a share position: issue `FUND_CANNOT_SHARE`, status `unparsed`.
- `chia <N>` compares N with the number of active **people**.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — every one of the 12 fund sentences the advisor appended to `docs/08-quick-entry-samples.md`, plus all earlier samples again. Record a table: sentence, expected, actual, match. Every row must match; a mismatch is a defect to fix, never a sample to change.
- [ ] **Step 4: Commit** — `feat(core): read expenses paid from the fund`

---

### Task 2C.4: Web — the fund

**Files:**
- Create: `apps/web/src/app/g/[groupId]/fund/page.tsx`, `apps/web/src/components/fund/FundBlock.tsx`, `apps/web/src/components/fund/CreateFundDialog.tsx`, `apps/web/src/components/ui/FundShape.tsx`, `apps/web/src/lib/fund.ts`
- Modify: the balances screen, the members screen, the expense form's payer picker and participant grid, the transfer fields, the shape renderer, `apps/web/src/app/globals.css` (token `--color-sun: #FFD84D` if the accent token cannot be reused), `apps/web/src/messages/vi.ts`

Strings: spec section 9.4 and the fund lines of 9.2.

Behavior:
- The shape renderer maps `fund` to a horizontal pill (width 1.6 × height, fully rounded) in `sun`, with no initial inside.
- `FundBlock` on S5, above the people's balances when a fund exists: the title line of 9.2 and the holder's name; tapping opens S17.
- S17: the cash as the large number under `Quỹ còn` (or the negative wording); `Đã góp` list; the two buttons open the transfer form with the fund fixed as receiver or sender.
- Payer picker: `Quỹ chung trả` (the fund's name replaces `Quỹ chung` when renamed) as an option beside the people. Participant grid: people only.
- A suggested transfer with the fund on a side uses the wording of 9.2 and has no paying screen: `Ghi nhận` opens the transfer form prefilled.
- The preview's `FUND_OVERDRAWN` shows the warning line with the amount = the overdraft, taken from `fund.cash` and the draft by integer subtraction for display.
- S10: `Lập quỹ chung` for editors when no fund exists; when one exists, a fund row that opens S17 with rename, holder, and close controls.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — the fund ledger through the screens; overdraw; try to close a non-empty fund; type `ăn tối 300k quỹ trả` in the typing box → the card shows the fund as payer.
- [ ] **Step 4: Commit** — `feat(web): add the shared fund`

**Manual checks for the project owner**
1. S10 → `Lập quỹ chung` → `Góp vào quỹ` 500.000 from one person → S5 shows `Quỹ còn 500.000 đ`.
2. Add an expense with `Quỹ chung trả` → the fund drops, nobody's personal debt to another person changes except by their share.
3. Pay more than the fund holds → a warning, and it still saves.

---

### Task 2C.5: Stage gate 2C

- [ ] **Step 1:** Acceptance script on a reset database: the fund ledger with the balances after F1, F2, F3; the `FUND_CANNOT_SHARE` request; the direct insert of 2C.1 row 2.
- [ ] **Step 2:** The gate of the common file. Every earlier acceptance script must still pass with `balances` listing people only; where an earlier script's group has no fund, its numbers are unchanged.
- [ ] **Step 3:** Record the gate; commit any fixes as their own commits.
