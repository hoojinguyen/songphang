# Phase 5 — Run Progress

- Branch: `phase-5`
- Approved design: `d40c649`
- Approved plan and branch base: `eac8aa7`
- Implementation: Antigravity
- Advisor and reviewer: Codex
- Status: Complete (Tasks 0 through 5E.2 plus all 10 advisor review fixes verified locally at code SHA `802d30f`; ready for Codex re-review).

## Tasks

- [x] 0 — Re-baseline and parity inventory
- [x] 5A.1 — OpenAPI snapshot and minimum version
- [x] 5A.2 — Native password sessions and revocation
- [x] 5A.3 — API gate
- [x] 5B.1 — Generated client and live composition
- [x] 5B.2 — Account lifecycle and snapshots
- [x] 5B.3 — Groups, members and local invite routing
- [x] 5B.4 — Ledger and realtime
- [x] 5B.5 — Early iOS/web Simulator acceptance and owner handoff
- [x] 5C.1 — Native Google exchange
- [x] 5C.2 — Apple sign-in and revocation
- [x] 5C.3 — Push device registration and preferences
- [x] 5C.4 — Push delivery worker
- [x] 5C.5 — Native push registration and routing
- [x] 5C.6 — Associated domains and gate
- [x] 5D.1 — Payments and settlement requests
- [x] 5D.2 — Search, categories, statistics and CSV
- [x] 5D.3 — Funds and budgets
- [x] 5D.4 — Receipts, item splits and assisted entry
- [x] 5D.5 — Notification center and reminders
- [x] 5D.6 — Detail, discussion, disputes and approval
- [x] 5D.7 — Telegram and parity gate
- [x] 5E.1 — Release metadata and assets
- [x] 5E.2 — Final parity evidence and owner handoff

## Task Reports

### Task 0 — Re-baseline and parity inventory

**Approach**
- Files to create/modify: `docs/superpowers/runs/phase-5/{progress,decisions,manual-checks,parity-matrix}.md`.
- Approach: Pin `main` (`eac8aa7`), verify local Xcode/Simulator/Node/Postgres prerequisites, diff 5U (`bb1e0432`) against baseline across contract/API/web, map existing Swift domain types/protocols to the 99 live routes, execute the baseline gate on a disposable database (`songphang_phase5_t0_baseline`) with clean-environment API and worker, and publish the complete parity inventory.
- Why this is the simplest approach: Uses direct read-only inspection and one isolated disposable replay to establish factual provenance before modifying any code.
- Rejected alternative: Assuming the Phase 4 handoff inventory still matches without re-running on `phase-5`.
- Questions: None (recorded D1 and D2 in `decisions.md`).

**Observed results (baseline SHA `4c4570ccfcf36d202dd8e4ce1b548263dbcfba91`, `main` `eac8aa70c730c6e3a148321377b2f1f8dd078456`):**
- Branch verification: `phase-5`, ancestor `eac8aa7` confirmed (`ANCESTOR_OK`).
- Toolchain & prerequisites:
  - `xcodebuild -version`: `Xcode 27.2`, `Build version 27B52`
  - `xcrun swift --version`: `Apple Swift version 6.4.2` (`arm64-apple-macosx26.0`)
  - `xcrun simctl list runtimes`: `iOS 26.5 (26.5 - 23F77) - com.apple.CoreSimulator.SimRuntime.iOS-26-5`
  - Available booted Simulator: `iPhone 17 Pro (607AC652-2E92-4BE7-BA18-1B888D79684B) (Booted)`
  - Node `v26.7.0`, pnpm `11.21.0`, Docker Postgres `songphang-db-1` (`postgres:17`, port `54329`, healthy); ports `3000` and `4000` free.
- Automated repo gates:
  - `pnpm check`: PASS (485 files checked by Biome with 3 pre-existing `noImgElement` warnings; all 8 workspaces typechecked cleanly).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build succeeded, 14 static + dynamic routes).
- Automated iOS gates:
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`: `** BUILD SUCCEEDED **`
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0)
  - `./apps/ios/Scripts/check-strings.sh`: `273` missing Phase 2–4 keys, `0` differing Phase 1 keys (expected pre-5D drift from `bb1e0432` to `eac8aa7`).
  - Release guard check (`xcodebuild ... -configuration Release ... build`): failed as expected at `apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift:36:12: error: Live repositories arrive in the integration stage`.
- Be Vietnam Pro font availability: `apps/web/public/fonts/be-vietnam-pro/` contains only `.woff2` files; no compatible `.ttf`/`.otf` files exist in the repo. Retaining 5U system font fallback and flagging asset need before final review (D2).
- Live route set & baseline replay (disposable DB `songphang_phase5_t0_baseline`, isolated `/tmp/songphang-phase5-t0-uploads`, clean env API `:4000` + worker):
  - Live route extraction: `TOTAL_HONO_ROUTES=99`, `TOTAL_OPENAPI_OPS=96` (includes 2 dev routes; 3 plain Hono routes not in OpenAPI: `POST /api/v1/notifications/unsubscribe`, `POST /api/v1/bots/telegram/webhook`, `GET /api/v1/openapi.json`).
  - Capability-off check (`:4001`, optional providers unset): `GET /api/v1/features` returned `{"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false}`; `POST /api/v1/bots/telegram/webhook` returned `404`.
  - Two verified password accounts (`minh.p5@local.songphang.test`, `lan.p5@local.songphang.test`): registered, verified from console mail log token, logged in via password (`emailVerified: true`, `hasPassword: true`).
  - Representative Phase 1–4 + 99-route replay: `TASK0_BASELINE_PASS: routes=99/99 assertions=121` (including fake receipt OCR completed to `done` by live worker, UTF-8 BOM CSV, SSE connect/404 outsider, comments/disputes, approval/reject, reminders, Telegram pairing & webhook).
  - Balance integrity check (`DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts`): `All groups balanced` (`sum 0; mismatches 0`).
  - Disposable database dropped and `/tmp/songphang-phase5-t0-uploads` removed cleanly.
- Security review: documentation-only task; no secrets, tokens, or personal data committed.

### Task 5A.1 — OpenAPI snapshot and minimum version

**Approach**
- Files to create/modify: `packages/contract/src/features.ts`, `apps/api/src/config.ts`, `apps/api/src/routes/features.ts`, `apps/api/src/routes/attachments.ts`, `apps/api/src/app.ts`, `apps/api/src/openapi/{build,diff,cli}.ts`, `apps/api/package.json`, `package.json`, `biome.json`, `packages/contract/openapi.json`, `.env.example`, `README.md`.
- Approach: Add `AppVersion` (`major.minor.patch`) and `minAppVersion: { ios, android }` to `FeaturesResponse` and API config (default `0.0.0`). Document multipart upload (`multipart/form-data` plain OpenAPI schema so `readSingleUploadedFile` keeps exact raw-body parsing) and all 3 binary image types (`image/jpeg`, `image/png`, `image/webp`) on attachment routes. Share `OPENAPI_DOCUMENT_CONFIG` between `app.doc31` and a deterministic offline CLI (`contract:write` / `contract:check`) that enables documented provider routes, excludes dev-only routes, sorts object keys without reordering semantic arrays, and classifies additive vs breaking diffs. Join `pnpm contract:check` into `pnpm check`.
- Why this is the simplest approach: Reuses the live `OpenAPIHono` registry with zero new dependencies and a single authoritative schema source.
- Rejected alternative: Hand-maintaining an OpenAPI YAML or adding a third-party OpenAPI diff package.
- Questions: None (recorded D3 in `decisions.md`).

**Observed results:**
- Repeat generation determinism (`pnpm contract:write` × 2):
  - `SHA1=835f96bc99cee24a864432c678fc10056cfc11be6d866adde4bdb40ef5bfab1e`
  - `SHA2=835f96bc99cee24a864432c678fc10056cfc11be6d866adde4bdb40ef5bfab1e` (`BYTE_IDENTICAL=YES`)
  - Dev routes in snapshot: `0`; Google routes: `2`; receipt-scan routes: `2`; chat-link routes: `3`.
- Scratch contract diff & drift exercises:
  - Hand-edited drift (`check --snapshot`): `[ADDITIVE] info.description: Documentation updated` → CLI exit code `1`.
  - New optional field + enum member (`diff`): `[ADDITIVE] components.schemas.GroupDto.properties.role.enum: Enum value "auditor" added`, `[ADDITIVE] components.schemas.UserDto.properties.nickname: Optional property "nickname" added` (`0 breaking, 2 additive`) → CLI exit code `1`.
  - Removed field (`diff`): `[BREAKING] components.schemas.UserDto.properties.avatarUrl: Property "avatarUrl" removed` (`1 breaking, 0 additive`) → CLI exit code `2`.
  - Optional field becoming required (`diff`): `[BREAKING] components.schemas.UpdateGroupRequest.required.name: Field "name" became required` (`1 breaking, 0 additive`) → CLI exit code `2`.
- Config & `/api/v1/features` exercises:
  - Defaults with providers off: `200 {"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false,"minAppVersion":{"ios":"0.0.0","android":"0.0.0"}}`
  - Custom `MIN_APP_VERSION_IOS=1.2.3`, `MIN_APP_VERSION_ANDROID=2.0.1`: `200 ... "minAppVersion":{"ios":"1.2.3","android":"2.0.1"}`
  - Invalid values (`1.0`, `v1.0.0`, `01.0.0`, `1.0.0-beta`): all refused at startup with `Invalid environment variables: MIN_APP_VERSION_IOS`.
- `pnpm check`: PASS (`biome check . && pnpm -r typecheck && pnpm contract:check` → `OpenAPI contract snapshot is up to date.`).
- Security review: checked relevant items 1, 2, 6, 8; no secrets in code/config/`.env.example`, Zod validates `MIN_APP_VERSION_*` at startup, no internal details leaked, no new dependencies added.

### Task 5A.2 — Native password sessions and revocation

**Approach**
- Files to create/modify: `packages/db/src/{schema,sessions,index}.ts`, `packages/db/drizzle/0023_useful_morlun.sql` (+ `meta/`), `packages/contract/src/auth.ts`, `apps/api/src/{app.ts,auth/sessions.ts,auth/middleware.ts,services/accounts.ts}`, `apps/api/src/routes/{account-auth,auth,me,mobile-auth}.ts`, `apps/web/src/messages/vi.ts`, `apps/web/src/lib/auth.ts`, `apps/web/src/components/account/SessionsCard.tsx`, `apps/web/src/app/account/page.tsx`, regenerated `packages/contract/openapi.json`.
- Approach: Add `client` (`'web' | 'ios' | 'android'`, default `'web'`) and nullable `device_name` (1–60 chars) with PostgreSQL `CHECK` constraints to `sessions` via `drizzle-kit generate`. Reuse `loginAccount` and the shared `"login-ip"` / `"login-email"` limiters in `POST /api/v1/auth/token` (returning `200 { token, user }`, `Cache-Control: no-store`, no cookie). Enforce query-string credential rejection in `requireUser` and Bearer-only vs Cookie/mixed same-origin rules in `requireSameOrigin`. Add `GET /api/v1/me/sessions` and `DELETE /api/v1/me/sessions/{id}` (revoking SSE via `deps.events.revokeSession` and expiring cookie on current web session revoke), and render "Thiết bị đang đăng nhập" on web `/account`.
- Why this is the simplest approach: Single session table, single credential verification path, single shared rate-limiter pair, and single SSE revocation channel.
- Rejected alternative: Separate native session table or duplicated password verification logic.
- Questions: None.

**Observed results:**
- Pre-existing migration backfill (`0000..0022` seeded with pre-existing web session row, then migrated with `0023_useful_morlun.sql`):
  - `PRE_EXISTING_SESSION_BACKFILL_PASS: {"id":"01900000-0000-7000-8000-000000000001","client":"web","deviceName":null,"createdAt":"...","lastSeenAt":"...","current":true}` (no `token` or `tokenHash`; pre-existing cookie continues returning 200 on `GET /api/v1/me`).
- Native token login & error parity:
  - `NATIVE_TOKEN_LOGIN_PASS: 200 no-cookie Cache-Control=no-store`
  - `IDENTICAL_401_BODIES_PASS: {"code":"INVALID_CREDENTIALS","message":"Email or password is incorrect"}` across wrong password & unknown email on both `POST /auth/login` and `POST /auth/token`.
  - `SHARED_EMAIL_BUDGET_PASS`: alternating `/auth/login` and `/auth/token` for the same email returned `401` on attempts 1–5 and `429 RATE_LIMITED` on attempt 6.
- Credential transport & Origin matrix:
  - `QUERY_STRING_CREDENTIAL_REJECT_PASS`: `GET /api/v1/me?token=...` returned `400 VALIDATION_FAILED`.
  - `ORIGIN_TRANSPORT_MATRIX_PASS`: Bearer-only `[absent=201, local=201, foreign=201, invalid=401]`, Cookie `[local=201, absent=201, foreign=400 VALIDATION_FAILED]`, Mixed Cookie+Bearer `[local=201, absent=201, foreign=400 VALIDATION_FAILED]`.
- Session revocation & SSE closure:
  - `REVOCATION_SSE_LOGOUT_PASS`: cross-account revoke `404`, active iOS SSE stream closed immediately (`CLOSED`) when revoked from web session, revoked iOS token returned `401`, web session remained `200`, revoking current web session returned `204` with `sp_session=; Max-Age=0` and invalidated cookie (`401`), Bearer `POST /auth/logout` returned `204` with no cookie and invalidated token (`401`).
- OpenAPI diff vs 5A.1 (`f0b735a`): `0 breaking, 9 additive` (3 new paths: `/api/v1/auth/token`, `/api/v1/me/sessions`, `/api/v1/me/sessions/{id}`; 6 new schemas).
- `pnpm check` & `pnpm build`: PASS.
- Security review: checked relevant items 1–8; no secrets/hashes in responses or logs, Zod validates all inputs and UUID params, query-string session credentials rejected, DB `CHECK` constraints in migration `0023_useful_morlun.sql`, mixed Cookie/Bearer stays on same-origin policy, `Cache-Control: no-store` on `/auth/token`, no new dependencies.

### Task 5A.3 — Stage 5A API gate

**Stage & SHA:** Stage 5A, code revision `d090617` (`feat(auth): add native password sessions and session management`).

**Fixture & commands:**
- Disposable DB `songphang_phase5_5a_gate` migrated via `pnpm --filter @songphang/db exec tsx src/migrate.ts` (including `0023_useful_morlun.sql`) and seeded via `src/seed.ts`.
- Isolated API (`:4000`, `AI_PROVIDER=fake`, `TELEGRAM_PROVIDER=console`, `GOOGLE_CLIENT_ID/SECRET` fake placeholders, clean env) + Worker (`AI_PROVIDER=fake`, clean env) + capability-off API (`:4001`, optional providers unset).
- Automated checks: `pnpm check`, `pnpm build`, `xcodebuild ... SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`, `xcrun swift-format lint --strict --recursive apps/ios`, and pre-integration Release `#error` guard check.

**Observed results:**
- `pnpm check`: PASS (`biome check .`, 8 workspaces `tsc --noEmit`, `pnpm contract:check` → `OpenAPI contract snapshot is up to date.`).
- `pnpm build`: PASS (`apps/web` Next.js production build succeeded).
- Capability-off check (`:4001`): `GATE_CAPABILITY_OFF_PASS: {"receiptReading":false,"sentenceAi":false,"telegram":false,"push":false,"appleSignIn":false,"errorAlerts":false,"minAppVersion":{"ios":"0.0.0","android":"0.0.0"}}`; disabled Telegram webhook returned `404`.
- Route/caller permission matrix & Phase 1–4 + 5A acceptance replay:
  - `STAGE_5A_GATE_PASS: routes=102/102 cases=226 bearer_routes=85 cookie_routes=22 balances=All groups balanced`
  - Covered all 102 live Hono routes (99 baseline + `POST /api/v1/auth/token`, `GET /api/v1/me/sessions`, `DELETE /api/v1/me/sessions/:id`) across signed-out (`401`), unverified, outsider (`404` on both Cookie & Bearer), viewer (`403` on writes, `200` on reads/comments/disputes/own payment methods), editor, owner, cross-group (`404`), idempotency replay, wrong-session Telegram pairing denial (`404`), fake worker receipt OCR (`done`), and UTF-8 BOM CSV.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced`.
- iOS checks (pre-integration):
  - Debug build (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`): `** BUILD SUCCEEDED **`.
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0).
  - Release build guard (still expected until 5B.4 removes it): failed as expected at `AppShell/AppDependencies.swift:36:12: error: Live repositories arrive in the integration stage`.
