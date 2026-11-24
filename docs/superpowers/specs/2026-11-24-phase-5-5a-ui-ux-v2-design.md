# Wave 5.5A — UI/UX v2, Design System & Cross-Group Foundation — Design

Date: 2026-11-24. Status: approved by the project owner on 2026-11-24, including bundling static Be Vietnam Pro `.ttf` fonts (weights 400–900, SIL OFL 1.1) in `apps/ios/`. Read `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md` first.

## 1. Intent

Wave 5.5A builds the visual and architectural foundation of **UI/UX v2** across iOS and Web: semantic Light & Dark themes, bundled `Be Vietnam Pro` `.ttf` typography on iOS, full resolution of open physical-device technical debt (`TD-001`, `TD-003`–`TD-007`), a 4-tab App Shell, a 3-segment Group Detail screen with full-width transaction cards, a responsive Web Desktop layout, native iOS polish (Haptics, Swipe Actions, hold-to-grow "Bơm hình"), Cross-Group Overview & Personal Ledger, and Group Archive & Clone.

**Goals:**
- Close `TD-001`, `TD-003`, `TD-004`, `TD-005`, `TD-006`, and re-verify `TD-007` on a physical iPhone (`TD-002` remains deferred to Server Step).
- Introduce Design System v2 (`Light` + `Dark` semantic tokens, `Be Vietnam Pro` `.ttf` on iOS, tabular digits everywhere).
- Ship the 4-tab App Shell + 3-segment Group Shell + Full-Width Feed Cards + Web Desktop multi-column shell cleanly so Waves 5.5B and 5.5C plug in without structural UI rewrites.
- Ship Cross-Group Overview (`GET /api/v1/me/overview`), Personal Ledger (`GET /api/v1/me/transactions`), and Group Archive/Unarchive/Clone with 100% iOS/Web parity.
- Re-introduce hold-to-grow **"Bơm hình"** on both iOS and Web (`SplitEditor`).

**Non-goals:**
- Settlement proofs/vault, settlement cycles, guest read-only links, or shareable summary cards (Wave 5.5B).
- Manual-form VAT/shipping/discount extras, recurring expenses, household debt grouping, iOS Share Extension, or iOS Home Screen Widgets (Wave 5.5C).
- Production SMTP, live OAuth/APNs/AI verification, or Android (Server Step / Phase 7 / Phase 6).

**Anti-goals:**
- Computing `netBalance`, `totalOwedToMe`, `totalIOwe`, or transaction `myDelta` on the client instead of using authoritative server integers.
- Making breaking changes to existing `/api/v1` endpoints or breaking existing deep links (`/g/[groupId]/*`, `/join/[token]`, push targets).
- Allowing writes to an archived group (`409 GROUP_ARCHIVED`).

## 2. Delivery Stages (`phase-5-5a`)

Run files live under `docs/superpowers/runs/phase-5-5a/` (`progress.md`, `decisions.md`, `manual-checks.md`).

| Stage | Scope | Branch Target |
|---|---|---|
| **5.5A.0** | Re-baseline `main`, verify existing Node/Postgres/Xcode gates, verify bundled `Be Vietnam Pro` `.ttf` font assets (`400`–`900`). | `phase-5-5a` |
| **5.5A.1** | Database migration (`groups.archived_at`), additive OpenAPI v1 schemas & `openapi.json`, `GROUP_ARCHIVED` write guard, `archive`/`unarchive`/`clone` endpoints, `GET /me/overview`, `GET /me/transactions`, `myDelta` on transactions, and `status` filter + `role` + `pendingActionCount` on `GET /groups`. | `phase-5-5a` |
| **5.5A.2** | Design System v2: Light & Dark CSS custom properties (`apps/web/src/app/globals.css`) + SwiftUI semantic `Tokens.swift`, per-device appearance storage, `Be Vietnam Pro` `.ttf` registration & Dynamic Type `Typography.swift`, tabular digits (`MoneyText` + web money formatter), `TD-001` Next.js `allowedDevOrigins` dev-host fix, `TD-004` placeholder contrast fix. | `phase-5-5a` |
| **5.5A.3** | App Navigation Shell v2: iOS 4-tab `TabView` (per-tab `NavigationStack`, unified deep-link & push routing, multi-tab offline banner) and Web bottom nav; Cross-Group Overview (`S0`) + Overview snapshot caching; Personal Ledger (`S0b`); Group List segmented `Đang mở` / `Đã lưu trữ`; Group Archive/Unarchive & Clone flows (iOS + Web). | `phase-5-5a` |
| **5.5A.4** | Group Screen v2 (`S4` 3-segment shell: `Chi tiêu`, `Thanh toán`, `Quỹ & Thống kê`), Full-Width Feed Cards (`TD-006`), collapsible filter bar, Quick Entry `ConfirmationCardView` wrapping grid (`TD-005`), `CreateGroupView` keyboard scroll fix (`TD-003`), `TD-007` verification, iOS Haptics & Swipe Actions, and **"Bơm hình"** hold-to-grow share interaction (iOS + Web). | `phase-5-5a` |
| **5.5A.5** | Web Desktop 2–3 column responsive shell (`>= 1024px` / `>= 1280px`), standing docs & ADR updates (`ADR-034`, `ADR-035`), full verification gate (`pnpm check`, `pnpm build`, `check-strings.sh`, `swift-format lint --strict`, Debug + unsigned Release `xcodebuild`, `pnpm db:check-balances`, permission matrix, 5.5A acceptance scripts), and owner physical-iPhone + Web manual-check handoff. | `phase-5-5a` |

