# Wave 5.5B — Stage 5.5B.3: iOS (`SongPhangKit`) Parity Implementation

> Runs in Wave 2 in parallel with Stage `5.5B.2` (`web`) **after** Stage `5.5B.1` is merged onto `phase-5-5b`. Touch **only** `apps/ios/**` (do not edit `Localizable.xcstrings`, which was locked in `5.5B.1.4` and verified by `check-strings.sh`). Obey every rule in `apps/ios/AGENTS.md` — features never import other features, `Repositories`, or `GeneratedAPI`; `Money` never multiplies, divides, or converts to floating-point.

### Task 5.5B.3.1: `Domain` models & repository protocols, `Repositories` live/guest mappings, and `PreviewSupport`

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/Domain/Models/{PaymentChannel,SettlementVault,SettlementCycle,MemberDebtBreakdown,GuestLink}.swift`
- Create: `apps/ios/SongPhangKit/Sources/Domain/Repositories/{SettlementCyclesRepository,GuestLinksRepository}.swift`
- Create: `apps/ios/SongPhangKit/Sources/Repositories/Balances/{LiveSettlementVaultMapping,LiveSettlementCyclesRepository,LiveMemberBreakdownsMapping}.swift`
- Create: `apps/ios/SongPhangKit/Sources/Repositories/Groups/LiveGuestLinksRepository.swift`
- Create: `apps/ios/SongPhangKit/Sources/PreviewSupport/Fakes/{FakeSettlementCyclesRepository,FakeGuestLinksRepository}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Domain/Models/{Balance,LedgerTransaction,TransactionDraft,TransactionFilter,GroupEvent,AppError}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Domain/Repositories/{AttachmentsRepository,BalancesRepository,SettlementRequestsRepository,TransactionsRepository}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Attachments/LiveAttachmentsRepository.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Balances/{BalanceMapping,LiveBalancesRepository,LiveSettlementRequestsRepository}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Transactions/LiveTransactionsRepository.swift`
- Modify: `apps/ios/SongPhangKit/Sources/Repositories/Realtime/` (map `"settlementCycles"` SSE resource)
- Modify: `apps/ios/SongPhangKit/Sources/PreviewSupport/{Fakes,Samples,Scenarios}/` (update existing fakes/samples with literal server values)
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift`

**Interfaces:**
- Consumes: Locked `packages/contract/openapi.json` (`GeneratedAPI` regenerates automatically during Xcode build).
- Produces:
  - `Domain` types: `PaymentChannel` (`bank`, `momo`, `zalopay`, `cash`, unknown fallback), `SettlementVaultPage` / `SettlementVaultItem` / `SettlementVaultSummary`, `SettlementCycle` / `CurrentPeriodSummary`, `MemberBreakdownsResult` / `MemberDebtBreakdown`, `GuestLink`, `GuestGroupView`, `AttachmentUploadPurpose` (`.expense`, `.transferProof`), `accountQrPayload` on bank `PaymentDestination`, `firstAttachmentId`/`paymentChannel`/`paymentNote`/`cycleId` on `LedgerTransaction`, `cycleId` on `TransactionFilter`.
  - Unauthenticated HTTP calls in `LiveGuestLinksRepository` (`fetchGuestGroup(token:cycleId:cursor:)` and `fetchGuestAttachmentData(token:attachmentId:)`) that work with or without a Keychain session token.
  - Updated `AppDependencies` wiring live and preview repositories.

- [ ] **Step 1: Add `Domain` models, `GroupEvent.Resource.settlementCycles`, `AppError` codes (`cycleEmpty`, `cycleNotLatest`), and repository protocol extensions**
  Keep `Domain` importing `Foundation` only (`apps/ios/AGENTS.md` §3).
- [ ] **Step 2: Implement `Repositories` OpenAPI mappings, `purpose` query on `LiveAttachmentsRepository`, and unauthenticated `LiveGuestLinksRepository`**
  Map unknown enum cases safely; ensure `LiveGuestLinksRepository` never attaches or requires Keychain auth headers on `/api/v1/guest-links/{token}*`.
- [ ] **Step 3: Add `PreviewSupport` fakes and literal sample fixtures and wire `AppDependencies`**
  Follow `apps/ios/AGENTS.md` §5: fakes return transcribed server integer literals and perform zero split/balance arithmetic.
- [ ] **Step 4: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  Run `xcrun swift-format lint --strict --recursive apps/ios` and `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`, then commit:
  `git commit -m "feat(ios): add domain models and live repositories for wave 5.5b"`

---

