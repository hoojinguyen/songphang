# Wave 5.5C — Manual Extras, Recurring Expenses, Household Debt Grouping & iOS System Extensions — Design

Date: 2026-11-26. Status: approved by the project owner on 2026-11-26. Read `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md`, `docs/superpowers/specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md`, and `docs/superpowers/specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md` first.

## 1. Intent

Waves 5.5A and 5.5B delivered UI/UX v2 (Light/Dark semantic tokens, bundled `Be Vietnam Pro` `.ttf` on iOS, 4-tab app shell, 3-segment Group Detail, Full-Width Feed Cards, Web Desktop 2–3 column workspace, Cross-Group Overview, Personal Ledger, Group Archive/Clone) and reconciliation/sharing depth (optional transfer proofs, Settlement Vault, cumulative Settlement Cycles, Guest Read-only Links, and 1-tap Share Cards).

Five real-world product depth and iOS ecosystem gaps remain to complete **Phase 5.5** before the Server Step and public v1 release:

1. **Awkward VAT / shipping / discount entry on manual bills:** When entering a restaurant receipt (e.g., `Tiền hàng 346.000 đ` + `Thuế GTGT 8% = 27.680 đ` -> `Tổng 373.680 đ`) or food-delivery order by hand into a single transaction without AI scanning, `S8` currently forces a single top-level total and buries fixed-VND `extras` inside `Theo món` with no percentage presets (`8%`, `10%`, `5%`), no `shipping` kind, and no support for `equal`, `exact`, `shares`, or `percent` splits.
2. **Repetitive manual entry for recurring bills:** Shared households, subscription groups, and weekly sports clubs repeatedly enter the same fixed bills (e.g., monthly fiber internet) or forget variable bills (e.g., monthly electricity or weekly court rental where payer and split stay constant while the VND amount changes each period).
3. **Fragmented couple / family settlements:** When couples or family members join a group trip or club together, they need separate member rows during daily expense entry (different attendance, dishes, or cash outlays) while settling as **one consolidated household unit** through a single representative member and VietQR account at settlement time.
4. **Friction importing photos from Zalo, Photos, or banking apps on iOS:** Users viewing a receipt photo or bank transfer screenshot in Zalo or Photos currently must save the image, switch apps, navigate to the group, and re-pick the file instead of sending it straight into Sòng Phẳng from the iOS Share Sheet.
5. **No Home Screen glanceability or 1-tap entry shortcuts on iOS:** Checking net cross-group balances or jumping directly into Quick Entry, `S8`, or `Thanh toán` for the active group requires cold-navigating from the app root instead of tapping a Home Screen Widget or App Icon Quick Action.

**Goals:**
- Add **Manual-form `extras`** (`tax`, `service`, `shipping`, `discount`, `other`, supporting both percentage rates and exact integer VND amounts) directly on `S8` across **all five expense split methods** (`equal`, `exact`, `shares`, `percent`, `items`), defaulting extras allocation to **`"equal"` (`Chia đều`)** per owner decision with a 1-tap toggle to **`"proportional"` (`Theo tỷ lệ`)**, computed exclusively in `packages/core` and previewed via `/api/v1`.
- Add **Recurring Expenses (`recurring_expenses`)** supporting both **fixed auto-posting** (`fixed`) and **variable-amount due reminders** (`variable`) across `weekly`, `monthly`, `quarterly`, and `yearly` schedules (`Asia/Ho_Chi_Minh` via `pg-boss`), managed in `Quỹ & Thống kê` with an inline creation toggle in `S8` and actionable due prompts on `Tổng quan`.
- Add **Household / Couple Debt Grouping (`households`)** managed in `Thành viên (S10)`, keeping individual member participation on transactions while consolidating net balances and routing suggested transfers, VietQR payloads, debt breakdowns, `/share/{token}`, and share cards through each household's designated `representative_member_id` in `packages/core` with zero synthetic ledger transactions.
- Add **iOS Share Extension (`SongPhangShareExtension`)** backed by App Group (`group.vn.songphang.app`) and Shared Keychain, accepting 1–3 images from Zalo, Photos, or banking apps (`ImageIO` downsampling `<= 5 MiB`) for either **new expense / receipt scan** or **transfer proof (`transfer_proof`)** with direct app handoff and automatic foreground inbox recovery.
- Add **iOS Home Screen Widgets (`SongPhangWidgetExtension` — `.systemSmall` & `.systemMedium`)** and **Home Screen Quick Actions (`UIApplicationShortcutItem`)**, backed by an App Group snapshot store with Light/Dark Design System v2 parity and an optional `"Ẩn số tiền trên Widget"` privacy setting in `Tài khoản`.

**Non-goals:**
- Multi-currency conversion or non-VND extras/recurring templates.
- Retroactively changing historical Phase 3 `items` transactions (omitted `extrasAllocation` on `method === "items"` continues to evaluate as `"proportional"` so existing ledger hashes/shares remain 100% unchanged).
- Merging historical `members` rows or creating synthetic internal `transfer` rows between household members.
- Background network polling inside `SongPhangWidgetExtension` (widgets read fast, battery-free local snapshots written by the app/share extension and wipe immediately on sign-out).
- Introducing any new third-party npm or SwiftPM runtime dependency.

**Anti-goals:**
- Performing percentage multiplication, largest-remainder rounding, household debt netting, or next-schedule date arithmetic on Web or iOS clients instead of `packages/core` / `apps/api`.
- Breaking additive-only `/api/v1` OpenAPI compatibility (`pnpm contract:check` must report `0` breaking changes) or breaking `pnpm db:check-balances` (`sum(balances) === 0`).
- Storing session bearer tokens in `UserDefaults` or App Group plain files (tokens live exclusively in Keychain).
- Using emoji anywhere in UI copy, widgets, share extension, notifications, or source code (`AGENTS.md` §11).

## 2. Delivery Stages (`phase-5-5c`)

Run files live under `docs/superpowers/runs/phase-5-5c/` (`progress.md`, `decisions.md`, `manual-checks.md`).

| Stage | Scope | Branch Target |
|---|---|---|
| **5.5C.0** | Re-baseline `main` (`ba2bfb4`), verify Node/Postgres/Xcode gates and Wave 5.5A + 5.5B acceptance checks on a disposable database. | `phase-5-5c` |
| **5.5C.1** | `packages/core` pure integer math (manual `extras` %/VND + `"equal"` water-filling & `"proportional"` allocation across all 5 split methods; `households` balance consolidation & pairwise/minimized transfer routing; Vietnam calendar recurring schedule advancement), additive Drizzle migration (`0033_wave_5_5c_recurring_and_households.sql`), API endpoints & `pg-boss` `process-recurring-expenses` job in `apps/api` + `apps/worker`, and regenerated `packages/contract/openapi.json`. | `phase-5-5c` |
| **5.5C.2** | Web implementation (`apps/web`): `S8` manual-form quick chips & `Phụ phí & Giảm giá` card (`Tiền hàng` + `Tổng thanh toán`, `Chia đều` \| `Theo tỷ lệ`) + `S20` & `/share/[token]` extras breakdown display; `S8` recurring toggle + `Quỹ & Thống kê` `Giao dịch định kỳ` CRUD/pause/skip/complete UI + `Tổng quan` due recurring prompt; `S10` `Hộ gia đình / Cặp đôi` management + `Thanh toán`, `/share/[token]`, `ShareCard`, and `MemberBreakdownSheet` household display. | `phase-5-5c` |
| **5.5C.3** | iOS (`apps/ios`) parity + System Extensions: `Domain` / `Repositories` / `PreviewSupport` mappings for 5.5C contracts; `S8` extras, recurring management & due prompts, and `S10` / `Thanh toán` / `GuestGroupView` / `ShareCard` household parity; App Group + Shared Keychain migration (`ExtensionSharedStore` + `TokenStore`), `songphang://` action routing in `LinkRouter`, `UIApplicationShortcutItem` Quick Actions, `SongPhangShareExtension` target, and `SongPhangWidgetExtension` target (`.systemSmall`, `.systemMedium`, `"Ẩn số tiền trên Widget"` toggle). | `phase-5-5c` |
| **5.5C.4** | Standing docs & ADRs (`ADR-039`, `ADR-040`, `ADR-041`), `check-strings.sh` 100% parity check, `pnpm check`, `pnpm build`, `swift-format lint --strict`, Simulator Debug + unsigned Release `xcodebuild` (covering app + both embedded app extensions), `pnpm db:check-balances`, permission matrix & Wave 5.5C acceptance exercises, and owner manual-check handoff. | `phase-5-5c` |

