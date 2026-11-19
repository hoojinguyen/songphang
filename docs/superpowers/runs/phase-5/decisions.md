# Phase 5 — Run Decisions

## Owner Decisions

- On 2026-11-19 the owner approved the revised Phase 5 design (`d40c649`) and implementation plan (`eac8aa7`), including the 5B Simulator checkpoint and final web parity.
- Antigravity implements. Codex advises and reviews. The owner records acceptance and decides merge.
- Real AI provider verification remains deferred until all phases, including iOS, are done.

## Re-baseline

### Baseline Revisions & Earlier Phases

- Starting `main` SHA: `eac8aa70c730c6e3a148321377b2f1f8dd078456` (`docs(ios): plan Phase 5 integration and acceptance`)
- Phase 4 merge SHA on `main`: `22a16fb` (`Merge pull request #1: Phase 4 collaboration`)
- Phase 5 branch base / handoff HEAD at Task 0 start: `4c4570ccfcf36d202dd8e4ce1b548263dbcfba91` (`docs(phase-5): prepare Antigravity implementation handoff`)
- 5U web reference commit: `bb1e0432fef6f1ceb4cf2ee960948129210626b2` (`feat(phase-1): complete core expense splitting`)
- Earlier phases merged on `main`: Phase 1 (`docs/superpowers/runs/phase-1/`), Phase 2 (`phase-2/`), Phase 3 (`phase-3/`), Phase 4 (`phase-4/`), and 5U interface (`ios-ui/`). No phase is skipped; all Phase 1–4 journeys are in scope for final parity.
- Live route set on baseline: **99 Hono routes** (96 OpenAPI operations including 2 dev-only routes `/api/v1/dev/users` and `/api/v1/dev/login`, plus 3 plain Hono routes: `POST /api/v1/notifications/unsubscribe`, `POST /api/v1/bots/telegram/webhook`, `GET /api/v1/openapi.json`).

### Plan File References vs Actual Repository

| Plan reference | Real location / status | Notes & Task Adjustment |
|---|---|---|
| `apps/api/src/routes/account-auth.ts` (5A.2) | Present (`apps/api/src/routes/account-auth.ts`) | Handles `/auth/register`, `/auth/login`, `/auth/verify-email`, `/auth/resend-verification`, `/auth/providers` |
| `apps/api/src/routes/auth.ts` (5A.2) | Present (`apps/api/src/routes/auth.ts`) | Registers account-auth, password-recovery, and `/auth/logout` |
| `apps/api/src/routes/me.ts` (5A.2, 5C.3) | Present (`apps/api/src/routes/me.ts`) | Handles `GET /me`, `DELETE /me` |
| `apps/api/src/routes/mobile-auth.ts` (5A.2, 5C.1, 5C.2) | Missing (new in 5A.2) | Create in 5A.2 for `/auth/token`, extend in 5C.1 (`/auth/exchange`) & 5C.2 (`/auth/apple`) |
| `apps/api/src/routes/features.ts` (5A.1, 5C.2, 5C.3) | Present (`apps/api/src/routes/features.ts`) | Currently returns `{ receiptReading, sentenceAi, telegram, push, appleSignIn, errorAlerts }` |
| `apps/api/src/routes/google.ts` (5C.1) | Present (`apps/api/src/routes/google.ts`) | Existing Google OAuth web flow |
| `apps/api/src/auth/sessions.ts` & `middleware.ts` (5A.2) | Present | Already extracts `Bearer` token in `requireUser`; `requireSameOrigin` currently checks `Origin` header uniformly for any caller |
| `apps/api/src/services/accounts.ts` (5A.2, 5C.2) | Present | Contains `authenticateUser`, `registerUser`, `deleteAccount`, etc. |
| `packages/db/src/schema.ts`, `schema-accounts.ts`, `sessions.ts` (5A.2, 5C.1–5C.3) | Present | Sessions table lives in `packages/db/src/schema.ts`; `user_identities` & `auth_tokens` live in `packages/db/src/schema-accounts.ts` |
| `packages/core/src/notification-text.ts` (5C.4) | Check at 5C.4 (`apps/worker/src/mail-templates.ts` / `packages/core/src/`) | If `packages/core/src/notification-text.ts` is missing, extract shared inbox wording helper in 5C.4 and record decision |
| `packages/contract/openapi.json` (5A.1) | Missing (new in 5A.1) | Generated deterministically by `pnpm contract:write` and verified by `pnpm contract:check` |
| `apps/ios/SongPhangKit/Package.swift` (5B.1) | Present | Swift tools 6.2, `.iOS(.v26)`, Swift 6 mode, warnings as errors, 5 upcoming features, 8 targets (`Domain`, `DesignSystem`, `PreviewSupport`, `AuthFeature`, `GroupsFeature`, `LedgerFeature`, `AccountFeature`, `AppShell`); `GeneratedAPI` and `Repositories` added in 5B.1 |
| `apps/ios/App/SongPhang.entitlements` (5C.2, 5C.5, 5C.6, 5E.1) | Missing (new in 5C.2) | Create and wire `CODE_SIGN_ENTITLEMENTS` in `SongPhang.xcodeproj` when Apple Sign-In / Push / Associated Domains are added |
| `apps/ios/App/PrivacyInfo.xcprivacy` (5E.1) | Missing (new in 5E.1) | Create in 5E.1 |
| `apps/web/public/fonts/be-vietnam-pro/` | Only `.woff2` files present | No `.ttf`/`.otf` files in repo; system font remains fallback (see D2) |
| `apps/ios/Scripts/check-strings.sh` | Present | Reports 273 missing Phase 2–4 web keys and 0 differing Phase 1 keys on baseline |

