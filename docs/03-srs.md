# 03 — SRS (Đặc tả yêu cầu phần mềm)

Cập nhật: 2026-11-11. Trạng thái: đã duyệt ngày 2026-11-11; bản sửa đổi cùng ngày (mục 2.7 ô gõ nhanh, FR-1.25, FR-3.5) đã duyệt. Bản sửa đổi thứ ba (nội bộ trước, phát hành công khai sau; đăng ký bằng email) đã duyệt.

Tài liệu này đặc tả hệ thống ở mức kiểm thử được. Nhu cầu người dùng đứng sau mỗi yêu cầu nằm trong [02 — PRD](02-prd.md).

Giai đoạn 1 được mô tả chi tiết đến mức kiểm thử được. Các giai đoạn sau mô tả ở mức tính năng; mỗi giai đoạn sẽ được chi tiết hoá trước khi bắt đầu làm.

Mã yêu cầu: `FR` là chức năng, `NFR` là phi chức năng. Số đầu là giai đoạn.

## 1. Thuật ngữ

| Thuật ngữ | Nghĩa |
|---|---|
| Nhóm | Một sổ chi tiêu chung |
| Thành viên | Một người được ghi tên trong nhóm để chia tiền; có thể không có tài khoản |
| Người dùng | Một tài khoản đã đăng nhập |
| Giao dịch | Chi tiêu, chuyển khoản hoặc thu nhập |
| Người trả | Thành viên bỏ tiền ra |
| Người chịu | Thành viên phải gánh một phần của giao dịch |
| Số dư | Tổng đã trả trừ tổng phải chịu của một thành viên; dương là được nợ, âm là đang nợ |
| Lượt chuyển | Một đề xuất "A trả B số tiền X" để đưa số dư về 0 |

## 2. Giai đoạn 1 — Lõi chia tiền

### 2.1 Tài khoản

| Mã | Yêu cầu |
|---|---|
| FR-1.1 | Người dùng đăng nhập bằng tài khoản Google. Lần đầu đăng nhập thì tài khoản được tạo tự động với tên, email và ảnh từ Google. |
| FR-1.2 | Người dùng đăng xuất được; phiên trên thiết bị đó mất hiệu lực ngay. |
| FR-1.3 | Khi phiên hết hạn, người dùng được đưa về trang đăng nhập và sau khi đăng nhập quay lại đúng trang đang xem. |
| FR-1.4 | Người dùng đăng ký bằng email, tên hiển thị và mật khẩu (tối thiểu 10 ký tự; từ chối mật khẩu nằm trong danh sách mật khẩu phổ biến). Ai cũng đăng ký được; không cần lời mời. |
| FR-1.5 | Sau khi đăng ký, ứng dụng gửi thư xác minh. Tài khoản chưa xác minh email đăng nhập được nhưng không tạo nhóm, không tham gia nhóm và không ghi dữ liệu được. Gửi lại thư xác minh được, có giới hạn tần suất. |
| FR-1.6 | Quên mật khẩu: nhập email, nhận link đặt lại có hạn 1 giờ, dùng một lần. Đặt lại xong, mọi phiên khác của tài khoản mất hiệu lực. |
| FR-1.7 | Người dùng đã đăng nhập đổi được mật khẩu (cần mật khẩu cũ) và đăng xuất khỏi mọi thiết bị khác. |
| FR-1.8 | Một email là một tài khoản. Đăng nhập Google với email trùng một tài khoản mật khẩu **đã xác minh** thì vào cùng tài khoản đó; nếu tài khoản mật khẩu chưa xác minh thì không tự liên kết. |
| FR-1.9 | Người dùng xoá được tài khoản của mình. Các thành viên họ từng gắn trong các nhóm trở thành thành viên không có tài khoản, giữ nguyên tên và giao dịch; nhóm họ làm chủ phải được chuyển quyền hoặc xoá trước. |

### 2.2 Nhóm

