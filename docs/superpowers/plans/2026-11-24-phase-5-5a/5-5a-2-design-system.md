# Wave 5.5A — Stage 5.5A.2: Design System v2 (Web + iOS)

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md).

### Task 5.5A.2.1: Web Design System v2, Dark Mode, Tabular Numerals & `TD-001` / `TD-004`

**Files:**
- `apps/web/src/app/globals.css`
- New `apps/web/public/theme-init.js`
- `apps/web/src/app/layout.tsx`
- New `apps/web/src/lib/theme.ts`
- `apps/web/src/lib/money.ts`
- `apps/web/src/components/ui/{TextField,Card,Button,SegmentedControl}.tsx`
- New `apps/web/src/components/account/AppearanceCard.tsx`
- `apps/web/src/app/account/page.tsx`
- `apps/web/next.config.ts`
- `apps/web/src/messages/vi.ts` (if adding Web strings early; keep paired with `5.5A.2.2` before final `check-strings.sh`, or add all new strings in `5.5A.2.2` — note if `vi.ts` changes in `5.5A.2.1`, update `Localizable.xcstrings` in `5.5A.2.2`; keep `5.5A.2.1` self-contained by putting all Wave 5.5A strings in `vi.ts` AND `Localizable.xcstrings` in `5.5A.2.2`, or updating `Localizable.xcstrings` together with `vi.ts` whenever new keys are added so `check-strings.sh` stays green after every commit!).

**Note on commit gate hygiene:** Add any new `vi.ts` keys together with their identical `Localizable.xcstrings` entries in the same commit so `./apps/ios/Scripts/check-strings.sh` remains green at every commit boundary.

