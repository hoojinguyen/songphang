# iOS Codebase Architecture — Design

Date: 2026-11-16. Status: approved by the project owner on 2026-11-16.

This document designs the inside of the iOS repository. It refines `2026-11-15-phase-5-ios-design.md` (the "phase 5 spec"): everything there about the API, sign-in, push, strings, release and verification still stands. Section 12 lists the lines of that spec and its plan that this document replaces.

## 1. Intent

The project owner is not an iOS developer and will read, review and extend this codebase mostly through agents. The codebase must therefore explain itself: a reader who knows the web repository should find the same ideas under familiar names, and the compiler, not convention, should stop a change from landing in the wrong place.

**Goals**

- Clean Architecture's dependency rule, enforced by the compiler: screens know the domain, never the network, the Keychain or generated code.
- Adding a feature means adding files in predictable places, not editing shared ones.
- Current, stable Apple technology only; no pattern or library kept for historical reasons.
- Because the project writes no automated tests, the type system and Xcode Previews carry the checking.
- The application feels instant: it opens onto content, scrolls without hitches, and answers every tap at once (section 8).

**Non-goals**

- A use case class for every action, a dependency-injection container, coordinators, or any layer that only forwards calls.
- Sharing code with Android, or preparing for it.
- Working offline: the last-known snapshot of section 8.1 is for showing content at once, not for writing or queueing changes.
- iPad layout, widgets (unchanged from the phase 5 spec).

**Anti-goals**

- A feature that imports another feature, the generated client, or the Keychain.
- A boundary that exists only as a folder name.
- A skeleton on every launch, or an amount estimated on the device to look fast.
- An abstraction with one implementation and no present reason (AGENTS.md section 7).

## 2. Constraints

- The server owns all business logic. The application computes no official amount; quick-entry sentences are parsed by the server.
- No third-party dependency beyond Apple's three OpenAPI packages (phase 5 spec 5.1).
- No automated tests (AGENTS.md section 6). Gate: `xcodebuild build` with warnings as errors, and `swift format lint --strict`.
- Money is an integer end to end.
- Toolchain on the owner's machine, verified 2026-11-16: Xcode 27.2, Swift 6.4.2, iOS SDK 27.2, `swift-format` 6.4.4.

## 3. Approaches

| | A. Textbook Clean Architecture | B. Right-sized Clean, compiler-enforced modules | C. The 15 November draft |
|---|---|---|---|
| Shape | Domain / Data / Presentation; one use case per action; DI container; coordinators | One Swift package with several modules; a module can import only what the manifest allows | One module, layers as folders |
| Layer boundary | Enforced if modularised | Enforced: a violation does not compile | Convention only |
| Files per screen | 6–8 | 2–3 | 2 |
| Fit with "simplicity first" | Poor: most layers only forward, because the logic is on the server | Good | Good at first, erodes as the app grows |

Also considered and dropped: The Composable Architecture (third-party, steep to learn, a 2.0 rewrite announced).

**Chosen by the project owner on 2026-11-16: B.** It keeps the part of Clean Architecture that pays here (one-way dependencies, a domain free of frameworks, swappable data sources) and drops the parts that would only forward calls in a thin client.

## 4. Technology