| Mã | Yêu cầu |
|---|---|
| FR-1.10 | Người dùng tạo nhóm với một tên. Người tạo trở thành chủ nhóm và là thành viên đầu tiên. |
| FR-1.11 | Người dùng xem danh sách các nhóm mình thuộc về, mỗi nhóm hiện số dư của chính mình. |
| FR-1.12 | Chủ nhóm đổi tên nhóm và bật/tắt tối giản nợ. Mặc định bật. |
| FR-1.13 | Chủ nhóm xoá nhóm sau khi xác nhận bằng cách gõ lại tên nhóm. |
| FR-1.14 | Người dùng không phải chủ nhóm rời nhóm được. Thành viên tương ứng và các giao dịch của họ vẫn giữ nguyên. |

### 2.3 Thành viên

| Mã | Yêu cầu |
|---|---|
| FR-1.20 | Người đọc-ghi thêm thành viên chỉ bằng một cái tên; thành viên không cần có tài khoản. |
| FR-1.21 | Người đọc-ghi đổi tên thành viên và đặt trọng số mặc định. |
| FR-1.22 | Thành viên chưa có giao dịch nào thì xoá được. Thành viên đã có giao dịch chỉ chuyển sang "ngừng hoạt động". |
| FR-1.23 | Thành viên ngừng hoạt động không xuất hiện mặc định trong giao dịch mới, nhưng vẫn hiện trong giao dịch cũ và bảng số dư. |
| FR-1.24 | Mỗi người dùng trong nhóm gắn với nhiều nhất một thành viên ("tôi là người này") và đổi được lựa chọn đó. |
| FR-1.25 | Mỗi thành viên được gán một cặp hình dạng và màu khi được thêm vào nhóm. Cặp này không đổi theo thời gian, giống nhau trên mọi thiết bị, và không trùng nhau trong một nhóm chừng nào còn cặp chưa dùng. Giao diện dùng nó thay cho ảnh đại diện. |

### 2.4 Mời và phân quyền

| Mã | Yêu cầu |
|---|---|
| FR-1.30 | Mỗi nhóm có một link mời và mã QR tương ứng. |
| FR-1.31 | Người mở link mời thấy tên nhóm và danh sách thành viên trước khi quyết định tham gia. |
| FR-1.32 | Khi tham gia, người dùng chọn một thành viên chưa có ai nhận là mình, hoặc tạo thành viên mới. |
| FR-1.33 | Người tham gia qua link nhận vai trò mặc định của nhóm. Mặc định là đọc-ghi; chủ nhóm đổi được. |
| FR-1.34 | Chủ nhóm tắt link mời, hoặc tạo link mới làm link cũ mất hiệu lực. |
| FR-1.35 | Chủ nhóm đổi vai trò của người khác giữa đọc-ghi và chỉ đọc, và gỡ người khỏi nhóm. |
| FR-1.36 | Chủ nhóm chuyển quyền chủ nhóm cho người dùng khác trong nhóm. Nhóm luôn có đúng một chủ nhóm. |

**Bảng quyền**

| Thao tác | Chủ nhóm | Đọc-ghi | Chỉ đọc |
|---|---|---|---|
| Xem giao dịch, số dư, lịch sử | Có | Có | Có |
| Thêm, sửa, xoá, khôi phục giao dịch | Có | Có | Không |
| Thêm, sửa thành viên | Có | Có | Không |
| Xem link mời | Có | Có | Không |
| Đổi vai trò, gỡ người, quản lý link mời | Có | Không | Không |
| Sửa cài đặt nhóm, xoá nhóm | Có | Không | Không |

### 2.5 Giao dịch

