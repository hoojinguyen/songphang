# Sòng Phẳng — Server Step Implementation Plan

> **For the implementation agent:** read `AGENTS.md`, the spec, `../2026-11-15-common.md`, then this file. Work through the tasks in order without stopping between them. You deploy nothing: everything is built and verified on the local machine.

**Goal:** A production stack that the owner can start on a VM from a runbook: containers, HTTPS through Caddy, real mail over SMTP, encrypted nightly backups with a rehearsed restore, one-command update and rollback.

**Architecture:** One Compose file (`infra/compose.prod.yml`) with `caddy`, `api`, `web`, `db`, `backup` (and `worker` when phase 3 is merged). The same images run locally under `songphang.localhost` with Caddy's internal certificate authority, which is how the gate verifies them.

**Tech Stack:** unchanged, plus `nodemailer` (latest stable; record version, license and size). Container tools, not code dependencies: Caddy, `age`, `rclone`, Mailpit (verification only).

**Spec:** `docs/superpowers/specs/2026-11-15-server-step-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-server-step`; `<BRANCH>` `server-step`; `<LAST TASK>` `S.7`.

## Constraints

- No secret, real domain, real address or real key enters the repository. `infra/.env.prod.example` holds fake values only; `.env.prod` is git-ignored in the same commit that introduces the example.
- The development setup (`pnpm dev`, `docker-compose.yml`) keeps working unchanged.
- Images are pinned to a version tag, never `latest`. Record each tag and why.
- Containers run as a non-root user; only `caddy` publishes ports (80, 443); `db` publishes none.
- You pull public container images to build and verify. You create no account and call no hosted service.
- `docs/runbooks/deploy.md` is the one file under `docs/` you write besides the run files.

## Review Focus

1. **The development login or the console mailer alive in production.** → S.2.
2. **Rate limits keyed on the proxy's address, so one user locks everyone out, or on a forged header, so nobody is ever limited.** → S.2.
3. **A backup that cannot be restored.** → S.5.
4. **A secret baked into an image layer or printed in a log.** → S.1, S.4, S.5.
5. **Realtime silently buffered by the proxy.** → S.3.

---

### Task S.1: Container images

**Files:**
- Create: `apps/api/Dockerfile`, `apps/web/Dockerfile`, `apps/worker/Dockerfile` (only when `apps/worker` exists), `.dockerignore`, `apps/api/docker-entrypoint.sh`
- Modify: `apps/web/next.config.*` (`output: "standalone"`), `README.md`

Requirements: multi-stage; the build stage installs with `pnpm install --frozen-lockfile` and builds only the target and its workspace dependencies; the final stage holds the built output and production dependencies, runs as the image's unprivileged user, sets `NODE_ENV=production`, and declares a `HEALTHCHECK` (API: `/api/v1/health`; web: `/`). The API entrypoint runs migrations, then `exec`s the server; a failed migration exits non-zero. `.dockerignore` excludes `.env*`, `.git`, `node_modules`, `.data`, `docs`. No `ARG` or `ENV` carries a secret; the web image needs no secret at build time (confirm by listing its build-time variables).

- [ ] **Step 1: Write the files; build the images**
- [ ] **Step 2: `pnpm check` and `pnpm build`**
- [ ] **Step 3: Exercise (Review Focus 4)**

| Check | Expected |
|---|---|
| `docker run --rm <api image> id -u` | not 0 |
| `docker history --no-trunc <each image>` searched for `PASSWORD`, `SECRET`, `KEY=` | nothing but variable names without values |
| `docker run --rm <api image> ls` at the application root | no `.env`, no `docs`, no source of other apps |
| image sizes | recorded |
| start the API image against the development database with a broken `DATABASE_URL` | exits non-zero; the log names the failure without printing the URL |

- [ ] **Step 4: Commit** — `chore(infra): add container images for api and web`

---

### Task S.2: Production configuration

**Files:**
- Modify: `apps/api/src/config.ts`, `apps/api/src/server.ts`, `apps/api/src/auth/sessions.ts` (cookie name and flags), `apps/api/src/rate-limit.ts` or wherever the client address is read, `apps/web/src/lib/` wherever the cookie name is referenced, `.env.example`

**Interfaces — produces:**
- `clientAddress(request, config): string` — one function, the only reader of the peer address. `TRUST_PROXY` false: the socket address. True: the last entry of `X-Forwarded-For` after trimming; when the header is absent or that entry is not an IP address, the socket address.
- Configuration rules of spec section 4, each enforced by the Zod schema with a start-up error that names the variable and never prints its value.
- Session cookie in production: name `__Host-sp_session` (or `__Host-` + the existing name), `Secure`, `HttpOnly`, `SameSite=Lax`, `Path=/`, no `Domain`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1, 2)** — start the API directly with environment overrides.

