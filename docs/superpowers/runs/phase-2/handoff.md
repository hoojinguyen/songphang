# Phase 2 continuation handoff — 2026-11-17

## Assignment and authorization

Continue the existing approved Phase 2 run through 2D.3 without routine approval pauses. The owner explicitly asked for handoff to another agent because the current agent is nearing its usage limit. Communicate in Vietnamese; engineering artifacts in English; exact approved product strings in Vietnamese, stored once in apps/web/src/messages/vi.ts.

Repository: /Users/hoojinguyen/Projects/songphang. Branch: phase-2. Do not implement on main or change branches. Do not touch /Users/hoojinguyen/Projects/songphang-ios-ui or ios-ui. No push, merge, deployment, history rewrite, external accounts, real transactions or external-service calls. The one-time public-bank-catalogue retrieval is already finished; implementation remains local. No automated tests, libraries or committed assertion scripts. Integer money and core-only division/rounding remain absolute.

Read AGENTS.md, execute-task and security-review skills, the remaining-phases overview spec, Phase 2 spec, common plan, Phase 2 overview and the run's progress/decisions/manual-checks. Read each stage plan completely before its first task. The run records contain historical blocker text; the current state below supersedes it. Do not repeat completed tasks.

## Git checkpoint

main and origin/main were verified at 30d27bc before starting. phase-2 was created from clean local main. Working tree was clean after the following commits:

| Commit | Work |
|---|---|
| 2416d0e | Initial preparation blocker record |
| 94f1c60 | Advisor preparation, bank snapshot, twelve fund samples, standing amendments |
| 282bc9b | Task 0 re-baseline and public features endpoint |
| 9f3f7c7 | 2A.1 VietQR payload/CRC/purpose/lookup |
| 27e5413 | 2A.2 payment methods schema/API/member DTO |
| 1af3d2b | 2A.3 settlement requests and authorized confirmation |
| bf7f6e7 | 2A.4 payTo/purpose/pendingRequest on balances |
| 5b911ff | 2A.5 payment editor and bank picker |

This handoff adds a documentation-only checkpoint after 5b911ff. Verify actual Git state before acting. One commit per remaining implementation task after pnpm check passes; use uniquely resolvable commit subjects in atomic run records when the same commit cannot contain its own hash.

## First pending task

**2A.6 has not started coding.** Build paying screen, pending-request controls, SSE client invalidation, and stage gate 2A. Then continue all of 2B.1–2B.6, 2C.1–2C.5, 2D.1–2D.3. No later stage is implemented.

Task 2A.6 source context already inspected:

- Balances page: apps/web/src/app/g/[groupId]/balances/page.tsx.
- Existing transfer cards: components/balances/OwnSettlementCard.tsx, SettlementCard.tsx, OtherSettlements.tsx. They currently link to the direct settlement form; viewers cannot use those editor-only actions yet.
- lib/balances.ts: useBalances and settlementHref (direct transfer form URL).
- lib/use-group-events.ts still recognizes only the original six resources and max(6); add settlementRequests as required, later categories/budget in their tasks. Backend GroupResource already includes settlementRequests.
- Existing SnackbarProvider/useSnackbar in components/ui/Snackbar.tsx supports exact success/409 notices across navigation; reuse it.
- Member shape renderer, ScreenHeader, Button, OnlineLink, LoadError and the settle page provide existing layout/access/loading/error patterns.
- No pay page, QrCard, CopyRow, PendingRequestRow or settlement-request web hook exists yet.

Suggested implementation direction (not a new requirement): a small shared transfer-action component can replace the three cards' editor-only actions, presenting a pending row or a paying link. Determine resolver permissions from current group role/myMemberId and receiving member.claimed: owner; linked receiver regardless of role; editor only for unlinked receiver. Cancel only creator or linked payer. The API remains authoritative. Use one mounted idempotency key plus synchronous submission guard on the paying screen. Draw the exact server qrPayload using the installed qrcode matrix, four-module quiet zone and minimum 240px, ink on white. No payload rebuilding/trimming. Copy fallback selects the visible value when clipboard is unavailable. A disappeared transfer returns to balances. Product strings are spec 9.1/9.2; none were added ahead of 2A.6.

