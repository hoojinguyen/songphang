# Phase 7 — Stages 7C, 7D and 7E: Limits, Operations, Security

> Part of the phase 7 plan. Read `00-overview.md` first.

**Spec:** sections 5, 6, 7.

## Decisions for these stages

1. Count-based limits (groups owned, groups joined, transactions per group) are checked inside the creating database transaction with a `SELECT count(*)` under `FOR UPDATE` of the parent row (the user row or the group row), so two parallel creates cannot both pass.
2. Per-day limits use Vietnam calendar days, like the AI quotas.
3. The global per-IP limit runs before authentication and before body parsing.
4. `admin_log` rows are written by the operator scripts only; the API never reads or writes the table.
5. The independent review (7E, item 4 of the spec) is not a task: it is the owner's.

---

### Task 7C.1: The limits module and the signup brake

**Files:**
- Create: `apps/api/src/limits.ts`, `packages/db/src/limits.ts`
- Modify: `apps/api/src/config.ts` (one optional variable per limit, `REGISTRATION_OPEN`), the services for groups, invites (join), transactions, comments, accounts (register), `apps/api/src/rate-limit.ts`, `apps/api/src/app.ts`, `packages/contract/src/error.ts`, `/register` and the web's error mapping, `apps/web/src/messages/vi.ts`, `.env.example`

**Interfaces — produces:**
- `LIMITS`: one frozen object holding every number of spec section 5, each read from its variable with the default of the table.
- `ErrorCode` gains `LIMIT_REACHED` (422, `details.limit`: `groups_owned` | `groups_joined` | `group_transactions`) and `SIGNUPS_PAUSED` (503).
- Register: when `REGISTRATION_OPEN` is false, or today's count of created users has reached the system limit, answer 503 `SIGNUPS_PAUSED` **before** looking at the email, the password or the consent field.
- Register per IP: 20 per day, in addition to the existing 5 per hour.
- Global: 600 requests per minute per client address → 429, for every route including static API errors.

Strings: spec section 5; `{limit}` is `số nhóm bạn làm chủ`, `số nhóm bạn tham gia`, `số khoản chi của nhóm` for the three codes.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — lower limits through environment variables to keep the runs short, and record the values used.

| Limit set to | Action | Expected |
|---|---|---|
| groups owned 2 | create a third group | 422 `LIMIT_REACHED`, `groups_owned` |
| groups owned 2 | two creates in parallel when owning one | exactly one succeeds |
| groups joined 2 | join a third | 422, `groups_joined` |
| group transactions 3 | a fourth; then delete one and add again | 422; then 201 |
| transactions per day 3 | a fourth | 429 |
| `REGISTRATION_OPEN=false` | register a new email, an existing email, and a body with no fields | three identical 503 responses (status, code, body apart from `requestId`) |
| system signups 2 | a third registration today | 503 |
| global 20 per minute | 21 requests to `/api/v1/health` | the 21st is 429 |
| defaults | every earlier acceptance script | unchanged results |

- [ ] **Step 4: Commit** — `feat(api): add account limits and a signup brake`

---

### Task 7C.2: Suspension and operator commands

**Files:**
- Create: `packages/db/src/admin/suspend.ts`, `unsuspend.ts`, `delete-user.ts`, `delete-group.ts`, `stats.ts`, `packages/db/src/admin/log.ts`, `packages/db/src/schema-admin.ts`, a migration
- Modify: `packages/db/package.json` and the root `package.json` (`"admin": "pnpm --filter @songphang/db admin"`, approved with the spec), `packages/db/src/schema-accounts.ts` (`users.suspended_at`), the session middleware and the sign-in services, `README.md`