### 5U (`bb1e0432`) to Baseline (`eac8aa7`) Drift & Swift Domain Reconciliation

Diffing `bb1e0432fef6f1ceb4cf2ee960948129210626b2..eac8aa7` across `packages/contract`, `apps/api/src/routes`, and `apps/web/src/{app,components,messages}` shows all Phase 2, Phase 3, and Phase 4 additions landed after 5U:

| Swift Domain Type / Protocol (5U) | Baseline Registered Route(s) & Contract | Concrete Differences to Reconcile | Owning Stage |
|---|---|---|---|
| `ServerFeatures` + `AuthRepository.serverFeatures()` | `GET /api/v1/features` + `GET /api/v1/auth/providers` | Baseline splits flags: `/features` has `{ receiptReading, sentenceAi, telegram, push, appleSignIn, errorAlerts }` (+ `minAppVersion` in 5A.1), while `/auth/providers` has `{ google, devLogin }`. `Repositories` fetches both and combines into `ServerFeatures` (extended with `push`, `receiptReading`, `sentenceAi`, `telegram`). | 5A.1 / 5B.2 |
| `AuthRepository` (`signIn`, `signOut`, etc.) | `POST /auth/token`, `GET /me`, `POST /auth/register`, `POST /auth/resend-verification`, `POST /auth/forgot-password`, `POST /auth/change-password`, `POST /auth/logout`, `DELETE /me`, `GET /me/sessions`, `DELETE /me/sessions/{id}` | Add `sessions()` and `revokeSession(id:)` in 5B.2. Parameterize/adapt Google & Apple sign-in methods in 5C.1–5C.2. Add `hidePushContent` / push settings in 5C.3 & 5C.5. | 5A.2 / 5B.2 / 5C |
| `ExpenseGroup` & `GroupsRepository` | `GET/POST /groups`, `GET/PATCH/DELETE /groups/{groupId}` | `GroupDto` gained Phase 4 fields: `reminderIntervalDays`, `approvalThreshold`, `ownerName`, `muted`. Preserve defaults during 5B and wire UI controls in 5D.5/5D.6. | 5B.3 / 5D.5 / 5D.6 |
| `Member` & `MembersRepository` | `GET/POST /groups/{groupId}/members`, `PATCH/DELETE .../members/{memberId}`, `GET/PATCH/DELETE .../users`, `PUT .../me/member`, `POST .../transfer-ownership`, `POST .../leave` | `MemberDto` gained `kind` (`"person" \| "fund"`), `fundHolderMemberId`, `shape` (`"fund"`), `color` (`"sun"`), and `paymentMethods` (`PaymentMethodDto[]`). Map safely with fallbacks in 5B.3; surface payment details & fund UI in 5D.1/5D.3. | 5B.3 / 5D.1 / 5D.3 |
| `InvitesRepository` | `GET/PATCH /groups/{groupId}/invite`, `POST .../invite/rotate`, `GET /invites/{token}`, `POST /invites/{token}/join` | Matches 1:1 (`JoinRequest` uses `{ memberId }` or `{ newMemberName }`). | 5B.3 |
| `LedgerTransaction`, `SplitSpec`, `SharePreview`, `TransactionsRepository` | `GET/POST /groups/{groupId}/transactions`, `GET/PATCH/DELETE .../transactions/{id}`, `POST .../restore`, `POST .../preview` | `TransactionDto`/`TransactionListItemDto` gained `categoryId`, `commentCount`, `dispute`, `approval`, `attachments`/`attachmentCount`; `SplitInput` gained `"items"`; `TransactionResponse` and `PreviewTransactionResponse` gained `warnings`; `GET /transactions` gained search/filter query params (`q`, `memberId`, `category`, `categoryId`, `uncategorized`, `spendingOnly`, `type`, `from`, `to`). Map safely in 5B.4 (preserving server approval status & unknown/items split fallback); full UI arrives in 5D.2/5D.4/5D.6. | 5B.4 / 5D.2 / 5D.4 / 5D.6 |
| `QuickEntryReading` & `QuickEntryRepository` | `POST /groups/{groupId}/transactions/parse` | `ParseRequest` gained `ai?: boolean` (default `false`); `ParseResponse` gained `reader` (`"rules" \| "ai"`), `moreDrafts`, `categoryId`, and `FUND_CANNOT_SHARE` issue code. Map safely in 5B.4; AI opt-in & multi-draft UI in 5D.4. | 5B.4 / 5D.4 |
| `GroupBalances` & `BalancesRepository` | `GET /groups/{groupId}/balances` | Transfers gained `payTo`, `purpose`, `pendingRequest`; response gained `fund`. Map safely in 5B.4; payment/settlement-request/fund UI arrives in 5D.1/5D.3. | 5B.4 / 5D.1 / 5D.3 |
| `ActivityItem` & `ActivityRepository` | `GET /groups/{groupId}/activity` | Added Phase 4 activity actions (`dispute_open`, `dispute_resolve`, `approve`, `reject`, etc.). Unknown actions render safely; full strings arrive in 5D. | 5B.4 / 5D.6 |
| `GroupEvent` & `GroupEventsRepository` | `GET /groups/{groupId}/events` | SSE emits `changed` (`resources` now includes `comments`, `disputes`, `settlements`, `fund`, `budget`, `categories`, `notifications`, etc.) and `removed`. Ignore unknown resource names safely in 5B.4; consume Phase 2–4 resources in 5D. | 5B.4 / 5D |
| New Phase 2–4 & 5C API areas (not in 5U) | `payment-methods`, `settlement-requests`, `categories`, `stats`, `export.csv`, `fund`, `budget`, `attachments`, `receipt-scans`, `items/preview`, `comments`, `dispute`, `approve`/`reject`, `notifications`, `notification-settings`, `me/muted`, `reminders`, `chat-links`, `chat-identities`, `telegram/pairings`, `me/devices`, `me/push-settings` | Added in 5C (`DevicesRepository`) and 5D (`PaymentsFeature`, `StatisticsFeature`, `NotificationsFeature`, `LedgerFeature` extensions, `AccountFeature` extensions). | 5C / 5D |

