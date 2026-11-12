# Phase 1 — Stage 1C: Splits and Settlements

> Part of the phase 1 plan. Read `00-overview.md` first. Task references inside this file mean this stage's tasks.

**Stage goal:** Every real money situation can be recorded: exact amounts, "the rest split equally", weights, percentages, several payers, transfers, income, and settling a suggested transfer with one tap.

**Spec:** design spec sections 4, 5.2; `docs/03-srs.md` FR-1.42–1.44, 1.51–1.56, 1.64; `docs/05-database-design.md` sections 4–7; `docs/05-api-spec.md` section 3; `docs/06-ux-ui/user-flows.md` flows C2, D, F.

## Decisions for this stage

1. "Bơm hình" is not built (design spec section 4). The split editor has number fields only; the mode button GE4 labels "Bơm hình" is labelled `Số tiền`, as on GE16.
2. A transfer's type cannot be changed into an expense or back; each transaction keeps the type it was created with.
3. In exact mode a member with an empty field takes part in "the rest split equally" (FR-1.52) automatically; the button "Chia đều … còn lại" applies FR-1.53 and exists only when no field is empty.
4. The web app subtracts integers to show "Còn dư" and "Vượt" while typing. Every amount shown under a person still comes from the preview endpoint.

## Review Focus

1. **Rounding in weighted and percent splits.** Every case in the 1C.1 tables sums exactly, and ties go to the lower position. → 1C.1.
2. **Pairwise debts drifting from balances.** With several payers, each member's pairwise transfers still net exactly to their balance. → 1C.1, 1C.2.
3. **Income counted with the wrong sign.** A refund reduces what people owe; the receiver ends up owing the others. → 1C.2.
4. **A split that does not add up is saved.** The API refuses it whatever the web app sent. → 1C.2, 1C.4.
5. **Settling a transfer twice.** Double-tapping "Ghi nhận" stores one transfer. → 1C.5.

---

### Task 1C.1: `core` — one rounding function, all split methods, debt attribution

**Files:**
- Create: `packages/core/src/allocate.ts`, `packages/core/src/decimal.ts`, `packages/core/src/pair-debts.ts`
- Modify: `packages/core/src/split.ts`, `packages/core/src/index.ts`

**Interfaces — produces:**
- `allocateByWeights(total: number, weights: readonly bigint[]): number[]` — **the only place money is divided.** With `BigInt`: `quotient_i = total × w_i / sum` (integer division), `remainder_i = total × w_i mod sum`. Each index gets its quotient; the `total − Σ quotient` leftover đồng go one each to the indexes with the largest remainders, ties to the lower index. `total` is a safe integer ≥ 0; weights are ≥ 0 with a positive sum; otherwise `RangeError`.
- `parseHundredths(text: string): bigint` — a decimal string with at most two decimals (`"1"`, `"1.5"`, `"33.33"`) to an integer of hundredths; anything else throws `RangeError`.
- `type SplitInput` — a union with the exact shapes of `docs/05-database-design.md` section 5: `equal`, `exact` (with `members`, `entries`, `remainder`), `shares`, `percent`.
- `computeShares(amount: number, split: SplitInput, memberIdsByPosition: readonly string[]): { ok: true; shares: Share[] } | { ok: false; code: "SPLIT_TOTAL_MISMATCH"; expected: number; actual: number }` — shares come back in position order, one per participating member, zero amounts included. `splitEqually` stays exported and is now `allocateByWeights` with equal weights.
- `type LedgerEntry = { type: "expense" | "transfer" | "income"; payers: readonly Share[]; shares: readonly Share[] }` (both lists in position order)
- `pairDebtsOf(entry: LedgerEntry): PairDebt[]` — attribution below. `netPairwiseDebts` (1A) is unchanged and consumes the concatenation over all entries.

`computeShares` rules:

