# Quy ước code

Cập nhật: 2026-11-11. File này chi tiết hoá mục 7 của `AGENTS.md`. Khi hai file khác nhau, `AGENTS.md` đúng.

## 1. Cấu trúc thư mục

```
apps/
  api/src/
    config.ts            đọc và kiểm biến môi trường
    app.ts               ráp ứng dụng: middleware, route
    errors.ts            AppError và bộ xử lý lỗi chung
    routes/              một file cho một nhóm endpoint; không chứa logic
    services/            một file cho một nhóm thao tác nghiệp vụ
    auth/                phiên, middleware đăng nhập và phân quyền
  web/src/
    app/                 trang (App Router); mỗi thư mục một màn hình
    components/ui/       thành phần dùng chung, không biết nghiệp vụ
    components/<tên>/    thành phần của riêng một tính năng
    lib/                 gọi API, hook dữ liệu, hàm tiện ích
    messages/vi.ts       mọi chuỗi hiển thị
packages/
  contract/src/          schema Zod của mọi yêu cầu và phản hồi
  db/src/                schema bảng, migration, truy vấn
  core/src/              logic tiền thuần (có từ mốc 1A)
docs/                    tài liệu; agent triển khai không sửa
```

Quy tắc phụ thuộc: `web → contract`; `api → contract, db, core`; `core` không phụ thuộc gì. Không nhập chéo giữa `apps/`. Không tạo thư mục mới ở cấp này khi chưa được đồng ý.

Chưa có file thứ hai cùng loại thì chưa cần thư mục: đừng tạo `utils/`, `helpers/`, `types/`, `constants/` để chứa một file.

## 2. Đặt tên

| Thứ | Quy ước | Ví dụ |
|---|---|---|
| File và thư mục | `kebab-case` | `create-session.ts`, `dev-login/` |
| File component React | `PascalCase` | `MemberShape.tsx` |
| Biến, hàm | `camelCase` | `findSessionUser` |
| Kiểu, component | `PascalCase` | `UserDto`, `MemberShape` |
| Hằng số cấp module | `SCREAMING_SNAKE_CASE` | `SESSION_TTL_MS` |
| Bảng và cột database | `snake_case`, bảng số nhiều | `sessions.token_hash` |
| Trường JSON của API | `camelCase` | `avatarUrl` |
| Mã lỗi | `SCREAMING_SNAKE_CASE` | `UNAUTHENTICATED` |

- **Hàm là động từ**, nói đúng việc nó làm và thứ nó trả: `createSession`, `findSessionUser`, `deleteSession`. Hàm trả `null` khi không thấy bắt đầu bằng `find`; hàm ném lỗi khi không thấy bắt đầu bằng `get`.
- **Giá trị đúng/sai** bắt đầu bằng `is`, `has`, `can`, `should`: `isExpired`, `hasVerifiedEmail`.
- **Không viết tắt**, trừ những từ ai cũng hiểu (`id`, `url`, `db`, `dto`). Viết `transaction`, không viết `tx` hay `txn`; `member`, không `mem`.
- **Đơn vị nằm trong tên** khi kiểu không nói lên: `SESSION_TTL_MS`, `amountMinor`, `expiresAt`.
- **Không dùng tên rỗng nghĩa**: `data`, `info`, `item`, `temp`, `handle`, `process`, `manager`, `util`. Nếu không nghĩ ra tên cụ thể thì hàm đang làm quá nhiều việc.
- Code, tên và comment viết bằng **tiếng Anh**. Chuỗi hiển thị cho người dùng viết bằng tiếng Việt và chỉ nằm trong `messages/vi.ts`.

**Từ vựng nghiệp vụ.** Dùng đúng một từ tiếng Anh cho mỗi khái niệm, ở mọi nơi:

| Tiếng Việt | Trong code |
|---|---|
| Nhóm | `group` |
| Thành viên (một cái tên trong nhóm) | `member` |
| Người dùng (một tài khoản) | `user` |
| Giao dịch | `transaction` |
| Chi tiêu, chuyển khoản, thu nhập | `expense`, `transfer`, `income` |
| Người trả | `payer` |
| Phần một người chịu | `share` |
| Cách chia | `split` |
| Số dư | `balance` |
| Lượt chuyển đề xuất | `settlement` |
| Lời mời | `invite` |
| Phiên đăng nhập | `session` |

## 3. TypeScript

- `strict` bật hoàn toàn, kèm `noUncheckedIndexedAccess` và `exactOptionalPropertyTypes`.
- Không `any`. Dữ liệu chưa biết kiểu là `unknown`, rồi thu hẹp bằng schema Zod.
- Không ép kiểu bằng `as` để cho qua trình biên dịch, không dùng `!`. Ngoại lệ duy nhất là `as const`.
- Kiểu của dữ liệu qua ranh giới được suy ra từ schema Zod (`z.infer`), không viết tay lần hai.
- Dùng union của chuỗi thay cho `enum`. Dùng `type` cho dữ liệu, `interface` chỉ khi cần được mở rộng.
- Chỉ `export` có tên. `export default` chỉ ở nơi framework bắt buộc (trang và layout của Next.js, file cấu hình).
- Ưu tiên `const`, hàm thuần và dữ liệu không đổi. Không sửa tham số đầu vào.
- Hàm có hơn ba tham số nhận một đối tượng có tên trường.
- Dùng `async`/`await`; không để promise trôi nổi không ai chờ.
- Trả về sớm thay cho lồng `if`. Không có `else` sau `return`.

