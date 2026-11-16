# Phase 5 — Stages 5B to 5E: The iOS Application

> Part of the phase 5 plan. Read `00-overview.md` first. Tasks here are in `../songphang-ios` unless a task says otherwise.

**Spec:** sections 3, 5, 6, 7 of the phase 5 spec, and the whole of `docs/superpowers/specs/2026-11-16-ios-codebase-architecture-design.md` ("the architecture design", cited below as AD).

## Decisions for these stages

1. Bundle identifier `vn.songphang.app` and display name `Sòng Phẳng` until the owner's Apple account says otherwise; both live in one `.xcconfig` file.
2. The API base address comes from the build configuration: Debug `http://localhost:4000/api/v1`, Release from `API_BASE_URL` in `Release.xcconfig` (a placeholder `https://example.invalid/api/v1` until the domain exists).
3. One Swift package inside the repository, `SongPhangKit`, holds all code as the modules of AD section 5. The application target holds only the entry point and its resources.
4. Read responses are kept by `SnapshotStore` as AD section 8.1 describes. There is no other cache.
5. A web screen is ported by reading its page and components in this repository and the spec section that designed it; the task names the web files.
6. A feature module is added to `Package.swift` by the first task that writes a file in it, with exactly the dependencies `Domain`, `DesignSystem`, `PreviewSupport`.

## Structure of the iOS repository

AD section 10. Paths in the tasks below are relative to `SongPhangKit/Sources/` unless they start with `App/`, `Config/` or `Scripts/`.

## Rules for every task from 5B.3 on

- **A screen** is a folder in its feature module with `<Name>Model.swift` (`@Observable`, receives repository protocols through its initialiser) and `<Name>View.swift`, which ends with one `#Preview` per state the screen can show (loading, loaded, empty, failed), built from `PreviewSupport`.
- **A resource** is added in four places: its types and protocol in `Domain`; its implementation and mapping in `Repositories`; its fake and sample values in `PreviewSupport`; its field in `AppShell/AppDependencies.swift`.
- **A read** has two functions: `lastKnown…()` (returns the snapshot or `nil`, never throws, never uses the network) and the fetching function (`async throws(AppError)`, updates the snapshot). A screen calls the first, shows it, then the second; a failed refresh sets `refreshError` and leaves shown content in place.
- **Navigation** leaves a feature through a closure parameter; only `AppShell` knows `Route` and constructs screens.
- **Performance:** AD section 8.2. Independent reads start together; every load runs in the view's `.task` so it is cancelled with the screen.
- **Step 2 "Gate"** always includes, besides the build and lint: every `#Preview` of the task renders in Xcode's canvas or, from the command line, the build of the scheme succeeds with previews compiled (previews are ordinary code and fail the build when broken).

---

### Task 5B.1: Project, package, generated client, design system

**Files:** `SongPhang.xcodeproj`, `App/SongPhangApp.swift`, `App/Info.plist`, `App/Assets.xcassets`, `Config/*.xcconfig`, `SongPhangKit/Package.swift`, `Scripts/sync-openapi.sh`, `AGENTS.md`; modules `Domain`, `GeneratedAPI`, `Repositories` (`Transport/`, `Session/`), `DesignSystem`, `PreviewSupport`, `AppShell`.

