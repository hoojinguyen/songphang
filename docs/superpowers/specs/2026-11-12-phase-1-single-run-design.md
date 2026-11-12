# Phase 1 in a Single Agent Run — Design

Date: 2026-11-12. Status: approved by the project owner on 2026-11-12.

This document records how phase 1 ("Lõi chia tiền", milestones 1A–1E) will be built in one continuous agent run, and every product and technical decision that run needs so the implementation agent never has to wait for an answer. The implementation plan is written from this document after it is approved.

## 1. Intent

**What the project owner asked for (2026-11-12):**

- One agent run builds a whole milestone, without stopping for approval after each task.
- Codex implements. Claude is the advisor (writes the spec and the plan) and the reviewer.
- The spec and the plan are agreed between the owner and the advisor before the run starts.

**Owner's answers during design:**

| Question | Answer |
|---|---|
| What is "a milestone" for one run? | All of phase 1: 1A through 1E. |
| Google sign-in needs an OAuth app the agent cannot create. | Codex writes it without real credentials. It stays unverified until the owner creates the app. |
| What does Codex do when the spec is silent? | It decides, records the decision, and continues. It never stops and never leaves a piece unbuilt. |
| Who designs the screens that have no mockup? | The advisor describes them in words in this spec (section 9). No mockups. |
| Where does the code land? | A dedicated branch `phase-1`, one commit per task, merged to `main` after review and manual checking. |
| Run structure | One spec, one plan, five stages with a self-run gate after each. |

**Success looks like:** the owner starts Codex with one fixed prompt (repeating it only when a Codex session runs out), and comes back to a branch where phase 1 works on the local machine, with a decision log, a gate record, and one manual-check list.

**Assumption:** the goal is fewer hand-offs and approvals, not less review. Review and the owner's manual check still happen, once, at the end.

## 2. Roles and lifecycle

| Step | Who | Output |
|---|---|---|
| 1. Spec | Advisor writes, owner approves | This file |
| 2. Plan | Advisor writes, owner approves | `docs/superpowers/plans/2026-11-12-phase-1/` (an overview and one file per stage), replacing the 1A plan |
| 3. Working rules | Advisor | `AGENTS.md`, `execute-task`, `review-code`, `docs/` amendments (section 11) |
| 4. Run | Codex, on branch `phase-1` | Code; the three run files (section 3.3) |
| 5. Review | Advisor | Findings by commit, ordered by severity |
| 6. Fix | Codex | New commits on `phase-1` |
| 7. Manual check and merge | Owner | Merge to `main` |

The owner sees no screen with their own eyes before step 7. Visual deviations accumulate until then; this is accepted.

## 3. Run mechanics

### 3.1 Per task

The six steps of `execute-task` stay, with two changes: **Report** is appended to `progress.md` instead of being sent to a person, and **Stop** becomes **continue with the next task**. One commit per task. `pnpm check` must pass before every commit.

### 3.2 Stage gate

After the last task of each stage (1A, 1B, 1C, 1D, 1E) Codex runs, in order:

1. `pnpm check` and `pnpm build`.
2. `pnpm db:check-balances` — every group's balances sum to 0, and every transaction's payer and share totals equal its amount.
3. The stage's acceptance script: a sequence of `curl` calls against a freshly reset database, with the expected numbers written in the plan. The scripts of all earlier stages are run again.
4. The permission matrix: every `groupId` endpoint that exists so far, called as owner, editor, viewer and outsider, compared with the SRS permission table. (Before 1B only owner and outsider exist.)

A failing gate is fixed until it passes. If the same gate still fails after three fix attempts, Codex records the exact failure in `progress.md` under "Gate not passed" and continues with the next stage. This is the only way past a gate, and it is the first thing the reviewer reads.

What Codex cannot verify (anything that needs human eyes; Google with real credentials) is listed under "Not verified" in `progress.md`. Silence is not allowed.

### 3.3 Run files

Codex writes three files under `docs/superpowers/runs/phase-1/`. They are the only exception to "implementation agents do not edit `docs/`".

| File | Content |
|---|---|
| `progress.md` | Task checklist; per task: commit hash and the real exercise output; per stage: gate results, "Gate not passed", "Not verified" |
| `decisions.md` | One entry per decision made without the owner: problem, options considered, choice, reason. A new library adds license, maintenance state and added size |
| `manual-checks.md` | The owner's check list, organized by screen and flow rather than by task, including invalid cases |

