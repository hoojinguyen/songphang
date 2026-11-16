# iOS interface stage run — progress

Written by the implementation agent during the run. See `docs/superpowers/plans/2026-11-16-ios-ui.md`.

For each task, under its heading: the approach note, the commit hash, the real output of the gate and the exercises with screenshot paths, and "Unresolved" if a check still fails after three fix attempts. Tick the box only when the task is committed.

- [x] U.0 Baseline
- [x] U.1 Project, package, domain basics, design system
- [x] U.2 Strings
- [ ] U.3 Domain, repository protocols, scripted fakes
- [ ] U.4 Shell, debug panel, sign-in
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

## Gate not passed

## Not verified

- Be Vietnam Pro bundled font registration on iOS: `apps/web/public/fonts/be-vietnam-pro/` contains only `.woff2` files, which iOS cannot register directly, and downloading `.ttf`/`.otf` files is forbidden in this run (see decision D1). The app uses the system font with Dynamic Type scaling.

## Out of scope

## For the integration stage
