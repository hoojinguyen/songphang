# Phase 5 — Stage 5A: API for Native Clients

> Part of the phase 5 plan. Read `00-overview.md` first. All tasks here are in this repository.

**Stage goal:** the contract is frozen and checked, and the API can sign in, identify and notify a native application.

**Spec:** section 4.

## Decisions for this stage

1. The exchange code's PKCE method is S256 only. The challenge is 43–128 characters of the unreserved set; anything else is refused at `/auth/google`.
2. `client` is `ios` or `android`; both redirect to `songphang://auth`. The Android value is accepted now so phase 6 changes nothing here.
3. Apple's key set is fetched from `https://appleid.apple.com/auth/keys` at most once per 24 hours and again at once when a token names an unknown key id (at most once per minute).
4. `provider_secret` is stored as `v1:` + base64 of `iv (12 bytes) || ciphertext || tag (16 bytes)`; `DATA_ENCRYPTION_KEY` is 32 bytes, base64 in the environment.
5. A push job gives up on a device after APNs answers 410 or `BadDeviceToken` and deletes the device.

---

### Task 5A.1: Contract freeze

**Files:**
- Create: `packages/contract/openapi.json` (generated), `packages/contract/src/scripts/write-openapi.ts`, `packages/contract/src/scripts/check-openapi.ts`
- Modify: `packages/contract/package.json`, root `package.json` (`"contract:write"`, `"contract:check"`, and `check` gains `&& pnpm contract:check`), `apps/api/src/routes/features.ts`, `packages/contract/src/features.ts`, `README.md`

**Interfaces — produces:**
- `pnpm contract:write` regenerates the file deterministically (sorted keys, stable order) from the same registry the API serves.
- `pnpm contract:check` regenerates in memory and compares. A difference fails with the list of changed paths, and classifies each by a small comparison of the two documents: `added path`, `added optional property`, `added enum value`, `added response` are **additive**; anything else is **breaking**. Additive differences fail with "run `pnpm contract:write` and commit"; breaking ones fail with "breaking change: needs `/api/v2` and the advisor's decision".
- `GET /features` gains `minAppVersion: { ios: string, android: string }` from `MIN_APP_VERSION_IOS` and `MIN_APP_VERSION_ANDROID` (default `"0.0.0"`).
- Every enum in the contract that may grow (notification kinds, transaction types, split methods, error codes, categories, issue codes) is listed in the README under "Clients must tolerate unknown values".

- [ ] **Step 1: Write it; commit the generated file in this task**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — each edit is made, checked, and reverted:

| Edit to a contract schema | `pnpm contract:check` |
|---|---|
| none | passes |
| add an optional response field | fails, "additive" |
| add a new endpoint | fails, "additive" |
| rename a response field | fails, "breaking" |
| make an optional request field required | fails, "breaking" |
| remove an enum value | fails, "breaking" |
| hand-edit `openapi.json` | fails |

- [ ] **Step 4: Commit** — `chore(contract): freeze the API contract in a committed OpenAPI file`

---

### Task 5A.2: Sessions for native clients

**Files:**
- Create: `apps/api/src/routes/mobile-auth.ts`, `apps/api/src/services/mobile-auth.ts`, a migration
- Modify: `packages/db/src/schema-accounts.ts` (`sessions.client`, `sessions.device_name`; `auth_tokens.purpose` gains `mobile_exchange`, plus `auth_tokens.context text` for the challenge), `apps/api/src/auth/sessions.ts`, `apps/api/src/auth/middleware.ts` (same-origin rule), `apps/api/src/routes/google.ts`, `apps/api/src/services/google-sign-in.ts`, `apps/api/src/routes/me.ts`, `packages/contract/src/auth.ts`, the account screen of the web app (`Thiết bị đang đăng nhập`)

