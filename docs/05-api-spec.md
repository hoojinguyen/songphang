# 05 — Đặc tả API (giai đoạn 1)

Cập nhật: 2026-11-11. Trạng thái: đã duyệt ngày 2026-11-11; bản sửa đổi cùng ngày (endpoint `parse`, trường `shape` và `color`) đã duyệt. Bản sửa đổi thứ ba (nội bộ trước, phát hành công khai sau; đăng ký bằng email) đã duyệt.

Đây là bản thiết kế cho người đọc. Hợp đồng chính thức là schema Zod trong `packages/contract`; file OpenAPI được sinh từ đó khi có code (ADR-005).

## 1. Quy ước chung

| Chủ đề | Quy ước |
|---|---|
| Gốc | `/api/v1` |
| Định dạng | JSON, UTF-8; tên trường `camelCase` |
| Xác thực | Web: cookie phiên. Mobile: `Authorization: Bearer <mã phiên>` |
| Tiền | Số nguyên theo đơn vị nhỏ nhất, kèm `currency` |
| Thời gian | Chuỗi ISO 8601 theo UTC |
| Trọng số, phần trăm | Chuỗi thập phân, ví dụ `"1.5"` |
| Phân trang | Theo con trỏ: `?cursor=…&limit=…`; phản hồi có `nextCursor` hoặc `null` |
| Chống trùng | Mọi `POST` tạo dữ liệu nhận header `Idempotency-Key` |
| Sửa đồng thời | `PATCH` giao dịch phải gửi `version` đang có |

**Mã trạng thái**

| Mã | Khi nào |
|---|---|
| 200, 201, 204 | Thành công |
| 400 | Dữ liệu sai định dạng hoặc vi phạm quy tắc |
| 401 | Chưa đăng nhập hoặc phiên hết hạn |
| 403 | Thuộc nhóm nhưng không đủ quyền |
| 404 | Không tồn tại, hoặc người gọi không thuộc nhóm |
| 409 | Xung đột phiên bản, hoặc khoá chống trùng dùng lại với nội dung khác |
| 422 | Dữ liệu hợp lệ về định dạng nhưng không thực hiện được, ví dụ xoá thành viên đã có giao dịch |
| 429 | Quá tần suất |

**Định dạng lỗi**

```json
{
  "error": {
    "code": "SPLIT_TOTAL_MISMATCH",
    "message": "Tổng các phần không bằng tổng tiền",
    "details": { "expected": 300000, "actual": 280000 },
    "requestId": "01JC…"
  }
}
```

Client dịch thông điệp theo `code`; `message` chỉ dùng cho log và gỡ lỗi.

**Mã lỗi nghiệp vụ**

| Mã | Ý nghĩa |
|---|---|
| `VALIDATION_FAILED` | Sai định dạng; `details` liệt kê theo trường |
| `UNAUTHENTICATED` | Chưa đăng nhập |
| `FORBIDDEN` | Không đủ quyền |
| `NOT_FOUND` | Không tìm thấy |
| `VERSION_CONFLICT` | Giao dịch đã bị người khác sửa; `details.current` chứa bản mới |
| `IDEMPOTENCY_KEY_REUSED` | Khoá chống trùng đã dùng cho nội dung khác |
| `SPLIT_TOTAL_MISMATCH` | Tổng phần chịu khác tổng tiền |
| `PAYER_TOTAL_MISMATCH` | Tổng phần trả khác tổng tiền |
| `MEMBER_NOT_IN_GROUP` | Thành viên không thuộc nhóm |
| `MEMBER_HAS_TRANSACTIONS` | Không xoá được thành viên đã có giao dịch |
| `MEMBER_ALREADY_CLAIMED` | Thành viên đã gắn với người dùng khác |
| `INVITE_INVALID` | Mã mời sai hoặc đã tắt |
| `OWNER_REQUIRED` | Nhóm phải có chủ nhóm; chủ nhóm không tự rời được |
| `RATE_LIMITED` | Quá tần suất |
| `INTERNAL` | Lỗi không lường trước ở server (500); không kèm chi tiết |