| Mã | Yêu cầu |
|---|---|
| FR-1.40 | Người đọc-ghi tạo **chi tiêu** với: số tiền (bắt buộc, lớn hơn 0), mô tả (bắt buộc), người trả, người chịu, cách chia, ngày giờ, danh mục. |
| FR-1.41 | Mặc định: người trả là thành viên gắn với người dùng; người chịu là mọi thành viên đang hoạt động; cách chia là chia đều; ngày giờ là hiện tại. |
| FR-1.42 | Một chi tiêu có thể có nhiều người trả, mỗi người một số tiền; tổng phải bằng tổng tiền. |
| FR-1.43 | Người đọc-ghi tạo **chuyển khoản** từ một thành viên sang một thành viên khác. |
| FR-1.44 | Người đọc-ghi tạo **thu nhập** (tiền nhóm nhận về, ví dụ hoàn tiền): một người nhận, chia cho những người hưởng theo các cách chia như chi tiêu. |
| FR-1.45 | Người đọc-ghi sửa mọi trường của giao dịch. Màn hình sửa hiện lại đúng đầu vào đã nhập. |
| FR-1.46 | Người đọc-ghi xoá giao dịch; giao dịch đã xoá khôi phục được từ lịch sử. |
| FR-1.47 | Danh sách giao dịch sắp theo ngày giờ, nhóm theo ngày; khi mở nhóm, các giao dịch mới nhất hiện sẵn, giao dịch cũ hơn tải thêm khi cuộn. |
| FR-1.48 | Mỗi dòng giao dịch hiện: mô tả, tổng tiền, ai trả, và phần của chính người đang xem. |
| FR-1.49 | Danh mục chọn từ một danh sách cố định: ăn uống, đi lại, chỗ ở, mua sắm, giải trí, hoá đơn, khác. |

### 2.6 Cách chia

| Mã | Yêu cầu |
|---|---|
| FR-1.50 | **Chia đều** giữa những người chịu được chọn. |
| FR-1.51 | **Theo số tiền:** nhập số tiền cho từng người. Màn hình hiện số còn lại và chỉ cho lưu khi còn lại bằng 0. |
| FR-1.52 | **Còn lại chia đều:** trong chế độ theo số tiền, những người để trống được chia đều phần còn lại. |
| FR-1.53 | **Phần riêng cộng phần chung:** nhập phần riêng của từng người; phần chưa phân bổ được chia đều cho mọi người chịu. |
| FR-1.54 | **Theo phần:** nhập trọng số cho từng người (cho phép số thập phân); tiền chia theo tỉ lệ. |
| FR-1.55 | **Theo phần trăm:** nhập phần trăm cho từng người; tổng phải bằng 100. |
| FR-1.56 | Mọi cách chia cho ra số tiền nguyên cho từng người với tổng bằng đúng tổng tiền. Quy tắc làm tròn: lấy phần nguyên của từng người, rồi phân các đơn vị còn dư cho những người có phần lẻ lớn nhất trước; nếu bằng nhau thì theo thứ tự thành viên được thêm vào nhóm. |

### 2.7 Ô gõ nhanh

Có hai cách thêm chi tiêu, ngang hàng nhau: **gõ một câu** như nhắn tin, hoặc **nhập tay** bằng form (mục 2.5, 2.6). Với câu gõ, ứng dụng đọc bằng **quy tắc cố định, không dùng AI**, rồi hiện thẻ xác nhận. Form làm được mọi thứ câu gõ làm được, cộng thêm chuyển khoản, thu nhập, nhiều người trả, ngày giờ và danh mục; nó cũng là nơi mọi câu không đọc được được chuyển tới.

