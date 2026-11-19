# Phase 4 — R11-A & R11-B Completion: Child-Level Browser Evidence, Expanded Money Matrix, and Final-SHA Replay Protocol

> **Supersedes:** [r11-completion.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/r11-completion.md) (retained intact as historical evidence).
> **Addresses:** [review-r11-final.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/review-r11-final.md) — **R11-A [P2]** and **R11-B [P2]** only (core-role permission matrix `353/353`, R9, and R10 retain their prior advisor PASS).

## 1. Documentation Corrections to Prior R11 Inventory

1. **Recomputed registered route breakdown (99 total Hono routes):**
   - **63** group-ID routes (`/api/v1/groups/:groupId*`, previously misstated as 62 in `r11-completion.md`).
   - **16** personal routes (`/api/v1/me*` and `/api/v1/groups`).
   - **17** public/auth/token routes (`/api/v1/health`, `/api/v1/features`, `/api/v1/openapi.json`, `/api/v1/auth/*`, `/api/v1/invites/*`, `/api/v1/notifications/unsubscribe`).
   - **2** dev-only routes (`/api/v1/dev/users`, `/api/v1/dev/login`).
   - **1** Telegram webhook route (`/api/v1/bots/telegram/webhook`).
   - `63 + 16 + 17 + 2 + 1 = 99` routes; `353/353` permission cases cover every applicable group role (`owner`/`editor`/`viewer`/`outsider`) with `0` missing group-role combinations.
2. **Corrected PM case ID ranges (unchanged IDs, corrected summary references):**
   - `POST /api/v1/groups/:groupId/reminders`: `PM-258`–`PM-268` (11 cases; previously cited as `PM-257`–`PM-267`).
   - `POST /api/v1/groups/:groupId/transactions/:id/restore`: `PM-214`–`PM-220` (7 cases; previously cited as `PM-214`–`PM-222`).
   - `POST /api/v1/groups/:groupId/leave`: `PM-339`–`PM-343` (5 cases; previously cited as `PM-337`–`PM-341`).
3. **Prior browser artifact filename:** the prior `93e01e9` replay stored browser results in `09_browser.json` (not `08_browser.json`). This run enforces consistent filenames across `r11-ab-completion.md`, `manifest.json`, and the external `final-replay-<FULL_SHA>/` directory.

## 2. Narrow Product Fix From Reproduced Failure

- **Reproduced defect (`BR-14.4` — S11 mobile horizontal overflow at `375×812`):** On `/g/{groupId}/settings` at `375×812`, `document.documentElement.scrollWidth` measured `838` against `clientWidth: 375` (`overflows: true`) because `AmountField` (`apps/web/src/components/expense-form/AmountField.tsx`) rendered an `<input>` with default HTML `size=20` at `52px` font size inside CSS grid cards (`ApprovalCard`, `BudgetCard`) without `size={1}` or `min-w-0 w-full`.
- **Narrow fix (`e479bd2`):** Added `min-w-0 w-full` to the `AmountField` wrapper and `size={1}` + `w-full` to `<input>`. Verified at `375×812`: `scrollWidth: 375 === clientWidth: 375` (`overflows: false`), `pnpm check` and `pnpm build` clean, security review clean.

## 3. Isolated Execution Environment and Final-SHA Replay Protocol

- **Disposable database:** `songphang_phase4_r11ab_20261119` (verified via `SELECT current_database()` before every reset; never modifying `songphang` or any prior agent/reviewer database; never running `docker compose down -v`).
- **Isolated uploads & ports:** `STORAGE_DIR=/Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/r11_ab_uploads`, API `4080` (standalone suites `4081`–`4088`), Web `3080`.
- **Durable local exercise sources (outside `/tmp` and outside repo):** `/Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/r11_ab_exercises/` (original `/tmp/r11_gates/` preserved untouched).
- **Final-SHA output directory (outside repo):** `/Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/final-replay-<FULL_SHA>/` containing:
  - `manifest.json` (full tested SHA, clean tracked worktree status, startup/build provenance with PIDs/ports/timestamps, per-family required/applicable/executed/passed/failed/not-run counts computed strictly from child records, browser parent & child counts separately, and all artifact links)
  - `00_static.log` (`pnpm check`, `pnpm build`, `git diff --check`)
  - `01_db_reset.log` (DB verification & reset provenance)
  - `02_permissions.json` (`353` cases, `99` routes, `63` group-ID routes)
  - `03_4d1_money_r11ab.json` (`65` leaf/standalone cases + `2` parent rollups = `67` records)
  - `04_87_samples.json` (`87` quick-entry samples + over-300 refusal)
  - `05_earlier_phases.json` (`15` representative earlier-phase checks, labeled representative)
  - `06_phase4_stages.json` (7 suites including exact 13-row 4D.2 table + R1–R10 regressions)
  - `07_capabilities_prod.json` (capability-off & production startup refusals)
  - `08_perf_1000.json` (1,000-notification perf + query plan + membership-loss privacy)
  - `09_browser_r11ab.json` (all `61` browser child records + `16` computed parent rollups, timestamped action logs, DOM/a11y/focus/contrast/overflow/network/console observations)
  - `screenshots/` (non-empty, sanitized PNG screenshots with sensitive tokens/codes masked before capture)
  - `provenance.log` (API/Web/Worker startup logs, PIDs, ports, timestamps, and final `pnpm db:check-balances`)

