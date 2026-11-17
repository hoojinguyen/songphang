# Phase 3 advisor preparation — 2026-11-17

Status: prepared for the owner's execution decision. The revised spec/plan is approved; Phase 3 implementation is explicitly **not authorized**. No Task 0, worker/package scaffold, dependency installation, migration, endpoint, adapter or UI feature was started.

## Authorization and approach

The owner approved the revised spec/plan, requested the Phase 2B fix plus fresh verification, and authorized the remaining advisor fixtures, keywords and standing-document amendments. Keep the fixed money examples, existing corpus and external-service ban unchanged. Use synthetic local images, independently authored readings/expected outcomes, and the existing seven category codes. Distinguish prepared inputs from future provider/worker validation.

Phase 2B correction commit: `257fc50` (`fix(stats): preserve spending scope in feed drill-downs`). Detailed HTTP/browser/access evidence: `docs/superpowers/runs/phase-2/statistics-fix-2026-11-17.md`. Its correctness finding is resolved; real-bank/Fast-4G/Excel limitations from the earlier review are not waived.

## Inventory

| Deliverable | Location | Content |
|---|---|---|
| Four receipt images | apps/worker/fixtures/receipts/{clean,tax-service,mismatch,not-a-receipt}.jpg | Synthetic 720x1000 JPEGs; visibly marked synthetic; no personal/payment data |
| Hash readings and expectations | apps/worker/fixtures/receipts/manifest.json and four SHA-256-named JSONs | Pure ReceiptReading data; manifest links image/hash/reading/status/flags |
| Fifteen sentence fixtures | apps/worker/fixtures/sentences.json | AI01–AI15, exact original refused sentences, active names/writer, provider-output templates and independent expected results |
| Provenance and consumption rules | apps/worker/fixtures/README.md | Offline synthetic source, byte-hash vs browser re-encode distinction, nonce mapping and hostile/uncertain cases |
| Category keywords | packages/core/src/category-keywords.ts | 120 unique normalized pairs; seven existing category codes; no consumer or core entry-point export |
| Standing decisions | docs/04-adr.md | ADR-023 (split_input items); ADR-024 (AI refs, validation, quota/attempt durability) |
| Architecture | docs/04-sad.md | Planned worker/deps/storage/events, body/quota bounds and atomic admission |
| Data model | docs/05-database-design.md | Superseded item tables; planned attachments, scans, ai_calls lifecycle and FK migration order |
| API | docs/05-api-spec.md | Planned attachments/scans/items preview/parse contracts, errors/auth/capabilities; implemented Phase 2B spendingOnly correction |
| UX | docs/06-ux-ui/user-flows.md | Planned S18/S4/S8/S7 behavior, mismatch/total-only/incomplete handling; implemented statistics scope correction |
| Requirements and working state | docs/03-srs.md and AGENTS.md | Approved privacy/attempt clarification and explicit no-execution boundary |

Only fixture data is created below apps/worker; it has no package.json, tsconfig, src, process or workspace runtime. The keyword module is deliberately not imported by the current reader. It will be consumed only in approved task 3D.2.

## Receipt evidence

All images were rendered locally with system fonts; no source receipt, image-generation API or OCR/provider call was used. The final four files were visually inspected; manifest hashes were computed from those exact image bytes. Readings are authored fixture expectations, not measured AI/OCR outputs.

| Key | Observed SHA-256 | Independent arithmetic / expected |
|---|---|---|
| clean | bc85e8c5552a75663623313b0b39338f5f5c8f28adaa08651559d61882c29488 | 350000 + 90000 = 440000; done, no flags |
| tax-service | 2b9ffd2dd8727f349423e2d235497b29f8afbc67a59ea4865db7a50287103d15 | 100000 + 8000 + 2000 = 110000; done, no flags |
| mismatch | c74553a4087925e1fc370de6986128aaa8adb88d986428435f631f018112a113 | 350000 + 90000 + 22000 - 20000 = 442000; printed 450000; TOTAL_MISMATCH |
| not-a-receipt | bd894f40e6e8ecab5e4de335f166ed19774f1472d3129ffa25283e2d90715be4 | no items or total; failed NOT_A_RECEIPT |

Observed for every image: JPEG leading bytes ffd8ff; hashMatches true; associated reading passes an independent scratch Zod schema matching the approved field bounds. The actual ReceiptReading schema/checkReceipt are not built yet, so their runtime gate remains for 3B.1. Whole-line amounts are not multiplied by quantity.

## Sentence evidence

All fifteen source comparisons printed sourceMatches true; the current rule reader returned unparsed for every source in its documented active-member context. The original 87-row document is untouched. The expected template outcomes intentionally include safe refusals rather than fabricated transactions.