## 2. Danh sách endpoint

Cột "Quyền": **Đăng nhập** là mọi người dùng; **Xem**, **Ghi**, **Chủ** là vai trò tối thiểu trong nhóm.

### Phiên

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/auth/google` | Công khai | Bắt đầu đăng nhập; nhận `?redirect=` | FR-1.1 |
| GET | `/auth/google/callback` | Công khai | Google gọi về; tạo phiên | FR-1.1 |
| POST | `/auth/register` | Công khai | Đăng ký bằng email, tên, mật khẩu; gửi thư xác minh | FR-1.4, 1.5 |
| POST | `/auth/login` | Công khai | Đăng nhập bằng email và mật khẩu | FR-1.4 |
| POST | `/auth/verify-email` | Công khai | Xác minh bằng mã trong thư | FR-1.5 |
| POST | `/auth/resend-verification` | Đăng nhập | Gửi lại thư xác minh | FR-1.5 |
| POST | `/auth/forgot-password` | Công khai | Gửi link đặt lại; luôn trả cùng một phản hồi | FR-1.6, NFR-1.13 |
| POST | `/auth/reset-password` | Công khai | Đặt mật khẩu mới bằng mã trong thư | FR-1.6 |
| POST | `/auth/change-password` | Đăng nhập | Đổi mật khẩu; tuỳ chọn huỷ các phiên khác | FR-1.7 |
| POST | `/auth/logout` | Đăng nhập | Huỷ phiên hiện tại | FR-1.2 |
| DELETE | `/me` | Đăng nhập | Xoá tài khoản | FR-1.9 |
| GET | `/me` | Đăng nhập | Thông tin người dùng | FR-1.1 |

### Nhóm

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/groups` | Đăng nhập | Nhóm của tôi, kèm số dư của tôi | FR-1.11 |
| POST | `/groups` | Đăng nhập | Tạo nhóm; người tạo là chủ nhóm và thành viên đầu tiên | FR-1.10 |
| GET | `/groups/{groupId}` | Xem | Chi tiết nhóm, vai trò và thành viên của tôi | |
| PATCH | `/groups/{groupId}` | Chủ | Đổi tên, tối giản nợ, vai trò mặc định | FR-1.12 |
| DELETE | `/groups/{groupId}` | Chủ | Xoá nhóm; thân yêu cầu chứa tên nhóm để xác nhận | FR-1.13 |
| POST | `/groups/{groupId}/leave` | Xem | Rời nhóm; chủ nhóm không dùng được | FR-1.14 |

### Mời

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/invites/{token}` | Đăng nhập | Xem trước: tên nhóm, thành viên, ai chưa có người nhận | FR-1.31 |
| POST | `/invites/{token}/join` | Đăng nhập | Tham gia; chọn `memberId` hoặc `newMemberName` | FR-1.32, 1.33 |
| GET | `/groups/{groupId}/invite` | Ghi | Lấy link mời hiện tại | FR-1.30 |
| PATCH | `/groups/{groupId}/invite` | Chủ | Bật hoặc tắt link | FR-1.34 |
| POST | `/groups/{groupId}/invite/rotate` | Chủ | Tạo link mới, link cũ mất hiệu lực | FR-1.34 |

### Thành viên

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/groups/{groupId}/members` | Xem | Danh sách thành viên | |
| POST | `/groups/{groupId}/members` | Ghi | Thêm thành viên | FR-1.20 |
| PATCH | `/groups/{groupId}/members/{memberId}` | Ghi | Đổi tên, trọng số mặc định, trạng thái hoạt động | FR-1.21, 1.23 |
| DELETE | `/groups/{groupId}/members/{memberId}` | Ghi | Xoá nếu chưa có giao dịch | FR-1.22 |
| PUT | `/groups/{groupId}/me/member` | Xem | Chọn "tôi là thành viên này" | FR-1.24 |

