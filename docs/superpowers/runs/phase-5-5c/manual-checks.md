# phase-5-5c — Hướng dẫn kiểm tra thực tế (Web + iPhone)

Tài liệu này liệt kê các kịch bản kiểm tra bằng tay cho chủ dự án trên Web và iPhone thật (sau khi chạy API + Worker + Web local và cài build `SongPhang` từ Xcode).

## Chuẩn bị môi trường local

1. Chạy database, migration (`0000`–`0033`), seed và khởi động `api`, `worker`, `web` như thường lệ.
2. Đăng nhập đủ các vai trò mẫu (ví dụ: `Minh` là `owner`, `Lan` là `viewer` đã liên kết thành viên `Lan`, `Khánh` là `editor` hoặc thành viên chưa liên kết tuỳ bài kiểm).
3. Kiểm tra không có emoji xuất hiện ở bất kỳ nhãn nút, thẻ chia tiền, thông báo, widget hay Share Sheet nào.

---

## Phần 1 — Phụ phí & Giảm giá ngay trên Form nhập tay (`S8`, Web & iPhone)

1. **Hoá đơn nhà hàng kiểu Three Koala (`VAT 8%`):**
   - Mở nhóm -> bấm tạo chi tiêu (`S8`). Kiểm tra khi chưa thêm phụ phí, ô tiền vẫn là `Số tiền` và màn hình gọn như cũ.
   - Nhập `346.000` -> bấm chip `VAT 8%`.
   - **Kỳ vọng:** Ô trên đổi nhãn thành `Tiền hàng`, thẻ `Phụ phí & Giảm giá` hiện dòng `Thuế VAT` (`8%` = `+27.680 đ`), mặc định chọn `Chia đều`, thanh màu vàng hiện `Tổng thanh toán: 373.680 đ`.
   - Vào `Chỉnh cách chia` -> `Theo số tiền`: nhập `168.000 đ` cho người A và `178.000 đ` cho người B -> kiểm tra preview tự cộng đều VAT (`181.840 đ` và `191.840 đ`), lưu và mở chi tiết `S20` (và `/share/{token}` nếu bật) thấy đủ khối `Tiền hàng`, `Thuế VAT (8%): +27.680 đ`, `Phụ phí chia đều`, `Tổng thanh toán: 373.680 đ`.
2. **Sửa tay số đồng lẻ & chuyển chế độ `Theo tỷ lệ`:**
   - Gõ sửa `+27.680 đ` thành `+27.681 đ` -> kiểm tra nhãn `8%` tự bỏ để giữ nguyên số đồng thực tế `373.681 đ`.
   - Gạt `Chia đều` -> `Theo tỷ lệ` và kiểm tra con số preview đổi tỷ lệ theo phần món gốc.
3. **Trường hợp biên — Giảm giá vượt quá phần món người ít tiền (Water-filling):**
   - Tạo chi tiêu `Theo số tiền`: người A `20.000 đ`, người B `200.000 đ` (Tổng `Tiền hàng 220.000 đ`), thêm chip `- Giảm giá` `50.000 đ` với chế độ `Chia đều`.
   - **Kỳ vọng:** Người A dừng ở `0 đ` (không bị âm), người B chịu `170.000 đ`, `Tổng thanh toán = 170.000 đ`.
4. **Trường hợp không hợp lệ & Lịch sử `Theo món` cũ:**
   - Chuyển loại giao dịch sang `Thu nhập`: kiểm tra không hiện/không cho gửi `extras`.
   - Mở một giao dịch quét hoá đơn `Theo món` cũ (tạo từ trước 5.5C): kiểm tra nhãn vẫn là `Phụ phí theo tỷ lệ` và nếu bấm sửa giữ nguyên tỷ lệ cũ.

---

## Phần 2 — Chi tiêu định kỳ (`S8`, `Quỹ & Thống kê`, `Tổng quan`, Web & iPhone)

1. **Tạo định kỳ trực tiếp khi nhập `S8`:**
   - Trong `S8`, nhập `Tiền Internet FPT` `300.000 đ`, bật công tắc `Lặp lại định kỳ` (`Tự động ghi sổ`, `Hằng tháng`), bấm Lưu.
   - **Kỳ vọng:** Tạo đúng **1** giao dịch cho hôm nay (không tự tạo đúp đơn thứ 2 trong ngày), vào `Quỹ & Thống kê` thấy mẫu `Tiền Internet FPT` với `Kỳ tiếp theo` là tháng sau.
