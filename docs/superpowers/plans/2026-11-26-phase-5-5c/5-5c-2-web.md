# Wave 5.5C — Stage 5.5C.2: Web Implementation (`apps/web/`)

> Runs in Wave 2 in parallel with Stage `5.5C.3` (`ios`) **after** Stage `5.5C.1` is merged onto `phase-5-5c`. Touch **only** `apps/web/**` (do not edit `apps/web/src/messages/vi.ts`, which was locked in `5.5C.1.4`; coordinate via Coordinator if an unforeseen key is ever needed).

### Task 5.5C.2.1: Manual-form `extras` on `S8` (`ExpenseForm` & `SplitEditor`) and breakdown display on `S20` & `/share/[token]`

**Files:**
- Create: `apps/web/src/components/expense-form/ManualExtrasCard.tsx`
- Modify: `apps/web/src/lib/transactions.ts`
- Modify: `apps/web/src/components/expense-form/{ExpenseForm,SplitEditor,use-expense-form,use-split-state}.ts*`
- Modify: `apps/web/src/components/receipt/{ExtrasFields,ItemsAssignmentPanel,use-receipt-editor}.ts*`
- Modify: `apps/web/src/components/transaction/TransactionSummary.tsx`
- Modify: `apps/web/src/components/guest/GuestExpenseDetailModal.tsx`

**Interfaces:**
- Consumes: `POST /groups/{groupId}/transactions/extras/preview` (`PreviewExtrasRequest`/`PreviewExtrasResponse`), generalized `SplitInput` (`extras`, `extrasAllocation`, `ratePercent`, `"shipping"`), and locked `vi.extras.*` keys.
- Produces:
  - `usePreviewExtras` React Query hook (300 ms debounced with cancellation) in `apps/web/src/lib/transactions.ts`.
  - Quick capsule chips (`VAT 8%`, `+ VAT 10%`, `+ Phí DV 5%`, `+ Phí ship`, `- Giảm giá`, `+ Phụ phí khác`) and `<ManualExtrasCard />` directly beneath `AmountField` on `S8` (`type === "expense"`):
    - Zero clutter when `extras.length === 0`; switches `AmountField` label to `Tiền hàng` when active.
    - Segmented pill `Chia đều` (default on `S8`) | `Theo tỷ lệ`, `%` | `đ` input mode on `tax`/`service`/`discount` (clearing `ratePercent` when the user edits the đồng value directly), and `phraseAmount` summary bar showing authoritative `Tổng thanh toán: {computedAmount}` (`tabular-nums`).
    - Works seamlessly across `equal`, `exact`, `shares`, `percent`, and `items` (and exposes `Chia đều` | `Theo tỷ lệ` on Receipt Review defaulting to `Theo tỷ lệ`).
  - `TransactionSummary.tsx` (`S20`) and `GuestExpenseDetailModal.tsx` (`/share/[token]`) rendering `Tiền hàng`, each extra line (`+27.680 đ` / `-40.000 đ`), allocation mode label, and `Tổng thanh toán` whenever `split.extras` is non-empty on any split method.

- [ ] **Step 1: Add `usePreviewExtras` in `apps/web/src/lib/transactions.ts` and extend `use-split-state.ts` / `use-expense-form.ts`**
  Ensure zero client-side percentage math: all `%` extras and `computedAmount` / `shares` come from `POST .../transactions/extras/preview` (`items` mode also passes `extrasAllocation`).
- [ ] **Step 2: Build `<ManualExtrasCard />` + quick chips on `ExpenseForm.tsx` and update `SplitEditor.tsx` & `ExtrasFields.tsx`**
  Support 1-tap `VAT 8%` / `VAT 10%` / `Phí DV 5%` toggle, `"shipping"` kind, and editing existing transactions that carry `extras` + `ratePercent`.
- [ ] **Step 3: Render `extras` breakdown across all split methods in `TransactionSummary.tsx` and `GuestExpenseDetailModal.tsx`**
  Keep all figures single-line `tabular-nums` in Light & Dark modes.
