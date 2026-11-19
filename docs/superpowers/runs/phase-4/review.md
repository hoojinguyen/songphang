# Phase 4 advisor review

Date: 2026-11-19. Reviewed branch: `phase-4`, HEAD `7f99fc6`, against `main` (`b3cf730`). Outcome: **CHANGES NEEDED**. No implementation changes, commits, or pushes were made during review.

Read the run decisions and unverified/failed-gate sections before reviewing the stage diffs, contracts, migrations, services, bot, worker jobs, and web changes. Findings below reference the reviewed HEAD; fixes should be new commits on the same branch.

## Stage 4A: PASS

No blocking code finding in this stage. This is a code-review conclusion, not certification of all browser and regression gates.

Replayed on a newly created disposable database: viewer comment 201; editor deleting another user's comment 403; owner deletion 204; viewer dispute 201; editor resolution 403; opener resolution 200; outsider comment listing 404. Balances remained identical across dispute creation and resolution.

## Stage 4B: CHANGES NEEDED

### Must fix

1. **R2 [P2] Implement the server-side one-click unsubscribe target.** Commit `4fc3c10`, `apps/worker/src/mail-templates.ts:8–9`. Both mail templates advertise `/notifications/unsubscribe?token=…` as the `List-Unsubscribe-Post` target, but that URL serves a client page whose `useEffect` performs the actual JSON API request. A mail provider's form-encoded POST does not execute JavaScript. Reproduction against the built Next app with a valid token: POST returned `200 text/html`; both email switches stayed `true`. The JSON API separately returned 204 for a valid token and 404 for an invalid token. Add server-side handling at the advertised URL that validates the token and handles the one-click form POST without a session, browser Origin, or JavaScript; keep the browser link usable.

2. **R3 [P2] Keep previously emailed unsubscribe links valid across worker restarts.** Commit `4fc3c10`, `apps/worker/src/mailer.ts:56–60`. When the in-memory cache is empty, issuing the next email overwrites the only stored hash even if a previous hash exists. Consequently every previously delivered link becomes invalid after a worker restart followed by a send; concurrent sends using the same old hash can invalidate one another too. Reproduction: issue a token, load a fresh mailer module instance with its real existing hash, issue another token, then try the first hash: `false`. This contradicts D4B.1's statement that links remain valid across restarts. Use a durable hash-only token record design that retains valid issued tokens, or another explicitly documented design that preserves old links. Serialize token issuance as needed.

3. **R4 [P2] Queue automatic reminder mail durably in the reminder transaction.** Commit `e2cf363`, `apps/worker/src/jobs/auto-reminders.ts:98–99`. The job commits all reminder/cooldown rows and notifications, then sends their mail directly using an in-memory ID list. If one send fails or the process stops before delivery, retry recomputes the pairs, finds their new cooldowns, and never retries those emails. Reproduction: mailer threw on the first automatic send; rerunning with a working mailer returned `0`, with no new mail. Enqueue each `send-notification-mail` job in the same database transaction that records its notification, reusing the existing transactional queue pattern. The scheduler should not own an ephemeral delivery backlog.

4. **R5 [P2] Publish a group event after creating debt reminders.** Commit `e2cf363`, `apps/api/src/services/reminders.ts:86–87`. `sendReminders` returns the database transaction without publishing any SSE event; the automatic job also never calls the worker's `notifyGroup`. Notification hooks refetch on focus or a group event, so a debtor who keeps S4 open sees no bell update after another user presses Nhắc. Reproduction with a group-hub subscriber: reminder 200, recipient unread count increased by 1, captured events `[]`. Publish an existing group resource event after successful manual commits and through the worker event bridge for automatic reminders, so notification queries invalidate without adding another stream.

### Should fix

- `README.md:105` describes a five-second delayed/rate-limited immediate job; the same schedule table also claims seven-day bot retention. Those settings are absent from the enqueue code, and the bot prune implementation uses 24 hours for updates/codes and its specified draft windows. Correct the operational documentation to match the implementation.

## Stage 4C: CHANGES NEEDED

### Must fix

1. **R1 [P1] Prove Telegram identity ownership before binding an application account.** Commit `21f6963`, `apps/api/src/bot/resolve-actor.ts:103–105`. The user-link bearer code is posted in the shared Telegram chat. Any signed-in application user can claim it; `claimUserChatIdentity` verifies the code but never proves that the claimant controls its Telegram sender ID. Reproduction: a `/chi` from Telegram ID 111 produced a link in chat -1001; Thu, who was outside the application group, submitted that code and received 204; ID 111 was linked to Thu. In the reverse direction, a malicious sender can get another signed-in user to claim the sender's shared link, after which that sender acts with the other application's rights. Showing the application email on the page does not authenticate the Telegram identity. Require confirmation from that Telegram ID, or a verified Telegram-authentication flow, before activating the mapping. This is an authentication design defect, including in the approved bearer-link flow, and requires an advisor design correction before real bot use.

2. **R7 [P2] Make a bot draft's idempotent save recoverable.** Commit `d645c7b`, `apps/api/src/bot/callbacks.ts:116–120`. Each callback puts its current time into `occurredAt`, which is part of the hash stored under the fixed `bot-draft-{id}` idempotency key. Transaction creation commits before `markBotDraftSaved`. If that update fails, a second callback cannot recover the committed transaction: its timestamp changes the request hash and raises `IDEMPOTENCY_KEY_REUSED`. Reproduction on the disposable database: temporarily failed the draft UPDATE with a database trigger, then removed the trigger and retried; one committed idempotency record existed, `savedTransactionId` remained null after retry, and no saved reply was sent. The temporary trigger/function were removed. Persist the request timestamp in the draft, and commit draft saved state together with transaction creation/idempotency state, or otherwise recover the original stored response safely. Also serialize save/drop operations against the same draft.

