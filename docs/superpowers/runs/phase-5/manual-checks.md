# Phase 5 — Owner Manual Checks

## Isolated Local Startup Recipe (Phase 5 Baseline)

This recipe uses a **fresh disposable database** (never touching the primary `songphang` database or running `docker compose down -v`), an isolated upload directory, clean-environment commands bypassing `.env`-loading scripts, console mail, `AI_PROVIDER=fake`, and `TELEGRAM_PROVIDER=console`. Default ports are API `4000` and Web `3000` (matching `apps/ios/Config/Debug.xcconfig`); if ports change, update `API_PORT`, `WEB_ORIGIN`, `API_ORIGIN`, and `API_BASE_URL` consistently.

1. **Create, migrate, and seed a disposable database:**
   ```sh
   docker compose up -d --wait db
   docker compose exec -T db psql -U songphang -d postgres -c "CREATE DATABASE songphang_phase5_local;"
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase5_local" \
     pnpm --filter @songphang/db exec tsx src/migrate.ts
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase5_local" \
     pnpm --filter @songphang/db exec tsx src/seed.ts
   ```
2. **Start API, Worker, and Web in separate terminals from a clean environment:**
   - **Terminal 1 — API (`http://127.0.0.1:4000`):**
     ```sh
     env -i PATH="$PATH" HOME="$HOME" \
       APP_ENV=development \
       DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase5_local" \
       API_PORT=4000 \
       WEB_ORIGIN="http://127.0.0.1:3000" \
       DEV_LOGIN=true \
       STORAGE_DIR="/tmp/songphang-phase5-uploads" \
       AI_PROVIDER=fake \
       TELEGRAM_PROVIDER=console \
       TELEGRAM_WEBHOOK_SECRET="local_phase5_secret_32_chars_minimum" \
       TELEGRAM_BOT_USERNAME="SongPhangLocalBot" \
       pnpm --filter @songphang/api exec tsx src/server.ts
     ```
   - **Terminal 2 — Worker:**
     ```sh
     env -i PATH="$PATH" HOME="$HOME" \
       APP_ENV=development \
       DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase5_local" \
       WEB_ORIGIN="http://127.0.0.1:3000" \
       STORAGE_DIR="/tmp/songphang-phase5-uploads" \
       AI_PROVIDER=fake \
       pnpm --filter @songphang/worker exec tsx src/main.ts
     ```
   - **Terminal 3 — Web (`http://127.0.0.1:3000`):**
     ```sh
     env -i PATH="$PATH" HOME="$HOME" \
       API_ORIGIN="http://127.0.0.1:4000" \
       pnpm --filter @songphang/web exec next dev --hostname 127.0.0.1 --port 3000
     ```
3. **Establish two verified password accounts for 5B (the dev seed creates no password identities):**
   - Register two accounts (`POST /api/v1/auth/register` or `/register` on web), copy each verification token printed by the console mailer in Terminal 1, and verify each via `POST /api/v1/auth/verify-email` (or by opening the printed `/verify-email?token=...` link).
4. **Verify balances and clean up when finished:**
   ```sh
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase5_local" \
     pnpm --filter @songphang/db exec tsx src/check-balances.ts
   docker compose exec -T db psql -U songphang -d postgres -c "DROP DATABASE IF EXISTS songphang_phase5_local;"
   rm -rf /tmp/songphang-phase5-uploads
   ```

## Early iOS/Web Simulator Checkpoint

Pending implementation of 5B. Antigravity records the tested code revision, isolated startup recipe, steps, exact expected and observed results, and screenshots in `handoff-5b.md`.

- Tested code revision:
- Owner result: Pending
- Owner notes:

## Final Local Parity

Pending 5E. Antigravity records the final code revision, results by journey in `parity-matrix.md`, and findings from replaying the early checkpoint.

- Tested code revision:
- Owner result: Pending
- Owner notes:

## Physical iPhone, Providers and TestFlight

Pending owner-led verification with the required configuration. Preserve the approved deferral for the real AI provider.

- **Payment details, VietQR & settlement requests (5D.1):**
  1. Open a group's `Thành viên và lời mời`, expand a member, tap `Thông tin nhận tiền`, pick a bank + enter account number/name + MoMo/ZaloPay, save → persists cleanly across reload; verify viewer can edit only their own member (`403` otherwise).
  2. Open `Số dư` as debtor and tap `Trả` → S14 shows VietQR ≥240pt, copy amount/bank/phone buttons toggle `Đã sao chép`, `Lưu mã QR` requests add-only Photos access and shows `Đã lưu mã QR.`, and scanning with a real Vietnamese banking app fills bank/account/amount/purpose accurately.
  3. Tap `Tôi đã chuyển` → ledger debt remains unchanged while pending; receiver taps `Đã nhận` → creates 1 transfer settlement and updates net balance to `0 đ`; test `Chưa nhận`, `Huỷ báo`, duplicate/409 `Yêu cầu này đã được xử lý.`, and `Ghi nhận luôn`.

