# Phase 5 — iOS Core Integration, Web Parity and Release

> Follow [00-overview.md](00-overview.md). Implement **5B**, then run [5C](5c-integrations.md), then return here for **5D–5E**. Swift module paths in the Files lists are relative to `apps/ios/SongPhangKit/Sources/`. API paths are relative to `/api/v1`.

## Rules for every task from 5B.3 on

- Adapt the existing SwiftUI screens and protocols. A screen is a folder in its feature module with a view, an `@Observable` model receiving its protocol dependencies, and Debug previews for its applicable states.
- For a resource, put domain types and protocols in `Domain`, transport and mapping in `Repositories`, scripted scenarios in `PreviewSupport`, and injection in `AppShell`. New feature targets have exactly the dependencies in architecture §5 and never import each other.
- For a read covered by architecture §8.1, keep the existing paired `lastKnown…()` and fetch methods. Show the snapshot immediately, keep shown content on transient refresh failure and cancel loads with their view. Feature navigation uses closure intents. Only AppShell constructs destination screens.
- Use the catalog for all new copy. Update keys from `apps/web/src/messages/vi.ts` for the journeys delivered by each task, including interpolated placeholders. `bash apps/ios/Scripts/check-strings.sh` reports missing and divergent values. At 5B any remaining difference must map to a 5D parity row. By 5E no in-scope web value may be missing or divergent.

## Stage 5B — Live core app and early owner checkpoint

### Task 5B.1: Generated client, transport and live composition

**Files:** `apps/ios/SongPhangKit/Package.swift`, resolved package lock, `GeneratedAPI/openapi-generator-config.yaml`, generator input adjacent to the config, `Repositories/{Transport,Session}/`, `AppShell/AppDependencies.swift`, `apps/ios/App/{SongPhangApp.swift,Info.plist}`, `apps/ios/Config/*.xcconfig`.

**Interfaces:** `GeneratedAPI` consumes the committed 5A document, generates types and client only with package visibility, and stays inside the module graph. Use the same-repository input link when supported. If the build plugin cannot resolve it, copy deterministically using a script in `apps/ios/Scripts/` and check that the copy matches the authoritative snapshot at the build gate. `Repositories` owns the generated client, a Bearer-only URLSession transport with cookie storage disabled, `X-App-Version`, and a single typed error mapper. The `TokenStore` actor stores the token as a generic password item with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Only `Repositories` handles the raw token.

