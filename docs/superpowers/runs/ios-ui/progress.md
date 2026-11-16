# iOS interface stage run — progress

Written by the implementation agent during the run. See `docs/superpowers/plans/2026-11-16-ios-ui.md`.

For each task, under its heading: the approach note, the commit hash, the real output of the gate and the exercises with screenshot paths, and "Unresolved" if a check still fails after three fix attempts. Tick the box only when the task is committed.

- [x] U.0 Baseline
- [x] U.1 Project, package, domain basics, design system
- [x] U.2 Strings
- [x] U.3 Domain, repository protocols, scripted fakes
- [x] U.4 Shell, debug panel, sign-in
- [ ] U.5 Groups, members, invites, account
- [ ] U.6 The group screen
- [ ] U.7 Entering and editing
- [ ] U.8 Stage gate and hand-over

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

## Gate not passed

## Not verified

- Be Vietnam Pro bundled font registration on iOS: `apps/web/public/fonts/be-vietnam-pro/` contains only `.woff2` files, which iOS cannot register directly, and downloading `.ttf`/`.otf` files is forbidden in this run (see decision D1). The app uses the system font with Dynamic Type scaling.

## Out of scope

## For the integration stage