Replayed working cases: wrong webhook secret 404; another sender's callback created no transaction; two sequential save callbacks produced one save reply and one transaction; `/huy` soft-deleted the saved expense with the expected reply; disabled webhook 404 and all six optional feature flags false. This does not replace verification of the real Telegram adapter.

## Stage 4D: CHANGES NEEDED

### Must fix

1. **R6 [P2] Apply the prospective approval status to preview warnings.** Commit `a4868f3`, `apps/api/src/services/transactions.ts:120–123`. Preview carries the existing expense's `counted` status into replacement calculations, but does not determine whether the new expense will be pending. `transactionWarnings` therefore assumes the new amount counts. Reproduction with a 1,000,000 threshold/budget and 600,000 already spent: Lan previews 1,500,000 and receives `BUDGET_OVER`; saving the same request yields `pending`, warnings `[]`, and unchanged balances. The fund warning path has the same missing input. Pass the authenticated actor into preview, calculate the same prospective approval status used by create/edit, and set `counted` consistently.

### Should fix

1. **R8 [P3] Include the amount in approval activity snapshots.** Commit `a4868f3`, `apps/api/src/services/approval.ts:88–89`. Approval/rejection activity records have no amount in `before` or `after`; `after` contains only the optional note. The new activity templates contain `{amount}`, and `describeActivity` reads that value exclusively from those snapshots, so these rows render the missing-value placeholder. Store the amount as it was at decision time, along with the optional note, instead of reading a later transaction value.

Replayed all 13 API rows of plan 4D.2. Numeric checkpoints matched exactly:

| Row | Minh | Lan | Hùng |
| --- | ---: | ---: | ---: |
| 1: pending 1,200,000 | 0 | 0 | 0 |
| 2: add 999,999 | -333333 | 666666 | -333333 |
| 4: approve row 1 | -733333 | 1466666 | -733333 |
| 6: edit to pending 1,500,000 | -333333 | 666666 | -333333 |
| 7: reject | -333333 | 666666 | -333333 |
| 8: edit to 900,000 | -633333 | 1266666 | -633333 |

Owner expense, transfer, and threshold-off creation returned `none`; non-owner approval/threshold change returned 403; repeated approval 409; a 301-character note 400.

## Verification and limits

- `pnpm check`: exit 0, 478 files, eight workspace typechecks; three pre-existing `noImgElement` warnings.
- `API_ORIGIN=http://localhost:4010 pnpm build`: exit 0; all routes built.
- `git diff --check main..phase-4`: exit 0.
- Fresh disposable database `songphang_phase4_review_20261119`: migrations and development seed succeeded. The owner's database and the implementer's gate database were not modified.
- `pnpm db:check-balances` against the review database: `All groups balanced`; both exercise groups had `sum 0; mismatches 0`, including the injected bot-save failure case.
- Additional working checks: manual reminder 200 then 429; digest first run sent three mails and immediate second run sent zero; an already-read notification skipped immediate delivery; muting prevented a new notification; removing Lan changed this group's notification-list count from four to zero.
- Security review: inspected relevant items 1–8 against the actual diff, including schema validation, group authorization, SQL parameters, notification membership joins, bot secret handling, link claims, mail settings, rendering, and dependency changes. R1 is blocking; R2/R3 affect unsubscribe behavior. No dependency manifests or lockfile changed. `pnpm audit --prod` was not run because it calls an external service, which this run forbids.
- The original `task0_*.mts` and `exercise_4*.mts` scripts named in the implementation report were absent from the repository and the searched temporary locations. Review used temporary, uncommitted exercise scripts. **The full earlier-phase acceptance replay, full permission matrix, all 87 reader samples, every 4D.1 statistics/fund/export variant, and browser keyboard/visual/performance gates were not rerun. Do not treat this review as a complete stage-gate certification.**
- Direct in-process calls to the unsubscribe route initially returned 500 because `socketIp` requires the Node HTTP adapter's connection context. Rechecking through the real local HTTP server produced the correct 204/404 results; the harness result is not a product defect.
- Real SMTP, real Telegram calls/webhook registration, and real AI-provider checks were not performed, consistent with the owner's constraints. All temporary services started for review were stopped afterward.

## Decisions for the project owner

| Recorded decision | Review disposition |
| --- | --- |
| Baseline/re-baseline adaptations | Confirm the recorded naming/location adaptations and disposable database approach. The original acceptance scripts remain unavailable. |
| D4A.1: response wrappers | Confirm; consistent with existing API contracts. |
| D4B.1: unsubscribe token cache/rotation | Change; R3 disproves the stated restart guarantee. Retain hash-only storage while preserving issued links. |
| D4B.2: digest checkpoint table | Confirm the table approach; it is represented by a migration. |
| D4B.3: shared formatter, worker mailer | Confirm; no new dependency or workspace package. |
| D4B.4: reminder cooldown table | Confirm the schema approach; correct delivery/event handling per R4/R5. |
| D4C.1: bot response shapes and parsing | Confirm the additive fields and malformed-body handling; displaying only the platform is the recorded privacy tradeoff. Separately correct identity ownership per R1 before enabling the bot. |
| D4D.1: opacity 0.85 | Confirm the plan-permitted contrast adjustment; the recorded browser contrast measurement was not independently rerun. |
| D4D.2: bell accessible name | Confirm alignment with the final accessibility requirement. |
| D4D.3: English command module names | Confirm; follows the recorded owner request and language policy. |

No additional product choice is needed to fix R2–R7. R1 needs a corrected identity-linking design consistent with the standing security rules. Re-review the fix commits and complete the outstanding gate replay before the owner's manual check and merge.