Consider while implementing: pending requests can remain confirmable even after suggested debt changes. The balances DTO decorates matching ordered pairs only; GET settlement-requests is available if the approved UI needs pending requests no longer present among suggestions. Do not invent new product wording or silently change fixed expected figures.

## Verified results so far

- Advisor input: owner expressly approved the public VietQR.io/Casso list instead of NAPAS. Source https://api.vietqr.io/v2/banks, retrieved 2026-11-17, 76 rows with unique six-digit BINs and nonempty names. All published entries retained. Static banks.ts records provenance; no NAPAS-certification claim. Raw snapshot SHA256 in decisions D4. Do not download again.
- Fund samples F01–F12 appended in docs/08-quick-entry-samples.md, with independent arithmetic and F/N/Q fixtures. Original 75 samples preserved byte-for-byte as a prefix. Fixed expectations must not be altered.
- Task 0: check/build passed, database backed up before reset, migrations/seed successful. Final trip, A/B/C acceptance, all 75 reader samples and permission replay ran through existing temporary manual loops; all four processes exited 0. 75 matches, zero mismatches, saved counts 4/0/0. Final trip pre-settlement 320001/180000/-180001/-320000/0, then all zeros and transfers []; stale edit 409. Original database restored successfully; All groups balanced before and after restore.
- Public GET /api/v1/features returns receiptReading/sentenceAi/telegram/push/appleSignIn/errorAlerts all false. Optional route probes returned 404. Google remains separate under auth/providers.
- 2A.1: CRC vector 29B1, all purpose references and both fixed QR payloads match exactly; invalid inputs RangeError.
- 2A.2: owner/editor/viewer-own writes 200; viewer-other 403; outsider 404; invalid BIN/duplicate kind/short phone/dashed account each 400. Wallet normalization and clear-list observed. Invite excludes paymentMethods; payment activity before/after NULL.
- 2A.3: all plan rows exercised. Pending leaves balances unchanged; receiver confirm creates one transfer; repeat 409 REQUEST_NOT_PENDING. Concurrent same-key create [201,201] one ID; concurrent confirm [200,409]. Owner/editor/receiver/payer/canceller/outsider/signed-out cases observed. Group with request deletes 204 then 404. All groups balanced.
- 2A.4: fresh 600000 expense, pending Hùng → Minh 150000: bank payload equals first reference, same account; createdByMe true for Hùng and false for Lan; other pair pending null; empty methods yields []. All groups balanced.
- 2A.5: pnpm check passed at 5b911ff: 256 files, five typechecks Done. Production web build passed before final save-label reuse. Browser saved bank/momo, reloaded canonical values, removed momo, tested picker vietc, dashed account and short phone exact errors. Viewer sees another member as read-only and own fields editable. Final label uses existing vi.compose.save (Lưu); this tiny label change passed check but the running production build still shows the earlier Lưu tên label until rebuilt.

No Phase 2 stage gate has run yet. No real bank-app scan, payment or external provider check. Final phase completion must not be claimed.

## Important implementation decisions to preserve

- Reuse qrcode 1.5.4 and existing React SVG rendering (InviteCard.tsx), not planned uqr. No new library.
- Contract now has an offline-linked workspace dependency on existing core to export BANKS; no external dependency was added. Drizzle config explicitly lists new schemas; format generated snapshot/journal JSON with Biome, not lint suppressions.
- Payment strings in vi.payment; CSV must reuse vi.ts labels, following existing narrow API import exception D24. Do not duplicate Vietnamese literals in csv-labels.ts.
- createTransaction(executor,input) still locks group and rechecks editor. createTransactionIn is the shared internal writer for settlement service, which separately locks group/request and checks viewer/identity authorization. Never route ordinary callers around the editor wrapper.
- Idempotency wrapper now acquires a parameterized transaction advisory lock on hashed user/key before lookup, so simultaneous same-key pending reports replay correctly. Helper belongs in packages/db/src/idempotency.ts.
- Group deletion removes settlement requests before transactions/group to preserve RESTRICT member references; member deletion with request references returns existing MEMBER_HAS_TRANSACTIONS. Do not weaken FKs.
- Balance method/member/pending reads remain in the same repeatable-read read-only snapshot as ledger reads. Keep Phase 1 post-lock access, account/password/session serialization and terminal SSE cancellation unchanged.
- MemberDto.paymentMethods defaults [] for new members; GET/edit/PUT explicitly load persisted methods. Invite DTO is independent and excludes payment methods.

