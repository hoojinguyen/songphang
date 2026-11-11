# Code conventions

Updated: 2026-11-11. This file expands section 7 of `AGENTS.md`. If the two files differ, `AGENTS.md` is authoritative.

## 1. Directory structure

```
apps/
  api/src/
    config.ts            read and validate environment variables
    app.ts               assemble the application: middleware, routes
    errors.ts            AppError and shared error handler
    routes/              one file per endpoint group; no logic
    services/            one file per group of business operations
    auth/                sessions, authentication middleware, and authorization
  web/src/
    app/                 pages (App Router); one screen per directory
    components/ui/       shared components with no business knowledge
    components/<name>/   feature-specific components
    lib/                 API calls, data hooks, utility functions
    messages/vi.ts       all displayed strings
packages/
  contract/src/          Zod schemas for every request and response
  db/src/                table schemas, migrations, queries
  core/src/              pure money logic (from milestone 1A)
docs/                    documentation; implementation agents do not edit it
```

Dependency rules: `web → contract`; `api → contract, db, core`; `core` has no dependencies. Do not import across `apps/`. Do not create a new top-level directory without approval.

Do not create a directory for one file: there is no need for `utils/`, `helpers/`, `types/`, or `constants/` until a second file of that kind exists.

## 2. Naming

| Thing | Convention | Example |
|---|---|---|
| Files and directories | `kebab-case` | `create-session.ts`, `dev-login/` |
| React component files | `PascalCase` | `MemberShape.tsx` |
| Variables and functions | `camelCase` | `findSessionUser` |
| Types and components | `PascalCase` | `UserDto`, `MemberShape` |
| Module-level constants | `SCREAMING_SNAKE_CASE` | `SESSION_TTL_MS` |
| Database tables and columns | `snake_case`, plural tables | `sessions.token_hash` |
| API JSON fields | `camelCase` | `avatarUrl` |
| Error codes | `SCREAMING_SNAKE_CASE` | `UNAUTHENTICATED` |

- **Functions are verbs**, accurately stating what they do and return: `createSession`, `findSessionUser`, `deleteSession`. Functions returning `null` when absent start with `find`; functions throwing when absent start with `get`.
- **Boolean values** start with `is`, `has`, `can`, or `should`: `isExpired`, `hasVerifiedEmail`.
- **Do not abbreviate**, except for universally understood terms (`id`, `url`, `db`, `dto`). Write `transaction`, not `tx` or `txn`; `member`, not `mem`.
- **Put units in names** when the type does not express them: `SESSION_TTL_MS`, `amountMinor`, `expiresAt`.
- **Do not use meaningless names:** `data`, `info`, `item`, `temp`, `handle`, `process`, `manager`, `util`. If you cannot find a specific name, the function is doing too much.
- Code, names, and comments are written in **English**. User-visible strings are written in Vietnamese and live only in `messages/vi.ts`.

**Business vocabulary.** Use one English word for each concept everywhere:

| Vietnamese | In code |
|---|---|
| Nhóm | `group` |
| Thành viên (một cái tên trong nhóm) | `member` |
| Người dùng (một tài khoản) | `user` |
| Giao dịch | `transaction` |
| Chi tiêu, chuyển khoản, thu nhập | `expense`, `transfer`, `income` |
| Người trả | `payer` |
| Phần một người chịu | `share` |
| Cách chia | `split` |
| Số dư | `balance` |
| Lượt chuyển đề xuất | `settlement` |
| Lời mời | `invite` |
| Phiên đăng nhập | `session` |

## 3. TypeScript

