# Nghiên cứu Settle Up — công nghệ, nghiệp vụ, hạ tầng, kiến trúc

Ngày: 2026-11-10. Đối tượng: web app `https://settleup.app/` (Step Up Labs, Séc) và tài liệu API công khai `https://api.settleup.io/`.

## 0. Phạm vi và độ tin cậy

| Nguồn | Cách lấy | Độ tin cậy |
|---|---|---|
| Bundle JS, network, Remote Config của web app | REA: chụp phiên trình duyệt chưa đăng nhập, xuất script, phân tích tĩnh (không thực thi) | Cao — quan sát trực tiếp |
| Mô hình dữ liệu, thao tác, server task | Tài liệu API công khai của chính Settle Up | Cao, nhưng họ tự ghi là "có thể chưa đầy đủ" |
| Giá Premium | Phản hồi thật của endpoint `getStripePrices` (giá web, USD) | Cao tại thời điểm chụp |
| Tính năng Premium, giá trên store | Kết quả tìm kiếm (App Store, trang tổng hợp) | Trung bình |

**Chưa làm / chưa xác minh:**
- Chưa đăng nhập, nên chưa quan sát luồng dữ liệu thật sau đăng nhập (màn hình nhóm, thêm giao dịch, biểu đồ).
- Chưa phân tích app Android/iOS (cần bạn đồng ý tải APK). Mọi nhận định về mobile bên dưới là suy luận.
- Thuật toán tính nợ chạy trên server (Cloud Functions), không nằm trong bundle → không quan sát được, phần mô tả thuật toán là thiết kế đề xuất của tôi.
- Security rules của database không công khai.

## 1. Công nghệ (đã xác minh bằng REA)

**Web client**
- Angular **20.3.16**, build bằng esbuild (các file `main-*.js`, `chunk-*.js`, `polyfills-*.js`), lazy-load theo route. Tổng JS khoảng 2,4 MB chưa nén.
- Angular Material (MDC), font Roboto + Material Symbols.
- PWA: có `manifest.json` và Angular service worker (`ngsw`).
- RxJS cho luồng realtime; có thư viện số thập phân (BigNumber/Decimal) để tính tiền.
- i18n tự làm: tải `assets/i18n/<lang>/default.json` (dùng chung với mobile) và `web.json`; dịch cộng đồng qua `translate.settleup.io`.
- Route: `/`, `/group`, `/charts`, `/premium`, `/password-reset`, `/migrate-account`.

**Backend — gần như 100% Firebase (serverless), project `settle-up-live`**
- **Firebase Realtime Database** là kho dữ liệu chính; client đọc/ghi trực tiếp, đồng bộ realtime, offline sẵn có trên mobile.
- **Firebase Authentication**: email/password, Google, Apple, và **passkey (WebAuthn)** — passkey đi qua custom token do Cloud Function cấp.
- **Cloud Functions** (us-central1): endpoint HTTP như `getStripePrices`, `createStripeSessionEmbedded`, và worker xử lý hàng đợi `serverTasks`.
- **Firebase Storage**: ảnh hoá đơn, ảnh "what's new".
- **Remote Config**: feature flag, ngưỡng cập nhật bắt buộc, cấu hình paywall, tần suất quảng cáo, cấu hình email.
- **FCM** (web push qua VAPID), **App Check**, **Firebase Installations**, **Analytics (GA4)**.
- Có môi trường **sandbox** riêng (`settle-up-sandbox`) song song với live.

**Bên thứ ba**
- Thanh toán web: **Stripe** (embedded checkout + link donate). Mobile nhiều khả năng dùng IAP của store.
- Lỗi: **Sentry**. Hành vi người dùng: **Microsoft Clarity**.
- Quảng cáo: **AppLixir** (video có thưởng), Google IMA / GPT, Prebid; banner affiliate (Alza, eToro).
- Consent GDPR: **Didomi**.
- Deep link: `join.settleup.app` + scheme `settleup://` (thay cho Firebase Dynamic Links đã bị khai tử).
- Bitcoin Lightning: có code và email template nhưng cờ `bitcoin_lightning_enabled = false`.

