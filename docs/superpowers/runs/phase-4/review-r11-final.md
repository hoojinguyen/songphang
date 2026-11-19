# Phase 4 advisor review — R11 completion evidence

Date: 2026-11-19. Reviewed HEAD: `93e01e992cc5a58a24227bf490c4ada98712f87a`. Baseline: `f0b5da5f07a26fd17ef456ba5e16b6549618928a`.

## R11: CHANGES NEEDED

The missing core-role permission cases have been added and independently pass. The expanded money exercise also passes every case it actually executes. R11 cannot close because required money variants and browser subcases remain unsupported by the final evidence. These are validation gaps; this review establishes no new product-code defect.

The new commit changes only run documentation. R9/R10 implementation is unchanged from the previous passing review. This focused review does not claim another independent replay of the entire phase or all browser interactions.

## Must fix

### R11-A [P2] Execute and substantiate every browser subcase before counting its parent case as passed

Commit `93e01e9`, `r11-completion.md:423`, with the requirements at lines 428–442. Actual final artifact: `09_browser.json`, not the documented `08_browser.json`.

The artifact contains 16 PASS rows tagged with the final SHA, but narrows the expected behavior relative to the committed inventory. Concrete omissions:

| Case | Required behavior not established by the final actual result |
|---|---|
| BR-02 | Restore after deleted-state commenting and preservation of those comments. Actual stops at the deleted banner remaining visible. |
| BR-03 | Non-opener editor denial and opener resolution. Actual contains only viewer opening and owner resolving. |
| BR-04 | Exact live balances, editor edit returning the approved transaction to pending, and displayed rejection-note content. Actual contains tag/block booleans. |
| BR-05 | Opening an individual notification marks it read and navigates; pagination from the assignment. The bell count and mark-all observation do not establish these actions. |
| BR-06 | Editor/receiver/non-receiver visibility, remind-all result count, and unchanged balances. The recorded actor is owner only. |
| BR-07 | All off/3/7/14 intervals; threshold enable/change/disable and invalid input; Telegram copy/unlink; non-owner refusal. Actual only records one weekly interval, a checked approval switch, and code presence. |
| BR-08 | Both mail switches persisted after reload. Actual records one online click and Telegram unlink. |
| BR-10 | Both intended-account mail settings disabled. Actual records confirmation text and invalid-link text only. |
| BR-11 | Tab/Shift+Tab and Enter/Space across the required screens, Escape specifically, and focus returning to its trigger. A solid outline and dialog counts cannot establish these steps. |
| BR-14 | S11 mobile overflow. It is absent from the recorded screen list. |
| BR-16 | S20 access-loss behavior. The artifact changes this check to S4 instead. |

The final `screenshots/` directory is empty. There are no accompanying per-case DOM/network/action logs, screenshot references, or rendered color inputs/calculation evidence for BR-13. The JSON strings are useful observations but do not supply the requested reviewable per-case evidence. A SHA field alone does not substantiate the missing actions.

Execute the remaining subcases, retain ordered actions and actual observations with durable supporting artifacts, and compute parent PASS/counts from the complete inventory. Mark unsupported subcases NOT RUN until exercised. Preserve a full final-SHA replay after the last tracked change; do not merely rename the existing summaries or replace missing observations with booleans.

### R11-B [P2] Finish the omitted approval-sensitive money variants

Commit `93e01e9`, `r11-completion.md:418` (M4D-030/031), also the warning coverage at line 414. Reviewed the actual `/tmp/r11_gates/gate_4d1_money_r11.mts`, the final `03_4d1_money.json`, and the existing Phase 4 and earlier-phase scripts.

M4D-030/031 execute only pending → approved and assert budget spent. The script's M3 heading mentions rejected, but neither items nor receipt transaction is rejected. The assigned pending/rejected/approved persisted behavior and official figures are therefore incomplete. Add rejection and subsequent transition observations for both save paths with the expected counted figures.

The 31-case suite has no settlement/payment request exercise against its pending/rejected/approved ledger, no threshold-sensitive fund refund check, and only a fund-overdraw **preview** comparison for one above-threshold amount. The older stage suite adds an above-threshold budget preview comparison but does not establish the assigned create/edit/preview parity for counted versus uncounted replacements, below/at threshold, owner/non-owner, and threshold off. Earlier-phase settlement/fund smoke cases without approval do not fill these gaps.

Add explicit cases for these previously assigned variants, with expected amounts/statuses and read-back postconditions, and rerun on the final frozen SHA. Keep the unchanged 4D.2 expected table. Do not describe `31/31` as the complete required matrix while these scenarios are absent.

## Independently verified

- `pnpm check`: PASS, 485 files; three existing `noImgElement` warnings, no errors.
- `pnpm build`: PASS.
- `git diff --check`: PASS.
- Permission exercise: 99/99 registered routes, 353/353 executed cases PASS; no missing core owner/editor/viewer/outsider label combinations among group-ID routes. Actual inventory contains 63 such routes, rather than the document's 62.
- Previously missing reminder cases: PM-262 viewer receiver 200, PM-263 editor 200, with separate suggested pairs; PM-261 non-receiver viewer 403.
- Restore: PM-219 owner and PM-220 editor 200 on separately deleted transactions, with `deletedAt === null` assertions; outsider/cross-group/unauthenticated/unverified/viewer rejection cases included.
- Leave: PM-341 owner 422 (`OWNER_REQUIRED`); PM-342 viewer and PM-343 editor 204, followed by inaccessible-group 404 assertions.
- Money exercise: 31/31 actual cases PASS, including real minimizeDebts true/false PATCH/readback, expected person balances/transfers, status-sensitive stats, budget, CSV presence, reminders, fund cash/contributions, local `/sodu`, and pending→approved item/receipt saves. Passing these cases does not establish the missing variants above.
- `pnpm db:check-balances`: all three new money fixture groups sum to zero with zero mismatches; PASS. The money exercise also invokes this check at its own checkpoints.

Created fresh reviewer database `songphang_phase4_advisor_r11final_20261119`; confirmed its name before resetting only that database between permission and money exercises. Used ports 4093/4094, fake/console adapters, and separate uploads. Both suite servers closed. Preserved the implementer's databases, scripts, and evidence.

Durable independent outputs and adapted exercise copies: `/Users/hoojinguyen/.codex/review-artifacts/songphang-r11-93e01e9/` (`permissions.json`, `money.json`, `balances.log`, `check.log`, `build.log`). Original implementation artifacts: `/Users/hoojinguyen/.gemini/antigravity/brain/c49aa591-9496-4ea8-aa53-d2f8241d3e34/final-replay-93e01e992cc5a58a24227bf490c4ada98712f87a/`.

The implementer's final summary also reports 87 samples, representative earlier phases, the seven-suite Phase 4 replay, R9/R10, capability/prod refusals and notification performance passing. These were inspected as recorded evidence, not independently rerun in this focused review. Browser results were reviewed as artifacts; no independent browser execution is claimed.

Security review: checked relevant item 1 against all added documentation; no new secret found. Other runtime/dependency checklist items have no changed implementation in this commit. No external audit, provider call, push, merge, or GitHub mutation was performed. Real-provider and owner-device checks remain deferred.

## Closure decision

Keep R11 open for R11-A and R11-B. Accept the expanded core-role permission coverage. Retain R9/R10's prior PASS; no new implementation change affects them. Correct the inventory's shifted case ranges and browser artifact filename while completing the evidence, without rewriting historical review reports. This review is an uncommitted advisor document and does not change the reviewed HEAD.
