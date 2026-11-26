# phase-5-5c — Run Decisions

## Earlier Phases on `main` (`ba2bfb4`)

- Phase 0–4, Phase 5 (iOS), Wave 5.5A (UI/UX v2 & Cross-group foundation), and Wave 5.5B (Settlement proofs, Vault, cycles & sharing, PR #4) are all merged on `main`.
- No tasks in Wave 5.5C are skipped.

## Re-baseline

| Plan's name | Real name and location | Status |
|---|---|---|
| `packages/core/src/{split,split-items,settlements,notification-text,index}.ts` | Same paths | Exists |
| `packages/db/src/{schema-groups,schema-transactions,reminders,groups,members,fund,index}.ts` | Same paths | Exists |
| `packages/db/drizzle.config.ts` | Same path | Exists (migrations `0000`..`0032` present) |
| `packages/contract/src/{transaction,error,jobs,member,group,balance,member-breakdown,guest-link,overview,index}.ts` & `openapi.json` | Same paths | Exists |
| `apps/api/src/app.ts`, `routes/transactions.ts`, `services/*` | Same paths | Exists |
| `apps/worker/src/{main,mail-templates}.ts` | Same paths | Exists |
| `apps/web/src/messages/vi.ts`, `lib/*`, `components/*`, `app/g/[groupId]/*` | Same paths | Exists |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | Same path | Exists |
| `apps/ios/SongPhangKit/Sources/Domain/Models/AppError.swift` | `apps/ios/SongPhangKit/Sources/Domain/AppError.swift` | Moved one level up in `Domain/` (noted for Stage 5.5C.3) |
| All other `apps/ios/` paths listed in `5-5c-3-ios.md` | Same paths | Exists |
| `docs/04-adr.md`, `docs/superpowers/plans/2026-11-15-common.md` | Same paths | Exists |

## Baseline Failures

- None. All baseline checks (`pnpm check`, `pnpm contract:check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, Simulator Debug `xcodebuild`, and disposable-DB smoke check) passed on `2b556de`.

## Stage 5.5C.1 Decisions

1. **Added `receipts.extrasKinds.shipping` in `vi.ts` and `Localizable.xcstrings` during `5.5C.1.2` / `5.5C.1.4`**
   - Problem: Spec §7 / Plan `5.5C.1.2` added `"shipping"` (`Phí giao hàng`) to `ItemsSplitExtra.kind`, and existing Web code maps `extrasKinds` keys cleanly when typed across all extra kinds.
   - Options: (a) Defer `shipping` UI key to `5.5C.1.4`; (b) Add `receipts.extrasKinds.shipping: "Phí giao hàng"` alongside `5.5C.1.2` contract update and mirror in `Localizable.xcstrings` in `5.5C.1.4`.
   - Choice: (b) Keeps `vi.ts` exhaustive with `ItemsSplitExtra.kind` from `5.5C.1.2` onward while `check-strings.sh` passes `0 missing, 0 differing` in `5.5C.1.4`.

2. **`CloneGroupRequest.includeMembers` made optional (`z.boolean().optional()`) instead of required default**
   - Problem: Existing Web `CloneGroupDialog.tsx` sends `CloneGroupRequest` without `includeMembers`, which would fail `pnpm check` if `includeMembers` were required.
   - Options: (a) Make `includeMembers` optional (treating omitted as copying existing members unless household cloning opts in); (b) Touch `apps/web` out of scope in Stage `5.5C.1`.
   - Choice: (a) Preserves backwards compatibility and avoids crossing `api-db` write boundaries before `5.5C.2`.

3. **Keep `NotificationPayload` OpenAPI union at 12 branches and handle recurring notification text cleanly**
   - Problem: Plan `00-overview.md` and `contract:check` prohibit changing the 12-branch `NotificationPayload` or 2-branch `OverviewPendingAction` OpenAPI unions; recurring auto-post/due notifications (`recurring_posted`, `recurring_due`) still need server-side Vietnamese text, APNs push, and deep-link sanitization (`/g/{groupId}/stats`).
   - Options: (a) Add new branches to `NotificationPayload` (breaking `contract:check` / Swift generator); (b) Introduce internal `ExtendedNotificationPayload` union in `apps/api/src/services/notify.ts` and route `recurring_posted` / `recurring_due` via `notification-text.ts` while `NotificationDto.payload` validates cleanly.
   - Choice: (b) Keeps OpenAPI non-breaking (`0 breaking, 61 additive`) while delivering localized recurring notifications and push targets cleanly.

4. **Inline `S8` recurring schemas in `packages/contract/src/transaction.ts` re-exported from `recurring.ts`**
   - Problem: `transaction.ts` (`CreateSplitTransactionRequest`) needs `CreateInlineRecurringInput`, while `recurring.ts` imports `SplitInput` and `CalendarDate` from `transaction.ts`.
   - Options: (a) Circular import between `transaction.ts` and `recurring.ts`; (b) Define `CreateInlineRecurringInput` in `transaction.ts` and re-export from `recurring.ts`.
   - Choice: (b) Keeps the package contract dependency graph strictly acyclic.

5. **`quarterly` recurring schedule fields use `dayOfMonth` without `monthOfYear` or `dayOfWeek`**
   - Problem: Clarify exact schedule-field invariant for `quarterly` frequency alongside `weekly` (`dayOfWeek`), `monthly` (`dayOfMonth`), and `yearly` (`dayOfMonth` + `monthOfYear`).
   - Options: (a) Require `monthOfYear` for quarterly; (b) Use `dayOfMonth` (advancing +3 calendar months with month-end clamping in `packages/core/src/recurring.ts`) and forbid `dayOfWeek`/`monthOfYear`.
   - Choice: (b) Matches Spec §5.1 (`Hằng quý`, anchor on `occurredAt` day-of-month) cleanly with `packages/db` constraints.

## Stage 5.5C.2–5.5C.4 Decisions

6. **Preserve legacy `.items` proportional default across Web & iOS detail/edit views**
   - Problem: `Money & Architecture Audit` caught that `useSplitState`, `ItemsSplitDraft`, and `TransactionExtrasCardView` defaulted omitted `extrasAllocation` to `"equal"`, which would mislabel or flip historical Phase 3 `.items` receipts when viewed/edited.
   - Options: (a) Leave default `"equal"`; (b) Default `extrasAllocation` to `"proportional"` when `method === "items"` and `"equal"` for all manual non-`items` splits (`TransactionExtrasCardView` accepts `defaultAllocation`).
   - Choice: (b) Preserves Phase 3 `ADR-023` receipts while honoring the owner's `"equal"` default for Wave 5.5C manual entries.

7. **Guard `ShareExtensionView` localhost fallbacks under `#if DEBUG` and add `ios.widget.galleryDescription`**
   - Problem: Release binary string scan detected `http://127.0.0.1:4000/api/v1` and `http://localhost:3000` fallbacks in `ShareExtensionView.swift`, and `SongPhangWidgets.swift` used template `"ios.widget.recentGroup"` (`"Nhóm gần nhất: {name}"`) for the widget gallery description.
   - Options: (a) Keep unguarded fallbacks; (b) Wrap local dev URLs in `#if DEBUG` so `Release` builds produce `RELEASE_LEAK_MATCH_COUNT=0`, and add a non-template `ios.widget.galleryDescription` key in `Localizable.xcstrings`.
   - Choice: (b) Enforces release hygiene and clean Vietnamese gallery copy.

8. **Eagerly load group list on startup for `ShareGroupsSnapshot` (`RootView.task`)**
   - Problem: Opening the app directly onto `Tổng quan` without visiting the `Nhóm` tab would leave `share-groups.json` empty for `SongPhangShareExtension`.
   - Options: (a) Populate `share-groups.json` only after visiting `Nhóm`; (b) Eagerly load `groupListModel.load()` in `RootView.task` when signed in (with `ExtensionStateSync` falling back to `overview.groupBalances`).
   - Choice: (b) Guarantees Zalo/Photos shares immediately see eligible groups on first use.
