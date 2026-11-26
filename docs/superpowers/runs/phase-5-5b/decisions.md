# phase-5-5b — Run Decisions

- Branch: `phase-5-5b` (base `main` at `8250d8e`; spec & plan commit `44487f6`)
- Earlier phases on `main`: Phase 1 (`phase-1`), Phase 2 (`phase-2`), Phase 3 (`phase-3`), Phase 4 (`phase-4`), 5U (`ios-ui`), Phase 5 (`phase-5`), Wave 5.5A (`phase-5-5a`).

## Re-baseline

| Plan reference | Actual repository location | Status |
|---|---|---|
| `packages/db/src/schema-{settlements,transactions,groups}.ts`, `schema.ts`, `index.ts` | `packages/db/src/...` | Present |
| `packages/core/src/{vietqr,index}.ts` | `packages/core/src/{vietqr,index}.ts` | Present |
| `packages/contract/src/{payment,attachment,settlement-request,transaction,balance,error,jobs,index}.ts`, `openapi.json` | `packages/contract/src/...`, `packages/contract/openapi.json` | Present |
| `apps/api/src/services/{attachments,settlement-requests,transactions,transaction-changes,transaction-input,balances}.ts` | `apps/api/src/services/...` | Present |
| `apps/api/src/routes/{attachments,settlement-requests,balances}.ts`, `apps/api/src/app.ts` | `apps/api/src/...` | Present |
| `apps/web/src/messages/vi.ts` | `apps/web/src/messages/vi.ts` | Present |
| `apps/web/src/components/pay/{PayContent,PayFooter}.tsx` | `apps/web/src/components/pay/...` | Present |
| `apps/web/src/components/balances/{SettlementForm,PendingRequestRow}.tsx` | `apps/web/src/components/balances/...` | Present |
| `apps/web/src/components/feed/{ExpenseRow,ExpenseStream}.tsx` | `apps/web/src/components/feed/...` | Present |
| `apps/web/src/components/layout/{AppShell,GroupInspector}.tsx` | `apps/web/src/components/layout/...` | Present |
| `apps/web/src/app/.well-known/apple-app-site-association/route.ts` | `apps/web/src/app/.well-known/apple-app-site-association/route.ts` | Present |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | Present |
| `apps/ios/SongPhangKit/Sources/AppShell/{AppDependencies,GroupContainerView,Routing/LinkRouter}.swift` | `apps/ios/SongPhangKit/Sources/AppShell/...` | Present |
| `apps/ios/SongPhangKit/Sources/LedgerFeature/{Balances/BalancesView,Settle/SettleView}.swift` | `apps/ios/SongPhangKit/Sources/LedgerFeature/...` | Present |
| `apps/ios/SongPhangKit/Sources/PaymentsFeature/Pay/PayView.swift` | `apps/ios/SongPhangKit/Sources/PaymentsFeature/Pay/PayView.swift` | Present |
| `apps/ios/SongPhangKit/Sources/GroupsFeature/Members/MembersView.swift` | `apps/ios/SongPhangKit/Sources/GroupsFeature/Members/MembersView.swift` | Present |

## Decisions

### D1 — Clean-environment DB CLI & isolated API port (Task 0)
- **Problem:** `share` worktrees do not inherit untracked `.env`, causing `pnpm db:*` scripts (`--env-file=../../.env`) to fail, while local dev processes may occupy `:4000` or `:3000`.
- **Options:** (1) Copy `.env` into each worktree; (2) Pass `DATABASE_URL="postgres://songphang:songphang@localhost:54329/<disposable_db>"` directly to `pnpm --filter @songphang/db exec tsx src/...`, create/drop disposable DBs via `docker exec songphang-db-1 psql -U songphang -d postgres`, and bind temporary exercise servers to isolated ports (e.g. `:4115`) and temporary `STORAGE_DIR` outside the repo.
- **Choice:** Option 2.
- **Reason:** Keeps worktrees clean and prevents cross-worker or host-server interference.

### D2 — Xcode Simulator build flags for Xcode 27.2 (Task 0)
- **Problem:** Remote SwiftPM plugin packages require `-skipPackagePluginValidation` and conflict with command-line `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`.
- **Options:** (1) Disable warnings-as-errors; (2) Keep `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` on all first-party Xcode configurations and `.treatAllWarnings(as: .error)` in `SongPhangKit/Package.swift`, and build with `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`.
- **Choice:** Option 2.
- **Reason:** Preserves strict compiler warnings-as-errors across all first-party Swift code.

