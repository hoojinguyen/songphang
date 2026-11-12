# Phase 1 — Stage 1E: History and Polish

> Part of the phase 1 plan. Read `00-overview.md` first. Task references inside this file mean this stage's tasks.

**Stage goal:** The ledger can be used for a long time: mistakes are corrected safely, deletions can be undone, every change is visible, a group can be deleted, and the app behaves well offline and under load.

**Spec:** design spec sections 4, 5.5, 9.8–9.11; `docs/03-srs.md` FR-1.13, 1.45, 1.46, 1.70, 1.71, 1.81, 1.82, NFR-1.4, 1.9, 1.11; `docs/05-api-spec.md`; `docs/06-ux-ui/user-flows.md` flow G, sections 6–8.

## Decisions for this stage

1. `PATCH` replaces the whole transaction: its body is a create request of the same type plus `version`. Changing `type` is refused.
2. A deleted transaction is still returned by `GET …/transactions/{id}` (with `deletedAt`), so history can show and restore it.
3. Activity lines are not mixed into the expense stream (design spec section 4). An edited transaction carries the tag `đã sửa`.
4. NFR-1.9 is checked locally as: API time and payload size for the first page of a 500-transaction group, plus time to content in the browser if a browser tool is available. A real 4G measurement belongs to the server step.

## Review Focus

1. **Silent overwrite.** Two people edit one transaction; the second save gets 409 with the current version and nothing is overwritten. → 1E.1, 1E.3.
2. **Edit breaks the money invariant.** After any edit, delete or restore, payer and share totals equal the amount and `pnpm db:check-balances` passes. → 1E.1.
3. **History that lies.** Before and after values in history are the stored ones, including for amounts and splits. → 1E.2, 1E.4.
4. **Group deletion by mistake or by the wrong person.** Only the owner, only with the exact name. → 1E.2, 1E.4.
5. **Writes attempted offline.** Controls are disabled with an explanation; nothing is queued or lost silently. → 1E.5.

---

### Task 1E.1: API — read, edit, delete and restore a transaction

**Files:**
- Modify: `packages/contract/src/transaction.ts`, `packages/contract/src/error.ts`, `packages/db/src/transactions.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/routes/transactions.ts`

**Interfaces — produces:**
- `ErrorCode` gains `VERSION_CONFLICT`.
- `UpdateTransactionRequest` = `CreateTransactionRequest` with an added `version: integer ≥ 1`.

| Method | Path | Access | Behavior |
|---|---|---|---|
| GET | `…/transactions/{id}` | viewer | 200 `TransactionResponse`, deleted ones included. An id that is not a UUID or not in the group → 404. |
| PATCH | `…/transactions/{id}` | editor | Deleted → 404. `type` differs from the stored type → 400 `VALIDATION_FAILED`. One database transaction: lock the row; `version` differs → 409 `VERSION_CONFLICT` with `details.current` = the current `TransactionDto`; validate exactly as create; replace payer and share rows; set the fields, `version + 1`, `updated_by`, `updated_at`; activity row (`update`) whose `before` and `after` hold only the fields that changed among description, amount, occurredAt, category, payers, shares, split. 200 `TransactionResponse`. Nothing changed → 200, no new version, no activity row. |
| DELETE | `…/transactions/{id}` | editor | Already deleted → 404. Sets `deleted_at`; activity row (`delete`) with a `before` snapshot. 204. |
| POST | `…/transactions/{id}/restore` | editor | Not deleted → 404. Clears `deleted_at`; activity row (`restore`). 200 `TransactionResponse`. |

Each publishes `transactions`, `balances`, `activity`.

- [ ] **Step 1: Write the schema, queries, service functions and routes**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1, 2)**