## Local runtime and disposable exercises

Original user runtime remains on API 4000 / web 3000; it was not stopped or reconfigured. API 4000 is an older loaded source instance and does not expose the Phase 2 routes. Use current-source runtime below for new exercises.

Agent-started API: port 4001, tsx watch, runtime WEB_ORIGIN=http://localhost:3001, log /tmp/songphang-phase2-api.log. Agent-started production web: port 3001, API_ORIGIN=http://localhost:4001, log /tmp/songphang-p2-web.log. Both are still running at handoff. Rebuild/restart only this production web after changes; do not kill unrelated listeners. Its build artifacts are ignored. For a new API runtime use the same explicit runtime origin or adapt the temporary exercise headers accordingly. Do not commit environment files.

Database schema has migrations 0004 (payment methods) and 0005 (requests) applied. Original data plus disposable Phase 2 exercise groups are present. A private pre-Phase-2 dump exists at /tmp/songphang-phase2-original.dump and was already restored during Task 0 before 0004/0005 were applied. **Before every new reset, take a fresh private backup of the current database.** Restore the corresponding backup after reset exercises, and keep migration state consistent. Never commit dumps, credentials, cookie jars or assertion scripts.

Useful temporary manual exercise sources (read before reuse; none are repository artifacts):

- /tmp/songphang-p2-http.py: helper BASE 4001 but its Origin is still localhost:3000 from earlier exercises; change the temporary helper to localhost:3001 before further writes against the current API. Cookie jars are private /tmp/sp2-*.cookies; do not print/copy their contents.
- /tmp/songphang-p2-payments.py, p2-settlements.py, p2-payto.py and p2-qr.mts: manual output loops, not assertions. Settlement outputs /tmp/songphang-p2-settlements.out.
- /tmp/songphang-p2-payto-fixture.json identifies the last pending-payment group and members (test fixture IDs, no credentials). Current group: 01a1e7fd-5df2-7912-b21e-6f2f9f446bef, Hùng pending to Minh, owner Minh. Browser on 3001 is currently signed in as Hùng viewer.
- Phase 1 replay scripts: /tmp/songphang-final-orchestrate.py, final-trip.py, replay-acceptance.py, gate1d-reader.py, final-permissions.py. They currently target original API 4000 and console log /tmp/songphang-api-console.log. Adapt private copies to current-source API, Origin and log before replaying new-stage gates; keep rate limits enabled. Orchestrator honors 60-second rate windows.
- /tmp/songphang-phase2-phase1-replay.out, task0-build.out, task0-check.out, task0-balances.out and task0-restored-balances.out record this run's baseline evidence. Do not treat older files with similar names as new results.

Browser CUA work was formally completed after 2A.5; a continuation must initialize/read its own CUA documentation before use. No browser verification substitutes for real banking-app acceptance.

## Remaining workflow

Write each approach before edits in progress.md; follow execute-task phase mode and security-review; inspect the entire diff, exercise normal and invalid paths, pnpm check before each task commit. Add owner manual checks, real outputs and deviations, tick only completed tasks. After 2A.6 replay stage 2A plus all Phase 1 acceptance/permission gates on a reset database with backup/restore, check/build/features and All groups balanced. Repeat cumulative gates for 2B/2C/2D. Resolve failures per the approved three-attempt rule; record unavailable verification honestly. Final report includes commits, failed gates and remaining owner checks, stopping only after 2D.3 and final records are complete unless the owner steers again.
