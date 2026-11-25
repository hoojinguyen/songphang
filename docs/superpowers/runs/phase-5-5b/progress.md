# Wave 5.5B — Run Progress

- Branch: `phase-5-5b`
- Baseline `main`: `8250d8e` (`6cd0755`, PR #3 Wave 5.5A merged)
- Spec: `docs/superpowers/specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md`
- Plan: `docs/superpowers/plans/2026-11-25-phase-5-5b/00-overview.md`
- Status: Wave 1 (`5.5B.1.1`–`5.5B.1.4`) landed onto `phase-5-5b`; preparing Wave 2 (`web` + `ios` in parallel)

## Tasks

- [x] 0 — Re-baseline `main` on `phase-5-5b`
- [x] 5.5B.1.1 — Database migration (`settlement_requests`, `settlement_cycles`, `transactions`, `groups`) & static VietQR in `@songphang/core`
- [x] 5.5B.1.2 — Transfer proof upload/GC protection, optional proof/channel/note on requests & transfers, `accountQrPayload` & `GET /settlement-vault`
- [x] 5.5B.1.3 — Settlement cycles, `cycleId` feed filter, member debt breakdowns, guest links & `openapi.json`
- [x] 5.5B.1.4 — Lock Wave 5.5B Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5B.1 Gate
- [ ] 5.5B.2.1 — Web data hooks, optional proof/channel/note in `Pay` & `Settle`, and Transfer proof badge
- [ ] 5.5B.2.2 — Web `Thanh toán` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Breakdown drawer & `Chi tiêu` cycle chip
- [ ] 5.5B.2.3 — Web Guest Link management UI, `AppShell` / `AASA` public routing, and `/share/[token]` page
- [ ] 5.5B.2.4 — Web 1-tap HTML5 2D `<canvas>` Share Card Export (`Tổng kết nhóm` & `Nhắc nợ khéo`) & Stage 5.5B.2 Web Gate
- [ ] 5.5B.3.1 — iOS `Domain` models & repository protocols, `Repositories` live/guest mappings, and `PreviewSupport`
- [ ] 5.5B.3.2 — iOS `DesignSystem` proof/channel components, optional proof/channel/note in `PayView` & `SettleView`, and feed Transfer badge
- [ ] 5.5B.3.3 — iOS `BalancesView` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Member Breakdown sheet & `Chi tiêu` cycle chip
- [ ] 5.5B.3.4 — iOS Guest Link sheet, zero-login `/share/{token}` routing + `GuestGroupView`, and `ImageRenderer` (`3x`) Share Card Export & Stage 5.5B.3 Gate
- [ ] 5.5B.4.1 — Record ADRs, run multi-angle `run_workflow` audit, execute full release gates & write owner manual-check guide

## Task Reports

### Task 0 — Re-baseline `main` on `phase-5-5b`

- Commit: pending baseline commit on `phase-5-5b` above `44487f6` (`main` `8250d8e`).
- `pnpm check`: passed (biome 538 files 0 errors / 3 pre-existing img warnings, 8 workspace typechecks passed, `OpenAPI contract snapshot is up to date.`).
- `pnpm build`: passed (Next.js production build succeeded).
- `./apps/ios/Scripts/check-strings.sh`: `OK: 717 web keys verified, 0 missing, 0 differing.`
- `xcrun swift-format lint --strict --recursive apps/ios`: passed (0 output).
- `xcodebuild` Simulator Debug (`-skipPackagePluginValidation build`): `BUILD SUCCEEDED`.
- Disposable DB (`songphang_phase55b_t0` on `songphang-db-1` port `54329`): `Migrations applied`, `Development users seeded`, `check-balances.ts` ran (`No groups`), dropped cleanly.

### Tasks 5.5B.1.1–5.5B.1.4 — DB, Core, Additive v1 API, OpenAPI & Copy Lock (`api-db`)

- Commits: `fef4e3e` (`5.5B.1.1`), `073cee2` (`5.5B.1.2`), `1175def` (`5.5B.1.3`), `834976e` (`5.5B.1.4`).
- `pnpm check`: passed (Biome 555 files 0 errors, 8 workspace typechecks passed, `OpenAPI contract snapshot is up to date.`).
- `pnpm build`: passed (Next.js production build succeeded).
- `./apps/ios/Scripts/check-strings.sh`: `OK: 787 web keys verified, 0 missing, 0 differing.`
- Exercises verified on disposable Postgres DB + isolated `:4115` API server (see board `#3`):
  - `buildStaticVietQrPayload` & `groupTransferPurpose`: EMVCo `010211`, omits tag `54`, CRC verified, ASCII fallback `"SP Thanh toan"`.
  - DB constraints & FK `ON DELETE SET NULL`, 1-tap `POST /settlement-requests` (`201`), linked `viewer` `?purpose=transfer_proof` (`201`) vs unlinked `viewer` (`403`) vs cross-user proof hijack (`403`), `+48h` `runCleanupAttachments` preserving pending proof while purging unbound orphan, `confirm` forwarding proof/channel/note onto `transfer` + single deduplicated `GET /settlement-vault` entry, `check-balances.ts` -> `All groups balanced`.
  - Closeout `Đợt 1` leaving `pending` expense `cycle_id = null`, `422 CYCLE_EMPTY`, `auto` breakdown post-closeout + post-closeout transfer (`invariantOk: true`), editing closed-cycle expense preserving `cycle_id` & updating live `netBalance`, `409 CYCLE_NOT_LATEST` vs `204` reopen latest, guest expense attachment `200` vs transfer proof `404`, archived-group `DELETE /guest-link` `200` immediately returning `404` on `/guest-links/{token}*`, full Spec §8 permission matrix (Cookie + Bearer).
- Security review: checked items 1–6 & 8; no issues found.
- Not verified in Wave 1: `pnpm audit --prod` (no dependency changes) and iOS client UI (owned by Wave 2 `ios`).