**Interfaces — produces:**
- `Package.swift`: the tools version of the installed toolchain; `platforms: [.iOS(.v26)]`; one shared settings list applied to every target: Swift 6 language mode, warnings as errors, and the upcoming features `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, `InferIsolatedConformances`; `.defaultIsolation(MainActor.self)` added for `DesignSystem`, `PreviewSupport`, `AppShell` and, later, every feature module. Target dependencies exactly as AD section 5. Read the manifest API of the installed toolchain for the exact spelling of each setting.
- `AGENTS.md`: as the phase 5 spec's section 3 says, plus AD sections 6 and 8.2 as hard rules and AD section 9 as "where things go".
- `Scripts/sync-openapi.sh` copies `../songphang/packages/contract/openapi.json` into `GeneratedAPI/`; the generator runs as a build plugin on that target with `generate: [types, client]` and `accessModifier: package`.
- `Domain`: `struct Money: Sendable, Hashable, Comparable, AdditiveArithmetic` over `Int64` (no multiplication, no division); `enum AppError: Error, Sendable` with the cases of AD 7.1; `enum Loadable<Value: Sendable>: Sendable`; `struct IdempotencyKey: Sendable` (a UUID string created by `init()`); `enum MemberShape` and `enum MemberColor` with the server's codes and a fallback.
- `Repositories/Transport`: `APITransport` builds the generated client with the base address and a middleware adding `Authorization` from `TokenStore` and `X-App-Version`; `func appError(from:) -> AppError` is the single error mapping (no network → `.offline`; 401 → `.unauthorized`; the upgrade code → `.upgradeRequired`; 409 → `.conflict`; 429 → `.rateLimited`; other API errors → `.api(code:status:)`; anything else → `.unexpected`).
- `Repositories/Session`: `Keychain.set/get/delete(account:)` (generic password items, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, no iCloud synchronisation); `actor TokenStore { func token() -> String?; func set(_:); func clear() }`. Both `internal`: no declaration that returns the token is `public`.
- `DesignSystem`: `Tokens` with every color of `docs/06-ux-ui/user-flows.md` section 6 and of `apps/web/src/app/globals.css`, by the same names. `MemberShapeView(shape:color:initial:size:)` draws `circle`, `diamond`, `squircle`, `leaf` (and `fund` when phase 2 is merged) with the web's geometry. `MoneyFormat.full(_: Money) -> String` → `150.000 đ` (dot grouping, a non-breaking space before `đ`); `MoneyFormat.compact` for the thousand-based form of the stream row; `MoneyText`. `LoadingSkeleton`, `LoadError` (with `Thử lại`), `EmptyState`, `OfflineBanner`. Be Vietnam Pro registered at launch; text styles relative to Dynamic Type.
- `AppShell`: `struct AppDependencies` (empty until 5B.3) with `static func live(configuration:)`; `RootView`, which in this task shows the debug gallery.

- [ ] **Step 1: Create the project and package; add the three Apple packages at their latest stable versions; record versions and licenses**
- [ ] **Step 2: The automated gate (build and lint).** Then prove the dependency rule once: add `import GeneratedAPI` to a `DesignSystem` file → the build fails; remove it. Record the compiler's message. If an upcoming-feature flag cannot be applied to `GeneratedAPI`, drop it for that target only and record it in `decisions.md`.
- [ ] **Step 3: Exercise** — the debug-only gallery showing every token, every shape in every color at 24, 44 and 96 points, the buttons, the state views, and a list of money values (`0`, `1000`, `150000`, `999999999999`). Screenshot in light appearance, at the default and the largest accessibility text size. Compare each color with the web by eye and by value.
- [ ] **Step 4: Commit** (iOS repository) — `feat(app): add project, modules, generated API client, and design system`

---

### Task 5B.2: Strings

**Files:** `DesignSystem/Resources/Localizable.xcstrings`, `Scripts/check-strings.sh`

Every key of `apps/web/src/messages/vi.ts` becomes a catalog key with the same dotted name and the same value; placeholders `{name}` become Swift format arguments while the visible text stays identical. Add the iOS-only strings of spec 5.3 under `ios.*`. Feature modules read strings through `DesignSystem` (generated symbols if the toolchain produces them for package resources, otherwise one accessor using the module's bundle). The script prints web keys missing from the catalog and catalog keys whose value differs from the web's.

- [ ] **Step 1: Write them**
- [ ] **Step 2: Gate; run the script → no missing key, no differing value. Record the output.**
- [ ] **Step 3: Commit** — `feat(app): add Vietnamese strings identical to the web`

---

### Task 5B.3: Session and sign-in (S1 and the account screens)

**Web sources:** `apps/web/src/app/login`, `register`, `verify-email`, `forgot-password`, `reset-password`; phase 1 spec section 9.1–9.4.

**Files:** `Domain/Models/User.swift`, `Domain/Repositories/AuthRepository.swift`, `Repositories/Auth/`, `PreviewSupport/Fakes/FakeAuthRepository.swift`, `AuthFeature/SignIn`, `Register`, `ForgotPassword`, `VerifyEmailBanner`, `AppShell/SessionModel.swift`, `AppShell/AppDependencies.swift`

**Interfaces — produces:**
- `protocol AuthRepository: Sendable` — `currentUser() -> User?` (`GET /me` when a token exists); `signIn(email:password:) -> User` (`POST /auth/token`); `googleSignInURL(codeChallenge:) -> URL`; `exchange(code:codeVerifier:) -> User` (`POST /auth/exchange`); `signInWithApple(_: AppleCredential) -> User` (`POST /auth/apple`); `register`, `requestPasswordReset`, `resendVerification`; `serverFeatures() -> ServerFeatures`; `signOut()`. All `async throws(AppError)`. Functions that sign in store the token inside `Repositories`; none returns it.
- `signOut()` → `POST /auth/logout`, clear `TokenStore`, delete the user's snapshot folder (5B.4), unregister the device (5C.1).
- `@Observable final class SessionModel { private(set) var state: State }` with `enum State { case loading, signedOut, signedIn(User) }`; `RootView` switches on it. An `.unauthorized` error from any repository moves it to `.signedOut`.
- Google, in `AuthFeature`: generate a 64-byte verifier and its S256 challenge with CryptoKit; `ASWebAuthenticationSession` to `googleSignInURL(codeChallenge:)` with callback scheme `songphang` and `prefersEphemeralWebBrowserSession = false`; on return, `exchange(code:codeVerifier:)`.
- Apple, in `AuthFeature`: `ASAuthorizationAppleIDProvider` with scopes full name and email, a random raw nonce whose SHA-256 goes in the request; pass `identityToken`, `rawNonce`, `authorizationCode` and the name as `AppleCredential`. Shown only when `serverFeatures().apple` is true; Google only when `.google` is true.
- Verification and reset links are opened by the mail application in the browser, on the web; the application offers `Gửi lại thư` and calls `currentUser()` when it returns to the foreground.
- Device name sent to the API: the model name (`UIDevice.current.model`), not the user-assigned name.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise in the Simulator against the local API (Review Focus 2)** — register a new email, read the link from the API console, verify in the simulator's browser, sign in; wrong password shows the exact web string; the rate-limit string after repeated failures; kill and relaunch → still signed in; sign out → the Keychain item is gone (`security` cannot read the simulator's keychain; verify by relaunching signed out and by a debug-only log of presence, not of value); Google's button starts the browser session and fails at Google as expected without credentials (record as not verified); the Apple button is hidden with the fake provider absent, and with `APPLE_PROVIDER=fake` the request reaches the API (the system sheet itself needs a real account: not verified). Search the Xcode console output of the whole exercise for the token → absent. Search the package for `public` declarations mentioning the token → none.
- [ ] **Step 4: Commit** — `feat(app): add session storage and sign-in`

---

### Task 5B.4: Groups, members, invites, snapshots (S2, S3, S10, S11, S12, S13)

**Web sources:** `apps/web/src/app/page.tsx`, `groups/new`, `g/[groupId]/members`, `settings`, `join` (phase 1 stage 1B), `account`; phase 1 spec sections 7, 9.5–9.8.

**Files:** `Domain/Models/ExpenseGroup.swift`, `Member.swift`, `Role.swift`, `Invite.swift`; `Domain/Repositories/GroupsRepository.swift`, `MembersRepository.swift`, `InvitesRepository.swift`; `Repositories/Groups/`, `Members/`, `Invites/`, `Snapshots/SnapshotStore.swift`; `PreviewSupport/Fakes/`, `Samples/`; `GroupsFeature/GroupList`, `CreateGroup`, `Members`, `GroupSettings`, `Join`; `AccountFeature/Account`; `AppShell/Route.swift`, `AppShell/RouteDestination.swift`

**Interfaces — produces:**
- `actor SnapshotStore` (internal to `Repositories`): `func read<T: Decodable & Sendable>(_ key: SnapshotKey, as: T.Type) -> T?`, `func write<T: Encodable & Sendable>(_ value: T, for key: SnapshotKey)`, `func remove(group: String)`, `func removeAll()`. Memory first, then the file; AD section 8.1 for location, protection, backup exclusion, the 20-group limit and deletion. `SnapshotKey` mirrors the web's query keys. Values are the generated response types.
- `GroupsRepository`: `lastKnownGroups() -> [ExpenseGroup]?`, `groups() -> [ExpenseGroup]`, `lastKnownGroup(id:)`, `group(id:)`, `create(name:…, key: IdempotencyKey)`, `update`, `delete`. `MembersRepository` and `InvitesRepository` on the same pattern.
- `enum Route: Hashable` with a case per destination; `RouteDestination` maps a `Route` to its screen and is the only place a screen model is constructed.

Requirements: every screen has the four states. Pull to refresh on lists. Role decides what is rendered exactly as on the web (viewer: no write control). The invite QR is drawn with Core Image's QR generator from the link; `ShareLink` shares the link. Destructive confirmations use the web's dialog strings in a confirmation dialog or, for delete-group, a sheet with the name field. A form's model creates its `IdempotencyKey` in its initialiser and reuses it for every submission of that instance.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise in the Simulator with the web open beside it** — create a group in the app, see it on the web; create on the web, pull to refresh; join a group by opening the app's join screen through a debug-only field that takes the invite token (opening the link itself comes in 5C.2); change a role on the web and see the app's controls change after refresh; delete a group; change password and delete account. A screenshot of each screen in each state.
- [ ] **Step 4: Exercise the snapshots (Review Focus 6)** — kill the app, stop the API, relaunch → the group list is shown at once with the offline banner, no skeleton; start the API → it refreshes. List the snapshot folder (`xcrun simctl get_app_container booted vn.songphang.app data`, then its caches directory) and record the listing; sign out → the folder is gone; sign in as a second user → the first user's groups never appear, even with the API stopped. Corrupt one snapshot file by hand → the screen loads from the network and the file is replaced. Read the file attributes → excluded from backup, protection class as AD 8.1.
- [ ] **Step 5: Commit** — `feat(app): add groups, members, invites, account screens, and snapshots`

---

### Task 5B.5: The group screen and realtime (S4, S5, S6)

**Web sources:** `g/[groupId]/page.tsx`, the feed components, `balances`, `activity`, `lib/use-group-events.ts`; user-flows section 5.

**Files:** `Domain/Models/LedgerTransaction.swift`, `Balance.swift`, `ActivityItem.swift`, `GroupEvent.swift`, `Page.swift`; `Domain/Repositories/TransactionsRepository.swift`, `BalancesRepository.swift`, `ActivityRepository.swift`, `GroupEventsRepository.swift`; `Repositories/Transactions/`, `Balances/`, `Activity/`, `Realtime/EventStream.swift`; `PreviewSupport`; `LedgerFeature/GroupFeed`, `Balances`, `Activity`; `Scripts/seed-large-group.sh`

**Interfaces — produces:**
- `struct Page<Item: Sendable>: Sendable { let items: [Item]; let nextCursor: String? }`. `TransactionsRepository.lastKnownFirstPage(groupId:)`, `page(groupId:cursor:) -> Page<LedgerTransaction>` (50 per page; only the first page is written to the snapshot). `ActivityRepository` likewise.
- `GroupEventsRepository.events(groupId:) -> AsyncStream<GroupEvent>` with `.changed([String])`, `.removed`, `.reconnected`, backed by `EventStream` reading `URLSession.bytes(for:)` line by line; reconnects with backoff (1 s doubling to 30 s) and emits `.reconnected`, on which the feature refetches everything for the group; cancelled when the screen disappears and when the application goes to the background. On `.changed`, the model refetches only the named resources.
- `Scripts/seed-large-group.sh <token> <groupId>`: posts 500 transactions to the local API with `curl`, for the performance measures.

Requirements: the stream row, the balance block, the pills for transfers and income, the `đã sửa` tag, the "new item" pill while scrolled up, the offline banner with disabled entry bar (from `NWPathMonitor` and failed requests), the read-only bar for viewers. Balances and suggested transfers are displayed exactly as returned. (Review Focus 1.) The feed is a lazy container of row views that each take one value; the next page is requested when the last rows appear. The feed, the balances and the members load together.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — add an expense on the web → it appears in the app within 2 seconds without interaction; turn the simulator's network off (through the host's network link conditioner or by stopping the API) → the banner, disabled entry, old data visible; back on → refetch; be removed from the group on the web → the app returns to the group list with the web's line, and that group's snapshot files are gone. Every number on S5 equals `GET …/balances` (paste both). Open a group with a snapshot → content is on screen when the push transition ends.
- [ ] **Step 4: Measure (AD 8.3)** — seed 500 transactions; record with `xcrun xctrace` the launch time to first content, a scroll of the whole feed, and hangs. Paste the numbers. A measure that cannot be taken in the Simulator is recorded as not verified, with the reason.
- [ ] **Step 5: Commit** — `feat(app): add the group stream, balances, history, and realtime`

---

### Task 5B.6: Entering and editing (S7, S8, S9)

**Web sources:** `g/[groupId]/tx/new`, `tx/[txId]`, `settle`, the expense-form components, the typing box and confirmation card; phase 1 stages 1C–1E.

**Files:** `Domain/Models/QuickEntryReading.swift`, `SharePreview.swift`, `TransactionDraft.swift`; `Domain/Repositories/QuickEntryRepository.swift` (and the write functions of `TransactionsRepository`); `Repositories/QuickEntry/`; `PreviewSupport`; `LedgerFeature/QuickEntry`, `ConfirmCard`, `ExpenseForm`, `SplitEditor`, `Settle`

**Interfaces — produces:** `QuickEntryRepository.parse(groupId:text:) -> QuickEntryReading`; `TransactionsRepository.preview(groupId:draft:) -> SharePreview`, `create(groupId:draft:key:)`, `transaction(groupId:id:)` (always from the network: an edit needs the current `version`), `update(…version:)`, `delete`, `restore`.

Requirements: the typing box calls `parse`; highlights use the returned `spans` on the returned normalised `text`; the confirmation card shows the returned `shares`. The form calls `preview` (debounced 300 ms, each request cancelling the one before) for every amount under a person; while a preview is pending the previous numbers are dimmed, never replaced by a local estimate. Money fields use the number pad with the `000` shortcut and live grouping. Edit sends `version`; `.conflict` shows the web's conflict line with `Xem bản mới`. Delete shows the undo toast (`Hoàn tác`). A save control shows its pending state in the frame of the tap. The four motions of user-flows section 6 are implemented with SwiftUI animations and disabled under "Reduce Motion".

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise (Review Focus 1)** — ten sentences from `docs/08-quick-entry-samples.md` covering `ok`, `needs_input` and `unparsed`: the card or form equals the web's for each (screenshots side by side); phase 1 stage 1C's transactions T1–T4 entered through the app give the plan's balances; double-tap Lưu → one transaction; edit conflict against the web; delete and undo; settle a suggested transfer. Search `LedgerFeature` for `*` and `/` applied to a `Money` → none can compile; record that `Money` offers neither.
- [ ] **Step 4: Commit** — `feat(app): add quick entry, the expense form, editing, and settling`

---

### Task 5B.7: Stage gate 5B

- [ ] **Step 1:** Both repositories' automated gates. `check-strings.sh` output recorded.
- [ ] **Step 2:** The phase 1 roadmap journey ("tạo nhóm, mời, gõ và nhập tay các khoản chi, sửa, xoá, thanh toán hết nợ") done entirely in the app with a second user on the web; every step's screenshot recorded; `pnpm db:check-balances` afterwards.
- [ ] **Step 3:** Accessibility pass: VoiceOver through sign-in, the stream, quick entry and the form (use the Accessibility Inspector's audit and record its findings); largest text size on every screen.
- [ ] **Step 4:** Architecture check: paste the `dependencies` of every target from `Package.swift` beside AD section 5 → identical. List every `public` declaration of `Repositories` → only the live repository types and what `AppShell` needs to build them.
- [ ] **Step 5:** The measures of AD 8.3 on the 500-transaction group, with their real numbers against the budgets.
- [ ] **Step 6:** This repository's common gate.

---

### Task 5C.1: Push in the application (needs task 5A.5)

**Files:** `Domain/Repositories/DevicesRepository.swift`, `Repositories/Devices/`, `AppShell/Push/PushDelegate.swift` (attached from `App/SongPhangApp.swift`), `AppShell/Routing/LinkRouter.swift`, `AccountFeature/PushPermission`, `App/SongPhang.entitlements`

Requirements: spec 5.3. The permission screen appears once, after the user's first successful save, and never again if dismissed with `Để sau` (stored in `UserDefaults`; this is a preference, not a secret); the account screen has `Bật thông báo` to ask later. On authorisation, register for remote notifications and `POST /me/devices` with `environment` from the build configuration. A received notification's `target` is a path (`/g/{id}/tx/{txId}/view`, `/g/{id}/balances`, `/notifications`) turned into a `Route` by one function, `LinkRouter.route(forPath:) -> Route?`, which accepts only paths matching a fixed set of patterns and returns `nil` for everything else. The account screen gains `Ẩn nội dung trên màn hình khoá` bound to `PUT /me/push-settings`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — `xcrun simctl push booted vn.songphang.app payload.apns` with payloads built to the 5A.5 shape: tapping opens the right screen for each of the three target kinds; a payload whose `target` is `https://evil.example/` or `/../x` opens nothing; with `PUSH_PROVIDER=console` on the API, the device row appears after permission and disappears after sign-out. Record under "Not verified": delivery through real APNs.
- [ ] **Step 4: Commit** — `feat(app): add push notifications`