## 3. Database Schema Changes (5.5A.1)

One additive Drizzle migration (`packages/db/src/schema-groups.ts` + generated migration under `packages/db/drizzle/`):

- Table `groups` adds:
  - `archived_at timestamptz NULL` (default `NULL`)
  - Index `groups_archived_at_idx` on `(archived_at)` (or `(created_at, id)` paired with `archived_at`).
- Update `findGroup`, `listUserGroups`, and `updateGroup` helpers in `packages/db/src/groups.ts` to project `archivedAt`.
- **Invariants preserved:** `transaction_payers`, `transaction_shares`, deferred balance triggers, and `pnpm db:check-balances` remain untouched. Archived groups remain complete ledgers whose member balances still sum strictly to `0`.

## 4. API & Contract Changes (Strictly Additive v1)

All changes live in `packages/contract/src/` and regenerate `packages/contract/openapi.json` via `pnpm contract:write`.

### 4.1 Error Codes & Additive DTO Fields

- **`ErrorCode` (`packages/contract/src/error.ts`):** Add `"GROUP_ARCHIVED"`. Returned with HTTP `409` whenever a write operation targets an archived group.
- **`GroupDto` (`packages/contract/src/group.ts`):**
  - Add `archivedAt: z.iso.datetime().nullable()`.
- **`GroupSummaryDto` (`packages/contract/src/group.ts`):**
  - Add `archivedAt: z.iso.datetime().nullable()`.
  - Add `role: GroupRole`.
  - Add `pendingActionCount: z.int().nonnegative()` (count of pending settlement confirmations actionable by the caller + pending expense approvals if the caller is owner; `0` when archived or none).
- **`GET /api/v1/groups` (`packages/contract/src/group.ts`):**
  - Optional query parameter: `status?: "active" | "archived" | "all"` (defaults to `"all"` when omitted so existing v1 callers continue receiving all groups).
- **`BaseTransactionFields` (`packages/contract/src/transaction.ts`, shared by `TransactionDto` and `TransactionListItemDto`):**
  - Add `myDelta: z.int().nullable()`.
  - **Exact server formula (matching `packages/db/src/balances.ts`):**
    - If `deletedAt !== null` or `approval.status === "rejected"`, or the signed-in user has no linked member in the group (`myMemberId === null`), `myDelta = null`.
    - Otherwise let `myPaid = sum(payers where memberId === myMemberId)` and `myShare = sum(shares where memberId === myMemberId)`.
    - If `myPaid === 0 && myShare === 0`, `myDelta = null` (displayed as `Không tham gia`).
    - For `type === "expense"` or `type === "transfer"`: `myDelta = myPaid - myShare`.
    - For `type === "income"`: `myDelta = myShare - myPaid`.
    - Property invariant: across all non-deleted, non-rejected transactions in a group, `sum(myDelta ?? 0) === myBalance`.
- **New `GroupEventResource` values (`packages/contract/src/jobs.ts`):**
  - Existing resources (`group`, `members`, `users`, `transactions`, `balances`, `activity`, `settlementRequests`, `categories`, `budget`, `receiptScans`, `comments`) suffice for Wave 5.5A (`archive`/`unarchive` emit `["group", "activity"]`).

### 4.2 Archive & Unarchive Endpoints

| Method & Path | Access & Guards | Behavior |
|---|---|---|
| `POST /api/v1/groups/{groupId}/archive` | `requireUser`, `requireGroupRole("owner")`, `requireVerifiedEmail`, `requireWriteLimit`, `requireSameOrigin` | Locks group row. If `archivedAt === null`, sets `archivedAt = now`, `updatedAt = now`, writes activity (`entityType: "group"`, `action: "group.archived"`), emits SSE `["group", "activity"]`. Idempotent when already archived (returns `200 GroupResponse`). |
| `POST /api/v1/groups/{groupId}/unarchive` | `requireUser`, `requireGroupRole("owner")`, `requireVerifiedEmail`, `requireWriteLimit`, `requireSameOrigin` | Locks group row. If `archivedAt !== null`, sets `archivedAt = null`, `updatedAt = now`, writes activity (`entityType: "group"`, `action: "group.unarchived"`), emits SSE `["group", "activity"]`. Idempotent when already active (returns `200 GroupResponse`). |