**Mobile (chưa xác minh):** package Android `cz.destil.settleup`, có Android Intent API công khai; Remote Config cho thấy Android min SDK 26, iOS tối thiểu 17.0, hỗ trợ QR thanh toán SPAYD của các ngân hàng Séc.

## 2. Mô hình dữ liệu (Realtime Database)

Dữ liệu được **phi chuẩn hoá theo nhóm**: mỗi loại thực thể là một nhánh gốc, khoá bằng `groupId`. Nhờ vậy client chỉ subscribe đúng nhánh cần, và security rule kiểm tra quyền theo `permissions/<groupId>/<uid>`.

| Đường dẫn | Nội dung chính |
|---|---|
| `/groups/<groupId>` | `name`, `convertedToCurrency` (tiền tệ nhóm), `minimizeDebts`, `remindOldDebts`, `inviteLink`, `inviteLinkHash`, `inviteLinkActive`, `defaultPermission`, `ownerColor`, `premiumPurchasedBy`, `premiumPurchasedUntil`, `lastChanged` |
| `/members/<groupId>/<memberId>` | Thành viên **ảo** (không cần tài khoản): `name`, `active`, `defaultWeight`, `bankAccount`, `lightningAddress`, `photoUrl`, `paymentHandles` (revolut, cashapp…) |
| `/permissions/<groupId>/<uid>` | `level`: 30 = chủ nhóm, 20 = đọc/ghi, 10 = chỉ đọc |
| `/userGroups/<uid>/<groupId>` | Chỉ mục ngược của permissions: `order`, `color`, `member` ("đây là tôi") |
| `/transactions/<groupId>/<txId>` | Xem bên dưới |
| `/recurringTransactions/<groupId>/<id>` | `template` (giao dịch không có `dateTime`) + `recurrence` (`period`: daily/weekly/monthly/yearly, `frequency`, `startDate`, `endDate`, `endCount`, `weeklySetting`, `monthlySetting`, `timezoneOffsetMillis`) + `lastGenerated`, `runCount` |
| `/debts/<groupId>` | Mảng `{from, to, amount}` theo tiền tệ nhóm — **server tự sinh** |
| `/changes/<groupId>/<id>` | Nhật ký thay đổi do server sinh: `action`, `entity`, `entityId`, `entityName`, `by`, `serverTimestamp` |
| `/groupCategories/<groupId>` | Map emoji → tên danh mục tuỳ chỉnh |
| `/users/<uid>` | `name`, `email`, `authProvider`, `locale`, `currentTabId`, `inviteLinkHash`, `superuser`, `defaultPaymentHandles` |
| `/inviteLinkHashes/<hash>` | Tra hash lời mời → nhóm |
| `/serverTasks/<taskName>/<taskId>` | Hàng đợi tác vụ bất đồng bộ: `request`, `progress`, `response` |
| `/exchangeRates`, `/subscriptions`, `/archivedGroups`, `/premium` | Tỉ giá, thuê bao, nhóm lưu trữ, gói premium (thấy trong bundle, không có trong tài liệu) |

**Giao dịch** — một cấu trúc duy nhất cho mọi kiểu chia:
```json
{
  "type": "expense",            // hoặc "transfer"; thu nhập = expense với số âm
  "purpose": "Ăn tối", "category": "🍕",
  "currencyCode": "CZK", "dateTime": 1700000000000, "timezone": "+01:00",
  "whoPaid": [{ "memberId": "m1", "weight": "1" }],
  "items": [                    // item 1 = khoản chính, 2 = tip, 3 = thuế
    { "amount": "200.33",
      "forWhom": [{ "memberId": "m1", "weight": "1" }, { "memberId": "m2", "weight": "2.3" }] }
  ],
  "exchangeRates": { "EUR": "27.05" }, "fixedExchangeRate": false,
  "receiptUrl": "...", "templateId": "...", "entryMode": "quick"
}
```
Điểm đáng học:
- **Tiền và trọng số là chuỗi thập phân**, không dùng float.
- **Weight tổng quát hoá mọi cách chia**: chia đều, theo phần, theo phần trăm, theo số tiền cụ thể đều quy về trọng số. Nhiều người trả cũng dùng weight.
- **Tỉ giá chụp lại tại thời điểm giao dịch** và lưu kèm, nên lịch sử không đổi khi tỉ giá thay đổi.
- Thành viên tách khỏi tài khoản: một người có thể dùng nhóm mà không cần đăng ký; nhiều tài khoản có thể trỏ cùng một thành viên.

