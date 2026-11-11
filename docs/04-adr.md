# 04 — ADR (Nhật ký quyết định kiến trúc)

Cập nhật: 2026-11-11. Bản sửa đổi thứ ba (nội bộ trước, phát hành công khai sau; đăng ký bằng email) đã duyệt.

Mỗi mục ghi một quyết định: bối cảnh, lựa chọn, các phương án đã cân nhắc và hệ quả. Quyết định đã ghi không sửa; khi thay đổi thì thêm mục mới và đánh dấu mục cũ là "đã thay thế".

Phiên bản cụ thể của từng công nghệ sẽ được chốt khi khởi tạo dự án (giai đoạn 0), lấy bản ổn định mới nhất tại thời điểm đó.

## Bảng công nghệ

| Lớp | Lựa chọn | ADR |
|---|---|---|
| Ngôn ngữ web và server | TypeScript | 002 |
| Runtime server | Node.js bản LTS | 003 |
| Framework API | Hono | 003 |
| Database | PostgreSQL | 004 |
| Truy cập database | Drizzle ORM | 004 |
| Kiểm tra dữ liệu và hợp đồng API | Zod, sinh OpenAPI | 005 |
| Web | Next.js, React | 006 |
| Dữ liệu phía web | TanStack Query | 006 |
| Giao diện web | Tailwind CSS, shadcn/ui | 006 |
| Đăng nhập | Google OAuth, phiên lưu trong database, thư viện Better Auth | 007 |
| Realtime | Server-Sent Events | 008 |
| Tác vụ nền (từ giai đoạn 3) | Hàng đợi trong Postgres (pg-boss) | 010 |
| Kiểm tra | Không test tự động; kiểm kiểu, lint (Biome) và kiểm tay | 016 |
| Quản lý mã nguồn | Monorepo, pnpm workspaces | 012 |
| Triển khai | Docker Compose, Caddy, VM Ubuntu | 013 |
| iOS | Swift, SwiftUI | 014 |
| Android | Kotlin, Jetpack Compose | 014 |

---

## ADR-001 — API độc lập, client mỏng

**Trạng thái:** đã chốt.

**Bối cảnh.** Sản phẩm có ba client viết bằng ba ngôn ngữ. Settle Up đặt logic ở client và phải lặp lại nó ba lần.

**Quyết định.** Một dịch vụ API độc lập chứa toàn bộ logic nghiệp vụ. Client chỉ hiển thị và gửi đầu vào.

**Đã cân nhắc.** (a) Supabase làm nền với dịch vụ Node nhỏ: ít code hạ tầng hơn nhưng quyền truy cập phải viết hai lần và gắn với nhà cung cấp. (b) Next.js full-stack: một ứng dụng để deploy nhưng API bị buộc vào web, khó làm tác vụ nền, phải tách ra khi làm iOS.

**Hệ quả.** Tự làm phần đăng nhập, realtime và lưu file. Đổi lại, mọi logic nằm một chỗ và không phụ thuộc nhà cung cấp.

## ADR-002 — TypeScript ở server thay vì Go hoặc Rust

**Trạng thái:** đã chốt.

**Bối cảnh.** Chủ dự án quen TypeScript và đã cân nhắc Go, Rust cho server.

**Quyết định.** TypeScript trên Node.js.

**Đã cân nhắc.** Go: hiệu năng và triển khai tốt, nhưng thêm một ngôn ngữ và mất khả năng dùng chung schema với web. Rust: không có phần nào của bài toán cần mức hiệu năng hay an toàn bộ nhớ đó, tốc độ phát triển chậm hơn.

**Hệ quả.** Web và server dùng chung kiểu dữ liệu và schema. Hiệu năng thấp hơn Go nhưng thừa cho quy mô nội bộ.

## ADR-003 — Node.js và Hono thay vì Bun

**Trạng thái:** đã chốt.

**Bối cảnh.** Bun nhanh hơn và tiện hơn trong phát triển, nhưng dự án sẽ dùng nhiều thư viện đa dạng (xử lý ảnh, SDK bot, SDK AI).

**Quyết định.** Chạy production trên Node.js LTS. Dùng Hono vì nó chạy được trên cả Node và Bun, giữ quyết định này đảo ngược được. Không dùng API riêng của Bun trong code.

**Đã cân nhắc.** Bun làm runtime: lợi thế tốc độ không có ý nghĩa khi nút thắt là database và lệnh gọi AI; rủi ro tương thích thư viện là có thật. Fastify, NestJS: tốt nhưng gắn với Node hoặc nặng hơn nhu cầu.

