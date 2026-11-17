# iOS interface stage run — progress

Written by the implementation agent during the run. See `docs/superpowers/plans/2026-11-16-ios-ui.md`.

For each task, under its heading: the approach note, the commit hash, the real output of the gate and the exercises with screenshot paths, and "Unresolved" if a check still fails after three fix attempts. Tick the box only when the task is committed.

- [x] U.0 Baseline
- [x] U.1 Project, package, domain basics, design system
- [x] U.2 Strings
- [x] U.3 Domain, repository protocols, scripted fakes
- [x] U.4 Shell, debug panel, sign-in
- [x] U.5 Groups, members, invites, account
- [x] U.6 The group screen
- [x] U.7 Entering and editing
- [x] U.8 Stage gate and hand-over

### U.0 Baseline

**Approach:** Verify worktree root, branch name (`ios-ui`), git baseline commit hash, installed Xcode/Swift/Simulator runtime versions, advisor deliverables, and re-baseline all web/contract source paths in `decisions.md` and `progress.md`.

**Checks:**
- Branch: `ios-ui`
- Worktree root: `/Users/hoojinguyen/Projects/songphang-ios-ui`
- `git rev-parse HEAD`: `bb1e0432fef6f1ceb4cf2ee960948129210626b2`
- `xcodebuild -version`:
  ```
  Xcode 27.2
  Build version 27B52
  ```
- `xcrun swift --version`:
  ```
  swift-driver version: 1.168.6 Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)
  Target: arm64-apple-macosx26.0
  ```
- `xcrun simctl list runtimes`:
  ```
  == Runtimes ==
  iOS 26.5 (26.5 - 23F77) - com.apple.CoreSimulator.SimRuntime.iOS-26-5
  ```
- Advisor deliverables confirmed present:
  - Branch `ios-ui` and worktree `../songphang-ios-ui`
  - `biome.json` and `.gitignore`
  - `apps/ios/AGENTS.md`
  - `docs/superpowers/runs/ios-ui/` (`progress.md`, `decisions.md`, `manual-checks.md`, `screens/`, `fixtures/` with 45 JSON files + `README.md`)
- **Commit:** `fc1218dc06057b3ded381d56ea35fe0b2d12abdf`

### U.1 Project, package, domain basics, design system

**Approach:** Write `apps/ios/SongPhang.xcodeproj` by hand with one application target (`App/` as a `PBXFileSystemSynchronizedRootGroup`), `Config/Debug.xcconfig` and `Config/Release.xcconfig` (`vn.songphang.app`, `Sòng Phẳng`), and local package `SongPhangKit` (`swift-tools-version: 6.2`, `.iOS(.v26)`, Swift 6 mode, warnings as errors, the 5 upcoming features, and `.defaultIsolation(MainActor.self)` on UI modules). Build `Domain` (`Money`, `AppError`, `Loadable`, `IdempotencyKey`, `MemberShape`, `MemberColor`), `DesignSystem` (`Tokens`, `Typography`, `MoneyFormat`, `MoneyText`, `MemberShapeView`, `SPButton`, `SPCard`, `LoadingSkeleton`, `LoadError`, `EmptyState`, `OfflineBanner`), `PreviewSupport` (`PreviewSamples`), and `AppShell` (`DebugGalleryView`, `RootView`).

**Gate output:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)
- Dependency rule proof (`import AppShell` added to `DesignSystem/Tokens/Tokens.swift`):
  ```
  error: Module dependency cycle: 'DesignSystem (Source Target) -> AppShell.swiftmodule -> DesignSystem.swiftmodule' (in target 'DesignSystem' from project 'SongPhangKit')
  ** BUILD FAILED **
  ```
  Removed `import AppShell` afterwards and verified clean build.

**Exercise results:**
- Exercised `DebugGalleryView` in iPhone 17 Pro (iOS 26.5 Simulator):
  - Money formatting verified:
    - `0` → `0\u{00A0}đ` (compact: `0`)
    - `1000` → `1.000\u{00A0}đ` (compact: `1`)
    - `150000` → `150.000\u{00A0}đ` (compact: `150`)
    - `999999999999` → `999.999.999.999\u{00A0}đ` (compact: `999.999.999.999`)
  - Color token comparison against `apps/web/src/app/globals.css`:
    | Token | Web (`globals.css`) | iOS (`Tokens.swift`) |
    |---|---|---|
    | `bg` | `#f6f2fb` | `Color(red: 0xF6/255, green: 0xF2/255, blue: 0xFB/255)` |
    | `surface` | `#ffffff` | `Color(red: 0xFF/255, green: 0xFF/255, blue: 0xFF/255)` |
    | `sunken` | `#e9e4f3` | `Color(red: 0xE9/255, green: 0xE4/255, blue: 0xF3/255)` |
    | `ink` | `#1c1b22` | `Color(red: 0x1C/255, green: 0x1B/255, blue: 0x22/255)` |
    | `ink-raised` | `#34323d` | `Color(red: 0x34/255, green: 0x32/255, blue: 0x3D/255)` |
    | `muted` | `#5a5766` | `Color(red: 0x5A/255, green: 0x57/255, blue: 0x66/255)` |
    | `on-ink-muted` | `#c9c5d6` | `Color(red: 0xC9/255, green: 0xC5/255, blue: 0xD6/255)` |
    | `dashed` | `#b9b3cc` | `Color(red: 0xB9/255, green: 0xB3/255, blue: 0xCC/255)` |
    | `accent` | `#ffd84d` | `Color(red: 0xFF/255, green: 0xD8/255, blue: 0x4D/255)` |
    | `debt-soft` | `#ffd9d1` | `Color(red: 0xFF/255, green: 0xD9/255, blue: 0xD1/255)` |
    | `mint` | `#9eebc0` | `Color(red: 0x9E/255, green: 0xEB/255, blue: 0xC0/255)` |
    | `sky` | `#9ccbff` | `Color(red: 0x9C/255, green: 0xCB/255, blue: 0xFF/255)` |
    | `coral` | `#ff8a73` | `Color(red: 0xFF/255, green: 0x8A/255, blue: 0x73/255)` |
    | `lilac` | `#d3b8ff` | `Color(red: 0xD3/255, green: 0xB8/255, blue: 0xFF/255)` |
    | `phrase-amount` | `#ffe99a` | `Color(red: 0xFF/255, green: 0xE9/255, blue: 0x9A/255)` |
    | `phrase-payer` | `#cfe3ff` | `Color(red: 0xCF/255, green: 0xE3/255, blue: 0xFF/255)` |
    | `phrase-split` | `#cff5df` | `Color(red: 0xCF/255, green: 0xF5/255, blue: 0xDF/255)` |
    | `phrase-rest` | `#e7d9ff` | `Color(red: 0xE7/255, green: 0xD9/255, blue: 0xFF/255)` |
  - Screenshots:
    - `docs/superpowers/runs/ios-ui/screens/u1-gallery-default.png`
    - `docs/superpowers/runs/ios-ui/screens/u1-gallery-shapes.png`
    - `docs/superpowers/runs/ios-ui/screens/u1-gallery-components.png`
    - `docs/superpowers/runs/ios-ui/screens/u1-gallery-ax5.png`