### Người dùng trong nhóm

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/groups/{groupId}/users` | Xem | Ai có quyền vào nhóm, vai trò gì | |
| PATCH | `/groups/{groupId}/users/{userId}` | Chủ | Đổi vai trò | FR-1.35 |
| DELETE | `/groups/{groupId}/users/{userId}` | Chủ | Gỡ khỏi nhóm | FR-1.35 |
| POST | `/groups/{groupId}/transfer-ownership` | Chủ | Chuyển quyền chủ nhóm | FR-1.36 |

### Giao dịch

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/groups/{groupId}/transactions` | Xem | Danh sách, mới nhất trước, phân trang | FR-1.47, 1.48 |
| POST | `/groups/{groupId}/transactions` | Ghi | Tạo chi tiêu, chuyển khoản hoặc thu nhập | FR-1.40–1.44 |
| POST | `/groups/{groupId}/transactions/preview` | Ghi | Tính thử phần của từng người, không lưu | FR-1.51–1.56 |
| POST | `/groups/{groupId}/transactions/parse` | Ghi | Đọc một câu gõ thành bản nháp chi tiêu, không lưu | FR-1.90–1.100 |
| GET | `/groups/{groupId}/transactions/{id}` | Xem | Chi tiết, kèm đầu vào gốc | FR-1.45 |
| PATCH | `/groups/{groupId}/transactions/{id}` | Ghi | Sửa; cần `version` | FR-1.45 |
| DELETE | `/groups/{groupId}/transactions/{id}` | Ghi | Xoá mềm | FR-1.46 |
| POST | `/groups/{groupId}/transactions/{id}/restore` | Ghi | Khôi phục | FR-1.46 |

### Số dư, lịch sử, sự kiện

| Phương thức | Đường dẫn | Quyền | Mô tả | SRS |
|---|---|---|---|---|
| GET | `/groups/{groupId}/balances` | Xem | Số dư từng thành viên và lượt chuyển đề xuất | FR-1.60–1.63 |
| GET | `/groups/{groupId}/activity` | Xem | Lịch sử thay đổi, phân trang | FR-1.70, 1.71 |
| GET | `/groups/{groupId}/events` | Xem | Luồng SSE | FR-1.80 |
| GET | `/health` | Công khai | Kiểm tra sức khoẻ | |

## 3. Cấu trúc dữ liệu chính

### Tạo giao dịch

`POST /groups/{groupId}/transactions`

```json
{
  "type": "expense",
  "description": "Ăn tối quán lẩu",
  "amount": 300000,
  "occurredAt": "2026-12-05T12:30:00Z",
  "category": "food",
  "payers": [{ "memberId": "m1", "amount": 300000 }],
  "split": {
    "method": "exact",
    "members": ["m1", "m2", "m3"],
    "entries": [
      { "memberId": "m1", "amount": 80000 },
      { "memberId": "m2", "amount": 60000 },
      { "memberId": "m3", "amount": 40000 }
    ],
    "remainder": "equal_among_all"
  }
}
```

Trường `split` có cùng cấu trúc với `split_input` trong [thiết kế database](05-database-design.md). Với `type: "transfer"`, gửi `fromMemberId` và `toMemberId` thay cho `payers` và `split`.

Phản hồi `201`:

```json
{
  "id": "01JE…",
  "type": "expense",
  "description": "Ăn tối quán lẩu",
  "amount": 300000,
  "currency": "VND",
  "occurredAt": "2026-12-05T12:30:00Z",
  "category": "food",
  "payers": [{ "memberId": "m1", "amount": 300000 }],
  "shares": [
    { "memberId": "m1", "amount": 120000 },
    { "memberId": "m2", "amount": 100000 },
    { "memberId": "m3", "amount": 80000 }
  ],
  "split": { "…": "đầu vào gốc, như đã gửi" },
  "version": 1,
  "createdBy": { "id": "u1", "name": "Minh" },
  "createdAt": "2026-12-05T12:31:02Z",
  "updatedAt": "2026-12-05T12:31:02Z",
  "deletedAt": null
}
```

