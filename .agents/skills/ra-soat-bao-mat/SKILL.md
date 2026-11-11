---
name: ra-soat-bao-mat
description: Dùng trước khi báo xong bất kỳ thay đổi code nào trong dự án Sòng Phẳng, và khi review code. Danh sách rà soát bảo mật cho API, database, phiên đăng nhập, web và cấu hình; mỗi mục phải được kiểm trên diff thật chứ không trả lời theo trí nhớ.
---

# Rà soát bảo mật

Chạy trên diff của thay đổi hiện tại (`git diff` hoặc `git show`). Với mỗi mục liên quan, mở đúng đoạn code và kiểm; đừng trả lời "ổn" theo trí nhớ. Mục không liên quan tới thay đổi thì bỏ qua.

Tìm thấy vấn đề: sửa nếu nằm trong phạm vi task; nếu không, ghi vào mục "Ngoài phạm vi" của báo cáo. Không chắc một thứ có an toàn không: dừng và hỏi.

## 1. Bí mật và cấu hình

- [ ] Không có mật khẩu, khoá, mã phiên, chuỗi kết nối thật trong code, file cấu hình, hay file được commit. Chạy `git diff --cached` và đọc từng dòng thêm vào.
- [ ] `.env` không nằm trong commit; `.env.example` chỉ có giá trị giả hoặc giá trị chỉ dùng cho máy local.
- [ ] Biến môi trường mới được khai báo trong schema cấu hình và có trong `.env.example`.
- [ ] Không log mật khẩu, mã phiên, cookie, header `Authorization`, hay toàn bộ thân yêu cầu.

## 2. Dữ liệu đầu vào

- [ ] Mọi thân yêu cầu, tham số đường dẫn, tham số truy vấn và header được dùng đều đi qua schema Zod trước khi tới logic.
- [ ] Chuỗi có giới hạn độ dài; số có giới hạn khoảng; mảng có giới hạn số phần tử.
- [ ] ID nhận từ client được kiểm là thuộc đúng nhóm hoặc đúng người dùng đang gọi, không chỉ kiểm là tồn tại.
- [ ] Không có giá trị nào từ client được dùng làm tên cột, tên bảng, đường dẫn file hay lệnh hệ thống.

## 3. Đăng nhập và phiên

- [ ] Endpoint cần đăng nhập có middleware `requireUser`. Endpoint công khai là có chủ đích và được ghi trong đặc tả API.
- [ ] Mã phiên được sinh bằng `node:crypto`, đủ dài (từ 32 byte), và chỉ lưu ở dạng băm.
- [ ] Cookie phiên có `HttpOnly`, `SameSite=Lax`, `Path=/`, và `Secure` ở production.
- [ ] Đăng xuất, đổi mật khẩu và đặt lại mật khẩu làm mất hiệu lực các phiên cần mất.
- [ ] Đường dẫn chỉ dành cho phát triển (`/dev/*`) không tồn tại khi `APP_ENV=production`.
- [ ] Mật khẩu chỉ được băm bằng thuật toán chuyên cho mật khẩu qua thư viện; không tự viết, không dùng SHA hay MD5 cho mật khẩu.
- [ ] So sánh mã bí mật dùng phép so sánh thời gian không đổi (`timingSafeEqual`) hoặc tra theo giá trị băm.

## 4. Phân quyền

- [ ] Mọi endpoint có `groupId` đi qua middleware phân quyền chung, với mức quyền tối thiểu đúng như đặc tả API.
- [ ] Người ngoài nhóm nhận 404; người trong nhóm thiếu quyền nhận 403.
- [ ] Không có truy vấn nào lấy dữ liệu của nhóm mà thiếu điều kiện theo `group_id`.
- [ ] Thao tác chỉ dành cho chủ nhóm được kiểm ở server, không chỉ ẩn nút ở web.

## 5. Database

- [ ] Mọi truy vấn dùng Drizzle hoặc tham số hoá. Không có chuỗi SQL được ghép từ biến.
- [ ] Thao tác ghi nhiều bảng nằm trong một transaction.
- [ ] Ràng buộc toàn vẹn mới (duy nhất, khoá ngoại, `CHECK`) nằm trong migration, không chỉ trong code.

## 6. Phản hồi và lỗi

- [ ] Phản hồi lỗi không chứa stack, câu SQL, đường dẫn file hay tên bảng.
- [ ] Phản hồi không trả thừa trường: không có `tokenHash`, `passwordHash`, email của người khác nhóm, hay cột nội bộ.
- [ ] Đăng ký, đăng nhập và quên mật khẩu không cho biết một email đã có tài khoản hay chưa.
- [ ] Endpoint dễ bị dò (đăng nhập, đăng ký, gửi thư, xem lời mời) có giới hạn tần suất khi đặc tả yêu cầu.

## 7. Web

- [ ] Không có `dangerouslySetInnerHTML`, `eval`, `new Function`, hay HTML dựng từ chuỗi.
- [ ] Chuyển hướng theo tham số (`next`, `redirect`) chỉ nhận đường dẫn nội bộ: bắt đầu bằng đúng một dấu `/`, không chứa `\`.
- [ ] Liên kết ra ngoài mở tab mới có `rel="noopener noreferrer"`.
- [ ] Không lưu mã phiên, mật khẩu hay dữ liệu nhạy cảm vào `localStorage` hoặc `sessionStorage`.
- [ ] Yêu cầu ghi gửi tới API cùng nguồn; không tắt kiểm tra nguồn gốc ở server.

## 8. Phụ thuộc

- [ ] Không có thư viện mới nào được thêm mà chưa được đồng ý.
- [ ] `pnpm audit --prod` không báo lỗ hổng mức cao hoặc nghiêm trọng mới do thay đổi này. Có thì báo, đừng tự nâng phiên bản lớn.
- [ ] File khoá phụ thuộc (`pnpm-lock.yaml`) được commit cùng thay đổi.

## Ghi vào báo cáo

Thêm một dòng vào mục "Tự chạy thử" của báo cáo:

```
Rà soát bảo mật: đã kiểm mục <số các mục liên quan>; <"không thấy vấn đề" hoặc danh sách vấn đề và cách đã xử lý>
```
