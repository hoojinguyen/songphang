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

Result:

Gate not passed:

Not verified:

## Stage 1C — Splits and settlements

- [x] 1C.1 `core`: rounding function, all split methods, debt attribution
- [x] 1C.2 API: every transaction type and split
- [x] 1C.3 Web: transaction type, several payers, transfer and income forms
- [x] 1C.4 Web: split editor
- [ ] 1C.5 Web: settling, and transfers and income in the stream
- [ ] 1C.6 Stage gate 1C

### Gate 1C

Result:

Gate not passed:

Not verified:

## Stage 1D — Quick entry

- [ ] 1D.1 `core`: the sentence reader
- [ ] 1D.2 API: parse endpoint
- [ ] 1D.3 Web: typing box and confirmation card
- [ ] 1D.4 Web: questions and sentences that are not understood
- [ ] 1D.5 Stage gate 1D

### Gate 1D

Result:

Gate not passed:

Not verified:

## Stage 1E — History and polish

- [ ] 1E.1 API: read, edit, delete and restore a transaction
- [ ] 1E.2 API: activity feed and group deletion
- [ ] 1E.3 Web: edit, delete with undo, conflict
- [ ] 1E.4 Web: history and deleting a group
- [ ] 1E.5 Web: offline state, new-item pill, motion
- [ ] 1E.6 Non-functional checks and final gate

### Final gate

Result:

Gate not passed:

Not verified:

## Final summary


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
