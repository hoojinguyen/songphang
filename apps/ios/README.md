# Sòng Phẳng — iOS Application (`apps/ios`)

Native iOS 26 application for Sòng Phẳng, built with Swift 6 and SwiftUI around the modular `SongPhangKit` local Swift package.

## Requirements

- macOS with **Xcode 26 or newer** (verified on Xcode 27.2 / Swift 6.4.2)
- An **iOS 26 or newer** Simulator runtime (verified on iOS 26.5 Simulator)
- `swift-format` (bundled with the Xcode toolchain via `xcrun swift-format`)

## Project Structure

```
apps/ios/
├── SongPhang.xcodeproj       # Single-target Xcode project (App/ root group)
├── App/                      # Application entry point, Info.plist, Assets.xcassets
├── Config/                   # Debug.xcconfig and Release.xcconfig
├── Scripts/
│   └── check-strings.sh      # Verifies Localizable.xcstrings matches apps/web/src/messages/vi.ts
└── SongPhangKit/             # Local Swift Package enforcing module boundaries
    ├── Package.swift
    └── Sources/
        ├── Domain/           # Value types, Money, AppError, Loadable, repository protocols
        ├── DesignSystem/     # Color/typography tokens, MemberShapeView, MoneyFormat, Localizable.xcstrings
        ├── PreviewSupport/   # #if DEBUG scripted scenarios and FakeWorld repositories
        ├── AuthFeature/      # Sign-in (S1), registration, password reset, email verification banner
        ├── GroupsFeature/    # Group list (S2), create group (S3), members (S10), settings (S11), join (S12)
        ├── LedgerFeature/    # Group feed (S4), balances (S5), activity (S6), quick entry (S7), form (S8), settle (S9)
        ├── AccountFeature/   # Account management (S13)
        └── AppShell/         # AppDependencies composition root, SessionModel, Route, DebugPanel, RootView
```

## Opening and Running in Xcode

1. Open `apps/ios/SongPhang.xcodeproj` in Xcode.
2. Select the **`SongPhang`** scheme and any **iPhone Simulator** running iOS 26 or newer.
3. Press **Run (`⌘R`)**.

In the interface stage (`5U`), Debug builds run entirely on the scripted `FakeWorld` in `PreviewSupport` with zero network or server dependencies. Release builds intentionally fail to compile at `AppShell/AppDependencies.swift` (`#error("Live repositories arrive in the integration stage")`) so scripted data cannot ship.

## Automated Gate

Run both commands from the repository root before every commit:

```bash
xcodebuild -project apps/ios/SongPhang.xcodeproj \
  -scheme SongPhang \
  -destination 'generic/platform=iOS Simulator' \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  build

xcrun swift-format lint --strict --recursive apps/ios
```

To verify that every Vietnamese user-facing string in `Localizable.xcstrings` matches `apps/web/src/messages/vi.ts` character for character:

```bash
./apps/ios/Scripts/check-strings.sh
```

## Using the Debug Panel and Scripted Scenarios

In Debug builds, open the **Debug Panel** at any time by tapping the **`Debug`** button in the top-right navigation bar (on Sign-In or Group List) or by shaking the device/simulator (`⌃⌘Z` in Simulator).

The Debug Panel controls `FakeWorld` at runtime:

- **Scenario preset:**
  - `empty` — signed-in user (`Minh`) with no groups.
  - `trip (step 0)` — the group `"Đà Lạt 3N2Đ"` with 4 members (`Minh`, `Lan`, `Hùng`, `Thu`) and zero transactions, ready for entering `T1`–`T4`.
  - `trip (step 4)` — the group `"Đà Lạt 3N2Đ"` after transactions `T1`–`T4`, with balances and suggested transfers transcribed verbatim from `docs/superpowers/runs/ios-ui/fixtures/26-step4-balances.json`.
  - `large` — a group with 500 transactions for scrolling and `xctrace` performance checks.
- **Latency:** `0 ms`, `300 ms`, or `2 s` (to inspect loading skeletons).
- **Snapshot (`hasSnapshot`):** toggles whether `lastKnown…` repository methods return cached values or `nil`. Combine a failure with `hasSnapshot = true` to inspect the stale/offline banner state, or `hasSnapshot = false` to inspect the full-screen `LoadError` state.
- **Failure injection:** `None`, `Offline`, `Unauthorized (401)`, `Upgrade required (426)`, `Conflict (409)`, `Rate limited (429)`, `Not found (404)`, `Server / Unexpected`.
- **Role:** `Owner`, `Editor`, or `Viewer` (updates role-gated write controls across all group screens).
- **Realtime events:** emit `changed`, `removed`, or `reconnected` on the active group stream.
- **Join preview:** open S12 (`JoinView`) with the valid fixture token or an invalid token.
- **Design gallery:** open the token, member shape, money formatting, and component gallery built in Task U.1.
