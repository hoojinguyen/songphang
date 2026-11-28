# Sòng Phẳng iOS — Agent Working Rules

These rules add to the root `AGENTS.md`, which you must read first and which still applies in full (language policy, roles, the six-step workflow, no automated tests, security, git, phase runs). Where the two differ on Swift-specific matters, this file wins.

The design behind every rule here is `docs/superpowers/specs/2026-11-16-ios-codebase-architecture-design.md` ("AD"). Read it completely before writing Swift.

## 1. Write boundary

Write only under `apps/ios/` and the run directory your plan names. The rest of the repository is read-only reference: the web screens you port from (`apps/web`), the strings (`apps/web/src/messages/vi.ts`) and the API contract (`packages/contract`). Never edit, format or "fix" a file outside the boundary; record what you saw under "Out of scope".

## 2. Automated gate

`pnpm check` does not cover this directory. Before every commit, from the repository root:

- `xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `BUILD SUCCEEDED`
- `xcrun swift-format lint --strict --recursive apps/ios` → no output

Do not silence a warning or the linter with an attribute, a comment directive, `!`, `try!`, `as!`, `@unchecked Sendable` or `nonisolated(unsafe)`. Do not install Xcode, runtimes or tools.

## 3. Dependency rule (AD sections 5 and 6)

`SongPhangKit/Package.swift` is the rule. Each target depends on exactly these modules:

| Module | May import |
|---|---|
| `Domain` | Foundation only |
| `GeneratedAPI` | Apple's OpenAPI runtime packages |
| `Repositories` | `Domain`, `GeneratedAPI` |
| `DesignSystem` | `Domain` |
| `PreviewSupport` | `Domain` |
| A feature module (`AuthFeature`, `GroupsFeature`, `LedgerFeature`, `AccountFeature`, …) | `Domain`, `DesignSystem`, `PreviewSupport` |
| `AppShell` | everything above |

- A feature never imports another feature, `Repositories` or `GeneratedAPI`.
- A generated type never appears in `Domain` or in a feature.
- Only `AppShell` constructs screens and repositories.
- Everything is `internal` unless another module needs it.
- If code does not compile where you put it, it is in the wrong module. Move the code; never add a dependency between existing modules. This is not a "decide and record" matter.

## 4. Where things go (AD section 9)

| To add | Do |
|---|---|
| A screen in an existing area | A folder in that feature module with `<Name>Model.swift` and `<Name>View.swift`; a case in `Route`; one line in `AppShell`'s route function |
| A new API resource | Type and protocol in `Domain`; implementation and mapping in `Repositories`; fake and samples in `PreviewSupport`; a field in `AppDependencies` |
| A new feature area | A new target depending on `Domain`, `DesignSystem`, `PreviewSupport`; add it to `AppShell` |
| A visual component used by two or more features | `DesignSystem` |

A model is `@Observable`, receives repository protocols through its initialiser, holds state and intents, and formats nothing. A view renders the model's state and ends with one `#Preview` per state (loading, loaded, empty, failed). A use case type appears only when one intent coordinates two or more repositories and two or more models need it.

## 5. Money

- `Money` is a 64-bit integer of đồng with addition, subtraction and comparison only. Never add multiplication or division to it, and never convert it to a floating-point number.
- The application never computes a share, a balance, a settlement or a QR payload. It shows what the server sent. This includes fakes: a fake returns literals transcribed from captured API responses and refuses input it has no literal for.
- One formatter produces `150.000 đ`.

## 6. Performance (AD section 8.2)

- Nothing slow on the main actor: networking, decoding, mapping and file access live in `Repositories`.
- Nothing runs before the first frame except reading the token and the group-list snapshot.
- Long lists load by page in lazy containers with stable identifiers.
- A row is its own view taking one value; a realtime event refetches only the resources it names.
- Independent reads start together; every load runs in the view's `.task` and is cancelled with the screen.
- A tap shows its pending state in the same frame; an amount appears only when the server answers.
- `parse` and `preview` are debounced 300 ms and each request cancels the one before.
- A screen shows its last-known value at once, then fetches. A failed refresh never replaces shown content.

## 7. Security

- The session token lives in the Keychain and inside `Repositories` only. It is never returned by a `public` declaration, logged, put in a URL, or stored in `UserDefaults`.
- A link or push target becomes a `Route` through one function that accepts only known path shapes.
- No analytics, crash-reporting or other third-party SDK.

## 8. Strings and screens

- User-visible strings are Vietnamese, in one String Catalog, identical character for character to `apps/web/src/messages/vi.ts`. Never reword a string that exists on the web.
  - Exception for UI/UX v3 (ADR-044): during Phases 5.6–5.8 a string may differ from the web file. Record every added, changed or removed string in the run's `copy-changes.md` (key, old value, new value, reason); Phase 5.9 applies them to the web file and ends the exception.
- When a web screen exists, the iOS screen has the same content, order and strings; platform conventions replace only navigation chrome and controls.
- Dynamic Type to the largest accessibility size without clipping; VoiceOver labels on every shape; Reduce Motion replaces motions with instant changes.

## 9. Exercising

Run the application in the iOS Simulator and record screenshots (`xcrun simctl io booted screenshot`) in the run directory. A result you did not observe goes under "Not verified", never in the result.

## 10. Git

Commits use `type(ios): short description`. One commit per task, after the gate passes. No push.
