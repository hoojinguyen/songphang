# Sòng Phẳng — Luật làm việc cho agent

File này áp dụng cho mọi agent làm việc trong kho mã này (Claude, Codex, Antigravity và các agent khác). Đọc hết trước khi làm bất cứ việc gì. Nó ngắn có chủ đích; chi tiết nằm ở các file được trỏ tới.

## Language policy

- Communicate with the project owner in Vietnamese.
- Use English for all engineering artifacts, including source code identifiers and comments, documentation, commit messages, branch names, pull request titles and descriptions, review comments, and repository metadata.
- Product-facing text and localized example data follow the approved Vietnamese product requirements.
- This policy takes precedence over older language guidance and examples in project documents.

## 1. Dự án

Sòng Phẳng là ứng dụng chia tiền nhóm cho người dùng Việt Nam: web trước, iOS và Android native sau, chung một API. Dùng nội bộ trước, phát hành công khai sau, nên phần tài khoản, bảo mật và chất lượng giao diện được làm theo chuẩn sản phẩm công khai ngay từ đầu.

Giai đoạn hiện tại: **0 — Nền móng trên máy local**. Mọi thứ chạy trên máy phát triển; không có máy chủ, tên miền hay dịch vụ bên ngoài.

## 2. Ai quyết định gì

| Vai trò | Quyền |
|---|---|
| **Chủ dự án** | Duyệt mọi thay đổi về yêu cầu, giao diện, thư viện. Tự tay kiểm sản phẩm. Lời của chủ dự án trong phiên làm việc cao hơn mọi file. |
| **Cố vấn** | Quyết định công nghệ và kiến trúc, viết kế hoạch, review code. Cập nhật `docs/` và file này. |
| **Agent triển khai** (bạn, trừ khi được giao vai khác) | Thực hiện đúng task được giao. Tự quyết những thứ nhỏ ở mục 5; mọi thứ khác phải hỏi. |

Khi các nguồn mâu thuẫn, thứ tự ưu tiên là: lời chủ dự án trong phiên → file này → kế hoạch của task → `docs/`. Thấy mâu thuẫn thì dừng và báo, đừng tự chọn.

## 3. Nguồn sự thật

| Cần biết | Đọc |
|---|---|
| Làm gì trong task này | Kế hoạch trong `docs/superpowers/plans/` |
| Hệ thống phải làm chính xác điều gì | `docs/03-srs.md` |
| Cấu trúc mã nguồn, các tầng, quy tắc phụ thuộc | `docs/04-sad.md` |
| Công nghệ đã chọn và lý do | `docs/04-adr.md` |
| Bảng, cột, ràng buộc | `docs/05-database-design.md` |
| Endpoint, định dạng lỗi | `docs/05-api-spec.md` |
| Màn hình, màu, chữ, hình, hành vi | `docs/06-ux-ui/user-flows.md` |
| Cách đặt tên, cách viết code | `docs/agents/quy-uoc-code.md` |

Không sửa gì trong `docs/` và không sửa file này, trừ khi bạn đang giữ vai cố vấn.

## 4. Luồng làm việc bắt buộc

Mọi task đi qua đúng sáu bước. Hướng dẫn đầy đủ nằm trong skill `thuc-hien-task` (`.agents/skills/thuc-hien-task/SKILL.md`).

1. **Đọc.** Đọc task, các tài liệu nó trỏ tới và code hiện có ở chỗ sẽ sửa.
2. **Nghĩ.** Trước khi viết dòng code nào, viết ra ba đến sáu dòng: sẽ đổi file nào, cách làm, và vì sao đó là cách đơn giản nhất. Nếu có hai cách đáng cân nhắc, nêu cả hai rồi chọn một.
3. **Làm.** Viết code theo `docs/agents/quy-uoc-code.md`. Chỉ đụng tới những gì task yêu cầu.
4. **Tự kiểm.** Chạy `pnpm check`; chạy thật tính năng vừa làm; rà soát bảo mật bằng skill `ra-soat-bao-mat`.
5. **Báo cáo.** Theo mẫu trong skill, kèm danh sách các bước để chủ dự án kiểm tay.
6. **Dừng.** Không sang task kế tiếp cho đến khi được duyệt.

