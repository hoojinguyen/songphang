# Wave 5.5B — Task 0 and Stage 5.5B.1: Database, Core, Additive v1 API & Copy Lock

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md). API paths below are relative to `/api/v1`.

### Task 0: Re-baseline `main` on `phase-5-5b`

**Files:**
- Modify: `docs/superpowers/runs/phase-5-5b/{progress,decisions,manual-checks}.md`

**Interfaces:**
- Consumes: `main` (`8250d8e` or later), Wave 5.5A merged baseline.
- Produces: Clean baseline verification and Re-baseline symbol/file mapping in `docs/superpowers/runs/phase-5-5b/decisions.md`.

- [ ] **Step 1: Verify branch and clean workspace**
  Confirm `git branch --show-current` prints `phase-5-5b` and `git status --short` is clean; record starting `main` SHA in `progress.md`.
- [ ] **Step 2: Run baseline build, lint, string, and iOS checks**
  Run `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, and Simulator Debug `xcodebuild ... -skipPackagePluginValidation build`. Record observed outputs.
- [ ] **Step 3: Verify existing files and symbols referenced by this plan**
  Confirm every existing file path named across `5-5b-1`..`5-5b-4` exists on `phase-5-5b` and write the Re-baseline table in `decisions.md`.
- [ ] **Step 4: Replay disposable-DB baseline smoke check**
  Create disposable DB `songphang_phase55b_t0`, run migrations + seed, verify auth, group archive/clone, `GET /me/overview`, quick entry, settlement confirm, and `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` (`All groups balanced`), then drop `songphang_phase55b_t0`.
- [ ] **Step 5: Commit baseline run log**
  `git commit -m "docs(run): re-baseline wave 5.5b"`

---

### Task 5.5B.1.1: Database migration (`settlement_requests`, `settlement_cycles`, `transactions`, `groups`) & static VietQR in `@songphang/core`

**Files:**
- Create: `packages/db/src/schema-cycles.ts`
- Create: `packages/db/src/settlement-cycles.ts`
- Modify: `packages/db/src/schema-settlements.ts`
- Modify: `packages/db/src/schema-transactions.ts`
- Modify: `packages/db/src/schema-groups.ts`
- Modify: `packages/db/src/schema.ts`
- Modify: `packages/db/src/index.ts`
- Create: new Drizzle migration under `packages/db/drizzle/`
- Modify: `packages/core/src/vietqr.ts`
- Modify: `packages/core/src/index.ts`

**Interfaces:**
- Consumes: `groups`, `members`, `transactions`, `attachments`, `settlementRequests` Drizzle tables; `crc16CcittFalse` & `foldVietnamese` in `@songphang/core`.
- Produces:
  - DB columns on `settlement_requests`: `channel` (`'bank'|'momo'|'zalopay'|'cash'`, nullable), `note` (`1..120`, nullable), `proofAttachmentId` (`uuid` FK -> `attachments.id` `ON DELETE SET NULL`, partial index).
  - DB table `settlement_cycles`: `id`, `groupId`, `cycleNumber` (`UNIQUE(group_id, cycle_number)`), `title` (`1..80`), `startedAt`, `closedAt`, `closedBy`, `expenseCount`, `totalExpenseAmount`, `snapshot` (`jsonb`), `createdAt`.
  - DB columns on `transactions`: `paymentChannel` (nullable, valid only when `type = 'transfer'`), `paymentNote` (`1..120` nullable, valid only when `type = 'transfer'`), `cycleId` (`uuid` FK -> `settlement_cycles.id` `ON DELETE SET NULL`, partial feed index).
  - DB columns on `groups`: `guestToken` (`text` unique nullable), `guestLinkActive` (`boolean` default `false`), `guestLinkCreatedAt` (`timestamptz` nullable) with consistency check `(guest_link_active = false AND guest_token IS NULL) OR (guest_link_active = true AND guest_token IS NOT NULL AND char_length(guest_token) >= 32)`.
  - Core functions in `@songphang/core`:
    - `groupTransferPurpose(groupName: string): string` -> ASCII-folded `"SP {plainGroupName}"` trimmed to `<= 25` chars (fallback `"SP Thanh toan"` if group name has zero ASCII alphanumerics).
    - `buildStaticVietQrPayload(input: { bankBin: string; accountNumber: string; purpose?: string }): string` -> EMVCo `00="01"`, `01="11"` (static QR, omitting tag `54`), `38` NAPAS `QRIBFTTA`, `53="704"`, `58="VN"`, optional `62` (`08=purpose`), `6304` + `crc16CcittFalse`.

- [ ] **Step 1: Add static VietQR helpers in `packages/core/src/vietqr.ts` and export from `packages/core/src/index.ts`**
  Validate `bankBin` (`^\d{6}$`), `accountNumber` (`^[A-Za-z0-9]{4,19}$`), and optional `purpose` (`1..25` printable ASCII).
- [ ] **Step 2: Add Wave 5.5B Drizzle schema definitions and `settlement-cycles.ts` DB query helpers**
  Implement `listSettlementCycles`, `findLatestSettlementCycle`, `findSettlementCycle`, `insertSettlementCycle`, `stampOpenCountedTransactionsToCycle` (`WHERE group_id = $1 AND cycle_id IS NULL AND deleted_at IS NULL AND approval_status IN ('none','approved')`), `deleteSettlementCycle`, and `countCurrentPeriodStats`.
- [ ] **Step 3: Generate Drizzle migration and verify constraints on a disposable DB**
  Generate the SQL migration in `packages/db/drizzle/`, apply it to a disposable Postgres 17 database, test check constraints (reject `payment_channel` on `type = 'expense'`, reject `guest_link_active = true` with `guest_token = NULL`, verify `ON DELETE SET NULL` when deleting a `settlement_cycles` row), and confirm `check-balances.ts` prints `All groups balanced`.
- [ ] **Step 4: Verify `buildStaticVietQrPayload` CRC & EMVCo structure via `tsx -e` and run `pnpm check`**
  Confirm static payload starts with `000201010211`, omits tag `54`, and passes `crc16CcittFalse`. Run `pnpm check`.
- [ ] **Step 5: Commit**
  `git commit -m "feat(db,core): add wave 5.5b settlement cycle, proof, guest link schema and static vietqr"`

---

### Task 5.5B.1.2: Transfer proof upload/GC protection, optional proof/channel/note on requests & transfers, `accountQrPayload` & `GET /settlement-vault`

**Files:**
- Create: `packages/contract/src/settlement-vault.ts`
- Create: `apps/api/src/services/settlement-vault.ts`
- Create: `apps/api/src/routes/settlement-vault.ts`
- Modify: `packages/contract/src/{payment,attachment,settlement-request,transaction,balance,index}.ts`
- Modify: `packages/db/src/{attachments,settlement-requests,transactions,groups,index}.ts`
- Modify: `apps/api/src/services/{attachments,settlement-requests,transactions,transaction-changes,transaction-input,balances}.ts`
- Modify: `apps/api/src/routes/{attachments,settlement-requests}.ts`
- Modify: `apps/api/src/app.ts`

**Interfaces:**
- Consumes: Task `5.5B.1.1` DB columns and `buildStaticVietQrPayload` / `groupTransferPurpose`.
- Produces:
  - `PaymentChannel = z.enum(["bank", "momo", "zalopay", "cash"])` in `@songphang/contract`.
  - `POST /groups/{groupId}/attachments?purpose=expense|transfer_proof` (allows `viewer` when `purpose === "transfer_proof"` AND `access.memberId !== null`; `403` for unlinked viewer).
  - Orphan GC protection in `listStaleUnattachedGroups` & `deleteStaleUnattachedForGroup` excluding attachments referenced by `settlement_requests.proof_attachment_id`.
  - Additive optional `channel`, `note`, `proofAttachmentId` on `CreateSettlementRequest`; `channel`, `note`, `proofAttachment`, `resolvedBy` on `SettlementRequestDto`; `channel`, `note`, `proofAttachmentId` on `BalancesResponse.transfers[].pendingRequest`; `accountQrPayload` on bank `PayTo`.
  - Automatic forwarding of `proofAttachmentId -> attachmentIds`, `channel -> paymentChannel`, `note -> paymentNote` in `resolveSettlement(..., action: "confirm")`.
  - Additive `paymentChannel`, `paymentNote`, `cycleId` on `TransactionDto` & `TransactionListItemDto`, plus `firstAttachmentId` on `TransactionListItemDto` (preserving existing `paymentChannel`/`paymentNote`/`cycleId` appropriately on `PATCH` in `transaction-changes.ts`).
  - `GET /groups/{groupId}/settlement-vault` (`filter?: "all" | "pending" | "confirmed" | "with_proof"`, `cycleId?: "current" | uuid`, `cursor`, `limit`) returning deduplicated `SettlementVaultResponse` (`items`, `summary`, `nextCursor`).

- [ ] **Step 1: Extend contract schemas (`payment.ts`, `balance.ts`, `settlement-request.ts`, `transaction.ts`, `settlement-vault.ts`)**
  Keep every new response field additive (`.nullable()` or `.nullable().optional()`).
- [ ] **Step 2: Update `attachments` upload authorization, delete guard, and orphan cleanup query**
  Allow linked `viewer` uploads for `purpose=transfer_proof`; block viewers from deleting others' attachments or deleting attachments bound to pending settlement requests; update `listStaleUnattachedGroups` & `deleteStaleUnattachedForGroup` with `NOT EXISTS (SELECT 1 FROM settlement_requests sr WHERE sr.proof_attachment_id = attachments.id)`.
- [ ] **Step 3: Wire `channel`, `note`, `proofAttachmentId`, `firstAttachmentId`, and `accountQrPayload` through services**
  Validate in `createSettlementRequest` that `proofAttachmentId` belongs to `groupId`, has `transactionId === null`, is not bound to another request, and (for `viewer`) `uploadedBy === userId`. Forward proof/channel/note into `createTransactionIn` on `confirm`. Populate `accountQrPayload` in `services/balances.ts` using `buildStaticVietQrPayload`.
- [ ] **Step 4: Implement `GET /groups/{groupId}/settlement-vault` and register in `app.ts`**
  Merge non-deleted `transfer` transactions (enriched with linked `confirmed` `settlement_requests` metadata) with `pending`/`rejected`/`cancelled` `settlement_requests` so confirmed requests never appear twice; compute `summary` (`pendingCount`, `confirmedCount`, `confirmedTotalAmount`, `proofCount`).
- [ ] **Step 5: Exercise on disposable DB + isolated API server and commit**
  Exercise: (a) 1-tap `POST /settlement-requests` with zero optional fields (`201`), (b) linked `viewer` uploading `purpose=transfer_proof` (`201`) vs unlinked `viewer` (`403`) vs cross-user proof reuse (`400`/`403`), (c) `runCleanupAttachments` at `now + 48h` keeping pending proof intact while deleting an unbound scan, (d) host `confirm` moving proof + `channel: "bank"` + `note` onto the created `transfer` (`firstAttachmentId` populated, single deduplicated `"confirmed"` entry in `/settlement-vault`), and (e) direct `POST /transactions` (`type: "transfer"`, `paymentChannel: "cash"`). Verify `check-balances.ts` and `pnpm check`, then commit:
  `git commit -m "feat(api): add transfer proofs, payment channels, static vietqr, and settlement vault"`

---

### Task 5.5B.1.3: Settlement cycles, `cycleId` feed filter, member debt breakdowns, guest links & `openapi.json`

**Files:**
- Create: `packages/contract/src/{settlement-cycle,member-breakdown,guest-link}.ts`
- Create: `packages/db/src/{member-breakdowns,guest-links}.ts`
- Create: `apps/api/src/services/{settlement-cycles,member-breakdowns,guest-links}.ts`
- Create: `apps/api/src/routes/{settlement-cycles,guest-links}.ts`
- Modify: `packages/contract/src/{error,jobs,transaction,index}.ts`
- Modify: `packages/db/src/{transactions,groups,index}.ts`
- Modify: `apps/api/src/services/{transactions,transaction-changes}.ts`
- Modify: `apps/api/src/routes/balances.ts`
- Modify: `apps/api/src/app.ts`
- Modify: `packages/contract/openapi.json`

**Interfaces:**
- Consumes: Task `5.5B.1.1` & `5.5B.1.2` schemas and services.
- Produces:
  - `ErrorCode` additions: `"CYCLE_EMPTY"`, `"CYCLE_NOT_LATEST"`.
  - `GroupEventResource` addition: `"settlementCycles"`.
  - `GET /groups/{groupId}/settlement-cycles`, `POST /groups/{groupId}/settlement-cycles` (`Idempotency-Key`, stamps only counted non-deleted rows, leaves `pending` approval rows `cycle_id = NULL`), `DELETE /groups/{groupId}/settlement-cycles/{cycleId}` (`owner` only, latest cycle only).
  - `GET /groups/{groupId}/transactions?cycleId=current|<uuid>` filter; `PATCH` in `transaction-changes.ts` preserves existing `row.cycleId` so closed-cycle transactions remain editable in place (`Owner Decision`).
  - `GET /groups/{groupId}/balances/breakdowns?cycleId=auto|current|<uuid>` (`MemberBreakdownsResponse` with smart `"auto"` focus resolving to `latestCycle` + post-closeout transfers whenever `currentPeriod.expenseCount === 0 && cycles.length > 0`).
  - `GET /groups/{groupId}/guest-link`, `POST /groups/{groupId}/guest-link` (`{ rotate?: boolean }`), `DELETE /groups/{groupId}/guest-link` (allowed even on archived groups).
  - Public unauthenticated IP-rate-limited `GET /guest-links/{token}` (`?cycleId=`, `?cursor=`) & `GET /guest-links/{token}/attachments/{attachmentId}` (`Cache-Control: private, no-store`, serves only counted `expense`/`income` attachments, `404` on `transfer` proofs or revoked token).
  - Regenerated `packages/contract/openapi.json`.

- [ ] **Step 1: Add contract schemas (`settlement-cycle.ts`, `member-breakdown.ts`, `guest-link.ts`, `error.ts`, `jobs.ts`, `transaction.ts`)**
  Define `SettlementCycleDto`, `MemberBreakdownsResponse`, `GuestLinkResponse`, and `GuestGroupViewResponse`.
- [ ] **Step 2: Implement `settlement-cycles` DB/service/routes and `TransactionsQuery.cycleId` + edit preservation**
  Ensure `POST /settlement-cycles` refuses empty open periods with `422 CYCLE_EMPTY`, excludes `pending`/`rejected` rows from `cycle_id` stamping, and `PATCH /transactions/{id}` keeps `cycle_id` unchanged while recalculating cumulative balances.
- [ ] **Step 3: Implement `member-breakdowns` DB/service and `GET /groups/{groupId}/balances/breakdowns`**
  Verify the exact integer invariant `carryOverBalance + focusExpenseDelta + focusTransferDelta + postCycleDelta === netBalance` across `"auto"`, `"current"`, and `<uuid>`.
- [ ] **Step 4: Implement `guest-links` DB/service/routes (`GET/POST/DELETE /groups/{groupId}/guest-link` and public `/guest-links/{token}*`)**
  Generate tokens via `randomBytes(32).toString("base64url")`; never write raw tokens to `activity` or logs; allow `DELETE /guest-link` even when `group.archivedAt !== null`; block `transfer` proof attachments on `/guest-links/{token}/attachments/{attachmentId}` (`404`).
- [ ] **Step 5: Regenerate `packages/contract/openapi.json`, exercise all endpoints on disposable DB, and commit**
  Run `pnpm contract:write` and `pnpm contract:check`. Exercise: (a) close `Đợt 1` while 1 `pending` expense exists (`pending` stays `cycle_id = NULL`), (b) immediately call `/balances/breakdowns` (`auto`) and `/guest-links/{token}` verifying `Đợt 1` expenses are itemized and exact integer sums match `netBalance`, (c) `PATCH` an expense inside `Đợt 1` and verify live `netBalance` updates while `cycleId` stays `Đợt 1`, (d) verify expense attachment `200` vs transfer proof attachment `404` on `/guest-links/{token}/attachments/{id}`, (e) archive the group and call `DELETE /guest-link` (`200`), confirming `/guest-links/{token}` immediately returns `404`. Verify `check-balances.ts` and `pnpm check`, then commit:
  `git commit -m "feat(api): add settlement cycles, member debt breakdowns, guest links, and openapi contract"`

---

### Task 5.5B.1.4: Lock Wave 5.5B Vietnamese UI strings (`vi.ts` + `Localizable.xcstrings`) & Stage 5.5B.1 Gate

**Files:**
- Modify: `apps/web/src/messages/vi.ts`
- Modify: `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: Wave 5.5B Spec §7 Vietnamese UI string table.
- Produces: Locked bidirectional string keys (`settlementProof.*`, `vault.*`, `cycles.*`, `breakdown.*`, `guestLink.*`, `shareCard.*`) consumed read-only by Wave 2 `web` and `ios` workers without key collisions.

