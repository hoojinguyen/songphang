# Sòng Phẳng Wave 5.5A (UI/UX v2 & Cross-Group Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` for the continuous phase run described in `AGENTS.md` §12. Use the project's `execute-task` and `security-review` skills for each implementation task. Track the checkboxes in `docs/superpowers/runs/phase-5-5a/progress.md`.
>
> **Status (2026-11-24):** Approved by the project owner. Antigravity owns implementation on branch `phase-5-5a`. Codex owns advisor review. The project owner performs physical iPhone and Web Desktop manual acceptance before merge.

**Goal:** Deliver Design System v2 (Light + Dark Mode, bundled `Be Vietnam Pro` `.ttf` fonts on iOS, tabular digits), close `TD-001` and `TD-003`–`TD-007`, ship the 4-tab App Shell, 3-segment Group Detail shell, full-width transaction cards, responsive Web Desktop 2–3 column layout, Cross-Group Overview & Personal Ledger, Group Archive & Clone, iOS Haptics & Swipe Actions, and hold-to-grow **"Bơm hình"** with 100% iOS/Web parity.

**Architecture:**
- **API & DB:** One additive migration (`groups.archived_at`) plus strictly additive `/api/v1` endpoints (`archive`, `unarchive`, `clone`, `GET /me/overview`, `GET /me/transactions`, `myDelta` on transactions, `status`/`role`/`pendingActionCount` on `GET /groups`, `409 GROUP_ARCHIVED` write guard inside the group lock).
- **Web (`apps/web/`):** Responsive Next.js App Shell with Light/Dark CSS semantic tokens, static `/theme-init.js` (no `dangerouslySetInnerHTML`), mobile bottom 4-tab bar (`< 1024px`), 2–3 column Desktop workspace (`>= 1024px` / `>= 1280px`), 3-segment group layout preserving all deep URLs, full-width feed cards, and pointer/touch "Bơm hình".
- **iOS (`apps/ios/`):** `SongPhangKit` preserves strict compiler-enforced boundaries (`apps/ios/AGENTS.md` §3): new `OverviewFeature` depends only on `Domain`, `DesignSystem`, `PreviewSupport`; 3-segment `GroupContainerView` lives in `AppShell`; `DesignSystem` provides dynamic Light/Dark `Tokens`, registered `Be Vietnam Pro` `.ttf` typography, and `Haptics`; `SnapshotStore` caches user-scoped `overview.json` alongside existing snapshots.

**Tech stack:** TypeScript, Hono/OpenAPI, Drizzle ORM, PostgreSQL 17, Next.js 16 / React / Tailwind CSS v4, Swift 6, SwiftUI (iOS 26 minimum), Apple Swift OpenAPI Generator/Runtime/URLSession.

**Specs:**
- [Phase 5.5 Overview Design](../../specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md)
- [Wave 5.5A Design](../../specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md)
- [iOS Codebase Architecture](../../specs/2026-11-16-ios-codebase-architecture-design.md)
- [Common Phase Rules](../2026-11-15-common.md)

## Global Constraints

- **Branch & isolation:** Work on branch `phase-5-5a` created from `main` (at or after `378df4d`). Never touch `main`, never push, never deploy or contact live external services. Use disposable databases and temporary upload directories for all exercises.
- **No automated tests (`AGENTS.md` §6):** Never install test libraries or create `*.test.*` / `*.spec.*` files. Every task runs type/lint/contract/build gates plus real manual HTTP, DB, browser, or Simulator exercises and records exact observed outputs.
- **Strictly additive `/api/v1`:** Never break existing OpenAPI schemas, cookie auth, Bearer auth, or existing Web URLs (`/g/[groupId]/*`, `/join/[token]`, `/notifications`, `/account`). Outsiders receive `404` for group resources.
- **Money invariants:** VND integers only end to end. Server owns `myDelta`, `netBalance`, `totalOwedToMe`, `totalIOwe`, and all split previews. On iOS and Web, never add floating-point arithmetic, multiplication, or division to `Money` (including during "Bơm hình"). `sum(myDelta ?? 0) === myBalance` across every group's counted transactions, and `pnpm db:check-balances` prints `All groups balanced`.
- **iOS module boundaries (`apps/ios/AGENTS.md` §3):** Feature targets import only `Domain`, `DesignSystem`, and `PreviewSupport`. Never let a feature import another feature, `Repositories`, or `GeneratedAPI`.
- **Security (`AGENTS.md` §9):** Never use `dangerouslySetInnerHTML` on Web (use static `apps/web/public/theme-init.js` for theme pre-init). Never log payment account numbers or secrets in server logs or activity records. Clear `overview.json` and all user snapshots on sign-out, session revocation, or account deletion.
- **String parity & no emoji:** Zero emoji anywhere in code, strings, or UI. Every user-facing string in `apps/web/src/messages/vi.ts` matches `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` character-for-character via `./apps/ios/Scripts/check-strings.sh`.
- **No new package dependencies:** Add no npm or SwiftPM packages. The only new bundled assets are static `Be Vietnam Pro` `.ttf` weights (`400`–`900`, SIL OFL 1.1) and `LICENSE.txt` under `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/`.

## Review Focus

