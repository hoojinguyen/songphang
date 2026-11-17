# Phase 2 run — owner manual checks

Status: advisor preparation completed; feature implementation pending. The sections below reserve the approved flow organization. Concrete task checks must be added as tasks are implemented, including invalid cases and actual URLs/commands where needed.

## With real money

1. Put your own real bank account on one member in S10, open a 1.000 đ debt to that member in S5 → S14 (`/g/{id}/pay`), scan the QR code with your banking app → bank, account number, account name, amount (1.000 đ), and content (`SP {from} tra {to}`) are all filled in and correct. Verify before sending, then send. (Not performed by the agent.)

## S5 — balances and settlement confirmation

1. In two browser windows (Hùng viewer who owes, Minh owner who receives), Hùng opens the debt to Minh and presses `Tôi đã chuyển` → Hùng sees `Đang chờ Minh xác nhận` and `Huỷ báo`, Minh sees `Hùng báo đã chuyển ...` with `Đã nhận` and `Chưa nhận` without refreshing; balances remain unchanged.
2. Minh presses `Đã nhận` → snackbar `Đã ghi nhận ... từ Hùng.`, debt disappears and balances update in both windows.
3. On another pending request, Minh presses `Chưa nhận` → `Đã báo lại là chưa nhận.`, balances remain unchanged and Hùng sees the pay link again; or Hùng presses `Huỷ báo` → pending row returns to the pay link.
4. Open the same pending request in two tabs, resolve in the first tab, then click `Đã nhận` in the second stale tab → `Yêu cầu này đã được xử lý.` and the list refreshes.
5. When the group has a fund, `FundBlock` (`Quỹ còn ...` or `Quỹ đang âm ...` + holder) appears above balances and opens S17; any fund settlement uses `Quỹ hoàn {to} {amount}` / `{from} góp thêm vào quỹ {amount}` with `Ghi nhận` opening S9 (`/settle`, no `/pay` QR screen).

## S10 — members and payment methods

1. On S10 (`/g/{id}/members`), editors see `Lập quỹ chung` when no fund exists (opens modal with `Tên quỹ` default `Quỹ chung` and `Ai giữ tiền quỹ?`), and the people count (`{count} người`) excludes the fund.
2. When a fund exists, S10 shows the fund row (`FundShape` yellow pill) linking to S17 (`/g/{id}/fund`) with no generic member-edit controls.
3. Expand a person → `Thông tin nhận tiền` → search bank, enter account/name or MoMo/ZaloPay, submit → `Đã lưu.`; dashed account → `Số tài khoản chỉ gồm chữ và số.`; short phone → `Số điện thoại chưa đúng.`; viewer sees others read-only and own details editable.

## S11 — categories and budget settings

