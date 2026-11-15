# Phase 4 — Stage 4B: Notifications and Reminders

> Part of the phase 4 plan. Read `00-overview.md` first.

**Stage goal:** each person is told about what concerns them, in the application and by mail they can switch off, and debts are reminded by the application.

**Spec:** sections 4, 7.2–7.4, 8.

## Decisions for this stage

1. Payload shapes are one Zod union in `contract`, discriminated on `kind`; every payload carries `actorName`, `groupName` and the ids needed to link to the right screen.
2. A user with no linked member in a group receives nothing that is addressed "through the member".
3. Several notifications of kind `comment_added` on one transaction within 10 minutes for one recipient are kept as separate rows; the digest groups them by transaction.
4. The digest mail lists at most 20 lines, then `và {count} cập nhật khác`.
5. Reminder times: the manual limit is a rolling 24 hours per ordered pair, whoever pressed.

---

### Task 4B.1: Notification core

**Files:**
- Create: `packages/db/src/schema-notifications.ts`, `packages/db/src/notifications.ts`, `packages/contract/src/notification.ts`, `apps/api/src/services/notify.ts`, `apps/api/src/services/notifications.ts`, `apps/api/src/routes/notifications.ts`, a migration
- Modify: `packages/db/src/schema-groups.ts` (`group_users.muted`), the services for transactions, comments, disputes, and (when phase 2 is merged) settlement requests and budget, `apps/api/src/routes/groups.ts` (the `muted` route), `apps/api/src/app.ts`

**Interfaces — produces:**
- Tables `notifications` and `notification_settings` as spec 4.1.
- `NotificationPayload` (Zod union) and `NotificationDto`: `{ id, kind, groupId, payload, read: boolean, createdAt }`.
- `notify(tx, input: { groupId: string; actorUserId: string | null; kind; payload; toUserIds?: string[]; toMemberIds?: string[] })` — resolves members to users through `group_users`, removes the actor, removes muted users, removes duplicates, inserts the rows in `tx`. It is the only writer of the table. Services call it inside their existing transaction.
- Recipients per kind: the table of spec 4.2. `expense_added` payload carries, per recipient, `share` (their share) so the line of 7.2 needs no query.
- `GET /me/notifications` (inner join on `group_users` for the caller; newest first; cursor), `GET /me/notifications/unread-count` → `{ count }` (same join), `POST /me/notifications/read` (`{ ids: uuid[] (1–100) }` or `{ all: true }`; affects only the caller's rows), `PUT /groups/{groupId}/me/muted` (`{ muted: boolean }`; viewer).
- The SSE stream gains nothing; mutating services already emit their resources.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1)** — fresh group with the role set-up.

| Action | Expected notifications |
|---|---|
| Minh adds an expense shared by Minh, Lan, Hùng, Thu | Lan and Hùng one each with their `share`; none for Minh; none for Thu (no user) |
| Lan edits it | Minh and Hùng `expense_changed` |
| Hùng comments | Minh (creator), Lan (in it) |
| Lan comments | Minh, Hùng |
| Hùng opens a dispute | Minh (creator and owner, once) |
| Hùng mutes the group; Minh adds another expense | Lan only |
| Minh removes Hùng from the group | Hùng's `GET /me/notifications` no longer contains this group; unread count excludes them |
| Hùng `POST …/read` with one of Lan's notification ids | 204; Lan's row is still unread |
| signed out | 401 on every `/me/notifications` route |

Force a failure after `notify` inside the expense service (throw in a scratch edit, then revert) → neither the expense nor the notification exists.

- [ ] **Step 4: Commit** — `feat(api): add notifications`

---

### Task 4B.2: Web — bell and notification list

**Files:**
- Create: `apps/web/src/app/notifications/page.tsx`, `apps/web/src/components/notifications/Bell.tsx`, `apps/web/src/components/notifications/NotificationRow.tsx`, `apps/web/src/lib/notifications.ts`, `apps/web/src/lib/notification-text.ts`
- Modify: the headers of S2 and S4, the group menu (`Tắt thông báo nhóm này`), `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`

Strings: spec section 7.2 and the group-menu line of 7.3.

