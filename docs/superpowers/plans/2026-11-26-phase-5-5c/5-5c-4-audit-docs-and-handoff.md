# Wave 5.5C — Stage 5.5C.4: Parallel Audit, Standing Docs, ADRs & Handoff

> Runs on `phase-5-5c` **after** the Coordinator lands both Wave 2 branches (`web` + `ios`) and **before** terminating Swarm workers or handing off to the project owner.

### Task 5.5C.4.1: Record ADRs, run multi-angle `run_workflow` audit, execute full release gates & write owner manual-check guide

**Files:**
- Modify: `docs/04-adr.md`
- Modify: `docs/superpowers/plans/2026-11-15-common.md` (add `5.5C` row to Plans table)
- Modify: `docs/superpowers/runs/phase-5-5c/{progress,decisions,manual-checks}.md`

**Interfaces:**
- Consumes: Integrated `phase-5-5c` HEAD containing Stages `5.5C.1`, `5.5C.2`, and `5.5C.3`.
- Produces:
  - `ADR-039` (Generalized `split_input.extras` with Equal Water-Filling Default & Server Percentage Preview), `ADR-040` (Recurring Expenses `fixed`/`variable` on `pg-boss` & Household Representative Consolidation), and `ADR-041` (iOS App Group Snapshot Store, Shared Keychain Migration & Dual-Delivery Share Extension Handoff) appended to `docs/04-adr.md`.
  - Clean 3-angle `run_workflow` audit report (`must_fixes: []`), verified Debug & unsigned Release iOS builds (app + both embedded `.appex` extensions), disposable-DB end-to-end replay, and complete Vietnamese `manual-checks.md` for the project owner.

- [ ] **Step 1: Append `ADR-039`, `ADR-040`, and `ADR-041` to `docs/04-adr.md` and add Wave `5.5C` to `docs/superpowers/plans/2026-11-15-common.md`**
  Match the exact concise format of `ADR-036`–`ADR-038`.
- [ ] **Step 2: Run 3-angle read-only `run_workflow` audit (`Security`, `Money & Layer Invariants`, `Web/iOS & Extension Parity`)**
  Follow `.agent/skills/songphang-swarm-orchestrator/references/swarm-briefs-and-workflow.md` against `git diff main...HEAD`:
  1. **Security (`security-review`):** Outsider `404`s on `/extras/preview`, `/recurring-expenses*`, and `/households*`; household `ADR-022` rule (partner allowed on outgoing `fromHousehold` `settlement_request`, blocked `403` on incoming `confirm`); `viewer` blocked `403` on `/recurring-expenses/*/skip`; Keychain-only session token (zero token in `UserDefaults` or App Group files); sign-out wiping `SharedState/` + `shortcutItems`; strict `LinkRouter.appActionRoute` validation; `ImageIO` `<= 5 MiB` cap; zero `dangerouslySetInnerHTML`.
  2. **Money & Layer Invariants:** Zero client-side `%` multiplication, rounding, household netting, or schedule date math; `Money` integer purity; water-filling non-negative shares summing to `amount`; legacy `items` proportional preservation; `SongPhangWidgetExtension` linking only `Domain` + `DesignSystem`; zero `*.test.*`/`*.spec.*` files; zero emoji.
  3. **Web/iOS & String Parity:** 1:1 parity across Manual `extras`, Recurring Expenses, and Households in Light & Dark modes, `check-strings.sh` (`0 missing, 0 differing`), and Widget/Share Extension UI fidelity.
  Fix any discovered defects as dedicated `fix(...)` commits before proceeding.
- [ ] **Step 3: Run complete verification & release-hygiene gate on `phase-5-5c` HEAD**
  - `pnpm check`
  - `pnpm contract:check` (`0` breaking changes)
  - `pnpm build`
  - `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`)
  - `xcrun swift-format lint --strict --recursive apps/ios` (empty output)
  - Simulator Debug `xcodebuild` (`BUILD SUCCEEDED`, verifying `SongPhang.app/PlugIns/SongPhangShareExtension.appex` and `SongPhangWidgetExtension.appex` exist)
  - Simulator unsigned Release `xcodebuild` (`-configuration Release CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build` -> `BUILD SUCCEEDED`) and verify `RELEASE_LEAK_MATCH_COUNT=0` across `SongPhang.app` and both `.appex` binaries for dev/fake endpoints.
  - Disposable Postgres 17 full Phase 1–5.5C replay (including `process-recurring` fixed + variable runs and household settlement closeout) + `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` -> `All groups balanced`.
- [ ] **Step 4: Write `docs/superpowers/runs/phase-5-5c/{progress,decisions,manual-checks}.md` and commit**
  Include numbered Vietnamese manual-check steps for physical iPhone + Web covering: (1) Three Koala `346.000 đ + VAT 8%` & GrabFood `Ship + Giảm giá` water-filling on `S8`, (2) fixed auto-post & variable due-prompt recurring bills in `Quỹ & Thống kê` / `Tổng quan`, (3) `Hộ gia đình / Cặp đôi` setup in `S10`, partner `"Tôi đã chuyển"`, representative `"Đã nhận"`, `/share/{token}` & `Nhắc nợ khéo` card, (4) sharing receipt & bank transfer screenshots straight from Zalo / Photos via `SongPhangShareExtension`, and (5) `.systemSmall` & `.systemMedium` Home Screen Widgets (Light/Dark + `"Ẩn số tiền trên Widget"` + sign-out wipe) and App Icon Quick Actions. Commit:
  `git commit -m "docs(5.5c): record ADRs, verification gates, and manual check guide"`
