# Phase 4 run — owner manual checks

Checks are appended by screen and flow as tasks complete, plus a section **After the Telegram bot token exists**.

## S20 — Transaction view, comments, and disputes (Stage 4A)

1. Open a group stream (`S4`) as an editor/owner and tap any expense row -> lands on `/g/{groupId}/tx/{txId}/view` showing the amount, payer, split breakdown, category, attachments, and `Sửa` in the header.
2. Tap `Sửa` -> opens the edit screen; tap `Quay lại` or `Huỷ` -> returns to `/view`.
3. Open the same transaction in a second browser window as a viewer member -> `Sửa` is hidden, while `Khoản này chưa đúng` and the comment input are active.
4. Type a comment and press `Enter` (use `Shift+Enter` for a newline) -> comment appears in both windows live via SSE without refreshing; send `<script>alert(1)</script>` -> displays as literal text with no alert.
5. Delete one of your own comments with `Xoá bình luận` -> removed from both windows live; verify a viewer cannot delete another member's comment (no delete button except author or group admin/owner).
6. Tap `Khoản này chưa đúng`, enter an empty/whitespace reason -> `Gửi` stays disabled; enter a reason and submit -> coral card appears (`{Name} cho rằng khoản này chưa đúng`), and the stream row shows the `đang hỏi lại` tag plus `{N} bình luận`.
7. Tap `Đã giải quyết` -> snackbar `Đã giải quyết.` appears, card returns to `Khoản này chưa đúng`, and `đang hỏi lại` disappears live from the stream row.

## S19 — Notification bell, list, and group mute (Stage 4B)

1. Sign in as a user with unread notifications -> the bell button in the S2 (`/`) and S4 (`/g/{groupId}`) headers shows the unread count (`9+` when above 9).
2. With S4 open in Window A, have another user add a comment or expense in Window B -> Window A's bell count updates live via SSE without refreshing.
3. Tap the bell -> opens `/notifications` (`S19`). Unread items have the `sunken` background and display the exact Spec 7.2 text (`{actor} thêm {description} · phần bạn {share}`, etc.).
4. Tap an unread item -> navigates directly to the transaction view, balances, or stats screen, and the item's unread count decreases by 1.
5. Tap `Đánh dấu đã đọc` -> all items become read, the button disables, and the bell badge disappears.
6. Open a group's members screen (`/g/{groupId}/members`) and toggle `Tắt thông báo nhóm này` on -> new expenses in that group create no notifications for you; toggle back off to resume.

## S13 & Unsubscribe — Email notifications and one-click unsubscribe (Stage 4B)

1. Open `/account` (`S13`) -> card `Thông báo qua email` shows `Việc cần bạn làm ngay` and `Tổng hợp cuối ngày` toggles; turn one off, refresh -> state persists.
2. With both worker and API running (`TELEGRAM_PROVIDER` unset, console mailer), have another member open a dispute -> worker console prints one mail with `List-Unsubscribe` / `List-Unsubscribe-Post: List-Unsubscribe=One-Click`, subject matching the notification line, `Mở Sòng Phẳng`, and footer `Không muốn nhận thư nữa? Bỏ đăng ký`.
3. Copy the `/notifications/unsubscribe?token=...` URL from the printed mail and open it in an unauthenticated/private browser window -> confirms `Bạn sẽ không nhận thư thông báo nữa.` with link `Bật lại trong Tài khoản`. Opening `/account` shows both email switches off; alter 1 character of `token` -> renders `Link này không còn dùng được.`.

## S5 & S11 — Debt reminders and auto-reminder settings (Stage 4B)

1. In a group with >= 2 linked debtor transfers and 1 unlinked debtor (`Thu`), open `/g/{id}/balances` as a linked member -> verify `Nhắc` is shown next to `Đã trả` for linked debtors, hidden for `Thu`, and `Nhắc cả nhóm một lần` appears.
2. Click `Nhắc` on `Hùng` -> snackbar shows `Đã nhắc Hùng.` and `Hùng`'s `/notifications` displays `Nhắc nhẹ: bạn cần trả Minh ...`.
3. Click `Nhắc` on `Hùng` again immediately -> snackbar shows `Bạn vừa nhắc Hùng rồi. Nhắc lại được sau {giờ} ngày {ngày}.`.
4. Click `Nhắc cả nhóm một lần` -> snackbar shows `Đã nhắc 1 người.` (or `Chưa đến lúc nhắc lại ai.` when all pairs are within 24 hours).
5. As owner, open `/g/{id}/settings` under `Tự nhắc nợ`, select `Mỗi tuần`, reload the page -> `Mỗi tuần` stays pressed (`PATCH /groups/{id}` persisted `reminderIntervalDays: 7`).