| Fixture | Source | Expected reader/status | Important outcome |
|---|---|---|---|
| AI01 | A61 | ai / ok | combine Lan 100000+200000 exactly; payer Minh; share Lan 300000 |
| AI02 | A60 | ai / ok | two drafts: 180000 gives four 45000s, 50000 gives four 12500s |
| AI03 | A53 | ai / needs_input | parts sum 180000 vs amount 300000; uncertain, no shares |
| AI04 | A54 | ai / needs_input | parts sum 400000 vs amount 300000; uncertain, no shares |
| AI05 | A55 | rules / unparsed | unknown payer; empty answer |
| AI06 | A56 | rules / unparsed | unknown share member; empty answer |
| AI07 | A57 | rules / unparsed | requested five of four known people; empty answer |
| AI08 | A58 | ai / needs_input | conflicting participant count; uncertain, no shares |
| AI09 | A62 | rules / unparsed | unsupported multiple payers; empty answer |
| AI10 | A50 | rules / unparsed | missing amount; empty answer |
| AI11 | A51 | rules / unparsed | ambiguous bare units; empty answer |
| AI12 | A52 | rules / unparsed | invalid zero; empty answer |
| AI13 | C04 | rules / unparsed | inactive Thu not offered; empty answer |
| AI14 | A63 | ai / needs_input | deliberate unknown reference Nam; cannot be ok, no shares |
| AI15 | A59 | ai / needs_input | confident false for unrepresentable relative date, no shares |

Valid confident fixture splits were mapped to scratch UUIDs and passed through the existing contract SplitInput and core computeShares: Lan 300000; four 45000s; four 12500s. Unknown AI14 cannot validate as an ordinary UUID split until safely mapped/sanitized; the future nonce-aware fake adapter/API must exercise the intended non-ok outcome. No real or fake AI adapter was implemented or exercised. The stage 3D table is aligned to each fixture's expected record: an empty answer preserves reader=rules per the already-approved fallback; it is not forced to reader=ai.

## Keyword evidence

Count 120; unique normalized keywords 120; invalid category or normalization rows `[]`. Counts by category: food 24, transport 20, lodging 16, shopping 16, entertainment 16, bills 20, other 8. The table is original advisor data, without external dataset or measured accuracy claim. Longest whole-word selection and live custom category matching remain task 3D.2, not preparation code.

## Review and verification

- pnpm check passed with 324 files and all five workspace typechecks after the data additions; the final repeated gate passed with the same 324 files and all typechecks completed.
- The Phase 2B production build, real HTTP normal/invalid/access cases, browser reload/scope behavior and populated review DB checker passed; no main development DB mutation was needed.
- Independent read-only code/data/document review: PASS, no actionable findings; reviewer separately checked hashes, arithmetic, corpus correspondence, keyword uniqueness/category codes and all four final images. It did not claim independent HTTP/browser execution.
- Security review: relevant items 1–8 checked across the complete change. No key/token/connection string, new external dependency, migration, unsafe HTML, weakened group authorization or money calculation outside core is added. Fixture names/amounts are synthetic. No online audit or provider request under the local-only rule.
- No automated tests, committed validation scripts, lockfile/configuration changes or build artifacts. Validation loops/render input remained private scratch files. Original fixed arithmetic and corpus bytes are preserved.

## Manual review for the owner

1. Open the four JPEGs and manifest: amounts, printed total and synthetic notices match the table; mismatch intentionally differs by 8000.
2. Read AI01/AI02/AI14/AI15: valid one/two expense, foreign reference and uncertainty expectations are explicit; no unknown person is guessed.
3. Inspect the keyword table and the seven existing category codes; no lookup/suggestion is active in the current app.
4. Re-run the Phase 2B manual checks in the focused correction report; scoped S16 links exclude transfers, generic feed filters still allow them.
5. Review the planned standing amendments and give separate Phase 3 execution authorization only when ready. This preparation does not start a phase run.

## Remaining execution boundary

The repository-owned advisor inputs and standing documents are prepared. The phase branch and run files are intentionally not created. An implementation agent still must receive execution approval, start from main's actual baseline on the approved phase branch, run Task 0 and the full cumulative gates, install only approved pg-boss, then prove transaction-bound enqueue/rollback in 3A before scans in 3B. If the installed adapter cannot support it, stop for an advisor outbox amendment; this preparation does not certify adapter support.

Real-provider structured-output compatibility/quality/cost/latency, camera behavior on phones and all Phase 3 runtime gates remain unverified because implementation is withheld. Phase 2 real banking, full Fast 4G, real screen-reader and spreadsheet-application checks remain the earlier explicit limits. Nothing in the preparation checkboxes waives them.

Preparation commit reference: `chore(phase-3): prepare advisor fixtures and standing documents`.
