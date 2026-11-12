# Phase 1 — Stage 1B: Accounts and Sharing

> Part of the phase 1 plan. Read `00-overview.md` first. Task references inside this file mean this stage's tasks.

**Stage goal:** A whole group uses one ledger together: people register or sign in, join through an invite link, hold one of three roles, and see each other's changes within two seconds.

**Spec:** design spec sections 5.3, 5.4, 6, 7, 9.1–9.7; `docs/03-srs.md` FR-1.1–1.9, 1.14, 1.24, 1.30–1.36, 1.80, NFR-1.12–1.14; `docs/05-api-spec.md` (sessions, invites, users, events); `docs/05-database-design.md` (`user_identities`); `docs/06-ux-ui/user-flows.md` flows A, B, H.

## Decisions for this stage

1. Mail subjects and bodies are user-visible Vietnamese text that must live in the API. They sit in one file, `apps/api/src/mail-templates.ts`, and nowhere else. This is the single exception to "strings only in `vi.ts`".
2. Google's ID token is read with `arctic`'s decoder without a separate signature check: it arrives directly from Google's token endpoint over TLS in the authorization-code flow.
3. After a transfer of ownership the former owner becomes an editor.
4. A user in a group may have no linked member (their member was deleted). They are listed after the members with the tag `Chưa chọn hình`.

## Review Focus

1. **Account enumeration.** Register and forgot-password give the same status and body for a known and an unknown email; sign-in gives the same 401 for both. → 1B.2, 1B.3.
2. **Token replay.** A verification or reset token works once; a second use, an expired token and a token of the other purpose all get `TOKEN_INVALID`. → 1B.2, 1B.3.
3. **A removed user keeps reading.** After removal, that user's next request to the group is 404 and their event stream is closed. → 1B.8, 1B.9.
4. **Two people claim one member.** The second gets 409 `MEMBER_ALREADY_CLAIMED`; the first is unaffected. → 1B.7.
5. **Open redirect through sign-in.** `redirect` and `next` values that are not same-site paths fall back to `/`. → 1B.4, 1B.5.

---

### Task 1B.1: Account foundations

**Files:**
- Create: `packages/db/src/schema-accounts.ts`, `packages/db/src/accounts.ts`, `apps/api/src/auth/passwords.ts`, `apps/api/src/auth/one-time-tokens.ts`, `apps/api/src/mailer.ts`, `apps/api/src/mail-templates.ts`, `apps/api/src/rate-limit.ts`
- Exists already (added by the advisor): `apps/api/src/auth/common-passwords.txt` — one password per line
- Modify: `packages/db/drizzle.config.ts`, `packages/db/src/index.ts`, `packages/contract/src/error.ts`, `packages/contract/src/auth.ts`, `apps/api/src/config.ts`, `apps/api/src/app.ts`, `apps/api/src/server.ts`, `.env.example`, root `package.json` (`engines.node`)

**Interfaces — produces:**
- Tables: `userIdentities` as `docs/05-database-design.md`, with `provider` in (`google`, `password`), `UNIQUE (provider, provider_subject)`, `UNIQUE (user_id, provider)`, and a `CHECK` that a `password` row has a hash and no subject while a `google` row has a subject and no hash. `authTokens`: `id`, `user_id` (cascade), `purpose` in (`verify_email`, `reset_password`), `token_hash` unique, `expires_at`, `used_at`, `created_at`.
- `ErrorCode` gains `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`, `TOKEN_INVALID`, `WEAK_PASSWORD`, `RATE_LIMITED`, `INVITE_INVALID`, `MEMBER_ALREADY_CLAIMED`, `OWNER_REQUIRED`.
- `UserDto` gains `emailVerified: boolean` and `hasPassword: boolean`.
- `hashPassword(password: string): Promise<string>` — argon2id from `node:crypto`: memory 19456 KiB, 2 passes, parallelism 1, 16-byte random salt, 32-byte tag; returns a PHC string `$argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>` (base64 without padding).
- `verifyPassword(password: string, phc: string): Promise<boolean>` — re-derives with the parameters in the string; compares with `timingSafeEqual`; a malformed string returns false.
- `DUMMY_PASSWORD_HASH` — a constant PHC string used to spend the same time when there is no account.
- `checkNewPassword(password: string): "ok" | "too_short" | "too_long" | "too_common"` — 10 to 128 characters; `too_common` when the lower-cased password, or the lower-cased password with its trailing digits and punctuation removed, is in the list (so `password123` and `qwerty2026!` are refused). The list is read once at start-up into a `Set`.
- `issueToken(executor, input: { userId; purpose; now }): Promise<string>` — 32 random bytes, base64url; stores only the SHA-256 hex; marks earlier unused tokens of the same user and purpose as used. Lifetime: `verify_email` 24 hours, `reset_password` 1 hour.
- `consumeToken(executor, input: { token; purpose; now }): Promise<string | null>` — one `UPDATE … WHERE used_at IS NULL AND expires_at > now … RETURNING user_id`; returns the user id or null.
- `type Mailer = { send(mail: { to: string; subject: string; text: string }): Promise<void> }`; `createConsoleMailer(): Mailer` prints a delimited block to the console. `AppDeps` gains `mailer`. With `APP_ENV=production` the server refuses to start: `Mailer is not configured for production`.
- `createRateLimiter(now: () => Date)` returning `limit(options: { name: string; max: number; windowMs: number; key: (context) => string | null })` — a middleware; fixed window; in memory; expired entries are dropped as they are met; over the limit answers 429 `RATE_LIMITED` with a `Retry-After` header in seconds. A null key skips the limit. The client IP is the socket address.
- `Config` gains `googleClientId` and `googleClientSecret`, both optional; setting only one is a start-up error naming both variables. `.env.example` lists them empty.
- `engines.node` is raised to the first release that documents `crypto.argon2` as available (read the Node.js documentation for the exact version).

Mail templates (subject / body; `{link}` is a full URL on `WEB_ORIGIN`):