| Method | Rule | Mismatch when |
|---|---|---|
| `equal` | `allocateByWeights` with weight 1 per member | — |
| `exact`, `remainder: "none"` | Each member's entry is their share; every member has an entry | Σ entries ≠ amount (`expected` amount, `actual` Σ) |
| `exact`, `equal_among_blank` | Members with an entry keep it; `amount − Σ entries` is split equally among members without one. With no blank member this behaves as `none` | Σ entries > amount; or no blank member and Σ ≠ amount |
| `exact`, `equal_among_all` | `amount − Σ entries` is split equally among all members and added to each entry (a member without an entry starts at 0) | Σ entries > amount |
| `shares` | `allocateByWeights` with `parseHundredths(weight)` | all weights zero (`expected` amount, `actual` 0) |
| `percent` | Percentages must total exactly 100; then `allocateByWeights` with `parseHundredths(percent)` | Σ percent ≠ 100 (`expected` 100, `actual` the integer part of Σ) |

Structural problems (an entry for an id outside `members`, a duplicate id, a negative number) are `RangeError`: the contract schema refuses them before `core` is called.

`pairDebtsOf` — every row and column must sum exactly, so that pairwise transfers net to the same balances as the minimized ones:

1. `capacity_j` starts as payer j's amount.
2. For each share in position order: `parts = allocateByWeights(share.amount, capacities)`; emit a debt of `parts_j` between the share's member and payer j; subtract `parts` from the capacities.
3. Direction: for `expense` and `transfer` the share's member is the debtor and the payer the creditor; for `income` the payer is the debtor and the share's member the creditor.
4. Skip zero amounts; entries where both sides are the same member may be emitted (`netPairwiseDebts` ignores them).

- [ ] **Step 1: Write the three files; rebuild `split.ts` on them**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise — rounding (Review Focus 1)**

`allocateByWeights`:

| Total | Weights | Expected |
|---|---|---|
| 100000 | 1, 1, 1 | 33334, 33333, 33333 |
| 300000 | 2, 1 | 200000, 100000 |
| 100 | 1, 2 | 33, 67 |
| 100 | 150, 100, 100 | 43, 29, 28 |
| 99999 | 5000, 3000, 2000 | 49999, 30000, 20000 |
| 0 | 1, 1 | 0, 0 |
| 5 | 0, 1 | 0, 5 |
| 5 | 0, 0 | `RangeError` |

`computeShares`, members a, b, c (and d where used), in position order:

| Amount | Split | Expected |
|---|---|---|
| 300000 | exact none: a 120000, b 100000, c 80000 | 120000, 100000, 80000 |
| 300000 | exact none: a 150000, b 140000 (members a, b) | mismatch, expected 300000, actual 290000 |
| 300000 | exact blank: a 150000; members a, b, c | 150000, 75000, 75000 |
| 100000 | exact blank: a 50000; members a, b, c, d | 50000, 16667, 16667, 16666 |
| 100000 | exact blank: a 60000, b 40000; members a, b | 60000, 40000 |
| 100000 | exact blank: a 60000, b 50000; members a, b, c | mismatch, expected 100000, actual 110000 |
| 300000 | exact all: a 80000, b 60000, c 40000 | 120000, 100000, 80000 |
| 100000 | exact all: a 10000, b 10000, c 10000 | 33334, 33333, 33333 |
| 100000 | exact all: a 60000, b 50000 | mismatch |
| 100 | shares: a "1.5", b "1", c "1" | 43, 29, 28 |
| 1200000 | shares: a "2", b "1", c "1", d "1" | 480000, 240000, 240000, 240000 |
| 1000 | shares: a "0", b "1" | 0, 1000 |
| 1000 | shares: a "0", b "0" | mismatch |
| 99999 | percent: a "50", b "30", c "20" | 49999, 30000, 20000 |
| 100000 | percent: a "33.33", b "33.33", c "33.34" | 33330, 33330, 33340 |
| 100000 | percent: a "50", b "49.99" | mismatch, expected 100, actual 99 |

- [ ] **Step 4: Exercise — attribution (Review Focus 2)**

| Entry | `pairDebtsOf` | After `netPairwiseDebts` (order a, b, c) |
|---|---|---|
| expense; payers a 200000, b 100000; shares a, b, c 100000 each | a→a 66667, a→b 33333; b→a 66667, b→b 33333; c→a 66666, c→b 33334 | b→a 33334; c→a 66666; c→b 33334 |
| transfer; payer c 50000; share a 50000 | a→c 50000 | a→c 50000 |
| income; payer b 200000; shares a, b, c, d 50000 each | b→a 50000, b→b 50000, b→c 50000, b→d 50000 | b→a 50000; b→c 50000; b→d 50000 |

