# Phase 4 advisor review — R11-A/R11-B closure

Date: 2026-11-19. Reviewed HEAD: `8602eda95abdd5e9a4b831a4c93a6abccfe8d373`. Previous review: `93e01e992cc5a58a24227bf490c4ada98712f87a`.

## R11: PASS

R11-A and R11-B are sufficiently addressed to close R11. No new must-fix finding was established in this correction range. This closes the local validation finding; real-provider checks and owner-device acceptance remain deferred. It does not merge the branch or substitute for the owner's product acceptance.

## Changes reviewed

- `e479bd2`: narrows the intrinsic input width in `AmountField` with `size={1}` and width/min-width constraints, addressing reproduced S11 overflow without changing amount parsing or money behavior.
- `3f076a2`: adds the child-level browser/money inventory, corrects route counts and case references, and preserves the previous advisor report.
- `8602eda`: constrains the Telegram pairing page width and allows a long account email to wrap at narrow viewports. No pairing/authentication logic changes.

The two UI fixes are narrow corrections arising from the assigned mobile gate. No new dependency, endpoint, schema, environment variable, test suite, or tooling change is introduced. Existing untracked advisor prompts were preserved.

## R11-B: PASS

Read the expanded exercise source and final money records, then independently replayed the exercise on a separate database. All **65 leaf/standalone cases plus two lifecycle parent records** passed. This is 67 records, not 67 independent leaf scenarios.

- `M4D-030.1`–`.4` and `M4D-031.1`–`.4` now execute pending, rejected, edited-back-to-pending, and approved states for actual items/receipt saves. They observe persisted status, item/attachment retention, official balances, budget/stat totals and approved suggestions. Rejected/reopened states stay excluded; approval adds the expected amounts. The fake receipt worker completes locally.
- `M4D-032`–`036` exercise isolated pending/rejected/approved settlement fixtures, payer/receiver authorization, duplicate/cancel/reject/confirm paths and exact resulting balances.
- `M4D-037`–`038` exercise threshold-sensitive fund refunds, immediate counted status, cash/contribution results, local `/sodu`, and overdraw warnings. Transfer preview is legitimately outside the split-preview contract and is explicitly documented, rather than silently skipped.
- `M4D-039`–`059` add 21 warning-parity cases: below/at/above threshold, disabled threshold, owner/editor, counted and uncounted replacements, budget/fund, items and fake receipt. The source compares preview and actual create/edit warnings, verifies preview is non-mutating and reads back official figures. This addresses the previous missing coverage; no additional Cartesian-product requirement is introduced here.
- The original debt-mode, stats, CSV, fund, reminder and `/sodu` exercises remain present. The unchanged exact 13-row 4D.2 table passes in the separate Phase 4 suite.

## R11-A: PASS based on reviewed execution evidence

The final browser artifact contains **61 distinct child records** and **16 parent results** derived from those children. Checked full-SHA tags, parent/child counts and every referenced artifact path. All **22 PNG files** exist with valid PNG chunk checksums. Visually inspected samples covering S11 mobile layout, pairing email wrapping, S20 Escape/focus and removed-member navigation.

The child observations now cover the prior omissions: restore with preserved comment identity; editor refusal and opener/owner dispute resolution; exact approval/edit-back balances and rejection notes; live manual/automatic reminder counts, read/navigation and pagination; role-specific reminder controls and unchanged money; S11 intervals/threshold/clipboard/unlink/refusal; independently persisted mail switches; unsubscribe target/control-account settings; actual keyboard actions and Escape focus return; rendered contrast inputs/calculations; all six mobile screens; offline recovery; S20 and notification access loss.

Unlike the prior replay, the evidence includes actions, observed values, timestamps, screenshots and contrast inputs rather than only parent PASS flags. The reviewed contrast ratios remain above 4.5:1. Final screenshots show the two narrow-layout corrections in use.

Limitation: independent browser execution in this review could not start because the in-app browser timed out attaching its webview. Browser acceptance here is a review of the implementer's saved evidence, not a claim that the advisor independently reran all 61 UI actions. The local backend and HTTP/web gate reruns below were independently executed.

## Final-commit evidence and independent gates

Implementer artifact directory:

`/Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/final-replay-8602eda95abdd5e9a4b831a4c93a6abccfe8d373/`

Reviewed `manifest.json`, detailed JSON records, static/reset/summary logs, process/port/build provenance and screenshots. All required gate families have a successful final-SHA result. The summary preserves an initial Phase 4 HTTP exercise failure (`ECONNREFUSED`, API not yet listening); a later successful seven-suite rerun and balance check occur on the same frozen HEAD. This is a recovered environment startup failure, not an unresolved product failure or a successful first attempt.

Independent results on the reviewed HEAD:

| Gate | Result |
|---|---|
| `pnpm check` | PASS; three existing `noImgElement` warnings |
| `pnpm build`, including build with isolated API origin | PASS |
| `git diff --check` and `git diff --check main..HEAD` | PASS |
| Permissions | 353/353 cases, 99/99 routes, no missing routes |
| Expanded 4D.1 | 65/65 leaf cases plus 2/2 parent records |
| Quick entry | 87/87; over-300 input refused |
| Earlier phases | 15/15 representative checks |
| Phase 4 HTTP/web/worker exercises | 7/7 suites, including exact 4D.2 and prior regressions |
| R9 digest and R10 deleted-comment exercises | PASS |
| Capability-off/production refusals | PASS |
| 1,000-notification performance/privacy | PASS; zero removed-group leaks |
| Final `pnpm db:check-balances` | All groups balanced; zero mismatches |

Used new disposable database `songphang_phase4_advisor_r11ab_20261119`, isolated uploads, API/web 4100/3100 and standalone ports 4101–4108. Verified database identity before resets, reset/migrated/seeded separately for suites, and used real local HTTP/web services for the Phase 4 exercise. Prior databases and artifacts were not changed. Reviewer service ports were confirmed no longer listening after the interrupted tool session.

Durable independent outputs and adapted exercise sources:

`/Users/hoojinguyen/.codex/review-artifacts/songphang-r11ab-8602eda/`

Security review: checked relevant items 1, 7 and 8 against the actual correction diff and added documentation; no new secret, unsafe rendering, redirect/authentication change, dependency or security issue found. Other checklist sections have no changed implementation in this correction range. No external audit/provider call was performed.

## Closure and remaining owner checks

Close R11-A, R11-B and their parent R11. R9/R10 remain PASS, with independent regression replay in this review. No new architecture decision is needed for the narrow layout fixes.

Real SMTP/mail-client behavior, Telegram network/registration, Google OAuth, real AI providers and owner-device acceptance remain deferred under the existing authorization. No push, merge, deployment or GitHub mutation occurred. HEAD remained `8602eda95abdd5e9a4b831a4c93a6abccfe8d373`; this advisor report is uncommitted and does not alter the tested commit.
