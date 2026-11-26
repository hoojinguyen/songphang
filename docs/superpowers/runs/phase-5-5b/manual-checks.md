# Wave 5.5B — Danh sách kiểm tra thủ công (Physical iPhone & Web)

- Branch: `phase-5-5b`
- Phạm vi: Chứng từ chuyển tiền (không bắt buộc), Kênh & Ghi chú ngắn, Sổ thanh toán, Chốt đợt (`settlement_cycles`) + bộ lọc đợt trên `Chi tiêu`, Link khách chỉ-xem (`/share/{token}`) + VietQR, Giải trình khoản nợ, và Xuất ảnh 1 chạm (`Tổng kết nhóm` & `Nhắc nợ khéo`, Light/Dark, số nguyên đồng).

## 1. Chứng từ chuyển tiền, kênh & ghi chú (không bắt buộc)

1. **Thao tác 1 chạm không cần chứng từ (nhanh như cũ):**
   - Vào `Thanh toán` -> chọn một lượt chuyển tiền của bạn -> bấm `Tôi đã chuyển` mà **không** chọn kênh, **không** đính ảnh và **không** nhập ghi chú -> kết quả đúng: gửi thành công ngay trong 1 chạm, tạo yêu cầu `Chờ xác nhận`.
   - Với vai trò chủ nhóm/editor, bấm `Ghi nhận đã trả` cho một thành viên không xài app mà không đính kèm gì -> kết quả đúng: tạo giao dịch chuyển tiền ngay lập tức, số dư cập nhật ngay.
2. **Thành viên (`viewer` hoặc `editor`) đính kèm ảnh bill & kênh thanh toán:**
   - Trong màn hình chuyển tiền, chọn kênh (`Ngân hàng` / `MoMo` / `ZaloPay` / `Tiền mặt`), chọn 1 ảnh chụp màn hình chuyển khoản, nhập ghi chú ngắn (ví dụ `"CK VCB tối thứ 3"`) rồi bấm `Tôi đã chuyển`.
   - Chủ nhóm xem trong `Thanh toán`: thẻ `Chờ xác nhận` hiện pill kênh, ghi chú và thumbnail ảnh bill; bấm vào thumbnail mở lightbox xem rõ ảnh trước khi bấm `Đã nhận`.
   - Sau khi chủ nhóm bấm `Đã nhận`: sang segment `Chi tiêu` kiểm tra thẻ transfer vừa tạo -> kết quả đúng: hiện badge ảnh thu nhỏ (`Có chứng từ`) cùng kênh và ghi chú mà không làm rớt dòng số tiền.
3. **Trường hợp lỗi / giới hạn:**
   - Thử đính kèm file không phải ảnh hoặc vượt 5 MiB -> phải báo lỗi hợp lệ và giữ nguyên các dữ liệu đã nhập.
   - Khi nhóm đang `Đã lưu trữ`, mọi nút upload chứng từ / xác nhận / ghi nhận đều bị ẩn hoặc từ chối (`409 GROUP_ARCHIVED`).

## 2. Sổ thanh toán (Settlement History & Receipt Proof Vault)

1. Trong segment `Thanh toán`, chuyển pill đầu trang sang `Sổ thanh toán`.
2. Kiểm tra dải tóm tắt trên cùng (`Tổng đã thanh toán`, số `Chờ xác nhận`, số `Có chứng từ`) khớp với thực tế nhóm.
3. Lần lượt bấm các chip lọc `Tất cả` | `Chờ xác nhận` | `Đã thanh toán` | `Có chứng từ`:
   - Giao dịch `Tôi đã chuyển` đã được chủ nhóm bấm `Đã nhận` chỉ xuất hiện **1 lần** duy nhất (trạng thái `Đã thanh toán`), không bị lặp đôi giữa request và transfer.
   - Chip `Có chứng từ` chỉ hiển thị các lượt chuyển tiền có ảnh bill; bấm vào thumbnail mở lightbox phóng to ảnh.

## 3. Chốt đợt (`settlement_cycles`) & Giải trình khoản nợ

1. **Khi chưa có đợt nào đã chốt:** Vào segment `Chi tiêu` -> kết quả đúng: không hiện chip lọc đợt (tránh rối mắt cho nhóm đi chơi 1 lần).
2. **Bấm `Chốt đợt`:**
   - Vào `Thanh toán` -> bấm `Chốt đợt` -> giữ hoặc sửa tên đợt (`"Đợt 1 · Cầu lông T11"`), đọc ghi chú `"Số dư chưa thanh toán vẫn được giữ nguyên và cộng dồn sang đợt tiếp theo."` và xác nhận.
   - Chuyển sang pill `Đợt đã chốt`: thấy thẻ `Đợt 1` với **`Số liệu tại thời điểm chốt`**; bấm `Xem các khoản chi đợt này` -> chuyển sang `Chi tiêu` đang lọc đúng `Đợt 1`.
   - Ở đầu segment `Chi tiêu`, chip đợt mặc định chọn `Đợt hiện tại` (rỗng sau khi vừa chốt); bấm chip để đổi qua `Đợt 1` hoặc `Tất cả các đợt`.