### D3 — OpenAPI response union diffing (`5.5B.1.2`, `apps/api/src/openapi/diff.ts`)
- **Problem:** Adding optional `accountQrPayload` inside the `"bank"` branch of `PayTo` (`BalancesResponse`) caused `diffOpenApiSnapshots` to flag `PayTo.oneOf` as breaking because `allOf|oneOf|anyOf` array element descent was gated by `/.requestBody.content..+.schema./`.
- **Options:** (1) Flatten `PayTo` away from `oneOf` (breaking); (2) Allow element-by-element comparison on same-length `allOf|oneOf|anyOf` arrays in `compareNode` across response and component schemas too.
- **Choice:** Option 2.
- **Reason:** Keeps `PayTo` strictly additive while still catching breaking changes inside union branches or length mismatches.

### D4 — Nullable `$ref` on `SettlementRequestDto.proofAttachment` (`5.5B.1.2`, `packages/contract/src/settlement-request.ts`)
- **Problem:** Calling `AttachmentDto.nullable()` mutated the shared `AttachmentDto` component schema's `type` from `"object"` to `["object", "null"]`.
- **Options:** (1) Inline `z.object(AttachmentDto.shape).nullable()`; (2) `z.union([AttachmentDto, z.null()]).optional()`.
- **Choice:** Option 2.
- **Reason:** Keeps `AttachmentDto` untouched and emits OpenAPI 3.1 `anyOf: [$ref AttachmentDto, null]` for clean client codegen.

### D5 — Drizzle schema export placement (`5.5B.1.1`, `packages/db/src/`)
- **Problem:** `schema-cycles.ts` imports `users` from `schema.ts`, so re-exporting `schema-cycles.ts` from `schema.ts` would create an ESM evaluation cycle.
- **Options:** (1) Inline `settlementCycles` inside `schema.ts`; (2) Export `settlementCycles` from `packages/db/src/index.ts` and register `./src/schema-cycles.ts` in `packages/db/drizzle.config.ts`.
- **Choice:** Option 2.
- **Reason:** Matches all existing `schema-*.ts` modules cleanly without circular imports.

### D6 — Feed transfer badge placement (`5.5B.2.1`, `apps/web/src/components/feed/LedgerPill.tsx`)
- **Problem:** Plan `5.5B.2.1` listed `ExpenseRow.tsx`, whereas `ExpenseStream.tsx` routes `type === "expense"` to `ExpenseRow` and `type === "transfer" | "income"` to `LedgerPill`.
- **Options:** (1) Duplicate transfer layout inside `ExpenseRow`; (2) Upgrade `LedgerPill.tsx` for `transfer` rows into a single-band card with a `28px` proof thumbnail (`firstAttachmentId`), `Có chứng từ` badge, channel/note subtitle, and single-line `tabular-nums` amount.
- **Choice:** Option 2.
- **Reason:** Matches existing codebase dispatch with zero redundant components.

### D7 — Swift OpenAPI generator union workaround for `proofAttachment` (`5.5B.3.1`, `LiveSettlementRequestsRepository.swift`)
- **Problem:** `swift-openapi-generator` skips `anyOf: [AttachmentDto, {type: null}]` on `SettlementRequestDto.proofAttachment` in generated types.
- **Options:** (1) Drop `proofAttachment` on iOS; (2) Decode `RawSettlementRequestsResponse` via `performAuthorizedDataRequest` in `LiveSettlementRequestsRepository.fetchPage`.
- **Choice:** Option 2.
- **Reason:** Preserves additive OpenAPI 3.1 compatibility while giving iOS full `proofAttachment` parity.

### D8 — Cycle-aware summary metrics on Share Cards (`5.5B.3.4`, `ShareCardPreviewSheet.swift`, `ShareCardModal.tsx`)
- **Problem:** Immediately after `Chốt đợt`, `currentPeriod` has `0` open expenses while `resolvedFocus` resolves to the latest closed cycle.
- **Options:** (1) Always display `currentPeriod.totalExpenseAmount`; (2) Use `focusCycle.totalExpenseAmount` / `expenseCount` when `resolvedFocus.kind == .cycle` and `currentPeriod` for `"current"` / `"all"` (zero client-side summing).
- **Choice:** Option 2.
- **Reason:** Displays accurate batch spend right after closeout while keeping server integers authoritative.
