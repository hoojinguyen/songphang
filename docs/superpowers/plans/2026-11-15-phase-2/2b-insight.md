# Phase 2 — Stage 2B: Insight

> Part of the phase 2 plan. Read `00-overview.md` first.

**Stage goal:** a group sees where its money went, finds any transaction, labels spending its own way, and takes its data out.

**Spec:** sections 7, 9.5–9.7, 10.

## Decisions for this stage

1. `byBucket` and `byCategory` list only entries with at least one counted transaction; an entry's amount may be negative (refunds exceeding spending).
2. An unknown or archived `categoryId` on create answers 400 `VALIDATION_FAILED`; an archived category stays on transactions that already have it.
3. `from` later than `to` answers 400. A range is at most 5 years.
4. The CSV's category and type labels live in `apps/api/src/csv-labels.ts` and equal the web's labels for the same codes character for character.

## The December ledger

Used by 2B.3, 2B.4, 2B.5 and the gate. Fresh group Minh, Lan, Hùng, Thu; Minh signed in.

| # | Type | Description | Amount | Payer | Split | Category | `occurredAt` (UTC) | Vietnam time |
|---|---|---|---|---|---|---|---|---|
| S1 | expense | Lẩu | 600000 | Minh | equal, all four | `food` | `2026-12-05T05:30:00Z` | 05/12 12:30 |
| S2 | expense | Taxi | 200000 | Lan | equal, Minh and Lan | `transport` | `2026-12-06T03:00:00Z` | 06/12 10:00 |
| S3 | income | Hoàn cọc | 100000 | received by Minh | equal, all four | `lodging` | `2026-12-06T04:00:00Z` | 06/12 11:00 |
| S4 | expense | Khách sạn | 1200000 | Minh | equal, all four | `lodging` | `2026-12-20T02:00:00Z` | 20/12 09:00 |
| S5 | transfer | — | 50000 | Lan → Minh | — | — | `2026-12-21T02:00:00Z` | 21/12 09:00 |
| S6 | expense | Phở | 99999 | Hùng | equal, Minh, Lan, Hùng | `food` | `2026-12-31T16:30:00Z` | 31/12 23:30 |
| S7 | expense | `=SUM(A1)` | 10000 | Thu | equal, Thu only | none | `2026-12-31T17:10:00Z` | 01/01 00:10 |

---

### Task 2B.1: API — custom categories

**Files:**
- Create: `packages/db/src/schema-categories.ts`, `packages/db/src/categories.ts`, `packages/contract/src/category.ts`, `apps/api/src/services/categories.ts`, `apps/api/src/routes/categories.ts`, a migration
- Modify: `packages/db/src/schema-transactions.ts`, `packages/db/src/transactions.ts`, `packages/contract/src/transaction.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/app.ts`

**Interfaces — produces:**
- Table `group_categories` as spec 7.1, plus `name_key text NOT NULL` (the normalised name) with `UNIQUE (group_id, name_key) WHERE archived_at IS NULL`.
- `transactions.category_id` with the `CHECK` of spec 7.1.
- `CategoryDto`: `{ id, name, color, archived: boolean }`. `color` is one of the member color codes.
- `GET /groups/{groupId}/categories` (viewer; includes archived), `POST` (editor; `{ name, color }`; `Idempotency-Key`), `PATCH …/{id}` (editor; `{ name?, color? }`), `DELETE …/{id}` (editor; archives; 204).
- Errors: duplicate live name → 409 `CATEGORY_EXISTS`; 31st live category → 422 `LIMIT_REACHED`.
- Transaction request bodies gain `categoryId: uuid | null` (optional, default null); both `category` and `categoryId` non-null → 400. `TransactionDto` gains `categoryId`.
- SSE resource `categories`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Caller | Request | Expected |
|---|---|---|
| Lan | create `Cà phê`, `mint` | 201 |
| Lan | create `ca phe`, `sky` | 409 `CATEGORY_EXISTS` |
| Hùng | create `Xăng` | 403 |
| Minh | expense with `categoryId` = it | 201; echoed |
| Minh | expense with `category: "food"` and that `categoryId` | 400 |
| Minh | expense with a `categoryId` of another group | 400 |
| Lan | DELETE it; `GET …/categories` | 204; listed with `archived: true`; the expense still carries the id |
| Minh | new expense with the archived id | 400 |
| Lan | create `Cà phê` again | 201 (the archived one no longer blocks) |
| Minh | create 30 live categories, then one more | the last answers 422 `LIMIT_REACHED` |
| outsider | list | 404 |

- [ ] **Step 4: Commit** — `feat(api): add custom categories per group`

---

### Task 2B.2: API — search and filter of transactions

**Files:**
- Create: `packages/core/src/dates.ts`, a migration
- Modify: `packages/db/src/schema-transactions.ts`, `packages/db/src/transactions.ts`, `packages/contract/src/transaction.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/routes/transactions.ts`, `packages/core/src/index.ts`