**Interfaces — produces:**
- `POST /auth/token` (`{ email, password, deviceName: string (1–60), client: "ios" | "android" }`) → `{ token, user }`. It calls the same service function as `POST /auth/login` (same rate limits, same hash work for unknown emails, same 401 body) and differs only in returning the token instead of setting a cookie.
- `GET /auth/google?client=ios&code_challenge=…[&redirect=…]`: stores `client` and the challenge in the existing state cookie; the callback, for a native client, creates an exchange code and redirects to `songphang://auth?code=…` (or `songphang://auth?error=…` with the same error keys the web uses). No session is created at this point.
- `POST /auth/exchange` (`{ code, codeVerifier, deviceName, client }`) → `{ token, user }`: the code's hash must exist, be unused and unexpired (60 seconds), and `base64url(sha256(codeVerifier))` must equal the stored challenge (constant-time). Any failure → 400 `TOKEN_INVALID`; the code is marked used on the first attempt, successful or not. 10 attempts per minute per IP.
- Same-origin rule: a request with a session cookie is checked as today. A request with `Authorization: Bearer` **and no cookie header at all** skips the check.
- `GET /me/sessions` → `[{ id, client, deviceName, createdAt, lastSeenAt, current }]`; `DELETE /me/sessions/{id}` (the caller's own; revoking the current one signs out).
- Bearer tokens are accepted only in the header, never in a query parameter; confirm no route reads `?token=` for sessions.

- [ ] **Step 1: Write it; `pnpm contract:write`**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 2)**

| Request | Expected |
|---|---|
| `POST /auth/token` with a right password | 200; the token works as `Bearer` on `GET /me` |
| with a wrong password, and with an unknown email | identical 401 bodies; similar timings (record) |
| 6 attempts for one email in 15 minutes | 429, shared with `/auth/login`'s counter |
| a `POST` creating a group with `Bearer` and no `Origin` header | 201 |
| the same with a session cookie and a foreign `Origin` | 403 |
| the same with both a cookie and a `Bearer` header and a foreign `Origin` | 403 |
| the whole permission matrix replayed with Bearer sessions | identical to cookies |
| create an exchange code directly through the service (Google cannot be called); exchange with the right verifier | 200 |
| the same code again | 400 `TOKEN_INVALID` |
| a new code with a wrong verifier, then the right one | 400, then 400 (burned) |
| a code dated 61 seconds back | 400 |
| `GET /auth/google?client=ios` without a challenge, with a 10-character challenge | 400 each |
| `GET /me/sessions`; delete the other session; use its token | listed; 204; 401 |
| `GET /me?token=<token>` | 401 |

The API log of the whole exercise searched for the token and the code values → absent.

- [ ] **Step 4: Commit** — `feat(api): add sessions and Google sign-in exchange for native clients`

---

### Task 5A.3: Apple sign-in

**Files:**
- Create: `apps/api/src/auth/apple/verify-identity-token.ts`, `apps/api/src/auth/apple/key-set.ts`, `apps/api/src/auth/apple/client-secret.ts`, `apps/api/src/auth/apple/token-client.ts` (interface: `exchange(code)`, `revoke(refreshToken)`; adapters `apple` and `fake`), `apps/api/src/auth/secret-box.ts`, `apps/api/src/services/apple-sign-in.ts`, a migration
- Modify: `packages/db/src/schema-accounts.ts` (`user_identities.provider` accepts `apple`; `provider_secret text`), `apps/api/src/routes/mobile-auth.ts`, the account deletion service, `apps/api/src/config.ts`, `apps/api/src/routes/features.ts` (`apple`), `packages/contract/src/auth.ts`, `.env.example`