| Request | Expected |
|---|---|
| Create "Vé" 600000 split four; `PATCH` to 800000 with `version: 1` | 200; `version: 2`; shares 200000 each; balances changed |
| The same `PATCH` again with `version: 1` | 409 `VERSION_CONFLICT`; `details.current.version` is 2 and amount 800000; stored data unchanged |
| `PATCH` with `version: 2` changing the split to exact with a wrong sum | 400 `SPLIT_TOTAL_MISMATCH`; stored shares unchanged (the whole edit rolled back) |
| `PATCH` an expense with `type: "transfer"` | 400 |
| `PATCH` with identical content | 200, `version` unchanged, no new activity row |
| `DELETE` | 204; gone from the list; balances as if it never existed; `GET` by id still returns it with `deletedAt` |
| `DELETE` again; `PATCH` it | 404; 404 |
| `restore` | 200; back in the list at its original time; balances restored |
| `restore` again | 404 |
| Two `PATCH` requests with the same version at the same moment (`&`) | one 200, one 409 |
| Viewer: `PATCH`, `DELETE`, `restore` | 403; outsider 404 |

After each row `pnpm db:check-balances` is balanced. The activity row of the first edit has `before.amount` 600000 and `after.amount` 800000 and the changed shares.

- [ ] **Step 4: Commit** — `feat(api): add transaction editing, deletion, and restoring`

---

### Task 1E.2: API — activity feed and group deletion

**Files:**
- Create: `packages/contract/src/activity.ts`, `apps/api/src/services/activity.ts`, `apps/api/src/routes/activity.ts`
- Modify: `packages/db/src/activity.ts`, `packages/contract/src/group.ts`, `apps/api/src/services/groups.ts`, `apps/api/src/routes/groups.ts`

**Interfaces — produces:**
- `ActivityDto` = `{ id; actor: { userId: uuid; name: string; memberId: uuid | null } | null; action: string; entityType: "transaction" | "member" | "group" | "group_user"; entityId: uuid | null; summary: string; before: Record<string, unknown> | null; after: Record<string, unknown> | null; createdAt: string; canRestore: boolean }` — `canRestore` is true for a `delete` of a transaction that is still deleted.
- `ActivityResponse` = `{ activity: ActivityDto[]; nextCursor: string | null }`; query as the transaction list (`cursor`, `limit` 1–200, default 50).
- `DeleteGroupRequest` = `{ name: string }`.

| Method | Path | Access | Behavior |
|---|---|---|---|
| GET | `/groups/{groupId}/activity` | viewer | Newest first, keyset-paginated on `created_at, id`. `actor` is null when the user was deleted. |
| DELETE | `/groups/{groupId}` | owner | `name` not exactly equal to the group's name → 400 `VALIDATION_FAILED`. Deletes the group (everything cascades); publishes `removed` to all; 204. |

Before writing the route, review every `insertActivity` call of stages 1A–1C: each must carry what section "History sentences" of Task 1E.4 needs (for example the member's name on join, the member count on group creation, sender, receiver and amount for a transfer). Add missing fields to `after`.

- [ ] **Step 1: Write the schema, service, routes; complete the activity payloads**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3, 4):** after the 1E.1 exercise, `GET …/activity` lists create, update (600000 → 800000), delete, restore in reverse order with correct actors; `canRestore` is true only on a delete whose transaction is still deleted; pagination with `limit=2` walks the whole list without repeats; an outsider gets 404. Delete group: editor → 403; owner with a wrong name, a name differing only in case, and an empty name → 400; owner with the exact name → 204, a listener on the event stream receives `removed`, every later request on the group is 404, `select count(*)` of its members, transactions and activity rows is 0, other groups are untouched; `DELETE /me` now succeeds for a user whose only owned group was deleted.
- [ ] **Step 4: Commit** — `feat(api): add activity feed and group deletion`

---

### Task 1E.3: Web — edit, delete with undo, conflict

**Files:**
- Create: `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx`, `apps/web/src/components/ui/Snackbar.tsx`, `apps/web/src/components/expense-form/ConflictNotice.tsx`
- Modify: `apps/web/src/components/expense-form/ExpenseForm.tsx`, `apps/web/src/components/feed/ExpenseRow.tsx`, `LedgerPill.tsx`, `apps/web/src/lib/transactions.ts`, `apps/web/src/app/g/[groupId]/layout.tsx`, `apps/web/src/messages/vi.ts`

