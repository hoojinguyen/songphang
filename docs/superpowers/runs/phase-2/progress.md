# Phase 2 run — progress

## Status — advisor preparation resumed

Date: 2026-11-17. Owner authorized preparation and continuous execution in the current session. This authorization supersedes the draft approval labels in the existing specs. No implementation has started.

Repository inspection: clean local `main` and `origin/main` both pointed at `30d27bc`, the terminal SSE cancellation fix. `phase-2` did not exist and was created from local `main`. The separate `songphang-ios-ui` worktree on `ios-ui` was not modified.

### Approach

- Create only the three authorized Phase 2 run records while investigating the mandatory advisor input.
- Obtain the complete bank/BIN mapping from official public NAPAS documentation before creating `packages/core/src/banks.ts`.
- Preserve the fixed QR references, existing 75 reader samples, Phase 1 security fixes and local database.
- Record unavailable input explicitly; do not turn an incomplete or third-party list into an authoritative dataset.

### Blocking prerequisite

The complete authoritative NAPAS bank dataset has not been obtained. See decision D1 for exact URLs and observed access results. The common plan's Advisor deliverables section explicitly says a run does not start without its data files. The owner also explicitly requires reporting this blocker instead of substituting dummy data.

Advisor preparation remains incomplete: no bank source file, fund-sample additions, standing-document amendments or completed-preparation commit. The record-only checkpoint is identified by the unique commit subject `docs(run): record phase 2 preparation blocker`; it does not represent completed advisor preparation or Task 0.

## Task checklist

- [x] Advisor preparation — commit reference `docs(phase-2): prepare approved real-money phase`
- [x] Task 0 — commit reference `docs(run): re-baseline phase 2`
- [x] 2A.1 — VietQR payload and bank lookup
- [x] 2A.2 — member payment methods
- [x] 2A.3 — settlement requests
- [x] 2A.4 — payment data and pending requests on balances
- [x] 2A.5 — payment methods editor
- [x] 2A.6 — paying screen, confirmation and gate 2A
- [x] 2B.1 — custom categories
- [x] 2B.2 — search and filters
- [x] 2B.3 — statistics
- [x] 2B.4 — statistics screen and filters
- [x] 2B.5 — CSV export
- [x] 2B.6 — categories UI and gate 2B
- [x] 2C.1 — fund member integrity
- [ ] 2C.2 — fund endpoints and balances
- [ ] 2C.3 — fund sentence reader
- [ ] 2C.4 — fund UI
- [ ] 2C.5 — gate 2C
- [ ] 2D.1 — budget core and API
- [ ] 2D.2 — budget UI
- [ ] 2D.3 — README, final gate and final records

## Preparation exercises

Temporary manual Python exercise, using standard-library `binascii.crc_hqx` with initial value 65535:

```text
CRC standard vector: 29B1
Hung expected CRC suffix 6329 actual CRC of prefix 6329
Hung purpose character count 16
Lan expected CRC suffix A05F actual CRC of prefix A05F
Lan purpose character count 15
long purpose rule: SP Nguyen Thi Thu Hang tr
```

The two fixed reference strings' top-level TLV fields were inspected and had matching declared lengths. This verifies the supplied references independently; it does not exercise an implemented Phase 2 builder or a banking app. No script was committed.

## Baseline failures

None established. Task 0 is pending; historical Phase 1 gate records are not fresh verification of this run.

## Record-only checkpoint validation

`pnpm check` passed before the record-only commit: `Checked 237 files`, no Biome fixes, all five workspace typechecks `Done`, including successful Next.js route type generation.

Security review: relevant item 1 checked against all three added run files; no secrets, connection strings, cookies or private dump paths. Items 2–8 have no changed implementation to review; no dependency or runtime change. Online dependency audit was not called. Full added-file diff inspected; all tasks remain unticked and historical results are distinguished from fresh exercises.

## Not verified

- Full advisor preparation and Task 0, including build, reset acceptance and permission replay.
- Every Phase 2 implementation task and stage gate.
- Complete current NAPAS member-bank/BIN dataset.
- Banking-app scan and real transfer (owner-only check after implementation).

The local database was neither reset nor modified, so no backup/restore exercise was required or performed. No banking/payment API, account creation, real transaction, deployment, push or merge was performed.

## Gate not passed

No stage gate was attempted. The mandatory advisor-input prerequisite remains blocked; no task is marked complete.


## Advisor preparation resumed — 2026-11-17

Approach: create banks.ts from the authorized public VietQR snapshot; append twelve independently calculated fund samples; amend AGENTS/SRS/database/API/UX/ADR for the approved Phase 2 scope. Keep old run blocker evidence as history, superseded by D4. Reuse installed QR rendering and the existing pure message import exception for CSV labels. No implementation or database mutation before this preparation checkpoint.

Observed source exercise: code 00, 76 entries, 76 unique six-digit BINs, all names nonempty. Original samples preserved as an exact byte prefix. The source snapshot is documented, not described as a NAPAS certification. No payment/account/transaction API was used; only the explicitly approved public bank catalogue.

Preparation validation: pnpm check passed (238 files, all five workspace typechecks Done). Security review: relevant items 1, 2, 8 checked; static catalogue fields validated before generation, no credentials or dependency/runtime changes. Full standing-document amendments and dataset reviewed. banks.ts exceeds 200 lines because it is the complete static catalogue, not executable logic. Fund sample arithmetic and original 75-sample byte preservation checked. Previous blocker status above is historical and resolved by D4.

## Task 0 — approach