| Template | Subject | Body |
|---|---|---|
| Verify email | `Xác minh email của bạn` | `Chào {name},\n\nBấm vào link dưới đây để xác minh email cho tài khoản Sòng Phẳng. Link có hiệu lực trong 24 giờ.\n\n{link}\n\nNếu bạn không đăng ký, hãy bỏ qua thư này.` |
| Account exists | `Bạn đã có tài khoản Sòng Phẳng` | `Có người vừa dùng email này để đăng ký. Bạn đã có tài khoản; hãy đăng nhập, hoặc đặt lại mật khẩu nếu quên.\n\n{link}` (link to `/login`) |
| Reset password | `Đặt lại mật khẩu Sòng Phẳng` | `Bấm vào link dưới đây để đặt mật khẩu mới. Link có hiệu lực trong 1 giờ và chỉ dùng được một lần.\n\n{link}\n\nNếu bạn không yêu cầu, hãy bỏ qua thư này.` |

- [ ] **Step 1: Write the schema, generate the migration, write the modules**
- [ ] **Step 2: `pnpm check`; `pnpm db:migrate` twice**
- [ ] **Step 3: Exercise** with `tsx -e` one-liners, real output recorded:

| Call | Expected |
|---|---|
| `hashPassword("correct horse battery")` twice | two different strings, both starting `$argon2id$v=19$m=19456,t=2,p=1$` |
| `verifyPassword` with the right, a wrong, and a truncated hash | `true`, `false`, `false` |
| `checkNewPassword` of `short`, `password123`, `QWERTYUIOP`, `basketball2026!`, a 129-character string, `tram-xe-buyt-so-8` | `too_short`, `too_common`, `too_common`, `too_common`, `too_long`, `ok` |
| `issueToken` then `consumeToken` twice | a user id, then `null` |
| `consumeToken` with the wrong purpose; after setting `expires_at` to the past | `null`, `null` |
| `issueToken` twice, consume the first | `null` |
| A limiter of 3 per minute called 4 times with one key | fourth is 429 with `Retry-After` |

`select token_hash from auth_tokens` shows 64 hex characters, never the token.

- [ ] **Step 4: Commit** — `feat(api): add password hashing, one-time tokens, mailer, and rate limiter`

**Manual checks for the project owner:** none visible; covered by 1B.2 and 1B.3.

---

### Task 1B.2: API — register, sign in, verify email

**Files:**
- Create: `apps/api/src/services/accounts.ts`, `apps/api/src/auth/verified-email.ts`
- Modify: `packages/contract/src/auth.ts`, `apps/api/src/routes/auth.ts`, `apps/api/src/routes/me.ts`, every route file with write routes, `apps/api/src/app.ts`

**Interfaces — produces:**
- `RegisterRequest` = `{ email: string (email, ≤ 254); name: string (trimmed, 1–50); password: string (1–1024) }`; `LoginRequest` = `{ email; password }`; `VerifyEmailRequest` = `{ token: string (≤ 256) }`; `ProvidersResponse` = `{ google: boolean; devLogin: boolean }`.
- `requireVerifiedEmail(deps)` — middleware after `requireUser`; an unverified caller gets 403 `EMAIL_NOT_VERIFIED`. Applied to every `POST`, `PATCH`, `PUT` and `DELETE` except the `/auth/*` routes and `DELETE /me`.
- The write rate limit (60 per minute per user) is applied to the same set of routes.

| Method | Path | Behavior |
|---|---|---|
| POST | `/auth/register` | Limit 5 per hour per IP. `checkNewPassword` failing → 400 `WEAK_PASSWORD` with `details.reason`. Always hash the password. Email not registered: create the user (unverified), a `password` identity, a `verify_email` token, send "Verify email". Email registered: send "Account exists". Both: 204, no cookie. Emails compare case-insensitively. |
| POST | `/auth/login` | Limits 10 per 15 minutes per IP and 5 per 15 minutes per lower-cased email. Look up the `password` identity; verify against its hash, or against `DUMMY_PASSWORD_HASH` when there is none; failure → 401 `INVALID_CREDENTIALS`. Success → `createSession`, cookie, 204. Unverified accounts can sign in. |
| POST | `/auth/verify-email` | `consumeToken`; null → 400 `TOKEN_INVALID`; otherwise set `email_verified_at`, 204. No session is required. |
| POST | `/auth/resend-verification` | Signed in. Limit 3 per hour per user. Verified → 204 and nothing sent. Otherwise issue a token and send "Verify email"; 204. |
| GET | `/auth/providers` | 200 `ProvidersResponse`: `google` is true when both Google variables are set; `devLogin` is `config.devLogin`. |
| GET | `/me` | Now includes `emailVerified` and `hasPassword`. |

- [ ] **Step 1: Write schemas, service, middleware, routes; attach `requireVerifiedEmail` and the write limit to existing write routes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1, 2)**

| Request | Expected |
|---|---|
| Register `ngan@example.test`, password `tram-xe-buyt-so-8` | 204, no `Set-Cookie`; the API console shows the "Verify email" mail with a link |
| Register the same email again | 204, identical body and headers apart from `X-Request-Id`; the console shows "Account exists"; `select count(*) from users where lower(email) = …` is 1 |
| Register `NGAN@example.test` | as the row above |
| Register with `password123` / `short` | 400 `WEAK_PASSWORD`, reason `too_common` / `too_short` |
| Sign in with the right password | 204 with the session cookie; `GET /me` shows `emailVerified: false`, `hasPassword: true` |
| Sign in with a wrong password; with an unknown email | both 401 `INVALID_CREDENTIALS`, identical bodies apart from `requestId` |
| As the unverified user: `POST /groups` | 403 `EMAIL_NOT_VERIFIED` |
| `POST /auth/verify-email` with the token from the console | 204; `emailVerified: true`; `POST /groups` now works |
| The same token again; a made-up token | 400 `TOKEN_INVALID` both |
| Six sign-in attempts for one email within 15 minutes | the sixth is 429 with `Retry-After` |
| Resend verification four times within an hour (unverified user) | the fourth is 429 |
| Dev login as Minh, then the 1A acceptance script's first two steps | still work (dev users are verified) |

`select password_hash from user_identities` starts with `$argon2id$`; no password or token appears in the API console outside the mail block.

- [ ] **Step 4: Commit** — `feat(api): add registration, sign-in, and email verification`

**Manual checks for the project owner**
1. Run the register command, copy the link from the API console, and call verify with its token → the account becomes verified.
2. Register an existing email → the same empty 204 answer as a new one.
3. Sign in with a wrong password six times → the sixth says `RATE_LIMITED`.