| Choice | Decision | Why |
|---|---|---|
| Minimum iOS | **26** (was 17) | About 78% of devices run iOS 26 or newer and the share grows until release (Statcounter, 2026-11-03). One code path, no availability branches, current SwiftUI APIs and system appearance. iOS 27-only would reach about 17% |
| Language | Swift 6 language mode in every module; complete data-race checking | The compiler replaces the tests the project does not write |
| Default isolation | `MainActor` by default in UI modules (`DesignSystem`, features, `AppShell`); non-isolated in `Domain`, `Repositories` | UI code needs no annotations; background work is explicit |
| Upcoming features | `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, `InferIsolatedConformances` (all reported as supported by the installed compiler) | The two import features stop a module from leaking its dependencies to its importers, which is what makes the boundaries real |
| UI | SwiftUI only; `@Observable` models; `NavigationStack` driven by a typed route value | No UIKit, Combine, or coordinator objects |
| Errors | Typed throws: repository functions are `throws(AppError)` | A screen must handle every error case or fail to compile |
| API client | `swift-openapi-generator` as a build plugin (unchanged) | |
| Persistence | No database. The session token in the Keychain (unchanged); last-known read responses as protected files (section 8.1) | Chosen by the owner on 2026-11-16 so the application opens onto content |
| Dependency wiring | Plain initialisers. One composition root builds the live repositories and hands each screen model exactly what it needs | A missing dependency is a compile error, not a runtime crash |

## 5. Modules

One Swift package, `SongPhangKit`, holds all code. The Xcode application target contains only the `@main` entry point, assets, `Info.plist`, entitlements and the privacy manifest.

```
SongPhang (Xcode app target: entry point only)
 └─ AppShell           composition root, navigation, deep links, push handling
     ├─ Repositories   live implementations: API calls, cache, event stream, Keychain
     │   ├─ GeneratedAPI   code generated from openapi.json; nothing hand-written
     │   └─ Domain
     ├─ AuthFeature ─┐
     ├─ GroupsFeature│   each: Domain + DesignSystem + PreviewSupport
     ├─ LedgerFeature│   never: another feature, Repositories, GeneratedAPI
     └─ AccountFeature┘
