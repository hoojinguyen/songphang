---
name: thuc-hien-task
description: Dùng khi được giao thực hiện một task, một bước trong kế hoạch, sửa lỗi, hoặc bất kỳ thay đổi code nào trong dự án Sòng Phẳng. Quy định sáu bước bắt buộc từ đọc, nghĩ, làm, tự kiểm, báo cáo đến dừng chờ duyệt, và mẫu báo cáo kèm danh sách kiểm tay.
---

# Thực hiện một task

Làm đúng sáu bước, theo thứ tự. Không bỏ bước nào, kể cả với thay đổi nhỏ.

## Bước 1 — Đọc

1. Đọc toàn bộ task được giao và mục "Global Constraints" của kế hoạch chứa nó.
2. Đọc các phần tài liệu trong `docs/` mà task trỏ tới.
3. Đọc code hiện có ở những chỗ sẽ sửa và ở những chỗ đang làm việc tương tự. Bạn sẽ làm theo cách đã có.
4. Nếu task đụng tới giao diện: đọc phần tương ứng trong `docs/06-ux-ui/user-flows.md`.

Chưa hiểu task yêu cầu gì, hoặc thấy nó mâu thuẫn với tài liệu: hỏi ngay ở bước này.

## Bước 2 — Nghĩ, rồi viết ra

Trước khi sửa file nào, viết ra cho người giao việc:

```
Cách làm
- File sẽ tạo/sửa: …
- Cách làm: … (hai đến bốn dòng)
- Vì sao đây là cách đơn giản nhất: …
- Phương án đã bỏ: … (nếu có một phương án đáng cân nhắc)
- Cần hỏi: … (nếu không có thì ghi "không")
```

Tự hỏi ba câu trước khi viết phần này:

- Có cách nào ít code hơn, ít khái niệm hơn mà vẫn đúng không?
- Nền tảng hoặc thư viện đang dùng đã có sẵn thứ này chưa?
- Mình có đang làm thêm thứ task không yêu cầu không?

Nếu mục "Cần hỏi" có nội dung thuộc cột "Phải hỏi" ở mục 5 của `AGENTS.md`, dừng ở đây chờ trả lời. Nếu không, làm tiếp.

## Bước 3 — Làm

- Theo `docs/agents/quy-uoc-code.md`.
- Dùng đúng tên file, tên hàm, kiểu mà kế hoạch đã ghi.
- Chỉ đụng tới file mà task cần. Không sửa định dạng, không đổi tên, không dọn dẹp ở chỗ khác.
- Không chắc API của một thư viện: đọc tài liệu hoặc mã nguồn của đúng phiên bản trong `node_modules`, đừng đoán.
- Không viết test tự động.

## Bước 4 — Tự kiểm

Làm đủ bốn việc, theo thứ tự:

1. `pnpm check` qua hoàn toàn. Lỗi thì sửa nguyên nhân, không tắt quy tắc.
2. Chạy thật thứ vừa làm: gọi endpoint bằng `curl`, chạy lệnh, mở trang. Thử cả đường bình thường lẫn ít nhất hai trường hợp sai (thiếu dữ liệu, sai định dạng, chưa đăng nhập, không có quyền, gửi hai lần). Giữ lại kết quả thật.
3. Rà soát bảo mật bằng skill `ra-soat-bao-mat`.
4. Đọc lại toàn bộ diff của mình (`git diff`) như thể người khác viết: có file nào quá dài, tên nào khó hiểu, đoạn nào thừa, thứ gì ngoài phạm vi không?

Sửa ba lần cho cùng một lỗi mà vẫn không qua: dừng và báo, đừng thử tiếp.

## Bước 5 — Báo cáo

Commit theo mục 10 của `AGENTS.md`, rồi gửi báo cáo đúng mẫu:

```
Task <số> — <tên>
Commit: <mã băm rút gọn>
pnpm check: qua / thất bại

Đã làm
- <một dòng cho mỗi thay đổi đáng kể>

File tạo/sửa
- <đường dẫn>

Tự chạy thử
- <lệnh hoặc thao tác> → <kết quả thật, dán nguyên văn phần quan trọng>

Kiểm tay cho chủ dự án
1. <làm gì, ở đâu> → thấy <gì> là đúng
2. …
(gồm cả trường hợp sai: làm <gì> → phải thấy <thông báo/hành vi>)

Tự quyết
- <lựa chọn kế hoạch để ngỏ mà bạn đã chọn; "không có">

Lệch so với kế hoạch
- <khác gì, vì sao; "không có">

Chưa kiểm được
- <bước nào chưa chạy và vì sao; "không có">

Ngoài phạm vi
- <lỗi hoặc điều đáng lo đã thấy nhưng không sửa; "không có">
```

Quy tắc cho mục "Kiểm tay cho chủ dự án":

- Mỗi bước là một thao tác cụ thể mà người không đọc code làm được: lệnh để dán, địa chỉ để mở, nút để bấm.
- Mỗi bước nói rõ kết quả đúng trông thế nào.
- Có ít nhất một bước cho đường bình thường và một bước cho mỗi trường hợp sai quan trọng.
- Không quá mười bước cho một task; nếu cần nhiều hơn, task đang quá lớn.

## Bước 6 — Dừng

Không bắt đầu task kế tiếp. Chờ người review trả lời "qua" hoặc danh sách cần sửa. Khi được yêu cầu sửa: sửa đúng những điểm đó, chạy lại bước 4, commit riêng, báo cáo lại phần thay đổi.

## Dừng và hỏi ngay khi

- Kế hoạch và tài liệu mâu thuẫn nhau.
- Không làm được task mà không đổi tên, kiểu hoặc hành vi kế hoạch đã ghi.
- Cần một thư viện, thư mục, endpoint, bảng, cột hoặc biến môi trường chưa có trong kế hoạch.
- Cần đổi thứ gì đó người dùng nhìn thấy.
- Một thay đổi có thể làm yếu bảo mật.
