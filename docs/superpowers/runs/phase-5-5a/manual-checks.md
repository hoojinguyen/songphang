# Wave 5.5A — Owner Manual Verification Checklist

- Branch: `phase-5-5a`
- Tested revision: _(Pending completion of Stage 5.5A.5)_
- Local checks summary: _(Pending)_

## Physical iPhone & Web Browser Checks

1. **Theme & Contrast (`TD-004`):** Switch `Giao diện` across `Theo hệ thống`, `Sáng`, and `Tối` on iPhone and Web; verify zero flash on Web reload and crisp placeholders/numbers in Light, Dark, and Increase Contrast.
2. **Dense Group Stress (`TD-003`, `TD-005`, `TD-006`):** Create an 8+ member group on iPhone (`TD-003`), pick a 7-person Quick Entry sample (`TD-005`), add an uneven expense and scan the `Chi tiêu` feed (`TD-006`) across normal and accessibility Dynamic Type sizes.
3. **Stats Label (`TD-007`):** Confirm `"Tổng chuyến đi"` renders cleanly in Vietnamese iOS UI and opens statistics.
4. **Local Email Verification (`TD-001`):** Open a verification link from `.local` dev host on iPhone in-app browser and confirm confirmation state succeeds.
5. **"Bơm hình" & iOS Native Polish:** Hold-to-grow member shapes in `Theo phần`, `Theo %`, and `Số tiền` on iPhone (Haptics + spring scale + server preview) and Web; verify swipe actions (`Sửa`, `Xoá`) on active groups and disabled state when archived or offline.
6. **Cross-Group Overview & Personal Ledger:** Verify `Tổng quan` totals and `Giao dịch của bạn` across 2+ groups (active + archived), and jump from a pending action directly to the target group screen.
7. **Group Archive & Clone:** Archive a group (confirm read-only state on iOS & Web), clone it with payment methods, verify zero copied transactions, and unarchive.
8. **Web Desktop Layout (`1440px`):** Verify 3-column `/g/[groupId]` workspace + live right balance/detail inspector in Light and Dark modes.

## External Checks Deferred to Server Step

- `TD-002` (production SMTP inbox delivery on iPhone), live Google/Apple OAuth, live APNs hardware delivery, real Telegram webhook, 30-receipt AI benchmark, TestFlight upload.
