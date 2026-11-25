# Technical Debt

## TD-001 — Email verification can stall on the local development host

**Status** Open. Observed on 2026-11-22 during Phase 5 physical iPhone acceptance.

Opening the verification page on the Mac's `.local` hostname in the in-app browser left the page on its loading placeholder. The HTML returned HTTP 200. A cross-site request for a Next.js development JavaScript asset returned HTTP 403, and the page did not submit verification. Submitting a valid, current link token directly through the normal verification API returned HTTP 204 and verified the account. The stall was reproduced locally. Production behavior remains unverified.

**Acceptance** Use the documented local device setup to open a verification link from the test email. The page must reach a success or actionable error state and the API must confirm successful verification. A link invalidated by resending must show an explanation and a path to request a fresh email. Preserve Next.js development origin restrictions for unrelated hosts.

## TD-002 — Production email delivery and iPhone onboarding acceptance

**Status** Open. Required before public release of email/password onboarding.

Development mail is written to the API console. The API currently refuses production startup because a production mailer is missing. The [server delivery plan, Task S.4](superpowers/plans/2026-11-15-server-step/00-overview.md#task-s4-smtp-mail) owns SMTP implementation and configuration. This entry tracks acceptance of the account verification journey on iPhone.

**Acceptance** On a physical iPhone with the release configuration, register a fresh account, receive the verification email in a real inbox, open its HTTPS link, and see confirmation. Return to the app and confirm it refreshes verification status and allows the user to create a group without signing out. Check resend, the superseded link, and a retry after a transient network failure. Users must be able to complete the journey without operator intervention.

## TD-003 — Keyboard obscures controls on New Group

**Status** Open. Owner device report, 2026-11-23. Investigated against the installed Phase 5 revision `15e658e`.

`IMG_8544.PNG` shows the keyboard and its Done accessory overlapping the Create Group button. The owner also reported that the member name field becomes obscured after adding several names. `CreateGroupView` puts the form in a vertical scroll view and the submit bar in a bottom safe-area inset. `NewMemberInputRow` keeps focus after adding a name, but the form has no explicit scroll-to-field behavior after the new row is inserted. Check the interaction between keyboard avoidance, the root keyboard toolbar, and scrolling as the member list grows. The exact safe-area failure has yet to be isolated on device.

**Acceptance** On iPhone, enter a group name and add enough members to extend the form past the visible area. Keep typing with the keyboard open, including after submitting from the keyboard. The focused field and Add action remain reachable, and the Create Group button never sits underneath the keyboard or its accessory. Check dismissal, a smaller portrait screen, and large Dynamic Type.

## TD-004 — Placeholder text has low contrast on white inputs

**Status** Open. Owner device screenshots, 2026-11-23, revision `15e658e`.

`IMG_8543.PNG`, `IMG_8544.PNG`, and the group-feed screenshot show that “Tên người mới” and “Tìm khoản chi” are barely legible. `NewMemberInputRow` and `FeedSearchBarView` set the typed-text foreground and use `Tokens.surface` (white), while both leave the prompt to SwiftUI's default styling. Confirm appearance in each system color scheme. The group-name field deliberately passes an empty prompt and has a separate visible label.

**Acceptance** Both affected prompts remain readable against the actual field background when empty, focused or unfocused, in Light and Dark system appearance and with Increase Contrast. Typed text and accessibility labels remain clear.

## TD-005 — Quick Entry confirmation exceeds the screen after selecting a sample

**Status** Open. Owner device screenshot `IMG_8542.PNG`, 2026-11-23, revision `15e658e`.

Selecting a suggested expense in a new group's empty feed opens Quick Entry with the sample sentence. The resulting confirmation screenshot shows content clipped on both edges, including the header, amount and actions. `ConfirmationCardView` passes all participants to `ShareShapesView`. That view lays them out in one `HStack` with fixed-size shapes, spacing and padding, with no wrapping or horizontal scrolling. For example, seven equal-share shapes require at least 580 pt including the row's spacing and padding, before the surrounding card's insets. Verify the exact width propagation through the Quick Entry container on device.

**Acceptance** In a fresh group with seven participants, select a sample that splits across everyone. The header, total, sentence and actions fit the viewport, and every participant's name and amount remains accessible. Repeat with long names, large amounts and large Dynamic Type, and confirm smaller splits still fit.

## TD-006 — Group detail feed compresses transaction rows and split amounts

**Status** Open. Owner device design feedback and screenshot, 2026-11-23, revision `15e658e`.

The group detail screen feels cramped and is difficult to scan. The screenshot shows `35.715` broken across three lines inside a split chip. In `GroupFeedSubViews.swift`, an expense paid by the signed-in user reserves at least 48 pt for the leading indent. Its card then fits four padded split chips plus an overflow count into a single `HStack`. The amount text can wrap within each chip under width pressure. Review visual hierarchy and density across the group header, actions, filters, transaction cards and entry controls as a design task.

**Acceptance** Review the updated group detail layout with the owner on an iPhone. Check a seven-person split of 250,000 VND and a split with shorter displayed values, at normal and large Dynamic Type. Transaction titles, totals and individual share amounts are easy to scan. A share value is never broken across lines, and all shares remain accessible.

## TD-007 — Group feed exposes the trip total localization key

**Status** Awaiting device verification. Owner device screenshot, 2026-11-23. Observed in `15e658e`.

`GroupFeedView` requests `feed.tripTotal`, which was missing from the iOS string catalog at `15e658e`. `L10n.tr` returns the key as its fallback, matching the screenshot. Phase 5 commit `d379b75` adds the Vietnamese value “Tổng chuyến đi”, matching the web copy. The installed build predates that change.

**Acceptance** Install a Phase 5 build containing `d379b75` or later and confirm the action displays “Tổng chuyến đi” in the Vietnamese iOS UI and still opens group statistics.