| Mã | Yêu cầu |
|---|---|
| FR-1.90 | Màn hình nhóm có một ô gõ ở đáy. Người đọc-ghi gõ một câu để tạo **chi tiêu**. Chuyển khoản và thu nhập không tạo qua ô gõ. Ngay cạnh ô gõ luôn có nút **Nhập tay** mở form trống bằng một lần chạm; người dùng không bao giờ buộc phải gõ câu. |
| FR-1.91 | **Số tiền:** đọc được `300k`, `300K`, `300.000`, `300000`, `300 nghìn`, `300 ngàn`, `1tr`, `1tr2`, `1,2tr`, `1.2 triệu`. Số tiền đầu tiên trong câu là tổng tiền. |
| FR-1.92 | **Mô tả:** phần chữ đứng trước tổng tiền, bỏ khoảng trắng thừa. Thiếu mô tả thì thẻ xác nhận yêu cầu nhập trước khi lưu. |
| FR-1.93 | **Người trả:** `<tên> trả`; `mình`, `tôi`, `tớ` là thành viên gắn với người đang gõ. Không nêu người trả thì dùng mặc định của FR-1.41. |
| FR-1.94 | **Chia đều:** `chia đều` hoặc không nói gì là chia đều cho mọi thành viên đang hoạt động. `chia <N>` với N bằng số thành viên đang hoạt động cũng vậy; N khác thì thẻ xác nhận yêu cầu chọn đúng N người. `chia <tên>, <tên>…` là chia đều cho những người được nêu. |
| FR-1.95 | **Phần riêng:** chuỗi các cặp `<tên> <số>` là số tiền riêng của từng người (FR-1.51). Nếu câu có `còn lại chia đều` thì phần chưa phân bổ chia đều cho những người đã nêu tên (FR-1.53); nếu không có và tổng các phần riêng khác tổng tiền thì câu được coi là chưa đọc được trọn vẹn (FR-1.99). |
| FR-1.96 | **Số viết tắt:** trong phần riêng, số không kèm đơn vị và nhỏ hơn 1.000 được hiểu là nghìn đồng (`minh 80` là 80.000 đ). |
| FR-1.97 | **Khớp tên:** không phân biệt hoa thường và dấu tiếng Việt (`hung` khớp `Hùng`). Một từ khớp từ hai thành viên trở lên thì không tự chọn; thẻ xác nhận yêu cầu người dùng chọn. |
| FR-1.98 | **Thẻ xác nhận:** hiện mô tả, tổng tiền, người trả, cách chia và số tiền cuối cùng của từng người; số tiền lấy từ cùng bộ tính với lúc lưu (FR-1.56). Mỗi cụm từ đã hiểu trong câu được tô màu theo loại. Không có gì được lưu trước khi người dùng bấm Lưu. Từ thẻ này mở được form nhập tay với mọi trường đã điền sẵn. |
| FR-1.99 | **Không đoán:** khi câu thiếu tổng tiền, có phần không hiểu ảnh hưởng đến con số, hoặc các con số không khớp nhau, ứng dụng không lưu và không tự sửa; nó mở form nhập tay với những gì đã hiểu được điền sẵn và nói rõ phần nào chưa hiểu. Câu đã gõ không bị mất. |
| FR-1.100 | Bộ đọc chạy ở server và trả cùng một kết quả cho mọi client. Nó đi kèm một danh sách ít nhất 60 câu mẫu trong `docs/`, gồm cả câu phải bị từ chối, mỗi câu ghi kết quả đúng, để kiểm tay. |

### 2.8 Số dư và thanh toán nợ

| Mã | Yêu cầu |
|---|---|
| FR-1.60 | Màn hình Số dư hiện số dư của từng thành viên, kể cả người ngừng hoạt động có số dư khác 0. |
| FR-1.61 | Hiện danh sách lượt chuyển đề xuất để mọi số dư về 0. |
| FR-1.62 | Khi bật tối giản: số lượt chuyển không vượt quá số thành viên trừ 1. |
| FR-1.63 | Khi tắt tối giản: nợ giữ theo từng cặp người, chỉ bù trừ hai chiều trong cùng một cặp. |
| FR-1.64 | Từ một lượt chuyển đề xuất, người đọc-ghi tạo khoản chuyển tương ứng bằng một lần bấm, sửa được số tiền trước khi lưu. |

### 2.9 Lịch sử

