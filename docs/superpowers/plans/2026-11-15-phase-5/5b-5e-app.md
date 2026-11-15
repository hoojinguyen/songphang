# Phase 5 — Stages 5B to 5E: The iOS Application

> Part of the phase 5 plan. Read `00-overview.md` first. Tasks here are in `../songphang-ios` unless a task says otherwise.

**Spec:** sections 3, 5, 6, 7.

## Decisions for these stages

1. Bundle identifier `vn.songphang.app` and display name `Sòng Phẳng` until the owner's Apple account says otherwise; both live in one `.xcconfig` file.
2. The API base address comes from the build configuration: Debug `http://localhost:4000/api/v1`, Release from `API_BASE_URL` in `Release.xcconfig` (a placeholder `https://example.invalid/api/v1` until the domain exists).
3. One Swift package inside the repository, `SongPhangKit`, holds everything but the application target's entry point, so the code builds and is navigable without the app target.
4. The cache is a dictionary of query key → value with a 5-minute staleness, cleared on sign-out and on a `removed` event.
5. A web screen is ported by reading its page and components in this repository and the spec section that designed it; the task names the web files.

## Structure of the iOS repository

```
SongPhang.xcodeproj
Config/Debug.xcconfig, Release.xcconfig
App/SongPhangApp.swift, Info.plist, PrivacyInfo.xcprivacy, Assets.xcassets
SongPhangKit/Package.swift
SongPhangKit/Sources/SongPhangKit/
  API/        openapi.json (copied), openapi-generator-config.yaml, APIClient.swift, APIError.swift, Idempotency.swift
  Session/    Keychain.swift, SessionStore.swift, AuthFlows.swift
  Realtime/   EventStream.swift
  Cache/      QueryCache.swift
  Design/     Tokens.swift, Typography.swift, MemberShape.swift, Buttons.swift, Card.swift, MoneyText.swift, StateViews.swift
  Format/     Money.swift, Dates.swift
  Features/   one folder per screen: Model.swift and View.swift
  Resources/  Localizable.xcstrings, Fonts/
Scripts/sync-openapi.sh, check-strings.sh
```

---

### Task 5B.1: Project, generated client, design system

**Files:** the structure above, without `Features/`.

**Interfaces — produces:**
- `Scripts/sync-openapi.sh` copies `../songphang/packages/contract/openapi.json` into the package; the generator runs as a build plugin with `generate: [types, client]` and `accessModifier: internal`.
- `actor APIClient` — wraps the generated client; adds the base address, the `Authorization` header from `SessionStore`, `X-App-Version`, and one error mapping: `APIError.api(code: String, status: Int, details: …)`, `.offline`, `.unauthorized` (which signs out), `.upgradeRequired`.
- `Tokens`: every color of `docs/06-ux-ui/user-flows.md` section 6 and of `apps/web/src/app/globals.css`, by the same names. `MemberShape(shape:color:initial:size:)` draws `circle`, `diamond`, `squircle`, `leaf` (and `fund` when phase 2 is merged) with the web's geometry; an unknown shape code draws `circle`, an unknown color the neutral token.
- `Money.format(_ amount: Int) -> String` → `150.000 đ` (dot grouping, a non-breaking space before `đ`); `Money.formatCompact` for the thousand-based form of the stream row.
- `LoadingSkeleton`, `LoadError` (with `Thử lại`), `EmptyState`, `OfflineBanner` in `StateViews.swift`.
- Be Vietnam Pro registered at launch; text styles defined relative to Dynamic Type.

- [ ] **Step 1: Create the project and package; add the three Apple packages at their latest stable versions; record versions and licenses**
- [ ] **Step 2: The automated gate (build and lint)**
- [ ] **Step 3: Exercise** — a debug-only gallery screen showing every token, every shape in every color at 24, 44 and 96 points, the buttons, the state views, and a list of money values (`0`, `1000`, `150000`, `999999999999`). Screenshot in light appearance, at the default and the largest accessibility text size. Compare each color with the web by eye and by value.
- [ ] **Step 4: Commit** (iOS repository) — `feat(app): add project, generated API client, and design system`