---

### Task 5C.2: Universal links; stage gate 5C

**Files:** `App/SongPhang.entitlements` (associated domains from the configuration file), `AppShell/Routing/LinkRouter.swift`

Requirements: `onContinueUserActivity` and `onOpenURL` both go through `LinkRouter.route(for: URL) -> Route?`: host must equal the configured web host; path must match `/join/{token}` or `/link/telegram`; signed out → sign in first, then continue to the link (kept in memory only). `songphang://auth` is handled only by the sign-in flow that started it.

- [ ] **Step 1: Write it**
- [ ] **Step 2: Gate**
- [ ] **Step 3: Exercise** — `xcrun simctl openurl booted "<web origin>/join/<token>"` cannot prove association without a real domain; exercise the router directly with a debug-only field and by `simctl openurl` on the custom scheme for the routing code path; a link with another host, and a path outside the two patterns, opens nothing. Record under "Not verified": association with the real domain.
- [ ] **Step 4: Commit** — `feat(app): open invite links in the application`
- [ ] **Step 5: Stage gate 5C** — both automated gates; the architecture check and the measures of task 5B.7 steps 4 and 5; this repository's common gate.

---

### Task 5D.1: Phase 2 features (needs phase 2)

**Web sources and scope:** phase 2 spec section 9 — S14 paying, the S5 changes, payment details in the member editor, S17 fund, S16 statistics, filters, categories and budget in settings, the budget banner.

