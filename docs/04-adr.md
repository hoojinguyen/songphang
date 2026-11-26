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

**Quyết định.** Một kho mã chứa API, web và các gói dùng chung, quản lý bằng pnpm workspaces. Mã iOS và Android nằm ở kho riêng khi bắt đầu. *(The last sentence is replaced for iOS by ADR-033, 2026-11-16.)*

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

## ADR-017 — Own session layer; Google through `arctic`; argon2id from Node

**Status:** decided 2026-11-12. Replaces the library choice left open in ADR-007; the rest of ADR-007 and ADR-015 stands.

**Context.** ADR-007 named Better Auth "to be confirmed". Phase 0 already built and checked a session layer with the required model: a cookie for the web, a header for mobile, only hashes in the database. Better Auth (1.7.22) manages its own user, session, and account tables and brings sixteen direct dependencies.

**Decision.** Keep the project's own sessions and the `user_identities` design. Hash passwords with argon2id from `node:crypto`. Use `arctic` only for the Google authorization-code flow. Single-use tokens for email verification and password reset are stored as hashes in `auth_tokens`.

**Considered.** Better Auth: less code to write, but it would discard verified work and an approved data model, and add a large dependency surface to the most security-sensitive part. Writing the OAuth flow by hand: possible, but that flow cannot be exercised against Google during the phase run, so verified library code is safer.

**Consequences.** The project owns account security (NFR-1.12, 1.13) and must review it carefully. Adding Apple sign-in in phase 5 is one more identity provider.

## ADR-018 — One agent run per phase, with gates and a decision log

**Status:** decided 2026-11-12 by the project owner. Changes how ADR-016's four activities are scheduled; ADR-016 itself stands.

**Context.** Phase 0 was built task by task, with the owner assigning and approving each task. The owner wants one agent run to build a whole phase.

**Decision.** A phase is built in one continuous run on its own branch. All decisions are settled beforehand in a spec; what remains open the agent decides and records. After each stage the agent runs a gate: type checking, build, acceptance scripts of this and earlier stages, the balance check, and the permission matrix. The advisor reviews the whole branch at the end; the owner then checks by hand once and merges. Details: `AGENTS.md` section 12.

**Considered.** Task-by-task approval (phase 0): safest, but every task waits for a person. One run without gates: fastest, but with no automated tests an early money or permission defect would be built upon by every later stage.

**Consequences.** Far fewer hand-offs. Visual defects are found only at the final manual check, and that check is long. The agent's exercises are self-graded, so the advisor re-runs every gate. Google sign-in in phase 1 ships unverified until the owner creates the OAuth app.

## ADR-033 — iOS code in this repository; interface built first on scripted data

**Status:** decided 2026-11-16 by the project owner. Replaces the last sentence of ADR-012 for iOS. (Numbers 019–032 are reserved by the specs of the remaining phases.)

**Context.** ADR-012 put the mobile code in separate repositories. The project is built by one person through agents: the agent porting a screen needs the web source, the strings and the API contract beside it, and one set of documents and rules. The owner also wants the iPhone interface built now, in parallel with the API and web work, without conflicting with it.

**Decision.** The iOS application lives in `apps/ios/` of this repository, with its own `AGENTS.md` for Swift-specific rules. It is built in two stages. The interface stage (5U) builds every phase 1 screen on scripted fakes, on branch `ios-ui` in its own git worktree, writing only under `apps/ios/` and its run directory. The integration stage follows stage 5A of phase 5: it adds the generated client and the live repositories, replaces the fakes at the composition root, and brings the screens up to date with whatever changed in the web and the contract since the recorded baseline commit.

**Considered.** A separate repository (ADR-012): isolation for free, but a second set of rules and documents, a copied contract file, and no single commit spanning API and application. Waiting for the API: no rework, but the interface, which is most of the work, starts months later.

**Consequences.** `biome.json` and `.gitignore` gain entries for `apps/ios`. Parallel agents must each work in their own worktree. The domain types of the interface stage are written against today's contract; a later change to the contract is paid for once, in the integration stage, and is confined to `Domain`, the mappings and the screens that use the changed field. The interface stage proves nothing about networking, sign-in or real launch time. Whether Android follows the same arrangement is decided with phase 6.



