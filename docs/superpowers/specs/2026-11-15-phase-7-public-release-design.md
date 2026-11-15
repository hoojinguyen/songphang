# Phase 7 — Public Release ("Phát hành công khai") — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` first; its sections 4 and 5 apply here.

## 1. Intent

Open the application to anyone in Vietnam, free of charge. Until now every user was someone the owner knows. Phase 7 is what must be true before a stranger can find the product, register, create a group and invite friends with nobody's help, and before the owner can sleep while they do.

**Entry condition (roadmap):** the owner has used the product and decided to open it. The server step is done.

**Goals:** an identity and a page that explains the product; lawful handling of personal data; limits that keep one abuser from hurting everyone; knowing when something breaks and being able to recover; a security review by someone who did not build it.

**Non-goals:** payments, premium features, advertising; an admin web interface; several API processes; English; marketing.

**Anti-goals:** legal texts that claim more than the system does; a limit that an ordinary group of friends ever hits; an alert channel that leaks personal data; opening before the review's findings are closed.

## 2. Scope and stages

| Stage | Adds |
|---|---|
| 7A | Wordmark and icon; landing page; metadata for sharing and search |
| 7B | Terms and privacy pages; recorded consent; personal data export; retention jobs |
| 7C | Account and system limits; signup brake; suspension; cleanup of unverified accounts |
| 7D | Error alerts; deep health; verified backups; recovery runbook; review of SAD section 10 |
| 7E | Self-audit, hardening, and the package for an independent reviewer |

**No new library.**

## 3. Identity and landing page (7A)

- **Wordmark:** `Sòng Phẳng` in Be Vietnam Pro weight 900 with negative tracking, in the main text color. **Mark:** the four member shapes (`circle`, `diamond`, `squircle`, `leaf`) in their four colors, in a 2 × 2 arrangement on the page background color. Both are SVG files in `apps/web/public/brand/`, drawn by the agent from the existing tokens. This is a placeholder-quality identity built from the design language, not a commissioned logo; the owner may replace the two files at any time without code changes.
- **Icons:** favicon (SVG), a 180-pixel touch icon and 192/512-pixel icons rendered from the mark with Next.js's built-in icon routes; a web manifest (`name`, `short_name` `Sòng Phẳng`, theme and background colors from the tokens, `display: standalone`).
- **Landing page:** a signed-out visitor at `/` sees it; a signed-in user at `/` sees the group list as today. Static, no data, no tracking, no third-party request.

| Block | String |
|---|---|
| Headline | `Chia tiền, gõ như nhắn tin.` |
| Sub-line | `Gõ "lẩu 600k chia 4" là xong. Sòng Phẳng tính ai nợ ai, đến từng đồng.` |
| Primary button | `Bắt đầu miễn phí` (to `/register`) |
| Secondary link | `Đăng nhập` |
| Three points | `Gõ một câu` / `Không cần form. Viết khoản chi như đang nhắn cho bạn.` · `Sòng phẳng từng đồng` / `Chia đều, chia theo món, chia theo phần. Không lệch một đồng.` · `Trả bằng mã QR` / `Quét là chuyển, số tiền và nội dung điền sẵn.` |
| Closing line | `Miễn phí. Không quảng cáo.` |
| Footer | `Điều khoản` · `Quyền riêng tư` · `Liên hệ` (a `mailto:` to `SUPPORT_EMAIL`) |

The third point is shown only when phase 2 is merged; the "chia theo món" phrase only when phase 3 is. The plan carries the layout numbers.

- **Metadata:** title `Sòng Phẳng — Chia tiền nhóm`, description from the sub-line, Open Graph image rendered from the mark and the headline, `robots.txt` that allows `/`, the legal pages, and nothing under `/g/`, `/join/`, `/api/`; `noindex` on every signed-in page and on `/join/*`.

## 4. Personal data (7B)

Written against Law 91/2025/QH15 and Decree 356/2025/NĐ-CP. **The advisor is not a lawyer.** The texts below are drafted to describe truthfully what the system does; the owner has them read by a lawyer before opening, and that is a prerequisite recorded in section 12.