**Files:** new modules `PaymentsFeature` (paying, the fund) and `StatisticsFeature` (statistics, budget); the S5 and settings changes in `LedgerFeature` and `GroupsFeature`; one resource per new API area, added as the rules above say.

Requirements: the QR code is drawn with Core Image from `qrPayload` exactly as received, at a size of at least 240 points with a white quiet zone; `Lưu mã QR` saves the rendered image with the add-only photo permission (`NSPhotoLibraryAddUsageDescription`: `Sòng Phẳng lưu mã QR vào ảnh của bạn.`). The CSV export opens the share sheet with the downloaded file. Bars in statistics are sized from the returned amounts; no number is derived.

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — phase 2's acceptance flows 2A (request and confirm between the app and the web), 2C (the fund ledger F0–F3) and 2D (budget rows 2–6) through the app; the QR decoded from a screenshot (any decoder on the host) equals `qrPayload` byte for byte.
- [ ] **Step 4: Commit** — `feat(app): add paying, fund, statistics, and budget`

---

### Task 5D.2: Phase 3 features (needs phase 3)

**Scope:** phase 3 spec section 8 — the camera button, S18 review, photos on transactions, AI readings on the card.

**Files:** `Domain/Repositories/ReceiptsRepository.swift`, `Repositories/Receipts/`, `LedgerFeature/ReceiptCapture`, `ReceiptReview`.

