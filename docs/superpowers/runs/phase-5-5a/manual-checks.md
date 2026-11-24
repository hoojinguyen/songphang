# Wave 5.5A — Owner Manual Verification Checklist

- Branch: `phase-5-5a`
- Tested revision: `phase-5-5a` (HEAD `9d2732b` + remediation commits / all Stage 5.5A.1–5.5A.5 commits merged)
- Local checks summary:
  - `pnpm check`: Exit 0 (all 8 packages clean, Biome clean, contract snapshot up to date)
  - `pnpm build`: Exit 0 (Next.js 16.4.6 static/dynamic production build clean)
  - `./apps/ios/Scripts/check-strings.sh`: Exit 0 (717 web keys verified, 0 missing, 0 differing)
  - `xcrun swift-format lint --strict --recursive apps/ios`: Exit 0 (clean)
  - `xcodebuild` Simulator Debug: `** BUILD SUCCEEDED **`
  - `xcodebuild` unsigned Release: `** BUILD SUCCEEDED **`
  - Release bundle leak check: `RELEASE_LEAK_MATCH_COUNT=0`, `ATS_FREE_OK`, `PRIVACY_INFO_OK`
  - Clean disposable DB replay: All 12 test stages passed; `check-balances` reports `All groups balanced`

## Physical iPhone & Web Browser Checks

1. **Theme & Contrast (`TD-004`):**
   - On iOS (`Tài khoản` -> `Giao diện`) and Web (`/account`), toggle between `Theo hệ thống`, `Sáng`, and `Tối`.
   - Verify on Web that reloading the page has zero flash of unstyled content (FOUC).
   - In Dark mode, verify all card text, form labels, and placeholder inputs (`placeholder:text-placeholder`) have crisp contrast (> 4.5:1) with zero dark-on-dark text.
2. **Dense Group Stress (`TD-003`, `TD-005`, `TD-006`):**
   - On iPhone, tap `Tạo nhóm mới`: add 10+ members with keyboard open (`TD-003`). Confirm newly added rows smoothly scroll into view above the keyboard and the bottom `Tạo nhóm` button is never obscured by the keyboard toolbar across portrait screen sizes and accessibility Dynamic Type.
   - In a group with 7–20 members, open Quick Entry (`TD-005`): pick a split among all members and verify `ConfirmationCard` and `ShareShapes` wrap cleanly into a responsive grid with zero horizontal clipping.
   - Scan the `Chi tiêu` feed (`TD-006`): verify full-width 3-row cards render total amounts with tabular numbers (`monospacedDigit`), server-authoritative `myDelta` signed delta (`+` credit, `-` debt, or `Không tham gia`), and overlapping 5-avatar cluster with `+N` badge.
3. **Stats Label (`TD-007`):**
   - In group details, switch to `Quỹ & Thống kê`: confirm `"Tổng chuyến đi"` renders cleanly in Vietnamese UI and opens detailed category breakdown and CSV export.
4. **Local Email Verification (`TD-001`):**
   - Register a new dev account or open a verification link from `.local` dev host on iPhone in-app browser and confirm confirmation succeeds without origin error.
5. **"Bơm hình" & iOS Native Polish:**
   - In expense split editor under `Theo phần`, `Theo %`, or `Số tiền`, press and hold a member shape badge.
   - Verify initial 250ms delay followed by smooth 180ms repeat increment, scale spring animation, light haptic feedback on iPhone, and debounced server preview sync on release.
   - In active group feed, swipe left/right on transactions: leading `Sửa` opens edit sheet, trailing `Xoá` soft-deletes with undo snackbar.
6. **Cross-Group Overview & Personal Ledger:**
   - In bottom navigation, tap `Tổng quan` (`S0`): verify `Tổng được nhận`, `Tổng cần trả`, and `Chênh lệch ròng` aggregate across all groups.
   - Tap `Cần bạn xử lý` item: verify it navigates directly to the target group screen.
   - In `Giao dịch gần đây` or tab `Sổ cái`, verify personal transaction feed with search query `q` (Vietnamese accent-insensitive) and confirm `sum(myDelta) === myBalance`.
7. **Group Archive & Clone:**
   - Open group settings as owner: tap `Lưu trữ nhóm`. Verify group moves to `Đã lưu trữ` tab in group list, bottom quick entry bar is replaced with `Nhóm đã lưu trữ — chỉ xem`, and mutation attempts return 409 `GROUP_ARCHIVED`.
   - Tap `Nhân bản nhóm`: verify dialog pre-fills `"{name} (bản sao)"`, toggles payment methods / categories, creates active clone with zero transactions, and navigates into it.
   - In archived group, tap `Khôi phục nhóm`: verify group returns to `Đang mở` and write actions are restored.
8. **Web Desktop Layout (`>= 1024px` & `>= 1280px`):**
   - Open Web browser on desktop:
     - At `1024px–1279px`: 2-column view with fixed left `DesktopSidebar` (260px) and center workspace (up to 760px).
     - At `>= 1280px` on group pages: 3-column view with `DesktopSidebar`, center feed, and sticky right `GroupInspector` (340px) showing live net balance hero and top suggested transfers with quick QR / settle buttons.
   - Auth and join pages (`/login`, `/register`, `/join/...`) remain clean focused single-column.

## External Checks Deferred to Server Step

- `TD-002` (production SMTP inbox delivery on iPhone), live Google/Apple OAuth, live APNs hardware delivery, real Telegram webhook, 30-receipt AI benchmark, TestFlight upload.