**Archived Write Guard (`409 GROUP_ARCHIVED`):**
While `group.archivedAt !== null`, the service layer (inside the group lock) refuses with `409 GROUP_ARCHIVED`:
- Creating, editing, deleting, or restoring transactions (`POST/PATCH/DELETE/restore` transactions, transaction change proposals if any).
- Opening or resolving disputes; creating or deleting comments.
- Creating, confirming, rejecting, or cancelling settlement requests.
- Approving or rejecting pending transactions.
- Adding, renaming, toggling active status, or setting payment details on members; updating group settings (except `unarchive` or owner `DELETE /groups/{groupId}`); rotating or disabling invites; joining via invite (`POST /invites/{token}/join`); updating fund, budget, categories, reminders, or uploading attachments / receipt scans / Telegram pairing for the group.
- Allowed on archived groups: all `GET` endpoints (feed, balances, stats, activity, CSV export, attachments), `unarchive`, `clone`, `mute/unmute`, `leave group` (respecting existing owner/non-zero-balance rules), and owner `DELETE /groups/{groupId}`.

### 4.3 Clone Group Endpoint

`POST /api/v1/groups/{groupId}/clone`
- **Access & Guards:** `requireUser`, `requireGroupRole("editor")` (allows `editor` and `owner`, refuses `viewer` with `403 FORBIDDEN` and non-members with `404 NOT_FOUND`), `requireVerifiedEmail`, `requireWriteLimit`, `requireSameOrigin`, `Idempotency-Key` required. Allowed regardless of whether the source group is active or archived.
- **Request (`CloneGroupRequest`):**
  ```json
  {
    "name": "Đà Lạt tháng 12",
    "copyPaymentMethods": true,
    "copyCategories": false
  }
  ```
  - `name`: `GroupName` (trimmed, 1–80 chars).
  - `copyPaymentMethods`: boolean, default `true`.
  - `copyCategories`: boolean, default `false`.
- **Transactional Behavior (`201 GroupResponse`):**
  1. Creates a new active group (`archivedAt = null`) owned by the caller (`group_users` has **only** the caller with `role: "owner"`), copying `minimizeDebts` and `defaultRole` from source.
  2. Copies all **active `person` members** (`kind = 'person' AND active = true`) ordered by `position` (`1..N`), preserving `name`, `shape`, `color`, and `defaultWeight` (never copying `fund` members or inactive members).
  3. Links the caller's `group_users.member_id` to the cloned copy of the caller's linked source member (if the caller was unlinked or their source member was inactive, creates/prepends a member named `user.name` as position `0` and links the caller, preserving the rule that every creator has a member).
  4. When `copyPaymentMethods` is `true`, copies `member_payment_methods` for the cloned active person members into the new group (never logged in activity payloads or server logs).
  5. When `copyCategories` is `true`, copies non-archived custom `group_categories` from source into the new group.
  6. Copies **zero** transactions, balances, invites, chat links, or other users' accounts/memberships. Records `group.created` activity in the new group.

### 4.4 Cross-Group Overview Endpoint

`GET /api/v1/me/overview`
- **Access:** `requireUser`.
- **Response (`OverviewResponse`):**
  ```ts
  {
    totalOwedToMe: number; // integer >= 0 (sum of myBalance > 0 across all member groups)
    totalIOwe: number; // integer >= 0 (sum of abs(myBalance) where myBalance < 0)
    netBalance: number; // totalOwedToMe - totalIOwe (signed integer)
    activeGroupCount: number; // integer >= 0
    archivedGroupCount: number; // integer >= 0
    pendingSettlementCount: number; // integer >= 0 across active groups
    pendingApprovalCount: number; // integer >= 0 across active groups
    pendingActions: Array<
      | {
          kind: "settlement_confirmation";
          id: string; // settlementRequestId
          groupId: string;
          groupName: string;
          amount: number;
          actorName: string; // paying member name
          description: string; // paying -> receiving member label
          createdAt: string;
        }
      | {
          kind: "expense_approval";
          id: string; // transactionId
          groupId: string;
          groupName: string;
          amount: number;
          actorName: string; // creator / payer name
          description: string; // transaction description
          createdAt: string;
        }
    >; // max 20 newest items across active groups where group.archivedAt === null
    groupBalances: Array<{
      groupId: string;
      groupName: string;
      archivedAt: string | null;
      role: "owner" | "editor" | "viewer";
      myBalance: number; // non-zero integer
      memberCount: number;
      previewMembers: Array<{ id: string; name: string; shape: MemberShapeCode; color: MemberColorCode }>;
    }>; // ordered by abs(myBalance) desc, groupName asc
  }
  ```