### 3.4 Autonomy

Codex decides everything this spec and the plan leave open, records it in `decisions.md`, and continues. This replaces the "must ask" column of `AGENTS.md` section 5 for the duration of the run.

These are not decisions and stay absolute:

- The hard security rules of `AGENTS.md` section 9.
- `AGENTS.md` section 11: no invented results, no external services, no deployment, no account creation, no emoji.
- No automated tests.
- No `push`, no force, no history rewriting. Work only on `phase-1`.
- The money rules: integers only; division and rounding only in `packages/core`.

When two documents conflict, Codex follows the priority order of `AGENTS.md` section 2 (this spec and the plan rank above `docs/`), records the conflict in `decisions.md`, and continues.

### 3.5 One prompt

A single prompt is reused verbatim for every Codex session: read `AGENTS.md`, this spec and the plan; open `progress.md`; continue from the first unchecked task to the end. When a session runs out, the owner opens a new one with the same prompt.

### 3.6 Review

The advisor, after the run:

1. Reads `decisions.md`, "Gate not passed" and "Not verified" first.
2. Re-runs every gate locally; Codex's recorded results are not trusted.
3. Reads the diff stage by stage, concentrating on what manual checking covers worst: the money layer (`core`, triggers, rounding), authorization, and accounts (password hashing, single-use tokens, no account enumeration).
4. Writes findings by commit, ordered by severity. Codex fixes them in new commits; the advisor re-reviews the fixes.

### 3.7 Accepted risks

- Codex's exercises are self-graded. `curl` gates catch logic and permission errors, not visual ones.
- Review is reading and re-running, not automated testing. At this volume some defects will reach the owner's manual check.
- The final manual check is long: several hours for five stages.
- Google sign-in ships unverified.

## 4. Scope

All of `docs/03-srs.md` section 2, in roadmap order.

| Stage | Adds | SRS |
|---|---|---|
| 1A | Groups, members, equal-split expenses, balances, minimized and pairwise settlements | FR-1.10–1.12, 1.20–1.23, 1.25, 1.40, 1.41, 1.47–1.50, 1.60–1.63 |
| 1B | Accounts (email and password, Google), invites and QR, three roles, leaving, realtime, rate limits | FR-1.1–1.9, 1.14, 1.24, 1.30–1.36, 1.80, NFR-1.12–1.14 |
| 1C | Exact, weighted and percent splits; several payers; transfers; income; recording a settlement | FR-1.42–1.44, 1.51–1.56, 1.64 |
| 1D | Rule-based sentence reader, confirmation card, sample list | FR-1.90–1.100 |
| 1E | Edit, delete, restore, history, deleting a group, offline state, motion, remaining NFRs | FR-1.13, 1.45, 1.46, 1.70, 1.71, 1.81, 1.82, NFR-1.4, 1.9, 1.11 |

**Decisions already made by the owner on 2026-11-12, kept:** FR-1.63 (pairwise mode) is built in 1A; the member palette stays at 4 shapes × 4 colors.

**Left out of this run, with reasons:**

| Item | Reason | Goes to |
|---|---|---|
| "Bơm hình" (hold a shape to grow a share) | A gesture cannot be verified by `curl` or by reading code; the number fields do the same job and are the accessible path | Waiting list |
| Activity lines inside the expense stream ("Minh đã sửa…", "Hùng đã vào nhóm") | Interleaving two paginated sources in one stream is complex; history has its own screen (S6) | Waiting list |
| 6 × 8 member palette, desktop layout | Not designed | Design backlog |
| NFR-1.6 HTTPS, NFR-1.10 backups, real mail delivery | Belong to "Đưa lên máy chủ" | Server step |

The stream still shows transfers and income as centered pills, because they are transactions, and marks an edited transaction with a "đã sửa" tag.

## 5. Technical decisions across stages

### 5.1 Libraries

Two new third-party packages, approved by the owner on 2026-11-12:

