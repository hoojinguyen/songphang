# Wave 5.5B — Run Progress

- Branch: `phase-5-5b`
- Baseline `main`: `8250d8e` (`6cd0755`, PR #3 Wave 5.5A merged)
- Spec: `docs/superpowers/specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md`
- Plan: `docs/superpowers/plans/2026-11-25-phase-5-5b/00-overview.md`
- Status: Complete (Wave 1 API/DB/Contracts, Wave 2A Web, Wave 2B iOS, 3-angle audit remediation, ADRs, and integrated release gates passed)

## Tasks

- [x] 0 — Re-baseline `main` on `phase-5-5b`
- [x] 5.5B.1.1 — Database migration (`settlement_requests`, `settlement_cycles`, `transactions`, `groups`) & static VietQR in `@songphang/core`
- [x] 5.5B.1.2 — Transfer proof upload/GC protection, optional proof/channel/note on requests & transfers, `accountQrPayload` & `GET /settlement-vault`
- [x] 5.5B.1.3 — Settlement cycles, `cycleId` feed filter, member debt breakdowns, guest links & `openapi.json`
- [x] 5.5B.1.4 — Lock Wave 5.5B Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5B.1 Gate
- [x] 5.5B.2.1 — Web data hooks, optional proof/channel/note in `Pay` & `Settle`, and Transfer proof badge
- [x] 5.5B.2.2 — Web `Thanh toán` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Breakdown drawer & `Chi tiêu` cycle chip
- [x] 5.5B.2.3 — Web Guest Link management UI, `AppShell` / `AASA` public routing, and `/share/[token]` page
- [x] 5.5B.2.4 — Web 1-tap HTML5 2D `<canvas>` Share Card Export (`Tổng kết nhóm` & `Nhắc nợ khéo`) & Stage 5.5B.2 Web Gate
- [x] 5.5B.3.1 — iOS `Domain` models & repository protocols, `Repositories` live/guest mappings, and `PreviewSupport`
- [x] 5.5B.3.2 — iOS `DesignSystem` proof/channel components, optional proof/channel/note in `PayView` & `SettleView`, and feed Transfer badge
- [x] 5.5B.3.3 — iOS `BalancesView` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Member Breakdown sheet & `Chi tiêu` cycle chip
- [x] 5.5B.3.4 — iOS Guest Link sheet, zero-login `/share/{token}` routing + `GuestGroupView`, and `ImageRenderer` (`3x`) Share Card Export & Stage 5.5B.3 Gate
- [x] 5.5B.4.1 — Record ADRs, run multi-angle `run_workflow` audit, execute full release gates & write owner manual-check guide

## Task Reports

### Task 0 — Re-baseline `main` on `phase-5-5b`

- Commit: `98dd771` (`docs(run): re-baseline wave 5.5b`) above `44487f6` (`main` `8250d8e`).
- `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh` (`717` keys), `xcrun swift-format lint --strict`, Simulator Debug `xcodebuild`, and disposable DB `songphang_phase55b_t0` migration/seed/`check-balances.ts` all passed.

### Tasks 5.5B.1.1–5.5B.1.4 — DB, Core, Additive v1 API, OpenAPI & Copy Lock (`api-db`)

- Commits: `fef4e3e` (`5.5B.1.1`), `073cee2` (`5.5B.1.2`), `1175def` (`5.5B.1.3`), `834976e` (`5.5B.1.4`), plus audit refactor `a906f55` (cherry-picked from `b063ef0`).
- Verified on disposable Postgres DB + isolated `:4115` API server: static EMVCo `010211` VietQR, DB constraints & `ON DELETE SET NULL`, 1-tap `POST /settlement-requests` (`201`), linked `viewer` `?purpose=transfer_proof` (`201`) vs unlinked `viewer` (`403`) vs cross-user hijack (`403`), `+48h` `runCleanupAttachments` keeping pending proofs, `confirm` forwarding proof/channel/note into deduplicated `GET /settlement-vault`, `POST /settlement-cycles` leaving `pending` approvals `cycle_id = null`, `auto` breakdown post-closeout + post-closeout transfer (`invariantOk: true`), editing closed-cycle expenses preserving `cycle_id`, archived-group `DELETE /guest-link` (`200`) immediately revoking `/guest-links/{token}*` (`404`), guest expense attachment `200` vs transfer proof `404`, and Spec §8 permission matrix (Cookie + Bearer).

### Tasks 5.5B.2.1–5.5B.2.4 — Web Implementation (`web`)

- Commits: `765d888` (`5.5B.2.1`), `44d7ebf` (`5.5B.2.2`), `db190ef` (`5.5B.2.3`), `4e43082` (`5.5B.2.4`), plus audit fix `f99bb58` (cherry-picked from `ebf0a91`).
- Live headless Chrome + `:4116` API + `:3116` Next.js exercise on 16-member `G4 Badminton 2026` group: 3-pill `Thanh toán` (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), `MemberBreakdownSheet` (`-185.775 đ`), `Sổ thanh toán` summary & filters, unauthenticated `/share/[token]` (`leakedAuthCalls: []`, `QrCard` SVG, expense modal receipt `200`, transfer proof `404`, instant `404` after revoke), and `1170px` (`3x`) Light/Dark 2D `<canvas>` PNG exports (`1170x3309px` summary, `1170x2772px` reminder) with `All groups balanced`.

### Tasks 5.5B.3.1–5.5B.3.4 — iOS `SongPhangKit` Parity (`ios`)

- Commits: `8342cad` (`5.5B.3.1`), `d1fc41f` (`5.5B.3.2`), `80a5840` (`5.5B.3.3`), `3aaa041` (`5.5B.3.4`), plus audit fix `be6bc32` (cherry-picked from `fab8f24`).
- Simulator (`iPhone 17e`, `375pt`) + live `:4117` API verification: signed-out `GuestGroupView` (`G4 Badminton 2026`, 15 transfers, itemized breakdown, QR, `404` revocation), `Thanh toán` 3-pill sub-navigation, `MemberBreakdownSheetView`, `CycleFilterChipView`, and `ImageRenderer` (`scale = 3.0`, `1170px`) Light Summary & Dark Reminder PNGs.

### Task 5.5B.4.1 — Parallel Audit, ADRs & Integrated Release Gates

- Recorded `ADR-036`, `ADR-037`, and `ADR-038` in `docs/04-adr.md`, and updated `docs/superpowers/plans/2026-11-15-common.md`.
- 3-angle `run_workflow` audit (`Security & Auth`, `Money & Architecture`, `Web/iOS Parity & Hygiene`) flagged 7 `must_fix` and 8 `should_fix` findings across Web, iOS, and API helpers; all were fixed in commits `a906f55`, `f99bb58`, and `be6bc32`.
- Integrated `phase-5-5b` verification after final code edits (`be6bc32`):
  - `pnpm check`: passed (Biome `571` files, 0 errors; all 8 TS projects typecheck; `OpenAPI contract snapshot is up to date.`).
  - `pnpm build`: passed (Next.js 16.4.6 production build including `ƒ /share/[token]`).
  - `./apps/ios/Scripts/check-strings.sh`: `OK: 787 web keys verified, 0 missing, 0 differing.`
  - `xcrun swift-format lint --strict --recursive apps/ios`: passed (0 output).
  - `xcodebuild` Simulator Debug (`-skipPackagePluginValidation`): passed (exit 0, zero warnings on Wave 5.5B files).
  - `xcodebuild` Simulator unsigned Release (`CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation`): passed (exit 0); Release bundle audit `DEV_ROUTE_MATCHES=0`, `ATS_FREE_OK`, `PRIVACY_INFO_OK`.
  - Disposable DB `songphang_phase55b_final` replay + `check-balances.ts`: `resolvedFocus: { kind: "cycle", label: "Đợt 1" }`, `lanNet: -50000`, `invariantEq: true`, `vaultConfirmed: 50000`, `hasStaticQr: true`, `guestStatus: 200`, `revokedStatus: 404`, `All groups balanced` (`sum 0; mismatches 0`), DB dropped.
  - Hygiene checks: `TEST_FILES=0`, `EMOJI_HITS=0`.

## Gate Not Passed

- None. All automated, build, balance, and API replay gates passed on integrated `phase-5-5b`.

## Not Verified

- Interactive system dialogs in live browsers/Simulator: `navigator.share({ files })` mobile Share Sheet, iOS `ShareLink` / `PHPhotoLibrary` save prompt, `PhotosPicker` UI selection inside `PayView`/`SettleView`, `PayContent`/`SettlementForm` form clicks in headless Chrome, and HTTPS Universal Link `/share/{token}` handoff via `apple-app-site-association` (underlying API uploads/submissions, `ImageRenderer` / `<canvas>` PNG exports, and `LinkRouter` parsing were verified; physical-device interactive checks are in `manual-checks.md`).
- `pnpm audit --prod` was not run (zero new dependencies added).

## Out of Scope

- Pre-existing `#ActorIsolatedCall` Swift 6 warnings in Wave 5.5A/Phase 3 files (`ExpenseFormView.swift`, `ReceiptCaptureSheet.swift`, `ReceiptReviewView.swift`) and 3 pre-existing `lint/performance/noImgElement` Biome warnings in `PhotoRow.tsx`, `ReceiptScanStates.tsx`, and `PhotoViewer.tsx`.