## S11, S13, `/link/telegram`, and `?form&text=` — Telegram linking web flows (Stage 4C)

1. When `TELEGRAM_PROVIDER` is enabled, open `/g/{id}/settings` as owner -> `Liên kết nhóm Telegram` appears with `Tạo mã liên kết`; click to generate a monospace `/lienket XXXXXXXX` command and copy with `Sao chép`.
2. Open `/link/telegram` while signed out -> redirects through `/login?next=%2Flink%2Ftelegram`. After signing in with a verified account, `/link/telegram` asks `Liên kết Telegram với tài khoản {email}?` and clicking `Bắt đầu liên kết` produces a deep link `Mở Telegram @{bot}` and a one-time `/start pair_...` command (10-minute TTL). Open a private chat with the bot (not a group chat), send `/start pair_...` -> bot replies with your display name and masked email plus `Xác nhận liên kết` / `Huỷ`; tapping `Xác nhận liên kết` updates the browser to show your staged Telegram name/ID and `Hoàn tất liên kết`; clicking `Hoàn tất liên kết` completes the link (`Đã liên kết. Quay lại Telegram để tiếp tục.`). Also check invalid cases: opening an old `/link/telegram?code=TEST` link immediately shows `Link này không còn dùng được.`; sending `/start pair_...` in a group chat is refused without echoing the secret and invalidates that pairing attempt.
3. Open `/account` -> `Telegram` card shows `Đã liên kết với Telegram`; clicking `Bỏ liên kết` removes it. Returning to `/g/{id}/settings` shows linked chat IDs and clicking `Bỏ liên kết` unlinks them.
4. Open `/g/{id}/tx/new?form&text=abc%20xyz` -> `Mô tả` input is prefilled with `abc xyz`.

## S11 & S20 — Expense approval above a threshold (Stage 4D)

1. Open `/g/{id}/settings` as group owner -> enable `Duyệt khoản chi lớn`, enter `1.000.000` in `Từ số tiền`, confirm hint `Khoản chi từ mức này chỉ được tính sau khi bạn duyệt.`, and tap `Lưu`.
2. Switch to a linked editor (`Lan`) and save an expense for `1.200.000 đ` -> snackbar shows `Đã lưu. Khoản này chờ Minh duyệt.`, stream row is dimmed with `chờ duyệt`, and group balances remain unchanged.
3. As owner (`Minh`), tap the notification bell -> tap `{Actor} thêm {desc} · 1.200.000 đ, cần bạn duyệt` -> lands on S20 showing `Khoản này chờ Minh duyệt. Chưa tính vào số dư.` with `Duyệt` and `Không duyệt` (hidden for non-owners).
4. Tap `Duyệt` -> approval block and `chờ duyệt` tag clear immediately and balances/SSE streams update across open windows; confirm approving again is rejected cleanly if triggered concurrently.
5. As editor (`Lan`), edit the approved expense on S20 (`Sửa`) to `1.500.000 đ` -> returns to `chờ duyệt` and clears balances until re-approved.
6. As owner (`Minh`), tap `Không duyệt` on S20 -> dialog `Vì sao không duyệt?` opens with optional `Ghi chú` -> submit with or without a note -> S20 shows `Minh không duyệt khoản này.` (+ note if entered) and stream rows show `không được duyệt`.

## After the Telegram bot exists

1. In a real Telegram group linked via `/lienket <code>`: send `/chi cà phê 180k chia 4` -> bot replies with split breakdown and `Lưu` / `Bỏ` buttons -> tap `Lưu` -> web app expense list updates within 2 seconds.
2. A friend who has not linked their Sòng Phẳng account runs `/chi ...` -> receives `Mình chưa biết bạn là ai trên Sòng Phẳng.` with `Liên kết tài khoản` button opening `/link/telegram` (containing no code/secret), and nothing is saved. Following the private `/start pair_...` -> Telegram `Xác nhận liên kết` -> browser `Hoàn tất liên kết` flow activates their identity without allowing any other user or group chat to hijack it.
3. Another person taps your `Lưu` button -> rejected with `Chỉ {tên bạn} lưu được khoản này.` and nothing is saved.
