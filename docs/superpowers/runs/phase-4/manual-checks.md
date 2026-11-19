# Phase 4 run — owner manual checks

> **Status:** Owner manual acceptance is **PENDING**. Do not precheck any box on the owner's behalf.
> **Gate-tested code revision:** `8602eda95abdd5e9a4b831a4c93a6abccfe8d373` (Advisor **PASS**: [review-r11-ab-final.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/review-r11-ab-final.md)).

---

## Pre-Merge Owner Acceptance

### 1. Safe Isolated Local Startup Recipe

This recipe uses a **fresh disposable database** (`songphang_phase4_owner_accept`), isolated ports (`4090` / `3090`), isolated upload directory, `AI_PROVIDER=fake`, console mail, and `TELEGRAM_PROVIDER=console`. It never edits `.env`, never touches your primary `songphang` database or prior agent/reviewer databases, and makes zero external provider calls.

1. **Ensure PostgreSQL is running and create the disposable owner-acceptance database:**
   ```sh
   docker compose up -d --wait db
   docker compose exec -T db psql -U songphang -d postgres -c "CREATE DATABASE songphang_phase4_owner_accept;"
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" pnpm db:migrate
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" pnpm db:seed
   ```
2. **Start the three required processes in three separate terminals from the repository root:**
   - **Terminal 1 — API (`http://127.0.0.1:4090`, console Telegram + console auth mail):**
     ```sh
     APP_ENV=development \
     DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" \
     API_PORT=4090 \
     WEB_ORIGIN="http://127.0.0.1:3090" \
     DEV_LOGIN=true \
     STORAGE_DIR="/tmp/songphang-owner-accept-uploads" \
     AI_PROVIDER=fake \
     TELEGRAM_PROVIDER=console \
     TELEGRAM_WEBHOOK_SECRET="local_owner_accept_secret_32_chars_min" \
     TELEGRAM_BOT_USERNAME="SongPhangLocalBot" \
     pnpm --filter @songphang/api dev
     ```
   - **Terminal 2 — Worker (fake receipt OCR, console notification/digest mail, auto-reminders):**
     ```sh
     APP_ENV=development \
     DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" \
     WEB_ORIGIN="http://127.0.0.1:3090" \
     STORAGE_DIR="/tmp/songphang-owner-accept-uploads" \
     AI_PROVIDER=fake \
     pnpm --filter @songphang/worker dev
     ```
   - **Terminal 3 — Web (`http://127.0.0.1:3090`):**
     ```sh
     API_ORIGIN="http://127.0.0.1:4090" \
     pnpm --filter @songphang/web exec next dev --hostname 127.0.0.1 --port 3090
     ```
3. **Stop cleanly when finished:**
   - Press `Ctrl+C` in Terminals 1, 2, and 3.
   - Optionally remove only the disposable acceptance database and temp uploads (never run `docker compose down -v`, which wipes the primary `songphang` database):
     ```sh
     docker compose exec -T db psql -U songphang -d postgres -c "DROP DATABASE IF EXISTS songphang_phase4_owner_accept;"
     rm -rf /tmp/songphang-owner-accept-uploads
     ```

### 2. Browser Windows and Owner Fixture Setup

Open **three independent browser contexts** pointing at `http://127.0.0.1:3090`:

- **Window A (Normal profile):** sign in via `/dev/login` as **Minh** (`minh@dev.songphang.local`, verified — **owner**).
- **Window B (Separate browser profile or Incognito 1):** sign in via `/dev/login` as **Lan** (`lan@dev.songphang.local`, verified — **editor**) or switch to **Hùng** (`hung@dev.songphang.local`, verified — **viewer**) when a step calls for Hùng.
- **Window C (Private/Incognito 2, signed out):** keep unauthenticated.

Create this small disposable fixture in the UI (about 3 minutes) so every figure below is exact and pre-derived:

1. **Group 1 — `Đà Lạt Nghiệm Thu`** (created by **Minh** in Window A):
   - Add members: `Minh` (owner, linked), `Lan`, `Hùng`, `Thu`.
   - On `/g/{g1}/settings`: generate an invite link, join in Window B as **Lan** (claim `Lan`, keep role **editor**) and join as **Hùng** (claim `Hùng`, change role to **viewer** on `/g/{g1}/members`). Leave `Thu` **unlinked**.
   - On `/g/{g1}/settings`: set **Hạn mức** (`Cả chuyến`) = `2.500.000 đ`; enable **Duyệt khoản chi lớn** (`Từ số tiền`) = `1.000.000 đ`; leave **Tự nhắc nợ** = `Tắt`.
   - Create baseline expenses:
     - **E1 (counted, below threshold):** Minh creates `Ăn trưa` `600.000 đ`, paid by `Minh`, equal split 4 (`Minh`, `Lan`, `Hùng`, `Thu` = `150.000 đ` each).
     - **E2 (pending, above threshold):** Lan creates `Khách sạn` `1.200.000 đ`, paid by `Lan`, equal split 3 (`Minh`, `Lan`, `Hùng` = `400.000 đ` each) → `chờ duyệt`.
     - **E3 (rejected, at threshold):** Lan creates `Thuê xe` `1.000.000 đ`, paid by `Lan`, equal split 2 (`Minh`, `Lan`) → Minh rejects on S20 with note `Trùng khoản` → `không được duyệt`.
   - **Pre-derived baseline figures for `Đà Lạt Nghiệm Thu` (E1 counted; E2 pending & E3 rejected excluded):**
     - Person balances: `Minh +450.000 đ`, `Lan -150.000 đ`, `Hùng -150.000 đ`, `Thu -150.000 đ` (sum `0`).
     - Transfers: `Lan → Minh 150.000 đ`, `Hùng → Minh 150.000 đ`, `Thu → Minh 150.000 đ`.
     - Budget spent: `600.000 đ / 2.500.000 đ` (24%, no near/over banner); Stats total: `600.000 đ`; CSV export: `1` counted row (`Ăn trưa`, `600000`).