## 5. Tự quyết và phải hỏi

| Tự quyết, ghi lại trong báo cáo | Phải hỏi và được đồng ý trước |
|---|---|
| Tên biến cục bộ, tên hàm phụ trong một file | Thêm, xoá, đổi phiên bản lớn của bất kỳ thư viện nào |
| Cách chia một file dài thành các file nhỏ trong cùng thư mục | Thêm, đổi tên, di chuyển thư mục; đổi cấu trúc gói |
| Chi tiết cài đặt bên trong một hàm | Đổi bất cứ thứ gì người dùng nhìn thấy: bố cục, màu, chữ, câu chữ, hành vi |
| Thông điệp log | Thêm hoặc đổi endpoint, bảng, cột, ràng buộc, biến môi trường |
| | Đổi tên, kiểu hoặc hành vi của thứ mà kế hoạch đã ghi rõ |
| | Đổi công cụ, cấu hình lint, cấu hình TypeScript, script trong `package.json` |
| | Bất cứ việc gì ngoài phạm vi task, kể cả sửa lỗi tình cờ thấy |

Khi hỏi: nêu vấn đề, hai hoặc ba phương án cùng cái giá của từng cái, và phương án bạn nghiêng về. Đề xuất thư viện phải kèm: nó giải quyết gì, vì sao không tự viết được trong vài chục dòng, giấy phép, mức độ được bảo trì, và kích thước nó thêm vào.

Thấy lỗi hoặc điều đáng lo ngoài phạm vi task: ghi vào mục "Ngoài phạm vi" của báo cáo. Không tự sửa.

## 6. Kiểm tra: không viết test tự động

Dự án **không viết test tự động** (không unit test, không test tích hợp, không test đầu cuối, không snapshot). Chủ dự án kiểm tay sau mỗi task và mỗi mốc. Không cài thư viện test, không tạo file `*.test.*` hay `*.spec.*`, kể cả khi bạn cho rằng nên có.

Vì không có test đỡ lưng, bốn việc sau là bắt buộc:

- **Cổng tự động.** `pnpm check` (kiểm kiểu và lint) phải qua hoàn toàn trước khi báo xong. Không dùng `any`, `@ts-ignore`, `@ts-expect-error`, `biome-ignore` hay `!` để cho qua.
- **Để máy chặn lỗi thay người.** Kiểu chặt, schema Zod ở mọi ranh giới (yêu cầu HTTP, biến môi trường, dữ liệu đọc từ ngoài), ràng buộc trong database. Trạng thái sai nên không biểu diễn được, thay vì được kiểm tra rải rác.
- **Tự chạy thử.** Bạn tự chạy tính năng vừa làm (gọi endpoint bằng `curl`, mở trang trên trình duyệt nếu có công cụ) và dán kết quả thật vào báo cáo. "Chắc là chạy" không phải kết quả.
- **Danh sách kiểm tay.** Mỗi báo cáo có các bước đánh số để chủ dự án làm theo: làm gì, ở đâu, thấy gì là đúng. Gồm cả trường hợp bình thường lẫn trường hợp sai (nhập thiếu, nhập sai, mất quyền, bấm hai lần).

## 7. Viết code

Chi tiết và ví dụ ở `docs/agents/quy-uoc-code.md`. Các nguyên tắc không được vi phạm:

- **Đơn giản trước.** Chọn cách ít khái niệm nhất mà giải quyết đúng việc. Không viết cho nhu cầu chưa có; không thêm lớp trừu tượng, tuỳ chọn hay cấu hình "để sau này dùng". Ba đoạn giống nhau mới tách hàm chung.
- **Tên nói thay comment.** Tên hàm, biến, file phải đủ để hiểu mà không cần chú thích. Comment chỉ để giải thích *vì sao* (một ràng buộc, một lựa chọn bất thường), không mô tả code đang làm gì.
- **File và hàm nhỏ.** Một file một trách nhiệm. Mốc xem lại: file quá 200 dòng, hàm quá 40 dòng, hơn 3 tham số, lồng quá 3 tầng. Vượt mốc thì chia nhỏ hoặc nêu lý do trong báo cáo.
- **Mẫu thiết kế khi có lý do.** Dùng một mẫu khi nó làm code dễ đọc hơn ngay bây giờ. Không áp mẫu để trông bài bản.
- **Theo cái có sẵn.** Trước khi viết, tìm trong kho mã xem việc tương tự đã được làm thế nào và làm theo. Không tạo cách thứ hai cho cùng một việc.
- **Đúng tầng.** Route không chứa logic; logic nghiệp vụ ở service; truy vấn ở `packages/db`; logic tiền chỉ ở `packages/core`; web không tự tính con số chính thức.
- **Tiền là số nguyên.** Không dùng số thực ở bất kỳ đâu trên đường đi của tiền.