**Hệ quả.** Có thể dùng Bun làm công cụ phát triển nếu muốn. Chuyển runtime sau này chỉ cần đổi lệnh khởi động.

## ADR-004 — PostgreSQL và Drizzle

**Trạng thái:** đã chốt.

**Bối cảnh.** Settle Up dùng Firebase Realtime Database, yếu về truy vấn và báo cáo. Giai đoạn 2 cần thống kê và ngân sách.

**Quyết định.** PostgreSQL là kho dữ liệu duy nhất. Drizzle để định nghĩa schema và truy vấn có kiểu.

**Đã cân nhắc.** Firebase, MongoDB: không có ràng buộc và phép gộp dữ liệu mà bài toán sổ sách cần. SQLite: đủ cho quy mô này nhưng kém khi cần worker riêng và hàng đợi. Prisma: chín hơn nhưng nặng hơn và kém linh hoạt với SQL viết tay cho câu truy vấn số dư.

**Hệ quả.** Ràng buộc toàn vẹn đặt ngay trong database. Phải tự lo sao lưu.

## ADR-005 — Zod là nguồn duy nhất của hợp đồng API

**Trạng thái:** đã chốt.

**Bối cảnh.** Hợp đồng API được dùng ở bốn nơi: kiểm tra đầu vào ở server, kiểu dữ liệu ở web, tài liệu, và client Swift, Kotlin.

**Quyết định.** Schema Zod trong `packages/contract` là nguồn duy nhất. Server dùng nó để kiểm tra, web nhập kiểu trực tiếp, file OpenAPI được sinh từ nó, client mobile sinh từ OpenAPI.

**Đã cân nhắc.** Viết OpenAPI bằng tay rồi sinh code: thêm một bước và dễ lệch với code. tRPC: tiện cho web nhưng không dùng được cho Swift, Kotlin.

**Hệ quả.** Tài liệu API không thể lệch khỏi code. [05 — Đặc tả API](05-api-spec.md) là bản thiết kế cho người đọc; file OpenAPI chính thức sinh ra khi có code.

## ADR-006 — Next.js cho web

**Trạng thái:** đã chốt; phần giao diện có thể điều chỉnh ở giai đoạn 0.

**Bối cảnh.** Chủ dự án dùng được cả React/Next.js và Vue/Nuxt. Web chỉ là một client của API.

**Quyết định.** Next.js với React. TanStack Query giữ dữ liệu từ API và bộ đệm để xem khi mất mạng. Tailwind CSS và shadcn/ui cho giao diện.

**Đã cân nhắc.** Nuxt: tương đương về khả năng; chọn Next vì hệ sinh thái thư viện React rộng hơn. Ứng dụng React thuần không có framework: đơn giản hơn nhưng mất định tuyến và tối ưu tải trang có sẵn.

**Hệ quả.** Web không dùng các tính năng truy cập dữ liệu phía server của Next.js để gọi database; mọi dữ liệu đi qua API.

## ADR-007 — Đăng nhập Google, phiên lưu ở server

**Trạng thái:** đã chốt; thư viện cần xác nhận ở giai đoạn 0.

**Bối cảnh.** Ứng dụng nội bộ, không muốn quản lý mật khẩu. iOS sau này bắt buộc có đăng nhập Apple.

**Quyết định.** Đăng nhập bằng Google qua OAuth. Phiên lưu trong Postgres; web nhận cookie HttpOnly, mobile gửi mã phiên qua header. Dùng thư viện Better Auth cho luồng OAuth và quản lý phiên.

**Đã cân nhắc.** JWT không trạng thái: không thu hồi được phiên ngay. Dịch vụ đăng nhập ngoài (Auth0, Clerk): thêm phụ thuộc và chi phí không cần thiết. Tự viết toàn bộ: dễ sai ở phần bảo mật.

**Hệ quả.** Đăng xuất và gỡ quyền có hiệu lực ngay. Ở giai đoạn 0 cần kiểm tra thư viện hỗ trợ đúng mô hình cookie cho web và header cho mobile; nếu không, thay bằng thư viện OAuth tối giản và tự quản lý bảng phiên.

**Sửa đổi 2026-11-11.** Thêm đăng ký bằng email và mật khẩu có xác minh, xem ADR-015. Phần "phiên lưu ở server" giữ nguyên.

## ADR-008 — Realtime bằng SSE, sự kiện chỉ là tín hiệu

**Trạng thái:** đã chốt.

**Bối cảnh.** Cần hiển thị thay đổi của người khác trong vài giây. Client không ghi qua kênh realtime.

