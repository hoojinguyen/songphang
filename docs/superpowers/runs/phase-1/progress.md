# Phase 1 run — progress

Written by the implementation agent during the run. See `docs/superpowers/plans/2026-11-12-phase-1/00-overview.md`, "Run files".

For each task, under its heading: the approach note, the commit hash, the real output of the exercises, and "Unresolved" if any check still fails after three fix attempts. Tick the box only when the task is committed.

## Stage 1A — Core ledger

- [x] 1A.1 `core`: equal split and settlement suggestions
- [x] 1A.2 Database: ledger tables, integrity triggers, balance check
- [x] 1A.3 API: groups, group authorization, idempotency
- [x] 1A.4 API: members
- [x] 1A.5 API: create, preview and list transactions
- [x] 1A.6 API: balances and settlements
- [x] 1A.7 Web: group list and create group
- [x] 1A.8 Web: group screen and expense stream
- [x] 1A.9 Web: manual expense form
- [x] 1A.10 Web: balances and settlements
- [x] 1A.11 Web: members and group settings
- [x] 1A.12 README and stage gate 1A

### Gate 1A

Result: passed. pnpm check; network-isolated pnpm build; reset database acceptance; balance check; all ten group-scoped endpoint permission rows passed. Full outputs below.

Gate not passed: none.

Not verified: external mockup comparison and real screen-reader speech are owner checks. Hourly cleanup timer passage was not waited for. No editor/viewer exists before 1B.

## Stage 1B — Accounts and sharing

- [x] 1B.1 Account foundations
- [x] 1B.2 API: register, sign in, verify email
- [x] 1B.3 API: forgot, reset and change password; delete account
- [x] 1B.4 API: Google sign-in
- [x] 1B.5 Web: sign-in, register, verify, forgot and reset screens
- [x] 1B.6 Web: account screen
- [x] 1B.7 API: invites, joining, member selection
- [x] 1B.8 API: users in a group, roles, leaving, ownership
- [x] 1B.9 API: realtime events
- [x] 1B.10 Web: joining and inviting
- [x] 1B.11 Web: roles, settings, leaving, read-only, realtime
- [x] 1B.12 Stage gate 1B

### Gate 1B

Result: passed. Accounts/invites/roles/SSE, reset acceptance and permissions passed; replayed again in the final gate. Google and device-specific checks remain unverified.

Gate not passed: none.

Not verified: see final summary and the per-task evidence below.

## Stage 1C — Splits and settlements

- [x] 1C.1 `core`: rounding function, all split methods, debt attribution
- [x] 1C.2 API: every transaction type and split
- [x] 1C.3 Web: transaction type, several payers, transfer and income forms
- [x] 1C.4 Web: split editor
- [x] 1C.5 Web: settling, and transfers and income in the stream
- [x] 1C.6 Stage gate 1C

### Gate 1C

Result: passed. Fixed split/type/settlement figures, reset acceptance, balances and permissions passed; replayed again in the final gate.

Gate not passed: none.

Not verified: see final summary and the per-task evidence below.

## Stage 1D — Quick entry

- [x] 1D.1 `core`: the sentence reader
- [x] 1D.2 API: parse endpoint
- [x] 1D.3 Web: typing box and confirmation card
- [x] 1D.4 Web: questions and sentences that are not understood
- [x] 1D.5 Stage gate 1D

### Gate 1D

Result: passed. All 75 samples, four saved drafts, stored counts, reset prior acceptance and permissions passed; replayed again in the final gate.

Gate not passed: none.

Not verified: see final summary and the per-task evidence below.

## Stage 1E — History and polish

- [x] 1E.1 API: read, edit, delete and restore a transaction
- [x] 1E.2 API: activity feed and group deletion
- [x] 1E.3 Web: edit, delete with undo, conflict
- [x] 1E.4 Web: history and deleting a group
- [x] 1E.5 Web: offline state, new-item pill, motion
- [x] 1E.6 Non-functional checks and final gate

### Final gate

Result: passed. Outbound-denied build, pnpm check, reset sample trip, replayed 1A–1D acceptance, complete endpoint permission matrix and final balance checker passed.

Gate not passed: none.

Not verified: physical/device, external Google/mail and 4G items listed in the final summary; no result is claimed for them.

## Final summary

- Completed: 41/41 tasks, 1A.1 through 1E.6, on phase-1. One commit per task; no push, merge, branch change or automated tests. The final task commit is uniquely identified by `docs(run): complete phase 1 run records` (D33).
- Gates: all five stage acceptance gates passed, including a reset final trip and complete role matrix. Final pnpm check passed (236 files; all workspace typechecks Done); outbound-denied pnpm build passed; final balance checker found six groups, sum 0/mismatches 0, `All groups balanced`.
- Unresolved implementation items: none. Gate not passed: none. Non-functional verification is scoped to the actual local evidence below.
- Decisions: 33 recorded decisions, D1–D33. Advisor attention: D19 native OAuth adapter instead of unavailable arctic; D22 cached qrcode instead of unavailable uqr; D24 API import of the pure Vietnamese message source; D26 last-editor DTO; D28 deletion order; D32 explicit identity choices. These are review inputs, not external-service verification.
- Not verified: real Google round trip; real mail/HTTPS/deployment/backups (server step); online dependency audit (external calls forbidden); 4G cold time-to-visible; physical screen-reader speech/software-keyboard reach; valid-invite S12 narrow layout; real native share/camera delivery; two physical phones/independent profiles through the whole trip; owner visual/mockup and reduced-motion judgment; passage of the hourly cleanup timer. Browser observer + HTTP actor exercises are distinguished from two real browser profiles.
- Later evidence supersedes earlier deferred UI checks: all original edit split/payer/type inputs, A01/A23/A43 browser saves, refusal banners, paste/NFC, viewer restrictions, history live updates and new-item scroll behavior were exercised in 1E.6. Temporary curl printers and comparison loops stayed outside Git and contain no test framework/assertions.
- Owner checklist: manual-checks.md is consolidated by S1–S13, then flows A–H, with Google checks separate. The run stops after the final task commit; the advisor reviews this branch before owner manual acceptance/merge.


## Task 1A.1 — Approach
- Create the dependency-free core package with the contract package's module/export/typecheck configuration.
- Implement equal splitting with BigInt division and remainder; preserve input order.
- Implement greedy settlements on copied balances and pairwise netting with BigInt accumulation.
- Reject invalid IDs, unsafe amounts, unbalanced totals and unsafe aggregated outputs with RangeError.
- Keep all exercises ephemeral; add no automated tests or assertion scripts.

### Task 1A.1 — Results
pnpm check: passed (57 files; all five workspace typechecks Done, including core).
Completed: dependency-free equal split, greedy settlements and pairwise netting; checked the entire source and lockfile diff.
Exercise: Node's local TypeScript support executed the functions directly (no tsx dependency added). Real output, in plan row order:
```text
split 300000: 100000,100000,100000
split 100000: 33334,33333,33333
split 100: 34,33,33
split 10: 3,3,2,2
split 2: 1,1,0
split 1: 1
split 999999999999: 142857142857 (each of seven)
split 0: RangeError
split 1.5: RangeError
split empty IDs: RangeError
split duplicated IDs: RangeError
minimized: c→a 250000; b→a 120000; d→a 80000
minimized: c→a 100; c→b 100
minimized: a→c 50; b→c 50
minimized: c→a 60; d→b 30; d→a 10
minimized: []
minimized unbalanced: RangeError
pairwise: b→a 70; c→a 50
pairwise: b→a 90; c→b 90
pairwise: []
pairwise unknown member: RangeError
```
Security review: checked relevant items 1, 2, 8 against actual diff; no secrets, no runtime dependencies, positive safe integer input validation and exact integer accumulation. Network-backed audit not run because external services are forbidden.
Not verified: no visual feature in this task.
Deviation: `pnpm install --offline` exited 1 with `ERR_PNPM_NO_OFFLINE_META` for @tailwindcss/node. A subsequent `pnpm exec biome` unexpectedly invoked installation and supply-chain verification (232 entries) before formatting; it exited 0. The tool's external activity was not independently inspected. Use direct installed binaries for subsequent tooling where possible. No packages were added beyond the dependency-free workspace package.
Out of scope: none.

Commit 1A.1: `6a6f9d6`.

## Task 1A.2 — Approach
- Add three schema files matching the approved columns and constraints; export their tables and DbExecutor.
- Generate the table migration with the installed drizzle-kit and a separate custom migration containing the plan SQL.
- Add the read-only balance command with database-side exact sums and mismatch counts.
- Exercise migrations twice and commit/rollback constraints against the existing local Docker database, then remove exercise rows.

### Task 1A.2 — Exercise output

valid
```text
BEGIN
INSERT 0 1
INSERT 0 1
INSERT 0 2
COMMIT
```

wrong shares
```text
BEGIN
INSERT 0 1
INSERT 0 1
INSERT 0 2
ERROR:  transaction shares total differs from amount
CONTEXT:  PL/pgSQL function assert_transaction_integrity(uuid) line 23 at RAISE
SQL statement "SELECT assert_transaction_integrity(NEW.id)"
PL/pgSQL function check_transaction_row() line 3 at PERFORM
```

wrong payer
```text
BEGIN
INSERT 0 1
INSERT 0 1
INSERT 0 2
ERROR:  transaction payers total differs from amount
CONTEXT:  PL/pgSQL function assert_transaction_integrity(uuid) line 19 at RAISE
SQL statement "SELECT assert_transaction_integrity(NEW.id)"
PL/pgSQL function check_transaction_row() line 3 at PERFORM
```

foreign member
```text
BEGIN
INSERT 0 1
INSERT 0 1
INSERT 0 2
ERROR:  transaction references a member of another group
CONTEXT:  PL/pgSQL function assert_transaction_integrity(uuid) line 35 at RAISE
SQL statement "SELECT assert_transaction_integrity(NEW.id)"
PL/pgSQL function check_transaction_row() line 3 at PERFORM
```

zero amount
```text
BEGIN
ERROR:  new row for relation "transactions" violates check constraint "transactions_amount_check"
DETAIL:  Failing row contains (0193a1b2-0000-7000-8000-000000000104, 0193a1b2-0000-7000-8000-000000000001, expense, Ledger exercise, 0, VND, 2026-11-12 15:52:25.807525+00, null, equal, {}, 1, null, null, 2026-11-12 15:52:25.807525+00, 2026-11-12 15:52:25.807525+00, null).
```

second owner
```text
BEGIN
ERROR:  duplicate key value violates unique constraint "group_users_owner_unique"
DETAIL:  Key (group_id)=(0193a1b2-0000-7000-8000-000000000001) already exists.
```

delete used member
```text
ERROR:  update or delete on table "members" violates foreign key constraint "transaction_payers_member_id_members_id_fk" on table "transaction_payers"
DETAIL:  Key (id)=(0193a1b2-0000-7000-8000-000000000011) is still referenced from table "transaction_payers".
```

change share
```text
BEGIN
UPDATE 1
ERROR:  transaction shares total differs from amount
CONTEXT:  PL/pgSQL function assert_transaction_integrity(uuid) line 23 at RAISE
SQL statement "SELECT assert_transaction_integrity(OLD.transaction_id)"
PL/pgSQL function check_transaction_line() line 4 at PERFORM
```

```text
0193a1b2-0000-7000-8000-000000000001 Ledger exercise: sum 0; mismatches 0
0193a1b2-0000-7000-8000-000000000002 Other ledger exercise: sum 0; mismatches 0
All groups balanced
$ pnpm --filter @songphang/db check-balances
$ tsx --env-file=../../.env src/check-balances.ts
```

### Task 1A.2 — Results
Completed: eight ledger tables, generated table migration and plan-provided deferred integrity triggers; exported DbExecutor; read-only balance command.
pnpm check: passed (63 files; every workspace typecheck Done). Initial formatting failure in generated metadata was resolved by formatting only the generated JSON.
Migrations: `pnpm db:migrate` twice → `Migrations applied`, exit 0 both times.
Cleanup: initial autocommit line deletion was refused by the deferred trigger; repeating all cleanup statements in one explicit transaction → `BEGIN; DELETE 2; DELETE 1; DELETE 1; DELETE 2; COMMIT`. Final balance command → `No groups`, exit 0. All exercise rows removed.
Security review: checked relevant items 1, 2, 5, 6, 8 against schema, generated SQL, custom SQL and script diff. No secrets; all checks, foreign keys and indexes present; parameterized static read queries; Zod validates query result structure. No new dependencies; network audit omitted under the external-services prohibition.
Size review: checkBalances is slightly over 40 lines because the two adjacent read-only SQL queries belong to one inspection operation; no abstraction introduced for a one-off command.
Decisions: D3.
Deviations: direct installed drizzle-kit binary instead of pnpm exec to avoid auto-install; generated JSON formatted for the existing gate.
Not verified: none for task exercises.
Out of scope: none.

Commit 1A.2: `bb7a515`.

## Task 1A.3 — Approach
- Add Zod group/member contracts, appearance allocation, and typed database query files.
- Centralize group authorization before route validation, returning the same 404 for malformed, absent and inaccessible groups.
- Store idempotency results in the same transaction as writes and recover only the key's unique-constraint race.
- Add thin OpenAPI routes, group services, the 100 KiB body limit and expired-key cleanup.
- Batch group-list membership/preview/balance reads; never issue one query per group.

### Task 1A.3 — Exercise output
```text
create 201 {"group": {"id": "01a1d079-c6a5-797a-acd4-dc23d7d0213d", "name": "Đà Lạt 12/2026", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d079-c6a6-7ff6-afff-6ece79e017a8", "createdAt": "2026-11-12T15:56:44.068Z"}}
list 200 {"groups": [{"id": "01a1d079-c6a5-797a-acd4-dc23d7d0213d", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 4, "previewMembers": [{"id": "01a1d079-c6a6-7ff6-afff-6ece79e017a8", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1d079-c6a8-7f25-820d-8dc0bd017af0", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1d079-c6a9-7e4b-a69d-48c1e3f989ce", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1d079-c6aa-75c9-b9c7-b66fa2f9c134", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 0}]}
edit 200 {"group": {"id": "01a1d079-c6a5-797a-acd4-dc23d7d0213d", "name": "Đà Lạt 12/2026", "currency": "VND", "minimizeDebts": false, "role": "owner", "myMemberId": "01a1d079-c6a6-7ff6-afff-6ece79e017a8", "createdAt": "2026-11-12T15:56:44.068Z"}}
empty edit 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1d079-c6da-74c9-bd7b-711ff86a0dd5"}}
outsider read 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d079-c6e4-78b9-b3aa-f1d882eec388"}}
outsider edit 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d079-c6ed-780a-952f-2fa11e7abd36"}}
random UUID 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d079-c6f6-71fd-aa1d-d08c0fabf59d"}}
malformed ID 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d079-c6fe-7b37-a9a3-7d5f75043dee"}}
outsider list 200 {"groups": []}
signed out 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d079-c70f-7278-94aa-568e77d46fff"}}
replay 201 {"group": {"id": "01a1d079-c6a5-797a-acd4-dc23d7d0213d", "name": "Đà Lạt 12/2026", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d079-c6a6-7ff6-afff-6ece79e017a8", "createdAt": "2026-11-12T15:56:44.068Z"}}
conflict 409 {"error": {"code": "IDEMPOTENCY_KEY_REUSED", "message": "Idempotency key was used with another request", "requestId": "01a1d079-c720-770b-84ab-2706d8b70973"}}
missing key 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"idempotency-key": ["Invalid input: expected string, received undefined"]}, "requestId": "01a1d079-c72a-7bfe-ae81-d9864a4e422e"}}
bad origin 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request origin is not allowed", "requestId": "01a1d079-c732-73a9-8999-c7eac1ad128f"}}
oversized body 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request body is too large", "requestId": "01a1d079-c73b-793a-899a-8228f2cb82a2"}}
 action | entity_type |    summary     
--------+-------------+----------------
 create | group       | Đà Lạt 12/2026
 update | group       | Đà Lạt 12/2026
(2 rows)

 count 
-------
     1
(1 row)

```

Concurrent create exercise (two curl processes, same key/body):
```text
{"group":{"id":"01a1d079-f0d7-7bb7-93d4-7aa82261bf88","name":"Concurrent exercise","currency":"VND","minimizeDebts":true,"role":"owner","myMemberId":"01a1d079-f0d9-7128-bd49-0a1aefb7612f","createdAt":"2026-11-12T15:56:54.871Z"}}
201
{"group":{"id":"01a1d079-f0d7-7bb7-93d4-7aa82261bf88","name":"Concurrent exercise","currency":"VND","minimizeDebts":true,"role":"owner","myMemberId":"01a1d079-f0d9-7128-bd49-0a1aefb7612f","createdAt":"2026-11-12T15:56:54.871Z"}}
201
```

### Task 1A.3 — Results
pnpm check: passed (74 files; all workspace typechecks Done).
Completed: group create/list/read/update, appearance assignment, shared authorization, idempotency, 100 KiB body limit, startup/hourly expiry cleanup.
Security review: relevant items 1–6, 8 checked against actual source and staged diff. Group paths authorize before body/path schema validation; all outsider/malformed/random IDs have identical 404 body apart from requestId. Parameterized database reads/writes, transactional create and activity, same-origin writes, response DTOs strip internal invite tokens. Concurrent duplicate creates returned the same 201 body. No external runtime service called.
Size review: createGroup is over 40 lines because it explicitly inserts the group, ordered members, ownership and activity in the caller's single transaction; splitting the single operation would obscure the write sequence. Route registration exceeds 40 lines due to declarative schema attachment and thin handlers. No file exceeds 200 lines.
Decisions: D4.
Deviations: local workspace lock entry/symlink written directly; pnpm check still unexpectedly emitted package-manager supply-chain verification once after the package metadata changed. This behavior is environmental, and is recorded rather than claiming all tool activity was offline.
Not verified: hourly timer passage was not waited for; its startup path ran without error.
Out of scope: none.

Commit 1A.3: `8483f09`.

## Task 1A.4 — Approach
- Extend the existing member contract and queries for list/create/update/delete.
- Lock the group for member writes so position and appearance selection serialize.
- Keep member lookups group-scoped and reject deletion when any historical payer/share references exist.
- Use the existing authorization/idempotency and transactional activity patterns.

### Task 1A.4 — Exercise output
```text
list 200 {"members": [{"id": "01a1d079-c6a6-7ff6-afff-6ece79e017a8", "name": "Minh", "active": true, "defaultWeight": "1.00", "position": 0, "shape": "circle", "color": "mint", "isMe": true}, {"id": "01a1d079-c6a8-7f25-820d-8dc0bd017af0", "name": "Lan", "active": true, "defaultWeight": "1.00", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}, {"id": "01a1d079-c6a9-7e4b-a69d-48c1e3f989ce", "name": "Hùng", "active": true, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}, {"id": "01a1d079-c6aa-75c9-b9c7-b66fa2f9c134", "name": "Thu", "active": true, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}]}
create trimmed 201 {"member": {"id": "01a1d07b-f017-7a18-be46-24576ee6d016", "name": "Bác Tư", "active": true, "defaultWeight": "1.00", "position": 4, "shape": "circle", "color": "sky", "isMe": false}}
appearance 6 201 {"member": {"id": "01a1d07b-f030-7641-a57b-192d508ce019", "name": "Person 0", "active": true, "defaultWeight": "1.00", "position": 5, "shape": "diamond", "color": "coral", "isMe": false}}
appearance 7 201 {"member": {"id": "01a1d07b-f045-753c-8db9-8bd6f246404d", "name": "Person 1", "active": true, "defaultWeight": "1.00", "position": 6, "shape": "squircle", "color": "lilac", "isMe": false}}
appearance 8 201 {"member": {"id": "01a1d07b-f057-7042-a36f-a3892de9134b", "name": "Person 2", "active": true, "defaultWeight": "1.00", "position": 7, "shape": "leaf", "color": "mint", "isMe": false}}
appearance 9 201 {"member": {"id": "01a1d07b-f065-7259-9771-37578d0823fd", "name": "Person 3", "active": true, "defaultWeight": "1.00", "position": 8, "shape": "circle", "color": "coral", "isMe": false}}
appearance 10 201 {"member": {"id": "01a1d07b-f072-7050-8a15-17da945308a8", "name": "Person 4", "active": true, "defaultWeight": "1.00", "position": 9, "shape": "diamond", "color": "lilac", "isMe": false}}
appearance 11 201 {"member": {"id": "01a1d07b-f081-7315-9d17-6b598d56d4a2", "name": "Person 5", "active": true, "defaultWeight": "1.00", "position": 10, "shape": "squircle", "color": "mint", "isMe": false}}
appearance 12 201 {"member": {"id": "01a1d07b-f090-764f-b557-ecbfa3d57486", "name": "Person 6", "active": true, "defaultWeight": "1.00", "position": 11, "shape": "leaf", "color": "sky", "isMe": false}}
appearance 13 201 {"member": {"id": "01a1d07b-f09e-70c4-8d00-a87af12f772a", "name": "Person 7", "active": true, "defaultWeight": "1.00", "position": 12, "shape": "circle", "color": "lilac", "isMe": false}}
appearance 14 201 {"member": {"id": "01a1d07b-f0ab-7e9b-b0fc-0ed2009c0171", "name": "Person 8", "active": true, "defaultWeight": "1.00", "position": 13, "shape": "diamond", "color": "mint", "isMe": false}}
appearance 15 201 {"member": {"id": "01a1d07b-f0bb-7398-aed8-9a62e2656867", "name": "Person 9", "active": true, "defaultWeight": "1.00", "position": 14, "shape": "squircle", "color": "sky", "isMe": false}}
appearance 16 201 {"member": {"id": "01a1d07b-f0cc-766d-be3d-57e0a85b34a7", "name": "Person 10", "active": true, "defaultWeight": "1.00", "position": 15, "shape": "leaf", "color": "coral", "isMe": false}}
appearance 17 201 {"member": {"id": "01a1d07b-f0db-752d-90ac-682b015b98e2", "name": "Person 11", "active": true, "defaultWeight": "1.00", "position": 16, "shape": "circle", "color": "mint", "isMe": false}}
rename 200 {"member": {"id": "01a1d079-c6a8-7f25-820d-8dc0bd017af0", "name": "Lan Anh", "active": true, "defaultWeight": "1.00", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}}
deactivate 200 {"member": {"id": "01a1d079-c6a9-7e4b-a69d-48c1e3f989ce", "name": "Hùng", "active": false, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}}
weight 200 {"member": {"id": "01a1d079-c6a8-7f25-820d-8dc0bd017af0", "name": "Lan Anh", "active": true, "defaultWeight": "1.50", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}}
negative weight 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"defaultWeight": ["Invalid string: must match pattern /^\\d{1,4}(\\.\\d{1,2})?$/"]}, "requestId": "01a1d07b-f10a-7fde-a3ba-ff67ba2ea9db"}}
empty name 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"name": ["Too small: expected string to have >=1 characters"]}, "requestId": "01a1d07b-f113-7b6e-8abf-fc7e4ff47724"}}
empty update 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1d07b-f11c-7282-86d3-c4ef1a6b7026"}}
delete unused 204 null
reuse appearance 201 {"member": {"id": "01a1d07b-f135-7c6f-8a76-9be997df69bc", "name": "Replacement", "active": true, "defaultWeight": "1.00", "position": 17, "shape": "circle", "color": "sky", "isMe": false}}
other group 201 {"group": {"id": "01a1d07b-f142-7afd-af2c-064eebbd93d8", "name": "Other group", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d07b-f143-7153-8444-e46220a1a19c", "createdAt": "2026-11-12T15:59:06.050Z"}}
foreign member 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f14e-753b-85e4-49c8b17e2068"}}
outsider GET 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f158-73cf-98e6-47f23f0ed7e9"}}
outsider POST 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f161-7d9a-81ca-28343afdca8b"}}
outsider PATCH 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f16a-70da-9e68-ba2a39555b4d"}}
outsider DELETE 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f172-785d-8013-377a0dff243d"}}
duplicate 1 201 {"member": {"id": "01a1d07b-f17e-73aa-b8e9-a4f022d6b402", "name": "Duplicate", "active": true, "defaultWeight": "1.00", "position": 18, "shape": "squircle", "color": "coral", "isMe": false}}
duplicate 2 201 {"member": {"id": "01a1d07b-f17e-73aa-b8e9-a4f022d6b402", "name": "Duplicate", "active": true, "defaultWeight": "1.00", "position": 18, "shape": "squircle", "color": "coral", "isMe": false}}
malformed member 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07b-f192-76a2-b0f1-99c3540b518f"}}
```

### Task 1A.4 — Results
pnpm check: passed (76 files; all workspace typechecks Done).
Completed: member list/create/update/delete with group-scoped access, serialized appearance allocation and transactional history. Every planned curl case ran with the actual outputs above, including the 17th member reusing circle/mint and reusing the deleted member's freed circle/sky pair.
Security review: relevant items 1–6, 8 checked against current diff; authenticated/authorized endpoints, same-origin writes, Zod request boundaries and UUID validation before member queries; no cross-group member query; idempotent creation; parameterized queries and transactional history. No new dependencies or secrets.
Size review: member services and route registration exceed 40 lines in places due to explicit transaction steps/schema wiring; kept together as one operation per exported service and no file above 200 lines.
Decisions: none.
Deviations: none.
Not verified: deletion of a member with transactions is exercised after transaction creation is available in 1A.5.
Out of scope: none.

Commit 1A.4: `197a6dc`.

## Task 1A.5 — Approach
- Add transaction request/response contracts with integer money and unique split members.
- Implement ordered core-backed share calculation shared by create and preview; lock the group during create.
- Keep transaction/payer/share/activity writes in the idempotency transaction.
- Use keyset pagination and batch payer/share reads, validating decoded cursor data before querying.

