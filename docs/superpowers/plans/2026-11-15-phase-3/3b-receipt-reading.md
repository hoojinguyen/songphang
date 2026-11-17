# Phase 3 — Stage 3B: Receipt Reading

> Part of the phase 3 plan. Read `00-overview.md` and spec section 15 first. Advisor revision approved 2026-11-17; preparation authorized, execution withheld. Do not execute yet.

**Stage goal:** a photo of a bill becomes a validated list of items, extras and a total, within a fixed budget of calls. Nothing reaches the ledger in this stage; the review screen is stage 3C.

**Spec:** section 5, 9, 10.

## Decisions for this stage

1. A reading with a total and no items is `done` with the flag `NO_ITEMS`; a reading with items and no total is `done` with `TOTAL_MISSING`. Only "no items and no total" is `failed` / `NOT_A_RECEIPT`.
2. A provider error or timeout after the one retry is `failed` / `READER_UNAVAILABLE`. An answer that fails the Zod schema is `failed` / `READER_INVALID`. Both write an `ai_calls` row with `ok = false`.
3. Quota days and months are Vietnam calendar days and months.
4. A scan may be created once per attachment; a second request returns the existing scan (200).

---

### Task 3B.1: Contract and `core` — the reading and its check

**Files:**
- Create: `packages/contract/src/receipt.ts`, `packages/core/src/receipt.ts`
- Modify: `packages/contract/src/index.ts`, `packages/core/src/index.ts`

**Interfaces — produces:**
- `ReceiptReading` (Zod), exactly the table of spec 5.3; every amount is `z.int()` in 0…999,999,999,999; strings are trimmed; unknown keys are stripped.
- `checkReceipt(reading): { status: "done"; computed: number; flags: Array<"TOTAL_MISMATCH" | "TOTAL_MISSING" | "NO_ITEMS"> } | { status: "failed"; errorCode: "NOT_A_RECEIPT" }` — `computed = Σ items.amount + Σ extras(tax, service, other).amount − Σ extras(discount).amount`, integer addition only.
- `ReceiptScanDto`: `{ id, attachmentId, status, reading: ReceiptReading | null, computed: number | null, flags: string[], errorCode: string | null, createdAt }`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Items | Extras | Total | Expected |
|---|---|---|---|
| 350000, 90000 | service 22000, discount 20000 | 442000 | `done`, computed 442000, flags none |
| same | same | 450000 | `done`, computed 442000, `TOTAL_MISMATCH` |
| same | same | null | `done`, computed 442000, `TOTAL_MISSING` |
| none | none | 500000 | `done`, computed 0, `NO_ITEMS`, `TOTAL_MISMATCH` |
| none | none | null | `failed`, `NOT_A_RECEIPT` |
| 100000 | tax 8000, other 2000 | 110000 | `done`, computed 110000 |

Schema: an item amount `12.5`, an amount as the string `"12000"`, 61 items, a `kind` of `"tip"` → each fails to parse.

- [ ] **Step 4: Commit** — `feat(core): add receipt reading schema and arithmetic check`

---

### Task 3B.2: Reader adapters, the cost ledger, quotas

**Files:**
- Create: `apps/worker/src/ai/receipt-reader.ts` (interface and selection), `apps/worker/src/ai/anthropic-receipt-reader.ts`, `apps/worker/src/ai/fake-receipt-reader.ts`, `apps/worker/src/ai/anthropic-client.ts`, `apps/worker/src/ai/prompts/receipt.ts`, `packages/db/src/schema-ai.ts`, `packages/db/src/ai-calls.ts`, `packages/core/src/ai-quota.ts`, a migration
- Existing, from the advisor: `apps/worker/fixtures/receipts/` — four images `clean.jpg`, `tax-service.jpg`, `mismatch.jpg`, `not-a-receipt.jpg`, and `{sha256}.json` readings for the first three
- Modify: `apps/worker/src/config.ts`, `apps/api/src/config.ts`, `.env.example`, `packages/db/src/index.ts`

**Interfaces — produces:**
- `interface ReceiptReader { read(image: { bytes: Uint8Array; contentType: string }): Promise<{ reading: unknown; model: string; inputTokens: number; outputTokens: number }> }` — the caller parses `reading` with `ReceiptReading`.
- `anthropicMessages(deps, body): Promise<unknown>` in `anthropic-client.ts`: exactly one `fetch` attempt with a 30-second deadline covering headers and body parsing; the caller may reserve and perform at most one further attempt on a network error, timeout, or 5xx, per spec 15.3; headers and body per the documentation read for this task. Shared with stage 3D.
- The Anthropic reader sends the image as a base64 image block and forces one tool named `record_receipt` whose input schema is `z.toJSONSchema(ReceiptReading)`; it returns the tool call's input. The prompt tells the model to copy numbers as printed, in đồng, as integers, to leave `total` null when not printed, and to return no items when the image is not a receipt.
- The fake reader hashes the bytes, returns the matching fixture, returns `{ items: [], extras: [], total: null, merchant: null, occurredOn: null }` for `not-a-receipt.jpg`'s hash, and for any other image a fixed reading: `Món 1` 100000, `Món 2` 50000, `Món 3` 30000, total 180000.
- Selection by `AI_PROVIDER`: `anthropic` (requires `ANTHROPIC_API_KEY` and `AI_MODEL`, checked at start-up), `fake`, or unset → null. The API's configuration reads the same variable to compute `features.receiptReading` and `features.sentenceAi`, and refuses `fake` in production.
- Table `ai_calls` as spec 5.2, index `(purpose, created_at)` and `(user_id, purpose, created_at)`.
- `countAiCalls(db, { purpose?, userId?, since: Date }): Promise<number>`; `recordAiCall(db, row)`.
- `quotaWindowStarts(now: Date): { dayStart: Date; monthStart: Date }` in `core/ai-quota.ts` (Vietnam calendar).
- `reserveAiCall(executor, { purpose, userId, groupId, limits, now }): Promise<{ status: "ok"; reservationId: string } | { status: "user_limit" | "month_limit" }>`: inside the caller transaction when creating a scan, takes `pg_advisory_xact_lock` on a constant key, counts, and inserts the `ai_calls` row with `ok = false` and zero tokens as a reservation; the caller updates the row after the call. The lock makes parallel requests see each other.

