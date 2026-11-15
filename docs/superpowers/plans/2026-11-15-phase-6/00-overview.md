# Sòng Phẳng — Phase 6 (Android) Implementation Plan

> **For the implementation agent:** read `AGENTS.md` of **both** repositories, the Android spec and the iOS spec, `../2026-11-15-common.md`, the phase 5 plan (`../2026-11-15-phase-5/`), then this file. This plan states what differs from phase 5; where it says "as 5B.4", do that task's requirements and exercise on Android.

**Goal:** A native Android application equal to the iOS one.

**Architecture:** As phase 5. Server additions are an FCM push adapter and the App Links file. The application is Kotlin and Jetpack Compose over a client generated from the same committed OpenAPI file.

**Tech Stack:** this repository unchanged (FCM through `fetch` and `node:crypto`). Android repository: Kotlin, Jetpack Compose with Material 3 restyled to the project's tokens, minimum API 26, OpenAPI Generator (Kotlin, Retrofit 2, OkHttp, kotlinx.serialization), AndroidX Navigation Compose, Lifecycle, DataStore, Browser; ZXing core; Firebase Messaging applied only when `google-services.json` exists; optionally the `ktlint` Gradle plugin.

**Spec:** `docs/superpowers/specs/2026-11-15-phase-6-android-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-phase-6`; `<BRANCH>` `phase-6`; `<LAST TASK>` `6E.2`.

## Constraints

- Requires phase 5 stage 5A on `main`. Without it, stop after the re-baseline and record why.
- Every constraint of the phase 5 overview applies with these substitutions: automated gate `./gradlew assembleDebug lintDebug` with `warningsAsErrors true` (plus `ktlintCheck` if the plugin is approved); strings in `app/src/main/res/values/strings.xml`; the token in a DataStore file encrypted with an AES-GCM key held in the Android Keystore; the emulator reaches the local API at `http://10.0.2.2:4000`, allowed as cleartext only in the debug source set's network security configuration.
- If the Android SDK or an emulator image is not installed, do stage 6A, record the rest as "Not built: no Android SDK", and stop. Do not install the SDK.
- Application id `vn.songphang.app`. The release signing key is never created by you and never enters the repository.
- `android:allowBackup="false"` and data-extraction rules that exclude the token file.
- Screenshots: `adb exec-out screencap -p`, saved under `docs/superpowers/runs/phase-6/screens/`.

## Review Focus

Those of phase 5, plus:

1. **State lost on process death**: a half-filled form, or its idempotency key, so a retry stores a duplicate. → 6B.4.
2. **The token readable from a backup or a rooted copy of the preferences.** → 6B.2.
3. **An exported component or an unverified link opening internal screens.** → 6C.2.

---

## Stage 6A — this repository

### Task 6A.1: FCM push adapter

**Files:**
- Create: `apps/worker/src/push/fcm-sender.ts`, `apps/worker/src/push/google-access-token.ts`
- Modify: `apps/worker/src/push/push-sender.ts` (choose the adapter by `device.platform`), `apps/worker/src/config.ts`, `.env.example`

**Interfaces — produces:**
- `googleAccessToken(config, now): Promise<string>` — a JWT assertion (`iss` = `FCM_CLIENT_EMAIL`, `scope` = `https://www.googleapis.com/auth/firebase.messaging`, `aud` = `https://oauth2.googleapis.com/token`, one-hour expiry) signed with `crypto.sign("RSA-SHA256", …)`, exchanged with `fetch` for an access token cached until 5 minutes before expiry.
- The FCM adapter posts to `https://fcm.googleapis.com/v1/projects/{FCM_PROJECT_ID}/messages:send` a message with `token`, `notification: { title, body }`, `data: { groupId, target }` and `android: { notification: { channel_id } }` where the channel is `todo` for immediate kinds and `activity` for the others; maps 200 → `sent`; 404 or error code `UNREGISTERED` → `gone`; else `failed`. Read the current FCM HTTP v1 documentation; record the date and shape.
- `PUSH_PROVIDER_ANDROID` = `fcm` (requires the three `FCM_*` variables), `console`, or unset.

- [ ] **Step 1: Write it** · **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — console adapter: an Android device and an iOS device of one user each get one line for a reminder, with the right channel; the assertion decoded shows the claims above and verifies with the matching public key (a scratch key pair); a stubbed `fetch` returning `UNREGISTERED` deletes the device. Record under "Not verified": real FCM.
- [ ] **Step 4: Commit** — `feat(worker): send push notifications through FCM`

### Task 6A.2: App Links file; stage gate 6A

**Files:** `apps/web/src/app/.well-known/assetlinks.json/route.ts`; environment configuration; `infra/Caddyfile` if present.