**Interfaces — produces:** `useTransaction(groupId, id)`, `useUpdateTransaction`, `useDeleteTransaction`, `useRestoreTransaction`; `Snackbar` — one message at a time, rendered by the group layout, `role="status"`, an optional action button, dismissed after 6 seconds or by its close button; `useSnackbar()`.

Strings: design spec 9.9, plus:

| Key | Value |
|---|---|
| `expenseForm.titleEditTransfer` | `Sửa chuyển khoản` |
| `expenseForm.titleEditIncome` | `Sửa khoản thu` |
| `expenseForm.saveChanges` | `Lưu thay đổi` |
| `feed.editRow` | `Sửa {description}` |
| `expenseForm.deletedNotice` | `Khoản này đã bị xoá. Bạn có thể khôi phục từ Lịch sử.` |
| `expenseForm.restored` | `Đã khôi phục.` |

Behavior:

| Part | Behavior |
|---|---|
| Stream | For editors each row and pill is a link labelled `feed.editRow` to `/g/{id}/tx/{transactionId}`. A transaction with `version > 1` shows the tag `đã sửa` (11px weight 700, muted on surface, `on-ink-muted` on ink). Viewers get no link. |
| Edit form | The same form component, filled from the transaction: type fixed (no switch), amount, description, category, payers, date, and the split from `split` — the exact numbers the user entered, in the mode they used, including blank fields and the "còn lại" choice (FR-1.45). Title by type; button `expenseForm.saveChanges`, enabled when something changed and the state is saveable. A deleted transaction shows `expenseForm.deletedNotice` and no form. |
| Save | `PATCH` with the loaded `version`. Success → back to the stream, row updated in place. |
| Conflict | 409 → `ConflictNotice` above the save button: the message of spec 9.9 with the name of `details.current`'s last editor when known (otherwise `Có người`), and a button `Xem bản mới` that reloads the form from `details.current`, discarding the local edits. Saving is disabled until then. |
| Delete | A `debt-soft` button `Xoá khoản này` at the bottom of the edit form; no confirmation (flow G). On 204 → back to the stream and a snackbar `Đã xoá.` with `Hoàn tác`, which calls restore and shows `expenseForm.restored`. |
| Realtime | If a `changed` event arrives for transactions while the edit form is open and the transaction's version on the server is now higher, show the `ConflictNotice` at once. |

- [ ] **Step 1: Write hooks, components, page**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 1):** edit each kind made in 1C (exact with blanks, exact with "còn lại", weights, percent, two payers, transfer, income) and confirm the form shows the original inputs, not the computed shares; change an amount and save; with two windows open the same expense, save in one, then save in the other → the notice, "Xem bản mới", then a successful save; delete → snackbar → "Hoàn tác" restores it at the same place; delete and let the snackbar expire → still restorable from history (1E.4); a viewer cannot open the edit address (forbidden message); `pnpm db:check-balances`.
- [ ] **Step 4: Commit** — `feat(web): add transaction editing, deletion with undo, and conflict handling`

**Manual checks for the project owner**
1. Tap an expense you entered with "còn lại chia đều" → the form shows your three personal amounts and the lilac choice, not the final shares.
2. With two windows, do the conflict scenario → the second person is told and nothing is overwritten.
3. Delete an expense and tap "Hoàn tác" within six seconds → it is back.

---

### Task 1E.4: Web — history and deleting a group (S6, S11)

**Files:**
- Create: `apps/web/src/lib/activity.ts`, `apps/web/src/lib/activity-sentences.ts`, `apps/web/src/components/activity/ActivityRow.tsx`, `ChangeChips.tsx`, `apps/web/src/app/g/[groupId]/activity/page.tsx`, `apps/web/src/components/settings/DeleteGroupCard.tsx`
- Modify: the members page (adds the `Lịch sử` link beside `Cài đặt nhóm`, both `flex: 1`, height 60), the settings page, `apps/web/src/messages/vi.ts`