### Task 5.5B.3.2: `DesignSystem` proof/channel components, optional proof/channel/note in `PayView` & `SettleView`, and feed Transfer badge

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/DesignSystem/Components/{ChannelPillPicker,ProofBadgeView,TransferProofInputSection,QRCodeMatrixRenderer}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/PaymentsFeature/Pay/{PayModel,PayView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/Settle/{SettleModel,SettleView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/BalancesView.swift` (pending request row proof thumbnail + channel/note)
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/` (transfer card proof badge & channel/note subtitle)
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/TransactionDetail/` (render `paymentChannel` & `paymentNote` on transfers)
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/{GroupContainerView,RouteDestination}.swift` (inject `AttachmentsRepository` upload closure into `PayModel`/`SettleModel`)

**Interfaces:**
- Consumes: `Domain` types from `5.5B.3.1` and locked `Localizable.xcstrings` keys from `5.5B.1.4`.
- Produces:
  - Shared `DesignSystem` views (`ChannelPillPicker`, `ProofBadgeView`, `TransferProofInputSection`, `QRCodeMatrixRenderer` using `CIQRCodeGenerator` safe for both live views and offscreen `ImageRenderer`) usable by both `PaymentsFeature` and `LedgerFeature` without cross-feature imports.
  - Optional `PhotosPicker` proof upload (`purpose: .transferProof` in `PayModel`, `.expense`/transfer attachment in `SettleModel`), channel pills, and 120-char note in `PayView` and `SettleView` with 1-tap submit preserved when empty.
  - Proof thumbnail lightbox on pending settlement rows and `28pt` proof badge on Transfer cards in `GroupFeedView`.

- [ ] **Step 1: Build shared `DesignSystem` components (`ChannelPillPicker`, `ProofBadgeView`, `TransferProofInputSection`, `QRCodeMatrixRenderer`)**
  Ensure full Dynamic Type scaling, VoiceOver labels, and Light/Dark semantic `Tokens` contrast.
- [ ] **Step 2: Extend `PayModel`/`PayView` and `SettleModel`/`SettleView` with optional proof upload, channel, and note**
  Compress selected `PhotosPickerItem` JPEG `<= 5 MiB` off the main actor; keep primary CTA enabled immediately with zero required proof fields; add `#Preview` states.
- [ ] **Step 3: Add proof thumbnail & channel/note display to `PendingRequest` rows, `GroupFeed` Transfer cards, and `TransactionDetail`**
  Keep currency amounts single-line `.monospacedDigit()` on `375pt` width.
- [ ] **Step 4: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  `git commit -m "feat(ios): add optional transfer proofs, payment channels, and proof badges"`

---

### Task 5.5B.3.3: `BalancesView` 3-pill sub-navigation (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`), Member Breakdown sheet & `Chi tiêu` cycle chip

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/{SettlementVaultSectionView,SettlementCyclesSectionView,CloseCycleSheetView,MemberBreakdownSheetView}.swift`
- Create: `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/CycleFilterChipView.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/{BalancesModel,BalancesView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/{GroupFeedModel,GroupFeedView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/GroupContainerView.swift`

**Interfaces:**
- Consumes: `SettlementCyclesRepository`, `BalancesRepository` (`fetchBreakdowns` & `fetchSettlementVault`), and `GroupEvent.Resource.settlementCycles`.
- Produces:
  - 3-pill sub-navigation in `BalancesView` (`Cần thanh toán` | `Sổ thanh toán` | `Đợt đã chốt`) with Quick Action Bar (`Xuất ảnh / Nhắc nợ`, `Link khách`, `Chốt đợt`), Vault filter chips + proof lightbox, Cycles closeout snapshot (`Số liệu tại thời điểm chốt`) + owner `"Mở lại đợt này"`, and `MemberBreakdownSheetView` (including `Phân bổ thanh toán` reconciliation).
  - `CycleFilterChipView` in `GroupFeedView` (hidden when `cycles.isEmpty`, defaulting to `.current` when `!cycles.isEmpty`) + cross-segment jump from `Đợt đã chốt` -> `Chi tiêu` wired in `GroupContainerView`.

- [ ] **Step 1: Extend `BalancesModel` to load Vault, Cycles, and Member Breakdowns concurrently and refresh on `.settlementCycles` / `.settlementRequests` / `.transactions` SSE events**
  Follow `apps/ios/AGENTS.md` §6: start independent reads together in `.task`, preserve shown content on refresh failure.
- [ ] **Step 2: Build `SettlementVaultSectionView`, `SettlementCyclesSectionView`, `CloseCycleSheetView`, and `MemberBreakdownSheetView` inside `LedgerFeature/Balances/`**
  Include `#Preview` states (`loading`, `loaded`, `empty`, `failed`) on new screens/sheets.
- [ ] **Step 3: Add `CycleFilterChipView` to `GroupFeedView`/`GroupFeedModel` and wire cycle-jump callback in `GroupContainerView`**
  Default feed query to `cycleId = "current"` once closed cycles exist; allow switching to any closed cycle (where `owner`/`editor` swipe/edit actions still work per owner decision) or `Tất cả các đợt`.
- [ ] **Step 4: Run `swift-format` and Simulator Debug `xcodebuild`, then commit**
  `git commit -m "feat(ios): add settlement vault, closeout cycles, breakdown sheet, and cycle filter chip"`

---

### Task 5.5B.3.4: Guest Link sheet, zero-login `/share/{token}` routing + `GuestGroupView`, and `ImageRenderer` (`3x`) Share Card Export & Stage 5.5B.3 Gate

**Files:**
- Create: `apps/ios/SongPhangKit/Sources/DesignSystem/Components/ShareCardCanvasView.swift`
- Create: `apps/ios/SongPhangKit/Sources/LedgerFeature/Balances/ShareCardPreviewSheet.swift`
- Create: `apps/ios/SongPhangKit/Sources/GroupsFeature/GuestShare/{GuestLinkSheetModel,GuestLinkSheetView,GuestGroupModel,GuestGroupView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/GroupsFeature/Members/MembersView.swift` (entry to `GuestLinkSheetView` for `owner`/`editor`)
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/{Route,RootView,RouteDestination,GroupContainerView}.swift`
- Modify: `apps/ios/SongPhangKit/Sources/AppShell/Routing/LinkRouter.swift`

**Interfaces:**
- Consumes: `GuestLinksRepository`, `QRCodeMatrixRenderer`, `MemberBreakdownsResult`, `BalancesResponse`.
- Produces:
  - `GuestLinkSheetView` presented from `Thanh toán` Quick Action Bar (via `GroupContainerView`) and `MembersView` (`S10`), supporting enable, copy URL, rotate, and revoke (allowed even on archived groups).
  - `Route.guestShare(token: String)` parsed in `LinkRouter.route(for:)` for `/share/{token}` (`32..64` base64url chars) and presented directly by `RootView` **without requiring login** (`isSignedIn == false` or `true`), rendering `GuestGroupView` with VietQR, member breakdown sheet, cycle picker, and read-only expense detail + receipt photo viewer.
  - `ShareCardCanvasView` (`DesignSystem`, `390pt` fixed width, unbounded vertical height, Light & Dark `Tokens` via `.environment(\.colorScheme, selectedScheme)`, exact integer `MoneyText` with zero rounding) + `ShareCardPreviewSheet` rendering `UIImage` via `ImageRenderer` (`scale = 3.0`) wired to native `ShareLink` / `UIActivityViewController` and `"Lưu vào Ảnh"`.

- [ ] **Step 1: Add `.guestShare(token:)` to `Route` & `LinkRouter` and build `GuestLinkSheetView` + `GuestGroupView` in `GroupsFeature/GuestShare/`**
  Ensure `RootView` presents `.guestShare(token:)` immediately when signed out instead of queuing in `PendingInviteState`.
- [ ] **Step 2: Build `ShareCardCanvasView` (`DesignSystem`) and `ShareCardPreviewSheet` (`LedgerFeature/Balances/`)**
  Support `Tổng kết nhóm` (optional expense digest + static `accountQrPayload` QR) and `Nhắc nợ khéo` (`Tất cả` or 1-debtor with itemized breakdown + `Phân bổ thanh toán` + dynamic `qrPayload` QR), Light/Dark card toggle, and `ImageRenderer` (`scale = 3.0`) PNG export.
- [ ] **Step 3: Wire `GuestLinkSheetView` and `ShareCardPreviewSheet` into `GroupContainerView` / `BalancesView` / `MembersView`**
  Keep feature modules strictly isolated (`GroupsFeature` and `LedgerFeature` never import each other; `GroupContainerView` in `AppShell` presents `GuestLinkSheetView` when tapped from `Thanh toán`).
- [ ] **Step 4: Run Stage 5.5B.3 iOS Gate & Simulator exercises**
  Run `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, and Simulator Debug `xcodebuild`. Boot iOS Simulator against local API, exercise 16-member group (`375pt`/compact portrait + accessibility Dynamic Type), capture screenshots of: (a) `Thanh toán` 3-pill `Cần thanh toán` / `Sổ thanh toán` / `Đợt đã chốt`, (b) `MemberBreakdownSheetView`, (c) signed-out `/share/{token}` `GuestGroupView` via `xcrun simctl openurl`, and (d) Light & Dark `ShareCardPreviewSheet` rendered PNGs.
- [ ] **Step 5: Commit**
  `git commit -m "feat(ios): add guest share links, zero-login guest view, and 3x share card export"`
