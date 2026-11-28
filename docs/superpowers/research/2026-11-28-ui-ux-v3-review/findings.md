# UI/UX v3 Review — Findings Register

Every finding from the four review parts, with a stable ID, the phase that owns it, and its status. This register is the checklist for UI/UX v3: a phase is not finished until every finding assigned to it is closed. How to use it is in [README.md](README.md).

Generated on 2026-11-28 from the four parts in this folder; maintained by hand from then on. The finding text is quoted from the parts in the original Vietnamese.

## Summary

| Phase | Findings |
|---|---|
| 5.6 — iOS foundations | 73 |
| 5.7 — iOS core screens | 161 |
| 5.8 — iOS money and secondary screens | 74 |
| All phases (rules every phase applies) | 8 |
| **Total** | **316** |
| 5.9 — Web v3 | Applies the finished iOS outcome of every row above to Web; tracked in the 5.9 spec |

Columns:

- **Type:** `Issue · <severity>` (a problem, with the review's severity label), `Defect` (broken behaviour), `Keep` (works well; must survive the redesign), `Remove`, `Change`, `Direction` (the proposed fix for the section), `Rule` (a principle or rationale), `Point` (one item of a list), `Repetition` (repeated text or controls), `Table row` (one row of a review table).
- **Defect:** the defect ID below when the finding is one of the 21 defects.
- **Status:** `Open`, `Done (<phase>, <commit>)`, `Changed (<decision>)`, or `Deferred (<reason>)`. A note after `Open:` flags something the phase spec must resolve.

## Defects

The 21 defects to fix in v3 (owner decision D1). The phase listed owns the fix and its manual check.

| ID | Defect | Found in | Phase | Status |
|---|---|---|---|---|
| B01 | Expense detail shows two back buttons and the header runs to the edge | Part 2 | 5.6 | Open |
| B02 | Pay sheet ignores role: the receiver sees "Trả Minh" and "Sao chép số tiền" | Part 2 | 5.7 | Open |
| B03 | Empty shared fund offers only "Quay lại", no way to set up the fund there | Part 2 | 5.8 | Open |
| B04 | Current cycle reads "26/11/2026 – 0" instead of a date or "đến nay" | Part 2 | 5.8 | Open |
| B05 | A new user with no groups sees "Bạn đã sòng phẳng ở tất cả nhóm" | Part 3 | 5.7 | Open |
| B06 | Quick entry: "Chỉnh tay" and "Lưu" are overlapped and cut by the "Nhập tay" label | Part 3 | 5.7 | Open |
| B07 | Dynamic Type is uneven: Settle breaks its layout, the expense form barely scales | Part 3 | 5.6 | Open |
| B08 | Viewer role: every row has a yellow "Xem" button and the bottom bar is a "Chỉ xem" shortcut | Part 3 | 5.7 | Open |
| B09 | Group not found still draws the group header with an empty member capsule | Part 3 | 5.6 | Open |
| B10 | A cloned group's header sits under the clock and cannot be pulled back | Part 4 | 5.6 | Open |
| B11 | An empty group shows "Bạn đã xong 0 đ" with a "Xem" button | Part 4 | 5.7 | Open |
| B12 | An empty group's title is truncated ("Gõ khoản chi đầu t…") | Part 4 | 5.7 | Open |
| B13 | Receipt review shows unformatted amounts (280000) and an ISO date (2026-11-16) | Part 4 | 5.8 | Open |
| B14 | Receipt surcharge has two fields with the same label, one truncated to "Phí dịc…" | Part 4 | 5.8 | Open |
| B15 | The group composer wraps to two lines when the camera button is shown | Part 4 | 5.7 | Open |
| B16 | Recurring card text and buttons wrap mid-phrase | Part 4 | 5.8 | Open |
| B17 | Recurring form cuts off "Hằng năm" with no hint that the row scrolls | Part 4 | 5.8 | Open |
| B18 | "Danh mục của nhóm" opens the top of settings; for an editor it opens a no-permission screen with no header or back button | Part 4 | 5.6 | Open |
| B19 | Account tab content scrolls under the clock | Part 4 | 5.6 | Open |
| B20 | Loading group: blank name, empty member capsule, and the composer appears late so the layout jumps | Part 4 | 5.6 | Open |
| B21 | On iPhone SE the "Ghi nhận đã nhận" note is covered by the button | Part 4 | 5.7 | Open |

B15 appears only in the defect list of part 4, so no finding row below carries it.

## Findings by part

### [01-main-screens.md](01-main-screens.md)

| ID | Section | Type | Finding | Phase | Defect | Status |
|---|---|---|---|---|---|---|
| F1-01 | Hình thành viên | Keep | Tròn, thoi, vuông bo, lá: nhận diện người không cần đọc tên. Đây là tài sản thương hiệu mạnh nhất, nên dùng nhiều hơn chứ không ít đi. | All |  | Open |
| F1-02 | Ô gõ như nhắn tin | Keep | "Lẩu 300k Minh trả chia đều" là cách nhập nhanh nhất thị trường. Nên là cửa chính, không phải tính năng phụ. | 5.7 |  | Open |
| F1-03 | Một con số lớn | Keep | Thẻ vàng "Bạn được nhận 500.001 đ" trả lời đúng câu hỏi số một. Chỉ cần đừng lặp lại nó 3 lần. | 5.7 |  | Open |
| F1-04 | Câu chữ thân thiện ở vài chỗ | Keep | "3 lượt chuyển là xong", "Mình chưa hiểu hết câu này" có giọng người thật. Nên đưa giọng này ra toàn app. | 5.6 |  | Open |
| F1-05 | Nhóm › Thanh toán: ba tầng điều hướng trước khi tới việc chính | Issue · Nặng | Segment (Chi tiêu / Thanh toán / Quỹ) → tab con (Cần thanh toán / Sổ thanh toán / Đợt đã chốt) → hàng nút (Xuất ảnh / Link khách / Chốt đợt). Người mới không biết bấm đâu. | 5.7 |  | Open |
| F1-06 | Nhóm › Thanh toán: ba tầng điều hướng trước khi tới việc chính | Issue · Nặng | Nút "Lập quỹ chung" nằm trên cùng của màn thanh toán, dù không liên quan tới việc trả nợ. | 5.7 |  | Open |
| F1-07 | Nhóm › Thanh toán: ba tầng điều hướng trước khi tới việc chính | Issue · Vừa | Số "Bạn được nhận 500.001 đ" lặp lại lần thứ ba (Tổng quan, thẻ vàng tab Chi tiêu, tab này). "Xem giải trình khoản nợ" xuất hiện 2 lần. | 5.7 |  | Open |
| F1-08 | Nhóm › Thanh toán: ba tầng điều hướng trước khi tới việc chính | Issue · Vừa | Khoản chuyển đầu tiên (việc thật sự cần làm) bị đẩy xuống gần đáy màn hình. | 5.7 |  | Open |
| F1-09 | Nhóm › Thanh toán: ba tầng điều hướng trước khi tới việc chính | Direction | Hướng sửa: bỏ tab con và hàng nút. Màn này chỉ còn danh sách "Ai trả ai" kèm nút "Đã nhận" ngay trên hàng. Lịch sử, chốt đợt, link khách và ảnh nhắc nợ vào menu "•••" hoặc trang Thông tin nhóm. | 5.7 |  | Open |
| F1-10 | Form thêm chi: 10 khối cho một việc cần 3 thông tin | Issue · Nặng | Phụ phí và giảm giá (VAT 8%, VAT 10%, Phí DV 5%…) hiện sẵn cho mọi khoản, dù đa số khoản chi không cần. | 5.7 |  | Open |
| F1-11 | Form thêm chi: 10 khối cho một việc cần 3 thông tin | Issue · Vừa | Ô số tiền không tự mở bàn phím. Người dùng phải chạm thêm một lần trước khi gõ. | 5.7 |  | Open |
| F1-12 | Form thêm chi: 10 khối cho một việc cần 3 thông tin | Issue · Vừa | "Ai trả?" và "Chia cho ai?" cùng hiện 4 ô hình lớn. Hai lưới gần giống nhau làm người dùng phải dò xem mình đang ở lưới nào. | 5.7 |  | Open |
| F1-13 | Form thêm chi: 10 khối cho một việc cần 3 thông tin | Issue · Nhẹ | Ba kiểu điều khiển khác nhau: toggle xám hệ thống (Lặp lại định kỳ), toggle vàng tự vẽ (Gộp nợ), ô ngày giờ xám của hệ thống. | 5.7 |  | Open |
| F1-14 | Form thêm chi: 10 khối cho một việc cần 3 thông tin | Direction | Hướng sửa: số tiền (bàn phím mở sẵn) → việc gì → một dòng tóm tắt "Bạn trả · chia đều 4 người ›". Ngày, lặp lại, ảnh, phụ phí, danh mục thu về hàng chip "Thêm chi tiết"; chip nào được dùng mới mở rộng. | 5.7 |  | Open |
| F1-15 | Nhóm › Chi tiêu: chỉ 2 khoản chi lọt vào màn hình đầu | Issue · Nặng | Mỗi thẻ có hai con số không nhãn (300.000 và 120.000). Người dùng phải đoán số thứ hai là gì. Khi thiếu `myDelta`, số này còn hiện màu xám, không dấu. | 5.7 |  | Open |
| F1-16 | Nhóm › Chi tiêu: chỉ 2 khoản chi lọt vào màn hình đầu | Issue · Vừa | Mỗi thẻ có 7 mẩu thông tin: hình người trả, "Bạn trả", giờ, tên, danh mục, cụm hình người tham gia, cách chia. Giờ và cách chia ít khi cần trong danh sách. | 5.7 |  | Open |
| F1-17 | Nhóm › Chi tiêu: chỉ 2 khoản chi lọt vào màn hình đầu | Issue · Vừa | Thẻ vàng, hai liên kết chữ, ô tìm kiếm và nút Lọc chiếm nửa màn hình trước khi tới khoản chi đầu tiên. | 5.7 |  | Open |
| F1-18 | Nhóm › Chi tiêu: chỉ 2 khoản chi lọt vào màn hình đầu | Direction | Hướng sửa: thẻ một dòng (hình người trả, tên khoản, "Bạn trả · 4 người", bên phải là phần của bạn có màu và dấu, tổng nhỏ bên dưới). Tìm kiếm chuyển thành kéo xuống để hiện, như Mail và Tin nhắn. | 5.7 |  | Open |
| F1-19 | Tổng quan và Nhóm: hai tab nói cùng một điều | Issue · Nặng | Tab Tổng quan và tab Nhóm đều có lời chào, tên nhóm, hình thành viên và số dư. Chuông thông báo xuất hiện ở cả header lẫn tab bar, và ảnh đại diện trùng với tab Tài khoản. | 5.7 |  | Open |
| F1-20 | Tổng quan và Nhóm: hai tab nói cùng một điều | Issue · Vừa | "Chênh lệch ròng" cùng hai số "Tổng được nhận" và "Tổng cần trả", trong khi một trong hai thường bằng 0. | 5.7 |  | Open |
| F1-21 | Tổng quan và Nhóm: hai tab nói cùng một điều | Issue · Nhẹ | Khi cuộn, nội dung chạy xuyên qua thanh trạng thái mà không có lớp mờ phía sau. | 5.7 |  | Open |
| F1-22 | Tổng quan và Nhóm: hai tab nói cùng một điều | Direction | Hướng sửa: gộp thành một màn hình chính "Nhóm" có một câu tổng ở trên ("Tính chung, bạn được nhận 500.001 đ"). Tab bar còn 3 mục. | 5.7 |  | Open |
| F1-23 | Quỹ & Thống kê: thêm một tầng tab nữa | Issue · Vừa | Segment → "Tiền đi đâu / Quỹ chung" → chip thời gian: ba hàng chọn chồng lên nhau. | 5.7 |  | Open |
| F1-24 | Quỹ & Thống kê: thêm một tầng tab nữa | Issue · Vừa | "Minh · đã trả 1.100.000 đ · phần mình 600.000 đ" là một câu dài xuống 2 dòng, kèm hai thanh bar không có chú thích. | 5.7 |  | Open |
| F1-25 | Quỹ & Thống kê: thêm một tầng tab nữa | Direction | Hướng sửa: thống kê là trang con mở từ "•••", không phải một segment lúc nào cũng hiện. Quỹ chung chỉ hiện khi nhóm đã có quỹ. | 5.7 |  | Open |
| F1-26 | Tài khoản: form đổi mật khẩu nằm ngay trang chính | Issue · Vừa | Ba ô mật khẩu luôn hiện, dù việc này làm vài lần mỗi năm. Trang dài và trông như một form phải điền. | 5.8 |  | Open |
| F1-27 | Tài khoản: form đổi mật khẩu nằm ngay trang chính | Direction | Hướng sửa: danh sách kiểu Cài đặt iOS (Giao diện, Âm thanh và rung, Thông báo, Bảo mật ›). Đổi mật khẩu là một trang con. | 5.8 |  | Open |
| F1-28 | Một màn, một việc | Rule | Mỗi màn có đúng một nút chính. Nếu cần hai nút chính, đó là hai màn. | All |  | Open |
| F1-29 | Đưa đáp án, giấu phép tính | Rule | Hiện "Thu trả bạn 210.000 đ". Cách ra con số đó chỉ hiện khi chạm vào. | All |  | Open |
| F1-30 | Nói như bạn bè | Rule | "Ai nợ ai", "Xong rồi", "Đã nhận tiền". Không dùng từ của kế toán. | 5.6 |  | Open |
| F1-31 | Tính năng hiện khi cần | Rule | Quỹ, chốt đợt, định kỳ, phụ phí: chỉ xuất hiện khi nhóm đã dùng, hoặc khi người dùng tự mở. | 5.7 |  | Open |
| F1-32 | Tiền đổi thì app phản hồi | Rule | Số dư thay đổi luôn đi kèm chuyển động, rung và (tuỳ chọn) âm thanh. | 5.6 |  | Open |
| F1-33 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Tổng quan · Số ròng, định kỳ, số dư theo nhóm, giao dịch gần đây | 5.7 |  | Open |
| F1-34 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Nhóm · Đang mở / Đã lưu trữ, thẻ nhóm, Tạo nhóm | 5.7 |  | Open |
| F1-35 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Thông báo | 5.7 |  | Open |
| F1-36 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Tài khoản | 5.7 |  | Open |
| F1-37 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Trong nhóm: Chi tiêu · Thanh toán · Quỹ & Thống kê · + 3 tab con Thanh toán, + 2 tab con Quỹ, + menu 6 mục | 5.7 |  | Open |
| F1-38 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Nhóm (màn hình chính) · Một câu tổng ở trên + danh sách nhóm. Nhóm lưu trữ nằm cuối danh sách, thu gọn. | 5.7 |  | Open |
| F1-39 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Hoạt động · Thông báo + sổ cá nhân gộp làm một dòng thời gian | 5.7 |  | Open |
| F1-40 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Tab Tôi · Danh sách cài đặt; mỗi mục là trang con | 5.7 |  | Open |
| F1-41 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Trong nhóm: một màn duy nhất · Thẻ số dư có nút theo ngữ cảnh (Thu về / Trả ngay / Xong rồi) → danh sách chi tiêu → ô gõ | 5.7 |  | Open |
| F1-42 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Sheet "Ai trả ai" · Mở từ thẻ số dư. Lịch sử và chốt đợt là liên kết ở cuối sheet. | 5.7 |  | Open |
| F1-43 | Từ 4 tab và 3 segment xuống 3 tab và 1 màn nhóm | Point | Thông tin nhóm (chạm vào tên nhóm) · Thành viên, quỹ, thống kê, định kỳ, link khách, Telegram, cài đặt. Giống trang thông tin nhóm của Tin nhắn. | 5.7 |  | Open |
| F1-44 | Hệ thống chuyển động, rung và âm thanh | Table row | **Mọi con số tiền thay đổi** · Chữ số lăn tới giá trị mới (`numericText`) · Không · Không | 5.6 |  | Open |
| F1-45 | Hệ thống chuyển động, rung và âm thanh | Table row | **Gõ câu, app hiểu** · Từ khoá sáng lần lượt trái sang phải, hình người "nảy" vào theo thứ tự · Chạm nhẹ khi hiểu xong · Không | 5.7 |  | Open |
| F1-46 | Hệ thống chuyển động, rung và âm thanh | Table row | **Lưu khoản chi** · Thẻ bay từ ô gõ vào đầu danh sách, số dư lăn · `.success` · "Tách" ngắn kiểu đồng xu | 5.7 |  | Open |
| F1-47 | Hệ thống chuyển động, rung và âm thanh | Table row | **Đã nhận / Đã chuyển** · Nút đổi thành dấu tích, hàng trượt ra, hình người nhún một cái · `.success` · "Ting" nhẹ | 5.7 |  | Open |
| F1-48 | Hệ thống chuyển động, rung và âm thanh | Table row | **Cả nhóm hết nợ** · Hình thành viên bung ra như pháo giấy, thẻ "Sòng phẳng rồi!" · Chuỗi 3 nhịp · Hợp âm ngắn, dưới 1 giây | 5.7 |  | Open |
| F1-49 | Hệ thống chuyển động, rung và âm thanh | Table row | **Chọn chip, đổi tab, chọn người** · Lò xo nhanh; biểu tượng tab nảy (`.symbolEffect(.bounce)`) · `.selection` · Không | 5.6 |  | Open |
| F1-50 | Hệ thống chuyển động, rung và âm thanh | Table row | **Vuốt xoá / sửa** · Hành động lộ ra theo ngón tay · Tích khi qua ngưỡng · Không | 5.6 |  | Open |
| F1-51 | Hệ thống chuyển động, rung và âm thanh | Table row | **Lỗi nhập liệu** · Ô lắc ngang 2 lần · `.warning` · Không | 5.6 |  | Open |
| F1-52 | Hệ thống chuyển động, rung và âm thanh | Table row | **Đang tải** · Bốn hình thành viên nhún lần lượt thay cho vòng xoay; khung xương có ánh sáng chạy · Không · Không | 5.6 |  | Open |
| F1-53 | Hệ thống chuyển động, rung và âm thanh | Table row | **Có thông báo mới** · Chuông lắc (`.symbolEffect(.wiggle)`) · Không · Không | 5.7 |  | Open |
| F1-54 | Luật cho âm thanh | Point | Tối đa 4 âm, mỗi âm dưới 400 ms, âm lượng thấp, file `.caf` vài KB. | 5.6 |  | Open |
| F1-55 | Luật cho âm thanh | Point | Dùng audio session `.ambient`: tự im khi máy ở chế độ im lặng và không ngắt nhạc đang phát. | 5.6 |  | Open |
| F1-56 | Luật cho âm thanh | Point | Thêm mục "Âm thanh và rung" trong tab Tôi, có thể tắt riêng từng loại. | 5.6 |  | Open |
| F1-57 | Luật cho âm thanh | Point | Chỉ phát cho hành động của chính người dùng. Không phát khi người khác thêm chi qua realtime. | 5.6 |  | Open |
| F1-58 | Luật cho chuyển động | Point | Ba token lò xo dùng chung: **nhanh** (chọn, đổi tab), **nảy** (thành công), **êm** (mở sheet). Đặt trong `DesignSystem/Tokens`. | 5.6 |  | Open |
| F1-59 | Luật cho chuyển động | Point | Chỉ một khoảnh khắc "ăn mừng" lớn: khi cả nhóm hết nợ. Còn lại giữ nhỏ và nhanh để app vẫn đáng tin khi xử lý tiền. | 5.6 |  | Open |
| F1-60 | Luật cho chuyển động | Point | Chuyển helper `Haptics` sang modifier `.sensoryFeedback` để rung gắn với thay đổi trạng thái, không gọi tay. | 5.6 |  | Open |
| F1-61 | Viết lại theo giọng bạn bè | Table row | Chênh lệch ròng · **Tính chung, bạn được nhận** · Một câu thay cho ba con số | 5.7 |  | Open |
| F1-62 | Viết lại theo giọng bạn bè | Table row | Xem giải trình khoản nợ · **Vì sao?** · Ngắn, đúng câu người dùng tự hỏi | 5.7 |  | Open |
| F1-63 | Viết lại theo giọng bạn bè | Table row | Cần thanh toán / Sổ thanh toán / Đợt đã chốt · **Ai trả ai** + liên kết "Lịch sử" · Bỏ hai tab con | 5.7 |  | Open |
| F1-64 | Viết lại theo giọng bạn bè | Table row | Ghi nhận · **Đã nhận tiền** · Nói rõ việc vừa xảy ra | 5.7 |  | Open |
| F1-65 | Viết lại theo giọng bạn bè | Table row | Gộp nợ · **Ít lượt chuyển nhất** · Mô tả kết quả, không mô tả thuật toán | 5.7 |  | Open |
| F1-66 | Viết lại theo giọng bạn bè | Table row | Đọc-ghi / Chỉ xem · **Được thêm chi / Chỉ xem** · Nói bằng hành động | 5.8 |  | Open |
| F1-67 | Viết lại theo giọng bạn bè | Table row | Quỹ & Thống kê · Tiền đi đâu · **Chi tiêu theo loại** (trong Thông tin nhóm) · Không còn là segment | 5.7 |  | Open |
| F1-68 | Viết lại theo giọng bạn bè | Table row | Chia đều · đổi cách chia · **Chia đều 4 người ›** · Dấu › đã nói "chạm để đổi" | 5.7 |  | Open |
| F1-69 | Học bằng cách làm, không có slide hướng dẫn | Point | **Nhóm trống:** ô gõ tự gõ thử một câu mẫu ("Lẩu 300k Minh trả chia đều") rồi xoá đi, như con trỏ đang làm mẫu. Chạm vào là dùng câu đó. | 5.7 |  | Open |
| F1-70 | Học bằng cách làm, không có slide hướng dẫn | Point | **Mỗi màn tối đa một gợi ý**, hiện một lần rồi biến mất vĩnh viễn (ví dụ "Vuốt trái để sửa" ở khoản chi đầu tiên). | 5.7 |  | Open |
| F1-71 | Học bằng cách làm, không có slide hướng dẫn | Point | **Mở dần tính năng:** chip "Phụ phí" chỉ xuất hiện sau khoản chi thứ 3; "Chốt đợt" chỉ hiện khi nhóm có trên 20 khoản; "Quỹ" chỉ hiện khi có người lập quỹ. Người dùng lâu năm vẫn tìm được mọi thứ trong Thông tin nhóm. | 5.7 |  | Open |
| F1-72 | Học bằng cách làm, không có slide hướng dẫn | Point | **Khoản chi đầu tiên được ăn mừng** bằng một hiệu ứng nhỏ. Mục tiêu là người mới thêm được khoản chi đầu tiên trong vòng một phút. | 5.7 |  | Open |

### [02-detail-screens.md](02-detail-screens.md)

| ID | Section | Type | Finding | Phase | Defect | Status |
|---|---|---|---|---|---|---|
| F2-01 | Chi tiết khoản chi: hai nút quay lại | Defect | Nút tròn kính mờ phía trên là của hệ thống, nút vuông phía dưới là header tự vẽ. Header còn tràn ra hai mép: nút quay lại và nút “Sửa” bị cắt. Nguyên nhân: `TransactionDetailView` là màn duy nhất trong nhóm này quên `.navigationBarBackButtonHidden(true)`. | 5.6 | B01 | Open |
| F2-02 | Chi tiết khoản chi: hai nút quay lại | Issue · Gốc | Sửa một dòng thì hết lỗi này, nhưng lỗi sẽ quay lại ở màn mới tiếp theo. 17 màn tự vẽ header, kèm `PopGestureEnabler` để bật lại cử chỉ vuốt lùi và `StatusBarCover` để che chữ chạy dưới đồng hồ. Ba thứ vá cho một quyết định. | 5.6 |  | Open |
| F2-03 | Chi tiết khoản chi: hai nút quay lại | Direction | Hướng: trả thanh điều hướng về cho hệ thống ở mọi màn đẩy sang. Tiêu đề, nút quay lại, nút phụ bên phải đặt bằng `toolbar`. Khi đó có sẵn: vuốt lùi đúng chuẩn, tiêu đề lớn thu nhỏ khi cuộn, nền kính mờ Liquid Glass ở mép trên, và không cần hai miếng vá. Giữ được màu, font và hình thành viên của Sòng Phẳng vì phần đó nằm trong nội dung, không nằm ở thanh điều hướng. | 5.6 |  | Open |
| F2-04 | Chi tiết khoản chi: hai nút quay lại | Table row | **Tổng quan → mở nhóm** · Đổi sang tab Nhóm và thay cả ngăn xếp (`groupsPath = [...]`) · Màn hình nhảy sang tab khác, không có hiệu ứng đẩy. Bấm quay lại thì về danh sách nhóm, không về Tổng quan. · Đẩy nhóm vào ngay ngăn xếp của tab đang đứng. Quay lại về đúng chỗ vừa bấm. | 5.6 |  | Open |
| F2-05 | Chi tiết khoản chi: hai nút quay lại | Table row | **Thông báo → khoản chi** · Cũng đổi tab rồi đẩy · Như trên: mất chỗ đang đọc trong hộp thông báo. · Đẩy trong tab Thông báo. | 5.6 |  | Open |
| F2-06 | Chi tiết khoản chi: hai nút quay lại | Table row | **Mọi màn đẩy sang** · Ẩn tab bar (`.toolbar(.hidden, for: .tabBar)`) · Tab bar biến mất khi đi vào và hiện bật lại ở cuối lúc quay ra, nhìn như giật. · Giữ tab bar ở màn nội dung (chi tiết, thành viên, lịch sử). Chỉ ẩn ở màn làm việc tập trung, và các màn đó nên là toàn màn hình (xem dòng dưới). Cần thử trên máy thật để xác nhận mức giật. | 5.6 |  | Open |
| F2-07 | Chi tiết khoản chi: hai nút quay lại | Table row | **Thêm / sửa khoản chi, nhập nhanh, ghi nhận đã nhận** · Đẩy sang như một trang · Đây là việc cần làm xong hoặc huỷ, nhưng trông như một trang để đọc. Vuốt lùi giữa chừng là mất dữ liệu đang nhập mà không hỏi. · Mở dạng toàn màn hình hoặc sheet lớn, có “Huỷ” bên trái, nút lưu ở dưới. Vuốt xuống khi đã nhập thì hỏi lại. | 5.7 |  | Open |
| F2-08 | Chi tiết khoản chi: hai nút quay lại | Table row | **Thẻ khoản chi → chi tiết** · Đẩy sang thường · Ổn, nhưng không nối được thẻ với trang. · Chuyển kiểu phóng to từ thẻ (`.navigationTransition(.zoom)`). Đây là chỗ duy nhất tôi đề xuất kiểu chuyển riêng. Bản iOS 26.x còn lỗi thẻ gốc biến mất khi vuốt lùi giữa chừng, nên phải thử trên bản iOS mới nhất trước khi chốt. | 5.7 |  | Open |
| F2-09 | Chi tiết khoản chi: hai nút quay lại | Table row | **Quét hoá đơn → kiểm tra**; **Sheet trả tiền → Ghi nhận luôn** · Đóng sheet rồi mới đẩy màn mới · Hai chuyển động nối nhau, màn hình “thở” hai lần. · Làm tiếp ngay trong sheet (đẩy bên trong sheet), hoặc thay nội dung sheet. Một chuyển động cho một ý. | 5.8 |  | Open |
| F2-10 | Chi tiết khoản chi: hai nút quay lại | Table row | **Nhân bản nhóm** · Đẩy nhóm mới lên trên nhóm cũ · Quay lại thì về nhóm cũ, rồi quay lại nữa mới ra danh sách. · Thay nhóm cũ bằng nhóm mới trong ngăn xếp. | 5.8 |  | Open |
| F2-11 | Chi tiết khoản chi: hai nút quay lại | Table row | **Đổi segment trong nhóm** · Đổi màu nền nút; nội dung cả màn mờ đi rồi hiện lại · Viên chọn không trượt, cả màn nháy. · Nếu giữ segment: viên chọn trượt theo (`matchedGeometryEffect`), nội dung đổi ngay không mờ. Nếu theo cấu trúc mới ở phần 1 thì segment không còn. | 5.7 |  | Open |
| F2-12 | So sánh: bộ lọc (trái) và link khách (phải) | Keep | Bộ lọc: cao vừa nội dung, có thanh kéo, nút chính ở dưới cùng. Chỉ cần bỏ bớt một trong ba nút (“Huỷ”, “Xoá lọc”, “Áp dụng”) và cho chip Người có hình thành viên. | 5.8 |  | Open |
| F2-13 | So sánh: bộ lọc (trái) và link khách (phải) | Issue · Cao | Link khách: nội dung chiếm một phần ba, phần còn lại trống. Chữ “chỉ xem” xuất hiện ở tiêu đề, nhãn vàng và nút. Khi bật lên, đường link thô hiện nguyên văn, chữ “link” lặp 6 lần, và “Thu hồi link” to bằng “Đổi link mới”. | 5.8 |  | Open |
| F2-14 | So sánh: bộ lọc (trái) và link khách (phải) | Direction | Hướng cho link khách: sheet cao theo nội dung. Một câu giải thích, một thẻ xem trước trang khách sẽ thấy, một nút “Gửi link” mở bảng chia sẻ của iOS (có sẵn nút sao chép trong đó). “Đổi link” và “Tắt link” vào menu dấu ba chấm, tắt thì hỏi lại. | 5.8 |  | Open |
| F2-15 | Sheet trả tiền và sheet xoá nhóm | Issue · Sai vai | Tôi đăng nhập là Minh, bấm “Ghi nhận” ở hàng “Thu trả bạn”. Sheet mở ra tiêu đề “Trả Minh”, có nút “Sao chép số tiền” và dòng “Minh chưa có thông tin nhận tiền”. Đây là màn của người trả, đưa cho người nhận. Tiêu đề luôn là `pay.title = "Trả {to}"`, không xét ai đang xem. | 5.7 | B02 | Open |
| F2-16 | Sheet trả tiền và sheet xoá nhóm | Issue · Kiểu | Sheet có nút mũi tên quay lại, một tín hiệu của màn đẩy sang. Việc chính (“Ghi nhận luôn”) là một dòng chữ gạch chân ở đáy, còn ba ô tuỳ chọn thì to. “(tuỳ chọn)” lặp 3 lần. | 5.7 |  | Open |
| F2-17 | Sheet trả tiền và sheet xoá nhóm | Issue · Cao | Xoá nhóm dùng nửa màn nhưng nội dung chỉ cần khoảng 300 điểm, phần dưới trống. | 5.7 |  | Open |
| F2-18 | Sheet trả tiền và sheet xoá nhóm | Direction | Hướng: tách hai sheet theo vai. Người trả thấy QR và số tài khoản. Người nhận thấy “Thu đã chuyển 210.000 đ cho bạn?” với một nút “Đã nhận” và một dòng “Thêm ảnh hoặc ghi chú” mở rộng khi cần. Gộp ba nhãn “(tuỳ chọn)” thành một tiêu đề nhỏ “Thêm chi tiết”, gập sẵn. | 5.7 |  | Open |
| F2-19 | Sheet trả tiền và sheet xoá nhóm | Table row | **Trả tiền / Đã nhận** · Toàn màn · **[Vừa nội dung]** rồi kéo lên được · Tách theo vai, bỏ mũi tên quay lại | 5.7 |  | Open |
| F2-20 | Sheet trả tiền và sheet xoá nhóm | Table row | **Link khách** · Toàn màn · **[Vừa nội dung]** · Bảng chia sẻ iOS thay cho nút Sao chép + Gửi | 5.7 |  | Open |
| F2-21 | Sheet trả tiền và sheet xoá nhóm | Table row | **Giải trình khoản nợ** · Toàn màn · **[Nửa + toàn]** · Nửa màn đủ thấy số dư và 3 khoản lớn nhất | 5.7 |  | Open |
| F2-22 | Sheet trả tiền và sheet xoá nhóm | Table row | **Xuất ảnh / Nhắc nợ** · Toàn màn · **[Toàn màn]** giữ · Đảo lại: ảnh xem trước ở trên, tuỳ chỉnh ở dưới | 5.7 |  | Open |
| F2-23 | Sheet trả tiền và sheet xoá nhóm | Table row | **Chốt đợt** · Toàn màn · **[Vừa nội dung]** · Một câu xác nhận và một nút | 5.7 |  | Open |
| F2-24 | Sheet trả tiền và sheet xoá nhóm | Table row | **Lập quỹ** · Nửa màn · **[Nửa màn]** giữ · Đã đúng | 5.7 |  | Open |
| F2-25 | Sheet trả tiền và sheet xoá nhóm | Table row | **Xoá nhóm** · Nửa màn · **[Vừa nội dung]** · Bớt khoảng trống ở dưới | 5.7 |  | Open |
| F2-26 | Sheet trả tiền và sheet xoá nhóm | Table row | **Thông tin nhận tiền** · Toàn màn, có mũi tên quay lại · **[Nửa + toàn]** · Nút đóng thay cho mũi tên | 5.7 |  | Open |
| F2-27 | Sheet trả tiền và sheet xoá nhóm | Table row | **Khoản chi định kỳ, Hộ gia đình** · Toàn màn · **[Toàn màn]** giữ · Form dài, hợp với toàn màn | 5.7 |  | Open |
| F2-28 | Sheet trả tiền và sheet xoá nhóm | Table row | **Quét hoá đơn** · Toàn màn rồi đẩy tiếp · **[Toàn màn]** · Làm tiếp trong cùng màn, không đóng rồi mở | 5.7 |  | Open |
| F2-29 | Một sheet, một việc | Rule | Sheet dành cho việc làm xong trong vài giây. Việc nhiều bước thì mở toàn màn hình. Không mở sheet chồng lên sheet. | 5.6 |  | Open |
| F2-30 | Cao bằng nội dung | Rule | Đo nội dung rồi đặt chiều cao theo đó. iOS 26 tự cho sheet thấp nổi lên và có nền kính mờ, chỉ cần không tô nền đè lên. | 5.6 |  | Open |
| F2-31 | Đóng bằng hai chữ | Rule | Sheet chỉ để xem: nút X góc trái. Sheet có thay đổi: “Huỷ” trái, việc chính ở dưới. Bỏ “Thôi”, “Đóng”, “Quay lại”, “Để sau”. Hiện có 6 chữ: Xong · Huỷ · Thôi · Đóng · Quay lại · Để sau | 5.6 |  | Open |
| F2-32 | Không có mũi tên quay lại | Rule | Mũi tên trái nghĩa là màn này được đẩy sang. Trong sheet nó làm người dùng tưởng vuốt sang phải sẽ quay lại. | 5.6 |  | Open |
| F2-33 | Thanh toán · Cần thanh toán · 2 × | Repetition | Thanh toán · Cần thanh toán · 2 ×: Chữ “Xem giải trình khoản nợ” ở thẻ số dư và lại ở dưới thẻ “Thu trả bạn”. Hiện: hai lối vào cùng một sheet, cách nhau một màn. Đổi: bấm vào số dư hoặc vào hàng để mở giải trình. Bỏ cả hai dòng chữ. | 5.7 |  | Open |
| F2-34 | Thành viên · 3 × 2 | Repetition | Thành viên · 3 × 2: “Chưa ai nhận hình này” và nút “Đây là tôi” lặp dưới Lan, Hùng, Thu. Hiện: mỗi người chưa nhận hình chiếm hai khối. Đổi: gom thành một mục “3 người chưa nhận hình”. Hình chưa nhận vẽ viền nét đứt. Bấm vào người để nhận. | 5.8 |  | Open |
| F2-35 | Giao dịch của bạn · 4 × | Repetition | Giao dịch của bạn · 4 ×: “Đà Lạt 3N2Đ • 10/11/2026” in lại ở mỗi hàng. Hiện: 4 hàng, cùng nhóm, cùng ngày. Đổi: tiêu đề mục theo ngày, tên nhóm chỉ hiện khi khác hàng trên. | 5.7 |  | Open |
| F2-36 | Lịch sử · 3 + 5 × | Repetition | Lịch sử · 3 + 5 ×: Ba tiêu đề chồng nhau (“Lịch sử”, “Đà Lạt 3N2Đ”, “Ai đã đổi gì”). “Minh” và “21:23” lặp ở cả 5 hàng. Đổi: một tiêu đề. Gom các thay đổi liên tiếp của một người trong một phút thành một mục: “Minh thêm 4 khoản · 21:23”, bấm để mở. | 5.7 |  | Open |
| F2-37 | Sổ thanh toán · 2 × | Repetition | Sổ thanh toán · 2 ×: “Chờ xác nhận 0” ở thẻ tổng và lại là chip lọc ngay dưới. Các số 0 vẫn hiện. Đổi: ẩn số đếm bằng 0. Chip lọc chỉ hiện khi có trên 5 dòng. | 5.7 |  | Open |
| F2-38 | Chi tiết khoản chi · 2 bộ số | Repetition | Chi tiết khoản chi · 2 bộ số: Chip “Riêng: Minh 80 · Lan 60 · Hùng 40” và ngay dưới là Minh 120.000, Lan 100.000, Hùng 80.000. Hai bộ số cho cùng ba người. Tên “Lẩu” ở header và ở thẻ. Đổi: chỉ hiện phần mỗi người chịu. Cách tính (riêng + chia đều) nằm trong một dòng gập “Cách chia”. | 5.7 |  | Open |
| F2-39 | Nhập nhanh · 2 × | Repetition | Nhập nhanh · 2 ×: Câu vừa gõ hiện hai lần trong cùng ô: một bản tô màu, một bản chữ thường. Đổi: chỉ một bản. Tô màu ngay trên chữ đang gõ. | 5.7 |  | Open |
| F2-40 | Menu ba chấm của nhóm · 3 → 1 | Repetition | Menu ba chấm của nhóm · 3 → 1: “Phân loại”, “Telegram” và “Cài đặt” mở cùng một trang cài đặt. Đổi: một mục “Thông tin nhóm”, như đề xuất cấu trúc ở phần 1. | 5.7 |  | Open |
| F2-41 | Đợt đã chốt · 2 bảng | Repetition | Đợt đã chốt · 2 bảng: Thẻ đợt in cả danh sách chuyển tiền (Thu → Minh…) và số dư từng người. Hai bảng nói cùng một chuyện. Số “3” không có nhãn. Đổi: thẻ đợt gồm tên, ngày, tổng, và “3 khoản chi · đã xong”. Chi tiết mở khi bấm. | 5.8 |  | Open |
| F2-42 | Gom theo thứ chung | Rule | Thứ gì giống nhau ở mọi hàng thì đưa lên làm tiêu đề mục: ngày, nhóm, người. Đà Lạt 3N2Đ • 10/11 · Vé 10/11 · Đà Lạt 3N2Đ → Vé, Hoàn cọc, Khách sạn | 5.6 |  | Open |
| F2-43 | Trạng thái là hình, không phải câu | Rule | Trạng thái lặp lại thì vẽ bằng hình (viền đứt, mờ, dấu chấm). Câu chữ chỉ giải thích một lần ở đầu mục. | 5.6 |  | Open |
| F2-44 | Không có số 0, không có ô trống | Rule | Số đếm bằng 0, bộ lọc khi mới có 2 dòng, tab khi chưa có dữ liệu: ẩn đi. Hiện lại khi có thứ để xem. | 5.6 |  | Open |
| F2-45 | Một câu trả lời cho một câu hỏi | Rule | Mỗi màn trả lời một câu hỏi bằng một con số. Muốn biết cách tính thì bấm mở. Không in kết quả và cách tính cạnh nhau. | 5.6 |  | Open |
| F2-46 | Nút gọn có chữ, đặt ở cuối hàng | Rule | Vẫn đọc được “Đã nhận”, chỉ to bằng một viên thuốc. Hàng thấp bằng một nửa. Nút vàng chỉ dành cho hàng bạn phải trả, nên mắt biết ngay việc nào là của mình. Nút nhỏ hơn, cần giữ vùng bấm tối thiểu 44 điểm. | 5.7 |  | Open |
| F2-47 | Nút gọn có chữ, đặt ở cuối hàng | Direction | Đề xuất: dùng kiểu này khi có từ 2 hàng. Bấm xong không mở sheet, chỉ đánh dấu ngay và hiện “Hoàn tác” vài giây, vì đây là việc làm nhiều lần liên tiếp. Thêm vuốt hàng sang trái làm đường tắt cho người quen tay, không thay cho nút. Bấm vào phần còn lại của hàng thì mở chi tiết. | 5.7 |  | Open |
| F2-48 | Ba hàng không cùng một nút | Rule | Hàng người khác trả bạn: “Đã nhận”. Hàng bạn trả người khác: “Trả” mở QR, tô vàng vì đó là việc của bạn. Hàng giữa hai người khác: không có nút, chỉ có “Nhắc” trong menu của hàng. Đặt cùng một nút cho cả ba là một nguồn lặp nữa. | 5.7 |  | Open |
| F2-49 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Lưu khoản chi** · **[Có]** · Thẻ mới trượt vào đầu danh sách, số dư đếm tới số mới, rung nhẹ · Cho biết đã lưu và lưu vào đâu | 5.7 |  | Open |
| F2-50 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Đánh dấu đã nhận / đã trả** · **[Có]** · Hàng mờ rồi thu lại, số còn lại đếm xuống, rung thành công · Tiền vừa đổi chủ | 5.7 |  | Open |
| F2-51 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Hết nợ cả nhóm** · **[Có]** · Hình thành viên bung ra một lần, có âm thanh nếu bật · Khoảnh khắc hiếm, đáng ăn mừng | 5.7 |  | Open |
| F2-52 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Chia tiền: đổi cách chia, kéo phần** · **[Có]** · Số của từng người đếm theo, thanh “khớp” đổi màu khi đủ · Người dùng đang điều khiển con số | 5.7 |  | Open |
| F2-53 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Thẻ → chi tiết** · **[Có]** · Phóng to từ thẻ (hệ thống) · Nối thẻ với trang | 5.7 |  | Open |
| F2-54 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Nút sao chép** · **[Có]** · Biểu tượng đổi thành dấu tích 1 giây (`symbolEffect`) · Không có toast, vẫn biết đã chép | 5.6 |  | Open |
| F2-55 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Lỗi khi lưu** · **[Có]** · Ô sai lắc nhẹ, rung cảnh báo · Chỉ ra chỗ sai | 5.6 |  | Open |
| F2-56 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Đổi segment / tab con** · **[Nhỏ]** · Viên chọn trượt, nội dung đổi ngay · Không làm mờ cả màn | 5.6 |  | Open |
| F2-57 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Mở màn, tải xong dữ liệu** · **[Không]** · Hiện thẳng, không cho từng thẻ trôi vào · Lặp lại mỗi lần mở, nhanh chóng thành chậm | 5.6 |  | Open |
| F2-58 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Cuộn danh sách** · **[Không]** · Không hiệu ứng theo cuộn, không parallax · Tốn nhiều nhất, có ích ít nhất | 5.6 |  | Open |
| F2-59 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Kéo để làm mới** · **[Không]** · Số giữ nguyên nếu không đổi, chỉ đếm khi khác · Không đếm lại số cũ | 5.6 |  | Open |
| F2-60 | Chỗ nào chuyển động, chỗ nào đứng yên | Table row | **Số trên mỗi hàng** · **[Không]** · Chỉ số chính của màn được đếm · Mười số cùng đếm là ồn | 5.6 |  | Open |
| F2-61 | Chỉ đổi vị trí và độ mờ | Rule | Animation bằng dịch chuyển, phóng, độ mờ là nhẹ. Animation thay đổi bố cục của danh sách dài (chiều cao, thêm bớt nhiều hàng) là nặng. Muốn thu một hàng thì làm mờ trước rồi mới rút. | 5.6 |  | Open |
| F2-62 | Ngắn và có lò xo | Rule | Phản hồi nút 100–150 ms, đổi trạng thái 200–300 ms, ăn mừng tối đa khoảng 1 giây. Dùng lò xo mặc định của SwiftUI thay cho đường cong tự chọn. | 5.6 |  | Open |
| F2-63 | Tôn trọng Giảm chuyển động | Rule | Khi người dùng bật Giảm chuyển động: bỏ bung hình và phóng to, giữ đổi màu và rung. | 5.6 |  | Open |
| F2-64 | Đo trước khi đoán | Rule | Mỗi chuyển động mới được kiểm bằng SwiftUI Instrument trên máy thật, ở danh sách nhóm lớn (cờ `--scenario-large`). `drawingGroup` chỉ dùng khi đo thấy có lợi. | 5.6 |  | Open |
| F2-65 | Thanh toán · Cần thanh toán | Keep | Câu “3 lượt chuyển là xong”: rõ, có tinh thần. | 5.7 |  | Open |
| F2-66 | Thanh toán · Cần thanh toán | Remove | “Lập quỹ chung” ở trên cùng, hàng nút bị cắt (“Chốt” lòi một nửa), dòng giải trình thứ hai. | 5.7 |  | Open |
| F2-67 | Thanh toán · Cần thanh toán | Change | Nút “Ghi nhận” thành nút gọn “Đã nhận” cuối hàng (mục D). Xuất ảnh, link khách, chốt đợt vào menu. | 5.7 |  | Open |
| F2-68 | Sổ thanh toán | Keep | Có nơi xem lại các lần chuyển. | 5.7 |  | Open |
| F2-69 | Sổ thanh toán | Remove | Số 0, chip lọc khi chưa có dòng nào. | 5.7 |  | Open |
| F2-70 | Sổ thanh toán | Change | Trạng thái trống có câu hướng dẫn: “Khi ai đó bấm Đã nhận, lần chuyển sẽ hiện ở đây.” Có thể gộp vào Lịch sử. | 5.7 |  | Open |
| F2-71 | Đợt đã chốt | Keep | Ý tưởng chốt sổ theo đợt. | 5.8 |  | Open |
| F2-72 | Đợt đã chốt | Remove | “26/11/2026 – 0” (ngày kết thúc hiện thành số 0), số “3” không nhãn, một trong hai bảng số. | 5.8 | B04 | Open |
| F2-73 | Đợt đã chốt | Change | “Mở lại đợt này” vào menu và hỏi lại, không đứng ngang hàng với “Xem các khoản chi”. | 5.8 |  | Open |
| F2-74 | Giải trình khoản nợ | Keep | Đi từ số dư về từng khoản: đây là điểm mạnh về minh bạch. | 5.7 |  | Open |
| F2-75 | Giải trình khoản nợ | Remove | Chữ “giải trình”, kiểu “20.000 đ / 99.999 đ” không giải thích. | 5.7 |  | Open |
| F2-76 | Giải trình khoản nợ | Change | Tên “Vì sao Thu nợ 210.000 đ”. Mỗi khoản viết thành câu: “Vé 99.999 đ · Hùng trả · phần Thu 20.000 đ”. Thống nhất có hay không có chữ “đ”. | 5.7 |  | Open |
| F2-77 | Xuất ảnh / Nhắc nợ | Keep | Ba câu nhắn mẫu, giọng nhẹ nhàng. | 5.8 |  | Open |
| F2-78 | Xuất ảnh / Nhắc nợ | Remove | Hai thanh chọn chồng nhau trông giống hệt nhau. Nhãn “Lời nhắn trên thẻ” lặp cả ở placeholder. | 5.8 |  | Open |
| F2-79 | Xuất ảnh / Nhắc nợ | Change | Ảnh xem trước lên đầu, chiếm nửa màn. Tuỳ chỉnh thành hàng chip dưới ảnh. Nút “Gửi” cố định ở đáy. | 5.8 |  | Open |
| F2-80 | Ghi nhận đã nhận | Keep | Số tiền to, sửa được. Câu “Sau khoản này Thu không còn nợ ai” rất hay. | 5.7 |  | Open |
| F2-81 | Ghi nhận đã nhận | Remove | Tiêu đề “Ghi nhận đã nhận” (hai chữ nhận). Phần tuỳ chọn bị nút đáy che. | 5.7 |  | Open |
| F2-82 | Ghi nhận đã nhận | Change | Tiêu đề “Thu trả bạn”. Kênh, ảnh, ghi chú gập vào “Thêm chi tiết”. Nên là sheet, không phải màn đẩy sang. | 5.7 |  | Open |
| F2-83 | Link khách (đã bật) | Keep | Không cần tài khoản vẫn xem được: giá trị lớn. | 5.8 |  | Open |
| F2-84 | Link khách (đã bật) | Remove | Đường link thô, 4 nút cùng cỡ. | 5.8 |  | Open |
| F2-85 | Link khách (đã bật) | Change | Thẻ xem trước + “Gửi link” + menu. Xem mục B. | 5.8 |  | Open |
| F2-86 | Quỹ chung (chưa có) | Keep | Câu ngắn. | 5.8 |  | Open |
| F2-87 | Quỹ chung (chưa có) | Remove | Nút “Quay lại”: ở trong một tab thì không có chỗ để quay lại. | 5.8 | B03 | Open |
| F2-88 | Quỹ chung (chưa có) | Change | Giải thích quỹ trong một câu và nút “Lập quỹ” ngay tại đây. Gỡ “Lập quỹ chung” khỏi đầu tab Thanh toán. | 5.8 |  | Open |
| F2-89 | Thống kê | Keep | Thanh theo danh mục dễ đọc. | 5.8 |  | Open |
| F2-90 | Thống kê | Remove | Ba tầng chọn (segment, tab con, khoảng thời gian). | 5.8 |  | Open |
| F2-91 | Thống kê | Change | Số vàng cần nhãn: “Cả nhóm đã chi”. Theo người: hai thanh thành một thanh có vạch “phần mình”, bớt một dòng chữ dài. | 5.8 |  | Open |
| F2-92 | Chi tiêu | Keep | Thanh nhập ở đáy, hình thành viên chồng nhau. | 5.7 |  | Open |
| F2-93 | Chi tiêu | Remove | “Theo số tiền”, “Theo phần” trên thẻ: thuật ngữ cách chia không cần ở danh sách. Hai link chữ “Mời bạn vào nhóm”, “Tổng chuyển đi” lơ lửng. | 5.7 |  | Open |
| F2-94 | Chi tiêu | Change | Số thứ hai có nhãn: “phần bạn 120.000”. Hình người trả có chữ cái, đang là chấm xanh trơn. | 5.7 |  | Open |
| F2-95 | Sửa khoản chi | Keep | Chọn người bằng hình. | 5.7 |  | Open |
| F2-96 | Sửa khoản chi | Remove | Hàng VAT luôn hiện. Danh sách người lặp ở “Ai trả” và “Chia cho ai”. | 5.7 |  | Open |
| F2-97 | Sửa khoản chi | Change | Một hàng người, chạm để đổi vai (trả / chịu). Phụ phí thành chip “+ Thêm”. | 5.7 |  | Open |
| F2-98 | Chia tiền | Keep | Dải “Khớp 300.000 đ · không còn dư”: phản hồi tốt. | 5.7 |  | Open |
| F2-99 | Chia tiền | Remove | Gợi ý “Nhấn giữ để tăng phần chia” hiện cả ở chế độ Số tiền, nơi nó không đúng. Chữ “đồng” cạnh chữ “đ” ở header. | 5.7 |  | Open |
| F2-100 | Chia tiền | Change | Hàng hình phía trên và các ô phía dưới cho hai số khác nhau (120.000 và 80.000). Chỉ giữ một: ô nhập, kèm số cuối cùng nhỏ bên cạnh. | 5.7 |  | Open |
| F2-101 | Nhập nhanh | Keep | Thẻ “Mình hiểu là”: đây là điểm khác biệt của app. | 5.7 |  | Open |
| F2-102 | Nhập nhanh | Remove | Câu hiện hai lần trong ô. Chữ “Nhập tay” trôi giữa màn trông như tiêu đề. Nút “Xong” nổi lơ lửng. | 5.7 |  | Open |
| F2-103 | Nhập nhanh | Change | Khi trống: 2–3 câu mẫu bấm được. “Nhập tay” thành link nhỏ cạnh ô. | 5.7 |  | Open |
| F2-104 | Thành viên | Keep | Mở hàng ra để đổi quyền. | 5.8 |  | Open |
| F2-105 | Thành viên | Remove | Ba lần “Chưa ai nhận hình này” và “Đây là tôi”. | 5.8 |  | Open |
| F2-106 | Thành viên | Change | Quyền thành menu trên hàng. “Gỡ khỏi nhóm” màu đỏ, nằm trong menu. | 5.8 |  | Open |
| F2-107 | Cài đặt nhóm | Keep | Giải thích “Gộp nợ” bằng một câu. | 5.8 |  | Open |
| F2-108 | Cài đặt nhóm | Remove | Dòng “Chỉ chủ nhóm thấy trang này”, nút “Lưu tên” riêng. | 5.8 |  | Open |
| F2-109 | Cài đặt nhóm | Change | Tên lưu khi rời ô. “Tự nhắc nợ” từ lưới 4 nút thành một menu chọn. | 5.8 |  | Open |
| F2-110 | Lịch sử | Keep | Câu kiểu “Minh thêm Vé · 99.999 đ”. | 5.7 |  | Open |
| F2-111 | Lịch sử | Remove | Hai tiêu đề thừa. Chấm xanh không có chữ cái. | 5.7 |  | Open |
| F2-112 | Lịch sử | Change | Gom theo người và phút (mục C). | 5.7 |  | Open |
| F2-113 | Giao dịch của bạn | Keep | Tìm kiếm, lọc theo nhóm. | 5.7 |  | Open |
| F2-114 | Giao dịch của bạn | Remove | Tên nhóm và ngày ở mỗi hàng. | 5.7 |  | Open |
| F2-115 | Giao dịch của bạn | Change | Số lớn có nhãn “bạn được nhận” hoặc “bạn chịu”. Số nhỏ là tổng khoản. | 5.7 |  | Open |
| F2-116 | Vào nhóm | Keep | Gần như tốt nhất app: một câu hỏi, chọn hình, một nút. | 5.8 |  | Open |
| F2-117 | Vào nhóm | Remove | Nút “Vào nhóm với tên” bị cụt khi chưa chọn. | 5.8 |  | Open |
| F2-118 | Vào nhóm | Change | Khi chọn hình: hình phóng lên, nút đổi thành “Vào nhóm là Lan”. Đây là chỗ đáng có một chuyển động. | 5.8 |  | Open |
| F2-119 | 1. Luôn nói từ phía người xem | Rule | Danh sách ghi “Bạn trả”, trang chi tiết lại ghi “Minh trả”, sheet trả tiền ghi “Trả Minh”. Cùng một người, ba cách gọi. | 5.6 |  | Open |
| F2-120 | 2. Một kiểu viết tiền | Rule | Hiện có “300.000 đ”, “300.000” và “80.000 đồng”. Chọn: số chính có “đ”, số phụ trong cùng hàng thì không. | 5.6 |  | Open |
| F2-121 | 3. Số luôn có nhãn | Rule | Không con số nào đứng một mình. Nhãn có thể nhỏ, nhưng phải có. | 5.6 |  | Open |
| F2-122 | 4. Hình thành viên ở mọi nơi có tên người | Rule | Lịch sử, chip lọc và thẻ chi tiêu đang dùng chấm tròn trơn hoặc chữ. Hình là nhận diện của app, nên ở đâu có tên người thì ở đó có hình. | 5.6 |  | Open |
| F2-123 | 5. Trạng thái trống có việc tiếp theo | Rule | “Chưa ai góp vào quỹ” + “Quay lại” là ngõ cụt. Trạng thái trống nào cũng chỉ ra việc đầu tiên nên làm. | 5.6 |  | Open |
| F2-124 | 6. Việc nguy hiểm không đứng cạnh việc thường | Rule | “Mở lại đợt”, “Thu hồi link”, “Gỡ khỏi nhóm” đang cùng cỡ, cùng màu với nút thường. Đưa vào menu, tô đỏ, hỏi lại. | 5.6 |  | Open |
| F2-125 | 7. Không để chữ bị cắt | Rule | Hàng nút cuộn ngang đang cắt “Chốt”, chip “Có ch…”, danh mục “C”. Nếu phải cuộn thì để lộ rõ nửa nút cuối, hoặc gom bớt. | 5.6 |  | Open |
| F2-126 | 8. Lề và vùng bấm thẳng hàng | Rule | Header chi tiết đang tràn mép. Dùng thanh điều hướng của hệ thống thì phần này tự đúng. | 5.6 |  | Open |
| F2-127 | 9. Rung có nghĩa | Rule | Rung nhẹ khi chọn, rung thành công khi tiền đổi chủ, rung cảnh báo khi lỗi. Không rung khi chỉ đổi tab. | 5.6 |  | Open |
| F2-128 | 10. Chữ cái đầu chỉ là chỗ tạm | Rule | Ô tên nhóm mới không có gợi ý. Dùng gợi ý cụ thể như “Đà Lạt cuối tuần”, đúng giọng app. | 5.6 |  | Open |

### [03-direction.md](03-direction.md)

| ID | Section | Type | Finding | Phase | Defect | Status |
|---|---|---|---|---|---|---|
| F3-01 | Vì sao chọn sheet lớn | Point | Apple xếp tạo mới là một việc có phạm vi rõ, gắn với ngữ cảnh hiện tại. Đó đúng là chỗ dành cho sheet. Apple cũng khuyên hỏi lại trước khi đóng một form đã nhập, để không mất dữ liệu. | 5.7 |  | Open |
| F3-02 | Vì sao chọn sheet lớn | Point | Các app gốc của iOS đều mở form tạo mới theo cách này: sự kiện mới trong Lịch, liên hệ mới trong Danh bạ, lời nhắc mới. | 5.7 |  | Open |
| F3-03 | Vì sao chọn sheet lớn | Point | Toàn màn hình chỉ dùng cho camera quét hoá đơn, vì đó là việc cần cả màn hình. | 5.7 |  | Open |
| F3-04 | Áp dụng cụ thể | Point | Mở sheet là bàn phím số bật ngay ở ô số tiền. | 5.7 |  | Open |
| F3-05 | Áp dụng cụ thể | Point | “Huỷ” ở góc trái, “Lưu” to ở đáy, luôn nhìn thấy trên bàn phím. | 5.7 |  | Open |
| F3-06 | Áp dụng cụ thể | Point | Sửa khoản chi dùng đúng sheet này, tiêu đề “Sửa khoản chi”. | 5.7 |  | Open |
| F3-07 | Áp dụng cụ thể | Point | Nhập nhanh vẫn nằm ở thanh đáy của nhóm. Thẻ “Mình hiểu là” hiện thành sheet nửa màn, có “Lưu” và “Sửa chi tiết”. Bấm sửa thì sheet kéo lên thành form đầy đủ, không đóng rồi mở lại. | 5.7 |  | Open |
| F3-08 | Áp dụng cụ thể | Point | Trang chi tiết khoản chi vẫn đẩy sang, vì đó là đọc chứ không phải làm. | 5.7 |  | Open |
| F3-09 | Vì sao phải đợi 5 giây mới gửi | Rule | Server gửi thông báo ngay khi có thanh toán mới. Nếu gửi ngay rồi hoàn tác bằng cách xoá, Thu vẫn nhận được thông báo “Minh đã ghi nhận 210.000 đ” cho một việc không còn tồn tại. Gmail làm nút “Hoàn tác gửi” theo cùng cách: giữ thư lại vài giây rồi mới gửi. 0 GIÂY · **Bấm Đã nhận** Hàng mờ đi, số còn lại đếm xuống, rung nhẹ. Thanh “Hoàn tác” hiện ở đáy. 0–5 GIÂY · **Còn đổi ý được** Chưa gửi gì lên server. Bấm Hoàn tác thì hàng trở lại như cũ. 5 GIÂY, HOẶC RỜI MÀN · **Gửi lên server** Dùng khoá chống gửi trùng sẵn có (`idempotencyKey`). Rời màn hoặc đưa app xuống nền thì gửi luôn, không chờ. SAU ĐÓ · **Muốn sửa nữa** Vào Lịch sử, mở khoản thanh toán, xoá như một khoản bình thường. | 5.7 |  | Open |
| F3-10 | Khi nào vẫn mở sheet | Point | **Nhận thiếu:** chạm vào hàng (không phải nút) để mở sheet sửa số tiền, thêm ảnh, ghi chú. | 5.7 |  | Open |
| F3-11 | Khi nào vẫn mở sheet | Point | **Ghi hộ hai người khác** (chủ nhóm ghi Thu đã trả Lan): đây là tiền của người khác, nên luôn mở sheet xác nhận. | 5.7 |  | Open |
| F3-12 | Khi nào vẫn mở sheet | Point | **Mất mạng:** vẫn bấm được, hàng có dấu “chờ gửi”, gửi khi có mạng. | 5.7 |  | Open: limit to the “Đã nhận” undo queue; general offline writes are a v3 non-goal |
| F3-13 | Khi nào vẫn mở sheet | Rule | NN/g khuyên chỉ dùng hộp xác nhận cho việc không đảo ngược được hoặc tốn kém. Đánh dấu đã nhận thì đảo ngược được, nên hoàn tác hợp hơn hỏi lại. | 5.7 |  | Open |
| F3-14 | Có hai lúc người ta mở app | Rule | Lúc quyết toán, câu hỏi là “trả ai bao nhiêu”, đúng như bạn nói. Nhưng lúc có thông báo khoản chi mới, câu hỏi là “khoản này mình chịu bao nhiêu”. Vì vậy trang chi tiết khoản chi phải mở đầu bằng **phần của bạn**, không phải tổng hoá đơn. Thêm 2 · vai | 5.7 |  | Open |
| F3-15 | Người ứng tiền hỏi câu khác | Rule | Người trả hộ (thường là chủ nhóm) hỏi “ai còn nợ mình, ai trả rồi” và cần nhắc. Cùng một màn, chỉ đổi câu đầu: “Bạn cần trả” hay “Bạn sẽ nhận”. Không cần màn riêng cho chủ nhóm. Khác biệt nằm ở quyền sửa và ở trang Thông tin nhóm. Thêm 3 · gộp nợ | 5.7 |  | Open |
| F3-16 | Gộp nợ làm đứt mạch “vì sao” | Rule | Khi bật Gộp nợ, Thu có thể phải trả Minh dù cả chuyến chỉ ăn với Hùng. Splitwise ghi nhận người dùng bối rối đúng chỗ này và nói họ đã thử làm rõ nhưng chưa thành công. Vì vậy phần “vì sao” phải giải thích theo **số dư của bạn** trước, rồi mới nói vì sao trả cho người này. | 5.7 |  | Open |
| F3-17 | Ghi chú cho mô hình | Point | Tầng 1 đến tầng 3 luôn là **con số → bấm → lý do → bấm → bằng chứng**. Không quá hai lần bấm từ con số khó hiểu tới hoá đơn gốc. | 5.7 |  | Open |
| F3-18 | Ghi chú cho mô hình | Point | Chủ nhóm và thành viên thấy cùng ba tầng. Chỉ khác chữ đầu (“cần trả” hay “sẽ nhận”) và nút “Sửa”. | 5.7 |  | Open |
| F3-19 | Ghi chú cho mô hình | Point | Ở tầng 3 chỉ còn một bộ số: phần của từng người. Cách tính (riêng + chia đều) là một dòng nhỏ, không phải một bộ số thứ hai. | 5.7 |  | Open |
| F3-20 | Ghi chú cho mô hình | Point | “Khoản này chưa đúng” hiện có ô “Lý do” tự gõ, sheet trống một nửa. Đổi thành 4 lý do bấm được. Lý do giúp người tạo khoản sửa đúng chỗ mà không phải hỏi lại. | 5.7 |  | Open |
| F3-21 | Lần đầu mở app | Issue · Cao | Người dùng mới chưa có nhóm nào thấy thẻ vàng “Bạn đã sòng phẳng ở tất cả nhóm”. Đây là màn đầu tiên họ thấy, và câu này sai: họ chưa có nhóm nào. Bên dưới là “Chưa có giao dịch nào” và nút “Xem tất cả giao dịch” dẫn tới một danh sách trống. | 5.7 | B05 | Open |
| F3-22 | Lần đầu mở app | Issue · Lặp | Khi có nhóm, thẻ vàng ghi “Chênh lệch ròng +500.001”, rồi “Tổng được nhận 500.001 đ” và “Tổng cần trả 0 đ”. Một con số in hai lần, kèm một số 0. Tiêu đề có ba tầng: “Chào Minh”, “Tổng quan tài chính”, chuông và ảnh đại diện. | 5.7 |  | Open |
| F3-23 | Lần đầu mở app | Direction | Hướng: người mới thấy một việc: “Tạo nhóm đầu tiên” hoặc “Có link mời? Dán vào đây”, kèm các hình thành viên làm minh hoạ. Khi có nhóm: một câu “Bạn sẽ nhận 500.001 đ”. Chỉ hiện tách hai chiều khi cả hai đều khác 0. | 5.7 |  | Open |
| F3-24 | Vai chỉ xem | Issue · Lặp | Người chỉ xem thấy một nút vàng to “Xem” ở mỗi hàng, cộng “Xem giải trình khoản nợ” ở dưới, cộng nút cùng tên ở thẻ số dư. Ba lối vào một việc. Màu vàng là màu của việc chính, nên người xem tưởng phải bấm. | 5.7 | B08 | Open |
| F3-25 | Vai chỉ xem | Issue · Kiểu | Thanh nhập ở đáy biến thành một nút xám “Chỉ xem” bị tắt, chiếm chỗ như một nút thật. | 5.7 | B08 | Open |
| F3-26 | Vai chỉ xem | Direction | Hướng: người chỉ xem không có nút trên hàng. Bấm vào hàng để xem. Thanh đáy ẩn đi, thay bằng một dòng nhỏ ở đầu nhóm: “Bạn đang xem nhóm này”. Đây cũng là bằng chứng thêm cho mục D của phần 2: nút trên hàng phải tuỳ vai. | 5.7 |  | Open |
| F3-27 | Cỡ chữ lớn (Trợ năng) | Issue · Không đều | Một nửa app phóng chữ, một nửa không. Tab Thanh toán phóng to đến mức nút “Xem giải trình khoản nợ” thành một khối tròn bốn dòng, segment bị cắt thành “Thanh t…”, “Quỹ &…”. Form sửa khoản chi gần như giữ nguyên cỡ chữ. | 5.6 | B07 | Open |
| F3-28 | Cỡ chữ lớn (Trợ năng) | Direction | Hướng: mọi chữ đi qua thang chữ của `Typography` có hỗ trợ cỡ chữ động. Ở cỡ chữ lớn, các hàng ngang tự xếp dọc. Đặt cỡ lớn nhất là một bước kiểm tra bắt buộc cho mỗi màn trong v3. | 5.6 |  | Open |
| F3-29 | Nhập nhanh và cuối trang thành viên | Defect | Nhập nhanh: nút “Chỉnh tay” và “Lưu” của thẻ “Mình hiểu là” bị chữ “Nhập tay” đè lên và cắt mất nửa dưới. Đây là hai nút quan trọng nhất của màn. | 5.7 | B06 | Open |
| F3-30 | Nhập nhanh và cuối trang thành viên | Issue · Dồn | Cuối trang thành viên có 8 khối khác loại: thêm tên, lập quỹ, hộ gia đình, tắt thông báo, mã mời, link khách, lịch sử, cài đặt. “Lập quỹ chung” có ở ba nơi trong app. “Lịch sử” và “Cài đặt” trùng với menu ba chấm. | 5.8 |  | Open |
| F3-31 | Nhập nhanh và cuối trang thành viên | Direction | Hướng: trang này trở thành “Thông tin nhóm” như phần 1 đề xuất, chia ba mục rõ: Người, Mời, Nhóm. Mỗi chức năng chỉ có một lối vào. | 5.7 |  | Open |
| F3-32 | Cả nhóm đã xong | Keep | “Cả nhóm đã xong. Không ai nợ ai.” Đây là chỗ cho chuyển động ăn mừng. | 5.7 |  | Open |
| F3-33 | Cả nhóm đã xong | Remove | “Bạn đã xong 0 đ” kèm “Xem giải trình khoản nợ” cho số 0. Bốn ô ai cũng “0 đ”. | 5.7 |  | Open |
| F3-34 | Cả nhóm đã xong | Change | Gợi ý việc tiếp theo: “Chốt đợt này” hoặc “Gửi ảnh tổng kết”. | 5.7 |  | Open |
| F3-35 | Khoản này chưa đúng | Keep | Câu hỏi “Khoản này chưa đúng ở đâu?” rất tự nhiên. | 5.7 |  | Open |
| F3-36 | Khoản này chưa đúng | Remove | Sheet nửa màn trống một nửa. “Thôi”. | 5.7 |  | Open |
| F3-37 | Khoản này chưa đúng | Change | 4 lý do bấm được, ô ghi chú tuỳ ý, sheet cao theo nội dung. | 5.7 |  | Open |
| F3-38 | Tạo hộ / cặp đôi | Keep | Ví dụ “Nhà Minh & Lan” trong ô tên. | 5.8 |  | Open |
| F3-39 | Tạo hộ / cặp đôi | Remove | “hộ / cặp đôi” lặp ở tiêu đề, nhãn, nút. Nửa dưới trống. | 5.8 |  | Open |
| F3-40 | Tạo hộ / cặp đôi | Change | Gọi chung là “Hộ”, giải thích một lần. Hình thành viên có chữ cái. Chọn đủ 2 người thì tự gợi ý tên. | 5.8 |  | Open |
| F3-41 | Khoản chi mới | Keep | Chi / Chuyển / Thu ở đầu form. | 5.7 |  | Open |
| F3-42 | Khoản chi mới | Remove | Ô “Chia cho ai” hiện “…” khi số tiền là 0. Bàn phím không tự bật. | 5.7 |  | Open |
| F3-43 | Khoản chi mới | Change | Theo mục A: sheet lớn, bàn phím bật sẵn, phần chia hiện khi đã có số tiền. | 5.7 |  | Open |
| F3-44 | Mất mạng | Keep | “Mất mạng. Bạn vẫn xem được sổ.” và “Có mạng lại là gõ tiếp được”: câu chữ tốt nhất app. | 5.7 |  | Open |
| F3-45 | Mất mạng | Remove | Nút “Thu về” vẫn sáng khi mất mạng. | 5.7 |  | Open |
| F3-46 | Mất mạng | Change | Cho phép ghi khi mất mạng theo hàng đợi ở mục B, thay vì chặn. | 5.7 |  | Open: limit to the “Đã nhận” undo queue; general offline writes are a v3 non-goal |
| F3-47 | Không tìm thấy nhóm | Keep | Có nút về danh sách nhóm. | 5.6 |  | Open |
| F3-48 | Không tìm thấy nhóm | Remove | Header vẫn vẽ một viên trắng rỗng (chỗ hình thành viên) và segment, dù không có nhóm. | 5.6 | B09 | Open |
| F3-49 | Không tìm thấy nhóm | Change | Trạng thái lỗi dùng một màn trống riêng, không có header nhóm. | 5.6 |  | Open |
| F3-50 | Đăng nhập | Keep | “Chia tiền, gõ như nhắn tin.” và cụm hình thành viên: nhận diện tốt. | 5.8 |  | Open |
| F3-51 | Đăng nhập | Remove | Form email hiện sẵn dưới Apple và Google, đẩy nút đăng nhập xuống đáy. | 5.8 |  | Open |
| F3-52 | Đăng nhập | Change | Apple, Google, rồi “Dùng email” mở form. Hình thành viên có thể chuyển động nhẹ một lần khi mở app. | 5.8 |  | Open |
| F3-53 | Tài khoản | Keep | Chọn giao diện sáng, tối, theo hệ thống. | 5.8 |  | Open |
| F3-54 | Tài khoản | Remove | Form đổi mật khẩu mở sẵn (đã nêu ở phần 1). | 5.8 |  | Open |
| F3-55 | Tài khoản | Change | Dạng danh sách cài đặt chuẩn iOS. Mỗi mục mở một trang con. | 5.8 |  | Open |
| F3-56 | Trang khách · link hỏng | Keep | Nói rõ link không tồn tại hoặc đã bị thu hồi. | 5.8 |  | Open |
| F3-57 | Trang khách · link hỏng | Remove | Hai nút “Quay lại” trên cùng một màn. | 5.8 |  | Open |
| F3-58 | Trang khách · link hỏng | Change | Một nút, và gợi ý “Xin người gửi một link mới”. | 5.8 |  | Open |
| F3-59 | Chế độ tối | Keep | Độ tương phản ổn, màu vàng vẫn rõ, hình thành viên vẫn tươi. | All |  | Open |
| F3-60 | Chế độ tối | Remove | Không thấy lỗi lớn ở 3 màn đã thử. | All |  | Open |
| F3-61 | Chế độ tối | Change | Cần thử thêm sheet và ảnh chia sẻ ở chế độ tối. | All |  | Open |

### [04-remaining-screens.md](04-remaining-screens.md)

| ID | Section | Type | Finding | Phase | Defect | Status |
|---|---|---|---|---|---|---|
| F4-01 | 1 · Một việc, hai bộ điều khiển | Rule | Chọn người trả ở form khoản chi là thẻ có hình. Ở form định kỳ lại là chip chữ. Ở hoá đơn có hai hàng người gần giống hệt nhau: một hàng để gán món, một hàng “Ai trả?”. | 5.6 |  | Open |
| F4-02 | 1 · Một việc, hai bộ điều khiển | Direction | Hướng sửa: một bộ chọn người dùng chung cho mọi form, có tiêu đề nói rõ đang chọn cho việc gì. | 5.6 |  | Open |
| F4-03 | 2 · Sheet lớn, nội dung nhỏ | Rule | Nhân bản nhóm, chụp hoá đơn, chốt đợt đều mở sheet cao cả màn. Nội dung chỉ chiếm 30 đến 50 phần trăm, phần còn lại trống. | 5.6 |  | Open |
| F4-04 | 2 · Sheet lớn, nội dung nhỏ | Direction | Hướng sửa: ba sheet này dùng chiều cao vừa nội dung. Sheet lớn chỉ dành cho form (câu 2 của phần 3). | 5.6 |  | Open |
| F4-05 | 3 · Xong việc rồi đi đâu | Rule | Nhân bản xong, nhóm mới chồng lên nhóm cũ, bấm quay lại thì về nhóm cũ. Chốt đợt xong, app lặng lẽ chuyển sang tab “Đợt đã chốt”. Menu “Danh mục của nhóm” mở đầu trang cài đặt, phải cuộn mới thấy danh mục. | 5.6 |  | Open |
| F4-06 | 3 · Xong việc rồi đi đâu | Direction | Hướng sửa: mỗi hành động kết thúc ở đúng chỗ người dùng cần xem, kèm một xác nhận ngắn nói việc gì vừa xảy ra. | 5.6 |  | Open |
| F4-07 | 4 · Màn nhỏ đẩy đáp án ra ngoài | Rule | Trên iPhone SE, tab Thanh toán chỉ còn lộ mép trên của hàng “Thu trả bạn”. Phía trên nó là nút “Lập quỹ chung”, hàng chip và thẻ số dư. | All |  | Open |
| F4-08 | 4 · Màn nhỏ đẩy đáp án ra ngoài | Direction | Hướng sửa: đáp án đứng đầu, các nút phụ gom vào một chỗ (đúng mô hình ba tầng ở phần 3). | All |  | Open |
| F4-09 | Nhân bản nhóm | Issue · Sheet | Sheet chỉ có 3 dòng nhưng cao cả màn. Sheet cũng không nói rõ gì được chép và gì không: thành viên có, khoản chi không. Người dùng phải đoán. | 5.8 |  | Open |
| F4-10 | Nhân bản nhóm | Defect | Ở nhóm mới, header bị đẩy lên dưới đồng hồ và kéo xuống không về được. Nút quay lại gần như không bấm được. | 5.6 | B10 | Open |
| F4-11 | Nhân bản nhóm | Defect | Nhóm chưa có khoản chi nào vẫn hiện thẻ vàng “Bạn đã xong 0 đ” kèm nút “Xem”. | 5.7 | B11 | Open |
| F4-12 | Nhân bản nhóm | Issue · Lặp | “Mời bạn vào nhóm” xuất hiện 2 lần. Tiêu đề “Gõ khoản chi đầu t…” bị cắt. | 5.7 | B12 | Open |
| F4-13 | Nhân bản nhóm | Direction | Hướng sửa: sheet vừa nội dung, thêm một dòng “Chép 4 thành viên và thông tin nhận tiền. Không chép khoản chi.” Tạo xong thì thay nhóm cũ bằng nhóm mới trên ngăn xếp thay vì chồng lên. Nhóm trống chỉ hiện một lời mời nhập khoản chi đầu tiên. | 5.8 |  | Open |
| F4-14 | Quét hoá đơn và gán món | Issue · Sheet | Sheet chụp hoá đơn chỉ có 2 nút mà cao cả màn. “Huỷ” là một nút to ngang hàng với nút chính. | 5.8 |  | Open |
| F4-15 | Quét hoá đơn và gán món | Defect | Số tiền món ăn không có dấu chấm (`280000`), trong khi mọi chỗ khác viết `300.000`. Ngày hiện dạng `2026-11-16`. | 5.8 | B13 | Open |
| F4-16 | Quét hoá đơn và gán món | Defect | Phụ phí có hai ô cùng chữ, ô thứ hai bị cắt thành “Phí dịc…”. | 5.8 | B14 | Open |
| F4-17 | Quét hoá đơn và gán món | Issue · Lặp | Hai hàng 4 người gần giống nhau: hàng gán món và hàng “Ai trả?”. Hàng thứ hai còn bị cắt mất “Thu” ở mép phải. | 5.8 |  | Open |
| F4-18 | Quét hoá đơn và gán món | Keep | Ý tưởng chọn món rồi chạm người là đúng, và dòng “Còn 1 món chưa có ai” giải thích vì sao chưa lưu được. | 5.8 |  | Open |
| F4-19 | Quét hoá đơn và gán món | Direction | Hướng sửa: nút camera mở thẳng camera toàn màn (đã chốt ở phần 3), thư viện ảnh là một nút nhỏ trong camera. Màn hoá đơn dùng chung ô tiền và ô ngày với form khoản chi. “Ai trả?” chuyển thành một dòng gọn ở đầu màn. | 5.8 |  | Open |
| F4-20 | Khoản chi định kỳ | Issue · Chỗ đặt | Định kỳ nằm dưới cùng tab thống kê, sau nút “Xuất CSV”. Khi đến kỳ, Tổng quan có nhắc, nhưng trong nhóm thì phải cuộn hết trang mới thấy. | 5.8 |  | Open |
| F4-21 | Khoản chi định kỳ | Defect | Chữ xuống dòng giữa cụm: “Nhắc nhập / số tiền”. Hai nút “Nhập số tiền kỳ này” và “Bỏ qua kỳ này” mỗi nút 2 dòng. | 5.8 | B16 | Open |
| F4-22 | Khoản chi định kỳ | Issue · Lặp | Nhãn vàng “Cần nhập số tiền kỳ 25/11/2026” ngay trên nút “Nhập số tiền kỳ này”. Tiêu đề viết “Giao dịch định kỳ”, nút lại viết “Tạo chi tiêu định kỳ”. | 5.8 |  | Open |
| F4-23 | Khoản chi định kỳ | Issue · Form | Form định kỳ dùng chip chữ, còn form khoản chi dùng thẻ có hình: hai cách khác nhau cho cùng một việc. “Hằng năm” bị cắt mà không có dấu hiệu cuộn ngang. Hàng người thứ hai không có tiêu đề. | 5.8 | B17 | Open |
| F4-24 | Khoản chi định kỳ | Keep | Form này đã là sheet lớn, có “Huỷ” và nút lưu ở cuối, đúng mẫu đã chọn cho câu 2. | 5.8 |  | Open |
| F4-25 | Khoản chi định kỳ | Direction | Hướng sửa: bỏ form riêng. Định kỳ thành một dòng “Lặp lại” trong form khoản chi chung. Khoản đến kỳ hiện như một hàng chờ ở đầu tab Chi tiêu: “Tiền nước tháng 11 · Nhập số tiền”. | 5.8 |  | Open |
| F4-26 | Chốt đợt | Issue · Sheet | Nửa dưới sheet trống. Cảnh báo dùng cùng màu vàng với thẻ số dư chính, nên màu vàng đang mang 3 nghĩa khác nhau. | 5.8 |  | Open |
| F4-27 | Chốt đợt | Issue · Chuyển | Chốt xong không có lời xác nhận nào. App tự chuyển sang tab “Đợt đã chốt”. | 5.8 |  | Open |
| F4-28 | Chốt đợt | Issue · Lặp | Số liệu lúc chốt hiện 2 lần: một lần dạng ai chuyển ai, một lần dạng số dư từng người. Có một số “3” không nhãn dưới tổng tiền. | 5.8 |  | Open |
| F4-29 | Chốt đợt | Defect | “26/11/2026 – 0” vẫn còn ở đợt hiện tại (đã ghi ở phần 2). | 5.8 |  | Open |
| F4-30 | Chốt đợt | Issue · Nguy hiểm | “Mở lại đợt này” có cùng độ nổi với “Xem các khoản chi đợt này”. | 5.8 |  | Open |
| F4-31 | Chốt đợt | Direction | Hướng sửa: sheet vừa nội dung. Chốt xong ở lại tab cũ, hiện một xác nhận kiểu “Đã chốt Đợt 1 · 3 khoản còn nợ chuyển sang đợt mới”. Ở đây đáng có một lần rung nhẹ và một hiệu ứng nhỏ, vì đây là một cột mốc thật. Số liệu lúc chốt chỉ hiện dạng ai chuyển ai. “Mở lại” chuyển vào menu. | 5.8 |  | Open |
| F4-32 | Chốt đợt | Rule | Ghi chú: tổng 1.599.999 đ ở đây khác số 1.399.999 đ trên tab thống kê. Tôi đã kiểm tra: số ở tab thống kê là số cứng trong dữ liệu mẫu, nên đây không phải lỗi. Có điều số to nhất tab thống kê không có nhãn, và người đọc sẽ đem nó so với tổng các danh mục ngay bên dưới. | 5.6 |  | Open: fix the fake data in 5.6; label the stats total in 5.8 |
| F4-33 | Danh mục và cài đặt nhóm | Issue · Lặp | Mỗi hàng danh mục có chữ “Ẩn danh mục”, cùng một vấn đề với nút “Nhận” trên từng hàng mà bạn nêu. Danh mục mặc định (Ăn uống, Đi lại…) không có trong danh sách, nên không biết ẩn chúng ở đâu. | 5.8 |  | Open |
| F4-34 | Danh mục và cài đặt nhóm | Issue · Lặp | Card “Nhân bản nhóm” có tiêu đề và nút cùng chữ. Mỗi card có nút lưu riêng (“Lưu tên”, “Lưu hạn mức”). | 5.8 |  | Open |
| F4-35 | Danh mục và cài đặt nhóm | Issue · Chỗ đặt | Nhân bản và lưu trữ có cả ở menu ba chấm lẫn trong cài đặt. | 5.8 |  | Open |
| F4-36 | Danh mục và cài đặt nhóm | Defect | Menu ba chấm hiện “Danh mục của nhóm” cho mọi người, nhưng mục này mở trang cài đặt chỉ chủ nhóm được vào. Biên tập viên bấm vào sẽ gặp màn “Bạn không có quyền làm việc này”, không có header, không có nút quay lại (ảnh ở mục C). | 5.6 | B18 | Open |
| F4-37 | Danh mục và cài đặt nhóm | Direction | Hướng sửa: cài đặt nhóm thành danh sách iOS kiểu Settings, mỗi dòng đẩy sang một màn con nhỏ: Tên, Danh mục, Hạn mức, Quyền, Nguy hiểm. Ẩn danh mục bằng vuốt hàng hoặc nút sửa, không cần chữ trên từng hàng. Menu ba chấm chỉ còn những gì không có ở chỗ khác. | 5.8 |  | Open |
| F4-38 | Tài khoản | Issue · Lặp | “Đăng xuất” 3 lần trên một màn: hai lần cho từng thiết bị, một lần cho cả tài khoản. | 5.8 |  | Open |
| F4-39 | Tài khoản | Issue · Ngợp | Form đổi mật khẩu và form xoá tài khoản luôn mở sẵn, chiếm hơn nửa trang cho hai việc gần như không ai làm hằng ngày. | 5.8 |  | Open |
| F4-40 | Tài khoản | Defect | Chữ của trang trôi lên dưới đồng hồ và biểu tượng sóng. Các màn khác có lớp che, riêng tab này không có. | 5.6 | B19 | Open |
| F4-41 | Tài khoản | Direction | Hướng sửa: tab Tài khoản dùng `List` kiểu Settings của iOS. Đổi mật khẩu, thiết bị và xoá tài khoản mỗi mục là một dòng đẩy sang màn con. Một nút “Đăng xuất” duy nhất ở cuối. | 5.8 |  | Open |
| F4-42 | Mạng chậm 2 giây, không có dữ liệu lưu sẵn | Keep | Đã có khối xám giữ chỗ. Khi có dữ liệu lưu trên máy, Tổng quan hiện ngay, không cần chờ. | 5.6 |  | Open |
| F4-43 | Mạng chậm 2 giây, không có dữ liệu lưu sẵn | Defect | Tên nhóm trống trong lúc tải dù app đã biết tên từ danh sách nhóm. Viên hình thành viên là một vạch rỗng. | 5.6 | B20 | Open |
| F4-44 | Mạng chậm 2 giây, không có dữ liệu lưu sẵn | Issue · Nhảy | Khối xám là 3 thẻ giống nhau, không giống bố cục thật (thẻ số dư, hàng liên kết, ô tìm, các hàng). Ô nhập khoản chi chỉ hiện sau khi tải xong, nên cả màn nhảy một lần. | 5.6 | B20 | Open |
| F4-45 | Mạng chậm 2 giây, không có dữ liệu lưu sẵn | Direction | Hướng sửa: truyền tên và màu thành viên khi mở nhóm để header hiện ngay. Khối xám có hình giống bố cục thật. Ô nhập luôn có mặt ngay từ đầu. | 5.6 |  | Open |
| F4-46 | iPhone SE (màn 4,7 inch) | Issue · Ưu tiên | Tab Thanh toán: hàng cần bấm (“Thu trả bạn 210.000”) chỉ lộ mép trên. Đây là bằng chứng rõ nhất cho việc đưa đáp án lên đầu. | 5.7 |  | Open |
| F4-47 | iPhone SE (màn 4,7 inch) | Issue · Chật | Tab Chi tiêu chỉ thấy 1 khoản chi trước khi phải cuộn. Tổng quan không thấy số dư theo nhóm vì thanh tab nổi che mất. | 5.7 |  | Open |
| F4-48 | iPhone SE (màn 4,7 inch) | Issue · Chật | Ghi nhận đã nhận: ghi chú màu xanh bị nút chính che. “Xem giải trình khoản nợ” và “Chưa ai nhận hình này” xuống 2 dòng. | 5.7 | B21 | Open |
| F4-49 | iPhone SE (màn 4,7 inch) | Keep | Form khoản chi giữ nút “Lưu” ở đáy và vẫn dùng được. | 5.7 |  | Open |
| F4-50 | Vai biên tập viên | Keep | Biên tập viên thấy Chi tiêu và Thanh toán giống hệt chủ nhóm, đúng với ý bạn ở câu 5: hai bên cùng một góc nhìn. | 5.7 |  | Open |
| F4-51 | Vai biên tập viên | Defect | Màn không có quyền không có header và nút quay lại, chỉ có “Về danh sách nhóm”. Lối vào màn này là menu “Danh mục của nhóm”. | 5.6 | B18 | Open |
| F4-52 | Vai biên tập viên | Issue · Hỏi | Biên tập viên vẫn thấy chip “Chốt đợt”. Tôi chưa kiểm tra server có cho phép biên tập viên chốt đợt không. Nếu không, chip này dẫn tới một lỗi nữa. | 5.7 |  | Open: spec section 8 question |
| F4-53 | Giảm chuyển động, VoiceOver, rung và âm thanh (đọc code) | Point | **Giảm chuyển động:** chỉ 4 file đọc cài đặt này (nhập nhanh, ghi nhận, chia tiền, hình thành viên), trong khi có 17 chỗ gọi animation. Ví dụ, chuyển segment trong nhóm vẫn chạy hiệu ứng mờ dần khi người dùng đã bật giảm chuyển động. **Hướng:** một bộ thông số chuyển động dùng chung, tự tắt hiệu ứng di chuyển khi bật cài đặt này. Đây cũng là chỗ để thêm hiệu ứng mới mà không phải kiểm tra từng màn. | 5.6 |  | Open |
| F4-54 | Giảm chuyển động, VoiceOver, rung và âm thanh (đọc code) | Point | **VoiceOver:** có 80 nhãn đọc và 9 chỗ gộp phần tử. Khoảng 10 nút chỉ có biểu tượng cần kiểm tra nhãn. Tôi chưa bật VoiceOver để nghe thật, nên mục này mới là ước lượng. | 5.6 |  | Open |
| F4-55 | Giảm chuyển động, VoiceOver, rung và âm thanh (đọc code) | Point | **Rung:** đã có sẵn 4 kiểu rung trong `Haptics.swift`, nhưng không dùng kiểu rung mới của SwiftUI (`sensoryFeedback`). App không có âm thanh nào. Phần 1 đã đề xuất nơi nên rung: lưu khoản chi, đã nhận, chốt đợt, cả nhóm sòng phẳng. | 5.6 |  | Open |