### 4.1 Pages

`/dieu-khoan` and `/quyen-rieng-tu`: static pages, content in `apps/web/src/content/legal/` as typed TypeScript (headings and paragraphs), versioned by a date constant `LEGAL_VERSION`. The advisor writes both full texts in Vietnamese and adds them with the plan. The privacy text must state, and the code must match:

| Topic | What it says |
|---|---|
| Who controls the data | The owner, with the contact address |
| What is collected | Email, display name, password hash, Google or Apple identifier; groups, members, transactions, comments, payment details entered; photos of receipts; technical logs (IP address, user agent, request ids) |
| Data about other people | A user may enter names and payment details of people who have no account; the user is responsible for having their agreement, and those people may ask the owner for removal |
| Purposes | Running the service; security; nothing else. No advertising, no sale, no profiling |
| Who receives it | Other members of the same group; the mail provider; the AI provider, only when the user photographs a receipt or types a sentence the application cannot read by itself; Telegram, only in a chat the group linked |
| Where it is stored | The VM's location and the backup location (filled in by the owner) |
| How long | Section 4.4 |
| Rights | See, correct, export, delete, withdraw consent; how to exercise each, in the application or by mail |
| Age | The service is for people aged 16 and over |

### 4.2 Consent

- `users` gains `legal_version text` and `legal_accepted_at timestamptz`.
- **Registration:** an unticked checkbox `Tôi đã đọc và đồng ý với Điều khoản và Chính sách quyền riêng tư, và tôi từ 16 tuổi trở lên.` with both names as links. The request carries `acceptLegalVersion`; the server refuses a missing or outdated version (400 `LEGAL_NOT_ACCEPTED`).
- **Google, Apple and existing accounts:** an account whose `legal_version` is not the current one is gated. Every route except `GET /me`, `POST /me/accept-legal`, sign-out, export and account deletion answers 403 `LEGAL_NOT_ACCEPTED`; the web app shows one screen: `Trước khi tiếp tục` / the same sentence / `Đồng ý và tiếp tục` · `Đăng xuất`.
- A changed text means a new `LEGAL_VERSION` and the same gate for everyone.
- **AI consent is separate and specific** (the law requires consent per purpose): the first time a user uses the camera button or an AI sentence reading, a dialog `Ảnh hoá đơn sẽ được gửi tới dịch vụ AI để đọc. Sòng Phẳng không dùng ảnh cho việc gì khác.` · `Đồng ý` · `Thôi`, recorded in `users.ai_consent_at`. Without it the camera is refused (403 `AI_CONSENT_REQUIRED`) and unparsed sentences stay with the rule reader. It can be withdrawn on the account screen.
- No cookie banner: the only cookie is the session cookie, which is strictly necessary. The privacy page says so.

### 4.3 Export

`GET /me/export` (2 per day per user) returns a JSON file `song-phang-du-lieu-{YYYYMMDD}.json`: profile; sign-in methods (provider names only); notification settings; consent records; for every group the user is in: name, role, the member linked to them with its payment details, and the transactions, comments and settlement requests **the user created or is part of**. It does not contain other members' payment details or anything from groups the user has left. Account screen: `Tải dữ liệu của tôi`.

### 4.4 Retention

| Data | Kept | Mechanism |
|---|---|---|
| Unverified accounts | 7 days | Daily job deletes them |
| Expired sessions, used or expired one-time tokens, idempotency keys | 30 days after expiry | Daily job |
| Notifications | 90 days | Exists from phase 4 |
| `ai_calls` | 13 months | Daily job |
| Application logs | 30 days | Docker log rotation by size, plus the runbook's statement |
| Backups | 30 copies | Exists from the server step |
| A deleted account | Removed at once from the live database; gone from backups within 30 days | The privacy text says exactly this |
| A deleted group | As above; its uploaded files are deleted by the phase 3 job | |

Account deletion (FR-1.9) is extended: it also deletes the user's notifications, chat identities, push devices and export limits (by cascade), and keeps their member and comment author **names** in groups, as the phase 1 deletion screen already tells them.

