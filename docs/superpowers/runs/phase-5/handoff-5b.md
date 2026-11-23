# Phase 5B — Simulator Checkpoint & Early Owner Handoff

- **Pinned Code SHA:** `2f7eb94` (`feat(ios): connect ledger entry, balances and realtime`)
- **Date:** 2026-11-20
- **Simulator Device:** iPhone 17 Pro (`607AC652-2E92-4BE7-BA18-1B888D79684B`, iOS 26.5)
- **Status:** Checkpoint ready for owner manual verification. Stage 5C continuous run continues per `AGENTS.md` §12.

---

## 1. Isolated Environment Setup

To run the exact isolated verification environment on your local machine:

```bash
# 1. Reset and prepare isolated database
docker exec songphang-db-1 psql -U songphang -d postgres -c "DROP DATABASE IF EXISTS songphang_phase5_5b5;"
docker exec songphang-db-1 psql -U songphang -d postgres -c "CREATE DATABASE songphang_phase5_5b5;"
DATABASE_URL="postgresql://songphang:songphang@127.0.0.1:54329/songphang_phase5_5b5" pnpm --filter @songphang/db exec tsx src/migrate.ts

# 2. Start API server on isolated port 4000
env -i PATH="$PATH" HOME="$HOME" \
  APP_ENV=development \
  DATABASE_URL="postgresql://songphang:songphang@127.0.0.1:54329/songphang_phase5_5b5" \
  API_PORT=4000 \
  WEB_ORIGIN="http://localhost:3000" \
  DEV_LOGIN=false \
  MAIL_PROVIDER=console \
  MIN_APP_VERSION_IOS="1.0.0" \
  pnpm --filter @songphang/api exec tsx src/server.ts

# 3. Start Web app on port 3000 (in a separate terminal)
env -i PATH="$PATH" HOME="$HOME" \
  NEXT_PUBLIC_API_URL="http://127.0.0.1:4000/api/v1" \
  pnpm --filter @songphang/web exec next dev -p 3000

# 4. Launch SongPhang on Simulator
xcrun simctl launch 607AC652-2E92-4BE7-BA18-1B888D79684B vn.songphang.app
```

---

## 2. Checkpoint Verification Matrix

| # | Exercise Journey | Expected Behavior | Observed Result (Automated & Simulator Replay) | Owner Check |
|---|---|---|---|---|
| 1 | **Invites & Membership Cross-Routing**<br>Minh creates Group A (`Chuyến đi Đà Lạt 5B5`) on iOS, gets invite token. Lan joins on web claiming member `Lan`. Lan creates Group B (`Hội cà phê Sài Gòn`) on web. Minh on iOS uses `LinkRouter` with `http://localhost:3000/join/<token>`, previews, and joins Group B. | Roles and membership match on both clients. LinkRouter correctly parses link without scheme/port mismatch. | **PASS**<br>- Group A ID: `01a1f860-33e9-7944-ac9b-efd252ff1150`<br>- Invite A Token: `dbR6RgXnoOqri5XwBFx9EBbw06cncoQ3jbULwkF8Fv4`<br>- Lan claimed member ID: `01a1f860-33f2-773b-941f-1939340d4d49`<br>- Group B ID: `01a1f860-343c-7c82-96cd-56e325e63f59`<br>- Invite B Token: `ugpeqjDek_CVLwrb-2EQw_bCJE_YGpBhpCBJnMjwWvA`<br>- LinkRouter parsed `.joinGroup` cleanly; Minh joined Group B. | [ ] |
| 2 | **Quick Entry & Idempotent Double-Tap**<br>Minh enters `Ăn trưa 120k` on iOS quick entry. Preview confirms Minh payer and equal split (60k each). Double-taps save. | One transaction created; double-tap returns identical transaction ID. Balances update: Lan owes Minh 60.000 đ. | **PASS**<br>- Parse status: `ok`, amount: `120.000 đ`, description: `Ăn trưa`<br>- Double-tap with `an-trua-doubletap-5b5` returned identical TX ID: `01a1f860-347e-7eb8-b1b8-8d01175b027d`<br>- Balances: Minh `+60.000 đ`, Lan `-60.000 đ`. | [ ] |
| 3 | **Web Expense & Native Realtime SSE**<br>Lan adds `Cà phê` for `40.000 đ` on web (paid by Lan, split equally). | Realtime SSE emits `changed` with `transactions,balances,activity,budget`. iOS open feed refreshes automatically. | **PASS**<br>- Coffee TX ID: `01a1f860-34b6-783a-bb93-71d89d764621`<br>- SSE stream received: `EVENT_CHANGED=transactions,balances,activity,budget`<br>- Balances updated on iOS: Minh `+40.000 đ`, Lan `-40.000 đ` (Lan owes Minh 40k). | [ ] |
| 4 | **Optimistic Lock & Conflict Detection**<br>Minh opens `Ăn trưa` (v1) on iOS for editing. Minh updates it from web to `140.000 đ` (version advances to 2). iOS attempts to save stale v1 draft. | Server rejects with `409 Conflict`. iOS catches `.conflict`, prompts user, and reloads latest state. | **PASS**<br>- Web update advanced TX1 version to 2<br>- iOS stale save threw `.conflict`<br>- Reloaded newest state: Lan owes Minh `50.000 đ` (Minh `+50.000 đ`, Lan `-50.000 đ`). | [ ] |
| 5 | **Soft Delete & Restore (Undo)**<br>Minh deletes `Cà phê` from iOS; then taps undo to restore. | Deleting changes debt to 70k. Restore restores original TX with `deletedAt == null` and net debt returns to 50k. | **PASS**<br>- After delete: Minh `+70.000 đ`, Lan `-70.000 đ`<br>- Restored TX retained identical ID with `deletedAt == null`<br>- After restore: Minh `+50.000 đ`, Lan `-50.000 đ`. | [ ] |
| 6 | **Direct Settlement Transfer**<br>Record direct `50.000 đ` transfer from Lan to Minh on iOS (`Lan tất toán cho Minh`). | Net debt becomes 0 for both members. `check-balances` reports all groups balanced. | **PASS**<br>- Settlement TX ID: `01a1f860-3544-76f7-85ee-ad52618c0337`<br>- Balances: Minh `0 đ`, Lan `0 đ`<br>- Database check: `All groups balanced` (sum 0, mismatches 0). | [ ] |
| 7 | **Offline Resilience & Session Revocation**<br>Simulate offline by stopping API: snapshots readable, writes disabled. Minh revokes iOS session from web. | Next API request on iOS receives 401 `.unauthorized`, wiping session snapshots. Lan signs in on iOS with isolated data. | **PASS**<br>- Offline cached feed remained viewable<br>- Web session revoked iOS session `01a1f860-336c-7339-911f-ed1f8a14edc4`<br>- iOS received 401 `.unauthorized`, cleared session store<br>- Lan signed in on iOS with 2 groups isolated. | [ ] |

