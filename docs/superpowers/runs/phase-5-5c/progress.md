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

- [ ] **Task 5.5C.1.1 — `@songphang/core` pure integer math (`extras`, `households`, `recurring`) & DB migration (`0033`)**
- [ ] **Task 5.5C.1.2 — Generalized `SplitInput.extras` validation & `POST /groups/{groupId}/transactions/extras/preview`**
- [ ] **Task 5.5C.1.3 — `households` & `recurring-expenses` endpoints, `pg-boss` worker job, cross-surface household balances & `openapi.json`**
- [ ] **Task 5.5C.1.4 — Lock Wave 5.5C Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5C.1 Gate**