## Implementation Decisions

### D1 — Clean-environment database CLI execution without worktree `.env` (Task 0)
- **Problem:** The root scripts `pnpm db:migrate`, `pnpm db:seed`, and `pnpm db:check-balances` pass `--env-file=../../.env` to `tsx`. In a fresh worktree without a committed `.env` file, those wrapper scripts exit with code 9 (`node: ../../.env: not found`) even when `DATABASE_URL` is provided in the environment.
- **Options:** (1) Create a `.env` file in the worktree; (2) Bypass the `.env`-loading wrapper scripts by running `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/{migrate,seed,check-balances}.ts`, matching the Task 0 pattern used for API and worker.
- **Choice:** Option 2.
- **Reason:** Keeps the worktree free of untracked `.env` files, guarantees strict isolation with no accidental fallback to a developer's primary database, and aligns with Task 0's clean-environment startup recipe.

### D2 — Be Vietnam Pro font availability for iOS (Task 0)
- **Problem:** Phase 5 design §5.1 requires bundling Be Vietnam Pro in the final app from compatible local font files (`.ttf`/`.otf`), or flagging missing files for owner-provided assets / approved substitution before final review.
- **Options:** (1) Download `.ttf` files from the network (forbidden by phase-run rules); (2) Keep the 5U iOS system font (`Font.system`) with Dynamic Type styles, flag the missing `.ttf`/`.otf` assets explicitly in `progress.md` / `manual-checks.md`, and continue independent implementation.
- **Choice:** Option 2.
- **Reason:** Inspection of `apps/web/public/fonts/be-vietnam-pro/` confirms only `.woff2` files exist, which CoreText/iOS cannot register as bundle fonts, and network downloads are prohibited. Owner action is flagged for final review before 5E archival.

