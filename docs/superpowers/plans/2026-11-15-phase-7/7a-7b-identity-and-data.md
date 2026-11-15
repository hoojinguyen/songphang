# Phase 7 — Stages 7A and 7B: Identity and Personal Data

> Part of the phase 7 plan. Read `00-overview.md` first.

**Spec:** sections 3, 4, 8.

## Decisions for these stages

1. `LEGAL_VERSION` is a date string (`"2026-11-15"` until the advisor's texts say otherwise), exported from `packages/contract/src/legal.ts` so API and web agree.
2. The consent gate sits after authentication and before the verified-email check, so an unverified and gated user is told about consent first.
3. The export is built in memory; a user is in at most 50 groups of at most 10,000 transactions, and the endpoint streams JSON group by group to keep memory flat.
4. Retention jobs run in the worker when it exists; otherwise through a new script `pnpm retention` that the runbook puts in the host's cron (no timer inside the API process). Record which.

---

### Task 7A.1: Wordmark, mark, icons, metadata

**Files:**
- Create: `apps/web/public/brand/wordmark.svg`, `apps/web/public/brand/mark.svg`, `apps/web/src/app/icon.svg`, `apps/web/src/app/apple-icon.tsx`, `apps/web/src/app/manifest.ts`, `apps/web/src/app/opengraph-image.tsx`, `apps/web/src/app/robots.ts`
- Modify: `apps/web/src/app/layout.tsx` (metadata), signed-in layouts and `/join` (`robots: noindex`)

Requirements: spec section 3. The mark is a 2 × 2 grid on a `#F6F2FB` square with radius 22 %: `circle` in `mint`, `diamond` in `sky`, `squircle` in `coral`, `leaf` in `lilac`, each shape drawn exactly as the member-shape component draws it (copy its geometry; do not approximate), each occupying 34 % of the side with equal gaps. The wordmark is rendered in HTML by a `Wordmark` component wherever it appears, because an SVG `<text>` element would depend on the font being installed where the file is opened. `wordmark.svg` is created only if a tool that converts text to outlines is already available on the machine; otherwise it is left out and recorded. Icon routes use Next.js's built-in image response; read the installed version's documentation for the file conventions. `robots.ts` allows `/`, `/dieu-khoan`, `/quyen-rieng-tu`, `/login`, `/register`; disallows `/g/`, `/join/`, `/api/`, `/account`, `/notifications`, `/link/`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check` and `pnpm build`**
- [ ] **Step 3: Exercise** — `/icon.svg`, `/apple-icon`, `/manifest.webmanifest`, `/opengraph-image`, `/robots.txt` each answer 200 with the right content type; the Open Graph image is 1200 × 630 and shows the mark and the headline; a signed-in page's HTML has `noindex`; record a screenshot of the mark at 32, 180 and 512 pixels.
- [ ] **Step 4: Commit** — `feat(web): add brand mark, icons, and site metadata`

---

### Task 7A.2: Landing page

**Files:**
- Create: `apps/web/src/components/landing/Landing.tsx`, `apps/web/src/components/landing/Point.tsx`, `apps/web/src/components/brand/Wordmark.tsx`, `apps/web/src/components/layout/LegalFooter.tsx`
- Modify: `apps/web/src/app/page.tsx` (signed out → landing; signed in → the group list, as now), `apps/web/src/lib/features.ts` or a build-time constant for which phases are merged, `apps/web/src/messages/vi.ts`

Strings: spec section 3. The contact link's address comes from `NEXT_PUBLIC_SUPPORT_EMAIL`; without it the link is not rendered.

Layout, in the 430px column, top to bottom: `Wordmark` (22 points) left and `Đăng nhập` right, 56-point bar; the mark at 96 points; the headline at 40 points, weight 900, tracking −0.02em; the sub-line in secondary text, 17 points; the primary button, full width, 56 points tall, accent background; 40 points of space; the three points as cards (radius 32, white, 24 points of padding, title 20 points weight 800, text 16 points), 12 points apart; the closing line centered; `LegalFooter`. At widths above 900px the column stays 430px, centered.

The page is a server component with no client JavaScript of its own. Whether the visitor is signed in is decided as the existing `page.tsx` decides it.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check` and `pnpm build`**
- [ ] **Step 3: Exercise in a browser** — signed out at `/`: the landing page, no request to another origin in the network panel, no cookie set; signed in at `/`: the group list; at 360px nothing overflows; keyboard order is header link, primary button, footer links; with phase 2 or 3 absent the dependent phrases are absent.
- [ ] **Step 4: Commit** — `feat(web): add landing page`

**Manual checks for the project owner**
1. Open the site in a private window → the landing page; `Bắt đầu miễn phí` leads to registration.
2. Look at the mark and the page on your phone. This is the first thing a stranger sees; note anything you want changed.

---

### Task 7B.1: Legal pages

**Files:**
- Existing, from the advisor: `apps/web/src/content/legal/terms.ts`, `apps/web/src/content/legal/privacy.ts` (each exports `{ title, updated, sections: Array<{ heading, paragraphs: string[] }> }`)
- Create: `apps/web/src/app/dieu-khoan/page.tsx`, `apps/web/src/app/quyen-rieng-tu/page.tsx`, `apps/web/src/components/legal/LegalDocument.tsx`, `packages/contract/src/legal.ts`
- Modify: S1, `/register`, S2 and S13 (footer links), `apps/web/src/messages/vi.ts`

Requirements: static server components; headings as real headings in order; paragraphs as text (no HTML from the content files); the `updated` date shown under the title as `Cập nhật ngày {DD/MM/YYYY}`; readable line length (the 430px column, 17-point text, 1.6 line height).

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — both pages render signed out and signed in; every section of the content files appears; compare the privacy text's claims with the code and write the table "claim → where the code does it → matches?" into `progress.md` for the rows of spec 4.1. A mismatch is listed under "Not verified" for the advisor, not fixed by rewording.
- [ ] **Step 4: Commit** — `feat(web): add terms and privacy pages`

---

### Task 7B.2: Consent — registration, gate, AI consent

**Files:**
- Create: `apps/api/src/auth/legal-gate.ts`, `apps/web/src/app/consent/page.tsx`, `apps/web/src/components/account/AiConsentDialog.tsx`, a migration
- Modify: `packages/db/src/schema-accounts.ts` (`users.legal_version`, `legal_accepted_at`, `ai_consent_at`), `packages/contract/src/user.ts` and the register request, `packages/contract/src/error.ts`, `apps/api/src/services/accounts.ts`, the Google (and Apple, if merged) sign-in services, `apps/api/src/routes/me.ts`, `apps/api/src/app.ts`, the web's API client (handle `LEGAL_NOT_ACCEPTED` by redirecting to `/consent`), `/register`, S13, the receipt and parse services when phase 3 is merged

**Interfaces — produces:**
- Register body gains `acceptLegalVersion: string`; not equal to `LEGAL_VERSION` → 400 `LEGAL_NOT_ACCEPTED`, checked before anything about the email (so the answer does not depend on the account's existence). A new account stores the version and time.
- Accounts created by Google or Apple sign-in start with `legal_version` NULL.
- `requireLegalAccepted` middleware, registered once for the whole authenticated router with an allow-list of exactly: `GET /me`, `POST /me/accept-legal`, `POST /auth/logout`, `GET /me/export`, `DELETE /me`. Everything else answers 403 `LEGAL_NOT_ACCEPTED` when the user's version differs from `LEGAL_VERSION`. SSE streams are covered.
- `POST /me/accept-legal` (`{ version }`): must equal `LEGAL_VERSION`; sets the two columns.
- `GET /me` gains `legalAccepted: boolean`, `aiConsent: boolean`.
- `PUT /me/ai-consent` (`{ granted: boolean }`). With phase 3 merged: creating a receipt scan without consent → 403 `AI_CONSENT_REQUIRED`; the parse fallback skips the AI silently without consent.
- The bot (phase 4) treats a gated user as not linked.

Strings: spec section 4.2 and the S13 lines of section 8.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1)**

| Request | Expected |
|---|---|
| register without `acceptLegalVersion`, for a new email and for an existing one | 400 `LEGAL_NOT_ACCEPTED`, identical bodies |
| register with it | 204; the row has the version |
| set an existing user's `legal_version` to NULL; `GET /me` | 200, `legalAccepted: false` |
| that user: **every** route in the OpenAPI file that needs authentication, generated as a list and called once each (a scratch loop, not committed) | 403 `LEGAL_NOT_ACCEPTED` for all but the five allowed; record the count and the five |
| that user: `GET …/events` | 403 |
| `POST /me/accept-legal` with an old version | 400 |
| with the current one | 204; a group route answers 200 again |
| phase 3: create a scan without AI consent | 403 `AI_CONSENT_REQUIRED`; after `PUT /me/ai-consent` granted → 201 |
| phase 3: an unparsed sentence without consent | the rule answer; no `ai_calls` row |

In a browser: register needs the box ticked (the button stays disabled and the box has an accessible label containing both links); a gated user lands on `/consent` from any address and returns to where they were after agreeing; `Đăng xuất` there works.

- [ ] **Step 4: Commit** — `feat(api): record consent and gate the API on the current legal version`

**Manual checks for the project owner**
1. Sign in with an account that existed before this phase → the consent screen appears once; agree → the app continues.
2. Try to register without ticking the box → not possible.

---

### Task 7B.3: Personal data export

**Files:**
- Create: `apps/api/src/services/export-me.ts`, `packages/db/src/export-me.ts`, `packages/contract/src/export-me.ts`
- Modify: `apps/api/src/routes/me.ts`, `apps/api/src/rate-limit.ts` (2 per day per user), S13, `apps/web/src/messages/vi.ts`

**Interfaces — produces:** `GET /me/export` → `application/json` attachment named as in spec 4.3, shape:

```
{ exportedAt, legalVersion,
  profile: { email, name, createdAt, emailVerifiedAt },
  signInMethods: string[],
  consents: { legalVersion, legalAcceptedAt, aiConsentAt },
  notificationSettings?,
  groups: [{ id, name, role, joinedAt,
             myMember: { name, paymentMethods? } | null,
             transactions: [...], comments?: [...], settlementRequests?: [...] }] }
```

Rules: `transactions` are those where the user is `created_by` or `updated_by`, or their linked member is a payer or has a share; each carries its own fields, payers and shares **with member names**, since those are part of the user's own record. `comments` are the user's own. `settlementRequests` are those the user created or whose paying or receiving member is theirs. `paymentMethods` only of `myMember`. No session, token, hash, identity subject, other users' emails, other members' payment details, or anything from a group the user is not in now.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 2)** — a group where Minh and Lan both have bank details; Lan exports.

