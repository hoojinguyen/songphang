# 01 — Vision & Scope (Tầm nhìn và phạm vi) — Sòng Phẳng

Cập nhật: 2026-11-11. Trạng thái: đã duyệt ngày 2026-11-11; bản sửa đổi cùng ngày (ô gõ nhanh vào giai đoạn 1, hướng thiết kế G + E) đã duyệt. Bản sửa đổi thứ ba (nội bộ trước, phát hành công khai sau; đăng ký bằng email) đã duyệt.

Bộ tài liệu:

| # | Tài liệu | Trả lời câu hỏi |
|---|---|---|
| 01 | **Vision & Scope** (tài liệu này) | Làm gì, cho ai, vì sao, không làm gì |
| 02 | [PRD — Yêu cầu sản phẩm](02-prd.md) | Người dùng cần gì |
| 03 | [SRS — Đặc tả yêu cầu phần mềm, giai đoạn 1](03-srs.md) | Hệ thống phải làm chính xác điều gì |
| 04 | [SAD — Kiến trúc phần mềm](04-sad.md) và [ADR — Nhật ký quyết định](04-adr.md) | Hệ thống gồm những khối nào, chọn công nghệ gì và vì sao |
| 05 | [Thiết kế database](05-database-design.md) và [Đặc tả API](05-api-spec.md) | Dữ liệu và giao tiếp cụ thể ra sao |
| 06 | [User flow và ngôn ngữ thiết kế](06-ux-ui/user-flows.md); mockup trên [canvas thiết kế](https://claude.ai/artifact/VEWSdwY25ULTJUSM1pBH5X), hàng "Vòng 3" | Người dùng đi qua những bước nào, màn hình trông ra sao |
| 07 | [Product Roadmap](07-roadmap.md) | Làm gì trước, làm gì sau |

Tài liệu nền: [Nghiên cứu Settle Up](../settle-up-research.md).

## 1. Bài toán

Một nhóm bạn, gia đình hoặc đồng nghiệp chi tiêu chung (ăn uống, du lịch, tiền nhà) cần biết ai đã trả gì, ai nợ ai bao nhiêu, và trả nợ sao cho ít lượt chuyển nhất. Các ứng dụng hiện có như Settle Up giải quyết tốt phần lõi nhưng không phù hợp thói quen ở Việt Nam (chuyển khoản bằng QR, ví điện tử, nhóm chat) và giới hạn tính năng sau paywall.

## 2. Mục tiêu

Một ứng dụng chia tiền có đầy đủ phần lõi của Settle Up và bổ sung các tính năng mà Settle Up không có, đi theo hai chặng:

1. **Nội bộ trước.** Người dùng đầu tiên là chủ dự án cùng bạn bè, gia đình và đồng nghiệp. Ứng dụng phải thực sự giải quyết được nhu cầu của nhóm này.
2. **Công khai sau.** Khi chủ dự án, qua việc tự dùng, đánh giá rằng chặng một đã đạt, ứng dụng được phát hành cho bất kỳ ai ở Việt Nam có cùng nhu cầu.

Hệ quả: dù người dùng đầu tiên là người quen, sản phẩm được xây theo chuẩn của một sản phẩm công khai ở những chỗ khó sửa về sau (tài khoản, bảo mật, quyền riêng tư, chất lượng giao diện). Những thứ chỉ cần khi có người lạ dùng (điều khoản, giám sát, chống lạm dụng, mở rộng hạ tầng) được làm ở giai đoạn phát hành công khai.

**Tiêu chí thành công**
- Thêm một khoản chi chia đều bằng một câu gõ rồi Lưu, hoặc tối đa ba thao tác trên form: số tiền, mô tả, lưu.
- Mọi người trong nhóm luôn thấy cùng một con số, trên mọi thiết bị.
- Tổng số dư của nhóm luôn bằng 0; không có sai lệch làm tròn.
- Người được mời tham gia nhóm bằng một link, không cần cài đặt.
- Dữ liệu được sao lưu hằng đêm và khôi phục được.

**Không phải mục tiêu**
- Miễn phí: không premium, không quảng cáo, không thanh toán trong ứng dụng. Chuyện doanh thu sẽ cân nhắc về sau và không nằm trong kế hoạch hiện tại.
- Chỉ Việt Nam: giao diện tiếng Việt và tiền VND. Tiếng Anh và đa tiền tệ không nằm trong kế hoạch phát hành.
- Chưa tối ưu cho quy mô lớn: chặng nội bộ chạy trên một máy chủ. Tuy vậy không quyết định nào được phép chặn đường mở rộng (xem SAD mục 10).
- Không giữ tiền hay xử lý giao dịch tài chính thật: ứng dụng chỉ ghi sổ và tạo mã QR/link để người dùng tự chuyển.

## 3. Người dùng

| Vai trò | Mô tả | Cần tài khoản |
|---|---|---|
| Chủ nhóm | Tạo nhóm, quản lý thành viên và quyền, xoá nhóm | Có |
| Người đọc-ghi | Thêm, sửa, xoá giao dịch | Có |
| Người chỉ đọc | Xem giao dịch và số dư | Có |
| Thành viên ảo | Được ghi tên trong nhóm để chia tiền, không tự thao tác | Không |

## 4. Giải pháp

Một API trung tâm chứa toàn bộ logic nghiệp vụ, phục vụ ba client mỏng: web (làm trước), iOS native và Android native (làm sau).

```
Web (Next.js) ──┐
iOS (Swift) ────┼── HTTPS ──► API (Node + Hono) ──► Postgres
Android (Kotlin)┘                  │
                                   └── SSE: báo "nhóm X vừa thay đổi"
```

**Các nguyên tắc định hướng**

1. **Server là nguồn sự thật duy nhất về tiền.** Client gửi đầu vào gốc, server tính và lưu số tiền của từng người. Client không tự tính con số chính thức.
2. **Client mỏng.** Web, iOS và Android không chia sẻ code, nên logic không được nằm ở client. Thứ dùng chung là hợp đồng API (OpenAPI).
3. **Thành viên tách khỏi tài khoản.** Chia tiền với người chưa đăng ký là trường hợp bình thường, không phải ngoại lệ.
4. **Tiền là số nguyên.** Lưu theo đơn vị nhỏ nhất của tiền tệ, làm tròn theo quy tắc cố định.
5. **Realtime, cần mạng để ghi.** Thay đổi của người khác tự hiện lên; mất mạng vẫn xem được dữ liệu đã tải.
6. **Mỗi giai đoạn là một bản dùng được.** Không có giai đoạn nào chỉ làm hạ tầng.

## 5. Phạm vi theo giai đoạn

| Giai đoạn | Nội dung |
|---|---|
| 0. Nền móng | Tài liệu, mockup, khung dự án chạy trên máy local |
| 1. Lõi chia tiền | Nhóm, thành viên ảo, mời, phân quyền, giao dịch, bốn cách chia, ô gõ nhanh đọc theo mẫu, tính nợ, lịch sử |
| Đưa lên máy chủ | Tên miền, HTTPS, đăng nhập Google trên tên miền thật, sao lưu; làm khi muốn người khác dùng thật |
| 2. Tiền thật | VietQR và ví điện tử, quỹ chung, thống kê và ngân sách |
| 3. Nhập liệu thông minh | Chụp hoá đơn AI đọc; AI đọc câu gõ tự do mà bộ quy tắc không hiểu |
| 4. Cộng tác | Bình luận, duyệt chi, bot Telegram/Zalo |
| 5. iOS | App Swift native |
| 6. Android | App Kotlin native |
| 7. Phát hành công khai | Điều khoản và quyền riêng tư, xoá tài khoản, chống lạm dụng, giám sát, thương hiệu riêng, hạ tầng đủ tin cậy cho người lạ |

Chi tiết từng giai đoạn nằm trong [07 — Product Roadmap](07-roadmap.md).

## 6. Khác biệt so với Settle Up

| Khía cạnh | Settle Up | Dự án này |
|---|---|---|
| Nơi đặt logic | Client dày, lặp lại ở 3 nền tảng | Server duy nhất |
| Dữ liệu | Firebase Realtime Database | Postgres |
| Số tiền mỗi người | Mỗi client tự tính từ trọng số | Server tính một lần, lưu kết quả |
| Bảng nợ | Server sinh và lưu | Tính trực tiếp khi đọc |
| Cách chia | Đều, trọng số, phần trăm, số tiền | Thêm "còn lại chia đều" và "phần riêng cộng phần chung" |
| Thanh toán | Tài khoản ngân hàng, Revolut, QR SPAYD (Séc) | VietQR, MoMo, ZaloPay |
| Nhập liệu | Form | Gõ một câu như nhắn tin; thêm OCR hoá đơn và AI ở giai đoạn 3 |
| Doanh thu | Premium + quảng cáo | Không có |

## 7. Quyết định đã chốt

| Chủ đề | Quyết định |
|---|---|
| Tên ứng dụng | Sòng Phẳng (tên miền dự kiến `songphang`; chưa đăng ký, chưa tra nhãn hiệu) |
| Mục đích | Nội bộ trước; phát hành công khai khi đã giải quyết tốt nhu cầu nội bộ |
| Nền tảng | Web trước, iOS native, rồi Android native |
| Server | Node.js + TypeScript, API độc lập |
| Dữ liệu | Postgres |
| Web | Next.js |
| Đồng bộ | Realtime qua SSE, cần mạng để ghi |
| Đăng nhập | Google, và email kèm mật khẩu có xác minh; thêm Apple khi có iOS |
| Hạ tầng | VM Ubuntu sẵn có, Docker Compose |
| Tiền tệ giai đoạn 1 | Chỉ VND; mô hình dữ liệu sẵn sàng cho đa tiền tệ |
| Hướng thiết kế | "G + E": sổ chi tiêu là dòng trò chuyện có ô gõ; mỗi thành viên một hình và màu; chữ số lớn |
| Ô gõ nhanh | Vào giai đoạn 1, đọc bằng quy tắc, không AI; AI bổ sung ở giai đoạn 3 |

## 8. Rủi ro chính

| Rủi ro | Ảnh hưởng | Cách giảm |
|---|---|---|
| Sai lệch tiền do làm tròn hoặc lỗi logic | Mất lòng tin vào ứng dụng | Logic thuần tách riêng; ràng buộc trong database kiểm tổng; kiểm tay theo danh sách của từng mốc (ADR-016) |
| Lọt quyền truy cập giữa các nhóm | Lộ dữ liệu chi tiêu | Một lớp kiểm tra quyền duy nhất; rà soát bảo mật trên mỗi commit; kiểm tay bảng quyền theo từng mốc |
| Mất dữ liệu trên một máy chủ đơn | Mất toàn bộ sổ sách | Sao lưu hằng đêm ra ngoài VM, diễn tập khôi phục |
| Phát hành công khai một sản phẩm trông giống Settle Up | Rắc rối pháp lý, mất uy tín | Tên, nhận diện và giao diện riêng (hướng G + E đã khác hẳn); chỉ học ý tưởng tính năng, không sao chép mã, hình ảnh hay câu chữ |
| Dữ liệu chi tiêu của người lạ bị lộ hoặc mất | Hậu quả pháp lý và mất lòng tin | Chuẩn bảo mật công khai ngay từ giai đoạn 1; rà soát bảo mật và quy định bảo vệ dữ liệu cá nhân trước giai đoạn 7 |
| Phạm vi phình to | Không bao giờ ra bản dùng được | Mỗi giai đoạn có tiêu chí hoàn thành; tính năng mới vào giai đoạn sau |
| Chi phí và độ chính xác của AI đọc hoá đơn | Tốn tiền, kết quả sai | Giai đoạn 3 bắt đầu bằng thử nghiệm đo độ chính xác; người dùng luôn xác nhận trước khi lưu |
| API của Zalo, MoMo, ZaloPay thay đổi hoặc hạn chế | Tính năng không làm được như dự kiến | Khảo sát khả thi trước mỗi tích hợp; VietQR và Telegram là phương án chắc chắn |
