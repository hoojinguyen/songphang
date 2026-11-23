# Sòng Phẳng — TestFlight & App Store Release Runbook

This runbook documents the owner-led steps required to build, sign, archive, and distribute **Sòng Phẳng (`vn.songphang.app`)** to TestFlight and the App Store. All source artifacts (`Release.xcconfig`, `Info.plist`, `SongPhang.entitlements`, `PrivacyInfo.xcprivacy`, `AppIcon.appiconset`, and Vietnamese store metadata) live in `apps/ios/`.

---

## 1. Prerequisites & Missing Owner Inputs

The local repository keeps placeholder hosts (`example.invalid`) and unsigned simulator verification defaults. Before creating a signed archive, supply or confirm the following owner inputs:

| Item | Current placeholder / status | Required owner value |
|---|---|---|
| Production API host | `https://example.invalid/api/v1` | Deployed HTTPS API URL (`https://api.<domain>/api/v1`) |
| Production Web host | `https://example.invalid` | Deployed HTTPS Web URL (`https://<domain>`) |
| Associated domain host | `example.invalid` | Exact Web hostname for Universal Links (`/join/*`) |
| Apple Developer Team ID | Not committed | 10-character Apple Developer Team ID (`<TEAM_ID>`) |
| APNs `.p8` Auth Key | Console provider locally | Apple Push Notifications key ID, `.p8` private key, Team ID (`PUSH_PROVIDER=apns`) |
| Privacy Policy & Support URLs | Pending production host | Public HTTPS pages required by App Store Connect |
| Be Vietnam Pro `.ttf`/`.otf` fonts | Only `.woff2` web fonts exist (Decision D2) | Supply licensed `.ttf`/`.otf` files for bundling, or approve iOS system-font fallback |
| Brand App Icon | Four-shape fallback mark (`AppIcon.png`, 1024×1024 RGB) | Keep fallback mark or replace with Phase 7A mark once complete |

---

## 2. Apple Developer Portal Setup

1. **Register App ID (`vn.songphang.app`):**
   - In **Certificates, Identifiers & Profiles → Identifiers**, create or edit the App ID with bundle identifier **`vn.songphang.app`** (explicit).
   - Enable capabilities matching `apps/ios/App/SongPhang.entitlements`:
     - **Sign in with Apple** (`com.apple.developer.applesignin`)
     - **Push Notifications** (`aps-environment`)
     - **Associated Domains** (`com.apple.developer.associated-domains`)
2. **Create Sign in with Apple & APNs Keys (`.p8`):**
   - In **Keys → +**, create a **Sign in with Apple** key (or reuse an existing Services/Apple Auth key) and an **Apple Push Notifications service (APNs)** key (`SongPhang APNs Production`). Record each 10-character **Key ID** and download the `.p8` file.
   - Configure the backend API & Worker environment (matching `.env.example` and `apps/api/src/config.ts`):
     ```env
     APPLE_PROVIDER=apple
     APPLE_BUNDLE_ID=vn.songphang.app
     APPLE_TEAM_ID=<team-id>
     APPLE_KEY_ID=<apple-sign-in-key-id>
     APPLE_PRIVATE_KEY=<apple-sign-in-p8-pem>
     DATA_ENCRYPTION_KEY=<encryption-secret>

     PUSH_PROVIDER=apns
     APNS_KEY_ID=<optional-apns-key-id-or-falls-back-to-APPLE_KEY_ID>
     APNS_PRIVATE_KEY=<optional-apns-p8-pem-or-falls-back-to-APPLE_PRIVATE_KEY>
     ```
3. **Configure Associated Domains & AASA on Web:**
   - Set `APPLE_APP_ID=<TEAM_ID>.vn.songphang.app` on the web server (`apps/web`).
   - Verify `https://<your-web-host>/.well-known/apple-app-site-association` returns HTTP `200`, `Content-Type: application/json`, zero redirects, and paths scoped exclusively to `/join/*`.
4. **Google Sign-In Callback URI (if enabled):**
   - Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` on the API and register the server OAuth redirect URI `https://<your-web-host>/api/v1/auth/google/callback` (constructed from `WEB_ORIGIN`). Native PKCE exchange invokes `ASWebAuthenticationSession` returning to `songphang://auth` under the `songphang` URL scheme in `apps/ios/App/Info.plist`.

---

## 3. Configure Release Hosts & Signing Override