`POST …/transactions/preview` nhận cùng thân yêu cầu và trả `shares` mà không lưu. Web dùng nó để hiện con số chính xác trước khi người dùng bấm lưu.

### Đọc câu gõ

`POST …/transactions/parse` nhận `{ "text": "…" }` và không lưu gì. Phản hồi:

```json
{
  "status": "ok",
  "draft": { "…": "cùng cấu trúc với thân yêu cầu tạo giao dịch" },
  "shares": [{ "memberId": "m1", "amount": 120000 }],
  "spans": [
    { "start": 4,  "end": 8,  "kind": "amount" },
    { "start": 10, "end": 18, "kind": "payer" },
    { "start": 20, "end": 42, "kind": "exact" },
    { "start": 44, "end": 60, "kind": "remainder" }
  ],
  "issues": []
}
```

- `status` là `ok` (lưu được ngay), `needs_input` (hiểu được nhưng thiếu một lựa chọn, ví dụ tên khớp hai người hoặc `chia 3` trong nhóm 4 người) hoặc `unparsed` (FR-1.99).
- `draft` luôn chứa những gì đã hiểu, kể cả khi `status` không phải `ok`; `shares` chỉ có khi `status` là `ok`.
- `spans` là vị trí ký tự của từng cụm đã hiểu trong `text`, để client tô màu. `kind`: `amount`, `description`, `payer`, `equal`, `exact`, `remainder`.
- `issues` là danh sách `{ "code", "start", "end", "candidates" }`; mã gồm `AMOUNT_MISSING`, `DESCRIPTION_MISSING`, `MEMBER_AMBIGUOUS`, `MEMBER_UNKNOWN`, `COUNT_MISMATCH`, `SUM_MISMATCH`, `TEXT_NOT_UNDERSTOOD`.
- Để lưu, client gửi `draft` (đã bổ sung nếu cần) tới `POST …/transactions` như mọi giao dịch khác. Endpoint `parse` không bao giờ tự lưu.

Đối tượng thành viên trong mọi phản hồi có thêm `shape` và `color` (FR-1.25).

### Số dư

`GET /groups/{groupId}/balances`

```json
{
  "currency": "VND",
  "minimized": true,
  "balances": [
    { "memberId": "m1", "balance": 450000 },
    { "memberId": "m2", "balance": -120000 },
    { "memberId": "m3", "balance": -250000 },
    { "memberId": "m4", "balance": -80000 }
  ],
  "transfers": [
    { "fromMemberId": "m3", "toMemberId": "m1", "amount": 250000 },
    { "fromMemberId": "m2", "toMemberId": "m1", "amount": 120000 },
    { "fromMemberId": "m4", "toMemberId": "m1", "amount": 80000 }
  ]
}
```

Số dương là được nợ, số âm là đang nợ.

### Xem trước lời mời

`GET /invites/{token}`

```json
{
  "group": { "id": "g1", "name": "Đà Lạt 12/2026" },
  "members": [
    { "id": "m1", "name": "Minh", "claimed": true },
    { "id": "m2", "name": "Lan", "claimed": false }
  ],
  "alreadyJoined": false
}
```

### Sự kiện SSE

`GET /groups/{groupId}/events`

```
event: changed
data: {"resources":["transactions","balances","activity"]}

event: removed
data: {}
```

- `changed`: client tải lại các tài nguyên được nêu. Giá trị có thể là `group`, `members`, `users`, `transactions`, `balances`, `activity`.
- `removed`: người dùng vừa bị gỡ khỏi nhóm hoặc nhóm bị xoá; client đưa về danh sách nhóm.
- Server gửi dòng giữ kết nối mỗi 25 giây.

## 4. Giới hạn

| Giới hạn | Giá trị |
|---|---|
| Kích thước thân yêu cầu | 100 KB |
| Thành viên mỗi nhóm | 100 |
| Số tiền mỗi giao dịch | Dưới 1.000 tỉ đồng |
| `limit` phân trang | Mặc định 50, tối đa 200 |
| Tần suất ghi | 60 yêu cầu mỗi phút mỗi người dùng |
| Tần suất xem trước lời mời | 30 yêu cầu mỗi phút mỗi IP |
| Độ dài câu gõ | 300 ký tự |
| Tần suất đọc câu gõ | 120 yêu cầu mỗi phút mỗi người dùng |

