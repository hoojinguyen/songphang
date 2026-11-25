# Sòng Phẳng

## Requirements

- Node.js 24.7 or later (native Argon2 is required).
- pnpm 11.21.0, matching the root `packageManager` field.
- Docker with Docker Compose installed and the Docker daemon running.
- Available local ports: 3000 for the web app, 4000 for the API, and 54329 for PostgreSQL.

## First run

From the repository root:

```sh
cp .env.example .env
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) and choose the development sign-in link, then Minh.

`pnpm dev` waits for PostgreSQL to become healthy, applies migrations, seeds the four development users, and starts the API, worker, and web app. Migrations and seed operations can run repeatedly without creating duplicate users.

Press Ctrl+C to stop the API and web app. PostgreSQL continues running in Docker. Run `pnpm dev` again to restart the application; existing data and valid login sessions are preserved.

Keep `.env` local and out of Git. `.env.example` contains configuration values intended only for local development.

### Local `.local` / LAN device testing

By default, the development API and web app bind to `127.0.0.1` (loopback) to prevent accidental exposure on untrusted networks:

- Web app: `http://127.0.0.1:3000`
- API server: `http://127.0.0.1:4000`

When testing from a physical device on the same local network (such as an iPhone on Wi-Fi or `.local` hostname, for example `http://macbook.local:3000` or `http://192.168.1.x:3000`):

1. **Host Binding:** Run the development server with host binding enabled, e.g. `pnpm --filter @songphang/web dev --hostname 0.0.0.0`.
2. **Web Origin & Allowed Dev Origins:** Set `WEB_ORIGIN` to the exact origin the device accesses (e.g. `WEB_ORIGIN=http://macbook.local:3000`). The API `requireSameOrigin` check rejects cookie-backed login and mutations whose `Origin` header does not match `WEB_ORIGIN`, so `ALLOWED_DEV_ORIGINS` is **not** an alternative to `WEB_ORIGIN` for API requests. `ALLOWED_DEV_ORIGINS` (comma-separated hostnames, e.g. `ALLOWED_DEV_ORIGINS=macbook.local,192.168.1.15`) only adds extra hostnames to Next.js `allowedDevOrigins` in development mode while continuing to reject unrelated origins (`403`). Wildcard entries are ignored and production origin checks are never relaxed.
3. **iOS Native Client (`SongPhangKit`):** Set the backend API URL in your build scheme configuration or use the in-app Debug Panel (`Cấu hình API`) to point to `http://macbook.local:4000` (or `http://<LAN_IP>:4000`).

## Common commands

| Command                  | Purpose                                                                               |
| ------------------------ | ------------------------------------------------------------------------------------- |
| `pnpm dev`               | Start PostgreSQL, migrate and seed the database, then start the API and web app.      |
| `pnpm check`             | Run linting, strict TypeScript checks, and OpenAPI contract snapshot check.           |
| `pnpm contract:write`    | Regenerate the deterministic v1 OpenAPI snapshot at `packages/contract/openapi.json`. |
| `pnpm contract:check`    | Verify `packages/contract/openapi.json` matches the live v1 route registry.           |
| `pnpm build`             | Build every workspace package that defines a `build` script.                          |
| `pnpm db:migrate`        | Apply database migrations; PostgreSQL must be running.                                |
| `pnpm db:check-balances` | Check ledger totals and group balances after changing or importing expenses.          |
| `pnpm db:seed`           | Insert missing development users; PostgreSQL must be running and migrated.            |
| `docker compose down`    | Stop and remove the database container while preserving its data volume.              |

**Reset local data:** stop the application with Ctrl+C, then run:

```sh
docker compose down -v
pnpm dev
```

`docker compose down -v` deletes the local PostgreSQL data volume, including all users and sessions. The next `pnpm dev` creates a fresh database with the four development users. Omit `-v` when you want to preserve data.

## Phase 1 features

- Email/password accounts, verification/reset mail, optional Google sign-in, invite links/QR, roles and live updates.
- Integer-only expense/income/transfer ledgers with equal, exact, weighted and percentage splits, balances and settlements.
- Vietnamese sentence entry, clarification/manual hand-off, version-safe editing, undo/history, group deletion and offline read state.