Map all plan paths against the actual source inventory; retain existing names and record missing prerequisites. Add the common plan's missing public capability contract/route with all optional services false, preserving separate auth providers. Back up the existing database privately before resetting public/drizzle schemas; replay Phase 1 acceptance using existing temporary manual exercise loops, then restore the dump before proceeding. Run check/build and inspect actual outputs; no assertion script is added to Git.

### Task 0 results

pnpm check passed: 240 files, all five workspace typechecks Done. pnpm build passed including Next compilation/type checking/static pages. Reset migrations and seed succeeded after a private pg_dump backup. Existing temporary manual exercise loops replayed final trip, 1A/1B/1C, 75 reader samples and permission matrix; all four processes exited 0. Reader: 75 match rows, zero mismatches, saved counts A=4/B=0/C=0. Final-trip edit shares 130000/90000/110000; stale edit 409 VERSION_CONFLICT; pre-settlement balances 320001/180000/-180001/-320000/0; settlement ended with five zeros and transfers []; group delete 204 then inaccessible. Permission replay retained owner/editor/viewer/outsider/signed-out statuses, malformed/random groups 404; final extension produced 52 observed lines. Intentional rate sweep observed 200/429 with limits enabled.

GET /features on the current-source API returned 200 with all six documented capabilities false; six unavailable optional route probes returned 404. The original API on 4000 predates this added route, so this new feature was exercised on a separate current-source API on 4001; all baseline ledger code remains identical.

Balance checker after replay: All groups balanced. Restored the original private dump with pg_restore --clean --if-exists --exit-on-error, then balance checker again: All groups balanced. No dump, cookie jar or exercise script is committed. Security review: relevant items 1/2/3/6/8 checked against the full diff; intentionally public schema-validated fixed booleans, no group data, no secrets/dependencies/configuration; all Phase 1 authorization/session/SSE/snapshot code untouched. No baseline failure found. Banking/device/external-provider checks remain unverified.

## Task 2A.1 — approach

Create core/vietqr.ts with the specified ASCII TLV fields and CRC-16/CCITT-FALSE; reuse foldVietnamese for the purpose and the prepared BANKS snapshot for lookup. Export these functions through core/index.ts. Validate all public builder inputs before formatting. Keep QR rendering out of core and avoid any dependency or network call. Exercise fixed payloads, standard CRC vector, normalized purposes and invalid inputs before committing.

### Task 2A.1 results

Commit reference: `feat(core): add VietQR payload builder and bank lookup`. pnpm check passed (241 files, five workspace typechecks Done). Temporary direct function exercise printed CRC 29B1; all three purpose references exactly; both fixed QR strings exactly ending 6329/A05F; five invalid cases each RangeError; lookup Vietcombank/undefined. Purpose folding preserves original case because the reader normalizer intentionally lowercases names. No money division or sum was added. Security review: relevant items 1/2/8 checked; bounded safe integer amount, ASCII payload, six-digit BIN and bounded alphanumeric account; no secret, new dependency or service. Full core diff reviewed; no out-of-scope change. Actual bank-app acceptance remains Not verified.

## Task 2A.2 — approach

Add the payment table/migration and typed group-scoped reads/replacement queries, then a discriminated request/DTO contract. The service locks the group, rechecks viewer access and applies own-member/editor rules before replacing the complete list and recording a value-free activity entry. Batch payment reads into member responses; keep invite DTOs unchanged. Add a thin PUT route with existing write/session/origin middleware; register the new schema in drizzle-kit configuration so generated migrations own all constraints.

### Task 2A.2 results

Commit reference: `feat(api): add payment details of members`. pnpm check passed (247 files, all five workspace typechecks Done); generated/applied migration 0004. Real HTTP: owner bank+momo 200; editor other member's zalopay 200; viewer own momo 200; viewer other member 403 FORBIDDEN; outsider 404 NOT_FOUND. Unknown BIN, duplicate momo, short phone and dashed account each 400 VALIDATION_FAILED. Readback normalized 0901234567 and 0912345678; clear list 200 []. Invite preview contained no paymentMethods. SQL observed the payment-update activity row with before/after both NULL. An initial temporary helper used id instead of actual userId; corrected the helper from the installed contract, no product change needed. Generated JSON initially failed formatting; formatting only fixed it, without disabling checks.

Security review: relevant items 1–8 checked against schema, migration, query, service, route and entire diff. Same-origin/verified writes, shared group auth and post-lock recheck retained; no group data accessible to outsiders; payment values absent from activity snapshots/invite DTOs/logging; parameterized group-scoped queries and atomic replacement. Internal workspace dependency only; no network audit under local-only rule. setPaymentMethods exceeds 40 lines to retain one explicit authorized replacement transaction; files remain under 200 lines. D7 records schema/dependency adaptation. Out of scope: none.

## Task 2A.3 — approach

Add settlement schema/queries/contracts and thin viewer routes, with service predicates for payer/resolver/canceller identity. Serialize writes with the existing group lock before locking a request, recheck current membership under that lock, and create the confirmed transfer through one shared internal transaction writer. Keep ordinary transaction creation's post-lock editor guard intact. Add per-idempotency-key transaction locking before lookup so concurrent duplicate request creation can replay rather than fail the pending-pair rule. Emit resource-only events after commit and exercise every permission/status case.

### Task 2A.3 results

