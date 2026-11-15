# Phase 5 — iOS — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` first; its sections 4, 5 and 7 apply here. Of all the specs this one is the furthest from being built and the most likely to be amended before its run.

## 1. Intent

A native iPhone application that does everything the web application does at the time it ships, opens faster, and tells people about changes with push notifications.

**Goals:** FR-5.1 to FR-5.5; US-5.1 to US-5.3. Roadmap target: testers install through TestFlight and use it daily instead of the web.

**Non-goals:** iPad layout; widgets; Apple Watch; working offline beyond what is already in memory; any logic that the server owns.

**Anti-goals:** a number computed on the phone that the server did not send; a session token anywhere but the Keychain; a contract change that breaks the installed application.

## 2. Scope and stages

| Stage | Where | Adds |
|---|---|---|
| 5A | This repository, branch `phase-5` | Contract freeze and OpenAPI snapshot; mobile sessions; Google for native apps; Apple sign-in; device registration; push sender; universal-link file |
| 5B | iOS repository | Project, design system, generated client, sign-in, and screens S1–S13 of phase 1 |
| 5C | Both | Push notifications; universal links for invites |
| 5D | iOS repository | Whatever of phases 2–4 is on `main` when the run starts; receipt capture with the camera |
| 5E | iOS repository | Release configuration, privacy manifest, store texts, TestFlight runbook |

**Requires:** phase 1. Stage 5C's push needs the notifications of phase 4B; when phase 4 is not merged, 5C builds only the universal links and records the rest as not built. Stage 5D is defined by what exists: the re-baseline task lists the merged phases and takes each one's "Screens" section as its scope.

## 3. Repository and rules

- A separate repository, `songphang-ios`, beside this one (ADR-012). The advisor creates it with the plan, containing an `AGENTS.md` adapted from this repository's: the same sections, with the automated gate replaced by `xcodebuild build` with warnings treated as errors and `swift format lint --strict`, and the same rule that no automated tests are written.
- The run has two working directories. Run files stay in this repository under `docs/superpowers/runs/phase-5/`; commits in the iOS repository are recorded there by hash.
- Engineering artifacts in English; user-visible strings Vietnamese, in one String Catalog, **identical character for character** to `apps/web/src/messages/vi.ts`. A string that exists on the web is never reworded for iOS.

## 4. API work (5A)

### 4.1 Contract stability

- `packages/contract/openapi.json` is generated and committed. New script `pnpm contract:check` (approved with this spec) regenerates it and fails when the committed file differs; it joins `pnpm check`.
- **Rule from this stage on, for every later phase:** version 1 of the API changes only by addition (new endpoints, new optional request fields, new response fields, new enumeration values, new error codes). Removing or renaming anything, or making an optional field required, needs `/api/v2` and the advisor's decision. Clients must ignore unknown fields and treat an unknown enumeration value as "other".
- `GET /features` gains `minAppVersion: { ios, android }`. The applications send `X-App-Version`; a build older than the minimum shows one blocking screen.

### 4.2 Sessions for native apps

The session layer already accepts `Authorization: Bearer` (ADR-017). Additions:

| Endpoint | Does |
|---|---|
| `POST /auth/token` | Email and password in, `{ token, user }` out. Same checks, limits and identical failure answer as `POST /auth/login` |
| `GET /auth/google?client=ios&code_challenge=…` | Runs the existing flow; at the end, instead of setting a cookie, redirects to `songphang://auth?code=…` |
| `POST /auth/exchange` | `{ code, codeVerifier }` in, `{ token, user }` out |
| `POST /auth/apple` | Section 4.3 |
| `POST /me/devices`, `DELETE /me/devices/{id}` | Section 4.4 |

- The exchange code is a single-use token of purpose `mobile_exchange` in `auth_tokens`, valid 60 seconds, stored as a hash together with the application's PKCE challenge. Another application that registers the same URL scheme and receives the code cannot redeem it without the verifier.
- A request authenticated by a Bearer token and carrying no cookie skips the same-origin check (there is no ambient credential to abuse). A request carrying a cookie is always checked.
- Sessions gain `client text` (`'web'`, `'ios'`, `'android'`) and `device_name text`, shown in a new "Thiết bị đang đăng nhập" list on the account screen, each with `Đăng xuất`.