**History sentences.** `describeActivity(entry, members): { text parts; chips }` maps each entry to one sentence. `{actor}` is the actor's name, or `Ai đó` when null; bold parts are weight 800.

| Action · entity | Sentence |
|---|---|
| create · transaction (expense) | `{actor} thêm {summary} · {amount}` |
| create · transaction (income) | `{actor} thêm khoản thu {summary} · {amount}` |
| create · transaction (transfer) | `{actor} ghi nhận {from} đã chuyển {amount} cho {to}` |
| update · transaction | `{actor} sửa {summary}` + chips |
| delete · transaction | `{actor} xoá {summary} · {amount}` + restore button when `canRestore` |
| restore · transaction | `{actor} khôi phục {summary} · {amount}` |
| create · group | `{actor} tạo nhóm với {count} người` |
| update · group (name) | `{actor} đổi tên nhóm` + chips |
| update · group (minimize) | `{actor} bật gộp nợ` / `{actor} tắt gộp nợ` |
| update · group (default role) | `{actor} đổi quyền mặc định thành {role}` |
| update · group (invite toggled) | `{actor} bật link mời` / `{actor} tắt link mời` |
| update · group (invite rotated) | `{actor} tạo link mời mới` |
| create · member | `{actor} thêm {member}` |
| update · member (name) | `{actor} đổi tên thành viên` + chips |
| update · member (active) | `{actor} cho {member} ngừng hoạt động` / `{actor} cho {member} hoạt động lại` |
| delete · member | `{actor} xoá {member}` |
| join · group_user | `{actor} vào nhóm, nhận hình của {member}` |
| leave · group_user | `{actor} rời nhóm` |
| remove · group_user | `{actor} gỡ {name} khỏi nhóm` |
| role_change · group_user | `{actor} đổi quyền của {name} thành {role}` |
| transfer ownership | `{actor} chuyển quyền chủ nhóm cho {name}` |
| member chosen | `{actor} nhận hình của {member}` |

Chips (`ChangeChips`, GE10): one pair per changed field, old value struck through on `bg`, an arrow, new value on `phrase-amount`; radius 12, padding 5/10, 13px weight 700. Field labels precede a pair when more than one field changed: `Số tiền`, `Mô tả`, `Ngày giờ`, `Danh mục`, `Người trả`, `Cách chia`. Amounts use `formatAmount`; "Người trả" and "Cách chia" show names with amounts.

Other strings:

| Key | Value |
|---|---|
| `activity.title` | `Lịch sử` |
| `activity.headline` | `Ai đã đổi gì` |
| `activity.someone` | `Ai đó` |
| `activity.loadingOlder` | `Đang tải thay đổi cũ hơn…` |
| `settings.deleteHint` | `Xoá nhóm là xoá mọi khoản chi. Bạn sẽ phải gõ lại tên nhóm.` |
| `settings.deleteButton` | `Xoá nhóm` |
| `groups.deleted` | `Đã xoá nhóm.` |

Screen behavior:

| Screen | Behavior |
|---|---|
| S6 `/g/{groupId}/activity` (GE10) | `ScreenHeader`: `activity.title`, subtitle the group name, back to members. `activity.headline` 30px weight 900. Entries newest first, grouped under day separators as in the stream. `ActivityRow`: surface, radius 26, padding 12/14; the actor's member shape at 40 (a `sunken` circle when unknown); the sentence 14px, line height 1.45; chips; the restore button (ink, height 44, `Khôi phục`) for editors; the time `HH:mm` 12px muted. An infinite list loading older entries at the bottom. Empty: `Chưa có thay đổi nào`. Restoring shows `Đã khôi phục.` and the button disappears. |
| S11 `DeleteGroupCard` (GE11) | At the bottom: background `debt-soft`, radius 28, `settings.deleteHint` 12px weight 600 and an ink button `settings.deleteButton`, height 48. It opens the `ConfirmDialog` of spec 9.8 with a `TextField`; the confirm button enables only on an exact match of the name. On 204: clear the group's queries, go to `/`, snackbar-style line `groups.deleted` on S2. |

