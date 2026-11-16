# Phase 1 run — decisions

Written by the implementation agent. One entry for every decision the spec and the plan did not make. The advisor reads this file first during review; the project owner confirms or changes each entry afterwards.

Entry format:

```
## D<number> — <short title> (task <id>)
Problem: …
Options: …
Choice: …
Reason: …
```

A new library adds: License, Maintenance, Added size.


## D1 — Safe accumulated money (task 1A.1)
Problem: Safe individual inputs can produce unsafe totals when accumulated.
Options: Accumulate as numbers; accumulate as BigInt and check the final number range.
Choice: BigInt for sums and pair netting, with RangeError for unsafe outputs; reject empty IDs as invalid identifiers.
Reason: Preserve exact integer money without silently rounding an accumulated result.

## D2 — Offline workspace installation (task 1A.1)
Problem: The task requests pnpm install while external services are forbidden.
Options: Contact the package registry; use the local package store offline.
Choice: Run pnpm install --offline and do not run the network-backed pnpm audit.
Reason: This package adds no dependencies; the run must not contact external services.

## D3 — Retain ledger authorship when accounts are deleted (task 1A.2)
Problem: Nullable created_by/updated_by foreign keys must allow account deletion while preserving ledger history.
Options: Default restrictive foreign keys; ON DELETE SET NULL.
Choice: SET NULL for group and transaction authors.
Reason: The approved account-deletion requirement retains members and transactions.

## D4 — Link existing dependency-free workspace without registry access (task 1A.3)
Problem: pnpm exec previously auto-installed and installation can trigger registry metadata lookups.
Options: Run package-manager install; add the workspace dependency, its deterministic lockfile link and local node_modules symlink directly.
Choice: Add only the local core workspace link manually.
Reason: No external dependency resolution is needed or allowed.

## D5 — Preserve source-extension imports for web contract (task 1A.7)
Problem: Browser compilation cannot resolve the .js exports added to the source-only contract package in earlier API tasks.
Options: Add bundler aliases; follow phase-0 .ts imports in contract.
Choice: Use .ts extensions throughout contract imports/exports, matching existing exports.
Reason: Source-only workspace exports must resolve in both Next.js and Node/tsx without new configuration.

## D6 — Split new-group member rows (task 1A.7)
Problem: The creation page exceeds 150 lines when the ordered member list is inline.
Options: Keep the oversized page; extract the member list beside the existing group components.
Choice: Add NewGroupMembers.tsx in the approved groups directory and keep the page responsible for submission.
Reason: Separate member editing from screen loading and submission without a new abstraction layer.

## D7 — Close icon in the expense header (task 1A.9)
Problem: The form requires a close icon while ScreenHeader initially always renders a back icon.
Options: Duplicate the header; add an optional backIcon prop defaulting to back.
Choice: Extend ScreenHeader with backIcon and pass close only for the form.
Reason: Preserve the shared layout and the plan's exact form header behavior.

## D8 — Separate expense form state from rendering (task 1A.9)
Problem: The expense component exceeds the 150-line component limit after formatting.
Options: Keep it oversized; move its local state/submission/preview preparation to a same-directory hook.
Choice: use-expense-form.ts beside ExpenseForm.tsx.
Reason: The component renders controls, while one cohesive controller owns the local draft; no extra package or directory.

## D9 — Identify claimed members during 1A (task 1A.11)
Problem: MemberDto has isMe but no claimed flag until account-sharing work.
Options: Add a new interim endpoint/field; use the fact that only the creator can be linked in 1A.
Choice: Hide deactivate/delete for isMe in 1A.
Reason: Exactly matches the reachable phase-1A state without inventing an interface ahead of 1B.

## D10 — Node crypto documentation without external access (task 1B.1)
Problem: The plan asks for Node documentation while external services are forbidden.
Options: Browse nodejs.org; read installed Node API documentation in @types/node/crypto.d.ts.
Choice: Use the installed API documentation and signature, which marks argon2 @since v24.7.0; runtime is v26.12.1.
Reason: Verify exact availability and parameters locally; set the engine minimum to 24.7.0.