- [ ] Add the three Apple Swift OpenAPI packages at pinned stable resolutions and build against the real document. Check that the versioned URL path is composed exactly once with the configured base. Do not edit generated Swift or hand-maintain a second contract. Fix any invalid schema documentation at the source within the 5A boundary and regenerate. [Swift OpenAPI Generator documentation](https://github.com/apple/swift-openapi-generator).
- [ ] Establish `AppDependencies.live(configuration:)`. Deliver a live reachability check with `GET /features` from the existing shell. Keep unconnected screens explicitly gated during intermediate commits and remove those gates as their tasks land. Scripted data stays selectable only for Debug scenarios and previews. Release loses the 5U compile guard once all live core dependencies exist.
- [ ] Run the default Debug app against localhost and record an API request and capability result. Confirm preview/scripted mode still works and credentials are absent from logs and exported public declarations. Run the task gate and commit `feat(ios): generate the v1 client and compose live transport`.

### Task 5B.2: Account lifecycle and session-scoped snapshots (S1 and S13)

**Files:** `Domain/Repositories/AuthRepository.swift`, `Domain/Models/ServerFeatures.swift`, new session DTO/domain types as needed, `Repositories/{Auth,Session,Snapshots}/`, `AuthFeature/{SignIn,Register,ForgotPassword,VerifyEmailBanner}/`, `AccountFeature/Account/`, `AppShell/{SessionModel,RootView,AppDependencies}.swift`, `PreviewSupport`, catalog.

**Interfaces:** Keep the existing async typed-throws auth protocol for current user, sign-in, registration, verification resend, password reset request, password change, sign-out and account deletion. Add session-list and revoke operations for the 5A endpoints. Map `appleSignIn` and `push` from `/features` and Google from `/auth/providers`; provider UI is connected in 5C. Route account verification and reset links through web, then refresh user state when iOS returns to foreground. For a rejected build, compare minimum versions numerically by component, surface the blocking screen and accept equal versions. Enable user-controlled App Store navigation only with the configured store destination.

**Snapshot interface:** One internal `SnapshotStore` actor with scoped reads, writes and removal. The authenticated scope includes the user ID and a session generation. Every network write-back must still match the active scope and, for group data, the group-access generation. Protect files until first unlock, exclude them from backup, cap at 20 recent groups, and discard corrupt files. Use the architecture §8.1 cache coverage and the existing paired domain methods. Explicit sign-out, current-session revoke, deletion and authenticated 401 invalidate the scope and clear the corresponding data before exposing signed-out UI. Plain network failure retains the user's current protected content and disables writes.

- [ ] Wire login, account actions, session invalidation and the snapshot store. Exercise account registration, console link, wrong-password and rate-limit copy, kill/relaunch, password change and deletion on disposable accounts. Verify revocation from a second web session removes the iOS session and active content and the next user sees only their own data.
- [ ] Exercise revoked late responses and corrupt snapshots as the corresponding resource paths become live in 5B.3 and 5B.4. In a disposable response fixture, add an unknown enum value and an extra field. Preserve readable data with a safe unknown fallback, including read-only treatment of an unknown role.
- [ ] Verify minimum-version cases `1.0.0/1.0.0` allowed, `1.0.0/1.0.1` blocked, and `1.10.0/1.9.0` allowed (build/minimum). Run the task gate and commit `feat(ios): connect native account lifecycle and protected snapshots`.

### Task 5B.3: Groups, members, settings and invites (S2, S3, S10–S12)

**Files:** `Repositories/{Groups,Members,Invites}/`, matching existing `Domain/Repositories/…`, `GroupsFeature/{GroupList,CreateGroup,Members,GroupSettings,Join}/`, `AppShell/{Route,RouteDestination,RootView,AppDependencies}.swift`, new `AppShell/Routing/LinkRouter.swift`, Debug panel, `PreviewSupport`, catalog.

**Interfaces:** Implement the existing group, member and invite protocols against `/groups`, its member/user/role/leave/transfer/invite routes and `/invites/{token}`. Persist only allowed snapshot resources. Keep owner/editor/viewer actions as on web, including claim, role changes, leave and ownership transfer. Core Image renders the invite QR from the server's link. System sharing uses that same link. Define `LinkRouter.route(for: URL) -> Route?` to accept only the configured web scheme/host/port and known invite path shape. Release uses HTTPS; local Debug accepts its configured local origin. Feed the same router from a Debug-only URL entry. Hold a validated join route in memory through sign-in and clear it when consumed or cancelled. System association is 5C.6.

- [ ] Connect S2, S3, S10–S12. With iOS and web, create groups on both clients, join from both directions including while signed out on iOS, exercise claim/role/leave/rotation, and try expired, malformed, foreign-host and already-used or deactivated invites as applicable to the current server contract. Check that viewers lack write actions.
- [ ] On Simulator, interrupt the API, reopen the same user and check group-list snapshot/failed refresh. Corrupt one disposable file and recover from API. Revoke and switch users, then inspect the cache directory and confirm the old data is gone. Verify protection and backup attributes. Run the task gate and commit `feat(ios): connect groups, membership and local invite routing`.

### Task 5B.4: Group ledger and realtime (S4–S9)

**Files:** `Repositories/{Transactions,Balances,Activity,QuickEntry}/`, `Repositories/Realtime/EventStream.swift`, existing ledger domain protocols, `LedgerFeature/{GroupFeed,Balances,Activity,QuickEntry,ConfirmCard,ExpenseForm,SplitEditor,Settle}/`, `AppShell`, `PreviewSupport`, catalog.

**Interfaces:** Implement the existing `TransactionsRepository`, `BalancesRepository`, `ActivityRepository`, `QuickEntryRepository` and `GroupEventsRepository`. The first page of feed/activity, balances and members use the scoped snapshot. The initial feed/balance/member reads start together and feed/activity use live cursors (50/page). Edit starts from a current network detail with `version`. Debounce `parse` and `preview` 300 ms, cancel superseded requests and guard against stale completions. Create reuses the form's key across duplicate taps or retries; no money or approval-counting calculation in Swift.

Use `URLSession.bytes` for `GET /groups/{groupId}/events`. Consume `changed(resources)` and `removed`, ignore keep-alives/unknown event names, and emit `.reconnected` after a successful resubscription. Revalidate the open group's resources on reconnect. Back off from 1 s to 30 s on transient disconnects. Cancel on background, navigation, session invalidation or group removal. Clear the group and route to the list on loss of access, including group-access 404 after a missed event. A scoped transaction or child-resource 404 alone is not group removal; confirm group authorization. Terminate on 401 and invalidate the session. Use approval state and official previews exactly as the baseline API sends them; the Phase 4 detail and decisions UI arrives in 5D.6.

- [ ] Connect the ledger reads and writes. Exercise parse `ok`, `needs_input` and `unparsed` using the approved sample corpus. Replay the existing Phase 1 split fixture T1–T4 through iOS and compare with API responses and expected debt math. Check viewer behavior, cursor pagination, edit conflict, delete/undo, duplicate save and direct settlement. Check no lagging preview can overwrite the latest form result.
- [ ] With open iOS feed, post from web, interrupt/restart the API, then remove the iOS user as owner and repeat with session revocation. Capture SSE-driven refresh, disabled writes, no stale data after removal, and successful return to the list. Inspect after relaunch and verify a late result does not repopulate a cleared snapshot. Remove the remaining 5U live-composition guard and verify both Debug and Release resolve live dependencies. Run the task gate and commit `feat(ios): connect ledger entry, balances and realtime`.

### Task 5B.5: Early iOS ↔ web acceptance on Simulator

**Files:** `docs/superpowers/runs/phase-5/{handoff-5b,progress,parity-matrix}.md`, `screens/5b/`. The handoff pins the verified code SHA. A later docs-only commit may contain its evidence.

**Fixture:** Use the Task 0 isolated recipe and two separate verified password accounts, shown below as Minh and Lan. Both clients use the same API, with the signed-in sessions isolated. The main journey has exactly two linked members, equal split, no earlier ledger entries, and approval disabled. Compare server integer amounts at each checkpoint.

| Exercise | Expected result |
|---|---|
| Minh creates the group and invite on iOS. Lan joins on web and claims Lan; repeat invite direction on another group with signed-out iOS using the Debug link entry. | Membership and role match on both clients. The pending invite resumes after sign-in. |
| Minh uses iOS quick entry to create `Ăn trưa` for `120.000 đ`, confirms Minh as payer and an equal split, and double-taps save. | The API preview shows `60.000 đ` per person. One transaction ID is created. Lan owes Minh `60.000 đ`. |
| Lan adds `Cà phê` for `40.000 đ` on web, paid by Lan and split equally. | iOS open feed refreshes via SSE and the API reports Lan owes Minh `40.000 đ`. |
| Open the first expense for editing on iOS; send a web edit under Minh's own web session to `140.000 đ`. Attempt to save the stale iOS draft. | iOS shows the conflict and reloads the newer state. Lan owes Minh `50.000 đ`. |
| Delete `Cà phê` from iOS as Minh; undo. | Debt changes to `70.000 đ`, then back to `50.000 đ`; undo restores the same ID. |
| Record a direct `50.000 đ` settlement from Lan to Minh on iOS. | API and both clients show zero net debt and one settlement. `pnpm db:check-balances` reports `All groups balanced`. |
| Interrupt/reconnect the API, then revoke Minh's iOS session from Minh's web account and sign in as Lan on iOS. Remove Lan from a separate test group while it is open on iOS. | Offline reads retain current content with writes disabled, then refresh. The old user's snapshots are cleared. Removed-group data does not reappear after relaunch. |

- [ ] Run the table on a fresh fixture, compare request IDs/transaction IDs and API before/after data, and replay the full stage gate. Exercise largest accessibility text size across S1–S13 and VoiceOver/Reduce Motion where the Simulator can verify them. Run string report, compare the actual package graph against architecture §5, and record performance evidence on a separate 500-entry group.
- [ ] Write the startup commands, web/iOS setup, numbered reproduction, expected/observed results, screenshots and empty owner-result field in `handoff-5b.md`. Confirm the isolation recipe disables real providers even when the developer's usual environment contains provider settings. Record remaining external checks and the unshipped 5D scope. If an item remains failed after the phase-run retry rule, label the checkpoint accordingly and retain the finding for final review.
- [ ] Commit `docs(run): hand off the Phase 5B Simulator checkpoint`. Notify the owner of the pinned revision and continue to 5C per the phase-run rules.

## Stage 5D — Complete baseline web parity

The Task 0 inventory defines full scope. Each task below closes its assigned rows and attaches separate UI, API and external evidence. New feature module names follow the architecture and the baseline entry points.

### Task 5D.1: Payment methods, QR and settlement requests

**Files:** new `PaymentsFeature/{Pay,PaymentDetails}/`, `LedgerFeature/Balances/`, `GroupsFeature/Members/`, payment and settlement domain/resources, AppShell, catalog, `apps/ios/App/Info.plist`.

- [ ] Port S14 and payment details from web `pay`, `balances` and the member editor. Use `/members/{memberId}/payment-methods` and `/settlement-requests` relative to the group. Render server-provided `qrPayload` in Core Image at 240 pt minimum with quiet zone. Add `Lưu mã QR` via add-only Photos access and preserve the copy, wallet, no-payment-details and direct recording paths.
- [ ] Exercise across iOS and web: request and confirm once, decline, cancel, permission refusal and missing payment info. A pending request leaves the ledger unchanged; confirmation creates the expected one settlement. Decode a screenshot with host tools and compare the payload byte for byte. Record device banking-app scan separately. Run the task gate and commit `feat(ios): add payment details, VietQR and settlement requests`.

### Task 5D.2: Search, categories, statistics and CSV

**Files:** new `StatisticsFeature/`, `LedgerFeature/GroupFeed/`, `GroupsFeature/GroupSettings/`, transaction/statistics/category/export domain/resources, AppShell, catalog.

- [ ] Port feed text/date/category filters, S16 statistics and its drill-downs, category administration and the existing CSV export action. Use the web query dimensions on the transactions and `/stats` routes, `/categories`, and `/export.csv`. Preserve exact scope from chart to filtered feed to export. Use native file sharing for CSV with a temporary protected file cleaned after use.
- [ ] With the same scoped API data, compare chart values, feed IDs, empty filter result and CSV rows. Verify category role restrictions, accents and recycled sharing state. Run the task gate and commit `feat(ios): add spending search, statistics and CSV sharing`.

### Task 5D.3: Funds and budgets

**Files:** new `PaymentsFeature/Fund/`, `GroupsFeature/GroupSettings/`, `LedgerFeature/{GroupFeed,QuickEntry,ExpenseForm}/`, fund/budget domain/resources, catalog and AppShell.

- [ ] Wire `/fund` and `/budget`. Port S17 funding, uses, breakdown and overdraft behavior, fund quick entry and form controls, budget setup and banners. Use returned official totals and warnings, preserving the current web visibility and editor permissions.
- [ ] Replay Phase 2 fund F0–F3 and budget acceptance rows, including threshold boundaries, different scopes and denied edits. Compare exact iOS, web and API figures and run `pnpm db:check-balances`. Run the task gate and commit `feat(ios): add group funds and budget tracking`.

### Task 5D.4: Receipt capture, attachments, item splitting and AI-assisted entry

**Files:** `LedgerFeature/{ReceiptCapture,ReceiptReview,QuickEntry,ExpenseForm}/`, attachment/receipt domain/resources, AppShell, catalog, `apps/ios/App/Info.plist`.

- [ ] Port Phase 3 entry, S18 and photo actions with capability handling. Use the system camera and PhotosPicker, resize off the main actor to a 2,000 px longest edge and re-encode JPEG at 0.85 without source location metadata. Upload via group `/attachments`, start and poll `/receipt-scans`, read photo content through the authenticated repository, and wire `/transactions/items/preview`. Preserve loading, partial corrections, manual fallback, cancel/remove and retry. Use current parse results for AI-assisted sentences.
- [ ] Import the four committed receipts through Simulator Photos with `AI_PROVIDER=fake`; replay the Phase 3 valid/invalid/failed outcome rows and preview-to-save parity, attachment deletion and unauthorized content refusal. Inspect re-encoded metadata with a local image metadata reader. Replay the full current sentence corpus including refusals and the fallback with AI disabled. Record physical camera and real AI separately. Run the task gate and commit `feat(ios): add receipt review, item splits and assisted entry`.

### Task 5D.5: Notification center, settings, mute and reminders

**Files:** new `NotificationsFeature/`, `AccountFeature/Account/`, `GroupsFeature/GroupSettings/`, `LedgerFeature/Balances/`, associated domain/resources, `AppShell`, catalog.

- [ ] Wire `/me/notifications`, unread count, read and notification settings, current group mute route and group `/reminders`. Port S19 inbox/bell, read/scope behavior, reminder controls, mail preferences and automatic reminder settings. Use the catalog by kind with the generic copy for unknown notification kinds; retain shared server-side delivery and web unsubscribe behavior.
- [ ] From web send an eligible reminder. Observe iOS count, row and read status plus console push, then repeat with mute, rate-limit and group removal. Replay applicable Phase 4 digest and mail preference evidence with the console adapter. Run the task gate and commit `feat(ios): add notification inbox and reminder controls`.

### Task 5D.6: Transaction detail, comments, disputes and approval

**Files:** `LedgerFeature/{TransactionDetail,GroupFeed,ExpenseForm}/`, `GroupsFeature/GroupSettings/`, transaction and approval domain/resources, AppShell, catalog.

- [ ] Port S20 and make it the baseline feed detail destination. Wire comment list/create/delete, dispute open/resolve, and reject/approve actions on the current transaction routes. Use plain SwiftUI text for comments. Respect the final Phase 4 soft-delete discussion behavior, policy settings, action permissions, reasons, version and API counted ledger state. Keep edit behind the correct role/action.
- [ ] Replay Phase 4 comment/dispute and approval cases against owner, editor and viewer across clients, including duplicate and concurrent decisions, a wrong role, soft-delete cases, and below/at-threshold amounts. Compare ledger before decision, after approval, after rejection and after edit. Run the task gate and commit `feat(ios): add transaction discussion and approvals`.

### Task 5D.7: Telegram and Stage 5D gate

**Files:** `AccountFeature/Account/`, `GroupsFeature/GroupSettings/`, chat-link and pairing domain/resources, AppShell routing, catalog and run evidence.

- [ ] Port account identity and group link management. Use `/me/chat-identities/telegram/pairings` and its status/confirm/cancel routes under the same iOS Bearer session that initiates the pairing. Hand off only the server-provided Telegram start link. Keep browser-initiated `/link/telegram` in its original browser session. Group chat operations use the current group chat-link routes and the owner role.
- [ ] Replay the corrected two-sided pairing using console Telegram and local webhook fixtures. Verify completion, cancel, expiry, wrong-session denial and legacy-link refusal. Exercise role-aware group link/unlink and shared commands. Record the real Telegram client flow as external.
- [ ] Replay 5C simulated push with target destinations now available (transaction detail, balances and inbox), including inaccessible or unknown targets. Run the full 5D stage gate and update the parity inventory for every assigned row. Commit `feat(ios): add Telegram management and verify feature parity`.

## Stage 5E — Release and final acceptance

### Task 5E.1: Release build, metadata and bundled assets

**Files:** `apps/ios/Config/Release.xcconfig`, `apps/ios/App/{Info.plist,PrivacyInfo.xcprivacy,Assets.xcassets,SongPhang.entitlements}`, app target resources, DesignSystem typography/resources.

- [ ] Keep `vn.songphang.app`, display name `Sòng Phẳng`, version `1.0.0` and build `1` as current defaults. Use `https://example.invalid/api/v1` for unsigned local Release compilation and document the owner-supplied HTTPS API/web hosts and signing overrides. Confirm the placeholder is replaced in the owner's checklist before archival. Retain localhost ATS exception in Debug only. Add the Phase 7A logo if available, otherwise the four-shape fallback. Bundle licensed compatible Be Vietnam Pro files from Task 0 if available. Record and surface unresolved font substitution for owner approval.
- [ ] Populate the privacy manifest from actual collected data and required-reason API use, with no tracking. Run the overview's build command with `-configuration Release` before the destination and `CODE_SIGNING_ALLOWED=NO` before `build`. Inspect the produced Info.plist and bundled manifest, validate entitlement/configuration separation, and confirm Release cannot access fakes. Exercise the version gate with the live Debug app and local API. [Apple privacy manifest guidance](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk).
- [ ] Run the task gate and commit `chore(ios): prepare Release configuration and app metadata`.

### Task 5E.2: TestFlight runbook and final evidence

**Files:** `docs/runbooks/testflight.md`, `apps/ios/README.md`, `apps/ios/Store/listing.vi.md`, `docs/superpowers/runs/phase-5/{manual-checks,parity-matrix,progress,decisions}.md`.

- [ ] Write owner-led TestFlight steps for IDs, domain association, signing, Apple/APNs credentials, privacy/support URLs, build settings, archive, upload and tester setup. Use spec §6's Vietnamese name and subtitle and approved landing/product copy. Identify missing owner inputs explicitly. [Apple TestFlight overview](https://developer.apple.com/testflight/).
- [ ] Replay the full 5B checkpoint on the final code SHA and close all findings from its owner review that have been reported. Compare the latest applicable `main` user-facing journeys with Task 0's baseline, and take deltas to the advisor/owner for reconciliation before claiming parity. Check the actual parity matrix for unmapped or omitted journeys, a local pass/fail for each locally testable row, and explicit pending external actions. Run the full final stage gate, Release bundle inspection, catalog compare, warning-as-error build, architecture review and supported performance checks. Report any local unmet condition as a failed or unverified gate.
- [ ] Give the owner fresh local reproduction and physical device steps for real Apple/Google login, APNs, HTTPS links, camera, banking-app QR, accessibility, device performance and TestFlight. Include remaining external Phase 2–4 checks and the deferred real AI decision. Final owner acceptance includes confirmation of the early journey at its checkpoint or final replay. Record owner fields unmarked until verified. Commit `docs(run): record Phase 5 parity and owner release handoff`.
