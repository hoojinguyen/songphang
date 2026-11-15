# Sòng Phẳng — Phase 2 Implementation Plan — Overview

> **For the implementation agent:** read `AGENTS.md`, the spec, `../2026-11-15-common.md`, then this file. Work through the stage files in order without stopping between tasks.

**Goal:** A group can pay debts by scanning a VietQR code with the receiver confirming before the ledger changes, run a shared fund, see statistics, search and export, and set a budget.

**Architecture:** As `docs/04-sad.md`. The VietQR payload, the budget state and the fund rules are pure functions in `packages/core`. A fund is a member of kind `fund`, so the balance query and the integrity triggers are untouched. New tables get typed queries in `packages/db`; each operation is one service function in one database transaction.

**Tech Stack:** unchanged from phase 1. **No new library.**

**Spec:** `docs/superpowers/specs/2026-11-15-phase-2-real-money-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-phase-2`; `<BRANCH>` `phase-2`; `<LAST TASK>` `2D.3`.

## Stage files

| Order | File | Tasks | Adds |
|---|---|---|---|
| 0 | `../2026-11-15-common.md` | 0 | Re-baseline |
| 1 | `2a-paying.md` | 2A.1–2A.6 | Payment details, VietQR, settlement requests |
| 2 | `2b-insight.md` | 2B.1–2B.6 | Categories, statistics, filter, CSV |
| 3 | `2c-fund.md` | 2C.1–2C.5 | The fund |
| 4 | `2d-budget.md` | 2D.1–2D.3 | Budget and the final gate |

## Constraints for this phase

- Payment details never appear in the invite preview, in an `activity_log` snapshot, or in a log line.
- The web app draws `qrPayload` exactly as received. It never builds, trims or re-encodes it.
- Statistics, budget and export sum money in SQL on `bigint` or with integer arithmetic in `core`. No average, no percentage, no division of money anywhere in this phase.
- The time zone for calendar dates is the constant `Asia/Ho_Chi_Minh`, defined once in `packages/core/src/dates.ts`.
- `GET …/balances` keeps every field it had. `balances` lists people only from stage 2C; this is recorded as an intended contract change (phase 5 has not frozen the contract yet).

## Review Focus

1. **A QR code that sends money to the wrong account.** The payload is byte-for-byte the reference string, and the account shown beside the code is the one inside it. → 2A.1, 2A.4.
2. **A debt cleared without the receiver's word.** Only the receiver's user, the owner, or an editor for an unlinked receiver can confirm; confirming twice stores one transfer. → 2A.3.
3. **The fund breaks the ledger.** The fund never receives a share; a group with a fund still sums to 0. → 2C.1, 2C.2.
4. **A statistic that disagrees with the ledger.** Refunds subtract, transfers never count, and a date at 23:30 Vietnam time belongs to that day. → 2B.3.
5. **A spreadsheet runs a description as a formula.** → 2B.5.