## Phase 2 features

- **VietQR and settlement confirmation:** Receiving bank/wallet methods on Members (`/g/{id}/members`), a paying screen (`/g/{id}/pay`) with a 240px VietQR QR code (`SP {from} tra {to}`) and payment fields, and pending-settlement report/confirm/reject/cancel flow on Balances (`/g/{id}/balances`).
- **Custom categories, filters, statistics, and CSV export:** Up to 30 custom categories per group on Settings (`/g/{id}/settings`), unaccented search and filters (`Người`, `Danh mục`, `Loại`, `Từ ngày`, `Đến ngày`) on the group feed (`/g/{id}`), Statistics (`/g/{id}/stats`) with category, member, and timeline breakdowns, and formula-safe UTF-8 CSV download (`/api/v1/groups/{id}/export.csv`).
- **Shared fund:** A group fund on Fund (`/g/{id}/fund`) held by a chosen member, funded by contributions/withdrawals, supporting fund-paid expenses (including quick entry such as `ăn tối 300k quỹ trả`), and reported separately on Balances.
- **Budget and spending warnings:** Owner-configured monthly (`Theo tháng`) or trip (`Cả chuyến`) limits on Settings (`/g/{id}/settings`), `80%` near/over banners on the group feed, summary line on Statistics, and `BUDGET_OVER` confirmation warnings.

### Bank dataset and manual VietQR check

- `packages/core/src/banks.ts` contains the 76-bank BIN mapping sourced from `https://api.vietqr.io/v2/banks` (VietQR.io by Casso, retrieved `2026-11-17`). It is not a NAPAS-certified dataset; automated NAPAS bank-account verification is disabled.
- Before real-money use, verify the QR payload bytes match the VietQR specification and scan a 1.000 đ test transfer from `/g/{id}/pay` with a Vietnamese banking app to confirm bank, account number, account name, amount, and transfer note fill in accurately.

## Phase 3 features

- **Background worker & private attachments:** `apps/worker` runs `pg-boss` jobs (`heartbeat`, `cleanup-attachments`, `delete-files`, `read-receipt`) and notifies the API over PostgreSQL `LISTEN`/`NOTIFY` (`songphang_events`) so connected clients refresh `receiptScans` live. Uploaded receipt photos are stored privately under `STORAGE_DIR` (resolved relative to the repository root; default `./.data/uploads`) with a 5 MB image cap, 200 MB per-group storage quota, magic-byte validation (`image/jpeg`, `image/png`, `image/webp`), authorized streaming (`Cache-Control: private, no-store`, `X-Content-Type-Options: nosniff`), and 24-hour orphan cleanup.
- **Receipt scanning & item-by-item splitting (`Theo món`):** Editors and owners can upload a receipt from `Chụp hoá đơn` in the feed entry bar, inspect extracted items, taxes/fees, and total discrepancies, assign items per member (including `Chia đều các món còn lại`), and save or edit expenses using the `items` split method (`packages/core/src/split-items.ts`, `POST /api/v1/groups/{groupId}/transactions/items/preview`).
- **AI sentence fallback & category suggestions:** When rule parsing cannot parse an expense sentence, the API optionally calls the sentence reader (`AI_PROVIDER`), displays `Đọc bằng AI. Hãy xem lại.`, supports multi-expense drafts (`Khoản {index}/{count}`, `Lưu và sang khoản sau`, `Bỏ khoản này`), and suggests categories via `suggestCategory` (`packages/core/src/category-keywords.ts` + live group custom categories).

### AI configuration and local fake fixtures

Leave `AI_PROVIDER` unset to keep optional AI endpoints and UI entry points disabled (`receiptReading: false`, `sentenceAi: false`). Production startups refuse `AI_PROVIDER=fake`, and require `ANTHROPIC_API_KEY` and `AI_MODEL` when `AI_PROVIDER=anthropic`.

