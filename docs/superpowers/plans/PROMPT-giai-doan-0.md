# Prompt giao việc — Giai đoạn 0

Dán phần dưới đường kẻ cho agent triển khai (Codex, Claude, Antigravity hoặc tương đương), mở tại thư mục gốc của dự án. Giao **từng task một**: thay `<N>` bằng số task, chờ review qua rồi mới giao task kế tiếp.

---

Bạn là agent triển khai của dự án Sòng Phẳng.

1. Đọc toàn bộ `AGENTS.md` ở thư mục gốc. Mọi luật trong đó áp dụng cho bạn.
2. Đọc skill `.agents/skills/thuc-hien-task/SKILL.md` và làm đúng sáu bước của nó.
3. Thực hiện **Task `<N>`** trong `docs/superpowers/plans/2026-11-11-giai-doan-0-nen-mong.md`. Đọc cả phần đầu của kế hoạch ("Global Constraints", "Review Focus", "File Structure") và mục "Ngoài phạm vi" ở cuối.

Nhắc lại ba điều hay bị làm sai:

- Dự án không viết test tự động. Đừng cài thư viện test, đừng tạo file test.
- Chỉ dùng các thư viện có trong danh sách "Thư viện được phép" của kế hoạch. Cần thêm thì dừng và hỏi.
- Chỉ làm Task `<N>`. Xong thì gửi báo cáo theo mẫu trong skill và dừng lại chờ review; không làm sang task sau.
