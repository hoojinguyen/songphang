# Wave 5.5A — Stage 5.5A.5: Web Desktop Shell, Parity Audit & Owner Handoff

> Follow the workflow and constraints in [00-overview.md](00-overview.md) and [common phase rules](../2026-11-15-common.md).

### Task 5.5A.5.1: Web Desktop Multi-Column Responsive Shell (`>= 1024px` / `>= 1280px`)

**Files:**
- `apps/web/src/components/layout/AppShell.tsx`
- New `apps/web/src/components/layout/{DesktopSidebar,GroupInspector}.tsx`
- `apps/web/src/app/g/[groupId]/{layout,page}.tsx`
- `apps/web/src/app/{page,groups/page,ledger/page,notifications/page,account/page}.tsx`

**Interfaces & Rules:**
- **Responsive Breakpoints (`AppShell.tsx`):**
  - `< 1024px`: Single-column workspace (`max-w-[480px]` centered) with fixed bottom 4-tab bar.
  - `1024px – 1279px` (`lg:`): **2-column layout** — sticky left rail `DesktopSidebar` (`260px`) + centered workspace (`flex-1 min-w-0`, content measure up to `760px`), hiding bottom mobile tab bar.
  - `>= 1280px` (`xl:`) on `/g/[groupId]*`: **3-column layout** — `DesktopSidebar` (`260px`) + center workspace (`flex-1 min-w-0 max-w-[760px]`) + sticky right `GroupInspector` (`340px`).
- **`DesktopSidebar.tsx`:**
  - Sòng Phẳng brand header + current user badge.
  - 4 primary navigation links (`Tổng quan`, `Nhóm`, `Thông báo` with unread badge, `Tài khoản`) + `Giao dịch của bạn` (`/ledger`) link.
  - Scrollable quick switcher of active groups (`Đang mở`) showing `myBalance` and `pendingActionCount`.
  - Primary `Tạo nhóm mới` CTA + quick Light/Dark/System theme toggle synced with `apps/web/src/lib/theme.ts`.
- **`GroupInspector.tsx`:**
  - Inside `/g/[groupId]*` at `>= 1280px`, renders live Group Net Balance hero + top suggested transfers with quick `VietQR` / `Tôi đã chuyển` / `Đã nhận` actions, OR displays an inline Transaction Detail preview when a feed card is selected on desktop (without losing scroll position in the center feed).
- **Auth & Invite Isolation:** Keep `/login`, `/register`, `/forgot-password`, `/reset-password`, `/verify-email`, `/join/[token]`, `/link/telegram`, and `/notifications/unsubscribe` clean centered single-column views without `DesktopSidebar` or bottom nav.

**Exercises:**
- [ ] Verify Web in a real browser at `390×844` (mobile), `768×1024` (tablet), `1024×768` (2-column desktop), and `1440×900` (3-column desktop) in both Light and Dark modes: zero horizontal overflow, clean scroll independent columns, theme toggle updates immediately, inspector reflects live SSE updates when another browser window adds/settles a transaction.
- [ ] Check browser DevTools console confirming zero CSP errors, zero hydration mismatches, and zero 4xx/5xx console errors during normal flows.
- [ ] Run `pnpm check`, `pnpm build`, and commit: `feat(web): add multi-column responsive desktop shell and group inspector`.

---

### Task 5.5A.5.2: Final Wave 5.5A Parity Gate & Owner Handoff

**Files:**
- `docs/superpowers/runs/phase-5-5a/{progress,decisions,manual-checks,parity-matrix}.md`
- `docs/superpowers/runs/phase-5-5a/screens/5-5a-final/`

**Tasks & Checks:**
- [ ] **Disposable DB Full Replay (Phases 1–5 + Wave 5.5A):**
  - Start clean Postgres DB + local API + local worker (`AI_PROVIDER=fake`, console mail, console push, console Telegram).
  - Replay complete Phase 1–5 journeys plus Wave 5.5A journeys (Overview totals, Personal Ledger filters, Archive `409` guards, Clone with payment methods & zero transactions, Unarchive, `myDelta` sum reconciliation, permission matrix across Cookie + Bearer callers including `404` for outsiders).
  - Run `DATABASE_URL=... pnpm --filter @songphang/db exec tsx src/check-balances.ts` -> verify `All groups balanced` (`sum 0; mismatches 0`).
- [ ] **Automated & Build Gates (after final code edit):**
  - `pnpm check` (Biome + 8 workspace typechecks + `OpenAPI contract snapshot is up to date.`) -> exit `0`.
  - `pnpm build` (Next.js production build) -> exit `0`.
  - `./apps/ios/Scripts/check-strings.sh` -> `0 missing, 0 differing`.
  - `xcrun swift-format lint --strict --recursive apps/ios` -> exit `0`.
  - `xcodebuild` Simulator Debug (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`) -> `** BUILD SUCCEEDED **`.
  - `xcodebuild` unsigned Release (`-configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`) -> `** BUILD SUCCEEDED **`, followed by Release bundle audit (`RELEASE_LEAK_MATCH_COUNT=0`: zero occurrences of `FakeWorld`, `DebugGalleryView`, `isShowingDebugPanel`, `SPDeviceDidShakeNotification`, `--gallery-`, `127.0.0.1`, `localhost:3000`; `Info.plist` free of `NSAppTransportSecurity`; `PrivacyInfo.xcprivacy` intact).
- [ ] **Security Review:** Walk `.agents/skills/security-review/SKILL.md` across the entire `main..HEAD` diff (zero `dangerouslySetInnerHTML`, dev-only `allowedDevOrigins`, snapshot wipe on sign-out/revocation/deletion, group lock around archive/clone, no logged bank details or tokens, `404` outsider checks).
- [ ] **Owner Handoff (`manual-checks.md`):**
  - Write numbered physical-iPhone and Web Desktop verification steps covering Light/Dark/System appearance (`TD-004`), `CreateGroupView` keyboard & scroll (`TD-003`), 7+ member Quick Entry wrapping (`TD-005`), dense full-width feed scanning (`TD-006`), `"Tổng chuyến đi"` (`TD-007`), `.local` email verification link (`TD-001`), "Bơm hình" + Haptics + Swipe Actions, Cross-Group Overview / Personal Ledger, Archive & Clone, and `1440px` Web Desktop inspector.
  - List any standing-doc updates needed by the advisor before merge (`docs/05-api-spec.md`, `docs/05-database-design.md`, `docs/06-ux-ui/user-flows.md`, `docs/tech-debt.md` closing verified `TD` items) and any external checks still deferred until Server Step (`TD-002`, live SMTP/OAuth/APNs/AI/TestFlight).
- [ ] Commit final run evidence: `docs(run): finalize Wave 5.5A parity evidence and owner handoff`.