- **5B Readiness:** 5B now has a reachable local v1 API (`http://localhost:4000/api/v1`) with native email/password sign-in (`POST /auth/token`), session listing/revocation (`GET/DELETE /me/sessions`), deterministic committed OpenAPI 3.1 snapshot (`packages/contract/openapi.json`), and documented baseline gaps (Be Vietnam Pro `.ttf`/`.otf` assets pending; Phase 2–4 strings scheduled across 5D).
- **Issues / verification gaps:** None on local Stage 5A gate. External providers (real SMTP, Google OAuth, Apple, APNs, Telegram Bot API, real AI) remain deferred/external.

### Task 5B.1 — Generated client, transport and live composition

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Package.swift`, `apps/ios/SongPhang.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `apps/ios/SongPhangKit/Sources/GeneratedAPI/{openapi-generator-config.yaml,GeneratedAPI.swift,openapi.json}`, `apps/ios/SongPhangKit/Sources/Repositories/{Session/TokenStore.swift,Transport/{APIConfiguration,BearerURLSession,AuthMiddleware,ErrorMapper,LiveAPIEnvironment,UnconnectedRepositories}.swift}`, `apps/ios/Config/{Debug.xcconfig,Release.xcconfig,Info-Debug.plist}`, `apps/ios/App/Info.plist`, `apps/ios/SongPhang.xcodeproj/project.pbxproj`, `apps/ios/SongPhangKit/Sources/AppShell/{AppDependencies.swift,RootView.swift,Debug/DebugPanel.swift}`, `docs/superpowers/runs/phase-5/{decisions,progress}.md`, `docs/superpowers/runs/phase-5/screens/5b1-{live-signin,scripted}.png`.
- Approach: Pin Apple's `swift-openapi-generator` (`1.14.4`), `swift-openapi-runtime` (`1.13.4`), and `swift-openapi-urlsession` (`1.4.0`). Point `GeneratedAPI/openapi.json` via relative symlink to `packages/contract/openapi.json` with `accessModifier: package` and `generate: [types, client]`. Build `Repositories` with an internal Keychain `TokenStore` (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), ephemeral cookie-free `URLSession`, `@concurrent` `AuthMiddleware` (`X-App-Version` + `Authorization: Bearer`), single `ErrorMapper`, and `LiveAPIEnvironment.fetchServerFeatures()` composing `/api/v1` exactly once. Isolate Debug localhost ATS in `Config/Info-Debug.plist` while keeping Release `App/Info.plist` free of HTTP exceptions. Compose `AppDependencies.live(configuration:)` by default in Debug while retaining `--scripted` / 5U launch flags and the Release `#error` guard until 5B.4.
- Why this is the simplest approach: Single authoritative OpenAPI snapshot via symlink (zero duplicate contract files), strict compiler-enforced module boundaries, and zero third-party networking libraries.
- Rejected alternative: Copying `openapi.json` via a shell build phase or using `URLSession.shared` (which retains cookies and disk cache).
- Questions: None (recorded Decisions D4, D5, D6 in `decisions.md`).

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0).
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`: `** BUILD SUCCEEDED **`.
  - Release `#error` guard check (`-configuration Release ... CODE_SIGNING_ALLOWED=NO build`): compiled `GeneratedAPI` + `Repositories` cleanly and failed as expected at `AppShell/AppDependencies.swift:56:12: error: Live repositories arrive in the integration stage`.
- Live Simulator run (booted `iPhone 17 Pro`, iOS 26.5, isolated local API on `127.0.0.1:4000`, providers off):
  - Default launch hit `GET /api/v1/features` and `GET /api/v1/auth/providers` (versioned `/api/v1` path composed once, `X-App-Version: 1.0.0`), rendered `SignInView` with Apple & Google buttons hidden and zero errors (`docs/superpowers/runs/phase-5/screens/5b1-live-signin.png`).
  - `--scripted` launch rendered `GroupListView` with `Đà Lạt 3N2Đ` (`+500.001 đồng bạn được nhận`) cleanly (`docs/superpowers/runs/phase-5/screens/5b1-scripted.png`).
- Security review: checked relevant items 1, 2, 4, 8; Keychain `TokenStore` is `internal` to `Repositories`, no raw token is returned or logged, ephemeral `URLSession` disables `HTTPCookieStorage` and `URLCache`, Release `App/Info.plist` has zero `NSAppTransportSecurity` exceptions, and Apple OpenAPI packages are pinned in `Package.resolved`.

### Task 5B.2 — Account lifecycle and session-scoped snapshots (S1 and S13)

**Approach**
- Files created/modified: `Domain/Models/{ServerFeatures,UserSession}.swift`, `Domain/Repositories/AuthRepository.swift`, `Repositories/Transport/{FlexibleDateTranscoder,ResponseBodyBox,AuthMiddleware,APIConfiguration,ErrorMapper,LiveAPIEnvironment,UnconnectedRepositories}.swift`, `Repositories/Session/SessionInvalidationHub.swift`, `Repositories/Snapshots/SnapshotStore.swift`, `Repositories/Auth/{AuthMapping,LiveAuthRepository}.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `PreviewSupport/Fakes/{FakeWorld,FakeRepositories}.swift`, `AccountFeature/Account/{AccountModel,AccountView,SessionsSectionView}.swift`, `AppShell/{UpgradeRequiredView,SessionModel,AppDependencies,RootView,RouteDestination}.swift`.
- Approach: Add `SemanticVersion` numeric 3-component comparison and `UserSession` (with `.unknown(String)` client fallback) to `Domain`. Implement internal `SnapshotStore` actor scoped by `(userId, sessionGeneration)` and per-group `groupGeneration`, writing protected files (`.completeFileProtectionUntilFirstUserAuthentication`, `isExcludedFromBackup = true`) under `Caches/SongPhangSnapshots/<userId>/`, capping at 20 recent groups, deleting corrupt files, and wiping completely on sign-out, 401, current-session revoke, or account deletion. Add `FlexibleISO8601DateTranscoder` (accepting JS fractional-second ISO-8601 dates) and `@TaskLocal` `ResponseBodyCapture` so unknown enum values fall back safely without breaking decoding or making duplicate network requests. Connect `LiveAuthRepository` for login, registration, verification resend, forgot password, change password, active sessions list/revoke, delete account, and sign-out. Surface `SessionsSectionView` ("Thiết bị đang đăng nhập") in `AccountView` matching web, `UpgradeRequiredView` when below `minAppVersion.ios`, foreground refresh on `scenePhase == .active`, and global 401 session invalidation in `RootView`.
- Why this is the simplest approach: Reuses the generated OpenAPI client everywhere while isolating Keychain, protected snapshots, and unknown-enum fallback strictly inside `Repositories`.
- Rejected alternative: Weakening OpenAPI schemas to plain strings (would weaken API validation and contract diffing) or polling `/me` on a timer.
- Questions: None.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0).
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`: `** BUILD SUCCEEDED **`.
  - `bash apps/ios/Scripts/check-strings.sh`: 0 missing `account.*` keys, 0 differing keys.
- Live Simulator UI screenshots (`iPhone 17 Pro`, iOS 26.5, isolated API `:4000`):
  - `1.0.0 / 1.0.0` → allowed (`docs/superpowers/runs/phase-5/screens/5b2-minver-100-100-allowed.png` shows `SignInView`).
  - `1.0.0 / 1.0.1` → blocked (`docs/superpowers/runs/phase-5/screens/5b2-minver-100-101-blocked.png` shows `UpgradeRequiredView` with `"Hãy cập nhật Sòng Phẳng để tiếp tục."` and `"Mở App Store"` disabled without a configured store URL).
  - `1.10.0 / 1.9.0` → allowed (`docs/superpowers/runs/phase-5/screens/5b2-minver-1100-190-allowed.png` shows `SignInView`).
  - Account active sessions UI (`docs/superpowers/runs/phase-5/screens/5b2-account-sessions.png` shows `"Thiết bị đang đăng nhập"`, current iOS badge `"iOS · Thiết bị này"`, Web row, single-line `"Đăng xuất"` buttons).
- Live Simulator repository & snapshot exercise (compiled against `Domain.o`, `GeneratedAPI.o`, `Repositories.o` and executed in a real Simulator sandbox against isolated API `:4000` + disposable unknown-enum fixture `:4099`):
  - `VERSION_AND_ROLE_PASS`: `1.0.0/1.0.0` allowed, `1.0.0/1.0.1` blocked, `1.10.0/1.9.0` allowed, `Role(code: "auditor") == .unknown("auditor")` with `canWrite == false`.
  - `REGISTER_AND_RATE_LIMIT_PASS` & `CONSOLE_VERIFY_ALICE_PASS`: registered `alice.5b2@local.songphang.test`, 5 wrong passwords returned `401 INVALID_CREDENTIALS`, 6th returned `rateLimited`, forgot-password succeeded, console email verification token verified via `/auth/verify-email`.
  - `BOB_SIGNIN_SNAPSHOT_PASS`: signed in `bob.5b2@local.songphang.test` via `POST /auth/token`, listed current iOS session (`client == .ios`, `deviceName == "iPhone 17 Pro Sim"`), confirmed `Caches/SongPhangSnapshots/<bobId>/me.json` exists with `isExcludedFromBackup == true` and `FileProtectionType.completeUntilFirstUserAuthentication`, confirmed cold-relaunch `lastKnownUser()` + `currentUser()`, confirmed offline relaunch retains snapshot & Keychain while returning `.offline`, changed password with `revokeOtherSessions: true`.
  - `WEB_REVOKE_IOS_SESSION_PASS` & `BOB_REVOKED_WIPED_PASS`: revoked Bob's iOS session from a second web cookie session; iOS `currentUser()` threw `.unauthorized`, `sessionInvalidations()` fired, and `SongPhangSnapshots/` was completely wiped from disk.
  - `CAROL_SWITCH_AND_DELETE_PASS`: signed in `carol.5b2@local.songphang.test`, confirmed Bob's snapshot folder absent, deleted Carol's account (`DELETE /me`), confirmed Keychain and `SongPhangSnapshots/` wiped.
  - `UNKNOWN_ENUM_FIXTURE_PASS`: disposable response fixture with `"client": "desktop"` and extra top-level & nested fields decoded cleanly via `LiveAuthRepository.sessions()` with `client == .unknown("desktop")` and all readable fields preserved.
- Security review: checked relevant items 1, 2, 4, 6, 8; tokens stay inside internal `TokenStore` Keychain item (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), snapshots protected until first unlock and excluded from backup, full snapshot directory wiped before signed-out UI on 401/sign-out/delete/current-session-revoke, specific 409 error codes (`OWNER_REQUIRED`, etc.) preserved while `VERSION_CONFLICT` maps to `.conflict`, no secrets logged.

### Task 5B.3 — Groups, members, settings and invites (S2, S3, S10–S12)

**Approach**
- Files created/modified: `Repositories/Groups/{GroupMapping,LiveGroupsRepository}.swift`, `Repositories/Members/{MemberMapping,LiveMembersRepository}.swift`, `Repositories/Invites/{InviteMapping,LiveInvitesRepository}.swift`, `Repositories/Transport/UnconnectedRepositories.swift`, `AppShell/Routing/LinkRouter.swift`, `AppShell/{AppDependencies,RootView,Debug/DebugPanel}.swift`, `GroupsFeature/Members/{MembersModel,MembersView}.swift`, `GroupsFeature/GroupSettings/GroupSettingsView.swift`, `GroupsFeature/Join/JoinView.swift`, `apps/ios/Config/Debug.xcconfig`.
- Approach: Connect `LiveGroupsRepository`, `LiveMembersRepository`, and `LiveInvitesRepository` to `/groups`, `/members`, `/users`, `/me/member`, `/leave`, `/transfer-ownership`, `/invite`, and `/invites/{token}`. Persist only allowed snapshot resources (group list, group detail, members, group users; invite tokens explicitly excluded via `lastKnownInvite == nil`), guarded by `(userId, sessionGeneration)` and per-group `groupGeneration`, with resilient unknown-enum fallbacks. Implement `LinkRouter.route(for: URL) -> Route?` validating scheme (HTTPS forced in Release), host, port, and `/join/{token}` shape; wire it to `.onOpenURL` and a Debug URL input in `DebugPanel`, holding validated pending join routes in memory through sign-in and clearing them on consumption or sign-out. Disable write controls when offline in `MembersView` and `GroupSettingsView`.
- Why this is the simplest approach: Reuses existing 5U screens (`SPQRCodeView`, `ShareLink`, role controls, claim flow) with zero feature-to-feature imports and one centralized URL validator.
- Rejected alternative: Persisting invite links to disk or validating URLs loosely by path suffix only.
- Questions: None.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: no output (exit 0).
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`: `** BUILD SUCCEEDED **`.
- Live iOS ↔ web Simulator exercise (isolated API `:4000`, disposable DB `songphang_phase5_5b3`, 2 verified password accounts Minh & Lan):
  - `LINK_ROUTER_PASS`: local Debug router accepted `http://localhost:3000/join/tok_ABC-123` and rejected foreign host, wrong port, empty token, extra path segment, unknown path, and malformed characters; Release HTTPS mode accepted `https://app.songphang.vn/join/tok_99` and rejected `http://`.
  - `MINH_CREATE_AND_SNAPSHOT_PASS`: Minh created `Da Lat iOS` (`["Lan", "Hung"]` + creator = 3 members) and fetched invite on iOS (`lastKnownInvite == nil`, zero invite files on disk); verified `groups.json` and `members.json` have `isExcludedFromBackup == true` and `FileProtectionType.completeUntilFirstUserAuthentication`; simulated offline interruption (snapshot retained while `groups()` threw `.offline`); corrupted `groups.json` (auto-deleted on `lastKnownGroups() -> nil`, recovered from live API and re-persisted cleanly).
  - `WEB_LAN_JOINED_GROUP_A_PASS` & `MINH_JOIN_ROLES_ROTATE_TRANSFER_PASS`: Lan joined Group A on web claiming `Lan` and created `Phu Quoc Web` on web; signed-out Minh validated web invite URL via `LinkRouter`, signed in, previewed and joined Group B on iOS; exercised role change to `.viewer`, invite disable (`INVITE_INVALID`), re-enable, rotate (old token `INVITE_INVALID`), malformed token refusal, `leaveGroup` clearing Group B snapshot, and `transferOwnership` to Lan.
  - `LAN_SWITCH_AND_SETTINGS_PASS` & `VIEWER_WRITE_REFUSED_PASS`: revoked Minh's iOS session from Minh's web session, observed 401 wiping Minh's snapshot directory, signed in as Lan confirming Minh's directory was absent, updated group settings, demoted Minh to viewer, and confirmed Minh's `role.canWrite == false` and API `403` refusal on member creation.
- Security review: checked relevant items 1, 2, 3, 4, 7; `LinkRouter` enforces exact configured origin + HTTPS in Release + strict token alphabet, invite tokens are never written to disk snapshots, group snapshots are cleared on 404/delete/leave/session-invalidation, and viewer writes are gated both in UI and server-side.

### Task 5B.4 — Ledger and realtime

**Approach**
- Files created/modified:
  - `Repositories/Transactions/LiveTransactionsRepository.swift`
  - `Repositories/Balances/LiveBalancesRepository.swift`
  - `Repositories/QuickEntry/LiveQuickEntryRepository.swift`
  - `Repositories/Realtime/LiveGroupEventsRepository.swift`
  - `Repositories/Activity/LiveActivityRepository.swift`
  - `AppShell/AppDependencies.swift`
  - `LedgerFeature/{ExpenseForm/ExpenseFormModel,QuickEntry/QuickEntryModel,Settle/SettleModel}.swift`
  - `GroupsFeature/Members/MembersModel.swift`
  - `packages/contract/src/transaction.ts` and `packages/contract/openapi.json`