For the first row: a receives 100000, b receives 33334 and pays 33334, c pays 100000 — exactly the balances +100000, 0, −100000.

- [ ] **Step 5: Commit** — `feat(core): add weighted rounding, all split methods, and debt attribution`

**Manual checks for the project owner**
1. Run three rows of your choice from each table → the outputs match and each row adds up to its amount.

---

### Task 1C.2: API — every transaction type and split

**Files:**
- Modify: `packages/contract/src/transaction.ts`, `packages/db/src/transactions.ts`, `packages/db/src/balances.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/services/balances.ts`, `apps/api/src/routes/transactions.ts`, `packages/contract/src/error.ts`

**Interfaces — produces:**
- `ErrorCode` gains `SPLIT_TOTAL_MISMATCH`.
- `SplitInput` (Zod) mirroring `core`: member lists of 1–100 unique ids; exact entries are `MoneyAmount`; `weight` matches `^\d{1,4}(\.\d{1,2})?$`; `percent` matches `^\d{1,3}(\.\d{1,2})?$`; every entry's member is unique and, for `exact`, listed in `members`.
- `CreateTransactionRequest` becomes a union on `type`:
  - `expense` and `income`: `{ type; description; amount; occurredAt; category; payers: Array<{ memberId; amount }> (1–100 unique members); split: SplitInput }`
  - `transfer`: `{ type: "transfer"; amount; occurredAt; fromMemberId; toMemberId; description?: string }` — the two members differ; `description` defaults to `Chuyển khoản`; no category.
- `TransactionDto.split` is `SplitInput`. A transfer is returned with `payers` = the sender, `shares` = the receiver, and `split` = `{ method: "exact", members: [to], entries: [{ to, amount }], remainder: "none" }`.

Behavior changes:

| Endpoint | Change |
|---|---|
| `POST …/transactions/preview` | Accepts `expense` and `income` with any split. A `core` mismatch → 400 `SPLIT_TOTAL_MISMATCH` with `details.expected` and `details.actual`. |
| `POST …/transactions` | All three types. Validation order: members belong to the group (`MEMBER_NOT_IN_GROUP`); payer total (`PAYER_TOTAL_MISMATCH`); split (`SPLIT_TOTAL_MISMATCH`). `split_method` and `split_input` store what was sent. A transfer stores one payer row and one share row. |
| `GET …/balances` | Balances already invert income (database design section 7); confirm it. Pairwise mode now loads every non-deleted transaction's payers and shares in two queries and uses `pairDebtsOf` + `netPairwiseDebts`. `listPairDebts` from 1A is removed. |

- [ ] **Step 1: Write the schemas and service changes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3, 4)**

Fresh group Minh, Lan, Hùng, Thu; Minh signed in. Create in order and check each response's `shares`:

| # | Transaction | Expected shares |
|---|---|---|
| T1 | expense "Lẩu" 300000, Minh pays; exact, members Minh, Lan, Hùng, entries 80000 / 60000 / 40000, `equal_among_all` | 120000, 100000, 80000 |
| T2 | expense "Khách sạn" 1200000, payers Minh 800000 and Lan 400000; shares Minh "2", Lan "1", Hùng "1", Thu "1" | 480000, 240000, 240000, 240000 |
| T3 | income "Hoàn cọc" 200000, received by Lan; equal, all four | 50000 each |
| T4 | expense "Vé" 99999, Hùng pays; percent Minh "50", Lan "30", Thu "20" | 49999, 30000, 20000 |

`GET …/balances` (minimized) → Minh +500001, Lan −120000, Hùng −170001, Thu −210000; transfers Thu→Minh 210000, Hùng→Minh 170001, Lan→Minh 120000.

| # | Then | Expected |
|---|---|---|
| T5 | transfer Thu → Minh 210000 | Thu 0, Minh +290001; two transfers remain |
| — | `minimizeDebts: false` | for every member, (received − paid) over the listed transfers equals their balance; record the list |
| — | T1 again with entries 200000 / 60000 / 60000 | 400 `SPLIT_TOTAL_MISMATCH`, expected 300000, actual 320000 |
| — | T2 with payers 800000 + 300000 | 400 `PAYER_TOTAL_MISMATCH` |
| — | percent 50 / 30 / 19 | 400 `SPLIT_TOTAL_MISMATCH`, expected 100, actual 99 |
| — | transfer with `fromMemberId` = `toMemberId` | 400 `VALIDATION_FAILED` |
| — | `weight: "1.234"`, `percent: "-5"`, an entry for a member not in `members` | 400 `VALIDATION_FAILED` each |
| — | preview of T2 | same shares, nothing stored |