2. **Group 2 — `Quỹ & Nhắc Nợ`** (created by **Minh** in Window A):
   - Add members: `Minh` (owner), `Lan` (editor, joined), `Hùng` (viewer, joined).
   - On `/g/{g2}/settings`: turn **Gộp nợ** OFF (`minimizeDebts: false`); enable **Duyệt khoản chi lớn** = `1.000.000 đ`.
   - On `/g/{g2}/fund`: create `Quỹ chung` held by `Minh`, then **Góp vào quỹ** `1.200.000 đ` by `Minh` → `Quỹ còn 1.200.000 đ`.
   - Create 1 counted expense: Minh creates `Vé vào cổng` `200.000 đ`, paid by `Hùng`, equal split 2 (`Lan`, `Hùng` = `100.000 đ` each) → transfer `Lan → Hùng 100.000 đ` (`Hùng` is a linked **viewer receiver**).
3. **Optional 35-row pagination seed for S19** (run once against `songphang_phase4_owner_accept` after creating Group 1 so Minh has `>= 35` notifications for Step 3.4):
   ```sh
   DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" \
   pnpm --filter @songphang/db exec tsx -e '
     import { createDb, groups, notifications, users } from "@songphang/db";
     import { eq } from "drizzle-orm";
     import { uuidv7 } from "uuidv7";
     const { db, close } = createDb(process.env.DATABASE_URL ?? "");
     try {
       const [minh] = await db.select().from(users).where(eq(users.email, "minh@dev.songphang.local"));
       const [g1] = await db.select().from(groups).where(eq(groups.name, "Đà Lạt Nghiệm Thu"));
       if (!minh || !g1) throw new Error("Create Đà Lạt Nghiệm Thu first");
       const now = Date.now();
       await db.insert(notifications).values(Array.from({ length: 35 }, (_, i) => ({
         id: uuidv7(),
         userId: minh.id,
         groupId: g1.id,
         kind: "comment_added",
         payload: { kind: "comment_added", actorName: "Lan", groupName: g1.name, description: `Mục kiểm tra #${i + 1}`, transactionId: uuidv7() },
         createdAt: new Date(now - (35 - i) * 1000),
       })));
       console.log("Seeded 35 notifications for Minh");
     } finally { await close(); }
   '
   ```

---

### 3. Pre-Merge Acceptance Checklist

#### Flow 1 — S20: Comments and Disputes (`Đà Lạt Nghiệm Thu`)

- [ ] **1.1 Viewer controls & live comments (`S20` `/g/{g1}/tx/{E1}/view`):**
  - **Actors:** Window A (`Minh`, owner) and Window B (`Hùng`, viewer) both open E1 (`Ăn trưa`).
  - **Action:** Check header controls; in Window B type `Hôm đó mình không ăn` + `Enter`, then send `<script>alert(1)</script>`.
  - **Expected:** Window A shows `Sửa`; Window B hides `Sửa` while keeping `Khoản này chưa đúng` and the comment box active. Both comments appear live in Window A via SSE without reload, and `<script>alert(1)</script>` renders as literal text with no alert.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **1.2 Comment deletion rules (`S20` `/g/{g1}/tx/{E1}/view`):**
  - **Actors:** Window B (`Hùng`, viewer), then Window B switched to `Lan` (editor), then Window A (`Minh`, owner).
  - **Action:** Have `Hùng` post a second comment and delete his first comment (`Xoá bình luận`); switch Window B to `Lan` and inspect `Hùng`'s remaining comment; in Window A (`Minh`) delete `Hùng`'s remaining comment.
  - **Expected:** Author (`Hùng`) deletes his own comment live in both windows; non-author editor (`Lan`) has no delete button on `Hùng`'s comment; owner (`Minh`) can delete `Hùng`'s comment live.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **1.3 Dispute open, non-opener editor denial, and opener/owner resolution (`S20` `/g/{g1}/tx/{E1}/view`):**
  - **Actors:** Window B (`Hùng` → `Lan` → `Hùng`), Window A (`Minh`).
  - **Action:** `Hùng` clicks `Khoản này chưa đúng`, checks that empty/whitespace keeps `Gửi` disabled, then submits `Sai số người`. Switch Window B to `Lan` (editor) and view E1. Switch back to `Hùng` and click `Đã giải quyết`. Reopen a dispute as `Hùng`, then have `Minh` (Window A) click `Đã giải quyết`.
  - **Expected:** Coral dispute card (`Hùng cho rằng khoản này chưa đúng`) appears live in Window A and feed shows `đang hỏi lại`; non-opener editor `Lan` does **not** see `Đã giải quyết`; opener (`Hùng`) and owner (`Minh`) can each resolve with snackbar `Đã giải quyết.` and live clearing of `đang hỏi lại`.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **1.4 Comment on soft-deleted transaction without auto-restoring, then restore (`S20` `/g/{g1}/tx/{E1}/view`):**
  - **Actors:** Window A (`Minh`, owner) and Window B (`Hùng`, viewer).
  - **Action:** `Minh` deletes `Ăn trưa` (`Sửa` → `Xoá khoản này`) while keeping its `/view` URL open (or open it from `Lịch sử`). In Window B (`Hùng`) post a comment `Ghi chú khi đã xoá` on the deleted `/view` page. Then in Window A (`Minh`) restore `Ăn trưa`.
  - **Expected:** Deleted banner remains visible after `Hùng`'s comment (no auto-restore), comment appears live in Window A; after `Minh` restores `Ăn trưa`, the deleted banner clears and `Ghi chú khi đã xoá` is preserved.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 2 — Approval & Money (`Đà Lạt Nghiệm Thu` & `Quỹ & Nhắc Nợ`)

> **Note on exhaustive money variants:** All 65 leaf/standalone approval-sensitive money cases (+2 parent rollups covering debt modes, stats, budget, CSV, fund, fund refund, settlement approval, items, fake receipt, and 21 warning-parity cases) are verified in [03_4d1_money_r11ab.json](file:///Users/hoojinguyen/.gemini/antigravity/brain/fa161507-b8d0-4447-ba9a-fef03545bbe9/final-replay-8602eda95abdd5e9a4b831a4c93a6abccfe8d373/03_4d1_money_r11ab.json) and independently replayed in [review-r11-ab-final.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/review-r11-ab-final.md). The steps below confirm the key owner-facing flows without repeating all 65 machine exercises.

- [ ] **2.1 Threshold below / at / above & pending exclusion (`S4`, `S5`, `S10`, CSV):**
  - **Actors:** Window A (`Minh`, owner) and Window B (`Lan`, editor) in `Đà Lạt Nghiệm Thu` (threshold `1.000.000 đ`).
  - **Action:** Inspect `/g/{g1}/balances`, `/g/{g1}/stats`, `/g/{g1}` budget banner, and CSV export (`Xuất CSV` on stats/settings) while E2 (`Khách sạn 1.200.000 đ`) is `chờ duyệt` and E3 (`Thuê xe 1.000.000 đ`) is `không được duyệt`. Also have `Lan` add a below-threshold expense `Bánh mì` `900.000 đ`? (Optional: or note E1 `600.000 đ` is counted, E3 `1.000.000 đ` triggered approval at threshold, and E2 `1.200.000 đ` triggered approval above threshold.)
  - **Expected:** Official balances match exact fixture baseline (`Minh +450.000 đ`, `Lan -150.000 đ`, `Hùng -150.000 đ`, `Thu -150.000 đ`), Stats total = `600.000 đ`, Budget spent = `600.000 đ`, CSV contains only `Ăn trưa` (`600000`). Both E2 and E3 appear dimmed in S4 with `chờ duyệt` and `không được duyệt` tags; E3's S20 shows `Minh không duyệt khoản này.` + `Trùng khoản`.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **2.2 Approve counted → editor edit returns to pending → reject with note (`S20`, `S5`, `S10`):**
  - **Actors:** Window A (`Minh`, owner) and Window B (`Lan`, editor).
  - **Action:** (a) `Minh` opens E2 (`Khách sạn 1.200.000 đ`) on S20 and clicks `Duyệt`. Check live balances in both windows, Stats, Budget, and CSV. (b) `Lan` clicks `Sửa` on E2, changes amount to `1.500.000 đ`, and saves. (c) `Minh` opens E2 on S20, clicks `Không duyệt`, enters note `Chưa có hoá đơn`, and submits.
  - **Expected:**
    - After **(a) Approve:** `chờ duyệt` clears; balances update live to `Minh +50.000 đ`, `Lan +650.000 đ`, `Hùng -550.000 đ`, `Thu -150.000 đ`; Stats total = `1.800.000 đ`; Budget spent = `1.800.000 đ`; CSV includes `Khách sạn`.
    - After **(b) Editor edit to `1.500.000 đ`:** snackbar `Đã lưu. Khoản này chờ Minh duyệt.`; E2 returns to `chờ duyệt`; balances revert to `Minh +450.000 đ`, `Lan -150.000 đ`, `Hùng -150.000 đ`, `Thu -150.000 đ`; Stats/Budget revert to `600.000 đ`.
    - After **(c) Reject:** S20 shows `Minh không duyệt khoản này.` and `Chưa có hoá đơn`; feed shows `không được duyệt`; balances/Stats/Budget remain at `600.000 đ` baseline.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **2.3 Fake receipt / items-split save & fund-paid expense (`S4`, `S20`, `S5`, `Fund`):**
  - **Actors:** Window B (`Lan`, editor) and Window A (`Minh`, owner).
  - **Action:**
    1. In `Đà Lạt Nghiệm Thu`, `Lan` taps `Chụp hoá đơn`, uploads `apps/worker/fixtures/receipts/clean.jpg` (`AI_PROVIDER=fake` extracts `440.000 đ`), adds one item `600.000 đ` assigned to `Minh` so total = `1.040.000 đ` (`>= 1.000.000 đ`), assigns remaining items, and saves. Check balances before and after `Minh` approves (or rejects) it.
    2. In `Quỹ & Nhắc Nợ` (`Quỹ còn 1.200.000 đ`, threshold `1.000.000 đ`), `Lan` creates a fund-paid expense `Tiệc tối` `1.000.000 đ` paid by `Quỹ chung` (equal 3: `Minh`, `Lan`, `Hùng`). Check `/g/{g2}/fund` and `/g/{g2}/balances` while `pending`, then after `Minh` approves on S20.
  - **Expected:** Fake receipt scan finishes cleanly (`Đọc bằng AI. Hãy xem lại trước khi lưu.`), saves as `chờ duyệt` with items + photo preserved and excluded from totals until approved. For `Quỹ & Nhắc Nợ`, `Quỹ còn` remains `1.200.000 đ` while `Tiệc tối` is `chờ duyệt`, and drops to `200.000 đ` immediately after `Minh` approves.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 3 — S19 & Header Bell: Live Reminders, Unread Count, Pagination, Mark-All, Mute

- [ ] **3.1 Live manual reminder & locally triggered automatic reminder (`S4` Bell + `S19`):**
  - **Actors:** Window B (`Hùng`, viewer) stays open on `/g/{g1}` (do not refresh); Window A (`Minh`, owner) on `/g/{g1}/balances` and `/g/{g1}/settings`.
  - **Action:** (a) In Window A, click `Nhắc` on `Hùng` → observe Window B's header bell. (b) On `/g/{g1}/settings`, set `Tự nhắc nợ` to `Mỗi 3 ngày`. Backdate or trigger on `Quỹ & Nhắc Nợ` (where `Lan → Hùng 100.000 đ` has not been reminded yet; set `Tự nhắc nợ` = `Mỗi 3 ngày` on `Quỹ & Nhắc Nợ` too) and run the local automatic reminder job once:
    ```sh
    APP_ENV=development \
    DATABASE_URL="postgres://songphang:songphang@localhost:54329/songphang_phase4_owner_accept" \
    WEB_ORIGIN="http://127.0.0.1:3090" \
    STORAGE_DIR="/tmp/songphang-owner-accept-uploads" \
    pnpm --filter @songphang/worker exec tsx -e '
      import { createDb } from "@songphang/db";
      import { loadWorkerConfig } from "./src/config.js";
      import { createConsoleMailer } from "./src/mailer.js";
      import { runAutoReminders } from "./src/jobs/auto-reminders.js";
      const config = loadWorkerConfig(process.env);
      const { db, close } = createDb(config.databaseUrl);
      try {
        const count = await runAutoReminders({ db, config, mailer: createConsoleMailer(), now: () => new Date() });
        console.log("Auto reminders sent:", count);
      } finally { await close(); }
    '
    ```
  - **Expected:** Both manual and automatic reminders increment the debtor's open bell count live via SSE without reload, and Terminal 2 (or the job output) prints the console email with `List-Unsubscribe` / `List-Unsubscribe-Post` headers.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **3.2 Open notification → mark read → navigate, pagination (`>= 35` rows), mark all read (`S19` `/notifications`):**
  - **Actors:** Window A (`Minh`, owner, with `>= 35` notifications).
  - **Action:** Observe bell badge (`9+` when `> 9`), click bell to open `/notifications`, tap one unread notification, return to `/notifications`, scroll and tap `Tải thêm` to load page 2, then click `Đánh dấu đã đọc`.
  - **Expected:** Tapping one unread row marks only that row read, decrements unread count by 1, and navigates to its target screen; `Tải thêm` loads older rows with no duplicates/missing rows; `Đánh dấu đã đọc` clears all unread states and hides the bell badge.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **3.3 Per-group mute (`S7` `/g/{g1}/members`):**
  - **Actors:** Window B (`Hùng`, viewer) and Window A (`Minh`, owner).
  - **Action:** `Hùng` opens `/g/{g1}/members`, toggles `Tắt thông báo nhóm này` ON, then `Minh` posts a comment on E1. Check `Hùng`'s bell/`/notifications`, then toggle `Tắt thông báo nhóm này` back OFF.
  - **Expected:** While muted, `Hùng` receives zero new notifications for `Đà Lạt Nghiệm Thu`; toggling OFF restores notifications.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 4 — S5 & S11: Reminder Roles, Cooldown, Auto-Intervals, Approval Threshold Controls

- [ ] **4.1 Role-specific reminder visibility (`S5` `/g/{g1}/balances` & `/g/{g2}/balances`):**
  - **Actors:** Window A (`Minh` owner), Window B (`Lan` editor, then `Hùng` viewer).
  - **Action:** Inspect `Nhắc` buttons on `/g/{g1}/balances` (`Lan → Minh`, `Hùng → Minh`, `Thu → Minh`) as `Minh`, `Lan`, and `Hùng`; then inspect `/g/{g2}/balances` (`Lan → Hùng 100.000 đ`) as `Hùng` (viewer receiver).
  - **Expected:** Unlinked debtor `Thu` never shows `Nhắc`; `Minh` (owner) sees `Nhắc` on `Lan` and `Hùng` plus `Nhắc cả nhóm một lần`; `Lan` (editor) sees `Nhắc` on `Hùng → Minh` (not on her own debt); `Hùng` (non-receiver viewer on `g1`) sees **no** `Nhắc` buttons; `Hùng` (linked receiver viewer on `g2`) **does** see `Nhắc` on `Lan → Hùng`.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **4.2 Double-click cooldown, remind-all count, and unchanged money (`S5` `/g/{g1}/balances`):**
  - **Actors:** Window A (`Minh`, owner).
  - **Action:** Note exact balances (`Minh +450.000 đ`, etc.). Click `Nhắc` on `Hùng` twice quickly; then click `Nhắc cả nhóm một lần` twice.
  - **Expected:** Second click on `Hùng` shows cooldown snackbar `Bạn vừa nhắc Hùng rồi. Nhắc lại được sau {giờ} ngày {ngày}.`; first `Nhắc cả nhóm một lần` shows `Đã nhắc 1 người.` (only `Lan`, since `Hùng` is on cooldown and `Thu` is unlinked); second click shows `Đã nhắc 0 người.`. Official balances and transfer amounts remain completely unchanged.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **4.3 S11 auto-reminder intervals, threshold change/disable/invalid input, and owner-only refusal (`S11` `/g/{g1}/settings`):**
  - **Actors:** Window A (`Minh`, owner), then Window B (`Lan`, editor).
  - **Action:** As `Minh`, test `Tắt` → `Mỗi 3 ngày` → `Mỗi tuần` → `Mỗi 2 tuần` → `Tắt`, reloading after selections. Under `Duyệt khoản chi lớn`, enter invalid input (`0` or empty) and check `Lưu`; change threshold to `2.000.000` and save; toggle switch OFF and reload. Finally, in Window B (`Lan`, editor), open `/g/{g1}/settings` directly.
  - **Expected:** Each interval persists across reload; invalid threshold keeps `Lưu` disabled with no unintended mutation; `2.000.000` and OFF persist across reload; non-owner `Lan` sees `Bạn không có quyền làm việc này.` (refused).
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 5 — S13 & Local Console Telegram Pairing (No Real Bot / No Token)

> **Important:** With `TELEGRAM_PROVIDER=console`, do **not** open a real Telegram client or create a bot token. Simulate the bot webhook locally with `curl` against `http://127.0.0.1:4090` and read bot replies from Terminal 1 (API logs). Do **not** paste raw pairing secrets/codes into this checklist or save unmasked screenshots.

