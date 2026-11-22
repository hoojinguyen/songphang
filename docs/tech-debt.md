# Technical Debt

## TD-001 — Email verification can stall on the local development host

**Status** Open. Observed on 2026-11-22 during Phase 5 physical iPhone acceptance.

Opening the verification page on the Mac's `.local` hostname in the in-app browser left the page on its loading placeholder. The HTML returned HTTP 200. A cross-site request for a Next.js development JavaScript asset returned HTTP 403, and the page did not submit verification. Submitting a valid, current link token directly through the normal verification API returned HTTP 204 and verified the account. The stall was reproduced locally. Production behavior remains unverified.

**Acceptance** Use the documented local device setup to open a verification link from the test email. The page must reach a success or actionable error state and the API must confirm successful verification. A link invalidated by resending must show an explanation and a path to request a fresh email. Preserve Next.js development origin restrictions for unrelated hosts.

## TD-002 — Production email delivery and iPhone onboarding acceptance

**Status** Open. Required before public release of email/password onboarding.

Development mail is written to the API console. The API currently refuses production startup because a production mailer is missing. The [server delivery plan, Task S.4](superpowers/plans/2026-11-15-server-step/00-overview.md#task-s4-smtp-mail) owns SMTP implementation and configuration. This entry tracks acceptance of the account verification journey on iPhone.

**Acceptance** On a physical iPhone with the release configuration, register a fresh account, receive the verification email in a real inbox, open its HTTPS link, and see confirmation. Return to the app and confirm it refreshes verification status and allows the user to create a group without signing out. Check resend, the superseded link, and a retry after a transient network failure. Users must be able to complete the journey without operator intervention.