1. On S11 (`/g/{id}/settings`), under `Danh mục của nhóm`, create a custom category with a name and color swatch → appears immediately; submit an accent/case duplicate (e.g. `ca phe sang`) → `Nhóm đã có danh mục này.`.
2. Rename/recolor an existing custom category, create an expense picking it in `CategoryPicker`, then tap `Ẩn danh mục` (either on S11 or from `CategoryPicker`'s `+ Thêm danh mục` modal) → the old expense keeps showing the category name and color dot in the stream and stays selected (`(đã ẩn)`) when editing that expense until changed, while new-expense picker no longer offers it.
3. On a group with 30 live custom categories, attempt adding a 31st → `Nhóm đã có 30 danh mục.`.

Pending 2D.2 for budget settings.

## S14 — paying

1. Tap a suggested transfer in S5 → opens `/g/{id}/pay?from=&to=` with both member shapes, large amount, `Sao chép số tiền`, QR card (`>= 240×240` with white quiet zone), bank rows (`Ngân hàng`, `Số tài khoản`, `Tên tài khoản`, `Nội dung`), wallet rows if present, and `Tôi đã chuyển`.
2. Click `Sao chép` on account number or content → button text changes to `Đã sao chép` for two seconds; double-tap `Tôi đã chuyển` → creates only one pending request and returns to S5 with `Đã báo cho {to}. Sổ sẽ ghi nhận khi {to} xác nhận.`.
3. Open a transfer to a member without payment details → `{to} chưa có thông tin nhận tiền.`; owner/editor (or the linked receiver) sees `Thêm thông tin`, while another viewer does not.
4. Open S14 as an editor/owner → `Ghi nhận luôn` link opens S9 (`/settle`); open as a viewer for another member's transfer → neither `Tôi đã chuyển` nor `Ghi nhận luôn` is shown; open `/pay` for an already-settled pair → redirects back to S5.

## S16 — statistics and CSV

1. Record three expenses and one refund in a new group, then open S16 (`Tổng chuyến đi`) → total equals expenses minus the refund.
2. Switch between `Tất cả`, `Tháng này`, `Tháng trước`, and `Tuỳ chọn` → totals change and bars resize; an empty period shows `Chưa có khoản chi nào trong khoảng này`.
3. Tap a category or member row on S16 → opens S4 filtered to that category/member (and active period) with filter chips above the stream.
4. Tap `Xuất CSV` on S16 → downloads `song-phang-YYYYMMDD.csv`; open in Excel or Google Sheets → Vietnamese reads correctly, one row per transaction, one column per member, and cells starting with `=`/`+`/`-`/`@` are plain text (not evaluated as formulas).

## S17 — shared fund

1. S10 → `Lập quỹ chung` → S17 (`/g/{id}/fund`) → `Góp vào quỹ` 500.000 from one person → S5 shows `Quỹ còn 500.000 đ` and S17 lists the contributor under `Đã góp`.
2. Add an expense with `Quỹ chung trả` (or type `ăn tối 300k quỹ trả` in quick-entry) → fund drops, `Quỹ chung trả` badge renders, sharers list stays people-only, and personal debts only change by each person's share.
3. Pay more than the fund holds in manual form → `Quỹ không đủ. Sau khoản này quỹ âm {amount}.` warning appears and still saves; S5 shows `Quỹ đang âm {amount}`.
4. Try `Đóng quỹ` on S17 while cash ≠ 0 → `Quỹ còn tiền. Hãy hoàn hết cho mọi người trước.`; type `ăn 300k chia quỹ` in quick-entry → unparsed banner shows `Quỹ không thể là người chia.`.

## S4 — filters and budget banner

1. On S4, scroll to the top of the stream → search field (`Tìm khoản chi`) and `Lọc` button appear.
2. Type a partial or unaccented description (e.g. `pho`) → matching transactions filter after debounce; reload the page → URL keeps filters and results; type a non-matching term → `Không có khoản nào khớp`.
3. Tap `Lọc` → filter modal opens with `Người`, `Danh mục`, `Loại`, `Từ ngày`, `Đến ngày`; apply filters → `BalanceBlock` hides while `EntryBar` remains; tap `Xoá lọc` → full stream and `BalanceBlock` return.

Pending 2D.2 for budget banner.

## Task 0 — local capabilities

1. Open `/api/v1/features` on the local API → receiptReading, sentenceAi, telegram, push, appleSignIn and errorAlerts are all false; no sign-in required.
2. Open `/api/v1/receipts` or `/api/v1/auth/apple` → 404; no optional service is enabled.

## Core VietQR reference — 2A.1

1. After the paying screen exists, compare its reference payload with task 2A.1 before scanning → exact bytes, bank/account/amount/purpose match. Do not send money to reference accounts.
2. Call buildVietQrPayload with amount 0, 1.5 or an account containing a space → RangeError; an unknown findBank BIN returns undefined.

### Payment details API — 2A.2

1. As a viewer, PUT the complete methods list for your linked member → 200 and reloading members retains it.
2. PUT for another member → 403; sign in outside the group and retry → 404.
3. Submit a dashed bank account, unsupported BIN, duplicate method kind or short wallet phone → 400; existing saved details remain intact.
4. Save an empty methods list → 200 and no receiving details remain. Invite previews and activity details must never show bank accounts or phone numbers.

### Settlement confirmation API — 2A.3

1. In a fresh four-person group record a 600000 expense paid by Minh; as Hùng (viewer) report Hùng → Minh 150000 → pending and unchanged balances.
2. Confirm as Minh → one transfer and Hùng balance zero. Confirm again → 409 REQUEST_NOT_PENDING and still one transfer.
3. As Hùng try to report Lan's payment or confirm your own payment to linked Minh → 403. An outsider must receive 404.
4. Create another report; cancel as its creator, or reject as receiver → no ledger/balance change. Concurrent double confirmation must create one transfer.

### Payment editor UI — 2A.5

1. S10 → expand a member → Thông tin nhận tiền → choose bank, fill account/name and wallet → Lưu → Đã lưu.; reload retains data.
2. Search vietc in the bank picker → Vietcombank appears; Escape closes and returns focus to the picker.
3. Enter a dashed account or short phone → exact validation text; saved values must remain unchanged.
4. Clear a wallet phone and save → the method disappears. As a viewer, other members' details are read-only; your linked member is editable, with no generic member-edit controls.
