# Sòng Phẳng — iOS Application (`apps/ios`)

Native iOS 26 application for Sòng Phẳng, built with Swift 6 and SwiftUI around the modular `SongPhangKit` local Swift package.

## Requirements

- macOS with **Xcode 26 or newer** (verified on Xcode 27.2 / Swift 6.4.2)
- An **iOS 26 or newer** Simulator runtime (verified on iOS 26.5 Simulator)
- `swift-format` (bundled with the Xcode toolchain via `xcrun swift-format`)

## Project Structure

```text
apps/ios/
├── SongPhang.xcodeproj       # Single-target Xcode project (PBXFileSystemSynchronizedRootGroup for App/)
├── App/                      # SongPhangApp, Info.plist (Release), PrivacyInfo.xcprivacy, Assets.xcassets, SongPhang.entitlements
├── Config/                   # Debug.xcconfig (localhost ATS in Info-Debug.plist) and Release.xcconfig
├── Scripts/
│   └── check-strings.sh      # Verifies Localizable.xcstrings matches apps/web/src/messages/vi.ts (670 keys)
├── Store/
│   └── listing.vi.md         # Vietnamese App Store listing metadata and privacy summary
└── SongPhangKit/             # Local Swift Package enforcing module boundaries
    ├── Package.swift
    └── Sources/
        ├── Domain/           # Value types, Money (integer-only), AppError, Loadable, repository protocols
        ├── GeneratedAPI/     # swift-openapi-generator client from packages/contract/openapi.json
        ├── Repositories/     # Live API repositories, SSE client, SnapshotStore, Apple/Google sign-in adapters
        ├── DesignSystem/     # Color/typography tokens, MemberShapeView, MoneyFormat, Localizable.xcstrings
        ├── PreviewSupport/   # #if DEBUG scripted scenarios and FakeWorld repositories
        ├── AuthFeature/      # Sign-in, Apple/Google native sign-in, registration, password reset, email verification
        ├── GroupsFeature/    # Group list, create group, members, owner settings, funds, approval & Telegram link
        ├── LedgerFeature/    # Feed, search/filters, balances, activity, quick entry, expense form, receipts, settle, detail (S20)
        ├── PaymentsFeature/  # Payment details, VietQR pay screen, two-party settlement requests
        ├── StatisticsFeature/# Category/member/time breakdowns and UTF-8 BOM CSV export
        ├── NotificationsFeature/ # Notification inbox (S19), badges and formatting
        ├── AccountFeature/   # Profile, sessions, push preferences, email settings, Telegram personal pairing
        └── AppShell/         # AppDependencies composition root, SessionModel, Route, PushCoordinator, LinkRouter, RootView
```

## Running Locally Against the Local API

1. Start Postgres, API (`http://127.0.0.1:4000`), and Worker (`AI_PROVIDER=fake`, `MAIL_PROVIDER=console`, `PUSH_PROVIDER=console`, `TELEGRAM_PROVIDER=console`) on a disposable database (see `docs/superpowers/runs/phase-5/manual-checks.md`).
2. Open `apps/ios/SongPhang.xcodeproj` in Xcode.
3. Select the **`SongPhang`** scheme (`Debug` configuration uses `Config/Debug.xcconfig` and `Config/Info-Debug.plist`, which enables `NSAllowsLocalNetworking` strictly in Debug).
4. Pick an iPhone Simulator running iOS 26+ and press **Run (`⌘R`)**.

### Debug Scripted Mode (Offline Previews / QA Scenarios)

Launch with `--scripted` (plus optional scenario flags such as `--scenario-empty`, `--scenario-trip0`, `--scenario-large`, `--role-viewer`, `--fail-offline`, etc.) or tap **`Debug`** in the top-right bar / shake Simulator (`⌃⌘Z`) to control `FakeWorld` at runtime. Scripted/Fake dependencies are strictly compiled under `#if DEBUG` and stripped from Release builds.

## Automated Gate

Run from the repository root:

```bash
# Debug build (warnings treated as errors on all first-party targets in Xcode/Package.swift)
xcodebuild -project apps/ios/SongPhang.xcodeproj \
  -scheme SongPhang \
  -destination 'id=<SIMULATOR_UUID>' \
  -skipPackagePluginValidation \
  build-for-testing

# Unsigned Release verification build
xcodebuild -project apps/ios/SongPhang.xcodeproj \
  -scheme SongPhang \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  -skipPackagePluginValidation \
  build

# Strict Swift formatting & localization parity (670/670 keys)
xcrun swift-format lint --strict --recursive apps/ios/SongPhangKit/Sources
./apps/ios/Scripts/check-strings.sh
```

> **Note:** Do not pass `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` as an `xcodebuild` command-line override because Xcode 27.2 passes `-suppress-warnings` to remote SwiftPM dependency `HTTPTypes`, producing an option conflict; all first-party targets (`SongPhang` and every target in `SongPhangKit`) already enable warnings-as-errors directly.

## Releasing & TestFlight

Follow [docs/runbooks/testflight.md](../../docs/runbooks/testflight.md) before signing, archiving, or distributing a Release build. Make sure to replace all `example.invalid` placeholders in `Config/Release.xcconfig` (or via an override `.xcconfig`) with your production HTTPS domain and supply your Apple Team ID, APNs `.p8` key, privacy/support URLs, and Be Vietnam Pro font decision.
