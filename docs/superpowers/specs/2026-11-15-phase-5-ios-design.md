# Phase 5 — iOS — Design

Originally drafted 2026-11-15. Revised 2026-11-19. Status: draft for owner approval. Sections 4, 5 and 7 of [the remaining-roadmap overview](2026-11-15-roadmap-remaining-phases-overview.md) apply.

The approved [iOS architecture design](2026-11-16-ios-codebase-architecture-design.md) governs modules, layers, dependency rules and performance. This revision governs Phase 5 delivery order. The [existing Phase 5 plan](../plans/2026-11-15-phase-5/00-overview.md) is historical planning input until revised against the approved spec.

## 1. Intent

A native iPhone application with the user-facing capabilities of the web baseline established in Task 0, fast launch onto existing content, and push notifications. The owner selected an early acceptance checkpoint for the shared iOS/web expense-splitting journey on the Simulator on 2026-11-19. Full parity remains a Phase 5 exit requirement.

**Goals:** FR-5.1 to FR-5.5; US-5.1 to US-5.3. Roadmap target: testers install through TestFlight and use it daily instead of the web.

**Non-goals:** iPad layout; widgets; Apple Watch; working offline (the last-known snapshots of the architecture design's section 8.1 show content at once; they do not allow writing or queue changes); any logic that the server owns.

**Anti-goals:** a number computed on the phone that the server did not send; a session token anywhere but the Keychain; a contract change that breaks the installed application.

## 2. Scope and stages

### 2.1 Approaches

| Approach | Trade-off |
|---|---|
| **Core integration with an early Simulator checkpoint, then full parity** | Exercises the shared contract, session and ledger before later features depend on them. Requires an early build and evidence handoff plus a final parity pass. Chosen by the owner. |
| Single acceptance after full parity | Exercises the complete product in one acceptance round. Contract, session and ledger problems can surface after dependent screens have already been built. |

### 2.2 Delivery order

| Stage | Where | Adds |
|---|---|---|
| 0 | Repository | Pin the starting `main` SHA, inventory current web journeys and API routes, and reconcile the 5U handoff against the Swift code and contract. |
| 5A | API and contract | Generate the OpenAPI snapshot from the registered v1 routes, add contract checks and minimum-version metadata, and support native email/password sessions and session revocation. |
| 5B | `apps/ios/` | Connect S1–S13 to the local API using the generated client and live repositories. Integrate Keychain, snapshots, SSE, the existing account flows and local invite routing with sign-in resumption. End with the early owner checkpoint in §7.2. |
| 5C | API, worker, web and iOS | Integrate native Apple and Google sign-in, device registration and push dispatch, and universal-link delivery for invites. Verify provider-independent behavior locally. |
| 5D | `apps/ios/` with the shared API | Complete the Phase 2–4 parity inventory and native receipt capture. Exercise push destinations that become available with these screens. |
| 5E | `apps/ios/` and runbooks | Validate Release, add the release configuration and assets, and prepare the owner's TestFlight runbook. End with the parity gate. |

The preparation baseline is `22a16fb`, which includes Phases 1–4 and 5U. Task 0 records the actual run baseline and compares it with the 5U reference in the [interface handoff](../runs/ios-ui/progress.md). Product behavior follows the approved requirements and amendments as implemented on that baseline. Record disagreements between those sources for advisor resolution. If the baseline moves before the final gate, review intervening user-facing changes with the owner and update the inventory before claiming parity.

### 2.3 Final parity inventory

Task 0 records each web journey by route or entry point, API, roles, capability flags, iOS destination and acceptance evidence. A SwiftUI flow may use native controls and system surfaces while preserving the same actions, permissions, results and Vietnamese copy. A provider-gated journey is exercised locally with its adapter where possible and has an explicit device or external check for the remaining steps.

| Baseline | Required journeys |
|---|---|
| Phase 1 | Account lifecycle, groups and membership, invite creation and join, roles and group settings, feed and activity, quick/manual entry, split preview, editing, delete and undo, balances and direct settlement. |
| Phase 2 | Payment details and VietQR with the native save action, settlement request and confirmation, categories, search and filters, statistics and drill-downs, CSV export through native sharing, funds and budgets. |
| Phase 3 | Receipt capture and library import, upload and attachments, receipt review, item splitting, and AI-assisted sentence entry including refusal and manual fallback. |
| Phase 4 | Transaction detail, comments and disputes, inbox and notification settings, reminders and mute, approval decisions and their ledger effects, and Telegram linking and management. Keep the bot and email delivery as shared server surfaces. Preserve the existing two-sided Telegram pairing and its initiating-session requirement. |

The final inventory accounts for every baseline journey, including embedded actions and denied states. Local parity requires passing evidence for every journey that can run locally. Provider-dependent steps retain explicit pending evidence until the owner verifies them externally.

## 3. Repository and rules

- **Amended 2026-11-16 (ADR-033):** the application lives in `apps/ios/` of this repository, not in a separate one, and its interface is built first on scripted data (architecture design, section 13). Wherever this spec or its plan says "the iOS repository", read `apps/ios/`.
- `apps/ios/AGENTS.md`, written by the advisor, is adapted from the root one: the same sections, with the automated gate replaced by `xcodebuild build` with warnings treated as errors and `swift format lint --strict`, and the same rule that no automated tests are written.
- Run files are under `docs/superpowers/runs/ios-ui/` for the interface stage and `docs/superpowers/runs/phase-5/` for the rest.
- Engineering artifacts in English; user-visible strings Vietnamese, in one String Catalog, **identical character for character** to `apps/web/src/messages/vi.ts`. A string that exists on the web is never reworded for iOS.

## 4. API work (5A and 5C)

### 4.1 Contract stability

- `packages/contract/openapi.json` is generated from the API's route registry and committed. The snapshot uses a deterministic configuration covering supported v1 capabilities and excludes development-only routes. `pnpm contract:check` regenerates it and fails when the committed file differs. It joins `pnpm check`.
- **Rule from this stage on, for every later phase:** version 1 of the API changes only by addition (new endpoints, new optional request fields, new response fields, new enumeration values, new error codes). Removing or renaming anything, or making an optional field required, needs `/api/v2` and the advisor's decision. Clients must ignore unknown fields and treat an unknown enumeration value as "other".
- `GET /api/v1/features` gains `minAppVersion: { ios, android }`; the existing `appleSignIn`, `push`, and other capability names keep their meaning. Google availability comes from `GET /api/v1/auth/providers`. The applications send `X-App-Version`; a build older than the minimum shows one blocking screen.

### 4.2 Sessions for native apps

The session layer already accepts `Authorization: Bearer` (ADR-017). Paths below are relative to `/api/v1`.

| Stage | Endpoint | Behavior |
|---|---|---|
| 5A | `POST /auth/token` | Accepts email, password, client and device name. Returns `{ token, user }` with the same credential checks, shared limits and failure response as `POST /auth/login`. |
| 5A | `GET /me/sessions`, `DELETE /me/sessions/{id}` | Lists the signed-in user's sessions and revokes a session belonging to that user. Revoking the current session signs the client out. |
| 5C | `GET /auth/google?client=ios&code_challenge=…` | Reuses the existing Google flow and returns a native exchange code through `songphang://auth?code=…`. The web flow keeps its cookie behavior. |
| 5C | `POST /auth/exchange` | Accepts the code, PKCE verifier, client and device name. Returns `{ token, user }`. |
| 5C | `POST /auth/apple` | See §4.3. |
| 5C | `POST /me/devices`, `DELETE /me/devices/{id}` | See §4.4. |

- The exchange code is a single-use token of purpose `mobile_exchange` in `auth_tokens`, valid 60 seconds, stored as a hash together with the application's PKCE challenge. Another application that registers the same URL scheme and receives the code cannot redeem it without the verifier.
- A Bearer-only request can write without a browser Origin. Requests carrying cookies remain subject to the web same-origin policy, including requests carrying both credentials. Assert that web and native sessions share group authorization and that outsiders receive 404.
- Sessions gain `client text` (`'web'`, `'ios'`, `'android'`) and `device_name text`, shown in a new "Thiết bị đang đăng nhập" list on the account screen, each with `Đăng xuất`.

### 4.3 Apple sign-in

- `POST /auth/apple` takes `{ identityToken, rawNonce, authorizationCode, name? }`.
- The identity token is a JWT. It is verified with `node:crypto` against Apple's published keys (fetched with `fetch`, cached for 24 hours): signature, issuer, audience equal to `APPLE_BUNDLE_ID`, expiry, and that the token's nonce is the SHA-256 of `rawNonce`. No library; this is verification with a standard primitive, not home-made cryptography.
- Account rules are those of Google in phase 1 (first sign-in creates a verified user and an `apple` identity; a matching verified password account is linked; a matching unverified one is refused with the same message). Apple's relay addresses are accepted as emails.
- **Revocation.** The server exchanges `authorizationCode` for a refresh token (this needs `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`) and stores it in `user_identities.provider_secret`, encrypted with AES-256-GCM from `node:crypto` under `DATA_ENCRYPTION_KEY`. `DELETE /me` calls Apple's revoke endpoint before deleting. When the provider is disabled the endpoint answers 404 and `features.appleSignIn` is false.
- **Local adapter:** `APPLE_PROVIDER=fake` verifies tokens against a key set in a local file and skips the exchange, so the whole flow can be exercised with a locally signed token.

### 4.4 Push

- `push_devices`: `id`, `user_id` and `session_id` (cascade), `platform` (`'ios'`, `'android'`), `token` (unique), `environment` (`'sandbox'`, `'production'`), `created_at`, `last_seen_at`. Signing out or revoking the session deletes its device row.
- `PushSender` in `deps`: `send(device, { title, body, groupId, target })`. Adapters: `apns` (HTTP/2 through `node:http2`, provider token signed with ES256 through `node:crypto`; needs the three Apple variables and `APPLE_BUNDLE_ID`) and `console`.
- A worker sends push for Phase 4 immediate notifications plus `expense_added` and `comment_added`. Before sending, check that the notification is unread, the recipient still belongs to the group, the group is unmuted and the device is still registered to an active session. Use the group name as the title and the current inbox wording as the body. Remove a token Apple reports as unregistered.
- Push content is visible on a lock screen. It carries the same line the in-application list shows, and the account screen gains a switch `Ẩn nội dung trên màn hình khoá`, which replaces the body with `Có cập nhật trong nhóm {group}`.

### 4.5 Universal links

The web application serves `/.well-known/apple-app-site-association` (JSON content type, no redirect) built from `APPLE_APP_ID`, for `/join/*`. Without the variable it returns 404. A single iOS router checks the configured host and supported paths for links and push destinations. A signed-out user resumes a valid invite after sign-in. A push targeting a later-stage screen opens the authorized group feed during 5C. Invalid or inaccessible targets take the user to the group list. By the 5D gate, supported push targets open their assigned screens after access is checked.

Keep `/link/telegram` in the browser for web-initiated pairing. During 5D, iOS starts its own pairing with its Bearer session, hands off the server-provided start link to Telegram, then polls and confirms or cancels in the initiating iOS session. Account verification and reset continue through the web link flows. The user can then return to the app to sign in.

## 5. The application (5B–5D)

### 5.1 Technology

| Choice | Decision |
|---|---|
| Language, UI | Swift 6, SwiftUI; minimum iOS 26 (architecture design, section 4) |
| API client | Generated at build time from the committed `openapi.json` by Apple's `swift-openapi-generator`, with `swift-openapi-runtime` and `swift-openapi-urlsession` (all Apache-2.0, maintained by Apple) |
| Other dependencies | None. Google sign-in uses `ASWebAuthenticationSession`, not Google's SDK; QR codes are drawn with Core Image from the server's payload; photos use PhotosUI and the system camera |
| Structure and state | The architecture design: one Swift package of compiler-enforced modules; one `@Observable` model per screen; repositories behind protocols. No database on the device; last-known read responses are kept as protected files |
| Session | The token in the Keychain, accessible after first unlock, this device only. Never in user defaults, logs or crash text |
| Realtime | The group's SSE stream read with `URLSession.bytes`; on an event, the named resources are refetched; on reconnect, everything for the open group |
| Font | The 5U system font is sufficient for the early checkpoint. The final app bundles Be Vietnam Pro (SIL Open Font License) from compatible local font files. Task 0 records whether those files are available. If they are missing, request the files or an approved substitution for the final gate. |

### 5.2 Rules carried from the web

- Retain the 5U screens and repository protocols. Add `GeneratedAPI` and `Repositories`; compose live repositories in `AppShell`. Debug previews retain scripted scenarios, and the default Debug run used for acceptance and Release both use live repositories.
- Keep snapshots protected, scoped to the signed-in user and cleared on sign-out, session loss or account deletion. Clear the affected group's snapshots on membership loss. Cancel in-flight reads with invalidated access so a late result cannot recreate cleared snapshots.
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

Provide Release configuration with an owner-supplied HTTPS API address and a reserved placeholder host for the local Release compile check. The owner sets the real host and signing details before archiving. Include the application icon from the Phase 7A mark (or the four shapes if 7A has not run), `PrivacyInfo.xcprivacy` for the app's actual data and required-reason API use with no tracking, and Vietnamese store text (name `Sòng Phẳng`, subtitle `Chia tiền nhóm, gõ như nhắn tin`, description from the landing page or approved product copy if the page has not shipped). In `docs/runbooks/testflight.md`, cover signing, the push key, archive, upload and tester setup. Archiving and upload are owner actions.

## 7. Verification

### 7.1 Stage gates

- Run the common repository gates on a disposable local database, replay earlier acceptance evidence as required by the phase-run rules, and record the permission matrix and `pnpm db:check-balances`. Run the iOS build with warnings as errors and strict Swift format lint. From 5B onward, use the live app with the local API and record screenshots and the architecture design's performance measures when the Simulator supports them. The local HTTP exception belongs only to Debug.
- **5A:** Compare native and web login checks and limits. Replay the full group permission matrix using Bearer sessions, check mixed Cookie/Bearer requests and revoked sessions, and verify that a hand-edited snapshot fails `pnpm contract:check`.
- **5C:** Exercise Google exchange using a locally issued code, including replay, wrong verifier and expiry. Accept a locally signed Apple token through the fake adapter and reject wrong audience, wrong nonce and expiry. Verify local invite routing and sign-in resumption, association document behavior, and simulated push to a valid destination. Check send-time membership, muted groups, hidden lock-screen content, and signed-out devices with the console sender.

### 7.2 Early owner checkpoint after 5B

Use an iPhone Simulator and a web browser with two separate verified local accounts against the same disposable database and API. Configure the local adapters and use email/password. The core ledger journey uses a fresh group with approval disabled. For other groups, preserve the server's existing approval rules and display the ledger state it returns. A local invite can open on web or enter the iOS router through a Debug-only link entry, with the pending invite held in memory during sign-in. Real universal-link association belongs to external verification.

| Exercise | Pass condition |
|---|---|
| Sign in on iOS and create a group; open the invite on web and join as a second user. Join another group on iOS using a web-created invite. | The same membership and role appear on both clients; a signed-out invite resumes after sign-in. |
| Enter an expense through iOS quick entry and another through the web form. Compare share previews and balances with the API. | Both feeds converge, including SSE updates for the open iOS group. Displayed official amounts match the API exactly. |
| Edit on both clients, including a stale iOS edit; delete and undo; submit a save twice. | A stale edit shows the conflict state, undo restores the same entry, and one form submission creates one transaction. |
| Record a direct settlement on iOS and check the group on web. | The API and both clients show the expected ending debts and ledger entries. The balance integrity check passes. |
| Interrupt the API and reconnect. From a web session for the same account, revoke its iOS session, then sign in on the Simulator as the other account. From a group owner's web session, remove the user currently viewing that group on iOS. | Cached content stays readable with writes disabled during interruption, then refreshes. Revocation clears the old account's cached content. Removal closes the affected group and clears its snapshots, including after relaunch. |

The run records a dedicated handoff at the 5B SHA with a startup recipe, exact steps, screenshots, observed results, and a place for the owner to record acceptance. The owner can review that revision while the agent continues under the phase-run rules after the automated and manual stage checks. Final owner acceptance includes confirming this journey, either at the checkpoint or during its replay on the final revision. Fix and replay any defect found in owner review before final acceptance.

### 7.3 Final acceptance and external verification

- Replay the early journey on the final revision. Complete the parity inventory with evidence for each locally exercisable row, including its role and capability boundaries. Validate the API/web and iOS gates, Release build and metadata, and contract compatibility. Record missing evidence against its specific row.
- The owner verifies Apple and Google sign-in against the real providers, APNs delivery, universal links on the intended HTTPS domain, camera and QR behavior on a physical iPhone, device accessibility and performance, and TestFlight installation when the prerequisites exist. Verify the remaining real Phase 2–4 integrations in their owner acceptance flows. Real AI provider checks stay deferred until all phases, including iOS, are complete.

## 8. Left to the builder

The list in the architecture design's section 11; transitions; which system components back each web component.

## 9. Changes to standing documents

| Document | Change |
|---|---|
| `docs/04-adr.md` | ADR-029: API v1 is additive-only, with a committed OpenAPI snapshot. ADR-030: native apps sign in through the system browser and a PKCE-bound exchange code. ADR-014 gains the versions chosen here and in the architecture design. ADR-032: the iOS application is one Swift package whose modules enforce the dependency rule; read responses are kept as last-known snapshots on the device |
| `docs/05-api-spec.md` | Section 4.2–4.5 endpoints; the versioning rule |
| `docs/05-database-design.md` | `push_devices`; new columns on `sessions` and `user_identities`; `apple` provider |
| `docs/03-srs.md` | FR-5.x refined with sections 4 and 5.3 |
| `AGENTS.md` | Section 5's "must ask" list gains "any non-additive API change" |

## 10. Owner's prerequisites

Before the run: approve this spec, the three Apple packages, the contract script and the revised implementation plan. The local run needs a Mac with Xcode and an iOS 26 Simulator runtime. External acceptance needs the owner's Apple Developer configuration, signing and provider credentials, plus an HTTPS deployment. The local run produces the release artifacts in source and an owner runbook.