## 5. Amendment 2026-11-12

Approved with the phase 1 spec. English, following the language policy.

- New endpoint `GET /auth/providers` (public): `{ "google": boolean, "devLogin": boolean }`.
- `POST /auth/register` always answers 204 and never creates a session.
- New error codes: `INVALID_CREDENTIALS` (401), `EMAIL_NOT_VERIFIED` (403), `TOKEN_INVALID` (400), `WEAK_PASSWORD` (400, `details.reason` is `too_short`, `too_long`, or `too_common`).
- `GET /invites/{token}` also returns `ownerName`, `memberCount`, `transactionCount`, each member's `shape` and `color`, and `balance` for unclaimed members.
- `POST /groups` takes `{ "name", "memberNames" }`. Create endpoints require `Idempotency-Key`.
- An issue of the parse response may also carry `count`, `expected`, and `actual`; the response also returns `text`, the normalized sentence its spans index.
- `PATCH` of a transaction takes the full create body plus `version`; the type cannot change.
- Rate limits for accounts are in the spec, section 6.8.


## Phase 2 amendment — approved 2026-11-17

API root remains `/api/v1`. Every group route retains shared authorization, same-origin writes, verified-email/write limiting and post-lock access revalidation. Create operations require Idempotency-Key. Outsiders receive indistinguishable 404; group members with insufficient permission receive 403.

| Method | Route (relative to API root) | Minimum access / result |
|---|---|---|
| GET | /features | Public; optional capability booleans; all false in Phase 2 |
| PUT | /groups/{groupId}/members/{memberId}/payment-methods | Viewer plus own-member rule; replace complete 0–3 unique-kind list |
| GET, POST | /groups/{groupId}/settlement-requests | Viewer; paginated status filter; create requires payer identity or editor |
| POST | /groups/{groupId}/settlement-requests/{id}/confirm | Receiver, owner, editor for unlinked receiver; atomic request plus transaction |
| POST | /groups/{groupId}/settlement-requests/{id}/reject | Same resolver rule; no ledger change |
| POST | /groups/{groupId}/settlement-requests/{id}/cancel | Creator or linked payer |
| GET, POST | /groups/{groupId}/categories | Viewer read, editor create |
| PATCH, DELETE | /groups/{groupId}/categories/{id} | Editor; delete archives |
| GET | /groups/{groupId}/stats | Viewer; inclusive Vietnam calendar from/to; expense minus income, excluding transfers/deletions |
| GET | /groups/{groupId}/export.csv | Viewer; 6/minute/user; UTF-8 BOM, CRLF, RFC 4180, formula-safe cells |
| POST, PATCH, DELETE | /groups/{groupId}/fund | Editor; one special member; no closure with nonzero cash |
| GET | /groups/{groupId}/budget | Viewer; budget null or period/amount/spent/state/periodStart/periodEnd |
| PUT, DELETE | /groups/{groupId}/budget | Owner |

Transaction requests/DTOs gain categoryId. Lists gain q/memberId/category/categoryId/type/from/to with AND semantics, escaped LIKE, same keyset cursor and at most five-year ranges. All sums use SQL bigint. Preview/create/edit always return warnings (FUND_OVERDRAWN, BUDGET_NEAR, BUDGET_OVER). Only threshold transitions warn for budgets; edits exclude the old transaction. Money division remains in core.

Member DTOs gain paymentMethods and kind. Balances transfers gain payTo, purpose and nullable pendingRequest {id, amount, createdByMe}. Bank payTo includes bankShortName and server-built qrPayload. From 2C balances lists people only, while fund contains memberId/name/active/cash/holderMemberId/contributions. This intended pre-freeze contract amendment preserves existing fields. SSE adds settlementRequests/categories/budget invalidations without sensitive payloads.

