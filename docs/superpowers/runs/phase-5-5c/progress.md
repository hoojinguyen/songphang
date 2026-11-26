# phase-5-5c — Run Progress

- Starting `main` SHA: `ba2bfb4` (Wave 5.5B merged via PR #4)
- Starting `phase-5-5c` SHA: `2b556de` (`api-db` share worktree branch `swarm-api-db-b8f935f9`)

## Stage 5.5C.0 — Re-baseline

- [x] **Task 0 — Re-baseline `main` on `phase-5-5c`**
  - Verified clean workspace on `swarm-api-db-b8f935f9` branched from `phase-5-5c` (`2b556de`).
  - `pnpm check` (`biome check .`, `pnpm -r typecheck`, `pnpm contract:check`): passed (9 Biome warnings on existing `<img>` / Next layout rules; 0 errors).
  - `pnpm contract:check`: passed (0 breaking changes).
  - `pnpm build`: passed (all workspace builds succeeded).
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 791 web keys verified, 0 missing, 0 differing.`
  - `xcrun swift-format lint --strict --recursive apps/ios`: passed (0 output).
  - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`: `** BUILD SUCCEEDED **`.
  - Disposable DB (`songphang_phase55c_t0`, migrations `0000`..`0032` + seed + isolated API on `:4125`):
    - `Login: 204`, `Group: 201`, `Tx: 201`, `Overview: 200 (netBalance: 66666)`, `Cycle: 201`, `GuestLink: 200`, `GuestView: 200 (Smoke T0, cycles: 1)`, `Archive: 200`, `Clone: 201`.
    - `pnpm --filter @songphang/db exec tsx src/check-balances.ts` → `All groups balanced`.
    - Dropped `songphang_phase55c_t0` cleanly.

## Stage 5.5C.1 — Core Math, Database, Worker, Additive v1 API & Copy Lock

- [x] **Task 5.5C.1.1 — `@songphang/core` pure integer math (`extras`, `households`, `recurring`) & DB migration (`0033`)**
  - Commit: `cdf721b`
  - Approach:
    - Files to create/modify: `packages/core/src/{split-items,split,settlements,recurring,index}.ts`, `packages/db/src/{schema-households,schema-recurring,households,recurring-expenses,schema-groups,schema-transactions,members,index}.ts`, `packages/db/drizzle.config.ts`, and migration `0033_wave_5_5c_recurring_and_households.sql`.
    - Approach: Extend `split-items.ts` / `split.ts` with `computePercentExtraAmount` and `allocateNetExtras` (including water-filling discount capping for `"equal"`), preserving `"proportional"` default on `items` and `"equal"` default on other split methods; add `consolidateHouseholdBalances` & `suggestHouseholdSettlements` (`BigInt` sums + representative mapping) in `settlements.ts`; add `Asia/Ho_Chi_Minh` calendar advancement in `recurring.ts`; add `households` and `recurring_expenses` tables, FKs, indexes, and DB query helpers in `@songphang/db`.
    - Why simplest: All money/date invariants live in pure `@songphang/core` functions and Postgres `CHECK`/FK constraints with no duplicate logic across API/worker/clients.
    - Rejected alternative: Handling water-filling or household mapping inside SQL/API services — rejected because `AGENTS.md` §7 requires all money math in `packages/core` so balances and settlements stay unified.
    - Questions: none.
  - Exercise results:
    - `pnpm check` passed (0 errors; 9 pre-existing `<img>` warnings).
    - Three Koala `346_000 + 8% VAT` (`27_680`, `"equal"`): `[{"memberId":"a","amount":181840},{"memberId":"b","amount":191840}]`.
    - Water-filling `[20_000, 200_000]` with `-50_000` `"equal"`: `[0, 170000]`.
    - Legacy `items` without `extrasAllocation`: `[{"memberId":"a","amount":22000},{"memberId":"b","amount":88000}]` (proportional).
    - Households (`Minh +600k`, `Lan -250k`, `Khánh -350k`) under both `minimizeDebts: true` & `false`: `[{"fromMemberId":"khanh","toMemberId":"minh","amount":350000}]`.
    - Schedule clamping: `dayOfMonth=31` after `2027-01-31` → `2027-02-28`, after `2028-01-31` → `2028-02-29`.
    - Disposable DB `songphang_phase55c_t1`: migration `0033` applied; `{ fundRejected: true, fixedNullRejected: true }`; `check-balances.ts` → `All groups balanced`.

- [x] **Task 5.5C.1.2 — Generalized `SplitInput.extras` validation & `POST /groups/{groupId}/transactions/extras/preview`**
  - Commit: `40241a2`
  - Approach:
    - Files to modify: `packages/contract/src/transaction.ts`, `apps/api/src/services/{transaction-input,transactions}.ts`, `apps/api/src/routes/transactions.ts`, `packages/contract/openapi.json` (via `pnpm contract:write` so `pnpm check` passes).
    - Approach: Generalize `ItemsSplitExtra` (`"shipping"`, `RatePercent`), add optional `extras` & `extrasAllocation` to `SplitInput` branches, reject `income` with `extras`, and add `POST /api/v1/groups/{groupId}/transactions/extras/preview` resolving `ratePercent` extras via `@songphang/core` and computing `computedAmount`, `shares`, `issues`, and `warnings`.
    - Why simplest: Reuses `calculateShares`, `computePercentExtraAmount`, and `transactionWarnings` directly inside a read-only repeatable-read DB transaction.
    - Rejected alternative: Computing `%` extras in Web/iOS clients before calling `/transactions/preview` — rejected by Spec §3.1 and `AGENTS.md` §7.
    - Questions: none.
  - Exercise results:
    - `pnpm check` passed (0 errors; added `receipts.extrasKinds.shipping` in `vi.ts` so `apps/web` typecheck passes with `"shipping"`).
    - Disposable DB `songphang_phase55c_t2` + isolated API (`:4125`):
      - `POST .../extras/preview` Three Koala `baseAmount: 346000` + `VAT 8%`: `200`, `resolvedExtras[0].amount === 27680`, `computedAmount === 373680`, `shares: [181840, 191840]`.
      - Manual VND override (`27681`, `ratePercent` omitted): `201` + `GET /transactions/{id}` `200`.
      - `equal+shipping`, `shares+discount` (`[0, 170000]`), `percent+tax`, `items+equal`: all `201`.
      - `income` with `extras`: `400 VALIDATION_FAILED`.
      - Auth matrix on `extras/preview`: `unauth: 401`, `viewer: 403`, `outsider: 404`.
      - `check-balances.ts` → `All groups balanced`.

- [x] **Task 5.5C.1.3 — `households` & `recurring-expenses` endpoints, `pg-boss` worker job, cross-surface household balances & `openapi.json`**
  - Commit: `c0e317d` (`6340833` in `api-db` share worktree)
  - Approach:
    - Files to create/modify: `packages/contract/src/{household,recurring,error,jobs,member,group,balance,member-breakdown,guest-link,overview,transaction,index}.ts`, `packages/core/src/notification-text.ts`, `packages/db/src/{reminders,transactions}.ts`, `apps/api/src/services/{households,recurring-expenses,balances,member-breakdowns,guest-links,groups,members,fund,overview,settlement-requests,reminders,transactions,notify}.ts`, `apps/api/src/routes/{households,recurring-expenses}.ts`, `apps/api/src/app.ts`, `apps/worker/src/{main,jobs/process-recurring}.ts`, `packages/contract/openapi.json`.
    - Approach: Add additive contract schemas keeping `OverviewPendingAction` (2 branches) and `NotificationPayload` (12 branches) unchanged; wire `suggestHouseholdSettlements` into `suggestGroupTransfers` so all settlement surfaces share identical household routing; add households & recurring CRUD/skip + inline `S8` creation/completion + member/fund deactivation auto-pause + unarchive advancement + `process-recurring` hourly `pg-boss` job.
    - Why simplest: Putting household netting in `suggestGroupTransfers` and recurring scheduling in `packages/core/src/recurring.ts` guarantees zero drift across API, guest links, cycles, reminders, and worker.
    - Rejected alternative: Duplicating household netting per endpoint — rejected because cycles, reminders, guest views, and balances would drift.
    - Questions: none.
- [x] **Task 5.5C.1.4 — Lock Wave 5.5C Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5C.1 Gate**
  - Plan:
    - Files changed: `apps/web/src/messages/vi.ts`, `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, `docs/superpowers/runs/phase-5-5c/{progress,decisions}.md`.
    - Approach: Add Wave 5.5C `extras`, `recurring`, and `households` namespaces to `vi.ts` (zero emoji, matching Spec §7), mirror all 880 web keys plus `ios.widget.*`, `ios.shareExtension.*`, and `ios.shortcuts.*` into `Localizable.xcstrings`, and run full Stage 5.5C.1 build, contract, string, Swift lint/Xcode, permission matrix, archived-group, and `check-balances` gates.
  - Checks:
    - `pnpm check`: exit 0 (0 errors; 9 pre-existing `lint/performance/noImgElement` warnings in `apps/web`).
    - `pnpm contract:check`: exit 0 (no breaking changes; additive OpenAPI diff `0 breaking, 61 additive`, `OverviewPendingAction.oneOf: 2`, `NotificationPayload` 12 branches).
    - `pnpm build`: exit 0.
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 880 web keys verified, 0 missing, 0 differing.`
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit 0.
    - `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`: `** BUILD SUCCEEDED **`.
    - Permission Matrix & Archived-Group Gate (`songphang_phase55c_gate`, dropped after run): `unauth` (`401`), `outsider` (`404`), `unlinked_viewer` (`200` GET / `403` writes), `linked_viewer_lan` (`200` GET / `403` writes / `201` household debtor `settlement-requests` / `200` own cancel), `editor_hung` & `owner_minh` bearer/cookie (`200` GET & `extras/preview` / `201` POST / `200` PATCH & `skip`), CSRF invalid `Origin` (`400`), archived group guards (`409` recurring POST/PATCH/skip & households POST/PATCH/DELETE; `204` recurring DELETE).
    - `check-balances.ts`: `Gate Group: sum 0; mismatches 0` -> `All groups balanced`.
    - Security review across `2b556de..HEAD`: Zod schemas on all boundaries, `requireGroupRole` + `404` outsiders, Drizzle parameterized queries only, no secrets/internal error leaks/forbidden tokens, 0 emoji matches.
    - Manual checks: Stage `5.5C.2` (Web) and `5.5C.3` (iOS) will exercise end-to-end UI rendering on top of these APIs and strings.
    - Not verified: Real external APNs/SMTP providers (deferred to Server Step per `AGENTS.md` §1); Web & iOS UI consumer screens (owned by `web` and `ios` swarm workers).

## Stage 5.5C.2 — Web Implementation (`apps/web/`)

- [x] **Task 5.5C.2.1 — Manual-form `extras` on `S8` (`ExpenseForm` & `SplitEditor`) and breakdown display on `S20` & `/share/[token]`**
  - Commit: `c2b121c` (`5d333e5` in `web` share worktree)
  - Exercise results: `POST .../extras/preview` Three Koala `346.000 đ + VAT 8%` -> `373.680 đ` (`[181.840, 191.840]`), manual VND override `27.681 đ`, water-filling `20.000 / 200.000 - 50.000 đ` -> `[0, 170.000]`, verified live in Chrome on `S8` and `S20`.

- [x] **Task 5.5C.2.2 — Recurring Expenses (`S8` inline toggle, `Quỹ & Thống kê` management, `Tổng quan` due prompts & notifications)**
  - Commit: `b68788a` (`4931514` in `web` share worktree)
  - Exercise results: Created variable template `Tiền điện tháng` in `Quỹ & Thống kê`, ran worker (`WORKER_RECURRING_RESULT:1`), opened due prompt from `Tổng quan` -> `S8` -> saved expense (`dueRecurringCount=0`), and skipped `Three Koala` fixed template via `Bỏ qua kỳ tới`.

- [x] **Task 5.5C.2.3 — Household / Couple Debt Grouping (`S10`, `Thanh toán`, `Nhóm`, `GroupInspector`, `/share/[token]`, `ShareCard`) & Stage 5.5C.2 Web Gate**
  - Commit: `f643fa3` (`29e4716` in `web` share worktree)
  - Exercise results: Created `Nhà Minh & Lan` in `S10`, verified consolidated `350.000 đ` transfer + `MemberBreakdownSheet` + `ShareCardModal` Light/Dark + `/share/[token]` Dark + `GroupInspector` (`1280x900`); verified `Lan` (`linked viewer`) submits `Tôi đã chuyển` (`201`) while `Đã nhận` (`confirm`) returns `403` for `Lan` and `200` for `Minh`, leaving `0 đ` across `Tổng quan`, `Nhóm`, and `Thanh toán`; `pnpm check` & `pnpm build` passed; `check-balances.ts` -> `All groups balanced`.

## Stage 5.5C.3 — iOS (`SongPhangKit`) Parity & System Extensions (`apps/ios/`)

- [x] **Task 5.5C.3.1 — `Domain` / `Repositories` / `PreviewSupport` for Wave 5.5C + App Group `ExtensionSharedStore` & Shared Keychain Migration**
  - Commit: `c9b722c` (`af67da3` in `ios` share worktree)
- [x] **Task 5.5C.3.2 — Manual-form `extras` (`S8`, `S20`, `GuestTransactionDetailSheet`) and Recurring Expenses (`S8`, `StatsView`, `OverviewView`, `NotificationsView`)**
  - Commit: `77b7e55` (`cf2b9e0` in `ios` share worktree)
- [x] **Task 5.5C.3.3 — Household / Couple Debt Grouping (`MembersView`, `BalancesView`, `GroupListView`, `GuestGroupView`, `ShareCardCanvasView`)**
  - Commit: `c894021` (`a5d2be2` in `ios` share worktree)
- [x] **Task 5.5C.3.4 — `LinkRouter` `songphang://` routing, Quick Actions, `SongPhangShareExtension`, `SongPhangWidgetExtension` & Stage 5.5C.3 Gate**
  - Commit: `515418e` (`8257c18` in `ios` share worktree)
  - Exercise results: `pluginkit -m -v` registered `vn.songphang.app.share-extension` and `vn.songphang.app.widget-extension`; Simulator (`iPhone 17 Pro`) `--scripted --route-overview` populated `group.vn.songphang.app` `widget-snapshot.json` & `share-groups.json` with zero auth tokens; `ShareInbox` batch consumed automatically on launch into `S8`; `--signed-out` wiped `SharedState/`.

## Stage 5.5C.4 — Parallel Audit, Standing Docs, ADRs & Handoff

- [x] **Task 5.5C.4.1 — Record ADRs, run multi-angle `run_workflow` audit, execute full release gates & write owner manual-check guide**
  - Recorded `ADR-039`, `ADR-040`, and `ADR-041` in `docs/04-adr.md`; added Wave `5.5C` to `docs/superpowers/plans/2026-11-15-common.md`.
  - Ran 3-angle read-only `run_workflow` audit (`Security & Auth`, `Money & Architecture`, `Web/iOS Parity & Hygiene`) against `git diff main...HEAD`:
    - `Security & Auth Audit`: `pass` (`0` findings).
    - `Money & Architecture Audit`: fixed 3 `must_fix` findings (preserving `.proportional` fallback on legacy `.items` rows in `TransactionExtrasCardView`, `ItemsSplitDraft`, and Web `useSplitState`).
    - `Web/iOS Parity & Hygiene Audit`: fixed 4 `must_fix` findings + 6 `should_fix` polish items (`ShareExtensionView` group name interpolation + `#if DEBUG` guard on dev fallback URLs, `ios.widget.galleryDescription` key, `Tokens.onAccent` / `Tokens.onInk` Dark mode contrast, `households.representativeBadge` Web/iOS parity, `.monospacedDigit()` / `tabular-nums`, `DD/MM/YYYY` formatting, and WidgetKit `.systemSmall` / `.systemMedium` parity).
  - Post-fix integrated verification gates on `phase-5-5c`:
    - `xcrun swift-format lint --strict --recursive apps/ios`: exit `0` (empty output).
    - `./apps/ios/Scripts/check-strings.sh`: `OK: 880 web keys verified, 0 missing, 0 differing.`
    - `pnpm check`: exit `0` (`Checked 594 files in 159ms. No fixes applied. Found 9 warnings.` pre-existing `<img>` warnings only; 8 workspace typechecks + `contract:check` pass).
    - `pnpm build`: exit `0`.
    - Simulator Debug `xcodebuild`: `** BUILD SUCCEEDED **`.
    - Simulator Release `xcodebuild` (`CODE_SIGNING_ALLOWED=NO`): `** BUILD SUCCEEDED **`, `PlugIns/` contains `SongPhangShareExtension.appex` and `SongPhangWidgetExtension.appex`, `otool -L` confirms `SongPhangWidgetExtension` links zero `Repositories`/`GeneratedAPI`, and `RELEASE_LEAK_MATCH_COUNT=0`.
    - Disposable Postgres 17 (`songphang_phase55c_final_gate`) migration + seed + `check-balances.ts` -> `All groups balanced` (plus end-to-end API/Worker/Web exercises across Stages `5.5C.1` & `5.5C.2`).
  - Not verified:
    - Real external APNs, SMTP, OAuth, and AI provider execution (deferred to Server Step per `AGENTS.md` §1).
    - Interactive iOS Home Screen WidgetKit gallery / Zalo live Share Sheet UI host interaction and physical-iPhone live API round-trip (deferred to owner physical iPhone manual check using `manual-checks.md`).
