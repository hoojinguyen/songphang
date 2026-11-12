# Phase 1 — Stage 1D: Quick Entry

> Part of the phase 1 plan. Read `00-overview.md` first. Task references inside this file mean this stage's tasks.

**Stage goal:** An expense is recorded by typing one sentence. The app shows exactly what it understood, saves nothing until "Lưu", and hands anything it does not understand to the form.

**Spec:** design spec section 8; `docs/03-srs.md` FR-1.90–1.100; `docs/05-api-spec.md` "Đọc câu gõ"; `docs/06-ux-ui/user-flows.md` flows C, D, E; **`docs/08-quick-entry-samples.md`**, which defines the reading rules and the expected result of 75 sentences.

## Decisions for this stage

1. An issue object is `{ code, start, end, candidates }` as in the API specification, plus optional `count` (for `COUNT_MISMATCH`), `expected` and `actual` (for `SUM_MISMATCH`). The web app needs them to phrase its questions.
2. A writer with no linked member who names no payer gets `MEMBER_AMBIGUOUS` at position 0–0 with every active member as candidate: the card asks who paid.
3. The API normalizes the sentence to NFC; spans refer to that text. The web app normalizes before sending and before highlighting.
4. The three sample sentences on the empty group screen are `cà phê 180k`, `taxi 250k mình trả`, `ăn trưa 240k chia đều`: they read correctly in a group of any size, unlike GE14's.
5. The draft passed from the confirmation card to the form lives in memory in the group layout; it is not written to storage or to the URL.

## Review Focus

1. **A guessed expense.** No `needs_input` or `unparsed` sentence can be saved from the card; "Lưu" exists only for `ok`. → 1D.3, 1D.4.
2. **Card and saved amounts differing.** The amounts on the card are the `shares` of the parse response, computed by the same `computeShares` as saving. → 1D.2.
3. **Name collisions.** "minh" in a group with Minh Anh and Minh Đức asks; it never picks. → 1D.1.
4. **Highlight drift.** Spans stay aligned with the text for accented letters, repeated spaces and pasted text. → 1D.3.
5. **A lost sentence.** Going to the form and back, or failing to save, never loses what was typed. → 1D.4.

---

### Task 1D.1: `core` — the sentence reader

**Files:**
- Create: `packages/core/src/quick-entry/normalize.ts`, `tokens.ts`, `amounts.ts`, `names.ts`, `read-sentence.ts`
- Modify: `packages/core/src/index.ts`

**Interfaces — produces:**
- `type QuickEntryMember = { id: string; name: string; active: boolean; position: number }`
- `type SpanKind = "amount" | "description" | "payer" | "equal" | "exact" | "remainder"`
- `type QuickEntryIssueCode = "AMOUNT_MISSING" | "DESCRIPTION_MISSING" | "MEMBER_AMBIGUOUS" | "MEMBER_UNKNOWN" | "COUNT_MISMATCH" | "SUM_MISMATCH" | "TEXT_NOT_UNDERSTOOD"`
- `type QuickEntryResult = { status: "ok" | "needs_input" | "unparsed"; draft: { description: string | null; amount: number | null; payerMemberId: string | null; split: SplitInput | null }; spans: Array<{ start: number; end: number; kind: SpanKind }>; issues: Array<{ code: QuickEntryIssueCode; start: number; end: number; candidates: string[]; count?: number; expected?: number; actual?: number }> }`
- `readSentence(input: { text: string; members: readonly QuickEntryMember[]; writerMemberId: string | null }): QuickEntryResult` — pure; implements section 1 of `docs/08-quick-entry-samples.md` exactly and nothing more. `text` is assumed NFC. Spans are sorted by `start` and never overlap. Candidates are in position order.
- `foldVietnamese(text: string): string` — lower-cases and removes diacritics, mapping `đ` to `d`, keeping the string length equal to the input's so positions carry over.

Structure: one small function per rule (amount token, payer phrase, `chia` phrase, personal parts), each returning what it consumed, and one function that assembles the result and derives `status`. No rule guesses; an input no rule consumes becomes an issue.