Note for `/swarm` execution: **5.5C.1** locks `packages/core`, `packages/db`, `apps/api`, `apps/worker`, and `packages/contract/openapi.json` first. **5.5C.2 (Web)** and **5.5C.3 (iOS)** then operate on strictly disjoint trees (`apps/web/` vs `apps/ios/`) in parallel `share` worktrees, with `apps/web/src/messages/vi.ts` keys locked upfront and mirrored 1:1 in `Localizable.xcstrings`.

## 3. Core Domain Rules & Data Model

### 3.1 Manual-Form `extras` Across All Expense Split Methods (`packages/core` & `split_input`)

1. **Unified `SplitExtra` shape (`packages/contract/src/transaction.ts` & `packages/core/src/split-items.ts`):**
   - `kind`: `z.enum(["tax", "service", "shipping", "discount", "other"])` (adds `"shipping"` additively to the existing 4 values).
   - `label`: `z.string().trim().max(40)` (empty string falls back to localized kind label in UI).
   - `amount`: `NonnegativeMoneyAmount` (`0..999_999_999_999`, exact integer đồng).
   - `ratePercent`: `z.string().regex(/^\d{1,2}(\.\d{1,2})?$/).optional()` (optional input metadata `0.01`..`99.99`, e.g. `"8"`, `"10"`, `"5"`). When `ratePercent` is present on a saved `SplitInput`, `amount` MUST equal `computePercentExtraAmount(baseSubtotal, ratePercent)` so stored `split_input` is self-consistent and reopening `S8` to edit restores the percentage badge; if the user manually overrides the đồng figure on `S8` (e.g. a restaurant printed `27.681 đ` instead of `27.680 đ`), the client clears `ratePercent` and sends the exact integer `amount`.
2. **Additive `extras` & `extrasAllocation` on `SplitInput`:**
   - `ExtrasAllocation = z.enum(["equal", "proportional"])`.
   - `EqualSplitInput`, `ExactSplitInput`, `SharesSplitInput`, and `PercentSplitInput` each gain optional fields:
     - `extras?: z.array(ItemsSplitExtra).max(6)`
     - `extrasAllocation?: ExtrasAllocation`
   - `ItemsSplitInput` gains optional:
     - `extrasAllocation?: ExtrasAllocation`
   - **Backward-compatible defaults in `packages/core`:**
     - When `split.method === "items"` and `extrasAllocation` is omitted, `core` uses `"proportional"` (100% identical to Phase 3 `ADR-023`).
     - When `split.method !== "items"` and `extras` is non-empty, `extrasAllocation` defaults to `"equal"` (`Chia đều`, Owner Decision). In UI, `S8` initializes `extrasAllocation` to `"equal"` for all manual entries (including manual `Theo món`), while Receipt Scan Review initializes `extrasAllocation` to `"proportional"` with the same 1-tap `Chia đều` | `Theo tỷ lệ` switch.
   - **Income restriction:** `type === "income"` rejects non-empty `extras` (`400 VALIDATION_FAILED`), matching the existing `items` restriction. Transfers use `exact` with no `extras`.
3. **Exact Integer Allocation Rules (`packages/core`):**
   - **Percentage calculation (`computePercentExtraAmount`):** Parse `ratePercent` into integer hundredths `rateBps` (`1..9999` via `parseHundredths`). Compute integer đồng with half-up rounding using `BigInt` only:
     `Number((BigInt(baseSubtotal) * rateBps + 5000n) / 10000n)`.
   - **Subtotal & total relationship:**
     - Let `netExtras = sum(extra.kind === "discount" ? -extra.amount : extra.amount)`.
     - For `equal | exact | shares | percent`: when `extras` is empty/omitted, `baseSubtotal = amount` (unchanged). When `extras` has `>= 1` entry, `baseSubtotal = amount - netExtras`. If `!Number.isSafeInteger(baseSubtotal) || baseSubtotal <= 0`, `computeShares` returns `{ ok: false, code: "SPLIT_TOTAL_MISMATCH", expected: amount, actual: Math.max(0, netExtras) }`.
     - Compute `baseShares` across participating members (`ids` ordered by `memberIdsByPosition`) against `baseSubtotal` using the existing `equal`, `exact` (`none | equal_among_blank | equal_among_all`), `shares`, or `percent` logic. (Thus on the Three Koala receipt with `amount = 373_680` and `VAT 8% = +27_680`, `baseSubtotal = 346_000`, so `exact` entries `168_000 + 178_000` match `346_000` directly!)
     - For `items`: `baseSubtotal = sum(items.amount)`, `actual = baseSubtotal + netExtras` must equal `amount`, and `baseShares` are the per-member item subtotals.
   - **Allocating `netExtras` onto `baseShares`:**
     - `netExtras === 0`: return `baseShares`.
     - `netExtras > 0`:
       - `"equal"`: `parts = allocateByWeights(netExtras, ids.map(() => 1n))`; `final[i] = baseShares[i] + parts[i]`.
       - `"proportional"`: `weights = allZero ? ids.map(() => 1n) : baseShares.map(s => BigInt(s))`; `parts = allocateByWeights(netExtras, weights)`; `final[i] = baseShares[i] + parts[i]`.
     - `netExtras < 0` (`discountToAllocate = -netExtras`, guaranteed `< baseSubtotal` since `amount >= 1`):
       - `"proportional"`: `parts = allocateByWeights(discountToAllocate, baseShares.map(s => BigInt(s)))`; `final[i] = baseShares[i] - parts[i]` (since `discountToAllocate <= baseSubtotal - 1`, `parts[i] <= baseShares[i]` always holds).
       - `"equal"` (**Water-filling cap — Builder Call**): Start with `working = [...baseShares]` and `remainingDiscount = discountToAllocate`. While `remainingDiscount > 0`: identify indices `activeIdx` where `working[i] > 0`; compute `cuts = allocateByWeights(remainingDiscount, working.map(v => v > 0 ? 1n : 0n))`; if every `cuts[i] <= working[i]`, subtract `cuts[i]` and finish; otherwise, for every `i` where `cuts[i] >= working[i]`, deduct `working[i]` from `remainingDiscount` and set `working[i] = 0` (capping their share at `0 đ`), and for remaining indices deduct nothing yet and repeat the next pass over remaining positive-share members. Terminates in at most `ids.length` passes with `working[i] >= 0` and `sum(working) === amount` to the exact đồng.

### 3.2 Database Migration (`0033_wave_5_5c_recurring_and_households.sql`)

One additive Drizzle migration adding two tables (`households`, `recurring_expenses`) and two nullable columns (`members.household_id`, `transactions.recurring_expense_id`), exported from `packages/db/src/index.ts` and registered in `packages/db/drizzle.config.ts` (avoiding ESM cycles per 5.5B Decision D5):

#### 3.2.1 `households` (`packages/db/src/schema-households.ts`) & `members.household_id`

```sql
CREATE TABLE households (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 50),
  representative_member_id uuid NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX households_group_idx ON households (group_id, created_at ASC);
CREATE UNIQUE INDEX households_representative_unique ON households (representative_member_id);
```

On `members` (`packages/db/src/schema-groups.ts`):
- `household_id uuid NULL REFERENCES households(id) ON DELETE SET NULL`
- `CHECK (kind = 'person' OR household_id IS NULL)` (`members_household_person_check`)
- Index `members_group_household_idx` on `(group_id, household_id) WHERE household_id IS NOT NULL`.