### Task 1A.5 — Exercise output
```text
fresh group 201 {"group": {"id": "01a1d07e-8794-76a4-a366-5e70e8970cc5", "name": "Task5 ledger", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "createdAt": "2026-11-12T16:01:55.603Z"}}
members 200 {"members": [{"id": "01a1d07e-8796-7200-87b8-90da6f966bf4", "name": "Minh", "active": true, "defaultWeight": "1.00", "position": 0, "shape": "circle", "color": "mint", "isMe": true}, {"id": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "name": "Lan", "active": true, "defaultWeight": "1.00", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}, {"id": "01a1d07e-879a-729f-a4a2-4240a29e512a", "name": "Hùng", "active": true, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}, {"id": "01a1d07e-879c-7a7c-b1cf-59826eb665de", "name": "Thu", "active": true, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}]}
preview 200 {"shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 45000}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 45000}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 45000}, {"memberId": "01a1d07e-879c-7a7c-b1cf-59826eb665de", "amount": 45000}]}
transaction count after preview SQL "0"
create coffee 201 {"transaction": {"type": "expense", "description": "Cà phê", "amount": 100000, "occurredAt": "2026-11-12T10:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 100000}], "split": {"method": "equal", "members": ["01a1d07e-8796-7200-87b8-90da6f966bf4", "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "01a1d07e-879a-729f-a4a2-4240a29e512a"]}, "id": "01a1d07e-8902-7cab-a280-9bb688acf0d6", "currency": "VND", "shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 33334}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 33333}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 33333}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:01:55.968Z", "updatedAt": "2026-11-12T16:01:55.968Z", "deletedAt": null}}
reverse split order 201 {"transaction": {"type": "expense", "description": "Cà phê", "amount": 100000, "occurredAt": "2026-11-12T10:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 100000}], "split": {"method": "equal", "members": ["01a1d07e-879a-729f-a4a2-4240a29e512a", "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "01a1d07e-8796-7200-87b8-90da6f966bf4"]}, "id": "01a1d07e-8919-715b-8101-777af0f3acf7", "currency": "VND", "shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 33334}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 33333}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 33333}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:01:55.991Z", "updatedAt": "2026-11-12T16:01:55.991Z", "deletedAt": null}}
create hotpot 201 {"transaction": {"type": "expense", "description": "Lẩu", "amount": 300000, "occurredAt": "2026-11-12T10:00:00.000Z", "category": "food", "payers": [{"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 300000}], "split": {"method": "equal", "members": ["01a1d07e-8796-7200-87b8-90da6f966bf4", "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "01a1d07e-879a-729f-a4a2-4240a29e512a", "01a1d07e-879c-7a7c-b1cf-59826eb665de"]}, "id": "01a1d07e-892a-7cd0-8f55-add69584a6ad", "currency": "VND", "shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 75000}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 75000}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 75000}, {"memberId": "01a1d07e-879c-7a7c-b1cf-59826eb665de", "amount": 75000}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:01:56.009Z", "updatedAt": "2026-11-12T16:01:56.009Z", "deletedAt": null}}
pagination create 0 201 id=01a1d07e-893c-7f35-a40b-4b7495089fec
pagination create 1 201 id=01a1d07e-894e-75d0-95ae-ffd6d04635e2
pagination create 2 201 id=01a1d07e-895e-7dbb-8b45-531fbddad7cb
pagination create 3 201 id=01a1d07e-8970-7719-a063-924ffbf5ca6a
pagination create 4 201 id=01a1d07e-8981-7786-9455-bbe8ac34f4ff
pagination create 5 201 id=01a1d07e-8992-79cc-a974-0367cd7796b0
pagination create 6 201 id=01a1d07e-89a2-7c9b-a285-04d1c213eacd
pagination create 7 201 id=01a1d07e-89b2-7196-a741-34a2fe3ce4ec
pagination create 8 201 id=01a1d07e-89c2-7d47-a188-3727635044fe
pagination create 9 201 id=01a1d07e-89d3-7572-9028-f2797323aac3
pagination create 10 201 id=01a1d07e-89e3-7073-bcd1-fd1ec9d40203
pagination create 11 201 id=01a1d07e-89f3-781f-b96e-a74ebd997bf6
pagination create 12 201 id=01a1d07e-8a04-75fd-9cff-ddbdae77af9e
pagination create 13 201 id=01a1d07e-8a14-76b9-8b26-696a67569c29
pagination create 14 201 id=01a1d07e-8a24-7f63-b063-7b4def8f9e38
pagination create 15 201 id=01a1d07e-8a34-72ff-90a1-a69dbcea57d0
pagination create 16 201 id=01a1d07e-8a45-796e-8fac-46e97b0b6bd0
pagination create 17 201 id=01a1d07e-8a55-7073-bd96-f75f30f2c6c8
pagination create 18 201 id=01a1d07e-8a66-7584-a936-78153c372176
pagination create 19 201 id=01a1d07e-8a75-70bc-ac73-862b15052bd5
pagination create 20 201 id=01a1d07e-8a85-73aa-8c85-7670537473f7
pagination create 21 201 id=01a1d07e-8a94-7f08-9985-8ae5fc7c5c78
pagination create 22 201 id=01a1d07e-8aa3-7247-83bf-568994d8525d
pagination create 23 201 id=01a1d07e-8ab3-766b-956e-d641f4c2bd6b
pagination create 24 201 id=01a1d07e-8ac3-71a7-a78e-4ef3a3f21171
pagination create 25 201 id=01a1d07e-8ad3-7195-a3d8-cf88302f813b
pagination create 26 201 id=01a1d07e-8ae5-7ddf-896d-e4c8702aa0fa
pagination create 27 201 id=01a1d07e-8af7-7e53-a259-17210da28927
pagination create 28 201 id=01a1d07e-8b07-73f2-913b-899d720d4d8c
pagination create 29 201 id=01a1d07e-8b16-7e08-bb54-af94cd210517
pagination create 30 201 id=01a1d07e-8b27-75e8-becd-2c6e5467e7ba
pagination create 31 201 id=01a1d07e-8b37-7022-82eb-72a0d025eed4
pagination create 32 201 id=01a1d07e-8b46-72bb-9e2e-190d7f945e78
pagination create 33 201 id=01a1d07e-8b56-7f68-9006-658be4e811e4
pagination create 34 201 id=01a1d07e-8b66-75c2-9bc3-7f074a8b999b
pagination create 35 201 id=01a1d07e-8b75-7fc9-9d82-474322024c62
pagination create 36 201 id=01a1d07e-8b85-7723-832b-ac6c84f37a2a
pagination create 37 201 id=01a1d07e-8b96-731e-b8c5-7f59e47b251c
pagination create 38 201 id=01a1d07e-8ba6-7300-abad-5ffe441dea83
pagination create 39 201 id=01a1d07e-8bb6-71db-9e82-b35b77c72d0b
pagination create 40 201 id=01a1d07e-8bc6-7b64-85dd-c8dc3155922c
pagination create 41 201 id=01a1d07e-8bd5-757f-8cbb-a75c2e664c45
pagination create 42 201 id=01a1d07e-8be4-76a1-af66-2a781e050860
pagination create 43 201 id=01a1d07e-8bf4-77bb-86b7-0c0e0b47fb50
pagination create 44 201 id=01a1d07e-8c03-7313-a8ae-3949f3ebd7b4
pagination create 45 201 id=01a1d07e-8c13-70da-b784-88ed9e28a792
pagination create 46 201 id=01a1d07e-8c23-7eb9-8f4d-54a1eec3ad5c
pagination create 47 201 id=01a1d07e-8c32-7c97-9bfb-2c80d3ae91dd
pagination create 48 201 id=01a1d07e-8c41-7a4c-bebd-7368fc0ad519
pagination create 49 201 id=01a1d07e-8c51-7d52-9585-4590cdf1fab7
pagination create 50 201 id=01a1d07e-8c61-7b9f-9091-83930a29edc3
pagination create 51 201 id=01a1d07e-8c71-76c8-9e0e-e6d1e40f535d
pagination create 52 201 id=01a1d07e-8c80-7048-b49e-8d6a227b4831
pagination create 53 201 id=01a1d07e-8c90-7f38-a101-b12dbaac2ae0
pagination create 54 201 id=01a1d07e-8c9e-7a9c-90a8-d699c5898b90
pagination create 55 201 id=01a1d07e-8cad-7414-856e-106dd0317738
pagination create 56 201 id=01a1d07e-8cbd-7491-8f5b-098788318724
pagination create 57 201 id=01a1d07e-8ccd-7e00-9d04-d73cce7dc78f
pagination create 58 201 id=01a1d07e-8cdb-7007-bef5-59a767ef3419
pagination create 59 201 id=01a1d07e-8ceb-79ad-ba64-415ab8c132fd
page 1 200 {"count": 50, "ids": ["01a1d07e-8ceb-79ad-ba64-415ab8c132fd", "01a1d07e-8cdb-7007-bef5-59a767ef3419", "01a1d07e-8ccd-7e00-9d04-d73cce7dc78f", "01a1d07e-8cbd-7491-8f5b-098788318724", "01a1d07e-8cad-7414-856e-106dd0317738", "01a1d07e-8c9e-7a9c-90a8-d699c5898b90", "01a1d07e-8c90-7f38-a101-b12dbaac2ae0", "01a1d07e-8c80-7048-b49e-8d6a227b4831", "01a1d07e-8c71-76c8-9e0e-e6d1e40f535d", "01a1d07e-8c61-7b9f-9091-83930a29edc3", "01a1d07e-8c51-7d52-9585-4590cdf1fab7", "01a1d07e-8c41-7a4c-bebd-7368fc0ad519", "01a1d07e-8c32-7c97-9bfb-2c80d3ae91dd", "01a1d07e-8c23-7eb9-8f4d-54a1eec3ad5c", "01a1d07e-8c13-70da-b784-88ed9e28a792", "01a1d07e-8c03-7313-a8ae-3949f3ebd7b4", "01a1d07e-8bf4-77bb-86b7-0c0e0b47fb50", "01a1d07e-8be4-76a1-af66-2a781e050860", "01a1d07e-8bd5-757f-8cbb-a75c2e664c45", "01a1d07e-8bc6-7b64-85dd-c8dc3155922c", "01a1d07e-8bb6-71db-9e82-b35b77c72d0b", "01a1d07e-8ba6-7300-abad-5ffe441dea83", "01a1d07e-8b96-731e-b8c5-7f59e47b251c", "01a1d07e-8b85-7723-832b-ac6c84f37a2a", "01a1d07e-8b75-7fc9-9d82-474322024c62", "01a1d07e-8b66-75c2-9bc3-7f074a8b999b", "01a1d07e-8b56-7f68-9006-658be4e811e4", "01a1d07e-8b46-72bb-9e2e-190d7f945e78", "01a1d07e-8b37-7022-82eb-72a0d025eed4", "01a1d07e-8b27-75e8-becd-2c6e5467e7ba", "01a1d07e-8b16-7e08-bb54-af94cd210517", "01a1d07e-8b07-73f2-913b-899d720d4d8c", "01a1d07e-8af7-7e53-a259-17210da28927", "01a1d07e-8ae5-7ddf-896d-e4c8702aa0fa", "01a1d07e-8ad3-7195-a3d8-cf88302f813b", "01a1d07e-8ac3-71a7-a78e-4ef3a3f21171", "01a1d07e-8ab3-766b-956e-d641f4c2bd6b", "01a1d07e-8aa3-7247-83bf-568994d8525d", "01a1d07e-8a94-7f08-9985-8ae5fc7c5c78", "01a1d07e-8a85-73aa-8c85-7670537473f7", "01a1d07e-8a75-70bc-ac73-862b15052bd5", "01a1d07e-8a66-7584-a936-78153c372176", "01a1d07e-8a55-7073-bd96-f75f30f2c6c8", "01a1d07e-8a45-796e-8fac-46e97b0b6bd0", "01a1d07e-8a34-72ff-90a1-a69dbcea57d0", "01a1d07e-8a24-7f63-b063-7b4def8f9e38", "01a1d07e-8a14-76b9-8b26-696a67569c29", "01a1d07e-8a04-75fd-9cff-ddbdae77af9e", "01a1d07e-89f3-781f-b96e-a74ebd997bf6", "01a1d07e-89e3-7073-bcd1-fd1ec9d40203"], "nextCursor": "eyJvY2N1cnJlZEF0IjoiMjAyNi0xMS0xMlQxMDowMDowMC4wMDBaIiwiaWQiOiIwMWExZDA3ZS04OWUzLTcwNzMtYmNkMS1mZDFlYzlkNDAyMDMifQ"}
page 2 200 {"count": 13, "ids": ["01a1d07e-89d3-7572-9028-f2797323aac3", "01a1d07e-89c2-7d47-a188-3727635044fe", "01a1d07e-89b2-7196-a741-34a2fe3ce4ec", "01a1d07e-89a2-7c9b-a285-04d1c213eacd", "01a1d07e-8992-79cc-a974-0367cd7796b0", "01a1d07e-8981-7786-9455-bbe8ac34f4ff", "01a1d07e-8970-7719-a063-924ffbf5ca6a", "01a1d07e-895e-7dbb-8b45-531fbddad7cb", "01a1d07e-894e-75d0-95ae-ffd6d04635e2", "01a1d07e-893c-7f35-a40b-4b7495089fec", "01a1d07e-892a-7cd0-8f55-add69584a6ad", "01a1d07e-8919-715b-8101-777af0f3acf7", "01a1d07e-8902-7cab-a280-9bb688acf0d6"], "nextCursor": null}
zero 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"amount": ["Too small: expected number to be >=1"]}, "requestId": "01a1d07e-8d0e-7793-bb33-40459963acca"}}
fraction 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"amount": ["Invalid input: expected int, received number"]}, "requestId": "01a1d07e-8d18-7bfb-89af-8ac65efc9013"}}
above max 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"amount": ["Too big: expected number to be <=999999999999"]}, "requestId": "01a1d07e-8d21-7e86-b646-150a53645e15"}}
blank description 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"description": ["Too small: expected string to have >=1 characters"]}, "requestId": "01a1d07e-8d2a-7b33-a093-ef1b43daa53f"}}
no sharers 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.members": ["Too small: expected array to have >=1 items"]}, "requestId": "01a1d07e-8d32-7f84-9c9b-42058de328e1"}}
duplicate sharer 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.members": ["Invalid input"]}, "requestId": "01a1d07e-8d3b-72a3-aebd-497f31be318f"}}
two payers 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"payers": ["Too big: expected array to have exactly 1 items"]}, "requestId": "01a1d07e-8d43-7045-8356-84f3769b7208"}}
wrong paid total 400 {"error": {"code": "PAYER_TOTAL_MISMATCH", "message": "Payer total differs from amount", "details": {"expected": 100000, "actual": 90000}, "requestId": "01a1d07e-8d4b-7f58-803b-f76ddfa2b0b5"}}
foreign member 400 {"error": {"code": "MEMBER_NOT_IN_GROUP", "message": "Member does not belong to group", "requestId": "01a1d07e-8d56-7c82-9353-a9742e9b3e91"}}
transfer 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"type": ["Invalid input: expected \"expense\""]}, "requestId": "01a1d07e-8d61-7578-b447-cdd11f962089"}}
invalid limit=0 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"limit": ["Too small: expected number to be >=1"]}, "requestId": "01a1d07e-8d69-7925-a848-d4ce2d11feef"}}
invalid limit=201 400 {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"limit": ["Too big: expected number to be <=200"]}, "requestId": "01a1d07e-8d71-7e69-8fdd-81a999f046ef"}}
invalid cursor=abc 400 {"error": {"code": "VALIDATION_FAILED", "message": "Invalid cursor", "requestId": "01a1d07e-8d79-77ad-ae64-a05d2651526f"}}
duplicate replay 201 {"transaction": {"type": "expense", "description": "Cà phê", "amount": 100000, "occurredAt": "2026-11-12T10:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 100000}], "split": {"method": "equal", "members": ["01a1d07e-8796-7200-87b8-90da6f966bf4", "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "01a1d07e-879a-729f-a4a2-4240a29e512a"]}, "id": "01a1d07e-8902-7cab-a280-9bb688acf0d6", "currency": "VND", "shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 33334}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 33333}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 33333}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:01:55.968Z", "updatedAt": "2026-11-12T16:01:55.968Z", "deletedAt": null}}
duplicate changed 409 {"error": {"code": "IDEMPOTENCY_KEY_REUSED", "message": "Idempotency key was used with another request", "requestId": "01a1d07e-8d8b-7141-8e7c-1bb3d1297b4c"}}
outsider GET 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07e-8d96-7fd7-9905-f7508945c7f1"}}
outsider POST 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07e-8d9d-7d59-95bd-69ac4bb16b97"}}
outsider POST/preview 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07e-8da6-7b82-8f19-249f23d2c854"}}
delete member with transactions 422 {"error": {"code": "MEMBER_HAS_TRANSACTIONS", "message": "Member has transactions", "requestId": "01a1d07e-8dad-70a4-b9ca-8b4ea52dbcda"}}
deactivate sharer 200 {"member": {"id": "01a1d07e-879a-729f-a4a2-4240a29e512a", "name": "Hùng", "active": false, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}}
explicit inactive sharer 200 {"shares": [{"memberId": "01a1d07e-8796-7200-87b8-90da6f966bf4", "amount": 33334}, {"memberId": "01a1d07e-8799-7a1e-9c75-30a3673cf6a8", "amount": 33333}, {"memberId": "01a1d07e-879a-729f-a4a2-4240a29e512a", "amount": 33333}]}
01a1d079-c6a5-797a-acd4-dc23d7d0213d Đà Lạt 12/2026: sum 0; mismatches 0
01a1d079-f0d7-7bb7-93d4-7aa82261bf88 Concurrent exercise: sum 0; mismatches 0
01a1d07b-f142-7afd-af2c-064eebbd93d8 Other group: sum 0; mismatches 0
01a1d07e-8794-76a4-a366-5e70e8970cc5 Task5 ledger: sum 0; mismatches 0
All groups balanced
$ pnpm --filter @songphang/db check-balances
$ tsx --env-file=../../.env src/check-balances.ts
```

Known member of another existing group, preview result:
```text
{"error":{"code":"MEMBER_NOT_IN_GROUP","message":"Member does not belong to group","requestId":"01a1d07f-08b2-7a65-b57c-7a3d95b4bad3"}}
400
```

### Task 1A.5 — Results
pnpm check: passed (80 files, all workspace typechecks Done).
Completed: create, no-write preview and keyset-paginated listing with batched payer/share queries. The recorded 50 + 13 IDs contain no duplicates between pages; final cursor is null. Reverse split order preserves the extra đồng for position 0.
Security review: relevant items 1–6, 8 checked against actual diff. Group authorization precedes request validation; all writes are same-origin and create is idempotent. Safe integer contract, membership validation before totals, core-only division, parameterized group-scoped queries, one transaction for ledger lines and activity. No secrets/new dependencies.
Size review: createTransaction exceeds 40 lines because its explicit transaction writes map all approved columns, payer/share rows and history; no file exceeds 200 lines.
Decisions: none.
Deviations: none.
Not verified: none for task exercises.
Out of scope: account-deletion rendering of nullable historical createdBy is deferred to the account task that introduces deletion.

Commit 1A.5: `96f7be9`.

## Task 1A.6 — Approach
- Add the balance response contract and one grouped pair-debt query.
- Reuse existing ordered balance reads and core settlement functions.
- Add a thin viewer-authorized route and exercise both debt modes plus inactive members.

### Task 1A.6 — Exercise output
```text
fresh group 201 {"group": {"id": "01a1d07f-f513-7726-9247-de57b018987c", "name": "Task6 balances", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "createdAt": "2026-11-12T16:03:29.170Z"}}
members 200 {"members": [{"id": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "name": "Minh", "active": true, "defaultWeight": "1.00", "position": 0, "shape": "circle", "color": "mint", "isMe": true}, {"id": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "name": "Lan", "active": true, "defaultWeight": "1.00", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}, {"id": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "name": "Hùng", "active": true, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}, {"id": "01a1d07f-f51a-7961-9f76-022c4a56a524", "name": "Thu", "active": true, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}]}
empty balances 200 {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 0}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": 0}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": 0}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": 0}], "transfers": []}
Vé cáp treo 201 {"transaction": {"type": "expense", "description": "Vé cáp treo", "amount": 800000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 800000}], "split": {"method": "equal", "members": ["01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "01a1d07f-f517-75c2-a3db-c96987ca90ed", "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "01a1d07f-f51a-7961-9f76-022c4a56a524"]}, "id": "01a1d07f-f551-7abf-aa59-7d14b15ed768", "currency": "VND", "shares": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 200000}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "amount": 200000}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "amount": 200000}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:03:29.230Z", "updatedAt": "2026-11-12T16:03:29.230Z", "deletedAt": null}}
after cable 200 {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 600000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": -200000}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": -200000}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}, {"fromMemberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}]}
Lẩu 201 {"transaction": {"type": "expense", "description": "Lẩu", "amount": 300000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 300000}], "split": {"method": "equal", "members": ["01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "01a1d07f-f517-75c2-a3db-c96987ca90ed", "01a1d07f-f519-7a6e-94f9-ed704f7667ab"]}, "id": "01a1d07f-f576-7bf3-8220-75a2ce58dae1", "currency": "VND", "shares": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 100000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 100000}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "amount": 100000}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:03:29.268Z", "updatedAt": "2026-11-12T16:03:29.268Z", "deletedAt": null}}
after hotpot 200 {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 500000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": 0}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": -300000}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 300000}, {"fromMemberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}]}
disable minimizing 200 {"group": {"id": "01a1d07f-f513-7726-9247-de57b018987c", "name": "Task6 balances", "currency": "VND", "minimizeDebts": false, "role": "owner", "myMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "createdAt": "2026-11-12T16:03:29.170Z"}}
pairwise 200 {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 500000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": 0}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": -300000}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 100000}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 100000}, {"fromMemberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}]}
deactivate Thu 200 {"member": {"id": "01a1d07f-f51a-7961-9f76-022c4a56a524", "name": "Thu", "active": false, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}}
inactive balance 200 {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 500000}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": 0}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": -300000}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 100000}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 100000}, {"fromMemberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}]}
Cà phê 201 {"transaction": {"type": "expense", "description": "Cà phê", "amount": 100000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 100000}], "split": {"method": "equal", "members": ["01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "01a1d07f-f517-75c2-a3db-c96987ca90ed", "01a1d07f-f519-7a6e-94f9-ed704f7667ab"]}, "id": "01a1d07f-f5c3-7125-878f-a59ab1cc7c28", "currency": "VND", "shares": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 33334}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 33333}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "amount": 33333}], "version": 1, "createdBy": {"id": "01a1cd7b-5691-7f2c-8ce1-355d36415149", "name": "Minh"}, "createdAt": "2026-11-12T16:03:29.346Z", "updatedAt": "2026-11-12T16:03:29.346Z", "deletedAt": null}}
after rounding 200 {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "balance": 566666}, {"memberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "balance": -33333}, {"memberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "balance": -333333}, {"memberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 133333}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 233333}, {"fromMemberId": "01a1d07f-f519-7a6e-94f9-ed704f7667ab", "toMemberId": "01a1d07f-f517-75c2-a3db-c96987ca90ed", "amount": 100000}, {"fromMemberId": "01a1d07f-f51a-7961-9f76-022c4a56a524", "toMemberId": "01a1d07f-f515-7d5e-93e4-e0f2cebcb151", "amount": 200000}]}
outsider 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1d07f-f5db-7640-8393-ec87899ec462"}}
signed out 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d07f-f5e3-7c97-a80d-03d131e6d4cd"}}
01a1d079-c6a5-797a-acd4-dc23d7d0213d Đà Lạt 12/2026: sum 0; mismatches 0
01a1d079-f0d7-7bb7-93d4-7aa82261bf88 Concurrent exercise: sum 0; mismatches 0
01a1d07b-f142-7afd-af2c-064eebbd93d8 Other group: sum 0; mismatches 0
01a1d07e-8794-76a4-a366-5e70e8970cc5 Task5 ledger: sum 0; mismatches 0
01a1d07f-f513-7726-9247-de57b018987c Task6 balances: sum 0; mismatches 0
All groups balanced
$ pnpm --filter @songphang/db check-balances
$ tsx --env-file=../../.env src/check-balances.ts
```

### Task 1A.6 — Results
pnpm check: passed (83 files; all workspace typechecks Done).
Completed: viewer-authorized balances with core minimized and pairwise settlements. All table response numbers match the plan: +600000/-200000 each after cable; +500000/0/-300000/-200000 after hotpot; pairwise 100000,200000,100000,200000; deactivation preserves Thu's -200000. After coffee: +566666/-33333/-333333/-200000, sum zero.
Security review: relevant items 1, 2, 3, 4, 5, 6, 8 checked against current diff; authorization, group-scoped parameterized query, validated DTO and exact integer sums. No secrets or new dependencies.
Decisions: none.
Deviations: database balance command ran after the complete sequence; intermediate returned balances were inspected for zero sum.
Not verified: none for returned API numbers.
Out of scope: none.

Commit 1A.6: `fc8709d`.

## Task 1A.7 — Approach
- Add shared formatting/request/session-guard helpers and the three approved UI primitives.
- Reuse TanStack Query and existing MemberShape/Button styles for group cards and creation.
- Copy the task's strings exactly into vi.ts; use only named color tokens.
- Keep one idempotency key per mounted creation screen and preserve fields on errors.

### Task 1A.7 — Results
pnpm check: passed (95 files; every workspace typecheck Done).
Completed: S2 group list and S3 creation screen; shared formatting/request/session helpers; Icon, ScreenHeader, LoadError; exact task strings and color tokens.
Browser exercise (CUA, localhost, viewport 360px): existing browser session was Hùng, so creation exercised as Hùng rather than Minh. Empty groups showed `Bạn chưa có nhóm nào` and enabled `Tạo nhóm`. Added Lan/Hùng/Thu → `Tạo nhóm 4 người`; removed Lan → `Tạo nhóm 3 người`, following shapes reflowed; Enter with spaces added nothing. Empty name kept submit disabled. Measured document scrollWidth 360, innerWidth 360 on both screens.
Stopped the owned API, clicked create → `Chưa lưu được. Kiểm tra mạng rồi thử lại.`; all names and group name retained. Restarted API, double-clicked submit → `/g/01a1d084-c4cc-74ce-8221-4a7b47bd659b`, Next.js 404 as planned until 1A.8. Returning to `/` → one yellow card with `0`/`bạn đã xong`. Created second group → newest yellow card, first compact with `3 người` and `0 đã xong`.
SQL real output after double click: `Nhóm kiểm tra giao diện | 1`, `Nhóm mới nhất | 1`.
Signed out and opened `/groups/new` → `/dev-login?next=%2Fgroups%2Fnew`; selected Lan → returned to `/groups/new` with Lan as creator.
Formatter exercise real output: `150.000 150.000 đ −320.000 +450.000 120 33.334`.
Security review: relevant items 1, 2, 6, 7, 8 checked against actual diff. Same-origin apiFetch, schema-validated API responses, encoded path IDs, internal return path, no local/session storage, no HTML injection. No secrets or dependencies added.
Size review: extracted NewGroupMembers; all new components under 150 lines.
Decisions: D5, D6.
Deviations: source-only contract extensions fixed as required by the browser compilation failure. Added currency symbol to vi.ts so formatting has no user-visible literal outside messages.
Not verified: comparison with the external mockup canvas is left to the owner; no external service opened.
Out of scope: none.

Commit 1A.7: `6c7d24e`.

## Task 1A.8 — Approach
- Add group member/balance queries and an infinite transaction query with validated responses.
- Render the approved two expense styles and official balance block using shared money formatting.
- Keep the stream in one scroll container; preserve the visible anchor when older pages load.
- Add S4 loading, empty, error and inaccessible states with the interim manual-entry bar.

### Task 1A.8 — Results
pnpm check: passed (104 files; all workspace typechecks Done).
Browser (CUA, 360px): empty four-person group showed `Ghi khoản chi đầu tiên`, `Bạn đã xong 0 đ Xem`, no shortcut. After 800000 Minh/four and 300000 Lan/three: `Bạn được nhận 500.000 đ Thu về`, right row four 200 chips, left row `Lan trả`, `Chia đều 3 · phần bạn 100.000`.
Created 118 further expenses with curl (real statuses: `{'201': 118}`) for 120 total. Included Hùng paying only for Lan/Thu → `Chia đều 2 · bạn không có phần`; coffee 100000/three → spans `33.334`, `33.333`, `33.333`. Yesterday and 05/11/2026 separators present (transaction description Hôm qua independently has the same text).
Initial stream: scrollHeight 5976, clientHeight 132, scrollTop 5843.33 (bottom). First upward scroll loaded next 50: scrollHeight 11801, scrollTop 5825.33; visible anchor remained `Khoản cũ 69`. Second loaded last 20: 120 expense payer labels, height 14175, scrollTop 2374, visible anchor `Khoản cũ 19`. No horizontal overflow: scrollWidth 360/innerWidth 360.
Malformed group and Lan opening Minh's group both rendered `Không tìm thấy nhóm này.` with back link. One initial browser wait timed out while queries retried, then the expected error rendered. Stopped API/reloaded → `Không tải được. Kiểm tra mạng rồi thử lại.` and `Thử lại`, URL stayed the group URL.
Security review: relevant items 1, 2, 6, 7, 8 checked against actual diff; validated response DTOs, same-origin reads, no browser-side official money arithmetic, no storage or HTML injection, internal group links. No secrets or new dependencies.
Decisions: none.
Deviations: empty content scrolls within short viewports so the hint remains reachable; transfer pill text stays on one line.
Not verified: external GE14/GE17 canvas comparison is for owner; browser verification uses the supplied numerical layout requirements.
Out of scope: none.

Commit 1A.8: `5388717`.

## Task 1A.9 — Approach
- Add create mutation and debounced API preview query using the existing transaction contract.
- Build amount/category/member controls with native inputs and accessible buttons.
- Keep form state local, official shares from preview, default payer from myMemberId and sharers from active members.
- Reuse one mounted form key and a synchronous submit guard for double clicks; preserve fields on errors.

### Task 1A.9 — Results
pnpm check: passed (110 files; all workspace typechecks Done).
Browser exercises: amount autofocus, default Minh payer/all active sharers; 180000 → `180.000` and four `45.000`; deselect Thu → three `60.000`; 100 + 000 → `100.000`, shares `33.334/33.333/33.333`. Description empty disabled save. Deselect everyone → `Chọn ít nhất một người để chia.` and disabled save. `abc1.5tr` → `15`; filling `1000000000000` left the prior valid `15` unchanged.
Stopped API, saved `Khoản kiểm tra form` → exact save error with all fields retained; restarted and double-clicked → returned to group, new row once. SQL `count(*)` for `Khoản kiểm tra form`, `Cà phê ba thao tác`, and `Khoản tuần trước từ form` was 1 each. Amount/description/Enter on save recorded `Cà phê ba thao tác` in three interactions from defaults.
Deactivated Hùng through API (200), reopened → only Minh/Lan/Thu in both grids. All seven categories present as pressed buttons; accessibility exposes member names and selected states.
Viewport tool uses physical pixels at DPR 1.5; override 585×1266 yielded measured CSS innerWidth 390, innerHeight 844, scrollWidth 390, scrollHeight 844. CSS 360 width also measured scrollWidth 360. Override reset afterwards.
Date investigation: CUA fill changed the native DOM value without React's value attribute. Native ArrowUp/ArrowDown emitted input events, synchronizing both to `2026-11-05T10:00`; save stored SQL `Ngày cũ qua bàn phím | 2026-11-05 03:00:00+00`, the correct UTC instant. The first attempted date fixture retained the current date; it was not silently described as a successful old-date check. No product fix needed.
After splitting the component/controller, browser created `Kiểm tra sau tách form`, preview `60.000` for three active people, returned to the group and showed the new row.
`pnpm db:check-balances` → every group sum 0/mismatches 0, `All groups balanced`.
Security review: relevant items 1, 2, 6, 7, 8 checked against actual diff: contract-validated draft/response, API-computed shares only, same-origin writes, mounted idempotency key and synchronous submit guard, no local/session storage, unsafe HTML or secrets. No dependencies added.
Decisions: D7, D8.
Deviations: semantic fieldsets provide the required group role under existing accessibility lint rules.
Not verified: real screen-reader speech and external GE19 comparison remain for the owner; accessibility tree checked.
Out of scope: none.

Commit 1A.9: `f09530d`.

## Task 1A.10 — Approach
- Add balances strings and the three approved presentation components.
- Render official API transfers with viewer-involving transfers first and balance signs as text.
- Use proportional bars only as display geometry, with all money figures unchanged from API.
- Add loading/error/not-found/empty/all-settled states and exercise the two debt modes.

### Task 1A.10 — Results
pnpm check: passed (114 files, all workspace typechecks Done).
Browser: fresh group → `Chưa có gì để tính`; one Minh-only expense → `Cả nhóm đã xong.`, all four members at 0 đ. Added cable 800000/four and Lan hotpot 300000/three → `2 lượt chuyển là xong`, `Hùng trả bạn 300.000`, `Thu trả bạn 200.000`; bars Minh +500000, Lan 0, Thu -200000, Hùng -300000. API response matched all displayed amounts.
PATCH minimizeDebts false and deactivate Thu → `4 lượt chuyển là xong`; ordered cards Lan→you 100000, Hùng→you 200000, Thu→you 200000, Hùng→Lan 100000; pairwise hint exact; bars unchanged with `Thu ngừng hoạt động −200.000`. Lan signed in and opened the private balances URL → `Không tìm thấy nhóm này.`.
Security review: relevant items 1, 2, 6, 7, 8 checked against current diff; official numbers unchanged from validated API responses; only proportional bar geometry uses a fractional ratio; no local/session storage or HTML injection, secrets or new dependencies.
Size review: all new components under 150 lines.
Decisions: none.
Deviations: added a zero-net self-only expense to the same fixture to exercise all-settled before the two nonzero expenses; it does not change the expected numbers.
Not verified: external GE5/GE18 comparison remains for owner.
Out of scope: none.

Commit 1A.10: `606545c`.

## Task 1A.11 — Approach
- Add member mutation hooks with existing invalidation/idempotency patterns.
- Render one expanded member editor at a time, deactivation warnings and undeletable-history errors.
- Reuse NewMemberRow with server-matching appearance previews and one key per opened row.
- Add owner settings with validated name and a pending/rollback-capable Gộp nợ switch.