## 4. R11-B — Expanded Approval-Sensitive Money Matrix (`M4D-001`–`M4D-059`, plus `M4D-030.1`–`M4D-031.4`)

All original 31 cases (`M4D-001`–`M4D-031`) and the unchanged 13-row 4D.2 API table are preserved. Every R11-B omission is mapped to explicit executable cases with pre-derived arithmetic expectations:

| Review Omission | Added Case IDs | Fixture & Preconditions | Expected Result (Pre-Derived) | Pre-Freeze Status |
|---|---|---|---|---|
| Items-split pending -> rejected -> edit back to pending -> approved | `M4D-030.1`–`M4D-030.4` (rolled up to `M4D-030`) | Fresh group `M3` (threshold `1,000,000`, budget `2,500,000`, counted baseline `300,000` paid by Minh equal 3 -> Minh `+200k`, Lan `-100k`, Hùng `-100k`). Lan creates `1,100,000` items-split (`Steak 600k` Minh, `Wine 500k` Lan). | Pending, rejected (with note `"Thiếu hóa đơn món"`), and PATCH-reopened pending each retain `items.length=2` and keep official balances `{Minh:200k,Lan:-100k,Hung:-100k}`, budget spent `300,000`, stats `300,000`. Approved adds exact contribution: `{Minh:-400k,Lan:500k,Hung:-100k}`, suggestions `Minh->Lan 400k, Hùng->Lan 100k`, budget spent `1,400,000`, stats `1,400,000`. | PASS (4/4) |
| Fake receipt scan + save pending -> rejected -> edit back to pending -> approved | `M4D-031.1`–`M4D-031.4` (rolled up to `M4D-031`) | Same `M3` group after `M4D-030.4` (`spent=1,400,000`). Upload 1×1 PNG -> `POST /receipt-scans` -> `runReadReceiptJob` (`AI_PROVIDER=fake`) -> Lan saves `1,050,000` transport expense equal 3 (`350k` each) with `attachmentIds:[attId]`. | `scan.status="done"`. Pending, rejected (`"Ảnh bị mờ"`), and PATCH-reopened pending each retain `attachments[0].id===attId` and keep balances `{Minh:-400k,Lan:500k,Hung:-100k}`, spent `1,400,000`, stats `1,400,000`. Approved yields `{Minh:-750k,Lan:1200k,Hung:-450k}`, suggestions `Minh->Lan 750k, Hùng->Lan 450k`, budget spent `2,450,000`, stats `2,450,000`. | PASS (4/4) |
| Settlement/payment paths under pending/rejected/approved ledger | `M4D-032`–`M4D-036` | Three isolated M1-clone groups (`M4S Pending`, `M4S Rejected`, `M4S Approved`; threshold `1,000,000`, `BaseFood 300k`, `BaseTrans 120k`, `LargeHotel 1.2M`). | Pending (`M4D-032`/`033`): `Minh->Lan` absent; viewer payer `Hùng->Minh 160k` created `201`, editor/payer confirm `403`, owner receiver confirm `200` -> `{Minh:40k,Lan:-40k,Hung:0}`; viewer other-payer `403`, unknown member `400`, duplicate pending `409`, cancel `200`. Rejected (`M4D-034`): `Minh->Lan` absent; reject `Lan->Minh 40k` leaves `{Minh:200k,Lan:-40k,Hung:-160k}`; recreate & confirm -> `{Minh:160k,Lan:0,Hung:-160k}`. Approved (`M4D-035`/`036`): `Minh->Lan 200k` now present; viewer confirm `403`, linked receiver `Lan` confirms `200` -> `{Minh:0,Lan:560k,Hung:-560k}`; editor confirms for unclaimed guest `Khách` (`200`, guest balance `0`). | PASS (5/5) |
| Fund refund under enabled threshold | `M4D-037`–`M4D-038` | Fresh group `M5` (threshold `1,000,000`, fund `Quỹ Hoàn`, chat `-1005333`, counted contributions Minh `1.8M` + Lan `1.2M` = `3.0M` cash). | `M4D-037`: Non-owner `Lan` posts transfer `fund->Minh 1,200,000` (`>= threshold`) -> `201`, `approval.status="none"`, `warnings=[]`, `fund.cash=1,800,000`, contributions `{Minh:600k,Lan:1.2M}`, `/sodu` contains `Quỹ còn 1.800.000 đ`. `M4D-038`: Transfer preview is N/A per `PreviewTransactionRequest = SplitTransactionRequest & { transactionId? }` (`400`), real transfer `fund->Lan 2,000,000` returns `201`, `approval.status="none"`, `warnings=["FUND_OVERDRAWN"]`, `cash=-200,000`. | PASS (2/2) |
| Create/edit/preview warning parity (budget & fund-overdraw) | `M4D-039`–`M4D-059` | Independent warning groups (`W1`–`W19`) covering owner/editor, threshold enabled (`<`, `=`, `>`) & disabled (`null`), create & edit replacement of counted (`none`, `approved`) and uncounted (`pending`, `rejected`), fund, items-split, and fake-receipt paths. | Every preview leaves official spent/cash unchanged (`nonMut=true`) and matches real create/edit warnings exactly (`[]`, `["BUDGET_NEAR"]`, `["BUDGET_OVER"]`, `["FUND_OVERDRAWN"]`, `["FUND_OVERDRAWN","BUDGET_NEAR"]`). Replacement of counted (`none`/`approved`) excludes old amount exactly once; replacement of uncounted (`pending`/`rejected`) subtracts `0`. | PASS (21/21) |

