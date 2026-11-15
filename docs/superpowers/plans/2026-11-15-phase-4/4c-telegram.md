# Phase 4 — Stage 4C: Telegram Bot

> Part of the phase 4 plan. Read `00-overview.md` first.

**Stage goal:** a Telegram group linked to a ledger adds expenses with `/chi`, sees balances with `/sodu`, and every action happens with the rights of the person who typed it.

**Spec:** section 5, 7.3 (Telegram lines), 9.

## Decisions for this stage

1. A command may arrive as `/chi@BotName`; the suffix is accepted only when it equals `TELEGRAM_BOT_USERNAME`, ignoring case; a command addressed to another bot is ignored.
2. Callback data is `s:{draftId}` (save) or `d:{draftId}` (drop); nothing else is accepted.
3. Link codes are 8 characters from `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, generated with `node:crypto`, stored as SHA-256, single-use, 10 minutes.
4. A processed `update_id` is remembered for 24 hours in a small table and a repeat is acknowledged without effect, because Telegram re-delivers.
5. The bot replies only in the chat the update came from. It never starts a private conversation.
6. Amounts in bot messages use the same `150.000 đ` formatter, moved to `core` if it lives in the web app.

## Update fixtures

Used in the exercises, posted with `curl -H 'X-Telegram-Bot-Api-Secret-Token: <secret>' -H 'Content-Type: application/json'`. `C` is the chat id `-1001`; Telegram user ids: Lan `111`, Hùng `222`, a stranger `999`.

```json
{ "update_id": 1, "message": { "message_id": 10, "from": { "id": 111, "first_name": "Lan" },
  "chat": { "id": -1001, "type": "supergroup" }, "text": "/chi cà phê 180k chia 4" } }
```

```json
{ "update_id": 2, "callback_query": { "id": "cb-1", "from": { "id": 111, "first_name": "Lan" },
  "message": { "message_id": 11, "chat": { "id": -1001, "type": "supergroup" } }, "data": "s:<draftId>" } }