**Never ship `example.invalid` URLs.** Do not add `NSAppTransportSecurity` or `NSAllowsLocalNetworking` to `apps/ios/App/Info.plist` (local HTTP exceptions belong exclusively to `apps/ios/Config/Info-Debug.plist`).

Pass production build settings via an untracked `.xcconfig` override file (e.g., `/tmp/songphang-release.xcconfig` supplied via `-xcconfig` on top of `apps/ios/Config/Release.xcconfig`) or edit them locally for an internal signing branch without committing secrets or temporary team changes:

```text
DEVELOPMENT_TEAM = <TEAM_ID>
API_BASE_URL = https:/$()/api.songphang.example/api/v1
WEB_BASE_URL = https:/$()/songphang.example
ASSOCIATED_DOMAIN_HOST = songphang.example
```

Verify key Release invariants before archiving:
- `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION` incremented for every upload (`1`, `2`, …).
- `APS_ENVIRONMENT = production`.
- No `#if DEBUG` / `PreviewSupport` / `FakeWorld` symbols linked in Release (`AppDependencies.live` only).

---

## 4. Archive & Upload to App Store Connect

### Using Xcode Organizer (Recommended for First Upload)
1. Open `apps/ios/SongPhang.xcodeproj` in Xcode 26+.
2. Select scheme **`SongPhang`** and destination **Any iOS Device (arm64)**.
3. Set Signing Team in **Signing & Capabilities** (or pass the override xcconfig).
4. Choose **Product → Archive**.
5. Once Organizer opens, verify:
   - App Icon displays cleanly.
   - Version (`1.0.0`) and Build number match.
6. Click **Distribute App → TestFlight & App Store → Upload**, letting Xcode validate `PrivacyInfo.xcprivacy` and symbols.

### Using Command-Line `xcodebuild` (CI / Scripted)
```sh
xcodebuild archive \
  -project apps/ios/SongPhang.xcodeproj \
  -scheme SongPhang \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -xcconfig /tmp/songphang-release.xcconfig \
  -archivePath /tmp/SongPhang.xcarchive \
  -skipPackagePluginValidation \
  DEVELOPMENT_TEAM=<TEAM_ID> \
  CURRENT_PROJECT_VERSION=1
```

Inspect the archive before exporting/uploading:
```sh
plutil -p /tmp/SongPhang.xcarchive/Products/Applications/SongPhang.app/Info.plist
plutil -lint /tmp/SongPhang.xcarchive/Products/Applications/SongPhang.app/PrivacyInfo.xcprivacy
```
Ensure `Info.plist` contains no `NSAppTransportSecurity` dictionary and uses your HTTPS `API_BASE_URL` / `WEB_BASE_URL` (never `example.invalid` or `127.0.0.1`).

Then create `/tmp/ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>TEAM_ID_HERE</string>
  <key>destination</key>
  <string>upload</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
```

Export & upload:
```sh
xcodebuild -exportArchive \
  -archivePath /tmp/SongPhang.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -exportPath /tmp/SongPhangExport
```

---

## 5. TestFlight Tester Setup & Physical Device Smoke Checks

1. In **App Store Connect → My Apps → Sòng Phẳng → TestFlight**:
   - Complete **Export Compliance Information** (Sòng Phẳng uses standard HTTPS/TLS & Apple CryptoKit AES-GCM/SHA-256 only for OS/standard encryption).
   - Add **Internal Testing** group members (App Store Connect team members get builds immediately).
   - For **External Testing**, fill out **Test Information** (Beta App Description in Vietnamese, Feedback Email, Review Notes with demo credentials) and submit for Beta App Review.
2. On a physical iPhone installed via TestFlight, verify every deferred device/external item in `docs/superpowers/runs/phase-5/manual-checks.md`:
   - Camera & photo library receipt scan + EXIF/GPS stripping.
   - Sign in with Apple & Google OAuth (`ASWebAuthenticationSession`).
   - APNs push delivery (foreground/background tap to `/g/{id}/tx/{txId}/view` & `/notifications`) and `Ẩn nội dung trên màn hình khoá`.
   - Universal Link `https://<web-host>/join/<token>` launching Sòng Phẳng directly into Join Group (while `https://<web-host>/link/telegram` remains in Safari).
   - VietQR scanning with a real Vietnamese banking app.
   - Open technical debt items tracked in `docs/tech-debt.md` (`TD-001`..`TD-007`) prior to public launch.