**Household integrity rules (enforced under `lockGroup` in service layer + DB constraints):**
- A group may have at most `30` households (`422 LIMIT_REACHED` beyond 30).
- Every household contains `2..20` distinct `person` members belonging to `group_id`.
- Each `person` member belongs to at most one household (`members.household_id` single FK). If a member already belongs to another household in the request, return `409 HOUSEHOLD_MEMBER_CONFLICT` (or reassign only via editing the household). Let's refuse overlapping assignment with `409 HOUSEHOLD_MEMBER_CONFLICT` so the user doesn't accidentally break another household below 2 members!
- `representative_member_id` must be one of the household's assigned `memberIds` and must have `active = true` (`400 VALIDATION_FAILED` otherwise).
- In `PATCH /members/{memberId}`: attempting to set `active = false` on a member who is currently a `households.representative_member_id` returns `422 HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED` instructing the editor to pick another representative or ungroup the household first; non-representative household members may be marked `active = false` freely.
- Deleting a member (`DELETE /members/{memberId}`): if the member belongs to a household of size `2`, removing them would leave a 1-person household, so `DELETE /members/{memberId}` refuses while `member.household_id IS NOT NULL` (`422 HOUSEHOLD_MEMBER_CONFLICT` or auto-ungroup? Refusing with `409 HOUSEHOLD_MEMBER_CONFLICT` unless removed from household first matches `ON DELETE RESTRICT` on `representative_member_id` cleanly and explicitly!).

#### 3.2.2 `recurring_expenses` (`packages/db/src/schema-recurring.ts`) & `transactions.recurring_expense_id`

```sql
CREATE TABLE recurring_expenses (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  mode text NOT NULL CHECK (mode IN ('fixed', 'variable')),
  active boolean NOT NULL DEFAULT true,
  description text NOT NULL CHECK (char_length(description) BETWEEN 1 AND 200),
  amount bigint NULL CHECK (
    (mode = 'fixed' AND amount IS NOT NULL AND amount > 0)
    OR (mode = 'variable' AND (amount IS NULL OR amount > 0))
  ),
  category text NULL,
  category_id uuid NULL REFERENCES group_categories(id) ON DELETE SET NULL,
  payers_template jsonb NOT NULL,
  split_template jsonb NOT NULL,
  frequency text NOT NULL CHECK (frequency IN ('weekly', 'monthly', 'quarterly', 'yearly')),
  day_of_week integer NULL CHECK (day_of_week IS NULL OR day_of_week BETWEEN 1 AND 7),
  day_of_month integer NULL CHECK (day_of_month IS NULL OR day_of_month BETWEEN 1 AND 31),
  month_of_year integer NULL CHECK (month_of_year IS NULL OR month_of_year BETWEEN 1 AND 12),
  next_due_date date NOT NULL,
  pending_due_date date NULL,
  last_processed_due_date date NULL,
  last_posted_at timestamptz NULL,
  last_transaction_id uuid NULL REFERENCES transactions(id) ON DELETE SET NULL,
  pause_reason text NULL CHECK (pause_reason IS NULL OR pause_reason IN ('member_invalid', 'split_invalid')),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (category IS NULL OR category_id IS NULL),
  CHECK (
    (frequency = 'weekly' AND day_of_week IS NOT NULL AND day_of_month IS NULL AND month_of_year IS NULL)
    OR (frequency IN ('monthly', 'quarterly') AND day_of_month IS NOT NULL AND day_of_week IS NULL AND month_of_year IS NULL)
    OR (frequency = 'yearly' AND day_of_month IS NOT NULL AND month_of_year IS NOT NULL AND day_of_week IS NULL)
  ),
  CHECK (mode = 'variable' OR pending_due_date IS NULL)
);
CREATE INDEX recurring_expenses_group_idx ON recurring_expenses (group_id, created_at DESC);
CREATE INDEX recurring_expenses_due_idx ON recurring_expenses (next_due_date) WHERE active = true;
CREATE INDEX recurring_expenses_pending_idx ON recurring_expenses (group_id, pending_due_date) WHERE pending_due_date IS NOT NULL;
```

On `transactions` (`packages/db/src/schema-transactions.ts`):
- `recurring_expense_id uuid NULL REFERENCES recurring_expenses(id) ON DELETE SET NULL`
- Index `transactions_recurring_expense_idx` on `(recurring_expense_id) WHERE recurring_expense_id IS NOT NULL`.

**Template JSONB & Schedule Rules (`packages/core/src/recurring.ts`):**
- At most `50` recurring templates per group (`422 LIMIT_REACHED` beyond 50).
- All members (and any `fund`) referenced in `payers_template` or `split_template` on `POST` or `PATCH /recurring-expenses` (including resuming `active: true`) must belong to `group_id` and currently have `active = true` (`422 RECURRING_MEMBER_INACTIVE` if any referenced member/fund is inactive).
- **`mode === "fixed"`:**
  - `amount`: required positive integer (`MoneyAmount`).
  - `payers_template`: `Array<{ memberId: uuid, amount: MoneyAmount }>` summing to `amount` (validated through `calculateShares` at creation/update time so invalid splits cannot be saved).
  - `split_template`: any valid `SplitInput` (`equal`, `exact`, `shares`, `percent`, or `items`, including `extras`).
- **`mode === "variable"`:**
  - `amount`: nullable `MoneyAmount` (stores the most recently posted amount as an optional hint, or `null` when never posted).
  - `payers_template`: `[{ memberId: uuid }]` (1 payer member in the group — active person or active fund).
  - `split_template`: variable-compatible `RecurringVariableSplitInput`: `equal`, `shares`, or `percent` (with optional `ratePercent`-based or fixed-VND `extras` and `extrasAllocation`), because exact per-person VND shares are unknown until the bill arrives.
- **Member/Fund Deactivation & Group Unarchive Rules (Builder Call):**
  - When a group member is marked `active = false` (`PATCH /members/{memberId}`) or the shared fund is deactivated (`PATCH /fund`), any active `recurring_expenses` template in that group referencing that member/fund in `payers_template` or `split_template` is atomically set to `active = false, pause_reason = 'member_invalid', pending_due_date = NULL` (logging `recurring.paused` in `activity_log` and emitting SSE `["recurringExpenses", "activity"]`), preventing deactivated ex-roommates or club members from being auto-billed while never blocking `PATCH /members`.
  - Deleting a member (`DELETE /members/{memberId}`) who has `0` historical transactions also refuses with `422 MEMBER_HAS_TRANSACTIONS` (or `409 RECURRING_MEMBER_INACTIVE`) if any `recurring_expenses` row in the group still references `memberId` until that template is edited or deleted.
  - When unarchiving a group (`setGroupArchived` with `archived = false`), any `recurring_expenses` row with `active = true` and stale `next_due_date < todayVN` atomically advances `next_due_date` to the next upcoming occurrence `>= todayVN` (matching `PATCH` resume) so unarchiving an old group never fires unexpected catch-up bills on the next worker tick.
- **Vietnam Calendar Date Math (`packages/core/src/recurring.ts`, pure calendar math in `Asia/Ho_Chi_Minh`):**
  - `computeNextDueDate(schedule, afterDateVN)` computes the earliest valid Vietnam calendar date `YYYY-MM-DD` strictly `>` `afterDateVN` (when creating standalone in `Quỹ & Thống kê`, defaults `next_due_date` to the next upcoming schedule date `>= todayVN`; **Builder Call:** when creating inline from `S8` alongside saving today's expense, `next_due_date` is set strictly `> todayVN` so saving today's bill + toggling `"Lặp lại"` never double-posts a second bill on the same day).
  - Clamping rule for `monthly` / `quarterly` / `yearly`: `actualDay = Math.min(dayOfMonth, daysInMonth(year, month))` (e.g., `dayOfMonth = 31` fires on `2027-02-28`, `2027-04-30`, `2028-02-29`).