Commit reference: `feat(api): add settlement requests confirmed by the receiver`. pnpm check passed (253 files, five workspace typechecks Done); migration 0005 applied. Exercise rows 1–16: pending 201, duplicate new key 409, original key 201 same ID; unauthorized other payer 403; editor for linked receiver 403; payer self-confirm 403; receiver confirm 200 with transfer; repeat 409 REQUEST_NOT_PENDING. Balances before/request pending 450000/-150000/-150000/-150000; after confirmation 300000/-150000/0/-150000; stored transfer count 1. Creator cancellation 200 vs other viewer 403. Editor for unlinked receiver create/confirm 201/200, viewer confirm 403; owner rejection 200 with unchanged balances. Zero/equal members 400 VALIDATION_FAILED; foreign member 400 MEMBER_NOT_IN_GROUP; outsider list/create 404/404; signed-out list 401. Concurrent same-key create [201,201], one ID; concurrent confirm [200,409]. Pagination request 200. Disposable group with pending request deleted 204, later list 404. pnpm db:check-balances: All groups balanced.

Security review: relevant items 1–8 checked against full schema/migration/query/contract/service/route/idempotency/cascade diff. Group role and linked identity re-read after group lock, request row locked, one atomic confirmation/ledger/log write, no sensitive snapshots/events/logging, safe integer schemas and parameterized SQL. Ordinary editor-only ledger guard, session serialization, repeatable reads and terminal SSE cancellation preserved. No external call/new library; online audit remains unverified. resolveSettlement and declarative route registration exceed function guideline to keep one cohesive transaction/endpoint group; each file under 200 lines. D8/D9 record required adaptations; no unresolved defect.

## Task 2A.4 — approach

Extend the existing balance contract in place with payTo/purpose/pendingRequest. Read member names, methods and all pending pairs inside the existing repeatable-read snapshot; decorate already-computed transfers without touching settlement arithmetic. Pass the authenticated user ID from the thin balance route for createdByMe. Build each bank payload only in core, retaining identical account/amount/purpose in the DTO; batch queries rather than one per transfer.

### Task 2A.4 results

Commit reference: `feat(api): add payment data and pending requests to suggested transfers`. pnpm check passed (253 files, five typechecks Done). Fresh four-person 600000 expense plus Hùng pending report: GET balances as Hùng/Lan 200; Hùng → Minh QR equals the first fixed reference byte for byte; account in QR equals payTo account; requested amount 150000; createdByMe true for Hùng and false for Lan. Lan → Minh pendingRequest null; removing receiver methods yields payTo []. pnpm db:check-balances: All groups balanced. Security review: relevant items 1/2/3/4/5/6/8 checked against full diff; existing shared read authorization, same repeatable-read snapshot for names/methods/pending/debts, batched group-scoped reads, validated additive DTO, no sensitive log/activity/invite changes and no new dependency. getBalances remains one snapshot operation above function guideline; no money arithmetic was changed. Not verified: real banking apps.

## Task 2A.5 — approach

Add BankPicker as a searchable native dialog and PaymentMethodsFields beside the existing member editor; reuse TextField/Button and current spacing. Keep editable payment state in a sibling hook, validate the complete list with the shared contract and save through the existing API client. Show the section read-only for other members viewed by a viewer, editable for their own member. Enable member-row expansion for details without granting generic name/deactivate/delete controls. Add exact spec strings once in vi.ts and reuse them everywhere.

### Task 2A.5 results

Commit reference: `feat(web): add payment details to the member editor`. pnpm check passed (256 files, five typechecks Done). Current-source production web build passed and was exercised at localhost:3001 against the isolated current-source API at 4001 (temporary runtime WEB_ORIGIN=localhost:3001; no committed env change). Browser: saved bank+momo, saw Đã lưu.; reloaded and read canonical account name NGUYEN VAN MINH and normalized momo; removed momo and later viewer read showed only bank details. Picker search vietc included Vietcombank. Dashed account showed Số tài khoản chỉ gồm chữ và số.; short phone showed Số điện thoại chưa đúng. As Hùng viewer, Minh's receiving details appeared as a definition list with no inputs; Hùng's own section had editable fields and no name/deactivate/delete controls. Initial check identified missing PUT in the existing request builder; extending only its accepted method union fixed the cause. Final save label reuses existing Lưu instead of the name-only label seen in the first browser pass.

Security review: relevant items 1/2/4/6/7/8 checked against full diff; contract validation and API authority retained, write guards and synchronous submit ref, no persisted sensitive browser storage, unsafe HTML or external link/API. No dependency. Each new component below 150 lines; hook below 100; preexisting oversized page retained as D10 explains. Physical banking/device checks remain unverified. No out-of-scope change.

## Handoff checkpoint — 2026-11-17

The owner requested handoff to another agent because of the current agent's usage limit. Current implementation checkpoint is 5b911ff, through 2A.5; first unticked task is 2A.6 and no code for it has been started. Full continuation instructions, current runtime/backup/exercise details and remaining work are in handoff.md. This documentation-only checkpoint does not mark the phase complete. Historical preparation-blocker/Not verified text above is superseded for completed tasks by their later recorded results. Current outstanding work: 2A.6, all 2B/2C/2D tasks and cumulative stage/final gates. No Phase 2 stage gate has been attempted yet.

## Task 2A.6 — approach

