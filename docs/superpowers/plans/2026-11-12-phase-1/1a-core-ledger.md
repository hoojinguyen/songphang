# Phase 1 — Stage 1A: Core Ledger

> Part of the phase 1 plan. Read `00-overview.md` first: it holds the global constraints, the per-task procedure, the gate procedure and the run files. Task references inside this file ("Task 3") mean this stage's tasks (1A.3).

**Stage goal:** One signed-in person can keep the whole ledger for a group on the local machine: create a group, name its members, record equally split expenses, and see every balance and the suggested settlements.

**Architecture:** A new dependency-free `packages/core` holds all money arithmetic (equal split, settlement suggestions). The API gains a service layer: routes validate with `contract` schemas, one shared middleware authorizes every `groupId` route, services open a database transaction, call `core`, write rows and an activity record. Balances are never stored; they are summed on read. The web app adds seven screens that read through TanStack Query and re-fetch after each of their own writes; realtime arrives in stage 1B.

**Spec:** `docs/03-srs.md` (FR-1.10–1.12, 1.20–1.23, 1.25, 1.40, 1.41, 1.47–1.50, 1.60–1.63, NFR-1.1–1.3, 1.5, 1.7, 1.8, 1.11), `docs/04-sad.md` (sections 4, 5, 6.2, 6.4, 7), `docs/05-database-design.md`, `docs/05-api-spec.md`, `docs/06-ux-ui/user-flows.md` (flows A, C2, F, H; sections 5–8).

## Decisions for this stage

The project owner decided these on 2026-11-12. Where they differ from `docs/`, this plan wins (AGENTS.md section 2).

1. **FR-1.63 moves from 1C to 1A.** The "Gộp nợ" switch works fully in 1A: on = fewest transfers, off = pairwise debts.
2. **The member palette stays at 4 shapes × 4 colors (16 pairs).** The 6 × 8 extension is deferred. The 17th member reuses pairs from the start.
3. **Editing and deleting transactions arrive in stage 1E.** This stage only creates and lists.

Decisions made by the advisor and approved with the plan:

4. **Interim S4 wording.** The sentence parser arrives in 1D, so the empty state and the bottom bar use the interim strings in Task 8 and show no sample sentences.
5. **Activity records are written from 1A** (`activity_log`), so history is complete when its screen arrives in 1E. No endpoint reads them yet.
6. **`Idempotency-Key` is required** on the three create endpoints (`POST /groups`, `POST …/members`, `POST …/transactions`).
7. **Group membership of payers and sharers is enforced by the database trigger** of Task 2, not by adding `group_id` to the payer and share tables.
8. **The group list is ordered newest group first.** The newest group is the large accent card.
9. **A member linked to a user shows no "Xoá" or "Ngừng hoạt động" action in S10.** "Tôi là người này" cannot be re-chosen until 1B (FR-1.24). The API still follows FR-1.22.
10. **`defaultWeight` is accepted by the API (FR-1.21) but has no control in the web app** until weighted splits arrive in 1C.
11. **Hidden until their milestone:** invite card, QR scan button, "Mời bạn" link, "Chỉ xem" state, "Đã nhận"/"Đã trả"/"Nhắc" buttons, transaction type switch, "đổi cách chia", "Lịch sử", every settings row except name and "Gộp nợ".

## Review Focus

Failure modes the spec implies but states only briefly. Each has an exercise step in the task that owns it; the reviewer re-runs them.

1. **Leaking a group to an outsider.** Signed in as Lan, every `/groups/{Minh's group}/…` route returns 404 with the same body as a random UUID, for reads and writes alike. → Tasks 3, 4, 5, 6.
2. **Double submit.** Sending the same `POST …/transactions` twice with one `Idempotency-Key` stores one transaction and returns the same body twice; the same key with a different body returns 409. Double-clicking "Lưu khoản chi" stores one expense. → Tasks 3, 5, 9.
3. **Rounding loses or invents a đồng.** 100.000 đ among three people stores 33.334 + 33.333 + 33.333, and the group's balances still sum to 0. → Tasks 1, 5, 6.
4. **A broken money invariant reaching disk.** A transaction whose shares or payers do not sum to its amount, or that references a member of another group, cannot be committed even with hand-written SQL. → Task 2.
5. **A member with money history disappearing.** Deleting a member who has transactions returns 422; deactivating keeps them in old transactions and in balances. → Tasks 4, 6, 11.

---

## File Structure

```
packages/
  core/                          NEW package @songphang/core
    src/split.ts                 splitEqually
    src/settlements.ts           suggestMinimizedSettlements, netPairwiseDebts
    src/index.ts
  db/
    src/schema.ts                unchanged (users, sessions)
    src/schema-groups.ts         groups, members, group_users
    src/schema-transactions.ts   transactions, transaction_payers, transaction_shares
    src/schema-records.ts        activity_log, idempotency_keys
    src/groups.ts                group and membership queries
    src/members.ts               member queries
    src/transactions.ts          transaction queries
    src/balances.ts              balance and pair-debt queries
    src/activity.ts              insertActivity
    src/idempotency.ts           idempotency key queries
    src/check-balances.ts        `pnpm db:check-balances`
    drizzle/                     two new migrations (tables; integrity triggers)
  contract/
    src/error.ts                 more error codes
    src/member.ts                MemberDto, MEMBER_APPEARANCES, member requests
    src/group.ts                 GroupDto, GroupSummaryDto, group requests
    src/transaction.ts           transaction requests and DTOs
    src/balance.ts               BalancesResponse
apps/
  api/src/
    auth/group-access.ts         requireGroupRole
    idempotency.ts               runIdempotent
    services/groups.ts
    services/members.ts
    services/transactions.ts
    services/balances.ts
    routes/groups.ts
    routes/members.ts
    routes/transactions.ts
    routes/balances.ts
  web/src/
    lib/money.ts                 the only money formatting functions
    lib/request.ts               jsonRequest
    lib/use-session-guard.ts     redirect on 401
    lib/groups.ts  members.ts  transactions.ts  balances.ts     data hooks
    components/ui/Icon.tsx  ScreenHeader.tsx  LoadError.tsx
    components/groups/           group list cards
    components/feed/             expense stream pieces
    components/expense-form/     form pieces
    components/balances/         settlement cards, balance bars
    components/members/          member rows
    app/page.tsx                 S2 (replace empty state)
    app/groups/new/page.tsx      S3
    app/g/[groupId]/page.tsx     S4
    app/g/[groupId]/balances/page.tsx   S5
    app/g/[groupId]/tx/new/page.tsx     S8
    app/g/[groupId]/members/page.tsx    S10
    app/g/[groupId]/settings/page.tsx   S11
```

The URL segment `tx` is fixed by `docs/06-ux-ui/user-flows.md`; identifiers in code still say `transaction`.

---

### Task 1A.1: `packages/core` — equal split and settlement suggestions

**Files:**
- Create: `packages/core/package.json`, `packages/core/tsconfig.json`, `packages/core/src/split.ts`, `packages/core/src/settlements.ts`, `packages/core/src/index.ts`

**Interfaces:**
- Consumes: nothing. `package.json` has no `dependencies`; follow `packages/contract` for `exports`, `type`, and the `typecheck` script.
- Produces (exported from `@songphang/core`):
  - `type Share = { memberId: string; amount: number }`
  - `splitEqually(amount: number, memberIdsByPosition: readonly string[]): Share[]` — one entry per id, same order. Each gets `(amount - amount % n) / n`; the first `amount % n` ids get one more đồng (FR-1.56).
  - `type MemberBalance = { memberId: string; balance: number }` — positive is owed money, negative owes.
  - `type Settlement = { fromMemberId: string; toMemberId: string; amount: number }`
  - `suggestMinimizedSettlements(balancesByPosition: readonly MemberBalance[]): Settlement[]` — repeat: take the debtor with the most negative balance and the creditor with the most positive balance (ties: earlier in the input), transfer the smaller of the two absolute values, until all are zero (SAD 6.4). Never more than `n − 1` settlements (FR-1.62).
  - `type PairDebt = { debtorMemberId: string; creditorMemberId: string; amount: number }`
  - `netPairwiseDebts(debts: readonly PairDebt[], memberIdsByPosition: readonly string[]): Settlement[]` — ignore entries where debtor equals creditor; add up each unordered pair; emit one settlement from the net debtor to the net creditor; drop pairs that net to zero; order by debtor position, then creditor position (FR-1.63).
  - All three throw `RangeError` on input they cannot handle: an amount that is not a safe integer or is `< 1`; an empty or duplicated id list; balances that do not sum to 0; an id in `debts` that is missing from `memberIdsByPosition`. No function mutates its input.

- [ ] **Step 1: Create the package and write the three functions**

- [ ] **Step 2: `pnpm install && pnpm check`**

Expected: no errors; `pnpm -r typecheck` lists `@songphang/core`.

- [ ] **Step 3: Exercise — equal split table (Review Focus 3)**

Run each row with `pnpm --filter @songphang/core exec tsx -e "import('./src/index.ts').then(m => console.log(JSON.stringify(m.splitEqually(<amount>, <ids>))))"` and paste the output in the report.

| Amount | Ids | Expected amounts |
|---|---|---|
| 300000 | a, b, c | 100000, 100000, 100000 |
| 100000 | a, b, c | 33334, 33333, 33333 |
| 100 | a, b, c | 34, 33, 33 |
| 10 | a, b, c, d | 3, 3, 2, 2 |
| 2 | a, b, c | 1, 1, 0 |
| 1 | a | 1 |
| 999999999999 | a … g (7 ids) | 142857142857 each |
| 0 | a | `RangeError` |
| 1.5 | a | `RangeError` |
| 1000 | (empty) | `RangeError` |
| 1000 | a, a | `RangeError` |

- [ ] **Step 4: Exercise — settlement tables**

`suggestMinimizedSettlements`, input in position order:

