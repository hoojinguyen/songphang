# Phase 5 — Run Progress

- Branch: `phase-5`
- Approved design: `d40c649`
- Approved plan and branch base: `eac8aa7`
- Implementation: Antigravity
- Advisor and reviewer: Codex
- Status: Task 0 complete; continuing to Stage 5A. Owner checkpoint, final acceptance and merge are pending.

## Tasks

- [x] 0 — Re-baseline and parity inventory
- [x] 5A.1 — OpenAPI snapshot and minimum version
- [x] 5A.2 — Native password sessions and revocation
- [ ] 5A.3 — API gate
- [ ] 5B.1 — Generated client and live composition
- [ ] 5B.2 — Account lifecycle and snapshots
- [ ] 5B.3 — Groups, members and local invite routing
- [ ] 5B.4 — Ledger and realtime
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

## Gate Not Passed

None.

## Not Verified

- **Be Vietnam Pro bundled font assets:** Only `.woff2` web fonts exist in `apps/web/public/fonts/be-vietnam-pro/`; compatible `.ttf`/`.otf` files require owner supply or approved system-font substitution before final acceptance (D2).
- **External providers:** Real SMTP, Google OAuth, Apple Sign-In, APNs, Telegram Bot API, HTTPS Universal Links, physical iPhone performance/camera/QR scan, and TestFlight upload remain external/owner checks. Real AI provider verification remains deferred until all phases including iOS are done.

## Out of Scope

- `packages/db/package.json` scripts (`migrate`, `seed`, `check-balances`) use `tsx --env-file=../../.env`, which exits with code 9 in a clean worktree without `.env`. Bypassed via `pnpm --filter @songphang/db exec tsx src/...` per D1; not modified here.