## ADR-019 — Optional external services and capabilities

Status: approved 2026-11-17 for later phase runs. Optional service capabilities sit behind deps interfaces and explicit real/local providers. Production refuses fake or console providers. Public GET /api/v1/features reports availability; disabled endpoints return 404. Phase 2 introduces the endpoint with later optional capabilities disabled, without any external adapter or new environment variable.

## ADR-021 — Fund as a special ledger member

Status: approved 2026-11-17. A single member of kind fund uses the existing ledger and settlement arithmetic. Its cash is negative its balance; it can pay, hold income and participate in transfers but never bear expense/income shares or be claimed. Services and database triggers enforce this. A separate ledger was rejected because it duplicates integrity and money rules. See Phase 2 spec section 6.

## ADR-022 — Settlement requires authorized receiver confirmation

Status: approved 2026-11-17. A payment report creates only a pending request. The authorized receiver/owner, or editor for an unlinked receiver, atomically creates one transfer while resolving it. Duplicate confirmation returns 409. Pending requests do not reserve debt; the existing direct editor transfer remains available. No bank API is called and payment is never automatically verified.

## Phase 2 implementation provenance amendment — 2026-11-17

The owner approved VietQR.io by Casso's public bank list as the data source instead of NAPAS's inaccessible complete mapping. Snapshot source https://api.vietqr.io/v2/banks, retrieved 2026-11-17; 76 entries. It is not represented as NAPAS-certified. Reuse installed qrcode 1.5.4 and its React SVG matrix rendering instead of planned uqr; no new library. All feature implementation and exercises after preparation remain local.

## ADR-023 — Store item splits in split_input

Status: approved by the owner on 2026-11-17 with the revised Phase 3 spec/plan; implementation has not started.

Decision: the fifth split method, `items`, stores 1–60 ordered items and at most six extras in `transactions.split_input`. Do not create the earlier proposed `transaction_items` or `item_assignments` tables: no approved feature queries items across transactions. The existing stored shares remain the authoritative ledger. Each item is divided equally in member-position order; net extras are allocated proportionally through the existing BigInt largest-remainder allocator in core. Fund members cannot bear shares. Income cannot use items.

The dedicated items-preview contract returns the computed total, optional authoritative shares and incomplete-input issues; the browser does not sum item money. Ordinary preview/create/edit still validate a complete amount and split. Existing fixed Phase 3 arithmetic references remain unchanged. Normalizing items into separate tables was rejected because it adds writes, queries and constraints without an approved use. See Phase 3 spec sections 6 and 15.4.

## ADR-024 — AI adapters, private member references and reserved attempts

Status: approved by the owner on 2026-11-17 with the revised Phase 3 spec/plan; implementation has not started.

Decision: receipt and sentence readers are replaceable deps interfaces with local fake adapters and a fetch-based real adapter. The agent never calls the real provider. Forced structured output is untrusted: validate the provider schema, resolve request-local references in API memory, validate the ordinary UUID draft, then compute shares only in core. Only user confirmation saves a transaction. Rule `ok`/`needs_input` never invokes sentence AI.

Real member/user/group IDs and email never leave the server. Every request uses a fresh cryptographic nonce namespace; every payer and split reference is mapped only in request memory. Unknown references make a draft non-confident and never `ok`. Neither prompts, raw responses nor reference-to-ID maps are logged or persisted; only the validated receipt reading is stored in the scan. Raw images remain private FileStore data.

The cost ceiling counts reserved provider attempts, including retry and uncertain outcomes. One group-locked transaction creates the unique scan, admission reservation and durable job. The worker atomically claims the existing reservation; redelivery cannot cause a second unreserved call. Receipts allow one separately reserved retry; sentences have an eight-second overall deadline and no retry. Claim/recovery metadata prevents indefinite processing. Database transaction integration for the installed stable pg-boss version must be demonstrated before scan implementation; otherwise an advisor outbox amendment is required. See Phase 3 spec section 15.3.

Hand-writing a queue, accepting model-computed money and sending persistent database IDs were rejected. pg-boss is the only approved new external library; version/license/size are recorded at installation, not guessed during preparation. Shared storage/AI workspace packages contain reused code and are not external libraries.