`pnpm db:check-balances` → balanced. The 1A acceptance requests still return the same numbers.

- [ ] **Step 4: Commit** — `feat(api): support all split methods, several payers, transfers, and income`

**Manual checks for the project owner**
1. Run T1–T4 and read the balances → the four numbers above, summing to 0.
2. Run T3 alone in a new group → Lan owes each of the other three 50.000 đ.

---

### Task 1C.3: Web — transaction type, several payers, transfer and income forms

**Files:**
- Create: `apps/web/src/components/expense-form/TypeSwitch.tsx`, `apps/web/src/components/expense-form/PayerAmounts.tsx`, `apps/web/src/components/expense-form/TransferFields.tsx`
- Modify: `apps/web/src/components/expense-form/ExpenseForm.tsx`, `MemberToggleGrid.tsx`, `apps/web/src/lib/transactions.ts`, `apps/web/src/messages/vi.ts`

Strings:

| Key | Value |
|---|---|
| `expenseForm.typeLabel` | `Loại giao dịch` |
| `expenseForm.typeExpense` | `Chi` |
| `expenseForm.typeTransfer` | `Chuyển` |
| `expenseForm.typeIncome` | `Thu` |
| `expenseForm.titleTransfer` | `Chuyển khoản mới` |
| `expenseForm.titleIncome` | `Khoản thu mới` |
| `expenseForm.receiverTitle` | `Ai nhận tiền?` |
| `expenseForm.beneficiariesTitle` | `Chia cho ai?` |
| `expenseForm.transferFrom` | `Ai chuyển?` |
| `expenseForm.transferTo` | `Chuyển cho ai?` |
| `expenseForm.payerAmountLabel` | `{name} trả` |
| `expenseForm.payersMatch` | `Khớp {amount}` |
| `expenseForm.payersShort` | `Còn dư {amount}` |
| `expenseForm.payersOver` | `Vượt {amount}` |
| `expenseForm.saveTransfer` | `Lưu chuyển khoản` |
| `expenseForm.saveIncome` | `Lưu khoản thu` |
| `expenseForm.descriptionTransferPlaceholder` | `Ghi chú (không bắt buộc)` |

Behavior:

| Part | Behavior |
|---|---|
| `TypeSwitch` | In the header's trailing slot (GE19): a surface pill, radius 22, padding 4, three `aria-pressed` buttons, height 40, 12px; selected ink. Switching keeps amount, description and date. Not shown when editing (stage 1E). |
| Expense | "Ai trả?" becomes multi-select; at least one payer. With one payer nothing else appears. With several, `PayerAmounts` lists a money field per selected payer (label `expenseForm.payerAmountLabel`, same field style as the split rows of 1C.4) and a status line: match (background `phrase-split`), short or over (background `debt-soft`). Save needs a match. |
| Income | Title `titleIncome`; the first card is titled `receiverTitle` (single selection, default the viewer); the second `beneficiariesTitle`, with the split controls of an expense; button `saveIncome`. |
| Transfer | Title `titleTransfer`; `TransferFields`: two single-selection grids, `transferFrom` (default the viewer) and `transferTo` (the sender is disabled there); amount; optional note; date; button `saveTransfer`. No category, no split. |

- [ ] **Step 1: Write the components and form changes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser:** record T2 (two payers), T3 (income) and T5 (transfer) of 1C.2 through the form and compare the stored transactions with the `curl` results; try saving two payers whose amounts do not match; switch types back and forth and confirm amount, description and date survive; choose the same person on both sides of a transfer (must be impossible).
- [ ] **Step 4: Commit** — `feat(web): add transfer and income forms and several payers`

**Manual checks for the project owner**
1. Compare the header switch with GE19.
2. Record a hotel bill paid 800.000 by Minh and 400.000 by Lan → both appear as payers; the status line reads "Khớp 1.200.000 đ" before saving.
3. Record a refund received by Lan → on the balances screen Lan now owes the others.

