# Phase 2 — Stage 2A: Paying

> Part of the phase 2 plan. Read `00-overview.md` first.

**Stage goal:** every suggested transfer can be paid by scanning a code, and the ledger records it when the receiver confirms.

**Spec:** sections 3, 4, 5, 9.1–9.3, 10.

## Decisions for this stage

1. A second pending request for the same pair answers 409 `REQUEST_ALREADY_PENDING` with `details.requestId`.
2. A confirmed request's transfer has `occurredAt` = the confirmation time, the default transfer description, and `createdBy` = the confirmer.
3. `payTo` is present on every suggested transfer; it is an empty list when the receiver has no payment details.
4. A wallet number is accepted with spaces, dots, or a leading `+84`/`84`, and stored as 10 digits starting with `0`.

---

### Task 2A.1: `core` — VietQR payload and bank lookup

**Files:**
- Create: `packages/core/src/vietqr.ts`
- Existing, from the advisor: `packages/core/src/banks.ts` (`BANKS: readonly { bin: string; shortName: string; name: string }[]`)
- Modify: `packages/core/src/index.ts`

**Interfaces — produces:**
- `crc16CcittFalse(text: string): string` — four upper-case hexadecimal digits; polynomial `0x1021`, initial `0xFFFF`, no reflection, over the ASCII bytes.
- `transferPurpose(fromName: string, toName: string): string` — `SP {from} tra {to}`; names normalised with the existing diacritic remover; characters outside `[A-Za-z0-9 ]` dropped; runs of spaces collapsed; cut to 25 characters; trailing space trimmed.
- `buildVietQrPayload(input: { bankBin: string; accountNumber: string; amount: number; purpose: string }): string` — field table of spec section 4. `RangeError` when the BIN is not 6 digits, the account is not 4–19 of `[A-Za-z0-9]`, the amount is not a safe integer in 1…999,999,999,999, or the purpose is empty or longer than 25.
- `findBank(bin: string): { bin; shortName; name } | undefined`

- [ ] **Step 1: Write `vietqr.ts`**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1)**

| Call | Expected |
|---|---|
| `crc16CcittFalse("123456789")` | `29B1` |
| `transferPurpose("Hùng", "Minh")` | `SP Hung tra Minh` |
| `transferPurpose("Nguyễn Thị Thu Hằng", "Trần Minh")` | `SP Nguyen Thi Thu Hang tr` |
| `transferPurpose("A&B", "C/D")` | `SP AB tra CD` |
| `buildVietQrPayload({ bankBin: "970436", accountNumber: "0011001234567", amount: 150000, purpose: "SP Hung tra Minh" })` | `00020101021238570010A00000072701270006970436011300110012345670208QRIBFTTA530370454061500005802VN62200816SP Hung tra Minh63046329` |
| `buildVietQrPayload({ bankBin: "970422", accountNumber: "123456", amount: 1000, purpose: "SP Lan tra Minh" })` | `00020101021238500010A0000007270120000697042201061234560208QRIBFTTA5303704540410005802VN62190815SP Lan tra Minh6304A05F` |
| amount `0`; amount `1.5`; BIN `97043`; account `12 34`; purpose of 26 characters | `RangeError` each |

- [ ] **Step 4: Commit** — `feat(core): add VietQR payload builder and bank lookup`

**Manual checks for the project owner**
1. Paste the first payload into any QR generator and scan it with a banking app → Vietcombank, account 0011001234567, 150.000 đ, content `SP Hung tra Minh`. Do not send.

---

### Task 2A.2: API — payment details of a member

**Files:**
- Create: `packages/db/src/schema-payments.ts`, `packages/db/src/payment-methods.ts`, `packages/contract/src/payment.ts`, `apps/api/src/services/payment-methods.ts`, a migration
- Modify: `packages/db/src/schema.ts`, `packages/db/src/index.ts`, `packages/db/src/members.ts`, `packages/contract/src/member.ts`, `packages/contract/src/index.ts`, `apps/api/src/routes/members.ts`, `apps/api/src/services/members.ts`

