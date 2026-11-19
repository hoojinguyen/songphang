# Phase 3 advisor review

Date: 2026-11-18. Role: advisor. Reviewed source: local `main` at merge `905cdf2`, range `6b36336..905cdf2` (Task 0 through 3D.4 plus eight rounds of review-fix commits). No push, fetch, branch change, deployment, provider call or product-source change was made. The review used a disposable database `songphang_review3` (dropped afterwards) and a current-source API on port 4031 with `AI_PROVIDER=fake`.

## Conclusion by stage

### Stage 3A: PASS

Notes (non-blocking): `Content-Disposition` always names the file `hoa-don.jpg`, also for PNG and WebP (`apps/api/src/routes/attachments.ts:96`).

### Stage 3B: PASS

Notes (non-blocking): see "Should fix" 2 and 3 under Stage 3D for the shared transport and the decision record.

### Stage 3C: PASS

### Stage 3D: CHANGES NEEDED

Must fix

1. `apps/web/src/lib/quick-entry.ts:8-20` with `apps/api/src/services/quick-entry.ts:291` (commits `b6031b2`, `4df53f5`): **partial sentences are sent to the AI provider while the user is still typing.** The typing box calls `POST …/transactions/parse` 300 ms after every pause (the Phase 1 live-reading design), and since 3D.1 every `unparsed` answer triggers a synchronous `SentenceAi.read` call. Most prefixes of an ordinary sentence are `unparsed`. Observed on the review API: typing `lẩu 300k lan 100 lan 200` as eleven prefixes created **10 `ai_calls` rows** (10 provider calls; only the last one was useful). Consequences: it breaks spec section 5 ("sentences are sent to the AI provider only when a user takes that action"); one user exhausts `AI_SENTENCES_PER_USER_PER_DAY=100` in about ten sentences, and the shared `AI_CALLS_PER_MONTH=1000` in a few days of normal use (receipt reading then stops for everyone); every keystroke pause can wait up to 8 seconds for the provider. Fix: keep the live parse rule-only, and call the AI only on an explicit send. For example, add an `ai: boolean` field (default `false`) to `ParseRequest`; the web sets it only from `send()` (Enter or the send button) and never from the debounced query; the API skips the AI branch when it is `false`. Re-exercise: typing the same sentence prefix by prefix creates 0 `ai_calls` rows; pressing send once creates exactly 1.

Should fix

1. `apps/web/src/components/receipt/ReceiptReview.tsx:86` (commit `086b1e5`): the file has 685 lines and the component well over 40, with no `decisions.md` entry explaining why. It also had most of the review-fix rounds. Split it into the editor state hook, the mismatch section and the save path. The same applies, to a lesser degree, to `apps/api/src/services/quick-entry.ts` (424 lines; move the AI branch at lines 294-424 into its own `quick-entry-ai.ts`) and `apps/worker/src/jobs/read-receipt.ts` (398 lines; the many repeated `recordAiCall(..., ok: false)` blocks can become one `finishFailedAttempt` helper).
2. `packages/ai/src/anthropic-client.ts:110-127` (commit `4df53f5`): when the response is well formed HTTP but has an invalid shape or no `tool_use` block, the error discards `usage`, and the callers record `inputTokens: 0, outputTokens: 0` (`apps/worker/src/jobs/read-receipt.ts:123`). Such calls are billed by the provider, so the cost ledger under-counts exactly the failures the 30-receipt measurement needs to see. Parse `usage` before the shape check and carry it on `AnthropicTransportError`.
3. `apps/web/src/components/receipt/ReceiptReview.tsx:35`, `apps/web/src/app/g/[groupId]/tx/new/ComposeScreen.tsx:51`, `apps/web/src/components/quick-entry/QuestionCard.tsx:110`: the same "today in Vietnam" expression `new Date(Date.now() + 7 * 3600_000)…` now appears three times. The project rule extracts a shared function at the third copy; move it to one helper in `apps/web/src/lib/`.
4. `apps/web/src/components/receipt/ReceiptReview.tsx:518`: the web computes the mismatch adjustment `scan.reading.total - computedAmount`. The API re-checks the total on save, so the ledger is safe, but this is money arithmetic in the web layer. Prefer letting the items preview (or the scan DTO) return the difference.
5. `docs/superpowers/runs/phase-3/decisions.md:32-35` (D4): the record does not describe the code. It says statuses `queued`/`reading`/`ready`, a partial unique index on active scans, and reservation states `pending -> claimed`. The migrations and code correctly follow the spec instead: statuses `queued`/`processing`/`done`/`failed`, `UNIQUE(attachment_id)`, states `reserved -> started -> finished`. Correct the record so later phases do not rely on the wrong description.

Questions for the project owner

1. With `UNIQUE(attachment_id)`, a failed scan of one photo cannot be read again; the user must take or choose the photo again (`Chụp lại`). This follows the approved database design. Confirm that this is the behavior you want.
2. `.env.example` sets `AI_MODEL=claude-haiku-4-5`. When you create the Anthropic key, decide which model to use; the newest Haiku is `claude-haiku-5-5`. Run the 30-receipt measurement with the model you will actually use.

## Fresh verification evidence