- `strict` is fully enabled, together with `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`.
- No `any`. Data of unknown type is `unknown`, then narrowed with a Zod schema.
- Do not use `as` casts to satisfy the compiler or use `!`. The only exception is `as const`.
- Types for boundary data are inferred from Zod schemas (`z.infer`), not handwritten a second time.
- Use string unions instead of `enum`. Use `type` for data; use `interface` only when extension is needed.
- Use named exports only. `export default` is allowed only where the framework requires it (Next.js pages and layouts, configuration files).
- Prefer `const`, pure functions, and immutable data. Do not mutate input parameters.
- Functions with more than three parameters receive an object with named fields.
- Use `async`/`await`; do not leave promises floating without an owner.
- Return early instead of nesting `if`. Do not use `else` after `return`.

## 4. Error handling

- API business errors throw `AppError(status, code, message, details?)`; the shared handler converts them to the API specification's error format. Do not build error responses in routes.
- Do not swallow errors: no empty `catch`, and no catch-then-log-and-continue as if nothing happened.
- Use `try/catch` only where the error can actually be handled. Otherwise let it reach the shared handler.
- Unexpected errors return 500 with a generic message and are logged fully with `requestId`.
- In the web app, every API call goes through `apiFetch`; data screens always have loading, error, and empty states.

## 5. API

- **Route** declares the path, attaches schemas from `contract`, calls one service function, and returns the result. It does not query the database or contain business conditions.
- **Service** is one function for one business operation. It opens a transaction when writing multiple tables, calls `core` for calculations, and writes data.
- **Queries** live in `packages/db`, are typed, and contain no business rules.
- Every request and response has a schema in `packages/contract`. Never return a raw database object; map it to a DTO.
- Read the current time through `deps.now()`; do not scatter `new Date()` through logic.

## 6. Database

- Change structure only through migrations generated by `drizzle-kit generate`. Do not edit a committed migration; create a new migration.
- Integrity rules belong in the database (foreign keys, `UNIQUE`, `CHECK`, `NOT NULL`), not only in code.
- A write across multiple tables uses one transaction.
- Do not `select *` in a query that returns data externally; select only the required columns.

## 7. Web

- Server data goes through TanStack Query. Do not copy it into `useState`.
- Keep local state close to where it is used. Do not add a state-management library until needed.
- One exported component per file. Split components over 150 lines.
- Get colors, font sizes, and radii from tokens in `globals.css`. Do not put raw color values in components.
- Every user-visible string lives in `messages/vi.ts`.
- Clickable elements are real `<button>` or `<a>` elements, have accessible labels, have a minimum 44×44 hit area, and work with the keyboard.
- Member images are always rendered with `MemberShape`. Do not redraw them elsewhere.
- Do not change layout, colors, typography, wording, or behavior from `docs/06-ux-ui/user-flows.md` and the task plan. Ask if the design is missing or impossible.

## 8. Comments

Write a comment when a later reader would ask “why is it done this way?”:

```ts
// Hash before lookup so a malformed cookie simply fails to match,
// instead of reaching the database as raw input.
const tokenHash = sha256Hex(token);
```

Do not write comments that repeat code (`// create session`), leave commented-out code, or add an unowned `TODO`. If code needs a long comment to be understood, rename it or split the function first.

## 9. When to use design patterns

| Situation | Approach |
|---|---|
| One operation has several implementations selected at runtime (for example, multiple splits) | A name-to-function map; every function has the same signature |
| An external dependency must be replaceable (clock, email, database) | Pass it through `deps`; do not import it directly in logic |
| Data has a few mutually exclusive forms (for example, `ok`, `needs_input`, `unparsed`) | A discriminated union, handled with an exhaustive `switch` |
| One operation has multiple steps that must all succeed | One service function with one transaction |
| Logic repeats in three or more places | Extract a shared function beside its callers |

Do not use a class when a function is enough. Do not build intermediate layers (a repository per table, factory, or dependency container) without a concrete task need.

## 10. Money

- Money is an integer in the smallest unit (VND: đồng), represented as `bigint` in the database.
- All division and rounding of money lives only in `packages/core`. The API calls `core`; the web app displays the number returned by the API.
- Do not use floating-point division, `toFixed`, or `Math.round` on money elsewhere.
- Display formatting is `150.000 đ`, done in one web function.
