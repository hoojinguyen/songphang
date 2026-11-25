# Sòng Phẳng Wave 5.5B (Settlement Proofs, Vault, Cycles & Sharing) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `.agent/skills/songphang-swarm-orchestrator/SKILL.md` (when invoked via Antigravity `/swarm`) or `superpowers:executing-plans` for the continuous phase run described in `AGENTS.md` §12. Use `.agents/skills/execute-task/SKILL.md` (phase-run mode) and `.agents/skills/security-review/SKILL.md` for every task. Steps use checkbox (`- [ ]`) syntax tracked in `docs/superpowers/runs/phase-5-5b/progress.md`.
>
> **Status (2026-11-26):** Spec approved by the project owner. Prepared for Antigravity `/swarm` execution on branch `phase-5-5b`.

**Goal:** Ship optional transfer receipt proofs + payment channel/note, the unified **Sổ thanh toán** reconciliation vault, cumulative **Chốt đợt / Hồ sơ đã chốt** (`settlement_cycles`) with `Chi tiêu` period filtering, opt-in revocable **Guest Read-Only Links** (`/share/{token}`) with server-computed per-member debt breakdowns and VietQR, and 1-tap Light/Dark high-DPI image export (**Tổng kết nhóm** & **Nhắc nợ khéo**) across Web and iOS with 100% parity.

**Architecture:**
- **DB, Core & Additive `/api/v1` (Wave 1 — `api-db`):** One additive Drizzle migration (`settlement_requests` proof/channel/note, `settlement_cycles`, `transactions` `payment_channel`/`payment_note`/`cycle_id`, `groups` guest-link columns), static account VietQR (`010211`) in `@songphang/core`, `?purpose=transfer_proof` attachment upload/GC protection, unified `GET /settlement-vault`, `GET/POST/DELETE /settlement-cycles`, `GET /balances/breakdowns` (`auto`/`current`/`<uuid>`), `GET/POST/DELETE /guest-link` + public `GET /guest-links/{token}*`, locked `packages/contract/openapi.json`, and locked bidirectional Vietnamese copy in `vi.ts` + `Localizable.xcstrings`.
- **Web (`apps/web/`, Wave 2A — `web`):** 3-pill sub-navigation in `Thanh toán` (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), optional proof/channel/note in `Pay` & `SettlementForm`, proof thumbnail badge on Transfer feed rows, `Chi tiêu` cycle filter chip, standalone unauthenticated `/share/[token]` (`AppShell` bypass + AASA `/share/*`), and deterministic HTML5 2D `<canvas>` (`1170px` `3x`, `Be Vietnam Pro` + `qrcode`) Share/Download sheet.
- **iOS (`apps/ios/`, Wave 2B — `ios`, parallel with `web`):** Strict `SongPhangKit` module isolation (`apps/ios/AGENTS.md` §3): `Domain` value types/protocols, `Repositories` live OpenAPI & unauthenticated guest mappings, `DesignSystem` `ProofBadgeView`/`ChannelPillPicker`/`ShareCardCanvasView`, 3-pill `BalancesView` + Vault/Cycles/Breakdown sheets in `LedgerFeature`, optional proof/channel/note in `PayView` & `SettleView`, zero-login `.guestShare(token:)` in `LinkRouter`/`AppShell`, and `ImageRenderer` (`scale = 3.0`) native `ShareLink` export.

**Tech Stack:** TypeScript, Hono/OpenAPI, Drizzle ORM, PostgreSQL 17, Next.js 16 / React 19 / Tailwind CSS v4 / `qrcode`, Swift 6, SwiftUI (iOS 26 minimum), Apple Swift OpenAPI Generator/Runtime/URLSession.

**Spec:**
- [Wave 5.5B Design](../../specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md)
- [Phase 5.5 Overview Design](../../specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md)
- [Wave 5.5A Design](../../specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md)
- [iOS Codebase Architecture](../../specs/2026-11-16-ios-codebase-architecture-design.md)
- [Common Phase Rules](../2026-11-15-common.md)

## Global Constraints

