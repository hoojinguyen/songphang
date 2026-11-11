# 02 — PRD (Yêu cầu sản phẩm)

Cập nhật: 2026-11-11. Trạng thái: đã duyệt ngày 2026-11-11; bản sửa đổi cùng ngày (US-1.5, US-1.20–1.22, US-3.4) đã duyệt. Bản sửa đổi thứ ba (nội bộ trước, phát hành công khai sau; đăng ký bằng email) đã duyệt.

PRD mô tả sản phẩm dưới góc nhìn người dùng: họ là ai, cần gì, và sản phẩm đáp ứng bằng tính năng nào. Đặc tả kỹ thuật kiểm thử được nằm trong [03 — SRS](03-srs.md); cột "SRS" trong các bảng dưới đây trỏ sang đó.

## 1. Bối cảnh

Xem [01 — Vision & Scope](01-vision-scope.md). Tóm tắt: ứng dụng chia tiền dùng nội bộ trước cho bạn bè, gia đình và đồng nghiệp, sau đó phát hành công khai; có phần lõi của Settle Up và thêm các tính năng hợp thói quen ở Việt Nam.

## 2. Chân dung người dùng

**Minh — người tổ chức.** Hay đứng ra đặt phòng, đặt bàn, trả trước cho cả nhóm. Dùng điện thoại là chính. Muốn ghi một khoản chi trong vài giây ngay tại quầy thanh toán, và cuối chuyến đi biết chính xác ai cần chuyển cho mình bao nhiêu. Ghét phải nhắn tin đòi tiền từng người.

**Lan — người tham gia.** Được mời vào nhóm, thỉnh thoảng trả một khoản. Không muốn cài thêm app hay tạo thêm tài khoản. Muốn mở link là thấy mình nợ bao nhiêu, và trả bằng cách quét mã QR ngân hàng.

**Bác Hùng — người không dùng app.** Có mặt trong các khoản chi của gia đình nhưng không dùng ứng dụng. Con cháu ghi hộ; bác chỉ cần được báo con số cuối cùng.

**Thu — người giữ quỹ.** Quản lý quỹ phòng trọ hoặc quỹ team. Thu tiền đầu tháng, chi dần, cần cho mọi người thấy quỹ còn bao nhiêu và đã tiêu vào đâu.

## 3. Tình huống sử dụng chính

| Tình huống | Đặc điểm |
|---|---|
| Chuyến du lịch | Nhiều khoản trong vài ngày, nhiều người trả, thanh toán một lần cuối chuyến |
| Bữa ăn nhóm | Một hoá đơn, mỗi người ăn khác nhau, có món chung |
| Ở chung nhà | Chi phí lặp lại hằng tháng, kéo dài, thành viên có thể thay đổi |
| Quỹ team hoặc gia đình | Góp trước, chi dần, cần minh bạch |

## 4. Nguyên tắc sản phẩm

1. **Ghi nhanh hơn nhắn tin.** Nếu ghi một khoản chi tốn công hơn nhắn vào nhóm chat, mọi người sẽ không dùng.
2. **Con số phải được tin.** Ai cũng thấy cùng một con số và xem được nó đến từ đâu.
3. **Không ai bị buộc đăng ký.** Người không có tài khoản vẫn là thành viên đầy đủ trong sổ.
4. **Sửa sai thoải mái.** Mọi thay đổi đều có lịch sử và khôi phục được.

## 5. User story theo giai đoạn

Mức ưu tiên: **P0** bắt buộc để giai đoạn được coi là xong, **P1** nên có, **P2** có thì tốt.

### Giai đoạn 1 — Lõi chia tiền

