# phase-5-6 — Hướng dẫn kiểm tra thực tế trên iPhone

Thực hiện trên iPhone thật sau khi nhánh `phase-5-6` được review, sử dụng bản build Debug từ Xcode (`SongPhang` scheme).

## Phần 1 — 13 bài kiểm tra cốt lõi (Spec mục 15)

1. **Nút Back nhất quán khắp ứng dụng (B01):**
   - **Thực hiện:** Vào một nhóm, lần lượt mở chi tiết một khoản chi, Thành viên, Hoạt động, Cài đặt nhóm, và Thống kê.
   - **Đúng:** Mọi màn hình chỉ có đúng một nút Back trên thanh điều hướng hệ thống; vuốt từ cạnh trái màn hình để quay lại hoạt động mượt mà; riêng chi tiết khoản chi không còn hai nút Back xếp chồng.

2. **Không che giờ hệ thống và Dynamic Island (B19):**
   - **Thực hiện:** Cuộn dọc Tài khoản, Danh sách nhóm, màn hình Nhóm và Chi tiết khoản chi.
   - **Đúng:** Thanh trạng thái và vùng Dynamic Island dùng hiệu ứng kính hệ thống, không có chữ hay thẻ nào đè lên đồng hồ.

3. **Hiển thị thanh Tab Bar đúng ngữ cảnh:**
   - **Thực hiện:** Mở chi tiết khoản chi, Thành viên, Hoạt động và Cài đặt nhóm; sau đó mở Nhập nhanh, Khoản chi mới và Ghi nhận đã nhận.
   - **Đúng:** Tab bar vẫn hiện ở bốn màn hình nội dung đầu tiên và ẩn ở ba màn hình tác vụ tập trung; khi quay lại không bị giật bố cục.

4. **Ở nguyên trong tab đang đứng:**
   - **Thực hiện:** Từ tab Tổng quan, chạm mở một nhóm rồi bấm Back; từ tab Thông báo, chạm mở một khoản chi rồi bấm Back.
   - **Đúng:** Back từ Tổng quan đưa về lại Tổng quan; Back từ Thông báo đưa về lại Thông báo.

5. **Nhân bản nhóm từ 3 điểm vào (B10):**
   - **Thực hiện:** Nhân bản một nhóm lần lượt từ menu ngữ cảnh ngoài danh sách nhóm, từ menu `...` trong màn hình Nhóm, và từ trong Cài đặt nhóm.
   - **Đúng:** Nhóm mới mở thẳng với tiêu đề nằm ngay dưới thanh điều hướng, hiện toast `"Đã tạo <Tên nhóm>"`, và bấm Back quay về thẳng Danh sách nhóm (không quay lại nhóm cũ).

6. **Nhóm không tồn tại, không có quyền và mục Danh mục của nhóm (B09, B18):**
   - **Thực hiện:** Bật cờ debug `--scripted --unknown-group --route-feed` để mở nhóm bị xoá/không tồn tại; tiếp theo bật `--scripted --role-editor --route-settings` và mở menu `...` ở vai trò biên tập viên, sau đó đổi về vai trò chủ nhóm để mở `"Danh mục của nhóm"`.
   - **Đúng:** Nhóm không tồn tại hiện màn hình sạch với nút Back và nút `"Về danh sách nhóm"`, không có header nhóm rỗng hay thanh phân đoạn; vai trò biên tập viên không thấy mục `"Danh mục của nhóm"` và thấy màn hình không có quyền nếu vào thẳng Cài đặt; vai trò chủ nhóm mở thẳng Cài đặt và tự cuộn tới phần Danh mục của nhóm.