- [ ] **5.1 Independent email switches persistence (`S13` `/account`):**
  - **Actors:** Window B (`Lan`).
  - **Action:** On `/account`, toggle `Việc cần bạn làm ngay` OFF while leaving `Tổng hợp cuối ngày` ON, reload; then flip them (`Việc cần bạn làm ngay` ON, `Tổng hợp cuối ngày` OFF), reload; restore both ON.
  - **Expected:** Each switch persists independently across page reloads.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **5.2 Legacy link refusal & signed-out return (`/link/telegram`):**
  - **Actors:** Window C (signed out) and Window B (`Lan`).
  - **Action:** In Window C, open `http://127.0.0.1:3090/link/telegram`. In Window B (signed in as `Lan`), open `http://127.0.0.1:3090/link/telegram?code=LEGACY123`.
  - **Expected:** Window C redirects to `/login?next=%2Flink%2Ftelegram`; Window B immediately rejects the legacy `?code=` link with `Link này không còn dùng được.`.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **5.3 Local two-sided pairing (inactive before final web confirm) & unlink (`/link/telegram`, `/account`):**
  - **Actors:** Window B (`Lan`, verified) + local terminal (`curl`) + Terminal 1 (API console logs).
  - **Action:**
    1. In Window B, open `/link/telegram`, click `Bắt đầu liên kết`, and copy the displayed `pair_...` secret (do not commit or log it in docs).
    2. Simulate a **private** Telegram `/start` message locally:
       ```sh
       curl -sS -X POST "http://127.0.0.1:4090/api/v1/bots/telegram/webhook" \
         -H "Content-Type: application/json" \
         -H "X-Telegram-Bot-Api-Secret-Token: local_owner_accept_secret_32_chars_min" \
         -d '{"update_id":9001,"message":{"message_id":1,"chat":{"id":777001,"type":"private"},"from":{"id":777001,"first_name":"Lan"},"text":"/start <PASTE_PAIR_SECRET>"}}'
       ```
    3. Read `pc:<PAIRING_ID>` from the Terminal 1 console bot reply, then simulate tapping `Xác nhận liên kết`:
       ```sh
       curl -sS -X POST "http://127.0.0.1:4090/api/v1/bots/telegram/webhook" \
         -H "Content-Type: application/json" \
         -H "X-Telegram-Bot-Api-Secret-Token: local_owner_accept_secret_32_chars_min" \
         -d '{"update_id":9002,"callback_query":{"id":"cb-9002","from":{"id":777001,"first_name":"Lan"},"message":{"message_id":2,"chat":{"id":777001,"type":"private"}},"data":"pc:<PASTE_PAIRING_ID>"}}'
       ```
    4. **Before** clicking `Hoàn tất liên kết`, open `/account` in a second tab of Window B and confirm Telegram is **still not linked**.
    5. Return to `/link/telegram`, click `Hoàn tất liên kết`, then open `/account` and click `Bỏ liên kết`.
  - **Expected:** Identity stays inactive until final web confirmation; clicking `Hoàn tất liên kết` shows `Đã liên kết. Quay lại Telegram để tiếp tục.`; `/account` shows `Đã liên kết với Telegram` and `Bỏ liên kết` removes it cleanly.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 6 — Unsubscribe (Signed-Out Valid & Invalid, Account Isolation)