| Package | Use | Why not hand-written | License, size |
|---|---|---|---|
| `arctic` 3.7.0 | Google OAuth flow | The flow cannot be exercised against Google in this run; verified code is safer than new code | MIT, 154 KB, three small dependencies |
| `uqr` 0.1.3 | Invite QR code as SVG | QR encoding is far beyond a few dozen lines | MIT, 79 KB, no dependencies |

Everything else uses what is installed or built in: SSE with Hono's streaming helper, rate limiting in memory, mail printed to the console, the sentence reader as plain TypeScript. Better Auth is **not** used (ADR-017, section 11): it owns its own user, session and account tables and would discard the session layer verified in phase 0 and the approved `user_identities` design.

A common-password list (`apps/api/src/auth/common-passwords.txt`: 10,000 entries, 73 KB, the file `Passwords/Common-Credentials/10k-most-common.txt` of the MIT-licensed SecLists project, downloaded on 2026-11-12) was added to the repository by the advisor together with the plan. Codex does not download anything.

### 5.2 Money

- One rounding function in `core` serves every split: exact fractions computed with `BigInt`, integer part to each member, leftover đồng to the largest fractional parts, ties to the lower `position` (FR-1.56). `splitEqually` from 1A becomes a call to it.
- Weights and percentages arrive as decimal strings with at most two decimals and are scaled to integers before any arithmetic. No float touches them.
- A transfer is stored as one payer (sender) and one share (receiver). Income is stored like an expense and its sign is inverted when balances are summed (`docs/05-database-design.md` section 7).
- Pairwise debts with several payers: each share is attributed to the payers in proportion to what they paid, through the same rounding function, in `core`.
- The integrity triggers of 1A stay in force for every transaction type.

### 5.3 Authorization

One middleware for every `groupId` route, as in SAD section 5. Outsiders and malformed ids get 404. The SRS permission table is the reference; the stage gate replays it.

Accounts whose email is not verified can sign in and read their own profile, and nothing else: every route that creates or changes data, and joining a group, answers 403 `EMAIL_NOT_VERIFIED` (FR-1.5).

### 5.4 Realtime

As SAD 6.3 and ADR-008: an in-memory hub per group; `GET /groups/{groupId}/events`; `changed` events naming resources, emitted after the database transaction commits; `removed` when the user is removed or the group is deleted, after which the server closes that user's connections; a keep-alive line every 25 seconds. The web app invalidates the named queries, and all of the group's queries after a reconnect.

### 5.5 Offline

The banner and disabled write controls follow `navigator.onLine` and failed requests. "Still viewable" means the data already in the query cache of the open tab; nothing is persisted to disk.

## 6. Accounts (1B)

### 6.1 Data

- `user_identities` as in `docs/05-database-design.md`.
- `auth_tokens`: `id`, `user_id` (cascade), `purpose` (`verify_email` or `reset_password`), `token_hash` (unique), `expires_at`, `used_at`, `created_at`. Only the SHA-256 of a token is stored. Verification tokens live 24 hours; reset tokens 1 hour; both are single-use.

### 6.2 Passwords

- Hash: argon2id from `node:crypto` (verified present on Node 26.12.1 on 2026-11-12). Parameters: memory 19,456 KiB, 2 passes, parallelism 1, 16-byte random salt, 32-byte tag. Stored in PHC string format; compared with `timingSafeEqual`. The root `engines.node` minimum is raised to the first Node release that ships `crypto.argon2`.
- Rules: 10 to 128 characters; rejected when the lower-cased password, or that password with its trailing digits and punctuation removed, is in the common-password list (FR-1.4). The second test is needed because only 51 of the list's 10,000 entries are 10 characters or longer.

### 6.3 No account enumeration (NFR-1.13)

- **Register** always answers 204 and never creates a session. A new email gets a verification mail; an existing email gets a mail saying an account already exists. The password is hashed in both cases so timing does not differ. The user then signs in.
- **Sign in** answers 401 `INVALID_CREDENTIALS` for an unknown email and for a wrong password alike, and runs a hash comparison in both cases.
- **Forgot password** always answers 204.

### 6.4 Sessions

- Reset password revokes every session of the account (FR-1.6). Change password requires the old password and optionally revokes the other sessions (FR-1.7).
- `loginPath` points to `/login`. The dev login page stays for development and is linked from `/login` only when enabled.

### 6.5 Google