| Mã | Là… | Tôi muốn… | Để… | Ưu tiên | SRS |
|---|---|---|---|---|---|
| US-1.1 | người dùng mới | đăng nhập bằng Google | không phải tạo và nhớ mật khẩu | P0 | FR-1.1–1.3 |
| US-1.1b | người không dùng Google | đăng ký bằng email và mật khẩu | vẫn dùng được ứng dụng | P0 | FR-1.4–1.8 |
| US-1.1c | người dùng | xoá tài khoản của mình | kiểm soát dữ liệu cá nhân | P1 | FR-1.9 |
| US-1.2 | Minh | tạo nhóm và thêm tên mọi người | bắt đầu ghi chi tiêu ngay, kể cả khi họ chưa tham gia | P0 | FR-1.10, 1.20 |
| US-1.3 | Minh | gửi một link hoặc mã QR mời | mọi người vào nhóm không cần hướng dẫn | P0 | FR-1.30–1.32 |
| US-1.4 | Lan | xem trước nhóm và chọn "tôi là ai" khi mở link | không tạo ra một thành viên trùng tên | P0 | FR-1.31, 1.32 |
| US-1.5 | Minh | ghi một khoản chi chia đều bằng ba thao tác trên form | ghi ngay tại quầy thanh toán, kể cả khi không muốn gõ câu | P0 | FR-1.40, 1.41, 1.50 |
| US-1.6 | Minh | chia một hoá đơn mà mỗi người một số tiền khác nhau | phản ánh đúng ai ăn gì | P0 | FR-1.51 |
| US-1.7 | Minh | nhập phần riêng của từng người, phần còn lại tự chia đều | không phải tự cộng trừ món chung | P0 | FR-1.52, 1.53 |
| US-1.8 | Minh | chia theo phần hoặc phần trăm | xử lý trường hợp cặp đôi tính hai phần, trẻ em nửa phần | P1 | FR-1.54, 1.55 |
| US-1.9 | Minh | ghi khoản chi có nhiều người cùng trả | phản ánh đúng khi góp tiền mặt tại chỗ | P1 | FR-1.42 |
| US-1.10 | Lan | thấy ngay mình nợ ai bao nhiêu | biết phải chuyển gì | P0 | FR-1.60, 1.61 |
| US-1.11 | cả nhóm | số lượt chuyển tiền ít nhất có thể | đỡ phải chuyển lòng vòng | P0 | FR-1.62 |
| US-1.12 | Lan | ghi nhận đã trả nợ bằng một lần bấm | sổ khớp ngay sau khi chuyển khoản | P0 | FR-1.43, 1.64 |
| US-1.13 | Minh | sửa hoặc xoá khoản chi ghi nhầm, và khôi phục khi xoá nhầm | sổ luôn đúng | P0 | FR-1.45, 1.46 |
| US-1.14 | Lan | xem ai đã thêm, sửa, xoá gì | tin vào con số | P1 | FR-1.70, 1.71 |
| US-1.15 | Minh | cho một số người chỉ được xem | bác Hùng hay người ngoài xem được mà không sửa nhầm | P1 | FR-1.33, 1.35 |
| US-1.16 | cả nhóm | thấy khoản chi người khác vừa thêm mà không cần tải lại | cùng nhìn một sổ khi ngồi tính tiền | P0 | FR-1.80 |
| US-1.17 | Lan | vẫn xem được số dư khi mất mạng | tra cứu được ở nơi sóng yếu | P1 | FR-1.81, 1.82 |
| US-1.18 | Minh | ghi khoản hoàn tiền hoặc tiền nhóm nhận về | sổ phản ánh đúng khi được hoàn cọc | P2 | FR-1.44 |
| US-1.19 | Minh | cho thành viên đã rời nhóm ngừng hoạt động | họ không còn bị chia vào khoản mới, nhưng nợ cũ vẫn còn | P1 | FR-1.22, 1.23 |
| US-1.20 | Minh | gõ "cà phê 180k chia 4" rồi bấm Lưu | ghi nhanh như nhắn tin, không phải đi qua form | P0 | FR-1.90–1.94, 1.98, 1.100 |
| US-1.21 | Minh | gõ "lẩu 300k, mình 80 lan 60 hùng 40, còn lại chia đều" | chia hoá đơn không đều trong một câu | P1 | FR-1.95–1.97 |
| US-1.22 | Minh | thấy rõ ứng dụng hiểu câu của mình thế nào trước khi lưu, và được đưa sang form khi nó không hiểu | không bao giờ có khoản chi bị ghi sai do đoán | P0 | FR-1.98, 1.99 |
| US-1.23 | cả nhóm | nhận ra từng người qua một hình và màu riêng | nhìn lướt là biết khoản nào của ai | P1 | FR-1.25 |