- [ ] **6.1 Signed-out valid & invalid unsubscribe URLs (`/notifications/unsubscribe`, `/account`):**
  - **Actors:** Window C (signed out), Window B (`Lan`, target account), Window A (`Minh`, control account).
  - **Action:**
    1. Trigger an immediate notification email for `Lan` (e.g., from Flow 3.1 or by opening a dispute on an expense `Lan` participates in) and copy the `http://127.0.0.1:3090/notifications/unsubscribe?token=...` URL from Terminal 2 (Worker console logs). **Treat this URL as a local secret — never commit or paste the raw token into run documents.**
    2. In Window C (signed out), first open that URL with 1 character altered in `token`.
    3. Next, in Window C (signed out), open the exact valid URL.
    4. Check `/account` in Window B (`Lan`) and Window A (`Minh`).
  - **Expected:** Altered URL renders `Link này không còn dùng được.`; valid URL renders `Bạn sẽ không nhận thư thông báo nữa.` with `Bật lại trong Tài khoản`; `Lan` now has **both** `Việc cần bạn làm ngay` and `Tổng hợp cuối ngày` OFF, while `Minh`'s email switches remain unchanged (both ON).
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

#### Flow 7 — Resilience, Accessibility, and 375px Mobile Layout

- [ ] **7.1 Offline failure & online recovery (`S13` `/account`):**
  - **Actors:** Window A (`Minh`).
  - **Action:** Open DevTools → Network → set **Offline**. Toggle `Việc cần bạn làm ngay` on `/account`. Switch back to **Online** and toggle again, then reload.
  - **Expected:** Offline toggle fails cleanly with error feedback and reverts to the persisted state; back online, toggling succeeds and persists across reload.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **7.2 Permission loss while S20 is open (`S20` & `S19`):**
  - **Actors:** Window B (`Hùng`, viewer) and Window A (`Minh`, owner).
  - **Action:** Keep Window B open on `/g/{g1}/tx/{E1}/view`. In Window A, remove `Hùng` from `Đà Lạt Nghiệm Thu` on `/g/{g1}/members`. In Window B, try posting a comment or reload S20, then open `/notifications`.
  - **Expected:** Window B loses access cleanly (`404`/not-found or redirect) with **zero** private transaction/comment content from the removed group, and `/notifications` hides all notifications from `Đà Lạt Nghiệm Thu`.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **7.3 Keyboard navigation & Escape focus return (`S20`, `S19`, `S11`, `/link/telegram`):**
  - **Actors:** Window A (`Minh`).
  - **Action:** Use `Tab` / `Shift+Tab` across S20, S19, S11, and `/link/telegram`; activate controls with `Enter` / `Space`; on S20 open `Khoản này chưa đúng` (or `Không duyệt` on a pending expense) and press `Escape`.
  - **Expected:** Visible focus outlines appear on interactive controls; `Enter`/`Space` activates them; `Escape` closes the dialog and returns keyboard focus directly to the trigger button.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

