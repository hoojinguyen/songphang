# Phase 3 — Stage 3C: Split by Items

> Part of the phase 3 plan. Read `00-overview.md` and spec section 15 first. Advisor revision 2026-11-17: pending owner review; do not execute yet.

**Stage goal:** a bill's items are assigned to people, tax and fees follow each person's part, and the scan's reading becomes a saved expense after review.

**Spec:** sections 6, 8.1, 8.2, 10.

## Decisions for this stage

1. Items are stored only in `split_input`; no item table is created (spec section 6).
2. An item's amount may be 0 (a free item); it must still have a member.
3. When every subtotal is 0 and the net extra is positive, the extra is split equally among the members named in any item, by the same rounding function.
4. Shares come back for every member named in any item, in position order.
5. The review screen uses the dedicated `items/preview` calculation contract of spec 15.4 and ordinary transaction `preview`/`create`; it holds no arithmetic beyond integer subtraction for the "Dùng {total}" difference.

---

### Task 3C.1: `core` — the items split

**Files:**
- Create: `packages/core/src/split-items.ts`
- Modify: `packages/core/src/split.ts` (the `SplitInput` union and `computeShares` dispatch), `packages/core/src/index.ts`

**Interfaces — consumes:** `allocateByWeights(total, weights)` from phase 1 stage 1C.

**Interfaces — produces:**
- `SplitInput` gains `{ method: "items"; items: Array<{ name: string; amount: number; memberIds: string[] }>; extras: Array<{ kind: "tax" | "service" | "discount" | "other"; label: string; amount: number }> }`.
- `computeItemShares(amount, split, memberIdsByPosition)` returning the same result type as `computeShares`, with the extra failure `{ ok: false; code: "ITEM_UNASSIGNED"; itemIndex: number }`.

Algorithm, integers and `BigInt` only:

1. An item with no member → `ITEM_UNASSIGNED` with the first such index.
2. For each item, `allocateByWeights(item.amount, [1, …])` over its members **in position order**; add each part to that member's subtotal.
3. `net = Σ tax, service, other − Σ discount`. `itemsTotal + net ≠ amount` → `SPLIT_TOTAL_MISMATCH` with `expected: amount`, `actual: itemsTotal + net`.
4. `net ≥ 0`: `parts = allocateByWeights(net, subtotals)` (decision 3 when all subtotals are 0); share = subtotal + part.
5. `net < 0`: `parts = allocateByWeights(−net, subtotals)`; share = subtotal − part. Because `−net ≤ itemsTotal` whenever `amount ≥ 0`, and parts are proportional with largest-remainder rounding, verify in the exercise that no share is negative; if a share would be negative, return `SPLIT_TOTAL_MISMATCH`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)** — members a, b, c in position order.

| Amount | Items | Extras | Expected shares a, b, c |
|---|---|---|---|
| 442000 | Lẩu 350000 [a, b, c]; Bia 90000 [a] | service 22000; discount 20000 | 207607, 117197, 117196 |
| 440000 | same | none | 206667, 116667, 116666 |
| 420000 | same | discount 20000 | 197273, 111364, 111363 |
| 100000 | Nước 100000 [a, b, c] | none | 33334, 33333, 33333 |
| 60000 | A 10000 [a]; B 100000 [b] | discount 50000 | 5455, 54545 (a, b) |
| 30000 | A 0 [a]; B 0 [b] | service 30000 | 15000, 15000 (a, b) |
| 442000 | Lẩu 350000 [a, b, c]; Bia 90000 [] | service 22000; discount 20000 | `ITEM_UNASSIGNED`, index 1 |
| 450000 | first row's items and extras | | `SPLIT_TOTAL_MISMATCH`, expected 450000, actual 442000 |
| 110000 | Lẩu 100000 [a, b] | tax 8000; other 2000 | 55000, 55000 |

Each row's shares sum to its amount. For row 1, record the intermediate values: subtotals 206667, 116667, 116666; extra parts 940, 530, 530.

- [ ] **Step 4: Commit** — `feat(core): add split by items with proportional extras`

**Manual checks for the project owner**
1. Run rows 1 and 3 → the outputs match and add up.

---

### Task 3C.2: API — the `items` split method

**Files:**
- Create: a migration (the `split_method` check gains `'items'`)
- Modify: `packages/contract/src/transaction.ts`, `packages/contract/src/error.ts`, `packages/db/src/schema-transactions.ts`, `apps/api/src/services/transactions.ts`

**Interfaces — produces:**
- `ItemsSplitInput` (Zod): 1–60 items; `name` 1–80 trimmed; `amount` integer 0…999,999,999,999; `memberIds` 0–20 unique uuids (an empty list is valid for the schema and refused by `core`, so the error names the item); 0–6 extras; `label` 0–40.
- `ErrorCode` gains `ITEM_UNASSIGNED` (400, `details.itemIndex`).
- `preview`, create and edit accept the method for `expense` only; `income` with `items` → 400. The fund (phase 2, if merged) may not be in any `memberIds` → 422 `FUND_CANNOT_SHARE`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — fresh group Minh, Lan, Hùng.

| Request | Expected |
|---|---|
| preview row 1 of 3C.1 (a, b, c = Minh, Lan, Hùng), Minh pays | shares 207607, 117197, 117196; nothing stored |
| create it with a photo's `attachmentIds` | 201; `split` echoed with items and extras; balances Minh +234393, Lan −117197, Hùng −117196 |
| `GET` it | `split.method` `items`, items in the order sent |
| edit: move Bia to Lan | shares 117197, 207607, 117196; balances Minh +324803, Lan −207607, Hùng −117196 |
| an item with `memberIds: []` | 400 `ITEM_UNASSIGNED`, `itemIndex` |
| amount 450000 | 400 `SPLIT_TOTAL_MISMATCH` |
| 61 items; an item amount `1.5`; a member id of another group | 400; 400; 400 `MEMBER_NOT_IN_GROUP` |
| income with `items` | 400 |

