# Phase 3 — Stage 3A: Worker and Photos

> Part of the phase 3 plan. Read `00-overview.md` and spec section 15 first. Advisor revision 2026-11-17: pending owner review; do not execute yet.

**Stage goal:** background jobs run; a photo can be attached to a transaction and seen by the group, and by nobody else.

**Spec:** section 4, 8.3, 9.

## Decisions for this stage

1. pg-boss keeps its tables in its own schema `pgboss`; it creates them at worker start. `drizzle-kit` is configured to ignore that schema.
2. The `NOTIFY` channel is `songphang_events`; the payload is `{"groupId":"…","resources":["…"]}` and never exceeds 500 bytes.
3. The API also enqueues jobs (it needs the queue's `send` only); it never runs workers.
4. An attachment belongs to at most one transaction. Editing a transaction with an `attachmentIds` list replaces its set; ids no longer listed are deleted with their files.

---

### Task 3A.1: Worker process, queue, event bridge, features endpoint

**Files:**
- Create: `apps/worker/package.json`, `apps/worker/tsconfig.json`, `apps/worker/src/main.ts`, `apps/worker/src/config.ts`, `apps/worker/src/queue.ts`, `apps/worker/src/notify.ts`, `apps/worker/src/jobs/heartbeat.ts`, `apps/api/src/queue.ts`, `apps/api/src/events/listen.ts`, `apps/api/src/routes/features.ts`, `packages/contract/src/features.ts`, `packages/contract/src/jobs.ts`
- Modify: root `package.json` (`dev` starts the worker), `pnpm-workspace.yaml` if needed, `apps/api/src/server.ts`, `apps/api/src/app.ts`, `drizzle` configuration, `.env.example`, `README.md`

**Interfaces — produces:**
- `packages/contract/src/jobs.ts`: one Zod schema per job payload and `JOB_NAMES` (`"heartbeat"` now; later tasks add theirs). API and worker both import it; a payload is parsed on both sides.
- Worker `registerJob<T>(boss, name, schema: ZodType<T>, handler: (data: T, deps) => Promise<void>)`.
- Worker `notifyGroup(db, groupId: string, resources: string[]): Promise<void>` — `SELECT pg_notify('songphang_events', $1)`.
- API `enqueue<T>(executor: DbExecutor, name, data: T, options?: { singletonKey?: string; startAfter?: Date })` in `deps`.
- API `listenForGroupEvents(connectionString, hub)`: one dedicated connection that `LISTEN`s, parses each payload with Zod, forwards to the existing hub, and reconnects with backoff (1 s doubling to 30 s) when the connection drops.
- `GET /api/v1/features` (public): the existing six-field response, preserving `receiptReading`, `sentenceAi`, `telegram`, `push`, `appleSignIn`, `errorAlerts`. Extend the existing route; do not replace its shape.
- `heartbeat` job: scheduled every minute; logs one JSON line. It exists to prove the queue runs.

- [ ] **Step 1: Install `pg-boss` in `apps/worker` and `apps/api`; record the decision entry**
- [ ] **Step 2: Write it**
- [ ] **Step 3: `pnpm check` and `pnpm build`**
- [ ] **Step 4: Exercise**

| Check | Expected |
|---|---|
| `pnpm dev` | API, web and worker start; within two minutes the worker logs a heartbeat |
| `psql`: `SELECT pg_notify('songphang_events', '{"groupId":"<a group>","resources":["transactions"]}')` while `curl -N …/events` is open as a member | a `changed` event with `["transactions"]` arrives |
| The same with a payload that is not JSON, and one with an unknown field type | nothing is forwarded; one warning log line; the listener keeps working |
| Restart the database container while the API runs | the listener reconnects; a later `NOTIFY` is delivered |
| Stop the worker | the API still answers every request |
| `GET /api/v1/features` signed out | 200; all six existing capabilities are false |

- [ ] **Step 5: Commit** — `feat(worker): add worker process, job queue, and event bridge`

---

### Task 3A.2: File storage and attachments API

**Files:**
- Create: `apps/api/src/storage/file-store.ts`, `apps/api/src/storage/disk-file-store.ts`, `apps/api/src/storage/sniff.ts`, `packages/db/src/schema-attachments.ts`, `packages/db/src/attachments.ts`, `packages/contract/src/attachment.ts`, `apps/api/src/services/attachments.ts`, `apps/api/src/routes/attachments.ts`, a migration
- Modify: `apps/api/src/config.ts` (`STORAGE_DIR`), `apps/api/src/app.ts`, `apps/api/src/rate-limit.ts`, `packages/contract/src/error.ts`, `.gitignore` (`.data/`)

**Interfaces — produces:**
- `interface FileStore { put(key: string, bytes: Uint8Array, contentType: string): Promise<void>; get(key: string): Promise<Uint8Array | null>; delete(key: string): Promise<void> }`.
- `diskFileStore(root: string)`: a key must match `^[0-9a-f-]{36}/[0-9a-f-]{36}$`; the resolved path must start with the resolved root plus a separator; otherwise it throws. Writes go to a temporary name and are renamed.
- `sniffImageType(bytes: Uint8Array): "image/jpeg" | "image/png" | "image/webp" | null` — JPEG `FF D8 FF`; PNG `89 50 4E 47 0D 0A 1A 0A`; WebP `52 49 46 46 ?? ?? ?? ?? 57 45 42 50`.
- Table `attachments` as spec 4.3.
- `AttachmentDto`: `{ id, contentType, byteSize, transactionId, createdAt }`.
- `POST /groups/{groupId}/attachments` (editor): multipart, one part `file`. Use the route-specific 6 MiB streaming bound of spec 15.2, preserving the global 100 KiB bound elsewhere. Order of checks: `Content-Length` over 6 MiB → 413 before reading; actual streamed bytes over 6 MiB → 413 regardless of header; part missing → 400; size 0 or over 5,242,880 → 400 `VALIDATION_FAILED` with `details.reason: "too_large"`; sniffed type null → 400 with `details.reason: "not_an_image"`; group quota (sum of `byte_size` + this file > 209,715,200) → 422 `STORAGE_QUOTA_EXCEEDED`; then store and insert. Limit 30 per hour per user → 429.
- `GET /groups/{groupId}/attachments/{id}/content` (viewer): the headers of spec 4.3; the content type is the stored one, never the request's.
- `DELETE /groups/{groupId}/attachments/{id}` (editor): row and file; 204.
- The row is inserted after the file is written; if the insert fails the file is deleted.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise (Review Focus 1, 2)** — make test files in the scratch directory: a small real JPEG, PNG and WebP; a text file named `x.jpg`; a 7 MB file; a 5.1 MB JPEG (pad a real one).

| Caller | Request | Expected |
|---|---|---|
| Lan (editor) | upload the JPEG | 201; `contentType` `image/jpeg` |
| Lan | `GET …/content` | 200; bytes identical (compare SHA-256); `X-Content-Type-Options: nosniff`; `Cache-Control: private, no-store` |
| Hùng (viewer) | `GET …/content` | 200 |
| Hùng | upload | 403 |
| outsider | `GET …/content` | 404, body identical to a random id |
| owner of **another** group | `GET /groups/{theirGroup}/attachments/{thisId}/content` | 404 |
| Lan | upload the PNG declared as `image/jpeg` | 201; stored `image/png` |
| Lan | upload `x.jpg` (text) | 400 `not_an_image` |
| Lan | upload the 5.1 MB file | 400 `too_large` |
| Lan | upload the 7 MB file | 413 |
| Lan | upload with the part named `photo` | 400 |
| Lan | delete; then `GET …/content` | 204; 404; the file is gone from `STORAGE_DIR` |
| — | `diskFileStore.put("../../etc/x", …)` called directly | throws |
| Lan | 31 uploads in an hour | the 31st answers 429 |

- [ ] **Step 4: Commit** — `feat(api): add file storage and photo attachments`

---

### Task 3A.3: Attachments on transactions; cleanup job

**Files:**
- Create: `apps/worker/src/jobs/cleanup-attachments.ts`, `apps/worker/src/storage.ts` (the worker's own `diskFileStore`, moved with `sniff.ts` into a new package `packages/storage` if and only if both apps now need the same code; record the choice)
- Modify: `packages/contract/src/transaction.ts`, `packages/contract/src/jobs.ts`, `packages/db/src/attachments.ts`, `apps/api/src/services/transactions.ts`, `apps/api/src/services/groups.ts` (deleting a group enqueues file cleanup for its keys)

**Interfaces — produces:**
- Transaction create and edit bodies gain `attachmentIds: uuid[]` (0–3, unique, optional). Each must belong to the group and be unattached or attached to this transaction; otherwise 400 `VALIDATION_FAILED`.
- `TransactionDto` detail/create/edit gains `attachments: AttachmentDto[]`; introduce `TransactionListItemDto` for list responses with `attachmentCount` rather than attachment bodies, updating all consumers.
- Job `cleanup-attachments`, daily at 03:30 Vietnam time: deletes rows with `transaction_id IS NULL` older than 24 hours, and their files; deletes only untracked files older than 24 hours under the coordination rules of spec 15.2. Never race an upload or fresh temporary file. Job `delete-files` (`{ keys: string[] }`): enqueued when a group is deleted, with the keys read **before** the cascade.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise**

| Request | Expected |
|---|---|
| create an expense with two uploaded ids | 201; `attachments` has two; the list shows `attachmentCount: 2` |
| create another expense with one of the same ids | 400 |
| four ids | 400 |
| an id of another group | 400 |
| edit the first expense with `attachmentIds: [first]` | the second's row and file are gone |
| set an unattached row's `created_at` 25 hours back in `psql`, run the job by hand | the row and its file are gone; a 1-hour-old one stays |
| delete a group that has attachments; let the worker run | its files are gone from disk |
| delete then restore a transaction with a photo | the photo is still there (soft delete does not remove files) |

- [ ] **Step 4: Commit** — `feat(api): attach photos to transactions and clean up orphans`

---

### Task 3A.4: Web — photos on the form and the stream; stage gate

**Files:**
- Create: `apps/web/src/components/expense-form/PhotoRow.tsx`, `apps/web/src/components/ui/PhotoViewer.tsx`, `apps/web/src/lib/attachments.ts`, `apps/web/src/lib/prepare-image.ts`
- Modify: `ExpenseForm.tsx`, the stream row, `apps/web/src/messages/vi.ts`

Strings: spec section 8.3 and the file-error lines of 8.1.

**Interfaces — produces:** `prepareImage(file: File): Promise<Blob>` — decodes with `createImageBitmap` honoring orientation, draws to a canvas whose longest side is at most 2,000 pixels, exports `image/jpeg` at quality 0.85. If decoding fails it rejects, and the caller shows the "not an image" message without uploading.

Behavior: thumbnails are `<img>` elements whose `src` is the content endpoint (same origin, cookie-authenticated), 64 × 64, radius 16, `object-fit: cover`. `PhotoViewer` is a full-screen dialog with the image, closable by button, Escape and backdrop. Removing a photo updates the form's list; the server deletes on save. The stream row shows a small photo mark when `attachmentCount > 0`.

- [ ] **Step 1: Write it**
- [ ] **Step 2: `pnpm check`**
- [ ] **Step 3: Exercise in a browser** — attach two photos to a new expense, save, reopen, remove one, save; a 12-megapixel phone photo uploads under 1 MB; a fourth photo shows the limit; a `.txt` renamed `.jpg` shows the type message; as a viewer the photos open and no add control exists.
- [ ] **Step 4: Commit** — `feat(web): add photos to transactions`
- [ ] **Step 5: Stage gate 3A.** Acceptance script: 3A.2 rows 1, 2, 5, 6, 8, 9; 3A.3 rows 1, 2. Then the gate of the common file.

**Manual checks for the project owner**
1. Add an expense with a photo from your phone → the thumbnail shows in the form; the photo opens full-screen from the transaction.
2. Open the photo's address in a private window (signed out) → not found.


**Additional required exercises (spec 15.2–15.3):** absent/understated Content-Length overflow; parallel group-quota uploads; cleanup concurrent with an upload; same storage root from API/worker; denied content after access removal. Before 3B, demonstrate same-transaction pg-boss enqueue rollback against the installed adapter. Record unsupported adapter behavior as a readiness blocker, not a passed gate.
