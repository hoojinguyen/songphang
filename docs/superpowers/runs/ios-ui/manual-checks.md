# iOS interface stage — manual checks for the project owner

Owner checks, not claims of verification. Evidence collected by the agent is in `progress.md`.

## Before you start

1. Open `apps/ios/SongPhang.xcodeproj` in the `songphang-ios-ui` worktree with Xcode 26 or newer.
2. Select the **`SongPhang`** scheme and an iPhone Simulator running **iOS 26 or newer** (for example, iPhone 17 Pro, iOS 26.5).
3. Press **Run (`⌘R`)**.
4. To open the **Debug Panel** at any time: tap the **`Debug`** button in the top-right navigation bar (on Sign-In or Group List) or trigger **Device → Shake (`⌃⌘Z`)** in Simulator.
5. In the interface stage (`5U`), the app runs entirely on the scripted `FakeWorld` in `PreviewSupport`; no API server (`pnpm dev`) is needed.

## Full Phase 1 Journey on `trip`

1. **Sign-in (S1):**
   - Open the Debug Panel and tap **`Sign out (go to S1)`**.
   - Confirm **`Đăng nhập với Apple`** is above **`Tiếp tục với Google`**, followed by email/password fields and links **`Quên mật khẩu?`** and **`Chưa có tài khoản? Tạo tài khoản`**.
   - Enter any email and password `wrong`, tap **`Đăng nhập`** → confirm error **`Email hoặc mật khẩu không đúng.`**.
   - Enter password `password123` (or tap **`Đăng nhập với Apple`**) → confirm navigation to Group List (S2).
2. **Create group (S2 → S3 → S4):**
   - Open the Debug Panel, switch Scenario to **`empty`**, and close the Debug Panel.
   - Confirm empty state **`Gõ khoản chi đầu tiên`** is shown.
   - Tap **`Tạo nhóm`**, enter **`Đà Lạt 3N2Đ`**, add members **`Lan`**, **`Hùng`**, **`Thu`**, and tap **`Tạo nhóm`** → confirm navigation to the empty group stream (S4) with sample quick-entry chips.
3. **Members & invite link (S4 → S10):**
   - Tap the 4-shape member pill in the top-right header of S4 (or **`Mời bạn vào nhóm`**) to open S10 (`MembersView`).
   - Confirm the 4 members (`Minh`, `Lan`, `Hùng`, `Thu`) with their shapes and colors, the **`Thêm một cái tên`** input, and the **`Link mời`** card with QR code, **`Sao chép link`**, **`Chia sẻ`**, **`Đổi link mới`**, and the active toggle.
   - Tap a member row to rename or adjust default share weight (`Phần mặc định`), then tap **`Lưu`**.
4. **Quick entry & manual entry of T1–T4 (S4 → S7 / S8 → S5):**
   - Open the Debug Panel, select **`trip (step 0)`**, and open the group **`Đà Lạt 3N2Đ`**.
   - Tap **`Gõ một khoản chi...`** to open Quick Entry (S7):
     - Type **`lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều`** → confirm the confirmation card shows **`300.000 đ`**, **`Minh trả`**, **`Riêng: Minh 80 · Lan 60 · Hùng 40`**, **`Còn 120.000 chia đều 3`**, and member shapes **`Minh 120.000`**, **`Lan 100.000`**, **`Hùng 80.000`**. Tap **`Lưu`**.
     - Open S5 (`Thu về` on the yellow balance card) → confirm balances match step 1 (`Minh +180.000`, `Lan −100.000`, `Hùng −80.000`, `Thu 0`).
   - Try the `needs_input` and `unparsed` sentences in S7:
     - Type **`cà phê 180k chia 3`** → confirm the 3-person picker (`3 người nào?`, `Chọn thêm 3 người`) appears; select 3 people and confirm the share preview updates to `60.000` each.
     - Type **`180k`** → confirm the prompt `Khoản này chi cho việc gì?` appears.
     - Type **`cà phê`** or **`cà phê 180k chia 9`** → confirm automatic transition to S8 (`ExpenseFormView`) with the yellow `Mình chưa hiểu hết câu này` banner.
5. **Edit, conflict, and delete with undo (S4 → S8):**
   - Open the Debug Panel, select **`trip (step 4)`**, and tap any expense bubble on S4 to open S8 (` Sửa khoản chi`).
   - Tap **`Theo số tiền · đổi cách chia`** to open the Split Editor (`Đều`, `Số tiền`, `Phần`, `%`).
   - Tap **`Xoá khoản này`** at the bottom of S8 → confirm return to S4 with the **`Đã xoá. Hoàn tác`** toast; tap **`Hoàn tác`** → confirm the transaction and step 4 balance (`500.001 đ`) are restored.
6. **Settle debts (S5 → S9 → S5):**
   - On S4 (`trip (step 4)`), tap **`Thu về`** to open S5 (`BalancesView`).
   - Confirm the 3 suggested transfers (`Thu trả bạn 210.000`, `Hùng trả bạn 170.001`, `Lan trả bạn 120.000`) and the 4 balance bars (`Minh +500.001`, `Lan −120.000`, `Hùng −170.001`, `Thu −210.000`).
   - Tap **`Đã nhận`** on each of the 3 transfers and tap **`Ghi nhận ...`** on S9 (`SettleView`) → confirm S5 transitions to the **`Cả nhóm đã xong. Không ai nợ ai.`** (`AllSettled`) state with the 3 recorded transfers listed.

## By screen

