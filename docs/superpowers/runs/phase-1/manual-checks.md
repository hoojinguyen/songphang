# Phase 1 — manual checks for the project owner

These are owner checks, not claims of verification. Use disposable local data and two independent browser profiles or phones. Evidence actually collected by the agent is in progress.md; decisions.md lists deviations for advisor review.

## Before you start

1. Run `pnpm dev`, then open `http://localhost:3000`. Use Đăng nhập thử for seeded users or register an example.test account. Read verification/reset mail only in the API console; keep links/passwords out of reports and Git.
2. Run `pnpm check`, `pnpm build`, `pnpm db:migrate` and `pnpm db:check-balances`. Migrations are repeatable; balance checking prints one balanced line per group and `All groups balanced`, or `No groups` on a clean database.
3. Inspect database tables with `docker compose exec db psql -U songphang -d songphang -c '\dt'`; ledger, identity and auth-token tables must exist. In a disposable transaction, try a 300000 expense with payer 300000 and shares 150000+140000: commit must fail its integrity constraint. A cross-group participant must also be refused.
4. From the root, run `node --input-type=module -e 'import {splitEqually} from "./packages/core/src/index.ts"; console.log(splitEqually(100000,["a","b","c"]))'`: 33334/33333/33333. Invalid zero total/empty participants throws RangeError. Pick three rows from each 1C.1 arithmetic table and compare exactly; largest remainders go to lower position on ties.
5. Repeat the screen checks below at 360×640 and with keyboard only. Every product control has a name, visible 2px ink focus with 2px offset, and sensible Tab order. Dialogs focus cancel, trap Tab, close with Escape and return focus to the opener. With a real screen reader, verify member names/selected states, phrase kinds and status/alert announcements.
6. With a group open, load stream, balances, members and history, then turn on airplane mode: cached data remains readable, write controls are disabled with `Cần có mạng để lưu.`, entry bar says `Có mạng lại là gõ tiếp được`, and nothing is queued. Restore network or stop/restart only the API: banner leaves, queries and events recover without reload. Judge shape resizing, row entrance, settlement collapse and balance count; reduced motion makes all instant. Check the primary action with a real software keyboard.

## Screens S1–S13

### S1 — Sign-in and account-entry screens

1. Compare /login with GE7: approved shapes/headline and email/password form, with the obsolete no-password claim absent. Sign in from a protected URL: return to that internal URL; `next=//evil.example` never leaves the app.
2. On /register, try a nine-character password and password123: exact approved weak-password messages. New and existing emails both produce the same 204/no-session result and generic confirmation. Uppercase email is treated consistently.
3. Open the console verification link: success; reused/invalid/expired token: recovery copy. An unverified account sees the banner and cannot create/join/write. Repeated resend and login attempts produce rate-limit copy and Retry-After (sixth login for one email; fourth resend per hour).
4. Unknown email and wrong-password login have identical INVALID_CREDENTIALS responses; known/unknown forgot-password submissions have identical generic results. Reset with a weak password leaves the token usable; successful reset revokes all old sessions, and replay is refused. Read every sentence on login/register/verify/forgot/reset for wording.

### S2 — Group list

1. Compare GE1: newest group is the large yellow card, others compact; four preview shapes and correct signed balance. Large balances and long names wrap without horizontal scrolling. Tap your own shape: account screen.
2. In an unrelated profile, private groups are absent. Group creation/removal notices appear once; reload preserves ledger/session.

### S3 — New group

1. Compare GE8. Name a group and add Lan/Hùng/Thu: four shapes and `Tạo nhóm 4 người`. Enter/Tab works; blank/whitespace names add nothing; blank group name disables create; double-tap creates one group.
2. Fail a save by stopping the API: all values remain. Restart and retry: one group. At 100 members, adding another is refused with the limit message.

### S4 — Group stream

1. Compare GE2 and empty GE14: approved title/hint and three marked sample buttons; a sample opens compose filled. Expense bubbles show the payer, original description/total and API shares; income/transfers are centered pills. Edited records have `đã sửa`.
2. Check day separators and chronological order. Scroll up through several pages: no duplicates or position jump. A remote insert more than one screen below leaves position unchanged and shows `Có khoản mới`; tap to reach the newest row.
3. Yellow balance and `Ai nợ ai?` open balances; `Nhập tay` opens the form. Viewer gets `Chỉ xem`, no entry/edit controls. An outsider/malformed group address shows not found; uncached network failure has retry, not a login redirect.

### S5 — Balances and settlements

1. Compare GE5/GE13: your transfers first, correct amounts and inactive-member badges. Sum signed balances: 0. Turn gộp nợ off: same balances, pairwise transfers; turn on: fewer transfers. A remote expense updates bars/cards live.
2. Compare GE18 after full settlement: all balances 0, no suggestions, recorded count and recent entries correct. Empty ledger says `Chưa có gì để tính`. No reminder/confirmation features appear.

