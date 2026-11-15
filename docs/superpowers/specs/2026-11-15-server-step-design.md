# Server Step ("Đưa lên máy chủ") — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` first.

## 1. Intent

Make the application deployable on the owner's Ubuntu VM with a domain and HTTPS, so a real group can use it for a trip. The agent builds and verifies everything that can be verified on the local machine; the owner performs the deployment itself from a runbook.

**Goals:** a production Compose stack; real mail; safe configuration for a public address; nightly encrypted backups off the VM with a rehearsed restore; a one-command update.

**Non-goals:** monitoring beyond a health endpoint (phase 7D); abuse limits beyond phase 1's (7C); legal pages (7B); a staging environment; zero-downtime deploys.

**Anti-goals:** a stack that differs between the local machine and the VM in anything but configuration; a secret in the repository; a backup that has never been restored.

## 2. Scope and stages

| Stage | Adds |
|---|---|
| SA | Container images, production Compose file, Caddy, configuration for production |
| SB | SMTP mailer; mail templates checked in a real mail client |
| SC | Backup, restore, update and rollback scripts; runbook |

SRS: NFR-1.6 (HTTPS, cookie flags), NFR-1.10 (backups), real mail delivery for FR-1.5 and FR-1.6.

## 3. Stack (SA)

Files under `infra/` (the directory SAD section 4 already names):

| File | Content |
|---|---|
| `infra/compose.prod.yml` | Services `caddy`, `api`, `web`, `db`, `backup`; later phases add `worker` |
| `infra/Caddyfile` | One site `{$SITE_ADDRESS}`: `/api/*` to `api:4000`, everything else to `web:3000`; compression; security headers (section 5) |
| `apps/api/Dockerfile`, `apps/web/Dockerfile` | Multi-stage builds on the Node version of `engines.node`; the final stage runs as a non-root user and contains only the built output and production dependencies |
| `infra/.env.prod.example` | Every variable with a fake value |

Decisions:

- **Postgres** is the same major version as local (17), with a named volume and no published port.
- **Migrations** run in the `api` container's entrypoint before the server listens (SAD section 8). A failed migration stops the container; Caddy answers 502 and the previous data is untouched.
- **Next.js** is built with `output: "standalone"`.
- **SSE through Caddy:** `flush_interval -1` on the `/api/*` proxy so events are not buffered.
- **Restart policy** `unless-stopped`; **log rotation** through Docker's `json-file` options (10 MB × 5 per service).
- **Health:** each service has a Compose health check; `caddy` waits for `api` and `web` to be healthy.

## 4. Configuration for production

Changes to `apps/api/src/config.ts`, validated by the existing Zod schema at start-up:

| Variable | Rule |
|---|---|
| `APP_ENV=production` | Dev login routes are not registered (already so); the session cookie is `Secure`; the API refuses to start when the mailer is the console mailer, or any `*_PROVIDER` is `fake` or `console` |
| `TRUST_PROXY` | `true` only behind Caddy. When true, the client IP for rate limits is the **last** address of `X-Forwarded-For` (the one Caddy appended), never the first. When false the socket address is used, as in phase 1 |
| `WEB_ORIGIN`, `API_ORIGIN` | Must be `https://` in production |
| `SESSION_COOKIE_NAME` | Gains the `__Host-` prefix in production |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `MAIL_FROM` | Required in production |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Still optional; the redirect URI becomes `{API_ORIGIN}/api/v1/auth/google/callback` |

Registration stays open (roadmap: the address is simply not published).

## 5. Security headers

Set by Caddy for every response: `Strict-Transport-Security: max-age=31536000`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `X-Frame-Options: DENY`, and a `Content-Security-Policy` of `default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self' https://accounts.google.com`.

`'unsafe-inline'` for scripts is accepted here because Next.js needs a nonce pipeline to avoid it; removing it is a phase 7E item. The agent verifies in a browser that no screen logs a CSP violation.

## 6. Mail (SB)

- **Library:** `nodemailer` (MIT-0, no dependencies, about 500 KB unpacked), in `apps/api`. Why not hand-written: SMTP with STARTTLS, authentication and MIME encoding of Vietnamese subjects is well beyond a few dozen lines. Why SMTP rather than one provider's HTTP API: the owner has not chosen a provider, every provider speaks SMTP, and SMTP can be exercised locally.
- The existing `Mailer` interface gains a second implementation, `smtpMailer`. Selection: `SMTP_HOST` set → SMTP; otherwise console (development only).
- Mails are sent as `multipart/alternative` with a plain-text part and a minimal HTML part (one heading, one paragraph, one button-styled link, the plain link below it). No images, no tracking.
- A send failure is logged without the recipient's address or the link, and never changes the HTTP answer of register or forgot-password (NFR-1.13).
- **Local verification:** the Compose file has an optional profile `mailcheck` that runs Mailpit (a local SMTP catcher with a web inbox; a container, not a dependency of the code). The agent sends the four mails of phase 1 through it and records how each renders.

