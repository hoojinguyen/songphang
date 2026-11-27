# Sòng Phẳng Wave 5.5C (Manual Extras, Recurring Expenses, Households & iOS Extensions) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `.agent/skills/songphang-swarm-orchestrator/SKILL.md` (when invoked via Antigravity `/swarm`) or `superpowers:executing-plans` for the continuous phase run described in `AGENTS.md` §12. Use `.agents/skills/execute-task/SKILL.md` (phase-run mode) and `.agents/skills/security-review/SKILL.md` for every task. Steps use checkbox (`- [ ]`) syntax tracked in `docs/superpowers/runs/phase-5-5c/progress.md`.
>
> **Status (2026-11-26):** Spec approved by the project owner. Prepared for Antigravity `/swarm` execution on branch `phase-5-5c`.

**Goal:** Ship manual-form `%`/VND `extras` (VAT, service fee, shipping, discount/voucher) across all five expense split methods with equal water-filling default, Vietnam-calendar **Recurring Expenses** (`fixed` auto-post and `variable` due reminders on `pg-boss`), **Household / Couple Debt Grouping** (`households`) consolidating settlements through a representative member in `packages/core`, **iOS Share Extension** (`SongPhangShareExtension`) for Zalo/Photos/banking receipts, and **iOS Home Screen Widgets & Quick Actions** (`SongPhangWidgetExtension`) with 100% Web/iOS core parity.

**Architecture:**
- **DB, Core, Worker & Additive `/api/v1` (Wave 1 — `api-db`):** Pure integer `BigInt` math in `@songphang/core` (`extras` `%`/VND + equal water-filling & proportional allocation across `equal|exact|shares|percent|items`, `households` balance consolidation + pairwise/minimized transfer routing, and `Asia/Ho_Chi_Minh` recurring schedule advancement), one additive Drizzle migration (`households`, `recurring_expenses`, `members.household_id`, `transactions.recurring_expense_id`), `POST .../transactions/extras/preview`, `recurring-expenses` & `households` CRUD + `pg-boss` `process-recurring` job, household-aware `Overview`/`Groups`/`Balances`/`Breakdowns`/`GuestGroupView`/`SettlementRequests`, locked `packages/contract/openapi.json`, and locked Vietnamese strings in `vi.ts` + `Localizable.xcstrings`.
- **Web (`apps/web/`, Wave 2A — `web`):** `S8` quick extras chips (`VAT 8%`, `VAT 10%`, `Phí DV 5%`, `Phí ship`, `Giảm giá`) + `Phụ phí & Giảm giá` card (`Chia đều` | `Theo tỷ lệ`) + `S20`/`/share/[token]` breakdown; `S8` inline recurring toggle + `Quỹ & Thống kê` `Giao dịch định kỳ` management + `Tổng quan` due recurring prompts; `S10` `Hộ gia đình / Cặp đôi` management + household consolidated display across `Thanh toán`, `Nhóm`, `GroupInspector`, `/share/[token]`, `MemberBreakdownSheet`, and `ShareCardModal`.
- **iOS (`apps/ios/`, Wave 2B — `ios`, parallel with `web`):** `SongPhangKit` `Domain`/`Repositories`/`PreviewSupport` mappings, App Group (`group.vn.songphang.app`) `ExtensionSharedStore` + Shared Keychain migration in `TokenStore`, `S8` manual extras + inline recurring, `StatsView` recurring CRUD + `OverviewView` due actions, `MembersView`/`BalancesView`/`GuestGroupView`/`ShareCardCanvasView` household parity, `LinkRouter` `songphang://` routing + `UIApplicationShortcutItem` Quick Actions, `SongPhangShareExtension` target (`ImageIO` `<= 5 MiB` + `ShareInbox` dual-delivery), and `SongPhangWidgetExtension` target (`.systemSmall` & `.systemMedium` + `"Ẩn số tiền trên Widget"` toggle).

**Tech Stack:** TypeScript, Hono/OpenAPI, Drizzle ORM, PostgreSQL 17, `pg-boss`, Next.js 16 / React 19 / Tailwind CSS v4, Swift 6, SwiftUI / WidgetKit / UniformTypeIdentifiers / ImageIO (iOS 26 minimum), Apple Swift OpenAPI Generator/Runtime/URLSession.