## ADR-034 — UI/UX v2 navigation shell, 3-segment group detail, full-width feed cards, and Web Desktop layout

**Status:** approved by the project owner on 2026-11-24 with the Phase 5.5 overview and Wave 5.5A specs; implementation pending on `phase-5-5a`.

**Context.** Physical iPhone acceptance during Phase 5 (`TD-006`) demonstrated that single-stream chat-bubble cards and inline per-person split chips wrap amounts across lines on 7+ member splits and overcrowd `S4` as Phases 2–4 features accumulated. Waves 5.5A–C also introduce cross-group overview, personal ledger, settlement history/cycles, and recurring bills.

**Decision.** Adopt a 4-tab app shell (`Tổng quan`, `Nhóm`, `Thông báo`, `Tài khoản`), a 3-segment group detail shell (`Chi tiêu`, `Thanh toán`, `Quỹ & Thống kê`), 3-row full-width transaction cards displaying server-computed `myDelta` instead of indented chat bubbles and inline share chips, and a 2–3 column responsive Web Desktop layout (`>= 1024px` / `>= 1280px`). On iOS, place Cross-Group Overview and Personal Ledger in a new `OverviewFeature` module (`Domain`, `DesignSystem`, `PreviewSupport` only) and host the 3-segment group container (`GroupContainerView`) in `AppShell` so feature modules never import one another (`apps/ios/AGENTS.md` §3). Preserve all existing Web deep routes and additive-only `/api/v1` contract compatibility.

**Considered.** Keeping a single feed screen with nested sheets (worsens discoverability and horizontal density); letting `LedgerFeature` import `PaymentsFeature` and `StatisticsFeature` (violates compiler-enforced module boundaries).

## ADR-035 — Per-device Light/Dark theme persistence, semantic tokens, and bundled Be Vietnam Pro .ttf on iOS

**Status:** approved by the project owner on 2026-11-24; implementation pending on `phase-5-5a`.

**Context.** Physical iPhone screenshots (`TD-004`, missing `.ttf` fonts in Phase 5) showed default SwiftUI placeholders have poor contrast on white fields, and iOS fell back to system fonts because `apps/web/public/fonts/be-vietnam-pro/` ships `.woff2` files only.

**Decision.** Define WCAG-verified Light and Dark semantic color tokens across `apps/web/src/app/globals.css` and `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/Tokens.swift` (including explicit `placeholder`, `credit`, `debt`, `warning`, `surfaceElevated`, and `borderSubtle`). Persist appearance mode (`system` | `light` | `dark`) per device only (`@AppStorage("appearanceMode")` on iOS; `localStorage` plus a static synchronous `/theme-init.js` script setting `data-theme` on `<html>` on Web — never `dangerouslySetInnerHTML`, respecting `AGENTS.md` §9). Bundle static `Be Vietnam Pro` `.ttf` weights (`400`–`900`, SIL OFL 1.1) in `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` and register them via `CTFontManagerRegisterFontsForURL` with Dynamic Type scaling and tabular digits (`monospacedDigit()` / `tabular-nums`).