Requirements: spec 5.3 of this phase. Camera through `UIImagePickerController` with `.camera` (the Simulator has none: the library path is exercised, the camera path is "Not verified"); library through `PhotosPicker` (no permission needed). Resize with Core Graphics to a longest side of 2,000 pixels, JPEG 0.85, metadata dropped by re-encoding. Upload as multipart with progress. Photos are loaded through `ReceiptsRepository` with the session header, never through a URL given to an image view; decoding and downsampling to the displayed size happen off the main actor.

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise with `AI_PROVIDER=fake`** — the four fixture images added to the simulator's library: each gives the review state phase 3 task 3C.3 describes; the saved shares equal an API preview; an uploaded photo's stored bytes contain no location metadata (inspect with `exiftool` if present, else `strings`).
- [ ] **Step 4: Commit** — `feat(app): add receipt capture and item review`

---

### Task 5D.3: Phase 4 features (needs phase 4); stage gate 5D

**Scope:** phase 4 spec section 7 — S20 transaction view with comments, disputes and approval; S19 notifications and the bell; reminders on S5; the notification, Telegram and approval settings.

**Files:** new module `NotificationsFeature` (S19, the bell, notification settings); `LedgerFeature/TransactionDetail` (S20); one resource per new API area.

Requirements: comment bodies are plain `Text`; the notification list uses `notificationText`'s lines from the string catalog by kind, with the generic line for an unknown kind; the application badge shows the unread count (cleared when the list is opened).