---

### Task 1B.3: API — forgot, reset and change password; delete account

**Files:**
- Modify: `packages/contract/src/auth.ts`, `apps/api/src/services/accounts.ts`, `apps/api/src/routes/auth.ts`, `apps/api/src/routes/me.ts`, `packages/db/src/accounts.ts`, `packages/db/src/sessions.ts`

**Interfaces — produces:** `ForgotPasswordRequest` = `{ email }`; `ResetPasswordRequest` = `{ token; password }`; `ChangePasswordRequest` = `{ currentPassword; newPassword; revokeOtherSessions: boolean }`; `DeleteAccountRequest` = `{ email }`.

| Method | Path | Behavior |
|---|---|---|
| POST | `/auth/forgot-password` | Limits 3 per hour per lower-cased email and 10 per hour per IP. An account with a `password` identity gets a `reset_password` token and the "Reset password" mail. Always 204. |
| POST | `/auth/reset-password` | `checkNewPassword` failing → 400 `WEAK_PASSWORD`, token not consumed. `consumeToken` null → 400 `TOKEN_INVALID`. Otherwise, in one database transaction: store the new hash, set `email_verified_at` if it was null (the link proved the address), delete **every** session of the user. 204, no cookie. |
| POST | `/auth/change-password` | Signed in. Wrong `currentPassword` → 401 `INVALID_CREDENTIALS`. Weak new password → 400 `WEAK_PASSWORD`. Otherwise store the new hash; when `revokeOtherSessions` is true delete the user's other sessions. 204. An account without a `password` identity gets 404 `NOT_FOUND`. |
| DELETE | `/me` | Signed in; body `DeleteAccountRequest`. Email not equal (case-insensitive) to the account's → 400 `VALIDATION_FAILED`. The user owns a group → 422 `OWNER_REQUIRED` with `details.groupCount`. Otherwise delete the user; clear the cookie; 204. |

- [ ] **Step 1: Write schemas, services, routes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1, 2)**

| Request | Expected |
|---|---|
| Forgot password for a known and for an unknown email | both 204, identical; only the known one prints a mail |
| Reset with the token and a weak password | 400 `WEAK_PASSWORD`; the token still works afterwards |
| Reset with the token and a good password, while signed in on two cookie jars | 204; both old sessions now get 401; the old password fails; the new one works |
| The reset token again; a `verify_email` token sent to reset | 400 `TOKEN_INVALID` |
| Change password with a wrong current password | 401 |
| Change password with `revokeOtherSessions: true` from jar A while jar B is signed in | A still works; B gets 401 |
| `DELETE /me` with a different email | 400 |
| `DELETE /me` as a user who owns a group | 422 `OWNER_REQUIRED`, `groupCount` 1 |
| `DELETE /me` as a user who joined Minh's group in 1B.7 (re-run this row after 1B.7) | 204; the member and its transactions remain; `group_users` row gone; `pnpm db:check-balances` balanced |

- [ ] **Step 4: Commit** — `feat(api): add password reset, password change, and account deletion`

**Manual checks for the project owner**
1. Request a reset, use the link's token to set a new password → every signed-in browser of that account is signed out.
2. Use the same token again → refused.

---

### Task 1B.4: API — Google sign-in

**Files:**
- Create: `apps/api/src/auth/google.ts`, `apps/api/src/services/google-sign-in.ts`, `apps/api/src/routes/google.ts`
- Modify: `apps/api/package.json` (add `arctic`), `apps/api/src/app.ts`, `packages/db/src/accounts.ts`

Read `arctic`'s documentation and types in `node_modules` for the installed version before writing.

**Behavior:**

| Method | Path | Behavior |
|---|---|---|
| GET | `/auth/google` | Registered only when both Google variables are set. Generates `state` and a PKCE code verifier; stores them, and the validated `redirect` query value, in three HttpOnly `SameSite=Lax` cookies with `Max-Age` 600 and `Path=/api/v1/auth/google`; answers 302 to Google's authorization URL with scopes `openid email profile`. The callback URL is `{WEB_ORIGIN}/api/v1/auth/google/callback`. |
| GET | `/auth/google/callback` | Clears the three cookies. Compares the `state` query value with the cookie in constant time. Exchanges the code with the verifier. Reads `sub`, `email`, `email_verified`, `name`, `picture` from the ID token. Then applies the outcome table. |

`redirect` is accepted only if it starts with exactly one `/`, contains no backslash and no control character; otherwise `/`.

| Situation | Outcome |
|---|---|
| Missing or mismatched state, missing code, failed exchange, `email_verified` not true | 302 `/login?error=google` |
| A `google` identity with this `sub` exists | Session for that user; 302 to `redirect` |
| No identity; no user with this email | Create the user (verified, name and avatar from Google) and the identity; session; 302 to `redirect` |
| No identity; a user with this email whose `email_verified_at` is set | Add the identity to that user; session; 302 to `redirect` |
| No identity; a user with this email that is not verified | 302 `/login?error=google_unverified`; nothing is created |

The outcome logic is one service function that takes the Google claims as a plain object, so it can be exercised without Google.

- [ ] **Step 1: Add `arctic`; write the three files**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Check | Expected |
|---|---|
| No Google variables: `GET /auth/google` | 404; `/auth/providers` says `google: false` |
| Placeholder values `test-client-id` / `test-client-secret`: `GET /auth/google?redirect=/g/abc` | 302; `Location` starts with `https://accounts.google.com/`, contains `client_id=test-client-id`, `code_challenge=`, `state=`, and the callback URL; three cookies set |
| Same with `redirect=//evil.example` | the stored redirect is `/` |
| Callback with a wrong `state` | 302 `/login?error=google` |
| The service function called by `tsx -e` with claims for: a new email; the email of a verified password account; the email of an unverified password account; a known `sub` | a new user and identity; identity added to the existing user; no change and the `google_unverified` outcome; the same user as before |

Record under "Not verified": the full round trip with a real Google account. Add to `manual-checks.md`, section "After the Google OAuth app exists": create an OAuth client of type "Web application" with redirect URI `http://localhost:3000/api/v1/auth/google/callback`; put the id and secret in `.env`; restart; then the four situations of the outcome table with real accounts.