- **Commit:** `6e9bbb49e7a84e71b11c99f30d5703a125b322f2`

### U.2 Strings

**Approach:** Create `DesignSystem/Resources/Localizable.xcstrings` containing all 392 leaf keys of `apps/web/src/messages/vi.ts` (character-for-character identical) plus the 10 iOS-specific strings of P5 section 5.3 under `ios.*`. Expose `L10n` in `DesignSystem` backed by `Bundle.module`, and write `apps/ios/Scripts/check-strings.sh` to verify that no web key is missing or differing.

**Gate & script output:**
- `./apps/ios/Scripts/check-strings.sh`:
  ```
  OK: 392 web keys verified, 0 missing, 0 differing.
  ```
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)
- **Commit:** `446961afbb3eb3c4c2f57b3e67f1d263ac52dd95`

### U.3 Domain, repository protocols, scripted fakes

**Approach:** Define all domain models (`User`, `ServerFeatures`, `ExpenseGroup`, `Member`, `GroupUser`, `Role`, `Invite`, `InvitePreview`, `LedgerTransaction`, `TransactionDraft`, `SharePreview`, `Balance`, `SuggestedTransfer`, `GroupBalances`, `ActivityItem`, `QuickEntryReading`, `GroupEvent`, `Page`) and repository protocols (`AuthRepository`, `GroupsRepository`, `MembersRepository`, `InvitesRepository`, `TransactionsRepository`, `BalancesRepository`, `ActivityRepository`, `QuickEntryRepository`, `GroupEventsRepository`) in `Domain`. Implement `FakeWorld`, `FakeBehavior`, and all fake repositories in `PreviewSupport` (wrapped in `#if DEBUG`), with literal scenarios `EmptyScenario`, `TripScenario` (steps 0–4), `QuickEntryFixtures` (10 sentences), and `LargeScenario` (500 rows).

**Gate & checks:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)
- Search `PreviewSupport` for `/`, `*`, `%`, `.rounded`, `quotientAndRemainder`:
  ```
  $ grep -rnE "([/*%]|\.rounded|quotientAndRemainder)" apps/ios/SongPhangKit/Sources/PreviewSupport/ | grep -v "//"
  (no output)
  ```
- Scenario file to fixture mapping:
  | Scenario file | Transcribed from fixture files |
  |---|---|
  | `PreviewSupport/Scenarios/EmptyScenario.swift` | `01-me.json` |
  | `PreviewSupport/Scenarios/TripScenario.swift` | `01-me.json`, `03-group-create.json`, `04-groups.json`, `05-group.json`, `06-members.json`, `07-users.json`, `08-invite.json`, `09-step0-transactions.json`, `10-step0-balances.json`, `11-t1-preview.json`, `12-t1-create.json`, `13-step1-transactions.json`, `14-step1-balances.json`, `15-t2-preview.json`, `16-t2-create.json`, `17-step2-transactions.json`, `18-step2-balances.json`, `19-t3-preview.json`, `20-t3-create.json`, `21-step3-transactions.json`, `22-step3-balances.json`, `23-t4-preview.json`, `24-t4-create.json`, `25-step4-transactions.json`, `26-step4-balances.json`, `27-transaction-detail.json`, `28-activity.json`, `45-invite-preview.json` |
  | `PreviewSupport/Scenarios/QuickEntryFixtures.swift` | `29-parse-1.json` through `44-parse-10.json` |
  | `PreviewSupport/Scenarios/LargeScenario.swift` | `12-t1-create.json`, `16-t2-create.json`, `20-t3-create.json`, `24-t4-create.json`, `26-step4-balances.json` |
- Hand-checked 3 amounts per step against fixtures:
  - **Step 0 (`10-step0-balances.json` vs `TripScenario.step0Balances`):**
    - Minh balance: fixture `0` == `Money(0)`
    - Lan balance: fixture `0` == `Money(0)`
    - Hùng balance: fixture `0` == `Money(0)`
  - **Step 1 (`11-t1-preview.json`, `14-step1-balances.json` vs `TripScenario`):**
    - T1 Minh share: fixture `120000` == `Money(120_000)`
    - Step 1 Minh balance: fixture `180000` == `Money(180_000)`
    - Step 1 Lan → Minh transfer: fixture `100000` == `Money(100_000)`
  - **Step 2 (`15-t2-preview.json`, `18-step2-balances.json` vs `TripScenario`):**
    - T2 Minh share: fixture `480000` == `Money(480_000)`
    - Step 2 Minh balance: fixture `500000` == `Money(500_000)`
    - Step 2 Hùng → Minh transfer: fixture `320000` == `Money(320_000)`
  - **Step 3 (`19-t3-preview.json`, `22-step3-balances.json` vs `TripScenario`):**
    - T3 each share: fixture `50000` == `Money(50_000)`
    - Step 3 Minh balance: fixture `550000` == `Money(550_000)`
    - Step 3 Thu → Minh transfer: fixture `190000` == `Money(190_000)`
  - **Step 4 (`23-t4-preview.json`, `26-step4-balances.json` vs `TripScenario`):**
    - T4 Minh share: fixture `49999` == `Money(49_999)`
    - Step 4 Minh balance: fixture `500001` == `Money(500_001)`
    - Step 4 Hùng → Minh transfer: fixture `170001` == `Money(170_001)`
- **Commit:** `a38c27d8b435c33372af0686da05500c70af75be`

### U.4 Shell, debug panel, sign-in

**Approach:** Add `AuthFeature` target (`SignIn`, `Register`, `ForgotPassword`, `VerifyEmailBanner`) and `AppShell` navigation infrastructure (`AppDependencies` with `#if DEBUG` `scripted(world:)` and `#else` `#error("Live repositories arrive in the integration stage")`, `SessionModel`, `Route`, `RouteDestination`, `DebugPanel`, `RootView`). Port S1 (`/login`), `/register`, `/forgot-password`, and `VerifyEmailBanner` from `apps/web/src/app/login/page.tsx`, `register/page.tsx`, `forgot-password/page.tsx`, and `components/ui/VerifyEmailBanner.tsx`.

**Gate output:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)

**Exercise results:**
- Exercised S1 Sign-In (`Đăng nhập với Apple` above `Tiếp tục với Google`, email & password, links to register & forgot password):
  - Loaded state: `docs/superpowers/runs/ios-ui/screens/s1-signin-loaded.png`
  - Wrong password (`.api(code: "INVALID_CREDENTIALS", status: 401)` → `"Email hoặc mật khẩu không đúng."`): `docs/superpowers/runs/ios-ui/screens/s1-signin-wrong-password.png`
  - Rate limited (`.rateLimited` → `"Bạn thử quá nhiều lần. Đợi một lúc rồi thử lại."`): `docs/superpowers/runs/ios-ui/screens/s1-signin-rate-limited.png`
- Exercised Register flow:
  - Form state: `docs/superpowers/runs/ios-ui/screens/register-form.png`
  - Submitted end state (`"Kiểm tra hộp thư của bạn"`): `docs/superpowers/runs/ios-ui/screens/register-submitted.png`
- Exercised Forgot Password flow:
  - Form state: `docs/superpowers/runs/ios-ui/screens/forgot-password-form.png`
  - Submitted end state (`"Nếu email này có tài khoản, link đặt lại đã được gửi. Link có hiệu lực trong 1 giờ."`): `docs/superpowers/runs/ios-ui/screens/forgot-password-submitted.png`