### S1 — Sign-In, Register, Forgot Password (`AuthFeature`)
1. Verify **`Đăng nhập với Apple`** is above **`Tiếp tục với Google`**.
2. In the Debug Panel, set Failure to **`Rate limited (429)`** and submit sign-in → confirm **`Bạn thử quá nhiều lần. Đợi một lúc rồi thử lại.`**.
3. Tap **`Chưa có tài khoản? Tạo tài khoản`**, fill name/email/password (≥ 10 characters), submit → confirm **`Kiểm tra hộp thư của bạn`**.
4. Tap **`Quên mật khẩu?`**, enter an email, submit → confirm **`Nếu email này có tài khoản, link đặt lại đã được gửi. Link có hiệu lực trong 1 giờ.`**.

### S2 — Group List (`GroupsFeature/GroupList`)
1. Toggle **`Latency: 2 s`** and **`Snapshot: Off`** in the Debug Panel → confirm loading skeleton.
2. Toggle **`Failure: Offline`** with **`Snapshot: Off`** → confirm `LoadError` with **`Thử lại`**.
3. Toggle **`Failure: Offline`** with **`Snapshot: On`** → confirm the group card stays on screen, the **`Mất mạng. Bạn vẫn xem được sổ.`** banner appears at the top, and **`Tạo nhóm`** is disabled.

### S3 — Create Group (`GroupsFeature/CreateGroup`)
1. Leave group name empty → confirm **`Tạo nhóm`** is disabled.
2. Add and remove member rows; double-tap **`Tạo nhóm`** → confirm only one group is created.

### S4 — Group Stream (`LedgerFeature/GroupFeed`)
1. In the Debug Panel, switch Role to **`Viewer`** → confirm the bottom entry bar becomes **`Chỉ xem`** and **`Mời bạn vào nhóm`** is hidden.
2. Switch Role back to **`Owner`** and set Failure to **`Offline`** (with Snapshot On) → confirm the bottom entry bar becomes **`Có mạng lại là gõ tiếp được`**.
3. Scroll up the feed, open the Debug Panel, and tap **`Emit changed`** → confirm the floating **`Có khoản mới`** pill appears; tap it to scroll to the newest item.
4. Open the Debug Panel and tap **`Emit removed`** → confirm navigation pops to S2 with the notice **`Bạn không còn ở trong nhóm này.`**.
5. Switch Scenario to **`large`** → scroll up through the 500 transactions and confirm smooth pagination in 50-item pages.

### S5 — Balances (`LedgerFeature/Balances`)
1. Compare all amounts on `trip (step 4)` with the web app (`Minh +500.001`, `Lan −120.000`, `Hùng −170.001`, `Thu −210.000`; transfers `210.000`, `170.001`, `120.000`).
2. Switch Role to **`Viewer`** → confirm **`Đã nhận`** / **`Ghi nhận`** buttons are hidden.

### S6 — Activity History (`LedgerFeature/Activity`)
1. Open S10 (`MembersView`) and tap **`Lịch sử`** in the header to open S6.
2. Delete transaction T4 on S8, then open S6 → confirm the top entry shows **`Minh xoá Vé · 99.999 đ`** with a **`Khôi phục`** button; tap **`Khôi phục`** to restore it.

### S7 — Quick Entry (`LedgerFeature/QuickEntry`)
1. Test the 10 fixture sentences (`docs/08-quick-entry-samples.md`) and confirm highlight colors (`phrase-amount`, `phrase-payer`, `phrase-split`, `phrase-rest`) and confirmation cards match the web app.

### S8 — Expense Form & Split Editor (`LedgerFeature/ExpenseForm`, `SplitEditor`)
1. Tap the **`000`** button next to the amount input → confirm three zeros are appended and dot grouping updates live.
2. While Latency is set to **`2 s`**, toggle a sharer → confirm existing share amounts dim while the preview call is pending and are never replaced by a local estimate; if an unscripted amount is entered, confirm **`Không tải được dữ liệu. Kiểm tra mạng rồi thử lại.`** is shown instead of a guess.

### S9 — Settle (`LedgerFeature/Settle`)
1. Confirm **`Sau khoản này {name} không còn nợ ai`** is shown when the amount equals the member's full debt, and disappears when edited to a partial amount.
2. Switch between **`Hôm nay`**, **`Hôm qua`**, and **`Ngày khác`**.

### S10, S11, S12, S13 — Members, Group Settings, Join, Account
1. On S11 (`GroupSettingsView`), test **`Gộp nợ thông minh`** and **`Quyền mặc định khi vào bằng link`** switches, and tap **`Xoá nhóm vĩnh viễn`** → confirm the sheet requires typing the exact group name **`Đà Lạt 3N2Đ`** before **`Xoá nhóm vĩnh viễn`** is enabled.
2. In the Debug Panel, tap **`Open Join (valid token)`** and **`Open Join (invalid token)`** to verify S12 (`JoinView`).
3. On S2, tap the `M` avatar in the top-right header to open S13 (`AccountView`); test password change validation, delete account email confirmation, and **`Đăng xuất`**.

## Accessibility & Reduce Motion

1. In Simulator **Settings → Accessibility → Display & Text Size → Larger Text**, drag the slider to the largest accessibility size (`AX5`), and in **Settings → Accessibility → Motion**, turn on **Reduce Motion**.
2. Walk the `trip` journey again → confirm every screen scrolls without clipped or overlapping text and that card/shape spring animations are disabled when Reduce Motion is on.