```

---

### Task 4C.1: Webhook, sender, identities and links

**Files:**
- Create: `apps/api/src/bot/chat-sender.ts` (interface and selection), `apps/api/src/bot/telegram-sender.ts`, `apps/api/src/bot/console-sender.ts`, `apps/api/src/bot/telegram-update.ts` (Zod), `apps/api/src/bot/link-codes.ts`, `apps/api/src/routes/telegram-webhook.ts`, `apps/api/src/routes/chat-links.ts`, `apps/api/src/services/chat-links.ts`, `apps/api/src/bot-messages.ts`, `packages/db/src/schema-chat.ts`, `packages/db/src/chat.ts`, `packages/contract/src/chat-link.ts`, a migration
- Modify: `apps/api/src/config.ts`, `apps/api/src/app.ts`, `apps/api/src/routes/features.ts` (`telegram`), `apps/api/src/rate-limit.ts`, `.env.example`

**Interfaces — produces:**
- `interface ChatSender { send(chatId: string, text: string, buttons?: Array<{ text: string; data?: string; url?: string }>): Promise<void>; answerCallback(callbackId: string, text?: string): Promise<void> }`. The Telegram adapter posts JSON to the Bot API's `sendMessage` (plain text, no parse mode, so nothing in a message is interpreted as markup) and `answerCallbackQuery`, with a 10-second timeout; a failure is logged with the HTTP status only and never thrown to the route. The console adapter prints one JSON line `{ chatId, text, buttons }`.
- Selection: `TELEGRAM_PROVIDER` = `telegram` (requires `TELEGRAM_BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET` of at least 32 characters, `TELEGRAM_BOT_USERNAME`), `console` (requires only the secret and the username), or unset → the webhook answers 404 and `features.telegram` is false.
- `TelegramUpdate` (Zod): `update_id`; optional `message` with `message_id`, `from.id`, `from.first_name`, `chat.id`, `chat.type`, `text` (at most 1,000 characters); optional `callback_query` with `id`, `from.id`, `message.chat.id`, `data` (at most 64). Ids are converted to strings. Unknown keys are stripped.
- `POST /api/v1/bots/telegram/webhook`: no session, no same-origin check. Secret mismatch or missing → 404 `NOT_FOUND`, same body as any unknown route. Invalid body → 200 with no effect (Telegram must not retry). A repeated `update_id` → 200 with no effect. More than 30 updates per minute for one chat → 200, one `Chậm lại một chút nhé.` reply per minute, no other effect. Otherwise dispatch (4C.2) and answer 200 `{}` whatever happened; an internal error is logged with the request id.
- Tables `chat_links`, `chat_identities`, `chat_link_codes`, `bot_drafts` as spec 5.2, and `bot_updates` (`platform`, `update_id`, `created_at`; primary key on the first two).
- `POST /groups/{groupId}/chat-links/code` (owner) → `{ command: "/lienket ABCD2345", expiresAt }`. `GET /groups/{groupId}/chat-links` (owner) → linked chats with `linkedAt`. `DELETE /groups/{groupId}/chat-links/{id}` (owner).
- `GET /me/chat-identities` → `[{ platform, linkedAt }]`; `DELETE /me/chat-identities/{platform}`.
- `POST /me/chat-identities/claim` (`{ code }`; signed in, verified email): a valid `user` code binds its `platform_user_id` to the caller; a Telegram id already bound to another account → 409 `CHAT_IDENTITY_TAKEN`; bad or expired → 400 `TOKEN_INVALID`.

- [ ] **Step 1: Read the Bot API sections named in the overview; record the request shapes; write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)** — `TELEGRAM_PROVIDER=console`.

| Request | Expected |
|---|---|
| the first fixture with no secret header | 404; nothing printed; no `bot_updates` row |
| with a wrong secret of the same length | 404 |
| with the right secret, chat not linked | 200; the console prints the "not linked" reply to chat `-1001` |
| the same `update_id` again | 200; nothing printed |
| a body that is not JSON; a body with `text` of 5,000 characters | 200; nothing printed |
| 31 different updates for one chat within a minute | the 31st prints `Chậm lại một chút nhé.` once |
| Lan (editor): `POST …/chat-links/code` | 403 |
| Minh: the same | 200; a command with an 8-character code |
| `/lienket <code>` posted from chat `-1001` by Lan's Telegram id | the console prints the "linked" reply; `GET …/chat-links` lists the chat |
| the same code again from chat `-1002` | "bad or expired code" |
| a code 11 minutes old (date it back) | "bad or expired code" |
| `/lienket <new code>` from chat `-1001`, already linked to this group | "linked" reply; still one row |
| unset `TELEGRAM_PROVIDER` | the webhook answers 404 even with a secret header; `features.telegram` false |
| `APP_ENV=production` with `TELEGRAM_PROVIDER=console` | the API refuses to start |

- [ ] **Step 4: Commit** — `feat(api): add Telegram webhook, sender, and chat linking`

---

### Task 4C.2: Commands — `/chi`, `/sodu`, `/huy`, `/trogiup`

**Files:**
- Create: `apps/api/src/bot/dispatch.ts`, `apps/api/src/bot/commands/chi.ts`, `sodu.ts`, `huy.ts`, `trogiup.ts`, `lienket.ts`, `apps/api/src/bot/callbacks.ts`, `apps/api/src/bot/resolve-actor.ts`, `apps/worker/src/jobs/prune-bot-data.ts`
- Modify: `apps/api/src/bot-messages.ts`, `packages/contract/src/jobs.ts`

**Interfaces — consumes:** the parse service function, the transaction-creating service function with `runIdempotent`, the balances service function, the transaction-deleting service function — each exactly as the routes call them.

**Interfaces — produces:**
- `resolveActor(db, update): { kind: "ok"; user; groupId; role; memberId | null } | { kind: "chat_not_linked" } | { kind: "sender_not_linked" } | { kind: "not_in_group"; groupName }` — chat → group through `chat_links`; Telegram user → application user through `chat_identities`; role through `group_users`. A suspended or unverified user counts as not linked.
- `sender_not_linked` creates a `user` link code for that Telegram id and replies with the button `Liên kết tài khoản` whose `url` is `{WEB_ORIGIN}/link/telegram?code=…`.
- `/chi <câu>`: role viewer → the viewer reply. Else call the parse service as the actor. `ok` → insert a `bot_drafts` row and reply with the draft message and buttons `Lưu` (`s:{id}`) and `Bỏ` (`d:{id}`). Not `ok` → the "not understood" reply naming the first issue in words (a small map from issue code to Vietnamese in `bot-messages.ts`: `AMOUNT_MISSING` → `thiếu số tiền`; `MEMBER_UNKNOWN` → `không biết "{text}" là ai`; `MEMBER_AMBIGUOUS` → `"{text}" khớp nhiều người`; `COUNT_MISMATCH` → `số người chia không khớp`; `SUM_MISMATCH` → `các số không cộng lại đúng`; others → `chưa hiểu "{text}"`) with the button `Mở form`, a `url` to `/g/{groupId}/tx/new?form&text=…` (the sentence URL-encoded). With phase 3 merged the parse service already includes the AI reader; an AI reading is prefixed with `Đọc bằng AI.` on its own line.
- Callback `s:{id}`: the draft must exist, be unexpired, unsaved, and belong to this chat. A different sender → `answerCallback` with the "only {name}" text and no other effect. Expired → the expired reply. Otherwise re-check the actor's role **now**, create the transaction with `Idempotency-Key` = `bot-draft-{id}`, set `saved_transaction_id`, reply "saved". A second tap finds `saved_transaction_id` set and answers the callback silently.
- Callback `d:{id}`: same checks; delete the draft; reply "dropped".
- `/sodu`: any role; the balances service's people and transfers, formatted as spec 5.5; with phase 2 merged, a first line `Quỹ còn {amount}` when a fund exists.
- `/huy`: the newest `bot_drafts` row of this sender and chat with `saved_transaction_id` set and saved within 10 minutes → delete that transaction through the delete service (so it is in history and restorable) → reply; none → the "nothing" reply.
- `/trogiup` and `/start`: the help text. Any other command: no reply.
- Job `prune-bot-data`, hourly: delete expired drafts, used or expired codes older than a day, `bot_updates` older than 24 hours.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — console sender; group Minh (owner), Lan (editor, Telegram `111`), Hùng (viewer, Telegram `222`), Thu; chat `-1001` linked. Link the two Telegram ids by claiming codes in the browser or with `curl`.

| # | Update | Expected |
|---|---|---|
| 1 | `/chi cà phê 180k chia 4` from `999` | the "sender not linked" reply with a link button; no draft |
| 2 | the same from `111` | a draft reply: `cà phê · 180.000 đ` / `Lan trả` / four lines of `45.000 đ` / buttons; the four shares equal `POST …/transactions/preview` of the same draft |
| 3 | callback `s:{id}` from `222` | callback answered `Chỉ Lan lưu được khoản này.`; no transaction |
| 4 | callback `s:{id}` from `111` | "saved"; one transaction, `createdBy` Lan; balances changed as for the web |
| 5 | the same callback again (new `update_id`) | no reply; still one transaction |
| 6 | `/chi lẩu 600k chia 4` from `222` (viewer) | the viewer reply; no draft |
| 7 | `/chi` from `111` | the "nothing after /chi" reply |
| 8 | `/chi abc xyz` from `111` | "not understood" with a `Mở form` button; no draft |
| 9 | `/sodu` from `222` | the same balances and transfers as `GET …/balances`, in the spec's format |
| 10 | `/huy` from `111` within 10 minutes | "deleted"; the transaction is soft-deleted and appears in the activity log |
| 11 | `/huy` again | the "nothing" reply |
| 12 | `/chi …` from `111`, date the draft 11 minutes back, then `s:` | the expired reply; no transaction |
| 13 | Minh changes Lan to viewer between `/chi` and the tap | the viewer reply; no transaction |
| 14 | Minh removes Lan from the group, then `/sodu` from `111` | the "not in the group" reply |
| 15 | `/chi@OtherBot cà phê 50k` | no reply |
| 16 | callback data `x:1`, and `s:` with a draft id of another chat | no effect |
| 17 | `/chi <script>` and a sentence of 400 characters | "not understood"; nothing stored |

`pnpm db:check-balances` → `All groups balanced`.

- [ ] **Step 4: Commit** — `feat(api): add Telegram commands for expenses and balances`

---

### Task 4C.3: Web — linking screens

**Files:**
- Create: `apps/web/src/app/link/telegram/page.tsx`, `apps/web/src/components/settings/TelegramCard.tsx`, `apps/web/src/components/account/TelegramIdentityCard.tsx`, `apps/web/src/lib/chat-links.ts`
- Modify: the settings page, the account page, the new-transaction page (accept `?form&text=` and prefill the typing box's sentence into the form's description when the reader cannot fill more), `apps/web/src/messages/vi.ts`

Strings: spec section 7.3, the Telegram lines.

Behavior: both cards render only when `features.telegram` is true. `/link/telegram?code=` requires sign-in (redirect through `/login` with a safe `next`), shows the confirmation with the signed-in email, and claims the code on `Liên kết`. The code is never logged or sent anywhere but the claim endpoint. The settings card shows the command in a monospace box with `Sao chép`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — generate a command; follow a link-account URL printed by the console sender, signed out then signed in; a used code shows the bad-link line; unlink the chat; unlink the identity.
- [ ] **Step 4: Commit** — `feat(web): add Telegram linking screens`

---

### Task 4C.4: Stage gate 4C and the bot runbook

**Files:**
- Create: `docs/runbooks/telegram.md`

- [ ] **Step 1: Runbook** (English, every command copyable): create the bot with BotFather; keep privacy mode on; set the three variables and `TELEGRAM_PROVIDER=telegram`; register the webhook with `setWebhook` including `secret_token` and `allowed_updates` of `message` and `callback_query`; add the bot to a group; link; the five commands; how to rotate the token and the secret.
- [ ] **Step 2: Stage gate.** Acceptance script: 4C.1 rows 1, 3, 9; 4C.2 rows 1–6, 9, 10. Then the gate of the common file.
- [ ] **Step 3:** Record under "Not verified": the real adapter, the webhook registration, message appearance in Telegram.
- [ ] **Step 4: Commit** — `docs(runbook): add Telegram bot setup`

**Manual checks for the project owner (after the bot exists)**
1. In a real Telegram group: `/chi cà phê 180k chia 4` → the bot answers with the split and two buttons → `Lưu` → the web app shows the expense within two seconds.
2. A friend who has not linked their account tries `/chi` → they get the link button, and nothing is saved.
3. Someone else taps your `Lưu` → refused.