- [ ] **Step 4: Commit** — `feat(api): add Google sign-in`

---

### Task 1B.5: Web — sign-in, register, verify, forgot and reset screens

**Files:**
- Create: `apps/web/src/lib/auth.ts`, `apps/web/src/components/ui/TextField.tsx`, `apps/web/src/components/ui/VerifyEmailBanner.tsx`, `apps/web/src/app/login/page.tsx`, `apps/web/src/app/register/page.tsx`, `apps/web/src/app/verify-email/page.tsx`, `apps/web/src/app/forgot-password/page.tsx`, `apps/web/src/app/reset-password/page.tsx`
- Modify: `apps/web/src/lib/session.ts` (`loginPath` → `/login`; `useLogout` → `/login`), `apps/web/src/app/dev-login/page.tsx` (unchanged behavior), every screen that renders write controls, `apps/web/src/messages/vi.ts`

**Interfaces — produces:**
- `useProviders()`, `useLogin()`, `useRegister()`, `useVerifyEmail()`, `useResendVerification()`, `useForgotPassword()`, `useResetPassword()`.
- `TextField(props: { label: string; type?: "text" | "email" | "password"; error?: string; hint?: string } & InputHTMLAttributes<HTMLInputElement>)` — a real `<label>`; input height 56, radius 26, surface, 17px weight 700; error text 13px in a `role="alert"`, linked with `aria-describedby`.
- `VerifyEmailBanner()` — rendered by every screen in place of its write controls when `useMe().data.emailVerified` is false.

Strings: exactly those of the design spec sections 9.1–9.4, plus:

| Key | Value |
|---|---|
| `login.googleError` | `Không đăng nhập được bằng Google. Hãy thử lại.` |
| `register.nameTooLong` | `Tên dài tối đa 50 ký tự.` |
| `auth.passwordTooLong` | `Mật khẩu dài tối đa 128 ký tự.` |

Screen behavior:

| Screen | Behavior |
|---|---|
| `/login` | Top: the four shapes of GE7 in a block 220px high (Minh circle/mint 112 at left 6/top 24; Lan diamond/sky 100 at left 104/top 0; Hùng squircle/coral 88 at left 136/top 100; Thu leaf/lilac 74 at left 44/top 140, each with its initial). Headline 36px weight 900, line height 1.05. Email and password `TextField`s; primary `lg` button; when `providers.google`, a surface `lg` link to `/api/v1/auth/google?redirect=<next>`; two text links, 14px weight 700, each at least 44px high; when `providers.devLogin`, a muted link to `/dev-login?next=…`. `?error=google` and `?error=google_unverified` show their message in a `role="alert"` above the form. 401 shows the wrong-credentials message; 429 the too-many-attempts message. Success goes to `safeNext(next)`. An already signed-in visitor is sent to `safeNext(next)`. |
| `/register` | `ScreenHeader` back to `/login`; three `TextField`s; the password hint under its field; client-side checks for the 10 and 128 limits and the name length before sending; `WEAK_PASSWORD` reasons map to the two messages. After a 204 the form is replaced by the "after submit" title (28px weight 900) and text, with a primary link `Đăng nhập`. |
| `/verify-email` | Sends the token once on arrival (guard against the double effect in development). Shows a skeleton, then the success or the bad-token state of spec 9.3. |
| `/forgot-password` | One `TextField`, the hint, the button; after a 204 the confirmation text replaces the form. |
| `/reset-password` | One `TextField`; success state with a primary link to `/login`; `TOKEN_INVALID` state with a link to `/forgot-password`. |
| `VerifyEmailBanner` | Accent card, radius 30: the banner text 14px weight 700 and a `Gửi lại thư` button, height 44; after a 204 the confirmation line; 429 shows the too-many-attempts message. Used on S2 (instead of "Tạo nhóm"), S4 (instead of the entry bar), S8, S10, S11. |

- [ ] **Step 1: Write hooks, components, the five pages; switch `loginPath`**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser**

1. Signed out, open `/g/<id>` → `/login?next=%2Fg%2F<id>`; sign in → back on that group (FR-1.3).
2. Register a new email → the "Kiểm tra hộp thư của bạn" state; open the link from the API console → "Email đã được xác minh."
3. Sign in before verifying → the banner replaces "Tạo nhóm"; "Gửi lại thư" prints a new mail; the old link no longer works, the new one does.
4. Wrong password → "Email hoặc mật khẩu không đúng."; six times → the too-many-attempts message.
5. Forgot password → the confirmation text for a known and an unknown email alike; the link sets a new password; signing in with it works.
6. `/login?next=//evil.example`, sign in → lands on `/` (Review Focus 5).
7. `/login?error=google_unverified` → the long message of spec 9.1.
8. With no Google variables there is no Google button; with placeholders there is one, and it leaves for `accounts.google.com`.
9. Every form works with the keyboard only; errors are announced; 360px width has no horizontal scroll.

- [ ] **Step 4: Commit** — `feat(web): add sign-in, registration, and password recovery screens`

**Manual checks for the project owner**
1. Compare `/login` with GE7: same shapes and headline, smaller, with the form beneath; the line about not needing a password is gone.
2. Do exercise steps 2, 3 and 5 yourself.
3. Register with a 9-character password and with `password123` → the two messages of spec 9.2.
4. Read every sentence on the five screens for tone and spelling.

---

### Task 1B.6: Web — account screen (S13)

