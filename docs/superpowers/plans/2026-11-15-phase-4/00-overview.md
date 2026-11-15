# Sòng Phẳng — Phase 4 Implementation Plan — Overview

> **For the implementation agent:** read `AGENTS.md`, the spec, `../2026-11-15-common.md`, then this file. Work through the stage files in order without stopping between tasks.

**Goal:** People comment on and dispute expenses, are notified in the application and by mail, are reminded of debts, add expenses from a Telegram group, and large expenses wait for the owner's approval.

**Architecture:** As `docs/04-sad.md`. Notifications are rows inserted in the same database transaction as their cause; delivery (mail, digest, reminders) is worker jobs. The Telegram bot is a webhook route plus a `ChatSender` interface; every bot action runs as the linked application user through the existing services. Approval adds one filter to every query that sums money.

**Tech Stack:** unchanged. **No new library.**

**Spec:** `docs/superpowers/specs/2026-11-15-phase-4-collaboration-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-phase-4`; `<BRANCH>` `phase-4`; `<LAST TASK>` `4D.4`.

## Stage files

| Order | File | Tasks | Adds |
|---|---|---|---|
| 0 | `../2026-11-15-common.md` | 0 | Re-baseline |
| 1 | `4a-comments.md` | 4A.1–4A.3 | Comments, disputes, the transaction view |
| 2 | `4b-notifications.md` | 4B.1–4B.5 | Notifications, mail, reminders |
| 3 | `4c-telegram.md` | 4C.1–4C.4 | The bot |
| 4 | `4d-approval.md` | 4D.1–4D.4 | Approval and the final gate |

## Dependencies on other phases

- **Phase 3 absent:** before 4B.1, do tasks 3A.1 of the phase 3 plan (worker, queue, event bridge, features endpoint) as task 4B.0, with its own commit, and record it.
- **Phase 2 absent:** skip the notification kinds `settlement_requested`, `settlement_confirmed`, `settlement_rejected` and `budget_state`, and the approval filter's lines for statistics, budget and export; record each.
- **Server step absent:** mail goes to the console mailer; nothing else changes.

## Constraints for this phase

- A notification's `payload` is a snapshot. Reading it never needs, and never performs, another query for group data; listing notifications joins `group_users` so a user who left a group sees none of its rows.
- Mail jobs re-check, at send time, that the recipient is still in the group and the notification is unread.
- The bot acts only as a linked user through the same service functions the routes call. No bot code path writes group data directly through `packages/db`.
- The Telegram secret is compared with `timingSafeEqual`; the bot token is read in the adapter only and never logged. The agent never calls `api.telegram.org`. Documentation to read: `https://core.telegram.org/bots/api` (sections "Update", "Message", "CallbackQuery", "sendMessage", "answerCallbackQuery", "setWebhook").
- From 4D.1 every query that sums money carries the approval filter. `rg "transaction_shares|transaction_payers" packages/db/src` is run at the end of 4D.1 and every hit is listed in `progress.md` with "filtered" or the reason it need not be.

## Review Focus

1. **A notification outlives membership.** A removed user's list, count, mail and push show nothing of that group. → 4B.1, 4B.3.
2. **Mail that cannot be stopped, or an unsubscribe link that acts on someone else.** → 4B.3.
3. **Someone in a Telegram chat acts with another person's rights.** Unlinked senders, non-members, viewers, and taps by another person all save nothing. → 4C.2, 4C.3.
4. **A forged webhook.** A missing or wrong secret is a 404 with no side effect. → 4C.1.
5. **A pending expense leaks into a balance.** Balances, pairwise debts, statistics, budget, export and the balance check all ignore it. → 4D.1.