- Exercised Verify Email Banner (`"Hãy xác minh email để tạo nhóm và ghi khoản chi."` + `"Gửi lại thư"`):
  - `docs/superpowers/runs/ios-ui/screens/verify-email-banner.png`
- Exercised Debug Panel (scenario, latency, snapshot, failure, role, realtime events, sign out):
  - `docs/superpowers/runs/ios-ui/screens/debug-panel.png`
- **Commit:** `52960b316abf2a8071b68afc5f6bf7747790f30d`

### U.5 Groups, members, invites, account

**Approach:** Add `GroupsFeature` (`GroupList`, `CreateGroup`, `Members`, `GroupSettings`, `Join`) and `AccountFeature` (`Account`), plus shared controls (`SPSegmentedControl`, `SPSwitch`, `SPQRCodeView` using Core Image `CIFilter.qrCodeGenerator()`, `NewMemberInputRow`) in `DesignSystem`. Persist screen models in `RouteDestination` `@State` so `@Observable` tracking works across async loads and actions.

**Gate output:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)

**Exercise results & screenshots:**
| Screen & State | Screenshot | Web source ported from | Differences & reason |
|---|---|---|---|
| S2 Group List — loading | `docs/superpowers/runs/ios-ui/screens/s2-groups-loading.png` | `apps/web/src/app/page.tsx` | None |
| S2 Group List — loaded | `docs/superpowers/runs/ios-ui/screens/s2-groups-loaded.png` | `apps/web/src/app/page.tsx`, `components/groups/FeaturedGroupCard.tsx`, `GroupCard.tsx` | Native pull-to-refresh added; debug toolbar button in `#if DEBUG` |
| S2 Group List — empty | `docs/superpowers/runs/ios-ui/screens/s2-groups-empty.png` | `apps/web/src/app/page.tsx` | None |
| S2 Group List — failed (no snapshot) | `docs/superpowers/runs/ios-ui/screens/s2-groups-failed.png` | `apps/web/src/app/page.tsx`, `components/ui/LoadError.tsx` | None |
| S2 Group List — stale (failure + snapshot) | `docs/superpowers/runs/ios-ui/screens/s2-groups-stale.png` | `apps/web/src/app/page.tsx`, `components/ui/OfflineBanner.tsx` | Content stays on screen with `OfflineBanner` at top and write button disabled |
| S3 Create Group — loaded | `docs/superpowers/runs/ios-ui/screens/s3-create-group-loaded.png` | `apps/web/src/app/groups/new/page.tsx`, `components/groups/NewGroupMembers.tsx`, `NewMemberRow.tsx` | None |
| S10 Members — loading | `docs/superpowers/runs/ios-ui/screens/s10-members-loading.png` | `apps/web/src/app/g/[groupId]/members/page.tsx` | None |
| S10 Members — owner | `docs/superpowers/runs/ios-ui/screens/s10-members-owner.png` | `apps/web/src/app/g/[groupId]/members/page.tsx`, `components/members/*` | QR code rendered with Core Image `CIFilter.qrCodeGenerator()`; share uses system `ShareLink`; remove-user confirmation uses iOS `.confirmationDialog` |
| S10 Members — editor | `docs/superpowers/runs/ios-ui/screens/s10-members-editor.png` | `apps/web/src/app/g/[groupId]/members/page.tsx` | Editor sees member edit, add member, invite card, and `Rời nhóm`, without owner `UserControls` or `Cài đặt nhóm` |
| S10 Members — viewer | `docs/superpowers/runs/ios-ui/screens/s10-members-viewer.png` | `apps/web/src/app/g/[groupId]/members/page.tsx` | Viewer has no write controls (`Thêm một cái tên`, member editor, invite card absent), sees `Rời nhóm` and `Lịch sử` |
| S10 Members — failed | `docs/superpowers/runs/ios-ui/screens/s10-members-failed.png` | `apps/web/src/app/g/[groupId]/members/page.tsx` | None |
| S10 Members — stale | `docs/superpowers/runs/ios-ui/screens/s10-members-stale.png` | `apps/web/src/app/g/[groupId]/members/page.tsx` | Snapshot remains visible with `OfflineBanner` |
| S11 Settings — loading | `docs/superpowers/runs/ios-ui/screens/s11-settings-loading.png` | `apps/web/src/app/g/[groupId]/settings/page.tsx` | None |
| S11 Settings — loaded (owner) | `docs/superpowers/runs/ios-ui/screens/s11-settings-loaded.png` | `apps/web/src/app/g/[groupId]/settings/page.tsx`, `components/settings/*` | Transfer ownership uses `.confirmationDialog`; delete group opens a `.sheet` with the group name confirmation field |
| S11 Settings — delete group sheet | `docs/superpowers/runs/ios-ui/screens/s11-settings-delete-sheet.png` | `apps/web/src/components/settings/DeleteGroupCard.tsx` | Native iOS `.sheet` in place of HTML `<dialog>` |
| S11 Settings — viewer forbidden | `docs/superpowers/runs/ios-ui/screens/s11-settings-viewer-forbidden.png` | `apps/web/src/app/g/[groupId]/settings/page.tsx` | Shows `"Bạn không có quyền làm việc này."` and `"Về danh sách nhóm"` |
| S11 Settings — failed | `docs/superpowers/runs/ios-ui/screens/s11-settings-failed.png` | `apps/web/src/app/g/[groupId]/settings/page.tsx` | None |
| S11 Settings — stale | `docs/superpowers/runs/ios-ui/screens/s11-settings-stale.png` | `apps/web/src/app/g/[groupId]/settings/page.tsx` | Snapshot remains visible with `OfflineBanner` |
| S12 Join — loading | `docs/superpowers/runs/ios-ui/screens/s12-join-loading.png` | `apps/web/src/app/join/[token]/page.tsx` | None |
| S12 Join — loaded | `docs/superpowers/runs/ios-ui/screens/s12-join-loaded.png` | `apps/web/src/app/join/[token]/page.tsx`, `components/join/JoinForm.tsx`, `ClaimGrid.tsx` | None |
| S12 Join — invalid token | `docs/superpowers/runs/ios-ui/screens/s12-join-invalid.png` | `apps/web/src/app/join/[token]/page.tsx` | None |
| S12 Join — failed | `docs/superpowers/runs/ios-ui/screens/s12-join-failed.png` | `apps/web/src/app/join/[token]/page.tsx` | None |
| S13 Account — loading | `docs/superpowers/runs/ios-ui/screens/s13-account-loading.png` | `apps/web/src/app/account/page.tsx` | None |
| S13 Account — loaded | `docs/superpowers/runs/ios-ui/screens/s13-account-loaded.png` | `apps/web/src/app/account/page.tsx`, `components/account/*` | Uses native `Toggle` for `Đăng xuất khỏi các thiết bị khác` |
| S13 Account — failed | `docs/superpowers/runs/ios-ui/screens/s13-account-failed.png` | `apps/web/src/app/account/page.tsx` | None |
| S13 Account — stale | `docs/superpowers/runs/ios-ui/screens/s13-account-stale.png` | `apps/web/src/app/account/page.tsx` | Snapshot remains visible with `OfflineBanner` |
- **Commit:** `0d6e8bc96cfb1da9d15560cac35e06c4613b74f5`

