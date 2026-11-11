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