---

### Task 5B.2: Strings

**Files:** `Resources/Localizable.xcstrings`, `Scripts/check-strings.sh`

Every key of `apps/web/src/messages/vi.ts` becomes a catalog key with the same dotted name and the same value; placeholders `{name}` become Swift format arguments while the visible text stays identical. Add the iOS-only strings of spec 5.3 under `ios.*`. The script prints web keys missing from the catalog and catalog keys whose value differs from the web's.

- [ ] **Step 1: Write them**
- [ ] **Step 2: Gate; run the script → no missing key, no differing value. Record the output.**
- [ ] **Step 3: Commit** — `feat(app): add Vietnamese strings identical to the web`

---

### Task 5B.3: Session and sign-in (S1 and the account screens)

**Web sources:** `apps/web/src/app/login`, `register`, `verify-email`, `forgot-password`, `reset-password`; phase 1 spec section 9.1–9.4.

**Files:** `Session/*`, `Features/SignIn`, `Features/Register`, `Features/ForgotPassword`, `Features/VerifyEmailBanner`

**Interfaces — produces:**
- `Keychain.set/get/delete(account:)` — generic password items with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, no iCloud synchronisation.
- `@Observable final class SessionStore { var state: .loading | .signedOut | .signedIn(User) }`; `signIn(email:password:)` → `POST /auth/token`; `signInWithGoogle()`; `signInWithApple()`; `signOut()` → `POST /auth/logout`, delete the Keychain item, clear the cache, unregister the device.
- Google: generate a 64-byte verifier and its S256 challenge; `ASWebAuthenticationSession` to `{base}/auth/google?client=ios&code_challenge=…` with callback scheme `songphang` and `prefersEphemeralWebBrowserSession = false`; on return, `POST /auth/exchange`.
- Apple: `ASAuthorizationAppleIDProvider` with scopes full name and email, a random raw nonce whose SHA-256 goes in the request; send `identityToken`, `rawNonce`, `authorizationCode` and the name to `POST /auth/apple`. Shown only when `features.apple` is true; Google only when `providers.google` is true.
- Verification and reset links are opened by the mail application in the browser, on the web; the application offers `Gửi lại thư` and refreshes `GET /me` when it returns to the foreground.
- Device name sent to the API: the model name (`UIDevice.current.model`), not the user-assigned name.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise in the Simulator against the local API (Review Focus 2)** — register a new email, read the link from the API console, verify in the simulator's browser, sign in; wrong password shows the exact web string; the rate-limit string after repeated failures; kill and relaunch → still signed in; sign out → the Keychain item is gone (`security` cannot read the simulator's keychain; verify by relaunching signed out and by a debug-only log of presence, not of value); Google's button starts the browser session and fails at Google as expected without credentials (record as not verified); the Apple button is hidden with the fake provider absent, and with `APPLE_PROVIDER=fake` the request reaches the API (the system sheet itself needs a real account: not verified). Search the Xcode console output of the whole exercise for the token → absent.
- [ ] **Step 4: Commit** — `feat(app): add session storage and sign-in`

---

### Task 5B.4: Groups, members, invites (S2, S3, S10, S11, S12, S13)

**Web sources:** `apps/web/src/app/page.tsx`, `groups/new`, `g/[groupId]/members`, `settings`, `join` (phase 1 stage 1B), `account`; phase 1 spec sections 7, 9.5–9.8.

**Files:** `Features/GroupList`, `CreateGroup`, `Members`, `GroupSettings`, `Join`, `Account`, `Cache/QueryCache.swift`, `API/Idempotency.swift`