- [ ] **Step 1: Write the files**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 3)**

Run every sentence of `docs/08-quick-entry-samples.md` through `readSentence` with a temporary loop that is **not committed**, and record in `progress.md` a table of sample id, expected status, actual status, and "match" for description, amount, payer, split and the required issue. For `ok` samples also compute `computeShares` and compare with the "Shares" column. All 75 must match. Check the spans of A01 and A36 against the document.

Also record: `foldVietnamese("Hùng ĐỨC mình")` → `hung duc minh`, same length; a 300-character sentence of `a` returns `unparsed` without error; an empty string returns `AMOUNT_MISSING`.

- [ ] **Step 4: Commit** — `feat(core): add rule-based sentence reader`

**Manual checks for the project owner**
1. Pick ten rows of the sample document, at least three from the refused section, and run them → status and numbers as written.

---

### Task 1D.2: API — parse endpoint

**Files:**
- Create: `packages/contract/src/quick-entry.ts`, `apps/api/src/services/quick-entry.ts`
- Modify: `apps/api/src/routes/transactions.ts`, `packages/contract/src/index.ts`

**Interfaces — produces:**
- `ParseRequest` = `{ text: string }` — the raw sentence, 1 to 300 characters; it is not trimmed, because spans index it.
- `ParseDraft` = `{ type: "expense"; description: string | null; amount: number | null; payers: Array<{ memberId; amount }>; split: SplitInput | null }` — `payers` is one entry carrying the total when both payer and amount are known, otherwise empty.
- `ParseResponse` = `{ status; text: string; draft: ParseDraft; shares?: ShareDto[]; spans; issues }` — `text` is the NFC sentence the spans refer to; `shares` is present only for `ok`.

`POST /groups/{groupId}/transactions/parse`, access editor, limit 120 per minute per user, no idempotency key (it stores nothing): normalize to NFC; call `readSentence` with the group's members and the caller's linked member; for `ok`, `shares` = `computeShares` — a mismatch there is a server error, not a response.

- [ ] **Step 1: Write the schemas, service and route**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 2):** build groups A, B and C of the sample document through the API; send every sample with `curl` and record status and shares as in 1D.1 (all 75 match); for five `ok` samples post the returned `draft` (adding `occurredAt` and `category: null`) to the create endpoint and confirm the stored shares equal the parse response's; a 301-character sentence → 400; a viewer → 403; an outsider → 404; 121 requests in a minute → 429; `select count(*) from transactions` does not change during parsing.
- [ ] **Step 4: Commit** — `feat(api): add sentence parse endpoint`

---

### Task 1D.3: Web — typing box and confirmation card

**Files:**
- Create: `apps/web/src/lib/quick-entry.ts`, `apps/web/src/lib/draft-context.tsx`, `apps/web/src/components/quick-entry/SentenceInput.tsx`, `HighlightedSentence.tsx`, `ConfirmationCard.tsx`, `ShareShapes.tsx`, `apps/web/src/app/g/[groupId]/tx/new/ComposeScreen.tsx`
- Modify: `apps/web/src/app/g/[groupId]/tx/new/page.tsx` (without `?form` it renders `ComposeScreen`; with it, the form), `apps/web/src/app/g/[groupId]/layout.tsx` (draft provider), `apps/web/src/components/feed/EntryBar.tsx`, `EmptyStream.tsx`, `apps/web/src/components/expense-form/SplitEditor.tsx` (use `ShareShapes`), `apps/web/src/app/globals.css`, `apps/web/src/messages/vi.ts`

**Interfaces — produces:**
- `useParseSentence(groupId, text)` — a query on the parse endpoint, debounced 300 ms, disabled for an empty sentence, keeping the previous result while loading.
- `ShareShapes(props: { shares: Array<{ member: MemberDto; amount: number }> })` — the row of shapes sized 56–104 by share with name and amount beneath, extracted from the split editor.
- `HighlightedSentence(props: { text: string; spans })` — renders the sentence with each span wrapped in a `<mark>` of its kind's color and an `aria-label` naming the kind.
- `useDraft()` — get, set and clear the in-memory draft `{ sentence: string; draft: ParseDraft; issues }` for the group.

