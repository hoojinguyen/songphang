# Phase 4 — R11 Completion: Expanded Gate Inventory, 4D.1 Money Matrix, and Final-SHA Browser Replay Protocol

> **Supersedes:** [gate-inventory-round-2.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/gate-inventory-round-2.md) (retained intact as historical evidence).
> **Addresses:** [review-round-3.md](file:///Users/hoojinguyen/Projects/songphang/docs/superpowers/runs/phase-4/review-round-3.md) — **R11 [P2]** only (R9 and R10 passed review and remain fixed).

## 1. Mapping Round 3 R11 Gaps to New Case IDs

| Round 3 R11 Gap | Resolution | Case IDs |
|---|---|---|
| 1. Endpoint-by-caller matrix gaps (`POST /reminders`, `POST /transactions/:id/restore`, `POST /leave`, and 14 other group routes missing one or more roles) | Audited all 99 registered Hono routes (62 group, 20 personal, 14 public/token, 2 dev, 1 webhook). Added every missing role combination across all 17 previously incomplete group routes plus unauth/unverified-member/cross-group/author/opener/payer/receiver cases, asserting **0 missing group-role combinations** across all 62 group routes. | `PM-001`–`PM-353` (reminders: `PM-257`–`PM-267`; restore: `PM-214`–`PM-222`; leave: `PM-337`–`PM-341`; all 17 gap routes closed) |
| 2. Incomplete 4D.1 money matrix (missing `minimizeDebts=false` PATCH, fund-paid threshold expense, stats breakdowns, parsed CSV, reminders on uncounted pairs, Telegram `/sodu`, items & fake-receipt threshold saves) | Built dedicated 31-case 4D.1 matrix across 3 independent fixture groups (`M1` person-paid, `M2` fund-paid + income/transfer non-pending, `M3` items-split + fake-receipt save) with pre-derived expected values across `pending`, `rejected`, and `approved`, plus unchanged 13-row 4D.2 table and `pnpm db:check-balances` checkpoints. | `M4D-001`–`M4D-031` |
| 3. Incomplete final-SHA browser replay (`preFreezeFullBrowserPass` reliance, missing full keyboard/focus, S11, offline, lost-access, contrast checks on final SHA) | Defined 16 explicit post-freeze browser case IDs (`BR-01`–`BR-16`) covering S20, S19/Bell (manual + automatic reminder live update), S5, S11, S13, R1 pairing, signed-out unsubscribe, keyboard/Escape/focus/44px, rendered contrast ratios, 375px mobile overflow, offline write error/revert, and lost-access privacy — all executed strictly AFTER freezing the final SHA. | `BR-01`–`BR-16` |

## 2. Isolated Environment and Final-SHA Replay Protocol

- **Disposable database:** `songphang_phase4_r11_20261119` (verified via `SELECT current_database()` before every reset; never modifying `songphang` or prior agents'/reviewers' databases; never running `docker compose down -v`).
- **Isolated uploads & ports:** `STORAGE_DIR=/tmp/songphang-r11-uploads`, API `4070` (standalone suites `4071`–`4077`), Web `3070`.
- **Final-SHA artifact convention (outside repo):** `/Users/hoojinguyen/.gemini/antigravity/brain/c49aa591-9496-4ea8-aa53-d2f8241d3e34/final-replay-<FULL_SHA>/` containing `manifest.json` (SHA, clean worktree status, serving build revision, timestamps, exact per-family required/applicable/executed/passed/failed/not-run counts) and sanitized JSON/log/screenshot artifacts.
- **Legitimate N/A justification:** Non-group routes (20 personal `/me/*` & `/auth/*` routes, 14 public/token routes, 2 dev-login routes, 1 Telegram secret-authenticated webhook) do not take a `groupId` parameter and do not use group roles (`owner`/`editor`/`viewer`/`outsider`); each is exercised with its own auth/session/token/secret matrix per `docs/05-api-spec.md`.

## 3. Expanded Endpoint-by-Caller Permission Matrix (99 Routes, 353 Cases, Pre-Freeze Verified)

| Case ID | Source | Method / Path | Fixture & Preconditions | Caller | Expected | Reproducible Invocation (Sanitized) | Actual (Pre-Freeze) | Status |
|---|---|---|---|---|---|---|---|---|
| PM-001 | Phase 1A auth | `POST /api/v1/auth/register` | Fresh email/password | public | 204 | `POST /api/v1/auth/register body={"name":"Unverified User","email":"unverified-c6e998ff@dev.songphang.local","password":"<redacted>"}` | HTTP 204 | PASS |
| PM-002 | Phase 0 | `GET /api/v1/health` | None | public | 200 | `GET /api/v1/health` | HTTP 200 | PASS |
| PM-003 | Phase 3A | `GET /api/v1/features` | None | public | 200 | `GET /api/v1/features` | HTTP 200 | PASS |
| PM-004 | Phase 0 | `GET /api/v1/openapi.json` | None | public | 200 | `GET /api/v1/openapi.json` | HTTP 200 | PASS |
| PM-005 | Phase 1A | `GET /api/v1/auth/providers` | None | public | 200 | `GET /api/v1/auth/providers` | HTTP 200 | PASS |
| PM-006 | Phase 0 dev | `GET /api/v1/dev/users` | DEV_LOGIN=true | public | 200 | `GET /api/v1/dev/users` | HTTP 200 | PASS |
| PM-007 | Phase 0 dev | `POST /api/v1/dev/login` | DEV_LOGIN=true | public | 204 | `POST /api/v1/dev/login body={"userId":"<uuid>"}` | HTTP 204 | PASS |
| PM-008 | Phase 1A | `POST /api/v1/auth/login` | Registered credentials | public | 204 | `POST /api/v1/auth/login body={"email":"unverified-c6e998ff@dev.songphang.local","password":"<redacted>"}` | HTTP 204 | PASS |
| PM-009 | Phase 1A | `POST /api/v1/auth/forgot-password` | Non-enumerating | public | 204 | `POST /api/v1/auth/forgot-password body={"email":"unverified-c6e998ff@dev.songphang.local"}` | HTTP 204 | PASS |
| PM-010 | Phase 1A | `POST /api/v1/auth/reset-password` | Invalid token | public | 400 | `POST /api/v1/auth/reset-password body={"token":"<redacted>","password":"<redacted>"}` | HTTP 400 TOKEN_INVALID | PASS |
| PM-011 | Phase 1A | `POST /api/v1/auth/verify-email` | Invalid token | public | 400 | `POST /api/v1/auth/verify-email body={"token":"<redacted>"}` | HTTP 400 TOKEN_INVALID | PASS |
| PM-012 | Phase 1A | `GET /api/v1/auth/google` | OAuth configured | public | 302 | `GET /api/v1/auth/google` | HTTP 302 | PASS |
| PM-013 | Phase 1A | `GET /api/v1/auth/google/callback` | Missing/invalid state | public | 302/400 | `GET /api/v1/auth/google/callback?code=x&state=bad` | HTTP 302 | PASS |
| PM-014 | Phase 1A | `POST /api/v1/auth/resend-verification` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/resend-verification` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-015 | Phase 1A | `POST /api/v1/auth/resend-verification` | Unverified session | unverified | 204 | `POST /api/v1/auth/resend-verification` | HTTP 204 | PASS |
| PM-016 | Phase 1A | `POST /api/v1/auth/change-password` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/change-password body={"currentPassword":"<redacted>","newPassword":"<redacted>","revokeOtherSessions":true}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-017 | Phase 1A | `POST /api/v1/auth/change-password` | Valid current password | authenticated | 204 | `POST /api/v1/auth/change-password body={"currentPassword":"<redacted>","newPassword":"<redacted>","revokeOtherSessions":true}` | HTTP 204 | PASS |
| PM-018 | Phase 1A | `POST /api/v1/auth/logout` | Unauth | unauthenticated | 401 | `POST /api/v1/auth/logout` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-019 | Phase 1A | `POST /api/v1/auth/logout` | Active session | authenticated | 204 | `POST /api/v1/auth/logout` | HTTP 204 | PASS |
| PM-020 | Phase 1B | `GET /api/v1/invites/:token` | Valid invite token | unauthenticated | 401 | `GET /api/v1/invites/<token>` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-021 | Phase 1B | `GET /api/v1/invites/:token` | Valid invite token | authenticated | 200 | `GET /api/v1/invites/<token>` | HTTP 200 | PASS |
| PM-022 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite | unauthenticated | 401 | `POST /api/v1/invites/<token>/join body={}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-023 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite | unverified | 403 | `POST /api/v1/invites/<token>/join body={}` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-024 | Phase 1B | `POST /api/v1/invites/:token/join` | Valid invite on fresh group | authenticated (verified) | 200 | `POST /api/v1/invites/<token>/join body={"memberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-025 | Phase 4B / R2 | `POST /api/v1/notifications/unsubscribe` | Valid token, no session/Origin | public (token) | 204 | `POST /api/v1/notifications/unsubscribe body={"token":"<redacted>"}` | HTTP 204 | PASS |
| PM-026 | Phase 4B / R2 | `POST /api/v1/notifications/unsubscribe` | Invalid token | public (token) | 404 | `POST /api/v1/notifications/unsubscribe body={"token":"<redacted>"}` | HTTP 404 NOT_FOUND | PASS |
| PM-027 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Missing secret | public (no secret) | 404 | `POST /api/v1/bots/telegram/webhook body={"update_id":90001}` | HTTP 404 NOT_FOUND | PASS |
| PM-028 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Wrong secret | public (wrong secret) | 404 | `POST /api/v1/bots/telegram/webhook body={"update_id":90002}` | HTTP 404 NOT_FOUND | PASS |
| PM-029 | Phase 4C | `POST /api/v1/bots/telegram/webhook` | Valid secret | telegram webhook | 200 | `POST /api/v1/bots/telegram/webhook body={"update_id":90003}` | HTTP 200 | PASS |
| PM-030 | Phase 1A | `GET /api/v1/me` | Unauth | unauthenticated | 401 | `GET /api/v1/me` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-031 | Phase 1A | `GET /api/v1/me` | Signed in | authenticated | 200 | `GET /api/v1/me` | HTTP 200 | PASS |
| PM-032 | Phase 1B | `GET /api/v1/groups` | Unauth | unauthenticated | 401 | `GET /api/v1/groups` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-033 | Phase 1B | `GET /api/v1/groups` | Signed in | authenticated | 200 | `GET /api/v1/groups` | HTTP 200 | PASS |
| PM-034 | Phase 1B | `POST /api/v1/groups` | Unauth | unauthenticated | 401 | `POST /api/v1/groups body={"name":"X"}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-035 | Phase 1B | `POST /api/v1/groups` | Unverified | unverified | 403 | `POST /api/v1/groups body={"name":"X"}` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-036 | Phase 1B | `POST /api/v1/groups` | Verified user | authenticated | 201 | `POST /api/v1/groups body={"name":"PM Created"}` | HTTP 201 | PASS |
| PM-037 | Phase 4B | `GET /api/v1/me/notifications` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notifications` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-038 | Phase 4B | `GET /api/v1/me/notifications` | Signed in | authenticated | 200 | `GET /api/v1/me/notifications` | HTTP 200 | PASS |
| PM-039 | Phase 4B | `GET /api/v1/me/notifications/unread-count` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notifications/unread-count` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-040 | Phase 4B | `GET /api/v1/me/notifications/unread-count` | Signed in | authenticated | 200 | `GET /api/v1/me/notifications/unread-count` | HTTP 200 | PASS |
| PM-041 | Phase 4B | `POST /api/v1/me/notifications/read` | Unauth | unauthenticated | 401 | `POST /api/v1/me/notifications/read body={"all":true}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-042 | Phase 4B | `POST /api/v1/me/notifications/read` | Signed in | authenticated | 204 | `POST /api/v1/me/notifications/read body={"all":true}` | HTTP 204 | PASS |
| PM-043 | Phase 4B | `GET /api/v1/me/notification-settings` | Unauth | unauthenticated | 401 | `GET /api/v1/me/notification-settings` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-044 | Phase 4B | `GET /api/v1/me/notification-settings` | Signed in | authenticated | 200 | `GET /api/v1/me/notification-settings` | HTTP 200 | PASS |
| PM-045 | Phase 4B | `PUT /api/v1/me/notification-settings` | Unauth | unauthenticated | 401 | `PUT /api/v1/me/notification-settings body={"emailImmediate":true,"emailDigest":true}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-046 | Phase 4B | `PUT /api/v1/me/notification-settings` | Signed in | authenticated | 200 | `PUT /api/v1/me/notification-settings body={"emailImmediate":true,"emailDigest":true}` | HTTP 200 | PASS |
| PM-047 | Phase 4C | `GET /api/v1/me/chat-identities` | Unauth | unauthenticated | 401 | `GET /api/v1/me/chat-identities` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-048 | Phase 4C | `GET /api/v1/me/chat-identities` | Signed in | authenticated | 200 | `GET /api/v1/me/chat-identities` | HTTP 200 | PASS |
| PM-049 | Phase 4C / R1 | `POST /api/v1/me/chat-identities/claim` | Legacy claim disabled | authenticated | 400 (TOKEN_INVALID) | `POST /api/v1/me/chat-identities/claim body={"code":"ABCD2345"}` | HTTP 400 TOKEN_INVALID | PASS |
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
| PM-066 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | owner | 200 | `PATCH /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 200 | PASS |
| PM-067 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | editor | 403 | `PATCH /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 403 FORBIDDEN | PASS |
| PM-068 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | viewer | 403 | `PATCH /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 403 FORBIDDEN | PASS |
| PM-069 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | outsider | 404 | `PATCH /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 404 NOT_FOUND | PASS |
| PM-070 | Phase 1B/4B/4D | `PATCH /api/v1/groups/:groupId` | Update name | unauthenticated | 401 | `PATCH /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 401 UNAUTHENTICATED | PASS |
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
| PM-095 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | owner | 201 | `POST /api/v1/groups/<uuid>/members body={"name":"M-8e6ce"}` | HTTP 201 | PASS |
| PM-096 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | editor | 201 | `POST /api/v1/groups/<uuid>/members body={"name":"M-8e6ce"}` | HTTP 201 | PASS |
| PM-097 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | viewer | 403 | `POST /api/v1/groups/<uuid>/members body={"name":"M-8e6ce"}` | HTTP 403 FORBIDDEN | PASS |
| PM-098 | Phase 1B | `POST /api/v1/groups/:groupId/members` | New member name | outsider | 404 | `POST /api/v1/groups/<uuid>/members body={"name":"M-8e6ce"}` | HTTP 404 NOT_FOUND | PASS |
| PM-099 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | owner | 200 | `PATCH /api/v1/groups/<uuid>/members/<uuid> body={"name":"Khách"}` | HTTP 200 | PASS |
| PM-100 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | editor | 200 | `PATCH /api/v1/groups/<uuid>/members/<uuid> body={"name":"Khách"}` | HTTP 200 | PASS |
| PM-101 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | viewer | 403 | `PATCH /api/v1/groups/<uuid>/members/<uuid> body={"name":"Khách"}` | HTTP 403 FORBIDDEN | PASS |
| PM-102 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Guest member | outsider | 404 | `PATCH /api/v1/groups/<uuid>/members/<uuid> body={"name":"Khách"}` | HTTP 404 NOT_FOUND | PASS |
| PM-103 | Phase 1B | `PATCH /api/v1/groups/:groupId/members/:memberId` | Cross-group resource ID | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/members/<uuid> body={"name":"Khách"}` | HTTP 404 NOT_FOUND | PASS |
| PM-104 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | owner | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 200 | PASS |
| PM-105 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | editor | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 200 | PASS |
| PM-106 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | viewer | 200 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 200 | PASS |
| PM-107 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer own member vs editor | outsider | 404 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 404 NOT_FOUND | PASS |
| PM-108 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Cross-group resource ID | owner (G2) | 404 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 404 NOT_FOUND | PASS |
| PM-109 | Phase 2A | `PUT /api/v1/groups/:groupId/members/:memberId/payment-methods` | Viewer editing OTHER member | viewer (other member) | 403 | `PUT /api/v1/groups/<uuid>/members/<uuid>/payment-methods body={"methods":[]}` | HTTP 403 FORBIDDEN | PASS |
| PM-110 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | outsider | 404 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-111 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | viewer | 403 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-112 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Cross-group member | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-113 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Unreferenced member | editor | 204 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 204 | PASS |
| PM-114 | Phase 1B | `DELETE /api/v1/groups/:groupId/members/:memberId` | Fresh unreferenced member | owner | 204 | `DELETE /api/v1/groups/<uuid>/members/<uuid>` | HTTP 204 | PASS |
| PM-115 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/invite` | HTTP 200 | PASS |
| PM-116 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/invite` | HTTP 200 | PASS |
| PM-117 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | viewer | 403 | `GET /api/v1/groups/<uuid>/invite` | HTTP 403 FORBIDDEN | PASS |
| PM-118 | Phase 1B | `GET /api/v1/groups/:groupId/invite` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/invite` | HTTP 404 NOT_FOUND | PASS |
| PM-119 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | owner | 200 | `PATCH /api/v1/groups/<uuid>/invite body={"active":true}` | HTTP 200 | PASS |
| PM-120 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | editor | 403 | `PATCH /api/v1/groups/<uuid>/invite body={"active":true}` | HTTP 403 FORBIDDEN | PASS |
| PM-121 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | viewer | 403 | `PATCH /api/v1/groups/<uuid>/invite body={"active":true}` | HTTP 403 FORBIDDEN | PASS |
| PM-122 | Phase 1B | `PATCH /api/v1/groups/:groupId/invite` | Toggle active | outsider | 404 | `PATCH /api/v1/groups/<uuid>/invite body={"active":true}` | HTTP 404 NOT_FOUND | PASS |
| PM-123 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | owner | 200 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 200 | PASS |
| PM-124 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | editor | 403 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 403 FORBIDDEN | PASS |
| PM-125 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | viewer | 403 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 403 FORBIDDEN | PASS |
| PM-126 | Phase 1B | `POST /api/v1/groups/:groupId/invite/rotate` | Rotate token | outsider | 404 | `POST /api/v1/groups/<uuid>/invite/rotate` | HTTP 404 NOT_FOUND | PASS |
| PM-127 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | owner | 200 | `PUT /api/v1/groups/<uuid>/me/muted body={"muted":false}` | HTTP 200 | PASS |
| PM-128 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | editor | 200 | `PUT /api/v1/groups/<uuid>/me/muted body={"muted":false}` | HTTP 200 | PASS |
| PM-129 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | viewer | 200 | `PUT /api/v1/groups/<uuid>/me/muted body={"muted":false}` | HTTP 200 | PASS |
| PM-130 | Phase 4B | `PUT /api/v1/groups/:groupId/me/muted` | Mute toggle | outsider | 404 | `PUT /api/v1/groups/<uuid>/me/muted body={"muted":false}` | HTTP 404 NOT_FOUND | PASS |
| PM-131 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Re-claim own member | owner | 200 | `PUT /api/v1/groups/<uuid>/me/member body={"memberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-132 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Re-claim own member | editor | 200 | `PUT /api/v1/groups/<uuid>/me/member body={"memberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-133 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Re-claim own member | viewer | 200 | `PUT /api/v1/groups/<uuid>/me/member body={"memberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-134 | Phase 1B | `PUT /api/v1/groups/:groupId/me/member` | Outsider | outsider | 404 | `PUT /api/v1/groups/<uuid>/me/member body={"memberId":"<uuid>"}` | HTTP 404 NOT_FOUND | PASS |
| PM-135 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | owner | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-136 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | editor | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-137 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | viewer | 200 | `GET /api/v1/groups/<uuid>/events` | HTTP 200 | PASS |
| PM-138 | Phase 1E SSE | `GET /api/v1/groups/:groupId/events` | G1 SSE stream | outsider | 404 | `GET /api/v1/groups/<uuid>/events` | HTTP 404 | PASS |
| PM-139 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-140 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-141 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/categories` | HTTP 200 | PASS |
| PM-142 | Phase 2B | `GET /api/v1/groups/:groupId/categories` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/categories` | HTTP 404 NOT_FOUND | PASS |
| PM-143 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | owner | 201 | `POST /api/v1/groups/<uuid>/categories body={"name":"PM Cat","color":"mint"}` | HTTP 201 | PASS |
| PM-144 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | editor | 201 | `POST /api/v1/groups/<uuid>/categories body={"name":"PM Cat 2","color":"mint"}` | HTTP 201 | PASS |
| PM-145 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | viewer | 403 | `POST /api/v1/groups/<uuid>/categories body={"name":"PM Cat V","color":"mint"}` | HTTP 403 FORBIDDEN | PASS |
| PM-146 | Phase 2B | `POST /api/v1/groups/:groupId/categories` | New category | outsider | 404 | `POST /api/v1/groups/<uuid>/categories body={"name":"PM Cat O","color":"mint"}` | HTTP 404 NOT_FOUND | PASS |
| PM-147 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | owner | 200 | `PATCH /api/v1/groups/<uuid>/categories/<uuid> body={"name":"PM Cat Renamed"}` | HTTP 200 | PASS |
| PM-148 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | editor | 200 | `PATCH /api/v1/groups/<uuid>/categories/<uuid> body={"name":"PM Cat Renamed"}` | HTTP 200 | PASS |
| PM-149 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | viewer | 403 | `PATCH /api/v1/groups/<uuid>/categories/<uuid> body={"name":"PM Cat Renamed"}` | HTTP 403 FORBIDDEN | PASS |
| PM-150 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Custom category | outsider | 404 | `PATCH /api/v1/groups/<uuid>/categories/<uuid> body={"name":"PM Cat Renamed"}` | HTTP 404 NOT_FOUND | PASS |
| PM-151 | Phase 2B | `PATCH /api/v1/groups/:groupId/categories/:id` | Cross-group resource ID | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/categories/<uuid> body={"name":"PM Cat Renamed"}` | HTTP 404 NOT_FOUND | PASS |
| PM-152 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | outsider | 404 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-153 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | viewer | 403 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-154 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-155 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Custom category | editor | 204 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 204 | PASS |
| PM-156 | Phase 2B | `DELETE /api/v1/groups/:groupId/categories/:id` | Fresh custom category | owner | 204 | `DELETE /api/v1/groups/<uuid>/categories/<uuid>` | HTTP 204 | PASS |
| PM-157 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | owner | 200 | `PUT /api/v1/groups/<uuid>/budget body={"amount":2000000,"period":"month"}` | HTTP 200 | PASS |
| PM-158 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | editor | 403 | `PUT /api/v1/groups/<uuid>/budget body={"amount":2000000,"period":"month"}` | HTTP 403 FORBIDDEN | PASS |
| PM-159 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | viewer | 403 | `PUT /api/v1/groups/<uuid>/budget body={"amount":2000000,"period":"month"}` | HTTP 403 FORBIDDEN | PASS |
| PM-160 | Phase 2D | `PUT /api/v1/groups/:groupId/budget` | Set monthly budget | outsider | 404 | `PUT /api/v1/groups/<uuid>/budget body={"amount":2000000,"period":"month"}` | HTTP 404 NOT_FOUND | PASS |
| PM-161 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-162 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-163 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/budget` | HTTP 200 | PASS |
| PM-164 | Phase 2D | `GET /api/v1/groups/:groupId/budget` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/budget` | HTTP 404 NOT_FOUND | PASS |
| PM-165 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | outsider | 404 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 404 NOT_FOUND | PASS |
| PM-166 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | viewer | 403 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-167 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | editor | 403 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 403 FORBIDDEN | PASS |
| PM-168 | Phase 2D | `DELETE /api/v1/groups/:groupId/budget` | G1 | owner | 204 | `DELETE /api/v1/groups/<uuid>/budget` | HTTP 204 | PASS |
| PM-169 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | outsider | 404 | `POST /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM"}` | HTTP 404 NOT_FOUND | PASS |
| PM-170 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | viewer | 403 | `POST /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM"}` | HTTP 403 FORBIDDEN | PASS |
| PM-171 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund | editor | 201 | `POST /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM"}` | HTTP 201 | PASS |
| PM-172 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | owner | 200 | `PATCH /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM 2"}` | HTTP 200 | PASS |
| PM-173 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | editor | 200 | `PATCH /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM 2"}` | HTTP 200 | PASS |
| PM-174 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | viewer | 403 | `PATCH /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM 2"}` | HTTP 403 FORBIDDEN | PASS |
| PM-175 | Phase 2C | `PATCH /api/v1/groups/:groupId/fund` | Rename fund | outsider | 404 | `PATCH /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM 2"}` | HTTP 404 NOT_FOUND | PASS |
| PM-176 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | outsider | 404 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 404 NOT_FOUND | PASS |
| PM-177 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | viewer | 403 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 403 FORBIDDEN | PASS |
| PM-178 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund | editor | 204 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 204 | PASS |
| PM-179 | Phase 2C | `POST /api/v1/groups/:groupId/fund` | Create fund (owner) | owner | 201 | `POST /api/v1/groups/<uuid>/fund body={"name":"Quỹ PM Owner"}` | HTTP 201 | PASS |
| PM-180 | Phase 2C | `DELETE /api/v1/groups/:groupId/fund` | Close fund (owner) | owner | 204 | `DELETE /api/v1/groups/<uuid>/fund` | HTTP 204 | PASS |
| PM-181 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-182 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-183 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 200 | PASS |
| PM-184 | Phase 1C | `GET /api/v1/groups/:groupId/transactions` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions` | HTTP 404 NOT_FOUND | PASS |
| PM-185 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-186 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-187 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 200 | PASS |
| PM-188 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | tx1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-189 | Phase 1C | `GET /api/v1/groups/:groupId/transactions/:id` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-190 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/parse body={"text":"cà phê 100k"}` | HTTP 200 | PASS |
| PM-191 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/parse body={"text":"cà phê 100k"}` | HTTP 200 | PASS |
| PM-192 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/parse body={"text":"cà phê 100k"}` | HTTP 403 FORBIDDEN | PASS |
| PM-193 | Phase 1D | `POST /api/v1/groups/:groupId/transactions/parse` | Simple sentence | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/parse body={"text":"cà phê 100k"}` | HTTP 404 NOT_FOUND | PASS |
| PM-194 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/preview body={"type":"expense","description":"Prev","amount":90000,"category":"food","occurredAt":"2026-11-19T11:32:12.831Z","payers":[{"memberId":"<uuid` | HTTP 200 | PASS |
| PM-195 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/preview body={"type":"expense","description":"Prev","amount":90000,"category":"food","occurredAt":"2026-11-19T11:32:12.831Z","payers":[{"memberId":"<uuid` | HTTP 200 | PASS |
| PM-196 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/preview body={"type":"expense","description":"Prev","amount":90000,"category":"food","occurredAt":"2026-11-19T11:32:12.831Z","payers":[{"memberId":"<uuid` | HTTP 403 FORBIDDEN | PASS |
| PM-197 | Phase 1C/R6 | `POST /api/v1/groups/:groupId/transactions/preview` | Equal preview | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/preview body={"type":"expense","description":"Prev","amount":90000,"category":"food","occurredAt":"2026-11-19T11:32:12.831Z","payers":[{"memberId":"<uuid` | HTTP 404 NOT_FOUND | PASS |
| PM-198 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/items/preview body={"items":[{"name":"Phở","amount":60000,"memberIds":["<uuid>","<uuid>"]}],"extras":[]}` | HTTP 200 | PASS |
| PM-199 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | editor | 200 | `POST /api/v1/groups/<uuid>/transactions/items/preview body={"items":[{"name":"Phở","amount":60000,"memberIds":["<uuid>","<uuid>"]}],"extras":[]}` | HTTP 200 | PASS |
| PM-200 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/items/preview body={"items":[{"name":"Phở","amount":60000,"memberIds":["<uuid>","<uuid>"]}],"extras":[]}` | HTTP 403 FORBIDDEN | PASS |
| PM-201 | Phase 3C | `POST /api/v1/groups/:groupId/transactions/items/preview` | Items split | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/items/preview body={"items":[{"name":"Phở","amount":60000,"memberIds":["<uuid>","<uuid>"]}],"extras":[]}` | HTTP 404 NOT_FOUND | PASS |
| PM-202 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | owner | 201 | `POST /api/v1/groups/<uuid>/transactions body={"type":"expense","description":"PM Tx","amount":60000,"category":"food","occurredAt":"2026-11-19T11:32:12.859Z","payers":[{"memberId":"<uui` | HTTP 201 | PASS |
| PM-203 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | editor | 201 | `POST /api/v1/groups/<uuid>/transactions body={"type":"expense","description":"PM Tx","amount":60000,"category":"food","occurredAt":"2026-11-19T11:32:12.859Z","payers":[{"memberId":"<uui` | HTTP 201 | PASS |
| PM-204 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions body={"type":"expense","description":"PM Tx","amount":60000,"category":"food","occurredAt":"2026-11-19T11:32:12.859Z","payers":[{"memberId":"<uui` | HTTP 403 FORBIDDEN | PASS |
| PM-205 | Phase 1C | `POST /api/v1/groups/:groupId/transactions` | New expense | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions body={"type":"expense","description":"PM Tx","amount":60000,"category":"food","occurredAt":"2026-11-19T11:32:12.859Z","payers":[{"memberId":"<uui` | HTTP 404 NOT_FOUND | PASS |
| PM-206 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | outsider | 404 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid> body={"type":"expense","version":1,"description":"PM Base outsider","amount":300000,"category":"food","occurredAt":"2026-11-19T11:32:12.124Z","pa` | HTTP 404 NOT_FOUND | PASS |
| PM-207 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | viewer | 403 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid> body={"type":"expense","version":1,"description":"PM Base viewer","amount":300000,"category":"food","occurredAt":"2026-11-19T11:32:12.124Z","paye` | HTTP 403 FORBIDDEN | PASS |
| PM-208 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v1 | editor | 200 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid> body={"type":"expense","version":1,"description":"PM Base editor","amount":300000,"category":"food","occurredAt":"2026-11-19T11:32:12.124Z","paye` | HTTP 200 | PASS |
| PM-209 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | tx1 v2 | owner | 200 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid> body={"type":"expense","version":2,"description":"PM Base owner","amount":300000,"category":"food","occurredAt":"2026-11-19T11:32:12.124Z","payer` | HTTP 200 | PASS |
| PM-210 | Phase 1E | `PATCH /api/v1/groups/:groupId/transactions/:id` | Cross-group | owner (G2) | 404 | `PATCH /api/v1/groups/<uuid>/transactions/<uuid> body={"type":"expense","version":1,"description":"X","amount":300000,"category":"food","occurredAt":"2026-11-19T11:32:12.946Z","payers":[{"member` | HTTP 404 NOT_FOUND | PASS |
| PM-211 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | outsider | 404 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-212 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | viewer | 403 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-213 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | editor | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 204 | PASS |
| PM-214 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 404 NOT_FOUND | PASS |
| PM-215 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 403 FORBIDDEN | PASS |
| PM-216 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | unauthenticated | 401 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-217 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 (unverified member) | unverified (member) | 403 (EMAIL_NOT_VERIFIED) | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-218 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Cross-group deleted tx2 | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 404 NOT_FOUND | PASS |
| PM-219 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Deleted tx2 | owner | 200 (restored deletedAt=null) | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 200 | PASS |
| PM-220 | Phase 1E | `POST /api/v1/groups/:groupId/transactions/:id/restore` | Independently deleted tx2Ed | editor | 200 (restored deletedAt=null) | `POST /api/v1/groups/<uuid>/transactions/<uuid>/restore` | HTTP 200 | PASS |
| PM-221 | Phase 1E | `DELETE /api/v1/groups/:groupId/transactions/:id` | tx2 | owner | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>` | HTTP 204 | PASS |
| PM-222 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 404 NOT_FOUND | PASS |
| PM-223 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 403 FORBIDDEN | PASS |
| PM-224 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | editor | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 403 FORBIDDEN | PASS |
| PM-225 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/approve` | Pending tx | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/approve` | HTTP 200 | PASS |
| PM-226 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject body={"note":"No"}` | HTTP 404 NOT_FOUND | PASS |
| PM-227 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | viewer | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject body={"note":"No"}` | HTTP 403 FORBIDDEN | PASS |
| PM-228 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | editor | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject body={"note":"No"}` | HTTP 403 FORBIDDEN | PASS |
| PM-229 | Phase 4D | `POST /api/v1/groups/:groupId/transactions/:id/reject` | Pending tx | owner | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/reject body={"note":"No"}` | HTTP 200 | PASS |
| PM-230 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | owner | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-231 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | editor | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-232 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | viewer | 200 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 200 | PASS |
| PM-233 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | outsider | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 404 NOT_FOUND | PASS |
| PM-234 | Phase 4A | `GET /api/v1/groups/:groupId/transactions/:id/comments` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/transactions/<uuid>/comments` | HTTP 404 NOT_FOUND | PASS |
| PM-235 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | owner | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments body={"body":"Hi"}` | HTTP 201 | PASS |
| PM-236 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | editor | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments body={"body":"Hi"}` | HTTP 201 | PASS |
| PM-237 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments body={"body":"Hi"}` | HTTP 201 | PASS |
| PM-238 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Live tx1 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments body={"body":"Hi"}` | HTTP 404 NOT_FOUND | PASS |
| PM-239 | Phase 4A / R10 | `POST /api/v1/groups/:groupId/transactions/:id/comments` | Deleted tx2 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/comments body={"body":"Comment on deleted"}` | HTTP 201 | PASS |
| PM-240 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | outsider | 404 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-241 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | editor (non-author) | 403 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-242 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-243 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung comment | owner (non-author) | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 204 | PASS |
| PM-244 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Lan comment | viewer (non-author) | 403 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-245 | Phase 4A | `DELETE /api/v1/groups/:groupId/transactions/:id/comments/:commentId` | Hung own comment | viewer (author) | 204 | `DELETE /api/v1/groups/<uuid>/transactions/<uuid>/comments/<uuid>` | HTTP 204 | PASS |
| PM-246 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"Bad"}` | HTTP 404 NOT_FOUND | PASS |
| PM-247 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Deleted tx2 | viewer | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"Bad"}` | HTTP 404 NOT_FOUND | PASS |
| PM-248 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | viewer | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"Wrong"}` | HTTP 201 | PASS |
| PM-249 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | outsider | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 404 NOT_FOUND | PASS |
| PM-250 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | editor (non-opener) | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 403 FORBIDDEN | PASS |
| PM-251 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Cross-group | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 404 NOT_FOUND | PASS |
| PM-252 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Hung | viewer (opener) | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 200 | PASS |
| PM-253 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Cross-group | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"X"}` | HTTP 404 NOT_FOUND | PASS |
| PM-254 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | editor | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"Editor dispute"}` | HTTP 201 | PASS |
| PM-255 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Lan | viewer (non-opener) | 403 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 403 FORBIDDEN | PASS |
| PM-256 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute/resolve` | Open dispute by Lan | owner (non-opener) | 200 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute/resolve` | HTTP 200 | PASS |
| PM-257 | Phase 4A | `POST /api/v1/groups/:groupId/transactions/:id/dispute` | Live tx1 | owner | 201 | `POST /api/v1/groups/<uuid>/transactions/<uuid>/dispute body={"reason":"Owner dispute"}` | HTTP 201 | PASS |
| PM-258 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Unauth | unauthenticated | 401 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-259 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Unverified member | unverified (member) | 403 (EMAIL_NOT_VERIFIED) | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 403 EMAIL_NOT_VERIFIED | PASS |
| PM-260 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 404 NOT_FOUND | PASS |
| PM-261 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Lan->Minh (Hung not receiver) | viewer (non-receiver) | 403 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 403 FORBIDDEN | PASS |
| PM-262 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Minh->Hung (Hung IS receiver) | viewer (receiver) | 200 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-263 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Hung->Lan (distinct pair) | editor | 200 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-264 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Lan->Minh (distinct pair) | owner | 200 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 200 | PASS |
| PM-265 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Repeat Lan->Minh within 24h | owner (cooldown) | 429 (REMINDER_TOO_SOON) | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 429 REMINDER_TOO_SOON | PASS |
| PM-266 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Guest->Minh unlinked debtor | owner (unlinked) | 422 (MEMBER_NOT_LINKED) | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 422 MEMBER_NOT_LINKED | PASS |
| PM-267 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Non-suggested pair Minh->Lan | owner (invalid pair) | 400 | `POST /api/v1/groups/<uuid>/reminders body={"fromMemberId":"<uuid>","toMemberId":"<uuid>"}` | HTTP 400 VALIDATION_FAILED | PASS |
| PM-268 | Phase 4B | `POST /api/v1/groups/:groupId/reminders` | Remind all pairs | owner (all:true) | 200 | `POST /api/v1/groups/<uuid>/reminders body={"all":true}` | HTTP 200 | PASS |
| PM-269 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-270 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | editor | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-271 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | viewer | 200 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 200 | PASS |
| PM-272 | Phase 2A | `GET /api/v1/groups/:groupId/settlement-requests` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/settlement-requests` | HTTP 404 NOT_FOUND | PASS |
| PM-273 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests body={"fromMemberId":"<uuid>","toMemberId":"<uuid>","amount":10000}` | HTTP 404 NOT_FOUND | PASS |
| PM-274 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Viewer for other payer | viewer (not payer) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests body={"fromMemberId":"<uuid>","toMemberId":"<uuid>","amount":10000}` | HTTP 403 FORBIDDEN | PASS |
| PM-275 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Owner creates request | owner | 201 | `POST /api/v1/groups/<uuid>/settlement-requests body={"fromMemberId":"<uuid>","toMemberId":"<uuid>","amount":5000}` | HTTP 201 | PASS |
| PM-276 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Editor creates request (distinct pair) | editor | 201 | `POST /api/v1/groups/<uuid>/settlement-requests body={"fromMemberId":"<uuid>","toMemberId":"<uuid>","amount":5000}` | HTTP 201 | PASS |
| PM-277 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests` | Viewer own payment | viewer (payer) | 201 | `POST /api/v1/groups/<uuid>/settlement-requests body={"fromMemberId":"<uuid>","toMemberId":"<uuid>","amount":10000}` | HTTP 201 | PASS |
| PM-278 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 404 NOT_FOUND | PASS |
| PM-279 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | editor (non-payer) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 403 FORBIDDEN | PASS |
| PM-280 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh, owner neither creator nor payer) | owner (non-payer) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 403 FORBIDDEN | PASS |
| PM-281 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | Cross-group | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 404 NOT_FOUND | PASS |
| PM-282 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/cancel` | sr1 (Hung->Minh) | viewer (payer) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/cancel` | HTTP 200 | PASS |
| PM-283 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 404 NOT_FOUND | PASS |
| PM-284 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | viewer (payer, not receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 403 FORBIDDEN | PASS |
| PM-285 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh, Lan not receiver) | editor (non-receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 403 FORBIDDEN | PASS |
| PM-286 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | Cross-group | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 404 NOT_FOUND | PASS |
| PM-287 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2 (Hung->Minh) | owner (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 200 | PASS |
| PM-288 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/reject` | sr2Ed (Hung->Lan) | editor (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/reject` | HTTP 200 | PASS |
| PM-289 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | outsider | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 404 NOT_FOUND | PASS |
| PM-290 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | viewer (payer, not receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 403 FORBIDDEN | PASS |
| PM-291 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh, Lan not receiver) | editor (non-receiver) | 403 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 403 FORBIDDEN | PASS |
| PM-292 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | Cross-group | owner (G2) | 404 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 404 NOT_FOUND | PASS |
| PM-293 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3 (Hung->Minh) | owner (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 200 | PASS |
| PM-294 | Phase 2A | `POST /api/v1/groups/:groupId/settlement-requests/:id/confirm` | sr3Ed (Hung->Lan) | editor (receiver) | 200 | `POST /api/v1/groups/<uuid>/settlement-requests/<uuid>/confirm` | HTTP 200 | PASS |
| PM-295 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | outsider | 404 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 404 NOT_FOUND | PASS |
| PM-296 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | viewer | 403 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 403 FORBIDDEN | PASS |
| PM-297 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | owner | 201 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 201 | PASS |
| PM-298 | Phase 3A | `POST /api/v1/groups/:groupId/attachments` | PNG upload | editor | 201 | `POST /api/v1/groups/<uuid>/attachments` | HTTP 201 | PASS |
| PM-299 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | owner | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-300 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | editor | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-301 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | viewer | 200 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 200 | PASS |
| PM-302 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Uploaded PNG | outsider | 404 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 404 NOT_FOUND | PASS |
| PM-303 | Phase 3A | `GET /api/v1/groups/:groupId/attachments/:id/content` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/attachments/<uuid>/content` | HTTP 404 NOT_FOUND | PASS |
| PM-304 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | outsider | 404 | `POST /api/v1/groups/<uuid>/receipt-scans body={"attachmentId":"<uuid>"}` | HTTP 404 NOT_FOUND | PASS |
| PM-305 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | viewer | 403 | `POST /api/v1/groups/<uuid>/receipt-scans body={"attachmentId":"<uuid>"}` | HTTP 403 FORBIDDEN | PASS |
| PM-306 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Valid attachmentId | owner | 201 | `POST /api/v1/groups/<uuid>/receipt-scans body={"attachmentId":"<uuid>"}` | HTTP 201 | PASS |
| PM-307 | Phase 3B | `POST /api/v1/groups/:groupId/receipt-scans` | Fresh attachmentId | editor | 201 | `POST /api/v1/groups/<uuid>/receipt-scans body={"attachmentId":"<uuid>"}` | HTTP 201 | PASS |
| PM-308 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | owner | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-309 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | editor | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-310 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | viewer | 200 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 200 | PASS |
| PM-311 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Created scan | outsider | 404 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-312 | Phase 3B | `GET /api/v1/groups/:groupId/receipt-scans/:id` | Cross-group resource ID | owner (G2) | 404 | `GET /api/v1/groups/<uuid>/receipt-scans/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-313 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | outsider | 404 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-314 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | viewer | 403 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-315 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-316 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Unused PNG | editor | 204 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 204 | PASS |
| PM-317 | Phase 3A | `DELETE /api/v1/groups/:groupId/attachments/:id` | Fresh unused PNG | owner | 204 | `DELETE /api/v1/groups/<uuid>/attachments/<uuid>` | HTTP 204 | PASS |
| PM-318 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | owner | 200 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 200 | PASS |
| PM-319 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | editor | 403 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 403 FORBIDDEN | PASS |
| PM-320 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | viewer | 403 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 403 FORBIDDEN | PASS |
| PM-321 | Phase 4C | `GET /api/v1/groups/:groupId/chat-links` | G1 | outsider | 404 | `GET /api/v1/groups/<uuid>/chat-links` | HTTP 404 NOT_FOUND | PASS |
| PM-322 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | owner | 200 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 200 | PASS |
| PM-323 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | editor | 403 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 403 FORBIDDEN | PASS |
| PM-324 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | viewer | 403 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 403 FORBIDDEN | PASS |
| PM-325 | Phase 4C | `POST /api/v1/groups/:groupId/chat-links/code` | G1 | outsider | 404 | `POST /api/v1/groups/<uuid>/chat-links/code` | HTTP 404 NOT_FOUND | PASS |
| PM-326 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | outsider | 404 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-327 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | viewer | 403 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-328 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | editor | 403 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-329 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Cross-group | owner (G2) | 404 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-330 | Phase 4C | `DELETE /api/v1/groups/:groupId/chat-links/:chatLinkId` | Linked chat | owner | 204 | `DELETE /api/v1/groups/<uuid>/chat-links/<uuid>` | HTTP 204 | PASS |
| PM-331 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | owner | 200 | `PATCH /api/v1/groups/<uuid>/users/<uuid> body={"role":"viewer"}` | HTTP 200 | PASS |
| PM-332 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | editor | 403 | `PATCH /api/v1/groups/<uuid>/users/<uuid> body={"role":"viewer"}` | HTTP 403 FORBIDDEN | PASS |
| PM-333 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | viewer | 403 | `PATCH /api/v1/groups/<uuid>/users/<uuid> body={"role":"viewer"}` | HTTP 403 FORBIDDEN | PASS |
| PM-334 | Phase 1B | `PATCH /api/v1/groups/:groupId/users/:userId` | Change Hung role | outsider | 404 | `PATCH /api/v1/groups/<uuid>/users/<uuid> body={"role":"viewer"}` | HTTP 404 NOT_FOUND | PASS |
| PM-335 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung | outsider | 404 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 404 NOT_FOUND | PASS |
| PM-336 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Lan as viewer | viewer | 403 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-337 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung as editor | editor | 403 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 403 FORBIDDEN | PASS |
| PM-338 | Phase 1B | `DELETE /api/v1/groups/:groupId/users/:userId` | Remove Hung as owner | owner | 204 | `DELETE /api/v1/groups/<uuid>/users/<uuid>` | HTTP 204 | PASS |
| PM-339 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Unauth | unauthenticated | 401 | `POST /api/v1/groups/<uuid>/leave` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-340 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/leave` | HTTP 404 NOT_FOUND | PASS |
| PM-341 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Owner cannot leave without transferring | owner | 422 (OWNER_CANNOT_LEAVE) | `POST /api/v1/groups/<uuid>/leave` | HTTP 422 OWNER_REQUIRED | PASS |
| PM-342 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Viewer leaves | viewer | 204 (post-leave GET 404) | `POST /api/v1/groups/<uuid>/leave` | HTTP 204 | PASS |
| PM-343 | Phase 1B | `POST /api/v1/groups/:groupId/leave` | Editor leaves | editor | 204 (post-leave GET 404) | `POST /api/v1/groups/<uuid>/leave` | HTTP 204 | PASS |
| PM-344 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Outsider | outsider | 404 | `POST /api/v1/groups/<uuid>/transfer-ownership body={"userId":"<uuid>"}` | HTTP 404 NOT_FOUND | PASS |
| PM-345 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Viewer on g1 | viewer | 403 | `POST /api/v1/groups/<uuid>/transfer-ownership body={"userId":"<uuid>"}` | HTTP 403 FORBIDDEN | PASS |
| PM-346 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Editor | editor | 403 | `POST /api/v1/groups/<uuid>/transfer-ownership body={"userId":"<uuid>"}` | HTTP 403 FORBIDDEN | PASS |
| PM-347 | Phase 1B | `POST /api/v1/groups/:groupId/transfer-ownership` | Owner -> Lan | owner | 200 | `POST /api/v1/groups/<uuid>/transfer-ownership body={"userId":"<uuid>"}` | HTTP 200 | PASS |
| PM-348 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gDest | outsider | 404 | `DELETE /api/v1/groups/<uuid> body={"name":"PM Destructive"}` | HTTP 404 NOT_FOUND | PASS |
| PM-349 | Phase 1B | `DELETE /api/v1/groups/:groupId` | g1 as viewer | viewer | 403 | `DELETE /api/v1/groups/<uuid> body={"name":"PM Main Group"}` | HTTP 403 FORBIDDEN | PASS |
| PM-350 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gOwn (Minh now editor) | editor | 403 | `DELETE /api/v1/groups/<uuid> body={"name":"PM Transfer"}` | HTTP 403 FORBIDDEN | PASS |
| PM-351 | Phase 1B | `DELETE /api/v1/groups/:groupId` | gDest | owner | 204 | `DELETE /api/v1/groups/<uuid> body={"name":"PM Destructive"}` | HTTP 204 | PASS |
| PM-352 | Phase 1A | `DELETE /api/v1/me` | Unauth | unauthenticated | 401 | `DELETE /api/v1/me body={"email":"unverified-c6e998ff@dev.songphang.local"}` | HTTP 401 UNAUTHENTICATED | PASS |
| PM-353 | Phase 1A | `DELETE /api/v1/me` | Fresh registered user | authenticated | 204 | `DELETE /api/v1/me body={"email":"unverified-c6e998ff@dev.songphang.local"}` | HTTP 204 | PASS |

## 4. Complete 4D.1 Money Matrix (31 Cases, Pre-Freeze Verified)

### Pre-Derived Expected Fixtures

- **M1 (Person-paid, threshold `1,000,000`, budget `1,000,000`):** Baseline `M1_BaseFood` (`300,000`, Minh pays, equal 3 -> `100k` each, `2026-11-10`) + `M1_BaseTrans` (`120,000`, Lan pays, equal Lan/Hùng -> `60k` each, `2026-11-12`). Baseline/Pending/Rejected expected balances: `Minh +200,000`, `Lan -40,000`, `Hùng -160,000` (sum `0`); `minimizeDebts=true`: `Hùng->Minh 160k`, `Lan->Minh 40k`; `minimizeDebts=false`: `Hùng->Lan 60k`, `Hùng->Minh 100k`, `Lan->Minh 100k`; stats total `420,000` (`food 300k`, `transport 120k`); CSV `2` rows. Threshold expense `M1_LargeHotel` (`1,200,000`, `lodging`, `2026-11-15`, Lan pays, equal 3 -> `400k` each): when Approved, expected balances `Minh -200,000`, `Lan +760,000`, `Hùng -560,000` (sum `0`); `minimizeDebts=true`: `Hùng->Lan 560k`, `Minh->Lan 200k`; `minimizeDebts=false`: `Hùng->Lan 460k`, `Hùng->Minh 100k`, `Minh->Lan 300k`; stats total `1,620,000` (`lodging 1.2M`, `2026-11-15` bucket `1.2M`); budget `over` (`1,620,000`); CSV `3` rows; reminder `Minh->Lan` transitions `400` -> `200`.
- **M2 (Fund-paid, threshold `1,000,000`):** Fund `Quỹ M2` with contributions `Minh 1,500,000` + `Lan 500,000` (`approval=none` even above threshold) + `income 1,200,000` (`approval=none`). Fund-paid expense `M2_FundDinner` (`1,200,000`): Pending/Rejected keep `fund.cash = 2,000,000` and `/sodu` prints `Quỹ còn 2.000.000 đ`; Approved reduces `fund.cash` to `800,000` and `/sodu` prints `Quỹ còn 800.000 đ`; previewing `2,500,000` fund expense gives `[]` for Lan (pending) vs `FUND_OVERDRAWN` for Minh (owner).
- **M3 (Items-split & Fake-receipt, threshold `1,000,000`):** `items` expense `1,100,000` -> pending (`spent=0`) -> approved (`spent=1,100,000`). Fake receipt scan (`done`) + expense `1,050,000` with `attachmentIds` -> pending (`spent=1,100,000`) -> approved (`spent=2,150,000`).

| Case ID | Family | Source | Fixture | Actor | Action / Invocation | Expected | Actual (Pre-Freeze) | Status |
|---|---|---|---|---|---|---|---|---|
| M4D-001 | DebtModes | 4D.1 | M1 pending minimizeDebts=true | owner | `PATCH minimizeDebts=true -> GET /balances` | bal={"Minh":200000,"Lan":-40000,"Hung":-160000} transfers=[{"from":"Hùng","to":"Minh","amount":160000},{"from":"Lan","to":"Minh","amount":40000}] | min=true bal={"Minh":200000,"Lan":-40000,"Hung":-160000} sum=0 transfers=[{"from":"Hùng","to":"Minh","amount":160000},{"from":"Lan","to":"Minh","amount":40000}] | PASS |
| M4D-002 | TelegramSodu | 4D.1/4C | M1 pending /sodu (minimizeDebts=true) | paired Lan | `POST /bots/telegram/webhook /sodu` | Minh +200k, Hung->Minh 160k, Lan->Minh 40k | Sổ "4D1 M1 Matrix" | Minh: được nhận 200.000 đ | Lan: cần trả 40.000 đ | Hùng: cần trả 160.000 đ | Hùng → Minh: 160.000 đ | Lan → Minh: 40.000 đ | PASS |
| M4D-003 | DebtModes | 4D.1 | M1 pending minimizeDebts=false | owner | `PATCH minimizeDebts=false -> GET /balances` | minimized=false transfers=[{"from":"Hùng","to":"Lan","amount":60000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Lan","to":"Minh","amount":100000}] | min=false transfers=[{"from":"Hùng","to":"Lan","amount":60000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Lan","to":"Minh","amount":100000}] | PASS |
| M4D-004 | TelegramSodu | 4D.1/4C | M1 pending /sodu (minimizeDebts=false) | paired Lan | `POST /bots/telegram/webhook /sodu` | Lan->Minh 100k, Hung->Minh 100k, Hung->Lan 60k | Sổ "4D1 M1 Matrix" | Minh: được nhận 200.000 đ | Lan: cần trả 40.000 đ | Hùng: cần trả 160.000 đ | Lan → Minh: 100.000 đ | Hùng → Minh: 100.000 đ | Hùng → Lan: 60.000 đ | PASS |
| M4D-005 | Stats | 4D.1 | M1 pending stats breakdown | owner | `GET /stats` | total=420000, lodging=absent, Minh=100000 | total=420000, byCat={"food":300000,"transport":120000}, byMem={"Minh":100000,"Lan":160000,"Hùng":160000} | PASS |
| M4D-006 | Budget | 4D.1 | M1 pending budget spent/state | owner | `GET /budget` | spent=420000, state=ok | spent=420000, state=ok | PASS |
| M4D-007 | CSV | 4D.1 | M1 pending parsed CSV rows | owner | `GET /export.csv` | rowCount=2, M1_LargeHotel=false | rowCount=2, M1_LargeHotel=false | PASS |
| M4D-008 | Reminders | 4D.1 | M1 pending reminder Minh->Lan | editor (Lan) | `POST /reminders {from:Minh,to:Lan}` | HTTP 400 | HTTP 400 | PASS |
| M4D-009 | DebtModes | 4D.1 | M1 rejected minimizeDebts=true | owner | `PATCH minimizeDebts=true -> GET /balances` | bal={"Minh":200000,"Lan":-40000,"Hung":-160000} transfers=[{"from":"Hùng","to":"Minh","amount":160000},{"from":"Lan","to":"Minh","amount":40000}] | min=true bal={"Minh":200000,"Lan":-40000,"Hung":-160000} sum=0 transfers=[{"from":"Hùng","to":"Minh","amount":160000},{"from":"Lan","to":"Minh","amount":40000}] | PASS |
| M4D-010 | TelegramSodu | 4D.1/4C | M1 rejected /sodu (minimizeDebts=true) | paired Lan | `POST /bots/telegram/webhook /sodu` | Minh +200k, Hung->Minh 160k, Lan->Minh 40k | Sổ "4D1 M1 Matrix" | Minh: được nhận 200.000 đ | Lan: cần trả 40.000 đ | Hùng: cần trả 160.000 đ | Hùng → Minh: 160.000 đ | Lan → Minh: 40.000 đ | PASS |
| M4D-011 | DebtModes | 4D.1 | M1 rejected minimizeDebts=false | owner | `PATCH minimizeDebts=false -> GET /balances` | minimized=false transfers=[{"from":"Hùng","to":"Lan","amount":60000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Lan","to":"Minh","amount":100000}] | min=false transfers=[{"from":"Hùng","to":"Lan","amount":60000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Lan","to":"Minh","amount":100000}] | PASS |
| M4D-012 | TelegramSodu | 4D.1/4C | M1 rejected /sodu (minimizeDebts=false) | paired Lan | `POST /bots/telegram/webhook /sodu` | Lan->Minh 100k, Hung->Minh 100k, Hung->Lan 60k | Sổ "4D1 M1 Matrix" | Minh: được nhận 200.000 đ | Lan: cần trả 40.000 đ | Hùng: cần trả 160.000 đ | Lan → Minh: 100.000 đ | Hùng → Minh: 100.000 đ | Hùng → Lan: 60.000 đ | PASS |
| M4D-013 | Stats | 4D.1 | M1 rejected stats breakdown | owner | `GET /stats` | total=420000, lodging=absent, Minh=100000 | total=420000, byCat={"food":300000,"transport":120000}, byMem={"Minh":100000,"Lan":160000,"Hùng":160000} | PASS |
| M4D-014 | Budget | 4D.1 | M1 rejected budget spent/state | owner | `GET /budget` | spent=420000, state=ok | spent=420000, state=ok | PASS |
| M4D-015 | CSV | 4D.1 | M1 rejected parsed CSV rows | owner | `GET /export.csv` | rowCount=2, M1_LargeHotel=false | rowCount=2, M1_LargeHotel=false | PASS |
| M4D-016 | Reminders | 4D.1 | M1 rejected reminder Minh->Lan | editor (Lan) | `POST /reminders {from:Minh,to:Lan}` | HTTP 400 | HTTP 400 | PASS |
| M4D-017 | DebtModes | 4D.1 | M1 approved minimizeDebts=true | owner | `PATCH minimizeDebts=true -> GET /balances` | bal={"Minh":-200000,"Lan":760000,"Hung":-560000} transfers=[{"from":"Hùng","to":"Lan","amount":560000},{"from":"Minh","to":"Lan","amount":200000}] | min=true bal={"Minh":-200000,"Lan":760000,"Hung":-560000} sum=0 transfers=[{"from":"Hùng","to":"Lan","amount":560000},{"from":"Minh","to":"Lan","amount":200000}] | PASS |
| M4D-018 | TelegramSodu | 4D.1/4C | M1 approved /sodu (minimizeDebts=true) | paired Lan | `POST /bots/telegram/webhook /sodu` | Lan +760k, Hung->Lan 560k, Minh->Lan 200k | Sổ "4D1 M1 Matrix" | Minh: cần trả 200.000 đ | Lan: được nhận 760.000 đ | Hùng: cần trả 560.000 đ | Hùng → Lan: 560.000 đ | Minh → Lan: 200.000 đ | PASS |
| M4D-019 | DebtModes | 4D.1 | M1 approved minimizeDebts=false | owner | `PATCH minimizeDebts=false -> GET /balances` | minimized=false transfers=[{"from":"Hùng","to":"Lan","amount":460000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Minh","to":"Lan","amount":300000}] | min=false transfers=[{"from":"Hùng","to":"Lan","amount":460000},{"from":"Hùng","to":"Minh","amount":100000},{"from":"Minh","to":"Lan","amount":300000}] | PASS |
| M4D-020 | TelegramSodu | 4D.1/4C | M1 approved /sodu (minimizeDebts=false) | paired Lan | `POST /bots/telegram/webhook /sodu` | Minh->Lan 300k, Hung->Lan 460k, Hung->Minh 100k | Sổ "4D1 M1 Matrix" | Minh: cần trả 200.000 đ | Lan: được nhận 760.000 đ | Hùng: cần trả 560.000 đ | Minh → Lan: 300.000 đ | Hùng → Minh: 100.000 đ | Hùng → Lan: 460.000 đ | PASS |
| M4D-021 | Stats | 4D.1 | M1 approved stats breakdown | owner | `GET /stats` | total=1620000, lodging=1200000, Minh=500000 | total=1620000, byCat={"lodging":1200000,"food":300000,"transport":120000}, byMem={"Minh":500000,"Lan":560000,"Hùng":560000} | PASS |
| M4D-022 | Budget | 4D.1 | M1 approved budget spent/state | owner | `GET /budget` | spent=1620000, state=over | spent=1620000, state=over | PASS |
| M4D-023 | CSV | 4D.1 | M1 approved parsed CSV rows | owner | `GET /export.csv` | rowCount=3, M1_LargeHotel=true | rowCount=3, M1_LargeHotel=true | PASS |
| M4D-024 | Reminders | 4D.1 | M1 approved reminder Minh->Lan | editor (Lan) | `POST /reminders {from:Minh,to:Lan}` | HTTP 200 | HTTP 200 | PASS |
| M4D-025 | Fund | 4D.1 | Transfer >=1M & Income >=1M never pending | editor (Lan) | `POST transfer 1.5M + POST income 1.2M` | both approval.status=none | transfer=none, income=none | PASS |
| M4D-026 | Warnings | 4D.1/R6 | Fund-overdraw warning parity (Lan pending=[] vs Minh owner=FUND_OVERDRAWN) | editor & owner | `POST /transactions/preview (fund 2.5M > cash 2M)` | Lan=[], Minh includes FUND_OVERDRAWN | Lan=[], Minh=["FUND_OVERDRAWN"] | PASS |
| M4D-027 | Fund | 4D.1 | M2 fund-paid expense pending -> cash & /sodu | owner & paired Lan | `GET /balances + /sodu` | cash=2000000, MinhContrib=1500000, LanContrib=500000, /sodu has "Quỹ còn 2.000.000 đ" | cash=2000000, MinhContrib=1500000, LanContrib=500000, soduHasCash=true | PASS |
| M4D-028 | Fund | 4D.1 | M2 fund-paid expense rejected -> cash & /sodu | owner & paired Lan | `GET /balances + /sodu` | cash=2000000, MinhContrib=1500000, LanContrib=500000, /sodu has "Quỹ còn 2.000.000 đ" | cash=2000000, MinhContrib=1500000, LanContrib=500000, soduHasCash=true | PASS |
| M4D-029 | Fund | 4D.1 | M2 fund-paid expense approved -> cash & /sodu | owner & paired Lan | `GET /balances + /sodu` | cash=800000, MinhContrib=1500000, LanContrib=500000, /sodu has "Quỹ còn 800.000 đ" | cash=800000, MinhContrib=1500000, LanContrib=500000, soduHasCash=true | PASS |
| M4D-030 | ItemsReceipt | 4D.1/Spec 14.3 | Threshold-sensitive items-split save (pending->approved) | editor & owner | `POST /transactions split.method=items 1.1M -> approve` | pending spent=0, approved spent=1100000 | status=pending, pendSpent=0, appSpent=1100000 | PASS |
| M4D-031 | ItemsReceipt | 4D.1/Spec 14.3 | Fake receipt scan + threshold-sensitive save (pending->approved) | editor & owner | `POST /receipt-scans -> worker -> POST /transactions attachmentIds 1.05M -> approve` | scan=done, pending spent=1100000, approved spent=2150000 | scan=done, status=pending, pendSpent=1100000, appSpent=2150000 | PASS |

## 5. Required Post-Freeze Final-SHA Browser Gate Matrix (`BR-01`–`BR-16`)

Every row below is executed strictly AFTER freezing the final HEAD on fresh built servers (`API 4070`, `Web 3070`, `songphang_phase4_r11_20261119`), with full results and screenshots archived in `final-replay-<FULL_SHA>/08_browser.json`.

| Case ID | Screen / Area | Actors | Required Verification |
|---|---|---|---|
| `BR-01` | S20 live comment & SSE | Minh (owner), Hùng (viewer) | Viewer posts live comment + `<script>alert(1)</script>`; owner receives live via SSE without reload; 0 `<script>` nodes in `<main>`. |
| `BR-02` | S20 soft-deleted comment & restore | Minh (owner), Hùng (viewer) | Viewer comments on soft-deleted tx; owner receives live via SSE; deleted banner stays (not auto-restored); owner restores tx -> comments preserved. |
| `BR-03` | S20 dispute open/resolve & role check | Minh (owner), Hùng (viewer), Lan (editor) | Viewer opens dispute -> coral `DisputeBlock` live in owner view; editor cannot resolve (no resolve button / 403); opener/owner resolves -> `đang hỏi lại` clears live. |
| `BR-04` | S20 pending approval lifecycle | Minh (owner), Lan (editor) | Pending 1.2M expense shows `chờ duyệt` + `Duyệt`/`Không duyệt` (owner only); approve updates live balances; edit back to pending; reject with note shows note & `không được duyệt`. |
| `BR-05` | S19 & Bell live manual + auto reminder | Minh (owner), Hùng (viewer) | Manual `Nhắc` from S5 and automatic `auto-reminders` worker run both increment Hùng's open S4 bell count without reload/focus; S19 shows exact Spec 7.2 text, tap marks read & navigates, `Đánh dấu đã đọc` clears all. |
| `BR-06` | S5 reminders & button visibility | Minh (owner), Lan (editor), Hùng (viewer) | Individual `Nhắc`, immediate repeat too-soon time message, `Nhắc cả nhóm một lần` count, `Nhắc` hidden for unlinked debtor & non-receiver viewer, balances unchanged. |
| `BR-07` | S11 group settings & owner-only | Minh (owner), Lan (editor) | Reminder interval off/3/7/14 persisted across reload; approval threshold enable/change/disable + invalid input; Telegram group link generate/copy/unlink; non-owner blocked. |
| `BR-08` | S13 account mail & Telegram controls | Hùng / Minh | Immediate & digest mail switches persist across reload; Telegram identity card shows linked state & unlink removes it. |
| `BR-09` | `/link/telegram` R1 pairing & legacy refusal | Signed-out + Minh | Legacy `?code=LEGACY` shows `Link này không còn dùng được.`; signed-out `/link/telegram` redirects to `/login?next=%2Flink%2Ftelegram`; web start -> private console `/start` -> exact-sender Telegram confirm (identity still 0) -> final web confirm activates & unlink works. |
| `BR-10` | Unsubscribe signed-out GET valid & invalid | Signed-out | Valid token renders `Bạn sẽ không nhận thư thông báo nữa.` and disables both switches; invalid token renders `Link này không còn dùng được.`. |
| `BR-11` | Keyboard navigation & Escape focus return | Minh | Tab/Shift+Tab, Enter/Space across S20/S19/S11/pairing; Escape closes modal dialog & returns focus to trigger button; visible focus outline recorded. |
| `BR-12` | Accessible names & >=44px tap targets | Minh, Hùng | Bell `aria-label` matches `{count} thông báo chưa đọc`; bell and primary action buttons measure >=44px. |
| `BR-13` | Rendered WCAG AA contrast ratios | Minh | Measured rendered contrast ratios on `DisputeBlock` (coral), `chờ duyệt` (pending), and `không được duyệt` (rejected) all >= 4.5:1. |
| `BR-14` | Mobile 375px overflow & zero console errors | Minh, Hùng | `scrollWidth <= clientWidth` at `375x812` across S20, S19, S5, S11 (Phase 4 cards), S13, `/link/telegram`; 0 console errors. |
| `BR-15` | Offline write behavior & recovery | Minh | Browser offline mode on S13 mail toggle -> request fails & UI reverts/errors cleanly; back online -> toggle succeeds and persists. |
| `BR-16` | Lost access & zero stale private data | Minh (owner), Hùng (removed) | Owner removes Hùng from group -> Hùng's S19/S20 no longer exposes removed group's notifications or content and returns clean not-found/access-lost UI. |