**Spec:**
- [Wave 5.5C Design](../../specs/2026-11-26-phase-5-5c-depth-and-extensions-design.md)
- [Wave 5.5B Design](../../specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md)
- [Phase 5.5 Overview Design](../../specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md)
- [iOS Codebase Architecture](../../specs/2026-11-16-ios-codebase-architecture-design.md)
- [Common Phase Rules](../2026-11-15-common.md)

## Global Constraints

- **Branch & isolation:** Work exclusively on branch `phase-5-5c` created from `main` (`ba2bfb4` or later). Never touch `main`, never `git push`, never deploy or call live external services. In `share` worktrees (which have no `.env`), pass `DATABASE_URL` explicitly and bind temporary API/worker exercise processes to an isolated port (e.g. `:4125`) and isolated `STORAGE_DIR` outside the repo.
- **No automated tests (`AGENTS.md` §6):** Zero test libraries and zero `*.test.*` or `*.spec.*` files. Every task verifies via `pnpm check` / `xcodebuild` plus real HTTP, disposable-DB, worker-runner, browser, or Simulator exercises with observed outputs recorded.
- **Strictly additive `/api/v1`:** `pnpm contract:check` must report `0` breaking changes. Do **not** alter branch counts of existing registered response `discriminatedUnion` schemas (`OverviewPendingAction` remains 2 branches — add optional `dueRecurringCount` & `dueRecurringActions` on `OverviewResponse`; `NotificationPayload` remains 12 branches — validate `"recurring_posted"` and `"recurring_due"` server-side while serializing through `NotificationDto.payload`'s existing `Record<string, unknown>` branch). Outsiders receive `404` on all group endpoints.
- **Money & calculation invariants:** VND integers only end to end — zero floating-point math, zero client-side percentage multiplication, rounding, household netting, or recurring date math (`AGENTS.md` §7, `apps/ios/AGENTS.md` §5). Omitted `extrasAllocation` on `method === "items"` evaluates as `"proportional"` (preserving historical Phase 3 receipts), while manual entries default to `"equal"` (`Chia đều`) with water-filling non-negative discount caps. `pnpm db:check-balances` must print `All groups balanced`.
- **iOS module & extension boundaries (`apps/ios/AGENTS.md` §3 & §7):** Feature modules import **only** `Domain`, `DesignSystem`, and `PreviewSupport`. `SongPhangWidgetExtension` links **only** `Domain` and `DesignSystem` (zero network/Keychain access in WidgetKit). Session bearer tokens live exclusively in Keychain (shared access group), never in `UserDefaults` or App Group JSON files; `TokenStore.clear()` / `SnapshotStore.clearAll()` wipe `SharedState/`, and `ExtensionStateSync.clearSignedOut()` coordinates clearing `SharedState/`, `UIApplication.shared.shortcutItems`, and reloading WidgetKit timelines immediately.
- **String parity & zero emoji:** Zero emoji anywhere in UI copy, widgets, share extension, notifications, or source code. Shared strings are locked in Task `5.5C.1.4` across `apps/web/src/messages/vi.ts` and `Localizable.xcstrings`, while iOS-only extension/widget strings use the `ios.*` key prefix permitted by `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`).
- **Zero new dependencies:** Install no npm or SwiftPM packages.

## Review Focus

