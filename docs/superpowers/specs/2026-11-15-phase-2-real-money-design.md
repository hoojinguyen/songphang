# Phase 2 — Real Money ("Tiền thật") — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` first; its sections 4 and 5 apply here.

## 1. Intent

Phase 1 tells a group who owes whom. Phase 2 lets them act on it: pay a debt by scanning a QR code, have the receiver confirm before the ledger changes, run a shared fund, and see where the money went.

**Goals:** US-2.1 to US-2.8 except the wallet deeplink of US-2.2, which the survey closed (overview section 6).

**Non-goals:** moving money (the application never touches a bank or a wallet); detecting that a transfer really happened; several funds per group; budgets per category; charts beyond bars; multi-currency.

**Anti-goals:** a balance that changes because someone merely claimed to have paid; a fund that breaks "balances sum to 0"; an account number shown to anyone outside the group.

## 2. Scope and stages

| Stage | Adds | SRS |
|---|---|---|
| 2A | Payment details of members; VietQR on every suggested transfer; "I have paid" and the receiver's confirmation | FR-2.1, 2.2, 2.3 (fallback), 2.4 |
| 2B | Custom categories; statistics; search and filter; CSV export | FR-2.6, 2.8, 2.9 |
| 2C | The shared fund | FR-2.5 |
| 2D | Budget and warnings | FR-2.7 |

**Not built:** 2E, opening MoMo or ZaloPay directly (no documented person-to-person link exists). FR-2.3 is met by copying the phone number and the amount.

**Added by the advisor, for the owner to strike if unwanted:** search and filter of transactions in 2B. The roadmap's waiting list calls it "hợp lý để ghép vào 2B", and statistics without a way to see the transactions behind a number are a dead end.

**No new library.** The QR code is drawn with `uqr`, already installed. Bars in the statistics are plain elements sized with CSS.

## 3. Payment details (2A)

### 3.1 Data

`member_payment_methods`

| Column | Type | Constraints | Note |
|---|---|---|---|
| id | uuid | PK | |
| member_id | uuid | FK members, ON DELETE CASCADE | |
| kind | text | `'bank'`, `'momo'` or `'zalopay'` | |
| bank_bin | text | 6 digits; required for `bank`, NULL otherwise | Must be in the bank list |
| account_number | text | NOT NULL | `bank`: 4–19 characters of `[A-Za-z0-9]`. Wallets: a Vietnamese mobile number, stored as 10 digits starting with `0` |
| account_name | text | 1–50 characters; required for `bank` | Shown so the payer can check the name their banking app displays |
| created_at, updated_at | timestamptz | NOT NULL | |

`UNIQUE (member_id, kind)`: one bank account and one of each wallet per member.

The bank list is `packages/core/src/banks.ts`: `{ bin, shortName, name }` for every NAPAS member bank, added to the repository by the advisor with the plan.

### 3.2 Who may read and write

- **Read:** every user of the group, as part of the member object. Never in the invite preview, never in an activity-log snapshot (the log records "payment details changed", not the values), never in a log line.
- **Write:** owner and editors for any member (virtual members have nobody else); a viewer only for the member linked to them.

### 3.3 Endpoint

`PUT /groups/{groupId}/members/{memberId}/payment-methods` takes the member's complete list (zero to three entries) and replaces it. Minimum role at the middleware is viewer; the service applies the rule of 3.2 and answers 403 otherwise.

## 4. VietQR (2A)

A pure function in `core`: `buildVietQrPayload({ bankBin, accountNumber, amount, purpose })` returns the payload string.

| Field | Value |
|---|---|
| 00 | `01` |
| 01 | `12` (single use, amount included) |
| 38 | Template: `00` = `A000000727`; `01` = template of `00` bank BIN and `01` account number; `02` = `QRIBFTTA` |
| 53 | `704` |
| 54 | The amount in đồng, digits only |
| 58 | `VN` |
| 62 | Template: `08` = purpose |
| 63 | CRC-16/CCITT-FALSE (polynomial `0x1021`, initial value `0xFFFF`) over the whole payload including `6304`, as four upper-case hexadecimal digits |

Every length is the two-digit count of the value's characters. The amount is an integer and is written without any arithmetic.

**Purpose** (final format): `SP {from} tra {to}`, with Vietnamese diacritics removed by the existing name normaliser, characters outside `[A-Za-z0-9 ]` dropped, cut to 25 characters. Example: `SP Lan tra Minh`.

`GET /groups/{groupId}/balances`: each element of `transfers` gains `payTo`, the receiver's payment methods; a `bank` entry also carries `bankShortName` and `qrPayload`. The web app only draws the payload; it never builds it.