## 5. Abuse limits (7C)

One module, `apps/api/src/limits.ts`, holds every number; each is overridable by an environment variable.

| Limit | Default | Answer when hit |
|---|---|---|
| Groups a user owns | 20 | 422 `LIMIT_REACHED` |
| Groups a user is in | 50 | 422 `LIMIT_REACHED` |
| Members per group | 100 (exists) | |
| Live transactions per group | 10,000 (SAD section 10) | 422 `LIMIT_REACHED` |
| Transactions a user creates per day | 500 | 429 |
| Comments per user per day | 500 | 429 |
| Registrations per IP | 5 per hour (exists), 20 per day | 429 |
| Registrations in the whole system per day | 500 | 503 `SIGNUPS_PAUSED` |
| Any request per IP | 600 per minute | 429 |
| Request body | 100 KB (exists; 6 MB for uploads) | 413 |

- `SIGNUPS_PAUSED` is the same for every email, so it reveals nothing about accounts. `REGISTRATION_OPEN=false` forces it. The register screen then shows `Sòng Phẳng đang tạm ngừng nhận đăng ký mới. Hãy quay lại sau.`
- Limit messages in the web app: `Bạn đã đạt giới hạn {limit}. Liên hệ chúng tôi nếu bạn cần nhiều hơn.` with the `mailto:` link.
- **Rate limiter storage stays in memory** in the single API process (section 6.3).
- **No CAPTCHA.** It is a third-party service on the registration path and a tracking surface; email verification, the per-IP limits, the system brake and the 7-day cleanup come first. Revisit only if the brake is ever hit by abuse.
- **Suspension:** `users.suspended_at`. A suspended user's sessions are revoked and sign-in answers the ordinary `INVALID_CREDENTIALS`. Operated from the command line on the server: `pnpm admin suspend <email>`, `unsuspend`, `delete-user`, `delete-group <id>`, `stats` (counts only). These are new `package.json` scripts, approved with this spec; each writes one line to an append-only `admin_log` table (who ran it is the operating-system user, what, when).
- **Report:** the footer's contact link; the terms state what is not allowed and that accounts may be suspended.

## 6. Operations (7D)

### 6.1 Alerts

`ErrorReporter` in `deps`: `report(event)`. Adapters: `webhook` (`ALERT_WEBHOOK_URL`; a JSON `POST` with `fetch`) and `console`. Reported: every 5xx, every failed job after its last retry, every failed backup or backup check, a failed start-up check. An event carries the error code, route pattern, request id and count, and **never** a body, a header, an email, a name or an amount. At most one alert per distinct event per 10 minutes, with a count.

### 6.2 Health and backups

- `GET /health` stays shallow. New `GET /health/deep` (database round trip, queue reachable, storage directory writable, last backup age), answering only to requests from the Compose network or carrying `HEALTH_TOKEN`.
- **Backup check:** every Sunday the backup service restores the newest backup into a scratch database inside its own container, runs the balance check on it, drops it, and reports the result. A check older than 8 days, or a backup older than 26 hours, turns `/health/deep` unhealthy and raises an alert.
- An outside uptime monitor pinging `/health` every minute is the owner's to set up; the runbook says how. The agent creates no account anywhere.

### 6.3 SAD section 10, reviewed

| Accepted limit | Decision for opening |
|---|---|
| One server, no standby | **Kept.** Stated in the terms as "no guaranteed availability". Recovery objectives: lose at most 24 hours of data, be back within 4 hours, both proven by the runbook's rehearsal |
| Event hub and rate limits in memory, one API process | **Kept.** One process serves several thousand connections. The trigger to change is written down: sustained CPU above 70 % or more than 2,000 open streams |
| No writing while offline | Kept |
| Balances computed on each read | Kept; the 10,000-transaction limit of section 5 guards it |

### 6.4 Runbooks