### D3 — Exclude generated `packages/contract/openapi.json` from Biome formatter (Task 5A.1)
- **Problem:** `biome check .` flags array-wrapping differences on the generated `packages/contract/openapi.json` produced by `JSON.stringify(doc, null, "\t")`.
- **Options:** (1) Invoke `biome format` inside `contract:write`/`contract:check`; (2) Exclude `!!packages/contract/openapi.json` in `biome.json` because `pnpm contract:check` (already part of `pnpm check`) enforces byte-for-byte determinism of that generated artifact.
- **Choice:** Option 2.
- **Reason:** Keeps `contract:write` and `contract:check` completely self-contained and fast without spawning Biome, mirrors `!!apps/ios` in `biome.json`, and preserves deterministic byte-identical snapshots enforced by `pnpm check`.

### D4 — Upcoming-feature flags on `GeneratedAPI` target (Task 5B.1)
- **Problem:** Apple's `swift-openapi-generator` (`1.14.4`) emits Swift 6 code without `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, or `InferIsolatedConformances` annotations.
- **Options:** (1) Enable all five upcoming features on `GeneratedAPI` (fails compilation on generated Swift); (2) Per architecture design §11, drop those upcoming-feature flags on `GeneratedAPI` only while keeping `.swiftLanguageMode(.v6)` and `.treatAllWarnings(as: .error)`, and keeping all five upcoming-feature flags on every hand-written target (`Domain`, `Repositories`, `DesignSystem`, `PreviewSupport`, feature targets, `AppShell`).
- **Choice:** Option 2.
- **Reason:** Explicitly permitted by AD §11; preserves strict Swift 6 + warnings-as-errors across `GeneratedAPI` and all hand-written modules without modifying generated code.

### D5 — Xcode 27.2 warnings-as-errors with remote SwiftPM packages (Task 5B.1)
- **Problem:** Passing `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` as a global `xcodebuild` command-line override conflicts with Xcode 27.2's automatic `-suppress-warnings` flag on remote SwiftPM dependencies (`swift-collections`, `swift-http-types`): `error: Conflicting options '-warnings-as-errors' and '-suppress-warnings'`.
- **Options:** (1) Remove warnings-as-errors; (2) Keep `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` on the `SongPhang` Xcode target (`project.pbxproj`) and `.treatAllWarnings(as: .error)` on every target in `SongPhangKit/Package.swift`, and run `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination '...' -skipPackagePluginValidation build` without overriding remote SwiftPM targets.
- **Choice:** Option 2.
- **Reason:** Every single target in `SongPhang` and `SongPhangKit` (including `GeneratedAPI` and `Repositories`) is still compiled with `-warnings-as-errors` enforced by Xcode/SwiftPM, while Apple's remote dependencies compile cleanly.

### D6 — Debug-only ATS local networking via `Config/Info-Debug.plist` (Task 5B.1)
- **Problem:** Phase 5 design §7.1 requires local HTTP (`NSAllowsLocalNetworking`) only in Debug and never in Release, while `App/Info.plist` is shared unless overridden per configuration.
- **Options:** (1) Add `NSAllowsLocalNetworking` to `App/Info.plist` (leaks into Release); (2) Point the Debug target configuration to `Config/Info-Debug.plist` (outside `App/` so it is never bundled as a resource in Release) with `NSAllowsLocalNetworking = true` and keep `App/Info.plist` for Release with zero ATS exceptions.
- **Choice:** Option 2.
- **Reason:** Guarantees strict Debug/Release separation verified by inspecting the Release bundle's `Info.plist`.

## Standing Documentation Follow-ups

- Codex reconciles the approved design §9 changes (`docs/04-adr.md` ADR-014/029/030/032, `docs/05-api-spec.md`, `docs/05-database-design.md`, `docs/03-srs.md`, root `AGENTS.md`) with the reviewed implementation before merge.
- Note for advisor: `packages/db/package.json` scripts (`migrate`, `seed`, `check-balances`) use `--env-file=../../.env` instead of `--env-file-if-exists`, causing clean worktrees without `.env` to require `pnpm --filter @songphang/db exec tsx src/...`. Recorded as out-of-scope observation.