| Start-up | Expected |
|---|---|
| `APP_ENV=production` without `SMTP_HOST` | refuses, naming `SMTP_HOST` |
| `APP_ENV=production`, `WEB_ORIGIN=http://…` | refuses |
| `APP_ENV=production`, `DEV_LOGIN=true` | starts; `GET /api/v1/dev/users` answers 404; `GET /auth/providers` shows `devLogin: false` |
| `APP_ENV=production` with any `*_PROVIDER=fake` or `console` that exists in the code base | refuses |

`clientAddress`, called from a scratch script:

| `TRUST_PROXY` | Socket | `X-Forwarded-For` | Expected |
|---|---|---|---|
| false | 10.0.0.5 | `1.2.3.4` | 10.0.0.5 |
| true | 10.0.0.5 | `1.2.3.4` | 1.2.3.4 |
| true | 10.0.0.5 | `9.9.9.9, 1.2.3.4` | 1.2.3.4 |
| true | 10.0.0.5 | absent | 10.0.0.5 |
| true | 10.0.0.5 | `not-an-ip` | 10.0.0.5 |

- [ ] **Step 4: Commit** — `feat(api): add production configuration rules and proxy-aware client address`

---

### Task S.3: Compose stack and Caddy

**Files:**
- Create: `infra/compose.prod.yml`, `infra/Caddyfile`, `infra/.env.prod.example`
- Modify: `.gitignore`

Requirements: spec sections 3 and 5. Caddy site address from `SITE_ADDRESS`; `tls internal` only when `CADDY_TLS=internal` (the local check), otherwise automatic certificates; `/api/*` to `api:4000` with `flush_interval -1`; everything else to `web:3000`; `encode zstd gzip`; the header set of spec section 5; request bodies above 7 MB refused at the proxy. Caddy does not trust client-sent `X-Forwarded-For` (its default); state that in a comment. Named volumes: `pgdata`, `caddy_data`, `caddy_config`, and `uploads` when the worker exists. Log options per service. `depends_on` with `condition: service_healthy`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Start it locally:** `SITE_ADDRESS=songphang.localhost CADDY_TLS=internal docker compose -f infra/compose.prod.yml --env-file <a local file in the scratch directory> up -d --build`; export Caddy's local root certificate to the scratch directory for `curl --cacert`.
- [ ] **Step 3: Exercise (Review Focus 5)**

| Check | Expected |
|---|---|
| `curl --cacert … https://songphang.localhost/api/v1/health` | 200 |
| `curl -I http://songphang.localhost/` | a redirect to HTTPS |
| response headers of `/` and of `/api/v1/health` | all six of spec section 5 |
| register, read the verification link from Mailpit (S.4) or, before S.4, from a temporary console mailer override recorded as such; sign in | the cookie is `__Host-…; Secure; HttpOnly; SameSite=Lax; Path=/` |
| `curl -N` on a group's `/events`, then add an expense from another session | the event arrives in under 2 seconds |
| 11 wrong sign-ins from the host | the 11th is 429; the limiter's key (log it once at debug level, then remove the log) is the host's address, not Caddy's |
| a request with a forged `X-Forwarded-For: 8.8.8.8` | the limiter still keys on the real address |
| `docker compose port db 5432` | no published port |
| `GET /api/v1/dev/users` | 404 |
| a 10 MB request body | refused by Caddy |
| open every screen in a browser with the developer console open | no Content-Security-Policy violation; list any and fix the policy or the page |

- [ ] **Step 4: Commit** — `chore(infra): add production compose stack and Caddy configuration`

---

### Task S.4: SMTP mail

**Files:**
- Create: `apps/api/src/smtp-mailer.ts`
- Modify: `apps/api/src/mailer.ts` (selection), `apps/api/src/mail-templates.ts` (HTML part; the new "password changed" mail), the password reset and change services, `apps/api/package.json`, `infra/compose.prod.yml` (profile `mailcheck` with Mailpit)

**Interfaces — produces:**
- `smtpMailer(config): Mailer` using `nodemailer`'s SMTP transport: `SMTP_PORT` 465 → implicit TLS, otherwise STARTTLS required (`requireTLS: true`) unless `SMTP_INSECURE=true`, which is accepted only when `APP_ENV` is not production or the host is the Compose service `mailpit`. Timeouts of 10 seconds.
- `renderMail(template): { subject, text, html }` — the HTML is built from escaped strings by one small function (`escapeHtml` for every interpolated value); no template engine. Layout: spec section 6.
- Every mail has `text` and `html`. A send failure is caught in the service, logged as `{ template, error: <error class name> }`, and does not change the HTTP response.
- The "password changed" mail is sent after a successful reset and a successful change.

- [ ] **Step 1: Install `nodemailer`; record the decision entry; write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — stack up with `--profile mailcheck`, SMTP pointed at Mailpit.

| Action | Expected in Mailpit |
|---|---|
| register a new email | "Xác minh email của bạn", sender name `Sòng Phẳng`, text and HTML parts, the link works |
| register the same email again | "Bạn đã có tài khoản Sòng Phẳng"; the HTTP answer is identical to the first (status, body) |
| forgot password | the reset mail; the link works; afterwards the "password changed" mail arrives |
| a display name `<b>x</b>` | shown as text in the HTML part |
| stop Mailpit, register | 204 as usual; one error log line without the address or the link |
| Vietnamese subject | displayed correctly |