## 8. Công nghệ

- Dùng bản **ổn định mới nhất** của các thư viện đã được chọn trong `docs/04-adr.md`. Không dùng bản beta, canary, rc.
- **Không tin trí nhớ về API của thư viện.** Trước khi dùng một API bạn không chắc, đọc tài liệu hoặc mã nguồn của đúng phiên bản đang cài trong `node_modules`. Ưu tiên cách làm hiện hành của thư viện; không dùng API đã bị đánh dấu lỗi thời.
- Ưu tiên tính năng có sẵn của nền tảng (Web API, Node.js, Postgres, CSS) trước khi nghĩ tới thư viện.
- Thấy một công nghệ mới đáng dùng: đề xuất trong báo cáo kèm lợi ích cụ thể cho dự án này. Không tự đưa vào.

## 9. Bảo mật

Bảo mật đứng trước tốc độ và sự tiện lợi. Danh sách rà soát đầy đủ nằm trong skill `ra-soat-bao-mat`. Luật cứng:

- **Bí mật** (mật khẩu, khoá, mã phiên, chuỗi kết nối thật) không vào git, không vào log, không vào thông báo lỗi, không vào báo cáo. Chỉ `.env.example` với giá trị giả được commit.
- **Mọi dữ liệu từ ngoài là không đáng tin**: thân yêu cầu, tham số, header, cookie, tham số trên URL. Kiểm bằng schema Zod ở ranh giới trước khi dùng.
- **Mọi endpoint có dữ liệu của nhóm phải kiểm quyền** qua middleware phân quyền chung. Người ngoài nhóm nhận 404, không phải 403.
- **Truy vấn database** chỉ qua Drizzle hoặc câu lệnh có tham số. Không nối chuỗi để tạo SQL.
- **Không tự viết mật mã.** Băm mật khẩu, sinh mã ngẫu nhiên, so sánh mã dùng thư viện chuẩn hoặc `node:crypto`.
- **Phản hồi lỗi** không lộ chi tiết nội bộ (stack, câu SQL, đường dẫn file) và không cho biết một email có tài khoản hay chưa.
- **Web** không dùng `dangerouslySetInnerHTML`, không `eval`, không chuyển hướng tới địa chỉ lấy thẳng từ tham số mà chưa kiểm.
- Nghi ngờ một thay đổi làm yếu bảo mật: dừng và hỏi.

## 10. Git

- Mỗi task một commit trên nhánh hiện tại, sau khi `pnpm check` qua. Thông điệp theo dạng `loại(phạm vi): mô tả ngắn`, với loại là `feat`, `fix`, `chore`, `refactor` hoặc `docs`.
- Không `push`, không `--force`, không sửa lịch sử, không `--no-verify`, không đổi nhánh, trừ khi chủ dự án bảo.
- Không commit file sinh ra khi build, `node_modules`, `.env`, hay file ngoài phạm vi task.

## 11. Tuyệt đối không

- Không báo "xong" khi `pnpm check` chưa qua hoặc chưa tự chạy thử.
- Không bịa kết quả; bước nào chưa chạy được thì ghi rõ là chưa chạy và vì sao.
- Không xoá hoặc viết lại code đang chạy đúng để "dọn dẹp" khi task không yêu cầu.
- Không gọi dịch vụ bên ngoài, không triển khai, không tạo tài khoản ở đâu.
- Không dùng emoji trong giao diện hay trong code.