| Check | Expected |
|---|---|
| the file searched for Minh's account number | absent |
| searched for Minh's email | absent |
| searched for `hash`, `token`, `subject` | absent as keys |
| an expense shared only by Minh and Hùng, created by Minh | absent |
| an expense Lan has a share in | present with all its shares |
| a group Lan left | absent |
| the third request in a day | 429 |
| signed out | 401 |
| a gated user | 200 |

- [ ] **Step 4: Commit** — `feat(api): add personal data export`

---

### Task 7B.4: Retention jobs

**Files:**
- Create: `packages/db/src/retention.ts`, the job or script of decision 4
- Modify: the account deletion service (confirm the cascades of spec 4.4 and add what is missing), `README.md`

**Interfaces — produces:** `runRetention(db, now: Date): Promise<Record<string, number>>` — one function, each rule one `DELETE … RETURNING` counted, in one transaction per rule:

| Rule | Deletes |
|---|---|
| `unverifiedUsers` | users with `email_verified_at IS NULL` and `created_at < now − 7 days` and no row in `group_users` |
| `sessions` | `expires_at < now − 30 days` |
| `authTokens` | `expires_at < now − 30 days` or `used_at < now − 30 days` |
| `idempotencyKeys` | `created_at < now − 30 days` |
| `aiCalls` (phase 3) | `created_at < now − 13 months` |

It logs the counts and nothing else.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 4)** — seed rows on both sides of every boundary by dating them in `psql`:

| Row | Expected |
|---|---|
| unverified user created 8 days ago | deleted |
| unverified user created 6 days ago | kept |
| **verified** user created 100 days ago | kept |
| unverified user created 8 days ago who is somehow in a group | kept |
| session expired 31 days ago / 29 days ago | deleted / kept |
| a live session | kept |
| idempotency key 31 days / 1 day old | deleted / kept |

Run it twice: the second run deletes nothing. Delete an account that has notifications, a chat identity and comments (phases present): the first two are gone; the comments remain with the author's name and a null author id.

- [ ] **Step 4: Commit** — `feat(db): add retention jobs`
- [ ] **Step 5: Stage gate 7A–7B.** Acceptance script: 7B.2 rows 1–3 and the route-loop count; 7B.3 rows 1–4; 7B.4's table. Then the gate of the common file.