**Considered.** Storing theme preference in PostgreSQL `users` (unnecessary migration and cross-device surprise); keeping iOS on the system font (diverges from Sòng Phẳng's typography identity); inline `dangerouslySetInnerHTML` boot script (violates `AGENTS.md` §9).

## ADR-036 — Cumulative settlement cycles via nullable `transactions.cycle_id` assignment and direct past-row editability

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5B on `phase-5-5b`.

**Context.** Recurring clubs (`G4 Badminton 2026`) collect expenses in batches (`Chốt đợt`) while members pay on different schedules and late-remembered or backdated expenses may still be entered or corrected later.

**Decision.** Add `settlement_cycles` (storing an immutable closeout `snapshot`, `expense_count`, and `total_expense_amount` labeled `Số liệu tại thời điểm chốt`) and a nullable `transactions.cycle_id` foreign key (`ON DELETE SET NULL`). Closing a cycle atomically stamps `cycle_id` only onto counted non-deleted rows (`approval_status IN ('none', 'approved')`), leaving `pending` approvals and newly entered expenses in `Đợt hiện tại` (`cycle_id IS NULL`) regardless of `occurred_at`. Ledger balance queries (`packages/db/src/balances.ts`) remain strictly cumulative across all cycles with zero synthetic balance-resetting entries, `owner`/`editor` may still edit or soft-delete transactions inside closed cycles in place (`PATCH` preserves `cycle_id`), and `owner` may reopen the latest cycle (`DELETE /settlement-cycles/{cycleId}`).

**Considered.** Timestamp-range slicing (causes backdated expenses entered later to vanish silently into already-closed cycles); locking closed-cycle transactions against edits (blocks fixing misassigned participants in earlier batches once a newer cycle closes); synthetic zeroing transfers at closeout (erases unpaid carry-over debt).

## ADR-037 — Opt-in revocable guest read-only links and server-authoritative member debt breakdowns

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5B on `phase-5-5b`.

**Context.** Non-app group members viewing a group link posted to Zalo need transparent proof of *which* prior carry-over and current-period expenses produced their exact balance plus an immediate VietQR code, without exposing bank screenshots or leaving the group public after collection ends.

**Decision.** Add an off-by-default 256-bit `groups.guest_token` managed via `GET/POST/DELETE /groups/{groupId}/guest-link` (never logged to `activity` or server logs; `DELETE` remains allowed when a group is archived) driving unauthenticated IP-rate-limited `GET /guest-links/{token}` and `/guest-links/{token}/attachments/{attachmentId}` (`Cache-Control: private, no-store`, `robots: noindex`). Guest attachment streaming serves only counted `expense`/`income` receipt photos and rejects `transfer` banking proofs (`404`). Both `/share/{token}` and authenticated `Thanh toán` read server-computed `GET /balances/breakdowns` (`cycleId=auto` defaults to the latest closed cycle plus post-closeout transfers whenever `Đợt hiện tại` has zero counted expenses, preserving exact `carryOverBalance + sum(lines.delta) + postCycleDelta === netBalance`).

**Considered.** Requiring account creation to view breakdowns (adds friction for one-off sports guests); sharing raw `transfer_proof` banking screenshots publicly (exposes personal transfer receipts); omitting `auto` cycle fallback (leaves `/share/{token}` empty immediately after closing a batch).

## ADR-038 — Zero-dependency client-side `3x` share card rendering (`ImageRenderer` on iOS, 2D `<canvas>` on Web)

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5B on `phase-5-5b`.

**Context.** Phone screenshots of 12–20+ member groups clip rows, hide receiver payment details, and cannot render crisp Light/Dark cards across both platforms without adding heavy server headless-browser dependencies.

**Decision.** Render `390pt`-wide, dynamic-height `3x` (`1170px` wide) PNG cards directly on-device from authoritative server DTOs (`BalancesResponse`, `MemberBreakdownsResponse`, `SettlementCyclesResponse`, `GuestLinkResponse`) in Light and Dark themes with exact integer VND tabular numerals and zero emoji: SwiftUI `ImageRenderer` (`scale = 3.0`) on iOS and pure HTML5 2D `<canvas>` (awaiting `document.fonts.ready` for `Be Vietnam Pro` and reusing installed `qrcode`) on Web, backed by server-built dynamic (`010212`) and static (`010211`, `accountQrPayload`) VietQR payloads in `@songphang/core`.

**Considered.** Puppeteer/Chromium image rendering on the API (heavy runtime footprint and server CPU load); `html2canvas` on Web (extra dependency and cross-browser font/SVG rendering quirks); client-side VietQR construction (violates `apps/ios/AGENTS.md` §5 and Phase 5.5 anti-goals).

## ADR-039 — Generalized `split_input.extras` with equal water-filling default and server percentage preview

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5C on `phase-5-5c`.

**Context.** Entering restaurant bills (`346.000 đ` + `Thuế GTGT 8% = 27.680 đ`) or delivery orders (`shipping`, `discount` vouchers) manually into a single transaction previously forced users to sum taxes in their head or bury fixed-VND extras inside `method: "items"` without percentage rates or equal allocation.

**Decision.** Extend `SplitInput` across all five split methods (`equal`, `exact`, `shares`, `percent`, `items`) with optional `extras` (`tax`, `service`, `shipping`, `discount`, `other`, optional `ratePercent`) and `extrasAllocation` (`"equal"` | `"proportional"`). Manual entries default to `"equal"` (water-filling non-negative cap when an equal discount exceeds a low-spend participant's base share so shares never go negative and always sum to `amount`), while omitted `extrasAllocation` on legacy `items` rows evaluates as `"proportional"` (`ADR-023`) to preserve historical receipts. Clients send debounced `POST /groups/{groupId}/transactions/extras/preview` requests and perform zero percentage multiplication or rounding locally.

**Considered.** Performing `%` arithmetic on Web/iOS clients (violates `AGENTS.md` §7 and `apps/ios/AGENTS.md` §5); switching legacy `items` rows to `"equal"` by default (mutates historical Phase 3 scan behavior); clamping negative shares without redistributing remaining discount (breaks `sum(shares) === amount`).

## ADR-040 — Recurring expenses (`fixed` / `variable` on `pg-boss`) and household representative consolidation

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5C on `phase-5-5c`.

**Context.** Shared households and sports clubs repeat both fixed bills (`fixed` auto-post) and variable bills (`variable` due prompts), while couples/families need separate member identities on daily meals yet settle externally as one consolidated unit.

**Decision.** Store recurring schedules in `recurring_expenses` executed hourly (`Asia/Ho_Chi_Minh`) by `pg-boss` (`process-recurring`) with single-catchup date advancement (`next_due_date > todayVN` so stalled dev containers or unarchived groups never flood duplicate bills), auto-pausing templates when a referenced member/fund is deactivated (`active = false`), and routing `variable` due prompts to `editor+` users consistent with `POST /transactions` RBAC. Store household groupings in `households` + `members.household_id` (`2..20` active-representative `person` members) and consolidate net balances and transfers exclusively in `@songphang/core` (`suggestHouseholdSettlements`) through `suggestGroupTransfers`, allowing any linked partner in `fromHousehold` to submit/cancel outgoing `settlement_requests` while restricting incoming `confirm`/`reject` to `representative_member_id` / `owner` (`ADR-022`).

**Considered.** Back-posting every missed period on worker restart (floods ledger with stale bills); writing synthetic internal `transfer` transactions between partners (pollutes transaction history and breaks ungrouping); allowing `viewer` partners to confirm incoming bank transfers (weakens `ADR-022` receiver control).

## ADR-041 — iOS App Group snapshot store, shared Keychain migration, and dual-delivery Share Extension handoff

**Status:** approved by the project owner on 2026-11-26; implemented in Wave 5.5C on `phase-5-5c`.

**Context.** Importing bill or transfer screenshots straight from Zalo/Photos (`SongPhangShareExtension`) and displaying Home Screen Widgets (`SongPhangWidgetExtension`) plus Quick Actions requires sharing session auth and read-only overview state safely without violating iOS memory limits (`120 MB` for extensions) or token-security rules.

**Decision.** Share bearer tokens exclusively through a Keychain access group (`TokenStore` with one-time migration from legacy ungrouped entries and Simulator unsigned fallback), store non-secret summaries (`widget-snapshot.json`, `share-groups.json`, `ShareInbox/`) in `ExtensionSharedStore` (`group.vn.songphang.app`, `.completeFileProtectionUntilFirstUserAuthentication`, wiped immediately on sign-out), downsample shared photos with `ImageIO` (`<= 5 MiB`), and pair `songphang://share-import/{batchId}` (`LinkRouter.appActionRoute`) with automatic `RootView` `scenePhase == .active` `ShareInbox` pickup so host apps that suppress `extensionContext?.open` still land cleanly in Sòng Phẳng. `SongPhangWidgetExtension` links only `Domain` and `DesignSystem` and honors `"Ẩn số tiền trên Widget"`.

**Considered.** Storing session tokens in `UserDefaults(suiteName:)` (violates `apps/ios/AGENTS.md` §7); background URLSession polling inside WidgetKit (drains battery and duplicates Repository logic); relying solely on `extensionContext?.open` from Share Extensions (drops imports when host apps like Zalo block URL opening).
