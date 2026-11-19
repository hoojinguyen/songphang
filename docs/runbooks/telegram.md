# Telegram Bot Setup and Operations Runbook

This runbook explains how to create and connect the Sòng Phẳng Telegram bot after the application is reachable over public HTTPS.

## 1. Create the bot with BotFather

1. Open [@BotFather](https://t.me/BotFather) in Telegram and run `/newbot`.
2. Choose a display name (for example `Sòng Phẳng`) and a username ending in `bot` (for example `songphang_bot`). Copy the HTTP API token.
3. Keep group privacy mode **enabled** so the bot only receives slash commands (`/chi`, `/sodu`, `/huy`, `/lienket`, `/trogiup`, `/start`) and callback button presses:

   In `@BotFather`, run `/setprivacy`, pick your bot, and confirm `Enable`.

4. Optionally register commands with `@BotFather` (`/setcommands`):

```text
chi - Thêm khoản chi mới
sodu - Xem ai nợ ai trong nhóm
huy - Xoá khoản bạn vừa thêm qua bot
lienket - Liên kết nhóm chat với sổ chi tiêu
trogiup - Xem hướng dẫn lệnh
```

## 2. Configure environment variables

Set these variables on the API service and restart it:

```sh
export TELEGRAM_WEBHOOK_SECRET="$(openssl rand -hex 32)"
```

```env
TELEGRAM_PROVIDER=telegram
TELEGRAM_BOT_TOKEN=<token-from-botfather>
TELEGRAM_WEBHOOK_SECRET=<output-of-openssl-rand-hex-32>
TELEGRAM_BOT_USERNAME=songphang_bot
```

Notes:
- Omit leading `@` in `TELEGRAM_BOT_USERNAME` (matching case-insensitively on `/chi@BotName`).
- In local development without external Telegram calls, use `TELEGRAM_PROVIDER=console`, `TELEGRAM_WEBHOOK_SECRET`, and `TELEGRAM_BOT_USERNAME` (`TELEGRAM_PROVIDER=console` is refused when `APP_ENV=production`).
- When `TELEGRAM_PROVIDER` is unset, `GET /api/v1/features` reports `telegram: false` and the webhook returns `404`.

## 3. Register the webhook with Telegram

Run `setWebhook` against your public HTTPS domain (`https://api.example.com`) using the exact `TELEGRAM_WEBHOOK_SECRET`:

```sh
curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"https://api.example.com/api/v1/bots/telegram/webhook\",
    \"secret_token\": \"${TELEGRAM_WEBHOOK_SECRET}\",
    \"allowed_updates\": [\"message\", \"callback_query\"]
  }"
```

Verify registration:

```sh
curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
```

Confirm `"url"` matches your HTTPS endpoint and `"allowed_updates"` lists `["message","callback_query"]`.

## 4. Link a group and user accounts

1. Add `@songphang_bot` to your Telegram group chat.
2. As the group **owner** on Sòng Phẳng, open **Cài đặt nhóm → Liên kết nhóm Telegram**, tap **Tạo mã liên kết**, copy the `/lienket XXXXXXXX` command, and send it inside the Telegram group within 10 minutes.
3. Any group member running `/chi`, `/sodu`, or `/huy` for the first time receives a generic link (`WEB_ORIGIN/link/telegram`, containing no secret or account-specific code). To pair their Telegram account safely (two-sided confirmation):
   - Sign in on `WEB_ORIGIN/link/telegram` with a verified Sòng Phẳng account and tap **Bắt đầu liên kết Telegram** (starts a 10-minute pairing attempt bound to the current web session).
   - Tap **Mở Telegram để xác nhận** (or send `/start <mã>` in a **private chat** with `@songphang_bot`; never send the pairing code in a group chat — group `/start` messages reject and cancel the attempt without echoing it).
   - In the private Telegram chat, the bot replies with the Sòng Phẳng display name and masked email plus **Xác nhận liên kết** / **Hủy**. Only that exact Telegram user can tap **Xác nhận liên kết**.
   - Return to the initiating browser tab on `WEB_ORIGIN/link/telegram`, verify the shown Telegram identity, and tap **Hoàn tất liên kết** to activate the mapping.
4. Remove access anytime from Sòng Phẳng:
   - Owner unlinks a chat in **Cài đặt nhóm → Liên kết nhóm Telegram → Bỏ liên kết**.
   - Any member unlinks their personal Telegram identity in **Tài khoản → Telegram → Bỏ liên kết**.

## 5. Bot commands

| Command | Who can run | Effect |
|---|---|---|
| `/chi <khoản chi>` | Editor / Owner | Parses expense (rules, then AI if enabled), posts split draft with `Lưu` / `Bỏ` buttons (`Lưu` creates expense only when tapped by sender) |
| `/sodu` | Any group member | Replies with fund remaining (if active), member balances, and suggested transfers |
| `/huy` | Editor / Owner | Soft-deletes the sender's most recent bot-saved expense in this chat within 10 minutes |
| `/lienket <mã>` | Telegram group | Consumes 10-minute owner code to link chat to the Sòng Phẳng group |
| `/start <mã ghép nối>` | Private chat with bot | Stages a web-initiated 10-minute pairing attempt and replies with Confirm/Cancel buttons (rejected and cancelled if sent in a group chat) |
| `/trogiup`, `/start` | Linked group chat | Prints command summary |

## 6. Rotate secrets

### Rotate webhook secret

1. Generate a new secret (`openssl rand -hex 32`), update `TELEGRAM_WEBHOOK_SECRET` on the API service, and deploy/restart the API.
2. Re-run `setWebhook` with the new `secret_token` immediately so Telegram sends the matching `X-Telegram-Bot-Api-Secret-Token` header:

```sh
export NEW_TELEGRAM_WEBHOOK_SECRET="$(openssl rand -hex 32)"
curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"https://api.example.com/api/v1/bots/telegram/webhook\",
    \"secret_token\": \"${NEW_TELEGRAM_WEBHOOK_SECRET}\",
    \"allowed_updates\": [\"message\", \"callback_query\"]
  }"
```

### Rotate bot token

1. In `@BotFather`, run `/revoke` and select `@songphang_bot` to invalidate the old token and receive a new `TELEGRAM_BOT_TOKEN`.
2. Update `TELEGRAM_BOT_TOKEN` on the API service, deploy/restart the API, and run `setWebhook` using the new token and current `TELEGRAM_WEBHOOK_SECRET`.