### Task 1A.11 — Results
pnpm check: passed (120 files; all workspace typechecks Done). `pnpm db:check-balances` → all nine groups sum 0/mismatches 0; `All groups balanced`.
Browser: four rows; Minh displayed `Bạn`/`Chủ nhóm`. Added Bác Tư with Enter → five rows and `5 người`; preview circle/sky. Renamed Lan → `Sửa Lan Anh`, appearance unchanged. Deleted unused Bác Tư via curl → 204. Hùng delete button → `Hùng đã có khoản chi nên không xoá được. Hãy cho ngừng hoạt động.`.
Deactivate Hùng → exact warning with `−300.000 đ`; `Thôi` preserved active status; `Vẫn ngừng` displayed inactive label and `Hoạt động lại`; reactivation restored active status. Opening Minh's editor exposed only name/save, no deactivate/delete.
Settings: renamed group to `Nhóm đã đổi tên`; database balance output confirmed new name. Pressed Space on `Gộp nợ` switch → on; API balances minimized true, two transfers, unchanged +500000/0/-300000/-200000. Empty name kept save disabled. Stopped API, pressed Space again → exact save error and switch rolled back to on (AX Value 1).
Security review: relevant items 1, 2, 4, 6, 7, 8 checked against current diff. API remains authorization authority; owner settings guard; validated DTO mutations, same-origin writes, encoded IDs, idempotent creates, API balances only. No secrets, storage, unsafe HTML or dependencies.
Size review: all components below 150 lines.
Decisions: in 1A only the creator can have a linked user, so member.isMe identifies the protected linked row; 1B explicitly expands this.
Deviations: successful deletion of the disposable unused fixture exercised via curl; undeletable historical member exercised through the browser button.
Not verified: external GE9/GE11 comparison and real screen-reader speech; browser AX switch name/state verified. Renamed stream/list propagation is implemented through member/group query invalidation, but those two screens were not revisited for this specific rename.
Out of scope: none.

Commit 1A.11: `9160d77`.

## Task 1A.12 — Approach
- Document the existing balance-check command in README.
- Run static/build gates with outbound network denied.
- Reset the local disposable Docker database as required, seed users and replay fixed acceptance numbers through curl.
- Replay every implemented group endpoint as owner, outsider and signed out; record real status and normalized errors.

### Stage 1A — Reset acceptance and permission matrix
```text
Create 201 {"group": {"id": "01a1d09b-d60d-7cbe-8fdb-b1e0257aefc2", "name": "Đà Lạt 12/2026", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "createdAt": "2026-11-12T16:33:56.237Z"}}
Vé cáp treo 201 {"transaction": {"type": "expense", "description": "Vé cáp treo", "amount": 800000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 800000}], "split": {"method": "equal", "members": ["01a1d09b-d610-75aa-833d-fdec26104104", "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "01a1d09b-d613-7162-ad0f-0cd7741d2423", "01a1d09b-d614-769e-b026-0b7c3b4dd4c1"]}, "id": "01a1d09b-d63b-7379-9724-00097ad68847", "currency": "VND", "shares": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 200000}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 200000}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "amount": 200000}, {"memberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "amount": 200000}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:33:56.281Z", "updatedAt": "2026-11-12T16:33:56.281Z", "deletedAt": null}}
Lẩu 201 {"transaction": {"type": "expense", "description": "Lẩu", "amount": 300000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 300000}], "split": {"method": "equal", "members": ["01a1d09b-d610-75aa-833d-fdec26104104", "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "01a1d09b-d613-7162-ad0f-0cd7741d2423"]}, "id": "01a1d09b-d656-74ee-b9d7-209db6d79d56", "currency": "VND", "shares": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 100000}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 100000}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "amount": 100000}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:33:56.307Z", "updatedAt": "2026-11-12T16:33:56.307Z", "deletedAt": null}}
Cà phê 201 {"transaction": {"type": "expense", "description": "Cà phê", "amount": 100000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 100000}], "split": {"method": "equal", "members": ["01a1d09b-d610-75aa-833d-fdec26104104", "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "01a1d09b-d613-7162-ad0f-0cd7741d2423"]}, "id": "01a1d09b-d669-7dc5-a776-fb838fb7235f", "currency": "VND", "shares": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 33334}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 33333}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "amount": 33333}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:33:56.328Z", "updatedAt": "2026-11-12T16:33:56.328Z", "deletedAt": null}}
Minimized ["200", {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "balance": 566666}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "balance": -33333}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "balance": -333333}, {"memberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 333333}, {"fromMemberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 200000}, {"fromMemberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 33333}]}]
Disable minimizing ["200", {"group": {"id": "01a1d09b-d60d-7cbe-8fdb-b1e0257aefc2", "name": "Đà Lạt 12/2026", "currency": "VND", "minimizeDebts": false, "role": "owner", "myMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "createdAt": "2026-11-12T16:33:56.237Z"}}]
Pairwise ["200", {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "balance": 566666}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "balance": -33333}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "balance": -333333}, {"memberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 133333}, {"fromMemberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 233333}, {"fromMemberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "toMemberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 100000}, {"fromMemberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 200000}]}]
Deactivate Thu ["200", {"member": {"id": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "name": "Thu", "active": false, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}}]
Taxi 201 {"transaction": {"type": "expense", "description": "Taxi", "amount": 90000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 90000}], "split": {"method": "equal", "members": ["01a1d09b-d610-75aa-833d-fdec26104104", "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "01a1d09b-d613-7162-ad0f-0cd7741d2423"]}, "id": "01a1d09b-d6ab-75cf-9efb-230164c8ed66", "currency": "VND", "shares": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 30000}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 30000}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "amount": 30000}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:33:56.393Z", "updatedAt": "2026-11-12T16:33:56.393Z", "deletedAt": null}}
After taxi ["200", {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1d09b-d610-75aa-833d-fdec26104104", "balance": 626666}, {"memberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "balance": -63333}, {"memberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "balance": -363333}, {"memberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 163333}, {"fromMemberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 263333}, {"fromMemberId": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "toMemberId": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "amount": 100000}, {"fromMemberId": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "toMemberId": "01a1d09b-d610-75aa-833d-fdec26104104", "amount": 200000}]}]
Permission matrix: endpoint | owner | outsider | random UUID outsider | malformed outsider | signed out; normalized outsider/random/malformed bodies
GET group | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
PATCH group | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
GET members | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
POST member | 201 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
PATCH member | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
DELETE member | 204 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
POST preview | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
POST transaction | 201 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
GET transactions | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
GET balances | 200 | 404 | 404 | 404 | 401 | [{"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
GET groups owner ["200", {"groups": [{"id": "01a1d09b-d60d-7cbe-8fdb-b1e0257aefc2", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1d09b-d610-75aa-833d-fdec26104104", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1d09b-d612-7812-8fb6-0ceecbe65b34", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1d09b-d613-7162-ad0f-0cd7741d2423", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1d09b-d614-769e-b026-0b7c3b4dd4c1", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 626666}]}]
GET groups outsider ["200", {"groups": []}]
01a1d09b-d60d-7cbe-8fdb-b1e0257aefc2 Đà Lạt 12/2026: sum 0; mismatches 0
All groups balanced
$ pnpm --filter @songphang/db check-balances
$ tsx --env-file=../../.env src/check-balances.ts

```

### Task 1A.12 — Results
pnpm check: passed after formatting README's updated table (120 files; all typechecks Done).
Build command: `NEXT_TELEMETRY_DISABLED=1 sandbox-exec -p '(version 1)(allow default)(deny network-outbound)(allow network-outbound (remote ip "localhost:*"))' pnpm build` → exit 0, `Compiled successfully in 1248ms`, static pages 5/5, all nine expected routes listed. Outbound network prohibited during the real build.
Database reset: docker compose down -v removed the local volume; up --pull never --wait used the existing local image and became Healthy; migrations → `Migrations applied`; seed → `Development users seeded`.
Acceptance: fixed +566666/-33333/-333333/-200000 matched; minimized transfers 333333,200000,33333; pairwise 133333,233333,100000,200000; Taxi 30000 each and inactive Thu stays -200000. See raw output above.
Permission matrix: all ten implemented group-scoped endpoints owner 2xx, outsider/random/malformed 404 with identical normalized bodies, signed out 401. GET /groups remains intentionally 200 with an empty list for outsiders.
Security review: relevant items 1, 4, 5, 6, 8 checked through the complete stage gate and README diff. No new code in this task; no secrets or network-dependent audit.
Decisions: none.
Deviations: permission exercise adds a self-only expense of 1 đồng (zero net balance) and a disposable member after fixed acceptance; earlier-stage scripts do not exist yet.
Not verified: human visual/keyboard journey and external mockup comparison remain in manual-checks; per-task browser exercises already recorded.
Out of scope: none.

Commit 1A.12: `47b1317`.

## Task 1B.1 — Approach
- Add account identity/token tables and typed queries with atomic token consumption.
- Use installed Node crypto.argon2 documentation/types (since v24.7.0) and standard timingSafeEqual; no crypto library or implementation.
- Load the approved local password list once; keep one-time tokens hashed and invalidate prior tokens under a user lock.
- Add console-only mail templates, a fixed-window limiter and optional validated Google configuration.
- Extend UserDto in place and update shared user selects so all current callers keep working.

### Task 1B.1 — Results
pnpm check: passed (128 files; all workspace typechecks Done). Migrations twice → `Migrations applied`, exit 0.
Password exercise real output: two different PHC strings both beginning `$argon2id$v=19$m=19456,t=2,p=1$`; verification right/wrong/truncated → `true false false`. Rules in plan order → `too_short`, `too_common`, `too_common`, `too_common`, `too_long`, `ok`. Only the plan's public dummy exercise phrase was hashed; no account password or raw token recorded.
Token exercise real output: consume → `01a1d09a-f3c2-7e23-aa0d-064356513fb2 null`; wrong purpose → `null`; expired → `null`; superseded → `null`. SQL inspection: token hash length 64, all_hex t, count 5; raw tokens never printed.
Limiter initial output: `200/null`, `200/null`, `200/null`, `429/null` (missing Retry-After). Root cause: shared error handler discarded prepared headers. After fix: `200/null`, `200/null`, `200/null`, `429/60`.
Unpaired configuration → `Invalid environment variables: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET`. Production startup → `Mailer is not configured for production`, exit 1 before serving/migrating.
GET /me as seeded Minh → emailVerified true, hasPassword false.
Security review: relevant items 1–6, 8 checked against the actual source, generated migration and staged diff. Standard node:crypto argon2id/randomBytes/timingSafeEqual only; PHC bounds validated; one-time token stores SHA256 only, atomically consumed and superseded under user lock; identity credential CHECK/uniques; no secrets logged outside permitted development mail; production mail refuses startup. No new dependencies; network audit not run.
Decisions: D10–D12.
Deviations: added users.ts shared projections and errors.ts header preservation, both required by the new UserDto and Retry-After contract. Installed crypto type documentation used locally instead of contacting nodejs.org.
Not verified: real mail delivery intentionally absent; templates only print locally in development.
Out of scope: none.

Commit 1B.1: `01bb562`.

## Task 1B.2 — Approach
- Add validated account requests and thin authentication routes using existing session cookies.
- Keep account creation/token/identity writes atomic and send development mail only after commit.
- Prepare validated email keys in middleware, then apply socket-IP/email rate limits before account work.
- Attach shared verified-email and per-user write limits to existing group writes.
- Exercise enumeration, token replay, weak inputs and rate limits without printing session or raw token values.

### Task 1B.2 — Exercise output
```text
register new 204 null Set-Cookie=False
sign in good 204 null Set-Cookie=True
unverified me 200 {"user": {"id": "01a1d0a5-b17f-74e6-811e-7c60188d62bc", "email": "ngan@example.test", "name": "Ngân", "avatarUrl": null, "emailVerified": false, "hasPassword": true}} Set-Cookie=False
unverified create 403 {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1d0a5-b1c2-76a8-8fe2-0653b5306d0e"}} Set-Cookie=False
resend 1 204 null Set-Cookie=False
resend 2 204 null Set-Cookie=False
resend 3 204 null Set-Cookie=False
resend 4 429 {"error": {"code": "RATE_LIMITED", "message": "Too many requests", "requestId": "01a1d0a5-b1f2-760a-8b1a-e21b5643a89f"}} Set-Cookie=False Retry-After=3600
superseded verification 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0a5-b1fa-7d49-9612-ed584b5d918a"}} Set-Cookie=False
verify current 500 {"error": {"code": "INTERNAL", "message": "An internal error occurred", "requestId": "01a1d0a5-b205-7bda-90b1-e4c8f8945601"}} Set-Cookie=False
verified me 200 {"user": {"id": "01a1d0a5-b17f-74e6-811e-7c60188d62bc", "email": "ngan@example.test", "name": "Ngân", "avatarUrl": null, "emailVerified": false, "hasPassword": true}} Set-Cookie=False
verified create 403 {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1d0a5-b219-7a06-ac6f-b752ba019b28"}} Set-Cookie=False
token replay 500 {"error": {"code": "INTERNAL", "message": "An internal error occurred", "requestId": "01a1d0a5-b221-712e-87fe-64e4e166be53"}} Set-Cookie=False
made up token 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0a5-b22a-7e37-876d-d9c2d3fd2ef8"}} Set-Cookie=False
register existing 204 null Set-Cookie=False
register uppercase 204 null Set-Cookie=False
weak common 400 {"error": {"code": "WEAK_PASSWORD", "message": "Password does not meet requirements", "details": {"reason": "too_common"}, "requestId": "01a1d0a5-b25e-706f-bf66-8f67411b918e"}} Set-Cookie=False
weak short 400 {"error": {"code": "WEAK_PASSWORD", "message": "Password does not meet requirements", "details": {"reason": "too_short"}, "requestId": "01a1d0a5-b265-7822-a8a2-5de1f0b2f4f7"}} Set-Cookie=False
wrong password 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0a5-b26c-72c2-b91b-088670ba8e77"}} Set-Cookie=False
unknown account 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0a5-b282-7cd5-88ac-5b8926add044"}} Set-Cookie=False
email sign-in attempt 3 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0a5-b298-70db-aeb6-4b0b2e0b692c"}} Set-Cookie=False
email sign-in attempt 4 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0a5-b2ad-72d1-a60d-2e6f3ce06512"}} Set-Cookie=False
email sign-in attempt 5 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0a5-b2c4-7b16-a07a-e6a243773b57"}} Set-Cookie=False
email sign-in attempt 6 429 {"error": {"code": "RATE_LIMITED", "message": "Too many requests", "requestId": "01a1d0a5-b2da-7ba8-a535-949d30507739"}} Set-Cookie=False Retry-After=900
providers 200 {"google": false, "devLogin": true} Set-Cookie=False
new registration headers: "HTTP/1.1 204 No Content\nDate: Thu, 12 Nov 2026 16:44:42 GMT\nConnection: keep-alive\nKeep-Alive: timeout=5\n"
existing registration headers: "HTTP/1.1 204 No Content\nDate: Thu, 12 Nov 2026 16:44:42 GMT\nConnection: keep-alive\nKeep-Alive: timeout=5\n"
 count 
-------
     1
(1 row)

 argon2_only 
-------------
 t
(1 row)


```

### Task 1B.2 — Timestamp fix and re-exercise
```text
before fix-retry me 200 {"user": {"id": "01a1d0a5-b17f-74e6-811e-7c60188d62bc", "email": "ngan@example.test", "name": "Ngân", "avatarUrl": null, "emailVerified": false, "hasPassword": true}}
resend after restart 204 null
verify after timestamp fix 204 null
verified me 200 {"user": {"id": "01a1d0a5-b17f-74e6-811e-7c60188d62bc", "email": "ngan@example.test", "name": "Ngân", "avatarUrl": null, "emailVerified": true, "hasPassword": true}}
verified group create 201 {"group": {"id": "01a1d0a6-f77b-71bb-adec-a4cc0a44b2dd", "name": "Verified Ngân", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d0a6-f77c-7f20-b537-2ddcdd9a2957", "createdAt": "2026-11-12T16:46:05.691Z"}}
replay after success 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0a6-f789-7924-8521-666525d45d6a"}}
made up token 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0a6-f793-7967-8a7f-9d7e8f1d7e18"}}
dev-user regression group 201 {"group": {"id": "01a1d0a6-f79e-726a-9738-ae274091665c", "name": "1A verified-user regression", "currency": "VND", "minimizeDebts": true, "role": "owner", "myMemberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "createdAt": "2026-11-12T16:46:05.726Z"}}
regression members 200 {"members": [{"id": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "name": "Minh", "active": true, "defaultWeight": "1.00", "position": 0, "shape": "circle", "color": "mint", "isMe": true}, {"id": "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "name": "Lan", "active": true, "defaultWeight": "1.00", "position": 1, "shape": "diamond", "color": "sky", "isMe": false}, {"id": "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "name": "Hùng", "active": true, "defaultWeight": "1.00", "position": 2, "shape": "squircle", "color": "coral", "isMe": false}, {"id": "01a1d0a6-f7a1-777d-8de7-ba6ef652bbaa", "name": "Thu", "active": true, "defaultWeight": "1.00", "position": 3, "shape": "leaf", "color": "lilac", "isMe": false}]}
cable 201 {"transaction": {"type": "expense", "description": "cable", "amount": 800000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "amount": 800000}], "split": {"method": "equal", "members": ["01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "01a1d0a6-f7a1-777d-8de7-ba6ef652bbaa"]}, "id": "01a1d0a6-f7bb-764d-8ec5-8a2e968db491", "currency": "VND", "shares": [{"memberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "amount": 200000}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "amount": 200000}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "amount": 200000}, {"memberId": "01a1d0a6-f7a1-777d-8de7-ba6ef652bbaa", "amount": 200000}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:46:05.753Z", "updatedAt": "2026-11-12T16:46:05.753Z", "deletedAt": null}}
hotpot 201 {"transaction": {"type": "expense", "description": "hotpot", "amount": 300000, "occurredAt": "2026-11-12T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "amount": 300000}], "split": {"method": "equal", "members": ["01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8"]}, "id": "01a1d0a6-f7dd-72c4-a1f2-82fa44de30bf", "currency": "VND", "shares": [{"memberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "amount": 100000}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "amount": 100000}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "amount": 100000}], "version": 1, "createdBy": {"id": "01a1d09a-f3c2-7e23-aa0d-064356513fb2", "name": "Minh"}, "createdAt": "2026-11-12T16:46:05.787Z", "updatedAt": "2026-11-12T16:46:05.787Z", "deletedAt": null}}
regression balances 200 {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "balance": 500000}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c635f985548", "balance": 0}, {"memberId": "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "balance": -300000}, {"memberId": "01a1d0a6-f7a1-777d-8de7-ba6ef652bbaa", "balance": -200000}], "transfers": [{"fromMemberId": "01a1d0a6-f7a0-7eb5-bbed-8c64ac3e06b8", "toMemberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "amount": 300000}, {"fromMemberId": "01a1d0a6-f7a1-777d-8de7-ba6ef652bbaa", "toMemberId": "01a1d0a6-f79f-7bc4-82c8-d6d2c5b7f663", "amount": 200000}]}
```

### Task 1B.2 — Results
pnpm check: passed (132 files; all workspace typechecks Done).
Registration new/existing/uppercase → 204, empty body, no cookie; normalized application headers identical, same Date on the measured calls. One user row; password identity hash prefix inspected as argon2 only. Weak reasons and credential failures matched the plan. Resend fourth → 429 / Retry-After 3600; sixth email login attempt → 429 / Retry-After 900. Unknown and wrong-password 401 bodies identical apart from requestId.
Initial verification returned 500. Isolated query reproduction showed TypeError: Date passed as a raw sql parameter was not encoded. Changed only that raw parameter to an ISO string cast to timestamptz. Transaction rollback preserved token state. After restart/resend: verification 204, me emailVerified true, group creation 201, replay and made-up token both 400 TOKEN_INVALID.
Dev-user regression: create group with four members, cable 800000/four and hotpot 300000/three → balances +500000/0/-300000/-200000 and transfers 300000/200000; guards preserve 1A behavior for verified seeded users.
Security review: relevant items 1–6, 8 checked against actual route/service/query diff. Socket IP only, validated email rate keys; standard password hashing for known and unknown paths; register always hashes; no sessions at registration; mail after commit; token consumption and verification atomic; verified-user/write-limit middleware on existing data writes. Shared unexpected-error logging now cannot print SQL parameters/password hashes. No secrets in reports; local development console capture is private mode 0600 and excluded from git. No new dependencies.
Size review: account-auth route registration and register service are kept as single cohesive operations; route file under 200 lines.
Decisions: D13–D15.
Deviations: same-directory account-auth route module plus account-limits middleware; shared logger redaction required by section 9.
Not verified: real mail delivery intentionally absent.
Out of scope: none.

Commit 1B.2: `4a2d0ba`.

## Task 1B.3 — Approach
- Add recovery/change/delete request contracts and typed account/session queries.
- Keep reset token consumption, password update, verification and session revocation in one transaction.
- Require the current password for changes, preserving the current session when revoking others.
- Lock the account before owner-count/deletion; retain historical members/transactions via existing foreign keys.
- Exercise both session jars, token replay/wrong purpose, owner refusal and disposable account deletion.

### Task 1B.3 — Exercise output
```text
second session before reset 204 null Set-Cookie=True
forgot known 204 null Set-Cookie=False
forgot unknown 204 null Set-Cookie=False
reset mail blocks before/after unknown: 1/1
weak reset 400 {"error": {"code": "WEAK_PASSWORD", "message": "Password does not meet requirements", "details": {"reason": "too_short"}, "requestId": "01a1d0ab-b0de-7fde-99d7-a3f1aaa28335"}} Set-Cookie=False
reset valid same token 204 null Set-Cookie=False
session A after reset 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d0ab-b106-784a-bc51-a52fecfb28e5"}} Set-Cookie=False
session B after reset 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d0ab-b10f-7f8c-9a01-3698ec0fb2c2"}} Set-Cookie=False
old password after reset 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0ab-b119-7b83-bbc4-e7922e7b5409"}} Set-Cookie=False
new password A 204 null Set-Cookie=True
new password B 204 null Set-Cookie=True
reset token replay 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0ab-b163-72f7-9a66-98d51ce9d87c"}} Set-Cookie=False
wrong current password 401 {"error": {"code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect", "requestId": "01a1d0ab-b17a-7001-aa63-aa0358ea37bd"}} Set-Cookie=False
change and revoke others 204 null Set-Cookie=False
current session A remains 200 {"user": {"id": "01a1d0a5-b17f-74e6-811e-7c60188d62bc", "email": "ngan@example.test", "name": "Ngân", "avatarUrl": null, "emailVerified": true, "hasPassword": true}} Set-Cookie=False
other session B revoked 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d0ab-b1c2-72b7-a2be-f1548f19fb79"}} Set-Cookie=False
delete wrong confirmation 400 {"error": {"code": "VALIDATION_FAILED", "message": "Email confirmation does not match", "requestId": "01a1d0ab-b1ca-7ed3-8b49-6e09ebe7e53c"}} Set-Cookie=False
delete owner 422 {"error": {"code": "OWNER_REQUIRED", "message": "Transfer or delete owned groups first", "details": {"groupCount": 1}, "requestId": "01a1d0ab-b1d2-7245-99af-c669adaa97bb"}} Set-Cookie=False
register disposable account 204 null Set-Cookie=False
verification token to reset 400 {"error": {"code": "TOKEN_INVALID", "message": "Token is invalid or expired", "requestId": "01a1d0ab-b1fa-76a8-9505-ab594896573e"}} Set-Cookie=False
sign in disposable 204 null Set-Cookie=True
delete non-owner 204 null Set-Cookie=True
deleted session 401 {"error": {"code": "UNAUTHENTICATED", "message": "Authentication required", "requestId": "01a1d0ab-b239-77cd-86ab-2585d3aacafe"}} Set-Cookie=False
```

### Task 1B.3 — Results
pnpm check: passed (134 files, all workspace typechecks Done). Balance check: all three groups sum 0/mismatches 0; `All groups balanced`.
Forgot known and unknown → identical empty 204/no cookie; only known printed a reset mail (mail-block count 1 before and after unknown). Weak reset → WEAK_PASSWORD and the same token then succeeded. Reset revoked both old sessions (401 each); old password 401, new password 204 in both jars. Replay and verification-purpose token at reset → TOKEN_INVALID. Wrong current password → 401; revokeOthers change 204, current jar /me 200, other jar 401. Seeded passwordless account change → 404.
DELETE /me wrong email → 400; Ngân owning one group → 422 OWNER_REQUIRED, groupCount 1. Disposable non-owner account → 204 with cookie clearing; its next /me → 401.
Security review: relevant items 1–6, 8 checked against actual source/query/contract diff. Recovery token consumption/hash update/email verification/all-session revocation atomic; weak password checked before consumption; password change requires current hash comparison and preserves only current session hash when requested; account deletion requires email and owner count under lock; no raw tokens, passwords or session values in reports/logs. No dependencies added.
Decisions: D16–D18.
Deviations: recovery services/routes split into same-directory files; nullable deleted author is represented directly instead of inventing an identity. Token consumption now follows account-first lock ordering while retaining the conditional atomic UPDATE.
Not verified: deletion after joining a group, preservation of its member and authored transactions, and actual null-author reads must be re-exercised after 1B.7 as the task explicitly requires.
Out of scope: none.

Commit 1B.3: `a425e29`.

## Task 1B.4 — Approach
- Implement the Google claims-to-account service independently of the remote exchange.
- Keep authorization state, verifier and safe return path in short-lived HttpOnly cookies.
- Use Node randomBytes/SHA256/timingSafeEqual and a fixed HTTPS token endpoint; validate the returned ID-token payload with Zod.
- Exercise only local authorization redirects, rejected callbacks and plain-claims outcomes; never contact Google.
- Record the unavailable approved dependency as a material implementation deviation.

### Task 1B.4 — Local exercise output
```text
No Google config /auth/google {"error":{"code":"NOT_FOUND","message":"Resource not found","requestId":"01a1d0b2-ef49-7a0d-a5d8-6e5ac7621bbc"}}
404
No Google config /auth/providers {"google":false,"devLogin":true}
200
Authorization /g/abc 302 {"scheme": "https", "host": "accounts.google.com", "clientId": ["test-client-id"], "redirectUri": ["http://localhost:3000/api/v1/auth/google/callback"], "scope": ["openid email profile"], "hasCodeChallenge": true, "stateLength": 43, "challengeMethod": ["S256"], "cookieCount": 3, "httpOnlyCount": 3, "cookie600sCount": 3, "storedRedirect": "/g/abc"}
Authorization //evil.example 302 {"scheme": "https", "host": "accounts.google.com", "clientId": ["test-client-id"], "redirectUri": ["http://localhost:3000/api/v1/auth/google/callback"], "scope": ["openid email profile"], "hasCodeChallenge": true, "stateLength": 43, "challengeMethod": ["S256"], "cookieCount": 3, "httpOnlyCount": 3, "cookie600sCount": 3, "storedRedirect": "/"}
Wrong state 302 /login?error=google cookies cleared=3
Claims service:
new signed_in 01a1d0b2-64c0-7d46-b651-79f5ceedf33d
verified password signed_in 01a1d0a5-b17f-74e6-811e-7c60188d62bc
unverified password google_unverified null
known subject signed_in 01a1d0b2-64c0-7d46-b651-79f5ceedf33d
```

### Task 1B.4 — Results
pnpm check: passed (138 files; all workspace typechecks Done). Local redirect/claims outputs recorded above.
Security review: relevant items 1–6, 8 checked against source and query diff. HttpOnly/Lax/path-scoped short-lived cookies; standard randomBytes/SHA256 PKCE/timingSafeEqual state; bounded Zod query/cookie/claims inputs; safe internal redirect; fixed HTTPS token endpoint, redirects disabled and 10-second timeout; ID payload accepted only from that direct TLS exchange as specified. Verified password accounts may link; unverified password accounts cannot. No credentials, state/verifier/session values printed in the report.
Decisions: D19 (material deviation).
Deviations: arctic could not be installed offline; used a built-in Node/Web API adapter instead. Its behavior requires special advisor review. Google queries split to google-accounts.ts to keep accounts.ts below 200 lines.
Unresolved: the plan's approved arctic dependency is unavailable locally and was not added; no external registry or Google service was contacted for this task.
Not verified: real Google authorization/token exchange, ID-token delivery and real-account outcomes.
Out of scope: none.

Commit 1B.4: `6569a0f`.

## Task 1B.5 — Approach
- Add account mutation hooks and one accessible TextField; preserve typed fields across errors.
- Build the five specified auth pages with exact spec copy and safe internal return paths.
- Use a one-shot verification effect and explicit success/invalid/loading states.
- Replace unverified users' write controls with the shared resend banner on every specified screen.
- Extend ApiError to retain validated business details for weak-password messages.

### Task 1B.5 — Results
Resumed and deliberately completed the interrupted working tree for this task.
pnpm check: passed (147 files, all workspace typechecks Done).
Browser exercises: registration with nine characters → `Mật khẩu cần ít nhất 10 ký tự.`; common password → `Mật khẩu này quá phổ biến. Hãy chọn mật khẩu khác.` Valid registration → `Kiểm tra hộp thư của bạn`, without signing in. Unverified login → verification banner, no create-group control; direct new-group route also showed the banner. Resend → `Đã gửi lại thư xác minh.`; the previous token returned TOKEN_INVALID; the new development-console link → `Email đã được xác minh.` and `Vào ứng dụng`.
Six wrong logins → invalid-credentials copy then `Bạn thử quá nhiều lần. Đợi một lúc rồi thử lại.` Safe-next exercise with //evil.example landed on /. Signing in from a protected group route returned to the exact group URL. Google-unverified query displayed the exact long explanation. Forgot-password known and unknown emails both displayed the same generic confirmation. Missing reset token and invalid verification token displayed their specified recovery states.
Responsive DOM measurements at CSS 360px: login, register, forgot-password, verify-email, reset-password all scrollWidth 360. With placeholder Google configuration the Google button used the internal API authorization URL; without configuration it was absent. No remote Google navigation occurred. API restarted afterwards without placeholders.
Security review: relevant items 1, 2, 6, 7, 8 checked against the complete source diff. Typed error details validated before use; same-origin writes; internal-only return paths; no storage of credentials; no raw HTML or credentials in committed files. No dependency changes. Network audit not run because external services are forbidden.
Deviations: LoginShapes is a same-directory presentational split. Fixed accessible labels after a browser exercise showed the hint was part of the password label. Restarted the development server after stale route/SSR output caused a temporary 404 and hydration warning; fresh SSR then matched the source.
Not verified: browser submission of password reset requires credential-change handoff under the browser tool policy and was not performed; API reset was exercised in 1B.3. Real Google sign-in remains unverified. Full keyboard-only traversal was not completed.
Out of scope: none.

