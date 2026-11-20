# Phase 5 — Run Progress

- Branch: `phase-5`
- Approved design: `d40c649`
- Approved plan and branch base: `eac8aa7`
- Implementation: Antigravity
- Advisor and reviewer: Codex
- Status: Stage 5B in progress (5B.4 complete; continuing to 5B.5). Owner checkpoint, final acceptance and merge are pending.

## Tasks

- [x] 0 — Re-baseline and parity inventory
- [x] 5A.1 — OpenAPI snapshot and minimum version
- [x] 5A.2 — Native password sessions and revocation
- [x] 5A.3 — API gate
- [x] 5B.1 — Generated client and live composition
- [x] 5B.2 — Account lifecycle and snapshots
- [x] 5B.3 — Groups, members and local invite routing
- [x] 5B.4 — Ledger and realtime
- [ ] 5B.5 — Early iOS/web Simulator acceptance and owner handoff
- [ ] 5C.1 — Native Google exchange
- [ ] 5C.2 — Apple sign-in and revocation
- [ ] 5C.3 — Push device registration and preferences
- [ ] 5C.4 — Push delivery worker
- [ ] 5C.5 — Native push registration and routing
- [ ] 5C.6 — Associated domains and gate
- [ ] 5D.1 — Payments and settlement requests
- [ ] 5D.2 — Search, categories, statistics and CSV
- [ ] 5D.3 — Funds and budgets
- [ ] 5D.4 — Receipts, item splits and assisted entry
- [ ] 5D.5 — Notification center and reminders
- [ ] 5D.6 — Detail, discussion, disputes and approval
- [ ] 5D.7 — Telegram and parity gate
- [ ] 5E.1 — Release metadata and assets
- [ ] 5E.2 — Final parity evidence and owner handoff

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

## Gate Not Passed

None.

## Not Verified

- **Be Vietnam Pro bundled font assets:** Only `.woff2` web fonts exist in `apps/web/public/fonts/be-vietnam-pro/`; compatible `.ttf`/`.otf` files require owner supply or approved system-font substitution before final acceptance (D2).
- **External providers:** Real SMTP, Google OAuth, Apple Sign-In, APNs, Telegram Bot API, HTTPS Universal Links, physical iPhone performance/camera/QR scan, and TestFlight upload remain external/owner checks. Real AI provider verification remains deferred until all phases including iOS are done.

## Out of Scope

- `packages/db/package.json` scripts (`migrate`, `seed`, `check-balances`) use `tsx --env-file=../../.env`, which exits with code 9 in a clean worktree without `.env`. Bypassed via `pnpm --filter @songphang/db exec tsx src/...` per D1; not modified here.