- **Scheduled Worker Execution (`apps/worker/src/jobs/process-recurring.ts`):**
  - Registered on `pg-boss` (`JOB_NAMES.processRecurring = "process-recurring"`), scheduled hourly at `"0 * * * *"` with `{ tz: "Asia/Ho_Chi_Minh" }` (running when Vietnam hour `>= 8`, plus callable directly in stage-gate exercise scripts).
  - Queries `recurring_expenses` joined with `groups` where `recurring_expenses.active = true AND groups.archived_at IS NULL AND recurring_expenses.next_due_date <= todayVN`.
  - Under `lockGroup(executor, groupId)`:
    - Re-reads row; skips if `!active`, group archived, or `next_due_date > todayVN` or `last_processed_due_date === next_due_date` (idempotent).
    - **No-flood catch-up rule (Builder Call):** Computes `advancedNextDueDate = computeNextDueDate(schedule, todayVN)` (strictly `> todayVN`). Even if a local dev container was stopped for months, a due template fires **once** for the current catch-up run rather than back-posting dozens of duplicate bills.
    - **If `mode === "fixed"`:**
      - Verifies all referenced members/funds are still in the group with `active = true` and validates `computeShares` in `core`. If invalid, sets `active = false, pause_reason = 'member_invalid'` (or `'split_invalid'`), logs `recurring.paused`, and skips cleanly without throwing a retry loop.
      - Inserts the `expense` transaction (`occurredAt = now`, `recurringExpenseId = row.id`, `createdBy = row.updatedBy ?? row.createdBy`, respecting group `approvalThreshold` identically to manual creation), updates `last_processed_due_date = dueDate, next_due_date = advancedNextDueDate, last_posted_at = now, last_transaction_id = tx.id, pause_reason = NULL`, logs `activity_log` (`action: "recurring_post", entityType: "transaction"`), emits SSE `["transactions", "balances", "activity", "recurringExpenses"]`, and inserts `notifications` (`kind: "recurring_posted"`) + push/mail jobs for group participants.
    - **If `mode === "variable"` (RBAC-aligned recipient routing — Builder Call):**
      - Verifies referenced members/funds still exist and have `active = true` (auto-pausing with `pause_reason = 'member_invalid'` if not).
      - Sets `pending_due_date = row.next_due_date, last_processed_due_date = row.next_due_date, next_due_date = advancedNextDueDate`.
      - Because creating an expense (`POST /transactions`) and skipping a period (`POST /recurring-expenses/{id}/skip`) require `editor+` ledger write permission, `"recurring_due"` notifications and `OverviewResponse.dueRecurringActions` target: the linked user of `payers_template[0].memberId` **if and only if** that user has role `owner` or `editor` in the group; otherwise (unlinked payer, `fund` payer, or `viewer`-role payer), falls back to `row.updated_by ?? row.created_by` (if still `editor+` in the group) and the group `owner`.
      - Inserts `notifications` (`kind: "recurring_due"`, payload `{ kind: "recurring_due", groupName, recurringExpenseId: row.id, description: row.description, dueDate: dueDate }`), enqueues push/mail, and emits SSE `["recurringExpenses"]`.

### 3.3 Household Debt Consolidation & Breakdown Math (`packages/core` & `apps/api`)

1. **`packages/core/src/settlements.ts` additions:**
   - `export type HouseholdGroup = { id: string; name: string; representativeMemberId: string; memberIds: readonly string[] };`
   - `consolidateHouseholdBalances(balancesByPosition: readonly MemberBalance[], households: readonly HouseholdGroup[])`:
     - Validates every household has `>= 2` unique known members, disjoint `memberIds` across households, and `representativeMemberId` inside `memberIds`.
     - Sums `BigInt(balance)` of all members in each household onto `representativeMemberId` and sets non-representative household members' consolidated balance to `0`. Total sum across the group remains strictly `0n`.
   - `suggestHouseholdSettlements({ balancesByPosition, minimizeDebts, pairDebts, households })`:
     - When `households.length === 0`: delegates 100% unchanged to `suggestMinimizedSettlements` or `netPairwiseDebts`.
     - When `households.length > 0`:
       - If `minimizeDebts === true`: runs `suggestMinimizedSettlements` on `consolidateHouseholdBalances(balancesByPosition, households)`.
       - If `minimizeDebts === false`: maps every `PairDebt` via `debtorMemberId -> representativeOf(debtorMemberId)` and `creditorMemberId -> representativeOf(creditorMemberId)` (intra-household pairs automatically collapse to `rep === rep` and are skipped by `accumulatePairDebts`), then runs `netPairwiseDebts` preserving `balancesByPosition` member ordering!
2. **Where `suggestGroupTransfers` applies household consolidation (`packages/db/src/reminders.ts`):**
   - `suggestGroupTransfers(executor, { groupId, minimizeDebts })` loads `listGroupHouseholds(executor, groupId)` alongside `listMemberBalances` and returns `{ balances, transfers, households }`!
   - Because `getBalances`, `getGuestGroupView`, `closeSettlementCycle` (snapshot!), and `runAutoReminders` ALL call `suggestGroupTransfers`, **every single settlement surface in Sòng Phẳng** (`Thanh toán`, `/share/{token}`, `Chốt đợt` snapshot, `Xuất ảnh / Nhắc nợ khéo`, and `auto-reminders`) automatically uses identical household-consolidated transfers with zero drift!
3. **Cross-Surface Balance & Settlement Consistency (`apps/api/src/services/{overview,groups,settlement-requests,reminders}.ts` — Builder Call):**
   - **Unified `myBalance` across all tabs & widgets:** In `getMeOverview` (`OverviewGroupBalance.myBalance`), `listGroups` (`GET /api/v1/groups` -> `GroupSummaryDto.myBalance`, which also feeds Tab 2 `Nhóm` and `recentGroup.myBalance` in `widget-snapshot.json`), Group Feed balance headers, and Web Desktop `GroupInspector`, whenever the caller's linked `memberId` belongs to a household `H` in that group, `myBalance` reports `H.netBalance` (while exposing `myIndividualBalance` and `householdName` as optional fields on `OverviewGroupBalance` and `GroupSummaryDto`). Once a household settles its external transfers to `0 đ`, every tab (`Tổng quan`, `Nhóm`, `Chi tiêu`, `Thanh toán`) and iOS Widget consistently shows `0 đ` (`Đã cân bằng`).
   - **Non-representative household partner settlement permissions:**
     - **Paying out (`fromHousehold`):** Any linked member belonging to `fromHousehold` (including a `linked viewer`, e.g., `Lan` when `Minh` is representative) sees the household's outgoing transfer in their own actionable `"Bạn cần chuyển"` list (`Thanh toán` & `GroupInspector`) and is authorized to submit or cancel a `settlement_request` (`POST /groups/{id}/settlement-requests` with `fromMemberId = representative_member_id`, including uploading a `transfer_proof` attachment from `Pay` or `SongPhangShareExtension`).
     - **Confirming incoming (`toHousehold`) & reminders:** Because incoming VietQR payments arrive in `representative_member_id`'s personal bank/wallet account, confirming/rejecting receipt (`POST /settlement-requests/{id}/confirm|reject` and `Overview` `settlement_confirmation` actions) remains strictly with `representative_member_id` (plus group `owner`, or `editor` when `representative_member_id` is unlinked, preserving `ADR-022`). Sending manual reminders (`POST /reminders`) stays `editor+` or the linked `representative_member_id`.

## 4. API & Contract Changes (Strictly Additive v1)

All schemas in `packages/contract/src/` pass `pnpm contract:check` (`0` breaking changes in `apps/api/src/openapi/diff.ts`):
- **Critical OpenAPI 3.1 union rule:** Do **not** alter the branch count of existing registered response `discriminatedUnion` components (`OverviewPendingAction` stays 2 branches; `NotificationPayload` stays 12 branches — `NotificationDto.kind` is already `z.string()` and `NotificationDto.payload` already unions `z.record(z.string(), z.unknown())`, so `"recurring_posted"` and `"recurring_due"` validate cleanly through a server-side `ExtendedNotificationPayload` schema without breaking `NotificationPayload.oneOf` in `openapi.json`!).

### 4.1 Manual Extras Preview & `SplitInput` Extensions (`packages/contract/src/transaction.ts`)