## D11 — Bounded PHC parameters and atomic token issue (task 1B.1)
Problem: Malformed hashes must not cause unbounded memory allocation, and concurrent token issues must invalidate each other.
Options: Trust every parsed PHC parameter and issue without locking; validate bounded parameters and serialize per user.
Choice: Verify only canonical base64 and bounded Argon2 parameters; issue tokens in a transaction under a user-row lock. Dummy PHC is generated once at startup from random bytes.
Reason: Preserve constant-work missing-account verification and single-use token semantics without new crypto code.

## D12 — Preserve rate-limit response headers (task 1B.1)
Problem: The real four-call limiter exercise returned 429 but Retry-After was null; the existing handleError created a new Response without middleware headers.
Options: Return errors directly from the limiter; preserve prepared response headers in the shared error handler.
Choice: Copy context.res.headers before setting the standard error headers.
Reason: Keep one error response format and preserve the required Retry-After header without route-specific error handling.

## D13 — Validate email before email-keyed rate limits (task 1B.2)
Problem: Hono OpenAPI route middleware runs before its automatic body validators, while the login limit needs a normalized email.
Options: Trust raw JSON in the limiter; prepare a validated email in authentication middleware first.
Choice: Add account-limits.ts with Zod email preparation and socket-IP lookup; share one limiter instance in AppDeps.
Reason: Never use unvalidated external data or proxy headers as a rate-limit identity.

## D14 — Keep authentication route files small (task 1B.2)
Problem: Adding all new password routes to the existing logout module would exceed the file-size guideline.
Options: Keep one large module; register account-auth.ts from auth.ts.
Choice: Split within the existing routes directory.
Reason: Keep account declarations and logout readable without changing endpoint ownership.

## D15 — Do not log database query parameters (task 1B.2)
Problem: The existing unexpected-error logger prints error.message/stack; Drizzle wraps SQL and parameters there, which could include password hashes. The verification exercise revealed this path with a non-secret Date serialization error.
Options: Log wrapped errors fully; log requestId plus error classification only.
Choice: Keep requestId/name and a fixed generic message; never log wrapped SQL or parameters.
Reason: AGENTS section 9's no-secrets-in-logs rule takes precedence over the lower-priority code-convention suggestion to log unexpected errors fully.

## D16 — Represent deleted transaction authors (task 1B.3)
Problem: Account deletion nulls transaction created_by; a required createdBy object would make historical transaction reads fail schema validation.
Options: Invent an author UUID/name; allow createdBy null.
Choice: Make TransactionDto.createdBy nullable, keeping all transaction/member money data unchanged.
Reason: Represent the actual deleted-account state without retaining an account or inventing an identity.

## D17 — Consistent account/token lock order (task 1B.3)
Problem: Token issue locks user then tokens; reset/verify could lock a token then the user, causing a concurrent deadlock.
Options: Accept transient deadlocks; look up the token owner, lock that user, then perform the single conditional UPDATE.
Choice: consumeToken uses the same account-first lock order in a transaction and still atomically updates only an unused/unexpired token.
Reason: Reset/revocation remains atomic with token consumption and serializes with issue. Future joining/ownership writes must also lock the account before making it own or join a group to serialize with account deletion.

## D18 — Keep recovery routes/services separate (task 1B.3)
Problem: Extending both account modules inline would exceed the size guidelines.
Options: Oversized account modules; sibling password-recovery modules.
Choice: Split within existing routes/services directories and register recovery routes from auth.ts.
Reason: No package or directory change; each module has one coherent responsibility.

## D19 — Google adapter without unavailable arctic (task 1B.4)
Problem: Offline arctic@3.7.0 installation fails ERR_PNPM_NO_OFFLINE_META; cache/runtime/other-project searches found no copy. External services are prohibited.
Options: Fetch the package despite the prohibition; leave Google unbuilt; implement the specified authorization-code protocol with standard Node/Web APIs.
Choice: A small built-in adapter with fixed Google endpoints, standard crypto primitives, PKCE/state cookies and Zod-validated claims; no third-party package added.
Reason: Continue the authorized phase run without remote calls, account creation or custom cryptographic algorithms. This differs materially from the advisor's chosen arctic integration and requires explicit attention in final review; real Google exchange remains unverified.

## D20 — Realtime publication at transaction ownership boundaries
Problem: create services run inside runIdempotent and cannot know when the outer transaction commits.
Options: publish in the service (could announce rolled-back writes); add a generic transaction event framework; add an optional committed callback to the existing wrapper input.
Choice: optional onCommitted callback, invoked only after a newly committed transaction; ordinary services publish after their own transaction resolves.
Reason: fewest concepts, no event on rollback or idempotent replay, while keeping routes thin orchestration.