Commit 1B.5: `c21e611`.

## Task 1B.6 — Approach
- Add account mutation hooks and two focused cards using existing TextField and Button components.
- Keep password fields in component state and clear them only after a successful change.
- Validate the owner-count error details before interpolating localized copy.
- Replace the group-list avatar action with an account link; retain logout on the account page.
- Exercise read states in the browser and the write endpoints locally; credential-change/deletion browser policy limits are recorded explicitly.

### Task 1B.6 — Results
pnpm check: passed (150 files; all workspace typechecks Done). Corrected a typed interpolation error by converting the validated integer count to a string.
Browser: signed-out /account redirected to /login?next=%2Faccount. Ngân's account displayed identity, password card, checkbox, logout and deletion card. Empty and wrong email left deletion disabled. Logout returned to login. Minh's passwordless account hid the password card. API DELETE for Ngân returned OWNER_REQUIRED with groupCount 1, preserving the account.
Security review: relevant items 1, 2, 6, 7, 8 checked against actual page, cards, hooks and avatar diff. No credentials stored beyond component state; typed owner-count details; same-origin writes; deletion requires exact email; no dependency changes. API remains authoritative. Network audit not run (external services forbidden).
Decisions: none. Deviations: none.
Not verified: browser credential changes and destructive account submission were not performed because the browser policy requires a handoff/action-time confirmation. API password/session behavior was exercised in 1B.3. Joined-member preservation remains scheduled after 1B.7/1B.10.
Out of scope: none.

Commit 1B.6: `80c0124`.

## Task 1B.7 — Approach
- Add bounded invite contracts and group-scoped query functions; keep raw invite links out of reports.
- Reuse group locking and member creation so simultaneous claims serialize and member limits stay consistent.
- Lock the joining account before the group to preserve account-deletion ordering.
- Require shared group authorization for management/selection and existing verified/write/origin guards for writes.
- Add claimed to the existing member DTO and correlated database selection instead of a second member representation.

### Task 1B.7 — Results
pnpm check: passed (154 files; all workspace typechecks Done). Balance checker: all three groups sum 0, mismatches 0; `All groups balanced`.
Local curl exercises on the retained two-expense regression group: invite token length 43, active true. Preview → 200, owner Minh, four active members, two transactions, Minh claimed/balance null, Hùng unclaimed/-300000. Lan join → 200; list myBalance 0. Hùng claim Lan → 409 MEMBER_ALREADY_CLAIMED. Concurrent Thu claims → one 200, one 409. New Hùng em → 200/fifth member; Lan repeat → 200/no extra member. Hùng choose original Hùng → 200/new myMemberId, choose Lan → 409. Editor toggle → 403. Disable/unknown/old-after-rotation → identical INVITE_INVALID 404 apart from requestId; new token preview → 200. Unverified preview → 200, join → 403 EMAIL_NOT_VERIFIED. Preview limiter returned 429 after 24 further successful requests in the already-used 30-request window. Outsider GET/PATCH invite, POST rotate and PUT member → NOT_FOUND 404 each.
Security review: relevant items 1–8 checked against actual contract/query/service/route diff. Bounded Zod inputs, same-origin and verified/write guards, shared group authorization, account-before-group locks, group lock plus unique member constraint for claims, transaction for every multirow write, no emails in preview. Invite tokens omitted from logs/reports. No dependencies added; network audit not run.
Decisions: reused the existing group lock to serialize claim races; the unique constraint remains the database backstop. Invite route file is 208 lines because the six explicit OpenAPI contracts and thin handlers belong together; no abstraction introduced.
Deviations: exercise reused the existing two-expense regression group with a different name; its amounts and expected balances match the plan. Not verified: fresh-window exact 31st request (the exercised window already had requests); account deletion preserving joined authored transactions is carried to the joining UI exercise in 1B.10.
Out of scope: none.

Commit 1B.7: `7cb3e9a`.

## Task 1B.8 — Approach
- Add explicit role/user contracts and scoped queries; never return user emails.
- Serialize role/removal/leave/ownership changes on the group and recheck the actor after acquiring the lock.
- Transfer ownership by demoting then promoting atomically; lock both accounts in stable order before the group.
- Extend the current group DTO/update path with defaultRole and exercise all existing permission rows with four sessions.

### Task 1B.8 — Permission matrix output
```text
GET /group minh: 200
GET /group lan: 200
GET /group hung: 200
GET /group ngan: 404
GET /group signed-out: 401
GET /members minh: 200
GET /members lan: 200
GET /members hung: 200
GET /members ngan: 404
GET /members signed-out: 401
GET /users minh: 200
GET /users lan: 200
GET /users hung: 200
GET /users ngan: 404
GET /users signed-out: 401
GET /transactions minh: 200
GET /transactions lan: 200
GET /transactions hung: 200
GET /transactions ngan: 404
GET /transactions signed-out: 401
GET /balances minh: 200
GET /balances lan: 200
GET /balances hung: 200
GET /balances ngan: 404
GET /balances signed-out: 401
GET /invite minh: 200
GET /invite lan: 200
GET /invite hung: 403
GET /invite ngan: 404
GET /invite signed-out: 401
POST /members minh: 201
POST /members lan: 201
POST /members hung: 403
POST /members ngan: 404
POST /members signed-out: 401
PATCH /members/01a1dfe5-b9be-73f0-bd4e-624985179b11 minh: 200
PATCH /members/01a1dfe5-b9be-73f0-bd4e-624985179b11 lan: 200
PATCH /members/01a1dfe5-b9be-73f0-bd4e-624985179b11 hung: 403
PATCH /members/01a1dfe5-b9be-73f0-bd4e-624985179b11 ngan: 404
PATCH /members/01a1dfe5-b9be-73f0-bd4e-624985179b11 signed-out: 401
POST /transactions minh: 201
POST /transactions lan: 201
POST /transactions hung: 403
POST /transactions ngan: 404
POST /transactions signed-out: 401
POST /transactions/preview minh: 200
POST /transactions/preview lan: 200
POST /transactions/preview hung: 403
POST /transactions/preview ngan: 404
POST /transactions/preview signed-out: 401
PATCH /group minh: 200
PATCH /group lan: 403
PATCH /group hung: 403
PATCH /group ngan: 404
PATCH /group signed-out: 401
PATCH /invite minh: 200
PATCH /invite lan: 403
PATCH /invite hung: 403
PATCH /invite ngan: 404
PATCH /invite signed-out: 401
POST /invite/rotate minh: 200
POST /invite/rotate lan: 403
POST /invite/rotate hung: 403
POST /invite/rotate ngan: 404
POST /invite/rotate signed-out: 401
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c minh: 200
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c lan: 403
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c hung: 403
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c ngan: 404
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c signed-out: 401
PUT /me/member minh: 200
PUT /me/member lan: 200
PUT /me/member hung: 200
PUT /me/member ngan: 404
PUT /me/member signed-out: 401
POST /transfer-ownership lan: 403
POST /transfer-ownership hung: 403
POST /transfer-ownership ngan: 404
POST /transfer-ownership signed-out: 401
POST /transfer-ownership minh: 200
DELETE /users/user lan: 403
DELETE /users/user hung: 403
DELETE /users/user ngan: 404
DELETE /users/user signed-out: 401
DELETE /users/user minh: 204
POST /leave minh: 422
POST /leave lan: 204
POST /leave hung: 204
POST /leave ngan: 404
POST /leave signed-out: 401
DELETE /members/member minh: 204
DELETE /members/member lan: 403
DELETE /members/member hung: 403
DELETE /members/member ngan: 404
DELETE /members/member signed-out: 401
GET /users malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /users random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /users/01a1d09a-f3c7-7b00-9650-c1ce81affe8c random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transfer-ownership malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transfer-ownership random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /leave malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /leave random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
```

### Task 1B.8 — Results
pnpm check: passed (158 files; all workspace typechecks Done). Balance checker: `All groups balanced`.
Role change to viewer → 200; viewer transaction write and invite read → 403; transaction read → 200. Owner demotion/leave → 422 OWNER_REQUIRED. Transfer → caller editor, target owner; transfer back → 200. Removed Hùng's read → 404; member rows remained. Lan leave → 204, claimed false; rejoin → 200. New join after defaultRole viewer → viewer. Group-users response ordered owner first and contained no email fields.
Matrix output above records every existing group endpoint. During destructive-row restoration, Lan rejoined with the new viewer default; the first DELETE member row therefore returned 403. Restored Lan to editor and repeated DELETE member → 204. The other rows matched the permission matrix. Malformed/random group IDs on each new route produced identical normalized NOT_FOUND bodies.
Security review: relevant items 1–8 inspected in contracts, queries, services, routes and group-update diff. All new group routes use shared authorization; writes use verified/rate/origin guards. Services recheck actor and target under group lock. Ownership demotion/promotion is atomic and protected by the existing unique owner index; account locks precede the group lock. No emails, secret fields, raw SQL concatenation or dependency changes. Network audit not run.
Decisions: owner/target accounts are locked in sorted order for ownership transfer to coordinate with account deletion and opposing transfers.
Deviations: no separate count SQL was run; the real users responses after each transfer showed exactly one owner, backed by the unique owner constraint.
Not verified: none beyond the count SQL noted above.
Out of scope: none.

Commit 1B.8: `50a7422`.

## Task 1B.9 — Approach
- Use the installed Hono streaming helper, read from its exact source and type declarations.
- Keep a process-local event hub indexed by group, with explicit unsubscribe/removal handling.
- Publish ordinary service writes only after transactions resolve; publish idempotent creates from the transaction wrapper's committed path.
- Send comments every 25 seconds, clear timers/listeners on abort, and serialize stream writes before closing removed connections.
- Exercise direct/proxied delivery, idle comments, removal, failed writes, replay and disconnect cleanup locally.

### Task 1B.9 — Results
pnpm check: passed (160 files; all workspace typechecks Done), after correcting a missing member-edit return during publication refactoring.
Direct port 4000 and proxied port 3000 streams both printed within the two-second exercise window:
```text
: connected

event: changed
data: {"resources":["transactions","balances","activity"]}
```
Create/replay → 201/201, invalid write → 400; each stream contained exactly one changed event. After 62 seconds each contained exactly two `: keep-alive` lines. Outsider events → 404; signed-out → 401. Removing Lan → 204, stream printed `event: removed` / `data: {}` and curl exited 0 before its timeout; reconnect → 404. Opened/closed 50 real curl streams; temporary numeric diagnostic printed 50 cleanup lines, final `SSE remaining listeners 0`. Diagnostic removed from source before final check/commit.
Security review: relevant items 1–8 inspected against actual hub, SSE route, transaction wrapper and publication diff. Group stream uses shared authorization; payloads contain resource names only, no group data or credentials. Removal drops targeted listeners before notifying remaining users. Abort clears timer/subscription; no publication before commit, on failure or on idempotent replay. No dependencies changed; network audit not run.
Decisions: D20; D21 records the preceding task's ownership lock ordering.
Deviations: committed callback in the existing transaction wrapper handles creates; no rewrite/proxy fix needed because the existing Next rewrite streamed promptly.
Not verified: explicit HTTP header capture was not performed; headers were inspected in the route source. Cross-process delivery is outside the specified single-process hub.
Out of scope: none.

Commit 1B.9: `6971ce8`.

## Task 1B.10 — Approach
- Add typed invite/join hooks with one idempotency key per mounted join form.
- Build the specified two-column claim picker, name preselection and server-provided balance wording.
- Render QR modules as React SVG paths, never injected markup; preserve the copy/share and disabled-link states.
- Add owner/editor invitation links and card using existing screen/error/loading components.
- Use the locally cached qrcode package because uqr is unavailable offline; record the dependency deviation and never call a registry.

### Task 1B.10 — Results
pnpm check: passed (165 files; all workspace typechecks Done).
Browser: owner invite card showed the labelled inline SVG, title/hint and copy/share buttons. Copy showed `Đã sao chép link`; the URL read from the real clipboard opened the join flow. Signed out → login preserving join return path; dev-login Lan → Lan preselected, `Lan không nợ ai trong nhóm này.` Selecting Hùng → `Hùng đang cần trả 300.000 đ trong nhóm này. Vào nhóm xong bạn sẽ thấy chi tiết.` Lan claimed her shape and landed on the group. A later Ngân session saw Lan disabled with `đã có người nhận`; new-member input was prefilled Ngân and joining succeeded. Invalid and disabled links both displayed the exact invalid-link title, hint and return control. Stale development module text cleared after restarting Next; no product workaround added.
Completed deferred 1B.3/1B.6 API exercise: disposable verified UI fixture joined (200), was promoted (200), authored an expense (201), deleted its account (204), then /me returned 401. Its member remained active/unclaimed with the same name; its transaction remained amount 1 with createdBy null.
Security review: relevant items 1, 2, 6, 7, 8 inspected against hooks, page, picker, QR, copy/share, localized strings and dependency diff. Zod responses, safe login return, one key per mounted form, no raw SVG/HTML injection, no storage of credentials. QR data comes from the validated server URL. No external service contacted. Offline installation downloaded 0 packages. Audit not run (external services forbidden).
Decisions: D22. qrcode package footprint 232 KiB; declaration package 40 KiB, excluding transitive packages. Bundle delta not yet measured.
Deviations: qrcode replaces unavailable uqr; JoinForm split beside ClaimGrid after the page exceeded 200 lines. Browser exercise used sequential sessions in one browser, not two simultaneous browser profiles.
Not verified: physical phone-camera QR scan, native share sheet delivery, visual comparison against GE6/GE9, and simultaneous-browser join race UI (the API race passed in 1B.7).
Out of scope: none. Two new untracked advisor spec documents were observed and left untouched.

Commit 1B.10: `75de514`.

## Task 1B.11 — Approach
- Mount one validated EventSource subscription per group layout and invalidate the existing query keys.
- Add native dialog and segmented-control primitives, then sharing/ownership and member-user controls.
- Gate every edit surface by verified email and role; retain claim/leave actions for viewers.
- Represent removal as a one-time query-cache notice on the group list and clear cached group data.
- Exercise live role changes, member updates, removal, dialogs and reconnects with local browser/API fixtures.

### Task 1B.11 — Results
pnpm check: passed (174 files; all workspace typechecks Done). Biome required semantic fieldset for the segmented group; used its native group role without suppressions.
Browser + local API actor: viewer Ngân saw `Chỉ xem` with no entry controls; promotion to editor made invitation/entry links appear without reload. New expense 100000 split Minh/Ngân appeared in the stream and changed Ngân's balance block to `Bạn cần trả 50.000 đ`. Demotion removed entry controls live; direct /tx/new displayed `Bạn không có quyền làm việc này.` Removal sent Ngân to / with `Bạn không còn ở trong nhóm này.` Member rename to Hùng nhỏ appeared without reload. Stopped/restarted API; the open group later displayed the changed group title with no alert stuck.
Owner settings displayed default role, link controls and transfer targets. Transfer dialog initially focused cancel; Escape closed it and returned focus to Lan's opener. Native dialog was open with focus inside. Transfer to Lan navigated to members; ownership restored through the API after the exercise. Moved transfer/leave navigation into mutation-level onSuccess before invalidation so navigation survives unmounts caused by live role updates.
Security review: relevant items 1, 2, 6, 7, 8 inspected against all new hooks/components and changed screens. SSE payload length/type/schema validated; source closed on cleanup/removal; group queries cancelled/removed on access loss; no persisted group notice or credentials. Role/verification controls are client presentation backed by existing server guards. Dialog uses native modal behavior; no raw HTML or unchecked redirect. No new dependencies; network audit not run.
Decisions: shared discriminated group-user mutation follows five operations with the same invalidation/permission handling; removal notice lives only in the existing query cache. Same-directory UserControls and LeaveGroupButton keep member page below 200 lines.
Deviations: semantic fieldset provides role=group implicitly. Used a browser observer plus API actor instead of two independent browser profiles.
Not verified: full long-stream scroll preservation (attempted native scroll did not move the intended container); complete Tab-cycle trap (native key exercise was inconclusive); every dialog variant, two-window rename/leave visibility, QR change after rotation, and Wi-Fi toggling. API SSE cleanup/replay/removal/idle delivery passed in 1B.9. Dialog Escape/focus return and transfer navigation were exercised directly.
Out of scope: none.

Commit 1B.11: `5b6aff5`.

## Task 1B.12 — Approach
- Build with outbound networking denied and run pnpm check before the gate commit.
- Reset only the development compose database, migrate and seed, then replay 1B and 1A acceptance requests.
- Record actual responses and the endpoint/caller matrix without storing credentials or mail tokens.
- Run the independent balance checker after all replayed writes.

### Stage 1B gate — acceptance output
```text
dev-login minh [204, null]
dev-login lan [204, null]
dev-login hung [204, null]
dev-login thu [204, null]
register Ngân [204, null]
sign in unverified [204, null]
unverified group write [403, {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1dffc-02c7-7295-aff5-d1e6202a89df"}}]
verify [204, null]
sign in verified [204, null]
create group 201
cable 201
hotpot 201
preview Lan [200, {"group": {"id": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71", "name": "Đà Lạt 12/2026"}, "ownerName": "Minh", "memberCount": 4, "transactionCount": 2, "members": [{"id": "01a1dffc-032b-78e3-a090-954fad1f0c05", "name": "Minh", "shape": "circle", "color": "mint", "claimed": true, "balance": null}, {"id": "01a1dffc-0330-7905-8814-b45ca322e57d", "name": "Lan", "shape": "diamond", "color": "sky", "claimed": false, "balance": 0}, {"id": "01a1dffc-0331-7ad4-8784-c73d9a473b1b", "name": "Hùng", "shape": "squircle", "color": "coral", "claimed": false, "balance": -300000}, {"id": "01a1dffc-0332-700f-bafe-537c723da5ef", "name": "Thu", "shape": "leaf", "color": "lilac", "claimed": false, "balance": -200000}], "alreadyJoined": false}]
Lan joins [200, {"groupId": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71"}]
Ngan joins [200, {"groupId": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71"}]
Hung joins [200, {"groupId": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71"}]
Lan groups [200, {"groups": [{"id": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1dffc-032b-78e3-a090-954fad1f0c05", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1dffc-0330-7905-8814-b45ca322e57d", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1dffc-0331-7ad4-8784-c73d9a473b1b", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1dffc-0332-700f-bafe-537c723da5ef", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 0}]}]
Hung groups [200, {"groups": [{"id": "01a1dffc-0327-7b50-b806-7ab6b8a4ba71", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1dffc-032b-78e3-a090-954fad1f0c05", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1dffc-0330-7905-8814-b45ca322e57d", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1dffc-0331-7ad4-8784-c73d9a473b1b", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1dffc-0332-700f-bafe-537c723da5ef", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": -300000}]}]
Ngân viewer 200
viewer create [403, {"error": {"code": "FORBIDDEN", "message": "Insufficient group role", "requestId": "01a1dffc-03f5-753e-902f-ec9a456e8558"}}]
viewer read 200
coffee 201
SSE within 2s ": connected\n\nevent: changed\ndata: {\"resources\":[\"transactions\",\"balances\",\"activity\"]}\n\n"
remove Hung [204, null]
removed read [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1dffc-0660-789e-addb-cca0aa75801c"}}]
preserved balances [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1dffc-032b-78e3-a090-954fad1f0c05", "balance": 566666}, {"memberId": "01a1dffc-0330-7905-8814-b45ca322e57d", "balance": -33333}, {"memberId": "01a1dffc-0331-7ad4-8784-c73d9a473b1b", "balance": -333333}, {"memberId": "01a1dffc-0332-700f-bafe-537c723da5ef", "balance": -200000}, {"memberId": "01a1dffc-03ad-78c4-8ec1-8febe4dd7b2c", "balance": 0}], "transfers": [{"fromMemberId": "01a1dffc-0331-7ad4-8784-c73d9a473b1b", "toMemberId": "01a1dffc-032b-78e3-a090-954fad1f0c05", "amount": 333333}, {"fromMemberId": "01a1dffc-0332-700f-bafe-537c723da5ef", "toMemberId": "01a1dffc-032b-78e3-a090-954fad1f0c05", "amount": 200000}, {"fromMemberId": "01a1dffc-0330-7905-8814-b45ca322e57d", "toMemberId": "01a1dffc-032b-78e3-a090-954fad1f0c05", "amount": 33333}]}]
rotate 200
old token [404, {"error": {"code": "INVITE_INVALID", "message": "Invite is invalid", "requestId": "01a1dffc-0693-746b-8b80-ba9fda3bc860"}}]
forgot [204, null]
reset [204, null]
old session 1 401
old session 2 401
login new [204, null]
register existing [204, null]
register new [204, null]
forgot known [204, null]
forgot unknown [204, null]
1A Vé cáp treo 201
1A Lẩu 201
1A Cà phê 201
1A minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "balance": 566666}, {"memberId": "01a1dffc-077a-7945-aaa0-205d934da197", "balance": -33333}, {"memberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "balance": -333333}, {"memberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "balance": -200000}], "transfers": [{"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 333333}, {"fromMemberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 200000}, {"fromMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 33333}]}]
1A pairwise setting 200
1A pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "balance": 566666}, {"memberId": "01a1dffc-077a-7945-aaa0-205d934da197", "balance": -33333}, {"memberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "balance": -333333}, {"memberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "balance": -200000}], "transfers": [{"fromMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 133333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 233333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "amount": 100000}, {"fromMemberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 200000}]}]
1A deactivate Thu 200
1A Taxi shares [201, [{"memberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 30000}, {"memberId": "01a1dffc-077a-7945-aaa0-205d934da197", "amount": 30000}, {"memberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "amount": 30000}]]
1A inactive balance [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "balance": 626666}, {"memberId": "01a1dffc-077a-7945-aaa0-205d934da197", "balance": -63333}, {"memberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "balance": -363333}, {"memberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "balance": -200000}], "transfers": [{"fromMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 163333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 263333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "amount": 100000}, {"fromMemberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 200000}]}]
```

### Stage 1B gate — permission matrix
```text
GET /group minh: 200
GET /group lan: 200
GET /group ngan: 200
GET /group hung: 404
GET /group signed-out: 401
GET /group malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /group random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /members minh: 200
GET /members lan: 200
GET /members ngan: 200
GET /members hung: 404
GET /members signed-out: 401
GET /members malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /members random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /users minh: 200
GET /users lan: 200
GET /users ngan: 200
GET /users hung: 404
GET /users signed-out: 401
GET /users malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /users random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /transactions minh: 200
GET /transactions lan: 200
GET /transactions ngan: 200
GET /transactions hung: 404
GET /transactions signed-out: 401
GET /transactions malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /transactions random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /balances minh: 200
GET /balances lan: 200
GET /balances ngan: 200
GET /balances hung: 404
GET /balances signed-out: 401
GET /balances malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /balances random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /events minh: 200
GET /events lan: 200
GET /events ngan: 200
GET /events hung: 404
GET /events signed-out: 401
GET /events malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /events random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /invite minh: 200
GET /invite lan: 200
GET /invite ngan: 403
GET /invite hung: 404
GET /invite signed-out: 401
GET /invite malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
GET /invite random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /members minh: 201
POST /members lan: 201
POST /members ngan: 403
POST /members hung: 404
POST /members signed-out: 401
POST /members malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /members random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 minh: 200
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 lan: 200
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 ngan: 403
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 hung: 404
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 signed-out: 401
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transactions minh: 201
POST /transactions lan: 201
POST /transactions ngan: 403
POST /transactions hung: 404
POST /transactions signed-out: 401
POST /transactions malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transactions random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transactions/preview minh: 200
POST /transactions/preview lan: 200
POST /transactions/preview ngan: 403
POST /transactions/preview hung: 404
POST /transactions/preview signed-out: 401
POST /transactions/preview malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transactions/preview random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /group minh: 200
PATCH /group lan: 403
PATCH /group ngan: 403
PATCH /group hung: 404
PATCH /group signed-out: 401
PATCH /group malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /group random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /invite minh: 200
PATCH /invite lan: 403
PATCH /invite ngan: 403
PATCH /invite hung: 404
PATCH /invite signed-out: 401
PATCH /invite malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /invite random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /invite/rotate minh: 200
POST /invite/rotate lan: 403
POST /invite/rotate ngan: 403
POST /invite/rotate hung: 404
POST /invite/rotate signed-out: 401
POST /invite/rotate malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /invite/rotate random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e minh: 200
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e lan: 403
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e ngan: 403
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e hung: 404
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e signed-out: 401
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PATCH /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PUT /me/member minh: 200
PUT /me/member lan: 200
PUT /me/member ngan: 200
PUT /me/member hung: 404
PUT /me/member signed-out: 401
POST /transfer-ownership lan: 403
POST /transfer-ownership ngan: 403
POST /transfer-ownership hung: 404
POST /transfer-ownership signed-out: 401
POST /transfer-ownership minh: 200
DELETE /users/user lan: 403
DELETE /users/user ngan: 403
DELETE /users/user hung: 404
DELETE /users/user signed-out: 401
DELETE /users/user minh: 204
POST /leave minh: 422
POST /leave lan: 204
POST /leave ngan: 204
POST /leave hung: 404
POST /leave signed-out: 401
DELETE /members/member minh: 204
DELETE /members/member lan: 204
DELETE /members/member ngan: 403
DELETE /members/member hung: 404
DELETE /members/member signed-out: 401
PUT /me/member malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
PUT /me/member random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transfer-ownership malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /transfer-ownership random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /users/01a1dff9-e1c4-7545-9879-42a58cb63f2e random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /leave malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
POST /leave random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 malformed: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
DELETE /members/01a1dffc-e198-740b-9ec9-8e09c41038e1 random: 404 {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}
```

### Task 1B.12 — Gate result
Gate passed after one build fix.
- pnpm check: passed (175 files; all workspace typechecks Done).
- pnpm build with outbound network denied: first failed fetching Be Vietnam Pro from fonts.googleapis.com. D23 replaces the remote build dependency with unchanged cached source WOFF2 assets and the local existing OFL license. Second build: compiled successfully, TypeScript finished, 11/11 static pages generated, all routes listed.
- Reset: docker compose down -v; up --pull never -d --wait db; migrate → `Migrations applied`; seed → `Development users seeded`.
- 1B acceptance: all real outputs above. Verified-email write guard 403 before verification; joins and balances correct; viewer write 403/read 200; SSE line in less than two seconds; removal preserves balances; rotated token invalid; password reset revokes both old sessions; known/new registration and known/unknown forgot responses each identical empty 204.
- Replayed 1A acceptance on a separate fresh group: exact balances 566666/-33333/-333333/-200000, minimized transfers 333333/200000/33333; pairwise transfers 133333/233333/100000/200000. Taxi shares 30000 each; inactive Thu remains -200000.
- Full existing endpoint matrix recorded above: owner/editor/viewer/outsider/signed-out outcomes match; malformed/random group IDs share the normalized NOT_FOUND body for every route.
- pnpm db:check-balances: both groups sum 0/mismatches 0; `All groups balanced`.
- Production web local font URL → `200 font/woff2 4720`; missing font → 404. Source font assets plus license use 200 KiB. Security review relevant items 1, 6, 7, 8: static licensed files, no external font URL, no credential/configuration/dependency change; no generated build folders committed.
Decisions: D23. Not verified: visual font comparison, precise QR bundle delta, real Google roundtrip and the browser/device checks already listed under the preceding tasks. No gate item remains failed. No external registry, font service, Google service, deployment or push performed.

Commit 1B.12: `be8919c`.

## Task 1C.1 — Approach
- Centralize integer money division in allocateByWeights with BigInt quotient/remainder ranking.
- Parse decimal weights into hundredths without floating point and validate structural split errors explicitly.
- Keep splitEqually as the same public helper over equal weights; computeShares orders every result by member position.
- Attribute each share using remaining payer capacities so both row and column totals stay exact.
- Print every specified table row through a temporary local invocation; commit no test or assertion script.