### U.6 The group screen

**Approach:** Add `LedgerFeature` target (`GroupFeed`, `Balances`, `Activity`, and `Shared/LedgerDateLabels.swift`) and wire `.groupFeed`, `.groupBalances`, and `.groupActivity` in `AppShell/RouteDestination.swift` and `RootView.swift`. `GroupFeedView` uses `LazyVStack` inside `ScrollViewReader` with value-driven row views (`FeedTransactionRowView`), concurrent loading of group, members, balances, and first transaction page after snapshot hydration, pagination on top scroll, and an async event loop (`changed`, `removed`, `reconnected`). `BalancesView` renders `OwnSettlementCardView`, `SettlementCardView`, `OtherSettlementsSection`, `AllSettledSection`, and `BalanceBarsSection` directly from repository amounts without any arithmetic on `Money`. `ActivityView` formats sentences and change chips identically to `apps/web/src/lib/activity-sentences.ts` and supports `Khôi phục`.

**Gate output:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)

**Exercise results & screenshots:**
- **S5 at step 4 of `trip` vs `26-step4-balances.json`:**
  - `docs/superpowers/runs/ios-ui/fixtures/26-step4-balances.json`:
    ```json
    {
      "currency": "VND",
      "minimized": true,
      "balances": [
        { "memberId": "1736b1cb-64ef-4c36-bd62-343f5990685b", "balance": 500001 },
        { "memberId": "3991e7a2-f583-4773-bd28-8e5cc53e8d71", "balance": -120000 },
        { "memberId": "63513328-c91d-4d91-b498-2f17d136b705", "balance": -170001 },
        { "memberId": "7508305b-c801-4cc6-bc00-fa1f1cd4eb41", "balance": -210000 }
      ],
      "transfers": [
        {
          "fromMemberId": "7508305b-c801-4cc6-bc00-fa1f1cd4eb41",
          "toMemberId": "1736b1cb-64ef-4c36-bd62-343f5990685b",
          "amount": 210000
        },
        {
          "fromMemberId": "63513328-c91d-4d91-b498-2f17d136b705",
          "toMemberId": "1736b1cb-64ef-4c36-bd62-343f5990685b",
          "amount": 170001
        },
        {
          "fromMemberId": "3991e7a2-f583-4773-bd28-8e5cc53e8d71",
          "toMemberId": "1736b1cb-64ef-4c36-bd62-343f5990685b",
          "amount": 120000
        }
      ]
    }
    ```
  - Rendered on S5 (`s5-balances-loaded.png` & `s5-balances-bars.png`):
    - Suggested transfers:
      1. `Thu trả bạn`: `210.000` (`210000`)
      2. `Hùng trả bạn`: `170.001` (`170001`)
      3. `Lan trả bạn`: `120.000` (`120000`)
    - Balance bars (`Cán cân của nhóm`):
      1. `Minh`: `+500.001` (`500001`)
      2. `Lan`: `−120.000` (`-120000`)
      3. `Hùng`: `−170.001` (`-170001`)
      4. `Thu`: `−210.000` (`-210000`)
- **Screenshots:**
  | Screen & State | Screenshot | Web source ported from | Differences & reason |
  |---|---|---|---|
  | S4 Group Feed — loading | `docs/superpowers/runs/ios-ui/screens/s4-feed-loading.png` | `apps/web/src/app/g/[groupId]/page.tsx` | None |
  | S4 Group Feed — loaded | `docs/superpowers/runs/ios-ui/screens/s4-feed-loaded.png` | `apps/web/src/app/g/[groupId]/page.tsx`, `components/feed/*` | Native `LazyVStack` inside `ScrollViewReader` |
  | S4 Group Feed — empty (`trip` step 0) | `docs/superpowers/runs/ios-ui/screens/s4-feed-empty.png` | `apps/web/src/components/feed/EmptyStream.tsx` | None |
  | S4 Group Feed — failed (no snapshot) | `docs/superpowers/runs/ios-ui/screens/s4-feed-failed.png` | `apps/web/src/app/g/[groupId]/page.tsx` | None |
  | S4 Group Feed — stale / offline | `docs/superpowers/runs/ios-ui/screens/s4-feed-stale.png` | `apps/web/src/app/g/[groupId]/page.tsx`, `components/feed/EntryBar.tsx` | Shows `OfflineBanner` at top and disabled entry bar `"Có mạng lại là gõ tiếp được"` |
  | S4 Group Feed — viewer | `docs/superpowers/runs/ios-ui/screens/s4-feed-viewer.png` | `apps/web/src/components/feed/EntryBar.tsx` | Shows read-only bar `"Chỉ xem"` and hides `"Mời bạn vào nhóm"` |
  | S4 Group Feed — `changed` event pill | `docs/superpowers/runs/ios-ui/screens/s4-feed-new-items-pill.png` | `apps/web/src/app/g/[groupId]/page.tsx`, `lib/use-group-events.ts` | Shows floating `"Có khoản mới"` pill when scrolled up |
  | S4 Group Feed — `removed` event to S2 | `docs/superpowers/runs/ios-ui/screens/s2-groups-removed-notice.png` | `apps/web/src/lib/use-group-events.ts`, `app/page.tsx` | Pops to group list and shows `"Bạn không còn ở trong nhóm này."` |
  | S4 Group Feed — `large` (500 rows) | `docs/superpowers/runs/ios-ui/screens/s4-feed-large.png` | `apps/web/src/app/g/[groupId]/page.tsx` | Paginates 500 rows in 50-item pages |
  | S5 Balances — loading | `docs/superpowers/runs/ios-ui/screens/s5-balances-loading.png` | `apps/web/src/app/g/[groupId]/balances/page.tsx` | None |
  | S5 Balances — loaded | `docs/superpowers/runs/ios-ui/screens/s5-balances-loaded.png` | `apps/web/src/app/g/[groupId]/balances/page.tsx`, `components/balances/*` | None |
  | S5 Balances — balance bars | `docs/superpowers/runs/ios-ui/screens/s5-balances-bars.png` | `apps/web/src/components/balances/BalanceBars.tsx` | Center-zero proportional bars rendered with custom `ProgressViewStyle` |
  | S5 Balances — empty | `docs/superpowers/runs/ios-ui/screens/s5-balances-empty.png` | `apps/web/src/app/g/[groupId]/balances/page.tsx` | None |
  | S5 Balances — all settled | `docs/superpowers/runs/ios-ui/screens/s5-balances-all-settled.png` | `apps/web/src/components/balances/AllSettled.tsx` | None |
  | S5 Balances — failed | `docs/superpowers/runs/ios-ui/screens/s5-balances-failed.png` | `apps/web/src/app/g/[groupId]/balances/page.tsx` | None |
  | S5 Balances — stale | `docs/superpowers/runs/ios-ui/screens/s5-balances-stale.png` | `apps/web/src/app/g/[groupId]/balances/page.tsx` | Snapshot remains visible with `OfflineBanner` |
  | S6 Activity — loading | `docs/superpowers/runs/ios-ui/screens/s6-activity-loading.png` | `apps/web/src/app/g/[groupId]/activity/page.tsx` | None |
  | S6 Activity — loaded | `docs/superpowers/runs/ios-ui/screens/s6-activity-loaded.png` | `apps/web/src/app/g/[groupId]/activity/page.tsx`, `components/activity/*` | None |
  | S6 Activity — restore button | `docs/superpowers/runs/ios-ui/screens/s6-activity-restore.png` | `apps/web/src/components/activity/ActivityRow.tsx` | Shows `"Khôi phục"` button on deleted transaction activity row |
  | S6 Activity — empty | `docs/superpowers/runs/ios-ui/screens/s6-activity-empty.png` | `apps/web/src/app/g/[groupId]/activity/page.tsx` | None |
  | S6 Activity — failed | `docs/superpowers/runs/ios-ui/screens/s6-activity-failed.png` | `apps/web/src/app/g/[groupId]/activity/page.tsx` | None |
  | S6 Activity — stale | `docs/superpowers/runs/ios-ui/screens/s6-activity-stale.png` | `apps/web/src/app/g/[groupId]/activity/page.tsx` | Snapshot remains visible with `OfflineBanner` |