With `ANDROID_PACKAGE` and `ANDROID_CERT_SHA256` (one or more fingerprints, comma-separated, each 32 colon-separated upper-case hex bytes; anything else is a start-up error) set: 200 `application/json` with one statement, relation `delegate_permission/common.handle_all_urls`, target `android_app` with the package and the fingerprints. Unset → 404.

- [ ] **Step 1: Write it** · **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — both states; a malformed fingerprint refuses to start; `GET /auth/google?client=android&code_challenge=…` reaches the redirect to Google.
- [ ] **Step 4: Commit** — `feat(web): serve the Android App Links file`
- [ ] **Step 5: Stage gate 6A** — the gate of the common file.

---

## Stage 6B — Android repository

Structure: one Gradle module `app`, packages `api` (generated client, `ApiClient`, `ApiError`), `session`, `realtime`, `cache`, `design`, `format`, `feature.<screen>` (a `ViewModel` and a composable each), `nav`.

### Task 6B.1: Project, generated client, design system

As 5B.1 and 5B.2 together. Specifics: the OpenAPI Generator Gradle plugin reads `../songphang/packages/contract/openapi.json` (copied by `scripts/sync-openapi.sh`); kotlinx.serialization configured with `ignoreUnknownKeys = true` and `coerceInputValues = true`, and every generated enum given an unknown fallback (the generator's `enumUnknownDefaultCase` option; confirm in its documentation). `SongPhangTheme` wraps Material 3 with a fixed color scheme from the tokens (no dynamic color), shapes with the project's radii, zero elevation everywhere. `MemberShape` composable with the web's geometry. `Money.format` → `150.000 đ`. `strings.xml` identical to the web's strings with positional placeholders; `scripts/check-strings.sh` reports missing and differing ones.

- [ ] **Step 1: Create the project; record every dependency's version and license** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — the debug gallery screen of 5B.1 on an emulator, at font scale 1.0 and 2.0; the strings script's output.
- [ ] **Step 4: Commit** — `feat(app): add project, generated API client, design system, and strings`

### Task 6B.2: Session and sign-in

As 5B.3, without Apple. Specifics: `TokenStore` — an AES-256-GCM key generated in the Android Keystore (not exportable), the token encrypted with it and written to a DataStore file excluded from backup; Google through a Custom Tab to `/auth/google?client=android&code_challenge=…`, returning to an activity with an intent filter for `songphang://auth` that is `android:exported="true"` for that scheme only and accepts the result only when a sign-in started by this process is pending (the verifier is held in memory); the "Dùng tài khoản Apple?" link and its explanatory string of spec section 4.

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise (Review Focus 2)** — the 5B.3 exercise; `adb shell run-as vn.songphang.app cat` on the DataStore file shows no readable token; `adb backup` or the data-extraction rules checked by reading the merged manifest; `adb shell am start -d "songphang://auth?code=x"` with no sign-in pending does nothing; logcat of the whole exercise searched for the token → absent.
- [ ] **Step 4: Commit** — `feat(app): add session storage and sign-in`

### Task 6B.3: Groups, members, invites, account

As 5B.4. Specifics: the invite QR drawn with ZXing's `QRCodeWriter` into a bitmap; sharing through `Intent.ACTION_SEND`; system back handled per spec 5.1.

- [ ] **Step 1** · **Step 2: Gate** · **Step 3: Exercise as 5B.4** · **Step 4: Commit** — `feat(app): add groups, members, invites, and account screens`

### Task 6B.4: The group screen, realtime, entering and editing

As 5B.5 and 5B.6. Specifics: SSE read from an OkHttp streaming body in a coroutine tied to the screen's lifecycle (`repeatOnLifecycle(STARTED)`); connectivity from `ConnectivityManager`; every form's fields **and its idempotency key** live in `SavedStateHandle`; the entry bar stays above the keyboard and the navigation bar with edge-to-edge insets; the dirty-form back dialog of spec 5.1.

- [ ] **Step 1** · **Step 2: Gate**
- [ ] **Step 3: Exercise (Review Focus 1)** — the 5B.5 and 5B.6 exercises; then: fill a form, press Lưu with the API stopped, enable "Don't keep activities" and switch away and back (or `adb shell am kill`), start the API, press Lưu → one transaction, and the request carried the same idempotency key as before the kill (compare in the API log).
- [ ] **Step 4: Commit** — `feat(app): add the group stream, realtime, entry, and editing`

### Task 6B.5: Stage gate 6B

As 5B.7, with TalkBack and font scale 2.0 in place of VoiceOver and the largest text size, and Android Lint's accessibility checks recorded.

---

## Stage 6C

### Task 6C.1: Push (needs task 6A.1)

**Files:** `push/MessagingService.kt`, `push/Channels.kt`, `feature/pushpermission`, Gradle configuration.

The Google services plugin and `firebase-messaging` are applied only when `app/google-services.json` exists (a Gradle condition); without it the push package compiles to a no-op implementation behind the same interface, and the build and every other feature work. Channels and permission flow per spec 5.1. A tapped notification's `target` goes through the same allow-listed router as 5C.1. The service is not exported.

- [ ] **Step 1** · **Step 2: Gate — both with and without a placeholder-free build (the file absent)**
- [ ] **Step 3: Exercise** — without the file: the app builds, runs, and the permission screen is not shown. Routing exercised with `adb shell am start` carrying the extras the service would pass, for the three target kinds and for a hostile target. Record under "Not verified": everything needing a Firebase project.
- [ ] **Step 4: Commit** — `feat(app): add push notifications`

### Task 6C.2: App Links; stage gate 6C

Intent filter with `android:autoVerify="true"` for `https://{web host}/join/*` and `/link/*`, the host from a manifest placeholder. One router as 5C.2. Every other activity, service, receiver and provider is `exported="false"`; list the merged manifest's exported components in `progress.md` (Review Focus 3).

- [ ] **Step 1** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — `adb shell am start -a android.intent.action.VIEW -d "https://<host>/join/<token>" vn.songphang.app` opens the join screen (explicit package, since verification needs the real domain); another host or path opens nothing; signed out → sign in, then the join screen.
- [ ] **Step 4: Commit** — `feat(app): open invite links in the application`
- [ ] **Step 5: Stage gate 6C.**

---

## Stage 6D

### Task 6D.1: Phase 2, 3 and 4 features

As 5D.1, 5D.2 and 5D.3, one commit each (`feat(app): add paying, fund, statistics, and budget`; `feat(app): add receipt capture and item review`; `feat(app): add comments, notifications, reminders, and approval`), each skipped when its phase is absent. Specifics: the VietQR code drawn with ZXing from `qrPayload` unchanged, error correction level M, saved through MediaStore; photos through the system photo picker and `ActivityResultContracts.TakePicture` with a `FileProvider` URI in the cache directory (deleted after upload); resizing with `BitmapFactory` sampling then scaling, re-encoded as JPEG 85; images fetched through the API client and decoded at display size; the CSV handed to `ACTION_SEND`.

- [ ] For each of the three: **write, gate, exercise as the matching 5D task, commit.**
- [ ] **Stage gate 6D** — as 5D's.

---

## Stage 6E

### Task 6E.1: Release build

Release build type: R8 shrinking with rules that keep the generated models' serializers (verify by running the release build against the local API through a debug-signed release variant used only for this check); the production API address from a Gradle property with an `https://example.invalid` placeholder; cleartext forbidden in the main network security configuration; signing configuration read from `keystore.properties` when present, absent otherwise (the build then produces an unsigned artifact and says so); the adaptive icon from the phase 7A mark; version `1.0.0`, code `1`; the upgrade screen as 5E.1.

- [ ] **Step 1** · **Step 2: Gate and `./gradlew assembleRelease`**
- [ ] **Step 3: Exercise** — the shrunk build signs in, lists groups, parses a sentence and saves (catches a serializer removed by shrinking); the merged release manifest has `usesCleartextTraffic` false and `allowBackup` false; APK size recorded.
- [ ] **Step 4: Commit** — `chore(app): add release build configuration`

### Task 6E.2: Distribution runbook; final gate

**Files (this repository):** `docs/runbooks/android-release.md`, `README.md`. **Android repository:** `README.md`, `store/listing.vi.md`, `store/data-safety.md`.

Runbook: creating the signing key and keeping it safe; its SHA-256 fingerprint into `ANDROID_CERT_SHA256`; the Firebase project, `google-services.json`, and the service account for the three `FCM_*` variables; building a signed APK and installing it directly; the Play Console's internal testing track; the data-safety form answered from phase 7B section 4.1; what to check on real devices.

- [ ] **Step 1: Write them**
- [ ] **Step 2: Final gate** — both automated gates; this repository's full common gate; `pnpm contract:check`.
- [ ] **Step 3: Finish the run files.** `manual-checks.md`: "In the emulator" by screen; "On real phones" (two manufacturers if available: sign-in, push in both channels, the invite link from a chat application, camera, a saved QR scanned by a banking app, back behaviour, font scale 200 %).
- [ ] **Step 4: Commit** (both repositories) — `docs(repo): document phase 6`

**Manual checks for the project owner**
1. Open the project in Android Studio, run it on an emulator with `pnpm dev` running, and walk one trip from creating a group to settling.
2. After the signing key and the Firebase project exist: follow `docs/runbooks/android-release.md`.