Record a screenshot or the raw source of each mail. Record under "Not verified": a real provider, deliverability, SPF/DKIM/DMARC.

- [ ] **Step 4: Commit** — `feat(api): send mail over SMTP`

---

### Task S.5: Backup and restore

**Files:**
- Create: `infra/backup/Dockerfile`, `infra/backup/backup.sh`, `infra/backup/run-loop.sh`, `infra/restore.sh`
- Modify: `infra/compose.prod.yml`, `infra/.env.prod.example`

Requirements: spec section 7. Scripts are POSIX shell with `set -eu` and `pipefail` where the shell supports it; every variable quoted; the dump is streamed `pg_dump | age -r "$BACKUP_AGE_RECIPIENT" | rclone rcat` so no plain dump is ever written to disk. File name `songphang-YYYYMMDD-HHMMSS.dump.age` (UTC). Retention: list the remote, sort, delete all but the newest 30. One JSON log line per run. A failure exits non-zero and logs `failed` with the stage name (`dump`, `encrypt`, `upload`, `prune`). `restore.sh <file> <identity file>` creates `songphang_restore_<timestamp>`, restores into it, runs the balance check against it, prints the row counts of `users`, `groups`, `transactions`, and then the commands to switch; it refuses to run when the target database name already exists.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Exercise (Review Focus 3)** — generate an `age` key pair in the scratch directory; `BACKUP_REMOTE` an rclone `local` remote pointing at the scratch directory; data seeded by running the phase 1 acceptance scripts.

| Check | Expected |
|---|---|
| run `backup.sh` once | one `.dump.age` file; log `ok` with size and duration |
| `file` and `head -c 200` on it | not a readable dump |
| the container's file system after the run | no plain dump anywhere |
| `restore.sh` with the identity | a new database; the balance check prints `All groups balanced`; row counts equal the live database's |
| `restore.sh` with a wrong identity | fails; no database left behind |
| truncate the file to half, restore | fails loudly |
| create 32 backups (loop), then one more | exactly 30 remain, the newest 30 |
| an unreachable remote | log `failed`, stage `upload`, exit non-zero |
| the log lines | contain no key, remote name or path |

- [ ] **Step 3: Commit** — `chore(infra): add encrypted off-site backups and a checked restore`

---

### Task S.6: Deploy, rollback, runbook

**Files:**
- Create: `infra/deploy.sh`, `infra/rollback.sh`, `docs/runbooks/deploy.md`

Requirements: spec sections 8 and 9. `deploy.sh` stops on a dirty working tree and on a non-fast-forward pull; tags images with the short commit hash; runs a backup before `up -d`; waits for health; prints the previous tag. `rollback.sh <tag>` compares the migration count recorded in the database with the count inside the image and refuses, with a clear message, when the database is ahead, unless `--restore <file> <identity>` is given. The runbook covers every item of spec section 9 plus: DNS records to create; SPF, DKIM and DMARC as the mail provider will describe them; the exact Google redirect URI; a first-day checklist; how to read logs; how to stop everything.

- [ ] **Step 1: Write them**
- [ ] **Step 2: Exercise on the local stack** — make a trivial commit, `deploy.sh` → new tag running, previous tag printed; `rollback.sh <previous>` → old images run; add a throwaway migration on a scratch branch, deploy, roll back → refused with the message; discard the scratch branch. Follow the runbook's local-applicable steps literally and fix every command that does not work as written.
- [ ] **Step 3: Commit** — `chore(infra): add deploy and rollback scripts and the deployment runbook`

---

### Task S.7: Gate

- [ ] **Step 1:** `pnpm check`, `pnpm build`, on a clean checkout.
- [ ] **Step 2:** Bring the stack up from nothing (`down -v` first). Run the acceptance scripts of **every merged phase** against `https://songphang.localhost` (through the development-free paths: register, verify through Mailpit, sign in; adapt each script's sign-in step and record how). `pnpm db:check-balances` against the stack's database through a one-off container.
- [ ] **Step 3:** The permission matrix of every merged phase, through Caddy.
- [ ] **Step 4:** S.3's table once more, whole.
- [ ] **Step 5:** `pnpm dev` on the development setup still works.
- [ ] **Step 6:** `progress.md`: "Not verified" (real certificate, DNS, SMTP provider, Google on the real domain, the off-site remote, the VM itself) and "Gate not passed". `manual-checks.md`: "On the local production-like stack" and "On the VM, following the runbook".

**Manual checks for the project owner**
1. Locally: start the stack as the README says, open `https://songphang.localhost`, accept the local certificate, register, find the mail in Mailpit, verify, create a group.
2. On the VM: follow `docs/runbooks/deploy.md` from the top. Note every step that is unclear.
3. On the VM: take a backup, restore it with `restore.sh`, read the balance check's output.