7. **Hệ thống sheet, nút đóng và cảnh báo bỏ thay đổi:**
   - **Thực hiện:** Mở lần lượt các sheet Lọc, Link khách, Chốt đợt, Xoá nhóm, Nhân bản nhóm và Trả tiền (VietQR). Gõ thay đổi một trường bất kỳ trên sheet tạo/sửa rồi vuốt xuống hoặc bấm `"Huỷ"`.
   - **Đúng:** Mỗi sheet cao vừa đúng nội dung (nền kính mờ hệ thống); sheet chỉ xem dùng nút X góc trên trái, sheet thao tác/chỉnh sửa dùng `"Huỷ"` (ngoại trừ sheet xin quyền thông báo giữ `"Để sau"`), không sheet nào có mũi tên Back; vuốt xuống khi đã sửa dữ liệu sẽ hỏi `"Bỏ thay đổi?"` trước khi đóng.

8. **Âm thanh, rung và trộn nhạc nền (chưa kiểm chứng vật lý trên Simulator):**
   - **Thực hiện:** Dùng cờ `--scripted` để tạo/lưu một khoản chi; vào Thanh toán ghi nhận một khoản trả tiền; chạm ghi nhận thanh toán cuối cùng để nhóm về trạng thái tất toán (`--exercise-all-settled`). Tiếp theo gạt công tắc im lặng phần cứng (Ring/Silent) và lưu lại khoản chi. Cuối cùng vào Tài khoản -> `"Âm thanh và rung"` tắt lần lượt `"Âm thanh"` và `"Rung"`, rồi bật Apple Music/Spotify đang phát nhạc và lưu một khoản chi khác.
   - **Đúng:** Lưu khoản chi phát tiếng coin + rung `.success`; ghi nhận trả tiền phát tiếng ting + rung `.success`; cả nhóm tất toán phát hợp âm chord + 3 nhịp rung + hiệu ứng bung hình (mở nhóm đã tất toán sẵn hoặc nhận cập nhật từ người khác không phát gì); khi gạt im lặng thì tắt tiếng nhưng vẫn rung; khi tắt cả hai nút trong Tài khoản thì im lặng hoàn toàn; nhạc nền Apple Music/Spotify không bị ngắt quãng.

9. **Giảm chuyển động (Reduce Motion) và hiệu năng cuộn nhóm lớn (chưa kiểm chứng SwiftUI Instrument trên Simulator):**
   - **Thực hiện:** Bật Trợ năng -> Chuyển động -> Giảm chuyển động trên iPhone, chuyển các phân đoạn nhóm, mở sheet, tất toán hết nhóm và lưu khoản chi bị lỗi. Sau đó tắt Giảm chuyển động, chạy `--scripted --scenario-large --route-feed`, vừa cuộn nhanh danh sách 500 giao dịch vừa ghi nhận bằng Xcode Instruments (`SwiftUI` template) kết nối iPhone qua cáp.
   - **Đúng:** Khi bật Giảm chuyển động: không trượt pill, không bung hình tất toán, không cuộn chữ số tiền, không rung lắc trường nhập mà chỉ giữ đổi màu, âm thanh và rung phản hồi. Khi cuộn nhóm lớn: tốc độ khung hình mượt, không khựng đáng kể và số lần cập nhật thân view (`SwiftUI` View Body updates) ổn định.

10. **Cỡ chữ trợ năng lớn nhất (AX5, B07):**
    - **Thực hiện:** Vào Cài đặt iOS -> Trợ năng -> Màn hình & Cỡ chữ -> Chữ lớn hơn -> kéo lên mức lớn nhất; mở Danh sách nhóm, Dòng thời gian nhóm, Thanh toán, Ghi nhận đã nhận, Tạo nhóm và Khoản chi mới.
    - **Đúng:** Các hàng dày tự xếp dọc gọn gàng, mọi nhãn tiền, tên thành viên và nút bấm đều đọc rõ, không chữ nào bị cắt ngang hay chồng lên nút khác.