| Variable                        | Purpose                                                                                | Default in `.env.example` |
| ------------------------------- | -------------------------------------------------------------------------------------- | ------------------------- |
| `STORAGE_DIR`                   | Private upload directory resolved from repo root                                       | `./.data/uploads`         |
| `AI_PROVIDER`                   | Leave empty to disable, `fake` for local fixtures, or `anthropic`                      | _(unset)_                 |
| `ANTHROPIC_API_KEY`             | Anthropic API key when `AI_PROVIDER=anthropic`                                         | _(unset)_                 |
| `AI_MODEL`                      | Claude model ID for receipt and sentence calls                                         | `claude-haiku-4-5`        |
| `AI_RECEIPTS_PER_USER_PER_DAY`  | Daily receipt scan cap per user                                                        | `20`                      |
| `AI_SENTENCES_PER_USER_PER_DAY` | Daily AI sentence cap per user                                                         | `100`                     |
| `AI_CALLS_PER_MONTH`            | Monthly total AI calls cap across all users                                            | `1000`                    |
| `AI_FAKE_RECEIPT_FIXTURE`       | Optional forced fake receipt key (`clean`, `tax-service`, `mismatch`, `not-a-receipt`) | _(unset)_                 |

Offline fake fixtures used when `AI_PROVIDER=fake`:

- Receipt JPEGs and SHA-256 readings: `apps/worker/fixtures/receipts/` (`manifest.json`, `clean.jpg`, `tax-service.jpg`, `mismatch.jpg`, `not-a-receipt.jpg`)
- Sentence fixtures (`AI01`–`AI15`): `apps/api/fixtures/sentences.json`

## Phase 4 features

- **Transaction view (`S20`), comments, and disputes:** Tapping any stream row opens `/g/{id}/tx/{txId}/view` with breakdown, comments (`20/min/user` rate limit, author/admin/owner deletion, live SSE `comments`), and disputes (`Khoản này chưa đúng` -> `đang hỏi lại` -> `Đã giải quyết`).
- **Notifications, mail delivery, and debt reminders:** Live unread header bell (`{count} thông báo chưa đọc`), notifications list (`/notifications`), per-group mute (`Tắt thông báo nhóm này` on `/g/{id}/members`), immediate & daily digest emails (`Thông báo qua email` on `/account`), RFC 8058 one-click unsubscribe (`/notifications/unsubscribe?token=...` — server-side `POST` handled directly without session/Origin/JS alongside browser `GET`, backed by durable hash-only tokens in `notification_unsubscribe_tokens`), manual debt reminders (`Nhắc` / `Nhắc cả nhóm một lần` on `/g/{id}/balances` with a 24-hour per-pair cooldown and live SSE refresh), and automatic reminders (`Tự nhắc nợ` on `/g/{id}/settings`: `Tắt`, `Mỗi 3 ngày`, `Mỗi tuần`, `Mỗi 2 tuần`, enqueuing `send-notification-mail` and publishing `songphang_events` transactionally).
- **Expense approval above a threshold:** Owners can enable `Duyệt khoản chi lớn` (`Từ số tiền`) on `/g/{id}/settings`. Non-owner expenses at or above the threshold enter `pending` (`chờ duyệt`), trigger `approval_requested` notifications, and stay excluded from balances, stats, budgets, fund cash, and CSV exports (`countedTransaction` SQL invariant) until approved (`Duyệt`) or rejected (`Không duyệt`) by the group owner on S20.

### Worker jobs and schedules

`apps/worker` runs these Phase 4 jobs in `pg-boss` (`Asia/Ho_Chi_Minh` timezone):

| Job                      | Schedule / trigger                                              | Purpose                                                                                                                                                |
| ------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `send-notification-mail` | Enqueued transactionally on notification write (`singletonKey`) | Sends immediate notification emails (at-least-once retry via `pg-boss`) using durable hashed one-click unsubscribe tokens and emits reminder refreshes |
| `send-push`              | Enqueued transactionally on notification write (`singletonKey`) | Checks unread status, membership, group mute, active device sessions, and `hidePushContent`, then dispatches alerts via APNs or `console`              |
| `send-digest`            | `0 20 * * *` (daily 20:00)                                      | Sends unread digest emails created since the `job_checkpoints` cursor                                                                                  |
| `auto-reminders`         | `0 9 * * *` (daily 09:00)                                       | Creates scheduled debt reminders when the group interval has elapsed, enqueuing `send-notification-mail` and `songphang_events` in the same tx         |
| `prune-notifications`    | `15 3 * * *` (daily 03:15)                                      | Deletes notifications older than 90 days                                                                                                               |
| `prune-bot-data`         | `0 * * * *` (hourly)                                            | Deletes expired unsaved `bot_drafts`, plus saved `bot_drafts`, `chat_link_codes`, `bot_updates`, and `chat_identity_pairings` older than 24 hours      |