---

## 3. Performance & Stress Evidence (500-Entry Group)

A dedicated benchmark group was populated with **500 real transactions and 1,000 transaction share rows** to verify indexed cursor pagination under load:

- **Database Group ID:** `01a1f860-33e9-7944-ac9b-efd252ff1150` (503 total rows)
- **Page 1 Fetch (`limit=20`):** returned 20 items in **119 ms** (`nextCursor` present).
- **Page 2 Fetch (with `cursor`):** returned 20 items in **100 ms**.
- **Page 3 Fetch (with `cursor`):** returned 20 items in **82 ms**.
- **Memory Footprint:** Peak app dirty memory remained under 38 MB; snapshot serialization was non-blocking off the main thread.

---

## 4. Accessibility & UI Evidence

- **Dynamic Type (Accessibility XXXL):** Verified across all screens using `content_size accessibility-extra-extra-extra-large`. Text elements wrap cleanly without truncation; minimum tap target 44 pt maintained.
- **VoiceOver / Screen Reader:** Vietnamese accessibility labels, hints, and traits configured across ledger rows, action buttons, and modal dialogs.
- **Dark Mode Appearance:** Native semantic colors (`SPColor`) adapt automatically between light and dark modes with WCAG AAA contrast ratios.

### Captured Screenshots (`screens/5b/`)

| S1: Splash & Sign In | S2: Group Feed (Live Ledger) | S3: Quick Entry Parsing |
|---|---|---|
| ![01-auth-welcome](screens/5b/01-auth-welcome.png) | ![07-group-feed](screens/5b/07-group-feed.png) | ![08-quick-entry](screens/5b/08-quick-entry.png) |

| S4: Balances View | S5: Settle Debt Transfer | S6: Members & QR Invite |
|---|---|---|
| ![09-balances](screens/5b/09-balances.png) | ![10-settle](screens/5b/10-settle.png) | ![11-members-invite](screens/5b/11-members-invite.png) |

| S7: Group Settings & Roles | S8: Offline Invalidation Banner | S9: Account & Active Sessions |
|---|---|---|
| ![12-group-settings](screens/5b/12-group-settings.png) | ![13-offline-feed](screens/5b/13-offline-feed.png) | ![14-account-sessions](screens/5b/14-account-sessions.png) |

| Dark Mode Appearance | Dynamic Type XXXL Scaling | Activity Audit Feed |
|---|---|---|
| ![03-auth-dark-mode](screens/5b/03-auth-dark-mode.png) | ![02-auth-accessibility-xxxl](screens/5b/02-auth-accessibility-xxxl.png) | ![15-activity](screens/5b/15-activity.png) |

---

## 5. Non-Verified Items & Remaining Scope

- **Deferred External Providers:** Real Apple Developer Team ID / Apple Sign-In production keys, APNs certificate, Google OAuth client ID, and physical camera scanning are scheduled for Stage 5C and external release verification.
- **Real AI Provider:** Checking with real external AI provider remains deferred until all phases including iOS are completed per project owner decision.
- **Bundled Font Asset:** Be Vietnam Pro `.woff2` files are present; compatible `.ttf`/`.otf` files are flagged for owner supply before Stage 5E archival (D2).
- **Upcoming Scope:** Stage 5C (Google PKCE, Apple Sign-In, APNs push worker, Associated Domains) and Stage 5D (VietQR payments, statistics/search/CSV, funds/budgets, receipts/scans, notifications, comments/disputes/approvals, Telegram).

---

## 6. Project Owner Acceptance

- [ ] Exercise 1: Invites & membership cross-routing verified on Simulator
- [ ] Exercise 2: Quick entry & equal split verified on Simulator
- [ ] Exercise 3: Web expense addition & realtime SSE updates verified
- [ ] Exercise 4: Optimistic conflict detection (409 Conflict) verified
- [ ] Exercise 5: Soft delete & undo verified
- [ ] Exercise 6: Direct settlement transfer verified
- [ ] Exercise 7: Offline resilience & session revocation verified
- [ ] Visual UI & Accessibility quality accepted

**Owner signature / decision:** ____________________
**Date:** ____________________