- Files to create/modify: create `apps/web/src/lib/settlement-requests.ts`, `apps/web/src/components/pay/QrCard.tsx`, `apps/web/src/components/pay/CopyRow.tsx`, `apps/web/src/components/balances/PendingRequestRow.tsx`, `apps/web/src/components/balances/TransferAction.tsx`, and `apps/web/src/app/g/[groupId]/pay/page.tsx`; modify `apps/web/src/lib/balances.ts`, `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`, `apps/web/src/app/g/[groupId]/balances/page.tsx`, and the three settlement card components (`OwnSettlementCard.tsx`, `SettlementCard.tsx`, `OtherSettlements.tsx`).
- Approach: add `settlementRequests` to SSE invalidation (invalidating both `balances` and `settlementRequests`), add settlement-request create/resolve/list hooks, and build the `/pay` screen drawing the server `qrPayload` via `qrcode` (`create`) as a 240px SVG with 4-module quiet zone (`#1c1b22` on `#ffffff`). Replace editor-only S5 actions with `TransferAction` linking to `/pay` or rendering `PendingRequestRow` with role/claim-based resolver and creator/payer cancel actions plus 409 handling via `useSnackbar`.
- Why simplest: reuses existing `qrcode` SVG rendering (`InviteCard`), `SnackbarProvider`, `ScreenHeader`, `MemberShape`, and shared `TransferAction` across all three balance cards without duplicating permission or mutation logic.
- Rejected alternative: duplicating pending-request state and buttons in each of the three balance cards, or introducing `uqr` (already rejected by D2).

### Task 2A.6 results

Commit reference: `feat(web): add paying screen and settlement confirmation`. pnpm check passed (264 files, five workspace typechecks Done) and production web built with API_ORIGIN=http://localhost:4001. Exercised in two isolated Chrome browser contexts on localhost:3001 against current-source API 4001: Minh rejected Hùng's pending 150.000 đ request (`Đã báo lại là chưa nhận.` snackbar) and Hùng's S5 updated live via SSE `settlementRequests` to show `Trả`. Hùng opened `/pay`, saw 240×240 QR SVG (`viewBox="0 0 45 45"` = 37+8 with 4-module quiet zone), Vietcombank/0011001234567/NGUYEN VAN MINH/`SP Hung tra Minh`, clicked `Sao chép Số tài khoản` → `Đã sao chép`, and double-clicked `Tôi đã chuyển` → network log showed exactly one `POST .../settlement-requests` (201) and Hùng returned to S5 (`Đang chờ Minh xác nhận` + `Huỷ báo`) while Minh's S5 updated live via SSE to `Hùng báo đã chuyển 150.000 đ` (`Đã nhận` / `Chưa nhận`). Hùng (viewer) opening `Lan → Minh` saw no `Tôi đã chuyển` or `Ghi nhận luôn`; Minh (owner) saw both `Ghi nhận luôn` and `Tôi đã chuyển`. Minh clicked `Đã nhận` → `Đã ghi nhận 150.000 đ từ Hùng.` snackbar, Minh +300.000, Hùng 0 in both windows via SSE; revisiting settled Hùng→Minh `/pay` redirected to S5. Clearing Minh's payment methods showed `Minh chưa có thông tin nhận tiền.` with `Thêm thông tin` for Minh and without it for Hùng; Minh created and cancelled (`Huỷ báo`) a request cleanly.

Security review: relevant items 1/2/4/6/7/8 checked against full diff; query parameters and SSE resources validated with Zod, safe SVG rendering via `qrcode` matrix, no `dangerouslySetInnerHTML`/`eval`/browser secret storage, internal-only redirects, same-origin API requests, no new dependency. All new files under 150 lines; preexisting oversized `balances/page.tsx` retained with minimal additions (D11). Not verified: real banking-app scan/transfer and clipboard unavailability fallback in an insecure context.

## Stage gate 2A — passed

- `pnpm check` (264 files, 5 typechecks) and `pnpm build` (`API_ORIGIN=http://localhost:4001`) passed.
- Backed up DB (`/tmp/songphang-p2-pre-gate2a.dump`), reset `public`/`drizzle`, ran `pnpm db:migrate` and `pnpm db:seed`.
- Replayed all four Phase 1 suites on current-source API 4001 (`songphang-final-trip.py`, `songphang-replay-acceptance.py`, `songphang-gate1d-reader.py`, `songphang-final-permissions.py`): all exited 0.
- `GET /api/v1/features` returned 200 with all six capabilities `false`; disabled optional probes (`/receipts`, `/auth/apple`, `/telegram/webhook`) returned 404.
- Stage 2A acceptance: 2A.2 rows 1–3 (`200`, normalized phones `0901234567`/`0912345678`, `0987654321`), 600000 expense, 2A.4 row 1 QR byte-for-byte match (`000201...63046329`), 2A.3 rows 1/7/8 (`201 pending` → `200 confirmed` with Hùng balance `0` → `409 REQUEST_NOT_PENDING`).
- Stage 2A permission matrix: read `200/200/200/404/401`; write other payment methods `200/200/403/404/401`; write own as viewer `200`; create other-payer request `403/404/401`; confirm linked receiver `403/403/404/401`; confirm unlinked receiver viewer `403`, editor `200`; outsider 404 body matched random UUID 404 body.
- `pnpm db:check-balances`: `All groups balanced` after reset acceptance and after restoring `/tmp/songphang-p2-pre-gate2a.dump`.
- Not verified: whether real banking apps accept the generated VietQR code (owner manual check).

## Task 2B.1 — approach