- [ ] **7.4 Mobile `375px` layout — S11 amount input & `/link/telegram` long-email wrapping:**
  - **Actors:** Window A (`Minh`).
  - **Action:** Open DevTools device toolbar at `375×812`. Inspect `/g/{g1}/settings` (with `Duyệt khoản chi lớn` enabled so `Từ số tiền` is visible) and `/link/telegram` (verify the signed-in email wraps cleanly inside the card without clipping or pushing page width). Check `document.documentElement.scrollWidth <= document.documentElement.clientWidth`.
  - **Expected:** Zero horizontal overflow (`scrollWidth <= clientWidth`) on both S11 and `/link/telegram`; S11 amount input fits inside its card and long account email wraps cleanly.
  - **Result:** `[ ] PASS  [ ] FAIL  [ ] NOT RUN` | **Notes:** `____________________`

---

### 4. Owner Acceptance Result

| Field | Value |
|---|---|
| Acceptance date | _(blank — pending)_ |
| Checked code revision | `8602eda95abdd5e9a4b831a4c93a6abccfe8d373` |
| Owner outcome | **PENDING** |
| Unresolved notes | _(none recorded yet)_ |

**Defect & Merge Rule:**
- If any owner check reveals a defect, record exact reproduction steps and observed vs. expected behavior here, and return the branch for a narrow fix, affected gate verification, and advisor review before merging.
- Checking boxes in this document does **not** automatically merge, push, or deploy `phase-4`. Merging to `main` remains an explicit owner action.