**AD 8.3 measurements on `large` (500 transactions) in Simulator (`iPhone 17 Pro`, iOS 26.5):**
| Measure | Budget | Tool | Real output |
|---|---|---|---|
| Launch to first content, with a snapshot | under 400 ms | `xcrun xctrace record --template 'App Launch'` | `dyld-activity-interval` `Launch Executable`: **361.17 ms** (`361171916 ns` < `400 ms`). (`life-cycle-period` table is empty on Simulator; see Not verified) |
| Scrolling the 500-transaction feed top to bottom | no hitch reported | `xcrun xctrace` `SwiftUI` and `Animation Hitches` | Not verified via `Hitches` instrument on Simulator: `xcrun xctrace` exited with `* [Error] Hitches is not supported on this platform.` and standalone `SwiftUI` instrument reported `* [Warning] Trace file had no SwiftUI data`. Recorded under Not verified per AD 8.3 & AD 11. |
| Main-actor hangs during 500-row scroll | none over 100 ms | `xcrun xctrace record --instrument 'Hangs'` | `potential-hangs` (`hangs-threshold="100"`): **0 hangs** (`0 rows`). `hang-risks`: **0 rows**. |
| Group screen, tap to content, with a snapshot | same frame as push transition | Observed | **0 frames of skeleton** when `hasSnapshot == true`; `GroupFeedModel.load()` hydrates `state = .loaded(...)` from `lastKnown*` before the first suspension point. |
- **Commit:** `7192902206a2af58ff91e19b893774cdcbd9fd93`

### U.7 Entering and editing

**Approach:** Build `ConfirmCard/` (`HighlightedSentenceView`, `ShareShapesView`, `ConfirmationCardView`, `QuestionCardView`), `QuickEntry/` (`QuickEntryModel`, `QuickEntryView`), `SplitEditor/` (`SplitEditorState`, `SplitEditorView`), `ExpenseForm/` (`ExpenseFormModel`, `ExpenseFormSubViews`, `ExpenseFormView`), and `Settle/` (`SettleModel`, `SettleView`) inside `LedgerFeature`, and wire `.quickEntry`, `.newTransactionForm`, `.editTransaction`, and `.settle` in `AppShell`. While a share preview is pending (`isPreviewPending`), previous share numbers stay on screen dimmed (`opacity(0.45)`) and are never replaced by a local estimate; a failed or unscripted preview sets `previewError` and renders `common.loadError`. Every form model creates its `IdempotencyKey` in `init` (or per sentence in `QuickEntryModel`) so double-tapping `Lưu` submits the same key and produces one transaction. All four motions (confirmation card spring appearance, member shape resize spring, confirmation card collapse on save, settlement card spring on record) check `@Environment(\.accessibilityReduceMotion)` and disable animation when Reduce Motion is enabled.

**Gate output:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)
- Search `LedgerFeature` for `*`, `/`, `%`, `.rounded`, `quotientAndRemainder`: only date formatting strings in `LedgerDateLabels.swift` (`"%02d"`, `"\(day)/\(month)/\(year)"`); zero arithmetic operators on `Money`.

**Exercise results & screenshots:**
- **Ten scripted sentences (`29-parse-1.json` through `44-parse-10.json`):**
  | # | Sentence | Fixture status | Rendered card / form | Screenshot |
  |---|---|---|---|---|
  | 1 | `"cà phê 180k chia 4"` | `ok` (`29-parse-1.json`) | ConfirmationCard: `cà phê`, `180.000 đ`, `Bạn trả (mặc định)`, `Chia đều 4 người · 45.000 mỗi người`, 4 × `45.000`, spans `180k` (`phraseAmount`) + `chia 4` (`phraseSplit`) | `docs/superpowers/runs/ios-ui/screens/s7-parse-1.png` |
  | 2 | `"taxi 250k lan trả"` | `ok` (`31-parse-2.json`) | ConfirmationCard: `taxi`, `250.000 đ`, `Lan trả`, `Chia đều 4 người · 62.500 mỗi người`, 4 × `62.500`, spans `250k` (`phraseAmount`) + `lan trả` (`phrasePayer`) | `docs/superpowers/runs/ios-ui/screens/s7-parse-2.png` |
  | 3 | `"nước 100k chia lan, hùng, thu"` | `ok` (`33-parse-3.json`) | ConfirmationCard: `nước`, `100.000 đ`, `Bạn trả (mặc định)`, `Chia 3 người · khoảng 33.334 mỗi người`, Lan `33.334`, Hùng `33.333`, Thu `33.333`, `Không tính Minh.` | `docs/superpowers/runs/ios-ui/screens/s7-parse-3.png` |
  | 4 | `"lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều"` | `ok` (`35-parse-4.json`) | ConfirmationCard: `lẩu`, `300.000 đ`, `Minh trả`, `Riêng: Minh 80 · Lan 60 · Hùng 40`, `Còn 120.000 chia đều 3`, Minh `120.000`, Lan `100.000`, Hùng `80.000` | `docs/superpowers/runs/ios-ui/screens/s7-parse-4.png` |
  | 5 | `"kẹo 1001"` | `ok` (`37-parse-5.json`) | ConfirmationCard: `kẹo`, `1.001 đ`, `Bạn trả (mặc định)`, `Chia 4 người · khoảng 251 mỗi người`, Minh `251`, Lan `250`, Hùng `250`, Thu `250` | `docs/superpowers/runs/ios-ui/screens/s7-parse-5.png` |
  | 6 | `"chợ 500k thu trả, lan 200 thu 300"` | `ok` (`39-parse-6.json`) | ConfirmationCard: `chợ`, `500.000 đ`, `Thu trả`, `Riêng: Lan 200 · Thu 300`, Lan `200.000`, Thu `300.000`, `Không tính Minh, Hùng.` | `docs/superpowers/runs/ios-ui/screens/s7-parse-6.png` |
  | 7 | `"cà phê 180k chia 3"` | `needs_input` (`41-parse-7.json`) | QuestionCard (`COUNT_MISMATCH`): `cà phê`, `180.000 đ`, `3 người nào?`, `đã chọn 0 / 3`, 4 member candidates, button `Chọn thêm 3 người` | `docs/superpowers/runs/ios-ui/screens/s7-parse-7.png` |
  | 8 | `"180k"` | `needs_input` (`42-parse-8.json`) | QuestionCard (`DESCRIPTION_MISSING`): `180.000 đ`, 4 × `45.000`, prompt field `Khoản này chi cho việc gì?` | `docs/superpowers/runs/ios-ui/screens/s7-parse-8.png` |
  | 9 | `"cà phê"` | `unparsed` (`43-parse-9.json`) | Transitions to ExpenseForm with `UnparsedBanner`: `Mình chưa hiểu hết câu này`, `cà phê`, `Mình chưa thấy số tiền trong câu.` | `docs/superpowers/runs/ios-ui/screens/s7-parse-9.png` |
  | 10 | `"cà phê 180k chia 9"` | `unparsed` (`44-parse-10.json`) | Transitions to ExpenseForm with `UnparsedBanner`: `Mình chưa hiểu hết câu này`, `cà phê 180k chia 9`, `Nhóm chỉ có 4 người đang hoạt động.` | `docs/superpowers/runs/ios-ui/screens/s7-parse-10.png` |