**Files:**
- Create: `apps/web/src/app/account/page.tsx`, `apps/web/src/components/account/ChangePasswordCard.tsx`, `apps/web/src/components/account/DeleteAccountCard.tsx`
- Modify: `apps/web/src/lib/auth.ts`, `apps/web/src/app/page.tsx` (the user's shape becomes a link to `/account`, labelled `Tài khoản`), `apps/web/src/messages/vi.ts`

Strings: design spec 9.5. Layout: `ScreenHeader` back to `/`; a surface card with the user's `MemberShape` 52 (circle/mint), name 16px weight 800 and email 13px muted; `ChangePasswordCard` (surface, radius 30) shown only when `hasPassword`; a surface `lg` button `Đăng xuất`; `DeleteAccountCard` with background `debt-soft`, radius 28: the two lines, an email `TextField`, and an ink button enabled only when the typed email equals the account's.

Behavior: change password → on 204 the fields clear and `Đã đổi mật khẩu.` shows; 401 → the wrong-current-password message; weak → the messages of 9.2. Delete → 422 shows the owner message with the count; 204 clears the query cache and goes to `/login`.

Add string `account.passwordChanged` = `Đã đổi mật khẩu.`

- [ ] **Step 1: Write the page and cards**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser:** change the password with and without "Đăng xuất khỏi các thiết bị khác" using two browsers; try deleting an account that owns a group; delete one that owns none and confirm its member name is still in the group it had joined (after 1B.10).
- [ ] **Step 4: Commit** — `feat(web): add account screen`

**Manual checks for the project owner**
1. Tap your shape on the group list → the account screen, not an immediate sign-out.
2. Change your password with the box ticked while signed in on a second browser → the second browser is signed out on its next action.
3. Try to delete an account that owns a group → the message names how many groups.

---

### Task 1B.7: API — invites, joining, "tôi là người này"

**Files:**
- Create: `packages/contract/src/invite.ts`, `packages/db/src/invites.ts`, `apps/api/src/services/invites.ts`, `apps/api/src/routes/invites.ts`
- Modify: `packages/contract/src/index.ts`, `packages/db/src/index.ts`, `apps/api/src/app.ts`, `apps/api/src/services/members.ts`

**Interfaces — produces:**
- `InviteDto` = `{ token: string; active: boolean; url: string }`; `InviteResponse` = `{ invite: InviteDto }`.
- `InvitePreviewResponse` = `{ group: { id; name }; ownerName: string; memberCount: number; transactionCount: number; members: Array<{ id; name; shape; color; claimed: boolean; balance: number | null }>; alreadyJoined: boolean }` — `balance` is null for claimed members; members are the active ones in position order.
- `JoinRequest` = exactly one of `{ memberId: uuid }` or `{ newMemberName: MemberName }`; `JoinResponse` = `{ groupId: uuid }`.
- `ChooseMemberRequest` = `{ memberId: uuid }`.

| Method | Path | Access | Behavior |
|---|---|---|---|
| GET | `/invites/{token}` | signed in; 30 per minute per IP | Unknown token or `invite_active = false` → 404 `INVITE_INVALID`. Otherwise 200 `InvitePreviewResponse`. No email verification needed to look. |
| POST | `/invites/{token}/join` | signed in, verified; `Idempotency-Key` | Invalid token → 404 `INVITE_INVALID`. Already in the group → 200 with the group id, nothing changes. `memberId`: must be an active member of this group, else 400 `MEMBER_NOT_IN_GROUP`; claimed → 409 `MEMBER_ALREADY_CLAIMED` (the unique constraint decides races). `newMemberName`: create the member as in 1A.4, including the 100-member limit. Insert `group_users` with the group's `default_role`; activity row (`join`, `group_user`). 200 `JoinResponse`. |
| GET | `/groups/{groupId}/invite` | editor | 200 `InviteResponse`; `url` is `{WEB_ORIGIN}/join/{token}`. |
| PATCH | `/groups/{groupId}/invite` | owner | Body `{ active: boolean }`; activity row; 200. |
| POST | `/groups/{groupId}/invite/rotate` | owner | New 32-byte token; the old one stops working at once; activity row; 200. |
| PUT | `/groups/{groupId}/me/member` | viewer | The member must be active, in the group, and unclaimed (409 otherwise); sets the caller's `member_id`; activity row; 200 `GroupResponse`. |

From this task `MemberDto` gains `claimed: boolean`, and deleting a member that is linked to a user is allowed (the link becomes null).

- [ ] **Step 1: Write schemas, queries, service, routes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)**

Minh owns "Đà Lạt 12/2026" with Lan, Hùng, Thu and the two expenses of the 1A.6 table.

| Request | Expected |
|---|---|
| Minh `GET …/invite` | a 43-character token; `active: true` |
| Lan `GET /invites/{token}` | group name; `ownerName` Minh; `memberCount` 4; `transactionCount` 2; Minh `claimed: true`, `balance: null`; Hùng `claimed: false`, `balance: -300000`; `alreadyJoined: false` |
| Lan joins with Lan's `memberId` | 200; `GET /groups` as Lan lists the group with `myBalance` 0 |
| Hùng (dev user) joins with Lan's `memberId` | 409 `MEMBER_ALREADY_CLAIMED` |
| Two simultaneous joins for Thu's member from two users (`&` in the shell) | one 200, one 409 |
| Hùng joins with `newMemberName: "Hùng em"` | 200; a fifth member with the next free pair |
| Lan joins again | 200, no new rows |
| An unverified user joins | 403 `EMAIL_NOT_VERIFIED`; the same user can still `GET /invites/{token}` |
| Minh disables the link; Thu previews | 404 `INVITE_INVALID`, same body as a made-up token |
| Minh enables and rotates; old token; new token | 404; 200 |
| Lan (editor) `PATCH …/invite` | 403 `FORBIDDEN` |
| Hùng `PUT …/me/member` with Hùng's member; with Lan's member | 200 and `myMemberId` changes; 409 |
| 31 previews within a minute from one IP | the 31st is 429 |

- [ ] **Step 4: Commit** — `feat(api): add invite links, joining, and member selection`

---

### Task 1B.8: API — users in a group, roles, leaving, ownership

**Files:**
- Create: `packages/contract/src/group-user.ts`, `packages/db/src/group-users.ts`, `apps/api/src/services/group-users.ts`, `apps/api/src/routes/group-users.ts`
- Modify: `packages/contract/src/group.ts` (`UpdateGroupRequest` gains `defaultRole?: "editor" | "viewer"`; `GroupDto` gains `defaultRole`), `apps/api/src/services/groups.ts`, `apps/api/src/app.ts`

**Interfaces — produces:** `GroupUserDto` = `{ userId: uuid; name: string; role: GroupRole; memberId: uuid | null; isMe: boolean }`; `GroupUsersResponse` = `{ users: GroupUserDto[] }`; `UpdateGroupUserRequest` = `{ role: "editor" | "viewer" }`; `TransferOwnershipRequest` = `{ userId: uuid }`.

