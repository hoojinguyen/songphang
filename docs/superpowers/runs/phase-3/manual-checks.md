# Phase 3 run — owner manual checks

Checks will be appended by screen and flow as tasks complete, plus sections for **After the Anthropic key exists** and **The 30-receipt measurement**.

## S8 and S4 — photos on transactions (3A.4)

1. Add an expense with a photo from your phone → the thumbnail shows in the form; saving shows the photo mark on the row in S4; tapping the expense reopens it and the photo opens full-screen (closable by button, Escape, or backdrop).
2. Open the photo's content address (`/api/v1/groups/{id}/attachments/{attachmentId}/content`) in a private window (signed out) → 401/not found; as a viewer in the group, open the expense with photos → photos open full-screen and no `Thêm ảnh` or remove control exists.

## S4 → Receipt review and item splitting (3B.3, 3C.3)

3. With `AI_PROVIDER=fake` and `AI_FAKE_RECEIPT_FIXTURE=clean`, open the group feed, tap `Chụp hoá đơn` → `Chọn từ thư viện`, and select `apps/worker/fixtures/receipts/clean.jpg` → lands on `/tx/new?scan=...` showing `Đọc bằng AI. Hãy xem lại trước khi lưu.`, `Lẩu thái` (`350.000`), `Bia` (`90.000`), and `Còn 2 món chưa có ai.`.
4. Tap `Chia đều các món còn lại`, assign `Bia` to one member, verify totals recompute cleanly, double-tap `Lưu` → creates 1 expense (`440.000`, `Có ảnh hoá đơn`) and returns to the feed.
5. Switch `AI_FAKE_RECEIPT_FIXTURE=mismatch`, upload an image → verify `MismatchNotice` (`442.000 đ` vs `450.000 đ`) appears and tapping `Dùng 450.000 đ` adds a `Chênh lệch` adjustment so total matches `450.000 đ`.
6. Switch `AI_FAKE_RECEIPT_FIXTURE=not-a-receipt`, upload an image → verify `Không đọc được hoá đơn trong ảnh này.` offers `Chụp lại` and `Nhập tay`; tap `Nhập tay` → opens the manual form with the photo still attached and `Theo món` available under `đổi cách chia`.
7. Navigate through `ReceiptReview` using only `Tab`, `Enter`, and `Space` → all items, member toggles, and `Lưu` operate without mouse/touch and every member shape exposes its name.

## S7 → AI sentence reading and category suggestions (3D.3)

8. With `AI_PROVIDER=fake`, open S7 (`Gõ một khoản chi…`) in a group containing Minh, Lan, Hùng, Thu and enter `"lẩu 300k lan 100 lan 200"` → shows `Đọc bằng AI. Hãy xem lại.`, no phrase highlights in the sentence box, and `Ăn uống` chip. Save and confirm on the feed.
9. Enter `"cà phê 180k và bánh 50k"` → shows `Khoản 1/2` (`cà phê`), `Lưu và sang khoản sau`, and `Bỏ khoản này`. Tap `Lưu và sang khoản sau` → advances to `Khoản 2/2` (`bánh`), then tap `Bỏ khoản này` → returns to feed with only `cà phê` saved.
10. Enter `"cà phê 180k hôm qua"` → opens `/tx/new?form` prefilled with `180000`, `cà phê`, `Ăn uống`, and `Mình chưa hiểu hết câu này`.
11. Enter `"phở 60k chia 2"` → after selecting 2 members, tap the `Ăn uống` category chip, switch to `Đi lại`, and save → feed shows `phở` under `Đi lại`.

## Feature-off behavior

12. Leave `AI_PROVIDER` unset in `.env` and restart → confirm `GET /api/v1/features` returns `receiptReading: false` and `sentenceAi: false`, `Chụp hoá đơn` is hidden in S4, and `POST /api/v1/groups/{groupId}/receipt-scans` returns `404`.

## After the Anthropic key exists

1. In local `.env`, set `AI_PROVIDER=anthropic`, `ANTHROPIC_API_KEY=<your key>`, `AI_MODEL=claude-haiku-4-5`, and unset `AI_FAKE_RECEIPT_FIXTURE`. Restart API, worker, and web (`pnpm dev`).
2. Confirm startup succeeds, `GET /api/v1/features` returns `receiptReading: true` and `sentenceAi: true`, and `GET /groups/{id}` renders `Chụp hoá đơn`.
3. Photograph a real Vietnamese paper receipt on a phone over mobile data (`4G`), upload it, and verify: upload completes with `Đang tải ảnh lên…`, scan settles to `ready`, line items/taxes/totals match the paper slip, and saving attaches the photo and updates balances accurately.
4. Test a blurry non-receipt photo → verify clean `Không đọc được hoá đơn trong ảnh này.` error state and `Nhập tay` preserves the photo.
5. In S7, type 2–3 colloquial natural sentences not handled by the rule parser (e.g., `"lẩu 320k thu 120 còn lại chia minh lan"` and multi-expense `"bún 90k và trà đá 20k"`) → verify `Đọc bằng AI. Hãy xem lại.`, accurate VND math, no hallucinated group members, and `ai_calls` cost/token logging (`cost_vnd`, `input_tokens`, `output_tokens`).
6. Verify daily/monthly quota caps (`AI_RECEIPTS_PER_USER_PER_DAY`, `AI_SENTENCES_PER_USER_PER_DAY`, `AI_CALLS_PER_MONTH`) by temporarily lowering them in `.env`: receipts return a friendly limit error (`RATE_LIMITED` / cap message) and sentences silently fall back to rules/manual form without breaking input.

## The 30-receipt measurement

Collect 30 real Vietnamese receipts across restaurants, cafés, supermarkets, and taxis/grab slips (mix thermal paper, crumpled/angled shots, VAT/service-charge bills, and handwritten bills). Record each run below before enabling AI by default for external users:

| # | Receipt type | Lighting / angle | Latency (upload -> ready, s) | Total matched paper? (Y/N) | Items missing/wrong (count) | Input tokens | Output tokens | Recorded `cost_vnd` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | | | | |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |
| 4 | | | | | | | | | |
| 5 | | | | | | | | | |
| 6 | | | | | | | | | |
| 7 | | | | | | | | | |
| 8 | | | | | | | | | |
| 9 | | | | | | | | | |
| 10 | | | | | | | | | |
| 11 | | | | | | | | | |
| 12 | | | | | | | | | |
| 13 | | | | | | | | | |
| 14 | | | | | | | | | |
| 15 | | | | | | | | | |
| 16 | | | | | | | | | |
| 17 | | | | | | | | | |
| 18 | | | | | | | | | |
| 19 | | | | | | | | | |
| 20 | | | | | | | | | |
| 21 | | | | | | | | | |
| 22 | | | | | | | | | |
| 23 | | | | | | | | | |
| 24 | | | | | | | | | |
| 25 | | | | | | | | | |
| 26 | | | | | | | | | |
| 27 | | | | | | | | | |
| 28 | | | | | | | | | |
| 29 | | | | | | | | | |
| 30 | | | | | | | | | |