## D21 — Serialize ownership changes with account deletion
Problem: ownership transfer can race an account deletion and violate the deletion precondition if ownership is granted after the owner count is read.
Options: group-only locking; lock both accounts before the group.
Choice: lock both account rows in sorted UUID order, then lock the group and recheck ownership/target membership.
Reason: matches the established account-first ordering and avoids opposing-transfer deadlocks.

## D22 — Offline QR dependency substitution
Problem: `pnpm --offline --filter @songphang/web add uqr` failed ERR_PNPM_NO_OFFLINE_META; the approved package is unavailable locally.
Options: omit required QR; implement a QR encoder ourselves; use the locally cached qrcode 1.5.4 with its TypeScript declarations.
Choice: qrcode 1.5.4 and @types/qrcode 1.5.6, installed with --offline (downloaded 0).
Reason: QR encoding/error correction cannot be implemented safely in a few dozen lines; a real QR is required. Render the standard library's module matrix with React SVG rather than inserting its serialized markup.
License: MIT. Maintenance: established library, installed stable release; current upstream maintenance/latest version could not be verified without a forbidden external call.
Added size: 29 runtime packages and one declaration package in the offline install; bundle impact will be measured at the stage build. This is a material deviation from the planned uqr dependency for advisor review.

## D23 — Self-host the existing product font for offline builds
Problem: stage 1B build with outbound networking denied failed because next/font/google tried to fetch Be Vietnam Pro from fonts.googleapis.com.
Options: permit external requests (forbidden); fall back to a different font; self-host the exact cached font resources.
Choice: keep all six approved weights and Vietnamese/Latin/Latin-extended subsets as source WOFF2 assets under public/fonts/be-vietnam-pro, with explicit CSS faces and the same fallback metrics. Copy the existing SIL OFL 1.1 license from the local Kệ Hàng font source. No download or new dependency.
Reason: preserves the approved typography while making builds independent of a remote service. The source font bytes are unchanged; generated Next CSS, source maps and build directories are not committed.

## D24 — Single source for the transfer default description
Problem: API transfers default to the Vietnamese product description, while the owner's rule requires all product literals to live only in apps/web/src/messages/vi.ts. Duplicating the literal in the API/contract would violate that rule.
Options: duplicate text; change the default; import the pure message module for this one default.
Choice: the API normalization module imports only the pure vi.ts message object for the approved default. It imports no web framework/runtime code.
Reason: preserves the exact API default and the owner's single-copy rule. This is a narrow dependency-direction exception to the plan that requires advisor review; the owner instruction has higher priority.

## D25 — Exercise weighted hotel input after the split editor exists
Problem: 1C.3 asks for T2's weighted split through the form, but the weighted editor is introduced by the following task 1C.4.
Options: build the editor early; exercise the new two-payer input with equal shares now and replay full T2 in 1C.4.
Choice: exercise two payers now and carry the exact weighted T2 form exercise into 1C.4.
Reason: preserves task order and one commit per task without claiming an unavailable control was exercised.

## D26 — Last editor in conflict responses
Problem: the specified conflict UI needs the last editor's name, but TransactionDto exposes only the creator.
Options: show the unknown-person fallback for every conflict; add the stored updated_by user's public id/name to the DTO.
Choice: add nullable updatedBy, using a second user alias in the existing row query.
Reason: the existing database already stores this field; a constant join supplies accurate attribution without guessing from the creator or adding an endpoint.

## D27 — Delete and restore concurrency versions
Problem: a form opened before a delete/restore cycle must not overwrite that newer state silently.
Options: leave version unchanged on deletion/restoration; increment it on each state change.
Choice: increment version, updatedBy and updatedAt on both operations.
Reason: the same monotonic version protects open editors; no-op edits remain version-neutral. No database schema change.

## D28 — Group cascade order with restricted member references
Problem: deleting a group containing transactions returned 500; a rolled-back direct SQL reproduction showed transaction_payers_member_id_members_id_fk blocking the members cascade.
Options: weaken the restricted member foreign key; delete the group's transactions first inside the same locked transaction.
Choice: explicitly delete group-scoped transactions before the group. Their payer/share rows cascade, then the group's remaining rows cascade.
Reason: preserves every integrity constraint and atomic deletion. Repeated API exercise returned 204, emitted removed and left no dependent rows.