---

### Task 1C.4: Web — split editor

**Files:**
- Create: `apps/web/src/components/expense-form/SplitEditor.tsx`, `SplitModeTabs.tsx`, `SplitMemberRow.tsx`, `SplitStatus.tsx`
- Modify: `apps/web/src/components/expense-form/ExpenseForm.tsx`, `apps/web/src/messages/vi.ts`

Strings:

| Key | Value |
|---|---|
| `split.change` | `{method} · đổi cách chia` |
| `split.modeEqual` | `Đều` |
| `split.modeExact` | `Số tiền` |
| `split.modeShares` | `Phần` |
| `split.modePercent` | `%` |
| `split.methodEqual` | `Chia đều` |
| `split.methodExact` | `Theo số tiền` |
| `split.methodShares` | `Theo phần` |
| `split.methodPercent` | `Theo phần trăm` |
| `split.unitMoney` | `đồng` |
| `split.unitShares` | `phần` |
| `split.unitPercent` | `%` |
| `split.memberField` | `Phần của {name}` |
| `split.addMember` | `Thêm {name} vào khoản này` |
| `split.removeMember` | `Bỏ {name} khỏi khoản này` |
| `split.spreadRest` | `Chia đều {amount} còn lại cho {count} người` |
| `split.undoSpread` | `Bỏ chia đều phần còn lại` |
| `split.match` | `Khớp {amount} · không còn dư` |
| `split.blankShare` | `Còn {amount} chia đều cho {count} người để trống` |
| `split.short` | `Còn dư {amount} · chưa lưu được` |
| `split.over` | `Vượt {amount} · chưa lưu được` |
| `split.percentMatch` | `Khớp 100%` |
| `split.percentShort` | `Còn thiếu {percent}% · chưa lưu được` |
| `split.percentOver` | `Vượt {percent}% · chưa lưu được` |
| `split.done` | `Xong` |

Behavior:

| Part | Behavior |
|---|---|
| Entry | The tag beside "Chia cho ai?" becomes a button `split.change` with the current method's name (GE19: radius 22, background `phrase-split`, height 44, 12px weight 800). It opens `SplitEditor` as a full-height panel over the form; `split.done` and the back arrow return to the form keeping the state. |
| Header | Description (or the form title when empty) 17px weight 800; payer line 12px muted; the amount 22px weight 900 on the right (GE4). |
| `SplitModeTabs` | Four `aria-pressed` buttons (GE16): the selected one stretches, ink, radius 20, height 52, 15px weight 800; the others 56 wide, surface, radius 26, 13px. Changing mode keeps the participating members and clears the numbers. |
| Shapes | A surface card, radius 40, with each participating member's `MemberShape`: diameter between 56 and 104, scaled linearly by that member's share of the amount from the latest preview; the result amount under each shape, 13px weight 800. |
| `SplitMemberRow` | Per participating member (GE4): surface, radius 26, a small shape, name 16px weight 800, and a field in a `bg` pill (radius 18, height 48) with the unit label and a right-aligned input 20px weight 900, labelled `split.memberField`; the focused row has a 3px ink border. Money fields format with dots as the amount field does; weight and percent fields accept digits and one decimal separator with two decimals. A 44 × 44 remove button labelled `split.removeMember`. In `Đều` mode rows have no field. |
| Non-participants | One dashed button `split.addMember` per active member who is not in the split (height 56, radius 26). |
| `Số tiền` | Any empty field → `remainder: "equal_among_blank"`, status `split.blankShare` (allowed to save when the rest is ≥ 0). No empty field and the sum below the amount → status `split.short` plus the lilac button `split.spreadRest` (background `phrase-rest` `#E7D9FF`, height 56, radius 28), which sets `remainder: "equal_among_all"`; then status `split.match` and the button reads `split.undoSpread`. Sum above → `split.over`. |
| `Phần` | Default field value is each member's `defaultWeight`. Always saveable unless every weight is 0. |
| `%` | Status from the sum of the fields: match, short or over, compared as hundredths. |
| `SplitStatus` | A bar above the save button (GE4, GE16): radius 22, 14px weight 700, a check icon on match with background `phrase-split`, a warning icon otherwise with background `debt-soft`; `role="status"`. |
| Saving | "Lưu khoản chi" is enabled only in a saveable state. The preview request (debounced 250 ms) is built only in a saveable state; a `SPLIT_TOTAL_MISMATCH` from the server shows `split.short` or `split.over` from its `details`. |