## 4. Xử lý lỗi

- Lỗi nghiệp vụ ở API ném `AppError(status, code, message, details?)`; bộ xử lý chung đổi nó thành định dạng lỗi của đặc tả API. Không tự dựng phản hồi lỗi trong route.
- Không nuốt lỗi: không có `catch` rỗng, không `catch` rồi chỉ log và đi tiếp như không có gì.
- Chỉ `try/catch` ở nơi thực sự xử lý được lỗi. Còn lại để lỗi nổi lên bộ xử lý chung.
- Lỗi không lường trước trả 500 với thông điệp chung và được log đầy đủ kèm `requestId`.
- Ở web, mọi lời gọi API đi qua `apiFetch`; màn hình có dữ liệu luôn có trạng thái đang tải, lỗi và trống.

## 5. API

- **Route** khai báo đường dẫn, gắn schema từ `contract`, gọi một hàm service và trả kết quả. Không truy vấn database, không có điều kiện nghiệp vụ.
- **Service** là một hàm cho một thao tác nghiệp vụ. Nó mở transaction khi ghi nhiều bảng, gọi `core` để tính, và ghi dữ liệu.
- **Truy vấn** nằm trong `packages/db`, có kiểu, không chứa quy tắc nghiệp vụ.
- Mọi yêu cầu và phản hồi có schema trong `packages/contract`. Không trả về đối tượng lấy thẳng từ database; ánh xạ sang DTO.
- Thời gian hiện tại lấy qua `deps.now()`, không gọi `new Date()` rải rác trong logic.

## 6. Database

- Thay đổi cấu trúc chỉ qua migration sinh bằng `drizzle-kit generate`. Không sửa migration đã commit; cần đổi thì tạo migration mới.
- Quy tắc toàn vẹn nằm trong database (khoá ngoại, `UNIQUE`, `CHECK`, `NOT NULL`), không chỉ trong code.
- Ghi nhiều bảng cho một thao tác thì dùng một transaction.
- Không `select *` trong truy vấn trả ra ngoài; chọn đúng cột cần.

## 7. Web

- Dữ liệu từ server đi qua TanStack Query. Không sao chép nó vào `useState`.
- Trạng thái cục bộ để gần nơi dùng nhất. Chưa cần thì chưa đưa thư viện quản lý trạng thái vào.
- Một file một component được `export`. Component quá 150 dòng thì tách phần con.
- Màu, cỡ chữ, bo góc lấy từ token trong `globals.css`. Không viết mã màu trực tiếp trong component.
- Mọi chuỗi người dùng nhìn thấy nằm trong `messages/vi.ts`.
- Phần tử bấm được là `<button>` hoặc `<a>` thật; có nhãn đọc được; vùng chạm tối thiểu 44×44; dùng được bằng bàn phím.
- Hình của thành viên luôn vẽ bằng `MemberShape`. Không tự vẽ lại ở nơi khác.
- Không đổi bố cục, màu, chữ, câu chữ hay hành vi so với `docs/06-ux-ui/user-flows.md` và kế hoạch của task. Thấy thiết kế thiếu hoặc không làm được: hỏi.

## 8. Comment

Viết comment khi người đọc sau sẽ hỏi "sao lại làm thế này?":

```ts
// Hash before lookup so a malformed cookie simply fails to match,
// instead of reaching the database as raw input.
const tokenHash = sha256Hex(token);
```

Không viết comment nhắc lại code (`// create session`), không để lại code bị comment, không `TODO` không có người nhận. Thứ gì cần comment dài để hiểu thì đặt lại tên hoặc tách hàm trước.

## 9. Khi nào dùng mẫu thiết kế

| Tình huống | Cách làm |
|---|---|
| Cùng một việc có nhiều cách thực hiện chọn lúc chạy (ví dụ nhiều cách chia tiền) | Một bảng ánh xạ từ tên sang hàm; mỗi hàm cùng chữ ký |
| Cần thay thứ phụ thuộc bên ngoài (đồng hồ, gửi thư, database) | Truyền vào qua tham số `deps`, không nhập trực tiếp trong logic |
| Dữ liệu có vài dạng loại trừ nhau (ví dụ kết quả `ok`, `needs_input`, `unparsed`) | Union có trường phân biệt, xử lý bằng `switch` đủ nhánh |
| Một thao tác gồm nhiều bước phải cùng thành công | Một hàm service với một transaction |
| Logic lặp lại ở ba nơi trở lên | Tách hàm chung, đặt cạnh nơi dùng |

Không dùng lớp khi một hàm là đủ. Không dựng tầng trung gian (repository cho từng bảng, factory, container phụ thuộc) khi chưa có nhu cầu cụ thể trong task.

## 10. Tiền

- Tiền là số nguyên theo đơn vị nhỏ nhất (VND: đồng), kiểu `bigint` trong database.
- Mọi phép chia và làm tròn tiền chỉ nằm trong `packages/core`. API gọi `core`; web hiển thị con số API trả về.
- Không dùng phép chia số thực, `toFixed`, `Math.round` trên tiền ở bất kỳ nơi nào khác.
- Định dạng hiển thị là `150.000 đ`, làm ở web bằng một hàm duy nhất.
