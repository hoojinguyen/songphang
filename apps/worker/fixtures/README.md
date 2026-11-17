# Phase 3 advisor fixtures

Prepared locally on 2026-11-17 for the approved Phase 3 spec. This directory contains data only: no worker application, queue, provider adapter, or Phase 3 endpoint has been implemented. The owner has not authorized Phase 3 execution.

## Receipt images

All four JPEGs are synthetic, rendered locally with system fonts, and contain no real receipt, account, location, person, or payment instruction. No external image or AI service was used. The author supplied the readings; they are not measured OCR results. The images carry a synthetic-data notice and use VND integers.

`receipts/manifest.json` maps each stable fixture key to its JPEG, SHA-256, reading JSON, and expected result. Hash-named JSON files contain only the future `ReceiptReading` shape. A line's `amount` is its whole line total, not a unit price; do not multiply it by quantity again. Do not rename a reading without recalculating the associated image hash.

| Key           | Arithmetic                                                                     | Expected              |
| ------------- | ------------------------------------------------------------------------------ | --------------------- |
| clean         | 350000 + 90000 = 440000                                                        | done, no flags        |
| tax-service   | 100000 + tax 8000 + service 2000 = 110000                                      | done, no flags        |
| mismatch      | 350000 + 90000 + service 22000 - discount 20000 = 442000; printed total 450000 | done, TOTAL_MISMATCH  |
| not-a-receipt | no items, no total                                                             | failed, NOT_A_RECEIPT |

For direct API exercises upload the original JPEG bytes so the future fake reader can match SHA-256. Browser canvas preparation changes those bytes: the approved development-only `AI_FAKE_RECEIPT_FIXTURE` override selects a named manifest key, with runtime restart between cases. It is rejected with a real provider or in production. The fake adapter and configuration are not built in this preparation task.

## Sentence templates

`sentences.json` is an ordered array of fifteen `{ id, source, sentence, members, writer, answer, expected, reason }` records. `source` references an unchanged refused row in `docs/08-quick-entry-samples.md`. `members` lists the active names offered to the adapter in position order. C04 intentionally offers no inactive Thu.

`answer` is a provider-output **template**: `payerRef`, equal/exact `members`, and split entry `memberId` values are names. The future fake adapter maps every offered name to the current request-local reference before returning provider output. The names in this file are not UUIDs and must never bypass ordinary UUID contract validation. Actual reference-to-database-ID mapping is private request memory in the API, not in this fixture.

- AI01 combines the repeated allocations to Lan (100000 + 200000) exactly; writer Minh pays by the documented default.
- AI02 produces two drafts, with independent expected shares.
- AI03/04/08 preserve conflicting information as uncertain drafts; no shares may be returned.
- Empty `answer.drafts` means the rule reader's existing refusal is returned, with `reader: rules`; the adapter must not invent money, units, members or unsupported multiple payers merely to fill a fixture.
- AI14 deliberately returns `Nam`, absent from the offered names, in an equal split. For this hostile-output exercise only, the fake adapter substitutes an unknown reference in the current nonce namespace (for example `<nonce>:unknown`), never a guessed member ID. The API must remove the unknown reference, mark the result uncertain, and return no shares or `ok`. `expected.foreignNames` is exercise metadata, not provider input.
- AI15 has `confident: false`: a relative date cannot be silently discarded when the draft does not represent dates. It requires manual review and has no shares.

`expected.shares` and each additional draft's expected shares are keyed by names for independent comparison after resolving the API's member IDs. `expected.draftCount` counts provider drafts; it is not the number of saved transactions. No fixture saves automatically. Reasons and expected metadata are not sent to the real provider.

The correct gate compares each fixture with its own `expected` record. It must not demand `reader: ai` when the fixture safely returns an empty answer. With AI unset, all 87 original/fund samples retain their rule behavior.

## Category keywords

`packages/core/src/category-keywords.ts` contains 120 distinct, already-normalized keyword/category pairs over the existing seven built-in category codes. It is prepared data only and is not exported from the core entry point or used by the current reader. Task 3D.2 will implement word-boundary/longest-match ordering and active custom-category precedence. These keywords express the approved heuristic scope, not measured classification accuracy or learning from private history.