- Files to create/modify: create `packages/db/src/schema-categories.ts`, `packages/db/src/categories.ts`, `packages/contract/src/category.ts`, `apps/api/src/services/categories.ts`, `apps/api/src/routes/categories.ts`, and a generated migration; modify `packages/db/drizzle.config.ts`, `packages/db/src/schema-transactions.ts`, `packages/db/src/transactions.ts`, `packages/db/src/index.ts`, `packages/contract/src/transaction.ts`, `packages/contract/src/error.ts`, `packages/contract/src/index.ts`, `apps/api/src/events/hub.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/services/transaction-input.ts`, `apps/api/src/services/transaction-changes.ts`, `apps/api/src/app.ts`, and `apps/web/src/lib/transaction-changes.ts` (if `categoryId` needs forwarding on edit).
- Approach: add `group_categories` with partial unique `(group_id, name_key) WHERE archived_at IS NULL` and `transactions.category_id` with mutual-exclusion check against `category`. Normalize `nameKey` in `apps/api` using `core`'s `foldVietnamese` so `packages/db` remains dependency-free. Lock the group before category mutations, enforce live limit 30 and duplicate name check, validate `categoryId` on transaction preview/create/edit (preserving existing archived categories on unrelated edits), and add `categories` SSE resource.
- Why simplest: reuses `foldVietnamese`, `lockGroup`, `runIdempotent`, and existing transaction validation/change tracking without adding dependencies to `db` or parallel transaction paths.
- Rejected alternative: normalizing category names in SQL extensions (`unaccent`) instead of existing `foldVietnamese`, which would couple uniqueness to Postgres extension state.

### Task 2B.1 results

Commit reference: `feat(api): add custom categories per group`. pnpm check passed (270 files, five workspace typechecks Done); generated and applied migration `0006_blue_oracle.sql`. Exercised all 2B.1 cases on API 4001: Lan created `Cà phê` (201); `ca phe` duplicate returned 409 `CATEGORY_EXISTS`; Hùng viewer create returned 403; Minh expense with `categoryId` returned 201 and echoed `categoryId`; `category`+`categoryId` both non-null returned 400; cross-group `categoryId` returned 400; DELETE archived (204), `GET /categories` showed `archived: true`, existing expense kept `categoryId` and still allowed editing amount/payers (200); new expense with archived `categoryId` returned 400; recreating `Cà phê` succeeded (201); 31st live category returned 422 `LIMIT_REACHED`; outsider returned 404; signed-out returned 401.

Security review: relevant items 1/2/4/5/6/8 checked against full diff; parameterized Drizzle queries, group-locked editor mutations, partial unique live index and exclusive category CHECK in migration `0006_blue_oracle.sql`, cross-group `categoryId` rejected, no secrets/new dependencies. All new files under 170 lines (D12). Not verified: none for this API task.

## Task 2B.2 — approach

- Files to create/modify: create `packages/core/src/dates.ts`, `packages/db/src/backfill-description-search.ts`, and a migration; modify `packages/core/src/index.ts`, `packages/db/package.json`, `packages/db/src/migrate.ts`, `packages/db/src/schema-transactions.ts`, `packages/db/src/transactions.ts`, `packages/db/src/index.ts`, `packages/contract/src/transaction.ts`, `apps/api/src/services/transactions.ts`, and `apps/api/src/services/transaction-changes.ts`.
- Approach: add `APP_TIME_ZONE` and `localDateRangeToUtc` (constant UTC+7 offset) in `core/dates.ts` with strict Gregorian calendar and 5-year range validation. Add `transactions.description_search` with an empty default for migration safety, populate it via SQL `lower(description)` and idempotent `backfillDescriptionSearch` using `foldVietnamese` inside `runMigrations`, write it on create/edit, and apply optional AND-combined filters (`q`, `memberId`, `category`, `categoryId`, `type`, `from`, `to`) to `listTransactionRows` with escaped `LIKE ... ESCAPE '\'`.
- Why simplest: reuses `foldVietnamese` and existing keyset cursor pagination without adding full-text search extensions or separate endpoints.
- Rejected alternative: computing Vietnam date boundaries in SQL for every row scan, which prevents index range filtering on `occurred_at`.

### Task 2B.2 results

Commit reference: `feat(api): add search and filters to the transaction list`. pnpm check passed (273 files, five workspace typechecks Done); migration `0007_gifted_white_tiger.sql` generated and applied cleanly, and `backfill-description-search.ts` ran idempotently (0 remaining rows after `runMigrations` backfill). Exercised all 2B.2 December-ledger cases on API 4001: `q=pho` → `[S6]`, `q=PHỞ` → `[S6]`, `q=%25` → `[]`, `q==sum` → `[S7]`, `memberId=Thu` → `[S7, S4, S3, S1]`, `type=transfer` → `[S5]`, `category=food` → `[S6, S1]`, `from=2026-12-31&to=2026-12-31` → `[S6]`, `from=2027-01-01` → `[S7]`, `to=2026-12-05` → `[S1]`, inverted range / 101-char `q` / invalid date `2026-13-01` → 400 `VALIDATION_FAILED` each, and `limit=2&memberId=Thu` keyset pagination → `[S7, S4]` then `[S3, S1]` then `nextCursor: null`.

Security review: relevant items 1/2/4/5/6/8 checked against full diff; query params validated with Zod (lengths, Gregorian dates, 5-year range), `LIKE` wildcards escaped and parameterized, `description_search` excluded from DTOs, viewer group-scoped query preserved, internal `@songphang/core` workspace link only (D13). Not verified: none.

## Task 2B.3 — approach

