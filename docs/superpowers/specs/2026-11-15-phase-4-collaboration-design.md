# Phase 4 — Collaboration ("Cộng tác") — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` first; its sections 4, 5 and 6 apply here.

## 1. Intent

Until now, questions about an expense and reminders to pay happen in a chat application, outside the ledger. Phase 4 brings both in: people discuss and dispute an expense where it is, are told about what concerns them, are reminded of debts by the application instead of by a friend, and add expenses from their Telegram group.

**Goals:** US-4.1 to US-4.5. Roadmap target: a real group adds expenses through Telegram for a week without opening the web app.

**Non-goals:** a general chat; push notifications (phase 5); Zalo (closed by the survey); the bot answering free questions; approval chains with several approvers.

**Anti-goals:** a notification that leaks a group's data to someone who has left it; mail that cannot be switched off; a bot that saves an expense nobody confirmed; anyone in a Telegram chat acting with another person's rights.

## 2. Scope and stages

| Stage | Adds | SRS |
|---|---|---|
| 4A | Comments and disputes on a transaction | FR-4.1, 4.2 |
| 4B | Notifications in the application and by mail; debt reminders | FR-4.4, 4.7 |
| 4C | Telegram bot: link a chat, add an expense, ask for balances | FR-4.5 |
| 4D | Approval of expenses above a threshold | FR-4.3 |

**Not built:** 4E, the Zalo bot.

**Depends on:** the worker and queue of stage 3A (reminders, mail digests). **No new library:** the Telegram Bot API is called with `fetch`.

## 3. Comments and disputes (4A)

### 3.1 Data

`comments`: `id`, `group_id` (cascade), `transaction_id` (FK, cascade), `author_user_id` (FK users, SET NULL), `author_name` (the display name at the time of writing), `body` (1–1,000 characters), `created_at`, `deleted_at`.

`transaction_disputes`: `id`, `group_id` (cascade), `transaction_id` (FK, cascade), `reason` (1–500), `opened_by` (SET NULL), `opened_by_name`, `opened_at`, `resolved_by` (SET NULL), `resolved_at`. Partial unique index on `(transaction_id) WHERE resolved_at IS NULL`.

### 3.2 Rules

- **Every user of the group may comment and may open a dispute, viewers included.** A viewer cannot edit, so speaking up is the only thing they can do about a wrong expense.
- A comment can be deleted by its author or the owner. Comments are not editable.
- A dispute is resolved by the person who opened it or by the owner. Editing the transaction does not resolve it; the resolver decides.
- **A disputed expense still counts in balances.** Excluding it would let anyone freeze a debt by objecting. The dispute is a mark, shown wherever the transaction is shown.
- Comments stay readable on a deleted transaction and return when it is restored.
- Transaction objects gain `commentCount` and `dispute: { id, reason, openedByName, openedAt } | null`.
- Write limit: the general write limit, plus 20 comments per minute per user.

### 3.3 Endpoints

| Method | Path | Minimum role |
|---|---|---|
| GET, POST | `/groups/{groupId}/transactions/{id}/comments` | Viewer |
| DELETE | `…/comments/{commentId}` | Viewer + author or owner |
| POST | `/groups/{groupId}/transactions/{id}/dispute` (`{ reason }`) | Viewer |
| POST | `…/dispute/resolve` | Viewer + opener or owner |

SSE resource name: `comments`. Opening and resolving a dispute also emit `transactions` and write the activity log.

## 4. Notifications (4B)

### 4.1 Data

`notifications`: `id`, `user_id` (FK, cascade), `group_id` (FK, cascade), `kind`, `payload jsonb`, `read_at`, `created_at`. Index `(user_id, created_at DESC)`. Rows older than 90 days are deleted by a daily job.

`notification_settings`: `user_id` (PK, cascade), `email_immediate boolean DEFAULT true`, `email_digest boolean DEFAULT true`, `unsubscribe_token_hash text UNIQUE`.

`group_users` gains `muted boolean NOT NULL DEFAULT false`: a muted group creates no notification for that user.

### 4.2 Kinds

A notification goes to users, found through the member linked to them. The actor never notifies themself.

