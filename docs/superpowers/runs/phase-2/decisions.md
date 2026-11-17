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


## D4 — Owner-approved VietQR source replaces D1 blocker

Problem: NAPAS complete BIN mapping was inaccessible. Options: continue blocked; use public VietQR dataset. Choice: owner explicitly authorized the latter on 2026-11-17. Retrieved https://api.vietqr.io/v2/banks, documented at https://www.vietqr.io/api-bank, before implementation. Response code 00, 76 rows, 76 unique six-digit BINs, nonempty names; all rows retained without guessing or filtering institutions. Raw JSON SHA256: 7f905bc2da19a8848bd805646e74c64fee8531314f68ce2476fcccb977dd6596. Static snapshot only; no runtime network dependency. D1's blocker is resolved by this owner decision, not by obtaining a NAPAS-certified list.

## D5 — Advisor sample fixtures and standing amendments

Choice: append F01–F12 without modifying any prior byte of the 75 existing samples. Define separate F/N/Q groups for fund, absent fund and person-name ambiguity. Calculate shares before implementation using the approved largest-remainder position rule. Amend standing documents additively in English, superseding the explicitly identified older Phase 2 reservations. No library or product requirement beyond approved spec added.

## Task 0 — named path mapping

| Plan path | Actual location / adaptation |
|---|---|
| apps/api/src/app.ts | apps/api/src/app.ts |
| apps/api/src/rate-limit.ts | apps/api/src/rate-limit.ts |
| apps/api/src/routes/members.ts | apps/api/src/routes/members.ts |
| apps/api/src/routes/transactions.ts | apps/api/src/routes/transactions.ts |
| apps/api/src/services/balances.ts | apps/api/src/services/balances.ts |
| apps/api/src/services/invites.ts | apps/api/src/services/invites.ts |
| apps/api/src/services/members.ts | apps/api/src/services/members.ts |
| apps/api/src/services/transactions.ts | apps/api/src/services/transactions.ts |
| apps/web/src/app/globals.css | apps/web/src/app/globals.css |
| apps/web/src/components/members/MemberEditor.tsx | apps/web/src/components/members/MemberEditor.tsx |
| apps/web/src/lib/members.ts | apps/web/src/lib/members.ts |
| apps/web/src/lib/transactions.ts | apps/web/src/lib/transactions.ts |
| apps/web/src/lib/use-group-events.ts | apps/web/src/lib/use-group-events.ts |
| apps/web/src/messages/vi.ts | apps/web/src/messages/vi.ts |
| packages/contract/src/balance.ts | packages/contract/src/balance.ts |
| packages/contract/src/error.ts | packages/contract/src/error.ts |
| packages/contract/src/index.ts | packages/contract/src/index.ts |
| packages/contract/src/member.ts | packages/contract/src/member.ts |
| packages/contract/src/transaction.ts | packages/contract/src/transaction.ts |
| packages/core/src/ | packages/core/src/ |
| packages/core/src/dates.ts | Missing at baseline; locate equivalent below or create in its producing task |
| packages/core/src/index.ts | packages/core/src/index.ts |
| packages/core/src/settlements.ts | packages/core/src/settlements.ts |
| packages/db/src/check-balances.ts | packages/db/src/check-balances.ts |
| packages/db/src/index.ts | packages/db/src/index.ts |
| packages/db/src/members.ts | packages/db/src/members.ts |
| packages/db/src/schema-groups.ts | packages/db/src/schema-groups.ts |
| packages/db/src/schema-transactions.ts | packages/db/src/schema-transactions.ts |
| packages/db/src/schema.ts | packages/db/src/schema.ts |
| packages/db/src/transactions.ts | packages/db/src/transactions.ts |

Semantic equivalents: members schema is schema-groups.ts; ledger schema is schema-transactions.ts; integrity SQL is packages/db/drizzle/0002_ledger-integrity.sql (replace via new generated migration). Split and settlement functions live in packages/core/src/split.ts and settlements.ts; reader in quick-entry/read-sentence.ts. Balance DTO is contract/src/balance.ts. Transactions create/preview/list use services/transactions.ts; edit/delete/restore use services/transaction-changes.ts. Payer/split normalization uses transaction-input.ts. Member queries use listGroupMembers, not listMembers. Existing member UI is MemberEditor/MemberRow, participant grid MemberToggleGrid, payer controls ParticipantFields/PayerAmounts, shape renderer ui/MemberShape.tsx. Feed components are components/feed; settings page app/g/[groupId]/settings/page.tsx; balances page app/g/[groupId]/balances/page.tsx. Source paths introduced by 2B/2C/2D are not missing Phase 1 prerequisites.

Phase 1 is the only earlier roadmap phase on main; its run directory contains all stages and review fixes. No later phase dependency applies to Phase 2. Preserve Phase 1 account-first session/password serialization, group post-lock checks, terminal SSE guards and repeatable-read ledger snapshots.

D6 — Features endpoint: expose receiptReading, sentenceAi, telegram, push, appleSignIn and errorAlerts booleans, all false in Phase 2. Google remains separately discoverable through /auth/providers. No optional adapter route is registered; no new environment variable. Missing endpoint supplied in Task 0 as an explicit common-plan prerequisite.

