# Phase 5 — Task 0 and Stage 5A: API for Native Clients

> Follow the workflow in [00-overview.md](00-overview.md). API paths below are relative to `/api/v1`.

### Task 0: Pin the baseline and prepare acceptance

**Files:** Create or populate `docs/superpowers/runs/phase-5/{progress,decisions,manual-checks,parity-matrix}.md`. Read `apps/ios/AGENTS.md` and the [5U handoff](../../runs/ios-ui/progress.md).

- [ ] Record the starting `main` SHA, 5U web reference `bb1e0432fef6f1ceb4cf2ee960948129210626b2`, and Phase 1–4 coverage. Diff that 5U reference to the baseline across `apps/web/src/{app,components,messages}`, `apps/api/src/routes` and `packages/contract`. Map existing Swift models and protocols to the registered routes. Record concrete differences in `decisions.md`. Keep the actual baseline's approved behavior.
- [ ] Build and lint iOS Debug, run the string report, and record the existing Release live-composition guard. Use `xcodebuild -version` and `xcrun simctl list runtimes` to identify local prerequisites. Record Be Vietnam Pro font availability and the known 5U system font fallback. If compatible local files are missing, flag the need for owner-provided assets or approved substitution before final review, and continue the independent implementation.
- [ ] Adapt the [Phase 4 isolated startup recipe](../../runs/phase-4/manual-checks.md). Use a new database and upload directory per replay, with default Phase 5 API/web ports `4000` and `3000` when free. Set explicit consistent web and API origins if ports change, including iOS Debug configuration. Launch API and worker with `pnpm --filter @songphang/api exec tsx src/server.ts` and `pnpm --filter @songphang/worker exec tsx src/main.ts` from a clean environment with explicit local configuration, bypassing the ordinary `.env`-loading scripts. Use console mail, `AI_PROVIDER=fake` and console Telegram for baseline replays. Establish two verified password accounts for 5B by local registration and console verification. The existing development-login seed serves earlier scripts and does not create password identities.
- [ ] Run the baseline gate from the overview. Take registered paths and methods from the live route set as well as the OpenAPI document, including raw handlers. Start from the [Phase 4 gate inventory](../../runs/phase-4/gate-inventory-round-2.md) and [R11 evidence](../../runs/phase-4/review-r11-ab-final.md) for provenance, then reconcile every missing scenario with the Phase 1–4 acceptance rows. Document which scripts/actions were replayed and any baseline failure. Build an inventory with stable row IDs, web entry point, routes, roles, capability states, expected UI/API result, native destination, owning task, local evidence and external follow-up. Assign each user-facing baseline journey and embedded action to 5B or 5D. Include mail and Telegram actions exercised through their shared endpoints/worker.
- [ ] Commit the run baseline as `docs(run): re-baseline phase 5`.

### Task 5A.1: Deterministic OpenAPI and minimum-version metadata

**Files:** `apps/api/src/app.ts`, `apps/api/src/config.ts`, `apps/api/src/routes/features.ts`, new `apps/api/src/openapi/` for registry snapshot CLI and diff, `apps/api/package.json`, `packages/contract/src/features.ts`, generated `packages/contract/openapi.json`, root `package.json`, `.env.example`, `README.md`.

**Interfaces:**

- `pnpm contract:write` and `pnpm contract:check` invoke the snapshot CLI in the API workspace, which already depends on the contract package. The CLI builds from the same registered OpenAPI routes as `app.doc31`, with explicit offline configuration enabling documented provider routes and excluding dev-only routes. Snapshot generation opens no database, worker, HTTP server or provider connection. Normalize object key order without reordering semantic arrays. Audit native operations that were previously untyped, including CSV, multipart, attachment bodies, SSE and provider redirects. SSE and browser redirects may have dedicated clients with their routes still documented.
- `contract:check` fails on drift and reports changed paths. Additive changes allowed by spec §4.1 can be regenerated. Removed or changed semantics that break existing clients are findings and need advisor resolution. During review, compare the resulting snapshot against the previous accepted snapshot as well as source, so regenerating the file cannot hide a breaking edit.
- `GET /features` keeps `appleSignIn`, `push` and the other existing flags. Add `minAppVersion: { ios: string, android: string }` from Zod-validated `MIN_APP_VERSION_IOS` and `MIN_APP_VERSION_ANDROID`, default `0.0.0`. Publish the three-component version format and document fallback handling for extensible enums.