- Authorization-code flow with PKCE through `arctic`. `state` and the code verifier travel in HttpOnly cookies that live 10 minutes. The `redirect` parameter is validated on the server with the same rule as the web app's `safeNext`.
- Google's `email_verified` must be true.
- First sign-in creates the user (verified) and a `google` identity. An email that matches a **verified** password account signs into that account and adds the identity. An email that matches an **unverified** password account is not linked: the user lands on `/login` with the message in section 9.1 (FR-1.8).
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are optional environment variables. Without them the Google routes answer 404 and the button is hidden. `GET /auth/providers` tells the web app which sign-in methods are available.
- **Not verified in this run.** `manual-checks.md` gets a separate section for the day the owner creates the OAuth app, with the exact redirect URI `http://localhost:3000/api/v1/auth/google/callback`.

### 6.6 Mail

A `mailer` in `deps` with one method. In development it prints the mail, including its link, to the API console (NFR-1.14). With `APP_ENV=production` and no real mailer, the API refuses to start. Links are `/verify-email?token=…` and `/reset-password?token=…` on `WEB_ORIGIN`.

### 6.7 Deleting an account (FR-1.9)

`DELETE /me` requires the account's email typed as confirmation. While the user owns any group it answers 422 `OWNER_REQUIRED`. Otherwise the user row is deleted; `group_users` rows cascade; members and transactions stay.

### 6.8 Rate limits

In memory, fixed windows, per process. 429 `RATE_LIMITED` with `Retry-After`.

| Action | Limit |
|---|---|
| Sign in | 10 per 15 minutes per IP; 5 per 15 minutes per email |
| Register | 5 per hour per IP |
| Resend verification | 3 per hour per user |
| Forgot password | 3 per hour per email; 10 per hour per IP |
| Any write | 60 per minute per user |
| Invite preview | 30 per minute per IP |
| Sentence parse | 120 per minute per user |

The client IP is the socket address. Trusting a proxy header is a server-step decision.

## 7. Invites and roles (1B)

- Link: `{WEB_ORIGIN}/join/{token}`; the QR code encodes the same link and is drawn in the web app with `uqr`.
- An unknown token and a disabled link both answer 404 `INVITE_INVALID`.
- The preview lists members with `claimed` and, for unclaimed members, their current balance (flow B shows it when a shape is selected). This exposes balances to any signed-in holder of the link, as the approved flow requires.
- Joining takes an unclaimed `memberId` or a `newMemberName`; a member claimed meanwhile answers 409 `MEMBER_ALREADY_CLAIMED`; joining twice is harmless. The role is the group's `default_role`.
- `PUT /groups/{groupId}/me/member` re-chooses "tôi là người này" among unclaimed members (FR-1.24).
- The owner changes roles, removes users, toggles and rotates the link, sets the default role, and transfers ownership. A group always has exactly one owner; the owner cannot leave (422 `OWNER_REQUIRED`).
- From 1B, the members screen offers deactivate and delete for every member, as FR-1.22 states. A user whose linked member is deleted has no linked member until they choose one again; the group screen then shows a prompt `Chọn hình của bạn trong nhóm` that opens the members screen.

## 8. Sentence reader (1D)

- A pure function in `core`: sentence, member list and the writer's member in; `status`, `draft`, `spans`, `issues` out, exactly as `docs/05-api-spec.md` section 3 defines. The API endpoint adds `shares` when `status` is `ok`.
- The grammar is FR-1.91–1.99, with no additions. Anything outside it is `unparsed`; the reader never guesses.
- The advisor delivers `docs/08-quick-entry-samples.md` with the plan: 75 sentences, including ones that must be refused, each with its expected result (FR-1.100). It is the measuring stick for the 1D gate: Codex runs every sample through the reader and records any mismatch.

## 9. Screens without a mockup

Each is built from existing components and tokens. Sizes follow the nearest designed screen; the plan carries the exact numbers. Strings below are final.

### 9.1 Sign-in (S1, extends GE7)

GE7 shows only "Tiếp tục với Google". S1 becomes: the four large shapes and the headline of GE7 at reduced height; then an email field, a password field, the primary button, the Google button when available, and two text links.