- **Entering T1–T4 in order from step 0 of `trip` and comparing S5 against each step's balances fixture:**
  - **After T1 (`14-step1-balances.json` vs `s5-step1-balances.png` & `s5-step1-bars.png`):**
    - Fixture `14-step1-balances.json`:
      - Balances: Minh `180000`, Lan `-100000`, Hùng `-80000`, Thu `0`
      - Transfers: Lan → Minh `100000`, Hùng → Minh `80000`
    - Rendered on S5:
      - Transfers: `Lan trả bạn 100.000`, `Hùng trả bạn 80.000`
      - Balance bars: `Minh +180.000`, `Thu 0`, `Hùng −80.000`, `Lan −100.000`
  - **After T2 (`18-step2-balances.json` vs `s5-step2-balances.png` & `s5-step2-bars.png`):**
    - Fixture `18-step2-balances.json`:
      - Balances: Minh `500000`, Lan `60000`, Hùng `-320000`, Thu `-240000`
      - Transfers: Hùng → Minh `320000`, Thu → Minh `180000`, Thu → Lan `60000`
    - Rendered on S5:
      - Transfers: `Hùng trả bạn 320.000`, `Thu trả bạn 180.000`, `Thu trả Lan 60.000`
      - Balance bars: `Minh +500.000`, `Lan +60.000`, `Thu −240.000`, `Hùng −320.000`
  - **After T3 (`22-step3-balances.json` vs `s5-step3-balances.png` & `s5-step3-bars.png`):**
    - Fixture `22-step3-balances.json`:
      - Balances: Minh `550000`, Lan `-90000`, Hùng `-270000`, Thu `-190000`
      - Transfers: Hùng → Minh `270000`, Thu → Minh `190000`, Lan → Minh `90000`
    - Rendered on S5:
      - Transfers: `Hùng trả bạn 270.000`, `Thu trả bạn 190.000`, `Lan trả bạn 90.000`
      - Balance bars: `Minh +550.000`, `Lan −90.000`, `Thu −190.000`, `Hùng −270.000`
  - **After T4 (`26-step4-balances.json` vs `s5-step4-balances.png` & `s5-step4-bars.png`):**
    - Fixture `26-step4-balances.json`:
      - Balances: Minh `500001`, Lan `-120000`, Hùng `-170001`, Thu `-210000`
      - Transfers: Thu → Minh `210000`, Hùng → Minh `170001`, Lan → Minh `120000`
    - Rendered on S5:
      - Transfers: `Thu trả bạn 210.000`, `Hùng trả bạn 170.001`, `Lan trả bạn 120.000`
      - Balance bars: `Minh +500.001`, `Lan −120.000`, `Hùng −170.001`, `Thu −210.000`

- **Additional S8 / S9 screenshots:**
  | Screen & State | Screenshot | Web source ported from | Differences & reason |
  |---|---|---|---|
  | S8 Expense Form — new | `docs/superpowers/runs/ios-ui/screens/s8-expense-form-new.png` | `apps/web/src/components/expense-form/ExpenseForm.tsx` | Native `DatePicker` for occurredAt |
  | S8 Expense Form — edit T1 | `docs/superpowers/runs/ios-ui/screens/s8-expense-form-edit.png` | `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx`, `ExpenseForm.tsx` | None |
  | S8 Split Editor | `docs/superpowers/runs/ios-ui/screens/s8-split-editor.png` | `apps/web/src/components/expense-form/SplitEditor.tsx` | None |
  | S8 Expense Form — `.conflict` notice | `docs/superpowers/runs/ios-ui/screens/s8-expense-form-conflict.png` | `apps/web/src/components/expense-form/ConflictNotice.tsx` | Shows `"Minh vừa sửa khoản này."` and `"Xem bản mới"` button |
  | S4 Group Feed — delete + `Hoàn tác` toast | `docs/superpowers/runs/ios-ui/screens/s4-feed-deleted-undo.png` | `apps/web/src/components/expense-form/ExpenseForm.tsx`, `components/ui/Snackbar.tsx` | Shows `"Đã xoá."` + `"Hoàn tác"` pill above entry bar |
  | S9 Settle — loaded | `docs/superpowers/runs/ios-ui/screens/s9-settle-loaded.png` | `apps/web/src/app/g/[groupId]/settle/page.tsx`, `components/balances/SettlementForm.tsx` | None |
- **Commit:** `525f31b5946ef1e7019b6b3bea4b579c5c421896`

### U.8 Stage gate and hand-over

**Approach:** Execute all eight steps of the interface stage gate: run the automated gate and `check-strings.sh`; verify the full Phase 1 journey screenshots on `trip`; verify accessibility labels and capture all 13 screens at the largest accessibility Dynamic Type size (`accessibility-extra-extra-extra-large` / `AX5`); verify module dependencies in `Package.swift` against AD section 5 and confirm zero `import PreviewSupport` outside `#if DEBUG` / `#Preview` in the feature modules; verify the Release build fails at `AppShell/AppDependencies.swift` with `#error("Live repositories arrive in the integration stage")`; record AD 8.3 performance measurements on `large`; write `apps/ios/README.md`, `manual-checks.md`, and complete `"For the integration stage"`.

**Step 1 — Automated gate & string check:**
- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output (exit code 0)
- `./apps/ios/Scripts/check-strings.sh`:
  ```
  OK: 392 web keys verified, 0 missing, 0 differing.
  ```

