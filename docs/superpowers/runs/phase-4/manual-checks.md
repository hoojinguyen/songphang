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