## D29 — Default-weight history wording
Problem: the history sentence table omits the existing member defaultWeight update, although every member change must be recorded and shown.
Options: show an inaccurate rename sentence; describe that field explicitly.
Choice: add `activity.memberWeight` = `“{actor} đổi phần mặc định của {member}”`, with the existing Phần label on the value chip.
Reason: accurately describes the already-supported action without adding a feature. All other history templates match the approved table.

## D30 — Offline controls and integer display animation
Problem: native buttons, shared controls and mutations must agree on offline state; balance animation must not introduce floating-point money arithmetic or a second allocator.
Options: duplicate online checks at every handler and interpolate money in web; share a connection store/control wrappers and call the existing core allocator for display frames.
Choice: OnlineButton/OnlineLink plus the existing Button guard all write controls; the API client rejects offline writes and mutations use networkMode always with retries off, so nothing is queued. Browser online events and a five-second local health probe recover the shared state. Web links to the existing core workspace package for integer-only display interpolation through allocateByWeights; official targets still come only from API responses.
Reason: one connectivity state, no persisted data, no external service/library. Offline install reused the workspace package with downloaded 0/added 0; lockfile contains only its local link.

## D31 — Final non-functional findings
Problem: the 52px featured-group balance overflowed at 360px with 37.575.000; custom controls lacked the required uniform focus outline; the textarea's visual marks were hidden from assistive technology. Oversized descriptions and an unsafe-integer “chia” count could also produce an unsaveable ok draft or an invalid response.
Options: reduce type sizes/relax boundaries; preserve sizes and refuse unsupported input while repairing wrapping/focus/accessible descriptions.
Choice: wrap large balance text, allow compact group cards to wrap, apply the 2px ink/2px-offset focus rule, expose a polite screen-reader-only marked sentence, and refuse over-200-character descriptions or non-safe counts as TEXT_NOT_UNDERSTOOD. Pending/stale share previews now show the existing pending marker instead of invented zero amounts. Card action heights are corrected to the specified 60px.
Reason: repairs observed/reproduced failures without changing money rules, approved sample results or product wording.

## D32 — Explicit identity choices for identical names
Problem: reparsing a chosen full name cannot resolve two members whose full names are identical. The allowed duplicate names reproduced this limitation.
Options: forbid duplicate names (new product restriction); apply the user's chosen member id directly while retaining the same grammar and server preview.
Choice: add optional in-memory memberChoices to the pure core reader, keyed by the original issue offset. Choices are accepted only among that issue's candidates; no API request contract changes. The web invokes the same reader with explicit choices, then requests the existing server preview before saving. API parsing without choices is unchanged.
Reason: handles identical full names, unlinked writers and sequential ambiguities without guessing or reparsing a different sentence. All official displayed shares still come from the API. Core 75-sample comparison remained unchanged; duplicate-name UI choice saved the second Minh and gave the writer a -60000 balance.

## D33 — Atomic final task record
Problem: a commit cannot contain its own hash, while the final task must leave one commit and a committed completion checkbox without rewriting history.
Options: leave the final tick/hash uncommitted; add a second task commit; store a uniquely resolvable commit reference in the atomic final commit.
Choice: commit the final tick and report together, identify that commit by the exact subject `docs(run): complete phase 1 run records`, and report its actual hash to the owner after commit. Resolve it with `git log -1 --format=%h --grep='^docs(run): complete phase 1 run records$'`.
Reason: leaves the branch/run records complete in one final task commit, without amend, history rewriting or an extra task commit.

## D34 — Session-bound event subscriptions (review R3)
Problem: a long-lived event subscription outlives its authentication middleware result.
Options: periodic revalidation only; session-hash revocation plus delivery-time checks.
Choice: hash-only subscription metadata, immediate post-commit session/user revocation, and session/group revalidation at connection, changed delivery and the existing 25-second keep-alive.
Reason: no resource event is delivered using expired access; idle expiry closes by the next keep-alive. No raw token enters the hub or logs, no new public event type or external service. An internal revoked signal closes the stream without falsely announcing group removal.