**Interfaces — produces:**
- `pnpm admin <command> <argument>`: `suspend <email>`, `unsuspend <email>`, `delete-user <email>`, `delete-group <groupId>`, `stats`. Each destructive command prints what it will do and requires `--yes`. `delete-user` refuses while the user owns a group. `stats` prints counts only: users, verified users, groups, live transactions, users created today.
- `admin_log`: `id`, `command`, `target_id uuid`, `operator text` (the operating-system user name), `created_at`. Append-only: the migration revokes `UPDATE` and `DELETE` on it from the application role if the application uses a dedicated role; otherwise state in the README that it is append-only by convention.
- Suspension: sets `suspended_at` and deletes the user's sessions. The session middleware treats a suspended user as unauthenticated (401). Password, Google and Apple sign-in for a suspended user answer exactly as a wrong password does (`INVALID_CREDENTIALS`), after the same hash work.
- Scripts log the user id, never the email, to `admin_log`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Action | Expected |
|---|---|
| `pnpm admin suspend lan@…` without `--yes` | prints the plan; changes nothing |
| with `--yes`; Lan's existing session calls `GET /me` | 401 |
| Lan signs in with the right password | 401 `INVALID_CREDENTIALS`, identical to a wrong password, in a similar time (record both timings) |
| Lan's groups | unchanged; her member and expenses remain |
| `unsuspend`; sign in | works |
| `delete-user` for an owner | refused with the reason |
| `delete-group <id> --yes` | the group is gone; with phase 3, its files are queued for deletion |
| `stats` | five counts; no personal data |
| `admin_log` | one row per executed command |
| an unknown email | "not found", exit code 1 |

- [ ] **Step 4: Commit** — `feat(db): add account suspension and operator commands`

---

### Task 7C.3: Stage gate 7C

- [ ] **Step 1:** Acceptance script: 7C.1 rows 1, 3, 6; 7C.2 rows 2, 3, 5.
- [ ] **Step 2:** The gate of the common file, with default limits.

---

### Task 7D.1: Error alerts

**Files:**
- Create: `apps/api/src/alerts/error-reporter.ts` (interface, selection, the throttle), `apps/api/src/alerts/webhook-reporter.ts`, `apps/api/src/alerts/console-reporter.ts`
- Modify: the API's error handler, the worker's job failure hook (when the worker exists), `apps/api/src/config.ts`, `.env.example`

**Interfaces — produces:**
- `interface ErrorReporter { report(event: { kind: "http_5xx" | "job_failed" | "backup_failed" | "backup_check_failed" | "startup_failed"; code: string; route?: string; requestId?: string }): void }` — never throws, never awaits in the request path.
- `route` is the route **pattern** (`/groups/:groupId/transactions`), never the concrete path.
- Throttle: per `(kind, code, route)`, the first event is sent at once; further ones are counted and one summary with `count` is sent when 10 minutes have passed.
- `ALERT_PROVIDER` = `webhook` (requires `ALERT_WEBHOOK_URL`, an `https://` address; the body is `{ "text": "…" }` plus the event fields, sent with `fetch` and a 5-second timeout; a failed send is logged once per 10 minutes), `console`, or unset (no reporting; allowed in development only: production requires `webhook`).

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 5)** — `ALERT_PROVIDER=console`; add a development-only route that throws, behind `APP_ENV !== "production"`, used for this exercise and removed before the commit.

| Action | Expected |
|---|---|
| call the throwing route once with a body containing an email and an amount | one alert line: kind, code `INTERNAL`, the route pattern, the request id; no email, no amount, no path id |
| call it 50 times within a minute | no further line until the window ends, then one with `count: 50` |
| a 404 and a 400 | no alert |
| a job that fails all its retries (worker present) | one `job_failed` alert naming the job, no payload |
| `APP_ENV=production` without `ALERT_PROVIDER` | the API refuses to start |

- [ ] **Step 4: Commit** — `feat(api): add throttled error alerts`

---

### Task 7D.2: Deep health and verified backups

**Files:**
- Create: `apps/api/src/routes/health-deep.ts`, `infra/backup/check.sh`, a table `ops_status` (`key text PRIMARY KEY`, `ok boolean`, `detail text`, `updated_at`) with its migration and queries
- Modify: `infra/backup/backup.sh` and `run-loop.sh` (write `ops_status` rows `backup` and `backup_check`; report failures), `infra/Caddyfile` (`/api/v1/health/deep` is not routed from outside), `infra/compose.prod.yml`