| Method | Path | Access | Behavior |
|---|---|---|---|
| GET | `/groups/{groupId}/users` | viewer | 200, owner first, then by join time. No emails. |
| PATCH | `/groups/{groupId}/users/{userId}` | owner | Target is the owner → 422 `OWNER_REQUIRED`. Activity row (`role_change`). 200. |
| DELETE | `/groups/{groupId}/users/{userId}` | owner | Target is the owner → 422 `OWNER_REQUIRED`. Deletes the `group_users` row; the member stays. Activity row (`remove`). 204. |
| POST | `/groups/{groupId}/transfer-ownership` | owner | Target must be another user of the group (404 otherwise). In one database transaction the caller becomes `editor`, then the target becomes `owner`. Activity row. 200 `GroupResponse`. |
| POST | `/groups/{groupId}/leave` | viewer | Owner → 422 `OWNER_REQUIRED`. Otherwise delete the caller's `group_users` row; activity row (`leave`). 204. |

A `userId` that is not in the group gets 404.

- [ ] **Step 1: Write schemas, queries, service, routes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Request | Expected |
|---|---|
| Minh sets Lan to `viewer`; Lan `POST …/transactions`; Lan `GET …/transactions` | 200; 403 `FORBIDDEN`; 200 |
| Lan (viewer) `GET …/invite` | 403 |
| Minh sets himself to `viewer` | 422 `OWNER_REQUIRED` |
| Minh `leave` | 422 `OWNER_REQUIRED` |
| Minh transfers ownership to Lan | Lan `owner`, Minh `editor`; `select count(*) from group_users where role = 'owner' and group_id = …` is 1 |
| Minh (now editor) `PATCH /groups/{id}` | 403 |
| Lan transfers back; Minh removes Hùng | Hùng's next `GET /groups/{id}` is 404; Hùng's member and its balance remain |
| Lan leaves | 204; Lan's member remains, `claimed: false`; Lan can join again through the link and claim it |
| `PATCH` group with `defaultRole: "viewer"`; a new user joins | their role is `viewer` |

Then replay the whole permission matrix of `00-overview.md` with four cookie jars and record it.

- [ ] **Step 4: Commit** — `feat(api): add group roles, removal, leaving, and ownership transfer`

---

### Task 1B.9: API — realtime events

**Files:**
- Create: `apps/api/src/events/hub.ts`, `apps/api/src/routes/events.ts`
- Modify: `apps/api/src/app.ts` (`AppDeps` gains `events`), `apps/api/src/server.ts`, every service that writes group data

Read Hono's streaming (SSE) helper documentation for the installed version first.

**Interfaces — produces:**
- `type GroupResource = "group" | "members" | "users" | "transactions" | "balances" | "activity"`
- `createEventHub()` returning `{ subscribe(groupId, userId, listener): () => void; publishChanged(groupId, resources: GroupResource[]): void; publishRemoved(groupId, userId: string | null): void }` — `publishRemoved` with a user id reaches and then drops only that user's listeners; with null it reaches and drops all of the group's.
- `GET /groups/{groupId}/events`, access viewer: `text/event-stream`; headers `Cache-Control: no-cache, no-transform` and `X-Accel-Buffering: no`; a comment line every 25 seconds; unsubscribes when the client disconnects.

Events are published **after** the database transaction commits, never for a replayed idempotent request, never when the write failed.

| Write | Resources |
|---|---|
| Group settings | `group`, `balances`, `activity` |
| Member created, updated, deleted | `members`, `balances`, `activity` |
| Transaction created (and, later, edited, deleted, restored) | `transactions`, `balances`, `activity` |
| Join, leave, role change, ownership transfer, member chosen | `users`, `members`, `group`, `activity` |
| Invite toggled or rotated | `group`, `activity` |
| User removed or left | as "join" for the others; `removed` for that user |
| Group deleted (1E) | `removed` for everyone |

- [ ] **Step 1: Write the hub and the route; publish from the services**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)**

| Check | Expected |
|---|---|
| Lan: `curl -N -b /tmp/lan.txt localhost:4000/api/v1/groups/{id}/events`; Minh creates a transaction | within 2 seconds Lan's stream prints `event: changed` with `{"resources":["transactions","balances","activity"]}` |
| The same through the web origin, port 3000 | the same line within 2 seconds. If the Next.js rewrite buffers the stream, fix the delivery and record the decision |
| Leave the stream idle for 60 seconds | at least two keep-alive lines |
| Minh removes Lan while her stream is open | `event: removed`, then the connection closes; reconnecting gets 404 |
| An outsider opens the stream | 404 |
| A failing write (400) | no event |
| The same idempotent create twice | one event |
| Open and close 50 streams in a loop, then check the hub | no listeners left (log the count in a temporary line, then remove the line) |

- [ ] **Step 4: Commit** — `feat(api): add realtime group events over SSE`

---

### Task 1B.10: Web — joining and inviting (S12, invite card)

**Files:**
- Create: `apps/web/src/lib/invites.ts`, `apps/web/src/app/join/[token]/page.tsx`, `apps/web/src/components/join/ClaimGrid.tsx`, `apps/web/src/components/members/InviteCard.tsx`
- Modify: `apps/web/package.json` (add `uqr`), `apps/web/src/app/g/[groupId]/members/page.tsx`, `apps/web/src/components/feed/EmptyStream.tsx`, `apps/web/src/app/g/[groupId]/page.tsx`, `apps/web/src/messages/vi.ts`

Strings (in addition to design spec 9.6):

| Key | Value |
|---|---|
| `join.invitedBy` | `{name} mời bạn vào` |
| `join.summary` | `{members} người · {count} khoản chi` |
| `join.question` | `Hình nào là bạn?` |
| `join.claimed` | `đã có người nhận` |
| `join.sameName` | `trùng tên tài khoản của bạn` |
| `join.unclaimed` | `chưa ai nhận` |
| `join.newMember` | `Tôi chưa có trong nhóm · tạo hình mới` |
| `join.newMemberLabel` | `Tên của bạn trong nhóm` |
| `join.owes` | `{name} đang cần trả {amount} trong nhóm này. Vào nhóm xong bạn sẽ thấy chi tiết.` |
| `join.isOwed` | `{name} đang được nhận {amount} trong nhóm này. Vào nhóm xong bạn sẽ thấy chi tiết.` |
| `join.even` | `{name} không nợ ai trong nhóm này.` |
| `join.submit` | `Vào nhóm với tên {name}` |
| `join.claimedMeanwhile` | `Hình này vừa có người khác nhận. Hãy chọn hình khác.` |
| `invite.title` | `Mời vào nhóm` |
| `invite.hint` | `Quét mã, hoặc gửi link.` |
| `invite.copy` | `Sao chép link` |
| `invite.share` | `Gửi` |
| `invite.qrLabel` | `Mã QR mời vào nhóm` |
| `feed.inviteLink` | `Mời bạn vào nhóm` |

