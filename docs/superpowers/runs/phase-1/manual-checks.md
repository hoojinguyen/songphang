# Phase 1 — manual checks for the project owner

Written by the implementation agent from the "Manual checks for the project owner" blocks of the plan, reorganized by screen (S1–S13) and then by flow (A–H). Each line: what to do, where, and what must be true. Invalid cases are included.

## Before you start

## Screens

## Flows

## After the Google OAuth app exists


## Core money functions (1A.1)
1. From the repository root run `node --input-type=module -e 'import {splitEqually} from "./packages/core/src/index.ts"; console.log(splitEqually(100000,["a","b","c"]))'` → amounts 33334,33333,33333, summing to 100000.
2. Call `netPairwiseDebts` with b→a 90 and c→b 90, order a,b,c → two transfers; call `suggestMinimizedSettlements` with a +90,b 0,c −90 → one c→a 90.
3. Call `splitEqually(0,["a"])` or `splitEqually(1000,[])` → RangeError, no amounts.

## Database integrity (1A.2)
1. Run `pnpm db:migrate` → no error. Run `docker compose exec db psql -U songphang -c "\dt"` → ten tables.
2. Run `pnpm db:check-balances` → `No groups` or one balanced line per group, exit 0.
3. In one SQL transaction create an expense of 300000 with a payer of 300000 and shares of 150000 + 140000 → COMMIT is refused with `transaction shares total differs from amount`.

## Groups API and access (1A.3)
1. Sign in through the development login as Minh, then POST `/api/v1/groups` with name `Đà Lạt 12/2026`, memberNames `Lan`, `Hùng`, `Thu`, and an Idempotency-Key → 201 owner group. GET `/api/v1/groups` → four preview members.
2. Sign in as Lan in a private window and open `http://localhost:4000/api/v1/groups` → empty list.
3. As Lan open Minh's `/api/v1/groups/<groupId>` → NOT_FOUND, identical to a made-up UUID except requestId.
4. Repeat the same POST body/key twice → same group id. Change the name but keep the key → 409 IDEMPOTENCY_KEY_REUSED.

## Members API (1A.4)
1. As Minh open `http://localhost:4000/api/v1/groups/<groupId>/members` → ordered members, each with shape/color, isMe only for Minh.
2. POST a name with surrounding spaces using a new Idempotency-Key → trimmed name, last position and first unused appearance.
3. PATCH Lan's name → name changes, shape/color/position unchanged. PATCH defaultWeight `1.5` → `1.50`; negative weight, empty name or empty PATCH → 400.
4. As Lan open Minh's members URL → NOT_FOUND. Delete a member of another group through Minh's group URL → NOT_FOUND.

## Expense API (1A.5)
1. Create 100000 paid by Minh, split Minh/Lan/Hùng → shares 33334/33333/33333, version 1. Reverse the submitted member order → same amounts by position.
2. Open `http://localhost:4000/api/v1/groups/<groupId>/transactions` → newest first with payers/shares. Follow nextCursor → no duplicate IDs.
3. Run `pnpm db:check-balances` → All groups balanced.
4. Repeat the create with one Idempotency-Key → same ID, stored once. Change amount with the same key → 409. Amount 0/fraction, no sharers or blank description → 400.