### 4.3 Apple sign-in

- `POST /auth/apple` takes `{ identityToken, rawNonce, authorizationCode, name? }`.
- The identity token is a JWT. It is verified with `node:crypto` against Apple's published keys (fetched with `fetch`, cached for 24 hours): signature, issuer, audience equal to `APPLE_BUNDLE_ID`, expiry, and that the token's nonce is the SHA-256 of `rawNonce`. No library; this is verification with a standard primitive, not home-made cryptography.
- Account rules are those of Google in phase 1 (first sign-in creates a verified user and an `apple` identity; a matching verified password account is linked; a matching unverified one is refused with the same message). Apple's relay addresses are accepted as emails.
- **Revocation.** The App Store requires that deleting an account revokes its Apple tokens. The server exchanges `authorizationCode` for a refresh token (this needs `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`) and stores it in `user_identities.provider_secret`, encrypted with AES-256-GCM from `node:crypto` under `DATA_ENCRYPTION_KEY`. `DELETE /me` calls Apple's revoke endpoint before deleting. Without the Apple variables the endpoint answers 404 and `features.apple` is false.
- **Local adapter:** `APPLE_PROVIDER=fake` verifies tokens against a key set in a local file and skips the exchange, so the whole flow can be exercised with a locally signed token.

### 4.4 Push

- `push_devices`: `id`, `user_id` (cascade), `platform` (`'ios'`, `'android'`), `token` (unique), `environment` (`'sandbox'`, `'production'`), `created_at`, `last_seen_at`. Signing out deletes the device row of that session.
- `PushSender` in `deps`: `send(device, { title, body, groupId, target })`. Adapters: `apns` (HTTP/2 through `node:http2`, provider token signed with ES256 through `node:crypto`; needs the three Apple variables and `APPLE_BUNDLE_ID`) and `console`.
- A push is sent for each notification whose kind is "immediate" in phase 4, and for `expense_added` and `comment_added`, to every device of the recipient, by a worker job, unless the group is muted. Title and body are the notification's line from phase 4 section 7.2. A token Apple reports as unregistered is deleted.
- Push content is visible on a lock screen. It carries the same line the in-application list shows, and the account screen gains a switch `Ẩn nội dung trên màn hình khoá`, which replaces the body with `Có cập nhật trong nhóm {group}`.

### 4.5 Universal links

The web application serves `/.well-known/apple-app-site-association` (JSON content type, no redirect) built from `APPLE_APP_ID`, for the paths `/join/*` and `/link/*`. Without the variable the route answers 404.

## 5. The application (5B–5D)

### 5.1 Technology

| Choice | Decision |
|---|---|
| Language, UI | Swift 6, SwiftUI; minimum iOS 17 |
| API client | Generated at build time from the committed `openapi.json` by Apple's `swift-openapi-generator`, with `swift-openapi-runtime` and `swift-openapi-urlsession` (all Apache-2.0, maintained by Apple) |
| Other dependencies | None. Google sign-in uses `ASWebAuthenticationSession`, not Google's SDK; QR codes are drawn with Core Image from the server's payload; photos use PhotosUI and the system camera |
| State | One `@Observable` model per screen; one `APIClient` actor; an in-memory cache keyed like the web's query keys. No database on the device |
| Session | The token in the Keychain, accessible after first unlock, this device only. Never in user defaults, logs or crash text |
| Realtime | The group's SSE stream read with `URLSession.bytes`; on an event, the named resources are refetched; on reconnect, everything for the open group |
| Font | Be Vietnam Pro, bundled (SIL Open Font License) |

### 5.2 Rules carried from the web

- Every amount shown as official comes from the API: shares from `preview`, balances from `balances`, the QR payload from the server.
- Money is `Int` (64-bit) end to end; one formatter produces `150.000 đ`.
- Every create sends an idempotency key generated once per form instance.
- Screens have the four states of user-flows section 7; offline shows the banner and disables writing.
- Member shapes and colors map the server's codes to SwiftUI shapes and the same hex values.
- Navigation follows user-flows section 3 with a navigation stack; system back gestures work everywhere; sheets are used where the web uses a dialog.
- Dynamic Type up to the largest accessibility size without clipping; every shape has a VoiceOver label that is the member's name; "reduce motion" replaces the four motions with instant changes.

