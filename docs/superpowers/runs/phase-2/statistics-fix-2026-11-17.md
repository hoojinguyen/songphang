# Phase 2B statistics drill-down correction

Authorization: owner requested this correction after reviewing `advisor-review-2026-11-17.md`. No Phase 3 implementation is authorized. Work stays on the current branch, with no push or unrelated fixes.

## Approach

Add one optional `spendingOnly` scope to the existing transaction query and carry it through service, DB filter, URL, query cache and filter chips. All three S16 drill-down types set it. Preserve ordinary uncategorized filtering, refunds, date/member filtering and the existing pagination. Use existing product labels for the removable combined type chip. A global exclusion on uncategorized rows was rejected because it changes the meaning of the generic feed filter.

## Verification

- `pnpm check` passed: 316 files before the preparation-only data additions, all five workspace typechecks completed.
- Production build against the isolated current-source API passed.
- Real HTTP against the retained disposable review database:
  - `uncategorized=true` -> 200, S7 expense 10000 and S5 transfer 50000 (unchanged).
  - `uncategorized=true&spendingOnly=true` -> 200, S7 expense 10000 only (corrected).
  - `spendingOnly=true` -> 200, expense/income rows including Hoàn cọc 100000, no transfer.
  - `spendingOnly=false&type=transfer` -> 200, S5 transfer 50000.
  - `spendingOnly=true&type=income` -> 200, Hoàn cọc 100000.
  - `spendingOnly=true&type=transfer` and `spendingOnly=wrong` -> 400 VALIDATION_FAILED.
  - Member filter retains the matching expense/income rows; transfer-only date 2026-12-21 returns an empty list.
  - Two-row cursor pages traverse all seven live counted rows, including income, without returning S5.
  - Editor/viewer reads 200; outsider 404; signed-out 401.
- `pnpm db:check-balances` on the separate populated review database -> `All groups balanced`. No money write or migration is required by this fix.
- Production browser: every S16 category/member/time href includes spendingOnly=true; Chưa phân loại shows only S7 10000 and a removable Chi/Thu type chip. Reload and applying the unchanged filter sheet preserve the scope; removing the scope chip shows S5 again. Captured local evidence: `/private/tmp/songphang-advisor-20261117/statistics-fixed.jpg`.

Security review: relevant items 1–8 checked; bounded enum query at the contract boundary, typed parameterized group-scoped predicate, existing middleware/roles unchanged, no secret, dependency, redirect, storage, money arithmetic or disabled check added. Online audit remains unavailable under the local-only rule.

## Manual checks

1. Recreate the December ledger from the Phase 2B plan. S16 -> Chưa phân loại -> only S7 10000 appears; transfer S5 does not. Reload and back/forward must keep the same scope.
2. Tap a member or time bucket on S16 -> matching expense/income rows appear, including refunds and excluding transfers.
3. Remove only the combined type chip or pick Chuyển in the filter sheet -> generic transfer filtering works again. Xoá lọc removes every filter.
4. As a viewer read the scoped list -> 200; outsider -> 404; signed out -> 401. An invalid query value -> 400.

## Decisions and scope

`spendingOnly` is an additive list query option, not an endpoint or schema/table change. No product wording is invented. Existing large files are changed minimally rather than restructured. The owner already authorized continuing from the fix to advisor preparation; this report does not authorize a Phase 3 run. Real-bank, Fast 4G and spreadsheet-application verification remain the limitations recorded in the earlier review.

## Files and review

Changed: contract/src/transaction.ts, db/src/transactions.ts, api services/transactions.ts, web lib/transactions.ts, FilterChips.tsx, FilterSheet.tsx and StatsContent.tsx. Standing API/UX amendments accompany the advisor preparation commit. Existing FilterSheet and transaction service/library files were already above the size guideline; the fix adds only the bounded filter plumbing and avoids unrelated splitting.

Independent read-only review returned PASS with no actionable findings; HTTP/browser/database exercise results above are from the primary agent. No tests were added. No out-of-scope product issue was fixed. Commit reference: `fix(stats): preserve spending scope in feed drill-downs`.