- Approach: Wire live ledger operations to OpenAPI generated endpoints (`/groups/{id}/transactions`, `/balances`, `/transactions/parse`, `/activity`, `/events`). Preserve strict integer money (`Money` wraps `Int64`, zero floating point or device share calculations). Persist first-page transactions and balances into `SnapshotStore` protected under `(userId, sessionGeneration, groupGeneration)`. Implement optimistic updates with rollback on failure, optimistic lock conflict detection (`.conflict` throws version error), and live SSE stream invalidation via `AsyncStream` that dispatches immediate chunked newline frames. Set `category` default to `null` in contract schema so Swift optional nil fields omit cleanly without triggering validation failure.
- Why this is the simplest approach: Reuses domain repository protocols, replaces remaining unconnected stub implementations, and binds existing 5U ledger screens to live data with zero schema drift.
- Rejected alternative: Calculating participant splits on-device in Swift or falling back to floating-point division.
- Questions: None (recorded D7 in `decisions.md`).

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --recursive apps/ios`: clean (exit 0).
  - Xcode build: `** BUILD SUCCEEDED **` for Debug configuration.
- Live Simulator exercise suite on isolated database `songphang_phase5_5b4`:
  - `MINH_REGISTER_PASS` & `SETUP_MINH_PASS`: Minh registered, email verified, group "Chuyến đi Đà Lạt 5B4" created with members Minh, Lan, An.
  - `QUICK_ENTRY_PARSER_PASS`: Valid phrase parsed successfully (`status: .ok`, draft expense populated); gibberish phrases returned `.unparsed`.
  - `SPLITS_AND_BALANCES_PASS`: Created 4 split fixtures (T1 equal split, T2 exact split with remainder, T3 shares split, T4 percent split). Server balances returned net balances matching exact integer arithmetic: Minh = +140,000, Lan = -40,000, An = -100,000 VND.
  - `PAGINATION_PASS`: Page 1 returned 20 items + `nextCursor`; page 2 returned 5 items; item IDs were completely disjoint; verified `SnapshotStore` populated with first 20 items.
  - `CONFLICT_DETECTED_PASS`: Stale transaction update threw `.conflict` on version mismatch.
  - `DELETE_AND_RESTORE_PASS`: Soft delete altered member balances; restore returned transaction to active state and restored net balances to original.
  - `SETTLE_PASS`: Direct Settle transfer (Lan transfers 10,000 VND to Minh) recorded with transaction ID, updating balances correctly.
  - `REALTIME_SSE_PASS`: Swift `LiveGroupEventsRepository` SSE stream connected, received `EVENT_CHANGED=transactions,balances,activity,budget` when external transaction was created.
  - `ALL_5B4_EXERCISES_SUCCEEDED`.
- Security review: items checked 1, 2, 4, 7, 9; no tokens or authorization headers exposed in logs, integer-only money path verified, Drizzle queries parameterized, Bearer session tokens validated on all ledger and SSE routes.

### Task 5B.5 — Early iOS/web Simulator acceptance and owner handoff

**Approach**
- Files created/modified: `docs/superpowers/runs/phase-5/{handoff-5b,progress,parity-matrix}.md`, `docs/superpowers/runs/phase-5/screens/5b/*.png`.
- Executed the complete 7-step iOS ↔ web Simulator acceptance matrix on an isolated fresh database (`songphang_phase5_5b5`) and API instance (`:4000`), testing real interactions between Minh (iOS) and Lan (web).
- Replayed split fixtures, idempotent double-tap, SSE push updates, optimistic lock conflict handling, soft delete & undo, direct settlement, offline reads, and web session revocation.
- Ran a 500-entry load benchmark measuring indexed cursor pagination (119 ms page 1, 100 ms page 2, 82 ms page 3).
- Verified accessibility scaling (Dynamic Type XXXL), VoiceOver elements, and semantic dark mode.
- Captured 15 Simulator screenshots across all screens and published `handoff-5b.md` with owner verification check fields.
- Pinned verified code SHA `2f7eb94`.

**Observed results:**
- Automated & manual Simulator acceptance journey:
  - Exercise 1 (Invites & membership cross-routing): PASS (Minh created Group A `01a1f860-33e9-7944-ac9b-efd252ff1150`, Lan joined on web claiming member `01a1f860-33f2-773b-941f-1939340d4d49`; Lan created Group B `01a1f860-343c-7c82-96cd-56e325e63f59`; Minh used `LinkRouter` on iOS to join Group B).
  - Exercise 2 (Quick entry & double-tap): PASS (parsed `Ăn trưa 120k` with `ok` status; double-tap idempotency key returned identical TX ID `01a1f860-347e-7eb8-b1b8-8d01175b027d`; net balances: Minh `+60.000 đ`, Lan `-60.000 đ`).
  - Exercise 3 (Web expense & realtime SSE): PASS (Lan added `Cà phê 40k` TX `01a1f860-34b6-783a-bb93-71d89d764621`; SSE stream received `EVENT_CHANGED=transactions,balances,activity,budget`; iOS balances updated: Minh `+40.000 đ`, Lan `-40.000 đ`).
  - Exercise 4 (Optimistic conflict check): PASS (Web update advanced TX1 version to 2; iOS stale update with version 1 threw `.conflict`; reloaded newest state: Minh `+50.000 đ`, Lan `-50.000 đ`).
  - Exercise 5 (Soft delete & undo): PASS (Delete changed debt to `70.000 đ`; restore returned original TX ID with `deletedAt == null` and net debt restored to `50.000 đ`).
  - Exercise 6 (Direct settle): PASS (Recorded direct transfer `50.000 đ` TX `01a1f860-3544-76f7-85ee-ad52618c0337`; net debt became `0 đ`; `pnpm db:check-balances` passed with `All groups balanced`).
  - Exercise 7 (Offline & session revocation): PASS (Offline reads served cached feed with writes disabled; web revoked iOS session `01a1f860-336c-7339-911f-ed1f8a14edc4`; iOS received 401 `.unauthorized` clearing snapshot store; Lan signed in with isolated data).
- Database balances invariant: `pnpm db:check-balances` confirmed `All groups balanced` (sum 0, mismatches 0).
- Performance stress: 503 rows in Group A paginated at 119ms / 100ms / 82ms.
- 15 screenshots archived in `screens/5b/`.
- Checkpoint handoff document published at `docs/superpowers/runs/phase-5/handoff-5b.md`.
- Parity matrix rows P1-01 through P1-13 marked verified.

### Task 5C.1 — Native Google exchange

**Approach**
- Files created/modified: `packages/db/src/{schema-accounts,accounts}.ts`, `packages/db/drizzle/0024_fixed_strong_guy.sql`, `packages/contract/src/auth.ts`, `packages/contract/openapi.json`, `apps/api/src/services/{google-sign-in,mobile-auth}.ts`, `apps/api/src/routes/{google,mobile-auth}.ts`, `apps/ios/App/Info.plist`, `apps/ios/Config/Info-Debug.plist`, `Repositories/Auth/{GoogleAuthCoordinator,LiveAuthRepository}.swift`, `AuthFeature/{AuthErrorMessages,SignIn/SignInModel}.swift`.
- Approach: Extend `auth_tokens` with `mobile_exchange` purpose, `code_challenge`, and `client` constraint; split `resolveGoogleUserId` so native `/auth/google?client=ios&code_challenge=...` binds the 43-char S256 challenge and native client into HttpOnly OAuth state cookies, issues a hashed 60s single-use code redirecting to `songphang://auth?code=...` without setting session cookies, and `POST /auth/exchange` atomically consumes the code against `sha256(codeVerifier)` and client context with `Cache-Control: no-store`. On iOS, `GoogleAuthCoordinator` initiates an ephemeral `ASWebAuthenticationSession` against `webBaseURL` and validates the `songphang://auth` callback strictly; tokens remain confined to `Repositories`.
- Why this is the simplest approach: Reuses the existing Google OAuth verification and one-time hash token table with atomic SQL `UPDATE ... RETURNING`, preserving the web cookie/redirect contract untouched and avoiding third-party SDKs.
- Rejected alternative: Minting a session token directly in the browser callback redirect URL.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: clean (exit 0).
  - Xcode Debug build: `** BUILD SUCCEEDED **` with warnings treated as errors.
- Live disposable exercise (`songphang_phase5_5c1`, isolated API `:4000` with test Google client credentials + Simulator `Exercise5C1.app`):
  - `PROVIDERS={"google":true,"devLogin":false}` verified.
  - `API_AND_SERVICE_5C1_PASS`: rejected missing/short `code_challenge` (`400`), preserved web `sp_google_redirect` while clearing native cookies on web authorize, isolated native error redirects to `songphang://auth?error=google` with no `sp_session` cookie, refused wrong verifier (`400 TOKEN_INVALID`), wrong client `android` (`400 TOKEN_INVALID`), and 61s-expired code (`400 TOKEN_INVALID`); 5 concurrent valid `/auth/exchange` calls produced exactly 1 `200` (`Cache-Control: no-store`) and 4 `400` responses (`CONCURRENT_EXCHANGE_SESSION_COUNT=1`), and subsequent replay returned `400 TOKEN_INVALID`.
  - `VERIFY_ROUTING_PASS`: `GoogleAuthCallback.parse` accepted valid `code`, `google`, and `google_unverified` URLs and rejected foreign schemes, wrong hosts, extra path segments, malformed codes, extra query params, and unknown errors; `LinkRouter` rejected `songphang://auth` and `/api/v1/auth/google/callback`.
  - `SIMULATOR_EXCHANGE_PASS`: Simulator `LiveAuthRepository.exchangeGoogleCode` exchanged a locally issued code for Minh (`minh.5c1@local.songphang.test`), persisted the Bearer token in Keychain, resolved `GET /me`, populated user snapshot, and cleaned up on `signOut()`.
- Security review: checked items 1, 2, 4, 7, 9; no exchange codes, verifiers, or session tokens are logged (`api-5c1.log` clean), query/body inputs validated by Zod, PKCE verifier retained only for the active authorization flow, atomic single-use DB update prevents concurrent session multiplication.

### Task 5C.2 — Apple sign-in and account deletion revocation

**Approach**
- Files created/modified: `packages/db/src/{schema-accounts,apple-accounts,index}.ts`, `packages/db/drizzle/0025_productive_tigra.sql`, `packages/contract/src/{auth,error}.ts`, `packages/contract/openapi.json`, `apps/api/src/{config,app,openapi/build}.ts`, `apps/api/src/auth/apple/{secret-box,key-set,verify,token-adapter}.ts`, `apps/api/src/services/{apple-sign-in,password-recovery}.ts`, `apps/api/src/routes/{features,me,mobile-auth}.ts`, `.env.example`, `README.md`, `apps/ios/App/SongPhang.entitlements`, `apps/ios/SongPhang.xcodeproj/project.pbxproj`, `Repositories/Auth/{AppleAuthCoordinator,LiveAuthRepository}.swift`.
- Approach: Add `provider_secret` and `'apple'` provider constraints on `user_identities`, implement AES-256-GCM secret sealing (`v1:` + base64(12-byte IV + ciphertext + 16-byte tag)), 24-hour cached Apple JWKS loader with warm-cache 60s unknown-`kid` refresh cooldown and `APPLE_PROVIDER=fake` local JWKS support, strict RS256/iss/aud/iat/exp/SHA-256 nonce JWT verification, ES256 client-secret token exchange/revocation adapter, pre-delete account revocation in `DELETE /me`, and native `AuthenticationServices` UI/coordinator flow with `com.apple.developer.applesignin` entitlements (`Apple` above `Google` in `SignInView`).
- Why this is the simplest approach: Uses Node `node:crypto` and native Apple `AuthenticationServices`/`CryptoKit` without adding any third-party dependency, while enforcing transactional non-orphan guarantees before storing identities.
- Rejected alternative: Introducing a third-party JOSE/JWT library or storing unencrypted Apple refresh tokens.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: clean (exit 0).
  - Xcode Debug build (`iPhone 17 Pro`) & Release build (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
  - Embedded entitlements inspected via `plutil -p .../Debug-iphonesimulator/SongPhang.build/SongPhang.app-Simulated.xcent`: confirmed `com.apple.developer.applesignin => ["Default"]`.
- Live disposable exercise (`songphang_phase5_5c2`, isolated API `:4000` with `APPLE_PROVIDER=fake` + `Exercise5C2.app`):
  - `UNIT_AND_SERVICE_5C2_PASS`: verified `encryptSecret`/`decryptSecret` (`v1:` round-trip, bit-flip tamper refusal, wrong-key refusal), disposable P-256 ES256 `createAppleClientSecret` signature + claims, disabled provider returning `appleSignIn: false` & `404` on `/auth/apple`, production config refusal of `APPLE_PROVIDER=fake`, 60s unknown-`kid` cooldown + key rotation (`k1` -> `k2` -> `k3`), relay-email first sign-in (`200`, `no-store`) and repeat login omitting `name`/`email` preserving `user.id`, verified password account linking (`200`), unverified password account refusal (`403 EMAIL_NOT_VERIFIED`), 8 invalid JWT rejections (`401`: bad `iss`, bad `aud`, bad `nonce`, expired `exp`, future `iat`, mismatched signature, `HS256`, unknown `kid`), production exchange failure returning `503` with zero orphan rows in `user_identities`, and production round-trip encrypting `"rt-prod-secret-value"` (`v1:`) and decrypting it on `DELETE /me` revocation.
  - `SIMULATOR_APPLE_SIGNIN_PASS`: Simulator `LiveAuthRepository.signInWithAppleCredential` signed in against `APPLE_PROVIDER=fake` (`sim.apple.5c2@privaterelay.appleid.com`), persisted Keychain token, resolved `GET /me`, kept snapshot, and cleaned up on `signOut()`.
  - `LIVE_DELETE_AND_REVOKE_5C2_PASS` & `REVOCATION_LOG_VERIFIED`: `DELETE /me` blocked while owning a group (`422 OWNER_REQUIRED`), succeeded (`204`) after group deletion, invalidated session (`401`), and emitted sanitized `{"event":"apple.revoke.simulated","userId":"..."}` with zero secrets in `api-5c2.log`.
- Security review: checked items 1, 2, 4, 7, 9; no identity tokens, nonces, authorization codes, refresh tokens, `DATA_ENCRYPTION_KEY`, private keys, or session tokens appear in logs/errors; production startup rejects fake JWKS/provider; JWT `alg` pinned to `RS256` and constant-time nonce hash comparison enforced.

### Task 5C.3 — Push devices and preferences

**Approach**
- Files created/modified: `packages/db/src/{schema,users,schema-push,push-devices,sessions,index}.ts`, `packages/db/drizzle.config.ts`, `packages/db/drizzle/0026_mighty_enchantress.sql`, `packages/contract/src/{push,auth,index}.ts`, `packages/contract/openapi.json`, `apps/api/src/{config,app,openapi/build}.ts`, `apps/api/src/auth/{sessions,middleware}.ts`, `apps/api/src/services/devices.ts`, `apps/api/src/routes/{me,features}.ts`, `apps/worker/src/config.ts`, `.env.example`, `README.md`, `docs/superpowers/runs/phase-5/decisions.md`.
- Approach: Add `users.hide_push_content` (`boolean`, default `false`) and `push_devices` (`user_id` & `session_id` cascade FKs, unique `token`, platform/environment/length checks, user & session indexes), expose `sessionId`/`sessionClient` on `AppEnv`, validate identical `PUSH_PROVIDER` (`apns | console`) rules across API and worker (production refuses `console`, optional `APNS_KEY_ID`/`APNS_PRIVATE_KEY` overrides falling back to `APPLE_KEY_ID`/`APPLE_PRIVATE_KEY` per D8), enforce native Bearer-only registration (`POST /me/devices`, transactional 10-device cap returning `422 LIMIT_REACHED`, `no-store`, `{ id }` only), caller-owned delete (`DELETE /me/devices/{id}`), and `PUT /me/push-settings` reflected additively on `UserDto.hidePushContent`.
- Why this is the simplest approach: Relies on SQL `ON CONFLICT (token) DO UPDATE` inside a row-locked user transaction (`lockAccount`) plus cascading FKs on `users` and `sessions`, avoiding background cleanup races or extra token state.
- Rejected alternative: Separate push-token table unlinked from `sessions`, which would require manual pruning on logout/revocation.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - Xcode Debug build (`iPhone 17 Pro`, regenerated OpenAPI `UserDto.hidePushContent`): `** BUILD SUCCEEDED **`.
- Live disposable exercise (`songphang_phase5_5c3`, isolated API `:4000` with `PUSH_PROVIDER=console`):
  - `CONFIG_AND_DISABLED_5C3_PASS`: verified disabled `PUSH_PROVIDER` returns `features.push === false` and `404` on `/me/devices`, `/me/devices/{id}`, `/me/push-settings`; verified `APP_ENV=production` refuses `PUSH_PROVIDER=console` in both API (`loadConfig`) and worker (`loadWorkerConfig`); verified `apns` missing config rejection and `APPLE_KEY_ID`/`APNS_KEY_ID` fallback/override.
  - `ALL_5C3_PASS`: verified Cookie, mixed Cookie+Bearer, and web-client Bearer `POST /me/devices` all rejected with `403 FORBIDDEN`; verified double registration returns identical `{ id }` with `Cache-Control: no-store` and no echoed token; verified rebind across sessions and across users; verified foreign delete denied (`404`); verified 10-device cap (`11th -> 422 LIMIT_REACHED`, existing-token re-upsert still succeeds); verified `POST /auth/logout`, remote `DELETE /me/sessions/{id}`, and `DELETE /me` all cascade-delete `push_devices`; verified `PUT /me/push-settings` (`true`/`false`) reflected in `GET /me`.
  - `ZERO_TOKEN_EXPOSURE_IN_LOGS`: confirmed `api-5c3.log` contains zero device tokens.
- Security review: checked items 1, 2, 4, 7, 9; raw device tokens never echoed or logged, native Bearer + non-web client enforced (`403`), foreign device deletion returns `404`, transactional lock prevents cap race.

### Task 5C.4 — Push sender and delivery guard

**Approach**
- Files created/modified: `packages/contract/src/jobs.ts`, `packages/db/src/notifications.ts`, `apps/api/src/services/{notify,approval,disputes,settlement-requests,reminders,transaction-changes,transactions,comments}.ts`, `apps/api/src/routes/{settlement-requests,transactions,comments}.ts`, `apps/api/src/bot/callbacks.ts`, `apps/worker/src/{queue,main}.ts`, `apps/worker/src/jobs/{auto-reminders,send-push}.ts`, `apps/worker/src/push/{types,console,apns-token,apns,index}.ts`, `README.md`.
- Approach: Add `JOB_NAMES.sendPush = "send-push"` deduplicated by `singletonKey: row.id`; enqueue it transactionally on notification writes when `PUSH_PROVIDER` is configured for immediate notification kinds plus `expense_added` and `comment_added` (excluding `budget_state` and `expense_changed`). Before dispatch, `runSendPush` verifies unread state, active membership, unmuted status, and active non-expired device sessions; renders `groupName` title and either `formatNotificationText` inbox wording or `"Có cập nhật trong nhóm {groupName}"` when `hide_push_content` is enabled; sanitizes deep-link targets against an allowlist; uses cached 50-minute ES256 provider JWTs over `node:http2` (APNs adapter) or sanitized structured logging (`console` adapter); and prunes `"gone"` tokens only if `(id, user_id, session_id, token, last_seen_at)` matches atomically (`deletePushDeviceIfUnchanged`).
- Why this is the simplest approach: Reuses `packages/core/src/notification-text.ts`, Node built-ins (`node:crypto`, `node:http2`), and PostgreSQL `pg-boss` `singletonKey` deduplication with optimistic CAS deletion against concurrent token rebinding.
- Rejected alternative: Adding external push/HTTP2 client libraries or storing duplicated notification text in job payloads.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
- Live disposable exercise (`songphang_phase5_5c4`, offline checks + live `apps/api` and `apps/worker` with `PUSH_PROVIDER=console`):
  - `ALL_5C4_UNIT_AND_GUARDS_PASS`: verified disposable P-256 ES256 JWT signing & 50-minute caching/rotation; verified worker production config refuses `PUSH_PROVIDER=console` and disabled config leaves sender `null`; verified allowlist sanitizer strips foreign/mismatched targets; verified 0 `send-push` jobs queued when push is disabled or for `budget_state`/`expense_changed`, and 1 deduplicated `send-push` job queued for `expense_added`, `comment_added`, and `runAutoReminders`; verified 2 active devices received 2 sanitized JSON console logs matching exact Vietnamese wording and `"Có cập nhật trong nhóm Đà Lạt 5C4"` when `hide_push_content` is enabled; verified 0 deliveries on muted group, read notification, and removed member; verified remaining active device still receives push after sign-out of device 1; verified concurrently rebound device survives a stale `"gone"` response while unchanged `"gone"` deletes cleanly.
  - `LIVE_PG_BOSS_PUSH_PASS`: live API expense creation (`Phở bò sáng`) triggered `pg-boss` dispatch in `apps/worker`, emitting `{"event":"push.sent.console",...,"title":"Sài Gòn Live 5C4","body":"Minh Live thêm Phở bò sáng · phần bạn 50.000 đ"}` with zero raw device tokens in `worker-5c4.log`.
- Security review: checked items 1, 2, 4, 7, 9; zero device tokens logged, ES256 key material loaded only from server config, target paths allowlisted per group UUID, worker checks live membership/session state right before send.

### Task 5C.5 — Native push registration and navigation

**Approach**
- Files created/modified: `apps/ios/App/{SongPhangApp.swift,SongPhang.entitlements}`, `apps/ios/Config/{Debug,Release}.xcconfig`, `Domain/{Models/User,Repositories/DevicesRepository}.swift`, `Repositories/{Auth/AuthMapping,Devices/LiveDevicesRepository}.swift`, `PreviewSupport/Fakes/{FakeRepositories,FakeWorld}.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `AccountFeature/Account/{AccountModel,AccountView}.swift`, `AppShell/{AppDependencies,RouteDestination,RootView,Debug/DebugPanel}.swift`, `AppShell/Push/{PushEventBridge,PushCoordinator,PushPermissionSheet}.swift`, `AppShell/Routing/LinkRouter.swift`.
- Approach: Add `User.hidePushContent`, `DevicesRepository`/`LiveDevicesRepository`, `APS_ENVIRONMENT` entitlement (`development` in Debug, `production` in Release), `SongPhangAppDelegate` + cold-launch buffering `PushEventBridge`, and `PushCoordinator` storing only the per-user `"Để sau"` deferral flag in `UserDefaults` (no device tokens persisted locally). Trigger `PushPermissionSheet` after the first saved expense (`.quickEntry` / `.newTransactionForm`) when `features.push == true`, status is `.notDetermined`, and the user has not deferred; never prompt at launch. Expose later opt-in and `"Ẩn nội dung trên màn hình khoá"` (`PUT /me/push-settings`) in `AccountView`, hiding the entire section when `features.push == false`. Validate push `groupId` and `target` in `LinkRouter.pushDestination(groupId:target:)` (forwarding recognized 5D routes like `/stats` and `/tx/<id>/view` to `.groupFeed` during 5C, rejecting traversal/queries/mismatches) and confirm live API access via `dependencies.groups.group(id:)` before navigating on cold or warm push taps.
- Why this is the simplest approach: Reuses existing `GroupListModel` / `AccountModel` / `LinkRouter` patterns with zero new dependencies and a single MainActor push bridge across `UIApplicationDelegate` and `RootView`.
- Rejected alternative: Persisting APNs device tokens in UserDefaults or routing push notifications before checking live API membership.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .`, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: clean (exit 0).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING` and `0` `EXTRA` keys (checked via `grep -E '^(DIFFERING|EXTRA):'`).
  - Debug `xcodebuild` (`iPhone 17 Pro`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
  - Embedded entitlements inspected via `plutil -p .../Debug-iphonesimulator/SongPhang.build/SongPhang.app-Simulated.xcent` (verified `aps-environment => development`, `com.apple.developer.applesignin => ["Default"]`).
- Live Simulator exercise (`songphang_phase5_5c5`, isolated API `:4000`, `Exercise5C5.app` + `vn.songphang.app`):
  - `ROUTER_AND_DEFER_5C5_PASS`: verified `LinkRouter.pushDestination` accepts valid feed/balances paths, routes 5D `/tx/<uuid>/view` and `/stats` to `.groupFeed` during 5C, and rejects mismatched group UUIDs, `..` traversal, query strings, non-UUID IDs, and unknown suffixes; verified `PushCoordinator.handleFirstExpenseSaved` hides sheet when `features.push == false`, presents sheet once when `true` + `.notDetermined`, persists per-user `"Để sau"` deferral flag, and skips re-prompting on subsequent saves.
  - `LIVE_DISABLED_HIDDEN_5C5_PASS`: against live API with `PUSH_PROVIDER` unset, `AccountModel` kept `pushFeatureEnabled == false` (push settings hidden).
  - `LIVE_CONSOLE_AND_ACCESS_5C5_PASS`: against live API with `PUSH_PROVIDER=console`, `LiveDevicesRepository.registerDevice` twice returned identical device IDs, `AccountModel` loaded `pushFeatureEnabled == true`, exercised later opt-in and `PUT /me/push-settings` `hidePushContent` `true`/`false` round-trip, removed device, confirmed live API group access (`200`) for member group and `404` block for nonexistent/removed group.
  - `xcrun simctl push` to `vn.songphang.app`: delivered 4 simulated push payloads (`balances`, 5D `/tx/.../view` fallback, malformed/mismatched `target`, removed `groupId`), all exited 0 (`Notification sent to 'vn.songphang.app'`), outputting `SIMCTL_PUSH_AND_5C5_ALL_PASS` with zero `sim_5c5_device_token_` occurrences in `api-5c5.log`.
- Security review: checked items 1, 2, 4, 7, 8; no device tokens persisted in `UserDefaults`, Keychain snapshots unaffected, zero device tokens logged in `api-5c5.log`, `LinkRouter.pushDestination` rejects traversal/queries/mismatched IDs before live API `groups.group(id:)` verification confirms current membership (`404` falls back to group list), and no third-party packages added.
- External verification gap: Real iOS system push permission prompt behavior and real APNs token issuance/delivery require a physical iPhone with Apple Developer provisioning and APNs `.p8` key.

### Task 5C.6 — Associated domains and Stage 5C gate

**Approach**
- Files created/modified: `apps/web/src/app/.well-known/apple-app-site-association/route.ts`, `apps/ios/Config/{Debug,Release}.xcconfig`, `apps/ios/App/SongPhang.entitlements`, `apps/ios/SongPhangKit/Sources/AppShell/Routing/LinkRouter.swift`, `apps/ios/SongPhangKit/Sources/AppShell/RootView.swift`, `.env.example`, `README.md`.
- Approach: Serve `/.well-known/apple-app-site-association` as a force-dynamic Next.js route validating `process.env.APPLE_APP_ID` with Zod (`/^[A-Z0-9]{10}\.[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/`): returning `404` (`Cache-Control: no-store`) when absent or invalid, and `200` `application/json` (`Cache-Control: public, max-age=3600`, no redirects) scoped strictly to `/join/*` when valid. Configure `ASSOCIATED_DOMAIN_HOST = example.invalid` in Debug/Release `.xcconfig` and `com.apple.developer.associated-domains` (`applinks:$(ASSOCIATED_DOMAIN_HOST)`) in `SongPhang.entitlements`. Add `PendingInviteState` in `LinkRouter.swift` and wire `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` in `RootView.swift` so universal invite URLs follow the same 5B validator and resume after sign-in while clearing on `.signedIn -> .signedOut` (and preserving `.loading -> .signedOut` cold-launch links).
- Why this is the simplest approach: Reuses Next.js Route Handlers (unaffected by existing `next.config.ts` `/api/*` rewrites or `proxy.ts`), xcconfig entitlement substitution, and the existing `LinkRouter` + pending-route pattern without third-party dependencies.
- Rejected alternative: Placing a static AASA file in `public/.well-known/`, which cannot dynamically return `404` when `APPLE_APP_ID` is unset or reflect runtime `APPLE_APP_ID` changes cleanly after `next build`.

**Observed results (Stage 5C boundary, pre-commit SHA `f8252fa` on branch `phase-5`):**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build succeeded; `├ ƒ /.well-known/apple-app-site-association` compiled as dynamic route).
  - `xcrun swift-format lint --strict --recursive apps/ios`: clean (exit 0).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING` and `0` `EXTRA` keys (`ZERO_DIFF_OR_EXTRA`).
  - Debug `xcodebuild` (`iPhone 17 Pro`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
  - Embedded entitlements inspected via `plutil -p .../Debug-iphonesimulator/SongPhang.build/SongPhang.app-Simulated.xcent`: verified `aps-environment => "development"`, `com.apple.developer.applesignin => ["Default"]`, `com.apple.developer.associated-domains => ["applinks:example.invalid"]`.
- Live AASA HTTP checks (`pnpm --filter @songphang/web exec next start -p 3000 -H 127.0.0.1`):
  - `APPLE_APP_ID` unset -> `HTTP/1.1 404` (`cache-control: no-store`, zero `Location` redirect).
  - `APPLE_APP_ID=invalid-id` -> `HTTP/1.1 404` (zero `Location` redirect).
  - `APPLE_APP_ID=ABCDE12345.vn.songphang.app` -> `HTTP/1.1 200`, `content-type: application/json`, zero `Location` redirect, body `{"applinks":{"details":[{"appIDs":["ABCDE12345.vn.songphang.app"],"components":[{"/":"/join/*"}]}]}}` (`AASA_LIVE_HTTP_5C6_PASS`).
- AppShell Universal Link & Exclusion exercise (`Exercise5C6.app` on Simulator `607AC652-2E92-4BE7-BA18-1B888D79684B`):
  - `ROUTER_AND_PENDING_5C6_PASS`: verified signed-in `/join/<token>` routes immediately without storing `pendingRoute`; signed-out holds `pendingRoute` and resumes upon sign-in; foreign host, wrong port, Release HTTP downgrade, `/link/telegram`, `/verify-email`, `/reset-password`, `/api/v1/auth/google/callback`, `songphang://auth`, `..` traversal, empty token, and extra segments are rejected without overwriting `pendingRoute`; sign-out clears `pendingRoute`.
- Disposable DB Replay & Stage 5C Capability/Session/Device/Role Matrix (`songphang_phase5_5c_gate`, isolated `:4001` capability-off, isolated `:4000` capability-on + `apps/worker`):
  - `CAPABILITY_OFF_5C6_PASS`: verified all capability booleans `false`, `providers.google === false`, and `404` on `/auth/apple`, `/me/devices`, `/me/push-settings`.
  - `REPLAY_5B_HANDOFF_5C6_PASS`: replayed all 5B handoff core ledger exercises on live API (`Group A` & `Group B` invites + signed-out universal link resume, quick entry `120k` + idempotent double-tap, live SSE `changed`, stale `v1` `409 .conflict`, delete/undo restore, direct settlement to `0 đ`, remote iOS session revoke `401`, removed/deleted group `404`).
  - `GATE_5C6_PASS`: `routes=38 cases=58 balances=All_groups_balanced` covering Google PKCE (`no challenge -> 400`, `302`, `wrong verifier -> 400`, `exchange -> 200 no-store`, `replay -> 400`), Apple Sign-In (`bad aud -> 401`, `good JWT -> 200`, `DELETE /me -> 204` logging `apple.revoke.simulated`), push device/session boundary (`Cookie -> 403`, `Mixed -> 403`, `Web Bearer -> 403`, foreign delete `404`, 10-device cap -> 11th `422 LIMIT_REACHED`, logout cascade deletes devices, `hideContent: true` persisted in `GET /me`), role boundaries (Owner/Editor/Viewer `403`/Outsider `404` across group endpoints/Unverified `403`), Phase 2–4 regression (payment methods, settlement request confirm, custom categories, stats, UTF-8 BOM CSV bytes `EF BB BF`, fund, budget, comments, disputes), and live worker `pg-boss` emitting sanitized `push.sent.console` (`"Có cập nhật trong nhóm Nhóm Gate 5C"`) with zero leaked tokens/verifiers in `api-5c6.log` or `worker-5c6.log`.
- Security review: checked items 1, 2, 4, 6, 7, 8; `APPLE_APP_ID` strictly validated before serving AASA JSON (`404` otherwise, no redirects), `.xcconfig`/entitlements contain placeholder `example.invalid` without real keys/secrets, universal link router enforces exact scheme/host/port + strict invite token format and excludes `/link/telegram`, email/reset, and OAuth callbacks, zero tokens/verifiers leaked in logs, no third-party packages added.
- External verification gap (5C.6): Live `applinks:<domain>` HTTPS domain association on a physical iPhone (`swcutil` / CDN-served AASA over HTTPS) requires the owner's production domain, Team ID, and provisioning profile.

### Task 5D.1 — Payment methods, QR and settlement requests

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Package.swift`, `apps/ios/App/Info.plist`, `apps/ios/Config/Info-Debug.plist`, `Domain/Models/{Balance,Member,PaymentMethod}.swift`, `Domain/Repositories/{MembersRepository,SettlementRequestsRepository}.swift`, `DesignSystem/Components/PendingSettlementCard.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `Repositories/Balances/{BalanceMapping,LiveSettlementRequestsRepository}.swift`, `Repositories/Members/{MemberMapping,LiveMembersRepository}.swift`, `PaymentsFeature/Pay/{PayModel,PayView,PaymentQRCode}.swift`, `PaymentsFeature/PaymentDetails/{PaymentBanks,PaymentDetailsModel,PaymentDetailsView}.swift`, `GroupsFeature/Members/{MembersModel,MembersView}.swift`, `LedgerFeature/Balances/{BalancesModel,BalancesView}.swift`, `PreviewSupport/Fakes/{FakeRepositories,FakeSettlementRequestsRepository,FakeWorld,FakeWorld+Payments}.swift`, `AppShell/{AppDependencies,RouteDestination}.swift`.
- Approach: Add `PaymentsFeature` (S14 `PayView` + `PaymentDetailsView`) and `PendingSettlementCard` in `DesignSystem` without adding feature-to-feature imports. Map `paymentMethods`, `purpose`, `qrPayload`, and `pendingRequest` from `/balances` and `/members`, preserving them across resilient snapshot encoding/decoding (`BalanceMapping` and `MemberMapping` skip unknown method kinds safely), and fetch pending requests via `GET /settlement-requests`. Render server `qrPayload` via Core Image `CIFilter.qrCodeGenerator()` (240pt minimum, 4-module white quiet zone) with `Lưu mã QR` (`PHPhotoLibrary.requestAuthorization(for: .addOnly)`), copyable bank/wallet details, `PendingSettlementCard` inline on `BalancesView` and `PayView`, and `PaymentDetailsView` with searchable 76-bank picker and Vietnamese uppercase/phone normalization.
- Why this is the simplest approach: Keeps all UI inside `PaymentsFeature`/`DesignSystem`, keeps money server-authoritative with integer `Money`, and isolates OpenAPI DTOs inside `Repositories`.
- Rejected alternative: Keeping `MemberPaymentEditor` inside `GroupsFeature`, which conflicted with AD §5 feature ownership.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING` and `0` `EXTRA` keys.
  - Debug `xcodebuild` (`generic/platform=iOS Simulator`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d1`, clean-env API `:4000`, `Exercise5D1.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D1_API_PASS`: verified viewer editing other member payment details refused (`403`), viewer editing own payment details accepted (`200`, phone `+84 912.345.678` -> `0912345678`), owner saving 3 methods (`bank`, `momo`, `zalopay`) returned `200`, `GET /balances` returned `qrPayload` + `purpose` (`SP Lan tra Minh`), `POST /settlement-requests` kept ledger unchanged while pending, duplicate idempotency key returned identical request, new key returned `409 REQUEST_ALREADY_PENDING`, viewer confirm refused (`403`), `reject` & `cancel` succeeded, `confirm` created 1 settlement transfer (`01a203d3-85cc-7d7e-8001-5590fdd3f168`) clearing debt to `0`, and re-confirming returned `409 REQUEST_NOT_PENDING`.
  - `SIM_EXERCISE_5D1_READY`: `LiveMembersRepository` & `LiveBalancesRepository` snapshot round-trips retained `paymentMethods`, `purpose`, and `pendingSettlement`; `LiveSettlementRequestsRepository` idempotent double-tap & `list(status: .pending)` succeeded.
  - Simulator QR screenshot (`docs/superpowers/runs/phase-5/screens/5d/pay-qr.png`) decoded with Apple Vision (`VNDetectBarcodesRequest`): `DECODED_COUNT=1`, `QR_BYTE_EXACT_MATCH=true length=123` matching server `qrPayload` (`00020101021238540010A00000072701240006970436011001234567890208QRIBFTTA53037045405600005802VN62190815SP Lan tra Minh6304227A`) byte for byte.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`sum 0; mismatches 0`).
- Security review: checked relevant items 1, 2, 4, 7, 8; no secrets or tokens in logs/diffs, `NSPhotoLibraryAddUsageDescription` uses add-only access, all writes gated by server group role + verified email + `hasCurrentPaymentDetails` / online checks, `PendingSettlementCard` & `PayView` accept only server-supplied `qrPayload`, no third-party dependencies added.
- External verification gap (5D.1): Physical iPhone banking-app QR scan and live Photos save authorization prompt belong to owner device checks.

### Task 5D.2 — Search, categories, statistics and CSV

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Package.swift`, `Domain/Models/{Category,GroupStats,TransactionFilter,LedgerTransaction,TransactionDraft}.swift`, `Domain/Repositories/{CategoriesRepository,StatisticsRepository,TransactionsRepository}.swift`, `Repositories/Snapshots/SnapshotStore.swift`, `Repositories/Categories/{CategoryMapping,LiveCategoriesRepository}.swift`, `Repositories/Statistics/{StatsMapping,LiveStatisticsRepository}.swift`, `Repositories/Transactions/{TransactionMapping,LiveTransactionsRepository}.swift`, `PreviewSupport/Fakes/{FakeWorld,FakeWorld+Ledger,FakeWorld+Stats,FakeRepositories}.swift`, `DesignSystem/Components/{CategoryLabel,CategoryManagementSection,FileShareSheet}.swift`, `DesignSystem/Resources/Localizable.xcstrings`, `StatisticsFeature/Stats/{StatsModel,StatsBarRows,StatsView}.swift`, `GroupsFeature/GroupSettings/{GroupSettingsModel,GroupSettingsView}.swift`, `LedgerFeature/ExpenseForm/{ExpenseFormModel,ExpenseFormSubViews,ExpenseFormView}.swift`, `LedgerFeature/GroupFeed/{FilterSheetView,GroupFeedModel,GroupFeedSubViews,GroupFeedView}.swift`, `AppShell/{AppDependencies,Route,RouteDestination,RootView,Routing/LinkRouter}.swift`.
- Approach: Add `GroupCategory`, `GroupStats`, `TransactionFilter`, and `categoryId` support in `Domain` and `Repositories` (with OpenAPI filter queries and raw-byte CSV export via `OpenAPIRuntime.HTTPBody`), snapshot-caching only unfiltered page 1 of transactions and group categories. Build `StatisticsFeature` (`StatsView` S16) computing integer permille widths only for visual bar fill ratios, writing UTF-8 BOM CSV bytes to temporary storage off the main actor with `.completeFileProtectionUntilFirstUserAuthentication`, sharing via `UIActivityViewController`, and deleting the temporary file on completion. Share `CategoryManagementSection` in `DesignSystem` across `GroupSettingsView` and `ExpenseFormView` without cross-feature imports, and wire `Tổng chuyến đi`, 300ms debounced search, filter sheet/chips, and `/stats` push routing in `GroupFeed` and `AppShell`.
- Why this is the simplest approach: Keeps money server-authoritative in integer `Money`, avoids cross-feature dependencies via `DesignSystem` + `StatisticsFeature`, and aligns 1:1 with web filter/stats drill-down query parameters.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0, no output).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING`, `0` `EXTRA`, and `0` missing keys across `csv.*`, `stats.*`, `categories.*`, `filter.*`.
  - Debug `xcodebuild` (`generic/platform=iOS Simulator`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d2`, clean-env API `:4000`, `Exercise5D2.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D2_API_PASS`: verified viewer `403` on category creation, `409 CATEGORY_EXISTS` duplicate rejection, owner/editor category CRUD & archive (`204`), accent-insensitive Vietnamese search (`q="ca phe"` -> 1 match), custom category & uncategorized filters, `/stats` total `370000`, and `/export.csv` (`435` bytes) starting with UTF-8 BOM `efbbbf`, exact Vietnamese headers, and integer amounts.
  - `SIM_5D2_CATEGORIES_PASS`, `SIM_5D2_FILTER_PASS` (`search=Cà phê sữa đá`), `SIM_5D2_DRILLDOWN_PASS` (`total=370000` with category/uncategorized drill-down IDs matching exact feed rows), `SIM_5D2_CSV_PASS` (`bytes=435 cleaned=true`), `SIM_EXERCISE_5D2_READY`.
  - Captured and inspected Simulator screenshot `docs/superpowers/runs/phase-5/screens/5d/stats.png`.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`01a203e7-16e7-7ebc-8b91-56354c681012 Đà Lạt 5D2: sum 0; mismatches 0`); disposable DB dropped and ports `3000`/`4000` verified free.
- Security review: checked relevant items 1, 2, 4, 7, 8; no secrets or tokens in logs/diffs, server validates filter queries and enforces group membership/write roles (`403` viewer on category mutations), temp CSV file uses `.completeFileProtectionUntilFirstUserAuthentication` off MainActor and is removed on share completion, no third-party dependencies added.

### Task 5D.3 — Funds and budgets

**Approach**
- Files created/modified: `Domain/Models/{Balance,Budget,Fund,LedgerTransaction,Member,QuickEntryReading,SharePreview}.swift`, `Domain/Repositories/{BudgetRepository,FundRepository}.swift`, `Repositories/{Snapshots/SnapshotStore,Balances/BalanceMapping,Members/MemberMapping,QuickEntry/QuickEntryMapping,Transactions/TransactionMapping,Transactions/LiveTransactionsRepository,Fund/LiveFundRepository,Budget/BudgetMapping,Budget/LiveBudgetRepository}.swift`, `DesignSystem/{Tokens/Tokens,Components/BudgetBannerView,Components/FundBlockView,Components/FundShapeView,Components/MemberShapeView,Resources/Localizable.xcstrings}.swift`, `PreviewSupport/Fakes/{FakeRepositories,FakeWorld,FakeWorld+FundBudget}.swift`, `PaymentsFeature/Fund/{CreateFundSheetView,FundModel,FundView}.swift`, `GroupsFeature/{Members/MembersView,GroupSettings/BudgetSettingsCard,GroupSettings/GroupSettingsModel,GroupSettings/GroupSettingsView}.swift`, `LedgerFeature/{Balances/BalancesView,GroupFeed/GroupFeedModel,GroupFeed/GroupFeedView,ExpenseForm/ExpenseFormModel,ExpenseForm/ExpenseFormSubViews,ExpenseForm/ExpenseFormView,ConfirmCard/ConfirmationCardView,ConfirmCard/QuestionCardView,QuickEntry/QuickEntryModel,QuickEntry/QuickEntryView}.swift`, `StatisticsFeature/Stats/{StatsModel,StatsView}.swift`, `AppShell/{AppDependencies,Route,RouteDestination,RootView,Routing/LinkRouter}.swift`.
- Approach: Add integer-only `FundSummary`, `FundContribution`, `TransactionWarning`, `GroupBudget`, `BudgetState`, `MemberKind`, and `.fundCannotShare` in `Domain`, wire `/fund` and `/budget` repositories (including explicit `"holderMemberId": null` raw PATCH in `LiveFundRepository.patchClearingHolder` because `swift-openapi-generator`'s synthesized `encodeIfPresent` omits `nil`), and surface server warnings (`FUND_OVERDRAWN`, `BUDGET_NEAR`, `BUDGET_OVER`) on `ExpenseFormView`, `QuickEntryView`/`ConfirmationCardView`, `QuestionCardView`, `GroupFeedView`, and `StatsView` alongside S17 `FundView` and `BudgetSettingsCard`.
- Why this is the simplest approach: Keeps all official fund cash, contributions, budget spent/state, and warning checks strictly on the server while keeping SwiftUI views declarative and preventing fund selection as an expense sharer.
- Rejected alternative: Client-side budget/fund cash recomputation from feed pages, which would drift from paginated/filtered views and violate integer-only server authority.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING`, `0` `EXTRA`, and `0` missing keys across `fund.*`, `budget.*`, `balances.fund*`, `balances.memberContributesToFund`, and `unparsed.fundCannotShare`.
  - Debug `xcodebuild` (`generic/platform=iOS Simulator`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d3`, clean-env API `:4000`, `Exercise5D3.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D3_SETUP_PASS`: verified editor & viewer receive `403` on `PUT/DELETE /budget`, viewer receives `403` on `POST /fund`, and outsider receives `404` on `/budget`.
  - `SIM_5D3_DELETE_UNUSED_FUND_PASS`, `SIM_5D3_FUND_CRUD_HOLDER_CLEAR_PASS`: verified idempotent fund creation replay, `FundHolderUpdate.clear` clearing holder (`nil`) on live PATCH, holder restoration, and deleting an unused fund.
  - `SIM_5D3_FUND_CANNOT_SHARE_PASS`: verified API `FUND_CANNOT_SHARE` error and quick-entry `.fundCannotShare` issue detection.
  - `SIM_5D3_BUDGET_LIFECYCLE_PASS`: verified editor `403` via `LiveBudgetRepository`, `ok` -> `near` (80% / `800000` on `1000000`) -> `over` (`1100000`) transitions, `BUDGET_NEAR` / `BUDGET_OVER` / `FUND_OVERDRAWN` preview & save warnings, month budget switch, and delete/recreate.
  - `SIM_5D3_OVERDRAWN_CLOSE_DELETE_GUARDS_PASS`, `SIM_5D3_CLOSE_REOPEN_AT_ZERO_PASS`, `SIM_5D3_FUND_VIEW_CASH cash=250000 contribs=3`, `SIM_EXERCISE_5D3_READY`.
  - Captured and visually inspected `docs/superpowers/runs/phase-5/screens/5d/fund.png`.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`01a20400-81a2-7831-8639-e953a9ad6280 Đà Lạt 5D3: sum 0; mismatches 0`, `01a20400-81ce-7b06-9a57-530559e1e7b8 Nhóm xoá quỹ 5D3: sum 0; mismatches 0`); disposable DB dropped and ports `3000`/`4000` verified free.
- Security review: checked relevant items 1, 2, 4, 6, 8; no secrets/tokens in code or logs, `LiveFundRepository.patchClearingHolder` sends `Authorization: Bearer` + `X-App-Version` without logging tokens or bodies, server enforces `owner` on `/budget` writes (`403` editor/viewer) and `editor` on `/fund` writes (`403` viewer), no floating-point money conversions or third-party dependencies added.

### Task 5D.4 — Receipt capture, attachments, item splitting, and assisted entry

**Approach**
- Files created/modified: `apps/ios/App/Info.plist`, `apps/ios/Config/Info-Debug.plist`, `apps/ios/SongPhangKit/Sources/Domain/Models/{Receipt,LedgerTransaction,TransactionDraft,QuickEntryReading}.swift`, `apps/ios/SongPhangKit/Sources/Domain/Repositories/{AttachmentsRepository,ReceiptScansRepository,QuickEntryRepository,TransactionsRepository}.swift`, `apps/ios/SongPhangKit/Sources/Repositories/{Attachments,ReceiptScans,Receipts,Transactions,QuickEntry}/`, `apps/ios/SongPhangKit/Sources/DesignSystem/{Components/PhotoAttachmentViews.swift,Resources/Localizable.xcstrings}`, `apps/ios/SongPhangKit/Sources/LedgerFeature/{ReceiptCapture,ReceiptReview,Shared/ItemsSplitDraft.swift,ConfirmCard,QuickEntry,ExpenseForm,SplitEditor,GroupFeed}`, `apps/ios/SongPhangKit/Sources/AppShell/{AppDependencies,Route,RouteDestination}.swift`, `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeWorld,FakeWorld+Ledger,FakeWorld+Receipts,FakeRepositories}.swift`.
- Approach: Added `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to app plists. Implemented `ReceiptImageProcessor` stripping EXIF/GPS metadata and re-encoding to JPEG <=2000px longest edge in detached background task. Implemented `AttachmentsRepository` for multipart upload `POST /groups/{id}/attachments` and authenticated `GET .../content` download, and `ReceiptScansRepository` for scanning and polling. Built `ItemsSplitDraft` and `ReceiptReviewModel` (S18 screen) with 3s polling, timeout handling, member assignment (`splitRemainingEqual`), mismatch banner detection, and printed total adjustment (`applyPrintedTotal`). Enhanced Quick Entry with explicit-send AI parsing (`ai: true`), slow-reading banner, and multi-draft queue navigation.
- Why this is the simplest approach: Keeps image re-encoding off the main actor, relies on server-authoritative item calculation and preview, and uses standard iOS PhotosPicker/Camera without third-party frameworks.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0).
  - `apps/ios/Scripts/check-strings.sh`: `0` `DIFFERING`, `0` `EXTRA`, and `0` missing keys across `attachments.*`, `receipts.*`, `compose.*`, `split.methodItems`, `split.modeItems`, and feed split captions.
  - Debug `xcodebuild` (`generic/platform=iOS Simulator`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d4`, clean-env API `:4010`, worker `AI_PROVIDER=fake`, `Exercise5D4.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D4_SETUP_PASS`: verified Group A setup, member invites, and viewer role on Hoa.
  - Verified all 4 committed fixtures: `clean.jpg` -> `SIM_5D4_FIXTURE_CLEAN_PASS` (2 items, 440k total), `tax-service.jpg` -> `SIM_5D4_FIXTURE_TAX_SERVICE_PASS` (2 extras, 110k total), `mismatch.jpg` -> `SIM_5D4_FIXTURE_MISMATCH_PASS` (`TOTAL_MISMATCH` flag), `not-a-receipt.jpg` -> `SIM_5D4_FIXTURE_NOT_A_RECEIPT_PASS` (`errorCode: NOT_A_RECEIPT`).
  - `SIM_5D4_ATTACHMENTS_SECURITY_PASS`: verified authenticated content download and outsider refusal 404.
  - `SIM_5D4_ITEMS_TRANSACTION_PASS`: saved expense with items split, service extra, and attachment (attachment count = 1).
  - `SIM_5D4_AI_QUICK_ENTRY_PASS`: verified multi-draft AI sentence parse ("cà phê 180k và bánh 50k" -> draft 180k + moreDrafts [50k]), rules fallback when `ai: false`, and saved both drafts to ledger.
  - `SIM_5D4_ATTACHMENT_DOWNLOAD_PASS` (size 55000), `SIM_5D4_SCAN_FETCH_PASS` (items = 2), `SIM_5D4_MISMATCH_BANNER_ACTIVE` (`[totalMismatch]`), `SIM_5D4_UNASSIGNED_ISSUE_PASS` (`unassignedCount = 2`), `SIM_5D4_MISMATCH_INFO_DETECTED` (`computed = 442000, printed = 450000`), `SIM_5D4_TARGET_ADJUSTMENT_PASS` (`computed = 450000, canSave = true`), `SIM_EXERCISE_5D4_READY`.
  - Captured and verified Simulator screenshot `docs/superpowers/runs/phase-5/screens/5d/receipt-review.png`.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`01a20434-7a4e-772c-9d34-8405bbbf0d73 Đà Lạt 5D4: sum 0; mismatches 0`).
- Security review: checked relevant items 1, 2, 4, 7, 8; no secrets or tokens in logs/diffs, `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` documented, EXIF/GPS stripped prior to upload, authenticated content download gated by group membership, outsider receives 404, integer-only money calculations.

### Task 5D.5 — Notification center, settings, mute and reminders

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Package.swift`, `apps/ios/SongPhangKit/Sources/Domain/Models/{AppNotification,ExpenseGroup}.swift`, `apps/ios/SongPhangKit/Sources/Domain/Repositories/{NotificationsRepository,RemindersRepository,GroupsRepository}.swift`, `apps/ios/SongPhangKit/Sources/Domain/AppError.swift`, `apps/ios/SongPhangKit/Sources/Repositories/{Notifications,Reminders,Groups}/`, `apps/ios/SongPhangKit/Sources/DesignSystem/{Components/NotificationBellButton.swift,Resources/Localizable.xcstrings}`, `apps/ios/SongPhangKit/Sources/NotificationsFeature/`, `apps/ios/SongPhangKit/Sources/AccountFeature/Account/{AccountModel,AccountView}.swift`, `apps/ios/SongPhangKit/Sources/GroupsFeature/{GroupList,GroupSettings,Members}/`, `apps/ios/SongPhangKit/Sources/LedgerFeature/{Balances,GroupFeed}/`, `apps/ios/SongPhangKit/Sources/AppShell/{AppDependencies,SessionModel,RootView,Route,RouteDestination}.swift`, `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeWorld+Notifications,FakeRepositories}.swift`.
- Approach: Added 38 Vietnamese localization strings matching web notification/reminder text. Implemented `AppNotification` domain models with 12 structured payloads and safe fallback. Added `NotificationsRepository` and `RemindersRepository` calling `/me/notifications`, `/me/notifications/unread-count`, `/me/notifications/read`, `/me/notification-settings`, and `/groups/{id}/reminders` (handling 429 `REMINDER_TOO_SOON` with extracted `nextAt`). Built `NotificationBellButton` with unread count badge on group list and feed headers. Built `NotificationsView` (S19 screen) with load-more pagination, mark one read on tap, and mark all read. Added email notification settings card to `AccountView`. Added `setMuted` switch to `MembersView`. Added `Tự động nhắc nợ` segmented picker to `GroupSettingsView`. Added manual `Nhắc` and `Nhắc cả nhóm` buttons to `BalancesView` with eligibility rules (`canRemindTransfer`) and formatted cooldown feedback (`formatReminderNextAt`).
- Why this is the simplest approach: Reuses established `@Observable` patterns, keeps notifications domain layer clean without third-party dependencies, wires directly into the AppShell route hierarchy, and validates server-enforced reminder rate limiting.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0).
  - `check-strings.sh`: 0 missing strings for notifications and reminders.
  - Debug `xcodebuild` (`generic/platform=iOS Simulator`) & Release `xcodebuild` (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`): both `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d5`, clean-env API `:4010`, worker `AI_PROVIDER=fake`, `Exercise5D5.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D5_SETUP_PASS`: verified registration & login for Minh, Lan, Hoa, Nam; created "Hội An 5D5"; invite & join with member claim; set Hoa as viewer.
  - Verified notification settings: `GET /me/notification-settings` defaults (`immediate=true, digest=true`), `PUT /me/notification-settings` persist (`immediate=false, digest=false`), restored.
  - Verified group mute: `PUT /groups/{id}/me/muted` toggles `muted: true` and `muted: false`.
  - Verified reminder interval: `PATCH /groups/{id}` sets `reminderIntervalDays: 7` and clears to `null`.
  - Verified reminders: single reminder sent from Minh to Lan; immediate retry caught expected `429 REMINDER_TOO_SOON` with `nextAt`; `remindAll` reminded Hoa and skipped Lan (cooldown).
  - Verified notifications inbox for Lan: `unread-count > 0`, `list` contains `debt_reminder` notification, `markOneRead` marks single notification, `markAllRead` clears unread count to 0.
  - Verified outsider 404 refusal for both reminders and mute.
  - Swift Simulator execution: `[5D.5] Minh signed in`, `Settings updated and verified`, `Group mute/unmute verified`, `Reminder interval verified`, `Caught expected reminderTooSoon: nextAt=2026-11-23T18:00:31.649Z`, `Send all reminders: reminded=0, skipped=2`, `Lan signed in`, `Lan unread count: 0`, `Lan notifications count: 2`, `SIM_EXERCISE_5D5_READY`.
  - Captured and verified Simulator screenshot: `docs/superpowers/runs/phase-5/screens/5d/notifications.png`.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`01a2046a-b426-7ba1-b2a3-ff06412f566e Hội An 5D5: sum 0; mismatches 0`).
- Security review: checked relevant items 1, 2, 4, 7, 8; no tokens/passwords in code/logs, notifications scoped to authenticated user, outsider receives 404 on group mute & reminders, integer-only money in notification payloads and reminder debt formatting, no HTML injection in notification text.

### Task 5D.6 — Transaction detail, discussions, disputes and approval

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Sources/Domain/Models/{Comment,ExpenseGroup,LedgerTransaction}.swift`, `apps/ios/SongPhangKit/Sources/Domain/Repositories/{GroupsRepository,TransactionsRepository}.swift`, `apps/ios/SongPhangKit/Sources/Repositories/{Groups,Transactions}/`, `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupSettings/{ApprovalCardView.swift,GroupSettingsModel.swift,GroupSettingsView.swift}`, `apps/ios/SongPhangKit/Sources/LedgerFeature/{TransactionDetail/,GroupFeed/}`, `apps/ios/SongPhangKit/Sources/AppShell/{Route,RouteDestination,SessionModel}.swift`, `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeWorld,FakeWorld+Ledger,FakeRepositories}.swift`.
- Approach: Added 33 Vietnamese localization keys for comments, disputes, and approvals. Implemented `Comment`, `TransactionApproval`, and `TransactionDispute` domain models. Added methods to `TransactionsRepository` and `GroupsRepository` calling `/transactions/{id}/comments`, `/dispute`, `/dispute/resolve`, `/approve`, `/reject`, and `/groups/{id}` (`approvalThreshold`). Built `ApprovalCardView` in `GroupSettingsView` with owner-only access. Built `TransactionDetailView` (S20 screen) with `TransactionSummaryView` (items breakdown, category chip, payer/split chips, remote photo attachments), `ApprovalBlockView` (pending amber / rejected coral banners with note, owner approve & reject action sheet), `DisputeBlockView` (coral dispute card, reason field sheet, resolve button), `CommentThreadView` (list, load more, delete button for author/owner), and `CommentFieldView` (bottom input bar). Wired transaction rows in `GroupFeedView` to navigate to S20 on tap, showing pending/rejected/dispute tags and comment counters.
- Why this is the simplest approach: Keeps discussion and dispute flows cleanly encapsulated within `TransactionDetailModel`, prevents cross-module circular dependencies by injecting email verification banner from `RouteDestination`, and relies on server-authoritative balance calculation (pending and rejected transactions excluded).

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors, 3 pre-existing `noImgElement` warnings; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `xcrun swift-format lint --strict --recursive apps/ios`: PASS (exit 0).
  - `check-strings.sh`: 0 missing strings for comments, disputes, and approvals (only 5D.7 Telegram keys remain).
  - Debug & Test iOS scheme build (`SongPhang` on `iPhone 17 Pro` `607AC652-2E92-4BE7-BA18-1B888D79684B`): `** TEST BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d6`, clean-env API `:4010`, worker `AI_PROVIDER=fake`, `Exercise5D6.app` on `iPhone 17 Pro`):
  - `EXERCISE_5D6_NODE_PASS`: verified registration & login for Minh, Lan, Hoa, Nam; created "Hội An 5D6"; invite & claim; set Hoa as viewer.
  - Verified approval policy: non-owner (Lan) PATCH approvalThreshold returned 403; negative threshold (-50,000) returned 400; owner set 500,000 returned 200 and verified via `GET /groups/{id}`.
  - Verified transaction below threshold (300k): `approval.status == "none"`, included in balances immediately (Lan balance = -150k).
  - Verified transaction above threshold (600k) by Lan: `approval.status == "pending"`, excluded from balances (Lan balance remained -150k); non-owner (Lan) and viewer (Hoa) approve/reject returned 403; outsider returned 404; owner approved -> `approval.status == "approved"`, balances updated (Lan balance = +150k).
  - Verified transaction rejected by owner (1.2M): `approval.status == "rejected"` with note "Khoản chi cá nhân không chia chung", excluded from balances (Lan balance remained +150k).
  - Verified disputes: Lan opened dispute on 300k tx (`POST .../dispute` -> 201 with reason), outsider returned 404, non-opener viewer resolve returned 403, opener (Lan) resolved dispute -> `dispute: null` (200).
  - Verified comments: posted 3 comments by Minh, Lan, Hoa (with `idempotency-key` >=8 chars); list returned 3 comments; non-author delete returned 403; author (Minh) deleted comment (204); remaining count = 2.
  - Verified soft-delete comments: deleted rejected tx, posted comment on soft-deleted tx returned 201 without restoring transaction (`deletedAt != null`).
  - Swift Simulator execution: `[5D.6] Minh signed in: Minh`, `[5D.6] Loaded txAbove: Hải sản Cửa Đại, approval=approved`, `[5D.6] Added comment via TransactionDetailModel, count=3`, `[5D.6] Swift model open dispute: true`, `[5D.6] Swift model resolve dispute completed`, `SIM_EXERCISE_5D6_READY`.
  - Captured and verified Simulator screenshot: `docs/superpowers/runs/phase-5/screens/5d/transaction-detail.png` (215 KB).
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `All groups balanced` (`01a20493-0418-7679-aecf-95dd2551af0b Hội An 5D6: sum 0; mismatches 0`).
- Security review: checked relevant items 1, 2, 4, 7, 8; no tokens/passwords in code/logs, all routes enforce role and membership (outsider 404), owner-only approval policy and decisions (403 for non-owners), integer-only money calculations, plain SwiftUI text rendering preventing HTML injection.

### Task 5D.7 — Telegram management, push target routing and Stage 5D parity gate

**Approach**
- Files created/modified: `apps/ios/SongPhangKit/Sources/Domain/Models/ChatLink.swift`, `apps/ios/SongPhangKit/Sources/Domain/Repositories/ChatLinksRepository.swift`, `apps/ios/SongPhangKit/Sources/Repositories/ChatLinks/LiveChatLinksRepository.swift`, `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeWorld,FakeWorld+ChatLinks,FakeRepositories}.swift`, `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, `apps/ios/SongPhangKit/Sources/AccountFeature/Account/{AccountModel,AccountModel+Telegram,TelegramAccountCardView,TelegramPairingSheetView,AccountView}.swift`, `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupSettings/{GroupSettingsModel,TelegramGroupCardView,GroupSettingsView}.swift`, `apps/ios/SongPhangKit/Sources/AppShell/{AppDependencies,RouteDestination,RootView,Routing/LinkRouter}.swift`, `docs/superpowers/runs/phase-5/{parity-matrix,manual-checks,progress}.md`, `docs/superpowers/runs/phase-5/screens/5d/telegram.png`.
- Approach: Added all 27 remaining `telegram.*` Vietnamese strings matching web `vi.ts` verbatim (670/670 keys). Implemented `ChatLinksRepository` and `LiveChatLinksRepository` using the generated OpenAPI client across all 9 account-pairing and group-link endpoints. Built `TelegramAccountCardView` and `TelegramPairingSheetView` polling pairing state every 2s under the initiating Bearer session, opening only server-supplied `deepLinkUrl`, supporting confirm/cancel/unlink and 409 `identityTaken` / expired handling. Built owner-only `TelegramGroupCardView` in Group Settings for generating `/lienket` codes and unlinking chats. Upgraded `LinkRouter.pushDestination` and `RootView.applyPushTap` to route `/g/{id}/tx/{txId}/view` to `.transactionDetail` and `/notifications` to `.notifications` while keeping browser `/link/telegram` untouched.
- Why this is the simplest approach: Reuses existing OpenAPI client operations, `AppDependencies` composition, and SwiftUI `.sheet`/`.task` polling without introducing any new background services or dependencies.

**Observed results:**
- Build & lint gates:
  - `pnpm check`: PASS (`biome check .` — 512 files, 0 errors, 3 pre-existing `noImgElement` warnings; 8 workspace typechecks; `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build succeeded across all 14 static/dynamic routes).
  - `./apps/ios/Scripts/check-strings.sh`: PASS (`OK: 670 web keys verified, 0 missing, 0 differing.`).
  - `xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources`: PASS (exit 0).
  - Debug & Test build (`xcodebuild build-for-testing` for `iPhone 17 Pro`): `** TEST BUILD SUCCEEDED **`.
  - Release build (`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`): `** BUILD SUCCEEDED **`.
- Live Simulator & API exercise (`songphang_phase5_5d7`, clean-env API `:4010` + Worker with `TELEGRAM_PROVIDER=console`, `TELEGRAM_BOT_USERNAME=SongPhangLocalBot`, `AI_PROVIDER=fake`, `PUSH_PROVIDER=console`):
  - `EXERCISE_5D7_NODE_PASS`: verified two-sided pairing cancel (`204`), wrong-session denial (`404` on poll & confirm across Minh's second session pre- and post-bot callback), legacy `/claim` refusal (`404`), premature confirm refusal (`400`), webhook private `/start` -> callback `pc:` -> confirm (`204`) -> `/me/chat-identities` linked; role-aware group chat link code (`403` editor/viewer, `404` outsider) -> webhook `/lienket` -> `/chi Kem dừa 90k` draft + callback `s:<draftId>` -> ledger recorded 90k + `/sodu`.
  - Swift Simulator execution (`Exercise5D7.app` on `iPhone 17 Pro`): `[5D.7] Minh signed in`, `[5D.7] AccountModel verified linked Telegram identity`, `[5D.7] GroupSettingsModel verified code generation & unlink`, `[5D.7] Push routing & 404 boundary verified` (`.transactionDetail`, `.groupBalances`, `.notifications`, unknown path `nil`, `/link/telegram` `nil`, outsider group 404), `[5D.7] AccountModel unlink, start pairing, cancel pairing verified`, `SIM_EXERCISE_5D7_READY`.
  - Captured Simulator screenshot: `docs/superpowers/runs/phase-5/screens/5d/telegram.png`.
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `01a20658-af9f-7226-9b87-3d89a36be433 Phú Quốc 5D7: sum 0; mismatches 0` (`All groups balanced`).
- Stage 5D Parity Matrix status: all Phase 2–4 rows (`P2-01`..`P4-07`) now verified locally in 5D.1–5D.7; remaining follow-ups are external providers only (`Real SMTP`, `Real Telegram client & Bot API webhook`, `Real AI provider`).
- Security review: checked items 1, 2, 4, 7, 8; wrong-session Telegram pairing denial confirmed (`404`), webhook secret required, no secret/token logged in Swift models, legacy `/claim` code refused, browser `/link/telegram` not hijacked by `LinkRouter`, integer-only money via `/chi`.

### Task 5E.1 — Release build, metadata and bundled assets

**Approach**
- Files created/modified: `apps/ios/App/Assets.xcassets/AppIcon.appiconset/{AppIcon.png,Contents.json}`, `apps/ios/App/PrivacyInfo.xcprivacy`, `docs/superpowers/runs/phase-5/{progress,manual-checks}.md`, `docs/superpowers/runs/phase-5/screens/5e/upgrade-required.png`.
- Approach: Rendered a 1024×1024 opaque RGB PNG (`hasAlpha: no`) containing Sòng Phẳng's four-shape fallback mark on `#F6F2EA` (teal `#0D7A6F`, amber `#E89B2D`, coral `#D9534F`, ink `#1F2421`) since Phase 7A branding assets are not yet present in the repo, and referenced it in `AppIcon.appiconset/Contents.json`. Added `PrivacyInfo.xcprivacy` with `NSPrivacyTracking = false`, `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`), and the five app-functionality data types (`EmailAddress`, `Name`, `UserID`, `PhotosorVideos`, `OtherUserContent`), automatically bundled via `PBXFileSystemSynchronizedRootGroup`. Confirmed `Release.xcconfig` keeps `vn.songphang.app`, `Sòng Phẳng`, `1.0.0`, build `1`, and `https://example.invalid` placeholders, while `NSAllowsLocalNetworking` stays strictly in `Config/Info-Debug.plist` and out of `App/Info.plist`. Retained system font per D2 and flagged Be Vietnam Pro `.ttf`/`.otf` replacement for owner action.
- Why this is the simplest approach: Reuses the Xcode synchronized App group, keeps Release free of fakes or local HTTP exceptions, and matches Apple's exact App Store Connect validation requirements.

**Observed results:**
- Asset & Privacy Manifest validation:
  - `sips -g pixelWidth -g pixelHeight -g hasAlpha .../AppIcon.png`: `pixelWidth: 1024`, `pixelHeight: 1024`, `hasAlpha: no`.
  - `plutil -lint apps/ios/App/PrivacyInfo.xcprivacy`: `OK`.
- Unsigned Release Simulator build (`xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build`): `** BUILD SUCCEEDED **` (including `builtin-validationUtility -validate-for-store`).
- Release `SongPhang.app` bundle inspection:
  - `plutil -p .../Release-iphonesimulator/SongPhang.app/Info.plist`: `CFBundleIdentifier = "vn.songphang.app"`, `CFBundleDisplayName = "Sòng Phẳng"`, `CFBundleShortVersionString = "1.0.0"`, `CFBundleVersion = "1"`, `API_BASE_URL = "https://example.invalid/api/v1"`, `WEB_BASE_URL = "https://example.invalid"`, and **no** `NSAppTransportSecurity` (`NO_ATS_IN_RELEASE`).
  - `.../Release-iphonesimulator/SongPhang.app/PrivacyInfo.xcprivacy`: present (`2504` bytes) and `plutil -lint`: `OK`.
  - `.../Release-iphonesimulator/SongPhang.app/Assets.car` + `AppIcon60x60@2x.png` + `AppIcon76x76@2x~ipad.png`: present.
  - `nm -gU .../Release-iphonesimulator/SongPhang.app/SongPhang | grep -i FakeWorld`: empty (`NO_FAKE_WORLD_IN_RELEASE`).
- Version gate live exercise (`MIN_APP_VERSION_IOS=9.9.9` on clean-env local API `:4010`, disposable DB `songphang_phase5_5e1`, Debug `Exercise5E1.app` wrapping `RootView(configuration:)` on `iPhone 17 Pro`):
  - `GET /api/v1/features`: `{"minAppVersion":{"ios":"9.9.9","android":"0.0.0"},...}`.
  - Simulator stdout: `SIM_VERSION_GATE_BLOCKED_OK: isUpgradeRequired=true minIos=9.9.9`.
  - Screenshot verified: `docs/superpowers/runs/phase-5/screens/5e/upgrade-required.png` displays `"Hãy cập nhật Sòng Phẳng để tiếp tục."` + `"Mở App Store"`.
- Repo & Swift gates: `pnpm check` PASS; `xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources` exit 0.
- Security review: checked items 1, 6, 7, 8; Release `Info.plist` contains zero `NSAppTransportSecurity` exceptions, Release binary exports zero `FakeWorld` symbols, `PrivacyInfo.xcprivacy` accurately sets `NSPrivacyTracking = false`, no secrets committed.

### Task 5E.2 — TestFlight runbook, App Store copy and final parity evidence

**Approach**
- Files created/modified: `docs/runbooks/testflight.md`, `apps/ios/Store/listing.vi.md`, `apps/ios/README.md`, `docs/superpowers/runs/phase-5/{parity-matrix,manual-checks,progress}.md`.
- Approach: Inspected `eac8aa7..main` (`9f6cbbe`) to check for any new web journeys or API changes since Phase 5 start; wrote the owner TestFlight runbook (`docs/runbooks/testflight.md`) matching `.env.example`, `apps/api/src/config.ts`, and `apps/api/src/routes/google.ts`; authored the Vietnamese App Store listing and App Privacy summary matching `PrivacyInfo.xcprivacy` (`apps/ios/Store/listing.vi.md`); updated `apps/ios/README.md` with Phase 5 module structure and gate commands; replayed all 7 Phase 5B checkpoint exercises against code revision `93834f6`; ran final automated gates and reconciled `parity-matrix.md` rows `P1-01`..`P5-06`.
- Why this is the simplest approach: Keeps all owner handoff steps, Vietnamese marketing/privacy text, and final simulator/API evidence directly traceable to verified repository files with no extra tooling or scripts added inside the repository.

**Observed results:**
- Baseline delta check (`git log eac8aa7..main --stat`): only `ab2f07b` and `9f6cbbe` modifying `docs/tech-debt.md` (`TD-001`..`TD-007`), zero new API routes, contract fields, or unmapped web user journeys. (`TD-007` confirms `feed.tripTotal` missing in earlier `15e658e` was fixed in `d379b75`; `TD-001`..`TD-006` remain open device/design items tracked on `main` outside Phase 5E.2 scope.)
- Final 5B checkpoint replay (`run-5e2-final-replay.sh` on disposable DB `songphang_phase5_5e2_final`, clean-env API `:4010`, `iPhone 17 Pro` iOS 26.5 Simulator against code revision `93834f6`):
  - `EXERCISE_5E2_SETUP_PASS`
  - `[5E.2] Ex1 PASS: invites cross-routing & LinkRouter`
  - `[5E.2] Ex2 PASS: quick entry & idempotent double-tap (01a20663-6a5d-7972-aa64-b442d5d3312b)`
  - `[5E.2] Ex3 PASS: realtime SSE & balance convergence (+40k/-40k)`
  - `[5E.2] Ex4 PASS: optimistic lock 409 conflict & reload (+50k/-50k)`
  - `[5E.2] Ex5 PASS: soft delete & undo restore`
  - `[5E.2] Ex6 PASS: direct settlement zeroed balances`
  - `[5E.2] Ex7 PASS: snapshot read, web session revocation -> 401, isolated Lan login`
  - `SIM_EXERCISE_5E2_FINAL_PASS`
  - `pnpm --filter @songphang/db exec tsx src/check-balances.ts`: `01a20663-5cc4-75fb-97ff-b458262903f4 Hội cà phê Sài Gòn 5E2: sum 0; mismatches 0`, `01a20663-68b4-7519-89c1-d55656e22995 Chuyến đi Đà Lạt 5E2: sum 0; mismatches 0`, `All groups balanced`.
- Final automated gates (all executed cleanly after documentation/runbook updates):
  - `pnpm check`: PASS (`biome check .` checked 512 files, 0 errors, 3 pre-existing `noImgElement` warnings; all 8 package/app typechecks passed; `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build succeeded across all 14 routes).
  - `./apps/ios/Scripts/check-strings.sh`: PASS (`OK: 670 web keys verified, 0 missing, 0 differing.`).
  - `xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources`: PASS (exit 0).
  - Debug build (`xcodebuild build-for-testing` on `iPhone 17 Pro` `-skipPackagePluginValidation`): `** TEST BUILD SUCCEEDED **`.
  - Unsigned Release build (`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build`): `** BUILD SUCCEEDED **`.
- Parity matrix reconciliation (`docs/superpowers/runs/phase-5/parity-matrix.md`): all Phase 1–5 rows (`P1-01`..`P1-13`, `P2-01`..`P2-09`, `P3-01`..`P3-04`, `P4-01`..`P4-07`, `P5-01`..`P5-06`) verified locally with recorded evidence; zero rows remain `Pending`.
- Security review: checked items 1, 6, 7, 8; `docs/runbooks/testflight.md` keeps zero real keys/secrets and documents non-shipping override for `example.invalid`, `Listing/App Privacy` matches `PrivacyInfo.xcprivacy` (`NSPrivacyTracking = false`, `CA92.1`), no ATS exceptions in Release.

## Review Fixes (Findings 1–10, verified at code SHA `802d30f`)

All 10 findings from the PR `#2` Phase 5 review (`0122a90`) were resolved in focused commits through final code SHA `802d30f97343523bbf2945ecc0d258c42d96a324` (`phase-5`):

| Finding | Severity | Commit | Summary & Verified Evidence |
|---|---|---|---|
| 1 (5B) | P1 | `f5884fd` | Bound iOS `TokenStore` snapshots/requests, `AuthMiddleware`, `LiveAPIEnvironment`, `LiveAuthRepository`, `LiveGroupsRepository`, `LiveAttachmentsRepository`, `LiveFundRepository`, `EventStream`, and `SessionModel` to issuing `tokenGeneration` (discarding delayed `200` and delayed `401` across REST/manual/SSE paths without clearing Account B). Simulator `run-fix1-exercise.sh` -> `SIM_FIX1_SESSION_BINDING_PASS` (delayed 200 `/me`, delayed 401 across `GET /me`, manual `PATCH`, and SSE, plus clean relaunch restoring B only). |
| 2 (5C) | P1 | `4de85f7` | Required fresh, single-use authorization-code exchange on every `POST /api/v1/auth/apple` sign-in (including returning users) and verified returned `sub` matches the verified identity token before storing AES-256-GCM refresh tokens or creating a session (`apps/api/src/{services/apple-sign-in,auth/apple/verify,auth/apple/token-adapter}.ts`). Disposable DB replay `exercise-fix2-apple.mts` -> `EXERCISE_FIX2_APPLE_PASS` (capability-off 404, first sign-in + encrypted `rt-1`, reused code refused 401, `sub` mismatch refused 401 with `rt-1` untouched, returning fresh code -> `rt-2`, `DELETE /me` revocation, fake adapter single-use & `sub=` refusal). |
| 3 (5A) | P2 | `1fc6e43` | Classified adding `requestBody` with `required: true` (or flipping `required` to `true`) on an existing OpenAPI operation as `"breaking"` in `apps/api/src/openapi/diff.ts` while keeping optional `requestBody` and new operations `"additive"`. Replay `exercise-fix3-diff.mts` -> `EXERCISE_FIX3_DIFF_PASS`. |
| 4 (5B) | P2 | `6d15453` | Reconciled cached group snapshots in `SnapshotStore.reconcileGroups` / `LiveGroupsRepository.groups()` on successful authoritative refresh, invalidating in-flight snapshot writes (`groupGenerations`) and purging disk/memory snapshots for removed groups while preserving cache on transport failure. Simulator `run-fix4-exercise.sh` -> `SIM_FIX4_SNAPSHOT_PURGE_PASS`. |
| 5 (5C) | P2 | `0f9498a` | Restored push device registration across sessions when notification permission is already `.authorized` without re-prompting, with `sessionGeneration` checks preventing delayed completions from updating a newer session (`PushCoordinator.swift`, `RootView.swift`). Simulator `run-fix5-exercise.sh` (`PUSH_PROVIDER=console`) -> `SIM_FIX5_PUSH_RESTORE_PASS` (repo + coordinator state; live APNs hardware delivery remains pending). |
| 6 (5D) | P2 | `110fb61` | Preserved `reminderIntervalDays` (`Int?`) on `GET/POST/PATCH` group responses via `ResponseBodyCapture` and `GroupMapping.extractReminderIntervalDays` while keeping `packages/contract/openapi.json` byte-for-byte intact. Simulator `run-fix6-exercise.sh` -> `SIM_FIX6_REMINDER_INTERVAL_PASS` (repo + snapshot + reopened `GroupSettingsModel` verified `7` and `nil`). |
| 7 (5D) | P2 | `fc3b84b` | Extracted `RouteDestination.notificationDestination(for:)` mapping `.transaction` inbox taps to `.transactionDetail` (S20) without skipping viewer read-only / editor permissions. Simulator `run-fix7-exercise.sh` -> `SIM_FIX7_INBOX_TO_S20_PASS` (`RouteDestination` mapping verified for Editor & Viewer, `TransactionDetailModel` `canEdit` & Viewer 403 write refusal checked, and `TransactionDetailView` mounted for Viewer). |
| 8 (5D) | P2 | `a450154` | Subscribed `TransactionDetailModel` / `TransactionDetailView` (S20) to group SSE events (`.task(id: model.transactionId)`) for silent refresh of comments, disputes, and approval decisions plus removal handling (`onRemoved`). Simulator `run-fix8-exercise.sh` (live `NavigationStack { TransactionDetailView }` UI + backend mutations) -> `SIM_FIX8_S20_LIVE_REFRESH_PASS`. |
| 9 (5D) | P2 | `0b088eb` | Added `listGeneration`, `loadMoreTask` tracking/cancellation, and post-await `(listGeneration, filter, cursor)` checks in `GroupFeedModel` so delayed cursor pages cannot overwrite a newly selected filter. Simulator `run-fix9-exercise.sh` (HTTP proxy delaying `.food` cursor 1500ms while switching to `.transport`) -> `SIM_FIX9_PAGINATION_GUARD_PASS` (`GroupFeedModel` + live repo layer). |
| 10 (5E) | P2 | `802d30f` | Wired `APP_STORE_URL` into `Debug.xcconfig`, `Release.xcconfig`, `Info-Debug.plist`, and `App/Info.plist`, validated via `RootView.parseOptionalHTTPURL` (rejecting empty/unexpanded/`$(...)`/non-HTTP(S) values), and documented owner-supplied `https:/$()/...` config in `docs/runbooks/testflight.md`. Bundle inspect + temporary `-xcconfig` Release build + Simulator `run-fix10-version-gate.sh` (`RootView` -> `UpgradeRequiredView` with visually inspected PNG screenshots showing muted disabled CTA when unset and active dark CTA when configured) -> `SIM_FIX10_ALL_PASS`. |

### Final Verification Gates on Code Revision `802d30f97343523bbf2945ecc0d258c42d96a324`

- **Automated static/build/lint gates:**
  - `pnpm check`: PASS (`biome check .` checked 512 files, 0 errors, 3 pre-existing `noImgElement` warnings on web; 8 workspaces typechecked; `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (`apps/web` Next.js 16.4.6 production build across all 14 static/dynamic routes).
  - `pnpm contract:check`: PASS (`OpenAPI contract snapshot is up to date.`).
  - `./apps/ios/Scripts/check-strings.sh`: PASS (`OK: 670 web keys verified, 0 missing, 0 differing.`).
  - `xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources`: PASS (exit 0).
  - `xcodebuild build-for-testing` (`iPhone 17 Pro`, D5 target-level `SWIFT_TREAT_WARNINGS_AS_ERRORS`, `-skipPackagePluginValidation`): `** TEST BUILD SUCCEEDED **`.
  - Unsigned Release build (`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build`): `** BUILD SUCCEEDED **` (`INFOPLIST`: `APP_STORE_URL=""`, `API_BASE_URL="https://example.invalid/api/v1"`, `NO_ATS_IN_RELEASE`, `PrivacyInfo.xcprivacy: OK`, `NO_FAKE_WORLD_IN_RELEASE`); temporary `-xcconfig` Release build with placeholder `https:/$()/apps.apple.com/app/id0000000000` -> `APP_STORE_URL="https://apps.apple.com/app/id0000000000"`, `NO_ATS_IN_RELEASE`, `NO_FAKE_WORLD_IN_RELEASE`, followed by clean default Release rebuild.
- **API regression, transport & role permission matrix (`exercise-final-matrix.mts` + `exercise-fix2-apple.mts` + `exercise-fix3-diff.mts` on disposable DBs & isolated storage):**
  - `FINAL_MATRIX_PASS: cases=66 pushJobs=18` (`songphang_phase5_final_matrix`, local fake Apple adapter, `PUSH_PROVIDER=console`, isolated temp upload dir deleted on exit).
  - Covered routes: `GET /features`, `POST /auth/{register,verify-email,login,token,apple,logout}`, `GET /me`, `GET /me/sessions`, `DELETE /me/sessions/{id}`, `POST /me/devices`, `DELETE /me/devices/{id}`, `GET /me/notifications`, `GET /me/notifications/unread-count`, `POST /me/notifications/read`, `GET/POST /groups`, `GET/PATCH /groups/{id}`, `DELETE /groups/{id}/users/{userId}`, `GET /groups/{id}/events`, `GET/POST /groups/{id}/transactions`, `GET/PATCH /groups/{id}/transactions/{id}`, `POST /transactions/{id}/approve`, `POST /comments`, `POST /dispute`, `POST /dispute/resolve`, `POST /settlement-requests`, `POST /settlement-requests/{id}/confirm`.
  - Covered callers & transports: signed-out (`401`), query-param credential (`400`), revoked Bearer & logged-out session (`401`), Cookie (`Origin` checked `400`/`204`), native Bearer (no `Origin` required, allowed on `POST /me/devices`), mixed Cookie+Bearer (invalid Bearer `401` with no Cookie fallback; valid Bearer takes precedence without Cookie user leakage; foreign `Origin` `400`; `POST /me/devices` refused `403`), outsider (`404` across group endpoints), viewer (`200` reads/SSE, `403` settings/transactions/approve/other-settlement/remove-user, allowed own comment/dispute/own outgoing settlement), editor (`200` create/edit tx, `403` owner settings/approve/resolve-other-dispute/remove-user), owner (`200`/`204` settings, `reminderIntervalDays` `7`/`null`, approve, resolve dispute, remove user -> subsequent `404` for removed user).
  - `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` (per D1 without root `.env`): `All groups balanced` (`sum 0; mismatches 0`).
- **Simulator replays on final `802d30f` objects (`iPhone 17 Pro`, iOS 26.5, disposable DBs & ports `4010`/`4011`):**
  - `run-5e2-final-replay.sh` (`Ex1`–`Ex7` + mounted `GroupFeedView` + `check-balances.ts`) -> `SIM_EXERCISE_5E2_FINAL_PASS` + `All groups balanced`.
  - `run-5d4-exercise.sh` -> `SIM_EXERCISE_5D4_READY` + `All groups balanced` (scratch adaptation: appended `$DD/NotificationsFeature.o` to pre-5D.5 link command).
  - `run-5d5-exercise.sh` -> `SIM_EXERCISE_5D5_READY` + `All groups balanced`.
  - `run-5d6-exercise.sh` -> `SIM_EXERCISE_5D6_READY` + `All groups balanced`.
  - `run-5d7-exercise.sh` -> `SIM_EXERCISE_5D7_READY` + `All groups balanced`.
  - `run-fix1-exercise.sh` -> `SIM_FIX1_SESSION_BINDING_PASS`.
  - `run-fix4-exercise.sh` -> `SIM_FIX4_SNAPSHOT_PURGE_PASS`.
  - `run-fix5-exercise.sh` -> `SIM_FIX5_PUSH_RESTORE_PASS`.
  - `run-fix6-exercise.sh` -> `SIM_FIX6_REMINDER_INTERVAL_PASS`.
  - `run-fix7-exercise.sh` -> `SIM_FIX7_INBOX_TO_S20_PASS`.
  - `run-fix8-exercise.sh` -> `SIM_FIX8_S20_LIVE_REFRESH_PASS`.
  - `run-fix9-exercise.sh` -> `SIM_FIX9_PAGINATION_GUARD_PASS`.
  - `run-fix10-version-gate.sh` -> `SIM_FIX10_ALL_PASS` (`RootView` / `UpgradeRequiredView` absent vs configured UI verified).

## Gate Not Passed

None.

## Not Verified

- **Be Vietnam Pro bundled font assets:** Only `.woff2` web fonts exist in `apps/web/public/fonts/be-vietnam-pro/`; compatible `.ttf`/`.otf` files require owner supply or approved system-font substitution before final acceptance (D2).
- **External providers & owner physical-device checks:** Real SMTP (`TD-002`), Google OAuth, live Apple Sign-In & Apple token revocation (only local fake/adapter verification ran here), live APNs hardware delivery, HTTPS Universal Links, `APP_STORE_URL` tap-through to the App Store on device, physical iPhone camera/VietQR scan/performance, real Telegram Bot API webhook, TestFlight archive/signing/upload, and owner triage/fixes for `TD-001`..`TD-006` (`docs/tech-debt.md`) remain external/device follow-ups. Real AI provider verification remains deferred until all phases including iOS are done.

## Out of Scope

- `packages/db/package.json` scripts (`migrate`, `seed`, `check-balances`) use `tsx --env-file=../../.env`, which exits with code 9 in a clean worktree without `.env`. Bypassed via `pnpm --filter @songphang/db exec tsx src/...` per D1; not modified here.
- Pre-existing owner physical-device findings logged on `main` in `docs/tech-debt.md` (`TD-001`..`TD-006` open; `TD-007` fixed in `d379b75` and awaiting device re-test) were intentionally left untouched outside Phase 5E.2 scope.

## Cubic PR #2 Remediation (verified on phase-5)

Audited all `158` Cubic threads on PR #2 (`56` already resolved, `102` unresolved). Across the `102` unresolved threads: `31` were valid unfixed findings fixed across commits below, `64` were already fixed by earlier remediation commits in `0122a90..166e8ad` (including `packages/core/src/dates.ts` `0001`–`9999` calendar support via `setUTCFullYear` in `c8cd863`), and `7` were declined per approved project rules (`AGENTS.md §6`, Phase 4 DR10, D14, and localhost dev-origin consistency).

**Remediation commits (above `166e8ad`):**
- `fe95576` — `fix(api): resolve OpenAPI ref params, Apple deletion guards, and push worker safety` (`apps/api/src/openapi/diff.ts` `#/components/parameters/` `$ref` resolution, `isAppleDeletionPending` helper in `@songphang/db`, `createGroup` locked-account `401` guard, `APPLE_REVOCATION_COMPLETED:` guard before missing-provider check in `deleteAccount`, `AppleKeySetError` narrowing so unexpected sign-in errors return `500`, idempotent `recordPushDeviceDelivered` containment guard, push worker `gone` delete ordering + sanitized `errorCode` log).
- `50a4aa4` — `fix(ios): harden TokenStore crash-safety, foreground recovery, and Debug web origin` (`TokenStore.clear()` pre-delete tombstone and async actor-safe `Task.sleep` retry, `LiveAPIEnvironment.clearSnapshotsWithoutSession`, `SessionModel` cold-launch recovery flag and `loadSession(fetchFeatures:)`, `PushCoordinator` empty-token guard, `AuthRepository.currentTokenGeneration()`, and `Debug.xcconfig` `WEB_BASE_URL` restored to `http:/$()/localhost:3000`).
- `bb5af0f` — `fix(ios): resolve S20/inbox concurrency races, draft retention, settle lock, and extras l10n` (`TransactionDetailModel` split `transactionGeneration`/`commentsGeneration` + per-mode `defer` + background comment resync, `NotificationsModel` `mutationGeneration` guard in `load()` + `markError = nil` on retry, `ApprovalCardView` `PendingAction` draft preservation, `SettleModel`/`SettleView` `isSubmitting` form lock + key stability, `ActivitySentenceFormatter` `receipts.extrasKinds.*` localization).
- `bb38e48` — `fix(ios): align PreviewSupport fakes with live API and TripScenario` (`FakeWorld+ChatLinks` `400 TOKEN_INVALID`, `FakeWorld+Payments` activity insertion on `.confirm`, `FakeWorld` `"Đà Lạt 3N2Đ"` + `Money(120_000)` notification share alignment).
- Documentation closeout commit (this commit) — `README.md` (`PUSH_PROVIDER=apns` note and 64-hex `sha256` nonce wording), `apps/ios/Store/listing.vi.md` (D11 subtitle deviation note), `docs/superpowers/runs/phase-5/decisions.md` (D12 `LedgerFields` / `CommonLedgerFields` wording), `docs/superpowers/runs/phase-5/handoff-5b.md` (trailing whitespace cleanup), and this evidence section.

**Observed verification outputs:**
- Backend / DB / OpenAPI exercise (disposable DB `songphang_phase5_cubic_verify`): `OPENAPI_REF_PARAM_PASS`, `DELETE_COMPLETED_WITHOUT_PROVIDER_PASS`, `CREATE_GROUP_DELETED_USER_401_PASS`, `APPLE_SIGNIN_ERROR_NARROWING_PASS`, `PUSH_RECORD_IDEMPOTENT_PASS`, `PUSH_WORKER_SANITIZED_LOG_AND_GONE_PASS`; `check-balances.ts` -> `All groups balanced` (disposable DB dropped after run).
- Booted `iPhone 17 Pro` Simulator (`iOS 26.5`, `607AC652-2E92-4BE7-BA18-1B888D79684B`) Swift exercises:
  - `exercise_cubic_ios`: `LINK_ROUTER_LOCALHOST_PASS`, `SESSION_MODEL_FOREGROUND_RECOVERY_PASS`, `PUSH_COORDINATOR_EMPTY_TOKEN_GUARD_PASS`, `S20_COMMENTS_CONCURRENCY_PASS`, `NOTIFICATIONS_MODEL_RACE_AND_ERROR_PASS`, `ACTIVITY_EXTRAS_L10N_PASS: Lẩu 100.000 (Minh) · Thuế 10.000`, `FAKE_WORLD_PARITY_PASS`, `LIVE_AUTH_NO_SPURIOUS_INVALIDATION_PASS`, `SETTLE_MODEL_SUBMIT_LOCK_PASS`, `ALL_CUBIC_IOS_EXERCISES_PASS`.
  - `exercise_tokenstore`: `TOKENSTORE_TOMBSTONE_FALLBACK_PASS`, `TOKENSTORE_ASYNC_READ_PASS`.
- Workspace & iOS build/static gates:
  - `pnpm check`: PASS (`biome check .` checked `516` files with 3 pre-existing `noImgElement` warnings; 8 workspace `tsc --noEmit` checks passed; `pnpm contract:check` -> `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: PASS (`apps/web` Next.js `16.4.6` production build compiled 14 routes).
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 670 web keys verified, 0 missing, 0 differing.`
  - `xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources`: PASS (exit 0).
  - Debug Simulator build (`xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'platform=iOS Simulator,id=607AC652-2E92-4BE7-BA18-1B888D79684B' -configuration Debug -skipPackagePluginValidation build`): `** BUILD SUCCEEDED **`.
  - Unsigned Release Simulator build (`-configuration Release -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build`): `** BUILD SUCCEEDED **`; Release bundle audit: `NO_ATS_CHECK=0`, `PrivacyInfo.xcprivacy: OK`, `FAKE_WORLD_COUNT=0`.
- Security review: checked relevant items in `.agents/skills/security-review/SKILL.md` across `166e8ad..HEAD` (`createGroup` `401` missing-account guard, `isAppleDeletionPending` across Apple sign-in/ownership/group creation, `APPLE_REVOCATION_COMPLETED:` ordering, `AppleKeySetError` narrowing without masking internal faults as `503`, `LiveAPIEnvironment.clearSnapshotsWithoutSession`, parameterized Drizzle JSONB `@>` check, sanitized push worker `errorCode` regex without logging raw `error.message` or tokens, Release bundle free of ATS exceptions and `FakeWorld`, zero changes to `packages/contract`, migrations, or dependencies).

**Follow-up remediation on `19ed24d` (9 Cubic threads: 8 fixed, 1 declined stale):**
- **Fixes:** `apps/api/src/openapi/diff.ts` (OpenAPI 3.1 `$ref` sibling `description`-only override handling, deduplicated unchanged component-parameter comparisons on operations, and explicit `reference "<$ref>"` labels on dangling parameter removals), `packages/db/src/apple-accounts.ts` & `apps/api/src/services/password-recovery.ts` (shared `APPLE_REVOKING_PREFIX` / `APPLE_REVOCATION_COMPLETED_PREFIX` constants), `apps/ios/SongPhangKit/Sources/GroupsFeature/GroupSettings/ApprovalCardView.swift` (disabled `SPTextField` while pending and preserved in-flight draft edits when confirmed threshold != current input), `apps/ios/SongPhangKit/Sources/LedgerFeature/TransactionDetail/TransactionDetailModel.swift` (cleared `isPerformingAction` before scheduling background `scheduleCommentsResync()`, cancelled resync task on `load()`, and required all three generation counters to match in `refreshSilently` error handling), and `docs/superpowers/runs/phase-5/handoff-5b.md` (blank-line separation between Owner signature and Date).
- **Declined:** `4667491240` (`progress.md`) was a stale report queued while `19ed24d` review started (`14:46:28Z`) before all `158` prior threads finished resolving (`14:52:27Z`); all `158` prior threads have explicit database IDs and are resolved.
- **Re-verified outputs:** disposable DB `songphang_phase5_cubic_verify2` (`OPENAPI_REF_PARAM_PASS` including shared parameter deduplication, 3.1/3.0 `$ref` sibling rules, and dangling `$ref` label; `APPLE_REVOKING_PREFIX`/`APPLE_REVOCATION_COMPLETED_PREFIX`; `check-balances.ts` -> `All groups balanced`, DB dropped), `pnpm check` PASS, `pnpm build` PASS (14 routes), `./apps/ios/Scripts/check-strings.sh` (`670` keys, 0 missing/differing), `xcrun swift-format lint --strict` PASS, Debug & unsigned Release `xcodebuild -skipPackagePluginValidation` `** BUILD SUCCEEDED **`, Release bundle audit (`NO_ATS_CHECK=0`, `PrivacyInfo.xcprivacy: OK`, `FAKE_WORLD_COUNT=0`), and booted `iPhone 17 Pro` Simulator `exercise_cubic_ios` (`S20_COMMENTS_CONCURRENCY_PASS` including `!isPerformingAction` after `addComment` and stale `refreshSilently` unauthorized guard, `ALL_CUBIC_IOS_EXERCISES_PASS`).

## Full-Branch Pre-Merge Review Remediation

- **Fixes:**
  - `packages/db/src/users.ts` (`USER_COLUMNS.hasPassword`): qualified `${userIdentities}."user_id" = ${users}."id"` so single-table queries (`findUserById`, `listUsers`) evaluate against `"users"."id"` rather than `"user_identities"."id"` inside the `EXISTS` subquery (resolving `hasPassword: false` on `POST /api/v1/auth/token`, `/exchange`, and `/apple`).
  - `apps/ios/SongPhangKit/Sources/Repositories/Auth/{GoogleAuthCoordinator,AppleAuthCoordinator}.swift`: retained `ASWebAuthenticationSession` strongly inside `@MainActor SessionHolder` with a one-shot `finish(_:)` continuation guard and weak capture; also retained `ASAuthorizationController` inside `AppleAuthCoordinator.Delegate` and cleared it on completion.
  - `apps/ios/SongPhangKit/Sources/AppShell/{Debug/DebugGalleryView.swift,Route.swift,RouteDestination.swift,RootView.swift}`: gated `DebugGalleryView`, `Route.debugGallery`, `UIWindow.motionEnded` / `SPDeviceDidShakeNotification`, `isShowingDebugPanel`, and `--gallery-*` launch arguments under `#if DEBUG`, and changed `RootView.bundleConfiguration()` non-Debug fallback URLs to `https://example.invalid/api/v1` and `https://example.invalid`.
  - `apps/ios/App/Info.plist`, `apps/ios/Config/Info-Debug.plist`, & `apps/ios/App/SongPhangApp.swift`: restored Spec §5.3 strings (`NSCameraUsageDescription` = `"Sòng Phẳng dùng máy ảnh để chụp hoá đơn."`, `NSPhotoLibraryUsageDescription` = `"Sòng Phẳng cần ảnh bạn chọn để đính kèm hoá đơn."`) and updated `Logger(subsystem: "vn.songphang.app", category: "Push")`.
  - `docs/superpowers/runs/phase-5/manual-checks.md`: aligned local startup `WEB_ORIGIN` and `next dev --hostname` with `http://localhost:3000` (matching `Debug.xcconfig`, `.env.example`, and `README.md`).
- **Observed verification outputs:**
  - Drizzle `toSQL()` check: both single-table and joined `USER_COLUMNS` selects emit `"user_identities"."user_id" = "users"."id"`.
  - Live HTTP + DB smoke test on disposable DB `songphang_phase5_smoke_final` (`APP_ENV=development`, `MIN_APP_VERSION_IOS=1.0.0`, `PUSH_PROVIDER=console`): `LIVE_API_REVIEW_SMOKE_PASS` (verified `hasPassword: true` on `POST /api/v1/auth/token` and `GET /api/v1/me`, `GET /api/v1/features` returning `minAppVersion.ios: "1.0.0"` and `push: true`, `/me/sessions`, `/me/devices`, `/me/push-settings`, group + `100001` VND equal split transaction `201`, outsider `404` checks, `/auth/apple` `404`, `/auth/exchange` `400`, `/auth/logout` `204` -> `401`) and `check-balances.ts` -> `All groups balanced` (`sum 0; mismatches 0`).
  - Static/build gates after final code edits: `pnpm check` PASS (`516` Biome files with 3 pre-existing `noImgElement` warnings, 8 workspace typechecks, `OpenAPI contract snapshot is up to date.`), `pnpm build` PASS (14 Next.js routes), `./apps/ios/Scripts/check-strings.sh` PASS (`670` keys, 0 missing/differing), `xcrun swift-format lint --strict --recursive apps/ios` PASS, `plutil -lint` PASS, `git diff --check main...HEAD` PASS.
  - Xcode Simulator Debug (`iPhone 17 Pro`, `-skipPackagePluginValidation`) and unsigned Release (`generic/platform=iOS Simulator`, `CODE_SIGNING_ALLOWED=NO`, `-skipPackagePluginValidation`) builds: both `** BUILD SUCCEEDED **`. Release bundle audit: `RELEASE_LEAK_MATCH_COUNT=0` (zero matches for `FakeWorld`, `DebugGalleryView`, `isShowingDebugPanel`, `SPDeviceDidShakeNotification`, `--gallery-`, `127.0.0.1`, `localhost:3000`), `Info.plist` free of `NSAppTransportSecurity` with `https://example.invalid` defaults and Spec §5.3 permission strings, `PrivacyInfo.xcprivacy: OK`.
- **Security review:** Verified relevant items in `.agents/skills/security-review/SKILL.md`: SQL identifiers in `USER_COLUMNS.hasPassword` remain static with no user interpolation, Release binary contains zero debug screens/flags/localhost HTTP URLs/ATS exceptions, cross-user resource ownership isolation returned `404` in live HTTP testing, and no secrets, pragmas, or unsafe constructs exist in the diff.
- **Out of scope:** `packages/db/src/members.ts:7` uses a similar unqualified `${members.id}` in `MEMBER_COLUMNS.claimed` (safe currently only because `group_users` has no `id` column; untouched as pre-Phase-5 code).