2. **Tạo mẫu `Nhắc nhập số tiền` & chạy worker `process-recurring`:**
   - Trong `Quỹ & Thống kê` -> `+ Tạo chi tiêu định kỳ`, tạo mẫu `Tiền điện căn hộ` chế độ `Nhắc nhập số tiền`, `Hằng tháng`, chọn người trả là `Minh` (`owner` hoặc `editor`).
   - Kích hoạt job worker hoặc chỉnh ngày đến hạn về hôm nay và chạy `process-recurring`.
   - **Kỳ vọng:** Chưa tự tạo giao dịch mới; tab `Tổng quan` -> `Cần bạn xử lý` và đầu mục `Giao dịch định kỳ` hiện nhắc `Cần nhập số tiền kỳ ...` cùng nút `Nhập số tiền` và `Bỏ qua kỳ này`.
   - Bấm `Nhập số tiền` -> mở sẵn `S8` điền sẵn tên, người trả, cách chia -> nhập `850.000 đ` -> Lưu -> kiểm tra dòng nhắc biến mất trên `Tổng quan`, khoản `850.000 đ` xuất hiện trong `Chi tiêu`.
3. **Thao tác phụ & Trường hợp biên:**
   - Thử bấm `Bỏ qua kỳ này` hoặc `Tạm dừng` / `Bật lại` / `Xoá mẫu`.
   - Vào `Thành viên (S10)` chuyển một thành viên đang nằm trong mẫu định kỳ sang ngừng hoạt động (`active = false`) -> **Kỳ vọng:** mẫu định kỳ liên quan tự chuyển trạng thái `Đang tạm dừng` thay vì tiếp tục tính tiền người đó.
   - Kiểm tra tài khoản `viewer` chỉ xem được danh sách mẫu trong `Quỹ & Thống kê`, không thấy nút tạo/sửa/bỏ qua và không nhận nhắc viết sổ thay `editor+`.

---

## Phần 3 — Gộp nợ theo Hộ gia đình / Cặp đôi (`S10`, `Thanh toán`, `/share/{token}`, `ShareCard`, Web & iPhone)

1. **Tạo hộ trong `Thành viên (S10)`:**
   - Tạo nhóm có `Minh` (đã cài VietQR), `Lan` (tài khoản `viewer` đã liên kết) và `Khánh`.
   - Ghi vài bữa ăn để có `Minh +600.000 đ`, `Lan -250.000 đ`, `Khánh -350.000 đ`.
   - Vào `Thành viên (S10)` -> `Hộ gia đình / Cặp đôi` -> `+ Tạo nhóm hộ / cặp đôi` đặt tên `Nhà Minh & Lan`, chọn `Minh` và `Lan`, chọn `Minh` làm `Người đại diện thanh toán` (có badge gợi ý có sẵn VietQR).
2. **Kiểm tra số dư gộp đa màn hình:**
   - Vào `Thanh toán` trên tài khoản `Minh` và `Lan`:
     - **Kỳ vọng:** Đề xuất chỉ còn **1 lượt chuyển duy nhất**: `Khánh -> Minh (Đại diện Nhà Minh & Lan): 350.000 đ` dùng VietQR của `Minh`.
     - Hero card của `Lan` hiển thị số dư gộp của hộ (`+350.000 đ`) kèm dòng phụ `Phần riêng của bạn: -250.000 đ` · `Gộp thanh toán qua Minh`.
     - Bấm `Xem giải trình khoản nợ` hoặc `Xuất ảnh / Nhắc nợ` (`Tổng kết nhóm` / `Nhắc nợ khéo` Sáng & Tối) và mở `/share/{token}`: kiểm tra hiển thị rõ `Theo hộ / cặp đôi` và `Tổng hợp hộ Nhà Minh & Lan`.
3. **Kiểm tra quyền hai chiều & tất toán về `0 đ`:**
   - Đổi vai: giả sử `Nhà Minh & Lan` đang nợ `Khánh` `350.000 đ`. Đăng nhập bằng tài khoản `Lan` (`viewer` thuộc hộ):
     - **Kỳ vọng:** `Lan` vẫn thấy lượt chuyển `Minh (Đại diện Nhà Minh & Lan) -> Khánh` trong mục của mình và bấm được `Tôi đã chuyển` (kèm ảnh chứng từ).
   - Ở chiều ngược lại (`Khánh` báo chuyển cho `Minh`): đăng nhập `Lan` kiểm tra **không** thấy nút `Đã nhận` / `Từ chối` (chỉ `Minh` hoặc chủ nhóm mới bấm xác nhận nhận tiền vào tài khoản VietQR của `Minh` được).
   - Khi `Minh` xác nhận `Đã nhận` `350.000 đ`: kiểm tra `Tổng quan`, `Nhóm`, `Chi tiêu`, `Thanh toán` và `GroupInspector` (Web Desktop) của cả `Minh` và `Lan` đều về **`0 đ (Đã cân bằng)`**.