- **Branch & isolation:** Work exclusively on branch `phase-5-5b` created from `main` (`8250d8e` or later). Never touch `main`, never `git push`, never deploy or call live external services. In `share` worktrees (which have no `.env`), pass `DATABASE_URL` explicitly and bind temporary API exercise servers to an isolated port (e.g. `:4115`) and isolated `STORAGE_DIR` outside the repo.
- **No automated tests (`AGENTS.md` §6):** Zero test libraries and zero `*.test.*` or `*.spec.*` files. Every task verifies via `pnpm check` / `xcodebuild` plus real HTTP, disposable-DB, browser, or Simulator exercises with observed outputs recorded.
- **Strictly additive `/api/v1`:** Only optional query params, new endpoints, and `.nullable()` / `.optional()` response fields (`pnpm contract:check` + non-breaking diff). Outsiders receive `404` on all group endpoints; invalid/revoked guest tokens return generic `404` with `Cache-Control: private, no-store`.
- **Money & QR invariants:** VND integers only end to end — zero floating-point math, zero rounding (`k` abbreviations forbidden), and zero client-side split/balance/carry-over/VietQR computation (`apps/ios/AGENTS.md` §5). Across every member in `GET /balances/breakdowns`, `carryOverBalance + focusExpenseDelta + focusTransferDelta + postCycleDelta === netBalance` holds to the exact đồng, and `pnpm db:check-balances` prints `All groups balanced`.
- **Optionality & editability rules:** `proofAttachmentId`, `channel`/`paymentChannel`, and `note`/`paymentNote` are **100% optional** everywhere (1-tap settlement preserved). Closing a cycle stamps only counted rows (`deleted_at IS NULL AND approval_status IN ('none', 'approved')`), and `owner`/`editor` may still edit/delete/restore transactions inside closed cycles (`PATCH` preserves existing `cycle_id`).
- **iOS module boundaries (`apps/ios/AGENTS.md` §3):** Feature modules (`LedgerFeature`, `PaymentsFeature`, `GroupsFeature`, …) import **only** `Domain`, `DesignSystem`, and `PreviewSupport`. Cross-feature coordination lives exclusively in `AppShell`.
- **String parity & zero emoji:** Zero emoji anywhere in UI copy, share cards, or code. All Wave 5.5B Vietnamese strings are locked in Task `5.5B.1.4` across `apps/web/src/messages/vi.ts` and `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` (`./apps/ios/Scripts/check-strings.sh` -> `0 missing, 0 differing`).
- **Zero new dependencies:** Install no npm or SwiftPM packages.

## Review Focus

| Failure Mode / Input Class | Owning Exercise |
|---|---|
| Host closes `Đợt 1` (`0` open expenses left in `Đợt hiện tại`) and immediately shares `/share/{token}` or exports `Nhắc nợ khéo`: naive `"current"` filtering would show `0 đ` spend and collapse all sessions into an opaque carry-over line | `5.5B.1.3`, `5.5B.2.3`, `5.5B.3.4`: close a cycle with 0 new expenses after it, verify `"auto"` focus itemizes `latestCycle` + post-closeout transfers on `/balances/breakdowns`, `/share/{token}`, and 1-debtor `Nhắc nợ khéo` |
| Unauthenticated visitor opens `/share/[token]` on Web and `AppShell` mounts `MobileTabBar`/`DesktopSidebar` (`useUnreadNotificationCount`), firing `/api/v1/notifications` `401`s or auth redirects; or banking `transfer_proof` screenshots leak through `/guest-links/{token}/attachments/{id}` | `5.5B.1.3` and `5.5B.2.3`: verify `/share/[token]` fires zero authenticated `/me` or `/notifications` requests in incognito, expense receipt images return `200`, transfer proof images return `404`, and `DELETE /guest-link` (even on an archived group) turns all `/guest-links/{token}*` calls into `404` immediately |
| A `viewer` linked to a member uploads a `transfer_proof` for `"Tôi đã chuyển"`, and either gets `403` on upload, attaches someone else's unbound scan, or has the pending proof deleted after 24h by `cleanup-attachments` before the host taps `"Đã nhận"` | `5.5B.1.2`: exercise linked `viewer` (`201`) vs unlinked `viewer` (`403`), cross-user proof hijack attempt (`400`/`403`), and run `runCleanupAttachments` with `now + 48h` confirming pending `settlement_requests.proof_attachment_id` survives while truly orphaned scans are purged |
| Editing or deleting an expense inside a closed cycle (`cycle_id IS NOT NULL`), or having `pending` approval expenses open when closing a cycle, corrupts `cycle_id` placement or breaks `carryOverBalance + sum(lines.delta) === netBalance` | `5.5B.1.3`: close `Đợt 1` while one `pending` expense exists (verify `pending` stays `cycle_id = NULL`), `PATCH` an expense inside `Đợt 1` (verify `cycle_id` stays `Đợt 1` and live `netBalance` + breakdown update immediately), and verify `pnpm db:check-balances` |
| Multi-creditor or `minimizeDebts = false` group where `{From}`'s `abs(netBalance)` differs from `{From} -> {To}` `transfer.amount`, or 15–20 member badminton group truncates rows / wraps VND numbers on `375pt` iPhone & exported `1170px` PNG | `5.5B.2.4` and `5.5B.3.4`: exercise 16-member group + 2-creditor split on both Web Canvas PNG and iOS `ImageRenderer` PNG in Light & Dark modes, verifying full dynamic height, exact integer VND, and visible `Phân bổ thanh toán` reconciliation |