| Element | String |
|---|---|
| Headline | `Chia tiền, gõ như nhắn tin.` |
| Email label | `Email` |
| Password label | `Mật khẩu` |
| Primary button | `Đăng nhập` |
| Google button | `Tiếp tục với Google` |
| Links | `Tạo tài khoản` · `Quên mật khẩu?` |
| Wrong email or password | `Email hoặc mật khẩu không đúng.` |
| Too many attempts | `Bạn thử quá nhiều lần. Đợi một lúc rồi thử lại.` |
| Google email matches an unverified account | `Email này đã đăng ký bằng mật khẩu nhưng chưa xác minh. Hãy đăng nhập bằng mật khẩu và xác minh email trước.` |
| Dev link, development only | `Đăng nhập thử` |

GE7's line "Không cần mật khẩu. Bạn bè không phải cài gì." is dropped; it is no longer true.

### 9.2 Register (`/register`)

| Element | String |
|---|---|
| Title | `Tạo tài khoản` |
| Fields | `Tên hiển thị` · `Email` · `Mật khẩu` |
| Password hint | `Ít nhất 10 ký tự.` |
| Button | `Tạo tài khoản` |
| Too short | `Mật khẩu cần ít nhất 10 ký tự.` |
| Too common | `Mật khẩu này quá phổ biến. Hãy chọn mật khẩu khác.` |
| After submit | `Kiểm tra hộp thư của bạn` / `Nếu email này chưa có tài khoản, chúng tôi vừa gửi một thư xác minh. Sau đó hãy đăng nhập.` |
| Link | `Đã có tài khoản? Đăng nhập` |

### 9.3 Verify email

A signed-in, unverified user sees, on every screen, a banner instead of the write controls:

| Element | String |
|---|---|
| Banner | `Hãy xác minh email để tạo nhóm và ghi khoản chi.` |
| Button | `Gửi lại thư` |
| After resend | `Đã gửi lại thư xác minh.` |

`/verify-email?token=…`:

| State | String |
|---|---|
| Success | `Email đã được xác minh.` with button `Vào ứng dụng` |
| Bad, expired or used token | `Link xác minh không còn dùng được.` with button `Gửi lại thư` (when signed in) or `Đăng nhập` |

### 9.4 Forgot and reset password

| Screen | Element | String |
|---|---|---|
| `/forgot-password` | Title | `Quên mật khẩu` |
| | Hint | `Nhập email của bạn. Chúng tôi sẽ gửi link đặt lại mật khẩu.` |
| | Button | `Gửi link` |
| | After submit | `Nếu email này có tài khoản, link đặt lại đã được gửi. Link có hiệu lực trong 1 giờ.` |
| `/reset-password?token=…` | Title | `Đặt mật khẩu mới` |
| | Field | `Mật khẩu mới` |
| | Button | `Lưu mật khẩu` |
| | Success | `Đã đổi mật khẩu. Hãy đăng nhập lại.` |
| | Bad token | `Link đặt lại không còn dùng được.` with button `Xin link mới` |

### 9.5 Account (`/account`, new screen S13)

Opened from the user's shape at the top of S2, which until now signed out directly.

| Element | String |
|---|---|
| Title | `Tài khoản` |
| Change password card | `Đổi mật khẩu` · `Mật khẩu hiện tại` · `Mật khẩu mới` · checkbox `Đăng xuất khỏi các thiết bị khác` · button `Lưu mật khẩu` |
| Wrong current password | `Mật khẩu hiện tại không đúng.` |
| Sign out | `Đăng xuất` |
| Delete card | `Xoá tài khoản` / `Tên bạn vẫn ở lại trong các nhóm, nhưng không còn gắn với tài khoản nào. Gõ lại email của bạn để xác nhận.` · button `Xoá tài khoản` |
| Still owns a group | `Bạn còn là chủ của {count} nhóm. Hãy chuyển quyền chủ nhóm hoặc xoá nhóm trước.` |

The password card is hidden for accounts that have only a Google identity.

### 9.6 Invites

| Place | String |
|---|---|
| Invalid or disabled link (`/join/{token}`) | `Link mời này không còn dùng được` / `Hãy xin chủ nhóm một link mới.` with button `Về danh sách nhóm` |
| Link copied | `Đã sao chép link` |
| Link disabled (members screen) | `Link mời đang tắt.` |
| Remove a user, confirmation | `Gỡ {name} khỏi nhóm?` / `Họ không còn xem được nhóm. Hình và các khoản chi của họ vẫn được giữ.` · `Gỡ` · `Thôi` |
| Removed while viewing | `Bạn không còn ở trong nhóm này.` |