| Failure Mode / Input Class | Owning Exercise |
|---|---|
| Equal voucher discount exceeds a low-spend participant's base share (e.g., `20.000 đ` drink + `200.000 đ` steak with `-50.000 đ` voucher under `Chia đều`), or restaurant bill (`346.000 đ` + `8% VAT` = `373.680 đ`) has its đồng amount manually overridden (`27.681 đ`), or legacy Phase 3 `items` row lacks `extrasAllocation` | `5.5C.1.1`, `5.5C.1.2`, `5.5C.2.1`, `5.5C.3.2`: verify water-filling produces `[0, 170_000]`, Three Koala `346k + 8%` yields `[181_840, 191_840]` (`373_680`), manual đồng edit clears `ratePercent`, and omitted `extrasAllocation` on `items` stays `"proportional"` |
| Creating an inline recurring rule from `S8` double-posts a second bill on the same day, or `dayOfMonth = 31` fails in February, or restarting a paused worker/group after 3 months floods duplicate bills, or deactivating an ex-roommate (`active = false`) keeps billing them, or a `viewer`-linked variable payer creates an RBAC `403` deadlock | `5.5C.1.3`: exercise inline `S8` create (`nextDueDate > todayVN`), `31 -> 2027-02-28` clamping, `todayVN + 95d` single-catchup advancement, `PATCH /members` (`active: false`) auto-pausing template (`pause_reason = 'member_invalid'`), unarchive date advancement, and `viewer` variable-payer fallback to `editor+` creator/`owner` |
| Coupled members (`Nhà Minh & Lan`: `Minh +600k` rep, `Lan -250k`, `Khánh -350k`) settle `Khánh -> Minh: 350.000 đ`, but `GET /groups`, `Overview`, or Widgets still show `Lan: -250.000 đ`; or non-rep partner `Lan` (`linked viewer`) cannot report household outgoing payment (`POST /settlement-requests`) or is wrongly allowed to confirm `Minh`'s incoming bank transfer | `5.5C.1.3`, `5.5C.2.3`, `5.5C.3.3`: verify both `minimizeDebts: true` and `false` consolidate to `Khánh -> Minh: 350.000 đ`, post-transfer `myBalance === 0` across `GET /groups`, `GET /me/overview`, `GET /balances`, `/share/{token}`, and `widget-snapshot.json`, `Lan` `POST /settlement-requests` (`fromMemberId = Minh`) -> `201`, and `Lan` `POST .../confirm` (`toMemberId = Minh`) -> `403` while `Minh` -> `200` |
| Adding recurring due actions or notification kinds mutates `OverviewPendingAction.oneOf` or `NotificationPayload.oneOf` branch counts and fails `pnpm contract:check` | `5.5C.1.3`: verify `pnpm contract:write && pnpm contract:check` exits `0` with `0` breaking changes |
| High-res iPhone photo in `SongPhangShareExtension` spikes above `120 MB` RAM, or upgrading user loses session when Keychain switches to shared access group, or Zalo suppresses `extensionContext?.open`, or signing out leaves stale balances visible on Home Screen Widgets | `5.5C.3.1` & `5.5C.3.4`: verify legacy-to-shared Keychain migration, `ImageIO` thumbnail normalization `<= 5 MiB`, `RootView` `scenePhase == .active` automatic `ShareInbox` pickup, and sign-out wiping `SharedState/` + `shortcutItems` |

## Swarm Topology & Hot-File Ownership