**Interfaces — produces:**
- Table `member_payment_methods` exactly as spec 3.1, with `CHECK` constraints for `kind`, for `bank_bin` (6 digits when `kind = 'bank'`, NULL otherwise) and for `account_name` (NOT NULL when `kind = 'bank'`).
- `PaymentMethodInput` (Zod, discriminated on `kind`): `{ kind: "bank"; bankBin; accountNumber; accountName }` | `{ kind: "momo" | "zalopay"; phone }`. `bankBin` must satisfy `findBank`. `phone` is normalised by decision 4 and must match `^0\d{9}$`.
- `PaymentMethodDto`: `{ kind: "bank"; bankBin; bankShortName; accountNumber; accountName }` | `{ kind: "momo" | "zalopay"; phone }`.
- `MemberDto` gains `paymentMethods: PaymentMethodDto[]`.
- `PUT /groups/{groupId}/members/{memberId}/payment-methods`, body `{ methods: PaymentMethodInput[] }` (0–3, unique `kind`). Middleware minimum: viewer. Service rule: owner or editor for any member; a viewer only when `group_users.member_id` is this member; otherwise 403 `FORBIDDEN`. Replaces the member's rows in one transaction; writes an activity entry with action `update`, entity `member`, summary = the member's name, and **no** `before`/`after`. Emits `changed: ["members", "balances"]`.
- `replacePaymentMethods(tx, memberId, rows)`, `listPaymentMethodsByGroup(db, groupId): Map<memberId, rows>` in `packages/db`.

- [ ] **Step 1: Schema, migration (`drizzle-kit generate`), queries, contract, service, route**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — fresh group with the role set-up of the common file.

| Caller | Request | Expected |
|---|---|---|
| Minh | PUT for Minh: bank `970436`, `0011001234567`, `NGUYEN VAN MINH`; momo `0901 234 567` | 200; `GET …/members` shows both, the phone as `0901234567`, `bankShortName` from the list |
| Lan (editor) | PUT for Thu: zalopay `+84912345678` | 200; stored `0912345678` |
| Hùng (viewer) | PUT for Hùng: momo `0987654321` | 200 |
| Hùng | PUT for Lan | 403 `FORBIDDEN` |
| outsider | PUT for Minh | 404, body identical to a random group id |
| Minh | bank BIN `999999` | 400 `VALIDATION_FAILED` |
| Minh | two entries of kind `momo` | 400 |
| Minh | phone `12345` | 400 |
| Minh | account number `12-34` | 400 |
| Minh | `{ methods: [] }` | 200; list empty |
| Hùng (outsider of another group) | `GET /invites/{token}` of this group | no `paymentMethods` anywhere in the body |

Read the `activity_log` row for the first request: it has no account number.

- [ ] **Step 4: Commit** — `feat(api): add payment details of members`

**Manual checks for the project owner**
1. As a viewer, try to change another member's payment details with `curl` → 403.

---

### Task 2A.3: API — settlement requests

**Files:**
- Create: `packages/db/src/schema-settlements.ts`, `packages/db/src/settlement-requests.ts`, `packages/contract/src/settlement-request.ts`, `apps/api/src/services/settlement-requests.ts`, `apps/api/src/routes/settlement-requests.ts`, a migration
- Modify: `packages/db/src/schema.ts`, `packages/db/src/index.ts`, `packages/contract/src/index.ts`, `packages/contract/src/error.ts`, `apps/api/src/app.ts`

**Interfaces — consumes:** the transaction-creating service function of phase 1 (find its real name in the re-baseline table); it must be callable inside an existing database transaction. If it opens its own, split it into an outer function and an inner `createTransactionIn(tx, …)` and keep one way.

**Interfaces — produces:**
- Table `settlement_requests` as spec 5.1; `CHECK (from_member_id <> to_member_id)`; the partial unique index.
- `SettlementRequestDto`: `{ id, fromMemberId, toMemberId, amount, status, transactionId, createdBy: { id, name } | null, createdAt, resolvedAt }`.
- `ErrorCode` gains `REQUEST_NOT_PENDING` (409) and `REQUEST_ALREADY_PENDING` (409).
- The five endpoints of spec 5.3. `canActAsMember(groupUser, memberId)`: true when the caller's linked member is `memberId`. Authorisation table of spec 5.2, implemented as three small predicates in the service file: `mayCreate`, `mayResolve`, `mayCancel`.
- Confirm, in one database transaction: `SELECT … FOR UPDATE` the request; not pending → 409; create the transfer; set `status`, `transaction_id`, `resolved_by`, `resolved_at`; activity entry. Emits `changed: ["settlementRequests", "transactions", "balances", "activity"]`. Create, reject and cancel emit `changed: ["settlementRequests"]`.
- Create requires `Idempotency-Key` and goes through `runIdempotent`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 2)** — fresh group, role set-up; Minh creates expense "Lẩu" 600000, Minh pays, equal for all four. Balances: Minh +450000, Lan −150000, Hùng −150000, Thu −150000.

