# Phase 1 run — progress

Written by the implementation agent during the run. See `docs/superpowers/plans/2026-11-12-phase-1/00-overview.md`, "Run files".

For each task, under its heading: the approach note, the commit hash, the real output of the exercises, and "Unresolved" if any check still fails after three fix attempts. Tick the box only when the task is committed.

## Stage 1A — Core ledger

- [x] 1A.1 `core`: equal split and settlement suggestions
- [x] 1A.2 Database: ledger tables, integrity triggers, balance check
- [x] 1A.3 API: groups, group authorization, idempotency
- [ ] 1A.4 API: members
- [ ] 1A.5 API: create, preview and list transactions
- [ ] 1A.6 API: balances and settlements
- [ ] 1A.7 Web: group list and create group
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