Screen behavior:

| Part | Behavior |
|---|---|
| S12 `/join/{token}` | Signed out → `/login?next=/join/{token}`. `INVITE_INVALID` → the invalid-link state of spec 9.6. `alreadyJoined` → `router.replace("/g/{id}")`. Otherwise (GE6): padding top 28; `join.invitedBy` 14px weight 600 muted; group name 36px weight 900; `join.summary` 14px muted; `join.question` 17px weight 800; `ClaimGrid`; the dashed button `join.newMember` (height 60, radius 30) which turns into a `TextField` `join.newMemberLabel` prefilled with the account name; a surface card (radius 26, 13px) with `join.owes`, `join.isOwed` or `join.even` for the selected member, the amount in ink weight 800; the accent button `join.submit`, height 68, radius 34, 18px weight 900, disabled until something is chosen. The banner of 1B.5 replaces the button for unverified users. |
| `ClaimGrid` | Two columns, gap 10. Each member is a `<button aria-pressed>`: radius 36, `MemberShape` 84, name 16px weight 800, a 12px line. Claimed: `disabled`, background `sunken`, shape at 55% opacity, `join.claimed`. Unclaimed: surface, `join.unclaimed`. Selected: 3px ink border. The unclaimed member whose name equals the account name (case- and accent-insensitive) is preselected and shows `join.sameName`. |
| After joining | `router.replace("/g/{id}")`. 409 → `join.claimedMeanwhile` and the preview is refetched. |
| `InviteCard` on S10 | For owner and editor (GE9): accent, radius 36, padding 16; a surface tile, radius 22, padding 10, holding the QR as inline SVG 96 × 96 drawn with `uqr` from `invite.url`, `role="img"`, labelled `invite.qrLabel`; `invite.title` 22px weight 900; `invite.hint` 13px weight 600; `invite.copy` (ink, height 44) writes the URL with the Clipboard API and shows `Đã sao chép link` for two seconds; `invite.share` (surface, height 44) calls `navigator.share` and is rendered only where that exists. When the link is inactive the card shows `Link mời đang tắt.` and no QR. |
| S4 | The empty state and the shortcut row gain the `feed.inviteLink` link to `/g/{id}/members` for owner and editor. The header link's label becomes `Thành viên và lời mời`. |

- [ ] **Step 1: Add `uqr` (read its README for the SVG renderer); write hooks, page and components**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser:** the flow B diagram of `user-flows.md` end to end with two browsers: signed-out link → sign in → back on the join page; preselection by name; the balance line for Hùng (−300.000 → "cần trả 300.000 đ"); claiming; a second person finding that shape disabled; "tạo hình mới"; an invalid link; a disabled link; copying the link and pasting it elsewhere; scanning the QR with a phone camera shows the `http://localhost:3000/join/…` URL (record under "Not verified" if no camera is available).
- [ ] **Step 4: Commit** — `feat(web): add join screen and invite card`

**Manual checks for the project owner**
1. Compare `/join/<token>` with GE6 and the yellow card on the members screen with GE9.
2. As Minh copy the link; in a private window sign in as Lan, open it, pick Lan's shape → Lan lands in the group.
3. In a third window sign in as Hùng and open the link → Lan's shape is greyed with "đã có người nhận".
4. Open a link after Minh has disabled it → "Link mời này không còn dùng được".

---

### Task 1B.11: Web — roles, settings, leaving, read-only, realtime

**Files:**
- Create: `apps/web/src/lib/group-users.ts`, `apps/web/src/lib/use-group-events.ts`, `apps/web/src/app/g/[groupId]/layout.tsx`, `apps/web/src/components/ui/ConfirmDialog.tsx`, `apps/web/src/components/ui/SegmentedControl.tsx`, `apps/web/src/components/settings/InviteLinkCard.tsx`, `apps/web/src/components/settings/TransferOwnershipCard.tsx`
- Modify: `apps/web/src/components/members/MemberRow.tsx`, `MemberEditor.tsx`, the members and settings pages, `apps/web/src/components/feed/EntryBar.tsx`, the group page, `apps/web/src/messages/vi.ts`

**Interfaces — produces:**
- `useGroupEvents(groupId)` — mounted once in `g/[groupId]/layout.tsx`. Opens an `EventSource` on `/api/v1/groups/{groupId}/events`. `changed` → invalidate the query for each named resource (`transactions`, `balances`, `members`, `users`, `group`) and `["groups"]`. `removed` → clear the group's queries, `router.replace("/")`, and show `Bạn không còn ở trong nhóm này.` once on S2. On reconnect after an error → invalidate every query of the group.
- `ConfirmDialog(props: { title; body; confirmLabel; cancelLabel; onConfirm; onCancel; confirmDisabled?; children? })` — a native `<dialog>` opened with `showModal()`; focus starts on the cancel button; Escape cancels.
- `SegmentedControl(props: { label; options: Array<{ value; label }>; value; onChange; disabled? })` — a `role="group"` of `aria-pressed` buttons, height 44, radius 18; selected ink.

Strings (in addition to design spec 9.6, 9.7):

