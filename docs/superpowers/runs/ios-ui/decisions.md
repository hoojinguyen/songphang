# iOS interface stage run — decisions

Written by the implementation agent. One entry for every decision the specs and the plan did not make. The advisor reads this file first during review.

Entry format:

```
## D<number> — <short title> (task <id>)
Problem: …
Options: …
Choice: …
Reason: …
```

## D1 — Be Vietnam Pro font files in web repository (task U.1)
Problem: Task U.1 specifies copying Be Vietnam Pro font files from `apps/web` into `DesignSystem/Resources/Fonts/` if they are TrueType or OpenType, or using the system font if they are only in a web format iOS cannot register.
Options: (1) Copy `.woff2` files from `apps/web/public/fonts/be-vietnam-pro/` and attempt registration; (2) Use the iOS system font with Dynamic Type weights and record under "Not verified" as instructed by the plan.
Choice: Option 2 — use the iOS system font (`Font.system`) and record under "Not verified".
Reason: Inspection of `apps/web/public/fonts/be-vietnam-pro/` confirmed only `.woff2` files exist (`latin-*.woff2`, `latin-ext-*.woff2`, `vietnamese-*.woff2`), which CoreText/iOS does not register as app bundle fonts, and downloading font files is forbidden by the phase run rules.

## D2 — SwiftPM tools version in `SongPhangKit/Package.swift` (task U.1)
Problem: The installed toolchain is Swift 6.4.2 (`Xcode 27.2`), and `Package.swift` needs `.iOS(.v26)`, `.swiftLanguageMode(.v6)`, `.treatAllWarnings(as: .error)`, and `.defaultIsolation(MainActor.self)`.
Options: (1) `swift-tools-version: 6.2`; (2) `swift-tools-version: 6.0`.
Choice: Option 1 (`swift-tools-version: 6.2`).
Reason: In the installed `PackageDescription.swiftinterface`, `.iOS(.v26)`, `.treatAllWarnings(as: .error)`, and `.defaultIsolation(MainActor.self)` are annotated `@available(_PackageDescription 6.2)`.

## Web baseline

`bb1e0432fef6f1ceb4cf2ee960948129210626b2`

## Re-baseline

