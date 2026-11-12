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