**Step 2 — Phase 1 journey on `trip` in Simulator:**
- Sign-in (S1): `docs/superpowers/runs/ios-ui/screens/s1-signin-loaded.png`
- Create group (S3): `docs/superpowers/runs/ios-ui/screens/s3-create-group-loaded.png`
- Empty group stream (S4 step 0): `docs/superpowers/runs/ios-ui/screens/s4-feed-empty.png`
- Invite & members (S10): `docs/superpowers/runs/ios-ui/screens/s10-members-owner.png`
- Quick entry & confirmation cards (S7): `docs/superpowers/runs/ios-ui/screens/s7-parse-1.png` through `s7-parse-10.png`
- Manual form, split editor, edit & conflict (S8): `docs/superpowers/runs/ios-ui/screens/s8-expense-form-new.png`, `s8-expense-form-edit.png`, `s8-split-editor.png`, `s8-expense-form-conflict.png`
- Balances after each step T1–T4 (S5): `docs/superpowers/runs/ios-ui/screens/s5-step1-balances.png`, `s5-step2-balances.png`, `s5-step3-balances.png`, `s5-step4-balances.png`
- Delete & undo toast (S4): `docs/superpowers/runs/ios-ui/screens/s4-feed-deleted-undo.png`
- Activity & restore (S6): `docs/superpowers/runs/ios-ui/screens/s6-activity-loaded.png`, `s6-activity-restore.png`
- Settle transfer & all-settled state (S9 → S5): `docs/superpowers/runs/ios-ui/screens/s9-settle-loaded.png`, `s5-balances-all-settled.png`

**Step 3 — Accessibility & largest text size (`accessibility-extra-extra-extra-large` / `AX5`):**
- Accessibility audit of controls & labels:
  - `MemberShapeView`: `.accessibilityElement(children: .ignore)` with `.accessibilityLabel(name)` so every member shape announces the member's name instead of a raw shape or single initial letter.
  - `HighlightedSentenceView`: phrase spans expose `.accessibilityLabel("\(kindLabel): \(spanText)")` (`Số tiền`, `Người trả`, `Cách chia`, `Phần còn lại`).
  - `FeedTransactionRowView`: editable rows expose `.accessibilityLabel(L10n.t("feed.editRow", ["description": transaction.description]))`.
  - Icon-only buttons (`SPScreenHeader` back button, `QuickEntryView` send button, `SplitEditorView` back and remove-member buttons, `UnparsedBannerView` close button) expose explicit `.accessibilityLabel(...)` strings from `Localizable.xcstrings`.
  - All interactive controls maintain `minWidth: 44, minHeight: 44` hit targets (`SPButton`, `SPSegmentedControl`, `MemberToggleGridView`, `TypeSwitchView`, `CategoryPickerView`).
- Screenshots at `accessibility-extra-extra-extra-large` (`AX5`):
  - S1 Sign-In: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s1-signin.png`
  - S2 Group List: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s2-groups.png`
  - S3 Create Group: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s3-create-group.png`
  - S4 Group Feed: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s4-feed.png`
  - S5 Balances: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s5-balances.png`
  - S6 Activity: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s6-activity.png`
  - S7 Quick Entry: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s7-quick-entry.png`
  - S8 Expense Form: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s8-expense-form.png`
  - S9 Settle: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s9-settle.png`
  - S10 Members: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s10-members.png`
  - S11 Settings: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s11-settings.png`
  - S12 Join: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s12-join.png`
  - S13 Account: `docs/superpowers/runs/ios-ui/screens/u8-ax5-s13-account.png`

**Step 4 — Architecture check (Review Focus 2):**
- Target `dependencies` in `apps/ios/SongPhangKit/Package.swift` vs AD section 5:
  | Target | AD section 5 `dependencies` | `Package.swift` `dependencies` | Match |
  |---|---|---|---|
  | `Domain` | `[]` | `[]` | Identical |
  | `DesignSystem` | `["Domain"]` | `["Domain"]` | Identical |
  | `PreviewSupport` | `["Domain"]` | `["Domain"]` | Identical |
  | `AuthFeature` | `["Domain", "DesignSystem", "PreviewSupport"]` | `["Domain", "DesignSystem", "PreviewSupport"]` | Identical |
  | `GroupsFeature` | `["Domain", "DesignSystem", "PreviewSupport"]` | `["Domain", "DesignSystem", "PreviewSupport"]` | Identical |
  | `LedgerFeature` | `["Domain", "DesignSystem", "PreviewSupport"]` | `["Domain", "DesignSystem", "PreviewSupport"]` | Identical |
  | `AccountFeature` | `["Domain", "DesignSystem", "PreviewSupport"]` | `["Domain", "DesignSystem", "PreviewSupport"]` | Identical |
  | `AppShell` | `["Domain", "DesignSystem", "PreviewSupport", "AuthFeature", "GroupsFeature", "LedgerFeature", "AccountFeature"]` (plus `Repositories` in integration stage) | `["Domain", "DesignSystem", "PreviewSupport", "AuthFeature", "GroupsFeature", "LedgerFeature", "AccountFeature"]` | Identical for interface-stage modules |
- Search `AuthFeature`, `GroupsFeature`, `LedgerFeature`, `AccountFeature` for `import PreviewSupport`:
  Every single occurrence (16 view files) is inside `#if DEBUG` guarding `#Preview` blocks, and zero occurrences exist in any `*Model.swift` or outside `#if DEBUG` (additionally proven by the Release build compiling all four feature modules cleanly).

**Step 5 — Release check (Review Focus 5):**
- Command:
  ```bash
  xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -configuration Release -destination 'generic/platform=iOS Simulator' build
  ```
- Real output:
  ```
  /Users/hoojinguyen/Projects/songphang-ios-ui/apps/ios/SongPhangKit/Sources/AppShell/AppDependencies.swift:36:12: error: Live repositories arrive in the integration stage (in target 'AppShell' from project 'SongPhangKit')
  ** BUILD FAILED **
  ```

**Step 6 — AD 8.3 performance measures on `large`:**
- Recorded under Task U.6 above:
  - `App Launch` (`dyld-activity-interval` `Launch Executable`): **361.17 ms** (budget: `< 400 ms`).
  - `Hangs` (`potential-hangs` with 100 ms threshold during 500-row scroll): **0 hangs**, **0 hang risks**.
  - Group screen tap-to-content with snapshot: **0 skeleton frames** (hydrates synchronously before first network await).
  - `Hitches` / `SwiftUI` instruments on Simulator: recorded under `Not verified` with exact `xctrace` CLI error.

## Gate not passed

None. Every automated gate (`xcodebuild ... SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`, `xcrun swift-format lint --strict --recursive apps/ios`, `./apps/ios/Scripts/check-strings.sh`, and the Release `#error` check) passed.

## Not verified

- **Be Vietnam Pro bundled font registration on iOS:** `apps/web/public/fonts/be-vietnam-pro/` contains only `.woff2` web font files, which iOS cannot register directly, and downloading `.ttf`/`.otf` files from the network is forbidden in this run (see decision D1). `Typography.swift` uses the iOS system font with Dynamic Type text styles.
- **`xctrace` `Hitches`, `SwiftUI`, and `life-cycle-period` instruments on iOS Simulator:** running `xcrun xctrace record --template 'Animation Hitches'` and `xcrun xctrace record --template 'SwiftUI'` against the iOS Simulator fails with `* [Error] Hitches is not supported on this platform.`, `xcrun xctrace record --instrument 'SwiftUI'` completes with `* [Warning] Trace file had no SwiftUI data`, and the `life-cycle-period` table in `--template 'App Launch'` emits `* [Warning] This configuration of instruments creates 1 table without a known input source` (while `dyld-activity-interval` records `361.17 ms`). Real-device cold start, scrolling hitch rate, and battery measurements require a physical iPhone.
- **Interactive VoiceOver rotor and Accessibility Inspector GUI audit:** VoiceOver labels, traits, grouping, hit-target sizes (≥ 44×44 pt), and `AX5` Dynamic Type layouts were verified in code and via `simctl` screenshots (`u8-ax5-s1-signin.png` through `u8-ax5-s13-account.png`), but interactive VoiceOver swipe navigation with audio output requires manual verification by the project owner.