**Quyết định.** Server-Sent Events, một kết nối cho nhóm đang xem. Sự kiện chỉ báo loại dữ liệu đã đổi; client tải lại qua API thường.

**Đã cân nhắc.** WebSocket: hai chiều, không cần ở đây, phức tạp hơn qua proxy. Đẩy dữ liệu trong sự kiện: nhanh hơn một chút nhưng tạo đường đọc thứ hai phải kiểm tra quyền riêng. Hỏi định kỳ: đơn giản nhất nhưng chậm hoặc tốn tài nguyên.

**Hệ quả.** Một đường đọc dữ liệu, một chỗ kiểm tra quyền. Mỗi thay đổi kéo theo một lượt tải lại ở mỗi client đang mở, chấp nhận được ở quy mô này.

## ADR-009 — Tiền là số nguyên; lưu cả kết quả lẫn đầu vào

**Trạng thái:** đã chốt.

**Bối cảnh.** Settle Up lưu trọng số dạng chuỗi và để mỗi client tự tính số tiền.

**Quyết định.** Số tiền lưu bằng số nguyên theo đơn vị nhỏ nhất của tiền tệ. Server tính phần của từng người một lần và lưu kết quả; đồng thời lưu đầu vào gốc (cách chia và con số người dùng nhập) để màn hình sửa hiện lại đúng. Số dư và lượt chuyển không lưu mà tính khi đọc.

**Đã cân nhắc.** Kiểu thập phân của database: chính xác nhưng dễ lọt số lẻ khi qua JSON và JavaScript. Chỉ lưu trọng số: mỗi client phải làm tròn giống hệt nhau. Lưu bảng nợ: nhanh hơn khi đọc nhưng có thể lệch khỏi giao dịch.

**Hệ quả.** Mọi client thấy cùng con số. Đổi quy tắc làm tròn không ảnh hưởng giao dịch cũ.

## ADR-010 — Hàng đợi tác vụ trong Postgres

**Trạng thái:** đã chốt cho giai đoạn 3; chưa triển khai.

**Quyết định.** Dùng pg-boss, hàng đợi chạy trên Postgres, cho OCR, bot và nhắc nợ.

**Đã cân nhắc.** Redis với BullMQ: mạnh hơn nhưng thêm một dịch vụ phải vận hành và sao lưu.

**Hệ quả.** Không thêm thành phần hạ tầng. Tác vụ được sao lưu cùng dữ liệu.

## ADR-011 — Chiến lược kiểm thử

**Trạng thái:** bị thay thế bởi ADR-016 ngày 2026-11-11.

**Quyết định.** Test đơn vị và test theo thuộc tính (fast-check) cho `core`. Test tích hợp API trên Postgres thật chạy bằng Testcontainers. Một số ít kịch bản Playwright cho luồng chính của web. Bảng test quyền bao phủ mọi endpoint với bốn loại người gọi.

**Đã cân nhắc.** Giả lập database trong test: nhanh hơn nhưng bỏ sót lỗi ràng buộc và truy vấn, là nơi rủi ro nhất.

**Hệ quả.** Bộ test cần Docker để chạy.

## ADR-012 — Monorepo với pnpm workspaces

**Trạng thái:** đã chốt.

**Quyết định.** Một kho mã chứa API, web và các gói dùng chung, quản lý bằng pnpm workspaces. Mã iOS và Android nằm ở kho riêng khi bắt đầu.

**Đã cân nhắc.** Nhiều kho: thay đổi hợp đồng API phải đồng bộ qua nhiều nơi. Turborepo hoặc Nx: chưa cần ở quy mô hai ứng dụng.

**Hệ quả.** Một thay đổi hợp đồng nằm gọn trong một commit cho cả server và web.

## ADR-013 — Docker Compose trên một VM

**Trạng thái:** đã chốt.

**Quyết định.** Chạy toàn bộ bằng Docker Compose trên VM Ubuntu sẵn có, Caddy lo HTTPS. Sao lưu database hằng đêm ra ngoài VM.

**Đã cân nhắc.** Dịch vụ quản lý sẵn: ít vận hành hơn, nhưng đã có máy chủ. Kubernetes: thừa.

**Hệ quả.** Một điểm lỗi duy nhất; sao lưu ngoài máy là bắt buộc, không phải tuỳ chọn.

## ADR-014 — Mobile native

**Trạng thái:** đã chốt hướng; chi tiết quyết định khi bắt đầu giai đoạn 5.

**Quyết định.** iOS bằng Swift và SwiftUI trước, Android bằng Kotlin và Jetpack Compose sau. Cả hai dùng client sinh từ OpenAPI.