---

### 5. Deferred External & Owner-Device Verification

The items below remain **explicitly deferred** under prior owner decisions (not silently passed, and not prerequisites to merge if the owner accepts the local verification above). Do not create accounts, obtain credentials, register webhooks, or contact external providers during local acceptance.

- **Real AI providers (`AI_PROVIDER=anthropic` / real receipt OCR & sentence fallback):** Deferred by the project owner until all phases, including the native iOS app, are complete.
- **Real SMTP delivery & mail-client RFC 8058 one-click unsubscribe:** Deferred until a real SMTP provider and domain exist (verified locally via console mailer and simulated no-Origin form `POST` to `/notifications/unsubscribe`).
- **Real Telegram Bot API (`api.telegram.org`), `@BotFather` token, public HTTPS `setWebhook` registration, and Telegram client rendering:** Deferred until a real bot and public HTTPS endpoint exist (see [docs/runbooks/telegram.md](file:///Users/hoojinguyen/Projects/songphang/docs/runbooks/telegram.md) and **After the Telegram bot exists** below).
- **Real Google OAuth sign-in:** Deferred until OAuth credentials are configured.
- **Owner physical device checks (iOS Safari / Android Chrome touch ergonomics and real banking app VietQR 1.000 đ transfer test):** Deferred until owner device testing.

---

## Detailed Screen-by-Screen Reference Checks

These detailed checks were appended as each stage completed and are retained for reference, with stale role/wording/local-Telegram notes aligned to the accepted implementation.

### S20 — Transaction view, comments, and disputes (Stage 4A)

1. Open a group stream (`S4`) as an editor/owner and tap any expense row -> lands on `/g/{groupId}/tx/{txId}/view` showing the amount, payer, split breakdown, category, attachments, and `Sửa` in the header.
2. Tap `Sửa` -> opens the edit screen; tap `Quay lại` or `Huỷ` -> returns to `/view`.
3. Open the same transaction in a second browser window as a viewer member -> `Sửa` is hidden, while `Khoản này chưa đúng` and the comment input are active.
4. Type a comment and press `Enter` (use `Shift+Enter` for a newline) -> comment appears in both windows live via SSE without refreshing; send `<script>alert(1)</script>` -> displays as literal text with no alert.
5. Delete one of your own comments with `Xoá bình luận` -> removed from both windows live; verify a viewer or non-author editor cannot delete another member's comment (delete is available only to the comment author or the group owner).
6. Tap `Khoản này chưa đúng`, enter an empty/whitespace reason -> `Gửi` stays disabled; enter a reason and submit -> coral card appears (`{Name} cho rằng khoản này chưa đúng`), and the stream row shows the `đang hỏi lại` tag plus `{N} bình luận`.
7. Tap `Đã giải quyết` (as opener or owner) -> snackbar `Đã giải quyết.` appears, card returns to `Khoản này chưa đúng`, and `đang hỏi lại` disappears live from the stream row.
8. Soft-deleted transaction check (R10): open a dispute on an expense as a viewer, delete the expense as owner, open the deleted expense's `/view` page in both windows -> confirm the deleted banner appears, the viewer can still post a comment (which appears live via SSE in the owner's window without auto-restoring the transaction), the opener/owner can resolve the already-open dispute (`Đã giải quyết`), opening a **new** dispute on the deleted transaction is rejected, and restoring the transaction retains all comments.

### S19 — Notification bell, list, and group mute (Stage 4B)

1. Sign in as a user with unread notifications -> the bell button in the S2 (`/`) and S4 (`/g/{groupId}`) headers shows the unread count (`9+` when above 9) and accessible name `{count} thông báo chưa đọc`.
2. With S4 open in Window A, have another user add a comment, expense, or debt reminder in Window B -> Window A's bell count updates live via SSE without refreshing.
3. Tap the bell -> opens `/notifications` (`S19`). Unread items have the `sunken` background and display the exact Spec 7.2 text (`{actor} thêm {description} · phần bạn {share}`, etc.).
4. Tap an unread item -> navigates directly to the transaction view, balances, or stats screen, and the unread count decreases by 1.
5. Tap `Đánh dấu đã đọc` -> all items become read, the button disables, and the bell badge disappears.
6. Open a group's members screen (`/g/{groupId}/members`) and toggle `Tắt thông báo nhóm này` on -> new expenses/comments in that group create no notifications for you; toggle back off to resume.

### S13 & Unsubscribe — Email notifications and one-click unsubscribe (Stage 4B)

1. Open `/account` (`S13`) -> card `Thông báo qua email` shows `Việc cần bạn làm ngay` and `Tổng hợp cuối ngày` toggles; toggle each independently and refresh -> state persists.
2. With both worker and API running (console mailer), have another member open a dispute -> worker console prints one mail with `List-Unsubscribe` / `List-Unsubscribe-Post: List-Unsubscribe=One-Click`, subject matching the notification line, `Mở Sòng Phẳng`, and footer `Không muốn nhận thư nữa? Bỏ đăng ký`.
3. Copy the `/notifications/unsubscribe?token=...` URL from the printed mail (keep the raw token out of docs/Git) and open it in a signed-out/private browser window -> confirms `Bạn sẽ không nhận thư thông báo nữa.` with link `Bật lại trong Tài khoản`. Opening `/account` shows both email switches off while another account's switches remain unchanged; alter 1 character of `token` -> renders `Link này không còn dùng được.`.
4. Re-enable email notifications in `/account`, trigger a second mail, then simulate an RFC 8058 mail client with `curl -i -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d 'List-Unsubscribe=One-Click' '<copied URL from mail 1>'` (no cookies, no `Origin` header, using the *older* link from step 3) -> returns `204 No Content` and disables both email switches again.

### S5 & S11 — Debt reminders and auto-reminder settings (Stage 4B)

1. In a group with `>= 2` linked debtor transfers and `1` unlinked debtor (`Thu`), open `/g/{id}/balances` as owner -> verify `Nhắc` is shown next to `Đã trả` for linked debtors, hidden for `Thu`, and `Nhắc cả nhóm một lần` appears.
2. Click `Nhắc` on `Hùng` -> snackbar shows `Đã nhắc Hùng.` and `Hùng`'s `/notifications` displays `Nhắc nhẹ: bạn cần trả Minh ...`.
3. Click `Nhắc` on `Hùng` again immediately -> snackbar shows `Bạn vừa nhắc Hùng rồi. Nhắc lại được sau {giờ} ngày {ngày}.`.
4. Click `Nhắc cả nhóm một lần` -> snackbar shows `Đã nhắc 1 người.` (or `Đã nhắc 0 người.` when all eligible pairs are within the 24-hour cooldown).
5. As owner, open `/g/{id}/settings` under `Tự nhắc nợ`, select `Mỗi tuần`, reload the page -> `Mỗi tuần` stays pressed (`PATCH /groups/{id}` persisted `reminderIntervalDays: 7`).

### S11, S13, `/link/telegram`, and `?form&text=` — Local Console Telegram Flows (Stage 4C)

1. When `TELEGRAM_PROVIDER=console` is enabled, open `/g/{id}/settings` as owner -> `Liên kết nhóm Telegram` appears with `Tạo mã liên kết`; click to generate a monospace `/lienket XXXXXXXX` command and copy with `Sao chép`.
2. Open `/link/telegram` while signed out -> redirects through `/login?next=%2Flink%2Ftelegram`. After signing in with a verified account, `/link/telegram` asks `Liên kết Telegram với tài khoản {email}?` and clicking `Bắt đầu liên kết` produces a one-time `/start pair_...` command (10-minute TTL). Use the local `curl` webhook simulation in **Flow 5.3** above (never a real bot or real token) to simulate private `/start pair_...` and `pc:<PAIRING_ID>` confirmation -> browser transitions to `Hoàn tất liên kết Telegram`; clicking `Hoàn tất liên kết` completes the link (`Đã liên kết. Quay lại Telegram để tiếp tục.`). Also check invalid cases: opening an old `/link/telegram?code=TEST` link immediately shows `Link này không còn dùng được.`; simulating `/start pair_...` with `"type":"group"` refuses without echoing the secret and invalidates that pairing attempt.
3. Open `/account` -> `Telegram` card shows `Đã liên kết với Telegram`; clicking `Bỏ liên kết` removes it. Returning to `/g/{id}/settings` shows linked chat IDs and clicking `Bỏ liên kết` unlinks them.
4. Open `/g/{id}/tx/new?form&text=abc%20xyz` -> `Mô tả` input is prefilled with `abc xyz`.

### S11 & S20 — Expense approval above a threshold (Stage 4D)

1. Open `/g/{id}/settings` as group owner -> enable `Duyệt khoản chi lớn`, enter `1.000.000` in `Từ số tiền`, confirm hint `Khoản chi từ mức này chỉ được tính sau khi bạn duyệt.`, and tap `Lưu`.
2. Switch to a linked editor (`Lan`) and save an expense for `1.200.000 đ` -> snackbar shows `Đã lưu. Khoản này chờ Minh duyệt.`, stream row is dimmed with `chờ duyệt`, and group balances remain unchanged.
3. As owner (`Minh`), tap the notification bell -> tap `{Actor} thêm {desc} · 1.200.000 đ, cần bạn duyệt` -> lands on S20 showing `Khoản này chờ Minh duyệt. Chưa tính vào số dư.` with `Duyệt` and `Không duyệt` (hidden for non-owners).
4. Tap `Duyệt` -> approval block and `chờ duyệt` tag clear immediately and balances/SSE streams update across open windows; confirm approving again is rejected cleanly if triggered concurrently.
5. As editor (`Lan`), edit the approved expense on S20 (`Sửa`) to `1.500.000 đ` -> returns to `chờ duyệt` and clears balances until re-approved.
6. As owner (`Minh`), tap `Không duyệt` on S20 -> dialog `Vì sao không duyệt?` opens with optional `Ghi chú` -> submit with or without a note -> S20 shows `Minh không duyệt khoản này.` (+ note if entered) and stream rows show `không được duyệt`.

### After the Telegram bot exists (Deferred)

1. In a real Telegram group linked via `/lienket <code>`: send `/chi cà phê 180k chia 4` -> bot replies with split breakdown and `Lưu` / `Bỏ` buttons -> tap `Lưu` -> web app expense list updates within 2 seconds.
2. A friend who has not linked their Sòng Phẳng account runs `/chi ...` -> receives `Mình chưa biết bạn là ai trên Sòng Phẳng.` with `Liên kết tài khoản` button opening `/link/telegram` (containing no code/secret), and nothing is saved. Following the private `/start pair_...` -> Telegram `Xác nhận liên kết` -> browser `Hoàn tất liên kết` flow activates their identity without allowing any other user or group chat to hijack it.
3. Another person taps your `Lưu` button -> rejected with `Chỉ {tên bạn} lưu được khoản này.` and nothing is saved.