Tokens: `--color-phrase-amount: #ffe99a`, `--color-phrase-payer: #cfe3ff` (`phrase-split` and `phrase-rest` exist). Span colors: `amount` → amount; `payer` → payer; `equal` and `exact` → split; `remainder` → rest; `description` → none. Motion: a mark's background grows from left to right in 150 ms; none under `prefers-reduced-motion`. New `Icon` name: `send` (`M12 19V5M6 11l6-6 6 6`).

Strings:

| Key | Value |
|---|---|
| `feed.entryPlaceholder` (changed) | `Gõ một khoản chi…` |
| `feed.emptyTitle` (changed) | `Gõ khoản chi đầu tiên` |
| `feed.emptyHint` (changed) | `Viết như nhắn tin. Chạm một câu mẫu để thử.` |
| `feed.samples` | `cà phê 180k` · `taxi 250k mình trả` · `ăn trưa 240k chia đều` |
| `compose.title` | `Khoản chi mới` |
| `compose.inputLabel` | `Gõ một khoản chi` |
| `compose.send` | `Gửi` |
| `compose.understood` | `Mình hiểu là` |
| `compose.payer` | `{name} trả` |
| `compose.payerDefault` | `Bạn trả (mặc định)` |
| `compose.equal` | `Chia đều {count} người · {amount} mỗi người` |
| `compose.equalUneven` | `Chia đều {count} người` |
| `compose.exact` | `Riêng: {parts}` |
| `compose.rest` | `Còn {amount} chia đều {count}` |
| `compose.notIncluded` | `{names} không có trong khoản này.` |
| `compose.nothingSaved` | `Chưa có gì được lưu.` |
| `compose.edit` | `Chỉnh tay` |
| `compose.save` | `Lưu` |
| `compose.kindAmount` | `số tiền` |
| `compose.kindPayer` | `người trả` |
| `compose.kindSplit` | `phần chia` |
| `compose.kindRest` | `phần còn lại` |

`compose.exact`'s `{parts}` is `{name} {formatCompactAmount}` joined by ` · `.

Behavior:

| Part | Behavior |
|---|---|
| S4 `EntryBar` | Unchanged shape; the box link now goes to `/g/{id}/tx/new` (the compose screen) and shows `feed.entryPlaceholder`. "Nhập tay" still goes to `?form`. |
| `EmptyStream` | Back to GE14: the title on two lines, the hint, and three surface buttons (radius 24, padding 14/18, 15px weight 600) holding the sample sentences with their phrases marked; tapping one opens the compose screen with that sentence filled in. |
| `ComposeScreen` (GE3) | `ScreenHeader` with the close icon, `compose.title`, the group name. The typing box is at the bottom: surface, radius 30, 3px ink border, a `SentenceInput` and a 52 × 52 ink send button (radius 20) labelled `compose.send`. The card sits above it and appears once a response exists. The input is focused on arrival; the sentence survives a reload of the query. |
| `SentenceInput` | A `<textarea>` (16px, line height 1.8, `maxLength` 300, labelled `compose.inputLabel`) with transparent text over a `HighlightedSentence` of the same metrics, so marks sit exactly under the letters; the caret stays visible. Enter sends (parses at once); Shift+Enter is ignored. Pasted text is normalized to NFC and line breaks become spaces. |
| `ConfirmationCard`, `ok` | Surface, radius 40, padding 20/18/18. `compose.understood` 13px weight 600 muted; description 18px weight 800; the total at 60px weight 900 on a `phrase-amount` mark, with `đ` at 22px muted. A wrapping row of chips (radius 14, padding 6/12, 13px weight 700): the payer on `phrase-payer` (or `compose.payerDefault` on `bg` when no payer was typed); the split on `phrase-split` — `compose.equal` when all shares are equal, `compose.equalUneven` when rounding made them differ, `compose.exact` for personal parts; and `compose.rest` on `phrase-rest` when there is a remainder. `ShareShapes` on a `bg` panel, radius 30. A 12px muted line: `compose.notIncluded` for active members without a share, then `compose.nothingSaved`. Two buttons, height 60: `compose.edit` (`bg`, flex 1) and `compose.save` (accent, flex 1.6, 17px weight 900). |
| Save | Posts the response's `draft` with `occurredAt` = now and `category: null`, one idempotency key per sentence value; on success returns to the stream. The saved row appears at the bottom. Motion: the card collapses toward the bottom over 250 ms before navigation; none under reduced motion. Failure shows `common.saveError`; the sentence stays. |
| `compose.edit` | Stores sentence, draft and issues with `useDraft` and opens `?form`, where every understood field is prefilled (payer, amount, description, split in the right editor mode). |