### Giai đoạn 2 — Tiền thật

| Mã | Là… | Tôi muốn… | Để… | Ưu tiên | SRS |
|---|---|---|---|---|---|
| US-2.1 | Lan | quét một mã QR đã điền sẵn số tiền và nội dung | trả nợ không phải gõ số tài khoản | P0 | FR-2.1, 2.2 |
| US-2.2 | Lan | mở thẳng MoMo hoặc ZaloPay | trả bằng ví mình hay dùng | P1 | FR-2.3 |
| US-2.3 | Minh | xác nhận đã nhận tiền trước khi sổ ghi nhận | không ai tự đánh dấu "đã trả" khi chưa chuyển | P1 | FR-2.4 |
| US-2.4 | Thu | quản lý quỹ góp trước và chi dần | mọi người thấy quỹ còn bao nhiêu | P0 | FR-2.5 |
| US-2.5 | Thu | xem chi tiêu theo danh mục, theo người, theo thời gian | biết tiền đi đâu | P0 | FR-2.6 |
| US-2.6 | Thu | đặt hạn mức và được cảnh báo khi sắp vượt | giữ chi tiêu trong kế hoạch | P1 | FR-2.7 |
| US-2.7 | Minh | tạo danh mục riêng cho nhóm | phân loại theo cách của nhóm mình | P2 | FR-2.8 |
| US-2.8 | Thu | xuất dữ liệu ra file | lưu trữ hoặc tính toán thêm | P2 | FR-2.9 |

### Giai đoạn 3 — Nhập liệu thông minh

| Mã | Là… | Tôi muốn… | Để… | Ưu tiên | SRS |
|---|---|---|---|---|---|
| US-3.1 | Minh | chụp hoá đơn và để ứng dụng đọc ra từng món | không phải gõ lại | P0 | FR-3.1, 3.2 |
| US-3.2 | Minh | chạm để gán từng món cho từng người | chia chính xác theo món | P0 | FR-3.3 |
| US-3.3 | Minh | xem lại và sửa trước khi lưu | không bị ghi sai khi ứng dụng đọc nhầm | P0 | FR-3.4 |
| US-3.4 | Minh | gõ câu tự do mà ô gõ ở giai đoạn 1 chưa hiểu | không phải nhớ mẫu câu | P1 | FR-3.5 |
| US-3.5 | Minh | danh mục được gợi ý sẵn | bớt một thao tác | P2 | FR-3.6 |

### Giai đoạn 4 — Cộng tác

| Mã | Là… | Tôi muốn… | Để… | Ưu tiên | SRS |
|---|---|---|---|---|---|
| US-4.1 | Lan | bình luận hoặc phản đối một khoản chi | hỏi lại khi thấy không đúng mà không phải ra nhóm chat | P0 | FR-4.1, 4.2 |
| US-4.2 | Thu | duyệt các khoản chi lớn từ quỹ | kiểm soát quỹ | P2 | FR-4.3 |
| US-4.3 | Lan | được báo khi có khoản chi mới liên quan đến mình | không bị bất ngờ cuối tháng | P1 | FR-4.4 |
| US-4.4 | Minh | thêm khoản chi ngay trong nhóm Telegram | không phải rời cuộc trò chuyện | P0 | FR-4.5 |
| US-4.5 | Minh | ứng dụng nhắc nợ thay mình | không phải đòi tiền trực tiếp | P1 | FR-4.7 |

### Giai đoạn 5 và 6 — iOS và Android