| Mã | Yêu cầu |
|---|---|
| FR-1.70 | Mọi thay đổi về giao dịch, thành viên, quyền và cài đặt nhóm được ghi lại: ai, làm gì, khi nào. |
| FR-1.71 | Với giao dịch bị sửa, lịch sử hiện giá trị trước và sau của các trường đã đổi. |

### 2.10 Realtime và ngoại tuyến

| Mã | Yêu cầu |
|---|---|
| FR-1.80 | Khi một người thay đổi dữ liệu của nhóm, những người đang mở nhóm đó thấy thay đổi trong vòng 2 giây mà không cần tải lại trang. |
| FR-1.81 | Khi mất mạng, người dùng vẫn xem được dữ liệu đã tải; các thao tác ghi bị vô hiệu kèm lời giải thích. |
| FR-1.82 | Khi có mạng lại, dữ liệu của nhóm đang xem tự làm mới. |

### 2.11 Phi chức năng

| Mã | Yêu cầu |
|---|---|
| NFR-1.1 | Tiền lưu và tính bằng số nguyên; không dùng số thực trong đường đi của tiền. |
| NFR-1.2 | Tổng số dư của mọi nhóm luôn bằng 0. |
| NFR-1.3 | Gửi lại cùng một yêu cầu tạo giao dịch không tạo ra giao dịch thứ hai. |
| NFR-1.4 | Hai người sửa cùng một giao dịch: người lưu sau được báo xung đột, không ghi đè âm thầm. |
| NFR-1.5 | Người ngoài nhóm không phân biệt được nhóm tồn tại hay không. |
| NFR-1.6 | Mọi kết nối dùng HTTPS. Cookie phiên là HttpOnly, Secure, SameSite. |
| NFR-1.12 | Mật khẩu chỉ lưu dưới dạng băm bằng thuật toán chuyên cho mật khẩu (argon2id hoặc tương đương). Đăng nhập, đăng ký, gửi lại thư và quên mật khẩu đều có giới hạn tần suất theo IP và theo email. |
| NFR-1.13 | Trang đăng ký, đăng nhập và quên mật khẩu không cho biết một email đã có tài khoản hay chưa. |
| NFR-1.14 | Ở môi trường phát triển, thư không được gửi đi mà in ra màn hình console; ứng dụng chạy đủ trên máy local không cần dịch vụ gửi thư. |
| NFR-1.7 | Giao diện dùng tốt trên màn hình rộng từ 360px; thao tác chính làm được bằng một tay. |
| NFR-1.8 | Giao diện tiếng Việt; số tiền hiển thị theo định dạng Việt Nam (`150.000 đ`). Chuỗi hiển thị tách khỏi code để thêm ngôn ngữ sau. |
| NFR-1.9 | Trang nhóm với 500 giao dịch mở trong dưới 2 giây trên mạng 4G. |
| NFR-1.10 | Sao lưu toàn bộ database mỗi đêm ra ngoài máy chủ, giữ 30 bản; quy trình khôi phục đã được chạy thử. |
| NFR-1.11 | Dùng được bằng bàn phím và trình đọc màn hình ở các luồng chính; độ tương phản đạt WCAG AA. |

### 2.12 Ngoài phạm vi giai đoạn 1

Đa tiền tệ, giao dịch định kỳ, ảnh hoá đơn, danh mục tuỳ chỉnh, biểu đồ, xuất file, thông báo đẩy, tìm kiếm, lưu trữ nhóm. Với ô gõ nhanh: đọc câu bằng AI, nhập bằng giọng nói, hỏi đáp ("ai nợ ai?") và tạo chuyển khoản bằng câu gõ.

## 3. Giai đoạn 2 — Tiền thật