- [ ] **Step 1: Write hooks, sentence mapping, components, pages**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 3, 4):** produce at least one entry of every row of the sentence table and read each sentence; the edited expense shows `600.000` struck through and `800.000`; a multi-field edit shows labelled chips; restore from history a deletion whose snackbar expired; a viewer sees history without restore buttons; a second window receives new entries live; delete group: wrong name keeps the button disabled, exact name deletes, a member watching the group in another window is sent to the list with the removed message.
- [ ] **Step 4: Commit** — `feat(web): add history screen and group deletion`

**Manual checks for the project owner**
1. Compare history with GE10.
2. Read every kind of sentence once for wording.
3. Delete a test group: confirm you must type its exact name.

---

### Task 1E.5: Web — offline state, new-item pill, motion

**Files:**
- Create: `apps/web/src/lib/use-online.ts`, `apps/web/src/components/ui/OfflineBanner.tsx`, `apps/web/src/components/feed/NewItemsPill.tsx`
- Modify: `apps/web/src/app/layout.tsx` or the group layout, `EntryBar.tsx`, every write control, `ExpenseStream.tsx`, `ShareShapes.tsx`, `SettlementCard.tsx`, `BalanceBlock.tsx`, `apps/web/src/app/providers.tsx`, `apps/web/src/app/globals.css`, `apps/web/src/messages/vi.ts`

Strings: design spec 9.10, plus `offline.since` = `lúc {time}` and `offline.writeDisabled` = `Cần có mạng để lưu.`

Behavior:

| Part | Behavior |
|---|---|
| `useOnline()` | `navigator.onLine` with the `online` and `offline` events; also false after a request fails with `code: "NETWORK"` until one succeeds. |
| `OfflineBanner` (GE17) | At the top of every screen while offline: ink background, white text, radius 22, padding 12/16, 13px weight 700, a wifi-off icon, the banner text, and `offline.since` with the time the connection was lost, in `on-ink-muted`. `role="status"`. |
| While offline | Loaded data stays on screen: queries keep their cache and do not show error states for network failures when cached data exists. `EntryBar` becomes a `sunken` bar reading `Có mạng lại là gõ tiếp được`. Every save, delete, add and toggle control is disabled with `aria-disabled` and the line `offline.writeDisabled` near the primary button. Nothing is queued. |
| Back online | The banner leaves; the group's queries are invalidated; the event stream reconnects (FR-1.82). |
| `NewItemsPill` | When a new transaction arrives while the viewer has scrolled up more than one screen, the view does not move and a pill `Có khoản mới` (ink, height 44, radius 22) appears above the entry bar; tapping scrolls to the bottom. A new row otherwise fades and rises 8px over 200 ms. |
| Motion | `ShareShapes`: size changes use a 300 ms spring-like `cubic-bezier(0.34, 1.56, 0.64, 1)` transition. Settlement recorded: the card scales to 0.9 and fades over 200 ms; the balance block's number counts to its new value over 400 ms (display only, integer steps). All of it is wrapped in `@media (prefers-reduced-motion: no-preference)`; otherwise states change at once. |

Add the `wifi-off` icon: `M3 9c5-5 13-5 18 0M6.5 12.5c3-3 8-3 11 0M10 16c1.2-1 2.8-1 4 0M4 4l16 16`.

- [ ] **Step 1: Write the hook and components; wire every write control**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 5):** with browser devtools set offline: banner appears with the time; stream, balances, members and history already opened remain readable and navigable; the entry bar and every button listed are disabled with the explanation; back online: banner leaves and a change made meanwhile in another window appears without reload. Stop only the API (network up): the same disabled state after the first failed request, and recovery after restart. Enable "reduce motion" in the OS or devtools: no animation anywhere. Record the motion checks under "Not verified" if no browser tool is available.
- [ ] **Step 4: Commit** — `feat(web): add offline state, new-item pill, and motion`