**Interfaces — produces:**
- `APP_TIME_ZONE = "Asia/Ho_Chi_Minh"`; `localDateRangeToUtc(from?: string, to?: string): { start?: Date; endExclusive?: Date }` — a `YYYY-MM-DD` date starts at 00:00 Vietnam time (UTC+7, no daylight saving: the offset is the constant 7 hours, stated in a comment); `to` is inclusive.
- `transactions.description_search text NOT NULL`. The migration back-fills it in SQL with `lower(description)`; a one-off script in the same task (`packages/db/src/backfill-description-search.ts`, run by the migration command after migrating, idempotent) rewrites every row with the real normaliser. The service writes it on create and edit.
- List query parameters: `q` (1–100 characters; normalised; `%`, `_` and `\` escaped; matched as `LIKE '%…%'`), `memberId`, `category`, `categoryId`, `type`, `from`, `to`. All optional, combined with AND. Cursor pagination unchanged.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — the December ledger.

| Query | Expected ids, newest first |
|---|---|
| `q=pho` | S6 |
| `q=PHỞ` | S6 |
| `q=%25` (a literal `%`) | none |
| `q==sum` | S7 |
| `memberId=` Thu | S7, S4, S3, S1 |
| `type=transfer` | S5 |
| `category=food` | S6, S1 |
| `from=2026-12-31&to=2026-12-31` | S6 |
| `from=2027-01-01` | S7 |
| `to=2026-12-05` | S1 |
| `from=2026-12-10&to=2026-12-01` | 400 |
| `q=` of 101 characters; `from=2026-13-01` | 400 each |
| `limit=2` with `memberId=` Thu, following `nextCursor` | S7, S4 then S3, S1 then end |

- [ ] **Step 4: Commit** — `feat(api): add search and filters to the transaction list`

---

### Task 2B.3: API — statistics

**Files:**
- Create: `packages/db/src/stats.ts`, `packages/contract/src/stats.ts`, `apps/api/src/services/stats.ts`, `apps/api/src/routes/stats.ts`
- Modify: `apps/api/src/app.ts`, `packages/db/src/index.ts`, `packages/contract/src/index.ts`

**Interfaces — produces:**
- `GET /groups/{groupId}/stats?from=&to=` (viewer), response of spec 7.2.
- Counted rows: `deleted_at IS NULL`, `type IN ('expense', 'income')`; the sign is `+` for expense and `−` for income, applied to the transaction amount, to payer amounts and to share amounts.
- `bucketFor(from: string, to: string): "day" | "week" | "month"` in `core/dates.ts`: number of days inclusive ≤ 31 → `day`; ≤ 182 → `week`; else `month`. Without `from`/`to`, the range is the first to the last counted transaction's Vietnam date.
- Bucket starts are Vietnam calendar dates: the day; the Monday of the week; the first of the month. Computed in SQL with `date_trunc(…, occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')`, the zone passed as a parameter.
- Three aggregate queries in `stats.ts`: `sumByCategory`, `sumByMember`, `sumByBucket`; `total` is the sum of `byBucket`, computed in SQL.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)** — the December ledger.

`from=2026-12-01&to=2026-12-31`:

| Field | Expected |
|---|---|
| `bucket` | `day` |
| `total` | 1999999 |
| `byCategory` | `food` 699999; `lodging` 1100000; `transport` 200000 |
| `byMember` paid | Minh 1700000; Lan 200000; Hùng 99999; Thu 0 |
| `byMember` share | Minh 558333; Lan 558333; Hùng 458333; Thu 425000 |
| `byBucket` | `2026-12-05` 600000; `2026-12-06` 100000; `2026-12-20` 1200000; `2026-12-31` 99999 |

Each of the four lists sums to 1999999.

| Other query | Expected |
|---|---|
| no parameters | `total` 2009999; `bucket` `day`; a fifth bucket `2027-01-01` 10000; `byCategory` gains `{ category: null, categoryId: null, amount: 10000 }` |
| `from=2026-09-01&to=2026-12-31` (122 days) | `bucket` `week`; bucket starts `2026-11-30`, `2026-12-14`, `2026-12-28` with 700000, 1200000, 99999 |
| `from=2026-01-01&to=2026-12-31` | `bucket` `month`; one bucket `2026-12-01` 1999999 |
| delete S4, repeat the first query | `total` 799999; restore S4 afterwards |
| viewer | 200 |
| outsider | 404 |

- [ ] **Step 4: Commit** — `feat(api): add spending statistics`

**Manual checks for the project owner**
1. Enter three expenses and one refund in a new group; open the statistics → the total is the expenses minus the refund.

---

### Task 2B.4: Web — statistics screen and filters

**Files:**
- Create: `apps/web/src/app/g/[groupId]/stats/page.tsx`, `apps/web/src/components/stats/BarRow.tsx`, `apps/web/src/components/stats/PeriodChips.tsx`, `apps/web/src/components/feed/FilterSheet.tsx`, `apps/web/src/components/feed/FilterChips.tsx`, `apps/web/src/lib/stats.ts`
- Modify: the group screen and its stream components, `apps/web/src/lib/transactions.ts`, `apps/web/src/messages/vi.ts`

Strings: spec sections 9.5 and 9.6.

Behavior:
- The shortcut `Tổng chuyến đi` of mockup GE2 is rendered on S4 and opens S16.
- S16: the total is the large number. `PeriodChips`: `Tất cả` (no parameters), `Tháng này` and `Tháng trước` (calendar months in Vietnam time, from `core/dates.ts`), `Tuỳ chọn` (two native date inputs).
- `BarRow`: label, amount, and a bar whose width is `max(amount, 0) / max(amounts)` as a CSS percentage. This ratio sizes a bar and is never shown as a number. A negative amount shows no bar and the amount with a minus sign.
- `Theo người` shows two thin bars per member (paid, share) with the sentence of 9.5.
- Tapping a category row opens S4 with that category and the period as filters; a member row, with `memberId`.
- Filters live in the URL's query string of S4 (`?q=&member=&category=&type=&from=&to=`), so back and reload keep them. With any filter active the entry bar stays and the balance block is hidden; `Xoá lọc` clears the query string.
- The search field debounces 300 ms.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — the December ledger: numbers equal 2B.3; tap `food` → S4 lists S6 and S1 with a chip; search `pho`; no result shows the empty line; reload keeps the filter.
- [ ] **Step 4: Commit** — `feat(web): add statistics screen, search and filters`

**Manual checks for the project owner**
1. S4 → `Tổng chuyến đi` → switch between `Tháng này` and `Tất cả` → totals change, bars resize.
2. Tap a category → the stream shows only that category; `Xoá lọc` restores it.

---

### Task 2B.5: CSV export

**Files:**
- Create: `apps/api/src/csv.ts`, `apps/api/src/csv-labels.ts`, `apps/api/src/services/export.ts`, `apps/api/src/routes/export.ts`
- Modify: `apps/api/src/app.ts`, `apps/api/src/rate-limit.ts` (a new named limit: 6 per minute per user), the S16 page (`Xuất CSV` as a plain link with the `download` attribute)

**Interfaces — produces:**
- `csvCell(value: string | number): string` — a string beginning with `=`, `+`, `-`, `@`, tab or carriage return gets a leading `'`; then RFC 4180 quoting (wrap in `"` and double inner `"` when the cell contains `"`, `,`, CR or LF). Numbers are written as plain digits.
- `GET /groups/{groupId}/export.csv` (viewer): `Content-Type: text/csv; charset=utf-8`, the disposition of spec 7.4 with today's Vietnam date, body starting with the bytes `EF BB BF`, lines ending CRLF. Columns and order of spec 7.4. A group is at most 10,000 live transactions, so the file is built in memory.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 5)** — the December ledger, saved with `curl -o`.

| Check | Expected |
|---|---|
| First three bytes | `EF BB BF` |
| Header | `Ngày,Loại,Mô tả,Danh mục,Tổng tiền,Người trả,Minh,Lan,Hùng,Thu` |
| Row S1 | `2026-12-05 12:30,Chi tiêu,Lẩu,<the web's label for food>,600000,Minh 600000,150000,150000,150000,150000` |
| Row S5 | type `Chuyển khoản`, payer `Lan 50000`, 50000 under Minh, empty under the others |
| Row S6 | date `2026-12-31 23:30`; 33333 under Minh, Lan, Hùng; empty under Thu |
| Row S7 | date `2027-01-01 00:10`; description cell `'=SUM(A1)` |
| An expense described `Cơm, "gà"` | cell `"Cơm, ""gà"""` |
| A member named `@home` | header cell `'@home` |
| Seven requests in one minute | the seventh answers 429 |
| outsider | 404 |

Open the file in a spreadsheet application if one is available and record that Vietnamese text reads correctly and no cell is a formula; otherwise list it under "Not verified".

- [ ] **Step 4: Commit** — `feat(api): add CSV export of a group`

**Manual checks for the project owner**
1. S16 → `Xuất CSV` → open in Excel or Google Sheets → Vietnamese reads correctly, one row per transaction, one column per member.

---

### Task 2B.6: Web — categories in settings and forms; stage gate

**Files:**
- Create: `apps/web/src/components/settings/CategoryList.tsx`, `apps/web/src/lib/categories.ts`
- Modify: the settings page, the category picker of the expense form, the stream row (category display), `apps/web/src/messages/vi.ts`

Strings: spec section 9.7, the category lines.

Behavior: the picker lists the seven built-in categories, then the group's live custom ones; a transaction holding an archived category shows it selected until changed. Settings show the list to everyone on S11 who can open it (owner), and the same list is reachable for editors from the picker's `Thêm danh mục` row. Custom categories show a filled circle in their color where built-in ones show their existing mark.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — create, use, rename, hide; the duplicate and the limit messages appear.
- [ ] **Step 4: Commit** — `feat(web): add custom categories`
- [ ] **Step 5: Stage gate 2B.** Acceptance script on a reset database: the December ledger; the first table of 2B.3; rows 1, 5, 8 of 2B.2; rows 1, 2, 6 of 2B.5. Then the gate of the common file.

**Manual checks for the project owner**
1. Create a category of your own, use it on an expense, hide it → the old expense keeps it, the picker no longer offers it.