New tokens: `--color-phrase-rest: #e7d9ff`. New `Icon` names: `check` (`M5 12l5 5 9-10`), `warning` (`M12 8v5M12 17h.01`).

- [ ] **Step 1: Write the components**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 4)**

1. 300.000, mode Số tiền, Minh 80.000, Lan 60.000, Hùng 40.000 → "Còn dư 120.000 đ · chưa lưu được"; tap the lilac button → shapes show 120.000 / 100.000 / 80.000; "Khớp 300.000 đ · không còn dư"; save; the stored `split` has `remainder: "equal_among_all"`.
2. 300.000, Minh 150.000, Lan and Hùng empty → "Còn 150.000 đ chia đều cho 2 người để trống"; shapes 150.000 / 75.000 / 75.000; save.
3. Fields summing to 320.000 → "Vượt 20.000 đ · chưa lưu được"; save disabled.
4. Mode Phần with 1,5 / 1 / 1 on 100 đ → 43 / 29 / 28.
5. Mode % with 50 / 30 / 19 → "Còn thiếu 1% · chưa lưu được"; 50 / 30 / 20 on 99.999 → 49.999 / 30.000 / 20.000.
6. Remove Thu, add Thu back; switch modes; leave and reopen the editor → state as described.
7. Shapes change size as shares change; the smallest still shows its initial.
8. Everything is operable by keyboard and each field is announced with the person's name.
9. `pnpm db:check-balances` → balanced.

- [ ] **Step 4: Commit** — `feat(web): add split editor for exact, weighted, and percent splits`

**Manual checks for the project owner**
1. Compare the editor with GE4 and GE16: the tabs (with "Số tiền" in place of "Bơm hình"), the rows, the status bar, the lilac button.
2. Do exercise steps 1, 2 and 3.
3. Try to save a split that does not add up → impossible in every mode.

---

### Task 1C.5: Web — settling, and transfers and income in the stream

**Files:**
- Create: `apps/web/src/app/g/[groupId]/settle/page.tsx`, `apps/web/src/components/feed/LedgerPill.tsx`, `apps/web/src/components/balances/OwnSettlementCard.tsx`, `apps/web/src/components/balances/OtherSettlements.tsx`
- Modify: `apps/web/src/components/balances/SettlementCard.tsx`, `AllSettled.tsx`, the balances page, `apps/web/src/components/feed/ExpenseStream.tsx`, `apps/web/src/messages/vi.ts`

Strings:

| Key | Value |
|---|---|
| `balances.youPayHeadline` | `Bạn chuyển {count} lần là xong` |
| `balances.youPayHint` | `Chuyển xong thì bấm Đã trả để sổ khớp.` |
| `balances.collectHint` | `Ít lượt chuyển nhất có thể. Bấm Đã nhận khi tiền về.` |
| `balances.received` | `Đã nhận` |
| `balances.paid` | `Đã trả` |
| `balances.record` | `Ghi nhận` |
| `balances.othersTitle` | `Lượt của người khác` |
| `balances.recordedTitle` | `{count} lượt chuyển đã ghi nhận` |
| `balances.memberPaidYou` | `{name} đã trả bạn` |
| `balances.youPaidMember` | `Bạn đã trả {name}` |
| `balances.memberPaidMember` | `{from} đã trả {to}` |
| `settle.titleReceived` | `Ghi nhận đã nhận` |
| `settle.titlePaid` | `Ghi nhận đã trả` |
| `settle.title` | `Ghi nhận thanh toán` |
| `settle.amountLabel` | `Số tiền {name} đã trả` |
| `settle.partialHint` | `{name} trả ít hơn? Sửa con số, phần còn lại vẫn nằm trong sổ.` |
| `settle.today` | `Hôm nay` |
| `settle.yesterday` | `Hôm qua` |
| `settle.otherDay` | `Ngày khác` |
| `settle.clears` | `Sau khoản này {name} không còn nợ ai` |
| `settle.submit` | `Ghi nhận {amount}` |
| `feed.transferToYou` | `{name} đã chuyển cho bạn {amount}` |
| `feed.transferFromYou` | `Bạn đã chuyển cho {name} {amount}` |
| `feed.transferOther` | `{from} đã chuyển cho {to} {amount}` |
| `feed.income` | `{name} nhận về {amount} · {description}` |
| `feed.incomeYou` | `Bạn nhận về {amount} · {description}` |