Strings (final), sender name `Sòng Phẳng`:

| Mail | Subject | Body | Button |
|---|---|---|---|
| Verify email | `Xác minh email của bạn` | `Chào {name}, bấm nút dưới đây để xác minh email cho tài khoản Sòng Phẳng. Link có hiệu lực trong 24 giờ.` | `Xác minh email` |
| Account exists | `Bạn đã có tài khoản Sòng Phẳng` | `Ai đó vừa đăng ký bằng email này. Bạn đã có tài khoản rồi; hãy đăng nhập, hoặc đặt lại mật khẩu nếu quên.` | `Đăng nhập` |
| Reset password | `Đặt lại mật khẩu` | `Bấm nút dưới đây để đặt mật khẩu mới. Link có hiệu lực trong 1 giờ. Nếu bạn không yêu cầu, hãy bỏ qua thư này.` | `Đặt mật khẩu mới` |
| Password changed | `Mật khẩu của bạn vừa được đổi` | `Nếu không phải bạn, hãy đặt lại mật khẩu ngay.` | `Đặt lại mật khẩu` |

If phase 1 shipped different wording for the first three, the phase 1 wording wins and the agent records it; "Password changed" is new and is sent after a reset and after a change.

## 7. Backup and restore (SC)

- `backup` service: a small image with `pg_dump`, `age` and `rclone` (all packaged tools; none enters `package.json`). A loop sleeps until 02:30 `Asia/Ho_Chi_Minh` each night.
- Each run: `pg_dump --format=custom` → `age` encryption to the public key `BACKUP_AGE_RECIPIENT` → upload with `rclone` to `BACKUP_REMOTE` → delete remote files beyond the newest 30 (NFR-1.10). The private key never touches the VM.
- From phase 3 the uploads directory is added to the same run as a second encrypted archive.
- A run writes one JSON log line: `ok` or `failed`, duration, byte size. No path, key or remote name.
- `infra/restore.sh <file>`: decrypts with a key file the operator passes, restores into a **new** database, runs `pnpm db:check-balances` against it, and only then prints the two commands that switch the application to it. It never drops the live database by itself.
- **Local verification:** `BACKUP_REMOTE` set to a local directory through rclone's `local` backend; the agent runs one backup, restores it into a scratch database, and records the balance check's output. That is the rehearsal NFR-1.10 requires for the tooling; the owner repeats it once on the VM.

## 8. Update and rollback

- `infra/deploy.sh`: `git pull --ff-only`, build images tagged with the commit hash, take an on-demand backup, `docker compose up -d`. Prints the previous tag.
- `infra/rollback.sh <tag>`: starts the previous images. Because migrations are forward-only, the runbook states that a rollback across a migration needs the pre-deploy backup; the script refuses to run when the database's migration count is ahead of the image's unless `--restore <file>` is given.

## 9. Runbook

`docs/runbooks/deploy.md`, written by the agent, in English, with every command copyable: prepare the VM (Docker, a non-root deploy user, firewall open on 80 and 443 only); point DNS; create `.env.prod` from the example; generate the `age` key pair on the owner's own machine; configure the rclone remote; first start; create the Google OAuth app for the real domain; send a test mail; run a backup and a restore; update; roll back.

`docs/runbooks/` is a new directory under `docs/`; during this run the implementation agent may write only that file there.

## 10. Verification

**Gate, on the local machine:** `docker compose -f infra/compose.prod.yml` with `SITE_ADDRESS=songphang.localhost` and Caddy's internal certificate authority. Then: `pnpm check` and `pnpm build`; the acceptance scripts of every finished phase run against `https://songphang.localhost` (with `curl --cacert` pointing at Caddy's local root); the dev-login route answers 404; the session cookie carries `Secure`, `HttpOnly`, `SameSite=Lax` and the `__Host-` prefix; an SSE event arrives within 2 seconds through Caddy; rate limiting keys on the forwarded address; the header set of section 5 is present; a backup is taken and restored.

**Not verified by the agent:** a real certificate; real DNS; a real SMTP provider and deliverability (SPF, DKIM, DMARC records are listed in the runbook); Google sign-in on the real domain; the off-site remote.

## 11. Left to the builder

Image base variants and layer order; the exact Caddy matcher syntax; the sleep-loop implementation of the backup schedule; wording of log lines.

## 12. Changes to standing documents

| Document | Change |
|---|---|
| `docs/04-adr.md` | ADR-020: SMTP through `nodemailer`; backups encrypted with `age` and shipped with `rclone` |
| `docs/04-sad.md` | Section 8 points to the runbook; `TRUST_PROXY` rule in section 7 |
| `README.md` | "Production-like stack on the local machine" |

## 13. Owner's prerequisites

Before the run: approve this spec and `nodemailer`. Before deploying (not before building): a domain; a trademark lookup for "Sòng Phẳng"; an SMTP account; a storage location off the VM that rclone supports.