**Interfaces & Rules:**
- **Light & Dark tokens (`apps/web/src/app/globals.css`):**
  - Define `@theme` semantic tokens backed by `:root` (Light) and `html[data-theme="dark"]` plus `@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) ... }` (Dark) matching [Overview spec §3.1–3.2](../../specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md#L48-L88) (`bg`, `surface`, `surface-elevated`, `sunken`, `border-subtle`, `ink`, `ink-raised`, `muted`, `placeholder`, `on-ink`, `on-ink-muted`, `dashed`, `accent`, `on-accent`, `credit`, `credit-soft`, `debt`, `debt-soft`, `warning`, `warning-soft`, Light/Dark member colors, Light/Dark phrase highlight colors).
  - Add `color-scheme: light` / `dark` appropriately on `html` so native inputs, date pickers, and scrollbars match the active theme.
  - Ensure all buttons and accents using `--color-accent` use `--color-on-accent` (`#1C1B22`) in both Light and Dark modes, and buttons using `--color-ink` fill use `--color-on-ink`.
- **Zero-FOUC Theme Init (`apps/web/public/theme-init.js` + `apps/web/src/app/layout.tsx`):**
  - Do **not** use `dangerouslySetInnerHTML` (`AGENTS.md` §9).
  - Serve a tiny static script `apps/web/public/theme-init.js` loaded synchronously in `<head>` (or Next.js `<Script strategy="beforeInteractive" src="/theme-init.js" />`) that reads `localStorage.getItem("sp-theme")`, validates against `"light" | "dark" | "system"`, and sets `document.documentElement.dataset.theme` before first paint.
  - Provide `apps/web/src/lib/theme.ts` for reading/updating `"system" | "light" | "dark"` cleanly from `AppearanceCard.tsx` (`Giao diện`: `Theo hệ thống`, `Sáng`, `Tối`).
- **Placeholder Contrast (`TD-004`) & Tabular Numerals:**
  - Update `TextField.tsx`, search inputs, and textarea/form fields to apply `placeholder:text-placeholder`.
  - Apply `tabular-nums` (`font-variant-numeric: tabular-nums`) across monetary columns and balance components.
- **`TD-001` Local Dev Origin Fix (`apps/web/next.config.ts`):**
  - Populate `allowedDevOrigins` **only** when `process.env.NODE_ENV === "development"` using hostnames parsed via `URL.parse` from `process.env.WEB_ORIGIN` and optional comma-separated `process.env.ALLOWED_DEV_ORIGINS` (document optional dev variable in `.env.example` and `README.md`). Never relax production checks or allow wildcard `*`.

**Exercises:**
- [ ] Run Next.js dev server with `WEB_ORIGIN="http://macbook.local:3000"`; verify `curl` / browser asset fetches from `macbook.local:3000` return `200` (not `403`), while an unconfigured foreign `Host` / `Origin` still returns `403`.
- [ ] Toggle `Giao diện` on `/account` between `Theo hệ thống`, `Sáng`, and `Tối`; reload the page under `Tối` and verify zero light-flash, crisp placeholder text, and readable contrast across `/login`, `/groups/new`, and `/account`.
- [ ] Verify `pnpm check` and `pnpm build` pass, and commit: `feat(web): add Design System v2 dark mode, theme toggle, and dev origin fix`.

---

### Task 5.5A.2.2: iOS Design System v2 (`Be Vietnam Pro` `.ttf`, Dynamic `Tokens`, `Haptics`, `TD-004` & String Parity)

**Files:**
- `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Fonts/{BeVietnamPro-Regular.ttf,BeVietnamPro-Medium.ttf,BeVietnamPro-SemiBold.ttf,BeVietnamPro-Bold.ttf,BeVietnamPro-ExtraBold.ttf,BeVietnamPro-Black.ttf,LICENSE.txt}`
- `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` and `apps/web/src/messages/vi.ts`
- `apps/ios/SongPhangKit/Sources/DesignSystem/Tokens/{Tokens,Typography}.swift`
- `apps/ios/SongPhangKit/Sources/DesignSystem/Components/{SPTextField,MoneyText}.swift` and new `Haptics.swift`
- `apps/ios/SongPhangKit/Sources/AccountFeature/Account/AccountView.swift`
- `apps/ios/SongPhangKit/Sources/AppShell/RootView.swift`
- `apps/ios/SongPhangKit/Sources/GroupsFeature/CreateGroup/CreateGroupView.swift` and `apps/ios/SongPhangKit/Sources/LedgerFeature/GroupFeed/GroupFeedSubViews.swift` (update placeholder prompts to `Tokens.placeholder` if not already routed via `SPTextField`)

**Interfaces & Rules:**
- **Bundled `Be Vietnam Pro` `.ttf` fonts:**
  - Verify static `.ttf` weights (`400` Regular, `500` Medium, `600` SemiBold, `700` Bold, `800` ExtraBold, `900` Black) and `LICENSE.txt` (`SIL OFL 1.1`) in `DesignSystem/Resources/Fonts/`. (`Package.swift` already processes `Resources`).
  - Implement `Typography.registerFontsIfAvailable()` using `CTFontManagerRegisterFontsForURL(..., .process, ...)` idempotently on app launch (`RootView` / `SongPhangApp`) and update `Typography` styles (`heroNumber`, `pageTitle`, `sectionTitle`, `screenHeaderTitle`, `bodyBold`, `body`, `subheadlineBold`, `subheadline`, `captionBold`, `caption`) to `Font.custom(...)` with `relativeTo:` Dynamic Type text styles so accessibility font sizes scale accurately.
- **Dynamic Light & Dark `Tokens.swift`:**
  - Add a clean private helper `dynamicColor(lightHex:darkHex:)` backed by `UIColor { $0.userInterfaceStyle == .dark ? ... : ... }` for every token in [Overview spec §3.1–3.2](../../specs/2026-11-24-ui-ux-v2-and-5-5-overview-design.md#L48-L88), adding `surfaceElevated`, `borderSubtle`, `placeholder`, `onInk`, `onAccent`, `credit`, `creditSoft`, `debt`, `debtSoft`, `warning`, `warningSoft`, and Dark member/phrase colors.
- **Placeholder Contrast (`TD-004`):**
  - Update `SPTextField`, `NewMemberInputRow`, `FeedSearchBarView`, and Quick Entry input prompts to use `prompt: Text(...).foregroundStyle(Tokens.placeholder)` so prompts remain legible against `Tokens.surface` in Light, Dark, and Increase Contrast.
- **`Haptics.swift` (`DesignSystem`):**
  - Add `@MainActor public enum Haptics` with `light()`, `medium()`, `success()`, `warning()` backed by `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` (using `#if canImport(UIKit)` cleanly).
- **Theme Persistence & Account Picker:**
  - Add `@AppStorage("appearanceMode")` (`system` | `light` | `dark`) in `RootView` applying `.preferredColorScheme(...)`.
  - Add `Giao diện` (`Theo hệ thống` / `Sáng` / `Tối`) segmented selector inside `AccountView`.
- **String Parity (`Wave 5.5A Spec §6`):**
  - Add all new Vietnamese UI keys from [Wave 5.5A spec §6](../../specs/2026-11-24-phase-5-5a-ui-ux-v2-design.md#L276-L291) identically to `apps/web/src/messages/vi.ts` and `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings`.

**Exercises:**
- [ ] Run `./apps/ios/Scripts/check-strings.sh` -> confirm `0 missing, 0 differing`.
- [ ] Run `xcodebuild` Simulator Debug build and `xcrun swift-format lint --strict --recursive apps/ios`.
- [ ] Launch Simulator in Light, Dark, and Increase Contrast modes; confirm `Be Vietnam Pro` font family registers cleanly (check via Debug gallery or runtime verification log), placeholders (`Tên người mới`, `Tìm khoản chi`) are crisp and legible (`TD-004`), and `Giao diện` switches Light/Dark/System immediately.
- [ ] Run `pnpm check` and commit: `feat(ios): add Design System v2 dark mode, bundled Be Vietnam Pro fonts, and haptics`.

---

### Task 5.5A.2.3: Stage 5.5A.2 Design System Gate

**Files:** `docs/superpowers/runs/phase-5-5a/{progress,decisions}.md` and `screens/5-5a-2/`.

- [ ] Run `pnpm check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, and Simulator Debug `xcodebuild`.
- [ ] Save Light & Dark screenshots (`screens/5-5a-2/`), verify `TD-001` and `TD-004` evidence in `progress.md`, and commit: `docs(run): record Wave 5.5A.2 design system gate`.