| # | Caller | Request | Expected |
|---|---|---|---|
| 1 | Hùng | create Hùng → Minh 150000 | 201 `pending`; balances unchanged |
| 2 | Hùng | the same again, new idempotency key | 409 `REQUEST_ALREADY_PENDING` |
| 3 | Hùng | the same again, same key as #1 | 201, same id as #1 |
| 4 | Hùng | create Lan → Minh 150000 | 403 |
| 5 | Lan | confirm #1 (the receiver is linked to Minh) | 403 |
| 6 | Hùng | confirm #1 | 403 |
| 7 | Minh | confirm #1 | 200; `transactionId` set; balances Minh +300000, Hùng 0 |
| 8 | Minh | confirm #1 again | 409 `REQUEST_NOT_PENDING`; still one transfer in the list |
| 9 | Lan | create Thu → Minh 150000 | 201 |
| 10 | Hùng | cancel #9 | 403 |
| 11 | Lan | cancel #9 | 200 `cancelled` |
| 12 | Lan | create Lan → Thu 1000 (Thu has no user) then confirm it as Lan | 201, then 200: an editor confirms for an unlinked receiver |
| 13 | Hùng | create Hùng → Thu 1000, then confirm it as Hùng | 201, then 403 |
| 14 | Minh | reject #13 | 200 `rejected`; balances unchanged |
| 15 | Hùng | amount `0`; `fromMemberId` = `toMemberId`; a member id of another group | 400; 400; 400 `MEMBER_NOT_IN_GROUP` |
| 16 | outsider | list, create | 404 |

`pnpm db:check-balances` → `All groups balanced`.

- [ ] **Step 4: Commit** — `feat(api): add settlement requests confirmed by the receiver`

**Manual checks for the project owner**
1. Two browser windows, Hùng and Minh: Hùng reports a payment, Minh's balance does not move until Minh confirms.

---

### Task 2A.4: API — `payTo` and pending requests on balances

**Files:**
- Modify: `packages/contract/src/balance.ts` (real name from the re-baseline), `apps/api/src/services/balances.ts`

**Interfaces — produces:** each element of `transfers` gains
- `payTo: Array<PaymentMethodDto & { qrPayload?: string }>` — the receiver's methods; a `bank` entry carries `qrPayload = buildVietQrPayload({ bankBin, accountNumber, amount: transfer.amount, purpose: transferPurpose(from.name, to.name) })`.
- `purpose: string` — the same purpose, for display and copying.
- `pendingRequest: { id, amount, createdByMe: boolean } | null` — the pending request of the same ordered pair.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — the group of 2A.3 before step 7, with Minh's bank details of 2A.2.

| Check | Expected |
|---|---|
| Transfer Hùng → Minh, `payTo[0].qrPayload` | the first reference string of 2A.1, byte for byte |
| The account number inside the payload | equals `payTo[0].accountNumber` |
| `pendingRequest` on Hùng → Minh, read by Hùng | `{ id, amount: 150000, createdByMe: true }` |
| The same, read by Lan | `createdByMe: false` |
| Transfer Lan → Minh | `pendingRequest: null` |
| A group whose receiver has no details | `payTo: []` |

- [ ] **Step 4: Commit** — `feat(api): add payment data and pending requests to suggested transfers`

---

### Task 2A.5: Web — payment details in the member editor

**Files:**
- Create: `apps/web/src/components/members/PaymentMethodsFields.tsx`, `apps/web/src/components/members/BankPicker.tsx`
- Modify: `apps/web/src/components/members/MemberEditor.tsx`, `apps/web/src/lib/members.ts`, `apps/web/src/messages/vi.ts`