1. **`ItemsSplitExtra` & `SplitInput`:**
   - `ItemsSplitExtra.shape.kind`: `z.enum(["tax", "service", "shipping", "discount", "other"])` (additive enum value `"shipping"`).
   - `ItemsSplitExtra` adds `ratePercent: z.string().regex(/^\d{1,2}(\.\d{1,2})?$/).optional()`.
   - `EqualSplitInput`, `ExactSplitInput`, `SharesSplitInput`, `PercentSplitInput` add optional `extras: z.array(ItemsSplitExtra).max(6).optional()` and `extrasAllocation: z.enum(["equal", "proportional"]).optional()`.
   - `ItemsSplitInput` adds optional `extrasAllocation: z.enum(["equal", "proportional"]).optional()`.
   - `SplitTransactionRequest` adds optional `recurringExpenseId: z.uuid().optional()` (when completing a due `"variable"` recurring expense via `S8`, atomically clears `pending_due_date` and links `transactions.recurring_expense_id`) and optional `recurring?: CreateInlineRecurringInput` (when toggling `"Lặp lại định kỳ"` right inside `S8` on create!).
   - `BaseTransactionFields` (`TransactionDto` & `TransactionListItemDto`) adds optional `recurringExpenseId: z.uuid().nullable().optional()`.
2. **`POST /api/v1/groups/{groupId}/transactions/extras/preview`:**
   - **Access:** `requireUser`, `editor+`, verified email, write rate limit, same-origin (same guards as `POST .../transactions/preview`).
   - **Request (`PreviewExtrasRequest`):**
     ```ts
     {
       baseAmount: NonnegativeMoneyAmount, // e.g. 346000 (or ignored when split.method === "items")
       extras: Array<{
         kind: "tax" | "service" | "shipping" | "discount" | "other";
         label: string;
         amount?: NonnegativeMoneyAmount;
         ratePercent?: string; // e.g. "8", "10", "5"
       }>, // 0..6 items
       extrasAllocation?: "equal" | "proportional",
       payers?: Array<{ memberId: string; amount: number }>, // optional; if single payer omitted amount, server assumes computedAmount
       payerMemberId?: string, // convenience when 1 payer pays total computedAmount
       split?: SplitInput, // base split against baseAmount (with extras omitted or raw)
       transactionId?: string, // for edit budget/fund warning delta
     }
     ```
   - **Response (`PreviewExtrasResponse`):**
     ```ts
     {
       baseAmount: number; // integer VND subtotal
       resolvedExtras: ItemsSplitExtra[]; // every extra populated with exact integer amount
       netExtras: number; // signed integer VND
       computedAmount: number; // baseAmount + netExtras
       shares?: ShareDto[]; // present when split is structurally complete & computedAmount >= 1
       issues: Array<{ code: "INVALID_TOTAL" | "SPLIT_TOTAL_MISMATCH" | "ITEM_UNASSIGNED"; itemIndex?: number }>;
       warnings: TransactionWarning[];
     }
     ```

### 4.2 Recurring Expenses Endpoints (`packages/contract/src/recurring.ts`)

| Method & Path | Access & Guards | Behavior |
|---|---|---|
| `GET /api/v1/groups/{groupId}/recurring-expenses` | `requireUser`, `viewer+` | Returns `{ recurringExpenses: RecurringExpenseDto[] }` ordered by `pendingDueDate IS NOT NULL DESC, active DESC, nextDueDate ASC`. Allowed on archived groups. |
| `POST /api/v1/groups/{groupId}/recurring-expenses` | `requireUser`, `editor+`, verified email, write limit, same-origin, `Idempotency-Key`, not archived | Validates template (`fixed` or `variable`), enforces max 50 per group, computes `nextDueDate`, inserts row, logs `recurring.created`, emits SSE `["activity", "recurringExpenses"]`. Returns `201 { recurringExpense }`. |
| `PATCH /api/v1/groups/{groupId}/recurring-expenses/{recurringId}` | `requireUser`, `editor+`, verified email, write limit, same-origin, not archived | Updates schedule, `active` (pause/resume; resuming when `nextDueDate < todayVN` advances `nextDueDate` to upcoming `>= todayVN` so resuming never back-fires stale dates), description, category, amount, payers, or split; logs `recurring.updated`, emits SSE `["activity", "recurringExpenses"]`. Returns `200 { recurringExpense }`. |
| `DELETE /api/v1/groups/{groupId}/recurring-expenses/{recurringId}` | `requireUser`, `editor+`, verified email, write limit, same-origin | Allowed on active or archived groups. Deletes template (`transactions.recurring_expense_id` becomes `NULL` via `ON DELETE SET NULL`), logs `recurring.deleted`, emits SSE `["activity", "recurringExpenses"]`. Returns `204`. |
| `POST /api/v1/groups/{groupId}/recurring-expenses/{recurringId}/skip` | `requireUser`, `editor+`, verified email, write limit, same-origin, not archived | If `pending_due_date IS NOT NULL`, clears `pending_due_date = NULL` (skipping the current due prompt); if `pending_due_date IS NULL`, advances `next_due_date` by one period (`computeNextDueDate(schedule, next_due_date)`). Logs `recurring.skipped`, emits SSE `["activity", "recurringExpenses"]`. Returns `200 { recurringExpense }`. |

- **Completing a variable due occurrence:** Opening `"Nhập số tiền kỳ này"` opens `S8` pre-filled from `RecurringExpenseDto` with `recurringExpenseId = recurring.id`. Submitting `POST /groups/{groupId}/transactions` with `recurringExpenseId` (`editor+`) atomically creates the expense, clears `pending_due_date = NULL`, sets `amount = tx.amount` (as hint for next time), `last_posted_at = now`, `last_transaction_id = tx.id`, and emits SSE `["transactions", "balances", "activity", "recurringExpenses"]`.
- **`OverviewResponse` (`packages/contract/src/overview.ts`):**
  - Adds optional `dueRecurringCount: z.int().nonnegative().optional()` and `dueRecurringActions: z.array(OverviewRecurringDueAction).max(20).optional()` (`{ id, groupId, groupName, description, dueDate, suggestedAmount: number | null, payerMemberId, payerName }`) for active groups where the caller has role `editor+` and is either the linked payer or (when payer is unlinked/`fund`/`viewer`) the template creator or group `owner`.
- **Additive SSE resource (`packages/contract/src/jobs.ts`):** Add `"recurringExpenses"` and `"households"` to `GroupEventResource` (and relax `GroupEventNotification.resources` `.max(10)` -> `.max(14)` — relaxing `maxItems` is strictly `"additive"` in `diff.ts`!).

### 4.3 Households Endpoints & Settlement DTO Additions (`packages/contract/src/household.ts`, `balance.ts`, `member-breakdown.ts`, `guest-link.ts`)

| Method & Path | Access & Guards | Behavior |
|---|---|---|
| `GET /api/v1/groups/{groupId}/households` | `requireUser`, `viewer+` | Returns `{ households: HouseholdDto[] }`. Allowed on archived groups. |
| `POST /api/v1/groups/{groupId}/households` | `requireUser`, `editor+`, verified email, write limit, same-origin, `Idempotency-Key`, not archived | Body `{ name, memberIds: uuid[2..20], representativeMemberId: uuid }`. Locks group, verifies all `memberIds` are `person` members in `groupId` with `household_id IS NULL` (else `409 HOUSEHOLD_MEMBER_CONFLICT`), verifies `representativeMemberId` is in `memberIds` and `active = true`, inserts `households` and sets `members.household_id`, logs `household.created`, emits SSE `["members", "balances", "households", "activity"]`. Returns `201 { household }`. |
| `PATCH /api/v1/groups/{groupId}/households/{householdId}` | `requireUser`, `editor+`, verified email, write limit, same-origin, not archived | Updates `name`, `memberIds` (`2..20`), and/or `representativeMemberId` (`active = true`), clearing removed members' `household_id` and assigning added members (refusing members already in another household with `409 HOUSEHOLD_MEMBER_CONFLICT`). Logs `household.updated`, emits SSE `["members", "balances", "households", "activity"]`. Returns `200 { household }`. |
| `DELETE /api/v1/groups/{groupId}/households/{householdId}` | `requireUser`, `editor+`, verified email, write limit, same-origin, not archived | Deletes household (`ON DELETE SET NULL` clears `members.household_id`), logs `household.deleted`, emits SSE `["members", "balances", "households", "activity"]`. Returns `204`. |

