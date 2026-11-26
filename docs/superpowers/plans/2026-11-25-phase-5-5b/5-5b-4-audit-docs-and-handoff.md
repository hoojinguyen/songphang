# Wave 5.5B — Stage 5.5B.4: Parallel Audit, Standing Docs, ADRs & Handoff

> Runs on `phase-5-5b` **after** the Coordinator lands both Wave 2 branches (`web` + `ios`) and **before** terminating Swarm workers or handing off to the project owner.

### Task 5.5B.4.1: Record ADRs, run multi-angle `run_workflow` audit, execute full release gates & write owner manual-check guide

**Files:**
- Modify: `docs/04-adr.md`
- Modify: `docs/superpowers/plans/2026-11-15-common.md` (add `5.5B` row to Plans table)
- Modify: `docs/superpowers/runs/phase-5-5b/{progress,decisions,manual-checks}.md`

**Interfaces:**
- Consumes: Integrated `phase-5-5b` HEAD containing Stages `5.5B.1`, `5.5B.2`, and `5.5B.3`.
- Produces:
  - `ADR-036` (Cumulative Settlement Cycles via Nullable `transactions.cycle_id` Assignment & Direct Past-Row Editability), `ADR-037` (Opt-In Revocable Guest Read-Only Links & Server-Authoritative Member Debt Breakdowns), and `ADR-038` (Zero-Dependency Client-Side `3x` Share Card Rendering) appended to `docs/04-adr.md`.
  - Clean 3-angle `run_workflow` audit report (`findings: []` on high/medium severity issues), verified Debug & unsigned Release iOS builds, disposable-DB end-to-end replay, and complete Vietnamese `manual-checks.md` for the project owner.

- [ ] **Step 1: Append `ADR-036`, `ADR-037`, and `ADR-038` to `docs/04-adr.md` and add Wave `5.5B` to `docs/superpowers/plans/2026-11-15-common.md`**
  Match the exact concise format of `ADR-034` and `ADR-035`.
- [ ] **Step 2: Run 3-angle read-only `run_workflow` audit (`Security`, `Money & Layer Invariants`, `Web/iOS & Copy Parity`)**
  Follow `.agent/skills/songphang-swarm-orchestrator/references/swarm-briefs-and-workflow.md` against `git diff main...HEAD`:
  1. **Security (`security-review`):** Outsider `404`s, guest-token entropy & zero token logging, `no-store` headers, transfer-proof attachment isolation (`404` on `/guest-links/{token}/attachments/{id}`), viewer upload/hijack guards, archived-group `DELETE /guest-link` revoke, zero `dangerouslySetInnerHTML`.
  2. **Money & Layer Invariants:** Zero client-side split/balance/VietQR math, `Money` integer purity, exact `carryOverBalance + sum(lines.delta) + postCycleDelta === netBalance` identity, `SongPhangKit` module isolation, zero `*.test.*`/`*.spec.*` files, zero emoji.
  3. **Web/iOS & String Parity:** 1:1 UI parity across all 5 Wave 5.5B capabilities in Light & Dark modes, `1170px` (`3x`) share cards without rounding, `/share/{token}` parity.
  Fix any discovered defects as dedicated `fix(...)` commits before proceeding.
- [ ] **Step 3: Run complete verification & release-hygiene gate on `phase-5-5b` HEAD**
  - `pnpm check`
  - `pnpm contract:check`
  - `pnpm build`
  - `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`)
  - `xcrun swift-format lint --strict --recursive apps/ios` (empty output)
  - Simulator Debug `xcodebuild` (`BUILD SUCCEEDED`)
  - Simulator unsigned Release `xcodebuild` (`-configuration Release CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation build` -> `BUILD SUCCEEDED`) and verify `RELEASE_LEAK_MATCH_COUNT=0` on the built `.app` binary for dev/fake endpoints.
  - Disposable Postgres 17 full Phase 1–5.5B replay + `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` -> `All groups balanced`.
- [ ] **Step 4: Write `docs/superpowers/runs/phase-5-5b/{progress,decisions,manual-checks}.md` and commit**
  Include numbered Vietnamese manual-check steps for physical iPhone + Web (normal & edge cases: 1-tap no-proof settle, linked-viewer proof upload & lightbox confirm, Vault filters, `Chốt đợt` + immediate `/share/{token}` in Zalo/incognito + editing an item in a closed cycle + revoking guest link, and 1-tap `Tổng kết nhóm` / `Nhắc nợ khéo` Share Sheet export in Light & Dark for a 15+ member group). Commit:
  `git commit -m "docs(5.5b): record ADRs, verification gates, and manual check guide"`