### S6 — History

1. Compare GE10: newest first, day separators, actors/member shapes, time and infinite older pages. Read every sentence type once, including join/leave/removal/roles/ownership/member choice and invite/settings changes. Deleted actors become `Ai đó`.
2. Change Vé from 600000 to 800000: 600.000 struck through, 800.000 highlighted; multi-field changes have labelled payer/share/description chips reflecting stored values. API limit=2 pagination visits every entry once.
3. Restore a deleted transaction after the undo period: row and balances return, `Đã khôi phục.` appears, restore controls disappear. Viewer sees history with no restore buttons. A second window sees history changes without reload; outsider gets 404.

### S7 — Sentence compose

1. Compare GE3. Type A01/A23/A36/A43 from docs/08-quick-entry-samples.md: exact totals, payer, split and rounding. A36 gives 120000/100000/80000 and excludes Thu; its four marks cover exactly the documented phrases. A43 gives 33334/33333/33333.
2. Type slowly with accents/double spaces and paste a line break: NFC text and marks stay aligned, newline becomes space. Enter parses immediately; Shift+Enter adds nothing. No transaction exists until Lưu; double-tap Lưu creates one. Save failure keeps sentence/choices.
3. Compare GE15 for A46: two choices leave save disabled, exactly three show 60000 each and enable it; a fourth cannot be chosen. B02 asks `minh nào?`; explicit Minh Đức is the saved payer. Identical full names remain selectable by shape; no linked writer asks who paid. Several ambiguities are answered sequentially.
4. A48 requires a description. Chỉnh tay carries every understood field, including original exact inputs/remainder. Nhập tay stays one tap away. Query refresh and back navigation retain the sentence in the open tab; no draft is persisted across a full reload.

### S8 — Manual create/edit and split editor

1. Compare GE19/GE4/GE16: seven categories, labelled amounts, active participants, four split modes. New expense defaults to you/all active people; switching expense/income/transfer retains amount/description/date. In edit, type is fixed and unchanged save disabled.
2. Enter 300000 with exact 80000/60000/40000 and explicitly spread remainder: 120000/100000/80000. A 300000 total with exact 150000 and two blanks yields 150000/75000/75000. Reopen editor: original values, blanks and choice survive; remove/add participants as specified.
3. Weight 1.5/1/1 on 100 gives 43/29/28. Percent 50/30/20 on 99999 gives 49999/30000/20000. Over-summed exact parts, 99% total, mismatched payers, missing transfer receiver, empty description/no sharers or out-of-range amount cannot save. Pending preview never invents zeros.
4. A53 opens the banner/editor with 80000/60000/40000, the approved 120000 shortage sentence/status and lilac resolution action. A50/A55/A57/A59 show their specific issue lines; return to compose retains the original sentence. Pick ten sample rows including three refused cases, then five personal sentences; record read/asked/refused judgments for the advisor.
5. Reopen exact-with-blanks/remainder, weights, percent, two-payer, income and transfer records: original inputs, not final shares. Use a past date: row goes under that day. Change and save: row updates in place. Delete: six-second snackbar; Hoàn tác restores original position. Later recovery is in S6.

### S9 — Recording a settlement

1. Compare GE12. Suggested sender/receiver/amount are prefilled; record a full payment and a partial one: only unpaid debt remains. Date chips and another date work; no Nhắc/Xác nhận controls.
2. Double-tap Ghi nhận: one transfer. Empty amount disables save; made-up/self/outside-member parameters return safely to balances. Failure retains values for retry.

### S10 — Members and invitations

1. Compare GE9. Add/rename: names update everywhere, shape/color/position stay. Unused member deletes; a member with transactions cannot. Blank name cannot save; default weight 1.5 is stored 1.50, negative/invalid weight refused.
2. Deactivate a debtor: warning; Thôi keeps active, Vẫn ngừng excludes from new splits while retaining old rows/balance. Reactivate restores selection. Deleting a claimed unused member unlinks its user; that user sees the choose-shape prompt.
3. Invite card copies the exact link and offers sharing/QR. Check clipboard copy, real native share delivery and phone camera scan (same join URL). Lịch sử is beside Cài đặt nhóm; settings is owner-only.

### S11 — Group settings

1. Compare GE11. Name, gộp nợ, default role, link toggle/rotation, ownership and delete rows are present. Empty name cannot save; failed toggle restores old state. Ownership transfer moves settings access and leaves the old owner an editor.
2. Delete a disposable group: wrong/case-changed/empty/trailing-space name does not confirm; exact name enables. Delete returns owner to list with `Đã xoá nhóm.`; watching members receive removed message, all later group reads 404, dependent rows are gone and other groups unchanged.