- [ ] **Step 4: Run `pnpm check` and commit**
  `git commit -m "feat(web): add manual-form extras chips, percent/vnd preview, and detail breakdowns"`

---

### Task 5.5C.2.2: Recurring Expenses (`S8` inline toggle, `Quỹ & Thống kê` management, `Tổng quan` due prompts & notifications)

**Files:**
- Create: `apps/web/src/lib/recurring-expenses.ts`
- Create: `apps/web/src/components/recurring/{RecurringInlineCard,RecurringSection,RecurringFormModal}.tsx`
- Modify: `apps/web/src/lib/use-group-events.ts`
- Modify: `apps/web/src/components/expense-form/{ExpenseForm,use-expense-form}.ts*`
- Modify: `apps/web/src/components/stats/StatsContent.tsx`
- Modify: `apps/web/src/app/g/[groupId]/page.tsx`
- Modify: `apps/web/src/components/overview/PendingActionsList.tsx`
- Modify: `apps/web/src/components/notifications/NotificationRow.tsx`

**Interfaces:**
- Consumes: `GET/POST/PATCH/DELETE /groups/{groupId}/recurring-expenses*`, `POST .../skip`, `OverviewResponse.dueRecurringActions`, `SplitTransactionRequest` (`recurring`, `recurringExpenseId`), `"recurringExpenses"` SSE resource, and `vi.recurring.*` keys.
- Produces:
  - React Query hooks: `useRecurringExpenses`, `useCreateRecurringExpense`, `useUpdateRecurringExpense`, `useDeleteRecurringExpense`, `useSkipRecurringExpense`, plus SSE invalidation on `"recurringExpenses"`.
  - `<RecurringInlineCard />` on `S8` (create `expense` mode only) allowing 1-tap `"Lặp lại định kỳ"` (`fixed` | `variable`, `weekly` | `monthly` | `quarterly` | `yearly`), plus pre-fill handling when `S8` opens with `?recurringId=<uuid>` to complete a due `"variable"` bill.
  - `<RecurringSection />` & `<RecurringFormModal />` inside Segment 3 (`Quỹ & Thống kê` — both `/g/[groupId]` segment and `/g/[groupId]/stats`) with highlighted due banner (`Nhập số tiền kỳ này` / `Bỏ qua kỳ này`), template list, create/edit/pause/resume/skip/delete actions.
  - Due recurring prompts in `PendingActionsList.tsx` (`Tổng quan`) and notification copy/navigation in `NotificationRow.tsx` for `"recurring_posted"` and `"recurring_due"`.

- [ ] **Step 1: Add `apps/web/src/lib/recurring-expenses.ts` hooks and wire `"recurringExpenses"` in `use-group-events.ts`**
  Invalidate `recurring-expenses` and `overview` queries when recurring templates mutate or complete.
- [ ] **Step 2: Build `<RecurringInlineCard />` + `?recurringId=` pre-fill in `ExpenseForm` / `use-expense-form.ts`**
  Pre-fill description, category, payer, suggested hint amount (or blank), and split template when completing a due variable item, submitting `recurringExpenseId` on save.
- [ ] **Step 3: Build `<RecurringSection />` & `<RecurringFormModal />` in `StatsContent.tsx` and wire `PendingActionsList.tsx` + `NotificationRow.tsx`**
  Hide write buttons for `viewer` or archived groups (keeping `Xoá mẫu` available to `editor+` when archived).
- [ ] **Step 4: Run `pnpm check` and commit**
  `git commit -m "feat(web): add recurring expenses management, inline s8 toggle, and overview due prompts"`

---

### Task 5.5C.2.3: Household / Couple Debt Grouping (`S10`, `Thanh toán`, `Nhóm`, `GroupInspector`, `/share/[token]`, `ShareCard`) & Stage 5.5C.2 Web Gate