### Telegram bot configuration

Leave `TELEGRAM_PROVIDER` unset to keep bot routes and linking cards disabled (`GET /api/v1/features` -> `telegram: false`). See [docs/runbooks/telegram.md](docs/runbooks/telegram.md) for BotFather setup, webhook registration, two-sided account pairing, and token rotation.

| Variable                  | Purpose                                                                                                | Default in `.env.example` |
| ------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------- |
| `TELEGRAM_PROVIDER`       | Leave empty to disable, `console` for local logging (`ConsoleChatSender`), or `telegram` for Bot API   | _(unset)_                 |
| `TELEGRAM_BOT_TOKEN`      | Token from `@BotFather` (required when `TELEGRAM_PROVIDER=telegram`)                                   | _(unset)_                 |
| `TELEGRAM_WEBHOOK_SECRET` | Random secret (`>= 32` chars, `[A-Za-z0-9_-]`) checked via `X-Telegram-Bot-Api-Secret-Token`           | _(unset)_                 |
| `TELEGRAM_BOT_USERNAME`   | Bot handle without `@`, shown on `/g/{id}/settings` (`/lienket <code>` -> `@bot`) and `/link/telegram` | _(unset)_                 |

When `TELEGRAM_PROVIDER=console`, outgoing replies print as structured JSON to API logs instead of calling `api.telegram.org` (refused in production). Supported bot commands: `/chi`, `/sodu`, `/huy`, `/lienket`, `/trogiup`, and `/start` (private chat pairing).

## Phase 5 contract and native app configuration

`packages/contract/openapi.json` is the deterministic OpenAPI 3.1 snapshot of the v1 API registry (excluding development-only `/api/v1/dev/*` routes). Version 1 evolves strictly by addition; clients ignore unknown fields and map unknown enum values to safe fallbacks.

| Variable                  | Purpose                                                                                                                           | Default in `.env.example` |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `MIN_APP_VERSION_IOS`     | Minimum allowed iOS app version (`major.minor.patch`) in `GET /features`                                                          | `0.0.0`                   |
| `MIN_APP_VERSION_ANDROID` | Minimum allowed Android version (`major.minor.patch`) in `GET /features`                                                          | `0.0.0`                   |
| `APPLE_PROVIDER`          | Leave empty to disable, `fake` for local JWKS testing, or `apple`                                                                 | _(unset)_                 |
| `APPLE_BUNDLE_ID`         | iOS bundle identifier validated as Apple ID token `aud`                                                                           | _(unset)_                 |
| `APPLE_TEAM_ID`           | Apple Developer Team ID (10 characters, required for `apple` mode)                                                                | _(unset)_                 |
| `APPLE_KEY_ID`            | Sign in with Apple Key ID (10 characters, required for `apple` mode)                                                              | _(unset)_                 |
| `APPLE_PRIVATE_KEY`       | Sign in with Apple `.p8` EC private key PEM (`apple` mode)                                                                        | _(unset)_                 |
| `DATA_ENCRYPTION_KEY`     | 32-byte base64 key encrypting Apple refresh tokens (`apple` mode)                                                                 | _(unset)_                 |
| `APPLE_FAKE_JWKS_FILE`    | Path to local JWKS fixture file (`fake` mode only; refused in prod)                                                               | _(unset)_                 |
| `PUSH_PROVIDER`           | Leave empty to disable, `console` for local logs (refused in prod), or `apns` (production dispatch deferred until Phase 7 mailer) | _(unset)_                 |
| `APNS_KEY_ID`             | Optional 10-character APNs `.p8` key ID overriding `APPLE_KEY_ID`                                                                 | _(unset)_                 |
| `APNS_PRIVATE_KEY`        | Optional APNs `.p8` EC private key PEM overriding `APPLE_PRIVATE_KEY`                                                             | _(unset)_                 |
| `APPLE_APP_ID`            | Web AASA `<TeamID>.<BundleID>` for `/.well-known/apple-app-site-association`                                                      | _(unset)_                 |

