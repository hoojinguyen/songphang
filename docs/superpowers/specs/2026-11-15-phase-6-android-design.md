# Phase 6 — Android — Design

Date: 2026-11-15. Status: draft, waiting for the project owner's approval. Read `2026-11-15-roadmap-remaining-phases-overview.md` and `2026-11-15-phase-5-ios-design.md` first. This spec states only what differs from iOS; everything else in the iOS spec applies with "Android" in place of "iOS".

## 1. Intent

An Android application equal to the iOS one (FR-6.1, US-6.1), distributed as a directly installable file or through Google Play's internal testing channel.

**Goals, non-goals, anti-goals:** those of phase 5. Additional non-goals: tablets and foldables beyond not breaking; Wear OS.

## 2. Scope and stages

| Stage | Where | Adds |
|---|---|---|
| 6A | This repository, branch `phase-6` | FCM push sender; App Links file; `client=android` for the sign-in exchange |
| 6B | Android repository | Project, design system, generated client, sign-in, screens S1–S13 |
| 6C | Both | Push notifications; App Links for invites |
| 6D | Android repository | Whatever of phases 2–4 is on `main`; receipt capture |
| 6E | Android repository | Signed release build; store texts; distribution runbook |

**Requires:** stage 5A (contract freeze, native sessions, `push_devices`).

## 3. Repository and rules

A separate repository, `songphang-android`, with its own adapted `AGENTS.md`. The automated gate is `./gradlew assembleDebug lintDebug` with warnings as errors, plus `ktlint` through its Gradle plugin if the owner approves it (section 5). No automated tests are written. Strings live in `res/values/strings.xml`, identical to the web's.

## 4. API work (6A)

- **Sign-in:** `GET /auth/google?client=android&code_challenge=…` redirects to the same `songphang://auth?code=…`; `POST /auth/exchange` and `POST /auth/token` are those of phase 5. **Apple sign-in is not offered on Android.** A user whose only identity is Apple signs in on Android by setting a password through "Quên mật khẩu?", which works with Apple's relay addresses because mail to them is forwarded. The sign-in screen says so under a "Dùng tài khoản Apple?" link: `Bấm "Quên mật khẩu?" với email Apple của bạn để đặt mật khẩu cho Sòng Phẳng.`
- **Push:** a second `PushSender` adapter, `fcm`: a service-account assertion signed with RS256 through `node:crypto`, exchanged for an access token (cached until shortly before expiry), then FCM's HTTP v1 send endpoint with `fetch`. Needs `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY`. No Firebase library on the server. The sender is chosen per device by `platform`.
- **App Links:** the web application serves `/.well-known/assetlinks.json` from `ANDROID_PACKAGE` and `ANDROID_CERT_SHA256`, for `/join/*` and `/link/*`; 404 without them.
- `features.minAppVersion.android` is honored.

## 5. The application

| Choice | Decision |
|---|---|
| Language, UI | Kotlin, Jetpack Compose; minimum Android 8.0 (API 26); target the newest stable API level |
| API client | Generated at build time from the committed `openapi.json` by OpenAPI Generator's Kotlin generator (Retrofit 2, OkHttp, kotlinx.serialization); all Apache-2.0 |
| Navigation, state | AndroidX Navigation Compose; one `ViewModel` per screen exposing a `StateFlow`; an in-memory cache keyed like the web's query keys. No database |
| Session | The token encrypted with a key held in the Android Keystore, stored through DataStore. Excluded from cloud backup and device transfer |
| Realtime | The SSE stream read with OkHttp's streaming response body |
| QR codes | `com.google.zxing:core` (Apache-2.0, about 550 KB) to draw the server's payload. Android has no built-in QR encoder, and writing one is far beyond a few dozen lines |
| Push | `firebase-messaging` and the Google services Gradle plugin, applied only when `google-services.json` is present, so the project builds and runs without a Firebase project |
| Sign-in | Google through Custom Tabs (`androidx.browser`) and the exchange code; no Google sign-in SDK |
| Photos | The system photo picker and the system camera through activity result contracts; no camera library |
| Images | Receipt photos decoded with the platform's decoder at the display size; no image-loading library |
| Font | Be Vietnam Pro, bundled |

Libraries for the owner's approval: the generated client's three, AndroidX (Compose, Navigation, Lifecycle, DataStore, Browser), ZXing core, Firebase Messaging, and, optionally, the `ktlint` Gradle plugin as the formatter.

**Material 3 is the component base, restyled to the project's tokens:** no dynamic color, no elevation shadows, the project's corner radii and the 3-point black selection border. The application must look like Sòng Phẳng, not like a stock Material application.

### 5.1 Android-specific behavior

| Place | Behavior | String |
|---|---|---|
| System back | Always goes where the screen's own back control goes; from a dirty form it asks first | `Bỏ thay đổi?` · `Bỏ` · `Tiếp tục sửa` |
| Notification permission (Android 13 and later) | Asked after the first saved expense, preceded by the same screen as iOS | iOS strings |
| Notification channels | Two: `Việc cần bạn làm` (reminders, requests, approvals; default importance) and `Hoạt động trong nhóm` (expenses, comments; low importance) | as shown |
| Invite link | Verified App Link opens S12 | |
| Edge to edge | Content draws behind the system bars; the entry bar stays above the keyboard and the navigation bar | |
| Process death | A form in progress is restored through saved state; its idempotency key is restored with it | |
| Paying (phase 2) | `Lưu mã QR` saves through MediaStore without a storage permission | `Lưu mã QR` |
| Too old a build | Blocking screen | `Hãy cập nhật Sòng Phẳng để tiếp tục.` · `Cập nhật` |

Accessibility: font scale up to 200 % without clipping; TalkBack labels are members' names; "remove animations" replaces the four motions with instant changes.

## 6. Release (6E)

A release build type with code shrinking and the production API address; the signing key generated and kept by the owner, never in the repository (the build reads it from a properties file listed in `.gitignore`); the adaptive icon from the phase 7A mark; the Play data-safety answers derived from phase 7B section 4.1; store texts as iOS; `docs/runbooks/android-release.md` covering both a directly installable APK and Play internal testing. The agent signs nothing and uploads nothing.

## 7. Verification

- **Gate after each stage:** this repository's gates; `./gradlew assembleDebug lintDebug` clean; the application run in an emulator against the local API at `http://10.0.2.2:4000` (cleartext allowed only in the debug build's network security configuration), walking the stage's flows with a screenshot of each screen recorded.
- **6A scripts:** the exchange flow with `client=android`; the console sender prints one push per Android device; `assetlinks.json` answers 404 without its variables and valid JSON with them.

**Not verified by the agent:** real devices and manufacturers' variations; real FCM; real Google sign-in; App Link verification (needs the real domain and the release key's fingerprint); Play Console.

## 8. Changes to standing documents

| Document | Change |
|---|---|
| `docs/04-adr.md` | ADR-014 gains the versions chosen here; ADR-031: FCM by HTTP from the server, Firebase SDK only in the application and only when configured |
| `docs/05-api-spec.md` | `client=android`; the App Links file |
| `docs/03-srs.md` | FR-6.1 refined with section 5.1; the Apple-account path of section 4 |

## 9. Owner's prerequisites

Before the run: approve this spec and the libraries of section 5; Android Studio with an emulator image. Any time after: a Firebase project for push; a Google Play developer account if the Play channel is wanted (one-time fee); the release signing key.
