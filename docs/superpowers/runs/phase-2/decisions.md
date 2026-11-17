# Phase 2 run — decisions

## D1 — Do not substitute an unverified bank dataset (advisor preparation)

Problem: the plan requires a complete `{ bin, shortName, name }` mapping taken from NAPAS's published member list before the run starts. No such complete mapping was obtained from the public official sources inspected on 2026-11-17.

Official source inspection:

- https://napas.com.vn/ — describes the member network; no complete bank-to-BIN table was present in the inspected page.
- https://napas.com.vn/dich-vu-chuyen-tien-nhanh-napas-247 — describes VietQR and shows participating-bank logos; the retrieved page does not provide the required complete BIN mapping.
- https://developer.napas.com.vn/vi/product — inspected after client rendering in a browser, rather than treating the initial `Loading` HTML as the final result.
- https://developer.napas.com.vn/vi/product/introduce/chuyen-tien-nhanh-247 — clicking `Xem tài liệu` produced `Bạn không có quyền xem tài liệu` and `Vui lòng liên hệ với chúng tôi`.
- https://developer.napas.com.vn/files/assets/files/Techspec_NapasCore_v1.1.pdf — a search-indexed official document URL redirected to `/vi/404`; the search excerpt is not a retrieved complete dataset.
- Focused public searches for NAPAS member BIN tables and downloadable official tables did not yield the complete required dataset. This is an access/retrieval finding, not proof that NAPAS never publishes one.

Options: use a third-party list or an old partial bank-hosted document; guess missing entries; report the missing authoritative input.

Choice: report the blocker and leave `banks.ts` absent. Do not call bank/payment APIs, create an account or send a request to NAPAS staff. No external calls after implementation begins.

Reason: the owner's explicit instruction forbids invented BINs and requires reporting a genuinely unavailable authoritative input. The common plan prohibits starting the run without advisor data. A complete publicly accessible official mapping, or an owner-supplied authoritative document with provenance, is needed to unblock preparation.

## D2 — Retain installed QR implementation (pending 2A.6)

Problem: the spec and plan assume `uqr`; the actual Phase 1 web package declares `qrcode` 1.5.4 and `@types/qrcode` 1.5.6.

Options: add another library; reuse the existing matrix-to-React-SVG approach.

Choice: reuse `create` from `qrcode` as demonstrated in `apps/web/src/components/members/InviteCard.tsx`. No new dependency.

Reason: the owner explicitly requires this adaptation. This records implementation direction; no Phase 2 QR component has been built.

## D3 — Preserve one source of product text (pending 2B.5)

Problem: stage 2B asks for CSV labels in `apps/api/src/csv-labels.ts`, while the owner requires a single source for localized product strings including CSV labels.

Options: duplicate the Vietnamese labels; use an adapter referencing the pure `apps/web/src/messages/vi.ts` object.

Choice: retain labels only in `vi.ts`; an API adapter may reference it using the established Phase 1 D24 exception. Do not duplicate literals in CSV code.

Reason: current owner instructions outrank the plan; this follows the existing transfer-default precedent. Not yet implemented.

## Partial re-baseline — not Task 0 completion

| Plan assumption | Actual source / adaptation |
|---|---|
| Phase 1 complete on main | `main` and `origin/main` at `30d27bc`; Phase 1 progress records final gates and review fixes, including terminal SSE cancellation |
| `uqr` | `qrcode` 1.5.4, `apps/web/src/components/members/InviteCard.tsx` |
| Transaction creation callable in a caller transaction | `createTransaction(executor, input)` in `apps/api/src/services/transactions.ts`; already takes `DbExecutor`, locks group and rechecks editor access |
| Viewer settlement confirmation through the existing creator | Needs a deliberate authorized internal path: existing creator requires editor after the lock; never remove that protection from ordinary transaction writes |
| Balances service | `getBalances` in `apps/api/src/services/balances.ts`; repeatable-read, read-only transaction must cover all new related balance reads |
| Settlement suggestions | `suggestMinimizedSettlements` in `packages/core/src/settlements.ts`; `netPairwiseDebts` for non-minimized groups |
| Member editor | `apps/web/src/components/members/MemberEditor.tsx` |
| Normalizer and reader | `packages/core/src/quick-entry/normalize.ts`, `read-sentence.ts` |
| Public `GET /api/v1/features` | Missing in `apps/api/src`; add contract and thin route during Task 0 prerequisite work, document capability names before implementation; do not claim it exists |
| NAPAS bank data | Missing; blocking advisor prerequisite D1 |

This is a partial mapping only. Task 0 must still map all other assumed existing interfaces and run its full gates after advisor preparation is complete.
