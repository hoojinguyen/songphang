# App Store Listing Metadata (tiếng Việt)

Metadata chuẩn cho App Store Connect theo thiết kế Phase 5 (`docs/superpowers/specs/2026-11-15-phase-5-ios-design.md` §6) và các chuỗi sản phẩm trong `apps/web/src/messages/vi.ts`.

---

## Thông tin chính

- **Bundle ID:** `vn.songphang.app`
- **Ngôn ngữ chính:** Tiếng Việt (`vi`)
- **Tên ứng dụng (App Name):** `Sòng Phẳng`
- **Phụ đề (Subtitle):** `Chia tiền nhóm sòng phẳng`
- **Danh mục chính (Primary Category):** Tài chính (Finance)
- **Danh mục phụ (Secondary Category):** Tiện ích (Utilities)

---

## Mô tả (Description)

```text
Chia tiền, gõ như nhắn tin.

Sòng Phẳng giúp nhóm bạn đi chơi, ăn uống, ở ghép hay du lịch theo dõi chi tiêu chung rõ ràng, minh bạch bằng tiếng Việt tự nhiên. Không cần nhập bảng tính rườm rà — chỉ cần gõ một câu như đang nhắn tin để tách tiền ngay lập tức.

TÍNH NĂNG NỔI BẬT

• Nhập nhanh bằng tiếng Việt tự nhiên: Gõ "cà phê 180k" hoặc "ăn trưa 240k chia đều", ứng dụng tự nhận số tiền, người trả và chia phần cho cả nhóm.
• Chụp hoá đơn & chia theo món: Chụp hoặc chọn ảnh hoá đơn từ thư viện để bóc tách từng món, thuế, phí dịch vụ và chia đúng phần từng người.
• Chia tiền linh hoạt, chính xác đến từng đồng: Hỗ trợ chia đều, chia theo số tiền cụ thể, chia theo phần, theo phần trăm hoặc theo từng món trên hoá đơn.
• Thanh toán nhanh qua VietQR: Hiển thị mã VietQR kèm sẵn số tiền và nội dung chuyển khoản, hỗ trợ báo đã chuyển và xác nhận đã nhận hai chiều.
• Quỹ chung & hạn mức chi tiêu: Lập quỹ nhóm, theo dõi tiền quỹ còn lại và bật cảnh báo khi gần chạm hoặc vượt hạn mức.
• Minh bạch & trao đổi ngay trên từng khoản: Theo dõi lịch sử chỉnh sửa, khôi phục khoản vừa xoá, bình luận trực tiếp, hỏi lại khi có sai sót và duyệt khoản chi lớn.
• Đồng bộ thời gian thực & nhắc nợ tinh tế: Cập nhật tức thì cho mọi thành viên, nhắc nợ nhẹ nhàng kèm tuỳ chọn thông báo qua ứng dụng, email và Telegram.
• Xem lại ngay cả khi mất mạng: Lưu tạm dữ liệu nhóm gần nhất để bạn vẫn tra cứu được sổ thu chi khi đang di chuyển.
```

---

## Từ khoá (Keywords — tối đa 100 ký tự)

```text
chia tiền,quản lý chi tiêu,tiền nhóm,du lịch,hoá đơn,vietqr,sòng phẳng,tính tiền,nhắc nợ
```

*(Độ dài: 89 ký tự)*

---

## Ghi chú phiên bản phát hành (What's New — v1.0.0)

```text
Phiên bản đầu tiên của Sòng Phẳng trên iOS:
• Nhập khoản chi nhanh bằng tiếng Việt tự nhiên và chụp ảnh hoá đơn.
• Xem số dư ai nợ ai, quét VietQR trả nợ và xác nhận thanh toán hai chiều.
• Hỗ trợ quỹ chung, hạn mức chi tiêu, thống kê, xuất CSV và liên kết Telegram.
```

---

## Quyền riêng tư (App Privacy — khớp với `apps/ios/App/PrivacyInfo.xcprivacy`)

- **Theo dõi (Tracking):** Không theo dõi người dùng (`NSPrivacyTracking = false`).
- **Dữ liệu liên kết với danh tính người dùng (`Data Linked to You`, chỉ dùng cho `App Functionality`):**
  - **Thông tin liên hệ:** Địa chỉ email (`NSPrivacyCollectedDataTypeEmailAddress`), Tên (`NSPrivacyCollectedDataTypeName`)
  - **Thông tin tài chính:** Thông tin tài chính khác (`NSPrivacyCollectedDataTypeOtherFinancialInfo` — số tiền chi tiêu, số dư công nợ, thông tin tài khoản VietQR để thanh toán)
  - **Định danh:** Mã người dùng (`NSPrivacyCollectedDataTypeUserID`), Mã thiết bị (`NSPrivacyCollectedDataTypeDeviceID` — mã token thiết bị APNs dùng để gửi thông báo đẩy)
  - **Nội dung người dùng:** Ảnh hoá đơn / chứng từ (`NSPrivacyCollectedDataTypePhotosorVideos`), Mô tả khoản chi, bình luận và nội dung nhập nhanh (`NSPrivacyCollectedDataTypeOtherUserContent`)
- **API yêu cầu khai báo lý do:** `NSPrivacyAccessedAPICategoryUserDefaults` — mã lý do `CA92.1` (lưu trạng thái hoãn lời nhắc bật thông báo cục bộ).

---

## Danh sách ảnh chụp màn hình cần chuẩn bị (6.9" iPhone Display)

1. **Màn hình Sổ chi tiêu nhóm (S04)** — Hiển thị thẻ số dư đầu màn hình và các bong bóng khoản chi + chia phần nhiều màu.
2. **Màn hình Nhập nhanh / Chụp hoá đơn (S07 / S18)** — Minh hoạ câu gõ tự nhiên hoặc hoá đơn chia theo món.
3. **Màn hình Ai nợ ai & Trả tiền VietQR (S05 / S14)** — Minh hoạ danh sách chuyển tiền gọn và mã VietQR điền sẵn.
4. **Màn hình Chi tiết khoản chi & Thảo luận (S20)** — Minh hoạ bảng chia phần, thẻ duyệt khoản chi và bình luận.
5. **Màn hình Tiền đi đâu & Quỹ chung (S16 / S17)** — Minh hoạ thống kê chi tiêu theo danh mục/thành viên và quỹ chung.
