# Wave 5.5A — Parity Matrix

- Branch: `phase-5-5a`
- Baseline: `main` (`fbc0b7a` / `378df4d`)

| Journey / Capability | API Surface | Web Surface | iOS Surface | Status |
|---|---|---|---|---|
| Appearance (`system`/`light`/`dark`) + Design System v2 | N/A (device-local) | `globals.css`, `/theme-init.js`, `AppearanceCard` | `Tokens`, `Typography`, `AccountView` | Complete |
| `TD-001` Dev `.local` email verification | Existing `/auth/verify-email` | `apps/web/next.config.ts` | N/A | Complete |
| `TD-003` Create group keyboard scroll | Existing `POST /groups` | Existing `/groups/new` | `CreateGroupView` | Complete |
| `TD-004` Placeholder contrast | N/A | `placeholder:text-placeholder` | `Tokens.placeholder` | Complete |
| `TD-005` Quick Entry 7+ wrap | Existing `/quick-entry/parse` | `ConfirmationCard`, `ShareShapes` | `ConfirmationCardView`, `ShareShapesView` | Complete |
| `TD-006` Full-width feed cards + 3-segment Group | `myDelta` on transactions (Complete) | `ExpenseRow`, `/g/[groupId]/layout` | `GroupContainerView`, `GroupFeedView` | Complete |
| `TD-007` Trip total label | Existing `/stats` | Existing `vi.feed.tripTotal` | `Localizable.xcstrings` (`feed.tripTotal`) | Complete |
| Cross-group Overview (`S0`) | `GET /me/overview` (Complete) | `/` + `OverviewSummaryCard` | `OverviewFeature/OverviewView` | Complete |
| Personal Ledger (`S0b`) | `GET /me/transactions` (Complete) | `/ledger` + `PersonalLedgerList` | `OverviewFeature/PersonalLedgerView` | Complete |
| Archive / Unarchive Group | `POST /groups/{id}/archive`, `unarchive`, `409 GROUP_ARCHIVED` (Complete) | `/groups`, `ArchiveGroupDialog`, settings | `GroupListView`, `GroupSettingsView` | Complete |
| Clone Group | `POST /groups/{id}/clone` (Complete) | `CloneGroupDialog` | `CloneGroupSheetView` | Complete |
| "Bơm hình" hold-to-grow split | Existing `/transactions/preview` | `SplitEditor` | `SplitEditorView` | Complete |
| Web Desktop 2–3 column shell | N/A | `AppShell`, `DesktopSidebar`, `GroupInspector` | N/A (iOS uses 4-tab `TabView`) | Complete |
