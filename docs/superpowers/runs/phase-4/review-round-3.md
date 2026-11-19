# Phase 4 advisor review — R9–R11 verification

Date: 2026-11-19. Reviewed HEAD: `f0b5da5f07a26fd17ef456ba5e16b6549618928a`. Baseline: `7078c00`. Overall: **CHANGES NEEDED — R11 remains open; R9 and R10 pass**.

The correction range contains three narrowly scoped implementation commits and one documentation commit. The final documentation commit changes no implementation files. Reviewed the actual diff, DR9/DR10, correction response, committed gate inventory, surviving temporary exercise sources, and the final-replay artifacts under:

`/Users/hoojinguyen/.gemini/antigravity/brain/c49aa591-9496-4ea8-aa53-d2f8241d3e34/final-replay-f0b5da5f07a26fd17ef456ba5e16b6549618928a/`

No implementation change, commit, push, merge, GitHub mutation, or external-provider call was made during this review. The pre-existing untracked advisor prompts were preserved.

## Stage 4A / R10: PASS

Commit `70cc66e` removes the deleted-transaction comment rejection and restores authorized resolution of an already-open dispute on a soft-deleted transaction. Opening a new dispute on a deleted transaction remains forbidden. Existing group authorization, validation, verification, write/comment limits, and comment idempotency remain intact.

Independently reran the surviving `exercise_r10.mts` against a newly created reviewer database after adapting only its disposable database/upload paths and ports:

```text
commentBeforeDelete: 201
idempotentRetrySameId: true
deleteTx: 204
disputeStillOpenAfterDelete: true
commentWhileDeleted: 201
notAutoRestored: true
editorResolveDeletedDispute: 403
openerResolveDeletedDispute: 200
openNewDisputeWhileDeleted: 404
restoredRetainsComments: true
deleteAuthChecksPassed: true
outsiderCrossGroup404: true
unauth401Unverified403: true
invalidInput400: true
rateLimit429At: 18
balancesUnchanged: true
```

The rate-limit assertion follows earlier comments in the same exercise, so 18 is the iteration where its remaining quota is exhausted, not a changed configured limit. The final browser artifact also records a deleted-transaction viewer comment, owner SSE receipt, literal script text, and no automatic transaction restoration. Those browser observations were inspected, not independently reproduced by this reviewer.

## Stage 4B / R9: PASS

Commit `8882307` correctly changes the upfront query to candidate user IDs and re-queries eligible notifications per recipient using a fixed `(since, until]` window. Current membership, unread state, verified email, digest setting, and email address are read before rebuilding that recipient's mail. Group prefixes, transaction grouping, line limit, and overflow are rebuilt from the fresh rows; empty recipients are skipped. No database lock is held over mail I/O.

Independently reran `exercise_r9.mts` on the isolated reviewer database. All nine reported scenarios passed:

```text
onlyGroupRemovedSkipped: true
immediateSecondRunZero: true
oneOfTwoGroupsRemovedNoLeakAndOverflowRecomputed: true
multiGroupWithOverflowFormatted: true
optOutSkipped: true
unverifiedSkipped: true
partialReadOmitted: true
updatedEmailUsed: true
allReadSkipped: true
```

This closes the reproduced inter-recipient disclosure in R9. It does not claim to recall an email already handed to a mail provider or resolve the separately deferred digest cursor/delivery issues.

## Stage 4C: no new finding in this correction range

Pairing and bot save implementation are unchanged from the prior review. The surviving seven-suite Phase 4 replay passed again on this HEAD, including its two-sided pairing and atomic save rollback/retry cases. This is bounded by the actual scenarios in that script, not every scenario originally requested.

## Stage 4D / R11: CHANGES NEEDED

### Must fix

**R11 [P2] Complete the missing cases before claiming a full final-commit gate replay.** Commit `f0b5da5`, `docs/superpowers/runs/phase-4/review-round-2-fixes.md:17`.

There is now real final-SHA evidence, a surviving script set, and substantially improved per-case results. The final static artifact explicitly identifies `f0b5da5f07a26fd17ef456ba5e16b6549618928a`. Independent reruns reproduced the recorded aggregate successes. However, examining the underlying cases shows that “all gates” and “full permission matrix” remain stronger claims than the evidence supports:

1. **Route coverage is not endpoint-by-caller coverage.** The 99-route / 309-case matrix covers each route at least once, but omits required caller cases. Concrete examples in the committed inventory and final `02_permissions.json`:
   - Reminder POST, PM-243–245: outsider, non-receiver viewer, owner; no editor case and no allowed viewer-as-receiver case.
   - Transaction restore, PM-212–214: outsider, viewer, owner; no editor case.
   - Leave group, PM-300–301: outsider and editor only; no owner 422 or viewer 204 case.
   These are actual missing scenarios, not differences in role-label spelling. Add the missing cases with valid independent fixtures and audit the remaining inventory for the same gaps.

