# Wave 5.5B — Stage 5.5B.2: Web Implementation (`apps/web/`)

> Runs in Wave 2 in parallel with Stage `5.5B.3` (`ios`) **after** Stage `5.5B.1` is merged onto `phase-5-5b`. Touch **only** `apps/web/**` (do not edit `apps/web/src/messages/vi.ts`, which was locked in `5.5B.1.4`; if an unforeseen key is ever needed, coordinate via the Coordinator).

### Task 5.5B.2.1: Web data hooks, optional proof/channel/note in `Pay` & `Settle`, and Transfer proof badge

**Files:**
- Create: `apps/web/src/lib/{settlement-vault,settlement-cycles,member-breakdowns,guest-links}.ts`
- Create: `apps/web/src/components/pay/TransferProofFields.tsx`
- Modify: `apps/web/src/lib/{attachments,settlement-requests,transactions,use-group-events}.ts`
- Modify: `apps/web/src/components/pay/{PayContent,PayFooter}.tsx`
- Modify: `apps/web/src/components/balances/{SettlementForm,PendingRequestRow}.tsx`
- Modify: `apps/web/src/components/feed/ExpenseRow.tsx`
- Modify: `apps/web/src/components/transaction/` (display `paymentChannel` & `paymentNote` on transfer detail)

**Interfaces:**
- Consumes: Locked `@songphang/contract` DTOs (`PaymentChannel`, `SettlementVaultResponse`, `SettlementCyclesResponse`, `MemberBreakdownsResponse`, `GuestLinkResponse`, `GuestGroupViewResponse`) and `vi.*` keys from `5.5B.1.4`.
- Produces:
  - React Query hooks: `useSettlementVault`, `useSettlementCycles`, `useCloseSettlementCycle`, `useReopenSettlementCycle`, `useMemberBreakdowns`, `useGuestLink`, `useEnableGuestLink`, `useRevokeGuestLink`, `useGuestGroupView`, and `uploadAttachment(..., { purpose: "transfer_proof" | "expense" })`.
  - SSE invalidation in `use-group-events.ts` handling `"settlementCycles"` (invalidating `cycles`, `transactions`, `balances`, `breakdowns`, `settlement-vault`) and `"settlementRequests"`/`"transactions"` invalidating `settlement-vault` & `breakdowns`.
  - Reusable `<TransferProofFields />` (`channel` pills, optional receipt image picker using `prepare-image.ts`, 120-char `note` input) wired into `PayContent`/`PayFooter` and `SettlementForm` while keeping 1-tap submit enabled when all optional fields are blank.

- [ ] **Step 1: Add React Query hooks and update `attachments.ts` (`purpose`) + `use-group-events.ts` (`settlementCycles`)**
  Scope all query keys under `["group", groupId, ...]` so SSE invalidations refresh Vault, Cycles, and Breakdowns automatically.
- [ ] **Step 2: Build `<TransferProofFields />` and integrate into `Pay` (`Tôi đã chuyển`) and `SettlementForm` (`Ghi nhận`)**
  Pre-select active payment method tab (`bank`/`momo`/`zalopay`) as toggleable default channel in `Pay`; keep proof upload & note strictly optional so 1-tap submit works immediately.
- [ ] **Step 3: Render proof thumbnail, channel pill, and note on `PendingRequestRow`, `ExpenseRow` (transfer band), and Transaction Detail**
  Add tappable lightbox preview on `PendingRequestRow` (`proofAttachmentId`) and compact `28px` proof badge (`firstAttachmentId`) + channel/note subtitle on Transfer rows in `ExpenseRow.tsx` without wrapping right-aligned tabular VND amounts.
- [ ] **Step 4: Run `pnpm check` and commit**
  `git commit -m "feat(web): add optional transfer proof, channel, note, and feed proof badges"`

---

### Task 5.5B.2.2: Segment `Thanh toán` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Breakdown drawer & `Chi tiêu` cycle chip

**Files:**
- Create: `apps/web/src/components/balances/{SettlementVaultView,SettlementCyclesView,CloseCycleModal,MemberBreakdownSheet}.tsx`
- Create: `apps/web/src/components/feed/CycleFilterChip.tsx`
- Modify: `apps/web/src/app/g/[groupId]/page.tsx`
- Modify: `apps/web/src/app/g/[groupId]/balances/page.tsx`
- Modify: `apps/web/src/components/balances/{SettlementCard,OwnSettlementCard,OtherSettlements,BalanceBars}.tsx`
- Modify: `apps/web/src/components/feed/ExpenseStream.tsx`
- Modify: `apps/web/src/components/layout/GroupInspector.tsx`