- Files to create/modify: create `packages/db/src/stats.ts`, `packages/contract/src/stats.ts`, `apps/api/src/services/stats.ts`, `apps/api/src/routes/stats.ts`; modify `packages/core/src/dates.ts`, `packages/core/src/index.ts`, `packages/db/src/index.ts`, `packages/contract/src/index.ts`, `apps/api/src/app.ts`.
- Approach: add `bucketFor` and `toVietnamDate` in `core/dates.ts`, `StatsQuery` and `StatsResponse` in `contract/stats.ts`, and `sumByCategory`, `sumByMember`, `sumByBucket`, and `findCountedDateBounds` in `db/stats.ts`. Inside one repeatable-read read-only transaction, resolve effective `from`/`to` bounds (defaulting missing bounds from counted Vietnam dates or today), compute `bucket` via `bucketFor`, and aggregate expenses (+) minus income (−) across SQL `bigint` sums while ignoring transfers and soft-deleted rows.
- Why simplest: reuses `localDateRangeToUtc` and runs all money sums directly in SQL on `bigint` with a CTE/subquery for `date_trunc(..., occurred_at AT TIME ZONE $tz)`, avoiding JS money sums and parameter-grouping mismatches.
- Rejected alternative: aggregating in TypeScript after fetching all rows, which violates spec 7.2's SQL `bigint` rule and scales poorly on 500+ transactions.

### Task 2B.3 results

Commit reference: `feat(api): add spending statistics`. pnpm check passed (277 files, five workspace typechecks Done). Exercised all 2B.3 December-ledger cases on API 4001: `from=2026-12-01&to=2026-12-31` → `bucket: day`, `total: 1999999`, `byCategory` (`lodging: 1100000`, `food: 699999`, `transport: 200000`), `byMember` paid (`1700000/200000/99999/0`) and share (`558333/558333/458333/425000`), `byBucket` (`12-05: 600000`, `12-06: 100000`, `12-20: 1200000`, `12-31: 99999`), all four lists summing to `1999999`. Unbounded query → `total: 2009999`, 5th bucket `2027-01-01: 10000`, uncategorized `10000`; `2026-09-01..2026-12-31` → `week` (`11-30: 700000`, `12-14: 1200000`, `12-28: 99999`); `2026-01-01..2026-12-31` → `month` (`2026-12-01: 1999999`); delete S4 → `799999`, restore → `1999999`; viewer 200, outsider 404, signed-out 401, inverted dates 400.

Security review: relevant items 1/2/4/5/6/8 checked against full diff; parameterized SQL `bigint` aggregates inside a single repeatable-read read-only snapshot, viewer role + `group_id` filters, Zod calendar/range checks, no new dependencies. Not verified: none for this API task.

## Task 2B.4 — approach

- Files to create/modify: create `apps/web/src/lib/stats.ts`, `apps/web/src/lib/categories.ts`, `apps/web/src/components/stats/BarRow.tsx`, `apps/web/src/components/stats/PeriodChips.tsx`, `apps/web/src/app/g/[groupId]/stats/page.tsx`, `apps/web/src/components/feed/FilterSheet.tsx`, `apps/web/src/components/feed/FilterChips.tsx`, and `apps/web/src/components/feed/StreamSearchBar.tsx`; modify `packages/core/src/dates.ts`, `packages/core/src/index.ts`, `apps/web/src/app/globals.css`, `apps/web/src/lib/transactions.ts`, `apps/web/src/lib/use-group-events.ts`, `apps/web/src/components/feed/ExpenseStream.tsx`, `apps/web/src/app/g/[groupId]/page.tsx`, and `apps/web/src/messages/vi.ts`.
- Approach: add `currentMonthRange` and `previousMonthRange` in `core/dates.ts`. Build S16 (`/g/{id}/stats`) with `PeriodChips`, `BarRow` horizontal bars (`max(amount, 0) / max` CSS percentage), dual bars for `Theo người`, and tappable rows linking to S4 with URL query filters. Add URL-synced filter parsing (`?q=&member=&category=&categoryId=&type=&from=&to=`), debounced search + `<dialog>` `FilterSheet` (revealed at top of stream or while active) + `FilterChips`, hiding `BalanceBlock` when filters are active while keeping `EntryBar`.
- Why simplest: keeps filter state in URL `searchParams` so reload/back work without extra client stores, and reuses `BalanceBars`'s plain CSS bar pattern and native `<dialog>` with `overscroll-behavior: contain`.
- Rejected alternative: client-side filtering of loaded feed pages, which would miss older unpaginated rows and ignore backend search normalization.

### Task 2B.4 results

Commit reference: `feat(web): add statistics screen, search and filters`. pnpm check passed (287 files, five workspace typechecks Done) and production web built with API_ORIGIN=http://localhost:4001. Exercised in Chrome on localhost:3001 with the December ledger group: S4 shows `Tổng chuyến đi` shortcut opening S16 (`Tiền đi đâu`), `Tất cả` showed `2.009.999 đ`, `Tháng này` showed `0 đ` (`Chưa có khoản chi nào trong khoảng này`), `Tuỳ chọn` (`2026-12-01`..`2026-12-31`) showed `1.999.999 đ` with exact `Theo danh mục` (`Chỗ ở 1.100.000 đ`, `Ăn uống 699.999 đ`, `Đi lại 200.000 đ`), `Theo người` (`Minh · đã trả 1.700.000 đ · phần mình 558.333 đ`, etc.), and `Theo thời gian` bars. Tapping `Ăn uống` navigated to S4 `?category=food&from=2026-12-01&to=2026-12-31` showing `Lẩu` and `Phở` with removable filter chips, `BalanceBlock` hidden, and `EntryBar` retained. Reloading S4 preserved filters; typing `pho` filtered to `Phở`; typing `khongco` showed `Không có khoản nào khớp`; opening `Lọc` rendered a native modal `<dialog>` with `Người`/`Danh mục`/`Loại`/date inputs, and `Xoá lọc` restored the full stream and `BalanceBlock`.

