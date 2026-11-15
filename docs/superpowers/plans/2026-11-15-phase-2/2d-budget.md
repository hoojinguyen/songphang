# Phase 2 — Stage 2D: Budget

> Part of the phase 2 plan. Read `00-overview.md` first.

**Stage goal:** the owner sets a limit for the month or for the whole trip, and the group is warned when spending nears or passes it.

**Spec:** section 8, 9.7 (budget lines), 9.8, 10.

## Decisions for this stage

1. The warning threshold is the constant 80 in `core`; it is not stored and not configurable.
2. `spent` may be negative (refunds); the state is then `ok`.
3. Editing a transaction recomputes warnings with the edited transaction's old amount excluded.

---

### Task 2D.1: `core` and API — budget

**Files:**
- Create: `packages/core/src/budget.ts`, `packages/db/src/schema-budgets.ts`, `packages/db/src/budgets.ts`, `packages/contract/src/budget.ts`, `apps/api/src/services/budget.ts`, `apps/api/src/routes/budget.ts`, a migration
- Modify: `packages/core/src/dates.ts`, `packages/core/src/index.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/app.ts`

**Interfaces — produces:**
- `BUDGET_NEAR_PERCENT = 80`; `budgetState(spent: number, amount: number): "ok" | "near" | "over"` — `over` when `spent > amount`; `near` when `BigInt(spent) * 100n >= BigInt(amount) * 80n`; else `ok`. `RangeError` unless both are safe integers and `amount > 0`.
- `currentMonthRange(now: Date): { start: string; end: string }` in `dates.ts`: the first and last Vietnam calendar dates of the month containing `now`.
- Table `budgets` as spec section 8.
- `GET /groups/{groupId}/budget` (viewer) → `{ budget: null }` or `{ budget: { period, amount, spent, state, periodStart, periodEnd } }`; for `total`, `periodStart` and `periodEnd` are null. `spent` uses `sumByBucket`'s rule (2B.3) over the period, through one query `sumSpent(db, groupId, range)`.
- `PUT /groups/{groupId}/budget` (owner; `{ period, amount: MoneyAmount }`), `DELETE` (owner; 204). Both write the activity log (entity `group`) and emit `changed: ["budget"]`. Any transaction change also emits `budget`.
- Transactions: preview, create and edit add `BUDGET_OVER` when the state after the transaction is `over` and before was not; `BUDGET_NEAR` when after is `near` and before was `ok`. Only for transactions dated inside the current period.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

`budgetState`:

| spent | amount | Expected |
|---|---|---|
| 799999 | 1000000 | `ok` |
| 800000 | 1000000 | `near` |
| 1000000 | 1000000 | `near` |
| 1000001 | 1000000 | `over` |
| 0 | 1 | `ok` |
| 1 | 1 | `near` |
| −5000 | 1000000 | `ok` |
| 799999999999 | 999999999999 | `ok` |
| 800000000000 | 999999999999 | `near` |
| 1 | 0 | `RangeError` |

API, fresh group, `deps.now()` inside December 2026 (set the development clock variable if phase 1 provides one; otherwise date the transactions in the current real month and record the dates used):

| # | Request | Expected |
|---|---|---|
| 1 | Lan (editor): PUT `month`, 1000000 | 403 |
| 2 | Minh: PUT `month`, 1000000 | 200; `spent` 0; `ok` |
| 3 | preview expense 799999 dated this month | `warnings: []` |
| 4 | create it | `warnings: []`; budget `ok` |
| 5 | create expense 1 | `warnings: ["BUDGET_NEAR"]`; `spent` 800000; `near` |
| 6 | create expense 200001 | `warnings: ["BUDGET_OVER"]`; `over` |
| 7 | create income 300000 | `spent` 700001; `ok` |
| 8 | create a transfer 900000 | `spent` unchanged |
| 9 | create expense 500000 dated last month | `spent` unchanged; `warnings: []` |
| 10 | PUT `total`, 1000000 | `spent` 1200001; `over`; `periodStart` null |
| 11 | PUT amount 0 | 400 |
| 12 | DELETE; GET | 204; `{ budget: null }` |
| 13 | outsider GET | 404 |

- [ ] **Step 4: Commit** — `feat(api): add group budget and spending warnings`

---

### Task 2D.2: Web — budget

**Files:**
- Create: `apps/web/src/components/settings/BudgetCard.tsx`, `apps/web/src/components/feed/BudgetBanner.tsx`, `apps/web/src/lib/budget.ts`
- Modify: the settings page, the group screen, the confirmation card, the statistics page (a budget line under the total when one exists), `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`

Strings: spec section 9.7 (budget lines) and 9.8.

Behavior: the banner sits above the stream, `sunken` background for `near`, the coral token for `over`, 44 points tall, tappable to S16; `{over}` is `spent − amount` by integer subtraction for display. The card's amount field uses the existing money input. The confirmation card shows the 9.8 line when the preview returns `BUDGET_OVER`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — rows 2–6 of 2D.1 through the screens; remove the budget → the banner disappears in a second window without reload.
- [ ] **Step 4: Commit** — `feat(web): add budget settings and warnings`

**Manual checks for the project owner**
1. S11 → `Hạn mức` → `Theo tháng`, 1.000.000 → add expenses up to 800.000 → the banner appears; pass 1.000.000 → it changes to the "vượt" wording.
2. As an editor, S11 is not reachable; `curl` PUT answers 403.

---

### Task 2D.3: README, non-functional checks, final gate

**Files:**
- Modify: `README.md` (new screens, the bank list's origin, the manual VietQR check)

- [ ] **Step 1: README.**
- [ ] **Step 2: Non-functional checks.** With the 500-transaction seed of phase 1's final task: S16 opens in under 2 seconds on a throttled "Fast 4G" profile; the export of that group downloads in under 2 seconds; keyboard-only walk through S14, S16, S17 and the filter sheet; contrast of the budget banner's two states meets WCAG AA (compute from the tokens and record the ratios).
- [ ] **Step 3: Stage gate 2D** — acceptance script: 2D.1 `budgetState` rows 1–4 and API rows 2–7. Then the full gate of the common file, replaying 2A, 2B, 2C and every earlier phase.
- [ ] **Step 4: Finish the run files.** `manual-checks.md` organised by screen (S5, S10, S11, S14, S16, S17, S4 filters), with a first section "With real money" holding the VietQR scan. `progress.md` ends with "Not verified" and "Gate not passed" (or "none").
- [ ] **Step 5: Commit** — `docs(repo): document phase 2`