- **Additive Error Codes (`packages/contract/src/error.ts`):**
  - `"HOUSEHOLD_MEMBER_CONFLICT"` (`409` — member already belongs to another household, or attempting to delete a member currently inside a household before removing/ungrouping).
  - `"HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED"` (`422` — attempting to deactivate a household's representative member).
  - `"RECURRING_MEMBER_INACTIVE"` (`422` — attempting to create/update/resume a recurring template referencing an inactive member or inactive fund).
- **Additive DTO fields:**
  - `MemberDto` & `GuestMemberDto`: `householdId: z.uuid().nullable().optional()`.
  - `GroupSummaryDto` (`GET /api/v1/groups`) & `OverviewGroupBalance` (`GET /api/v1/me/overview`): `myBalance` reflects household consolidated `netBalance` when the caller belongs to a household, plus optional `myIndividualBalance: z.int().optional()` and `householdName: z.string().nullable().optional()`.
  - `BalancesResponse` & `GuestGroupViewResponse`:
    - `households: z.array(HouseholdBalanceDto).optional()` (`{ id, name, representativeMemberId, memberIds, netBalance, memberBalances: Array<{ memberId, balance }> }`).
    - `transfers[number]` adds optional `fromHousehold: HouseholdTransferRefDto.nullable().optional()` and `toHousehold: HouseholdTransferRefDto.nullable().optional()` (`{ id, name, memberIds }`).
  - `MemberBreakdownsResponse` (`GET /balances/breakdowns` & `GuestGroupViewResponse`):
    - Adds optional `householdBreakdowns: z.array(HouseholdDebtBreakdownDto).optional()` (`{ householdId, name, representativeMemberId, memberIds, carryOverBalance, focusExpenseDelta, focusTransferDelta, postCycleDelta, netBalance }`, matching `sum(memberBreakdowns)` for the household's members to the exact đồng).
  - `CloneGroupRequest` (`packages/contract/src/group.ts`): when `includeMembers === true` (existing default), `cloneGroup` automatically copies `households` and re-maps `representative_member_id` + `members.household_id` to the newly cloned member UUIDs.

## 5. UI/UX Design (100% Web & iOS Feature Parity)

### 5.1 `S8` Expense Form — Manual Extras & Inline Recurring

1. **Quick Extras Chips & `Phụ phí & Giảm giá` Card (Expense mode only):**
   - Directly beneath `AmountField`, render horizontal capsule chips: `VAT 8%`, `+ VAT 10%`, `+ Phí DV 5%`, `+ Phí ship`, `- Giảm giá`, `+ Khác`.
   - **Zero-clutter default:** When `extras.length === 0`, `AmountField` label stays `Số tiền` and no extra card is rendered.
   - **Active Extras Card (`extras.length >= 1`):**
     - `AmountField` label switches to **`Tiền hàng`** (when `method !== "items"`).
     - Header of the card shows **`Phụ phí & Giảm giá`** on the left and a compact 2-pill segmented control **`Chia đều`** (default) | **`Theo tỷ lệ`** on the right.
     - Each extra row (`1..6`) shows:
       - Kind selector/badge (`Thuế VAT`, `Phí dịch vụ`, `Phí giao hàng`, `Giảm giá`, `Phụ phí khác`), optional custom label, `%` | `đ` mode pill (for `tax`, `service`, `discount`), numeric input, server-resolved signed đồng preview (`+27.680 đ` or `-40.000 đ` in `credit`), and remove (`X`) button.
       - Tapping `VAT 8%` (or `VAT 10%` / `Phí DV 5%`) toggles that preset in 1 tap; typing a manual đồng value switches that row to exact `đ` mode.
     - Highlighted bottom bar inside the card (`phraseAmount` token): **`Tổng thanh toán: {computedAmount}`** (`tabular-nums`, `monospacedDigit()`), read directly from `POST .../transactions/extras/preview` (`300 ms` debounce with request cancellation, matching `apps/ios/AGENTS.md` §6).
     - Single-payer amounts and `SplitStatus` automatically track `computedAmount` for payers while `SplitEditor` (`Chia đều`, `Theo số tiền`, `Theo phần`, `Theo %`) displays `Tiền hàng: {baseAmount}` for base entry alongside each member's authoritative final share (including extras) from server preview!
2. **Transaction Detail (`S20`) & Guest Expense Detail (`/share/{token}`):**
   - Whenever `transaction.split` has non-empty `extras` (for *any* `split.method`), `TransactionSummary` / `TransactionSummaryView` renders a crisp breakdown block: `Tiền hàng: {baseAmount}`, each extra line (`Thuế VAT (8%): +27.680 đ`, `Giảm giá: -40.000 đ`), allocation label (`Phụ phí chia đều` / `Phụ phí theo tỷ lệ`), and `Tổng thanh toán: {amount}`.
3. **Inline Recurring Toggle on `S8` (Create Expense only, hidden when editing or completing a due prompt):**
   - Compact expandable card below `Thời gian`: switch **`Lặp lại định kỳ`** (default OFF).
   - When toggled ON: shows Mode (`Tự động ghi sổ (số tiền cố định)` | `Nhắc nhập số tiền mỗi kỳ`) and Frequency (`Hằng tuần` | `Hằng tháng` | `Hằng quý` | `Hằng năm`, defaulting to `Hằng tháng` on the day of `occurredAt`). Saving the expense creates both today's transaction and the `recurring_expenses` template (with `next_due_date` set to the next period strictly after today).

### 5.2 `Quỹ & Thống kê` & `Tổng quan` — Recurring Expenses Management

1. **Segment 3 (`Quỹ & Thống kê`):**
   - Dedicated **`Giao dịch định kỳ`** card/section (visible to `viewer+`; create/edit/pause/skip/delete controls shown to `editor+` when group is active; delete allowed when archived).
   - **Due variable banner at top of section:** Any item with `pendingDueDate !== null` highlights in `warningSoft` with **`Cần nhập số tiền kỳ {date}`** + primary CTA **`Nhập số tiền`** (opens `S8` pre-filled with `recurringExpenseId`) + secondary **`Bỏ qua kỳ này`**.
   - Each template row shows: Description, Mode badge (`Tự động ghi` in `creditSoft`/`credit` or `Nhắc nhập tiền` in `warningSoft`/`warning`, or `Đang tạm dừng` in `sunken`/`muted`), Schedule summary (`Ngày 05 hằng tháng · Kỳ tới 05/12/2026`), Payer + Split label, fixed/hint amount (`tabular-nums`), and overflow/detail sheet (`Sửa mẫu`, `Tạm dừng` / `Bật lại`, `Bỏ qua kỳ tới`, `Xoá mẫu`).
   - **`+ Tạo chi tiêu định kỳ`** button opens a clean creation sheet/modal (`Loại định kỳ`, `Tên khoản chi`, `Chu kỳ lặp`, `Người trả`, `Cách chia`, and `Số tiền` when `fixed`).
2. **Tab 1 (`Tổng quan` — `Cần bạn xử lý`):**
   - Renders `dueRecurringActions` right inside `PendingActionsList` (`"Đến kỳ nhập: {description} ({groupName})"`) — tapping navigates straight into that group's `S8` pre-filled with `recurringExpenseId`!

### 5.3 `Thành viên (S10)` & `Thanh toán` — Household / Couple Grouping

1. **`Thành viên (S10)` (`Members` screen on Web & iOS):**
   - New **`Hộ gia đình / Cặp đôi`** card right below the active members list:
     - Explains in 1 line: *"Gộp số dư khi thanh toán qua một người đại diện, vẫn giữ tên riêng khi chia từng bữa."*
     - Lists existing households (`Nhà Minh & Lan` · `Đại diện: Minh` · overlapping member shapes + `Sửa` / `Tách hộ` for `editor+`).
     - **`+ Tạo nhóm hộ / cặp đôi`** modal/sheet (`editor+`, when `>= 2` unassigned active `person` members exist):
       1. `Tên hộ / cặp đôi` (e.g., `"Nhà Minh & Lan"`).
       2. Multi-select `2+` `person` members not yet in another household.
       3. Radio/pill picker for **`Người đại diện thanh toán`** among the selected active members (highlights if a member already has VietQR/payment methods configured!).
   - On individual member rows in `S10`, members belonging to a household show a subtle capsule badge (`Nhà Minh & Lan` or `Đại diện · Nhà Minh & Lan`).
2. **`Thanh toán`, `/share/{token}`, `MemberBreakdownSheet` & `ShareCard`:**
   - **Personal Hero Card (`Thanh toán`):** If the current user belongs to a household `H`, displays `H.netBalance` (`Nhà Minh & Lan được nhận +350.000 đ` / `Nhà Minh & Lan đã xong`) with a clear secondary line: `"Phần riêng của bạn: -250.000 đ · Gộp thanh toán qua {repName}"`.
   - **Suggested Transfers (`Ai chuyển cho ai`):** When `fromHousehold` or `toHousehold` is present, displays `{FromName}` (with subtle subtitle `Đại diện {fromHousehold.name}`) -> `{ToName}` (`Đại diện {toHousehold.name}`): `{Amount}`.
   - **Group Balance Bars (`Cán cân của nhóm`):** Shows a compact **`Theo hộ / cặp đôi`** summary block above or grouped with individual bars so both the consolidated household balance (`+350.000 đ`) and individual member figures (`Minh +600.000 đ`, `Lan -250.000 đ`) are 100% transparent.
   - **Debt Breakdown Sheet & `/share/{token}` & `Nhắc nợ khéo` PNG Card:** When inspecting a transfer involving a household representative, displays the **`Tổng hợp hộ {name}: {netBalance}`** header breaking down each household member's sub-balance (`Minh: +600.000 đ`, `Lan: -250.000 đ`) followed by the itemized transactions of all members in that household!

## 6. iOS System Extensions & Target Architecture (`apps/ios/`)

### 6.1 Shared App Group, Keychain & `SongPhangKit` Reuse (`apps/ios/AGENTS.md` Compliance)

1. **Entitlements & Build Settings (`apps/ios/Config/{Debug,Release}.xcconfig` & `.entitlements`):**
   - `APP_GROUP_IDENTIFIER = group.vn.songphang.app`
   - `KEYCHAIN_ACCESS_GROUP = $(AppIdentifierPrefix)vn.songphang.app.shared`
   - Three targets in `apps/ios/SongPhang.xcodeproj`:
     1. `SongPhang` (`vn.songphang.app`) — embeds `SongPhangShareExtension.appex` and `SongPhangWidgetExtension.appex`.
     2. `SongPhangShareExtension` (`vn.songphang.app.ShareExtension`) — links `Domain`, `DesignSystem`, `Repositories` from local `SongPhangKit`.
     3. `SongPhangWidgetExtension` (`vn.songphang.app.WidgetExtension`) — links **only** `Domain` and `DesignSystem` from local `SongPhangKit` (never `GeneratedAPI`, `Repositories`, or feature modules, keeping widget binary minimal and fast).
   - All three targets enforce `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` and Swift 6 strict concurrency.
2. **Keychain Access Group Migration (`TokenStore.swift`):**
   - `TokenStore` accepts `accessGroup: String?` (resolved from `Info.plist` `KeychainAccessGroup` or fallback to default group if Simulator lacks code-signing entitlements in unitless builds). On first read, if the shared access-group item is absent and a legacy ungrouped `vn.songphang.app.session` item exists, `TokenStore` atomically writes it into the shared access group and deletes the legacy item so signed-in users upgrading from 5.5B stay signed in across app + Share Extension!
3. **App Group Snapshot & Share Inbox (`ExtensionSharedStore` in `Domain` / `Repositories`):**
   - Stored inside `containerURL(forSecurityApplicationGroupIdentifier: "group.vn.songphang.app")/SharedState/` with `.completeFileProtectionUntilFirstUserAuthentication` and `isExcludedFromBackup = true`:
     - `widget-snapshot.json`: `{ isSignedIn, appearanceMode, hideAmounts, totalOwedToMe, totalIOwe, netBalance, pendingActionCount, recentGroup: { id, name, myBalance }?, updatedAt }`.
     - `share-groups.json`: `{ isSignedIn, appearanceMode, recentGroupId, groups: Array<{ id, name, role, receiptReadingEnabled }> }` (only active, non-archived groups where `role` is `owner`/`editor` for expenses, plus `viewer` with linked member for `transfer_proof`!).
     - `ShareInbox/{batchId}/manifest.json` (+ temporary normalized `.jpg` files if offline/deferred): `{ batchId, createdAt, groupId, groupName, mode: "expense" | "transfer_proof", attachmentIds: [String], receiptScanId: String? }`. Stale inbox batches older than 24 hours are pruned automatically on app launch.
   - **Privacy toggle (`Tài khoản`):** `AccountView` adds switch **`Ẩn số tiền trên Widget`** persisted in App Group preferences; toggling immediately updates `widget-snapshot.json` and calls `WidgetCenter.shared.reloadAllTimelines()`.
   - **Sign-out / Account deletion:** `TokenStore.clear()` and `SnapshotStore.clearAll()` wipe `SharedState/`, clear `UIApplication.shared.shortcutItems`, and trigger `WidgetCenter.shared.reloadAllTimelines()`.

### 6.2 `SongPhangShareExtension` (`apps/ios/ShareExtension/`)

- **Activation rule (`Info.plist`):** `NSExtensionPointIdentifier = com.apple.share-services`, `NSExtensionActivationRule` accepting `NSExtensionActivationSupportsImageWithMaxCount = 3`.
- **Memory-safe image normalization:** Reads each `NSItemProvider` via `loadFileRepresentation(forTypeIdentifier: UTType.image.identifier)` and downsamples directly from file URL using `ImageIO` (`CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize = 2048`, JPEG quality step-down ensuring `<= 5_242_880` bytes) inside `autoreleasepool` — never decoding full 48MP `UIImage` bitmaps in memory.
- **Extension Sheet UI (SwiftUI + `DesignSystem` tokens + `Be Vietnam Pro`):**
  - If `!isSignedIn`: clean prompt `"Vui lòng mở Sòng Phẳng và đăng nhập trước khi chia sẻ hoá đơn."` + `"Đóng"`.
  - Shows 1–3 image thumbnails, **Group Picker** (defaulting to `recentGroupId`; filters groups by role: `editor+` for `Chi tiêu mới`, `linked viewer+` for `Chứng từ trả nợ`), and 2-card Purpose selector:
    1. **`Chi tiêu mới`** (`Quét hoá đơn / Mở Form S8`, default)
    2. **`Chứng từ trả nợ`** (`Đính kèm vào Thanh toán`, max 1 photo for `settlement-request` or up to 3 for `Settle`)
  - Primary CTA **`Tải lên & Tiếp tục`**:
    - Uploads image(s) directly via `LiveAttachmentsRepository` (`purpose = "expense"` or `"transfer_proof"`). If `mode == .expense`, `images.count == 1`, and `group.receiptReadingEnabled == true`, also calls `POST /receipt-scans` so OCR starts immediately.
    - Writes `ShareInbox/{batchId}/manifest.json` and opens `songphang://share-import/{batchId}` to jump straight into Sòng Phẳng's `ReceiptReviewView`, `ExpenseFormView` (pre-populated with uploaded `Attachment`s), or `BalancesView` (`Pay`/`Settle` sheet with proof pre-attached).
    - **Dual-delivery resilience (Builder Call):** Because some iOS host apps (including certain Zalo views) suppress `extensionContext?.open` from Share Extensions, if URL opening returns `false`, the sheet displays a crisp confirmation `"Đã tải ảnh lên nhóm {groupName} — mở Sòng Phẳng để hoàn tất"` + `"Xong"`, and `RootView` automatically inspects `ShareInbox/` whenever `scenePhase == .active` to surface/route the pending shared batch with zero lost uploads!

### 6.3 `SongPhangWidgetExtension` (`apps/ios/WidgetExtension/`) & Home Screen Quick Actions

1. **Widgets (`WidgetBundle` with `SongPhangOverviewWidget`):**
   - Supported families: `.systemSmall`, `.systemMedium`.
   - Reads `widget-snapshot.json` synchronously in `TimelineProvider` (`policy: .never` driven by deterministic `WidgetCenter.shared.reloadAllTimelines()` on every app overview/balance refresh, group visit, theme/privacy toggle, or sign-out, plus a 4-hour safety refresh).
   - **`.systemSmall`:** Header `SÒNG PHẲNG`, net cross-group balance (`+{amount}` in `credit`, `-{amount}` in `debt`, or `0 đ` `Đã cân bằng`; or `"Số dư đang ẩn"` when `hideAmounts == true`), pending actions count, and capsule CTA `+ Ghi chi tiêu` (`widgetURL` -> `songphang://group/{recentGroupId}/quick-entry` or `songphang://overview` if no recent group).
   - **`.systemMedium`:** Left column shows `Được nhận` / `Cần trả` totals + `Nhóm gần nhất: {name}`; right column provides three interactive `Link(destination:)` buttons:
     1. `Ghi nhanh` -> `songphang://group/{id}/quick-entry`
     2. `Nhập tay / Bill` -> `songphang://group/{id}/expense-new`
     3. `Thanh toán` -> `songphang://group/{id}/balances`
2. **Home Screen Quick Actions (`UIApplicationShortcutItem`):**
   - Updated whenever active groups / session state changes (`0` items when signed out):
     1. `vn.songphang.app.shortcut.quick-entry` — `"Ghi chi tiêu nhanh"` (subtitle: recent group name)
     2. `vn.songphang.app.shortcut.expense-new` — `"Nhập tay / Quét hoá đơn"` (subtitle: recent group name)
     3. `vn.songphang.app.shortcut.balances` — `"Xem cần thanh toán"`
   - Routed through `LinkRouter.appActionRoute(for: URL)` — one centralized, strict validator in `LinkRouter.swift` (`apps/ios/AGENTS.md` §7).

## 7. Vietnamese UI Strings (100% Web & iOS Parity)

All shared user-visible strings are added character-for-character to `apps/web/src/messages/vi.ts` and `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, verified by `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`). Zero emoji. (iOS-only system extension plist/widget gallery descriptions live in extension `InfoPlist.strings` / widget configuration constants with zero emoji, while shared labels live in the common catalog.)

| Key Group | Exact Vietnamese Strings |
|---|---|
| Manual `extras` (`S8` & `S20`) | `Tiền hàng`, `Tổng thanh toán`, `Phụ phí & Giảm giá`, `VAT 8%`, `VAT 10%`, `Phí DV 5%`, `Phí giao hàng`, `Giảm giá`, `Phụ phí khác`, `Chia đều`, `Theo tỷ lệ`, `Phụ phí chia đều`, `Phụ phí theo tỷ lệ`, `Theo %`, `Theo số tiền` |
| Recurring Expenses (`S8`, `Quỹ & Thống kê`, `Tổng quan`) | `Giao dịch định kỳ`, `Lặp lại định kỳ`, `Tạo chi tiêu định kỳ`, `Sửa chi tiêu định kỳ`, `Tự động ghi sổ`, `Nhắc nhập số tiền`, `Hằng tuần`, `Hằng tháng`, `Hằng quý`, `Hằng năm`, `Kỳ tiếp theo: {date}`, `Cần nhập số tiền kỳ {date}`, `Nhập số tiền kỳ này`, `Bỏ qua kỳ này`, `Bỏ qua kỳ tới`, `Tạm dừng`, `Đang tạm dừng`, `Bật lại`, `Xoá mẫu định kỳ`, `Chưa có chi tiêu định kỳ nào`, `Đến kỳ nhập: {description}` |
| Households (`S10` & `Thanh toán`) | `Hộ gia đình / Cặp đôi`, `Gộp số dư khi thanh toán qua một người đại diện, vẫn giữ tên riêng khi chia từng bữa.`, `Tạo nhóm hộ / cặp đôi`, `Sửa nhóm hộ / cặp đôi`, `Tên hộ / cặp đôi`, `VD: Nhà Minh & Lan`, `Người đại diện thanh toán`, `Đại diện {name}`, `Tách nhóm hộ`, `Phần riêng của bạn: {amount}`, `Gộp thanh toán qua {name}`, `Tổng hợp hộ {name}`, `Theo hộ / cặp đôi` |
| iOS Extensions & Privacy | `Ẩn số tiền trên Widget`, `Ẩn số dư ròng trên màn hình chính iPhone.`, `Số dư đang ẩn`, `Chạm để mở Sòng Phẳng`, `Đưa vào Sòng Phẳng`, `Chọn nhóm nhận ảnh`, `Chi tiêu mới`, `Chứng từ trả nợ`, `Tải lên & Tiếp tục`, `Đã tải ảnh lên nhóm {name}`, `Ghi chi tiêu nhanh`, `Nhập tay / Quét hoá đơn`, `Xem cần thanh toán` |

## 8. Security & Authorization Matrix

| Action / Endpoint / Boundary | Unauthenticated | Outsider | Viewer (unlinked) | Viewer (linked) | Editor | Owner | Key Security Rules |
|---|---|---|---|---|---|---|---|
| `POST /groups/{id}/transactions/extras/preview` | `401` | `404` | `403` | `403` | `200` | `200` | Verified email, write rate limit, same-origin, `BigInt` math in `packages/core` only |
| `GET /groups/{id}/recurring-expenses` | `401` | `404` | `200` | `200` | `200` | `200` | Scoped strictly to `groupId`; outsiders receive `404` |
| `POST / PATCH / DELETE /groups/{id}/recurring-expenses*` | `401` | `404` | `403` | `403` | `200/201/204` | `200/201/204` | Verified email, `Idempotency-Key` on `POST`, write limit, same-origin, `POST`/`PATCH` blocked when archived, active members/fund only, max 50/group |
| `POST /groups/{id}/recurring-expenses/{rid}/skip` | `401` | `404` | `403` | `403` | `200` | `200` | Verified email, write limit, same-origin, not archived (`editor+` consistent with `POST /transactions`) |
| `POST /groups/{id}/settlement-requests` (household debtor) | `401` | `404` | `403` | `201` (own `fromMemberId`, or household's `representative_member_id` when caller belongs to `fromHousehold`) | `201` | `201` | Confirm/reject incoming transfer remains strictly `representative_member_id` / `owner` (or `editor` if unlinked) per `ADR-022` |
| `GET /groups/{id}/households` | `401` | `404` | `200` | `200` | `200` | `200` | Scoped strictly to `groupId`; outsiders receive `404` |
| `POST / PATCH / DELETE /groups/{id}/households*` | `401` | `404` | `403` | `403` | `200/201/204` | `200/201/204` | Verified email, `Idempotency-Key` on `POST`, write limit, same-origin, not archived, same-group `person` members only, active representative |
| `SongPhangShareExtension` | Blocked cleanly | `404` | Blocked | `transfer_proof` only | `expense` + `transfer_proof` | `expense` + `transfer_proof` | Token read from Shared Keychain only; `ImageIO` downsampling `<= 5 MiB`; magic-byte & quota enforced on API |
| `SongPhangWidgetExtension` & `songphang://` URLs | Signed-out placeholder | N/A | Read-only | Read-only | Read-only | Read-only | No token accessed by Widget; `completeFileProtectionUntilFirstUserAuthentication`; wiped on logout; strict UUID/path validation in `LinkRouter` |

## 9. Planned ADRs (`docs/04-adr.md`)

- **ADR-039: Generalized `split_input.extras` with Equal Water-Filling Default and Server Percentage Preview** — Extending `SplitInput` across all five split methods with optional `%`/`VND` extras (`tax`, `service`, `shipping`, `discount`, `other`), defaulting manual entries to equal allocation with non-negative water-filling discount caps while preserving proportional default on legacy `items` rows.
- **ADR-040: Recurring Expenses (`fixed` Auto-Post & `variable` Due Prompts) and Household Representative Consolidation** — Running Vietnam-calendar recurring schedules on `pg-boss` with single-catchup anti-flood protection, and consolidating household debts onto `representative_member_id` purely in `packages/core` (`suggestGroupTransfers`) without mutating historical individual ledger shares or creating synthetic internal transfers.
- **ADR-041: iOS App Group Snapshot Store, Shared Keychain Migration, and Dual-Delivery Share Extension Handoff** — Sharing authenticated session tokens exclusively via Keychain access groups while serving battery-free Home Screen Widgets and resilient Zalo/Photos Share Extension imports through protected App Group snapshots and `LinkRouter`-validated `songphang://` routes.
