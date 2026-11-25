# Phase 5.5 — UI/UX v2 & Core Product Depth — Overview Design

Date: 2026-11-24. Status: approved by the project owner on 2026-11-24. Read `docs/07-roadmap.md` section 8 first.

This document is the master design specification for **Phase 5.5** (`5.5A -> 5.5B -> 5.5C`). It replaces the single-feed Group Detail assumption in `docs/06-ux-ui/user-flows.md` with **UI/UX v2** and defines the shared visual system, navigation architecture, and wave boundaries across iOS and Web prior to the Server Step and v1 public release. Each wave has its own detailed spec and implementation plan.

## 1. Intent

After Phase 5 (`378df4d`, PR #2) achieved iOS feature parity with Phases 1–4, physical iPhone testing exposed structural UX limits and layout debt (`docs/tech-debt.md` `TD-001`–`TD-007`):

- The Phase 1 single-stream feed (`S4`) became overcrowded once Phases 2–4 layered search/filters, budget warnings, shared fund summaries, statistics shortcuts, pending approvals, and payment actions onto the same screen.
- Chat-style left/right indented cards and inline per-person amount chips break wrapping on 7+ member splits (`TD-006`), while `ConfirmationCardView` overflows horizontally (`TD-005`) and `CreateGroupView` lacks keyboard scroll coordination (`TD-003`).
- `apps/ios/` still relies on the system font fallback because bundled `Be Vietnam Pro` `.ttf` files are absent, and neither Web nor iOS supports Dark Mode or a multi-column Web Desktop layout.
- Real-world usage revealed core functional gaps: cross-group financial visibility, archiving and cloning groups, attachment-backed settlement verification and history, period/cycle closeout, zero-login guest settlement viewing, manual VAT/shipping/discount splitting, recurring bills, household debt grouping, and iOS system integrations.

**Goals:**

- Establish **UI/UX v2** with an iOS-first design mentality and **100% Web parity** for all core capabilities (plus a responsive Web Desktop workspace).
- Preserve the distinctive soul of Sòng Phẳng: geometric colored member shapes (`circle`, `diamond`, `squircle`, `leaf`, `fund`), bold scannable tabular numerals, and the messaging-like Quick Entry bar.
- Resolve all open UX/layout technical debt (`TD-001`, `TD-003`–`TD-007`) and prepare iOS + Web for v1 public release ahead of Android.
- Expand core splitting, settlement archiving/reconciliation, and low-friction sharing without breaking Phase 5A's additive-only OpenAPI v1 contract.

**Non-goals:**

- Multi-currency ledger or FX conversion (remains VND-only on the waiting list).
- Offline write queues or client-side conflict resolution (read-only snapshots remain the offline strategy).
- Nested groups (remains on the waiting list).
- Android implementation (`Phase 6`, deferred until after iOS + Web v1 launch so Android builds once against UI/UX v2).
- Calling live external providers (real SMTP, live APNs, real AI provider) during local development waves.

**Anti-goals:**

- Computing official splits, balances, totals, or VietQR payloads on the client.
- Introducing breaking changes to `/api/v1` schemas or removing existing Web deep URLs.
- Crowding every group capability back onto one scrollable feed screen.
- Silent unauthenticated ledger writes or exposing bank details outside explicitly opted-in controls.

## 2. Wave Structure & Delivery Order

Phase 5.5 executes sequentially in three waves as continuous phase runs (`AGENTS.md` §12), with an owner physical-iPhone and Web acceptance checkpoint at the end of each wave:

| Wave | Branch | Scope | Size | Depends on |
|---|---|---|---|---|
| **5.5A** | `phase-5-5a` | Design System v2 (Light + Dark Mode, `Be Vietnam Pro` `.ttf`, tabular numerals), `TD-001` & `TD-003`–`TD-007` fixes, 4-tab App Shell, 3-segment Group Detail, Full-width Feed Cards, Web Desktop 2–3 column shell, Haptics, Swipe Actions, Hold-to-grow "Bơm hình", Cross-group Overview & Personal Ledger, Group Archive & Clone | L | `main` (`378df4d`) |
| **5.5B** | `phase-5-5b` | Transfer receipt/proof image attachment + payment channel/note, dedicated Settlement History & Reconciliation Vault, Settlement Cycles / Closeout (with carry-over unpaid balances), opt-in revocable Guest Read-only Link (`/share/{token}`) with VietQR, shareable Summary & "Nhắc nợ khéo" cards | L | 5.5A merged |
| **5.5C** | `phase-5-5c` | Manual-form VAT/service fee/shipping/voucher discounts, Recurring Expenses (fixed auto-post & variable-amount reminders), Household / Couple debt grouping, iOS Share Extension (Zalo/Photos import), iOS Home Screen Widget & Quick Actions | L | 5.5B merged |

After **5.5C** is verified locally, the roadmap proceeds to:
1. **Server Step (`server-step`):** Deploy Ubuntu VM stack, configure real SMTP, Google/Apple OAuth, APNs, Telegram webhook, run the 30-receipt real AI benchmark, and distribute iOS via TestFlight.
2. **Phase 7 (`phase-7`):** Public v1 release for **iOS + Web**.
3. **Phase 6 (`phase-6`):** Native Android built once against the finalized UI/UX v2 contract and design system.

Wave 5.5A establishes the complete navigation shell and Design System v2 tokens upfront so Waves 5.5B and 5.5C plug into reserved UI slots with zero navigation redesign.

## 3. Design System v2 (Light & Dark Mode + Typography)

### 3.1 Semantic Color Tokens

All UI components in `apps/web/src/app/globals.css` and `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/Tokens.swift` read semantic tokens rather than raw palette literals. Contrast ratios satisfy WCAG 2.1 AA (`>= 4.5:1` for body and placeholder text against their surface, `>= 3:1` for large numerals and UI controls).

| Token | Role | Light | Dark | Notes |
|---|---|---|---|---|
| `bg` | Page / screen canvas | `#F6F2FB` | `#111016` | Soft lavender canvas in Light; deep slate-violet in Dark |
| `surface` | Primary cards, inputs, sheets | `#FFFFFF` | `#1B1924` | Distinct layer above `bg` |
| `surfaceElevated` | Floating bars, menus, popovers | `#FFFFFF` | `#242130` | Elevated modal / bar background |
| `sunken` | Secondary pills, skeleton blocks, wells | `#E9E4F3` | `#262333` | Recessed fill without borders |
| `borderSubtle` | Subtle card dividers and hairlines | `#E3DDF0` | `#343045` | Used sparingly; never replaces surface contrast |
| `ink` | Primary text, primary CTA fill in Light | `#1C1B22` | `#F5F3FA` | High-contrast foreground |
| `inkRaised` | Elevated dark surfaces (Light) / secondary ink | `#34323D` | `#E2DEF0` | |
| `muted` | Secondary labels, timestamps, metadata | `#5A5766` | `#A8A3BA` | `>= 5.5:1` on `surface` |
| `placeholder` | Input placeholder prompt text | `#6F6B7E` | `#8E88A3` | Fixes `TD-004`; `>= 4.5:1` on `surface` in both modes |
| `onInk` | Text/icons rendered on `ink` fill | `#FFFFFF` | `#14131A` | Inverse foreground |
| `onInkMuted` | Muted text rendered on `ink` fill | `#C9C5D6` | `#514D63` | |
| `dashed` | Dashed separators and empty outlines | `#B9B3CC` | `#4B4660` | |
| `accent` | Brand sun yellow (CTAs, active highlight) | `#FFD84D` | `#F5C93B` | Paired with `onAccent` `#1C1B22` in both modes |
| `onAccent` | Text/icons rendered on `accent` fill | `#1C1B22` | `#1C1B22` | Guaranteed legible contrast on yellow |
| `credit` | Positive amount (owed to user / settled) | `#0E7A4B` | `#5FE0A2` | Used for `+` balance deltas |
| `creditSoft` | Soft fill behind credit pills/badges | `#DFF7EA` | `#153326` | |
| `debt` | Negative amount (user owes / over budget) | `#C73826` | `#FF8A7A` | Used for `-` balance deltas and errors |
| `debtSoft` | Soft fill behind debt/warning pills | `#FFD9D1` | `#3B1E1B` | |
| `warning` | Near-budget or pending caution | `#9A6300` | `#FFD84D` | |
| `warningSoft` | Soft fill behind warning banners | `#FFF3C4` | `#352B14` | |

### 3.2 Member Shape & Quick-Entry Highlight Tokens

- **Member shape fills** stay recognizable across themes while keeping `#1C1B22` dark initials inside every shape (`>= 7:1` contrast):
  - `mint`: Light `#9EEBC0` / Dark `#6BD9A2`
  - `sky`: Light `#9CCBFF` / Dark `#70B4FF`
  - `coral`: Light `#FF8A73` / Dark `#FF7F66`
  - `lilac`: Light `#D3B8FF` / Dark `#BC9AFF`
  - `sun` (`fund`): Light `#FFD84D` / Dark `#F5C93B`
- **Quick-entry phrase highlight fills** (always paired with `ink` foreground):
  - `phraseAmount`: Light `#FFE99A` / Dark `#4A3D14`
  - `phrasePayer`: Light `#CFE3FF` / Dark `#1B3252`
  - `phraseSplit`: Light `#CFF5DF` / Dark `#153D2A`
  - `phraseRest`: Light `#E7D9FF` / Dark `#33214D`

### 3.3 Selection, Motion & Shape Language

- Cards use large rounded corners (`24pt–32pt` depending on card density); buttons and segmented pills use capsule/pill geometry.
- **Active selection:** `3pt` border in `ink` (no drop shadows).
- **Motion:** Spring scale (`300ms`) for share shapes during "Bơm hình", left-to-right highlight sweep (`150ms`) for parsed Quick Entry tokens, and subtle spring feedback on card actions. All animations degrade cleanly to instant state changes when OS Reduce Motion is enabled.

### 3.4 Typography & Tabular Numerals

- **Font family:** Bundle static `Be Vietnam Pro` `.ttf` weights (`400`, `500`, `600`, `700`, `800`, `900`, SIL OFL 1.1) inside `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/` and register them on launch in `Typography.registerFontsIfAvailable()` via `CTFontManagerRegisterFontsForURL`, matching `apps/web/public/fonts/be-vietnam-pro/`.
- **Dynamic Type:** iOS font styles use `Font.custom("BeVietnamPro-...", size:, relativeTo:)` so accessibility scaling up to the largest Dynamic Type setting works cleanly without fixed-frame clipping.
- **Tabular digits:** Every monetary figure and percentage uses `.monospacedDigit()` in iOS (`MoneyText` and inline amount labels) and `font-variant-numeric: tabular-nums` in Web CSS so aligned ledger columns never jitter or misalign.

### 3.5 Theme Persistence

- Appearance mode supports three choices: `Theo hệ thống` (`system`), `Sáng` (`light`), and `Tối` (`dark`).
- Stored per device only (`@AppStorage("appearanceMode")` on iOS; `localStorage` + a static synchronous `/theme-init.js` script setting `data-theme` on `<html>` on Web to prevent light-flash on load without violating `AGENTS.md` §9's ban on `dangerouslySetInnerHTML`). No database column or API endpoint is added.

## 4. Information Architecture v2

### 4.1 App-Level 4-Tab Navigation

| Tab | Vietnamese Label | iOS Root | Web Route | Primary Content |
|---|---|---|---|---|
| 1 | `Tổng quan` | Overview tab | `/` (signed in) | Cross-group net balance (`Tổng được nhận` / `Tổng cần trả`), actionable pending items (`Cần bạn xử lý`), non-zero group breakdown, recent personal ledger preview + link to `/ledger` |
| 2 | `Nhóm` | Groups tab | `/groups` | Segmented toggle `Đang mở` / `Đã lưu trữ`, featured/active group cards with role & pending count, Create Group CTA |
| 3 | `Thông báo` | Notifications tab | `/notifications` | Unread badge on tab item, notification inbox, inline quick-jump to group/transaction, reminder settings |
| 4 | `Tài khoản` | Account tab | `/account` | Profile summary, Appearance selector (`Giao diện`), Notification & Push lock-screen settings, Logged-in Devices, Password management, Delete Account |

Note: Unauthenticated visitors on Web `/` continue to reach `/login` until Phase 7A adds the public landing page.

### 4.2 Group-Level 3-Segment Navigation (`S4` Redesigned)

Inside any group (iOS pushed detail or Web `/g/[groupId]`), the single-screen overload is replaced by a persistent compact header + 3 focused segments:

- **Persistent Compact Group Header:**
  - Back control, group title, optional `Đã lưu trữ` pill when archived.
  - Tappable member-shapes cluster opening `S10` (Members & Invites).
  - Overflow action menu (`...`): `Lịch sử thay đổi`, `Danh mục`, `Telegram`, `Nhân bản nhóm`, `Lưu trữ nhóm` / `Khôi phục nhóm`, `Cài đặt nhóm`.
- **Segment 1 — `Chi tiêu` (Feed & Entry):**
  - Compact trigger row: search bar + filter toggle pill (shows active filter count when filters are applied; filter sheet/drawer opens on tap instead of permanently consuming vertical space).
  - Slim contextual budget banner (shown only when `BUDGET_NEAR` or `BUDGET_OVER` applies).
  - `[5.5B slot]` Cycle indicator chip (active period selector when Settlement Cycles exist).
  - Full-width transaction stream grouped by date dividers (`Hôm nay`, `Hôm qua`, date).
  - Pinned bottom entry dock: `[Manual Form]` button + Quick Entry text input + `[Camera Receipt]` button (`[5.5C]` adds recurring option inside Manual Form). Replaced by a clear read-only notice banner (`Nhóm đã lưu trữ — chỉ xem`) when the group is archived.
- **Segment 2 — `Thanh toán` (Settlements & Balances):**
  - Personal net balance hero card (`Bạn được nhận ...` / `Bạn cần trả ...` / `Bạn đã xong`).
  - Actionable suggested transfers (`N lượt chuyển là xong`) with inline VietQR sheet, `Tôi đã chuyển`, `Đã nhận`, and direct settle controls.
  - `[5.5B slot]` **Sổ thanh toán** (dedicated Settlement History & Receipt Proof Vault) and **Chốt đợt / Hồ sơ đã chốt** trigger & archive browser.
  - `[5.5B slot]` Opt-in Guest Read-only Link & "Nhắc nợ khéo" share trigger.
  - Group balance bars (`Cán cân của nhóm`) at the bottom of the segment.
- **Segment 3 — `Quỹ & Thống kê` (Fund, Budget & Analytics):**
  - Shared Fund summary & contribute/return actions (or owner/editor setup card if no fund exists yet).
  - Monthly/group Budget limit progress card + edit limit control.
  - Statistics summary (`Theo danh mục`, `Theo người`, `Theo thời gian`) + CSV Export action.
  - `[5.5C slot]` **Giao dịch định kỳ** management list.

**Deep-route compatibility:** Existing Web URLs (`/g/[groupId]/balances`, `/stats`, `/fund`, `/members`, `/settings`, `/activity`, `/tx/[transactionId]`) and iOS `PushDestination` / `Route` paths remain valid. Web sub-routes render inside the shared group shell with the corresponding segment active; iOS push destinations route cleanly onto the appropriate tab and push the target group/segment or detail screen.

### 4.3 Web Desktop Multi-Column Layout

- **Mobile / Narrow Web (`< 1024px`):** Single-column layout (`max-width: 480px` centered or full mobile viewport) with a fixed bottom 4-tab bar mirroring iOS 1:1.
- **Tablet / Compact Desktop (`1024px – 1279px`):** **2-column layout** — Left persistent navigation rail (`260px`: Sòng Phẳng mark, 4 primary tabs with unread badge, scrollable quick active-group switcher, `Tạo nhóm mới` button, theme quick switch) + Center workspace (`flex-1`, content measure up to `760px`).
- **Wide Desktop (`>= 1280px` inside `/g/[groupId]`):** **3-column layout** — Left rail (`260px`) + Center workspace (active Group segment) + Right contextual inspector (`340px`) displaying live Group Balances & quick settle shortcuts alongside the Expense Feed, or live Transaction Detail preview when a card is inspected, eliminating constant tab/page jumping on desktop browsers.

## 5. Full-Width Transaction Card & Dense-Group Rules

The indented chat-bubble layout in `S4` is retired across both iOS and Web to fix horizontal crowding and multi-line number wrapping (`TD-006`):

1. **Full-width cards with clear elevation:** Every transaction spans the full content width on `surface` (with subtle `creditSoft` / `ink` / `sunken` status cues instead of `48pt` left/right indent margins).
2. **Three-row card anatomy (Expenses & Income):**
   - **Header row:** Payer `MemberShape` (`28pt`) + `"Bạn trả"` or `"{name} trả"` (with `+{k}` badge when multi-payer, or fund badge when paid by fund) + short time + status chips (`Đã sửa`, comment count badge, `Chờ duyệt`, or `Đang phản đối`).
   - **Body row:** Description (max 2 lines) and optional category pill on the left; right-aligned numeric stack with **Total Amount** (`font-bold`, single-line tabular digits, never wrapped) above **"Phần của bạn"** signed delta (`+180.000 đ` in `credit`, `-45.000 đ` in `debt`, or `Không tham gia` in `muted`), read directly from server-computed `myDelta`.
   - **Footer row:** Compact overlapping participant cluster (up to 5 `22pt` member shapes + `+N` overflow badge) + split method label (`Chia đều`, `Theo món`, `Theo phần`, `Theo số tiền`, `Theo %`). **Per-member VND amount chips are never rendered on feed cards.**
3. **Transfer card anatomy:** Compact single-band card showing `From shape -> To shape`, `"{from} đã chuyển {to}"`, right-aligned tabular amount, and `[5.5B slot]` proof thumbnail badge when a bank receipt image is attached.
4. **Detail drill-down:** Tapping any card opens `S20` Transaction Detail (or desktop inspector), where the full itemized list, per-member shares, attachments, comments, disputes, and Edit/Delete live without width pressure.
5. **Group-size stress standard:** Every card, confirmation sheet, and split selector must render cleanly for **7 to 20 active members** on a `375pt` portrait iPhone screen up to accessibility Dynamic Type sizes without horizontal clipping or wrapped currency numbers.

## 6. Wave 5.5B & 5.5C Extension Slots

To keep Wave 5.5A self-contained while ensuring zero rework later:

- **Wave 5.5B plugs into:**
  - `Settle` sheet/modal + `POST /settlement-requests` / direct `transfer`: optional attachment upload (`transfer_proof`) and `channel` (`bank`, `momo`, `zalopay`, `cash`) + short reference note.
  - `Thanh toán` segment: **Sổ thanh toán** sub-view (`GET /settlement-requests` + confirmed transfer history with proof thumbnails) and **Chốt đợt** cycle selector/closeout modal (`settlement_cycles`).
  - `Chi tiêu` segment header: optional cycle filter chip when closed cycles exist.
  - `S10` / `Thanh toán`: Guest Read-only Link management (`POST /groups/{id}/guest-link`) driving unauthenticated `/share/{token}` view and 1-tap Share Sheet image export for Summary / "Nhắc nợ khéo".
- **Wave 5.5C plugs into:**
  - `S8` Expense Form + Quick Entry: manual-form `extras` (VAT %, service fee, shipping, discount/voucher amount) using the existing `core` proportional/equal largest-remainder allocator.
  - `Quỹ & Thống kê` segment + `S8`: Recurring expense templates (`recurring_expenses`) + pg-boss scheduled job.
  - `S10` + `Thanh toán`: Household / couple grouping metadata (`households`) feeding server-side balance transfer calculation (`packages/core`).
  - iOS Target Extensions: App Group shared Keychain/container supporting `SongPhangShareExtension` (images from Zalo/Photos) and `SongPhangWidgetExtension` (Overview snapshot + deep links).

## 7. Contract, Architecture & Standing Document Updates

- **API compatibility:** Every addition in Waves 5.5A–C follows the additive-only `/api/v1` contract rule (new routes, optional query parameters, nullable/optional response fields, new enum values with client unknown-fallback).
- **Planned ADRs (recorded in `docs/04-adr.md` alongside Wave 5.5A approval/implementation):**
  - **ADR-034:** UI/UX v2 navigation architecture (4-tab app shell, 3-segment group detail, full-width feed cards replacing chat bubbles, multi-column desktop layout).
  - **ADR-035:** Per-device Light/Dark theme persistence and WCAG-verified semantic token mapping across Web CSS and SwiftUI `Tokens`.
  - Future ADR numbers (`ADR-036+`) are reserved for Waves 5.5B and 5.5C specs.
- **Standing documents:** Once Wave 5.5A is approved, `docs/06-ux-ui/user-flows.md`, `docs/05-api-spec.md`, `docs/05-database-design.md`, and `docs/03-srs.md` will be updated to reflect UI/UX v2 and the Wave 5.5A endpoints and schema additions.
