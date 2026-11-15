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

## Balances API (1A.6)
1. Create four people; record Minh 800000 split four, then Lan 300000 split Minh/Lan/Hùng → balances +500000,0,-300000,-200000; Hùng→Minh 300000 and Thu→Minh 200000.
2. PATCH minimizeDebts false → unchanged balances; four pairwise transfers: Lan→Minh 100000, Hùng→Minh 200000, Hùng→Lan 100000, Thu→Minh 200000.
3. Deactivate Thu → her -200000 remains; sum all balances → 0. As outsider GET balances → 404; without session → 401.

## S2 — Group list (1A.7)
1. As Minh create `Đà Lạt 12/2026` with Lan, Hùng, Thu → large yellow card with four shapes and 0; compare with GE1. Create a second group → newest large card, first compact.
2. As Lan in a private window → no groups belonging to Minh.

## S3 — New group (1A.7)
1. Tap `Tạo nhóm`, name `Đà Lạt 12/2026`, add Lan/Hùng/Thu → compare with GE8, four shapes and `Tạo nhóm 4 người`.
2. Empty group name → disabled create; Enter with spaces in `Tên người mới` → adds nothing.
3. Use Tab/Enter to add a person and create → works; double-tap create → one group.
4. Stop API and submit → save error, all form values retained. Restart and retry → one group.

## S4 — Group and expense stream (1A.8)
1. Open an empty group → compare GE14, without sentence samples/invite link; four shapes and `Ghi khoản chi đầu tiên`.
2. Record Minh 800000/four and Lan 300000/Minh,Lan,Hùng → compare GE17; Minh right/black with four 200 chips, Lan left with `phần bạn 100.000`; official block 500.000 đ.
3. Check one separator per day and newest expense just above bottom bar. With 120 expenses scroll up twice → no duplicate expense, visible row does not jump.
4. Tap yellow block or `Ai nợ ai?` → balances URL. Tap `Nhập tay` → new expense URL.
5. As Lan open Minh's private group or malformed ID → `Không tìm thấy nhóm này.`. Stop API/reload → retry error, no login redirect.

## S8 — Manual expense form (1A.9)
1. Open Nhập tay → compare GE19 without type/split switches; all seven categories. Amount is focused, you pay, all active people share.
2. Enter 180000, Cà phê, save → new expense; four-person payer balance rises by 135000.
3. Enter 100000 for three → 33334/33333/33333; save and run balance check → balanced. Double-tap save → one expense.
4. Tab through fields and shapes; Space/Enter operates controls. Screen reader reads person names and selected states.
5. Blank description/no sharers → disabled save, correct hint. Try letters and an over-limit amount → only allowed digits remain.
6. Choose a date last week using native controls → expense is under that day. Stop API/save → error, values retained; restart/retry → one expense.

## S5 — Balances and settlements (1A.10)
1. Tap group balance → compare GE5 without settlement/reminder buttons. Cable 800000/four plus Lan 300000/three → two transfers 300000 and 200000 to Minh.
2. Add signed bar values → 0. Turn Gộp nợ off → four transfers, same balances; viewer-involving cards first.
3. Add expense in another tab, reload → bars/cards agree with group balance. Deactivate someone with debt → debt remains with inactive label.
4. Open group with only a self-paid/self-shared expense → compare yellow all-settled card GE18. No expenses → `Chưa có gì để tính`. As outsider → group-not-found.

## S10 — Members (1A.11)
1. Compare GE9 without invite/claim/other-role/history controls. Add/rename an unused person → correct preview, stream/list names update; delete unused person → disappears.
2. Delete Hùng with expenses → correct cannot-delete error. Deactivate with nonzero balance → warning; Thôi keeps active, Vẫn ngừng hides him in new form but retains old rows/balance. Reactivate → back in form.
3. Your own row only edits name. Blank name → save disabled; add row at 100 members → limit message.

## S11 — Group settings (1A.11)
1. Compare name field and Gộp nợ row with GE11; no later-phase rows. Rename → group header/list update; empty name cannot save.
2. Flip Gộp nợ and view balances → transfer count changes, each balance unchanged. Stop API and toggle → error and previous switch state restored.
3. Tab/Space on switch → name Gộp nợ and correct on/off state announced by screen reader.