**Verification limit:** the agent checks the payload against the field table and the CRC against a published example. Whether banking apps accept it is the owner's first manual check of this phase, with a real 1,000 đ transfer.

## 5. Settlement requests (2A, FR-2.4)

Phase 1 lets an editor record a transfer directly. That stays. Phase 2 adds the two-step path for everyone else, and makes it the default button for the person who owes.

### 5.1 Data

`settlement_requests`

| Column | Type | Constraints | Note |
|---|---|---|---|
| id | uuid | PK | |
| group_id | uuid | FK groups, ON DELETE CASCADE | |
| from_member_id, to_member_id | uuid | FK members, ON DELETE RESTRICT; different | |
| amount | bigint | > 0 | |
| status | text | `'pending'`, `'confirmed'`, `'rejected'`, `'cancelled'` | |
| transaction_id | uuid | FK transactions, ON DELETE SET NULL | Set on confirmation |
| created_by, resolved_by | uuid | FK users, ON DELETE SET NULL | |
| created_at, resolved_at | timestamptz | | |

Partial unique index on `(group_id, from_member_id, to_member_id) WHERE status = 'pending'`.

### 5.2 Rules

| Action | Who | Effect |
|---|---|---|
| Create ("Tôi đã chuyển") | The user linked to the paying member, whatever their role; or any editor or owner | A pending request. Balances do not change |
| Confirm | The user linked to the receiving member, whatever their role; the owner; any editor when the receiving member is linked to nobody | In one database transaction: create the transfer through the existing transaction service, set `confirmed` and `transaction_id`, write the activity log |
| Reject | Same as confirm | `rejected`. Nothing else changes |
| Cancel | The creator, or the user linked to the paying member | `cancelled` |

A pending request does not reserve anything: balances are computed as before, and a suggested transfer that matches a pending request (same pair) is returned with `pendingRequestId` and the requested amount. A request whose amount no longer matches the debt is still confirmable; the ledger simply records what was paid.

Confirming twice, or confirming a request that is no longer pending, answers 409 `REQUEST_NOT_PENDING`. Create requires `Idempotency-Key`.

### 5.3 Endpoints

| Method | Path | Minimum role | Note |
|---|---|---|---|
| GET | `/groups/{groupId}/settlement-requests?status=` | Viewer | Newest first, paginated |
| POST | `/groups/{groupId}/settlement-requests` | Viewer + rule 5.2 | `{ fromMemberId, toMemberId, amount }` |
| POST | `…/settlement-requests/{id}/confirm` | Viewer + rule 5.2 | Returns the request and the transaction |
| POST | `…/settlement-requests/{id}/reject` | Viewer + rule 5.2 | |
| POST | `…/settlement-requests/{id}/cancel` | Viewer + rule 5.2 | |

SSE resource name: `settlementRequests`.

## 6. The fund (2C, FR-2.5)

### 6.1 Model

**A fund is a special member.** `members` gains `kind text NOT NULL DEFAULT 'person'` (`'person'` or `'fund'`) and `fund_holder_member_id uuid` (FK members, ON DELETE SET NULL; only for a fund: who physically keeps the money, informational). A partial unique index allows one fund per group.

Why this works without touching the money rules:

| Event | Stored as | Fund's balance |
|---|---|---|
| Lan contributes 500.000 | Transfer, Lan → fund | −500.000 |
| The fund pays a 300.000 dinner for three | Expense, payer = fund, shares on the three people | −200.000 |
| The fund returns 200.000 to Lan | Transfer, fund → Lan | 0 |

The fund's cash is the negative of its balance. Contributions per person are transfers to the fund minus transfers from it. The balance query, the rounding function, the integrity triggers and `db:check-balances` are unchanged, and the group still sums to 0.

**Considered:** a separate `funds` entity with its own ledger. It needs a second balance formula, a second set of triggers and a bridge between the two ledgers, and every new transaction type would have to be written twice.

### 6.2 Rules

- A fund can be a payer of an expense, the holder side of an income, and either side of a transfer. It can never be given a share: 422 `FUND_CANNOT_SHARE`, enforced in the service and in the deferred constraint trigger.
- "All active members" everywhere (default equal split, `chia <N>`, the participant chips) means active **people**.
- A fund cannot be claimed, has no payment methods, and does not appear in the invite preview.
- The fund may be overdrawn (the holder advanced money). `preview` and create then return `warnings: ["FUND_OVERDRAWN"]`; nothing is blocked.
- Created by an editor or the owner; renamed like a member; deleted only while it has no transaction; deactivated only when its cash is 0 (422 `FUND_NOT_EMPTY`).
- Settlement suggestions treat the fund as a participant. When the fund holds cash and people are owed, the suggestion is a transfer from the fund; the web app words it as in section 9.
- Shape code `fund` (a horizontal pill) and color code `sun` (`#FFD84D`) are reserved for funds.