- **Actionability rules:**
  - `settlement_confirmation` matches Phase 2 confirmation rules (`settlement_requests.status = 'pending'` in an active group where either `to_member_id = caller.memberId`, caller is `owner`, or caller is `editor` and `to_member_id` is unlinked).
  - `expense_approval` matches Phase 4 approval rules (`transactions.approval_status = 'pending' AND deleted_at IS NULL` in an active group where caller is `owner`).
  - `totalOwedToMe`, `totalIOwe`, `netBalance`, and `groupBalances` include both active and archived groups with non-zero balances so unsettled debt in an archived trip is never silently hidden.

### 4.5 Personal Cross-Group Ledger Endpoint

`GET /api/v1/me/transactions`
- **Access:** `requireUser`.
- **Query (`PersonalTransactionsQuery`):**
  - `cursor?: string` (max 512, opaque base64url `(occurredAt, id)` matching group feed cursor style).
  - `limit?: number` (integer `1..50`, default `20`).
  - `type?: "expense" | "transfer" | "income"`.
  - `groupId?: uuid` (when provided, if user is not in that group returns empty list or `404`? Return `404 NOT_FOUND` if the user has no access to `groupId`, matching group authorization rules).
  - `q?: string` (trimmed `1..100`, matched against `description_search` normalized Vietnamese text).
- **Scoping:** Returns non-deleted transactions across groups the caller currently belongs to where the caller's linked `member_id` in that group appears in `transaction_payers` or `transaction_shares` (`exists`). Users with no linked member in a group see no transactions from that group. Removing a user from a group immediately excludes that group's items.
- **Response (`PersonalTransactionsResponse`):**
  ```ts
  {
    items: Array<{
      id: string;
      groupId: string;
      groupName: string;
      groupArchivedAt: string | null;
      type: "expense" | "income" | "transfer";
      description: string;
      amount: number;
      myDelta: number; // exact signed integer for the caller in this transaction (`0` when settled or pending/rejected in ledger scope; `TransactionDto.myDelta` stays `number | null`)
      occurredAt: string;
      category: TransactionCategory | null;
      categoryName: string | null;
      payerSummary: string; // e.g., "Bạn" or "Lan" or "Lan + 1"
      participantCount: number;
      approvalStatus: ApprovalStatus;
      hasOpenDispute: boolean;
    }>;
    nextCursor: string | null;
  }
  ```

## 5. Detailed UI/UX, Technical Debt Fixes & Interaction Rules

### 5.1 Resolving Open Technical Debt (`docs/tech-debt.md`)

| ID | Root Cause | Wave 5.5A Fix |
|---|---|---|
| `TD-001` | Next.js dev server rejects cross-origin asset fetches from `.local` Mac hostnames with `403`. | In `apps/web/next.config.ts`, populate `allowedDevOrigins` only when `NODE_ENV === "development"` from `WEB_ORIGIN` hostname (and optional comma-separated `ALLOWED_DEV_ORIGINS` hostname list in dev config), while preserving strict origin checks in production and ignoring invalid hosts. |
| `TD-003` | `CreateGroupView` keeps focus after adding a member without scrolling the newly inserted row or input into view, and keyboard + toolbar overlaps bottom bar. | Wrap `CreateGroupView` form in `ScrollViewReader`; assign deterministic IDs to the member input row and bottom error slot; scroll smoothly on `addedMembers.count` change and focus entry; ensure bottom submit button uses native `.safeAreaInset(edge: .bottom)` cleanly without competing root keyboard accessories obscuring the CTA across SE/Pro portrait & large Dynamic Type. |
| `TD-004` | `NewMemberInputRow` and `FeedSearchBarView` leave prompt styling to SwiftUI default on white `Tokens.surface`, rendering low-contrast gray placeholders. | Introduce `Tokens.placeholder` (`#6F6B7E` Light / `#8E88A3` Dark) across `SPTextField`, `NewMemberInputRow`, `FeedSearchBarView`, Quick Entry field, and Web inputs (`placeholder:text-placeholder`), using explicit `prompt: Text(...).foregroundStyle(Tokens.placeholder)` in SwiftUI. |
| `TD-005` | `ConfirmationCardView` passes all participants to `ShareShapesView` inside a single non-wrapping `HStack`, overflowing viewport width on 7+ participants. | Wrap `ConfirmationCardView` content inside vertical scrolling when needed and refactor `ShareShapesView` to use an adaptive wrapping layout (`LazyVGrid` / flow layout with 4 columns on compact iPhone, dynamic minimum width, horizontal pill chips with `.lineLimit(1)` + `.minimumScaleFactor(0.8)` or concise tabular amounts) so 7–20 participants fit cleanly inside `375pt` portrait width without clipping header, total, or action buttons. |
| `TD-006` | `GroupFeedSubViews` indents "your" cards by `48pt` and packs 4+ per-person amount chips horizontally, wrapping `35.715` into 3 lines. | Retire chat bubbles and inline per-person amount chips from `GroupFeedView` and Web feed cards; replace with the 3-row **Full-Width Transaction Card** (Overview spec §5) where total amount and `myDelta` stay single-line (`monospacedDigit`, `lineLimit(1)`, `minimumScaleFactor(0.75)`). Move search/filter/fund/stats pressure into the 3-segment Group shell. |
| `TD-007` | Installed build predated `d379b75` adding `feed.tripTotal`. | Verify `"Tổng chuyến đi"` renders in the redesigned `Quỹ & Thống kê` / Group header on device and passes `check-strings.sh`. |