DesignSystem → Domain
PreviewSupport → Domain
Domain → nothing (Foundation only)
```

| Module | Holds | Web counterpart |
|---|---|---|
| `Domain` | The application's own types (`User`, `ExpenseGroup`, `Member`, `Role`, `Money`, `LedgerTransaction`, `Balance`, `ActivityItem`, `Invite`, `QuickEntryReading`, `SharePreview`, `GroupEvent`), `AppError`, `Loadable`, `IdempotencyKey`, and the repository protocols | types exported by `packages/contract` |
| `GeneratedAPI` | `openapi.json`, the generator configuration, generated types and client | `packages/contract` as consumed by the web |
| `Repositories` | One implementation per repository protocol; mapping from generated types to `Domain`; `SnapshotStore`; `EventStream`; `Keychain`; request middleware (token, `X-App-Version`); error mapping | `apps/web/src/lib/*.ts` |
| `DesignSystem` | Color and type tokens, `MemberShapeView`, buttons, cards, `MoneyText` and the money formatter, the four state views, the String Catalog and fonts | `components/ui`, `globals.css`, `messages/vi.ts` |
| `PreviewSupport` | In-memory fake repositories and sample domain values, for Xcode Previews and the debug gallery | none |
| `AuthFeature` | Sign-in, register, forgot password, verify-email banner | `app/login`, `register`, … |
| `GroupsFeature` | Group list, create group, members, group settings, join | `app/page.tsx`, `groups/new`, `g/[groupId]/members`, `settings`, `join` |
| `LedgerFeature` | Group feed, balances, activity, quick entry, expense form, settle | `g/[groupId]/page.tsx`, `balances`, `activity`, `tx/*`, `settle` |
| `AccountFeature` | Account, devices, password, delete account | `app/account` |
| `AppShell` | `AppDependencies`, `Route`, the root view and navigation stack, the session model, universal-link and push routing, the "update required" screen | `app/layout.tsx`, session guard |

Names avoid collisions with Apple's: the domain types are `ExpenseGroup` and `LedgerTransaction` because SwiftUI already defines `Group` and `Transaction`; the module is `Repositories` because Foundation defines `Data`.

Later phases add modules beside these (`PaymentsFeature`, `StatisticsFeature`, `NotificationsFeature`); they do not grow existing ones.

## 6. Rules the compiler enforces

1. `Package.swift` is the dependency rule. Each target lists exactly the modules in section 5; nothing else is importable.
2. Only `Repositories` imports `GeneratedAPI`. A generated type never appears in a `Domain` type or a feature.
3. Only `AppShell` imports `Repositories`. Features receive repository protocols through initialisers.
4. Features do not import each other. A screen that leads into another feature reports it through a closure (`onOpenGroup: (ExpenseGroup.ID) -> Void`); `AppShell` turns it into a `Route`.
5. Every declaration is `internal` unless another module needs it; `public` is the module's reviewed surface.
6. `Domain` imports only Foundation: no SwiftUI, no networking.

## 7. Inside the layers

### 7.1 Domain

- Plain `struct` and `enum` values, all `Sendable`, `Identifiable` where listed, with typed identifiers (`ExpenseGroup.ID` is not interchangeable with `Member.ID`).
- `Money` wraps a 64-bit integer of đồng. It offers addition, subtraction and comparison only; there is no multiplication or division, so a share cannot be computed on the device by accident.
- Server enumerations become Swift enums with an explicit fallback case (`Role.unknown`, `MemberShape.circle` as the drawing fallback), as the additive-only contract requires.
- `AppError`: `.offline`, `.unauthorized`, `.upgradeRequired`, `.conflict`, `.rateLimited`, `.api(code: String, status: Int)`, `.unexpected`. The message shown to the user is chosen in the feature from the String Catalog, by error code, exactly as the web does.
- `Loadable<Value>`: `.loading`, `.loaded(Value)`, `.failed(AppError)`. A screen cannot be both loading and failed. "Empty" is a loaded value that is empty.
- Repository protocols, one per resource area, mirroring `apps/web/src/lib`: `AuthRepository`, `GroupsRepository`, `MembersRepository`, `InvitesRepository`, `TransactionsRepository`, `BalancesRepository`, `ActivityRepository`, `QuickEntryRepository`, `GroupEventsRepository`, `DevicesRepository`. Every function is `async throws(AppError)` and speaks only domain types.

### 7.2 Repositories

- One file per protocol implementation; one mapping file per resource (`GroupMapping.swift`). Mapping is the only place generated types are read.
- `SnapshotStore` is an actor private to this module (section 8.1). Features never see it; they see two read functions per resource: `lastKnownGroups()`, which never throws and never touches the network, and `groups()`, which fetches and updates the store.
- `EventStream` reads the group's server-sent events and yields `GroupEvent` (`.changed`, `.removed`, `.reconnected`) through `GroupEventsRepository`.
- `Keychain` and the token are private to this module. No function returns the token to a caller outside it.
- One function maps a failed call to `AppError`; `.unauthorized` also clears the session.

### 7.3 Features

Each screen is a folder with two files, plus sub-views when the view grows:

```
GroupsFeature/GroupList/
  GroupListModel.swift   @Observable; state, intents, calls repositories
  GroupListView.swift    renders the model; ends with #Preview blocks
```

```swift
@Observable
public final class GroupListModel {
    private(set) var groups: Loadable<[ExpenseGroup]> = .loading
    private let repository: any GroupsRepository

    public init(repository: any GroupsRepository) { self.repository = repository }

    private(set) var refreshError: AppError?

    func load() async {
        if let lastKnown = await repository.lastKnownGroups() { groups = .loaded(lastKnown) }
        do throws(AppError) {
            groups = .loaded(try await repository.groups())
            refreshError = nil
        } catch {
            if case .loaded = groups { refreshError = error } else { groups = .failed(error) }
        }
    }
}
```

- A model holds state and intents. It formats nothing and lays out nothing. A view holds no logic beyond choosing what to show for the model's state.
- Each view file has a Preview for every state it can be in (loading, loaded, empty, failed), built with `PreviewSupport`. With no tests, these Previews are how a screen is checked without a server.
- A use case type is introduced only when one intent coordinates two or more repositories and is needed by two or more models. Until then the model calls the repository directly.
- A form's model creates its `IdempotencyKey` once, in its initialiser.

### 7.4 AppShell

- `AppDependencies` is a struct of the live repositories, built once at launch.
- `Route` is one `Hashable` enum listing every destination. The root view owns the `NavigationStack` path; a function maps each `Route` to its screen and passes the model its repositories. This function is the only place screens are constructed.
- Universal links and push targets are parsed into a `Route` by one function that accepts only known path shapes; anything else opens nothing.
- `SessionModel` (`.loading`, `.signedOut`, `.signedIn(User)`) decides between the sign-in flow and the main stack.

## 8. Performance

The architecture already puts the heavy work in the right place; this section makes it a rule and makes it measurable.

### 8.1 Opening onto content: last-known snapshots

- `SnapshotStore` keeps the last successful response of each read: in memory for the running application, and as one file per query key for the next launch. It stores the response as the generated types encode it, so `Domain` stays free of serialisation and the one mapping path is reused. A file that fails to decode is deleted and treated as absent.
- Covered: the group list and, per group, the first page of the feed, the balances, the members and the first page of activity. Kept for the 20 most recently opened groups.
- Files live in the caches directory under a folder named by the user's id, excluded from backup, with file protection "complete until first user authentication". The folder is deleted on sign-out, on `.unauthorized`, on account deletion; a group's files are deleted on its `removed` event or a 404.
- A screen shows the snapshot at once and fetches in the same moment. A failed refresh never replaces shown content: it sets `refreshError`, which the screen shows as the offline banner or the retry line. A skeleton appears only when there is no snapshot.
- Every amount shown is still one the server sent. Writing stays disabled while offline, as before. Forms never start from a snapshot: editing fetches the transaction first, because it needs the current `version`.

### 8.2 Rules

| Rule | How it is held |
|---|---|
| Nothing slow on the main actor | Networking, decoding, mapping and file access live in `Repositories`, which is not main-actor isolated; UI modules cannot call the generated client or the file system because they cannot import them |
| Nothing before the first frame | Launch reads the token and the group-list snapshot, then draws. No third-party SDK; all modules are linked statically into the one binary |
| Long lists load by page | The feed and activity use the API's `cursor` and `nextCursor` (50 per page), in lazy containers with stable identifiers; the next page loads when the last rows appear |
| Redraw only what changed | `@Observable` tracks per property; a row is its own view taking a value; a realtime `changed` event refetches only the resources it names |
| Load in parallel, cancel when leaving | A screen's independent reads start together (`async let`); every load is tied to the view's task and is cancelled when the screen disappears |
| A tap answers at once | The control shows its pressed and pending state in the same frame; the amount appears when the server answers. No optimistic amount, no local estimate |
| Typing stays smooth | `parse` and `preview` are debounced 300 ms and each new request cancels the one before it |
| Images are sized before they are shown or sent | Receipts are downsampled to the displayed size off the main actor; uploads as the phase 5 spec says |

### 8.3 Budgets and how they are checked

Measured in the Simulator at each stage gate on a group seeded with 500 transactions, recorded in `progress.md` with the real numbers:

| Measure | Budget | Tool |
|---|---|---|
| Launch to first content, with a snapshot | under 400 ms | `xctrace` App Launch template |
| Scrolling the 500-transaction feed top to bottom | no hitch reported | `xctrace` SwiftUI and Hitches instruments |
| Main-actor hangs during the phase 1 journey | none over 100 ms | Hangs instrument |
| Group screen, tap to content, with a snapshot | same frame as the push transition | by eye, recorded as observed |

Simulator numbers show regressions, not what a phone does. Cold start, scrolling and battery on a real device stay under "Not verified" for the agent and on the owner's manual-check list.

## 9. Extending the codebase

| To add | Do |
|---|---|
| A screen in an existing area | A folder with `Model` and `View` in that feature module; a case in `Route`; one line in `AppShell`'s route function |
| A new API resource | The domain type and protocol in `Domain`; the implementation and mapping in `Repositories`; a fake in `PreviewSupport`; a field in `AppDependencies` |
| A new feature area | A new target in `Package.swift` depending on `Domain`, `DesignSystem`, `PreviewSupport`; add it to `AppShell`'s dependencies |
| A visual component used by two or more features | `DesignSystem` |
| A new server enumeration value | Nothing breaks: it maps to the fallback case until the application handles it |

## 10. Repository layout

Everything is under `apps/ios/` of this repository (ADR-033).

```
SongPhang.xcodeproj
App/                 SongPhangApp.swift, Info.plist, Assets.xcassets, PrivacyInfo.xcprivacy, entitlements
Config/              Debug.xcconfig, Release.xcconfig
SongPhangKit/
  Package.swift
  Sources/
    Domain/          Models/, Repositories/ (protocols), AppError.swift, Loadable.swift, Money.swift
    GeneratedAPI/    openapi.json (a link to packages/contract/openapi.json), openapi-generator-config.yaml
    Repositories/    one folder per resource, Snapshots/, Realtime/, Session/, Transport/
    DesignSystem/    Tokens/, Components/, States/, Resources/ (Localizable.xcstrings, Fonts/)
    PreviewSupport/  Fakes/, Samples/
    AuthFeature/ GroupsFeature/ LedgerFeature/ AccountFeature/    one folder per screen
    AppShell/
Scripts/             check-strings.sh
AGENTS.md
```

`AGENTS.md` of the iOS repository repeats sections 6 and 8.2 of this document as hard rules and the file-size limits of the main repository's section 7.

## 11. Left to the builder

- Exact fields of each domain type (they follow `openapi.json`), and file names inside a screen folder.
- Whether the String Catalog is read through generated symbols or a small accessor, depending on what the toolchain offers for package resources.
- If an upcoming-feature flag in section 4 cannot be applied to `GeneratedAPI` because of the generated code, it is dropped for that module only and recorded in `decisions.md`.
- How the system's iOS 26 appearance is applied to navigation chrome; custom components keep the web's tokens.
- The snapshot file format and naming; transitions.
- If a budget of section 8.3 cannot be measured with `xctrace` in the Simulator, the measure is recorded as not verified with the reason, not replaced by an estimate.

Calls made by the advisor in this document, for the owner to check: four feature modules by area rather than one module or one per screen; `AppShell` inside the package; initialiser injection instead of SwiftUI environment values; the names `ExpenseGroup`, `LedgerTransaction`, `Repositories`; `Money` without multiplication or division; the five upcoming-feature flags; snapshots stored as encoded API responses, 20 groups kept; the budgets of section 8.3.

## 12. Changes to standing documents

| Document | Change |
|---|---|
| Phase 5 spec, 1 and 5.1 | Minimum iOS 26. The "State" row is replaced by a reference to this document. The non-goal "working offline beyond what is already in memory" and "No database on the device" become: no database, no offline writing, last-known snapshots on disk |
| Phase 5 spec, 7 | The stage gate gains the measures of section 8.3 |
| Phase 5 spec, 8 | "File layout inside the iOS project" and "model and view names" are removed from the builder's list |
| Phase 5 spec, 9 | Adds ADR-032 for the iOS architecture (dependency rule enforced by package modules; last-known snapshots) |
| Phase 5 plan, `5b-5e-app.md` | Decision 3 and "Structure of the iOS repository" are replaced by sections 5 and 9 here; each task's **Files** line is rewritten to module paths; task 5B.1 gains the package manifest with all targets and `PreviewSupport`; decision 4 (the in-memory cache) is replaced by section 8.1; the stage gates gain section 8.3; the `APIClient` actor and `SessionStore` become `Repositories` internals and `AppShell.SessionModel` |
| `docs/04-adr.md` | Written during the phase 5 run, as the phase 5 spec's section 9 lists: ADR-014 gains the versions of section 4; ADR-032 |

The phase 5 spec and plan were updated with these changes on 2026-11-16.

## 13. Delivery in two stages (added 2026-11-16, ADR-033)

The owner chose to build the interface first, in parallel with the API and web work.

| Stage | Builds | Runs on | Plan |
|---|---|---|---|
| 5U — interface | `Domain`, `DesignSystem`, `PreviewSupport`, the feature modules, `AppShell`; every phase 1 screen in every state | Scripted fakes in `PreviewSupport`; no server | `docs/superpowers/plans/2026-11-16-ios-ui.md` |
| Integration | `GeneratedAPI`, `Repositories`; real sign-in, snapshots, realtime; then push, links, later phases, release | The API, after stage 5A | The phase 5 plan, whose stage 5B the advisor rewrites as integration before that run |

- The fakes hold literals only. A fake never divides or allocates money; every amount it returns is copied from a named document. Unscripted input is refused, not estimated.
- The architecture is what makes the split cheap: the integration stage replaces the fakes at the composition root and does not edit a screen unless a domain type changed.
- The interface stage records the commit it ported from. The integration stage diffs `apps/web` and `packages/contract` against it to list what must be brought up to date.
- If the generator's build plugin does not follow the link to `openapi.json`, the integration stage copies the file with a script and adds a check that the copy is current; recorded as a decision.