- [ ] **Step 1: Read the Anthropic documentation; record the request shape; write the adapters**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 5)** — with `AI_PROVIDER=fake`, calling the functions from a scratch script that is not committed:

| Check | Expected |
|---|---|
| fake reader on each of the four fixtures, then `ReceiptReading.parse` and `checkReceipt` | `clean`: done, no flags; `tax-service`: done, no flags; `mismatch`: done, `TOTAL_MISMATCH`; `not-a-receipt`: failed |
| `reserveAiCall` 25 times in parallel (`Promise.all`) for one user, user limit 20 | exactly 20 results with status `ok` and unique reservation IDs, 5 `user_limit`; 20 rows |
| the same with month limit 10 and user limit 100 | exactly 10 results with status `ok` |
| start the worker with `AI_PROVIDER=anthropic` and no key | it refuses to start, naming the missing variable and not printing any value |
| start the API with `APP_ENV=production` and `AI_PROVIDER=fake` | it refuses to start |
| read the Anthropic adapter's code path with a stubbed `fetch` returning a canned tool-use response | the tool input is returned; the key is absent from every log line produced |

Record under "Not verified": the real adapter against the real API.

- [ ] **Step 4: Commit** — `feat(worker): add receipt reader adapters, cost ledger, and quotas`

---

### Task 3B.3: Scans — endpoint, job, stage gate

**Files:**
- Create: `packages/db/src/schema-scans.ts`, `packages/db/src/receipt-scans.ts`, `apps/api/src/services/receipt-scans.ts`, `apps/api/src/routes/receipt-scans.ts`, `apps/worker/src/jobs/read-receipt.ts`, a migration
- Modify: `packages/contract/src/jobs.ts`, `packages/contract/src/error.ts`, `apps/api/src/app.ts`

**Interfaces — produces:**
- Table `receipt_scans` as spec 5.2, `UNIQUE (attachment_id)`.
- `POST /groups/{groupId}/receipt-scans` (editor; `{ attachmentId }`; `Idempotency-Key`): 404 when `features.receiptReading` is false; the attachment must belong to the group (else 400); an existing scan is returned with 200; otherwise, atomically in the same group-locked transaction as scan insertion and durable enqueue, `reserveAiCall` — `user_limit` or `month_limit` → 429 `AI_QUOTA_EXCEEDED` with `details.scope` `"user"` or `"month"` — then insert `queued`, enqueue `read-receipt` with the scan id and the reservation's `ai_calls` id, and answer 201.
- `GET /groups/{groupId}/receipt-scans/{id}` (viewer).
- Job `read-receipt`: set `processing`; load the bytes; call the reader; parse; `checkReceipt`; store `result`, flags and status; update the `ai_calls` row with tokens and `ok`; `notifyGroup(groupId, ["receiptScans"])`. Every failure path of decisions 1–2 ends in `failed` with its code and a notification; the receipt orchestrator performs at most one separately reserved retry; the transport never retries invisibly.
- The scan creates no transaction and changes no balance.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)** — `AI_PROVIDER=fake`, worker running, `curl -N …/events` open.

| Request | Expected |
|---|---|
| upload `clean.jpg`, create a scan | 201 `queued`; a `changed: ["receiptScans"]` event; `GET` → `done`, the fixture's items, flags none |
| create a scan for the same attachment again | 200, same id; one `ai_calls` row |
| `mismatch.jpg` | `done`, `TOTAL_MISMATCH`, `computed` and `reading.total` differ |
| `not-a-receipt.jpg` | `failed`, `NOT_A_RECEIPT` |
| transactions and balances of the group after all of the above | unchanged |
| viewer creates a scan | 403 |
| outsider reads a scan | 404 |
| set `AI_RECEIPTS_PER_USER_PER_DAY=2`, create a third scan | 429 `AI_QUOTA_EXCEEDED`, scope `user` |
| unset `AI_PROVIDER`, restart | `features.receiptReading` false; the POST answers 404 |
| stop the worker, create a scan, start the worker | the scan completes after start |

- [ ] **Step 4: Commit** — `feat(api): add receipt scans`
- [ ] **Step 5: Stage gate 3B.** Acceptance script: rows 1–4 and 8 above with `AI_PROVIDER=fake`; row 9. Then the gate of the common file.

**Manual checks for the project owner**
1. None in the browser yet; the review screen arrives in 3C.


**Reservation and fake-provider amendment:** implement spec 15.3's reservation lifecycle, combined-purpose monthly ceiling, at-most-once claim/recovery, and separately reserved provider retry. Do not embed retry inside a transport that can bypass reservation. Register `AI_FAKE_RECEIPT_FIXTURE` and its startup guards per spec 15.4 for deterministic browser exercises. The transport policy must also support sentence requests (8 seconds overall, no retry).

**Additional required exercises:** concurrent same-attachment creates with different keys -> one scan/reservation/job; forced enqueue failure -> no persisted admission; job redelivery -> no second provider attempt; retry at quota boundary -> no unreserved request; both purposes share the month ceiling; expired reservation and crashed claimed attempt reach explained terminal states. Use a stub transport only; never call the real provider.