4. **Ràng buộc an toàn trên `S10`:**
   - Thử chuyển `Minh` (đang là người đại diện) sang ngừng hoạt động -> hệ thống chặn với thông báo nhắc đổi người đại diện hoặc tách nhóm hộ trước.

---

## Phần 4 — iOS Share Extension (`SongPhangShareExtension`, iPhone thật)

1. **Đăng nhập & chia sẻ từ Zalo / Photos (`Chi tiêu mới`):**
   - Mở Sòng Phẳng trên iPhone ít nhất 1 lần (ở trạng thái đã đăng nhập) để đồng bộ App Group & Shared Keychain.
   - Mở **Ảnh (Photos)** hoặc **Zalo**, mở 1 ảnh hoá đơn -> bấm **Chia sẻ -> Sòng Phẳng**.
   - **Kỳ vọng:** Sheet `Đưa vào Sòng Phẳng` mở lên mượt mà, chọn sẵn nhóm vừa mở gần nhất, chế độ mặc định `Chi tiêu mới` -> bấm `Tải lên & Tiếp tục`. Nếu host app cho phép chuyển app, Sòng Phẳng tự mở thẳng vào màn duyệt bill / Form `S8` đã gắn sẵn ảnh; nếu Zalo giữ lại, đóng sheet rồi tự chuyển sang Sòng Phẳng, app tự nhận diện `ShareInbox` và mở thẳng tiếp tục không mất ảnh.
2. **Chia sẻ ảnh chuyển khoản từ App Ngân hàng (`Chứng từ trả nợ`):**
   - Chọn 1 ảnh biên lai chuyển khoản -> **Chia sẻ -> Sòng Phẳng** -> chọn `Chứng từ trả nợ` -> bấm `Tải lên & Tiếp tục`.
   - **Kỳ vọng:** Ảnh được upload với mục đích `transfer_proof` và mở sang màn `Thanh toán` của nhóm đã chọn với chứng từ sẵn sàng.
3. **Khi chưa đăng nhập:**
   - Đăng xuất trong app Sòng Phẳng -> thử chia sẻ ảnh từ Photos vào Sòng Phẳng -> hiện thông báo yêu cầu mở app đăng nhập trước, không lộ dữ liệu nhóm cũ.

---

## Phần 5 — iOS Home Screen Widget & Quick Actions (`SongPhangWidgetExtension`, iPhone thật)

1. **Thêm Widget `Sòng Phẳng` ra Màn hình chính:**
   - Thêm cả 2 cỡ **Nhỏ (`Small`)** và **Vừa (`Medium`)**, kiểm tra trên cả nền Sáng và Tối.
   - **Kỳ vọng:** Hiển thị số dư ròng gộp chuẩn `tabular-nums`, tên nhóm gần nhất; trên Widget Vừa bấm từng nút `Ghi nhanh`, `Nhập tay / Bill`, `Thanh toán` mở thẳng đúng màn hình của nhóm đó; Widget Nhỏ chạm `+ Ghi chi tiêu` mở thẳng `Ghi nhanh`.
2. **Công tắc riêng tư `Ẩn số tiền trên Widget`:**
   - Vào tab `Tài khoản` -> bật `Ẩn số tiền trên Widget` -> quay ra Màn hình chính kiểm tra Widget đổi thành `Số dư đang ẩn` ngay.
3. **Quick Actions (nhấn giữ icon Sòng Phẳng):**
   - Nhấn giữ biểu tượng app trên Màn hình chính -> kiểm tra 3 lối tắt `Ghi chi tiêu nhanh`, `Nhập tay / Quét hoá đơn`, `Xem cần thanh toán` mở đúng đích.
4. **Đăng xuất xoá sạch dữ liệu Widget:**
   - Đăng xuất tài khoản -> kiểm tra Widget quay về trạng thái chưa đăng nhập và nhấn giữ icon không còn lối tắt nhóm cũ.