## 3. Nghiệp vụ và tính năng

**Lõi**
- Nhóm, thành viên ảo, mời qua link / QR; 3 mức quyền; xem trước nhóm (`previewGroup`) trước khi tham gia.
- Chi tiêu, chuyển khoản, thu nhập; nhiều người trả; chia đều / theo trọng số / phần trăm / số tiền; nhiều item (tip, thuế).
- Đa tiền tệ với tỉ giá tự động, cho phép cố định tỉ giá; đổi tiền tệ cả nhóm (`currencyChange`).
- Tính nợ tự động, tuỳ chọn **tối giản số lượng khoản nợ**; "settle debt" / "settle all debts".
- Nhắc nợ (`remindDebt`, email debt-reminder), nhắc nợ cũ.
- Giao dịch định kỳ / tương lai: server quét 6 lần/ngày, sinh giao dịch trong khoảng 1–5h sáng giờ địa phương.
- Danh mục emoji + tuỳ chỉnh, **tự động phân loại** (`categorizeTransactions`), biểu đồ.
- Ảnh hoá đơn, xuất dữ liệu (Excel), nhập số dư có sẵn từ file hoặc thủ công (`importMemberBalances`).
- Lưu trữ / khôi phục / nhân bản nhóm (`archiveGroup`, `restoreGroup`, `cloneGroup`); cảnh báo nhóm lớn từ 1000 giao dịch.
- Lịch sử thay đổi, push notification khi có chi tiêu mới.
- Thông tin thanh toán của thành viên (tài khoản ngân hàng, Revolut, Cash App), QR SPAYD.
- Chương trình superuser / phần thưởng giới thiệu (mục tiêu 5 lượt), cộng đồng Discord.
- 18 server task: `activateEmptyGroupPremium`, `activateUserReward`, `archiveGroup`, `cancelSubscription`, `categorizeTransactions`, `cloneGroup`, `currencyChange`, `deleteArchivedGroup`, `deleteGroup`, `deleteUser`, `importMemberBalances`, `previewGroup`, `remindDebt`, `restoreGroup`, `updateExchangeRates`, `updateTransactionCategories`, `verifyGroupPremium`, `verifySubscription` (tài liệu còn nêu `deleteTransactions`, `calculateGroupsDebts`).

**Mô hình doanh thu** (giá web qua Stripe, USD, chụp ngày 2026-11-10)

| Gói | Giá |
|---|---|
| Premium cá nhân — tháng | 3,49 |
| Premium cá nhân — năm | 18,99 |
| Premium nhóm — 7 ngày | 5,49 |
| Premium nhóm — 31 ngày | 13,99 |
| Premium nhóm — 62 ngày | 27,99 |
| Premium nhóm — 1 năm | 34,99 |
| Premium nhóm — trọn đời | 134,99 |

- Hai trục: **premium cá nhân** (thuê bao) và **premium theo nhóm** (mua một lần theo thời hạn, hợp với chuyến đi; có thể chia tiền mua premium cho cả nhóm).
- Bản miễn phí có quảng cáo: video mỗi 3 lần thao tác (`video_ad_frequency = 3`), kèm màn hình mời nâng cấp trước quảng cáo.
- Premium mở: bỏ quảng cáo, ảnh hoá đơn, giao dịch định kỳ, danh mục tuỳ chỉnh, xuất file, tỉ giá, màu nhóm.
- Paywall, ưu đãi, màu sắc chiến dịch đều điều khiển từ Remote Config.

## 4. Kiến trúc

```
Web (Angular PWA) ─┐
Android ───────────┼─ Firebase SDK ─► Realtime Database ◄─ security rules (permissions/<group>/<uid>)
iOS ───────────────┘        │                 ▲
                            │                 │ trigger / hàng đợi serverTasks
                            ▼                 │
                    Auth · Storage · FCM   Cloud Functions ─► Stripe, email, tỉ giá, cron định kỳ
                    Remote Config · App Check
```

