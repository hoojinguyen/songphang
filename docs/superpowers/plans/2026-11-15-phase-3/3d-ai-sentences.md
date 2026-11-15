# Phase 3 — Stage 3D: AI Sentences

> Part of the phase 3 plan. Read `00-overview.md` first.

**Stage goal:** a sentence the rule reader refuses is read by the AI into the same draft, checked by the same code, and confirmed on the same card; descriptions suggest a category.

**Spec:** section 7, 8.4.

## Decisions for this stage

1. The sentence AI runs in the API process, inside the parse request (spec section 7), so its adapter lives in `apps/api`. `anthropic-client.ts` moves from the worker to a new package `packages/ai` used by both; nothing else moves.
2. The AI is asked only when the rule reader's status is `unparsed`. `needs_input` is never sent to the AI.
3. A user over their daily sentence quota, or a month over its ceiling, silently gets the rule reader's answer.
4. An AI draft is never returned as `ok` unless: the schema parses, every member id is in the group, `computeShares` succeeds, and the AI's own `confident` flag is true. Otherwise it is `needs_input` when a draft with an amount exists, else `unparsed`.
5. AI drafts are expenses only.

---

### Task 3D.1: The sentence AI and the parse fallback

**Files:**
- Create: `packages/ai/package.json`, `packages/ai/src/anthropic-client.ts` (moved), `packages/ai/src/index.ts`, `apps/api/src/ai/sentence-ai.ts`, `apps/api/src/ai/anthropic-sentence-ai.ts`, `apps/api/src/ai/fake-sentence-ai.ts`, `apps/api/src/ai/prompts/sentence.ts`, `packages/contract/src/sentence-ai.ts`
- Existing, from the advisor: `apps/worker/fixtures/sentences.json` — 15 entries `{ sentence, members: string[], answer }`; move it to `apps/api/fixtures/sentences.json`
- Modify: the worker's imports, `apps/api/src/services/transactions.ts` (the parse function), `packages/contract/src/transaction.ts`, `apps/api/src/app.ts` (`deps.sentenceAi`), `apps/api/src/routes/features.ts`

**Interfaces — produces:**
- `SentenceAiAnswer` (Zod): `{ drafts: Array<{ description: string (1–200); amount: int; payerMemberId: uuid | null; split: SplitInput (equal, exact, shares or percent; never items); category: TransactionCategory | null; confident: boolean }> (0–5) }`.
- `interface SentenceAi { read(input: { sentence: string; members: Array<{ id: string; name: string }>; writerMemberId: string | null }): Promise<{ answer: unknown; model: string; inputTokens: number; outputTokens: number }> }`.
- The Anthropic adapter forces one tool `record_expenses` with `z.toJSONSchema(SentenceAiAnswer)`, an 8-second timeout and **no retry**. The prompt gives the member list as `id` and `name` pairs, the writer's id for "mình/tôi/tớ", the rule that amounts are đồng with `k` = thousand and `tr` = million, and the instruction to set `confident: false` and guess nothing when any number is unclear.
- The fake adapter looks the normalised sentence up in the fixture file and maps the fixture's member **names** to the ids it was given; an unknown sentence returns `{ drafts: [] }`.
- The parse response gains `reader: "rules" | "ai"` (always present) and `moreDrafts: Draft[]` (always present, possibly empty; each with its own `shares` when it qualifies as `ok`).
- Parse flow after the rule reader answers `unparsed`: no adapter → return; `reserveAiCall(purpose "sentence")` not `ok` → return; call; on throw or timeout record `ok = false` and return the rule answer; parse the answer; drop any member id not in the group's people and mark that draft not confident; for each draft run `computeShares`; build the response by decision 4 with `spans: []` and `issues` = `[{ code: "TEXT_NOT_UNDERSTOOD", start: 0, end: text.length }]` when not `ok`.
- The sentence is limited to 300 characters before any of this, as today.

- [ ] **Step 1: Read the documentation for forced tool use; write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — `AI_PROVIDER=fake`, fresh group Minh, Lan, Hùng, Thu.