- [ ] **Step 1: Write hooks, context, components**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 2, 4):** type A01, A23, A36 and A43 in group A and compare the card with the sample rows and with the stored transaction after saving; type slowly and watch marks appear under the right letters, including with accents, double spaces, and a pasted sentence with a line break; A36's marks cover exactly `300k`, `mình trả`, `mình 80 lan 60 hùng 40`, `còn lại chia đều`; "Chỉnh tay" from A36 opens the split editor in "Số tiền" mode with 80.000 / 60.000 / 40.000 and the lilac button already applied; double-tap "Lưu" → one expense; tap a sample sentence on an empty group; a viewer never sees the box.
- [ ] **Step 4: Commit** — `feat(web): add typing box and confirmation card`

**Manual checks for the project owner**
1. Compare the compose screen with GE3 and the empty group screen with GE14.
2. Type "lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều" → four colored phrases, shapes of three sizes, 120.000 / 100.000 / 80.000, "Thu không có trong khoản này."
3. Save and check the stream and the balances.
4. With a screen reader, the marked phrases are announced with their kind, not only shown in color.

---

### Task 1D.4: Web — questions and sentences that are not understood

**Files:**
- Create: `apps/web/src/components/quick-entry/ChoicePanel.tsx`, `DescriptionPrompt.tsx`, `apps/web/src/components/expense-form/UnparsedBanner.tsx`
- Modify: `ConfirmationCard.tsx`, `ComposeScreen.tsx`, `ExpenseForm.tsx`, `apps/web/src/messages/vi.ts`

Strings:

| Key | Value |
|---|---|
| `compose.whichPeople` | `{count} người nào?` |
| `compose.chosen` | `đã chọn {selected} / {count}` |
| `compose.countReason` | `Nhóm có {total} người nên mình không tự chọn. Chưa có gì được lưu.` |
| `compose.chooseMore` | `Chọn thêm {count} người` |
| `compose.whichMember` | `{word} nào?` |
| `compose.whoPaid` | `Ai trả khoản này?` |
| `compose.memberReason` | `Có hơn một người khớp với “{word}” nên mình không tự chọn. Chưa có gì được lưu.` |
| `compose.descriptionPrompt` | `Khoản này chi cho việc gì?` |
| `unparsed.title` | `Mình chưa hiểu hết câu này` |
| `unparsed.amountMissing` | `Mình chưa thấy số tiền trong câu.` |
| `unparsed.sumShort` | `Các phần riêng cộng lại {actual}, còn {rest} chưa biết của ai. Mình không tự chia hộ.` |
| `unparsed.sumOver` | `Các phần riêng cộng lại {actual}, nhiều hơn tổng {total}.` |
| `unparsed.memberUnknown` | `Nhóm không có ai đang hoạt động tên “{word}”.` |
| `unparsed.countTooLarge` | `Nhóm chỉ có {total} người đang hoạt động.` |
| `unparsed.notUnderstood` | `Mình chưa hiểu đoạn “{fragment}”.` |

Behavior:

| Status | Behavior |
|---|---|
| `needs_input`, `COUNT_MISMATCH` (GE15) | The card shows what was understood, then a `ChoicePanel` on `bg`, radius 30: `compose.whichPeople` 20px weight 800 with `compose.chosen` 13px on the right; a four-column grid of `aria-pressed` member buttons (shape 52, name 13px; selected: 3px ink border); `compose.countReason`. The right button is `compose.chooseMore` on `sunken`, disabled, until exactly `count` people are chosen; then it becomes `compose.save`, and the card shows the equal split among them from a preview request. Choosing more than `count` is not possible. |
| `needs_input`, `MEMBER_AMBIGUOUS` | A `ChoicePanel` in single-selection mode titled `compose.whichMember` with the word from the sentence (or `compose.whoPaid` for the position 0–0 issue), listing only the candidates, with `compose.memberReason`. After the choice the web app replaces that word's meaning in the draft, requests a preview, and enables `compose.save`. Several ambiguous words are asked one after another. |
| `needs_input`, `DESCRIPTION_MISSING` | A `TextField` `compose.descriptionPrompt` inside the card; `compose.save` enables when it is not blank. |
| `unparsed` (GE16) | The compose screen does not show a card. It stores the draft with `useDraft` and replaces itself with `?form`. `UnparsedBanner` is the first block of the form: background `phrase-amount`, radius 30; `unparsed.title` 20px weight 800; the sentence in a surface box, radius 18, with its marks; one line per issue from the table below. The form holds every understood field. For `SUM_MISMATCH` the split editor is open in "Số tiền" mode with the typed parts, so the status bar and the lilac button of 1C.4 offer the way forward. The banner has a close button; the back arrow returns to the compose screen with the sentence intact. |

| Issue | Line |
|---|---|
| `AMOUNT_MISSING` | `unparsed.amountMissing` |
| `SUM_MISMATCH`, actual < expected | `unparsed.sumShort` with `rest` = expected − actual |
| `SUM_MISMATCH`, actual > expected | `unparsed.sumOver` |
| `MEMBER_UNKNOWN` | `unparsed.memberUnknown` with the text of the span |
| `COUNT_MISMATCH` | `unparsed.countTooLarge` |
| `TEXT_NOT_UNDERSTOOD` | `unparsed.notUnderstood` with the text of the span |

Saving from a `needs_input` card posts the draft completed with the user's choices; it goes through the same create endpoint and validation as any transaction.

- [ ] **Step 1: Write the components and the status handling**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in the browser (Review Focus 1, 5):** A46 → choose two then three people → "Lưu" appears only at three; shares 60.000 each; B02 in group B → "minh nào?" with three shapes → choose Minh Đức → saved with him as payer; A48 → type a description → save; A53 → the form with the banner, "Các phần riêng cộng lại 180.000 đ, còn 120.000 đ chưa biết của ai. Mình không tự chia hộ.", the three amounts filled, "Còn dư 120.000 đ · chưa lưu được", and the lilac button resolving it; A50, A55, A57, A59 → their lines; from the form go back → the sentence is still in the box; stop the API during save → the sentence and the choices remain; in no case does a transaction exist before "Lưu" is pressed (check the database after each step).
- [ ] **Step 4: Commit** — `feat(web): add clarifying questions and hand-off to the form`

**Manual checks for the project owner**
1. Compare A46 with GE15 and A53 with GE16.
2. Type five sentences of your own the way you would text a friend. For each, write down whether the app read it, asked, or refused, and whether that was right. These sentences are the input for extending the rules later (roadmap decision point "cuối mốc 1D").
3. Confirm you can always reach the form in one tap with "Nhập tay".

---

### Task 1D.5: Stage gate 1D

- [ ] **Step 1: Run the stage gate.** Acceptance script, reset database, `curl` only: build groups A, B, C; all 75 samples through the parse endpoint with a table of matches; save A01, A31, A36, A43 from their drafts and compare stored shares; confirm the transaction count equals the number of saves; `pnpm db:check-balances`. Then the 1A, 1B and 1C scripts again. Permission matrix: parse as viewer → 403, outsider → 404.
- [ ] **Step 2: Record the gate result; commit any fixes**

A sample that does not match is a defect in the reader, not in the document. If you believe a sample row contradicts FR-1.91–1.99, keep the document's result, and record the contradiction in `decisions.md`.