For the edit row, verify by hand before trusting it: subtotals 116667, 206667, 116666; extra 2000 → integer parts 530, 939, 530 with the one leftover đồng going to Lan (largest remainder) → 530, 940, 530. `pnpm db:check-balances` → `All groups balanced`.

- [ ] **Step 4: Commit** — `feat(api): accept the items split method`

---

### Task 3C.3: Web — camera in the entry bar and the review screen

**Files:**
- Create: `apps/web/src/components/feed/CameraButton.tsx`, `apps/web/src/components/receipt/ReceiptReview.tsx`, `apps/web/src/components/receipt/ItemRow.tsx`, `apps/web/src/components/receipt/ExtrasFields.tsx`, `apps/web/src/components/receipt/MismatchNotice.tsx`, `apps/web/src/lib/receipt-scans.ts`, `apps/web/src/lib/features.ts`
- Modify: `EntryBar.tsx`, `apps/web/src/app/g/[groupId]/tx/new/page.tsx` (the `?scan=` branch), `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`

Strings: spec sections 8.1 and 8.2.

Behavior:
- `useFeatures()` reads `GET /features` once per session. The camera button exists only when `receiptReading` is true and the role can write.
- `CameraButton` opens a native chooser through two hidden file inputs: one with `accept="image/*" capture="environment"` (`Chụp ảnh`), one without `capture` (`Chọn từ thư viện`). The file goes through `prepareImage`, is uploaded, a scan is created, and the page navigates to `/g/{id}/tx/new?scan={scanId}`.
- The review page listens for the `receiptScans` event and refetches; as a fallback it refetches every 3 seconds while the status is `queued` or `processing`, and gives up with the failed state after 60 seconds.
- `ReceiptReview` state is a list of items (`name`, `amount`, `memberIds`), extras, description, date and payer, initialised from the reading: description = `merchant` or `Hoá đơn`; date = `occurredOn` or today; payer = the user's own member; every item starts with no member.
- Selecting an item gives it the 3-point border; tapping a member shape toggles that member on the selected item. `Chia đều các món còn lại` puts all active people on every item that has none.
- After each change, debounced 300 ms, call `POST …/transactions/items/preview` with `{ items, extras }` and show each person's share under their shape. While the preview is refused for `ITEM_UNASSIGNED`, the shares row shows the save-blocked line with the count and Lưu is disabled.
- `MismatchNotice` appears when the scan has `TOTAL_MISMATCH` and the user has not chosen. `Dùng {computed}` sets the amount to the items' computed total. `Dùng {total}` sets the amount to the printed total and appends an extra labelled `Chênh lệch`: kind `other` with `total − computed` when positive, kind `discount` with `computed − total` when negative. After any edit to items or extras the amount follows `computedAmount` returned by `items/preview`, and the notice is gone. The browser does not sum money.
- Lưu sends an ordinary create with the photo's id in `attachmentIds` and one idempotency key per page instance, then returns to S4.
- `Nhập tay` from a failed state opens the manual form with the attachment id carried in the URL.
- The manual form's split chooser gains `Theo món`, which opens the same item editor without a scan.
- The AI note of 8.2 is always visible under the title.

Layout numbers: take the confirmation card's (S7) spacing; `ItemRow` is 56 points tall: name left, amount right in weight 700, member shapes (24 points) beneath the name, `Chưa ai` in secondary text when empty.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser, `AI_PROVIDER=fake`** — `clean.jpg`: review, assign, shares equal an API preview, save, the expense appears with its photo mark. `mismatch.jpg`: the notice, both choices, each saves and sums. `not-a-receipt.jpg`: the not-a-receipt state and `Nhập tay` with the photo attached. Any other image: the fixed three items. Edit an amount, add and remove an item. Double-tap Lưu → one expense. With `AI_PROVIDER` unset: no camera button.
- [ ] **Step 4: Commit** — `feat(web): add receipt capture and item-by-item review`

**Manual checks for the project owner**
1. With the fake provider: tap the camera, pick any photo → three items appear; tap an item, tap two people → their shares appear; `Chia đều các món còn lại`; Lưu.
2. Leave one item with nobody → Lưu is disabled and says how many items remain.

---

### Task 3C.4: Stage gate 3C

- [ ] **Step 1:** Acceptance script on a reset database: 3C.1 rows 1, 3, 7 through `preview`; 3C.2 rows 2 and 4 with the balances.
- [ ] **Step 2:** The gate of the common file.
- [ ] **Step 3:** Time one full run with the fake provider from tapping the camera to the saved expense, by hand with a stopwatch, and record it against the one-minute target. Record under "Not verified": the same with a real receipt and the real provider.


**Additional task 3C.2 contract:** add the editor-only `POST …/transactions/items/preview` request/response defined in spec 15.4, with group middleware, ordinary write protections and core-only sums/allocations. Include structural invalid input, unassigned items, fund participation, and totals outside the transaction bound in its permission/acceptance matrix.

**Additional task 3C.3 behavior:** use spec 15.4's total-only initialization and six-extra mismatch handling. For the named browser fixture cases, restart the isolated fake runtime with the matching `AI_FAKE_RECEIPT_FIXTURE` value; original SHA-256s alone do not survive `prepareImage`. All numerical reference tables above remain unchanged.