Errors: REQUEST_ALREADY_PENDING (409), REQUEST_NOT_PENDING (409), CATEGORY_EXISTS (409), FUND_EXISTS (409), FUND_CANNOT_SHARE (422), FUND_NOT_EMPTY (422). Other constraints retain existing VALIDATION_FAILED/LIMIT_REACHED/MEMBER_HAS_TRANSACTIONS behavior. Exact request/response fields are defined in Phase 2 spec and task interface blocks.

## Phase 2B statistics navigation correction — approved 2026-11-17

Transaction list query gains optional `spendingOnly=true|false` (default false). When true, results are restricted to `expense` and `income` in addition to every other filter. `spendingOnly=true&type=transfer` is invalid (400 VALIDATION_FAILED); other boolean strings are invalid. The existing group authorization and keyset cursor remain unchanged. This scope performs no new money calculation.

Every statistics category/member/time link sets `spendingOnly=true` in the feed URL. The scope survives reload, pagination, search and other filter changes and has a removable type chip composed from the existing Chi/Thu labels. Picking a single transaction type replaces the combined scope. Ordinary `uncategorized=true` without this flag continues to include transfers with no category; statistics navigation excludes them to match its source aggregate.

## Phase 3 API amendment — approved 2026-11-17, implemented (merged 905cdf2)

The following contracts come from the approved Phase 3 spec (including section 15) and are available on main since merge `905cdf2`. The section "Phase 3 review corrections — 2026-11-18" below amends the parse request and the items preview.

| Method | Route below /api/v1 | Authorization and planned result |
|---|---|---|
| POST | /groups/{groupId}/attachments | Editor; same-origin verified write; multipart file; 201 AttachmentDto |
| GET | /groups/{groupId}/attachments/{id}/content | Viewer; group-scoped ID; stored content type, nosniff, private,no-store, inline hoa-don.jpg |
| DELETE | /groups/{groupId}/attachments/{id} | Editor; 204, remove row/file |
| POST | /groups/{groupId}/receipt-scans | Editor, Idempotency-Key; {attachmentId}; 201 queued, 200 existing, 404 when receiptReading disabled |
| GET | /groups/{groupId}/receipt-scans/{id} | Viewer; group-scoped scan DTO |
| POST | /groups/{groupId}/transactions/items/preview | Editor and ordinary write guards; {items,extras,targetTotal?}; 200 computedAmount/optional shares/issues/optional targetAdjustment for structurally valid incomplete editor input |

All group endpoints use shared authorization; outsiders and cross-group attachment/scan IDs get indistinguishable 404, signed-out callers 401. Upload enforces a 6-MiB streamed body cap, file bytes 1..5242880, JPEG/PNG/WebP leading bytes, 30 uploads/hour/user and 200-MiB serialized group quota. The 100-KiB bound remains elsewhere. Never trust the request's type/name. Attachment IDs are 0–3 unique UUIDs, same group and unattached or owned by that transaction.

AttachmentDto: id, contentType, byteSize, nullable transactionId, createdAt. Transaction detail/create/edit gains attachments; introduce a distinct TransactionListItemDto carrying attachmentCount instead of attachment bodies. Removing an ID on edit deletes that attachment; omitted optional fields preserve the existing contract semantics. Soft deletion/restoration preserves photos. Group deletion schedules file cleanup with keys captured before cascade.

ReceiptScanDto: id, attachmentId, queued|processing|done|failed status, validated reading or null, computed or null, flags, errorCode or null, createdAt. No scan creates a transaction or changes balances. ReceiptReading fields and bounds are Phase 3 spec section 5.3: merchant <=80 or null; valid YYYY-MM-DD or null; 0–60 item lines (name 1–80, quantity 1–999, integer whole-line amount); 0–6 extras (tax/service/discount/other, bounded label, nonnegative integer amount); printed total or null. A mismatching printed total is retained with TOTAL_MISMATCH. No items/total is NOT_A_RECEIPT.