**Interfaces — produces:**
- `verifyAppleIdentityToken(token, { audience, rawNonce, keys, now }): { sub: string; email: string | null; emailVerified: boolean }` or a typed failure. Steps: split into three parts; header `alg` must be `RS256` (reject `none` and every other value); find the key by `kid`; verify the signature with `crypto.verify("RSA-SHA256", …)` using `createPublicKey({ key: jwk, format: "jwk" })`; `iss` = `https://appleid.apple.com`; `aud` = `APPLE_BUNDLE_ID`; `exp` in the future and `iat` not more than 10 minutes in the future; `nonce` = hex or base64url SHA-256 of `rawNonce` (read Apple's documentation for which; record it). Apple sends `email_verified` as a boolean or the string `"true"`; accept both.
- `seal(plaintext): string` and `open(sealed): string` in `secret-box.ts`: AES-256-GCM, random 12-byte IV per call, decision 4's format; `open` throws on a wrong key or a modified value.
- `POST /auth/apple` (`{ identityToken, rawNonce, authorizationCode, name?, deviceName, client }`) → `{ token, user }`. Account rules: phase 1 spec 6.5 with `apple` in place of `google`; no email in the token and no existing identity → 400 `VALIDATION_FAILED`. On success, exchange the authorization code and store `seal(refreshToken)`; an exchange failure does not fail the sign-in but is logged (code only) and leaves `provider_secret` NULL.
- `DELETE /me`: when an Apple identity has a `provider_secret`, call `revoke` first; a revoke failure is logged and the deletion proceeds.
- `APPLE_PROVIDER` = `apple` (requires `APPLE_BUNDLE_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, `DATA_ENCRYPTION_KEY`), `fake` (keys from `APPLE_FAKE_JWKS_FILE`; the token client returns a fixed refresh token and records revocations in memory), or unset → 404 and `features.apple` false.

- [ ] **Step 1: Read Apple's documentation on verifying the identity token, on generating the client secret, and on the token and revoke endpoints; record the pages and date; write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 5)** — `APPLE_PROVIDER=fake`. A scratch script (not committed) generates an RSA key pair, writes the public key as a key set file, and signs tokens.

| Token | Expected |
|---|---|
| valid, new `sub`, verified email | 200; a user and an `apple` identity; `provider_secret` starts with `v1:` and is not the plain refresh token |
| the same `sub` again | 200; the same user |
| valid, email equal to a **verified** password account | signs into that account; an identity is added |
| valid, email equal to an **unverified** password account | refused with the phase 1 error for this case |
| signature from another key | 401 |
| header `alg: none` with an empty signature | 401 |
| header `alg: HS256` signed with the public key as the secret | 401 |
| wrong `aud`; wrong `iss`; expired; nonce of another value | 401 each |
| an unknown `kid` | 401 after one key-set refresh |
| `open(seal("x"))`; `open` of a value with one byte changed; with another key | `"x"`; throws; throws |
| delete the account | the fake client recorded one revocation; the user is gone |
| unset `APPLE_PROVIDER` | 404; `features.apple` false |

- [ ] **Step 4: Commit** — `feat(api): add Apple sign-in with token revocation on account deletion`

---

### Task 5A.4: Device registration

**Files:**
- Create: `packages/db/src/schema-push.ts`, `packages/db/src/push-devices.ts`, `packages/contract/src/push.ts`, `apps/api/src/services/devices.ts`, a migration
- Modify: `apps/api/src/routes/me.ts`, the sign-out service, `packages/db/src/schema-accounts.ts` (`users.push_hide_content boolean NOT NULL DEFAULT false`), `packages/contract/src/user.ts`

**Interfaces — produces:**
- Table `push_devices` as spec 4.4, plus `session_id uuid REFERENCES sessions ON DELETE CASCADE` so revoking a session removes its device.
- `POST /me/devices` (`{ platform, token: string (32–4096), environment }`) → 200 `{ id }`. A token that exists is moved to the caller and the current session (a phone changes hands). At most 10 devices per user; the oldest is dropped.
- `DELETE /me/devices/{id}`. `PUT /me/push-settings` (`{ hideContent }`); `GET /me` gains `pushHideContent`.

- [ ] **Step 1: Write it; `pnpm contract:write`**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — register; register the same token from another user → it moves; sign out → the row is gone; an eleventh device drops the oldest; a cookie session may not register (400: devices belong to native sessions).
- [ ] **Step 4: Commit** — `feat(api): add push device registration`

---

### Task 5A.5: Push sender and delivery job (needs phase 4)

**Files:**
- Create: `apps/worker/src/push/push-sender.ts` (interface and selection), `apps/worker/src/push/apns-sender.ts`, `apps/worker/src/push/console-sender.ts`, `apps/worker/src/push/apns-token.ts`, `apps/worker/src/jobs/send-push.ts`, `packages/core/src/notification-text.ts` (moved from the web if it lives there, so worker, web and bot share one source of the lines)
- Modify: `apps/api/src/services/notify.ts` (enqueue `send-push` after commit for the kinds of spec 4.4), `packages/contract/src/jobs.ts`, `apps/worker/src/config.ts`, `.env.example`

**Interfaces — produces:**
- `interface PushSender { send(device: { platform; token; environment }, message: { title: string; body: string; groupId: string; target: string }): Promise<"sent" | "gone" | "failed"> }`.
- `apnsProviderToken(config, now): string` — an ES256 JWT (`iss` team id, `iat`, header `kid`) signed with `crypto.sign("sha256", …, { key, dsaEncoding: "ieee-p1363" })`, cached for 50 minutes.
- The APNs adapter keeps one HTTP/2 session per environment through `node:http2`, posts to `/3/device/{token}` with `apns-topic` = the bundle id, `apns-push-type: alert`, a JSON payload `{ aps: { alert: { title, body }, sound: "default" }, groupId, target }`, a 10-second timeout; maps 200 → `sent`, 410 or reason `BadDeviceToken`/`Unregistered` → `gone`, anything else → `failed` (logged with the status and the reason, never the token).
- Job `send-push` (`{ notificationId }`): skip when read, when the recipient left the group or muted it; for each device of the recipient send; `gone` deletes the device. Title = the group's name; body = the notification's line from `notificationText`, or `Có cập nhật trong nhóm {group}` when the user's `push_hide_content` is true.
- `PUSH_PROVIDER` = `apns` (requires the Apple variables), `console`, or unset (no push jobs are enqueued).

- [ ] **Step 1: Read Apple's documentation on sending notification requests to APNs and on token-based connection; record; write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)** — `PUSH_PROVIDER=console`; Lan has two devices, Hùng one.

| Action | Expected console lines |
|---|---|
| Minh reminds Lan | two, with the reminder's line as the body |
| Lan sets `hideContent` true; another reminder (after dating the first back) | two, body `Có cập nhật trong nhóm {group}` |
| Lan mutes the group | none |
| Lan signs out on one device | one fewer afterwards |
| a notification read before the job runs | none |
| Hùng is removed from the group before the job runs | none |
| `apnsProviderToken` decoded | header `alg` ES256 and the key id; payload `iss` and `iat`; the signature verifies with the matching public key |

Record under "Not verified": real APNs.

- [ ] **Step 4: Commit** — `feat(worker): send push notifications`

---

### Task 5A.6: Universal-link file; stage gate

**Files:**
- Create: `apps/web/src/app/.well-known/apple-app-site-association/route.ts`
- Modify: `apps/web` configuration for the environment variable, `infra/Caddyfile` if it exists (no redirect and JSON content type for the path), `.env.example`

**Interfaces — produces:** with `APPLE_APP_ID` (`TEAMID.bundle.id`) set, 200 `application/json`: `{ "applinks": { "details": [{ "appIDs": ["…"], "components": [{ "/": "/join/*" }, { "/": "/link/*" }] }] } }`; unset → 404.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — both states; no redirect; content type exact.
- [ ] **Step 4: Commit** — `feat(web): serve the Apple universal-link association file`
- [ ] **Step 5: Stage gate 5A.** Acceptance script: 5A.1 rows 1 and 4; 5A.2 rows 1, 2, 8, 9, 10; 5A.3 rows 1, 5, 6, 8; 5A.5 rows 1–3. Then the gate of the common file, with the permission matrix replayed twice: cookies and Bearer.