Requirements: every screen has the four states. Pull to refresh on lists. Role decides what is rendered exactly as on the web (viewer: no write control). The invite QR is drawn with Core Image's QR generator from the link; `ShareLink` shares the link. Destructive confirmations use the web's dialog strings in a confirmation dialog or, for delete-group, a sheet with the name field. `IdempotencyKey` is generated when a form's model is created and reused for every submission of that instance.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise in the Simulator with the web open beside it** — create a group in the app, see it on the web; create on the web, pull to refresh; join a group by opening the app's join screen through a debug-only field that takes the invite token (opening the link itself comes in 5C.2); change a role on the web and see the app's controls change after refresh; delete a group; change password and delete account. A screenshot of each screen in each state.
- [ ] **Step 4: Commit** — `feat(app): add groups, members, invites, and account screens`

---

### Task 5B.5: The group screen and realtime (S4, S5, S6)

**Web sources:** `g/[groupId]/page.tsx`, the feed components, `balances`, `activity`, `lib/use-group-events.ts`; user-flows section 5.

**Files:** `Realtime/EventStream.swift`, `Features/GroupFeed`, `Balances`, `Activity`

**Interfaces — produces:** `EventStream(groupId:)` — an `AsyncStream` of `.changed([String])`, `.removed`, `.reconnected`, reading `URLSession.bytes(for:)` line by line; reconnects with backoff (1 s doubling to 30 s) and emits `.reconnected`, on which the feature refetches everything for the group; cancelled when the screen disappears and when the application goes to the background.

Requirements: the stream row, the balance block, the pills for transfers and income, the `đã sửa` tag, the "new item" pill while scrolled up, the offline banner with disabled entry bar (from `NWPathMonitor` and failed requests), the read-only bar for viewers. Balances and suggested transfers are displayed exactly as returned. (Review Focus 1.)

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — add an expense on the web → it appears in the app within 2 seconds without interaction; turn the simulator's network off (through the host's network link conditioner or by stopping the API) → the banner, disabled entry, old data visible; back on → refetch; be removed from the group on the web → the app returns to the group list with the web's line. Every number on S5 equals `GET …/balances` (paste both).
- [ ] **Step 4: Commit** — `feat(app): add the group stream, balances, history, and realtime`

---

### Task 5B.6: Entering and editing (S7, S8, S9)

**Web sources:** `g/[groupId]/tx/new`, `tx/[txId]`, `settle`, the expense-form components, the typing box and confirmation card; phase 1 stages 1C–1E.

**Files:** `Features/QuickEntry`, `ConfirmCard`, `ExpenseForm`, `SplitEditor`, `Settle`

Requirements: the typing box calls `parse`; highlights use the returned `spans` on the returned normalised `text`; the confirmation card shows the returned `shares`. The form calls `preview` (debounced 300 ms) for every amount under a person; while a preview is pending the previous numbers are dimmed, never replaced by a local estimate. Money fields use the number pad with the `000` shortcut and live grouping. Edit sends `version`; a 409 shows the web's conflict line with `Xem bản mới`. Delete shows the undo toast (`Hoàn tác`). The four motions of user-flows section 6 are implemented with SwiftUI animations and disabled under "Reduce Motion".

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise (Review Focus 1)** — ten sentences from `docs/08-quick-entry-samples.md` covering `ok`, `needs_input` and `unparsed`: the card or form equals the web's for each (screenshots side by side); phase 1 stage 1C's transactions T1–T4 entered through the app give the plan's balances; double-tap Lưu → one transaction; edit conflict against the web; delete and undo; settle a suggested transfer.
- [ ] **Step 4: Commit** — `feat(app): add quick entry, the expense form, editing, and settling`

---

### Task 5B.7: Stage gate 5B