| Mã | Tính năng |
|---|---|
| FR-2.1 | Thành viên khai báo thông tin nhận tiền: ngân hàng và số tài khoản, số điện thoại MoMo, ZaloPay. |
| FR-2.2 | Mỗi lượt chuyển đề xuất hiện mã VietQR điền sẵn số tiền và nội dung chuyển khoản. |
| FR-2.3 | Nút mở thẳng ứng dụng MoMo hoặc ZaloPay nếu khả thi; nếu không thì sao chép số điện thoại và số tiền. |
| FR-2.4 | Người trả đánh dấu "đã chuyển"; người nhận xác nhận, khi đó khoản chuyển mới được ghi sổ. |
| FR-2.5 | Quỹ chung: thành viên góp tiền vào quỹ; chi tiêu có thể trả từ quỹ; hiện số dư quỹ và phần góp của từng người. |
| FR-2.6 | Thống kê: tổng chi theo thời gian, theo danh mục, theo thành viên. |
| FR-2.7 | Ngân sách: đặt hạn mức cho nhóm theo tháng hoặc theo chuyến đi; cảnh báo khi gần chạm và khi vượt. |
| FR-2.8 | Danh mục tuỳ chỉnh theo nhóm. |
| FR-2.9 | Xuất dữ liệu nhóm ra CSV. |

## 4. Giai đoạn 3 — Nhập liệu thông minh

| Mã | Tính năng |
|---|---|
| FR-3.1 | Đính kèm ảnh hoá đơn vào giao dịch. |
| FR-3.2 | Chụp hoá đơn: AI đọc ra danh sách món, giá, thuế, phí dịch vụ và tổng. |
| FR-3.3 | Gán từng món cho một hoặc nhiều người; thuế và phí phân bổ theo tỉ lệ. |
| FR-3.4 | Người dùng luôn xem lại và sửa kết quả AI trước khi lưu. |
| FR-3.5 | AI đọc những câu mà bộ quy tắc của ô gõ nhanh (mục 2.7) từ chối: câu tự do, viết tắt lạ, nhiều khoản trong một câu. Giao diện ô gõ và thẻ xác nhận giữ nguyên; câu theo mẫu vẫn do bộ quy tắc xử lý, không gọi AI. |
| FR-3.6 | Tự gợi ý danh mục từ mô tả. |

## 5. Giai đoạn 4 — Cộng tác

| Mã | Tính năng |
|---|---|
| FR-4.1 | Bình luận trên giao dịch. |
| FR-4.2 | Phản đối một khoản chi kèm lý do; khoản bị phản đối được đánh dấu cho đến khi giải quyết. |
| FR-4.3 | Tuỳ chọn theo nhóm: khoản chi trên một ngưỡng cần chủ nhóm duyệt. |
| FR-4.4 | Thông báo trong ứng dụng và qua email khi có khoản chi mới, khi bị nhắc nợ. |
| FR-4.5 | Bot Telegram: liên kết nhóm chat với nhóm chi tiêu; thêm chi tiêu bằng tin nhắn; hỏi số dư. |
| FR-4.6 | Bot Zalo, nếu khảo sát cho thấy khả thi. |
| FR-4.7 | Nhắc nợ: gửi lời nhắc thủ công hoặc tự động theo chu kỳ. |

## 6. Giai đoạn 5 và 6 — iOS và Android

| Mã | Tính năng |
|---|---|
| FR-5.1 | App iOS native có đủ tính năng của web tại thời điểm phát hành. |
| FR-5.2 | Đăng nhập bằng Apple và Google. |
| FR-5.3 | Thông báo đẩy. |
| FR-5.4 | Chụp hoá đơn bằng camera của máy. |
| FR-5.5 | Mở link mời dẫn thẳng vào app (universal link). |
| FR-6.1 | App Android native tương đương iOS. |

## 7. Ứng viên chưa xếp giai đoạn

Đa tiền tệ có tỉ giá theo giao dịch, giao dịch định kỳ, lưu trữ nhóm, nhân bản nhóm, tìm kiếm và lọc giao dịch, nhóm lồng nhau, widget màn hình chính. Xem [07 — Product Roadmap](07-roadmap.md) về cách đưa chúng vào kế hoạch.
