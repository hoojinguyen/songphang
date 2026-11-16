# Captured API responses

Captured by the advisor on 2026-11-16 from the local development API (`http://127.0.0.1:4000/api/v1`), signed in as the seeded user Minh, on a group created for the capture (`Đà Lạt 3N2Đ`: Minh, Lan, Hùng, Thu) and deleted afterwards. The API was running the `phase-1` working tree of that day, which included uncommitted changes.

Each file is `{ "request": { method, path, body }, "status", "response" }`. Files are numbered in the order the requests were made, so a `stepN-…` file shows the state after transaction `TN` of `docs/superpowers/plans/2026-11-12-phase-1/1c-splits-and-settlements.md`.

| Files | Content |
|---|---|
| `01`, `03`–`08`, `45` | The user, creating the group, the group list, the group, members, users, the invite link and its preview |
| `09`–`10` | Step 0: no transaction, zero balances |
| `11`–`26` | For each of T1–T4: its `preview`, its creation, then the transaction list and the balances |
| `27`–`28` | One transaction in detail; the activity list |
| `29`–`44` | `parse` of ten sentences (six `ok`, two `needs_input`, two `unparsed`) and, for each `ok` one, the `preview` of its draft with `occurredAt` and `category: null` added |

Checked against the phase 1 plan: step 4 balances are Minh +500001, Lan −120000, Hùng −170001, Thu −210000, with the three transfers the plan lists.

Notes for the run:

- `02-features.json` is a 404: `GET /features` does not exist yet (it arrives with a later phase). `ServerFeatures` in `Domain` is a domain guess; the fake reports Google and Apple as available so both buttons can be seen.
- Identifiers, timestamps and the invite token are those of the capture. The token is dead: its group was deleted. Use them as they are or replace them with fixed sample identifiers, consistently.
- Amounts are never to be changed or recomputed. A scenario needing an amount that is not here is not scripted.
- Not captured: error responses, pagination beyond the first page, the event stream, sign-in and registration. Their shapes come from `packages/contract`.