### 9.7 Read-only role

The entry bar of S4 is replaced by a `sunken` bar with `Chỉ xem`. Add, edit and member controls are not rendered.

### 9.8 Deleting a group (S11)

A dialog: `Xoá nhóm {name}?` / `Mọi khoản chi và số dư sẽ mất. Việc này không hoàn tác được. Gõ lại tên nhóm để xác nhận.` · field `Tên nhóm` · button `Xoá nhóm` (enabled only on an exact match) · `Thôi`.

### 9.9 Edit, delete, restore (1E)

| Place | String |
|---|---|
| Edit form title | `Sửa khoản chi` |
| Edited tag in the stream | `đã sửa` |
| Delete button in the edit form | `Xoá khoản này` |
| After delete | `Đã xoá.` with action `Hoàn tác` |
| Version conflict | `{name} vừa sửa khoản này. Xem bản mới rồi sửa lại nếu cần.` with button `Xem bản mới` |
| History, empty | `Chưa có thay đổi nào` |
| History, restore action | `Khôi phục` |

### 9.10 Offline, loading, errors

| Place | String |
|---|---|
| Offline banner | `Mất mạng. Bạn vẫn xem được sổ.` |
| Disabled entry bar | `Có mạng lại là gõ tiếp được` |
| Forbidden action | `Bạn không có quyền làm việc này.` |
| "New item" pill while scrolled up | `Có khoản mới` |

Loading is always a skeleton of the content. Errors always carry the existing `Thử lại` button.

### 9.11 Motion

The four motions of `docs/06-ux-ui/user-flows.md` section 6 are implemented with CSS transitions only, and replaced by instant state changes under `prefers-reduced-motion`. They are listed under "Not verified" by Codex and judged by the owner at the end.

## 10. What the plan must contain

- Five stages of ordered tasks in the format of the existing 1A plan, with the 1A tasks carried over.
- For each stage: the acceptance script with expected numbers, and the rows of the permission matrix that become active.
- Exact layouts for the designed screens that the agent cannot open on the canvas (GE2–GE6, GE9–GE13, GE15, GE16), written as numbers and tokens.
- The Codex prompt (section 3.5) and the initial `progress.md`.
- `docs/08-quick-entry-samples.md` and the common-password list file.

## 11. Changes to standing documents

Made by the advisor after this spec is approved, before the run.

| Document | Change |
|---|---|
| `AGENTS.md` | New section "Phase run": sections 3.1–3.4 of this spec. Section 4 step 6 and section 5 point to it. Section 10 allows the `phase-1` branch. Section 3 lists specs and run files |
| `.agents/skills/execute-task` | Report goes to `progress.md`; continue instead of stop; gate procedure |
| `.agents/skills/review-code` | Whole-branch review in the order of section 3.6 |
| `docs/04-adr.md` | ADR-017: own session layer, `arctic` for Google, argon2id from `node:crypto`; no Better Auth. ADR-018: one agent run per phase, with gates and a decision log |
| `docs/07-roadmap.md` | FR-1.63 in 1A; Google unverified until the OAuth app exists; process table updated |
| `docs/05-api-spec.md` | `GET /auth/providers`; new error codes `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`, `TOKEN_INVALID`, `WEAK_PASSWORD`; balance in the invite preview |
| `docs/05-database-design.md` | `auth_tokens` |
| `docs/06-ux-ui/user-flows.md` | S13 Account; section 9 of this spec; "bơm hình" and stream activity lines moved to the waiting list |
| `docs/superpowers/plans/2026-11-12-milestone-1a-core-ledger.md`, `PROMPT-milestone-1a.md` | Removed; superseded by the phase plan |

## 12. Before the run starts

| Who | What |
|---|---|
| Owner | Approve this spec, then the plan |
| Advisor | Add the common-password list and the sample sentences; amend the documents in section 11; create the `phase-1` branch when the owner says so |
| Owner | Nothing else. The Google OAuth app can be created at any later time |