| Kind | Recipients | Mail |
|---|---|---|
| `expense_added` | Users whose member has a share or is a payer | Digest |
| `expense_changed` (edited or deleted) | Same, by the previous or the new shares | Digest |
| `comment_added` | The transaction's creator, earlier commenters, users whose member is in it | Digest |
| `dispute_opened`, `dispute_resolved` | The transaction's creator, the owner, the opener | Immediate |
| `settlement_requested` (needs phase 2) | The user of the receiving member | Immediate |
| `settlement_confirmed`, `settlement_rejected` (needs phase 2) | The user of the paying member | Immediate |
| `debt_reminder` | The user of the owing member | Immediate |
| `approval_requested` (4D) | The owner | Immediate |
| `approval_decided` (4D) | The transaction's creator | Immediate |
| `budget_state` (needs phase 2; on entering `near` or `over`) | The owner | Digest |

`payload` holds ids, names and amounts as they were when the event happened, enough to render the line without another query.

**Losing access.** The list endpoint joins `group_users`, so a user who left or was removed sees none of that group's notifications from then on, and mail jobs check membership again at send time.

### 4.3 Creation and delivery

- A notification row is inserted **in the same database transaction** as the change that causes it, by one function the services call. Delivery is separate.
- **In the application:** a bell on S2 and S4 with an unread count; a list screen (S19). The count is refetched on window focus and whenever a group SSE event arrives. No new stream.
- **Immediate mail:** a job per notification, sent within a minute, skipped when the notification was read meanwhile.
- **Digest mail:** one job at 20:00 `Asia/Ho_Chi_Minh` gathers each user's unread digest-kind notifications of the day into one mail per user. Nothing unread, no mail.
- Every mail ends with a one-click unsubscribe link (`/notifications/unsubscribe?token=…`, no sign-in needed; only the token's SHA-256 is stored) and carries the `List-Unsubscribe` header. Unsubscribing turns both mail switches off.
- Mail goes through the existing `Mailer`: the console locally, SMTP after the server step.

### 4.4 Endpoints

| Method | Path | Who |
|---|---|---|
| GET | `/me/notifications?cursor=` | Signed in |
| GET | `/me/notifications/unread-count` | Signed in |
| POST | `/me/notifications/read` (`{ ids }` or `{ all: true }`) | Signed in |
| GET, PUT | `/me/notification-settings` | Signed in |
| POST | `/notifications/unsubscribe` (`{ token }`) | Public |
| PUT | `/groups/{groupId}/me/muted` (`{ muted }`) | Viewer |

### 4.5 Debt reminders (FR-4.7)

- **Manual:** on a suggested transfer, the user of the receiving member, an editor or the owner presses Nhắc. It creates a `debt_reminder` for the user of the paying member. One reminder per pair per 24 hours (429 `REMINDER_TOO_SOON` with the time of the next allowed one). A paying member linked to nobody cannot be reminded (422 `MEMBER_NOT_LINKED`); the button is hidden for them.
- **Automatic:** `groups` gains `reminder_interval_days integer` (NULL, 3, 7 or 14; owner sets it). A daily job at 09:00 Vietnam time computes each such group's suggested transfers through `core` and reminds every paying member who has not been reminded within the interval.
- "Nhắc cả nhóm một lần" (mockup GE5) sends the manual reminder for every suggested transfer the caller may remind, skipping pairs inside their 24 hours.
- `POST /groups/{groupId}/reminders` (`{ fromMemberId, toMemberId }` or `{ all: true }`), viewer plus the rule above.

## 5. Telegram bot (4C)

### 5.1 Shape

One bot for the whole installation. `ChatSender` interface: `send(chatId, text, buttons?)`, `answerCallback(id, text?)`. Adapters: `telegram` (needs `TELEGRAM_BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET`, `TELEGRAM_BOT_USERNAME`) and `console`. Unset: `features.telegram` is false and the webhook answers 404.

Inbound: `POST /api/v1/bots/telegram/webhook`. The header `X-Telegram-Bot-Api-Secret-Token` is compared with the secret using a constant-time comparison; a mismatch answers 404. The body is validated with a Zod schema covering only the fields used. The route answers 200 quickly and never echoes an internal error to Telegram. It is exempt from the same-origin check and has its own limit: 30 updates per minute per chat.

Registering the webhook with Telegram is a runbook step for the owner (it needs a public HTTPS address, so it follows the server step).

### 5.2 Data

`chat_links`: `id`, `group_id` (cascade), `platform` (`'telegram'`), `chat_id text`, `linked_by` (SET NULL), `created_at`. `UNIQUE (platform, chat_id)`: one chat serves one group; a group may have several chats.

`chat_identities`: `platform`, `platform_user_id text`, `user_id` (FK, cascade), `created_at`. Primary key `(platform, platform_user_id)`.

`chat_link_codes`: `code_hash` (PK), `purpose` (`'group'` or `'user'`), `group_id` or `platform_user_id`, `created_by`, `expires_at`, `used_at`. Codes live 10 minutes and work once.

`bot_drafts`: `id`, `chat_link_id` (cascade), `user_id` (cascade), `draft jsonb`, `expires_at` (10 minutes), `saved_transaction_id`.

### 5.3 Linking

- **A chat to a group:** the owner opens group settings, presses the button, and gets a command to paste into the Telegram group: `/lienket 8-character-code`. The bot checks the code and replies.
- **A Telegram account to an application account:** anyone who uses a command while unknown gets a reply with a button that opens `{WEB_ORIGIN}/link/telegram?code=…`. Signed in there, they confirm; the code binds their Telegram id to their account. One Telegram account maps to one application account.
- The owner can unlink a chat; a user can unlink their Telegram account on the account screen.

### 5.4 Acting

Every command runs **as the application user linked to the sender**, through the same services and the same role check as the web app. A sender who is not linked, or who is not in the chat's group, can do nothing. A viewer can ask but not add.

| Command | Does |
|---|---|
| `/chi <câu>` | Reads the sentence with the same reader as the typing box (rules, then AI if phase 3 is present). Replies with the summary and two buttons |
| `/sodu` | Replies with each person's balance and the suggested transfers |
| `/lienket <mã>` | Links the chat |
| `/huy` | Deletes the last expense the sender saved through the bot in this chat, if within 10 minutes |
| `/trogiup`, `/start` | Lists the commands |

Text that is not a command is ignored: the bot runs in Telegram's privacy mode and does not receive it.

**Saving needs a tap (the principle of FR-1.98).** `/chi` stores a draft and replies; only the sender's tap on Lưu creates the transaction, with the draft's id as the idempotency key, so a double tap saves once. Anyone else tapping gets a short refusal. A sentence that is `needs_input` or `unparsed` is not saved; the bot says what it did not understand and gives a link to the form with the sentence prefilled.

Messages from the bot contain only what a member of that group may see, and are sent only to the linked chat.

### 5.5 Strings (final)

| Situation | Reply |
|---|---|
| Chat linked | `Đã liên kết nhóm chat này với sổ "{group}". Gõ /chi rồi khoản chi, ví dụ: /chi cà phê 180k chia 4` |
| Bad or expired code | `Mã liên kết không đúng hoặc đã hết hạn. Hãy lấy mã mới trong cài đặt nhóm.` |
| Chat not linked | `Nhóm chat này chưa liên kết với sổ nào. Chủ nhóm lấy mã trong cài đặt nhóm trên Sòng Phẳng.` |
| Sender not linked | `Mình chưa biết bạn là ai trên Sòng Phẳng.` with button `Liên kết tài khoản` |
| Sender not in the group | `Bạn chưa ở trong sổ "{group}".` |
| Viewer tries to add | `Bạn chỉ có quyền xem sổ này.` |
| Draft | `{description} · {amount}` / `{payer} trả` / one line per person `{name}: {share}` with buttons `Lưu` · `Bỏ` |
| Saved | `Đã lưu: {description} · {amount}.` |
| Dropped | `Đã bỏ.` |
| Draft expired | `Khoản này đã quá 10 phút. Hãy gõ lại.` |
| Someone else taps | `Chỉ {name} lưu được khoản này.` |
| Not understood | `Mình chưa đọc được câu này: {issue}.` with button `Mở form` |
| `/chi` with nothing | `Gõ khoản chi sau /chi, ví dụ: /chi lẩu 600k chia 4` |
| `/sodu` | `Sổ "{group}"` / one line per person `{name}: được nhận {amount}` or `cần trả {amount}` or `đã xong` / then `{from} → {to}: {amount}` per transfer |
| `/huy` done | `Đã xoá: {description} · {amount}.` |
| `/huy` nothing | `Không có khoản nào của bạn trong 10 phút qua.` |
| `/trogiup` | `/chi <khoản chi> — thêm khoản chi` / `/sodu — xem ai nợ ai` / `/huy — xoá khoản bạn vừa thêm` |
| Too many messages | `Chậm lại một chút nhé.` |

## 6. Approval above a threshold (4D)

- `groups` gains `approval_threshold bigint` (NULL is off; owner sets it).
- `transactions` gains `approval_status text NOT NULL DEFAULT 'none'` (`'none'`, `'pending'`, `'approved'`, `'rejected'`), `approval_decided_by` (SET NULL), `approval_decided_at`, `approval_note text` (0–300).
- An **expense** of at least the threshold, created or edited by someone who is not the owner, becomes `pending`. Transfers and income never need approval. The owner's own expenses are `none`.
- **A pending or rejected expense does not count.** The balance query, the pairwise-debt query, statistics, the budget, the CSV export and `db:check-balances` all filter on `approval_status IN ('none', 'approved')`. This is the one change to the money path in this phase; the gate proves balances still sum to 0 with a pending expense present.
- The owner approves or rejects, with an optional note. A rejected expense stays visible to the group, marked, and can be edited by an editor, which makes it pending again. Editing an approved expense so that it still meets the threshold makes it pending again; lowering it below the threshold makes it `none`.
- `POST /groups/{groupId}/transactions/{id}/approve` and `…/reject` (`{ note? }`): owner. Changing the threshold does not re-evaluate existing transactions.

## 7. Screens

Strings are final.

### 7.1 Transaction detail (S20, `/g/{id}/tx/{txId}/view`)

New: until now tapping an expense opened the edit form. From this phase it opens a read view, the same for every role: the confirmation card's content, the photo marks of phase 3, the dispute block, the approval block, the comment thread, and a comment field at the bottom. `Sửa` in the header opens the form for those who may edit.

| Element | String |
|---|---|
| Comment field | `Viết bình luận…` |
| Send | `Gửi` |
| No comments | `Chưa có bình luận` |
| Delete own comment | `Xoá bình luận` |
| Open a dispute | `Khoản này chưa đúng` |
| Dispute dialog | `Khoản này chưa đúng ở đâu?` · field `Lý do` · `Gửi` · `Thôi` |
| Disputed block | `{name} cho rằng khoản này chưa đúng` / the reason / button `Đã giải quyết` (opener and owner) |
| Tag in the stream | `đang hỏi lại` |
| Resolved | `Đã giải quyết.` |
| Comment count in the stream | the number beside a speech mark, read as `{count} bình luận` |

### 7.2 Notifications (S19, `/notifications`)

| Element | String |
|---|---|
| Title | `Thông báo` |
| Mark all | `Đánh dấu đã đọc` |
| Empty | `Chưa có thông báo nào` |
| `expense_added` | `{actor} thêm {description} · phần bạn {share}` |
| `expense_changed` | `{actor} đã sửa {description}` or `{actor} đã xoá {description}` |
| `comment_added` | `{actor} bình luận về {description}` |
| `dispute_opened` | `{actor} cho rằng {description} chưa đúng` |
| `dispute_resolved` | `{actor} đã giải quyết {description}` |
| `settlement_requested` | `{actor} báo đã chuyển cho bạn {amount}` |
| `settlement_confirmed` | `{actor} đã xác nhận nhận {amount}` |
| `settlement_rejected` | `{actor} báo chưa nhận được {amount}` |
| `debt_reminder` | `Nhắc nhẹ: bạn cần trả {to} {amount} trong nhóm {group}` |
| `approval_requested` | `{actor} thêm {description} · {amount}, cần bạn duyệt` |
| `approval_decided` | `{actor} đã duyệt {description}` or `{actor} không duyệt {description}` |
| `budget_state` | `Nhóm {group} sắp chạm hạn mức` or `Nhóm {group} đã vượt hạn mức` |

Mail subjects use the same lines; the digest's subject is `Hôm nay trong các nhóm của bạn`. The mail footer reads `Không muốn nhận thư nữa? Bỏ đăng ký`, and the unsubscribe page says `Bạn sẽ không nhận thư thông báo nữa.` with a link `Bật lại trong Tài khoản`.

### 7.3 Account and group settings

| Place | String |
|---|---|
| Account (S13), new card | `Thông báo qua email` · `Việc cần bạn làm ngay` · `Tổng hợp cuối ngày` |
| Account, Telegram card | `Telegram` · `Đã liên kết với {name}` · `Bỏ liên kết` |
| Group menu | `Tắt thông báo nhóm này` |
| Settings (S11), reminders | `Tự nhắc nợ` · `Tắt` · `Mỗi 3 ngày` · `Mỗi tuần` · `Mỗi 2 tuần` |
| Settings, approval | `Duyệt khoản chi lớn` · `Từ số tiền` · hint `Khoản chi từ mức này chỉ được tính sau khi bạn duyệt.` |
| Settings, Telegram | `Liên kết nhóm Telegram` · `Thêm bot @{bot} vào nhóm Telegram rồi gửi lệnh này trong nhóm:` · the command with `Sao chép` · `Mã có hiệu lực 10 phút.` · linked chats with `Bỏ liên kết` |
| `/link/telegram` | `Liên kết Telegram với tài khoản {email}?` · `Liên kết` · done `Đã liên kết. Quay lại Telegram để tiếp tục.` · bad code `Link này không còn dùng được.` |

### 7.4 Reminders on S5

The buttons `Nhắc` and `Nhắc cả nhóm một lần` of mockup GE5, hidden in phase 1.

| Situation | String |
|---|---|
| Sent | `Đã nhắc {name}.` |
| Too soon | `Bạn vừa nhắc {name} rồi. Nhắc lại được sau {time}.` |
| Sent to several | `Đã nhắc {count} người.` |

### 7.5 Approval

| Place | String |
|---|---|
| Tag in the stream | `chờ duyệt` · `không được duyệt` |
| Block on S20, pending | `Khoản này chờ {owner} duyệt. Chưa tính vào số dư.` with `Duyệt` · `Không duyệt` (owner) |
| Reject dialog | `Vì sao không duyệt?` · field `Ghi chú` (optional) · `Không duyệt` · `Thôi` |
| Block, rejected | `{owner} không duyệt khoản này.` / the note |
| After saving a pending expense | `Đã lưu. Khoản này chờ {owner} duyệt.` |

## 8. Permission matrix additions

| Endpoint group | Owner | Editor | Viewer | Outsider |
|---|---|---|---|---|
| Read and write comments; open a dispute; mute the group | 2xx | 2xx | 2xx | 404 |
| Delete another person's comment; resolve another person's dispute | 2xx | 403 | 403 | 404 |
| Remind as the receiver; remind for another member | 2xx | 2xx | own member only | 404 |
| Approve or reject; set the threshold or the reminder interval; create a chat link code; unlink a chat | 2xx | 403 | 403 | 404 |

The Telegram webhook is outside the matrix; its gate cases are below.

## 9. Gate acceptance scripts (outline)

- **4A:** a viewer comments and opens a dispute; balances are identical before and after; an editor cannot resolve it; the opener can.
- **4B:** an expense shared by three creates two notifications and none for the actor; a removed user's list no longer shows that group; the digest job prints one mail per user with unread items and none otherwise; an unsubscribe token works once signed out and a wrong one answers 404; the second reminder inside 24 hours answers 429.
- **4C (console sender, updates posted with `curl`):** a wrong secret answers 404; `/chi` from an unlinked sender saves nothing; `/chi cà phê 180k chia 4` from an editor prints the draft with shares equal to the web preview; the callback saves once when posted twice; another user's callback saves nothing; a viewer's `/chi` is refused; `/sodu` equals `GET …/balances`; `/huy` deletes it.
- **4D:** with a threshold, an editor's large expense leaves balances unchanged and `db:check-balances` passing; approval changes balances by the expected amounts; rejection changes nothing; the owner's own large expense counts at once.

## 10. Not verified by the agent

The real Telegram adapter and webhook registration; how messages look in Telegram; mail rendering in real clients and the unsubscribe header's handling by mail providers.

## 11. Left to the builder

Job names and schedules' implementation; payload field names; how the comment thread paginates; the wording of log lines.

## 12. Changes to standing documents

| Document | Change |
|---|---|
| `docs/03-srs.md` | FR-4.6 closed by survey; rules of sections 3.2, 4.5 and 6 as numbered requirements; permission rows |
| `docs/04-adr.md` | ADR-025: a pending or rejected expense is outside the balance. ADR-026: the bot acts as the linked user and saves only on a tap |
| `docs/05-database-design.md` | Eight new tables; new columns on `groups`, `group_users`, `transactions`; the balance query's filter; section 8's phase 4 row replaced |
| `docs/05-api-spec.md` | New endpoints and error codes `REMINDER_TOO_SOON`, `MEMBER_NOT_LINKED` |
| `docs/06-ux-ui/user-flows.md` | S19, S20 and section 7 of this spec; the navigation change of 7.1 |
| `docs/runbooks/` | "Create the Telegram bot and register the webhook" |

## 13. Owner's prerequisites

Approve this spec, in particular three product rules the advisor chose: viewers may comment and dispute (3.2); a disputed expense still counts (3.2); a pending expense does not count (6). Any time after the server step: create the bot with BotFather.

## 14. Amendment 2026-11-18 (advisor, before the run)

Written after Phases 2 and 3 were merged (`d12f622`, `905cdf2`) and the Phase 3 review corrections (`5c27dea`, `ed086fa`). Product behavior of sections 1–13 is unchanged except where stated.

1. **`/chi` reads with the AI only as an explicit send.** Since `5c27dea`, `POST …/transactions/parse` calls the sentence AI only when the request carries `ai: true` (API spec, "Phase 3 review corrections — 2026-11-18"). A `/chi` command is the sender's explicit action, so the bot calls the parse service with `ai: true`. The AI reservation is charged to the linked application user, under the same per-user daily and monthly limits as the web; when the limit is reached the rule answer is used, as on the web. An AI reading is prefixed with `Đọc bằng AI.` on its own line (plan 4C, unchanged). Nothing from the chat other than the `/chi` sentence is sent to the AI provider.
2. **Phases 2 and 3 are present.** Every notification kind of section 4.2 is built, including `settlement_requested`, `settlement_confirmed`, `settlement_rejected` and `budget_state`; the "phase 3 absent" task 4B.0 does not apply because the worker exists. Mail and reminder jobs register in `apps/worker` beside the Phase 3 jobs.
3. **Approval and Phase 2/3 money.** The approval rule of section 6 applies to every expense, including the `items` split and expenses saved from a receipt scan; the threshold compares the expense `amount`. Transfers created by confirming a settlement request and fund contributions are never pending. The approval filter covers, in addition to section 6's list, the fund cash and contributions, the budget warnings returned by create, edit and edit preview, and the suggested transfers used by the paying screen and settlement requests; plan 4D.1's `rg` listing is the check.
4. **Re-baseline replay.** The acceptance scripts of earlier runs were never committed and are no longer on the machine. Task 0 reconstructs, from each merged phase's plan gate tables, a representative replay per stage (as the Phase 3 Task 0 did) and records exactly which cases ran and their real output. A case it cannot reconstruct is listed under "Not verified", not described as passed.
5. **Deferred owner checks.** On 2026-11-18 the owner deferred all checks with a real AI provider (Anthropic key, the 30-receipt measurement) until every phase, including the iOS app, is done. Phase 4 runs and gates with `AI_PROVIDER=fake` where the AI path is exercised and with it unset for the capability checks; the real Telegram bot remains "Not verified" (section 10).

