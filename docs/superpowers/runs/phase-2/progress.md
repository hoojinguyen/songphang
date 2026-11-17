# Phase 2 run — progress

## Status — advisor preparation resumed

Date: 2026-11-17. Owner authorized preparation and continuous execution in the current session. This authorization supersedes the draft approval labels in the existing specs. No implementation has started.

Repository inspection: clean local `main` and `origin/main` both pointed at `30d27bc`, the terminal SSE cancellation fix. `phase-2` did not exist and was created from local `main`. The separate `songphang-ios-ui` worktree on `ios-ui` was not modified.

### Approach

- Create only the three authorized Phase 2 run records while investigating the mandatory advisor input.
- Obtain the complete bank/BIN mapping from official public NAPAS documentation before creating `packages/core/src/banks.ts`.
- Preserve the fixed QR references, existing 75 reader samples, Phase 1 security fixes and local database.
- Record unavailable input explicitly; do not turn an incomplete or third-party list into an authoritative dataset.

### Blocking prerequisite

The complete authoritative NAPAS bank dataset has not been obtained. See decision D1 for exact URLs and observed access results. The common plan's Advisor deliverables section explicitly says a run does not start without its data files. The owner also explicitly requires reporting this blocker instead of substituting dummy data.

Advisor preparation remains incomplete: no bank source file, fund-sample additions, standing-document amendments or completed-preparation commit. The record-only checkpoint is identified by the unique commit subject `docs(run): record phase 2 preparation blocker`; it does not represent completed advisor preparation or Task 0.

## Task checklist

- [x] Advisor preparation — commit reference `docs(phase-2): prepare approved real-money phase`
- [ ] Task 0 — complete re-baseline and reset acceptance replay
- [ ] 2A.1 — VietQR payload and bank lookup
- [ ] 2A.2 — member payment methods
- [ ] 2A.3 — settlement requests
- [ ] 2A.4 — payment data and pending requests on balances
- [ ] 2A.5 — payment methods editor
- [ ] 2A.6 — paying screen, confirmation and gate 2A
- [ ] 2B.1 — custom categories
- [ ] 2B.2 — search and filters
- [ ] 2B.3 — statistics
- [ ] 2B.4 — statistics screen and filters
- [ ] 2B.5 — CSV export
- [ ] 2B.6 — categories UI and gate 2B
- [ ] 2C.1 — fund member integrity
- [ ] 2C.2 — fund endpoints and balances
- [ ] 2C.3 — fund sentence reader
- [ ] 2C.4 — fund UI
- [ ] 2C.5 — gate 2C
- [ ] 2D.1 — budget core and API
- [ ] 2D.2 — budget UI
- [ ] 2D.3 — README, final gate and final records

## Preparation exercises

Temporary manual Python exercise, using standard-library `binascii.crc_hqx` with initial value 65535:

```text
CRC standard vector: 29B1
Hung expected CRC suffix 6329 actual CRC of prefix 6329
Hung purpose character count 16
Lan expected CRC suffix A05F actual CRC of prefix A05F
Lan purpose character count 15
long purpose rule: SP Nguyen Thi Thu Hang tr
```

The two fixed reference strings' top-level TLV fields were inspected and had matching declared lengths. This verifies the supplied references independently; it does not exercise an implemented Phase 2 builder or a banking app. No script was committed.

## Baseline failures

None established. Task 0 is pending; historical Phase 1 gate records are not fresh verification of this run.

## Record-only checkpoint validation

`pnpm check` passed before the record-only commit: `Checked 237 files`, no Biome fixes, all five workspace typechecks `Done`, including successful Next.js route type generation.

Security review: relevant item 1 checked against all three added run files; no secrets, connection strings, cookies or private dump paths. Items 2–8 have no changed implementation to review; no dependency or runtime change. Online dependency audit was not called. Full added-file diff inspected; all tasks remain unticked and historical results are distinguished from fresh exercises.

## Not verified

- Full advisor preparation and Task 0, including build, reset acceptance and permission replay.
- Every Phase 2 implementation task and stage gate.
- Complete current NAPAS member-bank/BIN dataset.
- Banking-app scan and real transfer (owner-only check after implementation).

The local database was neither reset nor modified, so no backup/restore exercise was required or performed. No banking/payment API, account creation, real transaction, deployment, push or merge was performed.

## Gate not passed

No stage gate was attempted. The mandatory advisor-input prerequisite remains blocked; no task is marked complete.


## Advisor preparation resumed — 2026-11-17

Approach: create banks.ts from the authorized public VietQR snapshot; append twelve independently calculated fund samples; amend AGENTS/SRS/database/API/UX/ADR for the approved Phase 2 scope. Keep old run blocker evidence as history, superseded by D4. Reuse installed QR rendering and the existing pure message import exception for CSV labels. No implementation or database mutation before this preparation checkpoint.

Observed source exercise: code 00, 76 entries, 76 unique six-digit BINs, all names nonempty. Original samples preserved as an exact byte prefix. The source snapshot is documented, not described as a NAPAS certification. No payment/account/transaction API was used; only the explicitly approved public bank catalogue.

Preparation validation: pnpm check passed (238 files, all five workspace typechecks Done). Security review: relevant items 1, 2, 8 checked; static catalogue fields validated before generation, no credentials or dependency/runtime changes. Full standing-document amendments and dataset reviewed. banks.ts exceeds 200 lines because it is the complete static catalogue, not executable logic. Fund sample arithmetic and original 75-sample byte preservation checked. Previous blocker status above is historical and resolved by D4.