`docs/runbooks/recovery.md` (VM lost: new VM to working service from a backup, step by step, timed during rehearsal), `docs/runbooks/incident.md` (how to pause registration, suspend a user, rotate each secret, revoke every session, take the site down safely, and whom the law requires to be told after a data breach and within what time; the lawyer confirms the last part).

## 7. Security review (7E)

1. **Self-audit by the agent.** For every endpoint in the OpenAPI file: authentication, authorization (the whole permission matrix of every phase, replayed), validation, rate limit, error shape. Then the `security-review` checklist over the whole repository, `pnpm audit`, a search of the git history for secret-shaped strings, and a header check. Output: `docs/security/self-audit.md` with one line per endpoint and every finding, fixed or open.
2. **Hardening found necessary in advance:** remove `'unsafe-inline'` from `script-src` by adding a per-request nonce in the web application's request middleware (the agent reads the installed Next.js version's documentation for the current mechanism); `Permissions-Policy` limiting camera to the application itself; `Cross-Origin-Opener-Policy: same-origin`; session cookie lifetime and idle timeout reviewed and written down; sign-out of all sessions offered on the account screen (`Đăng xuất khỏi mọi thiết bị`).
3. **Package for the independent reviewer:** `docs/security/review-brief.md`: scope, architecture in one page, the threat list (the five failure modes of the phase 1 plan and those of later phases), test accounts on a staging copy, what is out of scope, how to report.
4. **The independent review itself is not done by the implementation agent or the advisor**, since both built or designed the system. Who does it is the owner's decision (section 12). Its findings are fixed as new commits and the review record is kept in `docs/security/`.

`docs/security/` and the two runbooks are new files the implementation agent may write during this run.

## 8. Screens changed

| Screen | Change |
|---|---|
| `/` signed out | Landing page |
| S1, `/register` | Footer links; the consent checkbox; the signups-paused state |
| Consent gate | New, section 4.2 |
| S13 Account | `Tải dữ liệu của tôi`; `Đăng xuất khỏi mọi thiết bị`; `Cho phép gửi ảnh hoá đơn tới AI` switch; links to the two legal pages |
| Every screen's footer area on S2 | `Điều khoản · Quyền riêng tư` |

## 9. Gate acceptance scripts (outline)

- **7B:** registering without the version is refused; a gated account gets 403 on a group route and 200 on export and delete; the export of a user contains none of another member's payment details; the unverified-account job deletes an 8-day-old account and keeps a 6-day-old one.
- **7C:** the 21st owned group is refused; with `REGISTRATION_OPEN=false` a known and an unknown email get the identical 503; a suspended user's existing session answers 401.
- **7D:** a forced 500 prints one alert containing no personal data, and a burst of the same error prints one more with a count; the backup check passes on a good backup and fails loudly on a truncated one.
- **7E:** the self-audit table has a row for every path in the OpenAPI file; no CSP violation is logged on any screen with the nonce policy.

## 10. Not verified by the agent

The legal sufficiency of the texts; real alert delivery; the outside monitor; the recovery time on a real VM; everything the independent reviewer finds.

## 11. Changes to standing documents

| Document | Change |
|---|---|
| `docs/03-srs.md` | New section for phase 7 requirements (FR-7.x, NFR-7.x) from sections 3–7 |
| `docs/04-adr.md` | ADR-027: consent is versioned and gates the API. ADR-028: one API process is kept for the public release, with a written trigger |
| `docs/04-sad.md` | Section 10 replaced by section 6.3 above |
| `docs/05-database-design.md` | New columns on `users`; `admin_log` |
| `docs/05-api-spec.md` | Export, consent, deep health, new error codes and limits |
| `docs/02-prd.md` | Metrics for the public stage (section 6 of the PRD says they are set before phase 7): registrations that create a group within a day; groups active after 30 days; balance errors, always 0 |

## 12. Owner's prerequisites

- Decide to open (the roadmap's entry condition).
- A lawyer's reading of the two texts and of the breach-notification part of the incident runbook.
- The official domain and the trademark lookup.
- Choose the independent reviewer: a security professional (strongest), a developer friend with the review brief, or, at the least, a separate AI model given only the brief and the repository.
- A support mail address.
