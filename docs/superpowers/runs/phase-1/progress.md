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
- [ ] 1A.8 Web: group screen and expense stream
- [ ] 1A.9 Web: manual expense form
- [ ] 1A.10 Web: balances and settlements
- [ ] 1A.11 Web: members and group settings
- [ ] 1A.12 README and stage gate 1A

### Gate 1A

Result:

Gate not passed:

Not verified:

## Stage 1B — Accounts and sharing

- [ ] 1B.1 Account foundations
- [ ] 1B.2 API: register, sign in, verify email
- [ ] 1B.3 API: forgot, reset and change password; delete account
- [ ] 1B.4 API: Google sign-in
- [ ] 1B.5 Web: sign-in, register, verify, forgot and reset screens
- [ ] 1B.6 Web: account screen
- [ ] 1B.7 API: invites, joining, member selection
- [ ] 1B.8 API: users in a group, roles, leaving, ownership
- [ ] 1B.9 API: realtime events
- [ ] 1B.10 Web: joining and inviting
- [ ] 1B.11 Web: roles, settings, leaving, read-only, realtime
- [ ] 1B.12 Stage gate 1B

### Gate 1B

Result:

Gate not passed:

Not verified:

## Stage 1C — Splits and settlements

- [ ] 1C.1 `core`: rounding function, all split methods, debt attribution
- [ ] 1C.2 API: every transaction type and split
- [ ] 1C.3 Web: transaction type, several payers, transfer and income forms
- [ ] 1C.4 Web: split editor
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
