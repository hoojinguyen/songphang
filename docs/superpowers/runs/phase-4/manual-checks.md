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