| Risk | Owning Exercise |
|---|---|
| An archived group allows a write mutation or bypasses the group lock | `5.5A.1.1` and `5.5A.1.4`: exercise `409 GROUP_ARCHIVED` across every group write endpoint |
| Removed users or revoked sessions still see group data in Overview, Personal Ledger, or iOS snapshots | `5.5A.1.4` and `5.5A.3.4`: remove a member/user and revoke session mid-flight, verify `overview`/`me/transactions` exclusion and snapshot deletion |
| `myDelta` drifts from `balances` on income, transfer, multi-payer, deleted, or rejected transactions | `5.5A.1.3` and `5.5A.1.4`: verify `sum(myDelta ?? 0) === myBalance` on every member across all transaction states |
| Group `clone` leaks other users, transactions, invites, or logs bank account numbers | `5.5A.1.2`: inspect cloned group DB rows, activity `before`/`after` payloads, and server stdout |
| Dark Mode fails contrast, Web flashes light theme before hydration, or `TD-001` weakens production origin rules | `5.5A.2.1` and `5.5A.2.3`: verify WCAG token pairs, reload with Dark preference, verify `.local` dev origin `200` vs foreign origin `403` and production `NODE_ENV` guard |
| Dense groups (`7–20` members) clip or wrap currency digits on `375pt` iPhone width (`TD-003`, `TD-005`, `TD-006`) | `5.5A.4.1`, `5.5A.4.2`, `5.5A.4.4`: capture Simulator screenshots at compact portrait width and accessibility Dynamic Type |
| iOS feature boundaries violated or Debug artifacts leak into Release build | `5.5A.5.2`: verify `xcodebuild` Debug & unsigned Release builds plus `RELEASE_LEAK_MATCH_COUNT=0` audit |

## Files and Stage Order

| Order | Stage File | Tasks & Scope |
|---|---|---|
| `0 – 5.5A.1` | [5-5a-1-api-and-db.md](5-5a-1-api-and-db.md) | `Task 0` (re-baseline), `5.5A.1.1` (`groups.archived_at` + guard), `5.5A.1.2` (`archive`/`unarchive`/`clone` + `GET /groups`), `5.5A.1.3` (`GET /me/overview`, `GET /me/transactions`, `myDelta`, OpenAPI), `5.5A.1.4` (API gate) |
| `5.5A.2` | [5-5a-2-design-system.md](5-5a-2-design-system.md) | `5.5A.2.1` (Web Light/Dark tokens, theme toggle, tabular nums, `TD-001`, `TD-004`), `5.5A.2.2` (iOS `Be Vietnam Pro` `.ttf`, Dynamic Light/Dark `Tokens`, `Haptics`, `TD-004`, strings parity), `5.5A.2.3` (Design System gate) |
| `5.5A.3` | [5-5a-3-shell-overview-archive.md](5-5a-3-shell-overview-archive.md) | `5.5A.3.1` (iOS `Domain`, `Repositories`, `SnapshotStore`, `PreviewSupport`), `5.5A.3.2` (iOS 4-tab `TabView`, `OverviewFeature`, Archive/Clone UI), `5.5A.3.3` (Web 4-tab shell, `/`, `/groups`, `/ledger`, Archive/Clone), `5.5A.3.4` (Shell & Overview gate) |
| `5.5A.4` | [5-5a-4-group-v2-and-polish.md](5-5a-4-group-v2-and-polish.md) | `5.5A.4.1` (iOS `GroupContainerView` 3-segment shell, full-width cards `TD-006`, Swipe & Haptics), `5.5A.4.2` (iOS `TD-003`, `TD-005`, `TD-007` & "Bơm hình"), `5.5A.4.3` (Web 3-segment shell, full-width cards, Quick Entry wrap, "Bơm hình"), `5.5A.4.4` (Group & Polish gate) |
| `5.5A.5` | [5-5a-5-desktop-and-handoff.md](5-5a-5-desktop-and-handoff.md) | `5.5A.5.1` (Web Desktop 2–3 column responsive shell & right inspector), `5.5A.5.2` (Final parity gate, unsigned Release audit & owner handoff) |

**Handoff inputs:** `<SPEC>` = `docs/superpowers/specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md` (with `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md`); `<PLAN>` = `docs/superpowers/plans/2026-11-24-phase-5-5a`; `<BRANCH>` = `phase-5-5a`; `<LAST TASK>` = `5.5A.5.2`. Run artifacts live under `docs/superpowers/runs/phase-5-5a/`.

**Advisor work:** Before starting the run, ensure branch `phase-5-5a` is created from `main` (with initial `docs/superpowers/runs/phase-5-5a/` headings) and commit static `Be Vietnam Pro` `.ttf` weights (`400`–`900`) + `LICENSE.txt` if owner delegates asset placement. After run completion, reconcile `docs/05-api-spec.md`, `docs/05-database-design.md`, `docs/06-ux-ui/user-flows.md`, and `docs/tech-debt.md` following physical device acceptance.

## Standard Verification Commands

```sh
pnpm check
pnpm build
./apps/ios/Scripts/check-strings.sh
xcrun swift-format lint --strict --recursive apps/ios
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
DATABASE_URL="<disposable_db_url>" pnpm --filter @songphang/db exec tsx src/check-balances.ts
```