- **Client dày, server mỏng**: client ghi thẳng vào DB; server chỉ làm việc cần tin cậy (tính nợ, changes, thanh toán, xoá, định kỳ).
- **Mẫu hàng đợi tác vụ trên database**: client push `{request}` vào `/serverTasks/<task>`, function xử lý rồi ghi `progress` / `response`, client lắng nghe với timeout 20 giây. Không cần API gateway riêng.
- **Dữ liệu dẫn xuất do server sở hữu**: `debts`, `changes`, `lastChanged` client chỉ đọc.
- **Ghi nguyên tử đa nhánh** cho `permissions` + `userGroups` (chỉ mục hai chiều).
- **API công khai = REST của Firebase** + developer portal cấp key, sandbox trước rồi mới live.

**Ưu điểm:** realtime và offline gần như miễn phí, vận hành ít, chi phí thấp khi nhỏ, một backend cho 3 nền tảng.
**Nhược điểm:** truy vấn và báo cáo yếu (không JOIN, không aggregate), phải tải cả nhóm về client (nên mới có cảnh báo 1000 giao dịch), khoá chặt vào Firebase, logic nghiệp vụ lặp lại ở 3 client, security rules phức tạp.

## 5. Đề xuất cho sản phẩm của bạn (ý kiến của tôi, chưa phải quyết định)

**Giữ lại:** thành viên ảo, giao dịch `whoPaid` + `items[].forWhom` theo weight, tiền dạng thập phân chính xác, tỉ giá chụp theo giao dịch, 3 mức quyền, nhật ký thay đổi, premium theo nhóm.

**Nên làm khác:**
- **Postgres thay cho Realtime Database** (ví dụ Supabase: Postgres + Auth + Realtime + Storage + Row Level Security). Tính năng nâng cao như thống kê, tìm kiếm, ngân sách, báo cáo đều cần SQL.
- **Một codebase mobile** (Flutter hoặc React Native/Expo) thay vì 3 client riêng.
- **Sổ cái dạng bút toán**: mỗi giao dịch sinh các dòng nợ/có theo thành viên; số dư là tổng bút toán, dễ kiểm toán và test.
- **Thuật toán nợ**: tính số dư ròng từng người → chế độ tối giản dùng greedy ghép người nợ nhiều nhất với người được nợ nhiều nhất (tối đa n−1 lượt chuyển); chế độ không tối giản giữ nợ theo cặp. Đây là cách phổ biến, không phải thuật toán đã xác minh của Settle Up.

**Hướng tính năng vượt trội:**
- OCR hoá đơn bằng AI, tự tách món và gán người; nhập chi tiêu bằng giọng nói / ngôn ngữ tự nhiên.
- Thanh toán nội địa: **VietQR**, deep link MoMo / ZaloPay, tự đối soát khi đã chuyển.
- Ngân sách nhóm, quỹ chung, mục tiêu tiết kiệm; thống kê theo người / danh mục / thời gian.
- Bình luận và phản ứng trên giao dịch; duyệt chi tiêu; chi tiêu nháp.
- Bot Zalo / Telegram / Messenger để thêm chi tiêu ngay trong nhóm chat.
- Chế độ offline-first có giải quyết xung đột; nhóm lồng nhau (chuyến đi trong nhóm bạn).

## 6. Lưu ý pháp lý

Sao chép **ý tưởng, tính năng, luồng nghiệp vụ** là bình thường. Không dùng lại **mã nguồn, tên, logo, hình ảnh, bản dịch, nội dung** của Settle Up, và không dùng project Firebase hay API key live của họ cho sản phẩm của bạn. Nếu muốn tương thích (nhập dữ liệu từ Settle Up), hãy đi qua API công khai và developer portal của họ.

## Nguồn

- https://api.settleup.io/ — index, `entities/`, `operations/`, `intent/`, `examples/`
- https://settleup.app/ — bundle và network (REA)
- https://apps.apple.com/app/id737534985
- https://adapty.io/paywall-library/settle-up/
