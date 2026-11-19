# Phase 4 advisor review — round 2

Date: 2026-11-19. Outcome: **CHANGES NEEDED**.

## Reviewed revisions

- GitHub PR: https://github.com/hoojinguyen/songphang/pull/1.
- GitHub connector metadata and `git ls-remote origin refs/heads/main refs/heads/phase-4 refs/pull/1/head` independently confirmed PR HEAD `7f99fc68692d5bd4a65c4e208f45fa6b2669c91a`, base `6b363368a5177fb0c2a27aa19458055eede027be`.
- Local `phase-4` HEAD: `7078c004180042e64b97dd74b2e33a753e6fe046`, ten correction commits beyond the previous review baseline `7f99fc6`. Those corrections were not on the PR at review time. GitHub discussion replies also describe the fixes as awaiting push.
- Reviewed the local correction diff and the retained Phase 4 paths relevant to the earlier findings. No push, GitHub comment, thread resolution, merge, or implementation modification was performed. The pre-existing untracked correction prompt was preserved.

## Stage 4A: CHANGES NEEDED

### Must fix

**R10 [P2] Preserve the approved ability to comment on deleted transactions.** Commit `e2e4be7`, `apps/api/src/services/comments.ts:137–138`.

The new `deletedAt` guard rejects a comment on a soft-deleted transaction with 404. Plan `4a-comments.md`, Task 4A.1 explicitly requires comments to be both readable and writable on a soft-deleted transaction, and its exercise table expects 201 after deletion. S20 still displays the comment field on such transactions, so this also leaves an enabled action that fails.

Independent exercise: viewer comment before deletion 201; owner deletes transaction 204; viewer comment after deletion 404; comment listing still 200. Remove the new guard while retaining transaction-in-group authorization, and replay the deleted-transaction case through both HTTP and S20. The cubic suggestion to reject this case conflicts with the approved plan; the GitHub reply reporting its implementation does not document a replacement product requirement.

The same commit also changed dispute resolution on deleted transactions to 404; inspect that change against the intended deleted-transaction workflow rather than treating all bot suggestions as requirements. It is not counted as a separate finding here because the explicit writable-on-deletion acceptance case is for comments.

## Stage 4B: CHANGES NEEDED

### Must fix

**R9 [P1] Recheck digest authorization for each recipient at delivery time.** Introduced in `4fc3c10`, still present after correction `0616f9d`; `apps/worker/src/jobs/send-digest.ts:93–107`.

The job loads every recipient's rows, membership, verification, and digest eligibility once, then sends from that snapshot. A user removed from a group while earlier recipients' emails are being sent still receives that group's private snapshot. The Phase 4 overview explicitly requires mail jobs to recheck group membership at send time, and the spec's anti-goal is disclosure after membership loss.

Independent deterministic reproduction on the disposable database: create unread digest notifications for two ordered recipients; while handling the earlier recipient's send, delete the later recipient's membership; continue the job. Output: `private data mailed after removal true`. The later mail still contained the private expense description from the removed group. This is a separate case from removing a user before the initial digest query, which the existing join correctly handles.

Before building/sending each recipient's mail, refresh that recipient's eligible unread notifications against current membership, verified-email status, and digest settings. Drop ineligible group rows and skip an empty digest. Exercise removal and opt-out between recipient sends, including a user who remains in another group, without leaking the removed group's text or counts. Keep already-deferred digest delivery/cursor concerns separate from this authorization defect.

### Earlier corrections verified

- R2: form POST to the exact advertised web URL, with foreign Origin and no session/JavaScript, returned 204 and changed both email switches to false; browser GET returned 200. JSON API valid/invalid cases returned 204/404.
- R3: after issuing a second token, the earlier token still worked through the advertised URL. Source inspection confirms durable hash-only issued-token rows and legacy compatibility.
- R4: automatic reminder exercise used the real transactional queue adapter: one reminder, one matching `send-notification-mail` job, zero additional reminders on immediate rerun. The normal worker entry point supplies `enqueue`.
- R5: inspected post-commit manual publication, transactional automatic `notifyGroup`, and delivery-job refresh recovery. The previously reported no-event paths are corrected in source; browser/SSE timing was not independently replayed this round.

## Stage 4C: PASS (targeted correction review)

No new blocking code finding in the inspected pairing/save corrections. This does not certify the complete stage gate or the old PR HEAD.

- R1: pairing start 201; legacy claim 400; another application user's attempt lookup 404; after staging, identity count 0; another Telegram sender's callback left status `pending_telegram`; after the correct Telegram confirmation, identity count remained 0; final initiating-session web confirmation 204 linked the expected user; revoked initiating session subsequently returned 401. Inspected session-bound final authorization, identity uniqueness, private-chat checks, cancellation, and legacy invalidation migration.
- R7: injected a temporary database failure at the draft saved-state UPDATE. Webhook returned 500, committed transaction count 0, committed idempotency-key count 0. After removing the injection, retry returned 200 and populated the saved reference; another callback returned 200 with transaction count still 1. Temporary trigger and function were removed.
- Read the later webhook retry, group-link replacement, and bot balance chunking changes as well as the new pairing UI and contract.