**Đã cân nhắc.** React Native, Flutter: một codebase cho hai nền tảng, nhưng chủ dự án ưu tiên trải nghiệm và công cụ native.

**Hệ quả.** Mỗi tính năng giao diện phải làm ba lần. Điều này củng cố ADR-001: logic không được nằm ở client.


## ADR-015 — Đăng ký mở: Google, và email kèm mật khẩu có xác minh

**Trạng thái:** đề xuất, đã duyệt. Bổ sung ADR-007.

**Bối cảnh.** Mục tiêu đổi từ "chỉ dùng nội bộ" sang "nội bộ trước, phát hành công khai sau". Với người dùng công khai, không thể giả định ai cũng có và muốn dùng tài khoản Google, và việc phụ thuộc một nhà cung cấp duy nhất là rủi ro cho người dùng.

**Quyết định.** Hai cách đăng nhập ngang hàng từ giai đoạn 1: Google, và email kèm mật khẩu có xác minh email. Ai cũng đăng ký được. Định danh nhà cung cấp tách khỏi bảng `users` ngay từ đầu (`user_identities`). Gửi thư đi qua một lớp trừu tượng: ở máy local thư in ra console, ở máy chủ dùng một dịch vụ gửi thư được chọn ở bước "Đưa lên máy chủ".

**Đã cân nhắc.**
- Chỉ Google: ít việc nhất, nhưng loại người không dùng Google và phụ thuộc một nhà cung cấp.
- Mật khẩu không xác minh email: không cần gửi thư, nhưng ai cũng đăng ký được bằng email của người khác và không có đường đặt lại mật khẩu. Không chấp nhận được cho sản phẩm công khai.
- Link đăng nhập qua email, không mật khẩu: gọn, nhưng mỗi lần đăng nhập phụ thuộc việc thư đến kịp; để dành như một lựa chọn bổ sung về sau.

**Hệ quả.** Thêm bốn màn hình (đăng ký, xác minh, quên mật khẩu, đặt lại) và một dịch vụ gửi thư khi lên máy chủ. Ứng dụng phải tự lo an toàn mật khẩu (NFR-1.12, 1.13). Thêm đăng nhập Apple ở giai đoạn 5 chỉ là thêm một loại định danh.

## ADR-016 — Không viết test tự động; chủ dự án kiểm tay

**Trạng thái:** đã chốt ngày 2026-11-11 theo quyết định của chủ dự án. Thay thế ADR-011.

**Bối cảnh.** Việc triển khai do các agent thực hiện; chủ dự án muốn đi nhanh và tự tay kiểm sản phẩm sau mỗi task và mỗi mốc.

**Quyết định.** Dự án không viết test tự động ở bất kỳ tầng nào. Chất lượng được giữ bằng bốn thứ: kiểm kiểu chặt và lint là cổng bắt buộc trước mỗi commit; schema Zod ở mọi ranh giới và ràng buộc trong database để trạng thái sai không biểu diễn được; agent tự chạy thử và dán kết quả thật vào báo cáo; mỗi task có danh sách kiểm tay cho chủ dự án, và cố vấn review diff của từng commit. Quy định chi tiết ở `AGENTS.md` mục 6.

**Đã cân nhắc.** Giữ chiến lược của ADR-011 (test đơn vị, test tích hợp trên Postgres thật, test đầu cuối): an toàn hơn khi sửa code về sau, nhưng làm chậm từng task và tăng lượng code agent phải viết và giữ đúng.

**Hệ quả.**
- Mỗi task nhanh hơn và ít code hơn.
- Lỗi hồi quy (sửa chỗ này làm hỏng chỗ khác) không có gì tự động bắt; càng nhiều tính năng, lượng kiểm tay lại càng lớn.
- Các bất biến về tiền ("tổng số dư của nhóm luôn bằng 0", làm tròn không lệch một đồng) và bảng quyền theo từng endpoint là hai chỗ kiểm tay khó phủ hết. Cố vấn đã đề xuất ngoại lệ cho phép test riêng `packages/core`; chủ dự án quyết định ngày 2026-11-11 là không có ngoại lệ nào. Bù lại, kế hoạch mốc 1A phải có: ràng buộc trong database kiểm tổng phần chịu và tổng phần trả bằng tổng tiền, một lệnh kiểm tra tổng số dư của mọi nhóm bằng 0 để chủ dự án chạy bất cứ lúc nào, và một bảng các trường hợp chia tiền kèm kết quả đúng để kiểm tay.