## Out of scope

- None observed in `apps/web` or `packages/`.

## For the integration stage

### 1. Web baseline commit hash
- **`bb1e0432fef6f1ceb4cf2ee960948129210626b2`** (`feat(phase-1): complete core expense splitting`)
- Before starting the integration stage, run:
  ```bash
  git diff bb1e0432fef6f1ceb4cf2ee960948129210626b2..main -- packages/contract apps/web/src/messages/vi.ts apps/web/src/app apps/web/src/components
  ```
  to identify any contract or web UI changes landed after this baseline.

### 2. Domain guesses checklist
From `decisions.md`:
- **DG1 — Server feature flags (`GET /api/v1/auth/features` vs P5 section 5.3):**
  - The baseline web contract (`packages/contract/src/auth.ts`) does not yet define a `/auth/features` schema, while P5 section 5.3 specifies `AuthRepository.serverFeatures() -> ServerFeatures` (`googleEnabled: Bool`, `appleEnabled: Bool`). Stage 5A adds this endpoint; verify its exact JSON property names when wiring `GeneratedAPI` in `Repositories`.
- **DG2 — Apple sign-in and Google sign-in repository methods:**
  - Per Task U.3 instructions, `AuthRepository` currently has `signInWithGoogle()` and `signInWithApple()` taking no parameters so S1 can exercise sign-in against `FakeWorld`. In the integration stage, split or parameterize them with the Apple identity token / nonce (`ASAuthorizationAppleIDCredential`) and Google OAuth code (`ASWebAuthenticationSession`).
- **DG3 — `ActivityItem.SnapshotValues` typed fields:**
  - On the web (`packages/contract/src/activity.ts`), `before` and `after` are untyped `z.record(z.string(), z.unknown()).nullable()`. In `Domain/Models/ActivityItem.swift`, `SnapshotValues` models the exact keys read by `apps/web/src/lib/activity-sentences.ts` (`transactionType`, `amount`, `description`, `occurredAt`, `category`, `payers`, `shares`, `split`, `name`, `defaultWeight`, `active`, `role`, `defaultRole`, `minimizeDebts`, `inviteActive`, `inviteRotated`, `memberCount`). When mapping `GeneratedAPI` in `Repositories/Activity`, decode those known keys from the raw JSON object into `ActivityItem.SnapshotValues`.

### 3. Screen-to-web source mapping
| Screen | iOS module & files | Web files ported from |
|---|---|---|
| S1 Sign-In | `AuthFeature/SignIn/{SignInModel,SignInView}.swift` | `apps/web/src/app/login/page.tsx` |
| Register | `AuthFeature/Register/{RegisterModel,RegisterView}.swift` | `apps/web/src/app/register/page.tsx` |
| Forgot Password | `AuthFeature/ForgotPassword/{ForgotPasswordModel,ForgotPasswordView}.swift` | `apps/web/src/app/forgot-password/page.tsx` |
| Verify Email Banner | `AuthFeature/VerifyEmailBanner/VerifyEmailBannerView.swift` | `apps/web/src/components/ui/VerifyEmailBanner.tsx` |
| S2 Group List | `GroupsFeature/GroupList/{GroupListModel,GroupListView}.swift` | `apps/web/src/app/page.tsx`, `components/groups/{FeaturedGroupCard,GroupCard}.tsx` |
| S3 Create Group | `GroupsFeature/CreateGroup/{CreateGroupModel,CreateGroupView}.swift` | `apps/web/src/app/groups/new/page.tsx`, `components/groups/{NewGroupMembers,NewMemberRow}.tsx` |
| S4 Group Feed | `LedgerFeature/GroupFeed/{GroupFeedModel,GroupFeedView,GroupFeedSubViews}.swift` | `apps/web/src/app/g/[groupId]/page.tsx`, `components/feed/*`, `lib/use-group-events.ts` |
| S5 Balances | `LedgerFeature/Balances/{BalancesModel,BalancesView}.swift` | `apps/web/src/app/g/[groupId]/balances/page.tsx`, `components/balances/{AllSettled,BalanceBars,OtherSettlements,OwnSettlementCard,SettlementCard}.tsx` |
| S6 Activity | `LedgerFeature/Activity/{ActivityModel,ActivitySentenceFormatter,ActivityView}.swift` | `apps/web/src/app/g/[groupId]/activity/page.tsx`, `components/activity/{ActivityRow,ChangeChips}.tsx`, `lib/activity-sentences.ts` |
| S7 Quick Entry & Confirm Card | `LedgerFeature/QuickEntry/{QuickEntryModel,QuickEntryView}.swift`, `LedgerFeature/ConfirmCard/*` | `apps/web/src/app/g/[groupId]/tx/new/{page,ComposeScreen}.tsx`, `components/quick-entry/*` |
| S8 Expense Form & Split Editor | `LedgerFeature/ExpenseForm/{ExpenseFormModel,ExpenseFormView,ExpenseFormSubViews}.swift`, `LedgerFeature/SplitEditor/*` | `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx`, `components/expense-form/*` |
| S9 Settle | `LedgerFeature/Settle/{SettleModel,SettleView}.swift` | `apps/web/src/app/g/[groupId]/settle/page.tsx`, `components/balances/SettlementForm.tsx` |
| S10 Members & Invites | `GroupsFeature/Members/{MembersModel,MembersView,MembersSubViews}.swift` | `apps/web/src/app/g/[groupId]/members/page.tsx`, `components/members/*` |
| S11 Group Settings | `GroupsFeature/GroupSettings/{GroupSettingsModel,GroupSettingsView}.swift` | `apps/web/src/app/g/[groupId]/settings/page.tsx`, `components/settings/*` |
| S12 Join Group | `GroupsFeature/Join/{JoinModel,JoinView}.swift` | `apps/web/src/app/join/[token]/page.tsx`, `components/join/{JoinForm,ClaimGrid}.tsx` |
| S13 Account | `AccountFeature/Account/{AccountModel,AccountView}.swift` | `apps/web/src/app/account/page.tsx`, `components/account/*` |

### 4. What was intentionally not built in Stage 5U (arrives in Integration Stage)
- `GeneratedAPI` and `Repositories` targets in `SongPhangKit/Package.swift` (OpenAPI code generation, `URLSession` transport, Keychain bearer token storage, on-disk JSON snapshots in `Application Support/snapshots/`, SSE client for `/events`, and `NWPathMonitor`).
- Live `AppDependencies.live(...)` constructor in `AppShell/AppDependencies.swift` (replacing the `#error("Live repositories arrive in the integration stage")` in `#else`).
- Native `ASAuthorizationController` (Sign in with Apple) and `ASWebAuthenticationSession` (Google OAuth) system sheets.
- Deep-link routing from `/verify-email?token=...` and `/reset-password?token=...` universal links, push notification registration, home-screen quick actions, and `.ttf` font files for Be Vietnam Pro.