## Stage 4D: CHANGES NEEDED (acceptance evidence)

### Must fix

**R11 [P2] Provide reproducible gate coverage for the final correction HEAD.** Commit `a91f41f`, `docs/superpowers/runs/phase-4/progress.md:518`.

The report calls an aggregate `totalChecks: 44` a full Phase 1–4 permission matrix but provides no executed endpoint-by-caller rows or surviving script to establish that coverage. The current OpenAPI document alone contains 94 method/path operations. An aggregate count cannot establish that each applicable group endpoint was exercised as owner, editor, viewer, outsider, plus its extra cases. The named `gate*_*.mts`/`exercise_r*.mts` scripts were absent from the searched temporary directory. The common plan requires one result per endpoint and caller.

Moreover, `e2e4be7`, `081e745`, and `7078c00` follow the gate-evidence commit. R10 is a concrete acceptance regression in that later code, and `git diff --check main..HEAD` now exits 2 at `progress.md:530` despite the recorded clean claim. This does not prove the historical runs never happened; it means they cannot certify the current HEAD.

Reconstruct and replay the required permission cases and affected acceptance/browser cases on the final fix revision. Preserve a sanitized per-case source/fixture/invocation/expected/actual/status matrix so another reviewer can reproduce the run without the temporary scripts. Recheck the already-requested 87 samples, representative per-earlier-stage replay, all 4D.1 variants, and keyboard/performance gates, or explicitly mark any remaining case unverified. Record the exact tested commit and run final static/build/balance gates after all code corrections. Do not relabel representative coverage as full coverage.

### Should fix

Commit `4335d95`, `apps/api/src/services/transaction-changes.ts:158`: remove the redundant `as "expense" | "transfer" | "income"` assertion. `before` is already a validated transaction DTO with that union. The assertion adds no information and violates the project's no-forced-cast convention; this is not a runtime money error.

### Earlier corrections verified

R6 preview and pending save both returned warnings `[]` for the reproduced above-threshold case. Approval with the actual web client's empty-body POST shape returned 200, advanced transaction version to 2, and set the approving owner as editor. R8 writes decision-time amount in the activity snapshot; inspected the change without manufacturing old historical values.

## Independent verification and limits

- Disposable database: `songphang_phase4_rereview_20261119`, created, migrated, and seeded for this review. The owner's and prior agents' databases were not reset or modified.
- `pnpm check`: exit 0; 485 files, eight workspace typechecks; three pre-existing image warnings.
- `API_ORIGIN=http://localhost:4030 pnpm build`: exit 0; routes and proxy compiled successfully.
- `git diff --check 7f99fc6..HEAD` and `git diff --check main..HEAD`: exit 2, `progress.md:530: new blank line at EOF`.
- `pnpm db:check-balances` on the review database: `All groups balanced`. A final balance check also included the atomic bot-save/reminder exercise group.
- Local HTTP servers were used for unsubscribe middleware/proxy checks; in-process app requests were used for the other endpoint exercises. Digest privacy was exercised with real database reads/writes and an injected mail sink, without contacting a provider.
- Security review: inspected relevant checklist items 1–8 on the correction diff and exercised the sensitive pairing, authorization, and unsubscribe paths. R9 remains a security blocker. No dependency/lockfile changes or test files were introduced by the ten corrections. External dependency audit was not run under the no-external-service constraint.
- Did not independently replay all 87 samples, the complete earlier-phase acceptance replay, every permission-matrix row, all fund/statistics/export variants, browser visual/keyboard/performance gates, or all R1 concurrency/expiry permutations. Their implementation-agent report remains evidence to inspect, not independent verification. R11 keeps this limitation visible.
- Real SMTP, Telegram API/webhook registration, and AI-provider calls remain unperformed/deferred. No GitHub mutations were made. Review-started HTTP processes were stopped and temporary failure-injection objects removed.

## Decisions for the project owner

- DR1: confirm the two-sided pairing direction from the correction prompt. Targeted local verification supports closing the original R1 on local HEAD; it is still absent from the remote PR.
- DR2_3: confirm durable token hashes and the narrowly scoped server-side unsubscribe proxy/Origin exception. The former D4B.1 cache design is superseded.
- Original D4A.1, D4B.2–4, D4C.1, D4D.1–3: no new change requested by this review. Their remaining standing-document amendments and unrerun visual measurements remain as previously recorded.
- Keep the explicitly deferred digest checkpoint/repeated-delivery discussions separate; R9 is an authorization leak and should be corrected before merge.
- Restore the approved comment-on-deleted behavior for R10. If a product change is desired, approve and update that requirement explicitly rather than resolving the cubic comment as a correctness fix.
- Do not merge based on the current remote PR, and do not treat this report as push authorization. Re-review the next correction commits and their final-head gate evidence before the owner's manual acceptance.