## D7 — Payment schema registration and shared core export (2A.2)

Problem: drizzle-kit enumerates schema files explicitly and contract did not yet depend on core. Options: duplicate the catalogue or import across source paths; register the new schema and the planned workspace dependency. Choice: add schema-payments.ts to drizzle.config.ts and link existing @songphang/core into contract with pnpm --offline (downloaded 0, added 0 external packages). Reason: generated migration and one bank catalogue shared by API/web, as task 2A.5 requires. No new library. Generated snapshot/journal formatting follows existing Biome rules; no lint configuration changed. Member DTO defaults paymentMethods to [] for newly created members while read/edit/PUT explicitly load persisted methods.

## D8 — Authorized shared ledger writer and lock order (2A.3)

Problem: ordinary createTransaction requires editor access, while a linked receiver may be a viewer. Options: weaken its guard; duplicate transfer writes; extract createTransactionIn for callers that already hold the group lock and have independently authorized the operation. Choice: shared internal writer; ordinary wrapper keeps its unchanged post-lock editor check. Settlement locks group then request, matching every existing group write and avoiding opposite request/group lock ordering. Transfer creation supplies the confirmation activity entry; no misleading duplicate group-settings activity is added.

## D9 — Concurrent idempotent reports and restricted member references (2A.3)

Problem: a second simultaneous same-key report could see the new pending pair before the idempotency insert conflict, returning 409 instead of replay. Choice: transaction-scoped advisory lock on hashed user/key before idempotency lookup; collisions only serialize unrelated keys, never relax validation. The key is parameterized and never logged. Request member FKs are RESTRICT, so group deletion explicitly removes requests before its existing transaction/member cascade; generic member deletion treats referenced requests as retained ledger history and returns existing MEMBER_HAS_TRANSACTIONS instead of database 500. Both preserve integrity without weakening an FK or adding product wording.

## D10 — Member payment editor access and existing UI reuse (2A.5)

Choice: keep MemberEditor for generic editor-only controls and place PaymentMethodsFields inside it; viewer expansion renders only payment fields, editable only for the linked member. BankPicker uses a native dialog with focus return and the existing TextField/Button styles from member/account forms. Reuse existing vi.compose.save (`Lưu`) rather than the name-only action. jsonRequest's method union gains PUT for the required endpoint; no script/configuration changes. The members page was already above the file-size guideline; retain its existing explicit loading/access states and limit this task to payment expansion, instead of unrelated restructuring.

## D11 — Shared S5 transfer action, unmatched pending list, and PayContent split (2A.6)

Choice: replace editor-only settlement links on `OwnSettlementCard`, `SettlementCard`, and `OtherSettlements` with one shared `TransferAction` component that renders `PendingRequestRow` when `pendingRequest` exists and links to `/g/{id}/pay?from=&to=` otherwise, reusing existing `vi.feed.pay` (`Trả`) for own debt, `vi.balances.record` (`Ghi nhận`) for editors/owners, and `vi.feed.view` (`Xem`) for viewers inspecting others' transfers. Fetch pending requests on S5 (`usePendingSettlementRequests`) only to surface any pending request whose pair no longer appears in `transfers` (e.g. after a debt edit). Split `PayContent` into `components/pay/PayContent.tsx` and `PayFooter.tsx` so each new component stays under 150 lines; leave preexisting `balances/page.tsx` structure intact with minimal additions. Reason: avoids duplicating pending controls across three cards, invents zero new Vietnamese strings, and keeps changed-debt pending requests confirmable/cancellable in the UI.

## D12 — Category name-key normalization and edit preservation (2B.1)

Choice: compute `name_key` in `apps/api/src/services/categories.ts` via `foldVietnamese(name.trim()).replace(/\s+/g, " ")` and pass it into `packages/db`, preserving `db`'s zero dependency on `core`. On `PATCH /transactions/{id}`, validate `categoryId` against live group categories only when `categoryId !== null && categoryId !== before.categoryId` so unrelated edits to transactions holding an archived category succeed without changing their category. Reason: follows SAD layer rules and 2B Decision 2 without SQL `unaccent` extensions.

## D13 — Description search backfill and core link in db (2B.2)

Choice: link existing `@songphang/core` (`workspace:*`) into `packages/db` offline (0 external dependencies) so `packages/db/src/backfill-description-search.ts` uses the exact `foldVietnamese` normalizer, and run `backfillDescriptionSearch` idempotently inside `runMigrations` after Drizzle SQL migrations (`0007_gifted_white_tiger.sql` adds `description_search text DEFAULT '' NOT NULL` and backfills `lower(description)` first). Reason: avoids duplicating Vietnamese folding logic across packages while allowing non-empty tables to migrate cleanly.

## D14 — Filter button label and dialog containment (2B.4)

Choice: label the S4 filter trigger button `Lọc` (`vi.filter.button`) alongside spec 9.6's `Xoá lọc`, and add `overscroll-behavior: contain` on `dialog:modal` and `dialog::backdrop` in `globals.css` with `closedby="any"` attribute on `FilterSheet`. Reason: `Lọc` matches the Vietnamese root of `Xoá lọc` cleanly on a 44px button without inventing a separate phrase, and modal scroll containment prevents background stream scrolling.