**Interfaces — produces:**
- `GET /api/v1/health/deep`: requires the header `X-Health-Token` equal to `HEALTH_TOKEN` (constant-time comparison; else 404). Answers 200 or 503 with `{ database, queue?, storage?, backup, backupCheck }`, each `"ok"` or `"fail"`, no detail text. `backup` fails when its row is older than 26 hours or not ok; `backupCheck` when older than 8 days or not ok.
- `check.sh`: download the newest backup, decrypt it, restore into a scratch database in the container's own Postgres, run the balance check, drop it, write `ops_status`. **The two specs pull apart here:** the server step keeps the private key off the VM, and an automatic check needs it there. The plan's resolution: the automatic Sunday 03:30 check runs only when `BACKUP_CHECK_IDENTITY_FILE` is set (an identity file mounted read-only into the backup container); without it, `backupCheck` is reported as `"manual"`, never fails health, and the owner runs the same `check.sh` from their own machine monthly, as the runbook describes. Record this in `decisions.md` as a decision for the owner to confirm.
- Backup and check failures call the alert webhook directly with `curl` from the script, with the kind and the stage only.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Exercise** — on the local production-like stack.

| Action | Expected |
|---|---|
| deep health without the token, through Caddy and directly | 404 |
| with the token, directly | 200, all `ok` after a backup and a check have run |
| date the `backup` row 27 hours back | 503, `backup: "fail"` |
| run `check.sh` on a good backup | `backupCheck` ok |
| truncate the newest backup, run `check.sh` | fails; the row is not ok; one alert line; the scratch database is gone |
| stop the queue's schema (worker present) | `queue: "fail"` |

- [ ] **Step 3: Commit** — `feat(infra): add deep health and weekly backup verification`

---

### Task 7D.3: Runbooks; SAD review; stage gate

**Files:**
- Create: `docs/runbooks/recovery.md`, `docs/runbooks/incident.md`
- Modify: `docs/runbooks/deploy.md` (the outside uptime monitor; the alert webhook; the health token; the check's two modes)

Requirements: spec sections 6.3 and 6.4. `recovery.md` is rehearsed: follow it on the local stack from "the VM is gone" (`down -v`, images removed) to a working service from a backup, time it, and write the measured time beside the 4-hour objective. `incident.md` has one section per action of spec 6.4, each with the exact commands (`REGISTRATION_OPEN=false` and restart; `pnpm admin suspend`; rotating `SESSION` secrets if any exist, the SMTP password, the AI key, the Telegram token and webhook secret, the health token, the backup key; revoking every session with one SQL statement; stopping Caddy), and a last section "Telling people" left with the headings the lawyer must fill in. Record the capacity trigger of spec 6.3 in `deploy.md` with the command that shows open event streams.

- [ ] **Step 1: Write them; rehearse the recovery**
- [ ] **Step 2: Stage gate 7D.** Acceptance script: 7D.1 rows 1–3; 7D.2 rows 1–3. Then the gate of the common file.
- [ ] **Step 3: Commit** — `docs(runbook): add recovery and incident runbooks`

**Manual checks for the project owner**
1. Follow `recovery.md` once on a spare machine or the VM. Time it.
2. Point an outside uptime monitor at `/api/v1/health` as `deploy.md` describes.

---

### Task 7E.1: Hardening

**Files:**
- Modify: the web app's request middleware (a per-request nonce; read the installed Next.js version's documentation for Content-Security-Policy with nonces, and record the mechanism), `infra/Caddyfile` (the policy moves to the web app for pages; Caddy keeps the other headers and a strict policy for `/api/*`), the session service (lifetimes), S13 (`Đăng xuất khỏi mọi thiết bị`), `apps/api/src/routes/me.ts` (`POST /me/sessions/revoke-all`, keeping the current one unless `{ includeCurrent: true }`)