11. **Trạng thái đang tải đúng bố cục (B20):**
    - **Thực hiện:** Bật cờ `--scripted --latency-2s --no-snapshot`, mở một nhóm từ Danh sách nhóm và mở lại qua deep link (`--route-feed`).
    - **Đúng:** Mở từ danh sách hiện ngay tên nhóm và các hình thành viên; thanh nhập nhanh ở đáy màn hình xuất hiện ngay từ khung hình đầu tiên ở trạng thái chờ nhập (không nhảy bố cục khi dữ liệu về); khung xương (skeleton) khớp đúng bố cục thẻ số dư, ô tìm kiếm và từng dòng giao dịch; màn hình chi tiết dùng hình thành viên nhảy làm loader thay cho vòng xoay hệ thống.

12. **Bộ chọn thành viên đồng nhất (`MemberPicker`):**
    - **Thực hiện:** Mở Khoản chi mới, Lịch định kỳ và Đối chiếu hoá đơn rồi chạm chọn người trả / người tham gia.
    - **Đúng:** Cùng một giao diện lưới hình + chữ cái đầu, viền nét đứt cho người chưa nhận hình, nhãn `"Bạn"` cho người dùng hiện tại, và tiêu đề rõ ràng cho biết đang chọn cho mục gì.

13. **Tình huống lỗi và thao tác lặp:**
    - **Thực hiện:** Để trống số tiền hoặc mô tả trên Khoản chi mới rồi bấm Lưu; bấm đúp thật nhanh nút Lưu; bật chế độ Máy bay khi bấm Lưu.
    - **Đúng:** Thiếu dữ liệu khiến ô nhập rung ngang nhẹ 2 nhịp kèm rung cảnh báo; bấm đúp chỉ tạo duy nhất 1 giao dịch và chỉ phát âm thanh 1 lần; mất mạng hiện biểu ngữ ngoại tuyến chuẩn, không tạo dữ liệu dở dang.

---

## Phần 2 — Các hạng mục bổ sung ngoài Simulator (cần kiểm tra trên iPhone thật)

14. **VoiceOver thực tế trên iPhone (chưa nghe trực tiếp trên Simulator do hạn chế `osascript`/AX):**
    - **Thực hiện:** Bật VoiceOver trên iPhone thật, lướt từng phần tử trên màn hình Nhóm (header hình thành viên, menu `...`, ô tìm kiếm, nút Lọc, máy ảnh hoá đơn, từng thẻ chi tiêu), Ghi nhận đã nhận (`Thu` -> `Bạn`, số tiền, nút lưu), Khoản chi mới (loại giao dịch, số tiền, danh mục, từng ô `MemberPicker`), Sổ cá nhân (nút `"Xoá"` ở ô tìm kiếm), nút sao chép (`CopyButton`), và mục `"Âm thanh và rung"` trong Tài khoản.
    - **Đúng:** Mọi nút chỉ có icon đều đọc nhãn tiếng Việt rõ ràng; hình thành viên luôn đọc đúng tên thành viên (không đọc chữ cái đơn lẻ); `MemberPicker` đọc `"{tên}, đã chọn"` khi được chọn; `CopyButton` đọc `"Đã sao chép"` khi chạm; không có phần tử trang trí nào làm rối thứ tự đọc.

15. **Widget màn hình chính, Share Extension từ Ảnh và Deep Link (hạn chế tương tác hệ thống trên Simulator):**
    - **Thực hiện:** Thêm Widget Sòng Phẳng ra Màn hình chính, bật rồi tắt tuỳ chọn ẩn số tiền Widget trong tab Tài khoản; mở ứng dụng Ảnh chọn một ảnh hoá đơn -> Chia sẻ -> chọn Sòng Phẳng; mở Safari truy cập liên kết `songphang://group/01a1e4bd-cc25-70c6-860e-275da20487f1/balances` rồi bấm `"Open"` trên hộp thoại hệ thống.
    - **Đúng:** Widget cập nhật ẩn/hiện số tiền đúng theo công tắc trong Tài khoản; Share Extension nhận ảnh và chuyển vào luồng tạo khoản chi hoặc chứng từ chuyển khoản; liên kết `songphang://` mở thẳng màn hình Thanh toán của nhóm.