**Interfaces:**
- Consumes: Hooks from `5.5B.2.1` (`useSettlementVault`, `useSettlementCycles`, `useMemberBreakdowns`).
- Produces:
  - 3-pill switcher at top of `Thanh toán`: `Cần thanh toán` (default, hosting Hero + Quick Action Bar `[Xuất ảnh / Nhắc nợ] [Link khách] [Chốt đợt]` + Transfers + BalanceBars) | `Sổ thanh toán` (`SettlementVaultView` with summary strip, `all|pending|confirmed|with_proof` chips, lightbox) | `Đợt đã chốt` (`SettlementCyclesView` showing `Số liệu tại thời điểm chốt`, jump-to-`Chi tiêu` CTA, and owner `"Mở lại đợt này"` on latest cycle).
  - `<MemberBreakdownSheet />` triggered from any transfer card or `BalanceBars` row, displaying `carryOverBalance`, itemized period lines, `postCycleDelta` if any, `netBalance`, and `Phân bổ thanh toán` when `abs(netBalance) !== transfer.amount`.
  - `<CycleFilterChip />` on `Chi tiêu` header (hidden when `cycles.length === 0`; defaults to `Đợt hiện tại` when `cycles.length >= 1`, switchable to any closed cycle or `Tất cả các đợt`).

- [ ] **Step 1: Build `<MemberBreakdownSheet />`, `<SettlementVaultView />`, `<SettlementCyclesView />`, and `<CloseCycleModal />`**
  Ensure every monetary column uses `tabular-nums` and reads server-computed integers directly from `useMemberBreakdowns` / `useSettlementVault` / `useSettlementCycles`.
- [ ] **Step 2: Wire 3-pill sub-navigation and Quick Action Bar into `Thanh toán` (`/g/[groupId]` & `/g/[groupId]/balances`) and `GroupInspector.tsx`**
  Hide `Chốt đợt` when `group.archivedAt !== null` or `role === "viewer"`; disable with hint when `currentPeriod.countedTransactionCount === 0`; wire `<MemberBreakdownSheet />` trigger onto transfer/member rows in both `Thanh toán` and desktop `GroupInspector.tsx`.
- [ ] **Step 3: Add `<CycleFilterChip />` to `Chi tiêu` (`ExpenseStream.tsx` / `/g/[groupId]/page.tsx`)**
  Pass selected `cycleId` (`"current"`, `<uuid>`, or `undefined`) into `useTransactions`, defaulting to `"current"` once `cycles.length >= 1`, and support jumping from `Đợt đã chốt` -> `Chi tiêu` with that cycle selected.
- [ ] **Step 4: Run `pnpm check` and commit**
  `git commit -m "feat(web): add settlement vault, closeout cycles, breakdown sheet, and feed cycle filter"`

---

### Task 5.5B.2.3: Guest Link management UI, `AppShell` / `AASA` public routing, and `/share/[token]` page

**Files:**
- Create: `apps/web/src/components/guest/{GuestLinkModal,GuestGroupPage,GuestExpenseDetailModal}.tsx`
- Create: `apps/web/src/app/share/[token]/page.tsx`
- Modify: `apps/web/src/components/layout/AppShell.tsx`
- Modify: `apps/web/src/app/.well-known/apple-app-site-association/route.ts`
- Modify: `apps/web/src/components/members/` (add `Link khách chỉ xem` entry point alongside invite link for `owner`/`editor`)

**Interfaces:**
- Consumes: `GET/POST/DELETE /groups/{groupId}/guest-link` and public `GET /guest-links/{token}` & `/guest-links/{token}/attachments/{attachmentId}`.
- Produces:
  - `<GuestLinkModal />` accessible from `Thanh toán` Quick Action Bar and `S10` (`Members`), supporting enable, copy URL, rotate (`Đổi link mới`), and revoke (`Thu hồi link`, enabled even when group is archived).
  - Unauthenticated `/share/[token]` page (`metadata: { robots: { index: false, follow: false } }`) bypassing signed-in `AppShell` chrome (`pathname.startsWith("/share/")` wrapped in `SnackbarProvider`), with Light/Dark theme switch, cycle selector, expandable per-transfer **Giải trình khoản nợ + VietQR (`QrCard`) + copyable receiver details**, and read-only group transaction list with `<GuestExpenseDetailModal />` (itemized shares + expense receipt images).
  - Updated `apple-app-site-association` including `{ "/": "/share/*" }`.