- [ ] **Step 1: Add all Wave 5.5B Vietnamese keys to `apps/web/src/messages/vi.ts` and `Localizable.xcstrings`**
  Copy every string from Spec §7 character-for-character (zero emoji) under clean namespaces (`balances.subTabs.*`, `settlementProof.*`, `vault.*`, `cycles.*`, `breakdown.*`, `guestLink.*`, `shareCard.*`).
- [ ] **Step 2: Verify 100% string parity and Swift/TS compilation**
  Run `./apps/ios/Scripts/check-strings.sh` (must print `0 missing, 0 differing`) and `pnpm check`.
- [ ] **Step 3: Run full Stage 5.5B.1 API & Permission Matrix Gate on a reset disposable DB**
  Exercise all 10 rows of Spec §8 Security & Authorization Matrix across unauthenticated (`401` / public `200`|`404`), outsider (`404`), unlinked `viewer`, linked `viewer`, `editor`, and `owner` (both Cookie and Bearer auth), plus archived-group `409 GROUP_ARCHIVED` checks (confirming `DELETE /guest-link` still succeeds `200` when archived), `pnpm contract:check`, `pnpm build`, and `check-balances.ts` (`All groups balanced`).
- [ ] **Step 4: Commit**
  `git commit -m "feat(i18n): lock wave 5.5b vietnamese strings across web and ios"`