### 5.2 Design System v2 & Bundled Font Assets (`5.5A.2`)

- **Web (`apps/web/`):**
  - Refactor `apps/web/src/app/globals.css` so `:root` defines Light token values and `html[data-theme="dark"]` (plus `@media (prefers-color-scheme: dark)` fallback when `data-theme="system"` or unset) defines Dark token values via semantic CSS variables (`--color-bg`, `--color-surface`, `--color-surface-elevated`, `--color-sunken`, `--color-border-subtle`, `--color-ink`, `--color-ink-raised`, `--color-muted`, `--color-placeholder`, `--color-on-ink`, `--color-on-ink-muted`, `--color-dashed`, `--color-accent`, `--color-on-accent`, `--color-credit`, `--color-credit-soft`, `--color-debt`, `--color-debt-soft`, `--color-warning`, `--color-warning-soft`, plus Dark member/phrase variables).
  - Add inline non-blocking theme-init `<script>` in `apps/web/src/app/layout.tsx` (no `dangerouslySetInnerHTML` with untrusted input — strictly static constant JS reading `localStorage.getItem("sp-theme")` against `"light" | "dark" | "system"`!) so Dark Mode loads with zero flash. Ensure `color-scheme: light dark` is applied on `<html>` for native scrollbars and date inputs.
  - Ensure all web numeric/currency displays apply `tabular-nums`.
- **iOS (`apps/ios/`):**
  - Bundle `Be Vietnam Pro` static `.ttf` files (`400` Regular, `500` Medium, `600` SemiBold, `700` Bold, `800` ExtraBold, `900` Black) in `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` alongside `LICENSE.txt` (`SIL OFL 1.1`).
  - Implement `Typography.registerFontsIfAvailable()` using `CTFontManagerRegisterFontsForURL` once on startup (`AppShell`), and map `Typography` font styles to `BeVietnamPro-*` with `relativeTo:` Dynamic Type text styles.
  - Upgrade `Tokens.swift` so every semantic color resolves dynamically via `UIColor { traitCollection in traitCollection.userInterfaceStyle == .dark ? ... : ... }` (including `Tokens.placeholder`, `Tokens.credit`, `Tokens.debt`, `Tokens.surfaceElevated`, `Tokens.borderSubtle`, and theme-aware `color(for:)`).
  - Apply `.preferredColorScheme(...)` in `RootView` from `@AppStorage("appearanceMode")` (`system` / `light` / `dark`), and `.monospacedDigit()` on `MoneyText` and tabular amounts.

### 5.3 App Navigation Shell, Overview & Archive/Clone (`5.5A.3`)

- **iOS 4-Tab `TabView` (`AppShell`):**
  - Tabs: `.overview` (`Tổng quan`, hosted in a new `OverviewFeature` target in `SongPhangKit/Package.swift` depending strictly on `Domain`, `DesignSystem`, and `PreviewSupport`), `.groups` (`Nhóm`), `.notifications` (`Thông báo`, displaying unread count badge), `.account` (`Tài khoản`).
  - Each tab owns an independent `NavigationStack(path:)`.
  - **Unified routing (`RootView` + `LinkRouter`):**
    - Tapping an Overview action (`settlement_confirmation` or `expense_approval`) switches to `.groups` and pushes the target group directly to `.thanhToan` segment or `TransactionDetail`.
    - Universal Link (`/join/{token}`) switches to `.groups` (or presents post-auth resumption) and pushes `JoinGroup`.
    - Push notifications switch to the matching tab (`.notifications` for `/notifications`, `.groups` for `/g/{id}*`) and reset or push the clean destination stack after checking authorization (`LinkRouter.pushDestination`).
  - Global `OfflineBanner` renders cleanly above tab content across all 4 tabs; write triggers disable gracefully offline.
  - `SnapshotStore` adds user-scoped `overview.json` snapshot alongside groups/group detail snapshots, cleared on sign-out, session loss, or account deletion.
- **Web Navigation & New Routes:**
  - Signed-in `/` renders **Tổng quan** (`Overview`); `/groups` renders **Nhóm** (`Đang mở` / `Đã lưu trữ`); `/ledger` renders **Giao dịch của bạn** (`Personal Ledger`); `/notifications` and `/account` remain on their routes inside the shared responsive App Shell (bottom 4-tab bar `< 1024px`, persistent left sidebar `>= 1024px`).