2. **The final money suite does not execute the required 4D.1 matrix.** `gate_phase4_stages.mts:436–443` checks aggregate stats, budget spent, and CSV only while one transaction is rejected. Its comment mentions `minimizeDebts=false`, but the script never changes `minimizeDebts`. The script contains no fund, item/receipt, or `/sodu` exercise at all. The final seven-row summary still claims all 4D.1 variants. Earlier-phase fund and receipt smoke checks without an approval threshold do not establish pending/rejected exclusion. Add pending/rejected/approved variants for both debt modes, pairwise suggestions, fund cash/contributions, statistics breakdowns, warnings, export, settlement/reminder/bot suggestions, and items/fake-receipt saves as assigned. Preserve the fixed 4D.2 numbers, which the existing script does verify.

3. **The complete browser gate was not replayed on the final SHA.** The final `08_browser.json` records only signed-out valid unsubscribe and the deleted-comment/SSE/script-text observations under `finalSha`. Its remaining observations are explicitly nested under `preFreezeFullBrowserPass`: invalid unsubscribe, live reminder bell, pending approval/Escape, S19, mobile overflow, and full browser pairing. They therefore are not final-commit replay evidence. The artifact also does not establish the requested complete keyboard/focus, S11, offline, and contrast checks. Rerun all required browser cases on the chosen final HEAD or mark each outstanding case NOT RUN, rather than reporting the complete final gate as passed.

After filling these gaps, freeze the final revision and rerun the required final gate protocol, preserving exact SHA, per-case evidence, and final artifact paths in the handoff. Keep already-deferred real-provider/device cases deferred. R11 is a validation/completion finding; no additional product-code defect was established by these missing cases.

## Independent reruns on this HEAD

Created disposable database `songphang_phase4_advisor_r3_20261119`, with isolated uploads and ports 4060–4066/3060. Original databases, scripts, output JSON, and final artifacts were preserved. Adapted exercise copies and reviewer logs are in `/tmp/songphang-advisor-round3/`. Each standalone suite began with a reset of only the reviewer's database, followed by migrations and development seed. The final Phase 4 suite used a fresh reset and actual API/web servers with fake/console adapters.

| Check | Independently observed result |
| --- | --- |
| `pnpm check` | Exit 0; 485 files, eight workspace typechecks, three pre-existing image warnings |
| `API_ORIGIN=http://127.0.0.1:4060 pnpm build` | Exit 0; all routes and proxy compiled |
| `git diff --check 7078c00..HEAD`, `git diff --check main..HEAD` | Exit 0 |
| Dedicated R9 / R10 exercises | Both passed, details above |
| Surviving permission suite | 309/309 checks passed, 99/99 routes represented; coverage limitations above |
| Quick-entry samples | 87/87 passed; over-300-character HTTP 400 case also passed |
| Earlier-phase representative replay | 15/15 passed; remains labeled representative |
| Phase 4 stage/regression script | 7/7 suites passed; does not imply absent 4D.1 scenarios ran |
| Capability-off / production refusals | Six flags false, four disabled routes 404, eight refusal checks passed |
| Notification performance/privacy | Page 1 7.79ms; page 2 4.83ms; 500 surviving rows walked, zero removed-group leaks |
| Final balance check | `All groups balanced` on the reviewer database |

Security review: checked relevant items 1–8 against this correction diff. R9 revalidation uses parameterized Drizzle conditions and current authoritative rows; R10 preserves access checks. No new dependency, migration, environment variable, public endpoint, test file, or secret was introduced by the implementation corrections. No new security issue found in this correction range; R11 remains open for missing verification. External audit/provider calls were not performed.

Reviewer-started servers were stopped, temporary failure-injection objects removed, and HEAD remained `f0b5da5f07a26fd17ef456ba5e16b6549618928a`. This review adds only this report, without changing the reviewed implementation.

## Decisions for the project owner

- Confirm DR9 and close R9: the per-recipient refresh fixes the reproduced privacy defect.
- Confirm DR10 and close R10: comments and existing-dispute resolution on deleted transactions match the assigned correction.
- The redundant cast and whitespace observations are fixed (`63840a4` and the documentation commit).
- Keep R11 open. The final-SHA replay exists, but its coverage is incomplete. Ask for the specific remaining cases above, not another undifferentiated “all passed” report.
- Prior authorized pairing/unsubscribe decisions remain unchanged. Real SMTP, Telegram, AI-provider, Google OAuth, and owner-device acceptance remain deferred as previously recorded.