### 6.3 Sentence reader

New FR-2.10: in the payer position, `quỹ trả` and `từ quỹ` name the group's fund (diacritics optional). In a group without a fund they are `MEMBER_UNKNOWN`. A fund named in a share position is the new issue `FUND_CANNOT_SHARE`. A person whose normalised name is `quy` makes the phrase ambiguous, handled as FR-1.97. The advisor adds 12 sentences to `docs/08-quick-entry-samples.md` with the plan.

### 6.4 Endpoints

`POST /groups/{groupId}/fund` (`{ name?, holderMemberId? }`, default name `Quỹ chung`), `PATCH /groups/{groupId}/fund`, `DELETE /groups/{groupId}/fund`: editor. `GET /groups/{groupId}/balances` gains `fund: { memberId, name, cash, holderMemberId, contributions: [{ memberId, amount }] } | null`, and its `balances` array lists people only.

## 7. Categories, statistics, filter, export (2B)

### 7.1 Categories

`group_categories`: `id`, `group_id` (cascade), `name` (1–30 characters, unique per group ignoring case and diacritics), `color` (one of the member color codes), `archived_at`, timestamps. At most 30 live categories per group.

`transactions` gains `category_id uuid` (FK `group_categories`, ON DELETE SET NULL) with `CHECK (category IS NULL OR category_id IS NULL)`. The seven built-in codes stay. Transaction bodies gain `categoryId`.

`GET`, `POST`, `PATCH`, `DELETE /groups/{groupId}/categories[/{id}]`: read by viewers, written by editors. `DELETE` archives: the category disappears from pickers and stays on old transactions.

### 7.2 Statistics