- **Pre-freeze R11-B totals (`gate_4d1_money_r11ab.mts`):** `65` leaf/standalone cases (`65/65` PASS, `0` FAIL, `0` NOT RUN) + `2` parent rollups (`M4D-030`, `M4D-031`, both PASS from 4/4 children each). `pnpm db:check-balances` returned `All groups balanced` at every checkpoint.
- **Legitimate N/A note:** `POST /api/v1/groups/{groupId}/transactions/preview` accepts `PreviewTransactionRequest` (`SplitTransactionRequest` only: `expense | income`), not `transfer` (`packages/contract/src/transaction.ts:254-259`), verified directly in `M4D-038` (`HTTP 400`).

## 5. R11-A — Complete Child-Level Browser Gate Inventory (`BR-01`–`BR-16`, 61 Children)

All 61 child cases below are executed strictly **after freezing the final HEAD SHA** on freshly built servers (`API 4080`, `Web 3080`, `songphang_phase4_r11ab_20261119`) using isolated Chrome contexts (two signed-in contexts + one signed-out context). A parent `BR-xx` passes only if every applicable child `BR-xx.y` executes and passes on that frozen SHA.

| Parent | Child IDs | Review Omissions Closed | Required Evidence per Child |
|---|---|---|---|
| `BR-01` | `BR-01.1`–`BR-01.3` | Live viewer comment, `<script>alert(1)</script>` literal rendering (`0` script nodes), author delete + owner SSE | Timestamped actions, DOM/script count, screenshot |
| `BR-02` | `BR-02.1`–`BR-02.3` | Deleted-state viewer comment + owner SSE, deleted banner stays, **owner restore preserves exact comment IDs/text & clears deleted banner** | Timestamped actions, comment IDs before/after restore, screenshot |
| `BR-03` | `BR-03.1`–`BR-03.4` | Viewer opens dispute -> owner SSE; **non-opener editor UI hidden + server `403`**; **opener resolves + live clear**; **owner resolves reopened dispute + live clear** | Actions, HTTP 403 observation, live SSE clearing, screenshot |
| `BR-04` | `BR-04.1`–`BR-04.5` | **Exact official & live UI balances before/after approve**; **editor edit returns approved tx to pending & excludes from balances**; **reject with known note displays exact note & tag in both live contexts** | Pre/post balance tables, persisted statuses, exact note text, screenshots |
| `BR-05` | `BR-05.1`–`BR-05.5` | Manual + **real local `auto-reminders` worker -> `pg_notify` SSE** on already-open bell without reload/focus; **open single notification marks read, decrements count & navigates**; **S19 pagination across >=35 distinct rows (no dup/missing)**; mark all read | Before/after counts, page 1/2 ID sets, navigation URL, screenshots |
| `BR-06` | `BR-06.1`–`BR-06.6` | Unlinked debtor hidden; **owner/editor/linked-receiver-viewer/non-receiver-viewer visibility**; individual send; cooldown message/time; **remind-all actual count**; **unchanged official balances before/after** | Role visibility matrix, snackbar text, pre/post balances, screenshot |
| `BR-07` | `BR-07.1`–`BR-07.6` | **All `off`/`3`/`7`/`14` reloaded & read back**; **threshold enable/change/disable + invalid input (no unintended mutation)**; **Telegram code generate/copy/unlink** (masked secret); **non-owner UI refusal + server `403`** | Reloaded values, clipboard observation/status, 403 status, masked screenshot |
| `BR-08` | `BR-08.1`–`BR-08.3` | **Both `emailImmediate` and `emailDigest` toggled independently & persisted across reload**; Telegram identity linked/unlinked persisted | Persisted API/UI states across reload, screenshot |
| `BR-09` | `BR-09.1`–`BR-09.4` | Legacy `?code=` refused; signed-out `/login?next=%2Flink%2Ftelegram`; two-sided pairing inactive before web confirm (`0` identities); final web confirm activates & unlink works | Identity counts before/after, masked screenshot |
| `BR-10` | `BR-10.1`–`BR-10.3` | Signed-out valid GET + **separate authorized verification that intended account has both settings `false` and another account unchanged**; invalid GET; separate no-Origin/form-POST `204` API case | Intended vs control account settings, HTTP 204, screenshot |
| `BR-11` | `BR-11.1`–`BR-11.4` | **Real `Tab`/`Shift+Tab` focused element log across S20/S19/S11/pairing**; **real `Enter`/`Space` activation**; **real `Escape` closing dispute & reject dialogs with focus returning to trigger**; rendered visible focus outline | Focused element sequences, trigger focus equality, outline styles, screenshot |
| `BR-12` | `BR-12.1`–`BR-12.2` | Bell `aria-label` (`{count} thông báo chưa đọc`), bell & primary controls `>=44px` | Bounding boxes (`width`, `height`), `aria-label` |
| `BR-13` | `BR-13.1`–`BR-13.3` | **Rendered `color`/`backgroundColor`/`opacity`/backdrop RGB inputs + computed WCAG 2.1 contrast calculation (`>=4.5:1`)** for `DisputeBlock`, `chờ duyệt`, `không được duyệt` | Raw CSS RGB/opacity inputs, exact luminance & ratio formula output, screenshots |
| `BR-14` | `BR-14.1`–`BR-14.6` | **`375×812` viewport `scrollWidth <= clientWidth` & `0` console errors across S20, S19, S5, S11, S13, `/link/telegram`** | Exact `innerWidth`/`clientWidth`/`scrollWidth`, scoped console logs, 6 screenshots |
| `BR-15` | `BR-15.1`–`BR-15.2` | Offline S13 toggle fails & reverts cleanly; back online succeeds & persists | Offline/online network & switch states, screenshot |
| `BR-16` | `BR-16.1`–`BR-16.2` | **Open private tx on S20 first, remove member from owner context, observe S20 stale-content refusal (`404`/not-found, 0 private data)**; S19 hides removed group | S20/S19 post-removal DOM & status, screenshot |

## 6. Reproducible Commands (Sanitized)

```bash
# 1. Reset disposable database (verifies current_database() === songphang_phase4_r11ab_20261119)
/Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/r11_ab_exercises/reset_db.sh

# 2. Static & production build checks
pnpm check
API_ORIGIN=http://127.0.0.1:4080 pnpm build
git diff --check main..HEAD

# 3. Backend gates (each preceded by reset_db.sh as recorded in manifest.json)
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_permissions_r11.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_4d1_money_r11ab.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_87_samples.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_earlier_phases.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_phase4_stages.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_capabilities_prod.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/gate_perf_1000.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/exercise_r9.mts
pnpm --filter @songphang/api exec tsx .../r11_ab_exercises/exercise_r10.mts
DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_r11ab_20261119" pnpm db:check-balances
```