| Plan reference | Found at | Notes |
|---|---|---|
| `apps/web/src/app/globals.css` | `apps/web/src/app/globals.css` | Present |
| `apps/web/src/app/fonts.css` | `apps/web/src/app/fonts.css` | Present |
| `apps/web/src/messages/vi.ts` | `apps/web/src/messages/vi.ts` | Present |
| `packages/contract/src/*.ts` | `packages/contract/src/activity.ts`, `auth.ts`, `balance.ts`, `error.ts`, `group-user.ts`, `group.ts`, `health.ts`, `index.ts`, `invite.ts`, `member.ts`, `quick-entry.ts`, `transaction.ts` | Present |
| `apps/web/src/lib/*.ts` | `apps/web/src/lib/activity-sentences.ts`, `activity.ts`, `api.ts`, `auth.ts`, `balances.ts`, `dev-shapes.ts`, `draft-context.tsx`, `group-users.ts`, `groups.ts`, `invites.ts`, `members.ts`, `money.ts`, `network-state.ts`, `quick-entry.ts`, `request.ts`, `session.ts`, `transaction-changes.ts`, `transactions.ts`, `use-counted-balance.ts`, `use-group-events.ts`, `use-online.ts`, `use-session-guard.ts` | Present |
| `apps/web/src/app/login` | `apps/web/src/app/login/page.tsx` | Present |
| `apps/web/src/app/register` | `apps/web/src/app/register/page.tsx` | Present |
| `apps/web/src/app/verify-email` | `apps/web/src/app/verify-email/page.tsx`, `apps/web/src/components/ui/VerifyEmailBanner.tsx` | Present |
| `apps/web/src/app/forgot-password` | `apps/web/src/app/forgot-password/page.tsx` | Present |
| `apps/web/src/app/reset-password` | `apps/web/src/app/reset-password/page.tsx` | Present |
| `apps/web/src/app/page.tsx` | `apps/web/src/app/page.tsx` | Present |
| `apps/web/src/app/groups/new` | `apps/web/src/app/groups/new/page.tsx` | Present |
| `apps/web/src/app/g/[groupId]/members` | `apps/web/src/app/g/[groupId]/members/page.tsx` | Present |
| `apps/web/src/app/g/[groupId]/settings` | `apps/web/src/app/g/[groupId]/settings/page.tsx` | Present |
| `apps/web/src/app/join/[token]` | `apps/web/src/app/join/[token]/page.tsx` | Present |
| `apps/web/src/app/account` | `apps/web/src/app/account/page.tsx` | Present |
| `apps/web/src/components/groups` | `apps/web/src/components/groups/FeaturedGroupCard.tsx`, `GroupCard.tsx`, `NewGroupMembers.tsx`, `NewMemberRow.tsx` | Present |
| `apps/web/src/components/members` | `apps/web/src/components/members/AddMemberRow.tsx`, `InviteCard.tsx`, `LeaveGroupButton.tsx`, `MemberEditor.tsx`, `MemberRow.tsx`, `UserControls.tsx` | Present |
| `apps/web/src/components/settings` | `apps/web/src/components/settings/DeleteGroupCard.tsx`, `InviteLinkCard.tsx`, `TransferOwnershipCard.tsx` | Present |
| `apps/web/src/components/join` | `apps/web/src/components/join/ClaimGrid.tsx`, `JoinForm.tsx` | Present |
| `apps/web/src/components/account` | `apps/web/src/components/account/ChangePasswordCard.tsx`, `DeleteAccountCard.tsx` | Present |
| `apps/web/src/app/g/[groupId]/page.tsx` | `apps/web/src/app/g/[groupId]/page.tsx`, `layout.tsx`, `balances/page.tsx`, `activity/page.tsx` | Present |
| `apps/web/src/components/feed` | `apps/web/src/components/feed/BalanceBlock.tsx`, `EmptyStream.tsx`, `EntryBar.tsx`, `ExpenseRow.tsx`, `ExpenseStream.tsx`, `LedgerPill.tsx`, `NewItemsPill.tsx` | Present |
| `apps/web/src/components/balances` | `apps/web/src/components/balances/AllSettled.tsx`, `BalanceBars.tsx`, `OtherSettlements.tsx`, `OwnSettlementCard.tsx`, `SettlementCard.tsx`, `SettlementForm.tsx` | Present |
| `apps/web/src/components/activity` | `apps/web/src/components/activity/ActivityRow.tsx`, `ChangeChips.tsx` | Present |
| `apps/web/src/lib/use-group-events.ts` | `apps/web/src/lib/use-group-events.ts` | Present |
| `apps/web/src/app/g/[groupId]/tx/new` | `apps/web/src/app/g/[groupId]/tx/new/page.tsx`, `ComposeScreen.tsx` | Present |
| `apps/web/src/app/g/[groupId]/tx/[transactionId]` | `apps/web/src/app/g/[groupId]/tx/[transactionId]/page.tsx` | Present |
| `apps/web/src/app/g/[groupId]/settle` | `apps/web/src/app/g/[groupId]/settle/page.tsx` | Present |
| `apps/web/src/components/expense-form` | `apps/web/src/components/expense-form/AmountField.tsx`, `CategoryPicker.tsx`, `ConflictNotice.tsx`, `ExpenseForm.tsx`, `MemberToggleGrid.tsx`, `ParticipantFields.tsx`, `PayerAmounts.tsx`, `SplitEditor.tsx`, `SplitMemberRow.tsx`, `SplitModeTabs.tsx`, `SplitStatus.tsx`, `TransferFields.tsx`, `TypeSwitch.tsx`, `UnparsedBanner.tsx`, `use-expense-form.ts`, `use-split-state.ts` | Present |
| `apps/web/src/components/quick-entry` | `apps/web/src/components/quick-entry/ChoicePanel.tsx`, `ConfirmationCard.tsx`, `DescriptionPrompt.tsx`, `HighlightedSentence.tsx`, `QuestionCard.tsx`, `SentenceInput.tsx`, `ShareShapes.tsx` | Present |

## Domain guesses