| Key | Value |
|---|---|
| `members.loggedInYou` | `Bạn · đã đăng nhập` |
| `members.joined` | `Đã vào nhóm` |
| `members.unclaimed` | `Chưa ai nhận hình này` |
| `members.noShape` | `Chưa chọn hình` |
| `members.roleEditor` | `Đọc-ghi` |
| `members.roleViewer` | `Chỉ xem` |
| `members.roleLabel` | `Quyền của {name}` |
| `members.removeUser` | `Gỡ khỏi nhóm` |
| `members.thisIsMe` | `Đây là tôi` |
| `members.leave` | `Rời nhóm` |
| `members.leaveTitle` | `Rời nhóm {name}?` |
| `members.leaveBody` | `Hình và các khoản chi của bạn vẫn được giữ.` |
| `feed.chooseShape` | `Chọn hình của bạn trong nhóm` |
| `settings.defaultRoleTitle` | `Người vào bằng link` |
| `settings.defaultRoleHint` | `Quyền họ nhận khi vừa vào.` |
| `settings.linkTitle` | `Link mời` |
| `settings.linkOn` | `Đang bật. Tạo link mới thì link cũ hết dùng được.` |
| `settings.linkOff` | `Đang tắt. Không ai vào được bằng link.` |
| `settings.disableLink` | `Tắt link` |
| `settings.enableLink` | `Bật link` |
| `settings.rotateLink` | `Tạo link mới` |
| `settings.transferTitle` | `Chuyển quyền chủ nhóm` |
| `settings.transferHint` | `Chọn một người đã vào nhóm.` |
| `settings.transferNobody` | `Chưa có ai khác trong nhóm.` |
| `settings.transferConfirmTitle` | `Chuyển quyền chủ nhóm cho {name}?` |
| `settings.transferConfirmBody` | `Bạn sẽ thành người đọc-ghi.` |
| `settings.transferConfirm` | `Chuyển` |

Behavior:

| Part | Behavior |
|---|---|
| `MemberRow` | Sub-line: `members.loggedInYou` for the viewer's member; `members.joined` for another claimed member; `members.unclaimed` otherwise; inactive members keep `Ngừng hoạt động`. A chip on claimed members: `Chủ nhóm` (accent), `Đọc-ghi` or `Chỉ xem` (`sunken`). Users without a member follow as rows with a `sunken` circle and `members.noShape`. |
| `MemberEditor` | Rename, deactivate, delete now apply to every member (editor and owner). For an unclaimed active member, any user sees `members.thisIsMe`. The owner, on another user's row, also sees a `SegmentedControl` labelled `members.roleLabel` and `members.removeUser`, which opens the confirmation of spec 9.6. |
| Bottom of S10 | Non-owners get `members.leave` (surface, height 60) with a `ConfirmDialog`; on 204 go to `/`. |
| Viewer | S10 shows rows only (plus `members.thisIsMe` and `members.leave`); `EntryBar` becomes a `sunken` bar, height 64, radius 32, with `Chỉ xem` 14px weight 600 muted; no "Nhập tay", no `InviteCard`. A 403 from any action shows `Bạn không có quyền làm việc này.` |
| No linked member | S4 shows a surface link `feed.chooseShape` to the members screen above the stream; the balance block shows the settled wording. |
| S11 | Adds, below "Gộp nợ" (GE11): the default-role row with a `SegmentedControl`; `InviteLinkCard` with the on/off line and the two buttons (surface on `bg`, height 48), "Tạo link mới" asking nothing; `TransferOwnershipCard` listing the other users as buttons and confirming with a `ConfirmDialog`, after which the page goes to `/g/{id}/members`. |

- [ ] **Step 1: Write hooks, shared components, and the changes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser, two windows (Minh, Lan):**
1. Minh adds an expense through the form → it appears in Lan's stream and her balance block changes within 2 seconds, without reload (FR-1.80).
2. Lan is scrolled up in a long stream when Minh adds an expense → Lan's view does not move.
3. Minh renames a member → Lan sees the new name on every screen she has open.
4. Minh sets Lan to "Chỉ xem" → Lan's entry bar turns into "Chỉ xem" without reload; opening `/g/{id}/tx/new` directly shows the forbidden message.
5. Minh removes Lan → Lan is sent to the list with "Bạn không còn ở trong nhóm này."
6. Stop and restart the API while both are open → both streams reconnect and data refreshes; no error state sticks.
7. Lan leaves; Minh's member list updates.
8. Minh transfers ownership to Lan → Minh loses the settings link; Lan gains it.
9. Disable the link, rotate it → the QR changes; the old link shows the invalid-link page.
10. All dialogs: focus is trapped, Escape cancels, focus returns to the opener.

- [ ] **Step 4: Commit** — `feat(web): add roles, sharing settings, read-only mode, and live updates`

**Manual checks for the project owner**
1. Do exercise steps 1, 4 and 5 with two windows side by side.
2. Compare the settings screen with GE11: every row is there except "Xoá nhóm" (stage 1E).
3. As a "Chỉ xem" person try every screen → nothing lets you add or change.
4. Turn Wi-Fi off and on with a group open → after reconnecting, a change made in the other window appears.

---

### Task 1B.12: Stage gate 1B

- [ ] **Step 1: Run the stage gate** as `00-overview.md` describes. Acceptance script for this stage, on a reset database, `curl` only:

1. Register `ngan@example.test`; confirm `POST /groups` is 403 before verification; verify with the token from the API console; sign in.
2. Dev-login Minh creates "Đà Lạt 12/2026" with Lan, Hùng, Thu and the two expenses of the 1A.6 table.
3. Dev-login Lan previews and joins as Lan; Ngân joins with `newMemberName: "Ngân"`; dev-login Hùng joins as Hùng.
4. Lan's `GET /groups` shows `myBalance` 0; Hùng's shows −300000.
5. Minh sets Ngân to `viewer`; Ngân's create-transaction is 403; her reads are 200.
6. Lan holds an event stream; Minh creates "Cà phê" 100000 split Minh, Lan, Hùng → the `changed` line arrives within 2 seconds.
7. Minh removes Hùng → Hùng gets 404 on the group; balances still show Hùng's member.
8. Minh rotates the link → the old token is 404 `INVITE_INVALID`.
9. Forgot and reset for Ngân → all her earlier sessions get 401.
10. Register an existing email and a new email → identical responses; forgot-password likewise.
11. `pnpm db:check-balances` → balanced. The full permission matrix with owner, editor, viewer, outsider and signed-out callers.
12. The 1A acceptance script again → unchanged numbers.

- [ ] **Step 2: Record the gate result in `progress.md`; commit any fixes**

**Manual checks for the project owner — stage 1B**
1. With two phones or two browser profiles, go through flow A and flow B of the design document from sign-up to both people seeing the same new expense.
2. Check that nothing on the sign-in, register or forgot-password screens tells you whether an email already has an account.
