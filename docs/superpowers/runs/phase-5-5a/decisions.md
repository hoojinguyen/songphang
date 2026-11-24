# Wave 5.5A — Run Decisions

- Branch: `phase-5-5a` (implementation share branch: `swarm-api-backend-bd62656b` from `33fe552`)
- Baseline `main`: `fbc0b7a` (`378df4d`, PR #2)
- Approved specs & plan commit: `7f4f782`
- Earlier phases on `main`: Phase 1 (`phase-1`), Phase 2 (`phase-2`), Phase 3 (`phase-3`), Phase 4 (`phase-4`), 5U (`ios-ui`), Phase 5 (`phase-5`).

## Re-baseline

| Plan reference | Actual repository location | Status |
|---|---|---|
| `packages/db/src/schema-groups.ts` (5.5A.1.1) | `packages/db/src/schema-groups.ts` | Present |
| `packages/db/src/groups.ts` (5.5A.1.1, 5.5A.1.2) | `packages/db/src/groups.ts` | Present |
| `packages/contract/src/error.ts` (5.5A.1.1) | `packages/contract/src/error.ts` | Present |
| `packages/contract/src/group.ts` (5.5A.1.2) | `packages/contract/src/group.ts` | Present |
| `packages/contract/src/transaction.ts`, `index.ts`, `openapi.json` (5.5A.1.3) | `packages/contract/src/{transaction,index}.ts`, `packages/contract/openapi.json` | Present |
| `packages/db/src/{members,payment-methods,categories,transactions}.ts` (5.5A.1.2–1.3) | `packages/db/src/{members,payment-methods,categories,transactions}.ts` | Present |
| `apps/api/src/services/*.ts` & `apps/api/src/routes/{groups,me}.ts` (5.5A.1.1–1.3) | `apps/api/src/services/*.ts` & `apps/api/src/routes/{groups,me}.ts` (plus `apps/api/src/bot/` for Telegram webhook draft/callback writes) | Present |
| `apps/api/src/openapi/cli.ts` (5.5A.1.3) | `apps/api/src/openapi/cli.ts` | Present |
| `apps/web/src/app/{globals.css,layout.tsx}` & `apps/web/next.config.ts` (5.5A.2.1) | `apps/web/src/app/{globals.css,layout.tsx}` & `apps/web/next.config.ts` | Present |
| `apps/web/src/lib/money.ts` & `apps/web/src/messages/vi.ts` (5.5A.2.1–2.2) | `apps/web/src/lib/money.ts` & `apps/web/src/messages/vi.ts` | Present |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` (5.5A.0, 5.5A.2.2) | Missing on `33fe552` (`apps/web/public/fonts/be-vietnam-pro/` holds `.woff2` + `LICENSE.txt` only) | Deferred to `@design-system` in `5.5A.2.2` |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` (5.5A.2.2) | `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | Present |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/{Tokens,Typography}.swift` (5.5A.2.2) | `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/{Tokens,Typography}.swift` | Present |
| `apps/ios/SongPhangKit/Sources/Domain/AppError.swift` (5.5A.3.1) | `apps/ios/SongPhangKit/Sources/Domain/AppError.swift` | Present |
| `apps/ios/SongPhangKit/Sources/Repositories/Errors/ErrorMapping.swift` (5.5A.3.1) | `apps/ios/SongPhangKit/Sources/Repositories/Transport/ErrorMapper.swift` | Renamed/existing location (`ErrorMapper.swift`) |
| `apps/ios/SongPhangKit/Sources/Repositories/Snapshots/SnapshotStore.swift` (5.5A.3.1) | `apps/ios/SongPhangKit/Sources/Repositories/Snapshots/SnapshotStore.swift` | Present |
| `apps/ios/SongPhangKit/Sources/AppShell/{RootView,AppDependencies,Routing/LinkRouter}.swift` (5.5A.3.1–3.2) | `apps/ios/SongPhangKit/Sources/AppShell/{RootView,AppDependencies,Routing/LinkRouter}.swift` | Present |
| `apps/ios/Scripts/check-strings.sh` (5.5A.0, 5.5A.2.2) | `apps/ios/Scripts/check-strings.sh` | Present |

## Decisions

### D1 — Clean-environment DB CLI & isolated API port (Task 0)
- **Problem:** Worktrees without `.env` fail `pnpm db:migrate` / `pnpm db:seed` / `pnpm db:check-balances` (which pass `--env-file=../../.env`). In addition, port `4000` is already bound in the host environment.
- **Options:** (1) Create an untracked `.env` in the share worktree and stop existing host processes; (2) Follow Phase 5 D1 by passing `DATABASE_URL` directly to `pnpm --filter @songphang/db exec tsx src/...` and running isolated API exercises on a free port (`4111`).
- **Choice:** Option 2.
- **Reason:** Preserves worktree cleanliness with zero `.env` risk and avoids interfering with running processes on `:4000`.

### D2 — Xcode 27.2 Simulator build flags for baseline & Stage gates (Task 0)
- **Problem:** Invoking `xcodebuild` without `-skipPackagePluginValidation` fails on `OpenAPIGenerator` plugin trust validation, and passing `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` globally on the command line conflicts with Xcode 27.2's `-suppress-warnings` on remote SwiftPM packages (as documented in Phase 5 D5).
- **Options:** (1) Disable warnings-as-errors; (2) Keep `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` on all 4 build configurations in `apps/ios/SongPhang.xcodeproj/project.pbxproj` and `.treatAllWarnings(as: .error)` on all 13 targets in `SongPhangKit/Package.swift`, and run `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`.
- **Choice:** Option 2.
- **Reason:** Compiler-enforced warnings-as-errors remains active on 100% of first-party Swift code while remote SwiftPM packages build cleanly.

### D3 — Be Vietnam Pro `.ttf` font assets deferred to `@design-system` in `5.5A.2.2` (Task 0)
- **Problem:** `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` does not yet exist on `33fe552`.
- **Options:** (1) Fetch fonts in Task 0 inside `api-backend`'s workspace; (2) Defer font placement to `@design-system` in `5.5A.2.2` per coordinator assignment boundaries (`api-backend` must not touch `apps/ios/`).
- **Choice:** Option 2.
- **Reason:** Preserves strict swarm file ownership boundaries between `api-backend` and `design-system`.

### D4 — OpenAPI additive response field rule (5.5A.1.2, 5.5A.1.3)
- **Problem:** `apps/api/src/openapi/diff.ts` treats any new `required` property on an existing schema (`GroupDto`, `GroupSummaryDto`, `BaseTransactionFields`) as breaking, causing `pnpm contract:write` to abort with exit code 2.
- **Options:** (1) Bypass breaking diff check via force write flag; (2) Declare additive fields on existing response schemas as `.optional()` or `.nullable().optional()` in OpenAPI schemas while always projecting them from server route handlers, following Overview Spec §7 (`nullable/optional response fields`).
- **Choice:** Option 2.
- **Reason:** Produces 0 breaking changes vs `33fe552` in `apps/api/src/openapi/cli.ts diff` while preserving backwards compatibility with older clients.

### D5 — Invariant alignment for `myDelta` and counted transactions (5.5A.1.3)
- **Problem:** `packages/db/src/balances.ts` counts only non-deleted transactions where `approval_status in ('none', 'approved')`. If pending or rejected transactions assigned non-zero `myDelta`, `sum(myDelta ?? 0)` would drift from `/balances`.
- **Options:** (1) Include pending/rejected transactions in balance calculations; (2) Define `computeMyDelta` to return `null` on `TransactionDto` (and `0` on `PersonalTransactionDto`) when `approval_status !== "none" && approval_status !== "approved"` or when soft-deleted.
- **Choice:** Option 2.
- **Reason:** Guarantees `sum(myDelta ?? 0) === myBalance` across all states without altering established double-entry balance accounting or requiring database schema changes.
