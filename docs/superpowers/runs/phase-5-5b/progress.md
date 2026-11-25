# Wave 5.5B — Run Progress

- Branch: `phase-5-5b`
- Baseline `main`: `8250d8e` (`6cd0755`, PR #3 Wave 5.5A merged)
- Spec: `docs/superpowers/specs/2026-11-25-phase-5-5b-settlements-and-sharing-design.md`
- Plan: `docs/superpowers/plans/2026-11-25-phase-5-5b/00-overview.md`
- Status: Wave 1 (`api-db`) launching via `/swarm`

## Tasks

- [x] 0 — Re-baseline `main` on `phase-5-5b`
- [ ] 5.5B.1.1 — Database migration (`settlement_requests`, `settlement_cycles`, `transactions`, `groups`) & static VietQR in `@songphang/core`
- [ ] 5.5B.1.2 — Transfer proof upload/GC protection, optional proof/channel/note on requests & transfers, `accountQrPayload` & `GET /settlement-vault`
- [ ] 5.5B.1.3 — Settlement cycles, `cycleId` feed filter, member debt breakdowns, guest links & `openapi.json`
- [ ] 5.5B.1.4 — Lock Wave 5.5B Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5B.1 Gate
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