## Swarm Topology & Hot-File Ownership

```text
Task 0 (Coordinator on `phase-5-5b`: clean tree + baseline verification)
  -> Wave 1 (`api-db` [share]): Tasks 5.5B.1.1 -> 5.5B.1.4 (locks DB, Core, API, openapi.json, vi.ts & Localizable.xcstrings)
  -> Coordinator lands Wave 1 on `phase-5-5b`, runs Stage 5.5B.1 Gate, broadcasts merged SHA
  -> Wave 2 in parallel:
       ├── `web` [share]: Tasks 5.5B.2.1 -> 5.5B.2.4 (`apps/web/**` excluding locked `vi.ts`)
       └── `ios` [share]: Tasks 5.5B.3.1 -> 5.5B.3.4 (`apps/ios/**` excluding locked `Localizable.xcstrings`)
  -> Coordinator lands `web` + `ios` onto `phase-5-5b` BEFORE `kill`, runs Stage 5.5B.4 (`run_workflow` audit, ADRs, full gates & handoff)
```

| Hot File | Single Owner | Rule |
|---|---|---|
| `packages/contract/openapi.json` | `api-db` (`5.5B.1.3`) | Additive only; frozen before Wave 2 starts |
| `apps/web/src/messages/vi.ts` & `apps/ios/.../Localizable.xcstrings` | `api-db` (`5.5B.1.4`) | Locked together and verified with `check-strings.sh` before Wave 2 so `web` and `ios` never collide on string keys |
| `apps/ios/SongPhangKit/Package.swift` & `AppShell/RootView.swift` | `ios` (`5.5B.3.1` / `5.5B.3.4`) | Single iOS worker owns all `apps/ios/**` edits |
| `docs/superpowers/runs/phase-5-5b/{progress,decisions,manual-checks}.md` | Coordinator | Updated on `phase-5-5b` after landing each wave |

## Files and Stage Order

| Order | Stage File | Owner | Tasks & Scope |
|---|---|---|---|
| `0 – 5.5B.1` | [5-5b-1-api-db-and-contracts.md](5-5b-1-api-db-and-contracts.md) | Coordinator (`Task 0`) + `api-db` | `Task 0` (re-baseline), `5.5B.1.1` (DB migration + static VietQR in `core`), `5.5B.1.2` (`transfer_proof` upload/GC, proof/channel/note on requests & transfers, `GET /settlement-vault`), `5.5B.1.3` (`settlement-cycles`, `cycleId` filter, `GET /balances/breakdowns`, `guest-link` + public `/guest-links/{token}*`, `openapi.json`), `5.5B.1.4` (lock `vi.ts` + `Localizable.xcstrings` & API Stage Gate) |
| `5.5B.2` | [5-5b-2-web.md](5-5b-2-web.md) | `web` (parallel with `5.5B.3`) | `5.5B.2.1` (Web data hooks, optional proof/channel/note in `Pay` & `Settle`, feed proof badge), `5.5B.2.2` (`Thanh toán` 3-pill UI: Vault, Cycles, Member Breakdown drawer + `Chi tiêu` cycle chip), `5.5B.2.3` (Guest Link sheet, `AppShell`/`AASA` updates, `/share/[token]` page), `5.5B.2.4` (2D `<canvas>` Light/Dark Share Card export & Web Stage Gate) |
| `5.5B.3` | [5-5b-3-ios.md](5-5b-3-ios.md) | `ios` (parallel with `5.5B.2`) | `5.5B.3.1` (`Domain` models/protocols, `Repositories` live & guest mappings, `PreviewSupport`), `5.5B.3.2` (`DesignSystem` proof/channel/share-card views + `PayView`/`SettleView`/feed proof badge), `5.5B.3.3` (`BalancesView` 3-pill Vault/Cycles/Breakdown + `GroupFeedView` cycle chip + `GroupContainerView`), `5.5B.3.4` (Guest Link sheet, `LinkRouter` + `GuestGroupView`, `ImageRenderer` `3x` Share Sheet & iOS Stage Gate) |
| `5.5B.4` | [5-5b-4-audit-docs-and-handoff.md](5-5b-4-audit-docs-and-handoff.md) | Coordinator | `5.5B.4.1` (`ADR-036`–`ADR-038`, `common.md` index update, `run_workflow` 3-angle audit, Debug + unsigned Release `xcodebuild` & leak check, disposable-DB full replay, `manual-checks.md`) |

**Handoff inputs:** `<SPEC>` = `docs/superpowers/specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md`; `<PLAN>` = `docs/superpowers/plans/2026-11-25-phase-5-5b`; `<BRANCH>` = `phase-5-5b`; `<LAST TASK>` = `5.5B.4.1`. Run artifacts live under `docs/superpowers/runs/phase-5-5b/`.

## Standard Verification Commands

```sh
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