Requirements: spec section 7, item 2. Final policy for pages: `default-src 'self'; script-src 'self' 'nonce-…' 'strict-dynamic'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'`. `Permissions-Policy: camera=(self), microphone=(), geolocation=(), payment=()`. `Cross-Origin-Opener-Policy: same-origin`. Session rules written into the README: absolute lifetime and idle timeout as the code has them; if no idle timeout exists, add one of 30 days and record it.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check` and `pnpm build`**
- [ ] **Step 3: Exercise** — on the production-like stack: every screen opened with the console open, including the camera chooser, the QR screen, Google's redirect start; no violation; a script tag injected through the browser's developer tools without the nonce is blocked; `revoke-all` signs out a second browser within one request.
- [ ] **Step 4: Commit** — `feat(web): tighten content security policy and session controls`

---

### Task 7E.2: Self-audit

**Files:**
- Create: `docs/security/self-audit.md`

Procedure:
1. Generate the list of every method and path from `packages/contract`'s OpenAPI output. One table row per entry: authentication required?; minimum role and where it is enforced (file and line); request schema; rate limit; idempotency; verified by which gate exercise.
2. Replay the complete permission matrix of every merged phase on a reset database. Paste the result table.
3. Run the `security-review` skill over the whole repository, section by section, answering each item with evidence (a file and line, or a command and its output).
4. `pnpm audit --prod`. List every advisory with severity and whether the vulnerable path is reachable; fix what has a patch release within the same major version; anything else is a recorded decision.
5. Search the git history for secret-shaped strings: `git log -p --all | rg -n "(?i)(secret|password|api[_-]?key|token)\s*[:=]\s*['\"][^'\"]{12,}"` and for private key headers. Every hit explained.
6. `rg` the code base for `dangerouslySetInnerHTML`, `eval(`, `new Function`, `innerHTML`, string-built SQL (`sql.raw`, template strings passed to a query), `Math.round`, `toFixed`, `parseFloat` on the money path. Every hit explained or fixed.
7. Every log statement in `apps/api` and `apps/worker` read once for personal data.
8. Findings table: id, severity, description, fixed in commit or open with the reason.

- [ ] **Step 1: Do the eight items; fix findings in their own commits (`fix(scope): …`)**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Commit** — `docs(security): add self-audit`

---

### Task 7E.3: Review brief; final gate

**Files:**
- Create: `docs/security/review-brief.md`
- Modify: `README.md`

Brief contents: spec section 7, item 3. Include how to start the production-like stack locally, four ready-made roles in one group (created by a documented sequence of commands, not by committed credentials), the threat list (every "Review Focus" line of every merged phase's plan, deduplicated), what is out of scope (denial of service by volume, the VM's operating system), and the report format (finding, steps, impact, suggested fix).

- [ ] **Step 1: Write it**
- [ ] **Step 2: Non-functional checks.** Landing page: under 100 KB transferred excluding the font, no layout shift on load, readable with JavaScript disabled. Legal pages and the consent screen: keyboard and screen-reader pass.
- [ ] **Step 3: Final gate** — the full gate of the common file on the development setup **and** the server step's gate (its task S.7, steps 2–4) on the production-like stack, replaying every phase.
- [ ] **Step 4: Finish the run files.** `manual-checks.md`: landing and identity; consent; export (open your own file and read it); limits; operator commands; alerts; recovery. `progress.md`: "Not verified" must include the legal sufficiency of the texts, real alert delivery, the outside monitor, and the independent review.
- [ ] **Step 5: Commit** — `docs(security): add review brief`

**Manual checks for the project owner**
1. Read `docs/security/self-audit.md`'s findings table. Every open finding needs your decision before opening.
2. Hand `docs/security/review-brief.md` to the reviewer you chose.
3. Do not open the product before the lawyer has read the two texts and the reviewer's findings are closed.