- [ ] Implement and regenerate. Confirm repeated generation is byte-identical, dev-only paths are absent and supported documented routes appear even when their runtime provider is off.
- [ ] In a scratch copy, exercise hand-edited snapshot drift, a new optional field and enum member, a removed field and an optional field becoming required. Record classification and exit status. Exercise flags with providers off, defaults and an invalid minimum version startup refusal.
- [ ] Run the task gate and commit `feat(api): publish deterministic v1 contract and version metadata`.

### Task 5A.2: Native password sessions and session revocation

**Files:** `apps/api/src/routes/{account-auth,auth,me}.ts`, new `apps/api/src/routes/mobile-auth.ts`, `apps/api/src/{app.ts,auth/sessions.ts,auth/middleware.ts,services/accounts.ts}`, `packages/db/src/{schema,sessions}.ts` and next migration, `packages/contract/src/auth.ts`, web account screen and session client, `apps/web/src/messages/vi.ts`, regenerated snapshot.

**Interfaces:**

- `POST /auth/token` takes `{ email, password, client: "ios" | "android", deviceName }`; device name 1–60 characters. Return 200 `{ token, user }` with no cookie and `Cache-Control: no-store`. Reuse web credential service and its named IP/email limiters and unknown-email work. Backfill existing sessions to `client: "web"` and nullable device name. Session DTOs expose `id`, `client`, `deviceName`, `createdAt`, `lastSeenAt` and `current`; keep existing timestamp semantics and exclude tokens and hashes.
- `GET /me/sessions` lists caller sessions. `DELETE /me/sessions/{id}` revokes caller's session, returns 204 and uses existing session-revocation event behavior for an open SSE stream. A foreign or missing session ID returns 404. Current cookie revocation expires the cookie. Keep `POST /auth/logout` working for both credential transports. Expose the session list and `Đăng xuất` controls on web so 5B can revoke its iOS session.
- Bearer-only writes require valid Bearer auth and can omit Origin. Requests with a cookie, including mixed Cookie/Bearer, take the existing web same-origin path. Keep the baseline refusal status (currently 400 `VALIDATION_FAILED` for foreign Origin). Keep Zod validation at boundaries and reject query-string session credentials.

- [ ] Implement migration and restore the previous worktree database from a disposable fixture if needed to exercise pre-existing web sessions. Check that migrated web sessions keep working. Add the web session actions and regenerate OpenAPI.
- [ ] Compare identical 401 bodies for wrong password and unknown email in both transports. Alternate login endpoints to show the shared email budget (sixth attempt in 15 minutes returns 429) and prove neither exposes credentials. Compare Bearer-only, cookie and mixed writes with local, absent and foreign Origin according to each credential policy. Exercise cross-account revocation, current-session revocation, SSE closure, continued access from a different session and denial with the revoked token.
- [ ] Run the task gate and commit `feat(auth): add native password sessions and session management`.

### Task 5A.3: Stage 5A gate

**Files:** Run records and endpoint/credential matrix.

- [ ] Run the full stage gate. Replay the current permission matrix with existing web cookie callers and eligible Bearer callers. Cover signed-out requests and outsider/viewer/editor/owner, and any ownership, verification, idempotency or flag boundaries on each applicable route. Record route and caller coverage with the new session routes and unchanged cookie paths included.
- [ ] Record that 5B has a reachable local v1 API with native email sign-in, session revocation, stable snapshot and known baseline gaps. Record the iOS Debug build/lint separately from the still-expected pre-integration Release guard. Commit `docs(run): record Phase 5A API gate`.