- [ ] **Step 1: Update `AppShell.tsx` (`isAuthPath` -> `/share/`) and `apple-app-site-association/route.ts` (`/share/*`)**
  Wrap `/share/` routes in `<SnackbarProvider>` without mounting `DesktopSidebar` or `MobileTabBar` so unauthenticated guests trigger zero `/notifications` or `/me` calls.
- [ ] **Step 2: Build `<GuestLinkModal />` and wire into `Thanh toán` and `Members` (`S10`)**
  Show clear privacy note from Spec §7, 1-tap copy, rotate confirmation, and revoke action (including on archived groups).
- [ ] **Step 3: Build `/share/[token]/page.tsx`, `<GuestGroupPage />`, and `<GuestExpenseDetailModal />`**
  Support expanding any transfer/member to inspect full server-computed breakdown + `Phân bổ thanh toán` + `QrCard`, cycle switching, `"Xem thêm"` cursor pagination, expense receipt image viewing, and clean `404` revoked state.
- [ ] **Step 4: Run `pnpm check` and commit**
  `git commit -m "feat(web): add revocable guest link management and public share page with vietqr"`

---

### Task 5.5B.2.4: 1-tap HTML5 2D `<canvas>` Share Card Export (`Tổng kết nhóm` & `Nhắc nợ khéo`) & Stage 5.5B.2 Web Gate

**Files:**
- Create: `apps/web/src/lib/share-card-canvas.ts`
- Create: `apps/web/src/components/balances/ShareCardModal.tsx`
- Modify: `apps/web/src/app/g/[groupId]/page.tsx` (or `Thanh toán` container wiring `ShareCardModal`)
- Modify: `apps/web/src/app/g/[groupId]/balances/page.tsx`

**Interfaces:**
- Consumes: `BalancesResponse` (`qrPayload` + `accountQrPayload`), `MemberBreakdownsResponse`, `SettlementCyclesResponse`, `GuestLinkResponse`, `qrcode` (`create`), and Design System v2 Light/Dark palette tokens.
- Produces:
  - `renderShareCardPng(options): Promise<Blob>` in `share-card-canvas.ts` drawing a crisp `1170px`-wide (`390pt @ 3x`) dynamic-height PNG on HTML5 2D `<canvas>` after `await document.fonts.ready` (`Be Vietnam Pro`), rendering geometric member shapes (`circle`, `diamond`, `squircle`, `leaf`), exact integer VND tabular numerals (zero rounding, zero emoji), and QR modules from `qrcode`.
  - `<ShareCardModal />` with live preview, `Tổng kết nhóm` | `Nhắc nợ khéo` tabs, `Nền sáng` | `Nền tối` toggle, `Kèm tóm tắt các khoản chi` toggle, debtor target picker (`Tất cả` or 1 transfer with itemized breakdown + `Phân bổ thanh toán` + exact-amount VietQR), 3 preset captions + custom 100-char line, and 1-tap `navigator.share({ files })` with automatic `Tải ảnh PNG` + `Sao chép ảnh` fallback.

- [ ] **Step 1: Implement pure 2D `<canvas>` card layout engine in `apps/web/src/lib/share-card-canvas.ts`**
  Support unbounded vertical height for 20+ transfers without clipping, exact Light (`#F6F2FB`/`#FFFFFF`/`#1C1B22`/`#FFD84D`) and Dark (`#111016`/`#1B1924`/`#F5F3FA`/`#F5C93B`) palettes, static `accountQrPayload` on single-receiver summary cards, and dynamic `qrPayload` + breakdown box on 1-debtor `Nhắc nợ khéo` cards.
- [ ] **Step 2: Build `<ShareCardModal />` and wire to `Xuất ảnh / Nhắc nợ` in `Thanh toán`**
  Use `navigator.canShare?.({ files: [file] })` for native mobile Share Sheet and provide instant PNG download + clipboard copy on desktop.
- [ ] **Step 3: Run Stage 5.5B.2 Web Gate & live exercises**
  Run `pnpm check` and `pnpm build`. Against a disposable DB + local API/Web server, exercise a 16-member badminton group (`G4 Badminton 2026` style) through: optional proof upload + Vault filters, `Chốt đợt` -> immediate `/share/[token]` in an unauthenticated session (verifying 0 `/me` or `/notifications` requests, itemized breakdown, VietQR, expense modal, and instant `404` on revoke), and exporting both `Tổng kết nhóm` and 1-debtor `Nhắc nợ khéo` PNGs in Light & Dark modes (verifying `1170px` width and exact integer VND).
- [ ] **Step 4: Commit**
  `git commit -m "feat(web): add high-dpi canvas share card export for group summary and polite reminders"`