- **Archive & Clone UX:**
  - `Nhóm` tab has a segmented toggle `Đang mở` / `Đã lưu trữ`. Groups with `archivedAt !== null` display under `Đã lưu trữ`, badge `Đã lưu trữ`, and open in read-only mode (hidden bottom Quick Entry dock + visible `Nhóm đã lưu trữ — chỉ xem` banner; owner can restore via `Khôi phục nhóm`).
  - Group overflow menu (`...`) and `GroupSettings` expose `Lưu trữ nhóm` / `Khôi phục nhóm` (owner only, confirmation dialog) and `Nhân bản nhóm` (owner/editor).
  - Clone sheet/modal asks only for new group name (pre-filled `"{oldName} (bản sao)"` or editable), checkbox `Sao chép thông tin nhận tiền` (default ON), and optional checkbox `Sao chép danh mục tuỳ chỉnh` (default OFF), then navigates straight into the newly created active group.

### 5.4 Group Screen v2, Haptics, Swipe Actions & "Bơm hình" (`5.5A.4`)

- **Group 3-Segment Shell (`GroupContainerView` in `AppShell` / Web `/g/[groupId]`):**
  - On iOS, `GroupContainerView` lives in `AppShell` (which already imports `LedgerFeature`, `PaymentsFeature`, and `StatisticsFeature`) so feature modules never import one another (`apps/ios/AGENTS.md` §3).
  - Segment switcher (`Chi tiêu` | `Thanh toán` | `Quỹ & Thống kê`) pinned cleanly below the compact header.
  - `Chi tiêu` segment: Search bar + `Lọc` pill (collapsible filter sheet/panel), slim budget warning pill when triggered, Full-Width Transaction Cards grouped by date, bottom Quick Entry bar (`Manual` + input + `Camera`).
  - `Thanh toán` segment: Embeds/hosts `BalancesView` content (My net hero, `N lượt chuyển là xong`, `Tôi đã chuyển` / `Đã nhận` / VietQR, `Cán cân của nhóm`).
  - `Quỹ & Thống kê` segment: Hosts Shared Fund summary + actions, Budget limit progress card, Statistics summary (`Tiền đi đâu`) + CSV Export.
  - Deep routes (`Balances`, `Stats`, `Fund`) and Web `/g/[groupId]/balances|stats|fund` continue working seamlessly (on Web, visiting those routes selects the matching segment inside the shared layout or renders focused detail on sub-flows like `/settle`, `/pay`, `/members`, `/activity`, `/settings`, `/tx/*`).
- **iOS Native Haptics & Swipe Actions:**
  - `Haptics` utility in `DesignSystem` wrapping `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` (respecting user system settings, light/medium/success/warning only on explicit actions: Quick Entry parse confirmation, save transaction, confirm settlement, "Bơm hình" tick, swipe threshold).
  - **Swipe Actions** on Full-Width Feed Cards in `Chi tiêu` (only when `!group.isArchived && isOnline`):
    - Leading swipe (when `canEdit` and transaction is active & not rejected): `Sửa` (opens `EditTransaction`).
    - Trailing swipe: `Xoá` (destructive, when `canEdit`, triggers soft-delete + undo snackbar) and/or `Phản đối` / `Chi tiết` (viewer/editor).
- **"Bơm hình" (Hold-to-grow share interaction, iOS & Web):**
  - Available in `SplitEditor` (`S8`) under `Theo phần` (`shares`), `Theo %` (`percent`), and `Số tiền` (`exact`) split modes.
  - **Interaction:** Each selected participant renders in a wrapping grid of interactive `MemberShapeView` / `MemberShape` badges showing current share/amount underneath. Pressing and holding a member shape triggers a repeating timer (`180ms` cadence after `250ms` initial hold) that increments that member's allocation by a discrete step:
    - `Theo phần`: `+1` weight on held member (others unchanged; total weight increases naturally).
    - `Theo %`: `+5%` on held member (clamped to `100%`), reducing other selected members in integer basis/percent steps (or leaving unpinned members balanced cleanly) while keeping total `100%`.
    - `Số tiền`: increments the held member's integer exact amount by a fixed integer step (`+10.000 đ`, or `+1.000 đ` when `totalAmount < 100.000 đ`, clamped to `[0, totalAmount]`) using integer addition/subtraction only — never floating-point or multiplication/division on `Money` (`apps/ios/AGENTS.md` §5) — leaving the server preview endpoint to compute any remaining split distribution.
  - Held shape animates smoothly with `300ms` spring scale (instant when Reduce Motion is enabled), and emits a `.light` haptic tick per step on iOS.
  - **Server truth:** When the gesture ends (or settles after a brief debounce), the client calls the existing `POST /api/v1/groups/{groupId}/transactions/preview` endpoint so the displayed official share amounts always come from `core` on the server.
  - **Accessibility:** Standard numeric text fields / steppers sit directly beneath or beside the shapes so keyboard users, VoiceOver (`accessibilityAdjustableAction` / hint `"Nhấn giữ để tăng phần chia"`), and precise edits never require long-press.