3. **Cộng dồn nợ & sửa lại khoản cũ:**
   - Nhập thêm 1 khoản chi mới hoặc 1 lượt chuyển khoản trả nợ muộn -> số dư của người chưa trả tự động cộng dồn tiếp, người đã trả chỉ tính khoản mới.
   - Mở lại `Đợt 1` và thử **sửa** một khoản chi cũ (ví dụ đổi số tiền hoặc tích lại người tham gia) -> kết quả đúng: sửa được trực tiếp, giao dịch vẫn nằm trong `Đợt 1` và số dư cộng dồn hiện tại tự tính lại ngay lập tức.
   - Kiểm tra nút `Mở lại đợt này` chỉ hiện ở đợt gần nhất (với chủ nhóm khi nhóm đang mở); thử chốt tiếp khi `Đợt hiện tại` chưa có giao dịch mới -> nút bị vô hiệu hoá hoặc báo `"Chưa có giao dịch mới để chốt đợt."`.
4. **Giải trình `"Số tiền này từ đâu ra?"`:**
   - Trong `Thanh toán` -> bấm `Xem giải trình khoản nợ` trên một thành viên bất kỳ (kể cả ngay sau khi vừa bấm `Chốt đợt`) -> kết quả đúng: thấy rõ `Số dư từ đợt trước`, danh sách từng buổi chi tiêu + phần của người đó, các lượt đã chuyển/nhận, và tổng khớp chính xác từng đồng với `Số dư hiện tại` (có thêm `Phân bổ thanh toán` nếu người đó cần chuyển cho từ 2 chủ nợ trở lên).

## 4. Link khách chỉ-xem (`/share/{token}`) & VietQR

1. **Bật & mở link khách không cần đăng nhập:**
   - Chủ nhóm/editor mở `Link khách` (từ `Thanh toán` hoặc màn hình Thành viên) -> bấm `Bật link khách chỉ xem` -> bấm `Sao chép link khách`.
   - Mở trình duyệt ẩn danh (hoặc gửi vào Zalo/Safari chưa đăng nhập, và thử bấm Universal Link trên iPhone) mở `/share/{token}`:
     - Hiển thị đầy đủ danh sách `Ai chuyển cho ai`, các khoản chi của nhóm, và bảng **Giải trình khoản nợ** + mã **VietQR** điền sẵn đúng số tiền và nội dung khi bấm vào từng thành viên.
     - Bấm vào một khoản chi mở chi tiết từng người + xem được ảnh hoá đơn mua hàng, **nhưng** ảnh chụp chuyển khoản ngân hàng (`transfer_proof`) không lộ ra ngoài trang khách.
     - Trên Web ẩn danh, mở DevTools Network tải lại `/share/{token}` -> kết quả đúng: không gọi `/api/v1/me` hay `/api/v1/notifications`.
2. **Đổi link & thu hồi link (kể cả nhóm đã lưu trữ):**
   - Bấm `Đổi link mới` -> link cũ ngay lập tức trả màn `"Liên kết xem chung không tồn tại hoặc đã được thu hồi."`.
   - Lưu trữ nhóm (`Lưu trữ nhóm`) rồi vào `Link khách` bấm `Thu hồi link` -> kết quả đúng: thu hồi được ngay cả khi nhóm đã lưu trữ, và trang `/share/{token}` lập tức báo không tồn tại (`404`).

## 5. Xuất ảnh 1 chạm qua Share Sheet (`Tổng kết nhóm` & `Nhắc nợ khéo`)

1. Trong `Thanh toán` của nhóm đông 12–20 thành viên, bấm `Xuất ảnh / Nhắc nợ`.
2. **Chế độ `Tổng kết nhóm`:**
   - Thử chuyển qua lại `Nền sáng` và `Nền tối`, bật/tắt `Kèm tóm tắt các khoản chi`.
   - Bấm `Chia sẻ ảnh` (iPhone mở Share Sheet / lưu vào Ảnh; Desktop Web tải PNG hoặc `Sao chép ảnh` dán trực tiếp vào Zalo/Messenger) -> kết quả đúng: ảnh nét (`1170px` rộng), chữ `Be Vietnam Pro` không vỡ, số tiền **nguyên đồng** không làm tròn `k`, hiển thị trọn vẹn tất cả 12–20 thành viên không bị cắt đuôi, kèm QR tài khoản nhận tiền (nếu chỉ có 1 người nhận dùng ngân hàng) và dòng link khách (nếu đang bật).
3. **Chế độ `Nhắc nợ khéo`:**
   - Chọn `Tất cả người chưa chuyển` và chọn 1 trong 3 câu nhắc mẫu (hoặc tự gõ lời nhắc ngắn < 100 ký tự).
   - Chọn riêng 1 người nợ -> kiểm tra thẻ ảnh xuất ra in sẵn bảng kê giải trình khoản nợ của người đó + mã **VietQR** điền sẵn đúng số tiền cần chuyển; thử quét thử bằng app ngân hàng để xác nhận nhận đúng số tài khoản và số tiền.