Strings: spec section 9.3.

Behavior:
- The section is rendered for owner and editors on every member, and for a viewer only on their own member; otherwise the details are shown read-only.
- `BankPicker`: a sheet with a text field filtering the bank list by short name, name or BIN, ignoring case and diacritics. The list comes from a new endpoint-free source: `contract` re-exports `BANKS` from `core` (web may depend on `core` for display, SAD section 4).
- Account name is upper-cased and stripped of diacritics as the user types, since banking apps show it that way.
- Saving calls the PUT of 2A.2 with the whole list; an empty account number removes that method.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — add a bank and a MoMo number; reload; edit; remove; type `vietc` in the picker → Vietcombank; an account number with a dash shows `Số tài khoản chỉ gồm chữ và số.`; as Hùng (viewer) the fields are editable only on Hùng.
- [ ] **Step 4: Commit** — `feat(web): add payment details to the member editor`

**Manual checks for the project owner**
1. S10 → a member → `Thông tin nhận tiền`: add your real bank account → saved, shown after reload.
2. As a viewer, open another member → the details are visible and not editable.

---

### Task 2A.6: Web — paying screen, pending requests, stage gate

**Files:**
- Create: `apps/web/src/app/g/[groupId]/pay/page.tsx`, `apps/web/src/components/pay/QrCard.tsx`, `apps/web/src/components/pay/CopyRow.tsx`, `apps/web/src/components/balances/PendingRequestRow.tsx`, `apps/web/src/lib/settlement-requests.ts`
- Modify: the balances screen and its transfer row (real names from the re-baseline), `apps/web/src/lib/use-group-events.ts`, `apps/web/src/messages/vi.ts`

Strings: spec sections 9.1 and 9.2 (the fund lines of 9.2 belong to 2C.4).

Behavior:
- Tapping a suggested transfer opens `/g/{id}/pay?from=&to=`. The page finds the transfer in the balances query by the pair; if it is gone (paid meanwhile) it returns to S5.
- `QrCard` draws `qrPayload` with `uqr` as SVG, dark modules `#1C1B22` on white, a quiet zone of four modules, at least 240 × 240. Nothing but the payload goes in.
- Layout, top to bottom, in the 430px column: header with back and the title; the two shapes (56 points) with names and an arrow; the amount as the screen's large number; `QrCard` on a white card with radius 32; the hint; four `CopyRow`s; wallet rows; the primary button fixed at the bottom; `Ghi nhận luôn` as a text link above it for owner and editors.
- `CopyRow` copies with `navigator.clipboard.writeText` and shows `Đã sao chép` for two seconds; when the clipboard API is unavailable the value is selected instead.
- `Tôi đã chuyển` creates the request (one idempotency key per page instance), shows the confirmation line, and returns to S5. It is shown to those `mayCreate` allows; others see no primary button.
- S5: a transfer with `pendingRequest` shows `PendingRequestRow` in place of its action buttons, with the three variants of 9.2. `Đã nhận` confirms, `Chưa nhận` rejects, `Huỷ báo` cancels. A 409 shows `Yêu cầu này đã được xử lý.` and refetches.
- `settlementRequests` in an SSE event invalidates the balances query.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in two browser windows** — the flow of 2A.3 rows 1 and 7 through the screens; the receiver without details shows the empty state and, for an editor, `Thêm thông tin`; double-tap `Tôi đã chuyển` → one request; reject → the row returns to its buttons.
- [ ] **Step 4: Commit** — `feat(web): add paying screen and settlement confirmation`
- [ ] **Step 5: Stage gate 2A.** Acceptance script, on a reset database: 2A.2 rows 1–3, the 600000 expense, 2A.4 row 1, 2A.3 rows 1, 7, 8. Then the gate of the common file. Record under "Not verified": whether real banking apps accept the code.

**Manual checks for the project owner**
1. **With real money:** put your own account on one member, open a 1.000 đ debt to it, scan the code with your banking app → the bank, account, name, amount and content are all filled in and correct. Send it.
2. As the payer press `Tôi đã chuyển`; as the receiver see the line and press `Đã nhận` → the debt disappears for both.
3. Press `Chưa nhận` on another → nothing changes in the balances.