### Task 1C.1 — Exercise output
```text
allocate 100000 [ 1, 1, 1 ] [ 33334, 33333, 33333 ]
allocate 300000 [ 2, 1 ] [ 200000, 100000 ]
allocate 100 [ 1, 2 ] [ 33, 67 ]
allocate 100 [ 150, 100, 100 ] [ 43, 29, 28 ]
allocate 99999 [ 5000, 3000, 2000 ] [ 49999, 30000, 20000 ]
allocate 0 [ 1, 1 ] [ 0, 0 ]
allocate 5 [ 0, 1 ] [ 0, 5 ]
allocate 5 [ 0, 0 ] RangeError
exact 300000 [ 120000, 100000, 80000 ] none {
  ok: true,
  shares: [
    { memberId: 'a', amount: 120000 },
    { memberId: 'b', amount: 100000 },
    { memberId: 'c', amount: 80000 }
  ]
}
exact 300000 [ 150000, 140000 ] none {
  ok: false,
  code: 'SPLIT_TOTAL_MISMATCH',
  expected: 300000,
  actual: 290000
}
exact 300000 [ 150000 ] equal_among_blank {
  ok: true,
  shares: [
    { memberId: 'a', amount: 150000 },
    { memberId: 'b', amount: 75000 },
    { memberId: 'c', amount: 75000 }
  ]
}
exact 100000 [ 50000 ] equal_among_blank {
  ok: true,
  shares: [
    { memberId: 'a', amount: 50000 },
    { memberId: 'b', amount: 16667 },
    { memberId: 'c', amount: 16667 },
    { memberId: 'd', amount: 16666 }
  ]
}
exact 100000 [ 60000, 40000 ] equal_among_blank {
  ok: true,
  shares: [
    { memberId: 'a', amount: 60000 },
    { memberId: 'b', amount: 40000 }
  ]
}
exact 100000 [ 60000, 50000 ] equal_among_blank {
  ok: false,
  code: 'SPLIT_TOTAL_MISMATCH',
  expected: 100000,
  actual: 110000
}
exact 300000 [ 80000, 60000, 40000 ] equal_among_all {
  ok: true,
  shares: [
    { memberId: 'a', amount: 120000 },
    { memberId: 'b', amount: 100000 },
    { memberId: 'c', amount: 80000 }
  ]
}
exact 100000 [ 10000, 10000, 10000 ] equal_among_all {
  ok: true,
  shares: [
    { memberId: 'a', amount: 33334 },
    { memberId: 'b', amount: 33333 },
    { memberId: 'c', amount: 33333 }
  ]
}
exact 100000 [ 60000, 50000 ] equal_among_all {
  ok: false,
  code: 'SPLIT_TOTAL_MISMATCH',
  expected: 100000,
  actual: 110000
}
shares 100 [ '1.5', '1', '1' ] {
  ok: true,
  shares: [
    { memberId: 'a', amount: 43 },
    { memberId: 'b', amount: 29 },
    { memberId: 'c', amount: 28 }
  ]
}
shares 1200000 [ '2', '1', '1', '1' ] {
  ok: true,
  shares: [
    { memberId: 'a', amount: 480000 },
    { memberId: 'b', amount: 240000 },
    { memberId: 'c', amount: 240000 },
    { memberId: 'd', amount: 240000 }
  ]
}
shares 1000 [ '0', '1' ] {
  ok: true,
  shares: [ { memberId: 'a', amount: 0 }, { memberId: 'b', amount: 1000 } ]
}
shares 1000 [ '0', '0' ] { ok: false, code: 'SPLIT_TOTAL_MISMATCH', expected: 1000, actual: 0 }
percent 99999 [ '50', '30', '20' ] {
  ok: true,
  shares: [
    { memberId: 'a', amount: 49999 },
    { memberId: 'b', amount: 30000 },
    { memberId: 'c', amount: 20000 }
  ]
}
percent 100000 [ '33.33', '33.33', '33.34' ] {
  ok: true,
  shares: [
    { memberId: 'a', amount: 33330 },
    { memberId: 'b', amount: 33330 },
    { memberId: 'c', amount: 33340 }
  ]
}
percent 100000 [ '50', '49.99' ] { ok: false, code: 'SPLIT_TOTAL_MISMATCH', expected: 100, actual: 99 }
attribution expense [
  { debtorMemberId: 'a', creditorMemberId: 'a', amount: 66667 },
  { debtorMemberId: 'a', creditorMemberId: 'b', amount: 33333 },
  { debtorMemberId: 'b', creditorMemberId: 'a', amount: 66667 },
  { debtorMemberId: 'b', creditorMemberId: 'b', amount: 33333 },
  { debtorMemberId: 'c', creditorMemberId: 'a', amount: 66666 },
  { debtorMemberId: 'c', creditorMemberId: 'b', amount: 33334 }
] [
  { fromMemberId: 'b', toMemberId: 'a', amount: 33334 },
  { fromMemberId: 'c', toMemberId: 'a', amount: 66666 },
  { fromMemberId: 'c', toMemberId: 'b', amount: 33334 }
]
attribution transfer [ { debtorMemberId: 'a', creditorMemberId: 'c', amount: 50000 } ] [ { fromMemberId: 'a', toMemberId: 'c', amount: 50000 } ]
attribution income [
  { debtorMemberId: 'b', creditorMemberId: 'a', amount: 50000 },
  { debtorMemberId: 'b', creditorMemberId: 'b', amount: 50000 },
  { debtorMemberId: 'b', creditorMemberId: 'c', amount: 50000 },
  { debtorMemberId: 'b', creditorMemberId: 'd', amount: 50000 }
] [
  { fromMemberId: 'b', toMemberId: 'a', amount: 50000 },
  { fromMemberId: 'b', toMemberId: 'c', amount: 50000 },
  { fromMemberId: 'b', toMemberId: 'd', amount: 50000 }
]
decimal -1 RangeError
decimal 1.234 RangeError
decimal  RangeError
outside entry RangeError
duplicate member RangeError
```

### Task 1C.1 — Results
pnpm check: passed (178 files; all workspace typechecks Done). All eight allocation rows, sixteen split rows and three attribution rows printed the exact fixed outputs above. Invalid decimal syntax, outside entries and duplicate members threw RangeError. No assertion script or tests committed.
Security review: relevant items 1, 2, 8 inspected against the complete pure-core diff: no I/O, dependencies, secrets or external inputs bypassing validation. BigInt products/division/remainders appear only in allocateByWeights; decimal hundredths remain integers. Exact allocations keep position order; zero shares are retained. Attribution conserves remaining payer capacity and skips zero rows.
Decisions: none. Deviations: none. The exact-case function is slightly above 40 lines because validation and the three remainder branches form one bounded operation; file remains below 200 lines.
Not verified: exhaustive arbitrary-input exploration; no automated tests by project rule.
Out of scope: none.

Commit 1C.1: `3a5235c`.

## Task 1C.2 — Approach
- Replace the equal-only contract with validated split/type unions and a normalized ledger DTO.
- Normalize transfers once, validate group membership before payer totals and core splits, and retain the submitted split input.
- Replace the single-payer SQL debt attribution with two scoped ledger-side queries and core attribution.
- Update affected callers in place and exercise all fixed T1–T5 amounts plus malformed boundaries.

### Task 1C.2 — Exercise output
```text
T1 [201, [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 120000}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 100000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "amount": 80000}]]
T2 [201, [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 480000}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 240000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "amount": 240000}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 240000}]]
T3 [201, [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 50000}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 50000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "amount": 50000}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 50000}]]
T4 [201, [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 49999}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 30000}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 20000}]]
T1–T4 minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "balance": 500001}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "balance": -120000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "balance": -170001}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "balance": -210000}], "transfers": [{"fromMemberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 210000}, {"fromMemberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 170001}, {"fromMemberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 120000}]}]
T5 [201, {"transaction": {"type": "transfer", "description": "Chuyển khoản", "amount": 210000, "occurredAt": "2026-11-15T00:00:00.000Z", "category": null, "payers": [{"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 210000}], "split": {"method": "exact", "members": ["01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0"], "entries": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 210000}], "remainder": "none"}, "id": "01a1e002-c65b-7a37-8515-2dd12daa0bf0", "currency": "VND", "shares": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 210000}], "version": 1, "createdBy": {"id": "01a1dff9-e1bf-766e-87e7-0f6c18f4a631", "name": "Minh"}, "createdAt": "2026-11-15T16:20:40.664Z", "updatedAt": "2026-11-15T16:20:40.664Z", "deletedAt": null}}]
after T5 [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "balance": 290001}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "balance": -120000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "balance": -170001}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "balance": 0}], "transfers": [{"fromMemberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 170001}, {"fromMemberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 120000}]}]
pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "balance": 290001}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "balance": -120000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "balance": -170001}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "balance": 0}], "transfers": [{"fromMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "toMemberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 50000}, {"fromMemberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 150000}, {"fromMemberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "toMemberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 190001}, {"fromMemberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "toMemberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 30000}, {"fromMemberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "toMemberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "amount": 20000}]}]
pairwise received minus paid {"Minh": 290001, "Lan": -120000, "Hùng": -170001, "Thu": 0}
exact over [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 300000, "actual": 320000}, "requestId": "01a1e002-c68e-7d54-a1cd-6eb0258dd805"}}]
payer mismatch [400, {"error": {"code": "PAYER_TOTAL_MISMATCH", "message": "Payer total differs from amount", "details": {"expected": 1200000, "actual": 1100000}, "requestId": "01a1e002-c69c-7720-9d51-997a03769c8b"}}]
percent mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 100, "actual": 99}, "requestId": "01a1e002-c6a9-74b2-9b7c-843df7ad5a10"}}]
self transfer [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1e002-c6b5-7598-86c4-987cb8ce8bb7"}}]
weight precision [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.weight": ["Invalid string: must match pattern /^\\d{1,4}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e002-c6bf-7d32-b2fd-60f3cc432253"}}]
negative percent [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.percent": ["Invalid string: must match pattern /^\\d{1,3}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e002-c6c8-760a-8563-3b13b7e68c61"}}]
outside exact entry [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split": ["Invalid input"]}, "requestId": "01a1e002-c6d2-76a7-b526-0acec321c623"}}]
T2 preview [200, {"shares": [{"memberId": "01a1e002-c5bb-7c9e-8ee2-fa7bc61961c0", "amount": 480000}, {"memberId": "01a1e002-c5be-741a-ae6f-6b057bb655b6", "amount": 240000}, {"memberId": "01a1e002-c5c0-7392-9184-2d2c68c0e2fe", "amount": 240000}, {"memberId": "01a1e002-c5c2-7a73-8c2c-ee20e23bf069", "amount": 240000}]}]
stored transaction count 5
membership first [400, {"error": {"code": "MEMBER_NOT_IN_GROUP", "message": "Member does not belong to group", "requestId": "01a1e002-c6fc-7c82-b045-919ca33b26a4"}}]
existing 1A balances [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "balance": 626666}, {"memberId": "01a1dffc-077a-7945-aaa0-205d934da197", "balance": -63333}, {"memberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "balance": -363333}, {"memberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "balance": -200000}], "transfers": [{"fromMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 163333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 263333}, {"fromMemberId": "01a1dffc-077b-7c9e-93e7-444a53c5c173", "toMemberId": "01a1dffc-077a-7945-aaa0-205d934da197", "amount": 100000}, {"fromMemberId": "01a1dffc-077d-7597-95ca-4677ef5ec1e5", "toMemberId": "01a1dffc-0778-7f94-827b-639f64427c4e", "amount": 200000}]}]
```