### 5.3 iOS-specific behavior

| Place | Behavior | String |
|---|---|---|
| Sign-in (S1) | `Đăng nhập với Apple` above `Tiếp tục với Google`, in Apple's required button style | as shown |
| Receipt capture | The camera opens directly from the entry bar; the photo is resized to at most 2,000 pixels and JPEG 0.85 before upload | `Chụp hoá đơn` |
| Camera permission text | | `Sòng Phẳng dùng máy ảnh để chụp hoá đơn.` |
| Photo library permission text | | `Sòng Phẳng cần ảnh bạn chọn để đính kèm hoá đơn.` |
| Push permission | Asked after the user's first saved expense, never at launch, preceded by one screen | `Bật thông báo để biết khi có khoản chi mới hoặc ai đó nhắc bạn.` · `Bật thông báo` · `Để sau` |
| Invite link | Opens S12 in the application; a signed-out user signs in first and returns to it | |
| Too old a build | Blocking screen | `Hãy cập nhật Sòng Phẳng để tiếp tục.` · `Mở App Store` |
| Sharing an invite | The system share sheet with the link | |
| Paying (phase 2) | The QR code can be saved to Photos, since the banking app is on the same phone | `Lưu mã QR` |

## 6. Release (5E)

Release build configuration with the production API address; application icon from the phase 7A mark (or the four shapes if 7A has not run); `PrivacyInfo.xcprivacy` declaring the collected data types of phase 7B section 4.1 and no tracking; the store listing texts in Vietnamese (name `Sòng Phẳng`, subtitle `Chia tiền nhóm, gõ như nhắn tin`, description from the landing page); `docs/runbooks/testflight.md` for the owner: certificates, the push key, archive, upload, adding testers. The agent archives nothing and uploads nothing.

## 7. Verification

- **Gate after each stage:** this repository's gates as usual; in the iOS repository `xcodebuild build` clean of warnings and the lint; the application run in the iOS Simulator against the local API (`http://localhost:4000`, allowed by an App Transport Security exception present only in the debug configuration), walking the stage's flows, with a screenshot of each screen recorded in `progress.md`.
- **5A scripts:** `POST /auth/token` behaves as login does for known and unknown emails; an exchange code works once, fails with a wrong verifier, fails after 60 seconds; a locally signed Apple token signs in, and one with the wrong audience, a wrong nonce or an expired date is refused; the full permission matrix passes with Bearer sessions; `pnpm contract:check` fails on a hand-edited snapshot.
- **5C:** a push payload delivered to the Simulator with `xcrun simctl push` opens the right screen; the console sender prints one push per device for a reminder and none for a muted group.

**Not verified by the agent:** a real device; real APNs; real Apple and Google sign-in; universal links (they need the real domain); TestFlight; battery and cold-start time.

## 8. Left to the builder

File layout inside the iOS project; model and view names; the cache's eviction; transitions; which system components back each web component.

## 9. Changes to standing documents

| Document | Change |
|---|---|
| `docs/04-adr.md` | ADR-029: API v1 is additive-only, with a committed OpenAPI snapshot. ADR-030: native apps sign in through the system browser and a PKCE-bound exchange code. ADR-014 gains the versions chosen here |
| `docs/05-api-spec.md` | Section 4.2–4.5 endpoints; the versioning rule |
| `docs/05-database-design.md` | `push_devices`; new columns on `sessions` and `user_identities`; `apple` provider |
| `docs/03-srs.md` | FR-5.x refined with sections 4 and 5.3 |
| `AGENTS.md` | Section 5's "must ask" list gains "any non-additive API change" |

## 10. Owner's prerequisites

Before the run: approve this spec, the three Apple packages, and the new script; a Mac with a current Xcode. Any time after: an Apple Developer account (yearly fee), from which come the bundle id, the team id and the push key.