Security review: relevant items 1/2/4/6/7/8 checked against full diff; URL filter params validated with Zod (`uuid`, `TransactionCategory`, `CalendarDate`, 5-year check) before API requests, no `dangerouslySetInnerHTML`/`eval`/secret browser storage, internal-only navigation links, no new dependencies. `FilterSheet.tsx` refactored with `PillSection` under 190 lines; preexisting `app/g/[groupId]/page.tsx` kept cohesive. Not verified: automated fast-4G timing (scheduled in 2D.3).

## Task 2B.5 — approach

- Files to create/modify: create `apps/api/src/csv.ts`, `apps/api/src/csv-labels.ts`, `apps/api/src/services/export.ts`, and `apps/api/src/routes/export.ts`; modify `packages/core/src/dates.ts`, `packages/core/src/index.ts`, `packages/db/src/transactions.ts`, `apps/api/src/app.ts`, `apps/web/src/messages/vi.ts`, and `apps/web/src/app/g/[groupId]/stats/page.tsx`.
- Approach: add `formatVietnamDateTime` in `core/dates.ts`, add `csvCell` (formula-prefixing `=`, `+`, `-`, `@`, tab, CR before RFC 4180 quoting) in `csv.ts`, and map CSV headers/types/categories directly from `vi.ts` in `csv-labels.ts` per D3 without duplicating Vietnamese literals. Load members, categories, live transactions (oldest first), payers, and shares inside one repeatable-read read-only transaction, serialize UTF-8 with BOM (`\uFEFF`) and CRLF lines, guard with `requireUser`, `requireGroupRole("viewer")`, and a 6/min rate limit, and add the `Xuất CSV` `<a download>` link on S16.
- Why simplest: builds CSV in memory for ≤10,000 live transactions using existing `vi.ts` labels, `core` Vietnam timezone offset, and `rateLimiter`.
- Rejected alternative: duplicating Vietnamese column/category strings in `apps/api` (violates D3) or streaming chunks with complex backpressure before any 10k-row memory issue exists.

### Task 2B.5 results

Commit reference: `feat(api): add CSV export of a group`. pnpm check passed (291 files, five workspace typechecks Done). Exercised all 2B.5 December-ledger and edge cases on API 4001: BOM `EF BB BF`, CRLF endings, header `Ngày,Loại,Mô tả,Danh mục,Tổng tiền,Người trả,Minh,Lan,Hùng,Thu`, S1 `2026-12-05 12:30,Chi tiêu,Lẩu,Ăn uống,600000,Minh 600000,150000,150000,150000,150000`, S5 `Chuyển khoản` (`50000` under Minh, empty elsewhere), S6 `2026-12-31 23:30` (`33333` under Minh/Lan/Hùng, empty under Thu), S7 `2027-01-01 00:10` with `'=SUM(A1)` formula prefix, `Cơm, "gà"` → `"Cơm, ""gà"""`, member `@home` → `'@home`, 7th export within 1 minute returned `429`, outsider `404`, signed-out `401`. S16 page renders `<a download>` for `Xuất CSV`.

Security review: relevant items 1/2/4/5/6/7/8 checked against full diff; formula-prefix neutralization and RFC 4180 quoting in `csvCell`, viewer auth + 6/min per-user rate limit, `Cache-Control: no-store`, repeatable-read snapshot, D3 `vi.ts` label reuse, no new dependencies. Not verified: opening the downloaded `.csv` in Excel/Google Sheets (owner manual check).


## Task 2B.6 — approach

- Files to create/modify: create `apps/web/src/components/settings/CategoryList.tsx`; modify `apps/web/src/messages/vi.ts`, `apps/web/src/lib/categories.ts`, `apps/web/src/app/g/[groupId]/settings/page.tsx`, `apps/web/src/components/expense-form/{use-expense-form.ts,CategoryPicker.tsx,ParticipantFields.tsx}`, `apps/web/src/components/feed/{ExpenseRow.tsx,ExpenseStream.tsx}`, and `apps/web/src/app/g/[groupId]/page.tsx`.
- Approach: add Spec 9.7 category strings to `vi.ts`, add category create/update/archive mutations in `lib/categories.ts` (invalidating categories, transactions, and stats queries), and build `CategoryList` with inline rename/color/archive and add form mapping `CATEGORY_EXISTS`/`LIMIT_REACHED` errors. Render `CategoryList` in S11 settings and inside a modal `<dialog>` triggered by `Thêm danh mục` at the end of `CategoryPicker`. Keep built-in `category` and custom `categoryId` mutually exclusive in `useExpenseForm`, retain an archived selected `categoryId` on edit until changed, and display category labels (with filled color circles for custom categories) in `ExpenseRow`.
- Why simplest: reuses one `CategoryList` component for both S11 (owner) and S6/S7 picker modal (editors), using native `<dialog>` and existing TanStack Query/member-editor patterns without inventing a separate category-management route.
- Rejected alternative: inline form inside `CategoryPicker` or a dedicated `/categories` route, which would add navigation friction or clutter the expense form.


### Task 2B.6 results

Commit reference: `feat(web): add custom categories`. pnpm check passed (293 files, five workspace typechecks Done) and production web built with `API_ORIGIN=http://localhost:4001`. Exercised in Chrome on `http://localhost:3001` (`Phase 2 exercise` group): S11 `Danh mục của nhóm` created `Cà phê sáng` (coral), normalized-duplicate `ca phe sang` showed alert `Nhóm đã có danh mục này.`, renamed/recolored to `Trà đá` (sky), selected `Trà đá` on new expense `Nước mía` (`40.000`) which displayed `Trà đá` with color dot in the stream, opened `+ Thêm danh mục` modal `<dialog>` on S6 to hide `Trà đá` (`Ẩn danh mục`), confirmed `Trà đá` disappeared from `CategoryPicker` for new expenses while `Nước mía` retained `Trà đá` in the stream and `Trà đá (đã ẩn)` pressed in edit mode, and confirmed 31st category creation in S11 showed `Nhóm đã có 30 danh mục.`.