### Task 1C.2 — Results
pnpm check: passed (179 files; all workspace typechecks Done). All fixed T1–T5 outputs recorded above. T1 shares 120000/100000/80000; T2 480000/240000/240000/240000; T3 50000 each; T4 49999/30000/20000. Minimized balances 500001/-120000/-170001/-210000. T5 default description exactly Chuyển khoản; sender payer/receiver share exact input; balances 290001/-120000/-170001/0. Pairwise net for each member matched those four balances. Invalid totals/precision/negative percentage/outside exact entry/self transfer returned the specified 400 codes. Membership validation ran before payer mismatch. Preview returned T2 shares; stored count remained five. Earlier 1A retained balances/transfers unchanged. Balance checker: `All groups balanced`.
Security review: relevant items 1–8 inspected against full schema, normalization, service, query and caller diff. Bound/unique member lists and split entries, strict decimal regexes, group membership before arithmetic, parameterized scoped reads, atomic payer/share inserts and deferred constraints, no client official amounts trusted. Existing authorization/idempotency/origin/rate guards remain. No dependency changes; network audit not run.
Decisions: D24 preserves the exact transfer default in the single authorized message source. Normalization/calculation moved to a same-directory service file to keep transactions.ts below 200 lines.
Deviations: narrow import of the pure vi.ts object by API normalization, as documented in D24. Preview explicitly accepts only expense/income per plan.
Not verified: separate income-only fresh-group manual example (T3's sign was exercised in the combined fixed ledger).
Out of scope: none.

Commit 1C.2: `fe78116`.

## Task 1C.3 — Approach
- Extend the current form controller with a transaction type and explicit multi-payer/transfer fields.
- Keep amount, description and date in one state across type switches; validate each request with the contract.
- Reuse the member grid with disabled receiver support and show integer payer-total status.
- Move the form header into the form so its title and trailing type switch share the same controller.
- Preview only expense/income requests; transfer requests normalize on the API as already verified.

### Task 1C.3 — Results
pnpm check: passed (182 files; all workspace typechecks Done).
Browser: 1200000 with payers Minh 800000/Lan 300000 showed `Còn dư 100.000 đ`, save disabled. Changed Lan to 400000, saved; API read showed both payer amounts and four equal 300000 shares. Found/fixed match-line bug (showed zero instead of total); repeated browser exercise showed exactly `Khớp 1.200.000 đ`.
Switched income/transfer/expense while keeping 200000, Hoàn cọc and date value. Saved income received by Lan → API read type income, amount 200000, Lan payer and four 50000 shares. Saved transfer Thu→Minh 210000 with empty note → API read type transfer/default Chuyển khoản, one sender payer and one receiver share 210000. Transfer receiver grid disabled the selected sender. Missing receiver disabled saving.
Security review: relevant items 1, 2, 6, 7, 8 checked against form/controller, grids, fields, type switch and caller diff. Contract validates final payload; payer-total status uses integer sums only; official per-person amounts remain API previews; transfer side cannot equal itself; same-origin/idempotent mutation unchanged; no dependency changes. No external calls/audit.
Decisions: D25. Header lives with form state; type buttons use the mandatory 44px hit area although the mockup specifies 40px.
Deviations: exact weighted T2 UI exercise carried into 1C.4 (split editor not yet introduced); hotel saved here uses equal split. Controller exceeds 40 lines because it keeps one coherent form state; files remain below 200 lines.
Not verified: GE19 visual comparison; date preservation was observed in native displayed value without changing its default date.
Out of scope: none.

Commit 1C.3: `d5c1d25`.

## Task 1C.4 — Approach
- Keep split participants/mode/typed values in a focused controller used by both form and overlay.
- Build exact remainder and percent-status feedback from integer totals; official shares still come only from preview.
- Add the four specified split components and a full-height panel that preserves state on close.
- Disable preview/save for invalid totals, and render validated API mismatch details as the specified status copy.
- Exercise exact/private-plus-common, blank remainder, overage, weights, percentages and the deferred T2 UI case.

### Task 1C.4 — Results
pnpm check: passed (188 files; all workspace typechecks Done). Balance checker: four groups sum 0/mismatches 0; `All groups balanced`.
Browser exact 300000 with 80000/60000/40000 → `Còn dư 120.000 đ · chưa lưu được`; spread → previews 120000/100000/80000 and match copy. Saved API read retained equal_among_all and original entries. Blank case 150000/empty/empty → exact blank copy, preview 150000/75000/75000; saved equal_among_blank. Total 320000 → `Vượt 20.000 đ · chưa lưu được`; closed panel and save was disabled; reopened and 200000 field persisted.
Shares mode 100 with 1,5/1/1 → API preview 43/29/28. Rendered geometry widths 76/69/69px, with initials visible. Added/removed Thu and switched modes. Percent 50/30/19 → `Còn thiếu 1% · chưa lưu được`; 99999 with 50/30/20 → 49999/30000/20000 and Khớp 100%, saved with percent input intact. Deferred full T2 UI exercise completed: payers 800000/400000; weights 2/1/1/1; preview and stored shares 480000/240000/240000/240000.
Security review: relevant items 1, 2, 6, 7, 8 inspected across all new/changed form/controller/component diff. Bounded contract input, integer total/percentage feedback, no official share calculation in web, invalid requests never preview/save, validated mismatch details. Pixel geometry uses an integer ratio solely for 56–104px rendering; no financial value is divided/rounded outside core. No storage/raw HTML/dependencies/external calls.
Decisions: same-directory ParticipantFields and use-split-state split keep ExpenseForm below 200 lines; aria labels use localized wording. Pixel size is integer geometry derived from the server preview, distinct from money allocation.
Deviations: none in behavior; focused form/split controller functions exceed 40 lines because they own the single coherent state. No extra state framework introduced.
Not verified: complete keyboard-only traversal and visual comparison with GE4/GE16; field labels and button semantics were inspected/exercised through the browser. Debounced preview can briefly retain the prior valid preview until the new response arrives, as with the existing preview hook.
Out of scope: none.

Commit 1C.4: `ea0c74e`.

## Task 1C.5 — Approach
- Link settlement suggestions to a validated recording form with one idempotency key per mount.
- Separate the viewer's outgoing transfers from other suggestions and hide recording controls for viewers/unverified accounts.
- Render income/transfer ledger pills from normalized server transactions.
- Add the recent-transfer card to the settled state using existing paginated transaction data.
- Exercise full/partial recording, duplicate submission and invalid query fallback against the fixed ledger.

### Task 1C.5 — Results
pnpm check: passed (193 files; all workspace typechecks Done). Balance checker: five groups sum 0/mismatches 0; `All groups balanced`.
Fresh fixed T1–T4 fixture had 500001/-120000/-170001/-210000. Browser Minh: Thu's Đã nhận opened a 210000 form with the correct whole-debt status. Double-click Ghi nhận → one 210000 transfer, Thu suggestion disappeared and Minh balance became 290001. Stream displayed exactly `Thu đã chuyển cho bạn 210.000 đ`. Made-up sender/receiver UUIDs redirected to balances.
Browser Lan: `Bạn chuyển 1 lần là xong`, own card `Bạn trả Minh 120.000`; recorded 100000 → `Bạn trả Minh 20.000`, balance -20000. Empty amount disabled Ghi nhận. Recorded remaining 20000 and Hùng 170001 → all four balances 0, transfers empty, `Cả nhóm đã xong.` and four recorded lines. API read showed exactly four transfers: 170001, 20000, 100000, 210000 (one after double click).
Security review: relevant items 1, 2, 6, 7, 8 inspected across page, form, cards, pills, query helper and message diff. Query ids/amount validated with Zod and actual group members; viewer form denied, write controls require verified editor role; one mount key plus synchronous submit guard; API remains authoritative. No calculated official shares, unsafe redirect/markup/storage, dependencies or external calls.
Decisions: settled history loads existing transaction pages until exhausted to count transfers accurately while rendering only five most recent; SettlementForm split in the existing balances directory. Balances page is 202 lines because loading/access/error/render branches remain explicit; no separate screen-state abstraction introduced.
Deviations: none in behavior.
Not verified: GE5/GE13/GE12/GE18 visual comparisons; alternate date selection, very long paginated settlement history and viewer UI for this screen were not exercised (server permission matrix already covers transfers).
Out of scope: none.

Commit 1C.5: `754a361`.

## Task 1C.6 — Approach
- Build with outbound networking denied and reset the local compose database.
- Replay C's fixed ledger/refusals, then B's account/sharing acceptance and A's original ledger acceptance using curl.
- Record each endpoint/caller permission outcome and normalized unknown-group errors.
- Run pnpm check and the independent balance checker before the gate commit.

### Stage 1C gate — actual acceptance and permission output
```text
dev login minh [204, null]
dev login lan [204, null]
dev login hung [204, null]
dev login thu [204, null]
create group 201
1C T1 [201, [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 120000}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 100000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "amount": 80000}]]
1C T2 [201, [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 480000}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 240000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "amount": 240000}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "amount": 240000}]]
1C T3 [201, [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 50000}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 50000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "amount": 50000}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "amount": 50000}]]
1C T4 [201, [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 49999}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 30000}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "amount": 20000}]]
1C minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "balance": 500001}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "balance": -120000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "balance": -170001}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "balance": -210000}], "transfers": [{"fromMemberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 210000}, {"fromMemberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 170001}, {"fromMemberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 120000}]}]
1C T5 201
1C after T5 [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "balance": 290001}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "balance": -120000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "balance": -170001}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "balance": 0}], "transfers": [{"fromMemberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 170001}, {"fromMemberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 120000}]}]
1C pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "balance": 290001}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "balance": -120000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "balance": -170001}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "balance": 0}], "transfers": [{"fromMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "toMemberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "amount": 50000}, {"fromMemberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 150000}, {"fromMemberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "toMemberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 190001}, {"fromMemberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "toMemberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 30000}, {"fromMemberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "toMemberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "amount": 20000}]}]
1C received minus paid {"Minh": 290001, "Lan": -120000, "Hùng": -170001, "Thu": 0}
1C exact mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 300000, "actual": 320000}, "requestId": "01a1e016-5ce9-7376-a874-d2ee3f031b7d"}}]
1C payer mismatch [400, {"error": {"code": "PAYER_TOTAL_MISMATCH", "message": "Payer total differs from amount", "details": {"expected": 1200000, "actual": 1100000}, "requestId": "01a1e016-5cf7-7ba3-ab8f-f45854b18c49"}}]
1C percent mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 100, "actual": 99}, "requestId": "01a1e016-5d04-7899-9972-4acd4f171c1b"}}]
1C self transfer [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1e016-5d10-7cfe-b91c-88ca566fad3d"}}]
1C weight precision [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.weight": ["Invalid string: must match pattern /^\\d{1,4}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e016-5d1a-7018-a923-a948506f79cb"}}]
1C negative percent [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.percent": ["Invalid string: must match pattern /^\\d{1,3}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e016-5d24-7858-b337-79cb3e1affac"}}]
1C outside entry [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split": ["Invalid input"]}, "requestId": "01a1e016-5d2f-7b3b-9e66-31ca30c4516d"}}]
1C preview [200, {"shares": [{"memberId": "01a1e016-5c2b-7877-a3be-8d722707478f", "amount": 480000}, {"memberId": "01a1e016-5c2e-7bc8-89cf-f8317f59f5ee", "amount": 240000}, {"memberId": "01a1e016-5c2f-709b-8527-3c9931673dba", "amount": 240000}, {"memberId": "01a1e016-5c30-70ca-bcff-c3eb12d5166d", "amount": 240000}]}]
1C stored count 5
1B register [204, null]
1B unverified write [403, {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1e016-5d84-7734-a17d-03a07dfab7e1"}}]
1B verify [204, null]
create group 201
1B preview [200, {"group": {"id": "01a1e016-5dce-7d3a-8586-101f1e28d539", "name": "Đà Lạt 12/2026"}, "ownerName": "Minh", "memberCount": 4, "transactionCount": 2, "members": [{"id": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "name": "Minh", "shape": "circle", "color": "mint", "claimed": true, "balance": null}, {"id": "01a1e016-5dd0-7d9e-9c41-1ede83b9705f", "name": "Lan", "shape": "diamond", "color": "sky", "claimed": false, "balance": 0}, {"id": "01a1e016-5dd0-7d9e-9c41-1edfdc0b9335", "name": "Hùng", "shape": "squircle", "color": "coral", "claimed": false, "balance": -300000}, {"id": "01a1e016-5dd1-722a-97b3-032755a5ea38", "name": "Thu", "shape": "leaf", "color": "lilac", "claimed": false, "balance": -200000}], "alreadyJoined": false}]
1B Lan join [200, {"groupId": "01a1e016-5dce-7d3a-8586-101f1e28d539"}]
1B Ngân join [200, {"groupId": "01a1e016-5dce-7d3a-8586-101f1e28d539"}]
1B Hùng join [200, {"groupId": "01a1e016-5dce-7d3a-8586-101f1e28d539"}]
1B Lan list [200, {"groups": [{"id": "01a1e016-5dce-7d3a-8586-101f1e28d539", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e016-5dd0-7d9e-9c41-1ede83b9705f", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e016-5dd0-7d9e-9c41-1edfdc0b9335", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e016-5dd1-722a-97b3-032755a5ea38", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 0}]}]
1B Hùng list [200, {"groups": [{"id": "01a1e016-5dce-7d3a-8586-101f1e28d539", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e016-5dd0-7d9e-9c41-1ede83b9705f", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e016-5dd0-7d9e-9c41-1edfdc0b9335", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e016-5dd1-722a-97b3-032755a5ea38", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": -300000}]}]
1B viewer write [403, {"error": {"code": "FORBIDDEN", "message": "Insufficient group role", "requestId": "01a1e016-5e87-717e-811d-d3138f7184c5"}}]
1B viewer read 200
1B SSE within 2s ": connected\n\nevent: changed\ndata: {\"resources\":[\"transactions\",\"balances\",\"activity\"]}\n\n"
1B remove Hùng [204, null]
1B removed read [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1e016-60fa-79ab-8e16-bc8473e37395"}}]
1B preserved balance [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "balance": 566666}, {"memberId": "01a1e016-5dd0-7d9e-9c41-1ede83b9705f", "balance": -33333}, {"memberId": "01a1e016-5dd0-7d9e-9c41-1edfdc0b9335", "balance": -333333}, {"memberId": "01a1e016-5dd1-722a-97b3-032755a5ea38", "balance": -200000}, {"memberId": "01a1e016-5e3a-7dd7-a959-b179e71099a4", "balance": 0}], "transfers": [{"fromMemberId": "01a1e016-5dd0-7d9e-9c41-1edfdc0b9335", "toMemberId": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "amount": 333333}, {"fromMemberId": "01a1e016-5dd1-722a-97b3-032755a5ea38", "toMemberId": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "amount": 200000}, {"fromMemberId": "01a1e016-5dd0-7d9e-9c41-1ede83b9705f", "toMemberId": "01a1e016-5dcf-75c8-b8f5-d38190106cae", "amount": 33333}]}]
1B old invite [404, {"error": {"code": "INVITE_INVALID", "message": "Invite is invalid", "requestId": "01a1e016-612b-7d0b-a645-1334629fdd83"}}]
1B forgot [204, null]
1B reset [204, null]
1B sessions after reset [401, 401]
1B existing register [204, null]
1B new register [204, null]
1B known forgot [204, null]
1B unknown forgot [204, null]
create group 201
1A Vé cáp treo 201
1A Lẩu 201
1A Cà phê 201
1A minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e016-61e5-78b5-b48f-903079559391", "balance": 566666}, {"memberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "balance": -33333}, {"memberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "balance": -333333}, {"memberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 333333}, {"fromMemberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 200000}, {"fromMemberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 33333}]}]
1A pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e016-61e5-78b5-b48f-903079559391", "balance": 566666}, {"memberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "balance": -33333}, {"memberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "balance": -333333}, {"memberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 133333}, {"fromMemberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 233333}, {"fromMemberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "toMemberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "amount": 100000}, {"fromMemberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 200000}]}]
1A taxi [201, [{"memberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 30000}, {"memberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "amount": 30000}, {"memberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "amount": 30000}]]
1A inactive balance [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e016-61e5-78b5-b48f-903079559391", "balance": 626666}, {"memberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "balance": -63333}, {"memberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "balance": -363333}, {"memberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 163333}, {"fromMemberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 263333}, {"fromMemberId": "01a1e016-61e6-7de4-a406-c0c4c3c11e30", "toMemberId": "01a1e016-61e6-7de4-a406-c0c34dcfaf2d", "amount": 100000}, {"fromMemberId": "01a1e016-61e7-711e-88f9-3786a54d8e92", "toMemberId": "01a1e016-61e5-78b5-b48f-903079559391", "amount": 200000}]}]
matrix GET /group minh 200
matrix GET /group lan 200
matrix GET /group ngan 200
matrix GET /group hung 404
matrix GET /group None 401
matrix GET  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members minh 200
matrix GET /members lan 200
matrix GET /members ngan 200
matrix GET /members hung 404
matrix GET /members None 401
matrix GET /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users minh 200
matrix GET /users lan 200
matrix GET /users ngan 200
matrix GET /users hung 404
matrix GET /users None 401
matrix GET /users malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions minh 200
matrix GET /transactions lan 200
matrix GET /transactions ngan 200
matrix GET /transactions hung 404
matrix GET /transactions None 401
matrix GET /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances minh 200
matrix GET /balances lan 200
matrix GET /balances ngan 200
matrix GET /balances hung 404
matrix GET /balances None 401
matrix GET /balances malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events minh 200
matrix GET /events lan 200
matrix GET /events ngan 200
matrix GET /events hung 404
matrix GET /events None 401
matrix GET /events malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite minh 200
matrix GET /invite lan 200
matrix GET /invite ngan 403
matrix GET /invite hung 404
matrix GET /invite None 401
matrix GET /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members minh 201
matrix POST /members lan 201
matrix POST /members ngan 403
matrix POST /members hung 404
matrix POST /members None 401
matrix POST /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda minh 200
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda lan 200
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda ngan 403
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda hung 404
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda None 401
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e016-62a6-7cb1-b089-4ba85153eeda random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions minh 201
matrix POST /transactions lan 201
matrix POST /transactions ngan 403
matrix POST /transactions hung 404
matrix POST /transactions None 401
matrix POST /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview minh 200
matrix POST /transactions/preview lan 200
matrix POST /transactions/preview ngan 403
matrix POST /transactions/preview hung 404
matrix POST /transactions/preview None 401
matrix POST /transactions/preview malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /group minh 200
matrix PATCH /group lan 403
matrix PATCH /group ngan 403
matrix PATCH /group hung 404
matrix PATCH /group None 401
matrix PATCH  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite minh 200
matrix PATCH /invite lan 403
matrix PATCH /invite ngan 403
matrix PATCH /invite hung 404
matrix PATCH /invite None 401
matrix PATCH /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate minh 200
matrix POST /invite/rotate lan 403
matrix POST /invite/rotate ngan 403
matrix POST /invite/rotate hung 404
matrix POST /invite/rotate None 401
matrix POST /invite/rotate malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 minh 200
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 lan 403
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 ngan 403
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 hung 404
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 None 401
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member minh 200
matrix PUT /me/member lan 200
matrix PUT /me/member ngan 200
matrix PUT /me/member hung 404
matrix PUT /me/member None 401
matrix POST /transfer-ownership lan 403
matrix POST /transfer-ownership ngan 403
matrix POST /transfer-ownership hung 404
matrix POST /transfer-ownership None 401
matrix POST /transfer-ownership minh 200
matrix DELETE /users/user lan 403
matrix DELETE /users/user ngan 403
matrix DELETE /users/user hung 404
matrix DELETE /users/user None 401
matrix DELETE /users/user minh 204
matrix POST /leave minh 422
matrix POST /leave lan 204
matrix POST /leave ngan 204
matrix POST /leave hung 404
matrix POST /leave None 401
matrix DELETE /members/member minh 204
matrix DELETE /members/member lan 204
matrix DELETE /members/member ngan 403
matrix DELETE /members/member hung 404
matrix DELETE /members/member None 401
matrix PUT /me/member malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e014-ab3d-7ad0-9555-21a8e70ba574 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e016-62a6-7cb1-b089-4ba85153eeda malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e016-62a6-7cb1-b089-4ba85153eeda random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
```

### Task 1C.6 — Gate result
Gate passed.
pnpm build with outbound networking denied: compiled successfully, TypeScript finished, 11/11 static pages generated; settlement route included. Reset compose volume, started cached Postgres image, migrations applied and development users seeded.
C acceptance produced every fixed T1–T5 share/balance/transfer; pairwise received-minus-paid equalled 290001/-120000/-170001/0. All seven invalid split/payer/type rows returned the specified 400 codes; preview returned exact T2 shares without increasing stored count beyond five.
B acceptance replay passed: unverified write denied; preview/joins/balances, viewer denial/read, live SSE, removal preservation, invite rotation, reset session revocation and identical enumeration-safe responses all recorded above.
A acceptance replay matched 566666/-33333/-333333/-200000 and all fixed minimized/pairwise transfers; Taxi shares 30000; inactive Thu -200000.
Every existing group endpoint was called as owner/editor/viewer/outsider/signed-out; outcomes match. Every malformed/random group endpoint produced normalized NOT_FOUND 404. Balance checker: three groups sum 0/mismatches 0; `All groups balanced`. pnpm check passed (193 files; all workspace typechecks Done).
Security review: relevant items 1, 4, 6, 8 checked against this documentation-only gate diff and observed responses; no secrets in output, no changed implementation or dependency.
Decisions: none. Deviations: acceptance requests are orchestrated by an uncommitted temporary curl-output printer; it contains no assertions and is not a repository test.
Not verified: device/visual/manual checks listed under C's UI tasks and real Google remain outstanding. Gate not passed: none.

Commit 1C.6: `154cbbc`.

## Task 1D.1 — Approach
- Tokenize folded NFC text while preserving original UTF-16 offsets and original description letters.
- Parse integer amount tokens, longest whole names, payer/equal phrases and personal parts with explicit consumed-token tracking.
- Assemble only recognized fields and derive status from issues; never guess ambiguous names, counts or unmatched words.
- Keep phrase/part helpers beside the five planned files to keep responsibilities and file sizes bounded.
- Print all 75 sample comparisons, computed shares and the required span/invalid-input exercises using an uncommitted local loop.

### Task 1D.1 — Result
`pnpm check`: passed (200 files; all five package typechecks Done).
All 75 sentences exercised through the actual reader and core split calculator. The additional checks cover required counts, sum totals, candidate order and issue fragments; no differences.

| Sample | Expected | Actual | Description / amount / payer / split / required issue / shares |
|---|---|---|---|
| A01 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A02 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A03 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A04 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A05 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A06 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A07 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A08 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A09 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A10 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A11 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A12 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A13 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A14 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A15 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A16 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A17 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A18 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A19 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A20 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A21 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A22 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A23 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A24 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A25 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A26 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A27 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A28 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A29 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A30 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A31 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A32 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A33 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A34 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A35 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A36 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A37 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A38 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A39 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A40 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A41 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A42 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A43 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A44 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A45 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| A46 | needs_input | needs_input | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: match, shares: — |
| A47 | needs_input | needs_input | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: match, shares: — |
| A48 | needs_input | needs_input | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: match, shares: — |
| A49 | needs_input | needs_input | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: match, shares: — |
| A50 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A51 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A52 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A53 | unparsed | unparsed | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: match, shares: — |
| A54 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A55 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A56 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A57 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A58 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A59 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A60 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A61 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A62 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| A63 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| B01 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| B02 | needs_input | needs_input | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| B03 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| B04 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| B05 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| B06 | needs_input | needs_input | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| B07 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| B08 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| C01 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| C02 | ok | ok | issueDetails: match, description: match, amount: match, payer: match, split: match, issue: —, shares: match |
| C03 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |
| C04 | unparsed | unparsed | issueDetails: match, description: —, amount: —, payer: —, split: —, issue: match, shares: — |

A01 spans: description 0–6, amount 7–11, equal 12–18. A36 spans: description 0–3, amount 4–8, payer 10–18, exact 20–42, remainder 44–60. Both match the document.
`foldVietnamese("Hùng ĐỨC mình")`: `hung duc minh`, length 13/13. 300 `a` characters: unparsed. Empty string: MEMBER_AMBIGUOUS, DESCRIPTION_MISSING, AMOUNT_MISSING.
Security review: relevant items 1, 2, 8 inspected against the whole diff; pure deterministic functions, no secrets/I/O/dependencies. No issues found. Full diff reviewed. Rule functions exceed 40 lines where one grammar pass owns its consumed tokens; files remain below 200 lines.
Decisions: phrase and personal-part helpers split into adjacent files to keep responsibilities small. Deviations: none. Not verified: live UI is introduced in later tasks; online dependency audit prohibited by the no-external-service rule. Out of scope: none.

Commit 1D.1: `abbfccb`.

## Task 1D.2 — Approach
- Add contract schemas for parse input/output and a service using the pure reader.
- Mount the editor-only endpoint through shared authorization, verified-email and origin checks.
- Use its separate 120/minute limiter; parsing never writes or consumes write quota.
- Compare all sample results over local HTTP, save five drafts, then exercise length, permissions and rate limits.

### Task 1D.2 — Result
`pnpm check`: passed (202 files, all workspace typechecks Done).
Initial exercise fixture put Lan first in B; corrected the fixture to the documented positions and linked writer Lan. Initial comparison also incorrectly expected an API payer with unknown amount; corrected to the specified empty payers. No application change was needed.
```text
A01 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A02 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A03 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A04 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A05 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A06 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A07 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A08 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A09 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A10 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A11 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A12 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A13 200 ok match [{'memberId': 'Minh', 'amount': 500000}, {'memberId': 'Lan', 'amount': 500000}, {'memberId': 'Hùng', 'amount': 500000}, {'memberId': 'Thu', 'amount': 500000}]
A14 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A15 200 ok match [{'memberId': 'Minh', 'amount': 24750}, {'memberId': 'Lan', 'amount': 24750}, {'memberId': 'Hùng', 'amount': 24750}, {'memberId': 'Thu', 'amount': 24750}]
A16 200 ok match [{'memberId': 'Minh', 'amount': 2500}, {'memberId': 'Lan', 'amount': 2500}, {'memberId': 'Hùng', 'amount': 2500}, {'memberId': 'Thu', 'amount': 2500}]
A17 200 ok match [{'memberId': 'Minh', 'amount': 250}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A18 200 ok match [{'memberId': 'Minh', 'amount': 251}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A19 200 ok match [{'memberId': 'Minh', 'amount': 400000}, {'memberId': 'Lan', 'amount': 400000}, {'memberId': 'Hùng', 'amount': 400000}, {'memberId': 'Thu', 'amount': 400000}]
A20 200 ok match [{'memberId': 'Minh', 'amount': 25000}, {'memberId': 'Lan', 'amount': 25000}, {'memberId': 'Hùng', 'amount': 25000}, {'memberId': 'Thu', 'amount': 25000}]
A21 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A22 200 ok match [{'memberId': 'Minh', 'amount': 200000}, {'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Hùng', 'amount': 200000}, {'memberId': 'Thu', 'amount': 200000}]
A23 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A24 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A25 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A26 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A27 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A28 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A29 200 ok match [{'memberId': 'Minh', 'amount': 100000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 100000}, {'memberId': 'Thu', 'amount': 100000}]
A30 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A31 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A32 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A33 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A34 200 ok match [{'memberId': 'Lan', 'amount': 22500}, {'memberId': 'Hùng', 'amount': 22500}]
A35 200 ok match [{'memberId': 'Thu', 'amount': 50000}]
A36 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A37 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A38 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A39 200 ok match [{'memberId': 'Minh', 'amount': 150000}, {'memberId': 'Lan', 'amount': 150000}]
A40 200 ok match [{'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 400000}]
A41 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A42 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
A43 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A44 200 ok match [{'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Thu', 'amount': 300000}]
A45 200 ok match [{'memberId': 'Lan', 'amount': 1500}, {'memberId': 'Hùng', 'amount': 248500}]
A46 200 needs_input match None
A47 200 needs_input match None
A48 200 needs_input match None
A49 200 needs_input match None
A50 200 unparsed match None
A51 200 unparsed match None
A52 200 unparsed match None
A53 200 unparsed match None
A54 200 unparsed match None
A55 200 unparsed match None
A56 200 unparsed match None
A57 200 unparsed match None
A58 200 unparsed match None
A59 200 unparsed match None
A60 200 unparsed match None
A61 200 unparsed match None
A62 200 unparsed match None
A63 200 unparsed match None
A parse count 0 0
save A01 201 True
save A23 201 True
save A31 201 True
save A36 201 True
save A43 201 True
B01 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B02 200 needs_input match None
B03 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B04 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B05 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B06 200 needs_input match None
B07 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B08 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B parse count 0 0
C01 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C02 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C03 200 unparsed match None
C04 200 unparsed match None
C parse count 0 0
301 400
empty 400
outsider 404
viewer 403
rate sweep {200: 43, 429: 78} total successes before429 includes previous samples
```
75/75 API statuses, draft fields, spans, issues match core sample results. Five stored share arrays equal their parse responses. Count stayed zero throughout parsing in each group. Rate limiter counts boundary-invalid requests too: 75 sample requests + 2 invalid lengths + 43 successes = 120; the next request returned 429.
Security review: items 1–6, 8 inspected; shared group authorization, bounded Zod body, separate per-user rate limit, parameterized group-member lookup, no write/log/secret exposure. Full diff reviewed. Not verified: online audit prohibited; real browser integration follows. Out of scope: none.

Commit 1D.2: `9056858`.

## Task 1D.3 — Approach
- Add group-scoped memory state, a debounced parse query and components for highlighted text and confirmation.
- Keep the server response as the source of all displayed official shares; disable saving stale/loading results.
- Extract the existing proportional shape display and initialize the manual form from the understood draft, preserving raw split inputs.
- Wire sample buttons and entry links to compose; retain the sentence during in-group navigation without storage or URL payloads.

### Task 1D.3 — Result
`pnpm check`: passed (209 files; all workspace typechecks Done).
Browser: dev-login Minh → compose A36. Card: 300.000, Minh trả, Riêng: Minh 80 · Lan 60 · Hùng 40, Còn 120.000 chia đều 3; shares Minh 120.000/Lan 100.000/Hùng 80.000; Thu excluded. DOM marks: `300k`, `mình trả`, `mình 80 lan 60 hùng 40`, `còn lại chia đều`. “Chỉnh tay” opens exact mode with 80000/60000/40000 and “Bỏ chia đều phần còn lại”. Back retained the sentence. Double-click Lưu returned to the stream; HTTP read count 6 (five prior API saves plus one UI save), newest lẩu shares 120000/100000/80000.
Security review: relevant items 1, 2, 7, 8 inspected; only React text nodes; response schemas validated, same-origin requests, memory-only drafts, no new dependency. Diff reviewed. The form controller is over 200 lines after initialization; it retains one state owner for the existing form and will be factored with edit support.
Decisions: accessible phrase labels use `role="img"` on marks because the implicit mark role does not support aria-label. Description remains ordinary text. Deviations: none.
Not verified: A01/A23/A43 browser saves, slow typing/double spaces/paste and empty sample/viewer checks remain for the combined D UI verification; API coverage for all four samples passed in 1D.2. Real screen-reader announcement and motion judgment require owner check. Out of scope: none.

Commit 1D.3: `61bd7e1`.

## Task 1D.4 — Approach
- Add a question card that retains explicit user choices and requests server previews before enabling save.
- Resolve ambiguous names by reparsing user-selected full names through the API, retaining the original sentence and span offsets in memory.
- Automatically hand unparsed sentences to the form once, show issue-specific copy and preserve exact inputs/back navigation.
- Keep count/description choices local; no transaction is created until the explicit save action.

### Task 1D.4 — Result
`pnpm check`: passed (213 files; all package typechecks Done).
Browser A46: 0/3 → 2/3 leaves “Chọn thêm 1 người” disabled; at 3/3 the fourth member is disabled, preview shows 60.000 each and Lưu enabled. No save pressed. A53 auto-opens exact editor with banner: “Các phần riêng cộng lại 180.000 đ, còn 120.000 đ chưa biết của ai. Mình không tự chia hộ.” Inputs 80000/60000/40000; status “Còn dư 120.000 đ · chưa lưu được”; lilac choice changes status to “Khớp 300.000 đ · không còn dư”. Returning to compose retained the original sentence. A48: empty description disables save; entering cà phê previews 45000 each; save returns to stream. B02: “minh nào?” lists Minh Anh, Minh Đức, Lan; choosing Minh Đức previews 50000 each; saving shows “Minh Đức trả” in stream. HTTP counts afterwards A=7, B=1, C=0, matching the five prior API saves and the explicit UI saves only; A46 and A53 created nothing.
Security review: relevant items 1, 2, 7, 8 inspected; user choices resolve only via validated parse/preview/create responses, no save of unresolved data, no HTML injection/storage/new dependency. Full diff reviewed. A separate current-preview flag prevents a previous preview being saved during debounce.
Decisions: original sentence and original highlight spans remain untouched while chosen full names are reparsed internally. No new grammar. Deviations: none.
Not verified: API-stop save recovery, individual A50/A55/A57/A59 browser lines, multiple simultaneous ambiguous words, and remaining D.3 visual exercises require the combined/manual checks. Their API rows passed. Out of scope: none.

Commit 1D.4: `a19b8fb`.

## Task 1D.5 — Approach
- Reset the local development database and replay all existing A/B/C acceptance requests.
- Rebuild sample groups A/B/C and compare every parse result; save the four required drafts and count only saves.
- Extend the role matrix with parse; run offline build, check and the balance checker.
- Record every actual output, including any gate item that cannot be verified.

### Task 1D.5 — Gate output
```text
dev login minh [204, null]
dev login lan [204, null]
dev login hung [204, null]
dev login thu [204, null]
create group 201
1C T1 [201, [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 120000}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 100000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "amount": 80000}]]
1C T2 [201, [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 480000}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 240000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "amount": 240000}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "amount": 240000}]]
1C T3 [201, [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 50000}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 50000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "amount": 50000}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "amount": 50000}]]
1C T4 [201, [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 49999}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 30000}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "amount": 20000}]]
1C minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "balance": 500001}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "balance": -120000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "balance": -170001}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "balance": -210000}], "transfers": [{"fromMemberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 210000}, {"fromMemberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 170001}, {"fromMemberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 120000}]}]
1C T5 201
1C after T5 [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "balance": 290001}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "balance": -120000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "balance": -170001}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "balance": 0}], "transfers": [{"fromMemberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 170001}, {"fromMemberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 120000}]}]
1C pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "balance": 290001}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "balance": -120000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "balance": -170001}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "balance": 0}], "transfers": [{"fromMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "toMemberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "amount": 50000}, {"fromMemberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 150000}, {"fromMemberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "toMemberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 190001}, {"fromMemberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "toMemberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 30000}, {"fromMemberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "toMemberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "amount": 20000}]}]
1C received minus paid {"Minh": 290001, "Lan": -120000, "Hùng": -170001, "Thu": 0}
1C exact mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 300000, "actual": 320000}, "requestId": "01a1e466-2913-7ee8-a8b4-17bd8e468603"}}]
1C payer mismatch [400, {"error": {"code": "PAYER_TOTAL_MISMATCH", "message": "Payer total differs from amount", "details": {"expected": 1200000, "actual": 1100000}, "requestId": "01a1e466-2921-778d-b16f-1656c7b72731"}}]
1C percent mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 100, "actual": 99}, "requestId": "01a1e466-292e-7cd5-9530-71d5f371423c"}}]
1C self transfer [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1e466-293b-7522-9097-3e1632b3cca3"}}]
1C weight precision [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.weight": ["Invalid string: must match pattern /^\\d{1,4}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e466-2945-738a-894a-52baecf85678"}}]
1C negative percent [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.percent": ["Invalid string: must match pattern /^\\d{1,3}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e466-294f-77c4-8729-56418d85b086"}}]
1C outside entry [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split": ["Invalid input"]}, "requestId": "01a1e466-2958-77f9-b19c-5ddc54d605e1"}}]
1C preview [200, {"shares": [{"memberId": "01a1e466-2860-7e2c-ba9b-ef5acec7a784", "amount": 480000}, {"memberId": "01a1e466-2861-777e-8ab6-5bd30d664de2", "amount": 240000}, {"memberId": "01a1e466-2862-787e-a5c6-ae2961f311dd", "amount": 240000}, {"memberId": "01a1e466-2863-74cf-89e1-bfccb5a45a22", "amount": 240000}]}]
1C stored count 5
1B register [204, null]
1B unverified write [403, {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1e466-29b3-761c-9c3b-4e1b69b13cd7"}}]
1B verify [204, null]
create group 201
1B preview [200, {"group": {"id": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17", "name": "Đà Lạt 12/2026"}, "ownerName": "Minh", "memberCount": 4, "transactionCount": 2, "members": [{"id": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "name": "Minh", "shape": "circle", "color": "mint", "claimed": true, "balance": null}, {"id": "01a1e466-29fb-7bb9-8c2b-5c00fbc19d3d", "name": "Lan", "shape": "diamond", "color": "sky", "claimed": false, "balance": 0}, {"id": "01a1e466-29fc-7f1a-b7a5-0bd43152fdbb", "name": "Hùng", "shape": "squircle", "color": "coral", "claimed": false, "balance": -300000}, {"id": "01a1e466-29fd-79bf-a6e5-f16bd8fd102f", "name": "Thu", "shape": "leaf", "color": "lilac", "claimed": false, "balance": -200000}], "alreadyJoined": false}]
1B Lan join [200, {"groupId": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17"}]
1B Ngân join [200, {"groupId": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17"}]
1B Hùng join [200, {"groupId": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17"}]
1B Lan list [200, {"groups": [{"id": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e466-29fb-7bb9-8c2b-5c00fbc19d3d", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e466-29fc-7f1a-b7a5-0bd43152fdbb", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e466-29fd-79bf-a6e5-f16bd8fd102f", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 0}]}]
1B Hùng list [200, {"groups": [{"id": "01a1e466-29fa-7d6a-8c8e-9f0f36cc8c17", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e466-29fb-7bb9-8c2b-5c00fbc19d3d", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e466-29fc-7f1a-b7a5-0bd43152fdbb", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e466-29fd-79bf-a6e5-f16bd8fd102f", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": -300000}]}]
1B viewer write [403, {"error": {"code": "FORBIDDEN", "message": "Insufficient group role", "requestId": "01a1e466-2aa7-74e7-aebc-479d26f10eb7"}}]
1B viewer read 200
1B SSE within 2s ": connected\n\nevent: changed\ndata: {\"resources\":[\"transactions\",\"balances\",\"activity\"]}\n\n"
1B remove Hùng [204, null]
1B removed read [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1e466-2d19-7206-925a-aa19b8d4a427"}}]
1B preserved balance [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "balance": 566666}, {"memberId": "01a1e466-29fb-7bb9-8c2b-5c00fbc19d3d", "balance": -33333}, {"memberId": "01a1e466-29fc-7f1a-b7a5-0bd43152fdbb", "balance": -333333}, {"memberId": "01a1e466-29fd-79bf-a6e5-f16bd8fd102f", "balance": -200000}, {"memberId": "01a1e466-2a64-752c-8c7f-6953dcd27cf5", "balance": 0}], "transfers": [{"fromMemberId": "01a1e466-29fc-7f1a-b7a5-0bd43152fdbb", "toMemberId": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "amount": 333333}, {"fromMemberId": "01a1e466-29fd-79bf-a6e5-f16bd8fd102f", "toMemberId": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "amount": 200000}, {"fromMemberId": "01a1e466-29fb-7bb9-8c2b-5c00fbc19d3d", "toMemberId": "01a1e466-29fb-7bb9-8c2b-5bfff46bdcaf", "amount": 33333}]}]
1B old invite [404, {"error": {"code": "INVITE_INVALID", "message": "Invite is invalid", "requestId": "01a1e466-2d4f-7433-9c5e-74b2779afaca"}}]
1B forgot [204, null]
1B reset [204, null]
1B sessions after reset [401, 401]
1B existing register [204, null]
1B new register [204, null]
1B known forgot [204, null]
1B unknown forgot [204, null]
create group 201
1A Vé cáp treo 201
1A Lẩu 201
1A Cà phê 201
1A minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "balance": 566666}, {"memberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "balance": -33333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "balance": -333333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 333333}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 200000}, {"fromMemberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 33333}]}]
1A pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "balance": 566666}, {"memberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "balance": -33333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "balance": -333333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 133333}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 233333}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "toMemberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "amount": 100000}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 200000}]}]
1A taxi [201, [{"memberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 30000}, {"memberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "amount": 30000}, {"memberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "amount": 30000}]]
1A inactive balance [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "balance": 626666}, {"memberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "balance": -63333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "balance": -363333}, {"memberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 163333}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 263333}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-45643b3f7120", "toMemberId": "01a1e466-2e24-780c-8652-a98f8098b5e6", "amount": 100000}, {"fromMemberId": "01a1e466-2e25-7a5c-8e2b-456522a0a1a1", "toMemberId": "01a1e466-2e23-7e10-aa3b-a8a95e42a58a", "amount": 200000}]}]
matrix GET /group minh 200
matrix GET /group lan 200
matrix GET /group ngan 200
matrix GET /group hung 404
matrix GET /group None 401
matrix GET  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members minh 200
matrix GET /members lan 200
matrix GET /members ngan 200
matrix GET /members hung 404
matrix GET /members None 401
matrix GET /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users minh 200
matrix GET /users lan 200
matrix GET /users ngan 200
matrix GET /users hung 404
matrix GET /users None 401
matrix GET /users malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions minh 200
matrix GET /transactions lan 200
matrix GET /transactions ngan 200
matrix GET /transactions hung 404
matrix GET /transactions None 401
matrix GET /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances minh 200
matrix GET /balances lan 200
matrix GET /balances ngan 200
matrix GET /balances hung 404
matrix GET /balances None 401
matrix GET /balances malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events minh 200
matrix GET /events lan 200
matrix GET /events ngan 200
matrix GET /events hung 404
matrix GET /events None 401
matrix GET /events malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite minh 200
matrix GET /invite lan 200
matrix GET /invite ngan 403
matrix GET /invite hung 404
matrix GET /invite None 401
matrix GET /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members minh 201
matrix POST /members lan 201
matrix POST /members ngan 403
matrix POST /members hung 404
matrix POST /members None 401
matrix POST /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 minh 200
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 lan 200
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 ngan 403
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 hung 404
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 None 401
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e466-2ee2-76ae-bc61-6d258b847076 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions minh 201
matrix POST /transactions lan 201
matrix POST /transactions ngan 403
matrix POST /transactions hung 404
matrix POST /transactions None 401
matrix POST /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview minh 200
matrix POST /transactions/preview lan 200
matrix POST /transactions/preview ngan 403
matrix POST /transactions/preview hung 404
matrix POST /transactions/preview None 401
matrix POST /transactions/preview malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /group minh 200
matrix PATCH /group lan 403
matrix PATCH /group ngan 403
matrix PATCH /group hung 404
matrix PATCH /group None 401
matrix PATCH  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite minh 200
matrix PATCH /invite lan 403
matrix PATCH /invite ngan 403
matrix PATCH /invite hung 404
matrix PATCH /invite None 401
matrix PATCH /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate minh 200
matrix POST /invite/rotate lan 403
matrix POST /invite/rotate ngan 403
matrix POST /invite/rotate hung 404
matrix POST /invite/rotate None 401
matrix POST /invite/rotate malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e minh 200
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e lan 403
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e ngan 403
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e hung 404
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e None 401
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member minh 200
matrix PUT /me/member lan 200
matrix PUT /me/member ngan 200
matrix PUT /me/member hung 404
matrix PUT /me/member None 401
matrix POST /transfer-ownership lan 403
matrix POST /transfer-ownership ngan 403
matrix POST /transfer-ownership hung 404
matrix POST /transfer-ownership None 401
matrix POST /transfer-ownership minh 200
matrix DELETE /users/user lan 403
matrix DELETE /users/user ngan 403
matrix DELETE /users/user hung 404
matrix DELETE /users/user None 401
matrix DELETE /users/user minh 204
matrix POST /leave minh 422
matrix POST /leave lan 204
matrix POST /leave ngan 204
matrix POST /leave hung 404
matrix POST /leave None 401
matrix DELETE /members/member minh 204
matrix DELETE /members/member lan 204
matrix DELETE /members/member ngan 403
matrix DELETE /members/member hung 404
matrix DELETE /members/member None 401
matrix PUT /me/member malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e465-dbbc-7f6b-8fa8-5cb2e8fce48e random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e466-2ee2-76ae-bc61-6d258b847076 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e466-2ee2-76ae-bc61-6d258b847076 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
A01 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A02 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A03 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A04 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A05 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A06 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A07 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A08 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A09 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A10 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A11 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A12 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A13 200 ok match [{'memberId': 'Minh', 'amount': 500000}, {'memberId': 'Lan', 'amount': 500000}, {'memberId': 'Hùng', 'amount': 500000}, {'memberId': 'Thu', 'amount': 500000}]
A14 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A15 200 ok match [{'memberId': 'Minh', 'amount': 24750}, {'memberId': 'Lan', 'amount': 24750}, {'memberId': 'Hùng', 'amount': 24750}, {'memberId': 'Thu', 'amount': 24750}]
A16 200 ok match [{'memberId': 'Minh', 'amount': 2500}, {'memberId': 'Lan', 'amount': 2500}, {'memberId': 'Hùng', 'amount': 2500}, {'memberId': 'Thu', 'amount': 2500}]
A17 200 ok match [{'memberId': 'Minh', 'amount': 250}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A18 200 ok match [{'memberId': 'Minh', 'amount': 251}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A19 200 ok match [{'memberId': 'Minh', 'amount': 400000}, {'memberId': 'Lan', 'amount': 400000}, {'memberId': 'Hùng', 'amount': 400000}, {'memberId': 'Thu', 'amount': 400000}]
A20 200 ok match [{'memberId': 'Minh', 'amount': 25000}, {'memberId': 'Lan', 'amount': 25000}, {'memberId': 'Hùng', 'amount': 25000}, {'memberId': 'Thu', 'amount': 25000}]
A21 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A22 200 ok match [{'memberId': 'Minh', 'amount': 200000}, {'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Hùng', 'amount': 200000}, {'memberId': 'Thu', 'amount': 200000}]
A23 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A24 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A25 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A26 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A27 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A28 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A29 200 ok match [{'memberId': 'Minh', 'amount': 100000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 100000}, {'memberId': 'Thu', 'amount': 100000}]
A30 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A31 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A32 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A33 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A34 200 ok match [{'memberId': 'Lan', 'amount': 22500}, {'memberId': 'Hùng', 'amount': 22500}]
A35 200 ok match [{'memberId': 'Thu', 'amount': 50000}]
A36 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A37 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A38 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A39 200 ok match [{'memberId': 'Minh', 'amount': 150000}, {'memberId': 'Lan', 'amount': 150000}]
A40 200 ok match [{'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 400000}]
A41 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A42 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
A43 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A44 200 ok match [{'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Thu', 'amount': 300000}]
A45 200 ok match [{'memberId': 'Lan', 'amount': 1500}, {'memberId': 'Hùng', 'amount': 248500}]
A46 200 needs_input match None
A47 200 needs_input match None
A48 200 needs_input match None
A49 200 needs_input match None
A50 200 unparsed match None
A51 200 unparsed match None
A52 200 unparsed match None
A53 200 unparsed match None
A54 200 unparsed match None
A55 200 unparsed match None
A56 200 unparsed match None
A57 200 unparsed match None
A58 200 unparsed match None
A59 200 unparsed match None
A60 200 unparsed match None
A61 200 unparsed match None
A62 200 unparsed match None
A63 200 unparsed match None
A parse count 0 0
save A01 201 True
save A31 201 True
save A36 201 True
save A43 201 True
B01 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B02 200 needs_input match None
B03 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B04 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B05 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B06 200 needs_input match None
B07 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B08 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B parse count 0 0
C01 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C02 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C03 200 unparsed match None
C04 200 unparsed match None
C parse count 0 0
301 400
empty 400
outsider 404
viewer 403
matrix parse minh 200
matrix parse lan 200
matrix parse ngan 403
matrix parse hung 404
matrix parse None 401
matrix parse bad group invalid (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e466-a493-70d0-84f3-1b7db8633b41'}})
matrix parse bad group 00000000-0000-4000-8000-000000000000 (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e466-a49c-7288-bdee-9214fdc6290b'}})
rate sweep {200: 42, 429: 79} total successes before429 includes previous samples
gate stored count A 4
gate stored count B 0
gate stored count C 0
```
Gate passed. Outbound-denied pnpm build passed (11/11 static pages); reset database migrated/seeded. All 75 parser comparisons match; A01/A31/A36/A43 saves match stored shares; counts A=4/B=0/C=0. A/B/C acceptance and full existing role matrix replayed above; parse matrix 200/200/403/404/401 with normalized malformed/random 404. `pnpm db:check-balances`: six groups sum 0, mismatches 0; `All groups balanced`. `pnpm check`: passed (213 files, all workspace typechecks Done).
Security review: relevant items 1,4,6,8 checked against documentation diff and actual responses; no secret output. No implementation changes or dependencies. Gate not passed: none. Not verified: UI/device items previously listed remain; Google remains unverified.

Commit 1D.5: `94ae2f1`.

## Task 1E.1 — Approach
- Reuse create validation and DTO mapping for scoped detail reads and transactional edits.
- Lock group then transaction, recheck access and compare version before changing any payer/share rows; no-op edits retain version.
- Store changed-field snapshots for updates and full snapshots for delete/restore, publishing only after commit.
- Split mutation helpers/routes into adjacent files to keep the existing list/create code small.

### Task 1E.1 — Result
`pnpm check`: passed (216 files, all typechecks Done).
```text
create group 201
create 201 {'description': 'Vé', 'amount': 600000, 'version': 1, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 150000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 150000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 150000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 150000}], 'deletedAt': None, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
edit 200 {'description': 'Vé', 'amount': 800000, 'version': 2, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'deletedAt': None, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
stale 409 {'error': {'code': 'VERSION_CONFLICT', 'message': 'Transaction has changed', 'details': {'current': {'type': 'expense', 'description': 'Vé', 'amount': 800000, 'occurredAt': '2026-11-15T00:00:00.000Z', 'category': None, 'payers': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 800000}], 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'id': '01a1e469-2ef4-78d1-897e-50682c2d1423', 'currency': 'VND', 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'version': 2, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}, 'createdBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}, 'createdAt': '2026-11-16T12:51:00.978Z', 'updatedAt': '2026-11-16T12:51:01.962Z', 'deletedAt': None}}, 'requestId': '01a1e469-35a8-7256-b570-86fea5da5c35'}}
balance checker 0 All groups balanced
wrong sum 400 {'error': {'code': 'SPLIT_TOTAL_MISMATCH', 'message': 'Split total differs from amount', 'details': {'expected': 800000, 'actual': 400000}, 'requestId': '01a1e469-38b2-7151-b0f4-958fc4375fba'}}
balance checker 0 All groups balanced
wrong type 400 {'error': {'code': 'VALIDATION_FAILED', 'message': 'Transaction type cannot change', 'requestId': '01a1e469-3b95-7d5b-8413-9e547c65941b'}}
balance checker 0 All groups balanced
no-op 200 {'description': 'Vé', 'amount': 800000, 'version': 2, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'deletedAt': None, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
delete 204 None
balance checker 0 All groups balanced
deleted get 200 {'description': 'Vé', 'amount': 800000, 'version': 3, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'deletedAt': '2026-11-16T12:51:05.710Z', 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
deleted list count 0
delete again 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e469-4739-7b3a-9848-a73363353eea'}}
balance checker 0 All groups balanced
patch deleted 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e469-4a17-7a2b-9756-ca08127021ce'}}
balance checker 0 All groups balanced
restore 200 {'description': 'Vé', 'amount': 800000, 'version': 4, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'deletedAt': None, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
restore again 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e469-4fee-7a96-babc-d05110c87777'}}
balance checker 0 All groups balanced
concurrent 200 {'description': 'Vé A', 'amount': 800000, 'version': 5, 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'deletedAt': None, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}}
balance checker 0 All groups balanced
concurrent 409 {'error': {'code': 'VERSION_CONFLICT', 'message': 'Transaction has changed', 'details': {'current': {'type': 'expense', 'description': 'Vé A', 'amount': 800000, 'occurredAt': '2026-11-15T00:00:00.000Z', 'category': None, 'payers': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 800000}], 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'id': '01a1e469-2ef4-78d1-897e-50682c2d1423', 'currency': 'VND', 'shares': [{'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2', 'amount': 200000}, {'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', 'amount': 200000}, {'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', 'amount': 200000}, {'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1', 'amount': 200000}], 'version': 5, 'updatedBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}, 'createdBy': {'id': '01a1e465-dbb7-7574-9975-b8ef6e67339d', 'name': 'Minh'}, 'createdAt': '2026-11-16T12:51:00.978Z', 'updatedAt': '2026-11-16T12:51:10.184Z', 'deletedAt': None}}, 'requestId': '01a1e469-52df-73c9-8eaa-10d8a5fdf1cc'}}
balance checker 0 All groups balanced
permissions ngan GET  200
permissions ngan PATCH  403
permissions ngan DELETE  403
permissions ngan POST /restore 403
permissions hung GET  404
permissions hung PATCH  404
permissions hung DELETE  404
permissions hung POST /restore 404
permissions None GET  401
permissions None PATCH  401
permissions None DELETE  401
permissions None POST /restore 401
bad id invalid (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e469-5905-769e-8f89-49bff94cadf6'}})
bad id 00000000-0000-4000-8000-000000000000 (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e469-5911-7557-b20c-1503cd9cafcc'}})
```
Direct database read: exactly five transaction activity rows (create, update, delete, restore, concurrent update); no row for no-op/failed edits. First edit before.amount=600000/after.amount=800000; before shares 150000 each/after shares 200000 each; changed fields only amount,payers,shares. Delete/restore snapshots retain original split.
Security review: items 1–7 inspected against added routes/services/queries; shared role checks, bounded params/body, malformed transaction IDs normalized 404, group-scoped lock and access recheck, atomic side replacement/deferred constraints, post-commit events, safe public last-editor identity. No issues found. Full diff reviewed. Mutations remain cohesive transaction functions; the 40-line guidance was reconsidered and helpers extracted for locks/snapshots/mapping.
Decisions: D26, D27. Deviations: adjacent helper files keep list/create files small. Not verified: owner/editor full new-route matrix will be replayed in the final gate; viewer/outsider/signed-out exercised above. Online audit prohibited. Out of scope: none.

Commit 1E.1: `084ef4e`.

## Task 1E.2 — Approach
- Add one keyset-paginated, group-scoped activity query with public actor data and live restore eligibility.
- Complete existing activity payloads for amounts, transaction type, member counts, chosen shapes and target names before exposing history.
- Add owner-only group deletion with exact, untrimmed confirmation and a locked access recheck.
- Exercise pagination, restore eligibility, role refusals, cascade deletion and the removed event using disposable local groups.

### Task 1E.2 — Result
`pnpm check`: passed (219 files, all typechecks Done).
Initial group deletion failed 500. Root cause and fix: D28; one fix, successful replay. No security/integrity constraints changed.
```text
history 200 [('restore', 'Minh', {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé A'}, {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé A'}, False), ('delete', 'Minh', {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé A'}, None, False), ('update', 'Minh', {'description': 'Vé'}, {'description': 'Vé A'}, False), ('restore', 'Minh', {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}, {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}, False), ('delete', 'Minh', {'type': 'expense', 'split': {'method': 'equal', 'members': ['01a1e469-2ec4-7b5b-8220-0816da5945d2', '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e', '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e', '01a1e469-2ecc-707b-b853-44d7315d2bf1']}, 'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}, None, False), ('update', 'Minh', {'amount': 600000, 'payers': [{'amount': 600000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 150000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 150000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 150000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 150000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}]}, {'amount': 800000, 'payers': [{'amount': 800000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}], 'shares': [{'amount': 200000, 'memberId': '01a1e469-2ec4-7b5b-8220-0816da5945d2'}, {'amount': 200000, 'memberId': '01a1e469-2ec7-7c00-b46a-a9bbb4e63e3e'}, {'amount': 200000, 'memberId': '01a1e469-2ec9-7ef0-95cf-9ffb697b3e6e'}, {'amount': 200000, 'memberId': '01a1e469-2ecc-707b-b853-44d7315d2bf1'}]}, False), ('create', 'Minh', None, None, False), ('create', 'Minh', None, None, False)]
pagination total 8 unique 8
canRestore deleted [('delete', True), ('restore', False), ('delete', True), ('update', False), ('restore', False), ('delete', True), ('update', False), ('create', False), ('create', False)]
canRestore restored [('restore', False), ('delete', False), ('restore', False), ('delete', False), ('update', False), ('restore', False), ('delete', False), ('update', False), ('create', False), ('create', False)]
outsider history 404
bad cursor 400
editor delete 403
wrong confirmation 'wrong' 400
wrong confirmation 'delete exercise' 400
wrong confirmation '' 400
wrong confirmation 'Delete Exercise ' 400
exact delete 204
removed event : connected

event: removed
data: {}


later requests [404, 404]
other groups unchanged True
delete account after owned group removed 204
```
SQL on the initially failed group after successful retry: members=0, transactions=0, activity=0. Balance checker: all seven remaining groups sum 0/mismatches 0; `All groups balanced`. Existing pre-1E.2 create activities had no after snapshot; newly created records now carry required type/amount/payers/shares/split, member count, target name, invite state and member choice. No dev-data backfill is needed; gates reset the database.
Security review: items 1–7 inspected; viewer activity reads authorized, outsider 404, bounded/validated cursor, group-scoped parameterized joins, public actor fields only, owner confirmation exact without trimming, lock/access recheck and atomic deletion, removed published after commit. Full diff reviewed. Decisions: D28. Deviations: explicit transaction deletion before cascading group deletion is necessary for the existing RESTRICT FKs. Not verified: final matrix and full history copy exercise follow in E4/E6. Out of scope: none.

Commit 1E.2: `dc2351a`.

## Task 1E.3 — Approach
- Add transaction detail/update/delete/restore hooks and an edit page retaining a loaded version while realtime data refreshes.
- Initialize the existing form from original split and payer inputs, fix its type, and enable update only for changed valid fields.
- Surface current server data in a conflict notice without overwriting local edits; reload only on explicit action.
- Add a group-layout snackbar for six-second undo and editor-only stream links/edited tags.

### Task 1E.3 — Result
`pnpm check`: passed (223 files; all workspace typechecks Done).
Browser edit: loaded 800000/Vé A, type switch absent, save disabled before edits. Typed “Vé đang sửa”; a separate HTTP editor saved “Vé bản mới” → realtime notice “Minh vừa sửa khoản này. Xem bản mới rồi sửa lại nếu cần.”, local text retained, save disabled. Xem bản mới explicitly loaded server content. Delete showed deleted notice and snackbar. First manual undo click was inconclusive across navigation/expiry; repeated with semantic locator within the six-second window → restored row and “Đã khôi phục.”. Changed amount to 900000 and saved → stream, balance 675000; HTTP detail amount=900000/version=15/deletedAt=null/shares=[225000,225000,225000,225000]. Every balance checker row sum 0/mismatches 0; All groups balanced.
Security review: items 1,2,7,8 checked against all new UI/hook code; same-origin validated DTOs, untrusted conflict data parsed before use, no raw HTML/storage/new dependencies; viewer address is forbidden and viewer stream has no edit links in code. Full diff reviewed. No issues found.
Decisions: last-editor attribution D26. The 247-line form renderer and 212-line controller were reconsidered: retaining one state owner and one renderer avoids splitting tightly coupled fields; adjacent mutation hooks, conflict and snackbar components contain independent behavior. Original inactive participants remain available when editing an old transaction. Original timestamp seconds are preserved unless the time field changes.
Deviations: browser observer plus HTTP actor exercises realtime; two independent browser profiles remain manual. A root dev command was accidentally invoked during startup, reran idempotent migrations/seeding and failed its duplicate API bind; stopped it and used web-only dev. No repository/config changes resulted.
Not verified: every original split mode, two-payer/income/transfer prefill, blank exact input, snackbar expiry, viewer address and physical screen-reader checks remain for E6/manual checks. No claim that these UI cases ran. Out of scope: none.

Commit 1E.3: `a8ca461`.

## Task 1E.4 — Approach
- Map validated activity data to the exact Vietnamese sentence table and changed-field chips in one formatter.
- Add a newest-first infinite history screen with day separators, restore controls for editors and live invalidation.
- Add the exact-name deletion dialog to owner settings; clear group queries and show the deletion notice on the group list.
- Exercise history values, restoring after undo expiry and deletion confirmation; retain actor/member names as text nodes.

### Task 1E.4 — Result
`pnpm check`: passed (229 files, all workspace typechecks Done).
Created 29 real activity entries spanning the sentence table; rendered the actual formatter and read the history page.
```text
role_change group_user Minh đổi quyền của Lan thành Chỉ xem []
transfer_ownership group_user Lan chuyển quyền chủ nhóm cho Minh []
transfer_ownership group_user Minh chuyển quyền chủ nhóm cho Lan []
remove group_user Minh gỡ Hùng khỏi nhóm []
join group_user Hùng vào nhóm, nhận hình của Hùng []
leave group_user Hùng rời nhóm []
role_change group_user Minh đổi quyền của Hùng thành Chỉ xem []
update group Minh tạo link mời mới []
update group Minh bật link mời []
update group Minh tắt link mời []
update group Minh đổi quyền mặc định thành Chỉ xem []
update group Minh bật gộp nợ []
update group Minh tắt gộp nợ []
update group Minh đổi tên nhóm [{"field":"Mô tả","before":"Đà Lạt 12/2026","after":"History Exercise"}]
delete member Minh xoá Tên mới []
update member Minh đổi phần mặc định của Tên mới [{"field":"Phần","before":"1.00","after":"2.00"}]
update member Minh cho Tên mới hoạt động lại []
update member Minh cho Tên mới ngừng hoạt động []
update member Minh đổi tên thành viên [{"field":"Mô tả","before":"Test member","after":"Tên mới"}]
create member Minh thêm Test member []
create transaction Hùng ghi nhận Hùng đã chuyển 100.000 đ cho Minh []
create transaction Lan thêm khoản thu Hoàn cọc · 200.000 đ []
delete transaction Minh xoá Vé mới · 800.000 đ []
update transaction Minh sửa Vé mới [{"field":"Số tiền","before":"600.000","after":"800.000"},{"field":"Người trả","before":"Minh 600.000","after":"Minh 800.000"},{"field":"Cách chia","before":"Minh 150.000 · Lan 150.000 · Hùng 150.000 · Thu 150.000","after":"Minh 200.000 · Lan 200.000 · Hùng 200.000 · Thu 200.000"},{"field":"Mô tả","before":"Vé","after":"Vé mới"}]
create transaction Minh thêm Vé · 600.000 đ []
update group_user Minh nhận hình của Minh []
join group_user Hùng vào nhóm, nhận hình của Hùng []
join group_user Lan vào nhóm, nhận hình của Lan []
create group Minh tạo nhóm với 4 người []
```
Browser: history shows all 29 entries, including actors and labelled multi-field chips. DOM del elements include 600.000, old payer/share values and old description; after amount 800.000. Khôi phục after the original undo period added newest “Minh khôi phục Vé mới · 800.000 đ”, removed restore controls and showed “Đã khôi phục.”. Settings dialog: empty/case-changed name leaves delete disabled; exact History Exercise enables; Thôi closes and restores focus to opener.
Security review: items 1,2,7,8 inspected: activity unknown fields are validated before formatting, React text nodes only, restore/create/delete use existing authorized APIs, no persistent draft/secret state or new dependencies. Full diff reviewed. Decisions: D29. The 219-line history formatter keeps its finite sentence mapping together; field rendering and changed-field extraction are separate functions. Deviations: none.
Not verified: final deletion through the UI button was not clicked; API deletion/cascade/removed passed in E2. Viewer history and second independent browser window remain owner checks; current code gates restore on role and verification. Physical screen-reader/visual judgment remains manual. Out of scope: none.

Commit 1E.4: `a0417ef`.

## Task 1E.5 — Approach
- Track browser connectivity and API network failures in a shared memory store; probe only the local health endpoint for recovery.
- Disable write requests at the API client as well as UI controls, without mutation queuing; keep cached reads visible.
- Add an offline banner and recovery invalidation/SSE reconnection, plus a new-item pill preserving a scrolled-up position.
- Add CSS-only shape/card/row motion and integer display interpolation through the existing core allocator; honor reduced motion everywhere.

### Task 1E.5 — Result
`pnpm check`: passed (236 files; all workspace typechecks Done).
Stopped only API while browser remained connected to the web server: banner “Mất mạng. Bạn vẫn xem được sổ.” / “lúc 20:14”. Cached balances remained 550000/-50000/-150000/-350000; cached stream/member/settings navigation stayed readable. Entry bar became “Có mạng lại là gõ tiếp được”. Member role controls, remove, claim, add, and settings save/minimize/default role/invite/ownership/delete controls were disabled, with “Cần có mạng để lưu.”. Restarted API: local health probe recovered, banner and explanations disappeared and controls enabled without reload. SSE lifecycle follows shared connectivity; recovery invalidates queries. Offline mutations use always-network mode with no retries and the API client rejects writes before fetch, so no queue exists.
Offline install for the existing core workspace link: `downloaded 0, added 0`, `Already up to date`. No new third-party dependency. Display frames use integer allocations in core; official balances are unchanged API values.
Security review: items 1,2,7,8 inspected against complete diff; only local health probing, no persistence/secrets, same-origin requests/origin checks retained, no permission checks weakened. Full diff reviewed. Decisions: D30. Deviations: native controls use shared wrappers so disabled and aria-disabled remain consistent; pure back/close/new-item navigation remains usable offline.
Not verified: browser devtools offline emulation, cached history offline, the new-item pill on a long stream, physical reduced-motion and owner judgment of the four motions remain for E6/manual checks. API-stop/recovery and cached stream/balances/members/settings were observed directly. Out of scope: none.

Commit 1E.5: `d511e98`.

## Task 1E.6 — Approach
- Populate a four-member local group with 500 API-created transactions while honoring per-user rate limits; measure five read samples and SQL statement counts.
- Inspect contrast tokens, 360×640 layouts, keyboard/accessibility naming and outstanding UI cases; fix concrete findings.
- Document Phase 1/dev mail/Google/balance checking in README, then reset and replay the full sample trip, prior gates and complete permission matrix.
- Consolidate the owner checklist by screen/flow and record final unresolved/unverified items before the final task commit.

### Task 1E.6 — Load and non-functional evidence (before final reset)
```text
create group 201
join lan 200
join hung 200
join thu 200
inserted 50
inserted 100
inserted 150
inserted 200
rate window wait 58 seconds
inserted 250
inserted 300
inserted 350
inserted 400
inserted 450
rate window wait 58 seconds
inserted 500
stored 500
transactions runs [['200', '0.010554', '49146'], ['200', '0.007636', '49146'], ['200', '0.006140', '49146'], ['200', '0.006827', '49146'], ['200', '0.008333', '49146']] median ms 7.636 bytes 49146
balances minimized runs [['200', '0.004337', '727'], ['200', '0.003791', '727'], ['200', '0.003741', '727'], ['200', '0.003681', '727'], ['200', '0.003989', '727']] median ms 3.791 bytes 727
groups runs [['200', '0.005677', '4519'], ['200', '0.003833', '4519'], ['200', '0.003905', '4519'], ['200', '0.003694', '4519'], ['200', '0.003920', '4519']] median ms 3.9050000000000002 bytes 4519
pairwise mode 200
balances pairwise runs [['200', '0.021571', '728'], ['200', '0.020161', '728'], ['200', '0.025184', '728'], ['200', '0.018771', '728'], ['200', '0.018249', '728']] median ms 20.160999999999998 bytes 728
SQL statements including authentication/authorization: transactions limit=50: 5; limit=1: 5; balances minimized: 4; balances pairwise: 6; groups: 4.
Temporary PostgreSQL logging had parameter values disabled (log_parameter_max_length=0); restored log_statement=none and log_parameter_max_length=-1 afterwards.
```

| Foreground | Background | Ratio | Result |
|---|---|---|---|
| ink | mint | 12.28:1 | pass |
| ink | sky | 10.09:1 | pass |
| ink | coral | 7.43:1 | pass |
| ink | lilac | 9.82:1 | pass |
| ink | accent | 12.35:1 | pass |
| ink | phrase-amount | 14.13:1 | pass |
| ink | phrase-payer | 13.09:1 | pass |
| ink | phrase-split | 14.46:1 | pass |
| ink | phrase-rest | 12.83:1 | pass |
| ink | debt-soft | 13.10:1 | pass |
| ink | sunken | 13.71:1 | pass |
| ink | bg | 15.47:1 | pass |
| ink | surface | 17.08:1 | pass |
| muted | bg | 6.36:1 | pass |
| muted | surface | 7.02:1 | pass |
| muted | sunken | 5.64:1 | pass |
| on-ink-muted | ink | 10.12:1 | pass |
| on-ink-muted | ink-raised | 7.45:1 | pass |
| surface | ink | 17.08:1 | pass |
All required text pairs exceed 4.5:1; no color-token change was needed.

Browser viewport override measured 360×640 CSS pixels initially; native zoom rounding produced 359–361px on later navigations. Screens S1–S13 inspected at this size (S12 invalid-link state); no unnamed product control found. Keyboard walks recorded normal order and 2px/2px focus on application controls; a native date sub-control initially used its browser outline, so date focus was explicitly covered too. Development tool focus is outside the product. S2 initially overflowed to 384px due to the featured 52px balance; wrapping repaired it (D31). Real software-keyboard reach and actual screen-reader speech remain Not verified.
New-item exercise on the 500-record group: scrollTop=2756, viewport height=141/scrollHeight=5882; remote insert 201 → Có khoản mới and same scrollTop=2756. Tapping pill → scrollTop=5741.33 and pill removed. The extra record was added after load measurements.
Original edit inputs observed for remainder 80000/60000/40000, weights 2/1/1/1 with payers 800000/400000, percent 50/30/20, income 200000, transfer 210000, and exact-with-blanks 40000/blank/blank/blank. All unchanged save buttons disabled; no type switch.
Browser A01/A23/A43 cards and saves completed: 45000 each / Lan payer 62500 each / 33334,33333,33333 with 70000 remainder. A36 already observed in D3. Pasted `cà  phê 180k\nmình trả` became `cà  phê 180k mình trả`; marks covered exactly 180k and mình trả. A50/A55/A57/A59 banners matched the approved sentences; back retained A59.
Viewer Lan observed live history deletion with two API-restorable entries and zero restore controls; newest row changed without reload. Direct edit address showed forbidden, stream had zero edit/entry links and Chỉ xem.
Duplicate-name exercise: unchosen reader needs_input; explicit second Minh choice produced ok, server preview and a successful UI save (writer balance -60000). Unlinked pronoun/default choices were exercised through core and resolved only to the chosen id. 75 core samples still match, including A01/A36 spans; huge count and long description return unparsed.
Not verified: 4G throttling/time-to-visible is unavailable in the provided browser capabilities; these latency numbers are localhost only. Physical screen reader, software keyboard, OS reduced-motion judgment, valid-invite S12 narrow layout and native share/QR camera remain manual.

### Task 1E.6 — Final gate outputs

#### Reset final trip
```text
trip login minh 204
trip login lan 204
trip login hung 204
trip login thu 204
create group 201
trip join lan 200
trip join hung 200
trip register 204
trip verify 204
trip Ngân join 200
trip viewer role 200
trip parse 200 ok [{'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 300000}] [{'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 120000}, {'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'amount': 80000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 100000}]
trip save 201 [{'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 120000}, {'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'amount': 80000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 100000}]
trip T2 201 [{'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b', 'amount': 480000}, {'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 240000}, {'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'amount': 240000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 240000}]
trip T3 201 [{'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b', 'amount': 50000}, {'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 50000}, {'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'amount': 50000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 50000}]
trip T4 201 [{'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b', 'amount': 49999}, {'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 30000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 20000}]
trip edit 200 2 [{'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 130000}, {'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'amount': 90000}, {'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'amount': 110000}]
trip conflict 409 VERSION_CONFLICT 2
trip Hùng delete T4 204
trip activity canRestore True
trip Hùng restore T4 200
trip balances before settle [('Minh', 320001), ('Lan', 180000), ('Hùng', -180001), ('Thu', -320000), ('Ngân', 0)]
trip settlement 201 {'fromMemberId': '01a1e493-9468-7662-90bd-188c5a4f819d', 'toMemberId': '01a1e493-9463-7da3-b67d-24ab1990a06b', 'amount': 320000}
trip settlement 201 {'fromMemberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'toMemberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', 'amount': 180000}
trip settlement 201 {'fromMemberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25', 'toMemberId': '01a1e493-9463-7da3-b67d-24ab1990a06b', 'amount': 1}
trip final balances [('Minh', 0), ('Lan', 0), ('Hùng', 0), ('Thu', 0), ('Ngân', 0)] transfers []
trip history [('Minh', 'create', 'transaction', 'Chuyển khoản', None, {'type': 'transfer', 'split': {'method': 'exact', 'entries': [{'amount': 1, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}], 'members': ['01a1e493-9463-7da3-b67d-24ab1990a06b'], 'remainder': 'none'}, 'amount': 1, 'payers': [{'amount': 1, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 1, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}], 'category': None, 'occurredAt': '2026-11-16T01:00:00.000Z', 'description': 'Chuyển khoản'}), ('Minh', 'create', 'transaction', 'Chuyển khoản', None, {'type': 'transfer', 'split': {'method': 'exact', 'entries': [{'amount': 180000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'members': ['01a1e493-9466-70e4-a0d1-d6b39e8be6a6'], 'remainder': 'none'}, 'amount': 180000, 'payers': [{'amount': 180000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 180000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'category': None, 'occurredAt': '2026-11-16T01:00:00.000Z', 'description': 'Chuyển khoản'}), ('Minh', 'create', 'transaction', 'Chuyển khoản', None, {'type': 'transfer', 'split': {'method': 'exact', 'entries': [{'amount': 320000, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}], 'members': ['01a1e493-9463-7da3-b67d-24ab1990a06b'], 'remainder': 'none'}, 'amount': 320000, 'payers': [{'amount': 320000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'shares': [{'amount': 320000, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}], 'category': None, 'occurredAt': '2026-11-16T01:00:00.000Z', 'description': 'Chuyển khoản'}), ('Hùng', 'restore', 'transaction', 'Vé', {'type': 'expense', 'split': {'method': 'percent', 'entries': [{'percent': '50', 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'percent': '30', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'percent': '20', 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, 'amount': 99999, 'payers': [{'amount': 99999, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 49999, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 30000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 20000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}, {'type': 'expense', 'split': {'method': 'percent', 'entries': [{'percent': '50', 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'percent': '30', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'percent': '20', 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, 'amount': 99999, 'payers': [{'amount': 99999, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 49999, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 30000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 20000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}), ('Hùng', 'delete', 'transaction', 'Vé', {'type': 'expense', 'split': {'method': 'percent', 'entries': [{'percent': '50', 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'percent': '30', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'percent': '20', 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, 'amount': 99999, 'payers': [{'amount': 99999, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 49999, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 30000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 20000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}, None), ('Minh', 'update', 'transaction', 'lẩu', {'amount': 300000, 'payers': [{'amount': 300000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'shares': [{'amount': 120000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 80000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 100000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, {'amount': 330000, 'payers': [{'amount': 330000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'shares': [{'amount': 130000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 90000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 110000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}), ('Minh', 'create', 'transaction', 'Vé', None, {'type': 'expense', 'split': {'method': 'percent', 'entries': [{'percent': '50', 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'percent': '30', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'percent': '20', 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, 'amount': 99999, 'payers': [{'amount': 99999, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}], 'shares': [{'amount': 49999, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 30000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 20000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Vé'}), ('Minh', 'create', 'transaction', 'Hoàn cọc', None, {'type': 'income', 'split': {'method': 'equal', 'members': ['01a1e493-9463-7da3-b67d-24ab1990a06b', '01a1e493-9466-70e4-a0d1-d6b39e8be6a6', '01a1e493-9467-7b5d-9ed4-37cd5f602c25', '01a1e493-9468-7662-90bd-188c5a4f819d']}, 'amount': 200000, 'payers': [{'amount': 200000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'shares': [{'amount': 50000, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 50000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 50000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 50000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Hoàn cọc'}), ('Minh', 'create', 'transaction', 'Khách sạn', None, {'type': 'expense', 'split': {'method': 'shares', 'entries': [{'weight': '2', 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'weight': '1', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'weight': '1', 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'weight': '1', 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}]}, 'amount': 1200000, 'payers': [{'amount': 800000, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 400000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'shares': [{'amount': 480000, 'memberId': '01a1e493-9463-7da3-b67d-24ab1990a06b'}, {'amount': 240000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 240000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 240000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-15T00:00:00.000Z', 'description': 'Khách sạn'}), ('Lan', 'create', 'transaction', 'lẩu', None, {'type': 'expense', 'split': {'method': 'exact', 'entries': [{'amount': 80000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 40000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 60000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'members': ['01a1e493-9466-70e4-a0d1-d6b39e8be6a6', '01a1e493-9467-7b5d-9ed4-37cd5f602c25', '01a1e493-9468-7662-90bd-188c5a4f819d'], 'remainder': 'equal_among_all'}, 'amount': 300000, 'payers': [{'amount': 300000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}], 'shares': [{'amount': 120000, 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}, {'amount': 80000, 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}, {'amount': 100000, 'memberId': '01a1e493-9468-7662-90bd-188c5a4f819d'}], 'category': None, 'occurredAt': '2026-11-16T00:00:00.000Z', 'description': 'lẩu'}), ('Minh', 'role_change', 'group_user', 'Group role changed', {'role': 'editor'}, {'name': 'Ngân', 'role': 'viewer'}), ('Ngân', 'join', 'group_user', 'Ngân', None, {'name': 'Ngân', 'memberId': '01a1e493-94f0-711d-bf8c-faba4ec1aee0'}), ('Ngân', 'create', 'member', 'Ngân', None, None), ('Hùng', 'join', 'group_user', 'Hùng', None, {'name': 'Hùng', 'memberId': '01a1e493-9467-7b5d-9ed4-37cd5f602c25'}), ('Lan', 'join', 'group_user', 'Lan', None, {'name': 'Lan', 'memberId': '01a1e493-9466-70e4-a0d1-d6b39e8be6a6'}), ('Minh', 'create', 'group', 'Đà Lạt 12/2026', None, {'memberCount': 4})]
trip delete group 204
trip removed : connected

event: removed
data: {}


trip Lan later  404
trip Lan later /members 404
trip Lan later /transactions 404
trip Lan later /activity 404
trip Lan later /balances 404
trip cascade counts members|0
transactions|0
activity|0
$ pnpm --filter @songphang/db check-balances
$ tsx --env-file=../../.env src/check-balances.ts
No groups
```

#### Replay 1A–1C and existing permission matrix
```text
dev login minh [204, null]
dev login lan [204, null]
dev login hung [204, null]
dev login thu [204, null]
create group 201
1C T1 [201, [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 120000}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 100000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "amount": 80000}]]
1C T2 [201, [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 480000}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 240000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "amount": 240000}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "amount": 240000}]]
1C T3 [201, [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 50000}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 50000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "amount": 50000}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "amount": 50000}]]
1C T4 [201, [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 49999}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 30000}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "amount": 20000}]]
1C minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "balance": 500001}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "balance": -120000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "balance": -170001}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "balance": -210000}], "transfers": [{"fromMemberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 210000}, {"fromMemberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 170001}, {"fromMemberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 120000}]}]
1C T5 201
1C after T5 [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "balance": 290001}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "balance": -120000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "balance": -170001}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "balance": 0}], "transfers": [{"fromMemberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 170001}, {"fromMemberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 120000}]}]
1C pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "balance": 290001}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "balance": -120000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "balance": -170001}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "balance": 0}], "transfers": [{"fromMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "toMemberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "amount": 50000}, {"fromMemberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 150000}, {"fromMemberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "toMemberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 190001}, {"fromMemberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "toMemberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 30000}, {"fromMemberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "toMemberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "amount": 20000}]}]
1C received minus paid {"Minh": 290001, "Lan": -120000, "Hùng": -170001, "Thu": 0}
1C exact mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 300000, "actual": 320000}, "requestId": "01a1e494-887e-72e6-ac68-3112441c8485"}}]
1C payer mismatch [400, {"error": {"code": "PAYER_TOTAL_MISMATCH", "message": "Payer total differs from amount", "details": {"expected": 1200000, "actual": 1100000}, "requestId": "01a1e494-888a-7f48-afab-6c89f1248f2e"}}]
1C percent mismatch [400, {"error": {"code": "SPLIT_TOTAL_MISMATCH", "message": "Split total differs from amount", "details": {"expected": 100, "actual": 99}, "requestId": "01a1e494-8897-72af-996a-ee09656384fa"}}]
1C self transfer [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"body": ["Invalid input"]}, "requestId": "01a1e494-88a2-7a14-ba6f-fcff0a9d04a9"}}]
1C weight precision [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.weight": ["Invalid string: must match pattern /^\\d{1,4}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e494-88ab-79ab-bddc-5719b50d5a53"}}]
1C negative percent [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split.entries.0.percent": ["Invalid string: must match pattern /^\\d{1,3}(\\.\\d{1,2})?$/"]}, "requestId": "01a1e494-88b4-7526-82e8-e39b6d36880f"}}]
1C outside entry [400, {"error": {"code": "VALIDATION_FAILED", "message": "Request validation failed", "details": {"split": ["Invalid input"]}, "requestId": "01a1e494-88bd-7629-8c08-46586100d8ce"}}]
1C preview [200, {"shares": [{"memberId": "01a1e494-87d1-7f46-91dc-dbf7e7c11b0c", "amount": 480000}, {"memberId": "01a1e494-87d3-78a1-9a20-65b96c16705f", "amount": 240000}, {"memberId": "01a1e494-87d4-78e3-8830-d897cda22a89", "amount": 240000}, {"memberId": "01a1e494-87d6-7c78-92cf-a8d38028627e", "amount": 240000}]}]
1C stored count 5
1B register [204, null]
1B unverified write [403, {"error": {"code": "EMAIL_NOT_VERIFIED", "message": "Email verification required", "requestId": "01a1e494-890f-7100-a066-b2f1aa924706"}}]
1B verify [204, null]
create group 201
1B preview [200, {"group": {"id": "01a1e494-8953-707a-a3f9-0375c6e131d6", "name": "Đà Lạt 12/2026"}, "ownerName": "Minh", "memberCount": 4, "transactionCount": 2, "members": [{"id": "01a1e494-8953-707a-a3f9-037668238cb1", "name": "Minh", "shape": "circle", "color": "mint", "claimed": true, "balance": null}, {"id": "01a1e494-8954-7867-8c59-91826be6f222", "name": "Lan", "shape": "diamond", "color": "sky", "claimed": false, "balance": 0}, {"id": "01a1e494-8955-75a5-ad24-bb2bccab74bd", "name": "Hùng", "shape": "squircle", "color": "coral", "claimed": false, "balance": -300000}, {"id": "01a1e494-8955-75a5-ad24-bb2c99e331a1", "name": "Thu", "shape": "leaf", "color": "lilac", "claimed": false, "balance": -200000}], "alreadyJoined": false}]
1B Lan join [200, {"groupId": "01a1e494-8953-707a-a3f9-0375c6e131d6"}]
1B Ngân join [200, {"groupId": "01a1e494-8953-707a-a3f9-0375c6e131d6"}]
1B Hùng join [200, {"groupId": "01a1e494-8953-707a-a3f9-0375c6e131d6"}]
1B Lan list [200, {"groups": [{"id": "01a1e494-8953-707a-a3f9-0375c6e131d6", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e494-8953-707a-a3f9-037668238cb1", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e494-8954-7867-8c59-91826be6f222", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e494-8955-75a5-ad24-bb2bccab74bd", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e494-8955-75a5-ad24-bb2c99e331a1", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": 0}]}]
1B Hùng list [200, {"groups": [{"id": "01a1e494-8953-707a-a3f9-0375c6e131d6", "name": "Đà Lạt 12/2026", "currency": "VND", "memberCount": 5, "previewMembers": [{"id": "01a1e494-8953-707a-a3f9-037668238cb1", "name": "Minh", "shape": "circle", "color": "mint"}, {"id": "01a1e494-8954-7867-8c59-91826be6f222", "name": "Lan", "shape": "diamond", "color": "sky"}, {"id": "01a1e494-8955-75a5-ad24-bb2bccab74bd", "name": "Hùng", "shape": "squircle", "color": "coral"}, {"id": "01a1e494-8955-75a5-ad24-bb2c99e331a1", "name": "Thu", "shape": "leaf", "color": "lilac"}], "myBalance": -300000}]}]
1B viewer write [403, {"error": {"code": "FORBIDDEN", "message": "Insufficient group role", "requestId": "01a1e494-89ff-75f8-b571-e9bd95b76963"}}]
1B viewer read 200
1B SSE within 2s ": connected\n\nevent: changed\ndata: {\"resources\":[\"transactions\",\"balances\",\"activity\"]}\n\n"
1B remove Hùng [204, null]
1B removed read [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found", "requestId": "01a1e494-8c7c-7b9f-8c0c-b8190b1cf4ad"}}]
1B preserved balance [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e494-8953-707a-a3f9-037668238cb1", "balance": 566666}, {"memberId": "01a1e494-8954-7867-8c59-91826be6f222", "balance": -33333}, {"memberId": "01a1e494-8955-75a5-ad24-bb2bccab74bd", "balance": -333333}, {"memberId": "01a1e494-8955-75a5-ad24-bb2c99e331a1", "balance": -200000}, {"memberId": "01a1e494-89ba-760d-8413-308037953a24", "balance": 0}], "transfers": [{"fromMemberId": "01a1e494-8955-75a5-ad24-bb2bccab74bd", "toMemberId": "01a1e494-8953-707a-a3f9-037668238cb1", "amount": 333333}, {"fromMemberId": "01a1e494-8955-75a5-ad24-bb2c99e331a1", "toMemberId": "01a1e494-8953-707a-a3f9-037668238cb1", "amount": 200000}, {"fromMemberId": "01a1e494-8954-7867-8c59-91826be6f222", "toMemberId": "01a1e494-8953-707a-a3f9-037668238cb1", "amount": 33333}]}]
1B old invite [404, {"error": {"code": "INVITE_INVALID", "message": "Invite is invalid", "requestId": "01a1e494-8cb6-7780-b984-d529e71c672c"}}]
1B forgot [204, null]
1B reset [204, null]
1B sessions after reset [401, 401]
1B existing register [204, null]
1B new register [204, null]
1B known forgot [204, null]
1B unknown forgot [204, null]
create group 201
1A Vé cáp treo 201
1A Lẩu 201
1A Cà phê 201
1A minimized [200, {"currency": "VND", "minimized": true, "balances": [{"memberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "balance": 566666}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "balance": -33333}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "balance": -333333}, {"memberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 333333}, {"fromMemberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 200000}, {"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 33333}]}]
1A pairwise [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "balance": 566666}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "balance": -33333}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "balance": -333333}, {"memberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 133333}, {"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 233333}, {"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "toMemberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "amount": 100000}, {"fromMemberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 200000}]}]
1A taxi [201, [{"memberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 30000}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "amount": 30000}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "amount": 30000}]]
1A inactive balance [200, {"currency": "VND", "minimized": false, "balances": [{"memberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "balance": 626666}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "balance": -63333}, {"memberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "balance": -363333}, {"memberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "balance": -200000}], "transfers": [{"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 163333}, {"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 263333}, {"fromMemberId": "01a1e494-8d78-7c1b-bb35-13fb24bb8b2f", "toMemberId": "01a1e494-8d78-7c1b-bb35-13fabaf260bf", "amount": 100000}, {"fromMemberId": "01a1e494-8d79-7213-b761-475eddb8b7d9", "toMemberId": "01a1e494-8d77-70dc-9a2e-ae27c5e1a8ce", "amount": 200000}]}]
matrix GET /group minh 200
matrix GET /group lan 200
matrix GET /group ngan 200
matrix GET /group hung 404
matrix GET /group None 401
matrix GET  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members minh 200
matrix GET /members lan 200
matrix GET /members ngan 200
matrix GET /members hung 404
matrix GET /members None 401
matrix GET /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users minh 200
matrix GET /users lan 200
matrix GET /users ngan 200
matrix GET /users hung 404
matrix GET /users None 401
matrix GET /users malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /users random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions minh 200
matrix GET /transactions lan 200
matrix GET /transactions ngan 200
matrix GET /transactions hung 404
matrix GET /transactions None 401
matrix GET /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances minh 200
matrix GET /balances lan 200
matrix GET /balances ngan 200
matrix GET /balances hung 404
matrix GET /balances None 401
matrix GET /balances malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /balances random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events minh 200
matrix GET /events lan 200
matrix GET /events ngan 200
matrix GET /events hung 404
matrix GET /events None 401
matrix GET /events malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /events random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite minh 200
matrix GET /invite lan 200
matrix GET /invite ngan 403
matrix GET /invite hung 404
matrix GET /invite None 401
matrix GET /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix GET /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members minh 201
matrix POST /members lan 201
matrix POST /members ngan 403
matrix POST /members hung 404
matrix POST /members None 401
matrix POST /members malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /members random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b minh 200
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b lan 200
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b ngan 403
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b hung 404
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b None 401
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /members/01a1e494-8e30-7a92-9e4a-df4738342f2b random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions minh 201
matrix POST /transactions lan 201
matrix POST /transactions ngan 403
matrix POST /transactions hung 404
matrix POST /transactions None 401
matrix POST /transactions malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview minh 200
matrix POST /transactions/preview lan 200
matrix POST /transactions/preview ngan 403
matrix POST /transactions/preview hung 404
matrix POST /transactions/preview None 401
matrix POST /transactions/preview malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transactions/preview random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /group minh 200
matrix PATCH /group lan 403
matrix PATCH /group ngan 403
matrix PATCH /group hung 404
matrix PATCH /group None 401
matrix PATCH  malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH  random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite minh 200
matrix PATCH /invite lan 403
matrix PATCH /invite ngan 403
matrix PATCH /invite hung 404
matrix PATCH /invite None 401
matrix PATCH /invite malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /invite random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate minh 200
matrix POST /invite/rotate lan 403
matrix POST /invite/rotate ngan 403
matrix POST /invite/rotate hung 404
matrix POST /invite/rotate None 401
matrix POST /invite/rotate malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /invite/rotate random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 minh 200
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 lan 403
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 ngan 403
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 hung 404
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 None 401
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PATCH /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member minh 200
matrix PUT /me/member lan 200
matrix PUT /me/member ngan 200
matrix PUT /me/member hung 404
matrix PUT /me/member None 401
matrix POST /transfer-ownership lan 403
matrix POST /transfer-ownership ngan 403
matrix POST /transfer-ownership hung 404
matrix POST /transfer-ownership None 401
matrix POST /transfer-ownership minh 200
matrix DELETE /users/user lan 403
matrix DELETE /users/user ngan 403
matrix DELETE /users/user hung 404
matrix DELETE /users/user None 401
matrix DELETE /users/user minh 204
matrix POST /leave minh 422
matrix POST /leave lan 204
matrix POST /leave ngan 204
matrix POST /leave hung 404
matrix POST /leave None 401
matrix DELETE /members/member minh 204
matrix DELETE /members/member lan 204
matrix DELETE /members/member ngan 403
matrix DELETE /members/member hung 404
matrix DELETE /members/member None 401
matrix PUT /me/member malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix PUT /me/member random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /transfer-ownership random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /users/01a1e491-721d-7bc6-9bd3-0928fde1c128 random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix POST /leave random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e494-8e30-7a92-9e4a-df4738342f2b malformed [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
matrix DELETE /members/01a1e494-8e30-7a92-9e4a-df4738342f2b random [404, {"error": {"code": "NOT_FOUND", "message": "Resource not found"}}]
```

#### Replay 1D and parse permissions
```text
A01 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A02 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A03 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A04 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A05 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A06 200 ok match [{'memberId': 'Minh', 'amount': 75000}, {'memberId': 'Lan', 'amount': 75000}, {'memberId': 'Hùng', 'amount': 75000}, {'memberId': 'Thu', 'amount': 75000}]
A07 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A08 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A09 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A10 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A11 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A12 200 ok match [{'memberId': 'Minh', 'amount': 375000}, {'memberId': 'Lan', 'amount': 375000}, {'memberId': 'Hùng', 'amount': 375000}, {'memberId': 'Thu', 'amount': 375000}]
A13 200 ok match [{'memberId': 'Minh', 'amount': 500000}, {'memberId': 'Lan', 'amount': 500000}, {'memberId': 'Hùng', 'amount': 500000}, {'memberId': 'Thu', 'amount': 500000}]
A14 200 ok match [{'memberId': 'Minh', 'amount': 300000}, {'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 300000}]
A15 200 ok match [{'memberId': 'Minh', 'amount': 24750}, {'memberId': 'Lan', 'amount': 24750}, {'memberId': 'Hùng', 'amount': 24750}, {'memberId': 'Thu', 'amount': 24750}]
A16 200 ok match [{'memberId': 'Minh', 'amount': 2500}, {'memberId': 'Lan', 'amount': 2500}, {'memberId': 'Hùng', 'amount': 2500}, {'memberId': 'Thu', 'amount': 2500}]
A17 200 ok match [{'memberId': 'Minh', 'amount': 250}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A18 200 ok match [{'memberId': 'Minh', 'amount': 251}, {'memberId': 'Lan', 'amount': 250}, {'memberId': 'Hùng', 'amount': 250}, {'memberId': 'Thu', 'amount': 250}]
A19 200 ok match [{'memberId': 'Minh', 'amount': 400000}, {'memberId': 'Lan', 'amount': 400000}, {'memberId': 'Hùng', 'amount': 400000}, {'memberId': 'Thu', 'amount': 400000}]
A20 200 ok match [{'memberId': 'Minh', 'amount': 25000}, {'memberId': 'Lan', 'amount': 25000}, {'memberId': 'Hùng', 'amount': 25000}, {'memberId': 'Thu', 'amount': 25000}]
A21 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A22 200 ok match [{'memberId': 'Minh', 'amount': 200000}, {'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Hùng', 'amount': 200000}, {'memberId': 'Thu', 'amount': 200000}]
A23 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A24 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A25 200 ok match [{'memberId': 'Minh', 'amount': 62500}, {'memberId': 'Lan', 'amount': 62500}, {'memberId': 'Hùng', 'amount': 62500}, {'memberId': 'Thu', 'amount': 62500}]
A26 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A27 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A28 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}, {'memberId': 'Hùng', 'amount': 50000}, {'memberId': 'Thu', 'amount': 50000}]
A29 200 ok match [{'memberId': 'Minh', 'amount': 100000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 100000}, {'memberId': 'Thu', 'amount': 100000}]
A30 200 ok match [{'memberId': 'Minh', 'amount': 45000}, {'memberId': 'Lan', 'amount': 45000}, {'memberId': 'Hùng', 'amount': 45000}, {'memberId': 'Thu', 'amount': 45000}]
A31 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A32 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A33 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 120000}]
A34 200 ok match [{'memberId': 'Lan', 'amount': 22500}, {'memberId': 'Hùng', 'amount': 22500}]
A35 200 ok match [{'memberId': 'Thu', 'amount': 50000}]
A36 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A37 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A38 200 ok match [{'memberId': 'Minh', 'amount': 120000}, {'memberId': 'Lan', 'amount': 100000}, {'memberId': 'Hùng', 'amount': 80000}]
A39 200 ok match [{'memberId': 'Minh', 'amount': 150000}, {'memberId': 'Lan', 'amount': 150000}]
A40 200 ok match [{'memberId': 'Lan', 'amount': 300000}, {'memberId': 'Hùng', 'amount': 300000}, {'memberId': 'Thu', 'amount': 400000}]
A41 200 ok match [{'memberId': 'Minh', 'amount': 250000}, {'memberId': 'Lan', 'amount': 250000}, {'memberId': 'Hùng', 'amount': 250000}, {'memberId': 'Thu', 'amount': 250000}]
A42 200 ok match [{'memberId': 'Minh', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
A43 200 ok match [{'memberId': 'Lan', 'amount': 33334}, {'memberId': 'Hùng', 'amount': 33333}, {'memberId': 'Thu', 'amount': 33333}]
A44 200 ok match [{'memberId': 'Lan', 'amount': 200000}, {'memberId': 'Thu', 'amount': 300000}]
A45 200 ok match [{'memberId': 'Lan', 'amount': 1500}, {'memberId': 'Hùng', 'amount': 248500}]
A46 200 needs_input match None
A47 200 needs_input match None
A48 200 needs_input match None
A49 200 needs_input match None
A50 200 unparsed match None
A51 200 unparsed match None
A52 200 unparsed match None
A53 200 unparsed match None
A54 200 unparsed match None
A55 200 unparsed match None
A56 200 unparsed match None
A57 200 unparsed match None
A58 200 unparsed match None
A59 200 unparsed match None
A60 200 unparsed match None
A61 200 unparsed match None
A62 200 unparsed match None
A63 200 unparsed match None
A parse count 0 0
save A01 201 True
save A31 201 True
save A36 201 True
save A43 201 True
B01 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B02 200 needs_input match None
B03 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B04 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B05 200 ok match [{'memberId': 'Minh Anh', 'amount': 50000}, {'memberId': 'Minh Đức', 'amount': 50000}, {'memberId': 'Lan', 'amount': 50000}]
B06 200 needs_input match None
B07 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B08 200 ok match [{'memberId': 'Minh Đức', 'amount': 100000}, {'memberId': 'Lan', 'amount': 50000}]
B parse count 0 0
C01 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C02 200 ok match [{'memberId': 'Minh', 'amount': 60000}, {'memberId': 'Lan', 'amount': 60000}, {'memberId': 'Hùng', 'amount': 60000}]
C03 200 unparsed match None
C04 200 unparsed match None
C parse count 0 0
301 400
empty 400
outsider 404
viewer 403
matrix parse minh 200
matrix parse lan 200
matrix parse ngan 403
matrix parse hung 404
matrix parse None 401
matrix parse bad group invalid (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e495-857f-7603-91c0-325760e12c71'}})
matrix parse bad group 00000000-0000-4000-8000-000000000000 (404, {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found', 'requestId': '01a1e495-8588-7cf0-b473-ae6dcb2e1447'}})
rate sweep {200: 42, 429: 79} total successes before429 includes previous samples
gate stored count A 4
gate stored count B 0
gate stored count C 0
```

#### New 1E endpoints and group deletion permissions
```text
final matrix GET detail minh 200
final matrix GET activity minh 200
final matrix GET detail lan 200
final matrix GET activity lan 200
final matrix GET detail ngan 200
final matrix GET activity ngan 200
final matrix GET detail hung 404
final matrix GET activity hung 404
final matrix GET detail None 401
final matrix GET activity None 401
final matrix PATCH detail minh 200
final matrix PATCH detail lan 200
final matrix PATCH detail ngan 403
final matrix PATCH detail hung 404
final matrix PATCH detail None 401
final matrix DELETE detail minh 204
final matrix restore minh 200
final matrix DELETE detail lan 204
final matrix restore lan 200
final matrix DELETE detail ngan 403
final matrix restore ngan 403
final matrix DELETE detail hung 404
final matrix restore hung 404
final matrix DELETE detail None 401
final matrix restore None 401
final matrix malformed/random group GET /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group GET /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group GET /activity 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group GET /activity 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group PATCH /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group PATCH /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group DELETE /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group DELETE /transactions/01a1e494-9332-7915-a7b5-7b4933f03690 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group POST /transactions/01a1e494-9332-7915-a7b5-7b4933f03690/restore 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group POST /transactions/01a1e494-9332-7915-a7b5-7b4933f03690/restore 404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group DELETE  404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix malformed/random group DELETE  404 {'error': {'code': 'NOT_FOUND', 'message': 'Resource not found'}}
final matrix missing detail invalid minh 404
final matrix missing detail invalid lan 404
final matrix missing detail invalid ngan 404
final matrix missing detail invalid hung 404
final matrix missing detail invalid None 401
final matrix missing detail 0a4e613e-1d6f-451f-bf2f-8500d99fe43f minh 404
final matrix missing detail 0a4e613e-1d6f-451f-bf2f-8500d99fe43f lan 404
final matrix missing detail 0a4e613e-1d6f-451f-bf2f-8500d99fe43f ngan 404
final matrix missing detail 0a4e613e-1d6f-451f-bf2f-8500d99fe43f hung 404
final matrix missing detail 0a4e613e-1d6f-451f-bf2f-8500d99fe43f None 401
final matrix DELETE group lan 403
final matrix DELETE group ngan 403
final matrix DELETE group hung 404
final matrix DELETE group None 401
final matrix DELETE group minh 204
```

### Task 1E.6 — Final result
`pnpm check`: passed (236 files, all workspace typechecks Done). `pnpm build` with outbound networking denied: compiled successfully, TypeScript finished, 11/11 static pages; activity and transaction-detail routes included. Reset database migrations/seed passed before the trip. The final trip produced the required 130000/90000/110000 edited shares and 409 on the old version, Hùng's delete/restore, all five balances zero, no suggested transfers, correct actors/snapshots, removed event, later 404s and zero dependent rows. Replayed A/B/C fixed figures and refusals matched; D was 75/75 match, four matching saves and counts 4/0/0. Complete existing/new permissions matched every role, including normalized malformed/random 404s.
Final balance checker after all acceptance and matrix operations: six groups, each sum 0/mismatches 0; `All groups balanced`. The extra narrow-layout fixture was created after the gate and deleted after observation (204); balances were checked again. Production-build browser verification at exactly 360×640: featured +37.500.000 line has clientWidth=261/scrollWidth=261; document scrollWidth=345 ≤ viewport 360. An initial full-page screenshot artifact compressed layout; read-only DOM geometry and viewport capture showed normal header/card widths, so the artifact was discarded. Final viewport proof is /tmp/songphang-phase1-proof.jpg (JPEG, local artifact outside Git). The A36 card showed 300000, shares 120000/100000/80000 and excluded Thu without saving.
Extra HTTP boundary checks on the final API: 220-character description plus amount → 200 unparsed/TEXT_NOT_UNDERSTOOD; 280-digit chia count → 200 unparsed/TEXT_NOT_UNDERSTOOD; NFD input → 200 ok, response text `cà phê 180k` in NFC. All 75 original samples remained unchanged. No external request was needed.
Security review: relevant items 1,2,7,8 checked against every final changed source file and staged/run output; no secrets, raw HTML, unchecked redirect, storage, external service or new dependency. D32 choices are candidate-checked in core and still use server-authorized preview/create; no API authorization or integrity rule changed. Final diff and whitespace reviewed. No new assertion/test scripts or build artifacts are staged. Offline dependency audit remains Not verified under the no-external-service rule.
Manual-check list consolidated without obsolete stage-only instructions; README now includes the three-line Phase 1 feature list, dev mail console, optional Google variables/callback and balance command. Decisions: D31–D33. Deviations and Not verified: final summary above. Out of scope: none newly found. Unresolved: none.
Final task commit reference: `docs(run): complete phase 1 run records`; resolve its hash with the D33 command. The owner-facing completion message records the actual hash.


## Review fixes — R1–R11

Owner authorization: fix all eleven findings continuously on phase-1, one commit per finding after pnpm check; no push or merge. Each entry identifies its atomic commit by unique subject (D33); final verification records the resolved hashes.

### R1 — post-lock authorization
Approach:
- Share the existing role lookup/check between middleware and locked service writes.
- Recheck transaction/member/invite writes after acquiring the group lock.
- Keep invite-created members on an internal creation path reached only after invite validation and locking.
- Reuse the same guard in transaction changes; do not change endpoints or permission rules.
Result: pnpm check passed. Real queued HTTP operations after owner demotion: create transaction 403, create member 403, edit member 403, delete member 403; owner demotion 200 in every case. Owner create 201, outsider 404, unsigned 401; stored transaction count 1. Invite/ownership race and removal are included in the final focused replay.
Security review: items 2–6 checked against the entire diff; the shared guard preserves 404/403 and rechecks after locking. Invite member insertion remains reachable only through validated/locked joining or the guarded editor service. No security rule weakened. Self-review: PASS for the four reproduced demotion paths; final matrix pending. Not verified: device UI, no UI changed. Out of scope: none.
Manual checks: 1. Queue a write while the owner demotes the writer → 403, nothing stored. 2. Remove the writer instead → 404. 3. As owner create normally → 201; outsider → 404.
Commit reference: `fix(api): recheck group permissions inside locked writes`.

### R2 — password/session race
Approach:
- Keep the existing real-or-dummy Argon2 verification outside the account lock.
- Lock and re-read the account in the session-insertion transaction; reject a changed password hash.
- Allow existing session insertion/user lookup helpers to accept the open DbExecutor, preserving the account-first reset/change lock order.
Result: pnpm check passed. Reproduced reset/account-lock race now: reset 204; overlapping old-password login 401; resulting old session /me 401. New password login 204 and /me 200; unknown account 401; wrong password 401. No credential/token was printed. Security review: items 1–6 checked; Argon2 dummy comparison retained, hash never logged, session insert shares the account lock and transaction. Entire diff reviewed: PASS. Not verified: physical multi-device UI. Out of scope: none.
Manual checks: 1. Reset while an old-password login is pending → that login cannot create a surviving session. 2. Sign in with the new password → succeeds. 3. Wrong password/unknown email → identical invalid-credentials response.
Commit reference: `fix(auth): serialize session issuance with password changes`.

### R3 — event access revocation
Approach:
- Track only session hashes in the in-process hub; close matching streams after logout/reset/change/delete commits.
- Recheck the validated session and membership before changed-event delivery, at connect, and before every keep-alive; close on failure or expiry.
- Publish member/user/group invalidation to remaining groups after account deletion. Keep removed semantics for actual group removal, not logout.
Result: pnpm check passed. HTTP stream exercise: logout 204/closed true; change password 204/other-session closed true/current-session remained open and received changed; reset 204/closed true; database-expired session closed before the next owner changed event; delete wrong email 400, correct email 204/closed true, /me 401. Revoked stream captures contain only `: connected`, no later group event. Remaining owner received users/members/group/activity invalidation and subsequent member change. Outsider SSE 404; unsigned 401.
Security review: items 1–6 checked; hash-only hub metadata, validated session checks, post-commit revocation/publication, no extra public payload or secret output. Entire diff reviewed: PASS. Decision D34. Not verified: waiting for the idle expiry keep-alive boundary (delivery-time expiry exercised); physical UI. Out of scope: none.
Manual checks: 1. Open a group on two sessions; change password with revoke others → only the other stream closes. 2. Logout/reset/delete the account → its stream cannot receive another group event. 3. Expire a session while idle → stream closes by its next 25-second keep-alive; reconnect returns 401.
Commit reference: `fix(auth): revoke session-bound event subscriptions`.

### R4 — consistent ledger read snapshots
Approach:
- Wrap balances, transaction lists/details and group summaries in read-only repeatable-read transactions.
- Keep transaction detail hydration inside existing write transactions on its current executor, avoiding nested isolation changes.
- Use installed Drizzle PgTransactionConfig isolationLevel/accessMode; retain existing constant-query joins and all integer core calculations.
Result: pnpm check passed. Concurrent replay: 80/80 balance reads returned 200; zero inconsistent responses; 80 additional list/detail reads preserved payer/share totals while 24 edits completed. Freshly authenticated outsider balances 404; invalid cursor 400; unsigned list 401. The first outsider call used an obsolete cookie and returned 401; repeated with a current outsider session returned 404.
Security review: items 2,4–6 checked; the shared authorization middleware is unchanged, all queries remain group-scoped and parameterized, snapshots are read-only and repeatable-read. Entire diff reviewed: PASS, including in-write hydration on the original locked executor. Not verified: large-group latency is replayed in the final gate; physical UI. Out of scope: none.
Manual checks: 1. Edit an amount repeatedly while another client reads pairwise balances → every response's transfers net to its balances. 2. Read transaction details/list concurrently → payer/share totals always equal that response's amount. 3. Outsider → 404; malformed cursor → 400.
Commit reference: `fix(api): read ledger responses from consistent snapshots`.

### R5 — expired-session cache and login redirects
Approach:
- Clear/cancel identity-scoped query state before redirecting a protected screen after 401.
- Require a successful, settled /me result before login redirects an already signed-in visitor; clear retained failed /me data.
- Clear the old identity's cache on password-login success, matching the existing dev-login/logout behavior. Keep safeNext unchanged.
Result: pnpm check passed. Browser: dev-login Mới, revoke its session in the local database, click Account → stable `/login?next=%2Faccount` with email/password/submit controls, no nested next or redirect loop. Follow dev sign-in and choose Thu → `/account` shows Thu and thu@dev.songphang.local, with no previous Mới data. Invalid credentials/unknown account both 401 in R2; expired session 401 is the reproduced browser trigger. safeNext remains unchanged and rejects non-internal paths.
Security review: items 1,3,6,7 checked against the whole diff; cancelled queries cannot refill the old identity cache, no credentials/storage/redirect rules added. Self-review: PASS for expired-session recovery and identity switch. Not verified: password-form sign-in itself (API password success/refusal exercised in R2); physical device. Out of scope: none.
Manual checks: 1. Revoke an open session, then navigate → login form stays usable. 2. Sign into another account → only that account's groups/profile appear. 3. Wrong credentials stay on login; unchecked external next must resolve to `/`.
Commit reference: `fix(web): clear stale identity state after session loss`.
