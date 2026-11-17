# Phase 2 run — owner manual checks

Status: advisor preparation completed; feature implementation pending. The sections below reserve the approved flow organization. Concrete task checks must be added as tasks are implemented, including invalid cases and actual URLs/commands where needed.

## With real money

Pending 2A.6. After implementation, use only an account you control for the approved 1,000 VND scan/transfer check. Verify bank, account, amount and purpose in the banking app before sending. This has not been performed by the agent.

## S5 — balances and settlement confirmation

Pending 2A.6 and 2C.4.

## S10 — members and payment methods

Pending 2A.5 and 2C.4.

## S11 — categories and budget settings

Pending 2B.6 and 2D.2.

## S14 — paying

Pending 2A.6.

## S16 — statistics and CSV

Pending 2B.4 and 2B.5.

## S17 — shared fund

Pending 2C.4.

## S4 — filters and budget banner

Pending 2B.4 and 2D.2.

## Task 0 — local capabilities

1. Open `/api/v1/features` on the local API → receiptReading, sentenceAi, telegram, push, appleSignIn and errorAlerts are all false; no sign-in required.
2. Open `/api/v1/receipts` or `/api/v1/auth/apple` → 404; no optional service is enabled.

## Core VietQR reference — 2A.1

1. After the paying screen exists, compare its reference payload with task 2A.1 before scanning → exact bytes, bank/account/amount/purpose match. Do not send money to reference accounts.
2. Call buildVietQrPayload with amount 0, 1.5 or an account containing a space → RangeError; an unknown findBank BIN returns undefined.

### Payment details API — 2A.2

1. As a viewer, PUT the complete methods list for your linked member → 200 and reloading members retains it.
2. PUT for another member → 403; sign in outside the group and retry → 404.
3. Submit a dashed bank account, unsupported BIN, duplicate method kind or short wallet phone → 400; existing saved details remain intact.
4. Save an empty methods list → 200 and no receiving details remain. Invite previews and activity details must never show bank accounts or phone numbers.

### Settlement confirmation API — 2A.3

1. In a fresh four-person group record a 600000 expense paid by Minh; as Hùng (viewer) report Hùng → Minh 150000 → pending and unchanged balances.
2. Confirm as Minh → one transfer and Hùng balance zero. Confirm again → 409 REQUEST_NOT_PENDING and still one transfer.
3. As Hùng try to report Lan's payment or confirm your own payment to linked Minh → 403. An outsider must receive 404.
4. Create another report; cancel as its creator, or reject as receiver → no ledger/balance change. Concurrent double confirmation must create one transfer.