## Development mail, background worker, and optional sign-in providers

Mail is printed by the API and worker processes to their development console. Read the verification/reset link there and open it locally; no external mail delivery service is called. Treat these links as secrets and do not copy them into Git or reports. A production configuration (`APP_ENV=production`) without a real mailer is refused by the API, and `apps/worker` unconditionally refuses production startup (`Mailer is not configured for production`) because production mailer adapters are deferred to Phase 7. Consequently, production worker operations (including production APNs push dispatch) remain deferred until production mail delivery is implemented. Similarly, `PUSH_PROVIDER=console` is refused in production.

### Local Apple Sign-In and Fake JWKS Testing

When `APPLE_PROVIDER=fake`, Apple identity token verification uses a local JWKS fixture file configured via `APPLE_FAKE_JWKS_FILE`:

- The file must contain a valid JSON Web Key Set (`{"keys": [{"kty": "RSA", "kid": "...", "n": "...", "e": "...", "alg": "RS256", "use": "sig"}]}`) matching the private key used to sign test JWTs.
- Test tokens must specify `iss: "https://appleid.apple.com"`, `aud: APPLE_BUNDLE_ID`, valid timestamps (`iat`, `exp`), and `nonce` as the lowercase hex SHA-256 digest of `rawNonce` (64 characters).
- Test authorization codes are single-use; the fake adapter keeps hashed receipts in the JWKS path’s adjacent `.replay` directory and rejects replayed codes with 401 across restarts. Put the JWKS and receipts in a writable disposable directory outside the repository. Use a fresh key set for each disposable fixture run. A custom Apple subject can be injected in tests using the prefix `sub=<custom_sub>:<code_body>`.
- Both `APPLE_PROVIDER=fake` and `APPLE_FAKE_JWKS_FILE` are strictly forbidden when `APP_ENV=production`.

Use this disposable fixture from a shell with Node.js. Configure the local API
with `APPLE_PROVIDER=fake`, the printed `APPLE_FAKE_JWKS_FILE` and
`APPLE_BUNDLE_ID=vn.songphang.app` before submitting the request.

```sh
fixture=$(mktemp -d)
node --input-type=module - "$fixture" <<'NODE'
import { createHash, generateKeyPairSync, randomUUID, sign } from "node:crypto";
import { writeFileSync } from "node:fs";

const directory = process.argv[2];
const { publicKey, privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
const kid = "local-fixture";
writeFileSync(directory + "/jwks.json", JSON.stringify({
  keys: [{ ...publicKey.export({ format: "jwk" }), kid, alg: "RS256" }],
}));
const rawNonce = randomUUID();
const now = Math.floor(Date.now() / 1000);
const encode = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
const input = encode({ alg: "RS256", kid }) + "." + encode({
  iss: "https://appleid.apple.com", aud: "vn.songphang.app",
  sub: randomUUID(), email: "apple-local@example.test", email_verified: true,
  iat: now, exp: now + 300, nonce: createHash("sha256").update(rawNonce).digest("hex"),
});
writeFileSync(directory + "/request.json", JSON.stringify({
  identityToken: input + "." + sign("sha256", Buffer.from(input), privateKey).toString("base64url"),
  rawNonce, authorizationCode: randomUUID(), client: "ios", deviceName: "Local fixture",
}), { mode: 0o600 });
NODE
printf 'APPLE_FAKE_JWKS_FILE=%s/jwks.json\n' "$fixture"
# After starting the local API, expect 200 once and 401 on repeat.
for attempt in 1 2; do
  curl -sS -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' \
    --data-binary @"$fixture/request.json" http://127.0.0.1:4000/api/v1/auth/apple
done
```

`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are optional; keep real values only in the local `.env`. Without both, the Google button/routes are disabled. The local callback is `http://localhost:3000/api/v1/auth/google/callback`. Google sign-in remains unverified until an OAuth app exists and the manual checklist has been completed.

Run `pnpm db:check-balances` after changing ledger data. Success ends with `All groups balanced`.