### S12 — Join

1. Compare GE6. Open a valid invitation in an independent signed-in profile: group/owner and available shapes, claimed shapes disabled, selected balance shown before claiming. Choose your shape: join and land in stream. Alternatively create a new member; repeat join is harmless.
2. Two people claim the same shape: one succeeds, the other gets the claimed-meanwhile message and can choose again. Already joined opens the group; signed-out sign-in returns to this link. Disabled/rotated/unknown link shows the approved invalid-link screen. Check valid and invalid layouts at 360×640.

### S13 — Account

1. Password accounts show current/new password and revoke-other-sessions checkbox; Google-only/dev accounts hide that card. Wrong current password shows the approved warning. Successful change with the box checked keeps the current session and signs out the other profile.
2. Wrong confirmation email disables deletion; an owner sees the number of groups to transfer/delete first. Non-owner account deletion clears session; member names, balances and authored transactions remain, author becomes null. Sign out returns to login.

## Flows A–H

### A — Create and invite

1. Use S1→S3→S4→S10 on two phones from registration through invitation, then a shared expense. Repeat the create request with the same Idempotency-Key/body: same id; changed body/key reuse: 409. No account-enumeration difference is visible.

### B — Join, isolation and permissions

1. Exercise S12's claim/new-member paths, then run every existing group endpoint as owner/editor/viewer/outsider/signed-out using the overview matrix: appropriate 2xx/403/404/401, owner leave 422. Malformed/random/outside ids have identical normalized 404 bodies except requestId. Foreign-group members never enter a ledger.

### C — Equal-entry trip

1. Record cable 800000 paid Minh/four, hotpot 300000 paid Lan/Minh,Lan,Hùng, coffee 100000 paid Minh/three: balances 566666/-33333/-333333/-200000. Minimized: 333333,200000,33333 to Minh. Pairwise: Lan→Minh 133333, Hùng→Minh 233333, Hùng→Lan 100000, Thu→Minh 200000.
2. Record a simple coffee in three interactions after opening the manual form. Follow transaction cursors: no repeats. Amount 0/fraction, empty payer/share sets and malformed requests are refused.

### D — Unequal-entry trip

1. Record 1C T1–T4: balances 500001/-120000/-170001/-210000. T5 Thu→Minh 210000 leaves 290001/-120000/-170001/0. T3 alone: Lan owes the other three 50000 each.
2. Enter a remembered restaurant bill with personal/shared dishes through the UI and compare each amount with your own arithmetic. API split/payer total mismatch, precision and self-transfer cases are refused without changing the ledger.

### E — Reader refusal

1. Send all 75 samples to the parse endpoint: documented statuses/drafts/shares; parsing changes no transaction count. Save returned drafts and compare stored shares. Empty/301 characters: 400; viewer: 403; outsider: 404; request 121/minute: 429. Oversized descriptions/unsafe counts are refused without 500.

### F — Settle

1. Settle all suggestions from the trip, including one partial payment, on two phones. Every balance becomes 0 and transfers is empty. Finish with `pnpm db:check-balances`: `All groups balanced`.

### G — Concurrent correction

1. Open the same record in two profiles. First save succeeds; second retains local work with the exact conflict notice, current version and reload action. Explicitly load the latest version, then edit successfully. Two simultaneous same-version API writes yield one 200 and one 409.
2. An identical edit changes neither version nor history. Wrong split total/type rolls back. Deleted details remain readable but repeated delete/edit is 404; restore works once, then 404. Check balances after each state change.

### H — Membership changes

1. Add remotely: other profile updates without reload. Change a joined user to viewer: controls disappear; remove: group closes with removal message while member ledger remains. Reconnect after network loss: missed changes appear. Owner cannot leave or be removed/demoted; transfer before leaving.
2. Delete a non-owning account with linked/paid transactions: identity/session disappears while name and financial records remain. If the deleted group was the account's only owned group, account deletion now succeeds.

## After the Google OAuth app exists

1. Create the OAuth Web application with exact callback `http://localhost:3000/api/v1/auth/google/callback`; keep client id/secret in local .env and restart. Review D19's native adapter deviation before real use; Google was never contacted in this run.
2. First sign-in creates a verified user/identity. A matching verified password email links the same account; a matching unverified password email shows the approved warning and is not linked. Known subject returns to the same user.
3. Verify state/PKCE cookies, expiry, failure/cancel handling and internal-only redirects in the real round trip. Remove optional credentials: button hidden/routes 404. Real mail delivery, deployment, HTTPS and backup checks belong to the server step.