| Check | Result |
|---|---|
| `pnpm check` on `905cdf2` | Passed: `Checked 389 files`, all workspace typechecks Done |
| `pnpm build` (`API_ORIGIN=http://localhost:4031`) | Passed: web `Compiled successfully`, all workspaces Done |
| Migrations 0000-0013 and seed on an empty database | `Migrations applied`, `Development users seeded` |
| `GET /features` with `AI_PROVIDER=fake` | `receiptReading: true`, `sentenceAi: true`, other four `false` |
| Upload `clean.jpg` as owner | 201; content 200 `image/jpeg`, `X-Content-Type-Options: nosniff`, `Cache-Control: private, no-store` |
| Same attachment: outsider through its group; owner of another group through that group's route; signed out | 404; 404; 401 |
| HTML bytes uploaded as `image/jpeg` | 400 `VALIDATION_FAILED`, `reason: not_an_image` |
| Four simultaneous `POST /receipt-scans` with distinct idempotency keys on one attachment | `201 200 200 200`, 1 distinct scan id, 1 `receipt` reservation, 1 `read-receipt` job |
| Items preview: Lẩu 350000 for three people, Bia 90000 for Minh, discount 10000 | `computedAmount` 430000; shares 201970 / 114015 / 114015 (sum 430000) |
| Create the same items transaction for 430000 | 201 with the same shares |
| Same items with amount 440000 | 400 `SPLIT_TOTAL_MISMATCH`, expected 440000, actual 430000 |
| An item with no members | 400 `ITEM_UNASSIGNED`, `itemIndex: 0` |
| Typing simulation (must-fix 1) | 11 prefixes, 10 `ai_calls` rows, all `sentence/finished` |
| `pnpm db:check-balances` after the exercises | `All groups balanced` |

## Code reading

- **Money (3C).** `packages/core/src/split-items.ts` divides only in integers through `allocateByWeights`. A discount is spread in proportion to subtotals, and a negative share is refused. All amounts are bounded by Zod (`ReceiptMoney` up to 999 999 999 999, at most 60 items and 6 extras), so no sum leaves the safe-integer range. The API refuses `Σ items + net extras ≠ amount`. A scan never writes to the ledger: saving is an ordinary create.
- **Photos (3A).** The storage key is always `groupId/uuidv7` generated by the server. `diskFileStore` checks the key format with a regular expression and keeps the resolved path inside the root. The type comes from the leading bytes. Reads go through `requireGroupRole` and a group-scoped query. Linking an attachment to a transaction happens under the group lock and checks that it is unlinked or already belongs to this transaction. Deleting a linked photo increases the transaction version.
- **Quota (3B).** `reserveAiCall` counts and inserts under a transaction-scoped advisory lock. A reservation is claimed once with a conditional update. A retry needs its own reservation. Stale `processing` scans are failed only when no attempt started inside the window. The API key is read only by the adapter, and no prompt, image or answer is logged or stored.
- **Sentences (3D).** Members are sent only as request-local `nonce:pN` references. Unknown references make the result non-`ok`. The answer is validated by Zod, and shares are computed by `core`. The AI branch runs only for rule `unparsed`, as specified. The problem is when that branch runs (must-fix 1), not what it does.
- **Production guards.** `APP_ENV=production` refuses `AI_PROVIDER=fake` and `AI_FAKE_RECEIPT_FIXTURE` in both the API and the worker configuration.
- **Libraries.** The only new external dependency is `pg-boss@12.38.2` (D1, approved). `@songphang/storage` and `@songphang/ai` are approved workspace packages. There are no test files.

## Security review

Relevant items checked against the diff: boundary validation, group authorization and 404 for outsiders, same-origin and verified-email checks on writes, parameterized and group-scoped queries, generated storage keys and path containment, content sniffing with `nosniff`, no secret in logs or rows, no unsafe HTML. No exploitable issue was established. Must-fix 1 is a privacy and cost defect (text the user has not chosen to send reaches the provider), not an authorization bypass. Uploads without an `Origin` header are accepted; this is the existing Phase 1 `requireSameOrigin` policy, not a Phase 3 change.

## Decisions for the project owner

- D1 pg-boss 12.38.2 with the `fromDrizzle` transactional adapter: **confirm.** Four parallel scan requests produced one scan, one reservation and one job.
- D2 `packages/storage`: **confirm.**
- D3 Anthropic request shape: **confirm** for now. It must be checked against the real API the first time the key is used (manual checks, section "After the Anthropic key exists").
- D4 atomic scan creation: **confirm the behavior, change the record** (should-fix 5).
- D5 item split computed only by API and core: **confirm**, with should-fix 4.
- D6 `@songphang/ai` and fixtures moved to `apps/api`: **confirm.**
- D7 category suggestion precedence: **confirm.**
- D8 inline category picker; `infra/` skipped: **confirm.** The server step must add the `worker` service and the `STORAGE_DIR` volume to the production Compose file.

## Not verified

- The recorded gate scripts (`exercise_3a2.mts`, `verify_87_samples.ts` and the others listed in `progress.md`) were never committed and are not on this machine, so the recorded gates could not be replayed byte for byte. Representative cases were reconstructed above. The 87 quick-entry samples and the full permission matrix were not re-run in this review.
- The worker was not started; scan completion, the stale-scan recovery and the cleanup job were reviewed by reading code only.
- Web screens (receipt review, item assignment, AI card) were not opened in a browser in this review.
- A real Anthropic call, a real phone camera, the 30-receipt measurement, Fast 4G and production deployment, for the same reasons as in the run.

## Gate not passed

- Stage 3D: must-fix 1.

## Manual checks for the owner

1. After the must-fix: with `AI_PROVIDER=fake`, open S7 and type a sentence letter by letter, then count rows (`select count(*) from ai_calls where purpose='sentence'`). Expected: no new rows while typing; exactly one after pressing send on a sentence the rules refuse.
2. Run steps 3-12 of `runs/phase-3/manual-checks.md` (receipt fixtures, items, AI sentences, feature off).
3. Open a photo link of group A while signed in as a member of group B only: you must see "not found", never the image.
