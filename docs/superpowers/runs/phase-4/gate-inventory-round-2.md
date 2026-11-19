# Phase 4 Round 2 — Reproducible Gate Inventory and Results

Disposable database: `songphang_phase4_r2_20261119` (verified via `SELECT current_database()` before every reset; never modifying `songphang` or prior agents' databases; never running `docker compose down -v`). Isolated uploads: `/tmp/songphang-r2-uploads`. Isolated ports: API `4040`, Web `3040`.

## 1. Summary Coverage Counts

| Gate Area | Total Cases | Passed | Failed | Not Run | Notes |
|---|---:|---:|---:|---:|---|
| Registered Hono Routes Covered | 99 | 99 | 0 | 0 | 99/99 actual Hono routes (94 OpenAPI + 5 plain Hono) |
| Endpoint/Caller Permission Matrix | 309 | 309 | 0 | 0 | Owner, Editor, Viewer, Outsider, Cross-group, Unauth, Unverified, Public/Token, Webhook, Dev |
| Quick-Entry Samples (`docs/08-quick-entry-samples.md`) | 87 | 87 | 0 | 0 | Domain status + description/amount/payer/shares/issue codes over HTTP; >300 chars -> HTTP 400 |
| Earlier-Phase Representative Replay (1A-1E, 2A-2D, 3A-3D) | 15 | 15 | 0 | 0 | Labeled representative per Phase 4 spec 14.4; fake AI adapters |
| Phase 4 Stage Gates + R1-R10 Regressions | 7 | 7 | 0 | 0 | Includes R9 inter-recipient digest mutations, R10 deleted-tx comment/dispute, R1-R8, 4D.1 variants, 4D.2 13-row exact balances |
| Capability-Off & Production Refusals | 18 | 18 | 0 | 0 | 6 false flags, 4 disabled 404 routes, 8 production refusals (incl. API & worker mailer) |
| 1,000-Notification Performance & Privacy | 4 | 4 | 0 | 0 | page1=8.6ms, page2=4.58ms (<300ms), 0 leaked after removal |
| Browser Gates (Chrome DevTools MCP, 2 signed-in + 1 signed-out contexts) | 10 | 10 | 0 | 0 | S20 deleted comment SSE + literal script, S5 reminder -> S4 live bell (10->11), S20 pending approval + Escape dialog, S19 mark-all, S13 375px zero overflow, signed-out unsubscribe valid/invalid, R1 legacy refusal + full pairing, 0 console errors |

## 2. Reproduction Protocol

1. Verify `SELECT current_database()` equals `songphang_phase4_r2_20261119`, reset only that database (`DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS drizzle CASCADE; DROP SCHEMA IF EXISTS pgboss CASCADE; CREATE SCHEMA public;`), then run `pnpm db:migrate` and `pnpm db:seed`.
2. Run `pnpm check`, `API_ORIGIN=http://127.0.0.1:4040 pnpm build`, and `git diff --check main..HEAD`.
3. Start isolated API (`API_PORT=4040`, `WEB_ORIGIN=http://localhost:3040`, `DEV_LOGIN=true`, `AI_PROVIDER=fake`, `TELEGRAM_PROVIDER=console`, `TELEGRAM_WEBHOOK_SECRET=<32-char-local-secret>`, `TELEGRAM_BOT_USERNAME=SongPhangTestBot`) and built Next.js (`PORT=3040`, `API_ORIGIN=http://127.0.0.1:4040`).
4. Execute permission matrix, 87 quick-entry samples, earlier-phase representative replay, Phase 4 stage/regression suite, capability-off/production checks, 1,000-notification perf/privacy check, Chrome DevTools MCP browser flows, and `pnpm db:check-balances` (`All groups balanced`).

## 3. Complete Endpoint-by-Caller Permission Matrix (99 Routes, 309 Cases)

| Case ID | Source Requirement | Method / Path | Fixture / Precondition | Caller | Expected | Reproducible Invocation | Actual | Status |
|---|---|---|---|---|---|---|---|---|
| PM-001 | Phase 1A auth | `POST /api/v1/auth/register` | Fresh email/password | public | 204 | `POST /api/v1/auth/register` | HTTP 204 | PASS |
| PM-002 | Phase 0 | `GET /api/v1/health` | None | public | 200 | `GET /api/v1/health` | HTTP 200 | PASS |
| PM-003 | Phase 3A | `GET /api/v1/features` | None | public | 200 | `GET /api/v1/features` | HTTP 200 | PASS |
| PM-004 | Phase 0 | `GET /api/v1/openapi.json` | None | public | 200 | `GET /api/v1/openapi.json` | HTTP 200 | PASS |
| PM-005 | Phase 1A | `GET /api/v1/auth/providers` | None | public | 200 | `GET /api/v1/auth/providers` | HTTP 200 | PASS |
| PM-006 | Phase 0 dev | `GET /api/v1/dev/users` | DEV_LOGIN=true | public | 200 | `GET /api/v1/dev/users` | HTTP 200 | PASS |
| PM-007 | Phase 0 dev | `POST /api/v1/dev/login` | DEV_LOGIN=true | public | 204 | `POST /api/v1/dev/login` | HTTP 204 | PASS |
| PM-008 | Phase 1A | `POST /api/v1/auth/login` | Registered credentials | public | 204 | `POST /api/v1/auth/login` | HTTP 204 | PASS |
| PM-009 | Phase 1A | `POST /api/v1/auth/forgot-password` | Non-enumerating | public | 204 | `POST /api/v1/auth/forgot-password` | HTTP 204 | PASS |
| PM-010 | Phase 1A | `POST /api/v1/auth/reset-password` | Invalid token | public | 400 | `POST /api/v1/auth/reset-password` | HTTP 400 TOKEN_INVALID | PASS |
| PM-011 | Phase 1A | `POST /api/v1/auth/verify-email` | Invalid token | public | 400 | `POST /api/v1/auth/verify-email` | HTTP 400 TOKEN_INVALID | PASS |
| PM-012 | Phase 1A | `GET /api/v1/auth/google` | OAuth configured | public | 302 | `GET /api/v1/auth/google` | HTTP 302 | PASS |
| PM-013 | Phase 1A | `GET /api/v1/auth/google/callback` | Missing/invalid state | public | 302/400 | `GET /api/v1/auth/google/callback?code=x&state=bad` | HTTP 302 | PASS |
| PM-014 | Phase 1A | `POST /api/v1/auth/resend-verification` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/resend-verification` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-015 | Phase 1A | `POST /api/v1/auth/resend-verification` | Unverified session | unverified | 204 | `POST /api/v1/auth/resend-verification` | HTTP 204 | PASS |
| PM-016 | Phase 1A | `POST /api/v1/auth/change-password` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/change-password` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-017 | Phase 1A | `POST /api/v1/auth/change-password` | Valid current password | authenticated | 204 | `POST /api/v1/auth/change-password` | HTTP 204 | PASS |
| PM-018 | Phase 1A | `POST /api/v1/auth/logout` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/logout` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-019 | Phase 1A | `POST /api/v1/auth/logout` | Active session | authenticated | 204 | `POST /api/v1/auth/logout` | HTTP 204 | PASS |
| PM-020 | Phase 1B | `GET /api/v1/invites/:token` | Valid invite token | unauthenticated | 401 | `GET /api/v1/invites/<token>` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-021 | Phase 1B | `GET /api/v1/invites/:token` | Valid invite token | authenticated | 200 | `GET /api/v1/invites/<token>` | HTTP 200 | PASS |
| PM-022 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite | unauthenticated | 401 | `POST /api/v1/invites/<token>/join` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-023 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite | unverified | 403 | `POST /api/v1/invites/<token>/join` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-024 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite on fresh group | authenticated (verified) | 200 | `POST /api/v1/invites/<token>/join` | HTTP 200 | PASS |
| PM-025 | Phase 4B / R2 | `POST /api/v1/notifications/unsubscribe` | Valid token, no session/Origin | public (token) | 204 | `POST /api/v1/notifications/unsubscribe` | HTTP 204 | PASS |
| PM-026 | Phase 4B / R2 | `POST /api/v1/notifications/unsubscribe` | Invalid token | public (token) | 404 | `POST /api/v1/notifications/unsubscribe` | HTTP 404 NOT_FOUND | PASS |
| PM-027 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Missing secret | public (no secret) | 404 | `POST /api/v1/bots/telegram/webhook` | HTTP 404 NOT_FOUND | PASS |
| PM-028 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Wrong secret | public (wrong secret) | 404 | `POST /api/v1/bots/telegram/webhook` | HTTP 404 NOT_FOUND | PASS |
| PM-029 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Valid secret | telegram webhook | 200 | `POST /api/v1/bots/telegram/webhook` | HTTP 200 | PASS |
| PM-030 | Phase 1A | `GET /api/v1/me` | Unauth | unauthenticated | 401 | `GET /api/v1/me` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-031 | Phase 1A | `GET /api/v1/me` | Signed in | authenticated | 200 | `GET /api/v1/me` | HTTP 200 | PASS |
| PM-032 | Phase 1B | `GET /api/v1/groups` | Unauth | unauthenticated | 401 | `GET /api/v1/groups` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-033 | Phase 1B | `GET /api/v1/groups` | Signed in | authenticated | 200 | `GET /api/v1/groups` | HTTP 200 | PASS |
| PM-034 | Phase 1B | `POST /api/v1/groups` | Unauth | unauthenticated | 401 | `POST /api/v1/groups` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-035 | Phase 1B | `POST /api/v1/groups` | Unverified | unverified | 403 | `POST /api/v1/groups` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-036 | Phase 1B | `POST /api/v1/groups` | Verified user | authenticated | 201 | `POST /api/v1/groups` | HTTP 201 | PASS |
| PM-037 | Phase 4B | `GET /api/v1/me/notifications` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notifications` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-038 | Phase 4B | `GET /api/v1/me/notifications` | Signed in | authenticated | 200 | `GET /api/v1/me/notifications` | HTTP 200 | PASS |
| PM-039 | Phase 4B | `GET /api/v1/me/notifications/unread-count` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notifications/unread-count` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-040 | Phase 4B | `GET /api/v1/me/notifications/unread-count` | Signed in | authenticated | 200 | `GET /api/v1/me/notifications/unread-count` | HTTP 200 | PASS |
| PM-041 | Phase 4B | `POST /api/v1/me/notifications/read` | Unauth | unauthenticated | 401 | `POST /api/v1/me/notifications/read` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-042 | Phase 4B | `POST /api/v1/me/notifications/read` | Signed in | authenticated | 204 | `POST /api/v1/me/notifications/read` | HTTP 204 | PASS |
| PM-043 | Phase 4B | `GET /api/v1/me/notification-settings` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notification-settings` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-044 | Phase 4B | `GET /api/v1/me/notification-settings` | Signed in | authenticated | 200 | `GET /api/v1/me/notification-settings` | HTTP 200 | PASS |
| PM-045 | Phase 4B | `PUT /api/v1/me/notification-settings` | Unauth | unauthenticated | 401 | `PUT /api/v1/me/notification-settings` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-046 | Phase 4B | `PUT /api/v1/me/notification-settings` | Signed in | authenticated | 200 | `PUT /api/v1/me/notification-settings` | HTTP 200 | PASS |
| PM-047 | Phase 4C | `GET /api/v1/me/chat-identities` | Unauth | unauthenticated | 401 | `GET /api/v1/me/chat-identities` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-048 | Phase 4C | `GET /api/v1/me/chat-identities` | Signed in | authenticated | 200 | `GET /api/v1/me/chat-identities` | HTTP 200 | PASS |
| PM-049 | Phase 4C / R1 | `POST /api/v1/me/chat-identities/claim` | Legacy claim disabled | authenticated | 400 (TOKEN_INVALID) | `POST /api/v1/me/chat-identities/claim` | HTTP 400 TOKEN_INVALID | PASS |
| PM-050 | Phase 4C | `DELETE /api/v1/me/chat-identities/:platform` | Unauth | unauthenticated | 401 | `DELETE /api/v1/me/chat-identities/telegram` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-051 | Phase 4C | `DELETE /api/v1/me/chat-identities/:platform` | Signed in | authenticated | 204 | `DELETE /api/v1/me/chat-identities/telegram` | HTTP 204 | PASS |
| PM-052 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings` | Unauth | unauthenticated | 401 | `POST /api/v1/me/chat-identities/telegram/pairings` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-053 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings` | Unverified | unverified | 403 | `POST /api/v1/me/chat-identities/telegram/pairings` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-054 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings` | Verified user | authenticated (Lan) | 201 | `POST /api/v1/me/chat-identities/telegram/pairings` | HTTP 201 | PASS |
| PM-055 | R1 pairing | `GET /api/v1/me/chat-identities/telegram/pairings/:pairingId` | Owner session | initiating session (Lan) | 200 | `GET /api/v1/me/chat-identities/telegram/pairings/<uuid>` | HTTP 200 | PASS |
| PM-056 | R1 pairing | `GET /api/v1/me/chat-identities/telegram/pairings/:pairingId` | Other user | other user (Minh) | 404 | `GET /api/v1/me/chat-identities/telegram/pairings/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-057 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings/:pairingId/confirm` | Other user | other user (Minh) | 404 | `POST /api/v1/me/chat-identities/telegram/pairings/<uuid>/confirm` | HTTP 404 NOT_FOUND | PASS |
| PM-058 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings/:pairingId/confirm` | Unconfirmed on Telegram | initiating session (Lan) | 400 | `POST /api/v1/me/chat-identities/telegram/pairings/<uuid>/confirm` | HTTP 400 TOKEN_INVALID | PASS |
| PM-059 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings/:pairingId/cancel` | Other user | other user (Minh) | 404 | `POST /api/v1/me/chat-identities/telegram/pairings/<uuid>/cancel` | HTTP 404 NOT_FOUND | PASS |
| PM-060 | R1 pairing | `POST /api/v1/me/chat-identities/telegram/pairings/:pairingId/cancel` | Initiating session | initiating session (Lan) | 204 | `POST /api/v1/me/chat-identities/telegram/pairings/<uuid>/cancel` | HTTP 204 | PASS |
| PM-061 | Phase 1B | `GET /api/v1/groups/:groupId` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>` | HTTP 200 | PASS |
| PM-062 | Phase 1B | `GET /api/v1/groups/:groupId` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>` | HTTP 200 | PASS |
| PM-063 | Phase 1B | `GET /api/v1/groups/:groupId` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>` | HTTP 200 | PASS |
| PM-064 | Phase 1B | `GET /api/v1/groups/:groupId` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-065 | Phase 1B | `GET /api/v1/groups/:groupId` | G1 | unauthenticated | 401 | `GET /api/v1/groups/<uuid>` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-066 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | owner | 200 | `PATCH /api/v1/groups/<uuid>` | HTTP 200 | PASS |
| PM-067 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | editor | 403 | `PATCH /api/v1/groups/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-068 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | viewer | 403 | `PATCH /api/v1/groups/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-069 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | outsider | 404 | `PATCH /api/v1/groups/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-070 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | unauthenticated | 401 | `PATCH /api/v1/groups/<uuid>` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-071 | Phase 1C | `GET /api/v1/groups/:groupId/balances` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/balances` | HTTP 200 | PASS |
| PM-072 | Phase 1C | `GET /api/v1/groups/:groupId/balances` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/balances` | HTTP 200 | PASS |
| PM-073 | Phase 1C | `GET /api/v1/groups/:groupId/balances` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/balances` | HTTP 200 | PASS |
| PM-074 | Phase 1C | `GET /api/v1/groups/:groupId/balances` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/balances` | HTTP 404 NOT_FOUND | PASS |
| PM-075 | Phase 1E | `GET /api/v1/groups/:groupId/activity` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/activity` | HTTP 200 | PASS |
| PM-076 | Phase 1E | `GET /api/v1/groups/:groupId/activity` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/activity` | HTTP 200 | PASS |
| PM-077 | Phase 1E | `GET /api/v1/groups/:groupId/activity` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/activity` | HTTP 200 | PASS |
| PM-078 | Phase 1E | `GET /api/v1/groups/:groupId/activity` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/activity` | HTTP 404 NOT_FOUND | PASS |
| PM-079 | Phase 2B | `GET /api/v1/groups/:groupId/stats` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/stats` | HTTP 200 | PASS |
| PM-080 | Phase 2B | `GET /api/v1/groups/:groupId/stats` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/stats` | HTTP 200 | PASS |
| PM-081 | Phase 2B | `GET /api/v1/groups/:groupId/stats` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/stats` | HTTP 200 | PASS |
| PM-082 | Phase 2B | `GET /api/v1/groups/:groupId/stats` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/stats` | HTTP 404 NOT_FOUND | PASS |
| PM-083 | Phase 2B | `GET /api/v1/groups/:groupId/export.csv` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/export.csv` | HTTP 200 | PASS |
| PM-084 | Phase 2B | `GET /api/v1/groups/:groupId/export.csv` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/export.csv` | HTTP 200 | PASS |
| PM-085 | Phase 2B | `GET /api/v1/groups/:groupId/export.csv` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/export.csv` | HTTP 200 | PASS |
| PM-086 | Phase 2B | `GET /api/v1/groups/:groupId/export.csv` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/export.csv` | HTTP 404 NOT_FOUND | PASS |
| PM-087 | Phase 1B | `GET /api/v1/groups/:groupId/users` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/users` | HTTP 200 | PASS |
| PM-088 | Phase 1B | `GET /api/v1/groups/:groupId/users` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/users` | HTTP 200 | PASS |
| PM-089 | Phase 1B | `GET /api/v1/groups/:groupId/users` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/users` | HTTP 200 | PASS |
| PM-090 | Phase 1B | `GET /api/v1/groups/:groupId/users` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/users` | HTTP 404 NOT_FOUND | PASS |
| PM-091 | Phase 1B | `GET /api/v1/groups/:groupId/members` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/members` | HTTP 200 | PASS |
| PM-092 | Phase 1B | `GET /api/v1/groups/:groupId/members` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/members` | HTTP 200 | PASS |
| PM-093 | Phase 1B | `GET /api/v1/groups/:groupId/members` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/members` | HTTP 200 | PASS |
| PM-094 | Phase 1B | `GET /api/v1/groups/:groupId/members` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/members` | HTTP 404 NOT_FOUND | PASS |
| PM-095 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | owner | 201 | `POST /api/v1/groups/<uuid>/members` | HTTP 201 | PASS |
| PM-096 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | editor | 201 | `POST /api/v1/groups/<uuid>/members` | HTTP 201 | PASS |
| PM-097 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | viewer | 403 | `POST /api/v1/groups/<uuid>/members` | HTTP 403 FORBIDDEN | PASS |
| PM-098 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | outsider | 404 | `POST /api/v1/groups/<uuid>/members` | HTTP 404 NOT_FOUND | PASS |
| PM-099 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | owner | 200 | `PATCH /api/v1/groups/<uuid>/members/<uuid>` | HTTP 200 | PASS |
| PM-100 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | editor | 200 | `PATCH /api/v1/groups/<uuid>/members/<uuid>` | HTTP 200 | PASS |
| PM-101 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | viewer | 403 | `PATCH /api/v1/groups/<uuid>/members/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-102 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | outsider | 404 | `PATCH /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-103 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Cross-group resource ID | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-104 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | owner | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 200 | PASS |
| PM-105 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | editor | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 200 | PASS |
| PM-106 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | viewer | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 200 | PASS |
| PM-107 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | outsider | 404 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 404 NOT_FOUND | PASS |
| PM-108 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Cross-group resource ID | owner (G2) | 404 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 404 NOT_FOUND | PASS |
| PM-109 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer editing OTHER member | viewer (other member) | 403 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods` | HTTP 403 FORBIDDEN | PASS |
| PM-110 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | outsider | 404 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-111 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | viewer | 403 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-112 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Cross-group member | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-113 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | editor | 204 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 204 | PASS |
| PM-114 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Fresh unreferenced member | owner | 204 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 204 | PASS |
| PM-115 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/invite` | HTTP 200 | PASS |
| PM-116 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/invite` | HTTP 200 | PASS |
| PM-117 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | viewer | 403 | `GET /api/v1/groups/<uuid>/invite` | HTTP 403 FORBIDDEN | PASS |
| PM-118 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/invite` | HTTP 404 NOT_FOUND | PASS |
| PM-119 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | owner | 200 | `PATCH /api/v1/groups/<uuid>/invite` | HTTP 200 | PASS |
| PM-120 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | editor | 403 | `PATCH /api/v1/groups/<uuid>/invite` | HTTP 403 FORBIDDEN | PASS |
| PM-121 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | viewer | 403 | `PATCH /api/v1/groups/<uuid>/invite` | HTTP 403 FORBIDDEN | PASS |
| PM-122 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | outsider | 404 | `PATCH /api/v1/groups/<uuid>/invite` | HTTP 404 NOT_FOUND | PASS |
| PM-123 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | owner | 200 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 200 | PASS |
| PM-124 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | editor | 403 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 403 FORBIDDEN | PASS |
| PM-125 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | viewer | 403 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 403 FORBIDDEN | PASS |
| PM-126 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | outsider | 404 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 404 NOT_FOUND | PASS |
| PM-127 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | owner | 200 | `PUT /api/v1/groups/<uuid>/me/muted` | HTTP 200 | PASS |
| PM-128 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | editor | 200 | `PUT /api/v1/groups/<uuid>/me/muted` | HTTP 200 | PASS |
| PM-129 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | viewer | 200 | `PUT /api/v1/groups/<uuid>/me/muted` | HTTP 200 | PASS |
| PM-130 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | outsider | 404 | `PUT /api/v1/groups/<uuid>/me/muted` | HTTP 404 NOT_FOUND | PASS |
| PM-131 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Re-claim own member | viewer | 200 | `PUT /api/v1/groups/<uuid>/me/member` | HTTP 200 | PASS |
| PM-132 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Outsider | outsider | 404 | `PUT /api/v1/groups/<uuid>/me/member` | HTTP 404 NOT_FOUND | PASS |
| PM-133 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | owner | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-134 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | editor | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-135 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | viewer | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-136 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | outsider | 404 | `GET /api/v1/groups/<uuid>/events` | HTTP 404 | PASS |
| PM-137 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-138 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-139 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-140 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/categories` | HTTP 404 NOT_FOUND | PASS |
| PM-141 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | owner | 201 | `POST /api/v1/groups/<uuid>/categories` | HTTP 201 | PASS |
| PM-142 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | editor | 201 | `POST /api/v1/groups/<uuid>/categories` | HTTP 201 | PASS |
| PM-143 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | viewer | 403 | `POST /api/v1/groups/<uuid>/categories` | HTTP 403 FORBIDDEN | PASS |
| PM-144 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | outsider | 404 | `POST /api/v1/groups/<uuid>/categories` | HTTP 404 NOT_FOUND | PASS |
| PM-145 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | owner | 200 | `PATCH /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 200 | PASS |
| PM-146 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | editor | 200 | `PATCH /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 200 | PASS |
| PM-147 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | viewer | 403 | `PATCH /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-148 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | outsider | 404 | `PATCH /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-149 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Cross-group resource ID | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-150 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | outsider | 404 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-151 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | viewer | 403 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-152 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-153 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | editor | 204 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 204 | PASS |
| PM-154 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Fresh custom category | owner | 204 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 204 | PASS |
| PM-155 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | owner | 200 | `PUT /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-156 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | editor | 403 | `PUT /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-157 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | viewer | 403 | `PUT /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-158 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | outsider | 404 | `PUT /api/v1/groups/<uuid>/budget` | HTTP 404 NOT_FOUND | PASS |
| PM-159 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-160 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-161 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-162 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/budget` | HTTP 404 NOT_FOUND | PASS |
| PM-163 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | outsider | 404 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 404 NOT_FOUND | PASS |
| PM-164 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | viewer | 403 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-165 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | editor | 403 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-166 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | owner | 204 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 204 | PASS |
| PM-167 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | outsider | 404 | `POST /api/v1/groups/<uuid>/fund` | HTTP 404 NOT_FOUND | PASS |
| PM-168 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | viewer | 403 | `POST /api/v1/groups/<uuid>/fund` | HTTP 403 FORBIDDEN | PASS |
| PM-169 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | editor | 201 | `POST /api/v1/groups/<uuid>/fund` | HTTP 201 | PASS |
| PM-170 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | owner | 200 | `PATCH /api/v1/groups/<uuid>/fund` | HTTP 200 | PASS |
| PM-171 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | editor | 200 | `PATCH /api/v1/groups/<uuid>/fund` | HTTP 200 | PASS |
| PM-172 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | viewer | 403 | `PATCH /api/v1/groups/<uuid>/fund` | HTTP 403 FORBIDDEN | PASS |
| PM-173 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | outsider | 404 | `PATCH /api/v1/groups/<uuid>/fund` | HTTP 404 NOT_FOUND | PASS |
| PM-174 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | outsider | 404 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 404 NOT_FOUND | PASS |
| PM-175 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | viewer | 403 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 403 FORBIDDEN | PASS |
| PM-176 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | editor | 204 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 204 | PASS |
| PM-177 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund (owner) | owner | 201 | `POST /api/v1/groups/<uuid>/fund` | HTTP 201 | PASS |
| PM-178 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund (owner) | owner | 204 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 204 | PASS |
| PM-179 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-180 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-181 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-182 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 404 NOT_FOUND | PASS |
| PM-183 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-184 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-185 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-186 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-187 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-188 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/parse` | HTTP 200 | PASS |
| PM-189 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/parse` | HTTP 200 | PASS |
| PM-190 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/parse` | HTTP 403 FORBIDDEN | PASS |
| PM-191 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/parse` | HTTP 404 NOT_FOUND | PASS |
| PM-192 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/preview` | HTTP 200 | PASS |
| PM-193 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/preview` | HTTP 200 | PASS |
| PM-194 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/preview` | HTTP 403 FORBIDDEN | PASS |
| PM-195 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/preview` | HTTP 404 NOT_FOUND | PASS |
| PM-196 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/items/preview` | HTTP 200 | PASS |
| PM-197 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/items/preview` | HTTP 200 | PASS |
| PM-198 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/items/preview` | HTTP 403 FORBIDDEN | PASS |
| PM-199 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/items/preview` | HTTP 404 NOT_FOUND | PASS |
| PM-200 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | owner | 201 | `POST /api/v1/groups/<uuid>/transactions` | HTTP 201 | PASS |
| PM-201 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | editor | 201 | `POST /api/v1/groups/<uuid>/transactions` | HTTP 201 | PASS |
| PM-202 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions` | HTTP 403 FORBIDDEN | PASS |
| PM-203 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions` | HTTP 404 NOT_FOUND | PASS |
| PM-204 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | outsider | 404 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-205 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | viewer | 403 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-206 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | editor | 200 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-207 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v2 | owner | 200 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-208 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | Cross-group | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-209 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | outsider | 404 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-210 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | viewer | 403 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-211 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | editor | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 204 | PASS |
| PM-212 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 404 NOT_FOUND | PASS |
| PM-213 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 403 FORBIDDEN | PASS |
| PM-214 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 200 | PASS |
| PM-215 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | owner | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 204 | PASS |
| PM-216 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 404 NOT_FOUND | PASS |
| PM-217 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 403 FORBIDDEN | PASS |
| PM-218 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | editor | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 403 FORBIDDEN | PASS |
| PM-219 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 200 | PASS |
| PM-220 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject` | HTTP 404 NOT_FOUND | PASS |
| PM-221 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject` | HTTP 403 FORBIDDEN | PASS |
| PM-222 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | editor | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject` | HTTP 403 FORBIDDEN | PASS |
| PM-223 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject` | HTTP 200 | PASS |
| PM-224 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-225 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-226 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-227 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 404 NOT_FOUND | PASS |
| PM-228 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 404 NOT_FOUND | PASS |
| PM-229 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | owner | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 201 | PASS |
| PM-230 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | editor | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 201 | PASS |
| PM-231 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 201 | PASS |
| PM-232 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 404 NOT_FOUND | PASS |
| PM-233 | Phase 4A / R10 | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Deleted tx2 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 201 | PASS |
| PM-234 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | outsider | 404 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-235 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | editor (non-author) | 403 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-236 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | owner (non-author) | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 204 | PASS |
| PM-237 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute` | HTTP 404 NOT_FOUND | PASS |
| PM-238 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Deleted tx2 | viewer | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute` | HTTP 404 NOT_FOUND | PASS |
| PM-239 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute` | HTTP 201 | PASS |
| PM-240 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 404 NOT_FOUND | PASS |
| PM-241 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | editor (non-opener) | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 403 FORBIDDEN | PASS |
| PM-242 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | viewer (opener) | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 200 | PASS |
| PM-243 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Suggested transfer | outsider | 404 | `POST /api/v1/groups/<uuid>/reminders` | HTTP 404 NOT_FOUND | PASS |
| PM-244 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Suggested transfer (viewer not receiver) | viewer | 403 | `POST /api/v1/groups/<uuid>/reminders` | HTTP 403 FORBIDDEN | PASS |
| PM-245 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Suggested transfer | owner | 200 | `POST /api/v1/groups/<uuid>/reminders` | HTTP 200 | PASS |
| PM-246 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-247 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-248 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-249 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 404 NOT_FOUND | PASS |
| PM-250 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests` | HTTP 404 NOT_FOUND | PASS |
| PM-251 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Viewer own payment | viewer (payer) | 201 | `POST /api/v1/groups/<uuid>/settlement-requests` | HTTP 201 | PASS |
| PM-252 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 404 NOT_FOUND | PASS |
| PM-253 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | editor (non-payer) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 403 FORBIDDEN | PASS |
| PM-254 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | viewer (payer) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 200 | PASS |
| PM-255 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 404 NOT_FOUND | PASS |
| PM-256 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | viewer (payer, not receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 403 FORBIDDEN | PASS |
| PM-257 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | owner (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 200 | PASS |
| PM-258 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 404 NOT_FOUND | PASS |
| PM-259 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | viewer (payer, not receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 403 FORBIDDEN | PASS |
| PM-260 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | owner (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 200 | PASS |
| PM-261 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | outsider | 404 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 404 NOT_FOUND | PASS |
| PM-262 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | viewer | 403 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 403 FORBIDDEN | PASS |
| PM-263 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | editor | 201 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 201 | PASS |
| PM-264 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | owner | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-265 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | editor | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-266 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | viewer | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-267 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | outsider | 404 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 404 NOT_FOUND | PASS |
| PM-268 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 404 NOT_FOUND | PASS |
| PM-269 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | outsider | 404 | `POST /api/v1/groups/<uuid>/receipt-scans` | HTTP 404 NOT_FOUND | PASS |
| PM-270 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | viewer | 403 | `POST /api/v1/groups/<uuid>/receipt-scans` | HTTP 403 FORBIDDEN | PASS |
| PM-271 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | editor | 201 | `POST /api/v1/groups/<uuid>/receipt-scans` | HTTP 201 | PASS |
| PM-272 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | owner | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-273 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | editor | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-274 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | viewer | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-275 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | outsider | 404 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-276 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-277 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | outsider | 404 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-278 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | viewer | 403 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-279 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | editor | 204 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 204 | PASS |
| PM-280 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 200 | PASS |
| PM-281 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | editor | 403 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 403 FORBIDDEN | PASS |
| PM-282 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | viewer | 403 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 403 FORBIDDEN | PASS |
| PM-283 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 404 NOT_FOUND | PASS |
| PM-284 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | owner | 200 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 200 | PASS |
| PM-285 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | editor | 403 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 403 FORBIDDEN | PASS |
| PM-286 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | viewer | 403 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 403 FORBIDDEN | PASS |
| PM-287 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | outsider | 404 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 404 NOT_FOUND | PASS |
| PM-288 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | outsider | 404 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-289 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | viewer | 403 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-290 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | editor | 403 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-291 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-292 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | owner | 204 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 204 | PASS |
| PM-293 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | owner | 200 | `PATCH /api/v1/groups/<uuid>/users/<uuid>` | HTTP 200 | PASS |
| PM-294 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | editor | 403 | `PATCH /api/v1/groups/<uuid>/users/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-295 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | viewer | 403 | `PATCH /api/v1/groups/<uuid>/users/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-296 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | outsider | 404 | `PATCH /api/v1/groups/<uuid>/users/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-297 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung | outsider | 404 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-298 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung | editor | 403 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-299 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung | owner | 204 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 204 | PASS |
| PM-300 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/leave` | HTTP 404 NOT_FOUND | PASS |
| PM-301 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Editor leaves | editor | 204 | `POST /api/v1/groups/<uuid>/leave` | HTTP 204 | PASS |
| PM-302 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/transfer-ownership` | HTTP 404 NOT_FOUND | PASS |
| PM-303 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Editor | editor | 403 | `POST /api/v1/groups/<uuid>/transfer-ownership` | HTTP 403 FORBIDDEN | PASS |
| PM-304 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Owner -> Lan | owner | 200 | `POST /api/v1/groups/<uuid>/transfer-ownership` | HTTP 200 | PASS |
| PM-305 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gDest | outsider | 404 | `DELETE /api/v1/groups/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-306 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gOwn (Minh now editor) | editor | 403 | `DELETE /api/v1/groups/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-307 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gDest | owner | 204 | `DELETE /api/v1/groups/<uuid>` | HTTP 204 | PASS |
| PM-308 | Phase 1A | `DELETE /api/v1/me` | Unauth | unauthenticated | 401 | `DELETE /api/v1/me` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-309 | Phase 1A | `DELETE /api/v1/me` | Fresh registered user | authenticated | 204 | `DELETE /api/v1/me` | HTTP 204 | PASS |

## 4. Earlier-Phase Representative Replay (Labeled Representative)

| Stage | Case | Expected | Actual | Status |
|---|---|---|---|---|
| 1A | Register account | 204 | 204 | PASS |
| 1A | Change password revokes other sessions | 204 then 401 on other session | 204, 401 | PASS |
| 1A | Logout revokes current session | 204 then 401 | 204, 401 | PASS |
| 1B | Invite join, rotate invalidates old token, role change | 200, 404 on old token, 200, 200 | 200, 404, 200, 200 | PASS |
| 1C | Uneven equal split 300001 -> integer shares & zero-sum balance | 201, sum=0, Lan=-100000 | 201, sum=0 | PASS |
| 1D | Rule quick-entry parse | 200 ok 180000 | 200 ok 180000 | PASS |
| 1E | Edit v1->v2, stale v1 409, delete, restore, activity | 200, 409, 204, 200, >=4 activities | 200, 409, 204, 200, 9 | PASS |
| 2A | Payment method (VietQR) & settlement confirm | 200, 201, 200 confirmed | 200, 201, 200 confirmed | PASS |
| 2B | Stats total=300000 & UTF-8 BOM CSV export | 200 total=300000, BOM CSV | 200 300000, 200 bom=true | PASS |
| 2C | Fund creation & 200k contribution | 201, 201, fund.cash=200000 | 201, 201, cash=200000 | PASS |
| 2D | Budget 350k with 300k spent -> state=near | 200, spent=300000, near | 200, 300000 near | PASS |
| 3A | Attachment upload magic-byte rejection & valid PNG | 400 then 201 | 400, 201 | PASS |
| 3B | Fake receipt scan worker job -> status=done | 201 then done | 201, done | PASS |
| 3C | Items preview with tax & targetAdjustment=8000 | 200, targetAdjustment=8000 | 200, {"kind":"other","amount":8000} | PASS |
| 3D | Explicit sentence AI opt-in (ai:false=rules, ai:true=ai) | rules then ai | rules, ai | PASS |

## 5. Phase 4 Stage Gates and R1-R10 Regression Summary

| Area | Case | Expected | Actual | Status |
|---|---|---|---|---|
| 4A/R10 | Deleted tx comment (201), open-dispute resolve (200), new dispute on deleted (404), restore retains comments, balances unchanged | 201,201,204,201,deleted=true,200,404,200 count=2,balEqual | 201,201,204,201,deleted=true,200,404,200 count=2 | PASS |
| 4B/R2+R3 | Advertised web URL form POST (no session/Origin, foreign Origin, older token retained), GET 200, bad 404, hash-only DB | 204,204,200,404,both false | 204,204,200,404,imm=false,dig=false | PASS |
| 4B/R4+R5 | Manual 200->429, auto-reminders transactional pg-boss enqueue (2 then 0), transient failure retry succeeds | 200,429,auto=2->0,queued>=2,retry=true | 200,429,auto=2->0,queued=47,threw=true,retried=true | PASS |
| 4B/R9 | Inter-recipient group removal drops removed-group text/name/overflow (2 not 7) & repeat run=0 | sent=2,noLeak,overflow=2,repeat=0 | sent=2,leaked=false,hasOverflow2=true,repeat=0 | PASS |
| 4C/R1 | Two-sided Telegram pairing (stage=0, wrongCb ignored, tgConfirm=0, concurrent webConfirm=[204,400], active=1) | 0,pending_telegram,0,[204,400],1 | 0,pending_telegram,0,[204,400],1 | PASS |
| 4C/R7 | Injected failure rolls back tx & idempotency key (0/0), retry commits 1 tx + savedRef, /huy soft-deletes | fail=0/0,retry=1,savedRef!=null,undone=true | fail=0/0,retry=1,savedRef=true,undone=true | PASS |
| 4D/R6+R8 | Full 13-row 4D.2 exact balances, 4D.1 variants, R6 preview/save parity, R8 decision-time amount, stale v1 409, check-balances | all 13 rows exact + R6 + R8 + All groups balanced | rows1-13=ok,staleEdit=409,R8="Minh duyệt Row1 · 1.200.000 đ",R6Lan=[],R6Minh=BUDGET_OVER | PASS |

## 6. 1,000-Notification Performance & Query Plan

- Page 1 (`limit=30`): `8.6 ms` (< 300 ms)
- Cursor Page 2 (`limit=30`): `4.58 ms` (< 300 ms)
- Unread count after removing 500-row group: `500`, full cursor walk: `500`, leaked rows from removed group: `0`

```text
Limit  (cost=71.53..71.60 rows=31 width=264) (actual time=0.281..0.284 rows=31 loops=1)
  Buffers: shared hit=47
  ->  Sort  (cost=71.53..72.04 rows=205 width=264) (actual time=0.281..0.282 rows=31 loops=1)
        Sort Key: n.created_at DESC, n.id DESC
        Sort Method: top-N heapsort  Memory: 56kB
        Buffers: shared hit=47
        ->  Hash Join  (cost=3.70..65.42 rows=205 width=264) (actual time=0.017..0.160 rows=1000 loops=1)
              Hash Cond: (n.group_id = gu.group_id)
              Buffers: shared hit=47
              ->  Seq Scan on notifications n  (cost=0.00..58.99 rows=1000 width=264) (actual time=0.009..0.067 rows=1000 loops=1)
                    Filter: (user_id = '01a1f2ad-be84-762c-a459-ea84836876dc'::uuid)
                    Rows Removed by Filter: 119
                    Buffers: shared hit=45
              ->  Hash  (cost=3.45..3.45 rows=20 width=32) (actual time=0.006..0.006 rows=16 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB
                    Buffers: shared hit=2
                    ->  Seq Scan on group_users gu  (cost=0.00..3.45 rows=20 width=32) (actual time=0.002..0.004 rows=16 loops=1)
                          Filter: (user_id = '01a1f2ad-be84-762c-a459-ea84836876dc'::uuid)
                          Rows Removed by Filter: 66
                          Buffers: shared hit=2
Planning:
  Buffers: shared hit=2
Planning Time: 0.055 ms
Execution Time: 0.290 ms
```

## 7. Deferred Items (Not Converted to Pass)

- Real SMTP delivery and real external mail-provider RFC 8058 callbacks (local console mailer and simulated HTTP POST used).
- Real Telegram Bot API (`api.telegram.org`) and public HTTPS webhook registration (`TELEGRAM_PROVIDER=console` and local webhook POST used).
- Real AI providers (`gemini`/`openai`/`anthropic`) and 30-receipt accuracy measurement (deferred by owner until all phases including iOS are done; `AI_PROVIDER=fake` used).
- Real Google OAuth login and owner-device manual checks.