**Manual checks for the project owner**
1. Compare the offline group screen with GE17.
2. Turn on airplane mode with a group open: read old expenses, open balances, try to add → not possible, with the reason shown.
3. Judge the four motions of the design document; with "giảm chuyển động" on, none of them plays.

---

### Task 1E.6: Non-functional checks and final gate

**Files:**
- Modify: `README.md`; fixes wherever the checks find problems

- [ ] **Step 1: Load (NFR-1.9).** In a group with four members insert 500 transactions through the API in a shell loop. Record: time and response size of `GET …/transactions?limit=50`, `GET …/balances` (both modes) and `GET /groups`, each as the median of five runs; the number of SQL statements each issues (enable statement logging temporarily, then disable). Targets on the local machine: each under 200 ms and no statement count that grows with the number of transactions returned. If a browser tool is available, record time until the newest expense is visible on a cold load with 4G throttling; target under 2 seconds.
- [ ] **Step 2: Keyboard and screen reader (NFR-1.11).** Walk every screen S1–S13 with the keyboard only: every control reachable in a sensible order, visible focus (2px ink outline, 2px offset) everywhere, no trap outside dialogs. Check with the accessibility tree that every button and field has a name, member shapes are named by the person, and status and alert regions announce. Fix what fails.
- [ ] **Step 3: Contrast (NFR-1.11).** Compute the contrast ratio of every text and background token pair in use (ink on mint, sky, coral, lilac, accent, each phrase color, `debt-soft`, `sunken`; muted on bg, surface, `sunken`; `on-ink-muted` on ink and `ink-raised`; white on ink). Record the table. Any pair under 4.5:1 for text below 24px is a finding: record it in `decisions.md` with the measured ratio and the smallest token change that fixes it, and apply that change.
- [ ] **Step 4: Narrow screens (NFR-1.7).** Every screen at 360 × 640: no horizontal scroll, primary action reachable without scrolling past the keyboard.
- [ ] **Step 5: README.** Add: the phase 1 feature list in three lines, how to read mails in development (the API console), the optional Google variables, and `pnpm db:check-balances`.
- [ ] **Step 6: Final gate.** Run the stage gate. Acceptance script for this stage, reset database, `curl` only — the roadmap's sample trip with several users:
  1. Minh (dev login) creates "Đà Lạt 12/2026" with Lan, Hùng, Thu; Lan and Hùng join by link; a newly registered and verified Ngân joins as a new member and is made a viewer.
  2. Lan parses and saves `lẩu 300k, mình trả. mình 80 hùng 40 thu 60, còn lại chia đều` → payer Lan; shares Lan 120000, Hùng 80000, Thu 100000. Minh creates T2–T4 of Task 1C.2.
  3. Minh edits the "Lẩu" total to 330000 keeping the personal parts and the remainder choice → shares Lan 130000, Hùng 90000, Thu 110000, `version` 2; an edit by Lan still carrying `version: 1` → 409.
  4. Hùng deletes T4 and restores it from the activity list.
  5. Record balances; settle every suggested transfer with transfers; balances are all 0; `transfers` is empty.
  6. History lists every step with the right actor.
  7. Minh deletes the group with its exact name; Lan's requests are 404.
  8. `pnpm db:check-balances`; then the acceptance scripts of 1A–1D; then the whole permission matrix.
- [ ] **Step 7: Finish the run files.** `manual-checks.md` is complete, ordered by screen S1–S13 and then by flow A–H, with no duplicates; `progress.md` has a final summary: tasks done, unresolved items, gates not passed, not verified, and the count of decisions. Commit: `docs(run): complete phase 1 run records`.

After Step 7 the run is over. Do not merge, push, or start anything else.

**Manual checks for the project owner — phase 1 completion criteria**
1. Go through one sample trip on two phones from invitation to everyone settled, typing and using the form, editing and deleting along the way (roadmap, phase 1 completion criteria).
2. Run `pnpm db:check-balances` at the end → `All groups balanced`.
3. Work through `manual-checks.md`.
