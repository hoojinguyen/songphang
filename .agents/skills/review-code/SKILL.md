---
name: review-code
description: Dùng khi được giao review một commit, một task đã làm xong, hoặc báo cáo của agent triển khai trong dự án Sòng Phẳng. Quy định cách đối chiếu diff với kế hoạch và luật của dự án, thứ tự kiểm tra, và mẫu kết luận "qua" hoặc danh sách cần sửa.
---

# Review một task

Người review đọc **code thật**, không chỉ đọc báo cáo. Báo cáo cho biết agent nghĩ mình đã làm gì; diff cho biết điều đã xảy ra.

## Chuẩn bị

1. Đọc task trong kế hoạch và mục "Global Constraints".
2. Lấy diff: `git show <commit>` hoặc `git diff <commit trước>..<commit>`.
3. Chạy `pnpm check` trên commit đó. Không qua thì dừng review và trả lại.

## Thứ tự kiểm

Kiểm theo thứ tự này; lỗi ở mục trên nghiêm trọng hơn mục dưới.

### 1. Đúng việc

- Mọi thứ task yêu cầu đều có trong diff, với đúng tên file, tên hàm, kiểu đã ghi trong kế hoạch.
- Hành vi khớp đặc tả: mã trạng thái, định dạng lỗi, tên trường, ràng buộc database.
- Chạy lại ít nhất hai mục trong phần "Tự chạy thử" của báo cáo và so kết quả. Kết quả khác báo cáo là lỗi nghiêm trọng.

### 2. Không thừa

- Không có file, endpoint, bảng, cột, tuỳ chọn hay thư viện nào ngoài task.
- `package.json` và `pnpm-lock.yaml`: mọi phụ thuộc mới đều đã được đồng ý.
- Không có file test, không có thư viện test.
- Không có thay đổi giao diện ngoài những gì task và tài liệu thiết kế mô tả.
- Không có thay đổi trong `docs/`, `AGENTS.md`, cấu hình lint hay TypeScript.

### 3. An toàn

Chạy skill `ra-soat-bao-mat` trên diff.

### 4. Dễ đọc

Theo `docs/agents/quy-uoc-code.md`:

- Tên hàm, biến, file tự giải thích; không viết tắt; dùng đúng từ vựng nghiệp vụ.
- File quá 200 dòng, hàm quá 40 dòng, hơn 3 tham số, lồng quá 3 tầng: có lý do không?
- Code nằm đúng tầng: route không có logic, web không tính tiền, truy vấn nằm trong `db`.
- Không có `any`, `as` ép kiểu, `!`, `@ts-ignore`, quy tắc lint bị tắt.
- Comment giải thích vì sao, không nhắc lại code; không có code bị comment.
- Không có cách thứ hai cho việc đã có cách làm trong kho mã.

### 5. Đơn giản

- Có lớp trừu tượng, tham số hay cấu hình nào chưa có nơi dùng không?
- Có đoạn nào thay được bằng tính năng sẵn có của nền tảng hoặc thư viện đang dùng không?
- Có dùng API đã lỗi thời của thư viện trong khi phiên bản đang cài có cách mới hơn không?

## Kết luận

Trả lời theo đúng một trong hai mẫu.

```
Task <số>: QUA
Ghi chú (không chặn): <tuỳ chọn>
```

```
Task <số>: CẦN SỬA

Phải sửa
1. <file:dòng> — <vấn đề> — <sửa thế nào>

Nên sửa
1. <file:dòng> — <vấn đề> — <gợi ý>

Câu hỏi cho chủ dự án
1. <nếu có điều cần chủ dự án quyết>
```

- "Phải sửa": sai so với kế hoạch hoặc đặc tả, lỗ hổng bảo mật, thứ thừa ngoài phạm vi, vi phạm luật trong `AGENTS.md`.
- "Nên sửa": dễ đọc và đơn giản hơn nhưng không sai.
- Mỗi mục chỉ đúng một chỗ trong code và nói rõ cách sửa. Không viết nhận xét chung chung.
- Không tự sửa code khi đang review, trừ khi chủ dự án yêu cầu.