### 5.5 Web Desktop Multi-Column Shell (`5.5A.5`)

- Shared responsive layout shell (`apps/web/src/components/layout/AppShell.tsx`):
  - `< 1024px`: Fixed bottom 4-tab bar + top safe padding; single-column content (`max-w-[480px] mx-auto`).
  - `1024px – 1279px`: Fixed left rail (`260px`) + centered workspace (`max-w-[760px]`).
  - `>= 1280px` on `/g/[groupId]*`: Left rail (`260px`) + center workspace (`flex-1 min-w-0 max-w-[760px]`) + sticky right inspector (`340px`) displaying live Group Net Status + Suggested Transfers (or selected Transaction preview when inspecting from the feed).
  - Unauthenticated/invite/auth routes (`/login`, `/register`, `/forgot-password`, `/reset-password`, `/verify-email`, `/join/[token]`) stay clean centered single-column shells without the signed-in app navigation rail.

## 6. Vietnamese UI Strings (100% Web & iOS Parity)

All keys are added to `apps/web/src/messages/vi.ts` and `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`, verified by `./apps/ios/Scripts/check-strings.sh` (`0 missing, 0 differing`). No emoji anywhere.

| Key Group | Exact Vietnamese Strings |
|---|---|
| App Tabs | `Tổng quan`, `Nhóm`, `Thông báo`, `Tài khoản` |
| Group Segments | `Chi tiêu`, `Thanh toán`, `Quỹ & Thống kê` |
| Overview (`S0`) | `Tổng quan tài chính`, `Tổng được nhận`, `Tổng cần trả`, `Chênh lệch ròng`, `Bạn đã sòng phẳng ở tất cả nhóm`, `Cần bạn xử lý`, `Số dư theo nhóm`, `Giao dịch gần đây của bạn`, `Xem tất cả giao dịch`, `Xác nhận nhận tiền`, `Duyệt khoản chi`, `Chưa có giao dịch nào` |
| Personal Ledger (`S0b`) | `Giao dịch của bạn`, `Tất cả nhóm`, `Tìm theo mô tả`, `Không tham gia`, `Phần của bạn` |
| Group List & Archive | `Đang mở`, `Đã lưu trữ`, `Chưa có nhóm nào đã lưu trữ`, `Lưu trữ nhóm`, `Lưu trữ nhóm này? Nhóm sẽ chuyển sang chế độ chỉ xem, số dư và lịch sử vẫn được giữ nguyên.`, `Khôi phục nhóm`, `Nhóm đã lưu trữ — chỉ xem`, `Thao tác này không khả dụng khi nhóm đã lưu trữ.` |
| Group Clone | `Nhân bản nhóm`, `Tên nhóm mới`, `Sao chép thông tin nhận tiền`, `Sao chép danh mục tuỳ chỉnh`, `Tạo nhóm từ bản sao` |
| Appearance | `Giao diện`, `Theo hệ thống`, `Sáng`, `Tối` |
| Card & Split | `Tất cả {count} người`, `Nhấn giữ để tăng phần chia`, `Cần thao tác` |
| Desktop Shell | `Điều hướng`, `Nhóm đang mở`, `Tóm tắt số dư` |

## 7. Security & Authorization Matrix

| Action / Endpoint | Unauthenticated | Outsider | Viewer | Editor | Owner | Additional Checks |
|---|---|---|---|---|---|---|
| `GET /me/overview` | `401` | — | Self only | Self only | Self only | Strictly scoped to groups in `group_users` for `user.id`; zero cross-user leakage |
| `GET /me/transactions` | `401` | `404` (if `groupId` invalid/outsider) | Self only | Self only | Self only | Strictly scoped to current memberships + linked `member_id`; deleted transactions excluded |
| `POST /groups/{id}/archive` | `401` | `404` | `403` | `403` | `200` | Verified email, write limit, same-origin; idempotent |
| `POST /groups/{id}/unarchive` | `401` | `404` | `403` | `403` | `200` | Verified email, write limit, same-origin; idempotent |
| `POST /groups/{id}/clone` | `401` | `404` | `403` | `201` | `201` | Verified email, write limit, same-origin, `Idempotency-Key`; bank details copied in DB transaction only, never logged |
| Mutations inside archived group | `401` | `404` | `403`/`409` | `409 GROUP_ARCHIVED` | `409 GROUP_ARCHIVED` | Checked inside group row lock before any ledger/member/setting mutation |

