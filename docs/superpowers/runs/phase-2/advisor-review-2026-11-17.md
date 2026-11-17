# Phase 2 verification and Phase 3 preflight review

Date: 2026-11-17. Role: advisor. Reviewed source: local `main` at merge `d12f622`, including the Phase 2 commits from `94f1c60` through `198c115` and their review fixes. The concurrent iOS changes are outside this review. Local `main` was 35 commits ahead of the recorded remote-tracking ref; no fetch, push, branch change, merge, deployment, or external provider request was performed.

The owner authorized Phase 3 document revisions and this verification, explicitly withholding Phase 3 implementation approval. Request-local AI references are approved; the other Phase 3 revisions remain proposals pending review. No product source, dependency, database migration, automated test, or committed exercise script was added.

## Conclusion by stage

### Stage 2A: PASS

Local payload, payment details, settlement authorization, idempotency, confirmation, balance decoration and browser exercises passed. Physical banking-app acceptance remains owner-only and unverified.

### Stage 2B: CHANGES NEEDED

Must fix

1. **[P2] Statistics drill-down includes transfers excluded from the statistic** — commit `680d778`, `apps/web/src/components/stats/StatsContent.tsx:147` (uncategorized drill-down; the target query's null-category predicate is `packages/db/src/transactions.ts:110`). On the plan's December ledger, all-time statistics show uncategorized spending of 10000, from S7 only. Opening that row sends only `uncategorized=true`; the feed includes S5 (transfer 50000) as well as S7 (expense 10000), because a transfer also has both category fields null. This was reproduced through HTTP and the production browser. Add an explicit counted-transaction scope to statistics navigation (expense/income only), propagate it through the validated query and feed filter state, and keep ordinary feed filtering semantics explicit. Apply the same scope to statistics member/time drill-down where needed; their source aggregates also exclude transfers. Re-exercise with an expense, refund and transfer in the same period, including reload/back navigation. Do not change the fixed ledger expectations.

Should fix

None beyond the finding above established by this review.

### Stage 2C: PASS

Fund cash, contributions, suggestions, people-only shares, authorization, deferred integrity trigger and reader exercises passed. The API's `DEFAULT_FUND_NAME` in `apps/api/src/services/fund.ts:27` duplicates localized `Quỹ chung` instead of reusing the project's one-message-source pattern; this is a non-blocking maintenance note to reconcile when approved, without changing the displayed wording.

### Stage 2D: PASS

Budget thresholds, current-month and total periods, income/transfer handling, replaced-excluded edit baseline and cross-tab SSE browser behavior passed. The inherited 2B finding prevents declaring the whole phase passed. Fresh Fast 4G timing is not established below.

## Environment and method

- Started a separate empty local review database, applied all ten migrations (0000–0009), and seeded the existing four development users. The ordinary development database was neither reset nor written by the review.
- Used current-source API on 4017 and a fresh production web build on 3017 with matching origin. Existing user runtimes were not stopped or reconfigured. Only review-owned processes are stopped at the end.
- Historical `/tmp` replay files were absent. Reconstructed disposable manual HTTP/function/SQL exercise loops from the plans; inspected the observed output against the fixed expectations. The loops are scratch files only and have no test framework or committed assertions.
- Read `decisions.md` before the gates and reviewed the Phase 2 migrations/contracts, group-scoped queries, shared ledger writer, new route middleware, service transactions, reader changes, warning calculations, SSE invalidation, and affected payment/fund/statistics/budget UI.
- Repeated the original final-trip exercise after correcting the scratch role setup: Hùng is editor there, while Phase 2's permission exercises intentionally use Hùng as viewer. The corrected trip includes a newly registered/verified Ngân as viewer. The earlier scratch 403 on Hùng delete/restore was a fixture setup error, not a product finding.

## Fresh verification evidence

### Automated gates and database integrity

- `pnpm check`: passed, 316 files at the initial gate, all five workspace typechecks completed.
- `API_ORIGIN=http://localhost:4017 pnpm build`: passed; production Next.js compilation, type checks and page generation completed.
- Migrations: `Migrations applied`; seed: `Development users seeded`.
- Review database balance checker after the acceptance exercises: every group printed `sum 0; mismatches 0`, followed by `All groups balanced`. Final repeat after UI/load and all 87 HTTP reader rows again printed `All groups balanced`.
- Ordinary development database checker: `No groups`; this is explicitly not used as ledger correctness evidence.
- No online dependency audit: external service calls remain prohibited. Package/lockfile inspection found workspace links to the existing core package, with no added external library in Phase 2.

### Phase 1 cumulative acceptance

| Gate | Observed result |
|---|---|
| 1A sample ledger | Minimized balances 566666, -33333, -333333, -200000; pairwise mode preserved balances and returned the required four transfers; after taxi 626666, -63333, -363333, -200000 |
| 1B accounts | Register 204; group write before verification 403; verify 204, reuse 400; login 204; Ngân joins and is viewer, reads 200 and write 403; removed Hùng reads 404 while member remains in ledger; old rotated invite 404 |
| 1B token/session safety | Forgot/reset 204; reset token reuse 400; previous Ngân session gets 401; existing/new registration responses both 204; existing/absent forgot responses both 204; absent-account login 401 with generic credentials error |
| 1B SSE | `event: changed` observed about 37 ms after the write in the local exercise |
| 1C T1–T4 | Shares match 120000/100000/80000, 480000/240000/240000/240000, four 50000s, and 49999/30000/20000; balances 500001, -120000, -170001, -210000; T5 leaves 290001, -120000, -170001, 0 |
| 1C invalid paths | Wrong exact sum 400 SPLIT_TOTAL_MISMATCH with 300000/320000; payer sum 400 PAYER_TOTAL_MISMATCH with 1200000/1100000; preview T2 matches stored shares |
| 1D and Phase 2 reader | All 87 documented rows exercised through real HTTP parse (87 responses 200, no status differences) and directly through `readSentence` and `computeShares`, including status, descriptions/amounts/payers, issues and shares. No status difference. A01/A36 span outputs inspected; expected fund ambiguity/refusals retained |
| 1E corrected final trip | Parsed/saved Lan's bill; edit gives 130000/90000/110000, version 2; stale edit 409; Hùng delete 204 and restore 200; balances 320001/180000/-180001/-320000/0; three suggested transfers settle all five to zero and `transfers: []`; history actors read; wrong-name delete 400, editor delete 403, exact-name owner delete 204 then 404 |

### Stage 2A

- CRC standard vector: `29B1`. Both fixed QR payloads match byte for byte, ending `6329` and `A05F`. All three purpose examples match. Five invalid builder inputs raise `RangeError`.
- Owner bank/MoMo write 200; editor other-member ZaloPay write 200 with normalized `0912345678`; viewer own write 200; viewer other member 403; outsider 404. Unknown BIN, duplicate kind, short phone and dashed account each 400.
- Invite preview contains no `paymentMethods`; three inspected payment update activity rows had zero non-null before/after snapshots.
- Expense 600000 creates 450000/-150000/-150000/-150000. Pending report 201 leaves them unchanged and supplies the exact server QR/pending decoration. Original idempotency key replays 201 with the same ID; new key on the pending pair gives 409.
- Linked receiver confirmation 200; editor for a linked receiver and payer self-confirm each 403. Repeated confirmation 409 REQUEST_NOT_PENDING. Creator cancellation 200, unrelated viewer cancellation 403. Editor can confirm for unlinked Thu; viewer cannot. Owner rejection 200 leaves balances unchanged.
- Concurrent same-key creation: `[201, 201]`, same ID. Concurrent confirmation: `[409, 200]`.
- Large debt 1999999999998 returns 200 with exact balances/debt and null QR, without crashing; normal transfer amount remains bounded by the approved partial-payment behavior.
- Browser: QR/account/purpose visible on S14; copy amount reports `Đã sao chép`; reporting 148000 leaves Minh +299000/Lan -148000 until confirmation; confirmation changes them to Minh +151000/Lan 0 and one remaining transfer.

### Stage 2B

- December aggregate: total 1999999; food 699999, lodging 1100000, transport 200000. Paid amounts 1700000/200000/99999/0; shares 558333/558333/458333/425000. Day, week and month buckets match every required aggregate example.
- All-time total 2009999, including uncategorized 10000 on Vietnam date 2027-01-01. Deleting S4 gives 799999; restored afterwards.
- `pho` and `PHỞ` each return S6; literal percent returns none; `=sum` returns S7; Thu member filter S7/S4/S3/S1; transfer S5; food S6/S1; Vietnam date boundaries return S6/S7 as specified. Invalid reversed range, 101-character search and invalid month each 400. Cursor pages S7/S4 then S3/S1 then end.
- CSV 200, BOM `efbbbf`, UTF-8, CRLF, exact ten-column header. S1, S5, S6 and S7 rows match the plan, including `'=SUM(A1)`. Direct cell exercises escape all six formula prefixes and correctly quote `Cơm, "gà"`; numeric negative values remain numbers. Requests 1–6 returned 200 and request 7 returned 429.
- Category duplicate folded name 409; viewer create 403; archive 204 and archived DTO retained. Existing archived-category edit preview and save return 200; new use of archived category 400; simultaneous built-in/custom category 400; re-create archived name 201; 31st live category 422 LIMIT_REACHED.
- Browser: S16 renders aggregates and drill-down links; uncategorized drill-down reproduces the must-fix finding. Filter sheet opens; Escape closes and restores focus to `Lọc`.

### Stage 2C

- Cash after F0/F1/F2/F3: 0/500000/200000/0. People after F2: -100000/+400000/-100000; suggestions fund→Lan 200000, Minh→Lan 100000, Hùng→Lan 100000. Contributions Lan 500000, then 300000 after the withdrawal.
- Duplicate fund 409; nonzero close 422 FUND_NOT_EMPTY; delete referenced fund 422 MEMBER_HAS_TRANSACTIONS; API fund share 422 FUND_CANNOT_SHARE. Rename, close at zero and reopen return 200. Overdrawn expense is allowed with FUND_OVERDRAWN.
- SQL exercises in the disposable database: duplicate fund unique violation; linking a user to a fund rejected; correctly summed expense share on fund rejected by the deferred integrity trigger at COMMIT. Fund transfers remained valid. Failed SQL connections rolled back; no invalid state persisted.
- Browser S17 shows renamed fund, negative cash 1000, holder Lan and contribution 300000. Closing the nonzero fund displays the approved rejection text.

### Stage 2D

- All ten budget core rows match, including exact 80%, equality at the full amount, large boundary values, negative spending and invalid zero limit.
- Current real Vietnam month used: November 2026; current exercise transactions dated 2026-11-17T05:00:00Z, previous month dated 2026-10-15T05:00:00Z.
- Month budget: 799999 no warning; +1 BUDGET_NEAR; +200001 BUDGET_OVER; income -300000 gives 700001/ok; transfer does not count; previous-month expense does not count; total mode gives 1200001/over with null period boundaries; zero amount 400; delete 204 then null.
- Edit preview and PATCH agree at the replaced-excluded boundary, including 1050000 -> 1100000: both return BUDGET_OVER as required by the approved review correction.
- Browser S11 save succeeds without taking focus on initial load; changing limit to 600000 causes `Đã vượt hạn mức 100.001 đ.` to appear in the second feed tab through SSE, without reload. Removing it makes the banner disappear in that tab without reload.
- Recomputed contrast: ink on sunken 13.71:1; ink on coral 7.43:1.

### Permission matrix

Read endpoints (group, members, users, transaction list/detail, balances, activity, categories, statistics, budget, settlement requests, CSV and events) returned owner/editor/viewer 200, outsider 404, signed-out 401. Invite read was 200/200/403/404/401.

Transaction create/edit/delete/restore, preview/parse, member create/edit/delete, category create/edit/archive and fund create/edit/delete preserve editor writes and viewer 403, outsider 404, signed-out 401. Budget write/delete and group settings/invite controls/role changes/removal/ownership transfer/group deletion remain owner-only. Leaving returned owner 422, editor/viewer 204, outsider 404, signed-out 401. Choosing one's own member returned 200 for owner/editor/viewer. Settlement and payment identity exceptions are exercised separately above.

The initial shared-fixture loop caused expected state conflicts (second category creation 409, editor deleting a fund already removed by owner 404, and editor attempting to claim owner's member 409). Replayed those editor cases with valid independent state: category create 201, unused fund delete 204, own-member choose 200. They are not permission failures. Outsider vs random-group 404 response bodies were identical after removing `requestId`.

### Local load measurements

A separate 500-transaction fixture was seeded directly in SQL in one valid ledger transaction (500 payer rows and 2000 shares); this measures reads, not API write throughput. All reads returned 200.

| Endpoint | Median of five, ms | Last response bytes |
|---|---:|---:|
| transactions?limit=50 | 7.95 | 50198 |
| balances (minimized) | 7.54 | 923 |
| stats | 5.58 | 888 |
| export.csv | 9.63 | 45477 |

Browser S16 showed total 50000000 and four shares of 12500000. These are unthrottled local measurements; they do not establish the Fast 4G gate.

## Security review

Security review: checked relevant items 1–8 against the actual Phase 2 source/diff; no new exploitable issue established in the inspected scope. Verified boundary schemas, shared group middleware and post-lock write checks, viewer identity exceptions, integer/core money calculations, parameterized group-scoped queries, atomic confirmation and idempotency, value-free payment activity, private invite DTOs, generic errors, and plain-text rendering. Authentication/session protections were exercised through account flows and the permission matrix. Online dependency audit is not verified under the local-only rule. The statistics finding is a correctness failure, not an authorization bypass.

No credentials, console mail tokens, cookie jars, environment files, connection strings or full private logs are included in this report or Git. The screenshot uses only synthetic review fixtures. Local evidence image: `/private/tmp/songphang-advisor-20261117/uncategorized-drilldown.jpg`.

## Decisions for the project owner

D1–D5: confirm the recorded supersession: D4 resolves D1 through the explicitly authorized VietQR snapshot; D2 reuses qrcode; D3 keeps CSV text in the common message source; D5 supplies fixed fund samples. These are historical preparation records, not fresh external-source certification.

D6–D10: confirm the capability shape, workspace export/schema registration, independently authorized ledger writer, group→request lock order/advisory idempotency and viewer-own editor layout. New exercises support their intended behavior.

D11: confirm the shared transfer action, unmatched pending list and split payment components; large-debt behavior remains as approved. D12: confirm archived category preservation. D13: confirm the existing shared normalizer/backfill workspace link (supersedes D12's earlier statement that db had no core link). D14: confirm filter wording and native-dialog containment. No extra decision entry was present after D14 in the inspected file.

Phase 3: approve or revise spec section 15 and its aligned stage plans. These proposals cover temporary references, preserved capabilities, body/storage limits, transaction-bound durable enqueue, attempt reservations/recovery, server-computed item preview, deterministic fake fixtures and regression gates. The fixed item-sharing numbers were independently rechecked and retained.

## Phase 3 readiness

**Not ready to execute.** Revised documents have received a read-only independent builder check and corrections; they remain pending owner approval. Existing source paths and capability names are now explicit. Blocking prerequisites:

1. Owner reviews this result and the revised spec/plan; Phase 3 execution is still unauthorized.
2. Resolve the Phase 2B finding and verify its correction in a separate approved code task.
3. Advisor supplies four receipt images/readings, fifteen sentence fixtures and the category keyword table. They are currently absent; no placeholders were substituted.
4. Advisor updates the standing ADR/SAD/database/API/UX documents before the run; the old item-table proposal must be superseded.
5. After execution approval, task 3A must demonstrate the exact installed stable pg-boss adapter can enqueue in the existing database transaction before scan implementation. Unsupported integration requires an advisor outbox amendment, not a non-atomic fallback.

## Manual checks for the owner

1. Recreate the December ledger from stage 2B, open S16 all-time, then tap `Chưa phân loại`: current code lists S5 and S7 while the statistic counts only S7. After an approved fix, only counted expense/income rows should appear and reload/back should preserve the scope.
2. With two local accounts, report a synthetic payment: balances must remain unchanged until the receiver confirms; confirming again must not create a second transfer.
3. Create a shared fund, contribute 500000 and pay 300000 across three people: cash is 200000 and closing is refused until zero.
4. Save a 1000000 month limit; spending 800000 shows near, 1000001 shows over; removing the limit must update a second tab live.
5. Review spec section 5.6 and 15 plus the Phase 3 overview checklist. Approval of these documents does not by itself authorize implementation in this chat; give execution approval separately.

## Not verified

- Real banking-app scan, bank account-name lookup, real transfer, SMTP delivery and Google OAuth. No outside service was called.
- Fresh cold Fast 4G timing and a complete keyboard-only walk of every screen/device size. Browser flow/accessibility checks above are narrower; native browser control changed during the attempt to open network tools, so no throttled timing is claimed. Historical Phase 2 records are not substituted as fresh evidence.
- Opening CSV in Excel/another spreadsheet application; byte/content/formula escaping was verified locally.
- Online dependency vulnerability audit, physical phones, real screen readers, iOS workspace.
- All Phase 3 runtime behavior, fixture quality, provider quality/cost/latency, and pg-boss integration: Phase 3 has not been implemented.

## Gate not passed

- Stage 2B statistics drill-down finding above.
- Fresh Fast 4G non-functional gate is not established. Do not describe this report as an unqualified full-phase PASS.