| Mã | Là… | Tôi muốn… | Để… | Ưu tiên | SRS |
|---|---|---|---|---|---|
| US-5.1 | người dùng iPhone | một app native đủ tính năng như web | thao tác mượt và mở nhanh | P0 | FR-5.1, 5.2 |
| US-5.2 | người dùng iPhone | nhận thông báo đẩy | biết ngay khi có thay đổi | P0 | FR-5.3 |
| US-5.3 | người dùng iPhone | bấm link mời là vào thẳng app | tham gia nhóm liền mạch | P1 | FR-5.5 |
| US-6.1 | người dùng Android | app tương đương iOS | có cùng trải nghiệm | P0 | FR-6.1 |

## 6. Chỉ số theo dõi

Ở chặng nội bộ, các chỉ số dùng để biết sản phẩm có giải quyết được nhu cầu thật không. Chỉ số cho chặng công khai được đặt trước giai đoạn 7.

| Chỉ số | Mục tiêu sau khi đưa lên máy chủ và dùng thật |
|---|---|
| Thời gian ghi một khoản chi chia đều | Dưới 10 giây |
| Tỉ lệ câu gõ theo mẫu được đọc đúng, đo trên câu gõ thật | Trên 90%; không có câu nào bị lưu sai |
| Tỉ lệ người mở link mời rồi tham gia thành công | Trên 90% |
| Số nhóm có hoạt động trong 30 ngày gần nhất | Ít nhất 3 nhóm thật của chủ dự án |
| Sai lệch tổng số dư | Luôn bằng 0 |
| Lần phải sửa dữ liệu thủ công trong database | 0 |

## 7. Giả định và câu hỏi mở

**Đã trả lời ngày 2026-11-11**

| Câu hỏi | Trả lời của chủ dự án |
|---|---|
| Khi nào chặng nội bộ "đạt" để mở công khai? | Chủ dự án tự dùng thử, đánh giá và quyết định. Không đặt ngưỡng số liệu. |
| Có thu tiền không? | Miễn phí. Chuyện doanh thu sẽ cân nhắc về sau, không nằm trong kế hoạch hiện tại. |
| Phát hành ở đâu? | Chỉ Việt Nam: giao diện tiếng Việt, tiền VND, theo quy định dữ liệu của Việt Nam. |
| Ứng dụng tên gì? | **Sòng Phẳng**. Ngày 2026-11-11, các tên miền `songphang` đuôi `.vn`, `.com.vn`, `.com`, `.app`, `.io`, `.co` đều chưa có bản ghi DNS, và tìm kiếm web không thấy ứng dụng hay công ty nào cùng tên. Chưa tra nhãn hiệu. |

**Giả định**
- Phần lớn người dùng có tài khoản Google; người không có đăng ký bằng email.
- Phần lớn lượt dùng là trên điện thoại, qua trình duyệt.
- Nhóm thường có 2–20 thành viên và dưới 1.000 giao dịch.

**Câu hỏi mở** — cần trả lời trước giai đoạn tương ứng, không chặn giai đoạn 1:

| Câu hỏi | Cần trước |
|---|---|
| Người dùng thật gõ khoản chi bằng những mẫu câu nào? Thu thập câu gõ thật ở mốc 1D để mở rộng bộ quy tắc. | Mốc 1D |
| MoMo và ZaloPay có cho phép mở app với số tiền điền sẵn từ một trang web bên ngoài không? | Giai đoạn 2 |
| Quỹ chung là một loại thành viên đặc biệt hay một thực thể riêng? | Giai đoạn 2 |
| Dịch vụ AI nào đọc hoá đơn tiếng Việt đủ chính xác, chi phí mỗi lượt bao nhiêu? | Giai đoạn 3 |
| Zalo có cho bot hoạt động trong nhóm chat của người dùng cá nhân không? | Giai đoạn 4 |
| Có cần đa tiền tệ cho chuyến đi nước ngoài không, và vào giai đoạn nào? | Sau giai đoạn 1 |
| Tên "Sòng Phẳng" có trùng nhãn hiệu đã đăng ký không? Cần tra cơ sở dữ liệu của Cục Sở hữu trí tuệ; và đăng ký tên miền `songphang`. | Trước bước đưa lên máy chủ |