Additional security guarantees:
- Web theme initialization script contains zero user-controlled values (`dangerouslySetInnerHTML` avoided or strictly avoided via static non-interpolated script / Next.js compatible attribute init — prefer zero `dangerouslySetInnerHTML` per `AGENTS.md` §9 by using a small static file `/theme-init.js` or Next.js `<Script strategy="beforeInteractive" src="/theme-init.js" />`!). Note: `AGENTS.md` §9 explicitly forbids `dangerouslySetInnerHTML` in web code, so loading a tiny static `/theme-init.js` asset (permitted by CSP `script-src 'self'`) respects §9 strictly!
- `TD-001` `allowedDevOrigins` applies strictly when `NODE_ENV === "development"` and parses clean hostnames via `URL.parse`, never opening wildcard origins or weakening production origin/CSRF checks.
- `Overview` and `PersonalLedger` snapshots on iOS reside in user-scoped protected files inside `SnapshotStore` and are wiped on sign-out, session revocation, or account deletion.

## 8. Standing Document Updates & ADRs

Upon approval/implementation of Wave 5.5A:
- `docs/04-adr.md`: Record **ADR-034** (UI/UX v2 navigation shell, 3-segment Group Detail, Full-Width Feed Cards, and Desktop shell) and **ADR-035** (Per-device Light/Dark theme persistence and semantic token contract).
- `docs/05-api-spec.md`: Document `GET /me/overview`, `GET /me/transactions`, `POST /groups/{id}/archive`, `POST /groups/{id}/unarchive`, `POST /groups/{id}/clone`, `GROUP_ARCHIVED`, and additive fields on `GroupDto`, `GroupSummaryDto`, `TransactionDto`/`TransactionListItemDto`, and `GET /groups?status=`.
- `docs/05-database-design.md`: Document `groups.archived_at`.
- `docs/06-ux-ui/user-flows.md`: Add UI/UX v2 amendment or update flows/tokens/layouts to reflect 4-tab shell, 3-segment group view, Dark Mode tokens, Full-Width Cards, and "Bơm hình".
- `docs/tech-debt.md`: Update status of `TD-001`, `TD-003`–`TD-007` as verified/closed after physical iPhone testing.

## 9. Verification & Owner Prerequisites

### 9.1 Owner Prerequisites Before Starting 5.5A Run

1. Approve `docs/superpowers/specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md` and this Wave 5.5A design spec.
2. Confirm static `Be Vietnam Pro` `.ttf` font files (`400`–`900`, SIL OFL 1.1) may be committed into `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` (either supplied by owner or downloaded from the official Google Fonts / Be Vietnam Pro release during task setup).

### 9.2 Automated & Local Verification Gates (Wave 5.5A Exit Criteria)

- `pnpm check` passes (`biome check .`, `pnpm -r typecheck`, `pnpm contract:check`).
- `pnpm build` passes cleanly for Next.js production build.
- `./apps/ios/Scripts/check-strings.sh` passes with `0 missing, 0 differing`.
- `xcrun swift-format lint --strict --recursive apps/ios` passes with zero warnings/errors.
- `xcodebuild` Simulator Debug and unsigned Release builds succeed with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` and zero debug leaks in Release.
- `pnpm db:check-balances` passes (`All groups balanced`) after replaying Phase 1–5 + Wave 5.5A acceptance scripts on a reset disposable database (`sum(myDelta) === myBalance`, archive `409` guards, clone isolation, cross-group overview totals, permission matrix including `404` outsider checks).

### 9.3 Owner Manual Verification Checklist (Physical iPhone & Web Browser)

1. **Theme & Contrast (`TD-004`):** Switch `Giao diện` between `Theo hệ thống`, `Sáng`, and `Tối` on both iPhone and Web; verify zero flash on Web reload; verify placeholders (`Tìm khoản chi`, `Tên người mới`) and numeric deltas remain crisp in Light, Dark, and iOS Increase Contrast.
2. **Dense Group Stress (`TD-005`, `TD-006`, `TD-003`):** Create an 8-member group on a physical iPhone (`TD-003`: keyboard never covers `Tạo nhóm` and scrolls to newly added row); pick a 7-person Quick Entry sample (`TD-005`: card fits width without clipping); add an uneven expense and view the `Chi tiêu` feed (`TD-006`: no wrapped currency digits, full-width card easy to scan); adjust Dynamic Type to an accessibility size and re-check.
3. **"Bơm hình" & Haptics:** Long-press a member shape in `Theo phần`, `Theo %`, and `Số tiền` on both iPhone (verify haptic ticks + spring scale + server preview) and Web mouse/touch.
4. **Cross-Group Overview, Archive & Clone:** Verify `Tổng quan` totals match sum of positive/negative group balances across 2+ groups, approve an item or confirm settlement straight from Overview, archive a group (verify read-only state on iOS & Web), clone it with payment methods, and unarchive it.
5. **Local Email Verification (`TD-001`) & Desktop Shell:** Open a local `.local` verification link from iPhone (`TD-001`: reaches confirmation screen instead of stalling); open Web at `1440px` desktop width and verify 3-column `/g/[groupId]` workspace + live balance inspector.