| Request | Expected |
|---|---|
| parse `cà phê 180k chia 4` | `reader: "rules"`, `ok`; no new `ai_calls` row |
| parse a `needs_input` sample from `docs/08-quick-entry-samples.md` | `reader: "rules"`; no new `ai_calls` row |
| each of the 15 fixture sentences | `reader: "ai"`; the fixture's draft; `shares` equal to a `preview` of the same draft; record the table |
| a fixture whose answer holds two expenses | `draft` is the first, `moreDrafts` has one |
| a fixture whose answer names a member not in this group (the advisor's fixture 14) | that member is dropped; status is not `ok` |
| a fixture with `confident: false` (fixture 15) | `needs_input`; no `shares` |
| an unparsed sentence not in the fixtures | exactly the rule reader's `unparsed` answer, `reader: "rules"` |
| stub the adapter to sleep 9 seconds | the request returns the rule answer in about 8 seconds; `ai_calls.ok` false |
| stub the adapter to return `{ drafts: [{ amount: "abc" }] }` | the rule answer; `ai_calls.ok` false |
| `AI_SENTENCES_PER_USER_PER_DAY=1`, two unparsed fixture sentences | the second gets the rule answer |
| viewer | 403 |
| unset `AI_PROVIDER` | `features.sentenceAi` false; unparsed stays unparsed |

All 75 phase 1 samples (and phase 2's 12, if merged) return exactly what they returned before, with `reader: "rules"`.

- [ ] **Step 4: Commit** — `feat(api): read refused sentences with the AI reader`

---

### Task 3D.2: `core` — category suggestion

**Files:**
- Existing, from the advisor: `packages/core/src/category-keywords.ts` — `CATEGORY_KEYWORDS: ReadonlyArray<readonly [keyword: string, category: string]>`, keywords already normalised
- Create: `packages/core/src/suggest-category.ts`
- Modify: `packages/core/src/index.ts`, the parse function in `apps/api/src/services/transactions.ts`

**Interfaces — produces:**
- `suggestCategory(description: string, custom: ReadonlyArray<{ id: string; nameKey: string }>): { category: string } | { categoryId: string } | null` — normalise the description; a custom category whose `nameKey` equals the whole normalised description, or one of its words, wins; otherwise the **longest** keyword that occurs on word boundaries wins; ties go to the earlier table entry; no match → null.
- Parse: every draft from either reader whose category is empty gets the suggestion. An AI draft's own category, when present, is kept.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise** — with the advisor's table:

| Description | Expected |
|---|---|
| `Phở bò` | `food` |
| `grab ra sân bay` | `transport` |
| `Khách sạn Đà Lạt` | `lodging` |
| `tiền điện tháng 12` | `bills` |
| `xyz` | null |
| `phong` (must not match `pho`) | null, or whatever the table gives for the whole word; never `food` |
| `Cà phê` with a custom category named `Cà phê` | that `categoryId` |

Parse `phở 60k chia 2` → `draft.category` `food`.

- [ ] **Step 4: Commit** — `feat(core): suggest a category from the description`

---

### Task 3D.3: Web — AI readings on the card

**Files:**
- Modify: the typing box, the confirmation card and its page (real names from the re-baseline), `apps/web/src/messages/vi.ts`

Strings: spec section 8.4.

Behavior: `Đang đọc…` appears when the parse request has been pending for one second. A response with `reader: "ai"` shows the AI line on the card and no phrase highlighting in the sentence. With `moreDrafts`, the card shows `Khoản {index}/{count}`; `Lưu và sang khoản sau` saves the current draft (its own idempotency key) and shows the next; `Bỏ khoản này` skips it; after the last, the page returns to S4. A draft that is not `ok` opens the manual form prefilled, as today. The category chip shows the suggestion and opens the existing picker.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser, `AI_PROVIDER=fake`** — a single-expense fixture; the two-expense fixture saved one and skipped one; the not-confident fixture opens the form; a rule sentence looks exactly as before; `phở 60k chia 2` shows the `food` chip.
- [ ] **Step 4: Commit** — `feat(web): show AI sentence readings and suggested categories`

**Manual checks for the project owner**
1. With the fake provider, type the first sentence of `apps/api/fixtures/sentences.json` → a card marked `Đọc bằng AI. Hãy xem lại.`; Lưu stores it.
2. Type `cà phê 180k chia 4` → no AI mark, as before.

---

### Task 3D.4: README, non-functional checks, final gate

**Files:**
- Modify: `README.md` (the worker, `STORAGE_DIR`, the AI variables and the fake provider, the fixtures), `infra/compose.prod.yml` if it exists (a `worker` service and an uploads volume shared by `api` and `worker`; the backup script gains the uploads archive, server-step spec section 7)

- [ ] **Step 1: README and, when the server step is merged, the Compose and backup changes.**
- [ ] **Step 2: Non-functional checks.** Keyboard-only walk through the review screen (select an item, toggle members, save); every member shape there has an accessible name; the camera button has its label; a 5 MB upload on a throttled "Fast 4G" profile shows progress and completes.
- [ ] **Step 3: Stage gate 3D** — acceptance script: 3D.1 rows 1, 3 (three sentences of your choice, recorded), 5, 6, 7. Then the full gate of the common file, replaying 3A–3C and every earlier phase.
- [ ] **Step 4: Finish the run files.** `manual-checks.md` gains a section "After the Anthropic key exists": set `AI_PROVIDER=anthropic`, `AI_MODEL`, the key; photograph five real receipts and type five free sentences; for each, note what was read wrong; check `ai_calls` for token counts. And a section "The 30-receipt measurement" restating the roadmap's survey with a table to fill in (receipt, total right?, items right?, tokens).
- [ ] **Step 5: Commit** — `docs(repo): document phase 3`