- **Search, categories, statistics & CSV (5D.2):**
  1. In `Cài đặt nhóm`, create/rename/recolor/archive a custom category; verify duplicate name shows `Nhóm đã có danh mục này.` and a Viewer cannot mutate categories. On `Khoản chi mới`, pick built-in or custom category (`+ Thêm danh mục` modal works inline).
  2. In the group feed, type accent-stripped text into `Tìm khoản chi` (300ms debounce) and open `Lọc` to filter by member, category, `Chưa phân loại`, type, or date range; verify filter chips remove individually and `Xoá lọc` restores full feed, while empty matches show `Không có khoản nào khớp`.
  3. Tap `Tổng chuyến đi` → S16 `Tiền đi đâu` shows server total, period chips (`Tất cả`, `Tháng này`, `Tháng trước`, `Tuỳ chọn`), and category/member/time bars; tap any bar to drill down into the matching scoped feed.
  4. Tap `Xuất CSV` → system Share sheet exports a `.csv` file that opens in Excel/Numbers with proper Vietnamese accents (UTF-8 BOM) and leaves no lingering temp files.

- **Group funds & budget tracking (5D.3):**
  1. In `Thành viên và lời mời` or `Số dư`, tap `Lập quỹ chung`, enter name + choose holder (or `Chưa chọn`), create → S17 shows fund cash `0 đ` and holder line; test changing holder to another person and back to `Chưa chọn`.
  2. Contribute to the fund (`Góp vào quỹ`) and record an expense paid by the fund (`Khoản chi mới` selecting the fund as payer, ensuring fund is absent from split sharer checkboxes); overdraw the fund beyond its cash → yellow `FUND_OVERDRAWN` warning appears and balance card reads `Quỹ đang âm ...`.
  3. Attempt closing/deleting the fund while non-empty or with transactions → refusal copy is shown (`Quỹ còn ...` / `Không thể xoá ...`); refund/contribute back to `0 đ`, then close (`Đóng quỹ`) and reopen (`Mở lại quỹ`); delete an unused fund successfully.
  4. As Owner in `Cài đặt nhóm`, set a `Tháng này` or `Toàn chuyến đi` budget (`Lưu hạn mức`); confirm Editors/Viewers cannot edit budget; add expenses reaching ≥80% and >100% → amber `Gần chạm hạn mức` / coral `Đã vượt hạn mức` banners appear on the feed & stats, and `Khoản này làm nhóm vượt hạn mức.` appears in preview/save before removing the budget.

- **Receipt capture, review, item splits & assisted entry (5D.4):**
  1. In the group feed entry bar, tap the camera icon (or on `Khoản chi mới`, tap `Chụp / chọn hoá đơn`) → system camera or photo picker opens with permission prompt; select or take a photo → detached re-encoding strips EXIF/GPS, resizes to <=2000px JPEG, and uploads to `/attachments`.
  2. The review screen (S18) opens and polls `/receipt-scans` with a loading indicator; upon completion, merchant name fills the title, date fills occurrence date, and items and extras appear in editable rows.
  3. Tap `Chia đều cho tất cả` (or assign members individually to each item) → unassigned warnings clear, total computes, and member breakdown updates in real-time via `/preview`.
  4. For a receipt with mismatched printed total vs item sum, the yellow mismatch banner appears (`Tổng hoá đơn ghi ... nhưng cộng món là ...`); tap `Dùng tổng ghi trên hoá đơn` → automatically adds an adjustment extra (`Điều chỉnh chênh lệch`) to balance the total.
  5. In Quick Entry (`Nhập nhanh`), type multi-item text ("cà phê 180k và bánh 50k") and tap send (`Gửi`) → AI parser splits the sentence into two queued drafts (`1/2`), with category chips, payer attribution, and a `Lưu & tiếp tục` action to save drafts sequentially to the ledger.

- **Notifications, reminders, mute & settings (5D.5):**
  1. Open `Tài khoản` → verify `Thông báo email` card shows two switches for `Nhận ngay khi có thay đổi` (`emailImmediate`) and `Bản tin định kỳ` (`emailDigest`); toggle switches → persists across app restart and profile reloads.
  2. In `Thành viên và lời mời`, verify `Tắt thông báo nhóm này` switch (`notifications.muteGroup`); turn on → group activity/reminder notifications are suppressed for the current user; check `Cài đặt nhóm` as owner → `Tự động nhắc nợ` segmented control allows choosing `Tắt`, `Mỗi 3 ngày`, `Mỗi tuần`, `Mỗi 2 tuần`, persisting `reminderIntervalDays` cleanly.
  3. In `Số dư`, verify `Nhắc` button appears on eligible debtor rows where debtor is claimed and current user is creditor or owner; tap `Nhắc` → sends reminder notification and toast shows `Đã gửi nhắc nợ cho ...`.
  4. Tap `Nhắc` again immediately on the same debtor → returns rate limit toast (`Bạn vừa nhắc người này gần đây. Có thể nhắc lại sau ...`). When ≥2 debtors are remindable, tap `Nhắc cả nhóm` → sends to all debtors not on cooldown and reports count.
  5. Tap the bell icon in group feed or group list header → S19 `Thông báo` opens showing notification rows with bold actor, kind-specific formatted text, relative timestamp, and unread dot; tap `Đánh dấu đã đọc tất cả` → clears badge and updates list.

- **Pending asset decision before final release:** Compatible Be Vietnam Pro `.ttf`/`.otf` font files are absent from the repository (only web `.woff2` files exist under `apps/web/public/fonts/be-vietnam-pro/`). Provide licensed `.ttf`/`.otf` files or approve the iOS system font substitution before final acceptance.