- [ ] **Step 1:** Both repositories' automated gates. `check-strings.sh` output recorded.
- [ ] **Step 2:** The phase 1 roadmap journey ("tạo nhóm, mời, gõ và nhập tay các khoản chi, sửa, xoá, thanh toán hết nợ") done entirely in the app with a second user on the web; every step's screenshot recorded; `pnpm db:check-balances` afterwards.
- [ ] **Step 3:** Accessibility pass: VoiceOver through sign-in, the stream, quick entry and the form (use the Accessibility Inspector's audit and record its findings); largest text size on every screen.
- [ ] **Step 4:** This repository's common gate.

---

### Task 5C.1: Push in the application (needs task 5A.5)

**Files:** `App/AppDelegate.swift`, `Features/PushPermission`, `Session/DeviceRegistration.swift`, `App/SongPhang.entitlements`

Requirements: spec 5.3. The permission screen appears once, after the user's first successful save, and never again if dismissed with `Để sau` (stored in `UserDefaults`; this is a preference, not a secret); the account screen has `Bật thông báo` to ask later. On authorisation, register for remote notifications and `POST /me/devices` with `environment` from the build configuration. A received notification's `target` is a path (`/g/{id}/tx/{txId}/view`, `/g/{id}/balances`, `/notifications`) routed by one function, `Router.open(path:)`, which accepts only paths matching a fixed set of patterns and ignores everything else. The account screen gains `Ẩn nội dung trên màn hình khoá` bound to `PUT /me/push-settings`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — `xcrun simctl push booted vn.songphang.app payload.apns` with payloads built to the 5A.5 shape: tapping opens the right screen for each of the three target kinds; a payload whose `target` is `https://evil.example/` or `/../x` opens nothing; with `PUSH_PROVIDER=console` on the API, the device row appears after permission and disappears after sign-out. Record under "Not verified": delivery through real APNs.
- [ ] **Step 4: Commit** — `feat(app): add push notifications`

---

### Task 5C.2: Universal links; stage gate 5C

**Files:** `App/SongPhang.entitlements` (associated domains from the configuration file), `Features/Router.swift`

Requirements: `onContinueUserActivity` and `onOpenURL` both go through `Router.open(url:)`: host must equal the configured web host; path must match `/join/{token}` or `/link/telegram`; signed out → sign in first, then continue to the link (kept in memory only). `songphang://auth` is handled only by the sign-in flow that started it.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — `xcrun simctl openurl booted "<web origin>/join/<token>"` cannot prove association without a real domain; exercise the router directly with a debug-only field and by `simctl openurl` on the custom scheme for the routing code path; a link with another host, and a path outside the two patterns, opens nothing. Record under "Not verified": association with the real domain.
- [ ] **Step 4: Commit** — `feat(app): open invite links in the application`
- [ ] **Step 5: Stage gate 5C** — both automated gates; this repository's common gate.

---

### Task 5D.1: Phase 2 features (needs phase 2)

**Web sources and scope:** phase 2 spec section 9 — S14 paying, the S5 changes, payment details in the member editor, S17 fund, S16 statistics, filters, categories and budget in settings, the budget banner.

Requirements: the QR code is drawn with Core Image from `qrPayload` exactly as received, at a size of at least 240 points with a white quiet zone; `Lưu mã QR` saves the rendered image with the add-only photo permission (`NSPhotoLibraryAddUsageDescription`: `Sòng Phẳng lưu mã QR vào ảnh của bạn.`). The CSV export opens the share sheet with the downloaded file. Bars in statistics are sized from the returned amounts; no number is derived.

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — phase 2's acceptance flows 2A (request and confirm between the app and the web), 2C (the fund ledger F0–F3) and 2D (budget rows 2–6) through the app; the QR decoded from a screenshot (any decoder on the host) equals `qrPayload` byte for byte.
- [ ] **Step 4: Commit** — `feat(app): add paying, fund, statistics, and budget`

---

### Task 5D.2: Phase 3 features (needs phase 3)

**Scope:** phase 3 spec section 8 — the camera button, S18 review, photos on transactions, AI readings on the card.

Requirements: spec 5.3 of this phase. Camera through `UIImagePickerController` with `.camera` (the Simulator has none: the library path is exercised, the camera path is "Not verified"); library through `PhotosPicker` (no permission needed). Resize with Core Graphics to a longest side of 2,000 pixels, JPEG 0.85, metadata dropped by re-encoding. Upload as multipart with progress. Photos are loaded through `APIClient` with the session header, never through a URL given to an image view.

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise with `AI_PROVIDER=fake`** — the four fixture images added to the simulator's library: each gives the review state phase 3 task 3C.3 describes; the saved shares equal an API preview; an uploaded photo's stored bytes contain no location metadata (inspect with `exiftool` if present, else `strings`).
- [ ] **Step 4: Commit** — `feat(app): add receipt capture and item review`

---

### Task 5D.3: Phase 4 features (needs phase 4); stage gate 5D

**Scope:** phase 4 spec section 7 — S20 transaction view with comments, disputes and approval; S19 notifications and the bell; reminders on S5; the notification, Telegram and approval settings.

Requirements: comment bodies are plain `Text`; the notification list uses `notificationText`'s lines from the string catalog by kind, with the generic line for an unknown kind; the application badge shows the unread count (cleared when the list is opened).

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — phase 4's acceptance flows 4A and 4D between the app and the web; a reminder sent from the web arrives as a console push line and a bell count.
- [ ] **Step 4: Commit** — `feat(app): add comments, notifications, reminders, and approval`
- [ ] **Step 5: Stage gate 5D** — both automated gates; `check-strings.sh`; this repository's common gate; one screenshot per new screen.

---

### Task 5E.1: Release configuration

**Files:** `Config/Release.xcconfig`, `App/PrivacyInfo.xcprivacy`, `App/Assets.xcassets/AppIcon`, `App/Info.plist`, `Features/UpgradeRequired`

Requirements: spec section 6. The App Transport Security exception for `localhost` exists only in the Debug configuration (verify by building Release and reading the built `Info.plist`). The privacy manifest declares the data types of phase 7B section 4.1, linked to the user, not used for tracking, and the required-reason API entries for whatever system APIs the code uses (`UserDefaults`); read Apple's current documentation for the keys. The icon is the phase 7A mark on its background at 1024 pixels, exported from the SVG (or the four shapes drawn in the same arrangement when 7A has not run). Version `1.0.0`, build `1`. The upgrade screen appears when `features.minAppVersion.ios` is greater than the build's version, compared numerically by component.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate, and a Release build for the Simulator**
- [ ] **Step 3: Exercise** — the Release `Info.plist` has no ATS exception; set `MIN_APP_VERSION_IOS=9.0.0` on the API → the blocking screen; version comparison table: `1.0.0` vs `1.0.0` → allowed; `1.0.0` vs `1.0.1` → blocked; `1.10.0` vs `1.9.0` → allowed.
- [ ] **Step 4: Commit** — `chore(app): add release configuration, privacy manifest, and icon`

---

### Task 5E.2: TestFlight runbook; final gate

**Files (this repository):** `docs/runbooks/testflight.md`, `README.md`. **iOS repository:** `README.md`, `Store/listing.vi.md`.

Runbook: joining the Apple Developer Program; creating the App ID with Sign in with Apple, Push Notifications and Associated Domains; creating the APNs key and the Sign in with Apple key; the server variables each produces; setting the bundle id, team and the web host in the configuration files; archiving; uploading; adding testers; what to check on a real device (the list under "Not verified" turned into steps). Store listing: name, subtitle, description (the landing page's strings), keywords, the support address placeholder, the privacy policy address.

- [ ] **Step 1: Write them**
- [ ] **Step 2: Final gate** — both automated gates; this repository's full common gate; `pnpm contract:check`.
- [ ] **Step 3: Finish the run files.** `manual-checks.md`: "In the Simulator" by screen; "On a real iPhone, after the Apple account exists" (sign in with Apple and Google, push, universal link from Messages, camera, QR saved and scanned by a banking app, cold-start time). `progress.md`: "Not verified" complete.
- [ ] **Step 4: Commit** (both repositories) — `docs(repo): document phase 5`

**Manual checks for the project owner**
1. Open the iOS project in Xcode, run it in a Simulator with `pnpm dev` running, sign in with the development account's email and password, and walk one trip from creating a group to settling.
2. After the Apple account exists: follow `docs/runbooks/testflight.md`.