- [ ] **Step 1: Write it** · **Step 2: Gate**
- [ ] **Step 3: Exercise** — phase 4's acceptance flows 4A and 4D between the app and the web; a reminder sent from the web arrives as a console push line and a bell count.
- [ ] **Step 4: Commit** — `feat(app): add comments, notifications, reminders, and approval`
- [ ] **Step 5: Stage gate 5D** — both automated gates; `check-strings.sh`; the architecture check and the measures of task 5B.7 steps 4 and 5; this repository's common gate; one screenshot per new screen.

---

### Task 5E.1: Release configuration

**Files:** `Config/Release.xcconfig`, `App/PrivacyInfo.xcprivacy`, `App/Assets.xcassets/AppIcon`, `App/Info.plist`, `AppShell/UpgradeRequired`

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
- [ ] **Step 2: Final gate** — both automated gates; the architecture check and the measures of task 5B.7 steps 4 and 5; this repository's full common gate; `pnpm contract:check`.
- [ ] **Step 3: Finish the run files.** `manual-checks.md`: "In the Simulator" by screen; "On a real iPhone, after the Apple account exists" (sign in with Apple and Google, push, universal link from Messages, camera, QR saved and scanned by a banking app, cold-start time with and without a snapshot, scrolling a long group, opening the app in flight mode). `progress.md`: "Not verified" complete.
- [ ] **Step 4: Commit** (both repositories) — `docs(repo): document phase 5`

**Manual checks for the project owner**
1. Open the iOS project in Xcode, run it in a Simulator with `pnpm dev` running, sign in with the development account's email and password, and walk one trip from creating a group to settling.
2. After the Apple account exists: follow `docs/runbooks/testflight.md`.