| Balances | Expected |
|---|---|
| a +450000, b −120000, c −250000, d −80000 | c→a 250000; b→a 120000; d→a 80000 |
| a +100, b +100, c −200 | c→a 100; c→b 100 |
| a −50, b −50, c +100 | a→c 50; b→c 50 |
| a +70, b +30, c −60, d −40 | c→a 60; d→b 30; d→a 10 |
| a 0, b 0 | (empty) |
| a +10, b −5 | `RangeError` |

`netPairwiseDebts`, member order a, b, c:

| Debts (debtor→creditor amount) | Expected |
|---|---|
| b→a 100; a→b 30; c→a 50; a→a 20 | b→a 70; c→a 50 |
| b→a 90; c→b 90 | b→a 90; c→b 90 |
| a→b 40; b→a 40 | (empty) |
| x→a 10 | `RangeError` |

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(core): add equal split and settlement suggestions"
```

**Manual checks for the project owner**
1. Run the 100000 / a, b, c row → `33334, 33333, 33333`; the three add up to 100000.
2. Run the second `netPairwiseDebts` row and the matching minimized case (a +90, b 0, c −90) → pairwise gives two transfers, minimized gives one (c→a 90). This is the visible difference the "Gộp nợ" switch makes.
3. Run a `RangeError` row → the command prints the error and no amounts.

---

### Task 1A.2: Database — ledger tables, integrity triggers, balance check command

**Files:**
- Create: `packages/db/src/schema-groups.ts`, `packages/db/src/schema-transactions.ts`, `packages/db/src/schema-records.ts`, `packages/db/src/check-balances.ts`
- Create (generated): one table migration and one custom migration in `packages/db/drizzle/`
- Modify: `packages/db/drizzle.config.ts` (include the new schema files), `packages/db/src/index.ts`, `packages/db/package.json` (script `check-balances`), root `package.json` (script `db:check-balances`)

**Interfaces:**
- Consumes: `users` from `schema.ts`.
- Produces (exported from `@songphang/db`): tables `groups`, `members`, `groupUsers`, `transactions`, `transactionPayers`, `transactionShares`, `activityLog`, `idempotencyKeys`; `type DbExecutor` — a `Db` or an open Drizzle transaction, accepted by every query function from now on; root script `pnpm db:check-balances`.

Columns follow `docs/05-database-design.md` section 3 exactly. Constraints to declare, beyond `NOT NULL` and foreign keys listed there:

| Table | Constraints |
|---|---|
| `groups` | `name` length 1–80; `currency` default `'VND'`; `minimize_debts` default `true`; `invite_token` unique; `invite_active` default `true`; `default_role` in (`editor`, `viewer`) default `editor` |
| `members` | `name` length 1–50; `default_weight numeric(6,2)` default 1, `>= 0`; `shape` in (`circle`, `diamond`, `squircle`, `leaf`); `color` in (`mint`, `sky`, `coral`, `lilac`); `UNIQUE (group_id, position)` |
| `group_users` | PK `(group_id, user_id)`; `role` in (`owner`, `editor`, `viewer`); `UNIQUE (group_id, member_id)`; partial unique index on `(group_id) WHERE role = 'owner'` |
| `transactions` | `type` in (`expense`, `transfer`, `income`); `description` length 1–200; `amount` between 1 and 999999999999; `category` null or in (`food`, `transport`, `lodging`, `shopping`, `entertainment`, `bills`, `other`); `split_method` in (`equal`, `exact`, `shares`, `percent`); `version` default 1; index `(group_id, occurred_at DESC, id DESC) WHERE deleted_at IS NULL` |
| `transaction_payers` | PK `(transaction_id, member_id)`; `amount > 0`; `member_id` `ON DELETE RESTRICT` |
| `transaction_shares` | PK `(transaction_id, member_id)`; `amount >= 0`; `member_id` `ON DELETE RESTRICT` |
| `activity_log` | index `(group_id, created_at DESC)`; `actor_user_id` `ON DELETE SET NULL` |
| `idempotency_keys` | PK `(user_id, key)` |

`bigint` money columns use Drizzle's number mode. `invite_token`, `invite_active` and `default_role` exist now so that 1B needs no backfill; nothing reads them in 1A.

- [ ] **Step 1: Write the three schema files; update `drizzle.config.ts` and `index.ts`**

- [ ] **Step 2: Generate the table migration**

Run: `pnpm --filter @songphang/db exec drizzle-kit generate`
Expected: one new SQL file creating eight tables with every constraint in the table above. Read it; do not edit it.

- [ ] **Step 3: Add the integrity triggers as a custom migration**

Create an empty custom migration with drizzle-kit (check the installed version's flag for custom migrations in `node_modules/drizzle-kit`), then put this SQL in it:

```sql
CREATE FUNCTION assert_transaction_integrity(checked_id uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  expected_amount bigint;
  owning_group uuid;
  paid_total bigint;
  shared_total bigint;
  outside_members integer;
BEGIN
  SELECT amount, group_id INTO expected_amount, owning_group
  FROM transactions WHERE id = checked_id;
  IF NOT FOUND THEN
    RETURN; -- the transaction was removed in this same database transaction
  END IF;
  SELECT COALESCE(SUM(amount), 0)::bigint INTO paid_total
  FROM transaction_payers WHERE transaction_id = checked_id;
  SELECT COALESCE(SUM(amount), 0)::bigint INTO shared_total
  FROM transaction_shares WHERE transaction_id = checked_id;
  IF paid_total <> expected_amount THEN
    RAISE EXCEPTION 'transaction payers total differs from amount'
      USING ERRCODE = 'check_violation';
  END IF;
  IF shared_total <> expected_amount THEN
    RAISE EXCEPTION 'transaction shares total differs from amount'
      USING ERRCODE = 'check_violation';
  END IF;
  SELECT COUNT(*) INTO outside_members
  FROM (
    SELECT member_id FROM transaction_payers WHERE transaction_id = checked_id
    UNION ALL
    SELECT member_id FROM transaction_shares WHERE transaction_id = checked_id
  ) used
  JOIN members ON members.id = used.member_id
  WHERE members.group_id <> owning_group;
  IF outside_members > 0 THEN
    RAISE EXCEPTION 'transaction references a member of another group'
      USING ERRCODE = 'check_violation';
  END IF;
END $$;
--> statement-breakpoint
CREATE FUNCTION check_transaction_row() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM assert_transaction_integrity(NEW.id);
  RETURN NULL;
END $$;
--> statement-breakpoint
CREATE FUNCTION check_transaction_line() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP <> 'INSERT' THEN
    PERFORM assert_transaction_integrity(OLD.transaction_id);
  END IF;
  IF TG_OP <> 'DELETE' THEN
    PERFORM assert_transaction_integrity(NEW.transaction_id);
  END IF;
  RETURN NULL;
END $$;
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transactions_integrity
AFTER INSERT OR UPDATE OF amount, group_id ON transactions
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_row();
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transaction_payers_integrity
AFTER INSERT OR UPDATE OR DELETE ON transaction_payers
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_line();
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transaction_shares_integrity
AFTER INSERT OR UPDATE OR DELETE ON transaction_shares
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_line();
```

The triggers are deferred to commit so a service can insert the transaction, its payers and its shares in any order inside one database transaction.

- [ ] **Step 4: Write `check-balances.ts`**

A script in the style of `seed.ts`. It runs two read-only queries over transactions where `deleted_at IS NULL` and prints one line per group: group id, name, sum of all member balances (formula in `docs/05-database-design.md` section 7), and the number of transactions whose payer total or share total differs from `amount`. It ends with `All groups balanced` and exit code 0, or `IMBALANCE FOUND` and exit code 1 when any sum is not 0 or any count is not 0. With no groups it prints `No groups` and exits 0.

- [ ] **Step 5: `pnpm check`**

- [ ] **Step 6: Exercise — migrations and constraints (Review Focus 4)**

Run: `pnpm db:migrate && pnpm db:migrate`
Expected: both exit 0.

In `docker compose exec db psql -U songphang`, create a group, two members of that group, one member of a second group, then paste the result of each case into the report:

| Case (one `BEGIN … COMMIT` each) | Expected |
|---|---|
| Transaction 300000, one payer 300000, shares 150000 + 150000 | `COMMIT` succeeds |
| Same, shares 150000 + 140000 | `COMMIT` fails: shares total differs |
| Same, payer 200000 | `COMMIT` fails: payers total differs |
| Shares total correct but one share belongs to the other group's member | `COMMIT` fails: member of another group |
| Transaction with `amount = 0` | fails immediately on the `CHECK` |
| A second `group_users` row with `role = 'owner'` for the same group | fails on the partial unique index |
| `DELETE FROM members` for a member used in the committed transaction | fails on the foreign key |
| After the first case: `UPDATE transaction_shares SET amount = 1 WHERE …; COMMIT` | `COMMIT` fails |

Run: `pnpm db:check-balances`
Expected: one line for the group with sum `0` and `0` mismatches; `All groups balanced`; exit code 0.

Clean up the rows created by hand before finishing.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(db): add ledger tables, integrity triggers, and balance check"
```

**Manual checks for the project owner**
1. Run `pnpm db:migrate` → no error. Run `docker compose exec db psql -U songphang -c "\dt"` → ten tables.
2. Run `pnpm db:check-balances` → `No groups` (or one balanced line per group) and exit code 0. This command stays valid for every later milestone; run it whenever you want to confirm NFR-1.2.
3. Repeat the "shares 150000 + 140000" case from Step 6 → the `COMMIT` is refused.

---

### Task 1A.3: API — groups, group authorization, idempotency

**Files:**
- Create: `packages/contract/src/member.ts`, `packages/contract/src/group.ts`, `packages/db/src/groups.ts`, `packages/db/src/members.ts`, `packages/db/src/balances.ts`, `packages/db/src/activity.ts`, `packages/db/src/idempotency.ts`, `apps/api/src/auth/group-access.ts`, `apps/api/src/idempotency.ts`, `apps/api/src/services/groups.ts`, `apps/api/src/routes/groups.ts`
- Modify: `packages/contract/src/error.ts`, `packages/contract/src/index.ts`, `packages/db/src/index.ts`, `apps/api/package.json` (add `@songphang/core`), `apps/api/src/app.ts`, `apps/api/src/server.ts` (idempotency clean-up timer)

**Interfaces:**
- Consumes: tables and `DbExecutor` (Task 2); `requireUser`, `requireSameOrigin`, `AppError`, `AppDeps`, `AppEnv` (phase 0).
- Produces — contract:
  - `ErrorCode` gains `FORBIDDEN`, `IDEMPOTENCY_KEY_REUSED`, `MEMBER_NOT_IN_GROUP`, `MEMBER_HAS_TRANSACTIONS`, `PAYER_TOTAL_MISMATCH`.
  - `MemberShapeCode` = `circle | diamond | squircle | leaf`; `MemberColorCode` = `mint | sky | coral | lilac`.
  - `MEMBER_APPEARANCES: ReadonlyArray<{ shape: MemberShapeCode; color: MemberColorCode }>` — 16 pairs; index `i` is shape `[circle, diamond, squircle, leaf][i % 4]` with color `[mint, sky, coral, lilac][(i + floor(i / 4)) % 4]`. The first four are circle/mint, diamond/sky, squircle/coral, leaf/lilac.
  - `nextMemberAppearance(usedPairs: ReadonlyArray<{ shape; color }>, position: number): { shape; color }` — the first entry of `MEMBER_APPEARANCES` not in `usedPairs`; when all 16 are used, entry `position % 16` (FR-1.25). It lives in `contract/src/member.ts` beside the list so the API assigns with it and the web app previews with it.
  - `MemberName` = trimmed string, 1–50 characters. `GroupName` = trimmed string, 1–80 characters.
  - `MemberDto` = `{ id: uuid; name: string; active: boolean; defaultWeight: string; position: number; shape: MemberShapeCode; color: MemberColorCode; isMe: boolean }` — `isMe` is true for the member linked to the caller.
  - `GroupRole` = `owner | editor | viewer`.
  - `GroupDto` = `{ id: uuid; name: string; currency: "VND"; minimizeDebts: boolean; role: GroupRole; myMemberId: uuid | null; createdAt: string }`
  - `GroupSummaryDto` = `{ id: uuid; name: string; currency: "VND"; memberCount: number; previewMembers: Array<{ id; name; shape; color }>; myBalance: number }` — `previewMembers` is the first four members by position; `myBalance` is 0 when the caller has no linked member.
  - `GroupsResponse` = `{ groups: GroupSummaryDto[] }`; `GroupResponse` = `{ group: GroupDto }`
  - `CreateGroupRequest` = `{ name: GroupName; memberNames: MemberName[] }` — `memberNames` defaults to `[]`, at most 99 entries.
  - `UpdateGroupRequest` = `{ name?: GroupName; minimizeDebts?: boolean }` — at least one field.
  - `IdempotencyKeyHeader` = string, 8–128 characters of `[A-Za-z0-9_-]`.
- Produces — API:
  - `requireGroupRole(deps: AppDeps, minimumRole: GroupRole)` — middleware placed after `requireUser`; parses `groupId`; sets `c.var.groupAccess: { groupId: string; role: GroupRole; memberId: string | null }`. Rank: `viewer < editor < owner`.
  - `runIdempotent(deps, input: { userId: string; key: string; requestHash: string }, operation: (transaction: DbExecutor) => Promise<{ status: 200 | 201; body: unknown }>): Promise<{ status: number; body: unknown }>`
  - `hashRequest(method: string, path: string, body: unknown): string` — SHA-256 hex from `node:crypto` over method, path and the JSON of the parsed body.
- Produces — db: `insertActivity(executor, input: { groupId; actorUserId; action; entityType; entityId; summary; before?; after? })`; `findGroupAccess(executor, groupId, userId)`; `listMemberBalances(executor, groupId): Promise<MemberBalance-shaped rows ordered by position>` using the query in `docs/05-database-design.md` section 7 with the sum cast to `bigint` and mapped to a number. The group list must not run one query per group for balances or preview members.

Endpoints:

| Method | Path | Access | Behavior |
|---|---|---|---|
| POST | `/groups` | signed in; `Idempotency-Key` | One database transaction: insert the group (`invite_token` = 32 bytes from `node:crypto`, base64url; `created_by` = caller), insert the creator's member (name = the user's name, position 0), insert `memberNames` at positions 1…n, insert `group_users` (`owner`, linked to the creator's member), insert one `activity_log` row (`create`, `group`). Each member gets `nextMemberAppearance`. Returns 201 `GroupResponse`. |
| GET | `/groups` | signed in | 200 `GroupsResponse`, ordered `created_at DESC, id DESC`. |
| GET | `/groups/{groupId}` | viewer | 200 `GroupResponse`. |
| PATCH | `/groups/{groupId}` | owner | Updates the given fields and `updated_at`; one `activity_log` row (`update`, `group`) with `before` and `after` of the changed fields. 200 `GroupResponse`. |

`runIdempotent` behavior:

| Situation | Result |
|---|---|
| No stored row for `(userId, key)` younger than 24 hours | Open a database transaction, run `operation`, insert the key row with the response in the same transaction, return the response |
| Stored row with the same `requestHash` | Return the stored status and body; `operation` does not run |
| Stored row with a different `requestHash` | 409 `IDEMPOTENCY_KEY_REUSED` |
| Two concurrent requests with the same new key | The second insert hits the primary key, its transaction rolls back, and it then answers from the stored row as above |
| Header missing or malformed | 400 `VALIDATION_FAILED` |

Also in this task: apply Hono's built-in body limit middleware at 100 KB to every route (larger bodies get 400 `VALIDATION_FAILED`); in `server.ts`, delete `idempotency_keys` rows older than 24 hours at start-up and once an hour on an unref'd timer.

- [ ] **Step 1: Write the contract schemas and the db query files**

- [ ] **Step 2: Write `group-access.ts`, `idempotency.ts`, `services/groups.ts`, `routes/groups.ts`; register in `app.ts`**

- [ ] **Step 3: `pnpm check`**

- [ ] **Step 4: Exercise — normal path**

Sign in as Minh with the phase 0 dev login (`-c /tmp/minh.txt`), then:

`curl -si -b /tmp/minh.txt -X POST localhost:4000/api/v1/groups -H 'content-type: application/json' -H 'Idempotency-Key: task3-key-0001' -d '{"name":"Đà Lạt 12/2026","memberNames":["Lan","Hùng","Thu"]}'`
Expected: 201; `role` is `owner`; `myMemberId` is a UUID.

`curl -s -b /tmp/minh.txt localhost:4000/api/v1/groups`
Expected: one group; `memberCount` 4; `previewMembers` are Minh circle/mint, Lan diamond/sky, Hùng squircle/coral, Thu leaf/lilac; `myBalance` 0.

`PATCH` the group with `{"minimizeDebts":false}` → 200 with `minimizeDebts: false`. `PATCH` with `{}` → 400.

`docker compose exec db psql -U songphang -c "select action, entity_type, summary from activity_log order by created_at"` → a `create` row and an `update` row.

- [ ] **Step 5: Exercise — outsider and idempotency (Review Focus 1, 2)**

Sign in as Lan (`-c /tmp/lan.txt`). Each of these must return 404 `NOT_FOUND`, and the bodies must be identical apart from `requestId`:

- `GET /groups/<Minh's group id>` as Lan
- `PATCH /groups/<Minh's group id>` as Lan with `{"name":"x"}`
- `GET /groups/0193a1b2-0000-7000-8000-00000000ffff` as Lan
- `GET /groups/not-a-uuid` as Lan

Lan's `GET /groups` returns an empty list. Without a cookie, `GET /groups` returns 401.

Repeat the Step 4 `POST` with the same key and body → 201 with the same `id`; `select count(*) from groups` is still 1. Same key, different `name` → 409 `IDEMPOTENCY_KEY_REUSED`. No `Idempotency-Key` → 400. `POST` with `Origin: http://evil.example` → 400. A 200 KB body → 400.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(api): add groups, group authorization, and idempotent creates"
```

**Manual checks for the project owner**
1. Run the Step 4 `POST` → a group is returned. Open `http://localhost:4000/api/v1/groups` in the browser where you are signed in as Minh → the group with four preview members.
2. Sign in as Lan in a private window and open the same address → an empty list.
3. As Lan, open `http://localhost:4000/api/v1/groups/<id of Minh's group>` → `NOT_FOUND`, the same answer as for a made-up id.
4. Run the Step 4 `POST` twice with the same key → the same group id both times.

---

### Task 1A.4: API — members

**Files:**
- Create: `apps/api/src/services/members.ts`, `apps/api/src/routes/members.ts`
- Modify: `packages/contract/src/member.ts`, `packages/contract/src/index.ts`, `packages/db/src/members.ts`, `packages/db/src/index.ts`, `apps/api/src/app.ts`

**Interfaces:**
- Consumes: `requireGroupRole`, `runIdempotent`, `hashRequest`, `nextMemberAppearance`, `insertActivity`, `MemberDto`, `MemberName` (Task 3).
- Produces — contract:
  - `MembersResponse` = `{ members: MemberDto[] }` ordered by `position`; `MemberResponse` = `{ member: MemberDto }`
  - `CreateMemberRequest` = `{ name: MemberName }`
  - `UpdateMemberRequest` = `{ name?: MemberName; defaultWeight?: string; active?: boolean }` — at least one field; `defaultWeight` matches `^\d{1,4}(\.\d{1,2})?$`.

Endpoints:

| Method | Path | Access | Behavior |
|---|---|---|---|
| GET | `/groups/{groupId}/members` | viewer | 200 `MembersResponse`, active and inactive. |
| POST | `/groups/{groupId}/members` | editor; `Idempotency-Key` | Lock the group row (`SELECT … FOR UPDATE`), then position = highest position + 1, appearance from `nextMemberAppearance` over the pairs in use. A group that already has 100 members gets 400 `VALIDATION_FAILED` with `details.members`. Activity row (`create`, `member`). 201 `MemberResponse`. |
| PATCH | `/groups/{groupId}/members/{memberId}` | editor | Updates the given fields; shape, color and position never change. Activity row (`update`, `member`) with `before` and `after`. 200 `MemberResponse`. |
| DELETE | `/groups/{groupId}/members/{memberId}` | editor | A member that appears in any `transaction_payers` or `transaction_shares` row (deleted transactions included) gets 422 `MEMBER_HAS_TRANSACTIONS`. Otherwise delete; activity row (`delete`, `member`). 204. |

A `memberId` that is not a UUID or does not belong to `groupId` gets 404 `NOT_FOUND`.

- [ ] **Step 1: Write the contract additions, queries, service and routes**

- [ ] **Step 2: `pnpm check`**

- [ ] **Step 3: Exercise**

As Minh, in the group from Task 3:

- `GET …/members` → four members, positions 0–3, `isMe` true only for Minh.
- `POST …/members` with `{"name":"  Bác Tư  "}` → 201; name `Bác Tư`; position 4; appearance circle/sky.
- Add members until the group has 17 → the 17th has circle/mint again (the pair at index `16 % 16`).
- `PATCH` Lan with `{"name":"Lan Anh"}` → name changes; shape and color unchanged.
- `PATCH` Hùng with `{"active":false}` → `active: false`; still listed.
- `PATCH` with `{"defaultWeight":"1.5"}` → `"1.50"`. With `{"defaultWeight":"-1"}` → 400. With `{"name":""}` → 400. With `{}` → 400.
- `DELETE` Bác Tư (position 4, no transactions) → 204; gone from the list. Add one more member → it gets circle/sky, the pair Bác Tư freed.
- `DELETE` a member of another group using Minh's group in the path → 404.
- As Lan: `GET`, `POST`, `PATCH`, `DELETE` on Minh's group → all 404 (Review Focus 1).
- `POST` twice with one `Idempotency-Key` → one new member.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(api): add member endpoints"
```

**Manual checks for the project owner**
1. Open `http://localhost:4000/api/v1/groups/<id>/members` as Minh → the member list with a `shape` and `color` each.
2. Run the `POST` from Step 3 → the new member appears at the end with a pair nobody else has.
3. Run the `PATCH` that renames Lan → the name changes, `shape` and `color` do not.
4. Open the same address as Lan → `NOT_FOUND`.

---

### Task 1A.5: API — create, preview and list transactions

**Files:**
- Create: `packages/contract/src/transaction.ts`, `packages/db/src/transactions.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/routes/transactions.ts`
- Modify: `packages/contract/src/index.ts`, `packages/db/src/index.ts`, `apps/api/src/app.ts`

**Interfaces:**
- Consumes: `splitEqually` (Task 1); `requireGroupRole`, `runIdempotent`, `hashRequest`, `insertActivity` (Task 3).
- Produces — contract:
  - `MoneyAmount` = integer, 1 to 999_999_999_999.
  - `TransactionCategory` = `food | transport | lodging | shopping | entertainment | bills | other`.
  - `EqualSplitInput` = `{ method: "equal"; members: uuid[] }` — 1 to 100 unique ids.
  - `CreateTransactionRequest` = `{ type: "expense"; description: string (trimmed, 1–200); amount: MoneyAmount; occurredAt: ISO datetime; category: TransactionCategory | null; payers: Array<{ memberId: uuid; amount: MoneyAmount }> (exactly one entry in 1A); split: EqualSplitInput }`
  - `ShareDto` = `{ memberId: uuid; amount: number }`
  - `TransactionDto` = `{ id; type; description; amount; currency: "VND"; occurredAt; category; payers: Array<{ memberId; amount }>; shares: ShareDto[]; split: EqualSplitInput; version: number; createdBy: { id: uuid; name: string }; createdAt; updatedAt; deletedAt: string | null }` (shape from `docs/05-api-spec.md` section 3).
  - `TransactionResponse` = `{ transaction: TransactionDto }`; `PreviewTransactionResponse` = `{ shares: ShareDto[] }`
  - `TransactionsQuery` = `{ cursor?: string; limit?: integer 1–200, default 50 }`; `TransactionsResponse` = `{ transactions: TransactionDto[]; nextCursor: string | null }`

Endpoints:

| Method | Path | Access | Behavior |
|---|---|---|---|
| POST | `/groups/{groupId}/transactions/preview` | editor | Same body as create. Validates and computes exactly as create, writes nothing. 200 `PreviewTransactionResponse`. |
| POST | `/groups/{groupId}/transactions` | editor; `Idempotency-Key` | One database transaction: validate, compute shares, insert `transactions` (`currency` = the group's, `split_method` `equal`, `split_input` = the `split` as sent, `created_by` and `updated_by` = caller), `transaction_payers`, `transaction_shares`, and an activity row (`create`, `transaction`, summary = description). 201 `TransactionResponse`. |
| GET | `/groups/{groupId}/transactions` | viewer | Transactions with `deleted_at IS NULL`, ordered `occurred_at DESC, id DESC`, keyset-paginated. `nextCursor` is null on the last page. |

Validation shared by preview and create, in this order:

| Check | Failure |
|---|---|
| Every payer and every split member belongs to the group | 400 `MEMBER_NOT_IN_GROUP` |
| Payer amounts sum to `amount` | 400 `PAYER_TOTAL_MISMATCH` with `details.expected` and `details.actual` |

Shares are `splitEqually(amount, <split members sorted by their position>)`. Inactive members are accepted when sent explicitly (FR-1.23 only removes them from defaults). The cursor is the base64url of the last row's `occurredAt` and `id`; a cursor that does not decode to a valid pair gets 400 `VALIDATION_FAILED`. The list query must not issue one query per transaction for payers and shares.

- [ ] **Step 1: Write the contract schemas, queries, service and routes**

- [ ] **Step 2: `pnpm check`**

- [ ] **Step 3: Exercise — normal path and rounding (Review Focus 3)**

Use a fresh group: Minh, Lan, Hùng, Thu.

- Preview 180000, payer Minh, split all four → four shares of 45000; `select count(*) from transactions` unchanged.
- Create 100000 "Cà phê", payer Minh, split Minh, Lan, Hùng → shares 33334, 33333, 33333 in position order; `version` 1; `createdBy.name` Minh; `split` echoes the request.
- Create the same split with the member ids sent in reverse order → the same three shares (order of the request does not move the extra đồng).
- Create 300000 "Lẩu", payer Lan, split all four, `category: "food"` → 75000 each.
- `pnpm db:check-balances` → sum 0, 0 mismatches.
- Create 60 more transactions in a shell loop, then `GET …/transactions?limit=50` → 50 items and a `nextCursor`; follow it → the remaining items, `nextCursor: null`, no id repeated between the pages.

- [ ] **Step 4: Exercise — invalid input and double submit (Review Focus 1, 2)**

| Request | Expected |
|---|---|
| `amount: 0`, `amount: 1.5`, `amount: 1000000000000` | 400 `VALIDATION_FAILED` |
| `description: "   "` | 400 `VALIDATION_FAILED` |
| `split.members: []`; a duplicated id in `split.members` | 400 `VALIDATION_FAILED` |
| Two payers | 400 `VALIDATION_FAILED` |
| Payer amount 90000 for `amount` 100000 | 400 `PAYER_TOTAL_MISMATCH` |
| A split member from another group | 400 `MEMBER_NOT_IN_GROUP` |
| `type: "transfer"` | 400 `VALIDATION_FAILED` |
| `?limit=0`, `?limit=201`, `?cursor=abc` | 400 `VALIDATION_FAILED` |
| Same body twice with one `Idempotency-Key` | 201 twice, same `id`; one row stored |
| Same key, `amount` changed | 409 `IDEMPOTENCY_KEY_REUSED` |
| Any of the three endpoints as Lan on Minh's private group | 404 `NOT_FOUND` |

After the table: `pnpm db:check-balances` → still balanced.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(api): add equal-split expense creation, preview, and listing"
```

**Manual checks for the project owner**
1. Run the 100000 create from Step 3 → the response shows 33334, 33333, 33333.
2. Open `http://localhost:4000/api/v1/groups/<id>/transactions` → newest first, each with `payers` and `shares`.
3. Run `pnpm db:check-balances` → `All groups balanced`.
4. Send the same create twice with the same `Idempotency-Key` → the list has it once.

---

### Task 1A.6: API — balances and settlements

**Files:**
- Create: `packages/contract/src/balance.ts`, `apps/api/src/services/balances.ts`, `apps/api/src/routes/balances.ts`
- Modify: `packages/contract/src/index.ts`, `packages/db/src/balances.ts`, `packages/db/src/index.ts`, `apps/api/src/app.ts`

**Interfaces:**
- Consumes: `suggestMinimizedSettlements`, `netPairwiseDebts` (Task 1); `listMemberBalances` (Task 3); `requireGroupRole`.
- Produces:
  - `BalancesResponse` = `{ currency: "VND"; minimized: boolean; balances: Array<{ memberId: uuid; balance: number }>; transfers: Array<{ fromMemberId: uuid; toMemberId: uuid; amount: number }> }` — field names from `docs/05-api-spec.md`; `balances` lists every member, active or not, in position order.
  - db: `listPairDebts(executor, groupId)` — one grouped query over non-deleted transactions joining payers to shares on the transaction, returning `{ debtorMemberId, creditorMemberId, amount }` totals where debtor is the share member and creditor is the payer. This is exact while every transaction has one payer; 1C replaces it when multiple payers arrive.

Endpoint: `GET /groups/{groupId}/balances`, access viewer. `transfers` comes from `suggestMinimizedSettlements` when the group's `minimize_debts` is true, otherwise from `netPairwiseDebts`. `minimized` echoes the setting.

- [ ] **Step 1: Write the schema, query, service and route**

- [ ] **Step 2: `pnpm check`**

- [ ] **Step 3: Exercise**

Fresh group Minh, Lan, Hùng, Thu, with "Gộp nợ" on:

| Step | Expected `GET …/balances` |
|---|---|
| No transactions | four balances of 0; `transfers: []` |
| Minh pays 800000 "Vé cáp treo", split all four | Minh +600000; others −200000 each; three transfers to Minh |
| Lan pays 300000 "Lẩu", split Minh, Lan, Hùng | Minh +500000, Lan 0, Hùng −300000, Thu −200000; transfers Hùng→Minh 300000, Thu→Minh 200000 |
| `PATCH` the group to `minimizeDebts: false` | same balances; `minimized: false`; transfers Lan→Minh 100000, Hùng→Minh 200000, Hùng→Lan 100000, Thu→Minh 200000 |
| Deactivate Thu | Thu still listed with −200000 (FR-1.60) |
| Minh pays 100000, split Minh, Lan, Hùng | balances sum to 0 with shares 33334, 33333, 33333 |

After every row, the balances in the response sum to 0, and `pnpm db:check-balances` agrees. As Lan on a group she is not in → 404. Without a cookie → 401.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(api): add balances with minimized and pairwise settlements"
```

**Manual checks for the project owner**
1. Follow the table in Step 3 with `curl` or the browser address bar → each row matches.
2. Compare the third and fourth rows: with "Gộp nợ" on there are two transfers, off there are four, and each person's balance is the same in both.
3. Add up the `balance` values by hand for any row → 0.

---

### Task 1A.7: Web — group list and create group (S2, S3)

**Files:**
- Create: `apps/web/src/lib/money.ts`, `apps/web/src/lib/request.ts`, `apps/web/src/lib/use-session-guard.ts`, `apps/web/src/lib/groups.ts`, `apps/web/src/components/ui/Icon.tsx`, `apps/web/src/components/ui/ScreenHeader.tsx`, `apps/web/src/components/ui/LoadError.tsx`, `apps/web/src/components/groups/FeaturedGroupCard.tsx`, `apps/web/src/components/groups/GroupCard.tsx`, `apps/web/src/components/groups/NewMemberRow.tsx`, `apps/web/src/app/groups/new/page.tsx`
- Modify: `apps/web/src/app/page.tsx`, `apps/web/src/app/globals.css`, `apps/web/src/messages/vi.ts`

**Interfaces:**
- Consumes: group and member schemas, `MEMBER_APPEARANCES` (Task 3); `apiFetch`, `ApiError`, `useMe`, `loginPath`, `MemberShape`, `Button`, `Card`, `t`, `vi` (phase 0).
- Produces:
  - `formatAmount(amount: number): string` → `150.000`; `formatMoney(amount: number): string` → `150.000 đ`; `formatSignedAmount(amount: number): string` → `+450.000`, `−320.000` (U+2212), `0`; `formatCompactAmount(amount: number): string` → thousands without the last three digits when `amount % 1000 === 0` (`120000` → `120`), otherwise `formatAmount`. Built on `Intl.NumberFormat("vi-VN")` and integer operators only.
  - `jsonRequest(method: "POST" | "PATCH" | "DELETE", body?: unknown, idempotencyKey?: string): RequestInit`
  - `useSessionGuard(error: ApiError | null): void` — on status 401, `router.replace(loginPath(<current path and query>))`. `page.tsx` switches to it.
  - `useGroups()`, `useGroup(groupId)`, `useCreateGroup()`, `useUpdateGroup(groupId)` — query keys `["groups"]` and `["group", groupId]`; mutations invalidate both.
  - `Icon(props: { name: "plus" | "back" | "close"; size: number })` — inline stroke SVG, `aria-hidden`. Paths on a 24 × 24 view box: plus `M12 5v14M5 12h14`, back `M15 18l-6-6 6-6`, close `M6 6l12 12M18 6L6 18`.
  - `ScreenHeader(props: { title: string; subtitle?: string; backHref: string; backLabel: string; trailing?: ReactNode })` — back link 48 × 48, radius 18, surface; title 18px weight 800; subtitle 12px muted.
  - `LoadError(props: { onRetry: () => void; isRetrying: boolean })` — `common.loadError` and a `common.retry` button, `role="alert"`.
  - New tokens in `globals.css`: `--color-debt-soft: #ffd9d1`, `--color-on-ink-muted: #c9c5d6`, `--color-dashed: #b9b3cc`.

Strings to add:

| Key | Value |
|---|---|
| `common.back` | `Quay lại` |
| `common.cancel` | `Huỷ` |
| `common.saveError` | `Chưa lưu được. Kiểm tra mạng rồi thử lại.` |
| `common.you` | `Bạn` |
| `common.groupNotFound` | `Không tìm thấy nhóm này.` |
| `common.backToGroups` | `Về danh sách nhóm` |
| `groups.memberCount` | `{count} người` |
| `groups.moreMembers` | `+{count}` |
| `groups.owedToYou` | `đồng bạn được nhận` |
| `groups.youOwe` | `đồng bạn cần trả` |
| `groups.settled` | `bạn đã xong` |
| `groups.chipOwedToYou` | `bạn được nhận` |
| `groups.chipYouOwe` | `bạn cần trả` |
| `groups.chipSettled` | `đã xong` |
| `newGroup.title` | `Nhóm mới` |
| `newGroup.nameLabel` | `Tên nhóm` |
| `newGroup.membersTitle` | `Ai đi cùng?` |
| `newGroup.creatorTag` | `bạn` |
| `newGroup.removeMember` | `Bỏ {name}` |
| `newGroup.newMemberLabel` | `Tên người mới` |
| `newGroup.add` | `Thêm` |
| `newGroup.hint` | `Mỗi cái tên nhận một hình riêng. Họ không cần tài khoản, và bạn thêm người sau cũng được.` |
| `newGroup.submitOne` | `Tạo nhóm` |
| `newGroup.submitMany` | `Tạo nhóm {count} người` |

Screen behavior:

| Screen | Behavior |
|---|---|
| S2 `/` | Header as in phase 0. Groups in API order. The first is `FeaturedGroupCard`: accent background, radius 40, padding 20/22; a row of up to four `MemberShape` at size 30; name 20px weight 800; `formatSignedAmount(myBalance)` at 52px weight 900; caption 14px weight 600 — `groups.owedToYou`, `groups.youOwe`, or `groups.settled`. The rest are `GroupCard`: surface, radius 32, padding 18/20; up to four shapes at size 22 followed by `groups.moreMembers` when there are more; name 18px weight 800; `groups.memberCount` 13px muted; on the right a chip (radius 18, padding 8/12) with the signed amount at 18px weight 900 and an 11px weight 700 caption — accent with `chipOwedToYou`, `debt-soft` with `chipYouOwe`, `sunken` with `chipSettled`. Each card is one link to `/g/{id}`. No groups: the phase 0 empty state. Bottom: a link to `/groups/new` styled as the primary `lg` button with the plus icon and `groups.create`, now enabled. |
| S3 `/groups/new` | `ScreenHeader` with `newGroup.title`, back to `/`. Name field: label 13px weight 600 muted; input height 72, radius 28, surface, 26px weight 900, `maxLength` 80, focused on arrival. `newGroup.membersTitle` 17px weight 800. First row: the creator — `MemberShape` 44 (circle/mint), the user's name 16px weight 800, `newGroup.creatorTag` on the right. Each added name is a row with its shape and a 44 × 44 remove button labelled `newGroup.removeMember`. `NewMemberRow`: surface, radius 30, 3px ink border; a preview `MemberShape` 44 showing the pair the next member will get and the first letter typed; input 18px weight 800, `maxLength` 50; `newGroup.add` button height 48. Enter or the button appends the trimmed name; an empty name does nothing; at 99 added names the row is disabled. Shapes shown are `MEMBER_APPEARANCES[index]` in list order, so removing a row re-flows the ones after it, exactly as the server will assign them. `newGroup.hint` 13px muted. Bottom: accent button height 68, radius 34, 18px weight 900 — `newGroup.submitOne` with no added names, else `newGroup.submitMany` with the total including the creator. Disabled while the name is empty or the request is pending. On success `router.replace("/g/{id}")`. On failure `common.saveError` in a `role="alert"` above the button; the typed data stays. |

One idempotency key is generated with `crypto.randomUUID()` when the screen mounts and reused for every retry of that submission.

- [ ] **Step 1: Write the shared pieces (`money.ts`, `request.ts`, `use-session-guard.ts`, `Icon`, `ScreenHeader`, `LoadError`, tokens, strings)**

- [ ] **Step 2: Write `lib/groups.ts`, the two cards, S2 and S3**

- [ ] **Step 3: `pnpm check`**

- [ ] **Step 4: Exercise in the browser**

1. As Minh with no groups → the empty state; "Tạo nhóm" is enabled and opens `/groups/new`.
2. Type a name, add Lan, Hùng, Thu → four rows with circle/mint, diamond/sky, squircle/coral, leaf/lilac; the button reads "Tạo nhóm 4 người".
3. Remove Lan → Hùng becomes diamond/sky, Thu squircle/coral; the button reads "Tạo nhóm 3 người".
4. Submit → lands on `/g/<id>` (a 404 page from Next.js is expected until Task 8). Back at `/` the group is the accent card with `0` and "bạn đã xong".
5. Create a second group → it becomes the accent card; the first becomes a compact card.
6. Double-click the submit button → one group is created.
7. Stop the API and submit → "Chưa lưu được…"; the form keeps its content. Start the API and submit again → one group.
8. Open `/groups/new` signed out → redirected to the login page, and back to `/groups/new` after choosing a person.
9. At 360px width → no horizontal scroll on either screen.

If no browser tool is available, record these under "Not verified" in the report and paste what `curl` can show.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(web): add group list and group creation screens"
```

**Manual checks for the project owner**
1. As Minh, tap "Tạo nhóm", name it "Đà Lạt 12/2026", add Lan, Hùng and Thu → compare with screen GE8 on the canvas: field sizes, the four shapes, the yellow button text "Tạo nhóm 4 người".
2. Create the group → back on `/`, it appears as the large yellow card with four shapes and `0`; compare with GE1.
3. Try to create a group with an empty name → the button stays disabled.
4. Press Enter in the "Tên người mới" field with only spaces → nothing is added.
5. Use only the keyboard (Tab, Enter) to add a person and create the group → works.
6. Sign in as Lan in a private window → Lan sees no groups.

---

### Task 1A.8: Web — group screen and expense stream (S4)

**Files:**
- Create: `apps/web/src/lib/members.ts`, `apps/web/src/lib/transactions.ts`, `apps/web/src/lib/balances.ts`, `apps/web/src/components/feed/BalanceBlock.tsx`, `apps/web/src/components/feed/ExpenseRow.tsx`, `apps/web/src/components/feed/ExpenseStream.tsx`, `apps/web/src/components/feed/EmptyStream.tsx`, `apps/web/src/components/feed/EntryBar.tsx`, `apps/web/src/app/g/[groupId]/page.tsx`
- Modify: `apps/web/src/messages/vi.ts`

**Interfaces:**
- Consumes: Task 7 pieces; member, transaction and balance schemas (Tasks 4–6).
- Produces:
  - `useMembers(groupId)` — key `["group", groupId, "members"]`.
  - `useTransactions(groupId)` — an infinite query, key `["group", groupId, "transactions"]`, page size 50, following `nextCursor`.
  - `useBalances(groupId)` — key `["group", groupId, "balances"]`.
  - `dayLabel(occurredAt: string, now: Date): string` in `lib/transactions.ts` — `feed.today`, `feed.yesterday`, otherwise `dd/MM/yyyy`, in the device time zone.

Strings to add:

| Key | Value |
|---|---|
| `feed.membersLink` | `Thành viên` |
| `feed.owedToYou` | `Bạn được nhận` |
| `feed.youOwe` | `Bạn cần trả` |
| `feed.settled` | `Bạn đã xong` |
| `feed.collect` | `Thu về` |
| `feed.pay` | `Trả` |
| `feed.view` | `Xem` |
| `feed.today` | `Hôm nay` |
| `feed.yesterday` | `Hôm qua` |
| `feed.youPaid` | `Bạn trả` |
| `feed.memberPaid` | `{name} trả` |
| `feed.equalSplitMine` | `Chia đều {count} · phần bạn {amount}` |
| `feed.equalSplitNotMine` | `Chia đều {count} · bạn không có phần` |
| `feed.moreShares` | `+{count}` |
| `feed.loadingOlder` | `Đang tải khoản cũ hơn…` |
| `feed.whoOwesWho` | `Ai nợ ai?` |
| `feed.manualEntry` | `Nhập tay` |
| `feed.entryPlaceholder` | `Thêm một khoản chi…` |
| `feed.emptyTitle` | `Ghi khoản chi đầu tiên` |
| `feed.emptyHint` | `Chạm Nhập tay để thêm một khoản chi cho cả nhóm.` |

Screen behavior (`/g/{groupId}`):

| Part | Behavior |
|---|---|
| States | Loading: skeleton blocks. 401: `useSessionGuard`. 404: `common.groupNotFound` and a link `common.backToGroups` to `/`. Other errors: `LoadError`. |
| Header | `ScreenHeader`: title = group name, back to `/`; `trailing` is a link to `/g/{id}/members`, height 48, radius 24, surface, labelled `feed.membersLink`, holding up to four `MemberShape` at size 24. |
| `BalanceBlock` | One link to `/g/{id}/balances`: accent, radius 32, padding 14/18/16/20. Caption 13px weight 600 and `formatMoney` of the absolute value at 40px weight 900; on the right a pill, height 48, ink. The viewer's balance is their entry in `useBalances`. Positive: `feed.owedToYou` / `feed.collect`. Negative: `feed.youOwe` / `feed.pay`. Zero or no linked member: `feed.settled`, `0 đ`, `feed.view`. |
| `ExpenseStream` | Oldest at the top, newest at the bottom; on first render the view is scrolled to the bottom. A day separator (12px weight 600 muted, centered) precedes the first row of each day. A sentinel at the top, watched with `IntersectionObserver`, fetches the next page while `hasNextPage`; the visible rows must not jump when older rows are inserted; `feed.loadingOlder` shows while fetching. |
| `ExpenseRow`, payer is the viewer's member | Right-aligned, max width 300, ink background, radius 26 with an 8px bottom-right corner, padding 12/16/14. `feed.youPaid` 12px weight 600 in `on-ink-muted`; description 15px weight 700 and `formatAmount(amount)` 19px weight 900 on one line; below, a wrapping row of chips for the first four shares, then `feed.moreShares` when there are more: each chip has background `ink-raised` (new token `--color-ink-raised: #34323d`), radius 14, padding 5/9, a `MemberShape` at size 14 and `formatCompactAmount` at 12px weight 700. |
| `ExpenseRow`, any other payer | Left-aligned with the payer's `MemberShape` at size 36 beside a surface bubble, max width 270, radius 26 with an 8px bottom-left corner. `feed.memberPaid` 12px weight 600 muted; description and amount as above; then `feed.equalSplitMine` with the viewer's share via `formatAmount`, or `feed.equalSplitNotMine`, 13px muted. |
| `EmptyStream` | Shown when the first page is empty: up to four `MemberShape` at size 76 in a centered row, `feed.emptyTitle` 32px weight 900, `feed.emptyHint` 14px muted. |
| Shortcut row | Shown when there is at least one transaction: a link `feed.whoOwesWho` to `/g/{id}/balances`, height 44, radius 22, surface, 13px weight 700. |
| `EntryBar` | Fixed at the bottom of the column. A link to `/g/{id}/tx/new?form`, 84 × 64, radius 26, accent, plus icon above `feed.manualEntry` at 12px weight 800. Beside it a second link to the same address shaped like the typing box: surface, radius 32, height 64, `feed.entryPlaceholder` at 15px muted. |

Rows are not tappable in 1A. Inactive members still render by name and shape in old rows.

- [ ] **Step 1: Write the three hook files and the strings**

- [ ] **Step 2: Write the feed components and the page**

- [ ] **Step 3: `pnpm check`**

- [ ] **Step 4: Exercise in the browser**

Create expenses with the `curl` commands from Task 5 until Task 9 exists.

1. A group with no expenses → the four shapes, "Ghi khoản chi đầu tiên", no shortcut row; the balance block reads "Bạn đã xong", "0 đ".
2. As Minh, after "Minh pays 800000 split four" and "Lan pays 300000 split Minh, Lan, Hùng" → Minh's row on the right in black with four chips, each a small shape and `200`; Lan's row on the left with her blue diamond and "Chia đều 3 · phần bạn 100.000"; balance block "Bạn được nhận", "500.000 đ", "Thu về".
3. An expense paid by Hùng and split only between Lan and Thu → a left-aligned row reading "Chia đều 2 · bạn không có phần".
4. An expense of 100000 paid by Minh and split between Minh, Lan and Hùng → the black row's chips show `33.334`, `33.333`, `33.333`, in full, not rounded.
5. Insert an expense dated yesterday and one dated last week → separators "Hôm qua" and a `dd/MM/yyyy` date, in chronological order.
6. With 120 expenses → the page opens at the newest; scrolling up loads older pages twice; the row under the finger does not jump; no expense appears twice.
7. Open `/g/<Minh's group>` as Lan and `/g/not-a-uuid` → "Không tìm thấy nhóm này." both times.
8. Stop the API and reload → `LoadError`, not a redirect to login.
9. At 360px width → rows wrap inside the column; no horizontal scroll.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(web): add group screen with expense stream and balance block"
```

**Manual checks for the project owner**
1. Open a new group → compare with GE14 on the canvas, minus the three sample sentences and the "Mời bạn vào nhóm" link (they arrive in 1D and 1B).
2. Open a group with expenses → compare the header, the yellow balance block and the two row styles with GE17 (ignore its offline banner).
3. Check each day has one separator and the newest expense sits just above the bottom bar.
4. Tap the yellow block and "Ai nợ ai?" → both go to `/g/<id>/balances` (a 404 page until Task 10).
5. As Lan, paste the address of Minh's group → "Không tìm thấy nhóm này."

---

### Task 1A.9: Web — manual expense form (S8)

**Files:**
- Create: `apps/web/src/components/expense-form/AmountField.tsx`, `apps/web/src/components/expense-form/CategoryPicker.tsx`, `apps/web/src/components/expense-form/MemberToggleGrid.tsx`, `apps/web/src/components/expense-form/ExpenseForm.tsx`, `apps/web/src/app/g/[groupId]/tx/new/page.tsx`
- Modify: `apps/web/src/lib/transactions.ts`, `apps/web/src/lib/money.ts`, `apps/web/src/messages/vi.ts`

**Interfaces:**
- Consumes: Tasks 7 and 8; `CreateTransactionRequest`, `PreviewTransactionResponse` (Task 5).
- Produces:
  - `useCreateTransaction(groupId)` — invalidates `["group", groupId, "transactions"]`, `["group", groupId, "balances"]` and `["groups"]`.
  - `usePreviewShares(groupId, request: CreateTransactionRequest | null)` — a query on `POST …/transactions/preview`, disabled when `request` is null, keeping the previous result while a new one loads.
  - `parseAmountInput(text: string): number | null` in `lib/money.ts` — strips every non-digit; returns null for an empty result or a value above 999_999_999_999.
  - `MemberToggleGrid(props: { members: MemberDto[]; selectedIds: readonly string[]; onToggle: (memberId: string) => void; captionFor: (member: MemberDto) => string; label: string })` — a four-column grid of real `<button aria-pressed>`; selected: 3px ink border on surface; unselected: `bg` background, muted text; each cell is `MemberShape` 44 above a 12px caption.

Strings to add:

| Key | Value |
|---|---|
| `expenseForm.title` | `Khoản chi mới` |
| `expenseForm.amountLabel` | `Số tiền` |
| `expenseForm.addThousands` | `000` |
| `expenseForm.descriptionLabel` | `Mô tả` |
| `expenseForm.descriptionPlaceholder` | `Chi cho việc gì?` |
| `expenseForm.categoryLabel` | `Danh mục` |
| `expenseForm.categories.food` | `Ăn uống` |
| `expenseForm.categories.transport` | `Đi lại` |
| `expenseForm.categories.lodging` | `Chỗ ở` |
| `expenseForm.categories.shopping` | `Mua sắm` |
| `expenseForm.categories.entertainment` | `Giải trí` |
| `expenseForm.categories.bills` | `Hoá đơn` |
| `expenseForm.categories.other` | `Khác` |
| `expenseForm.payerTitle` | `Ai trả?` |
| `expenseForm.sharersTitle` | `Chia cho ai?` |
| `expenseForm.equalSplit` | `Chia đều` |
| `expenseForm.occurredAtLabel` | `Ngày giờ` |
| `expenseForm.needSharer` | `Chọn ít nhất một người để chia.` |
| `expenseForm.save` | `Lưu khoản chi` |

Screen behavior (`/g/{groupId}/tx/new`, with or without `?form`):

| Part | Behavior |
|---|---|
| Header | `ScreenHeader`: `expenseForm.title`, subtitle = group name, back link with the close icon labelled `common.cancel` to `/g/{id}`. No type switch. |
| `AmountField` | Surface, radius 32, 3px ink border; a centered input, 52px weight 900, `inputMode="numeric"`, labelled `expenseForm.amountLabel`, focused on arrival; `đ` 22px weight 900 muted. Typing re-renders the value through `formatAmount` (thousands separated by dots). A `expenseForm.addThousands` button, height 44, appends three zeros. Digits beyond the maximum amount are not accepted. |
| Description | Input height 56, radius 26, surface, 17px weight 800, `maxLength` 200, labelled `expenseForm.descriptionLabel`, with the placeholder. |
| `CategoryPicker` | A `role="group"` labelled `expenseForm.categoryLabel`: seven `aria-pressed` buttons, height 44, radius 22, 13px; selected ink with white text, others surface. The row scrolls horizontally inside the column. None selected at first; tapping the selected one clears it (the category is optional). |
| Payer | Card: surface, radius 30. `expenseForm.payerTitle` 14px weight 800. `MemberToggleGrid` of active members, single selection, caption = name, or `common.you` for the viewer's member. Default: the viewer's member (FR-1.41); none when the viewer has no linked member. |
| Sharers | Card as above; `expenseForm.sharersTitle` with a non-interactive tag `expenseForm.equalSplit` (radius 22, phrase-split background `#CFF5DF` added as token `--color-phrase-split`). `MemberToggleGrid` of active members, multiple selection, all selected by default. Caption of a selected member = `formatAmount` of that member's share from `usePreviewShares`, or `…` while the first preview loads; unselected = name. With none selected, `expenseForm.needSharer` shows under the grid. |
| Date and time | A native `<input type="datetime-local">` labelled `expenseForm.occurredAtLabel`, height 64, radius 32, surface; default = now in the device time zone; sent as UTC ISO. |
| Save | Accent button `expenseForm.save`, height 64, full width. Enabled only when the amount parses, the description is not blank, a payer is chosen, at least one sharer is selected, and no request is pending. On success `router.replace("/g/{id}")`. On failure `common.saveError` in a `role="alert"`; nothing typed is lost. |

The preview request is built only when amount, payer and at least one sharer are valid, and is debounced by 250 ms. The create request sends `type: "expense"`, one payer carrying the full amount, and `split: { method: "equal", members: <selected ids> }`. One idempotency key per mounted form, reused for retries.

- [ ] **Step 1: Write the hooks, `parseAmountInput`, strings and token**

- [ ] **Step 2: Write the four components and the page**

- [ ] **Step 3: `pnpm check`**

- [ ] **Step 4: Exercise in the browser**

1. Tap "Nhập tay" in a four-person group → the cursor is in the amount field; payer is "Bạn"; all four are selected.
2. Type `180000` → the field shows `180.000`; after a moment each shape shows `45.000`.
3. Deselect Thu → three captions of `60.000`; Thu shows her name.
4. Type `100`, tap "000" → `100.000`; with three sharers → `33.334`, `33.333`, `33.333`.
5. Type a description and save → back on the group; the new row is at the bottom with the same amounts; the balance block changed.
6. Save with only amount and description changed from defaults → three interactions: amount, description, "Lưu khoản chi" (US-1.5).
7. Double-click "Lưu khoản chi" → one expense in the stream and in the database (Review Focus 2).
8. Leave the description blank, or deselect everyone → the button is disabled; with nobody selected the hint "Chọn ít nhất một người để chia." shows.
9. Paste `abc1.5tr` into the amount → only digits remain. Type 13 digits → the 13th is not accepted.
10. Deactivate Hùng with the Task 4 `PATCH`, reopen the form → Hùng is in neither grid.
11. Pick a date last week and save → the row appears under that day's separator, above today's rows.
12. Stop the API and save → "Chưa lưu được…", the form keeps every value; start the API and save → one expense.
13. `pnpm db:check-balances` → `All groups balanced`.
14. In a four-person group at 390 × 844 the whole form fits without scrolling; at 360px width nothing overflows sideways.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(web): add manual expense form with live equal-split preview"
```

**Manual checks for the project owner**
1. Open the form → compare with GE19 on the canvas, minus the "Chi / Chuyển / Thu" switch and the "đổi cách chia" link (1C). All seven categories are present.
2. Enter 180.000, "Cà phê", save → the stream shows the expense; "Bạn được nhận" rose by 135.000 đ.
3. Enter 100.000 for three people → the shapes show 33.334, 33.333, 33.333; after saving, `pnpm db:check-balances` reports balanced.
4. Double-tap save quickly → the expense appears once.
5. Complete the whole form with the keyboard only → every field and shape is reachable with Tab and operable with Space or Enter.
6. Turn on a screen reader and move across the shapes → it reads the person's name and whether they are selected, never the shape's name.

---

### Task 1A.10: Web — balances and settlements (S5)

**Files:**
- Create: `apps/web/src/components/balances/SettlementCard.tsx`, `apps/web/src/components/balances/BalanceBars.tsx`, `apps/web/src/components/balances/AllSettled.tsx`, `apps/web/src/app/g/[groupId]/balances/page.tsx`
- Modify: `apps/web/src/messages/vi.ts`

**Interfaces:**
- Consumes: `useBalances`, `useMembers`, `useGroup`, `useTransactions` (Task 8); formatting functions (Task 7).
- Produces: no shared interface.

Strings to add:

| Key | Value |
|---|---|
| `balances.headline` | `{count} lượt chuyển là xong` |
| `balances.minimizedHint` | `Ít lượt chuyển nhất có thể.` |
| `balances.pairwiseHint` | `Từng cặp trả nhau. Bật Gộp nợ trong cài đặt nhóm để ít lượt hơn.` |
| `balances.memberPaysYou` | `{name} trả bạn` |
| `balances.youPayMember` | `Bạn trả {name}` |
| `balances.memberPaysMember` | `{from} trả {to}` |
| `balances.groupBalanceTitle` | `Cán cân của nhóm` |
| `balances.inactiveTag` | `ngừng hoạt động` |
| `balances.emptyTitle` | `Chưa có gì để tính` |
| `balances.emptyHint` | `Thêm khoản chi đầu tiên để thấy ai nợ ai.` |
| `balances.allSettledTitle` | `Cả nhóm đã xong.` |
| `balances.allSettledHint` | `Không ai nợ ai.` |
| `balances.backToGroup` | `Về nhóm` |

Screen behavior (`/g/{groupId}/balances`):

| State | Behavior |
|---|---|
| Loading, 401, 404, error | As S4. |
| No transactions | `ScreenHeader` (group name, back to `/g/{id}`), then `balances.emptyTitle` 34px weight 900 and `balances.emptyHint`. |
| Transactions exist, no transfers | `AllSettled`: accent card, radius 40, `balances.allSettledTitle` 48px weight 900, `balances.allSettledHint` 15px weight 600; a surface card with every member's `MemberShape` 72, name (or `common.you`) and `0 đ`; a primary `lg` link `balances.backToGroup`. |
| Transfers exist | Headline `balances.headline` 34px weight 900 with the hint for the current mode, 14px muted. One `SettlementCard` per transfer: surface, radius 36; a `MemberShape` 76 of the other party (the payer when neither side is the viewer); a 13px weight 600 muted line — `memberPaysYou`, `youPayMember`, or `memberPaysMember`; `formatAmount(amount)` 26px weight 900. Transfers involving the viewer come first, otherwise API order. No buttons. Then `BalanceBars`. |
| `BalanceBars` | Surface card, radius 30, `balances.groupBalanceTitle` 14px weight 800. One row per member with a non-zero balance or `active: true`, ordered by balance descending: name (with `balances.inactiveTag` for inactive members); a 14px-high track with a bar in the member's color growing right from the center for a positive balance and left for a negative one, its width proportional to the largest absolute balance; `formatSignedAmount(balance)` right-aligned. The bar width is display geometry, not a money figure. |

Every balance shows its sign as text; meaning never rests on color or side alone.

- [ ] **Step 1: Write the strings, the three components and the page**

- [ ] **Step 2: `pnpm check`**

- [ ] **Step 3: Exercise in the browser**

Using the group from the Task 6 table:

1. Before any expense → "Chưa có gì để tính".
2. After the two expenses, as Minh → "2 lượt chuyển là xong"; cards "Hùng trả bạn 300.000" and "Thu trả bạn 200.000"; bars Minh `+500.000` to the right, Lan `0`, Thu `−200.000` and Hùng `−300.000` to the left.
3. Set `minimizeDebts` to false with the Task 3 `PATCH`, reload → "4 lượt chuyển là xong" with the pairwise hint; "Hùng trả Lan 100.000" is listed after the three cards involving Minh.
4. A group whose only expense is paid by Minh and shared only by Minh → "Cả nhóm đã xong."
5. Deactivate Thu → her bar stays, tagged "ngừng hoạt động".
6. Each card's amounts match `GET …/balances` exactly.
7. As Lan on Minh's group → "Không tìm thấy nhóm này."

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(web): add balances screen with suggested settlements"
```

**Manual checks for the project owner**
1. Tap the yellow block on the group screen → compare with GE5 on the canvas, minus the "Đã nhận", "Nhắc", "Xác nhận" and "Nhắc cả nhóm một lần" buttons (1C and later phases).
2. Add up the numbers beside the bars by hand → 0.
3. Add one more expense in another tab, come back and reload → cards and bars changed consistently with the block on the group screen.
4. Open a group where nobody owes anything → compare the yellow "Cả nhóm đã xong." card with GE18.

---

### Task 1A.11: Web — members and group settings (S10, S11)

**Files:**
- Create: `apps/web/src/components/members/MemberRow.tsx`, `apps/web/src/components/members/MemberEditor.tsx`, `apps/web/src/components/members/AddMemberRow.tsx`, `apps/web/src/components/ui/Switch.tsx`, `apps/web/src/app/g/[groupId]/members/page.tsx`, `apps/web/src/app/g/[groupId]/settings/page.tsx`
- Modify: `apps/web/src/lib/members.ts`, `apps/web/src/messages/vi.ts`

**Interfaces:**
- Consumes: `useMembers`, `useGroup`, `useUpdateGroup`, `useBalances`; member endpoints (Task 4).
- Produces:
  - `useCreateMember(groupId)`, `useUpdateMember(groupId)`, `useDeleteMember(groupId)` — each invalidates `["group", groupId, "members"]`, `["group", groupId, "balances"]` and `["groups"]`.
  - `Switch(props: { checked: boolean; onChange: (checked: boolean) => void; label: string; disabled?: boolean })` — a `<button role="switch" aria-checked>`, 64 × 44, radius 22; on: ink track with an accent knob at the right; off: `sunken` track with a surface knob at the left.

Strings to add:

| Key | Value |
|---|---|
| `members.memberCount` | `{count} người` |
| `members.youTag` | `Bạn` |
| `members.ownerBadge` | `Chủ nhóm` |
| `members.inactiveTag` | `Ngừng hoạt động` |
| `members.edit` | `Sửa {name}` |
| `members.nameLabel` | `Tên` |
| `members.saveName` | `Lưu tên` |
| `members.deactivate` | `Ngừng hoạt động` |
| `members.reactivate` | `Hoạt động lại` |
| `members.delete` | `Xoá` |
| `members.deactivateWarning` | `{name} còn số dư {amount}. Ngừng hoạt động thì số dư này vẫn được giữ.` |
| `members.deactivateAnyway` | `Vẫn ngừng` |
| `members.keepActive` | `Thôi` |
| `members.hasTransactions` | `{name} đã có khoản chi nên không xoá được. Hãy cho ngừng hoạt động.` |
| `members.addName` | `Thêm một cái tên` |
| `members.newNameLabel` | `Tên người mới` |
| `members.add` | `Thêm` |
| `members.limitReached` | `Nhóm đã đủ 100 người.` |
| `members.settingsLink` | `Cài đặt nhóm` |
| `settings.title` | `Cài đặt nhóm` |
| `settings.ownerOnly` | `Chỉ chủ nhóm thấy trang này` |
| `settings.nameLabel` | `Tên nhóm` |
| `settings.saveName` | `Lưu tên` |
| `settings.minimizeTitle` | `Gộp nợ` |
| `settings.minimizeHint` | `Ít lượt chuyển nhất có thể, thay vì từng cặp trả nhau.` |

Screen behavior:

| Screen | Behavior |
|---|---|
| S10 `/g/{groupId}/members` | `ScreenHeader`: group name, subtitle `members.memberCount`, back to `/g/{id}`. One `MemberRow` per member in position order: surface, radius 28; `MemberShape` 52; name 16px weight 800; a 12px muted line — `members.youTag` for the viewer's member, `members.inactiveTag` for inactive members, otherwise empty; the viewer's row carries the `members.ownerBadge` chip (accent, radius 14) when their role is owner. Inactive rows have muted text. The row is a button labelled `members.edit` that opens `MemberEditor` beneath it; only one editor is open at a time. |
| `MemberEditor` | A name input (`members.nameLabel`, `maxLength` 50) with `members.saveName`, enabled when the trimmed name is non-empty and changed. For members not linked to a user: `members.deactivate` or `members.reactivate`, and `members.delete`. Deactivating a member whose balance is not 0 first shows `members.deactivateWarning` (amount = `formatSignedAmount` + ` đ`) with `members.deactivateAnyway` and `members.keepActive` (flow H). Delete sends the request directly; a 422 `MEMBER_HAS_TRANSACTIONS` shows `members.hasTransactions` in a `role="alert"`; other failures show `common.saveError`. |
| `AddMemberRow` | A dashed button (2px `dashed` token, radius 28, height 56) `members.addName`; tapping it turns it into the same input row as S3 (`members.newNameLabel`, `members.add`, preview shape = the pair the server will assign). At 100 members it is replaced by `members.limitReached`. One idempotency key per opened row. |
| Bottom of S10 | For the owner only: a surface link `members.settingsLink`, height 60, radius 30, to `/g/{id}/settings`. No "Lịch sử" link. |
| S11 `/g/{groupId}/settings` | A caller whose role is not owner sees `common.groupNotFound` with `common.backToGroups`. `ScreenHeader`: `settings.title`, subtitle `settings.ownerOnly`, back to `/g/{id}/members`. Name field (label 13px weight 600 muted; input height 64, radius 26, 22px weight 900, `maxLength` 80) with `settings.saveName`, enabled when changed and non-empty. A surface card, radius 28: `settings.minimizeTitle` 15px weight 800, `settings.minimizeHint` 12px muted, and a `Switch` that sends `PATCH` immediately, is disabled while pending, and returns to its previous position with `common.saveError` on failure. Nothing else from GE11. |

- [ ] **Step 1: Write the mutation hooks, strings and `Switch`**

- [ ] **Step 2: Write the member components and both pages**

- [ ] **Step 3: `pnpm check`**

- [ ] **Step 4: Exercise in the browser (Review Focus 5)**

1. Open members from the shape cluster on the group screen → four rows; Minh's shows "Bạn" and "Chủ nhóm".
2. Add "Bác Tư" → a fifth row with the pair shown in the preview; the group list card shows "5 người".
3. Rename Lan to "Lan Anh" → the row and the expense stream both show the new name; her shape is unchanged.
4. Delete "Bác Tư" (no expenses) → the row disappears.
5. Try to delete Hùng, who has expenses → "Hùng đã có khoản chi nên không xoá được. Hãy cho ngừng hoạt động."
6. Deactivate Hùng, whose balance is −300.000 → the warning with "−300.000 đ"; "Thôi" changes nothing; "Vẫn ngừng" marks him "Ngừng hoạt động". He is gone from the expense form, still in old rows and in the balance bars.
7. Reactivate Hùng → he is back in the form.
8. Minh's own row offers only the name field.
9. Open settings, rename the group → the new name is in the header and the group list.
10. Turn "Gộp nợ" off → the balances screen shows the pairwise list; turn it on → the minimized list.
11. Save an empty group name → not possible; the button is disabled.
12. `pnpm db:check-balances` → balanced.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(web): add member management and group settings screens"
```

**Manual checks for the project owner**
1. Open the members screen → compare with GE9 on the canvas, minus the yellow invite card, the "Đã vào nhóm" and "Chưa ai nhận hình này" lines, the role chips of other people, and the "Lịch sử" button (1B and 1E).
2. Open settings → compare the name field and the "Gộp nợ" row with GE11; nothing else from GE11 is shown.
3. Do steps 5 and 6 of the exercise → the member with expenses cannot be deleted, and after deactivation their debt is still on the balances screen.
4. Flip "Gộp nợ" and look at the balances screen each time → the number of transfers changes; each person's balance does not.
5. Operate the switch with the keyboard (Tab, Space) and a screen reader → it announces "Gộp nợ" and on or off.

---

### Task 1A.12: README and stage gate 1A

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the README**

"Common commands" gains `pnpm db:check-balances` with one sentence on when to run it.

- [ ] **Step 2: Run stage gate 1A**

Follow "Stage gate" in `00-overview.md`. The acceptance script for this stage, on a freshly reset database (`docker compose down -v`, then start everything), signed in as Minh through the dev login, using `curl` only:

1. Create "Đà Lạt 12/2026" with Lan, Hùng, Thu.
2. Create: "Vé cáp treo" 800000, Minh pays, all four; "Lẩu" 300000, Lan pays, split Minh, Lan, Hùng; "Cà phê" 100000, Minh pays, split Minh, Lan, Hùng.
3. `GET …/balances` with "Gộp nợ" on → Minh +566666, Lan −33333, Hùng −333333, Thu −200000; transfers Hùng→Minh 333333, Thu→Minh 200000, Lan→Minh 33333.
4. `PATCH` `minimizeDebts: false` → transfers Lan→Minh 133333, Hùng→Minh 233333, Hùng→Lan 100000, Thu→Minh 200000; balances unchanged.
5. Deactivate Thu; create "Taxi" 90000, Minh pays, split Minh, Lan, Hùng → shares 30000 each; Thu's balance is still −200000.
6. `pnpm db:check-balances` → `All groups balanced`.
7. Permission matrix rows active in this stage: every endpoint of Tasks 3–6 called as owner (Minh) succeeds and as outsider (Lan) returns 404 with a body identical to that of a random UUID.

If a number differs from steps 3–5, the code is wrong; do not adjust the expected values.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs(repo): document the balance check command"
```

**Manual checks for the project owner — stage 1A**
1. On a phone-sized window, create the group and the three expenses of the acceptance script through the screens → the balances screen shows the numbers of steps 3 and 4.
2. Recording the "Cà phê" expense takes three interactions after opening the form.
3. Reload any screen → nothing is lost; you are still Minh.
4. Walk S2 → S3 → S4 → S8 → S5 → S10 → S11 using only the keyboard.

---

## Not in this stage

Everything listed in the later stage files. Do not build ahead: a later stage's task defines its own interfaces.