```text
Task 0 (Coordinator on `phase-5-5c`: clean tree + baseline verification)
  -> Wave 1 (`api-db` [share]): Tasks 5.5C.1.1 -> 5.5C.1.4 (locks Core, DB, API, Worker, openapi.json, vi.ts & Localizable.xcstrings)
  -> Coordinator lands Wave 1 on `phase-5-5c`, runs Stage 5.5C.1 Gate, broadcasts merged SHA
  -> Wave 2 in parallel:
       ├── `web` [share]: Tasks 5.5C.2.1 -> 5.5C.2.3 (`apps/web/**` excluding locked `vi.ts`)
       └── `ios` [share]: Tasks 5.5C.3.1 -> 5.5C.3.4 (`apps/ios/**` excluding locked `Localizable.xcstrings`)
  -> Coordinator lands `web` + `ios` onto `phase-5-5c` BEFORE `kill`, runs Stage 5.5C.4 (`run_workflow` audit, ADRs, full gates & handoff)
```

| Hot File | Single Owner | Rule |
|---|---|---|
| `packages/contract/openapi.json` | `api-db` (`5.5C.1.3`) | Additive only (`0` breaking changes); frozen before Wave 2 starts |
| `apps/web/src/messages/vi.ts` & `apps/ios/.../Localizable.xcstrings` | `api-db` (`5.5C.1.4`) | Locked together (`ios.*` prefix for extension-only strings) and verified with `check-strings.sh` before Wave 2 |
| `apps/ios/SongPhang.xcodeproj/project.pbxproj`, `SongPhangKit/Package.swift`, `AppShell/RootView.swift` | `ios` (`5.5C.3.1`..`5.5C.3.4`) | Single iOS worker owns all `apps/ios/**` edits |
| `docs/superpowers/runs/phase-5-5c/{progress,decisions,manual-checks}.md` | Coordinator | Updated on `phase-5-5c` after landing each wave |

## Files and Stage Order

| Order | Stage File | Owner | Tasks & Scope |
|---|---|---|---|
| `0 – 5.5C.1` | [5-5c-1-api-db-and-contracts.md](5-5c-1-api-db-and-contracts.md) | Coordinator (`Task 0`) + `api-db` | `Task 0` (re-baseline), `5.5C.1.1` (`@songphang/core` extras/households/recurring math + DB migration `0033`), `5.5C.1.2` (generalized `SplitInput.extras` + `POST .../transactions/extras/preview`), `5.5C.1.3` (`households` + `recurring-expenses` endpoints, `pg-boss` `process-recurring` worker, household-aware `Overview`/`Groups`/`Balances`/`Breakdowns`/`GuestGroupView`/`SettlementRequests`, `openapi.json`), `5.5C.1.4` (lock `vi.ts` + `Localizable.xcstrings` & API/Worker Stage Gate) |
| `5.5C.2` | [5-5c-2-web.md](5-5c-2-web.md) | `web` (parallel with `5.5C.3`) | `5.5C.2.1` (`S8` manual-form quick chips & `Phụ phí & Giảm giá` card + `S20`/`/share/[token]` extras breakdown), `5.5C.2.2` (`S8` inline recurring toggle + `Quỹ & Thống kê` `Giao dịch định kỳ` CRUD/skip + `Tổng quan` due recurring prompts), `5.5C.2.3` (`S10` `Hộ gia đình / Cặp đôi` CRUD + household display across `Thanh toán`, `Nhóm`, `GroupInspector`, `/share/[token]`, `MemberBreakdownSheet`, `ShareCard` & Web Stage Gate) |
| `5.5C.3` | [5-5c-3-ios.md](5-5c-3-ios.md) | `ios` (parallel with `5.5C.2`) | `5.5C.3.1` (`Domain`/`Repositories`/`PreviewSupport` for 5.5C + App Group `ExtensionSharedStore` + Shared Keychain migration in `TokenStore`), `5.5C.3.2` (`S8` manual extras + `S20`/`GuestTransactionDetailSheet` extras + `S8` inline recurring + `StatsView` recurring CRUD + `OverviewView` due actions), `5.5C.3.3` (`MembersView` households CRUD + `BalancesView`/`GroupListView`/`GuestGroupView`/`ShareCardCanvasView` household parity), `5.5C.3.4` (`LinkRouter` `songphang://` + Quick Actions + `SongPhangShareExtension` + `SongPhangWidgetExtension` + `"Ẩn số tiền trên Widget"` & iOS Stage Gate) |
| `5.5C.4` | [5-5c-4-audit-docs-and-handoff.md](5-5c-4-audit-docs-and-handoff.md) | Coordinator | `5.5C.4.1` (`ADR-039`–`ADR-041`, `common.md` index update, `run_workflow` 3-angle audit, Debug + unsigned Release `xcodebuild` covering app & both extensions, disposable-DB full replay, `manual-checks.md`) |

**Handoff inputs:** `<SPEC>` = `docs/superpowers/specs/2026-11-26-phase-5-5c-depth-and-extensions-design.md`; `<PLAN>` = `docs/superpowers/plans/2026-11-26-phase-5-5c`; `<BRANCH>` = `phase-5-5c`; `<LAST TASK>` = `5.5C.4.1`. Run artifacts live under `docs/superpowers/runs/phase-5-5c/`.

## Standard Verification Commands

```sh
# Ensure Node 24 LTS + corepack pnpm are on PATH in non-login shells:
export PATH="$HOME/.nvm/versions/node/v24.22.1/bin:$PATH"
pnpm check
pnpm contract:check
pnpm build
./apps/ios/Scripts/check-strings.sh
xcrun swift-format lint --strict --recursive apps/ios
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -skipPackagePluginValidation build
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build
DATABASE_URL="<disposable_db_url>" pnpm --filter @songphang/db exec tsx src/check-balances.ts
```
