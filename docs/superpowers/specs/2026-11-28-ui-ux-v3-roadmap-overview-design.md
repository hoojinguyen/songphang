# UI/UX v3 — Roadmap Overview (Phases 5.6–5.9)

Date: 2026-11-28. Status: roadmap approved by the project owner on 2026-11-28. Each phase still needs its own spec and plan, approved before its run. Read `docs/07-roadmap.md` section 9 first.

This document sets the order, scope and boundaries of the UI/UX v3 redesign. It records the decisions the owner has already made, and the direction that each phase spec must work out. Every finding and defect of the review is tracked separately in the findings register (section 1), so none is lost. It does not define screens in detail; the phase specs do.

## 1. Intent

Phase 5.5 (Waves 5.5A–5.5C, merged on `main`, last merge `b6ad8cd`, PR #5) added the features the product needed, but each wave placed its features directly on the main screens. A UI/UX review of the iOS app on 2026-11-28 (iPhone 17 Pro and iPhone SE, scripted data, `main@6839bbf`) found:

- **Too much at once.** Group Detail has three levels of navigation before the main task (segment, sub-tab, button row). The expense form shows 10 blocks for a task that needs 3 inputs. The app has 963 UI strings, up 44% over three waves.
- **Accounting language.** "Chênh lệch ròng", "Giải trình khoản nợ", "Đợt đã chốt", "Ghi nhận" make users translate in their heads.
- **A static app.** 17 animation calls, no transitions, no sound, haptics in 8 files, `accessibilityReduceMotion` read in only 4 files.
- **Custom navigation.** The hand-built header loses the native iOS back gesture, Liquid Glass bars and standard transitions, and causes several layout defects (section 7).
- **Four recurring patterns** across 17 further screens: one task with two sets of controls; large sheets with little content; no clear landing place after finishing a task; on small screens the answer is pushed below the fold.
- **Three product gaps** raised by the owner: no single place that answers "whom do I pay, and how much" across groups; payment details stored per group instead of per account; no way to duplicate an expense.

The review pages are private artifacts owned by the project owner:

- Part 1, main screens: https://claude.ai/artifact/V2pnPiiaDgYFnUP4VrwutS
- Part 2, detail screens: https://claude.ai/artifact/1pPqWyGEvhC3iJHnRKjz34
- Part 3, direction and decisions: https://claude.ai/artifact/XhnuFd9j59r6ywDopcHugz
- Part 4, remaining screens and global checks: https://claude.ai/artifact/2j55wSDoTTZ6jfGGcLSsta

The full record lives in the repository at `docs/superpowers/research/2026-11-28-ui-ux-v3-review/`: a Markdown copy of each part with its screenshots, and `findings.md`, a register of all 316 findings and 21 defects with IDs, owning phase and status. Use those files, not the artifact pages, which agents cannot open. This overview summarises; where it is silent, the register and the parts apply.

**Goals**

- Every screen answers one question first, and shows how it got there only on request.
- Native iOS navigation, sheets sized to their content, and a small shared system of motion, haptics and sound.
- Fewer words and fewer repeated elements; the brand assets (member shapes, sun yellow, large numerals, the message-style quick entry) stay.
- Fix all 21 defects (section 7) and close every finding in the register.
- Bring the finished design to Web in one phase after iOS.

**Non-goals**

- Production deployment. The Server Step, Phase 7 and Phase 6 are on hold; everything runs locally.
- Multi-currency, offline writes, nested groups (still on the waiting list).
- Netting debts across groups (section 4.1).
- Android.

**Anti-goals**

- Computing official balances, transfers or VietQR payloads on the client.
- Breaking `/api/v1` changes. Web v2 must keep working against the API until Phase 5.9 replaces it.
- Decorative motion that slows down money tasks. There is exactly one large celebration: when the whole group is settled.

## 2. Phase order

Phases run one after another as phase runs (`AGENTS.md` §12), each on its own branch, each ending with the owner's check on a physical iPhone.

| Phase | Branch | Scope | Size | Depends on |
|---|---|---|---|---|
| **5.6 — iOS foundations** | `phase-5-6` | Native navigation; sheet rules; motion, haptic and sound tokens; typography and Dynamic Type; copy rules; shared loading, empty and error states; fake data for unverified screens; defects in shared components | M | `main` |
| **5.7 — iOS core screens** | `phase-5-7` | 3-tab app shell and home (cross-group "whom to pay"); one group screen with a "who pays whom" sheet and a group info page; expense list; Settle in three layers; history merge; expense form as a large sheet with duplication; instant "Đã nhận" with undo; debt simplification on by default | L | 5.6 merged |
| **5.8 — iOS money and secondary screens** | `phase-5-8` | Account-level payment profile and QR import; VietQR on pay and share cards; clone, receipt, recurring, close cycle, fund, settings, categories, account screens; iPhone SE and VoiceOver passes | L | 5.7 merged |
| **5.9 — Web v3** | `phase-5-9` | The v3 structure, copy and behaviour on Web (mobile and desktop), using the API added in 5.7 and 5.8 | L | 5.8 merged |

After 5.9 the existing sequence continues unchanged and stays on hold until the owner decides: **Server Step → Phase 7 (public release, iOS + Web) → Phase 6 (Android)**. Android is then built once against v3 instead of v2.

Why foundations first: the motion and sheet rules are applied to every screen in 5.7 and 5.8. Building them first means no screen is animated twice.

## 3. Decisions already made by the owner

| # | Decision | Applies in |
|---|---|---|
| D1 | All 21 defects in section 7 are fixed inside v3, not as separate fixes | 5.6–5.8 |
| D2 | Navigation returns to native iOS: system navigation bar, back button and swipe-back on every pushed screen. Web keeps its own header | 5.6 |
| D3 | Add and edit expense open as a large sheet. Swipe-down dismisses while empty; once anything is entered, dismissal is blocked and Cancel asks "Bỏ khoản chi này?" | 5.7 |
| D4 | "Đã nhận" records immediately with a 5-second undo. Nothing is sent to the server until the 5 seconds pass or the user leaves the screen, so no notification goes out for an undone action. Uses the existing idempotency key | 5.7 |
| D5 | The settlement record ("Sổ thanh toán") merges into history ("Lịch sử") with a Payments filter | 5.7 |
| D6 | Owner and members see the same screens. Every money screen has three layers, each one tap apart: answer (how much, to whom) → reason (a worked sum in words) → evidence (the expense detail) | 5.7 |
| D7 | The bold number on each expense row is the user's own share ("phần bạn"); the bill total is small underneath | 5.7 |
| D8 | Debt simplification ("Gộp nợ") is on by default for new groups; existing groups keep their setting. The reason layer explains why simplification changes whom you pay | 5.7 |
| D9 | v3 is iOS and API first. Web is updated afterwards in Phase 5.9, following the finished iOS design. Production deployment is on hold | all |
| D10 | The app has 3 tabs: home (Overview and Groups merged), activity (notifications and the personal ledger merged), account. Final labels are set in the 5.7 copy. Supersedes the 4-tab shell of ADR-034 | 5.7 |
| D11 | Group Detail drops its 3 segments and becomes one group screen (balance card with a context action, expense list, quick entry), a "who pays whom" sheet, and a group info page for members, fund, statistics, recurring, guest link, Telegram and settings. Supersedes the 3-segment group detail of ADR-034 | 5.7 |
| D12 | Sound is on by default at low volume, silent with the ringer switch, and can be turned off per type in settings | 5.6 |
| D13 | Shared motion, haptic, sound and sheet foundations are built before the structural change, so no screen is animated twice | 5.6 |

## 4. Direction each phase spec must work out

These are agreed directions, not final designs. Each phase spec turns them into screens, copy and contract changes, and lists anything it changes against this section.

### 4.1 Cross-group home: "whom do I pay" (5.7)

Today the default tab "Tổng quan tài chính" (`OverviewView`, `GET /api/v1/me/overview`) shows a net figure, totals, and a balance per group. The net figure is not actionable (owed 500k in one group and owing 300k in another shows +200k, while the real task is paying 300k), the screen never says whom to pay, and the Groups tab repeats the same balances.

Direction:

- Merge Overview and Groups into one home screen; the tab bar drops from 4 to 3 (D10). The 5.7 spec records this in an ADR that supersedes ADR-034's 4-tab shell.
- Top section **"Bạn cần trả"**: one row per person per group ("Lan · 150.000 · Đà Lạt"), showing a recent reminder inline ("nhắc 2 ngày trước"). Tapping opens the pay sheet with VietQR.
- Section **"Bạn được nhận"**: same shape, with a remind action on the row.
- Then the group list, groups that need action first, role as a small label, archived groups collapsed at the end.
- **No netting across groups.** Each group's ledger settles separately. Rows for the same person may be visually grouped under the name, but amounts are never subtracted across groups.
- API: add an optional field to the overview response with the current user's suggested transfers per group, computed in `packages/core` with each group's simplification setting. Additive only.

### 4.2 Group screen and expense list (5.7)

- Group Detail becomes one group screen, a "who pays whom" sheet and a group info page (D11). History and close cycle are links at the end of the sheet. The group info page opens from the group name, like the group info page in Messages. Existing deep routes keep working and land on the matching place in the new structure.
- Expense rows follow D7. Search moves to pull-down.
- Features appear when used: surcharges, close cycle, fund and recurring stay out of the main path until the group uses them, but remain reachable.
- First use teaches by doing, with no tutorial slides: the empty group's composer demonstrates a sample sentence, each screen shows at most one hint once, and the first expense gets a small celebration. Target: a new user adds a first expense within one minute.

### 4.3 Expense form and duplication (5.7)

- Large sheet (D3). The amount field is focused with the number pad open. The core is amount → what → one summary line "Bạn trả · chia đều 4 người ›". Date, repeat, photo, surcharge and category become "add detail" chips that expand only when used.
- **Duplicate expense** (new). Two entry points: "Nhân bản" in expense detail and as a swipe action on the row; "Thêm khoản tương tự" offered right after saving. The duplicate keeps payer, participants, split method and category; clears the amount and focuses it; sets the date to today. It never copies receipt images, receipt items or settlement transactions. No API change: the server receives a new expense.

### 4.4 Settle flow (5.7)

- Three layers (D6). The answer shows one number, one name, one button. The reason is a half-height sheet with a worked sum. The evidence is the expense detail, which opens with the user's share.
- "Đã nhận" follows D4. Partial amounts, recording a payment between two other people, and offline use keep a sheet, as described in part 3.
- The pay sheet must match the viewer's role (defect B02).

### 4.5 Account-level payment profile and VietQR (5.8)

Today payment details live in `member_payment_methods`, one set per member per group (kinds `bank`, `momo`, `zalopay`), edited from the member list via `/api/v1/groups/{groupId}/members/{memberId}/payment-methods`. A user in 9 groups enters them 9 times, and an owner can enter another person's account number.

Direction:

- A payment profile on the user account ("Thông tin nhận tiền" in the account tab). All groups the user belongs to use it.
- An optional, skippable step at the end of sign-up, and a one-time prompt the first time someone owes the user money.
- Member-level details stay for members without an app account, entered by the owner as today.
- **QR import:** the user picks a photo of their bank QR; the app decodes the VietQR (EMVCo) payload on device and stores bank BIN, account number and account name. The image is never uploaded or stored. A static QR has no amount, so the app keeps generating VietQR with the exact amount and transfer note for each transfer. Codes that are not VietQR fall back to manual entry; MoMo and ZaloPay keep phone-number entry.
- Share cards: one QR cannot serve a whole group because each person owes a different amount, so QR appears on per-person cards and on the guest page per person.
- The 5.8 spec must decide: who may see a user's account number (proposed: members of groups the user is in), how existing member-level rows of linked members migrate, and the precedence when both exist. The schema change is additive; Web v2 keeps using the member-level endpoints until 5.9.

### 4.6 Motion, haptics and sound (5.6 tokens, applied in 5.7–5.8)

From parts 1 and 2:

- Three shared spring tokens in `DesignSystem/Tokens`: quick (select, switch), bounce (success), smooth (sheets). Button response 100–150 ms, state change 200–300 ms, celebration at most about 1 s.
- Animate position, scale and opacity only; never animate the layout of long lists. Only the main number on a screen counts up; row numbers change without animation.
- Haptics move to `.sensoryFeedback` tied to state changes: selection on choose, success when money changes hands, warning on errors, nothing on tab switches.
- Sound: at most 4 sounds, each under 400 ms, low volume, `.ambient` audio session (silent with the ringer switch, never interrupts music), only for the user's own actions, never for realtime changes by others. A "Âm thanh và rung" setting can turn each off. Sound is on by default (D12).
- With Reduce Motion on: no bursts or scaling; colour changes and haptics stay.
- Every new animation is measured with the SwiftUI Instrument on a physical device using `--scenario-large`.

### 4.7 Copy (5.6 rules, applied in 5.7–5.8)

- Labels at most 3 words; hints at most one line; explanations over 60 characters move behind a "Vì sao?" control or a help page.
- Friend's voice over accounting terms. The replacement table in part 1 is the starting point ("Chênh lệch ròng" → a sentence, "Xem giải trình khoản nợ" → "Vì sao?", "Ghi nhận" → "Đã nhận tiền", and so on).
- Each phase updates the localized strings it touches and removes strings that are no longer used.

### 4.8 Sheets and landing places (5.6 rules)

- Sheets size to their content (medium or custom detents); full height only for content that needs it. Full screen only for the receipt camera.
- One shared person picker for every form, titled with what it picks for (payer, participants, receipt items), instead of picture cards in one form and text chips in another.
- Every flow states where the user lands when it ends, with visible confirmation. Examples to fix: clone opens the new group in place of the source group, not on top of it; closing a cycle confirms and stays; "Danh mục của nhóm" opens the categories section.

## 5. Cross-cutting rules for all v3 phases

- **Findings coverage.** Each phase spec has a "Findings coverage" section listing every finding and defect that `findings.md` assigns to the phase, with how the spec handles it. The run's `progress.md` names the IDs each task closes. At review the advisor updates the status in `findings.md`. A phase is not finished while one of its findings is still open. The full procedure is in the research folder's `README.md`.
- **Web parity is deferred, not dropped.** Phases 5.6–5.8 change iOS and the API only. Every API change is additive so Web v2 keeps working. Phase 5.9 brings Web to v3.
- **Small screens.** Every redesigned screen is checked on iPhone SE (3rd generation) as well as a 6.3-inch iPhone: the answer must be visible without scrolling.
- **Accessibility.** Every redesigned screen is checked with Dynamic Type at the largest standard size, with VoiceOver, and with Reduce Motion.
- **Dark mode** is checked for every redesigned screen and share card.
- **Usability check (no automated tests).** At the end of 5.7, 3–5 people who have not used the app do three tasks: add "lẩu 300k chia đều", find how much they are owed, mark Thu as paid. Taps and hesitations are recorded in the run files.
- **ADRs.** New decisions start at ADR-042. Reversing parts of ADR-034 requires a superseding ADR in the phase that does it.
- **Standing documents.** Each phase updates `docs/06-ux-ui/user-flows.md`, `docs/03-srs.md`, `docs/05-api-spec.md` and `docs/05-database-design.md` for what it changes.

## 6. Screens not yet verified

These could not be opened with the current scripted data and must be captured once Phase 5.6 adds the fake data, then reviewed in the phase that redesigns them.

| Screen or check | Reviewed in |
|---|---|
| Payment details and VietQR with an account | 5.8 |
| Confirming a pending settlement request | 5.7 |
| Fund with money | 5.8 |
| Approval of a large expense | 5.7 |
| Telegram linking | 5.8 |
| Guest page with content | 5.8 |
| Home screen widget, share extension, push permission sheet, upgrade-required screen | 5.8 |
| VoiceOver and Reduce Motion run on device | every phase |
| Web, all screens | 5.9 |

## 7. Defects to fix in v3

The 21 defects (B01–B21) found during the review are listed, with their owning phase and status, in the "Defects" section of `docs/superpowers/research/2026-11-28-ui-ux-v3-review/findings.md`. None was fixed separately (D1). By phase: 5.6 owns B01, B07, B09, B10, B18, B19, B20; 5.7 owns B02, B05, B06, B08, B11, B12, B15, B21; 5.8 owns B03, B04, B13, B14, B16, B17.

Data note, not a product defect: `PreviewSupport/Fakes/FakeWorld+Stats.swift` hard-codes a total of 1,399,999 while its categories add up to 1,599,999. Phase 5.6 corrects it with the other fake data (finding F4-32).

## 8. Open questions for the phase specs

| Question | Proposed answer | Decided in |
|---|---|---|
| Can an editor close a cycle? The chip is shown to editors today | Check the server rule; hide the chip if not allowed | 5.7 |
| Who may see a user's account number? | Members of groups the user is in | 5.8 |
| Migration of member-level payment details for linked members | Copy into the profile when the profile is empty, keep the row otherwise | 5.8 |
| Web QR import (no native decoder in every browser) | Manual entry on Web if no decoder is available | 5.9 |
