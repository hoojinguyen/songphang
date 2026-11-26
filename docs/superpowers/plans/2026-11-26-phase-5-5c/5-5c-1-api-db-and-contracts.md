# Wave 5.5C — Task 0 and Stage 5.5C.1: Core Math, Database, Worker, Additive v1 API & Copy Lock

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md). API paths below are relative to `/api/v1`.

### Task 0: Re-baseline `main` on `phase-5-5c`

**Files:**
- Modify: `docs/superpowers/runs/phase-5-5c/{progress,decisions,manual-checks}.md`

**Interfaces:**
- Consumes: `main` (`ba2bfb4` or later), Wave 5.5A and Wave 5.5B merged baseline.
- Produces: Clean baseline verification and Re-baseline symbol/file mapping in `docs/superpowers/runs/phase-5-5c/decisions.md`.

- [ ] **Step 1: Verify branch and clean workspace**
  Confirm `git branch --show-current` prints `phase-5-5c` and `git status --short` is clean; record starting `main` SHA in `progress.md`.
- [ ] **Step 2: Run baseline build, lint, contract, string, and iOS checks**
  Run `pnpm check`, `pnpm contract:check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, and Simulator Debug `xcodebuild ... -skipPackagePluginValidation build`. Record observed outputs.
- [ ] **Step 3: Verify existing files and symbols referenced by this plan**
  Confirm every existing file path named across `5-5c-1`..`5-5c-4` exists on `phase-5-5c` and write the Re-baseline table in `decisions.md`.
- [ ] **Step 4: Replay disposable-DB baseline smoke check**
  Create disposable DB `songphang_phase55c_t0`, run migrations (`0000`..`0032`) + seed, verify auth, group archive/clone, `GET /me/overview`, settlement cycles, guest link, and `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` (`All groups balanced`), then drop `songphang_phase55c_t0`.
- [ ] **Step 5: Commit baseline run log**
  `git commit -m "docs(run): re-baseline wave 5.5c"`

---

### Task 5.5C.1.1: `@songphang/core` pure integer math (`extras`, `households`, `recurring`) & DB migration (`0033`)

**Files:**
- Create: `packages/core/src/recurring.ts`
- Create: `packages/db/src/{schema-households,schema-recurring,households,recurring-expenses}.ts`
- Create: `packages/db/drizzle/0033_wave_5_5c_recurring_and_households.sql` (via Drizzle + registered journal)
- Modify: `packages/core/src/{split,split-items,settlements,index}.ts`
- Modify: `packages/db/src/{schema-groups,schema-transactions,index}.ts`
- Modify: `packages/db/drizzle.config.ts`

**Interfaces:**
- Consumes: `allocateByWeights`, `parseHundredths`, `isValidCalendarDate` in `@songphang/core`; `groups`, `members`, `groupCategories`, `transactions`, `users` in `@songphang/db`.
- Produces:
  - `@songphang/core` (`split-items.ts` & `split.ts`):
    - `ItemExtraKind = "tax" | "service" | "shipping" | "discount" | "other"`
    - `ExtrasAllocation = "equal" | "proportional"`
    - `ItemExtraEntry = { kind: ItemExtraKind; label: string; amount: number; ratePercent?: string }`
    - `computePercentExtraAmount(baseSubtotal: number, ratePercent: string): number` -> half-up `BigInt` `(BigInt(baseSubtotal) * rateBps + 5000n) / 10000n` (`rateBps` in `1n..9999n`).
    - `allocateNetExtras(baseShares: readonly number[], netExtras: number, allocation: ExtrasAllocation): SplitResult | { ok: true; amounts: number[] }` implementing water-filling non-negative cap when `netExtras < 0 && allocation === "equal"`.
    - `SplitInput` branches (`equal`, `exact`, `shares`, `percent`) accept optional `extras?: readonly ItemExtraEntry[]` and `extrasAllocation?: ExtrasAllocation` (default `"equal"` when omitted on non-`items`; `ItemsSplitInput` accepts `extrasAllocation?: ExtrasAllocation` defaulting to `"proportional"` when omitted).
  - `@songphang/core` (`settlements.ts`):
    - `HouseholdGroup = { id: string; name: string; representativeMemberId: string; memberIds: readonly string[] }`
    - `HouseholdBalanceSummary = { id: string; name: string; representativeMemberId: string; memberIds: string[]; netBalance: number; memberBalances: MemberBalance[] }`
    - `consolidateHouseholdBalances(balancesByPosition: readonly MemberBalance[], households: readonly HouseholdGroup[]): { consolidated: MemberBalance[]; summaries: HouseholdBalanceSummary[] }`
    - `suggestHouseholdSettlements(input: { balancesByPosition: readonly MemberBalance[]; minimizeDebts: boolean; pairDebts?: readonly PairDebt[]; households: readonly HouseholdGroup[] }): { transfers: Settlement[]; summaries: HouseholdBalanceSummary[] }`
  - `@songphang/core` (`recurring.ts`):
    - `RecurringSchedule = { frequency: "weekly"; dayOfWeek: number } | { frequency: "monthly" | "quarterly"; dayOfMonth: number } | { frequency: "yearly"; monthOfYear: number; dayOfMonth: number }`
    - `todayInVietnam(now: Date): string` (`YYYY-MM-DD` in `Asia/Ho_Chi_Minh`) & `hourInVietnam(now: Date): number`
    - `computeNextDueDate(schedule: RecurringSchedule, afterDateVN: string, inclusive?: boolean): string` (clamping `dayOfMonth` to `daysInMonth(year, month)`).
  - `@songphang/db` tables (`households`, `recurringExpenses`) + nullable columns `members.householdId` (`ON DELETE SET NULL`, `CHECK (kind = 'person' OR household_id IS NULL)`) and `transactions.recurringExpenseId` (`ON DELETE SET NULL`), exported from `packages/db/src/index.ts` (not `schema.ts`, avoiding ESM cycles) + CRUD query helpers in `households.ts` and `recurring-expenses.ts`.

- [ ] **Step 1: Implement `extras` `%`/VND & water-filling allocation across all 5 split methods in `packages/core/src/{split-items,split}.ts`**
  Ensure omitted `extrasAllocation` on `method === "items"` stays `"proportional"` while `equal|exact|shares|percent` default to `"equal"`; validate `ratePercent` consistency when present (`extra.amount === computePercentExtraAmount(baseSubtotal, extra.ratePercent)`).
- [ ] **Step 2: Implement `consolidateHouseholdBalances`, `suggestHouseholdSettlements`, and `recurring.ts` calendar helpers in `packages/core`**
  Use `BigInt` sums in `consolidateHouseholdBalances` and map `PairDebt` endpoints through `representativeOf` when `minimizeDebts === false` so intra-household pairs cancel automatically.
- [ ] **Step 3: Add `schema-households.ts`, `schema-recurring.ts`, `members.householdId`, `transactions.recurringExpenseId`, DB query modules, and Drizzle migration `0033`**
  Register `./src/schema-households.ts` and `./src/schema-recurring.ts` in `packages/db/drizzle.config.ts` and export from `packages/db/src/index.ts`.
- [ ] **Step 4: Exercise core edge cases & DB constraints on a disposable DB and commit**
  Verify via `tsx -e` and disposable DB: (a) Three Koala `amount = 373_680` with `exact` (`168_000`, `178_000`) + `tax` `8%` (`27_680`, `"equal"`) -> `[181_840, 191_840]`; (b) water-filling `[20_000, 200_000]` with `-50_000` `"equal"` discount -> `[0, 170_000]`; (c) legacy `items` without `extrasAllocation` -> `"proportional"`; (d) `households` (`Minh +600k`, `Lan -250k`, `Khánh -350k`) under both `minimizeDebts: true` and `false` -> single transfer `Khánh -> Minh: 350_000`; (e) `dayOfMonth = 31` after `2027-01-31` -> `2027-02-28` and `2028-02-29` in leap year; (f) DB rejects `fund` member having `household_id IS NOT NULL` and rejects `mode = 'fixed'` with `amount IS NULL`. Run `pnpm check` and `check-balances.ts`, then commit:
  `git commit -m "feat(core,db): add manual extras, household consolidation, and recurring expense schema"`

---

### Task 5.5C.1.2: Generalized `SplitInput.extras` validation & `POST /groups/{groupId}/transactions/extras/preview`

**Files:**
- Modify: `packages/contract/src/transaction.ts`
- Modify: `apps/api/src/services/{transaction-input,transactions,transaction-changes}.ts`
- Modify: `apps/api/src/routes/transactions.ts`

**Interfaces:**
- Consumes: Task `5.5C.1.1` `@songphang/core` `computePercentExtraAmount` and generalized `computeShares`.
- Produces:
  - Additive `ItemsSplitExtra` (`kind` includes `"shipping"`, optional `ratePercent`), optional `extras` & `extrasAllocation` on `EqualSplitInput`, `ExactSplitInput`, `SharesSplitInput`, `PercentSplitInput`, and optional `extrasAllocation` on `ItemsSplitInput`.
  - `PreviewExtrasRequest` & `PreviewExtrasResponse` in `packages/contract/src/transaction.ts`.
  - `POST /api/v1/groups/{groupId}/transactions/extras/preview` (`editor+`, verified email, write limit, same-origin) resolving `ratePercent` extras against `baseAmount` (or `items` subtotal), computing `netExtras`, `computedAmount`, optional `shares`, `issues`, and `warnings` (`FUND_OVERDRAWN`, `BUDGET_NEAR`, `BUDGET_OVER`).
  - `type === "income"` with non-empty `extras` rejected with `400 VALIDATION_FAILED` in `SplitTransactionRequest`, `UpdateSplitTransactionRequest`, and `calculateShares`.

- [ ] **Step 1: Extend `packages/contract/src/transaction.ts` with generalized `extras`, `extrasAllocation`, and `PreviewExtrasRequest`/`PreviewExtrasResponse`**
  Keep all existing required arrays untouched so `SplitInput` union branches remain strictly additive.
- [ ] **Step 2: Update `transaction-input.ts` and implement `previewExtras` in `apps/api/src/services/transactions.ts` + route in `routes/transactions.ts`**
  Resolve each `ratePercent` extra via `computePercentExtraAmount(baseSubtotal, extra.ratePercent)`, build complete `SplitInput`, compute shares via `computeShares`, and evaluate budget/fund warnings when payers/payerMemberId are supplied.
- [ ] **Step 3: Exercise `POST .../transactions/extras/preview` and `POST/PATCH /transactions` across all 5 split methods on disposable DB + isolated API**
  Verify: (a) Three Koala `baseAmount: 346000` + `ratePercent: "8"` returns `resolvedExtras[0].amount === 27680`, `computedAmount === 373680`, `shares: [181840, 191840]`; (b) manual đồng override (`amount: 27681`, `ratePercent` omitted) saves and re-reads cleanly on `GET /transactions/{id}`; (c) `income` with `extras` returns `400 VALIDATION_FAILED`; (d) outsider receives `404`, `viewer` receives `403`. Run `pnpm check` and `check-balances.ts`, then commit:
  `git commit -m "feat(api): support manual extras across all split methods and add extras preview endpoint"`

---

### Task 5.5C.1.3: `households` & `recurring-expenses` endpoints, `pg-boss` worker job, cross-surface household balances & `openapi.json`

**Files:**
- Create: `packages/contract/src/{household,recurring}.ts`
- Create: `apps/api/src/services/{households,recurring-expenses}.ts`
- Create: `apps/api/src/routes/{households,recurring-expenses}.ts`
- Create: `apps/worker/src/jobs/process-recurring.ts`
- Modify: `packages/contract/src/{error,jobs,member,group,balance,member-breakdown,guest-link,overview,transaction,index}.ts`
- Modify: `packages/core/src/{notification-text,index}.ts`
- Modify: `packages/db/src/{reminders,groups,members,fund,index}.ts`
- Modify: `apps/api/src/services/{balances,member-breakdowns,guest-links,groups,members,fund,overview,settlement-requests,reminders,transactions}.ts`
- Modify: `apps/api/src/app.ts`
- Modify: `apps/worker/src/{main,mail-templates}.ts`
- Modify: `packages/contract/openapi.json`

**Interfaces:**
- Consumes: Task `5.5C.1.1` & `5.5C.1.2` core math, DB tables, and transaction services.
- Produces:
  - `ErrorCode` additions: `"HOUSEHOLD_MEMBER_CONFLICT"`, `"HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED"`, `"RECURRING_MEMBER_INACTIVE"`.
  - `GroupEventResource` additions: `"households"`, `"recurringExpenses"` (`GroupEventNotification.resources` `.max(14)`).
  - `JOB_NAMES.processRecurring = "process-recurring"` + `ProcessRecurringPayload`.
  - `GET/POST/PATCH/DELETE /groups/{groupId}/households*`, `cloneGroup` copying households, `PATCH /members` refusing `active: false` on a household representative (`422 HOUSEHOLD_REPRESENTATIVE_ACTIVE_REQUIRED`) and `DELETE /members` refusing members inside a household (`409 HOUSEHOLD_MEMBER_CONFLICT`).
  - Household-consolidated `suggestGroupTransfers` (`packages/db/src/reminders.ts`), `BalancesResponse` (`households`, `fromHousehold`, `toHousehold`), `MemberBreakdownsResponse` (`householdBreakdowns`), `GuestGroupViewResponse`, `GroupSummaryDto` & `OverviewGroupBalance` (`myBalance` = household `netBalance`, plus optional `myIndividualBalance` & `householdName`), and non-representative partner authorization in `settlement-requests.ts` (`mayCreate` / `mayCancel` allow any linked member in `fromHousehold`; `mayResolve` stays strictly `representative_member_id` / `owner` / unlinked `editor` per `ADR-022`).
  - `GET/POST/PATCH/DELETE /groups/{groupId}/recurring-expenses*` + `POST .../skip` (`editor+`), inline `recurring` creation & `recurringExpenseId` completion on `POST /groups/{groupId}/transactions`, auto-pausing affected recurring templates on member/fund deactivation (`pause_reason = 'member_invalid'`), stale `nextDueDate` advancement on `PATCH` resume and group unarchive, `OverviewResponse` optional `dueRecurringCount` & `dueRecurringActions`, and `process-recurring` hourly `pg-boss` job (`0 * * * *` `Asia/Ho_Chi_Minh`, hour `>= 8`, single-catchup anti-flood, server-validated `"recurring_posted"` / `"recurring_due"` notifications without mutating `NotificationPayload.oneOf`).
  - Regenerated `packages/contract/openapi.json` (`pnpm contract:check` -> `0` breaking changes).

- [ ] **Step 1: Add contract schemas (`household.ts`, `recurring.ts`) and additive extensions across `error.ts`, `jobs.ts`, `member.ts`, `group.ts`, `balance.ts`, `member-breakdown.ts`, `guest-link.ts`, `overview.ts`, `transaction.ts`**
  Keep `OverviewPendingAction` (2 branches) and `NotificationPayload` (12 branches) unchanged in `openapi.json`; add `recurring_posted` & `recurring_due` formatting to `packages/core/src/notification-text.ts` and `apps/worker/src/mail-templates.ts`.
- [ ] **Step 2: Implement `households` service/routes and wire household consolidation into `suggestGroupTransfers`, `balances`, `member-breakdowns`, `guest-links`, `groups` (`listGroups` + `cloneGroup`), `overview`, and `settlement-requests`**
  Verify `MemberDto.householdId`, `fromHousehold`/`toHousehold` on transfers, `householdBreakdowns` exact sum identity, `Lan` (`linked viewer` in `fromHousehold`) allowed to create/cancel outgoing `settlement_request` (`fromMemberId = representative_member_id`), and `Lan` forbidden (`403`) from confirming incoming `settlement_request` (`toMemberId = representative_member_id`).
- [ ] **Step 3: Implement `recurring-expenses` service/routes, inline `S8` creation/completion in `transactions.ts`, member/fund deactivation pause hooks, unarchive date advancement, and `apps/worker/src/jobs/process-recurring.ts`**
  Enforce active-member validation (`422 RECURRING_MEMBER_INACTIVE`), inline `S8` `nextDueDate > todayVN`, `31 -> Feb 28/29` clamping, single-catchup `advancedNextDueDate > todayVN`, and `editor+`-only `dueRecurringActions`/`"recurring_due"` routing.
- [ ] **Step 4: Regenerate `packages/contract/openapi.json`, run `pnpm contract:check`, exercise all Review Focus cases on disposable DB, and commit**
  Run `pnpm contract:write && pnpm contract:check` (confirm `0` breaking changes). Exercise all household, recurring, worker catch-up, deactivation, unarchive, clone, and `viewer` RBAC flows from `00-overview.md` Review Focus; confirm `check-balances.ts` prints `All groups balanced` and `pnpm check` passes, then commit:
  `git commit -m "feat(api,worker): add households, recurring expenses, pg-boss scheduler, and additive openapi"`

---

### Task 5.5C.1.4: Lock Wave 5.5C Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5C.1 Gate

**Files:**
- Modify: `apps/web/src/messages/vi.ts`
- Modify: `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: Wave 5.5C Spec §7 Vietnamese UI string table and `./apps/ios/Scripts/check-strings.sh` rules.
- Produces: Locked bidirectional shared keys (`extras.*`, `recurring.*`, `households.*`) in both `vi.ts` and `Localizable.xcstrings`, plus `ios.*`-prefixed iOS extension/widget keys (`ios.widget.*`, `ios.shareExtension.*`, `ios.shortcuts.*`) in `Localizable.xcstrings`.

- [ ] **Step 1: Add all shared Wave 5.5C strings to `vi.ts` and `Localizable.xcstrings`, and `ios.*` extension strings to `Localizable.xcstrings`**
  Copy every string from Spec §7 character-for-character with zero emoji.
- [ ] **Step 2: Verify 100% string parity and typecheck**
  Run `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`) and `pnpm check`.
- [ ] **Step 3: Run full Stage 5.5C.1 API, Worker & Permission Matrix Gate on a reset disposable DB**
  Exercise every row of Spec §8 Security & Authorization Matrix across unauthenticated (`401`), outsider (`404`), unlinked `viewer`, linked `viewer` (both non-household and `fromHousehold`/`toHousehold` partner), `editor`, and `owner` (Cookie + Bearer), archived-group guards, `pnpm contract:check`, `pnpm build`, and `check-balances.ts` (`All groups balanced`).
- [ ] **Step 4: Commit**
  `git commit -m "feat(i18n): lock wave 5.5c vietnamese strings across web and ios"`