**Interfaces — produces:** `notificationText(dto): { text: string; href: string }` — one function mapping every kind to its line and its target (the transaction view, S5, or S16). An unknown kind returns a generic `Có cập nhật trong nhóm {group}` and the group's address.

Behavior: the bell is a 44-point button with a count badge (hidden at 0, `9+` above 9); the count refetches on window focus and on any group SSE event. Opening a row marks it read and navigates. Unread rows have the `sunken` background.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in two browser windows** — each kind of 4B.1's table shows its exact line; the badge updates without reload while a group is open; `Đánh dấu đã đọc`; mute and unmute.
- [ ] **Step 4: Commit** — `feat(web): add notification bell and list`

---

### Task 4B.3: Mail — immediate, digest, unsubscribe

**Files:**
- Create: `apps/worker/src/jobs/send-notification-mail.ts`, `apps/worker/src/jobs/send-digest.ts`, `apps/worker/src/jobs/prune-notifications.ts`, `apps/worker/src/mailer.ts` (the worker's use of the shared mailer; move the mailer and templates to `packages/mail` if both apps now need them, and record it), `apps/api/src/routes/unsubscribe.ts`, `apps/web/src/app/notifications/unsubscribe/page.tsx`
- Modify: `apps/api/src/mail-templates.ts`, `apps/api/src/services/notify.ts` (enqueue the immediate job after commit), `apps/api/src/services/notifications.ts`, `packages/contract/src/jobs.ts`, the account screen (the mail card of 7.3), `apps/web/src/messages/vi.ts`

**Interfaces — produces:**
- `GET /me/notification-settings` → `{ emailImmediate, emailDigest }`; `PUT` the same.
- Unsubscribe token: 32 random bytes, base64url; `notification_settings.unsubscribe_token_hash` = its SHA-256; created on first mail and reused. `POST /notifications/unsubscribe` (`{ token }`; public; 30 per minute per IP): a matching hash sets both switches false and answers 204; anything else answers 404. It reveals nothing about the user.
- Immediate job, per notification: skip when read, when the user left the group, when `emailImmediate` is false, or when the user's email is unverified; else send. Subject = the notification's line; body = the line, a button `Mở Sòng Phẳng` to its target, the footer of 7.2. Header `List-Unsubscribe: <{WEB_ORIGIN}/notifications/unsubscribe?token=…>` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click`.
- Digest job, daily at 20:00 Vietnam time: for each user with `emailDigest` true, unread digest-kind notifications created since the previous run, grouped by group then transaction; one mail; none when empty.
- Prune job, daily: delete notifications older than 90 days.
- The mailer's log line for a sent mail carries the template name and the user id, never the address or the body.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 2)** — console mailer; run jobs by hand.

| Action | Expected |
|---|---|
| Hùng opens a dispute | within a minute the console prints one mail to Minh with the subject `Hùng cho rằng {description} chưa đúng`, the footer, and both list headers |
| the same after Minh read the notification first | no mail |
| run the digest after Minh added two expenses and Lan commented | one mail to Lan with two lines, one to Hùng, one to Minh with the comment; a second run prints nothing |
| Minh sets `emailDigest` false; repeat | no digest for Minh |
| `POST /notifications/unsubscribe` signed out with the token from a printed mail | 204; both switches false for that user only |
| the same with one character changed | 404 |
| a user removed from the group before the immediate job runs (stop the worker, remove, start) | no mail |
| a notification dated 91 days back; run the prune | deleted |

- [ ] **Step 4: Commit** — `feat(worker): send notification mail, digests, and one-click unsubscribe`

---

### Task 4B.4: Debt reminders

**Files:**
- Create: `packages/db/src/schema-reminders.ts` (table `debt_reminders`: `id`, `group_id` cascade, `from_member_id`, `to_member_id`, `amount`, `sent_by` SET NULL — NULL for automatic, `created_at`; index `(group_id, from_member_id, to_member_id, created_at DESC)`), `packages/db/src/reminders.ts`, `apps/api/src/services/reminders.ts`, `apps/api/src/routes/reminders.ts`, `apps/worker/src/jobs/auto-reminders.ts`, a migration
- Modify: `packages/db/src/schema-groups.ts` (`groups.reminder_interval_days` with `CHECK (… IN (3, 7, 14))`), the group settings service and contract, `packages/contract/src/error.ts`, `packages/contract/src/jobs.ts`

`debt_reminders` is a table the spec did not name; it is the record the 24-hour and interval rules need. Record it in `decisions.md`.

**Interfaces — produces:**
- `POST /groups/{groupId}/reminders` (viewer + rule): `{ fromMemberId, toMemberId }` or `{ all: true }`. Allowed for a pair when the caller is linked to `toMemberId`, or is an editor or the owner. The pair must be a currently suggested transfer (else 400), `fromMemberId` must be linked to a user (else 422 `MEMBER_NOT_LINKED`), and no reminder for the pair may exist in the last 24 hours (else 429 `REMINDER_TOO_SOON` with `details.nextAt`). Success: insert the row and `notify` with kind `debt_reminder`, payload `{ toName, amount, groupName }`; answer `{ reminded: [{ fromMemberId, toMemberId }], skipped: [{ …, reason }] }`. With `all`, every pair the caller may remind is tried and failures go to `skipped` instead of failing the request.
- The amount in the reminder is the suggested transfer's amount at that moment, from the same `core` function the balances endpoint uses.
- Job `auto-reminders`, daily at 09:00 Vietnam time: for each group with an interval, each suggested transfer whose payer is linked and has no reminder within the interval gets one, with `sent_by` NULL and `actorUserId` null.
- `PATCH /groups/{groupId}` accepts `reminderIntervalDays: 3 | 7 | 14 | null` (owner).

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — group with the role set-up; expense 600000 by Minh, equal for four (Lan, Hùng, Thu each owe Minh 150000).

| Caller | Request | Expected |
|---|---|---|
| Minh | remind Hùng → Minh | 200; Hùng has a `debt_reminder` with amount 150000 |
| Minh | the same again | 429 `REMINDER_TOO_SOON`, `nextAt` 24 hours after the first |
| Lan (editor) | remind Hùng → Minh | 429 (the pair is limited whoever asks) |
| Minh | remind Thu → Minh | 422 `MEMBER_NOT_LINKED` |
| Hùng (viewer, the debtor) | remind Lan → Minh | 403 |
| Minh | `{ all: true }` | `reminded` Lan; `skipped` Hùng (`REMINDER_TOO_SOON`) and Thu (`MEMBER_NOT_LINKED`) |
| Minh | remind Minh → Lan (not a suggested transfer) | 400 |
| owner sets the interval to 3; date the existing reminders 4 days back; run the job | Lan and Hùng each get one; running it again gives none |
| Lan (editor) | set the interval | 403 |

- [ ] **Step 4: Commit** — `feat(api): add manual and automatic debt reminders`

---

### Task 4B.5: Web — reminders and settings; stage gate

**Files:**
- Modify: the balances screen's transfer row (`Nhắc`, `Nhắc cả nhóm một lần`), the settings page (`Tự nhắc nợ`), `apps/web/src/lib/reminders.ts` (new), `apps/web/src/messages/vi.ts`

Strings: spec sections 7.3 (reminder setting) and 7.4. `{time}` in the too-soon line is `nextAt` as `HH:mm` when it is today and `HH:mm ngày DD/MM` otherwise, Vietnam time.

Behavior: `Nhắc` is rendered on a suggested transfer only when the caller may remind that pair and the payer is linked. `Nhắc cả nhóm một lần` is rendered when at least two pairs qualify; its result line uses `reminded.length`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — remind, the too-soon line with the right time, remind all, the debtor's bell and notification line.
- [ ] **Step 4: Commit** — `feat(web): add debt reminders`
- [ ] **Step 5: Stage gate 4B.** Acceptance script: 4B.1 rows 1, 6, 7; 4B.3 rows 5, 6; 4B.4 rows 1, 2, 4. Then the gate of the common file.

**Manual checks for the project owner**
1. Two windows: add an expense as Minh → Lan's bell shows 1 with `Minh thêm … · phần bạn …`.
2. S5 → `Nhắc` on a debt → the debtor gets `Nhắc nhẹ: …`; pressing again says when you can remind next.
3. Find a notification mail in the API console, open its unsubscribe link in a private window → the page confirms; the account screen shows both switches off.