## Stage 1A acceptance
1. On a phone-size window create Đà Lạt 12/2026 with Minh/Lan/Hùng/Thu; record cable 800000 Minh/four, hotpot 300000 Lan/first three, coffee 100000 Minh/first three → balances +566666/-33333/-333333/-200000. Gộp nợ on → transfers 333333,200000,33333 to Minh; off → Lan→Minh 133333, Hùng→Minh 233333, Hùng→Lan 100000, Thu→Minh 200000.
2. Record coffee in three interactions after opening the form. Reload any screen → ledger/session retained.
3. Walk S2→S3→S4→S8→S5→S10→S11 with keyboard only.

## Account API (1B.2)
1. Register a fresh example.test email with a strong password → empty 204, no session. Use verification link from API console → verified account.
2. Register the same email again or uppercase → same empty 204 and no cookie. Unknown email/wrong-password login → identical INVALID_CREDENTIALS.
3. Before verification POST /groups → EMAIL_NOT_VERIFIED; after verification → succeeds. Reuse verification token → TOKEN_INVALID.
4. Six login attempts for one email → sixth RATE_LIMITED with Retry-After. Fourth resend within one hour → RATE_LIMITED.

## Password recovery and deletion API (1B.3)
1. Request reset and use console link token → new password works and all old browser sessions get 401. Weak new password → token remains usable; replay → TOKEN_INVALID.
2. Change with revokeOtherSessions true while signed in twice → current session remains, other session gets 401. Wrong current password → INVALID_CREDENTIALS.
3. Delete with wrong email → 400; own one group → OWNER_REQUIRED/groupCount 1; non-owner account → 204, cleared cookie and next request 401. After 1B.7, confirm member/transactions remain after deleting a joined account.

## After the Google OAuth app exists — 1B.4
1. Create an OAuth client of type Web application with exact redirect URI `http://localhost:3000/api/v1/auth/google/callback`; put client ID/secret in local .env and restart.
2. First real Google sign-in → verified account/identity; a matching verified password email → same account with Google identity.
3. Matching unverified password email → google_unverified, no link; known Google subject → same user.
4. Check next/redirect rejects external addresses; full round-trip and real mail remain unverified in this run. The built-in adapter replacing unavailable arctic needs advisor review before this check.

## Authentication screens — 1B.5
1. Compare /login with GE7: same shapes and headline, smaller, with the form beneath; the line about not needing a password is gone.
2. Register, open the console verification link, and sign in; sign in from a protected group URL and confirm return to that URL.
3. Register with a nine-character password and with password123 → the two messages of spec 9.2.
4. Read every sentence on the five screens for tone and spelling.
5. Try an invalid token, wrong password repeatedly, and //evil.example as next → recovery copy, rate limit, and internal landing respectively.

## Account — 1B.6
1. Tap your shape on the group list → the account screen, not an immediate sign-out.
2. Change your password with the box ticked while signed in on a second browser → the second browser is signed out on its next action.
3. Try to delete an account that owns a group → the message names how many groups.
4. Enter a wrong current password → the specified warning; use a wrong confirmation email → deletion stays disabled.

## Joining and invitation card — 1B.10
1. Compare /join/<token> with GE6 and the yellow card on the members screen with GE9.
2. As Minh copy the link; in a private window sign in as Lan, open it, pick Lan's shape → Lan lands in the group.
3. In a third window sign in as Hùng and open the link → Lan's shape is greyed with “đã có người nhận”.
4. Open a link after Minh has disabled it → “Link mời này không còn dùng được”.
5. Scan the QR using a phone camera → the same localhost join URL. Check the balance sentence before claiming a shape.

## Roles and realtime — 1B.11
1. With two windows side by side, add an expense as Minh → Lan sees it and updated balance without reload; change Lan to viewer → entry bar becomes Chỉ xem; remove Lan → list and removal message.
2. Compare settings with GE11: every row is there except Xoá nhóm (stage 1E).
3. As a Chỉ xem person try every screen → nothing lets you add or change; direct transaction form shows the permission message.
4. Turn Wi-Fi off and on with a group open → after reconnecting a change from the other window appears.
5. Check dialogs: cancel initially focused, Tab stays inside, Escape cancels, opener regains focus. Transfer ownership → settings access moves to the new owner.

## Stage 1B
1. With two phones or browser profiles, go through flow A and flow B from sign-up to both people seeing the same new expense.
2. Confirm sign-in, registration and forgot-password screens do not disclose whether an email already has an account.

## Split arithmetic — 1C.1
1. Run three rows of your choice from each task table → outputs match and each row adds up to its amount.

## Transaction types and splits — 1C.2
1. Run T1–T4 and read balances → 500001, -120000, -170001, -210000, summing to 0.
2. Run T3 alone in a new group → Lan owes each of the other three 50.000 đ.