`GET /groups/{groupId}/stats?from=&to=` (viewer). `from` and `to` are calendar dates in `Asia/Ho_Chi_Minh`, inclusive, both optional (default: the group's whole life). The time zone is fixed because the product is Vietnam-only.

```json
{
  "from": "2026-12-01", "to": "2026-12-31", "bucket": "day",
  "total": 4350000,
  "byCategory": [{ "category": "food", "categoryId": null, "amount": 2100000 }],
  "byMember": [{ "memberId": "m1", "paid": 3000000, "share": 1450000 }],
  "byBucket": [{ "start": "2026-12-01", "amount": 300000 }]
}
```

- **What counts:** expenses minus income (a refund reduces spending); transfers never; deleted transactions never. In `byMember`, `paid` and `share` follow the same rule. The fund appears in `paid` only.
- `bucket` is chosen by the server: `day` up to 31 days, `week` (Monday start) up to 26 weeks, otherwise `month`.
- All sums are done in SQL on `bigint`. There is no average and no percentage in the response; the web app sizes bars with CSS from the amounts and shows no computed money figure of its own.

### 7.3 Search and filter

`GET /groups/{groupId}/transactions` gains `q`, `memberId` (payer or sharer), `category`, `categoryId`, `type`, `from`, `to`. `q` matches the description ignoring case and diacritics: `transactions` gains `description_search text NOT NULL`, written by the service with the same normaliser the sentence reader uses, queried with `LIKE` and an escaped pattern. Pagination is unchanged.

### 7.4 CSV export

`GET /groups/{groupId}/export.csv` (viewer; 6 per minute per user). UTF-8 with a byte-order mark so Excel opens Vietnamese correctly; `Content-Disposition: attachment; filename="song-phang-{YYYYMMDD}.csv"`. One row per live transaction, oldest first.

Columns: `Ngày` (`YYYY-MM-DD HH:mm`, Vietnam time), `Loại` (`Chi tiêu`, `Chuyển khoản`, `Thu nhập`), `Mô tả`, `Danh mục`, `Tổng tiền`, `Người trả` (names and amounts joined by `; `), then one column per member, in `position` order, holding that member's share as a plain integer.

A cell that starts with `=`, `+`, `-`, `@`, a tab or a carriage return is prefixed with `'` so a spreadsheet does not run it as a formula. Fields are quoted per RFC 4180.

## 8. Budget (2D, FR-2.7)

`budgets`: `group_id` (PK, cascade), `period` (`'month'` or `'total'`), `amount` (bigint, > 0), `updated_by`, timestamps. One budget per group: `month` is the calendar month in Vietnam time, `total` is the whole group ("theo chuyến đi").

`GET /groups/{groupId}/budget` (viewer) answers `{ "budget": null }` or `{ "budget": { period, amount, spent, state, periodStart, periodEnd } }`. `PUT` and `DELETE`: owner. `spent` uses the rule of 7.2. `state` comes from one function in `core`, integers only: `over` when `spent > amount`; `near` when `spent × 100 ≥ amount × 80`; else `ok`.

`preview` and create add `BUDGET_NEAR` or `BUDGET_OVER` to `warnings` when the transaction would cause that state. A warning never blocks. Notifying people is phase 4.

## 9. Screens

No mockups; built from existing components and tokens. Strings are final.

### 9.1 Paying (S14, `/g/{id}/pay?from=&to=`)

Opened from a suggested transfer on S5. Top to bottom: the two shapes with names and an arrow; the amount as the screen's large number; the QR code on a white card (minimum 240 × 240, quiet zone kept); bank, account number, account name and purpose, each with a copy button; wallet rows; the primary button.

| Element | String |
|---|---|
| Title | `Trả {to}` |
| Bank rows | `Ngân hàng` · `Số tài khoản` · `Tên tài khoản` · `Nội dung` |
| QR hint | `Quét bằng app ngân hàng. Số tiền và nội dung đã điền sẵn.` |
| Wallet row | `MoMo {phone}` · `ZaloPay {phone}` |
| Copy buttons, after copy | `Sao chép` → `Đã sao chép` |
| Copy amount | `Sao chép số tiền` |
| Primary button | `Tôi đã chuyển` |
| After pressing | `Đã báo cho {to}. Sổ sẽ ghi nhận khi {to} xác nhận.` |
| No payment details | `{to} chưa có thông tin nhận tiền.` with button `Thêm thông tin` (shown to those who may write) |
| Editor's direct path | `Ghi nhận luôn` (opens S9, as in phase 1) |

### 9.2 Balances (S5 changes)

| Place | String |
|---|---|
| Pending, seen by the receiver | `{from} báo đã chuyển {amount}` with buttons `Đã nhận` · `Chưa nhận` |
| Pending, seen by others | `Đang chờ {to} xác nhận` |
| Pending, seen by its creator | adds the action `Huỷ báo` |
| After confirming | `Đã ghi nhận {amount} từ {from}.` |
| After rejecting | `Đã báo lại là chưa nhận.` |
| Request no longer pending | `Yêu cầu này đã được xử lý.` |
| Fund block title | `Quỹ còn {amount}` or `Quỹ đang âm {amount}` |
| Fund suggestion | `Quỹ hoàn {to} {amount}` · `{from} góp thêm vào quỹ {amount}` |

### 9.3 Payment details (inside the member editor of S10)

| Element | String |
|---|---|
| Section title | `Thông tin nhận tiền` |
| Fields | `Ngân hàng` (searchable list) · `Số tài khoản` · `Tên tài khoản` · `Số MoMo` · `Số ZaloPay` |
| Hint | `Cả nhóm thấy thông tin này để chuyển tiền cho {name}.` |
| Invalid account number | `Số tài khoản chỉ gồm chữ và số.` |
| Invalid phone | `Số điện thoại chưa đúng.` |
| Saved | `Đã lưu.` |

### 9.4 Fund (S17, `/g/{id}/fund`)

Reached from the fund block on S5 and from S10.

| Element | String |
|---|---|
| Create entry on S10 | `Lập quỹ chung` |
| Create dialog | `Tên quỹ` (default `Quỹ chung`) · `Ai giữ tiền quỹ?` · `Lập quỹ` |
| Large number | the cash, labelled `Quỹ còn` |
| Contributions list title | `Đã góp` |
| Buttons | `Góp vào quỹ` · `Rút khỏi quỹ` (both open the transfer form with one side fixed) |
| Payer option in the expense form | `Quỹ chung trả` |
| Overdrawn warning in preview | `Quỹ không đủ. Sau khoản này quỹ âm {amount}.` |
| Close a non-empty fund | `Quỹ còn tiền. Hãy hoàn hết cho mọi người trước.` |
| Fund named as a sharer | `Quỹ không thể là người chia.` |

### 9.5 Statistics (S16, `/g/{id}/stats`)

Reached from the shortcut `Tổng chuyến đi` on S4 (hidden in phase 1, user-flows section 9). The total is the large number; then a period selector; then three sections of horizontal bars, each row tappable into S4 with the matching filter.

| Element | String |
|---|---|
| Title | `Tiền đi đâu` |
| Period chips | `Tất cả` · `Tháng này` · `Tháng trước` · `Tuỳ chọn` |
| Sections | `Theo danh mục` · `Theo người` · `Theo thời gian` |
| Member row | `{name} · đã trả {paid} · phần mình {share}` |
| Uncategorised | `Chưa phân loại` |
| Empty | `Chưa có khoản chi nào trong khoảng này` |
| Export | `Xuất CSV` |

### 9.6 Filter (S4)

A search field and a filter button appear when the stream is scrolled to its top. Active filters show as chips above the stream.

| Element | String |
|---|---|
| Search placeholder | `Tìm khoản chi` |
| Filter sheet | `Người` · `Danh mục` · `Loại` · `Từ ngày` · `Đến ngày` · `Áp dụng` · `Xoá lọc` |
| No result | `Không có khoản nào khớp` |

### 9.7 Settings (S11 additions)

| Element | String |
|---|---|
| Categories | `Danh mục của nhóm` · `Thêm danh mục` · `Tên danh mục` · `Ẩn danh mục` |
| Duplicate name | `Nhóm đã có danh mục này.` |
| Limit reached | `Nhóm đã có 30 danh mục.` |
| Budget | `Hạn mức` · `Theo tháng` · `Cả chuyến` · `Số tiền` · `Lưu hạn mức` · `Bỏ hạn mức` |

### 9.8 Budget banner (S4)

Above the stream, only in state `near` or `over`; tapping opens S16.

| State | String |
|---|---|
| `near` | `Đã chi {spent} trên hạn mức {amount}.` |
| `over` | `Đã vượt hạn mức {over}.` |
| In the confirmation card | `Khoản này làm nhóm vượt hạn mức.` |

## 10. Permission matrix additions

| Endpoint group | Owner | Editor | Viewer | Outsider |
|---|---|---|---|---|
| Read payment methods, settlement requests, categories, stats, budget, export | 200 | 200 | 200 | 404 |
| Write payment methods of any member | 2xx | 2xx | 403 | 404 |
| Write payment methods of one's own member | 2xx | 2xx | 2xx | 404 |
| Create a settlement request for one's own member; confirm or reject as the receiver | 2xx | 2xx | 2xx | 404 |
| Create a settlement request for another member | 2xx | 2xx | 403 | 404 |
| Confirm a request to an unlinked member | 2xx | 2xx | 403 | 404 |
| Create, edit, archive a category; create, edit, delete the fund | 2xx | 2xx | 403 | 404 |
| Set or remove the budget | 2xx | 403 | 403 | 404 |

## 11. Gate acceptance scripts (outline; the plan carries the numbers)

- **2A:** a payload for a fixed bank, account, amount and purpose equals a known string byte for byte; a debtor who is a viewer creates a request; balances unchanged; the receiver confirms; balances change by exactly the amount; a second confirmation answers 409.
- **2B:** statistics for a seeded month equal hand-computed totals, with one refund and one transfer present; a description starting with `=` is escaped in the CSV; `q=pho` finds `Phở`.
- **2C:** the three-row example of 6.1 produces the three fund balances shown; a share on the fund is refused by the API and, when inserted directly, by the trigger; `db:check-balances` passes.
- **2D:** `spent × 100 = amount × 80` exactly is `near`; one đồng less is `ok`.

## 12. Left to the builder

File and function names; how the bank picker filters; bar heights and spacing; which existing component the pending-request row extends.

## 13. Changes to standing documents

| Document | Change |
|---|---|
| `docs/03-srs.md` | FR-2.3 reduced to its fallback; FR-2.10 (fund in the sentence reader); FR-2.11 (search and filter); permission table rows |
| `docs/05-database-design.md` | Sections for the four new tables and the new columns; section 8's phase 2 row replaced |
| `docs/05-api-spec.md` | New endpoints, error codes `REQUEST_NOT_PENDING`, `FUND_CANNOT_SHARE`, `FUND_NOT_EMPTY`, the `warnings` array |
| `docs/06-ux-ui/user-flows.md` | S14, S16, S17 and section 9 of this spec |
| `docs/04-adr.md` | ADR-021: a fund is a member of kind `fund`. ADR-022: a settlement is recorded only on the receiver's confirmation |
| `docs/08-quick-entry-samples.md` | 12 fund sentences |

## 14. Owner's prerequisites

Approve this spec. After the run: one real VietQR scan with a 1,000 đ transfer.