**Files:**
- Create: `apps/web/src/lib/households.ts`
- Create: `apps/web/src/components/members/{HouseholdsCard,HouseholdModal}.tsx`
- Modify: `apps/web/src/lib/use-group-events.ts`
- Modify: `apps/web/src/app/g/[groupId]/members/page.tsx`
- Modify: `apps/web/src/components/members/MemberRow.tsx`
- Modify: `apps/web/src/components/balances/{OwnSettlementCard,OtherSettlements,SettlementCard,BalanceBars,MemberBreakdownSheet,ShareCardModal}.tsx`
- Modify: `apps/web/src/lib/share-card-canvas.ts`
- Modify: `apps/web/src/components/groups/{FeaturedGroupCard,GroupCard}.tsx`
- Modify: `apps/web/src/components/feed/BalanceBlock.tsx`
- Modify: `apps/web/src/components/layout/GroupInspector.tsx`
- Modify: `apps/web/src/components/overview/OverviewSummaryCard.tsx` (group row sub-label when `householdName` present)
- Modify: `apps/web/src/components/guest/GuestGroupPage.tsx`

**Interfaces:**
- Consumes: `GET/POST/PATCH/DELETE /groups/{groupId}/households*`, `BalancesResponse` (`households`, `fromHousehold`, `toHousehold`), `MemberBreakdownsResponse.householdBreakdowns`, `GroupSummaryDto` & `OverviewGroupBalance` (`householdName`, `myIndividualBalance`), `"households"` SSE resource, and `vi.households.*` keys.
- Produces:
  - `<HouseholdsCard />` & `<HouseholdModal />` on `S10` (`Members`) + household badge on `MemberRow.tsx`.
  - Household-aware Personal Hero Card, `"own"` transfer matching (including non-representative household members seeing outgoing `fromHousehold` transfers with `"Tôi đã chuyển"` enabled!), `Đại diện {name}` subtitles on transfers, `Theo hộ / cặp đôi` summary in `BalanceBars`, and `Tổng hợp hộ {name}` section in `MemberBreakdownSheet`, `GuestGroupPage` (`/share/[token]`), `GroupInspector`, and `share-card-canvas.ts` (`Tổng kết nhóm` & `Nhắc nợ khéo`).

- [ ] **Step 1: Add `apps/web/src/lib/households.ts`, wire `"households"` SSE invalidation, and build `<HouseholdsCard />` + `<HouseholdModal />` in `S10`**
  Highlight members who already have VietQR/payment methods configured when selecting `Người đại diện thanh toán`.
- [ ] **Step 2: Update `Thanh toán`, `GroupInspector`, `Nhóm` cards, `Overview`, `/share/[token]`, `MemberBreakdownSheet`, and `share-card-canvas.ts` for households**
  Ensure a non-representative partner (`Lan`, including `linked viewer`) sees their household's outgoing transfer in their own actionable card and can submit `"Tôi đã chuyển"`, while incoming `"Đã nhận"` appears only for the representative (`Minh`) or `owner` (or `editor` when unlinked).
- [ ] **Step 3: Run Stage 5.5C.2 Web Gate & live browser exercises**
  Run `pnpm check` and `pnpm build`. Against a disposable DB + isolated API/Web server, exercise: (a) Three Koala `346.000 đ + VAT 8% = 373.680 đ` + equal voucher water-filling in `S8` -> `S20` -> `/share/[token]`; (b) creating fixed & variable recurring templates in `Quỹ & Thống kê` and `S8`, triggering worker due state, completing from `Tổng quan` `Cần bạn xử lý` and skipping a period; (c) creating `Nhà Minh & Lan` in `S10`, verifying consolidated `350.000 đ` transfer + breakdown + `ShareCard` PNG in Light/Dark, `Lan` submitting `"Tôi đã chuyển"`, `Minh` confirming `"Đã nhận"`, and verifying `0 đ` across `Tổng quan`, `Nhóm`, `Chi tiêu`, `Thanh toán`, `GroupInspector`, and `/share/[token]`. Capture screenshots for Coordinator.
- [ ] **Step 4: Commit**
  `git commit -m "feat(web): add household debt grouping across members, settlements, guest links, and share cards"`