Security review: relevant items 1/2/4/6/7/8 checked against full diff; `CategoryName`/`MemberColorCode` bounded in UI and contract, API `CATEGORY_EXISTS`/`LIMIT_REACHED`/`403` errors mapped without exposing internal details, modal `<dialog>` uses native `showModal()`/`closedby="any"`/`overscroll-behavior: contain`, no `dangerouslySetInnerHTML`/`eval`/new libraries. `CategoryList.tsx` and `CategoryRow.tsx` kept cohesive under 150 lines each. Not verified: none for 2B.6.


## Stage gate 2B — passed

- `pnpm check` (293 files, 5 typechecks) and `API_ORIGIN=http://localhost:4001 pnpm build` passed.
- Backed up DB (`/tmp/songphang-p2-pre-gate2b.dump`), reset `public`/`drizzle`, ran `pnpm db:migrate` and `pnpm db:seed`.
- Replayed all four Phase 1 suites (`songphang-final-trip.py`, `songphang-replay-acceptance.py`, `songphang-gate1d-reader.py`, `songphang-final-permissions.py`) and Stage Gate 2A (`songphang-p2-gate2a.py`, including `GET /api/v1/features` all-false check and 404 probes) on current-source API 4001: all passed.
- Stage 2B acceptance (`/tmp/songphang-p2-gate2b.py`): December ledger S1–S7 created; 2B.3 first table (`from=2026-12-01&to=2026-12-31`, `bucket: day`, `total: 1999999`, `byCategory`, `byMember` paid/share, `byBucket`) passed; 2B.2 rows 1/5/8 (`q=pho`, `memberId=Thu`, `from=2026-12-31&to=2026-12-31`) passed; 2B.5 rows 1/2/6 (`EF BB BF` BOM, header, row S6, row S7 `'=SUM(A1)`) passed.
- Stage 2B permission matrix: read `/categories`, `/stats`, `/export.csv` (`200/200/200/404/401`); write `/categories` (`201/201/403/404/401`).
- `pnpm db:check-balances`: `All groups balanced` after reset acceptance and after restoring `/tmp/songphang-p2-pre-gate2b.dump`.
- Not verified: opening the exported `.csv` in Excel/Google Sheets (owner manual check).


## Task 2C.1 — approach

- Files to create/modify: create a Drizzle migration (`drizzle/0008_*.sql`); modify `packages/db/src/schema-groups.ts`, `packages/db/src/members.ts`, `packages/db/src/check-balances.ts`, and `apps/api/src/services/{invites,groups,members,quick-entry}.ts`.
- Approach: add `kind` (`'person' | 'fund'`) and self-referencing `fund_holder_member_id` (`ON DELETE SET NULL`) to `members`, expand `shape`/`color` checks to permit `'fund'`/`'sun'`, add `CHECK (kind = 'fund' OR fund_holder_member_id IS NULL)` and partial unique index on `(group_id) WHERE kind = 'fund'`. In the new migration, replace `assert_transaction_integrity(uuid)` to forbid fund members in `transaction_shares` for `'expense'` and `'income'` transactions while still permitting `'transfer'`, and add a `BEFORE INSERT OR UPDATE` trigger on `group_users` forbidding linking to a fund. Add `listPeople` and `findFund` in `db/members.ts`, update `checkBalances` to detect any fund shares in expense/income rows, and switch user-facing people callers (`invites`, `groups` list counts/avatars, `quick-entry`) and `claimableMember` to require `person`. (`suggestMinimizedSettlements` / `netPairwiseDebts` in `packages/core/src/settlements.ts` already work unchanged with an extra zero-sum participant.)
- Why simplest: leverages the existing deferred transaction integrity trigger and `MEMBER_COLUMNS` projection without rewriting settlement arithmetic or creating a separate fund table.
- Rejected alternative: a separate `group_funds` table instead of a `members` row, which would require parallel payer/share foreign keys across transactions, balances, and integrity triggers.


### Task 2C.1 results

Commit reference: `feat(db): add fund members and their integrity rules`. pnpm check passed (294 files, five workspace typechecks Done) and migration `0008_youthful_preak.sql` applied cleanly. Exercised all five `psql` constraint/trigger rows on rolled-back/cleaned test transactions: second fund in group → `members_group_fund_unique` unique violation; `transaction_shares` on fund for an `expense` with matching totals → `assert_transaction_integrity` raised `fund member cannot appear in transaction shares` at `COMMIT`; `transfer` with share row on fund → `COMMIT` succeeded; `group_users.member_id` pointing to fund → `check_group_user_member_is_person` trigger raised `group user cannot link to a fund member`; `person` with `fund_holder_member_id` set → `members_fund_holder_kind_check` check violation. `pnpm db:check-balances` → `All groups balanced`.

Security review: relevant items 1/2/3/4/5/8 checked against full diff; DB triggers/constraints enforce fund share and `group_users` invariants even outside app code, `invites.ts` `claimableMember` and `chooseMember` reject non-person members with 400, `listPeople` separates user-facing counts/previews from `fund`, no secrets/new dependencies. Not verified: runtime API `POST /fund` (pending 2C.2).