The items preview accepts 1–60 items and 0–6 extras, with 0–20 unique group people per item. Unassigned items produce ITEM_UNASSIGNED with itemIndex and no shares; invalid/nonpositive/out-of-range computed totals have issues and no shares. Structural schema failures are 400. Fund participants are refused, never silently dropped. All sums and allocations are core-only. Ordinary preview/create/edit still require a complete amount, payer list and valid split; expense only for items, not income. Core refuses mismatched totals or negative shares.

Parse response adds reader (rules|ai), category/categoryId on drafts (mutually exclusive), and moreDrafts (0–4 per-draft status/draft/issues/optional shares results). Existing rule-readable or needs_input sentences never call AI. AI boundary input/output uses bounded nonce-scoped references; API-memory mapping and ordinary UUID validation happen before core. Unknown references or uncertain/arithmetically invalid answers never yield ok or shares. Empty/invalid/error/timeout/quota-limited answers preserve the rule refusal. Every issue includes candidates, empty when not applicable. Only live custom categories may be suggested; explicit AI built-in category wins over keyword suggestions.

Preserve the existing six-field public features response; enable receiptReading/sentenceAi only through approved configuration. SSE adds receiptScans as a resource, distinct from capability receiptReading. Unset AI leaves camera hidden and scan creation 404. Provider errors never expose raw bodies, keys, paths or prompts.

New planned errors: STORAGE_QUOTA_EXCEEDED (422), AI_QUOTA_EXCEEDED (429 with scope user|month), ITEM_UNASSIGNED (400 on ordinary create/preview, itemIndex). Scan terminal errors are NOT_A_RECEIPT, READER_UNAVAILABLE, READER_INVALID and READ_FAILED (missing image, abandoned or stale attempt); flags include TOTAL_MISMATCH, TOTAL_MISSING, NO_ITEMS. Reuse SPLIT_TOTAL_MISMATCH and FUND_CANNOT_SHARE. Quota is per reserved provider attempt, including retries and uncertain outcomes; one scan may consume two receipt attempts. API admission/reservation/job enqueue is one transaction; actual HTTP is outside it.

Synthetic fixture inventory and exact expected data: apps/worker/fixtures/README.md and receipts/manifest.json. The fake browser fixture selector is development configuration only and is rejected with real providers or production. No application-facing fixture selector exists.

## Phase 3 review corrections — 2026-11-18

Approved by the owner after the Phase 3 advisor review (`docs/superpowers/runs/phase-3/advisor-review-2026-11-18.md`).

**Parse request.** `POST …/transactions/parse` accepts `{ "text": "…", "ai": false }`. `ai` is an optional boolean, default `false`; any other type is 400 `VALIDATION_FAILED`. The sentence AI runs only when `ai` is `true`, `features.sentenceAi` is on, the rule reader answered `unparsed` and the quota allows. With `ai` absent or `false` the response is the rule reader's answer and no `ai_calls` row is created. Clients send `ai: true` only when the user explicitly sends the sentence (Enter or the send button), never from a live, as-you-type reading, so unfinished text never reaches the provider. While `features.sentenceAi` is on, the web keeps a refused live reading on S7 until the user sends; with it off, the Phase 1 behavior (open the form) is unchanged.

**Items preview.** The request accepts an optional `targetTotal` (integer, 0–999 999 999 999), the printed receipt total. When it is present, the response carries `targetAdjustment`: `null` when `computedAmount` already equals it, otherwise `{ "kind": "other" | "discount", "amount": <positive integer> }`, the one extra that makes the computed total equal the printed total (`other` when the receipt is higher, `discount` when lower). `core` computes it; the client only adds it as an extra line labelled with the approved mismatch label. Without `targetTotal` the field is absent. Example: items and extras summing to 442 000 with `targetTotal` 450 000 give `{ "kind": "other", "amount": 8000 }`.

**AI cost ledger.** A provider response that is billed but unusable (no tool block, invalid shape, invalid reading) records its model and token counts in `ai_calls` with `ok = false`; only transport failures without a response record zero tokens.