Behavior:

| Part | Behavior |
|---|---|
| S5, viewer owes (GE13) | Headline `balances.youPayHeadline` with the number of transfers the viewer must make, hint `youPayHint`. Each of the viewer's own transfers is an `OwnSettlementCard`: surface, radius 40, the creditor's `MemberShape` 84, "Bạn trả {name}" 13px, amount 40px weight 900, and an accent button `balances.paid`, height 60. Then `OtherSettlements` (surface, radius 30, title `balances.othersTitle`): one line per other transfer with a 28px shape, "{from} trả {to}", the amount, and for editors a small `balances.record` button. Then `BalanceBars`. |
| S5, viewer is owed or uninvolved (GE5) | Headline as in 1A with `balances.collectHint` in minimized mode. `SettlementCard` gains a button: `balances.received` when the viewer is the receiver, `balances.record` otherwise. No "Nhắc" buttons. |
| S5, viewers | No buttons. |
| S9 `/g/{groupId}/settle?from=…&to=…&amount=…` | Editor only. Query values are validated against the group's members and the amount range; anything invalid falls back to `/g/{id}/balances`. Layout GE12: title `settle.titleReceived` (viewer is `to`), `settle.titlePaid` (viewer is `from`) or `settle.title`; a surface card, radius 40, with the two shapes at 104 and an arrow between them (`Icon` `arrow-right`: `M4 12h16M14 6l6 6-6 6`), names beneath, the viewer shown as `Bạn`; the amount field (46px weight 900, 3px ink border, labelled `settle.amountLabel`), prefilled and editable; `settle.partialHint`; three date chips, "Ngày khác" revealing a native date input; `settle.clears` in a `phrase-split` bar when the amount equals the sender's whole debt; the accent button `settle.submit`, height 68. Saving creates a transfer with one idempotency key per mount and returns to the balances screen. |
| `AllSettled` | Adds the card of GE18: `balances.recordedTitle` and the five most recent transfers, each with a 28px shape, the `…đã trả…` line and the amount. |
| `LedgerPill` in the stream | Transfers and income are centered pills (GE2): background `sunken`, radius 18, padding 6/12/6/8, 12px weight 600, an 18px `MemberShape` of the sender or receiver, and the text from the five `feed.*` strings with `formatMoney`. |

- [ ] **Step 1: Write the page and components**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 5):** with the T1–T4 data, as Minh tap "Đã nhận" on Thu's card → the amount is 210.000; save → the card disappears, the stream shows "Thu đã chuyển cho bạn 210.000 đ", Minh's block drops to 290.001 đ. As Lan (editor, joined in 1B) the screen follows GE13 with "Bạn trả Minh 120.000"; change the amount to 100.000 and save → 20.000 remains. Double-tap the submit button → one transfer. Open `/settle` with a made-up member id → back on balances. Settle everything → "Cả nhóm đã xong." with the recorded list.
- [ ] **Step 4: Commit** — `feat(web): add settlement recording and ledger pills`

**Manual checks for the project owner**
1. Compare the three screens with GE5, GE13 and GE12 (no "Nhắc" or "Xác nhận" buttons).
2. Settle one suggested transfer in full and one in part → the remaining suggestion is the unpaid part.
3. After everything is settled, compare with GE18.

---

### Task 1C.6: Stage gate 1C

- [ ] **Step 1: Run the stage gate.** Acceptance script, reset database, `curl` only: T1–T5 of Task 1C.2 with their expected shares, balances and transfers; the pairwise check of 1C.2; the four refusal rows; `pnpm db:check-balances`. Then the 1A and 1B acceptance scripts again. Permission matrix: preview and create as viewer → 403; as outsider → 404.
- [ ] **Step 2: Record the gate result; commit any fixes**

**Manual checks for the project owner — stage 1C**
1. Record one real restaurant bill you remember, with personal items and shared dishes, entirely through the screens, and check each person's amount against your own arithmetic.
