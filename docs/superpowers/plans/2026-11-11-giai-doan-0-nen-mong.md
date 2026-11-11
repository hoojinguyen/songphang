# Sòng Phẳng — Giai đoạn 0: Nền móng trên máy local — Implementation Plan

> **For the implementation agent:** read the root `AGENTS.md` first. Execute each task using the `execute-task` skill (`.agents/skills/execute-task/SKILL.md`). Use checkboxes (`- [ ]`) to track steps. The project does not write automated tests; every task ends with exercising the change and a manual-check list for the project owner.

**Goal:** Chạy một lệnh trên máy local, mở `localhost`, chọn "Minh" ở trang đăng nhập thử và thấy màn hình danh sách nhóm trống đúng thiết kế G + E.

**Architecture:** Monorepo pnpm gồm một API Hono độc lập và một web Next.js mỏng; web gọi API qua cùng origin nhờ rewrite `/api/*`. Phiên đăng nhập là một dòng trong Postgres, cookie chỉ mang mã ngẫu nhiên; trang đăng nhập thử tạo phiên bằng đúng hàm mà đăng nhập thật sẽ dùng ở mốc 1B. Không có máy chủ, tên miền, OAuth hay dịch vụ gửi thư trong giai đoạn này.

**Tech Stack:** TypeScript, Node.js ≥ 24, pnpm workspaces, Hono + `@hono/zod-openapi`, Zod, PostgreSQL 17 (Docker), Drizzle ORM + drizzle-kit, Next.js (App Router) + React, TanStack Query, Tailwind CSS v4, Biome.

**Spec:** `docs/07-roadmap.md` (mục "Giai đoạn 0"), `docs/04-sad.md` (mục 4, 5, 7), `docs/04-adr.md`, `docs/05-api-spec.md` (mục 1), `docs/05-database-design.md` (mục 1, bảng `users`, `sessions`), `docs/06-ux-ui/user-flows.md` (mục 6, 7), `docs/03-srs.md` (FR-1.2, FR-1.3, NFR-1.6, NFR-1.8, NFR-1.11), `docs/agents/quy-uoc-code.md`.

## Global Constraints

- Mọi luật trong `AGENTS.md` áp dụng cho mọi task.
- **Thư viện được phép** (bản ổn định mới nhất). Ngoài danh sách này phải hỏi trước:
  - Gốc: `typescript`, `@biomejs/biome`.
  - `packages/db`: `drizzle-orm`, `postgres`, `uuidv7`; dev: `drizzle-kit`, `tsx`.
  - `packages/contract`: `zod`, `@hono/zod-openapi`.
  - `apps/api`: `hono`, `@hono/node-server`, `@hono/zod-openapi`; dev: `tsx`.
  - `apps/web`: `next`, `react`, `react-dom`, `@tanstack/react-query`, `zod`; dev: `tailwindcss`, `@tailwindcss/postcss`, và các gói `@types/*` tương ứng.
- Không cài thư viện test; không tạo file `*.test.*` hay `*.spec.*`.
- Gốc API là `/api/v1`. JSON, tên trường `camelCase`. Thời gian là chuỗi ISO 8601 theo UTC.
- Định dạng lỗi duy nhất: `{ "error": { "code", "message", "details"?, "requestId" } }`. Mã dùng trong giai đoạn này: `VALIDATION_FAILED` (400), `UNAUTHENTICATED` (401), `NOT_FOUND` (404), `INTERNAL` (500).
- Bảng số nhiều, `snake_case`. Khoá chính `id` là UUID phiên bản 7 sinh ở server. Thời gian là `timestamptz` UTC; mọi bảng có `created_at`.
- Cookie phiên: tên `sp_session`, `HttpOnly`, `SameSite=Lax`, `Path=/`, `Secure` khi `APP_ENV=production`. Database chỉ lưu SHA-256 của mã phiên. Phiên sống 30 ngày.
- Cấu hình chỉ đọc từ biến môi trường, kiểm bằng schema khi khởi động.
- Quy tắc phụ thuộc: `apps/web` chỉ phụ thuộc `packages/contract`; `apps/api` phụ thuộc `contract` và `db`. `packages/core` chưa tạo trong giai đoạn này.
- Giao diện tiếng Việt, không emoji. Mọi chuỗi hiển thị nằm trong `apps/web/src/messages/vi.ts`.
- Thiết kế: nền `#F6F2FB`, thẻ `#FFFFFF`, chữ `#1C1B22`, chữ phụ `#5A5766`, nhấn `#FFD84D`; phông Be Vietnam Pro (400–900); không viền, không đổ bóng; vùng chạm tối thiểu 44×44.
- Cổng: web `3000`, API `4000`, Postgres trên máy `54329`.
- `pnpm check` = `biome check . && pnpm -r typecheck`. Phải qua trước mỗi commit.

## Review Focus

Năm tình huống dễ hỏng mà đặc tả không nói thẳng. Mỗi cái có bước tự chạy thử trong task tương ứng; người review sẽ chạy lại.

1. **Trang đăng nhập thử lọt ra production.** Với `APP_ENV=production`, mọi đường dẫn `/api/v1/dev/*` phải trả 404, kể cả khi `DEV_LOGIN=true`. → Task 4.
2. **Cookie phiên rác hoặc hết hạn.** API trả 401 `UNAUTHENTICATED`, không phải 500; web đưa về trang đăng nhập rồi quay lại đúng trang đang xem (FR-1.3). → Task 4, Task 6.
3. **Postgres bị tắt.** `/api/v1/health` trả 503 với `db: "down"` trong vài giây, không treo và không làm sập tiến trình. → Task 3.
4. **Chạy `pnpm dev` lần thứ hai.** Migration và seed chạy lại không tạo người dùng trùng và không báo lỗi. → Task 1, Task 7.
5. **Thiếu hoặc sai biến môi trường.** API từ chối khởi động với thông báo nêu đúng tên biến. → Task 3.

---

## File Structure

```
package.json                  script gốc: dev, check, typecheck, build, db:*
pnpm-workspace.yaml
tsconfig.base.json
biome.json
docker-compose.yml            chỉ có dịch vụ db
.env.example
.gitignore
README.md
packages/
  db/
    src/schema.ts             bảng users, sessions
    src/client.ts             createDb
    src/migrate.ts            runMigrations
    src/seed.ts               DEV_USERS, seedDevUsers
    src/index.ts
    drizzle/                  migration sinh bởi drizzle-kit
    drizzle.config.ts
  contract/
    src/error.ts              ErrorCode, ErrorResponse
    src/health.ts             HealthResponse
    src/auth.ts               UserDto, MeResponse, DevUsersResponse, DevLoginRequest
    src/index.ts
apps/
  api/
    src/config.ts             loadConfig
    src/app.ts                createApp
    src/errors.ts             AppError, bộ xử lý lỗi
    src/routes/health.ts
    src/routes/me.ts
    src/routes/auth.ts        logout
    src/routes/dev.ts         chỉ gắn khi bật đăng nhập thử
    src/auth/sessions.ts      createSession, findSessionUser, deleteSession, sessionCookieAttributes
    src/auth/middleware.ts    requireUser
    src/server.ts             điểm khởi động
  web/
    next.config.ts            rewrite /api/*
    src/app/layout.tsx
    src/app/providers.tsx
    src/app/globals.css       token màu
    src/app/page.tsx          danh sách nhóm (trạng thái trống)
    src/app/dev-login/page.tsx
    src/components/ui/MemberShape.tsx
    src/components/ui/Button.tsx
    src/components/ui/Card.tsx
    src/lib/api.ts            apiFetch, ApiError
    src/lib/session.ts        useMe, useLogout, loginPath, safeNext
    src/lib/dev-shapes.ts     devShapeFor
    src/messages/vi.ts
```

---

### Task 1: Khung monorepo và gói `db`

**Files:**
- Create: `package.json`, `pnpm-workspace.yaml`, `tsconfig.base.json`, `biome.json`, `docker-compose.yml`, `.env.example`, `.gitignore`
- Create: `packages/db/package.json`, `packages/db/tsconfig.json`, `packages/db/drizzle.config.ts`, `packages/db/src/schema.ts`, `packages/db/src/client.ts`, `packages/db/src/migrate.ts`, `packages/db/src/seed.ts`, `packages/db/src/index.ts`

**Interfaces:**
- Consumes: không có.
- Produces (xuất từ `@songphang/db`):
  - `users`, `sessions` — bảng Drizzle.
  - `type Db` — kiểu của client Drizzle.
  - `createDb(url: string): { db: Db; close(): Promise<void> }`
  - `runMigrations(url: string): Promise<void>` — chạy lại nhiều lần an toàn.
  - `DEV_USERS: ReadonlyArray<{ email: string; name: string }>` — đúng bốn phần tử theo thứ tự: Minh `minh@dev.songphang.local`, Lan `lan@dev.songphang.local`, Hùng `hung@dev.songphang.local`, Thu `thu@dev.songphang.local`.
  - `seedDevUsers(db: Db): Promise<void>` — chèn theo thứ tự của `DEV_USERS`, bỏ qua email đã có, đặt `email_verified_at = now()`.
  - Script gốc: `check`, `typecheck`, `db:migrate`, `db:seed`.

Cấu trúc bảng:

| Bảng | Cột |
|---|---|
| `users` | `id uuid PK`, `email text NOT NULL`, `email_verified_at timestamptz`, `name text NOT NULL` (1–50 ký tự, `CHECK`), `avatar_url text`, `created_at`, `updated_at`; chỉ mục duy nhất trên `lower(email)` |
| `sessions` | `id uuid PK`, `user_id uuid NOT NULL FK users ON DELETE CASCADE`, `token_hash text NOT NULL UNIQUE`, `expires_at timestamptz NOT NULL`, `user_agent text`, `created_at`, `last_seen_at` |

- [ ] **Step 1: Tạo các file gốc và khởi tạo git**

`pnpm-workspace.yaml` khai báo `apps/*` và `packages/*`. `package.json` gốc: `"private": true`, `"packageManager"` theo bản pnpm đang cài, `"engines": { "node": ">=24" }`. Gói con có tiền tố `@songphang/`. `tsconfig.base.json` bật `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `verbatimModuleSyntax`. `biome.json` dùng bộ quy tắc khuyến nghị, cấm `any` tường minh và non-null assertion. `.gitignore` có `node_modules`, `.env`, `.next`, `dist`.

`docker-compose.yml` có một dịch vụ `db`: image `postgres:17`, cổng `54329:5432`, user, mật khẩu và database đều là `songphang`, volume `songphang_pgdata`, healthcheck bằng `pg_isready`.

`.env.example`:

```
APP_ENV=development
DATABASE_URL=postgres://songphang:songphang@localhost:54329/songphang
API_PORT=4000
WEB_ORIGIN=http://localhost:3000
DEV_LOGIN=true
```

Run: `git init && pnpm install`
Expected: cài xong không lỗi.

- [ ] **Step 2: Viết `schema.ts`, `client.ts`, `migrate.ts`, `seed.ts`, `index.ts`**

Driver là `postgres` (postgres.js). UUID v7 sinh bằng gói `uuidv7`. `seedDevUsers` dùng `ON CONFLICT DO NOTHING` trên chỉ mục `lower(email)`. Script `db:migrate` và `db:seed` đọc `DATABASE_URL` từ `.env` (dùng `node --env-file` hoặc `tsx --env-file`).

- [ ] **Step 3: Sinh migration**

Run: `pnpm --filter @songphang/db exec drizzle-kit generate`
Expected: một file SQL trong `packages/db/drizzle/` tạo hai bảng, chỉ mục duy nhất trên `lower(email)` và ràng buộc `CHECK` độ dài tên.

- [ ] **Step 4: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 5: Tự chạy thử**

Run: `cp .env.example .env && docker compose up -d --wait db && pnpm db:migrate && pnpm db:seed && pnpm db:seed`
Expected: cả bốn lệnh thoát mã 0; lần seed thứ hai không báo lỗi.

Run: `docker compose exec db psql -U songphang -c "select name, email, email_verified_at is not null as verified from users order by created_at, id"`
Expected: đúng bốn dòng theo thứ tự Minh, Lan, Hùng, Thu; cột `verified` đều là `t`.

Run: `docker compose exec db psql -U songphang -c "insert into users (id, email, name) values (gen_random_uuid(), 'MINH@dev.songphang.local', 'X')"`
Expected: lỗi vi phạm ràng buộc duy nhất.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(repo): khung monorepo va goi db voi users, sessions"
```

**Kiểm tay cho chủ dự án**
1. Chạy `docker compose ps` → dịch vụ `db` ở trạng thái `healthy`.
2. Chạy câu `select` ở Step 5 → thấy bốn người, đúng thứ tự.
3. Chạy `pnpm db:seed` thêm một lần rồi chạy lại câu `select` → vẫn bốn người.

---

### Task 2: Gói `contract`

**Files:**
- Create: `packages/contract/package.json`, `packages/contract/tsconfig.json`, `packages/contract/src/error.ts`, `packages/contract/src/health.ts`, `packages/contract/src/auth.ts`, `packages/contract/src/index.ts`

**Interfaces:**
- Consumes: không có.
- Produces (xuất từ `@songphang/contract`; mỗi schema Zod kèm kiểu suy ra cùng tên):
  - `ErrorCode` = `"VALIDATION_FAILED" | "UNAUTHENTICATED" | "NOT_FOUND" | "INTERNAL"`
  - `ErrorResponse` = `{ error: { code: ErrorCode; message: string; details?: Record<string, unknown>; requestId: string } }`
  - `HealthResponse` = `{ status: "ok" | "degraded"; db: "ok" | "down" }`
  - `UserDto` = `{ id: string (uuid); email: string; name: string; avatarUrl: string | null }`
  - `MeResponse` = `{ user: UserDto }`
  - `DevUsersResponse` = `{ users: UserDto[] }`
  - `DevLoginRequest` = `{ userId: string (uuid) }`

- [ ] **Step 1: Viết các schema**

Nhập `z` từ `@hono/zod-openapi` để schema mang metadata OpenAPI; gọi `.openapi("<Tên>")` trên mỗi schema xuất ra. `avatarUrl` là bắt buộc và cho phép `null` (không phải tuỳ chọn).

- [ ] **Step 2: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 3: Tự chạy thử**

Run: `pnpm --filter @songphang/contract exec tsx -e "import('./src/index.ts').then(m => console.log(m.DevLoginRequest.safeParse({userId:'minh'}).success, m.ErrorResponse.safeParse({error:{code:'UNAUTHENTICATED',message:'x',requestId:'r'}}).success, m.MeResponse.safeParse({user:{id:'0193a1b2-0000-7000-8000-000000000001',email:'a@b.c',name:'Minh'}}).success))"`
Expected: `false true false`

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(contract): schema loi, health, nguoi dung, dang nhap thu"
```

**Kiểm tay cho chủ dự án:** task này không có gì để nhìn; kết quả của nó được kiểm qua Task 3 và Task 4.

---

### Task 3: API — cấu hình, khung ứng dụng, health, định dạng lỗi

**Files:**
- Create: `apps/api/package.json`, `apps/api/tsconfig.json`, `apps/api/src/config.ts`, `apps/api/src/errors.ts`, `apps/api/src/app.ts`, `apps/api/src/routes/health.ts`, `apps/api/src/server.ts`

**Interfaces:**
- Consumes: `createDb`, `runMigrations`, `Db` từ `@songphang/db`; `HealthResponse`, `ErrorResponse`, `ErrorCode` từ `@songphang/contract`.
- Produces:
  - `type Config = { appEnv: "development" | "production"; databaseUrl: string; apiPort: number; webOrigin: string; devLogin: boolean }`
  - `loadConfig(env: Record<string, string | undefined>): Config` — ném `Error` có thông điệp liệt kê tên từng biến sai hoặc thiếu. `devLogin` là `true` chỉ khi `DEV_LOGIN === "true"` **và** `APP_ENV !== "production"`.
  - `class AppError extends Error { constructor(status: number, code: ErrorCode, message: string, details?: Record<string, unknown>) }`
  - `type AppDeps = { config: Config; db: Db; now: () => Date }`
  - `createApp(deps: AppDeps): OpenAPIHono` — gắn mọi route dưới `/api/v1`; sinh `requestId` (UUID v7) cho mỗi yêu cầu, đặt vào header `X-Request-Id` và vào thân lỗi; phục vụ `/api/v1/openapi.json`.
  - Script: `pnpm --filter @songphang/api dev` (tự nạp lại khi sửa), `start`.

Hành vi:

| Tình huống | Phản hồi |
|---|---|
| `GET /api/v1/health`, database trả lời `select 1` trong 2 giây | 200 `{ "status": "ok", "db": "ok" }` |
| `GET /api/v1/health`, database không trả lời trong 2 giây hoặc lỗi | 503 `{ "status": "degraded", "db": "down" }` |
| Đường dẫn không khớp route nào | 404 `NOT_FOUND` theo định dạng lỗi chung |
| Thân yêu cầu không qua schema | 400 `VALIDATION_FAILED`, `details` liệt kê theo trường |
| `AppError` | Mã trạng thái và mã lỗi của nó |
| Lỗi không lường trước | 500 `INTERNAL`, thông điệp chung, không lộ chi tiết; log đầy đủ kèm `requestId` |

- [ ] **Step 1: Viết `config.ts`, `errors.ts`, `routes/health.ts`, `app.ts`, `server.ts`**

`loadConfig` kiểm bằng Zod và gom mọi lỗi vào một thông điệp. `server.ts` gọi `loadConfig(process.env)`, `runMigrations`, `createDb`, rồi phục vụ bằng `@hono/node-server` ở `apiPort`; nếu `loadConfig` ném lỗi thì in thông điệp và thoát mã 1.

- [ ] **Step 2: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 3: Tự chạy thử — đường bình thường**

Run: `pnpm --filter @songphang/api dev`, rồi ở cửa sổ khác:

`curl -si localhost:4000/api/v1/health`
Expected: `HTTP/1.1 200`, có header `X-Request-Id`, thân `{"status":"ok","db":"ok"}`.

`curl -s localhost:4000/api/v1/khong-co`
Expected: `{"error":{"code":"NOT_FOUND","message":…,"requestId":…}}` với mã 404.

`curl -s localhost:4000/api/v1/openapi.json`
Expected: JSON có `paths` chứa `/api/v1/health`.

- [ ] **Step 4: Tự chạy thử — Postgres bị tắt (Review Focus 3)**

Run: `docker compose stop db`, rồi `time curl -si localhost:4000/api/v1/health`
Expected: `HTTP/1.1 503`, thân `{"status":"degraded","db":"down"}`, trả về trong dưới 5 giây; tiến trình API vẫn sống.

Run: `docker compose start db`, chờ vài giây, gọi lại health.
Expected: trở lại 200 mà không cần khởi động lại API.

- [ ] **Step 5: Tự chạy thử — biến môi trường sai (Review Focus 5)**

Run: `DATABASE_URL= pnpm --filter @songphang/api start; echo "exit=$?"`
Expected: một dòng lỗi có chữ `DATABASE_URL`; `exit=1`.

Run: `API_PORT=abc pnpm --filter @songphang/api start; echo "exit=$?"`
Expected: một dòng lỗi có chữ `API_PORT`; `exit=1`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(api): cau hinh, health, dinh dang loi, openapi"
```

**Kiểm tay cho chủ dự án**
1. Chạy `pnpm --filter @songphang/api dev`, mở `http://localhost:4000/api/v1/health` trên trình duyệt → thấy `{"status":"ok","db":"ok"}`.
2. Mở `http://localhost:4000/api/v1/abc` → thấy JSON lỗi có `"code":"NOT_FOUND"`.
3. Chạy `docker compose stop db`, tải lại trang health → thấy `"db":"down"` sau vài giây. Chạy `docker compose start db`, tải lại → trở về `"ok"`.

---

### Task 4: API — phiên, đăng nhập thử, `/me`, đăng xuất

**Files:**
- Create: `apps/api/src/auth/sessions.ts`, `apps/api/src/auth/middleware.ts`, `apps/api/src/routes/dev.ts`, `apps/api/src/routes/me.ts`, `apps/api/src/routes/auth.ts`
- Modify: `apps/api/src/app.ts` (gắn route; chỉ gắn `dev` khi `config.devLogin`)

**Interfaces:**
- Consumes: `createApp`, `AppDeps`, `AppError`, `Config` (Task 3); `users`, `sessions`, `Db` (Task 1); `UserDto`, `MeResponse`, `DevUsersResponse`, `DevLoginRequest` (Task 2).
- Produces:
  - `SESSION_COOKIE = "sp_session"`, `SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000`
  - `createSession(db: Db, input: { userId: string; now: Date; userAgent?: string }): Promise<{ token: string; expiresAt: Date }>` — `token` là 32 byte từ `node:crypto` mã hoá base64url; database lưu SHA-256 dạng hex.
  - `findSessionUser(db: Db, token: string, now: Date): Promise<UserDto | null>` — trả `null` với mã không tồn tại, sai định dạng, hoặc hết hạn.
  - `deleteSession(db: Db, token: string): Promise<void>`
  - `sessionCookieAttributes(appEnv: Config["appEnv"]): { httpOnly: true; sameSite: "Lax"; path: "/"; secure: boolean; maxAge: number }` — `secure` là `true` chỉ khi `appEnv === "production"`; `maxAge` là `SESSION_TTL_MS / 1000`.
  - `requireUser` — middleware Hono; đọc header `Authorization: Bearer <mã>` trước, rồi cookie `sp_session`; đặt `c.var.user: UserDto`; không có thì ném `AppError(401, "UNAUTHENTICATED", …)`.

Endpoint:

| Phương thức | Đường dẫn | Điều kiện | Phản hồi |
|---|---|---|---|
| GET | `/api/v1/dev/users` | Chỉ tồn tại khi `config.devLogin` | 200 `DevUsersResponse`, sắp theo `created_at, id` |
| POST | `/api/v1/dev/login` | Chỉ tồn tại khi `config.devLogin`; thân `DevLoginRequest` | 204 kèm `Set-Cookie`; `userId` không có thì 404; sai định dạng thì 400 |
| GET | `/api/v1/me` | `requireUser` | 200 `MeResponse` |
| POST | `/api/v1/auth/logout` | `requireUser` | 204, xoá phiên và xoá cookie |

`createSession` là hàm mà đăng nhập Google và đăng nhập bằng mật khẩu ở mốc 1B sẽ gọi lại. Không file nào ngoài `routes/dev.ts` biết đến khái niệm "đăng nhập thử".

- [ ] **Step 1: Viết `sessions.ts`, `middleware.ts`, ba file route; gắn vào `app.ts`**

`findSessionUser` băm mã nhận được rồi tìm theo `token_hash`, nên chuỗi rác chỉ đơn giản là không khớp. Cookie được đặt bằng đúng các thuộc tính `sessionCookieAttributes` trả về. Thời gian hiện tại lấy từ `deps.now()`.

- [ ] **Step 2: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 3: Tự chạy thử — đường bình thường**

Với API đang chạy:

`curl -s localhost:4000/api/v1/dev/users`
Expected: bốn người theo thứ tự Minh, Lan, Hùng, Thu; mỗi người có `id`, `email`, `name`, `avatarUrl: null`.

Lấy `id` của Minh, rồi: `curl -si -c /tmp/sp.txt -X POST localhost:4000/api/v1/dev/login -H 'content-type: application/json' -d '{"userId":"<id của Minh>"}'`
Expected: `204`; header `Set-Cookie: sp_session=…; Max-Age=2592000; Path=/; HttpOnly; SameSite=Lax` và **không** có `Secure`.

`curl -s -b /tmp/sp.txt localhost:4000/api/v1/me`
Expected: `{"user":{…"name":"Minh"…}}`.

`curl -s -H "Authorization: Bearer <giá trị sp_session>" localhost:4000/api/v1/me`
Expected: cùng kết quả.

`docker compose exec db psql -U songphang -c "select token_hash from sessions"`
Expected: chuỗi 64 ký tự hex, khác với giá trị cookie.

- [ ] **Step 4: Tự chạy thử — cookie sai và đăng xuất (Review Focus 2)**

Mỗi lệnh sau phải trả 401 với `"code":"UNAUTHENTICATED"`, không phải 500:

- `curl -si localhost:4000/api/v1/me`
- `curl -si -H 'cookie: sp_session=khong-phai-ma-phien' localhost:4000/api/v1/me`
- `curl -si -H 'cookie: sp_session=' localhost:4000/api/v1/me`
- `curl -si -H "cookie: sp_session=$(printf 'a%.0s' {1..5000})" localhost:4000/api/v1/me`

Phiên hết hạn: `docker compose exec db psql -U songphang -c "update sessions set expires_at = now() - interval '1 minute'"`, rồi `curl -si -b /tmp/sp.txt localhost:4000/api/v1/me`
Expected: 401.

Đăng nhập lại, rồi `curl -si -b /tmp/sp.txt -X POST localhost:4000/api/v1/auth/logout`, rồi `curl -si -b /tmp/sp.txt localhost:4000/api/v1/me`
Expected: 204, sau đó 401.

Dữ liệu sai: `curl -si -X POST localhost:4000/api/v1/dev/login -H 'content-type: application/json' -d '{"userId":"minh"}'`
Expected: 400 `VALIDATION_FAILED`.

`curl -si -X POST localhost:4000/api/v1/dev/login -H 'content-type: application/json' -d '{"userId":"0193a1b2-0000-7000-8000-00000000ffff"}'`
Expected: 404 `NOT_FOUND`.

- [ ] **Step 5: Tự chạy thử — production (Review Focus 1)**

Dừng API, chạy `APP_ENV=production DEV_LOGIN=true pnpm --filter @songphang/api start`, rồi:

`curl -si localhost:4000/api/v1/dev/users` và `curl -si -X POST localhost:4000/api/v1/dev/login -H 'content-type: application/json' -d '{}'`
Expected: cả hai trả 404.

Chạy lại với `DEV_LOGIN=false` ở chế độ development.
Expected: cả hai vẫn trả 404.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(api): phien dang nhap, dang nhap thu, me, dang xuat"
```

**Kiểm tay cho chủ dự án**
1. Mở `http://localhost:4000/api/v1/dev/users` → thấy bốn người Minh, Lan, Hùng, Thu.
2. Mở `http://localhost:4000/api/v1/me` khi chưa đăng nhập → thấy lỗi `UNAUTHENTICATED`.
3. Chạy lệnh đăng nhập ở Step 3 rồi lệnh gọi `/me` với `-b /tmp/sp.txt` → thấy tên Minh.
4. Chạy lệnh đăng xuất rồi gọi lại `/me` → thấy lỗi `UNAUTHENTICATED`.
5. Khởi động API với `APP_ENV=production`, mở `/api/v1/dev/users` → thấy lỗi `NOT_FOUND`.

---

### Task 5: Web — khung Next.js, token thiết kế, thành phần giao diện

**Files:**
- Create: `apps/web/package.json`, `apps/web/tsconfig.json`, `apps/web/next.config.ts`, `apps/web/postcss.config.mjs`, `apps/web/src/app/layout.tsx`, `apps/web/src/app/globals.css`, `apps/web/src/messages/vi.ts`, `apps/web/src/components/ui/MemberShape.tsx`, `apps/web/src/components/ui/Button.tsx`, `apps/web/src/components/ui/Card.tsx`
- Create (tạm, xoá ở Task 6): `apps/web/src/app/page.tsx` — trang trưng bày các thành phần

**Interfaces:**
- Consumes: không có gói nội bộ nào.
- Produces:
  - Token Tailwind (khai báo bằng `@theme` trong `globals.css`): `--color-bg: #F6F2FB`, `--color-surface: #FFFFFF`, `--color-ink: #1C1B22`, `--color-muted: #5A5766`, `--color-accent: #FFD84D`, `--color-sunken: #E9E4F3`, `--color-mint: #9EEBC0`, `--color-sky: #9CCBFF`, `--color-coral: #FF8A73`, `--color-lilac: #D3B8FF`.
  - `type ShapeCode = "circle" | "diamond" | "squircle" | "leaf"`; `type ColorCode = "mint" | "sky" | "coral" | "lilac"`
  - `MemberShape(props: { shape: ShapeCode; color: ColorCode; size: number; name: string; showInitial?: boolean })` — khung ngoài luôn là `size`×`size`; `role="img"`, `aria-label` bằng `name`; hiện chữ cái đầu của `name` (viết hoa) khi `showInitial !== false` và `size >= 44`.
  - `Button(props: { variant: "primary" | "accent" | "surface"; size?: "md" | "lg" } & ButtonHTMLAttributes<HTMLButtonElement>)` — `primary` nền `ink` chữ trắng, `accent` nền `accent` chữ `ink`, `surface` nền `surface` chữ `ink`; `md` cao 48px, `lg` cao 64px; bo tròn hết cỡ; `type="button"` mặc định; trạng thái `disabled` nền `sunken` chữ `muted`.
  - `Card(props: { tone?: "surface" | "accent" | "sunken"; className?: string; children: ReactNode })` — bo góc 32px, không viền, không bóng.
  - `vi` — đối tượng chuỗi lồng nhau, `as const`; và `t(template: string, vars: Record<string, string>): string` thay `{tên}` bằng giá trị.
  - `next.config.ts` rewrite `/api/:path*` → `${process.env.API_ORIGIN ?? "http://localhost:4000"}/api/:path*`.

Chuỗi trong `vi`:

| Khoá | Giá trị |
|---|---|
| `common.appName` | `Sòng Phẳng` |
| `common.logout` | `Đăng xuất` |
| `common.retry` | `Thử lại` |
| `common.loadError` | `Không tải được. Kiểm tra mạng rồi thử lại.` |
| `devLogin.title` | `Đăng nhập thử` |
| `devLogin.hint` | `Chỉ có ở môi trường phát triển. Chọn một người để vào.` |
| `devLogin.enterAs` | `Vào với tên {name}` |
| `groups.greeting` | `Chào {name}` |
| `groups.title` | `Nhóm của bạn` |
| `groups.emptyTitle` | `Bạn chưa có nhóm nào` |
| `groups.emptyHint` | `Tạo một nhóm rồi gõ khoản chi đầu tiên.` |
| `groups.create` | `Tạo nhóm` |

Hình dạng (kích thước tính theo `size`):

| Mã | Cách vẽ |
|---|---|
| `circle` | Phủ kín khung, `border-radius: 50%` |
| `squircle` | Phủ kín khung, `border-radius: 38%` |
| `diamond` | Hình vuông cạnh `0.72 × size`, `border-radius: 24%`, xoay 45°; chữ bên trong xoay ngược −45° |
| `leaf` | Hình vuông cạnh `0.86 × size`, `border-radius: 50% 10% 50% 10%` |

Chữ cái đầu: `Array.from(name.trim())[0]?.toLocaleUpperCase("vi")`, cỡ chữ `0.36 × size`, độ đậm 900.

- [ ] **Step 1: Khởi tạo ứng dụng Next.js**

App Router, TypeScript, Tailwind v4. Phông Be Vietnam Pro nạp bằng `next/font/google` với độ đậm 400, 500, 600, 700, 800, 900 và tập ký tự `vietnamese`. `layout.tsx` đặt `<html lang="vi">`, nền `bg-bg`, chữ `text-ink`, tiêu đề trang là `common.appName`.

- [ ] **Step 2: Viết `globals.css`, `vi.ts`, `MemberShape`, `Button`, `Card`**

- [ ] **Step 3: Viết trang trưng bày tạm ở `src/app/page.tsx`**

Trang hiện: bốn hình (Minh circle/mint, Lan diamond/sky, Hùng squircle/coral, Thu leaf/lilac) ở ba cỡ 24, 52, 84; ba biến thể `Button` ở hai cỡ, kèm một nút `disabled`; ba tông `Card`.

- [ ] **Step 4: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 5: Tự chạy thử**

Run: `pnpm --filter @songphang/web dev`, mở `http://localhost:3000`.
Expected: trang trưng bày hiện đủ; nền tím nhạt; phông Be Vietnam Pro; hình cỡ 24 không có chữ, cỡ 52 và 84 có chữ cái M, L, H, T; không lỗi trong console của trình duyệt.

Nếu không có công cụ mở trình duyệt, ghi vào mục "Chưa kiểm được" và dán kết quả `curl -s localhost:3000 | grep -o 'role="img"' | wc -l` (phải là 12).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(web): khung Next.js, token G+E, MemberShape, Button, Card"
```

**Kiểm tay cho chủ dự án**
1. Chạy `pnpm --filter @songphang/web dev`, mở `http://localhost:3000` → thấy trang trưng bày.
2. So bốn hình với canvas thiết kế: Minh tròn xanh lá, Lan thoi xanh dương, Hùng vuông bo cam, Thu lá tím.
3. Nút đen, nút vàng, nút trắng đều bo tròn; nút bị khoá có nền xám tím nhạt.
4. Thu nhỏ cửa sổ về bề rộng điện thoại → không có thanh cuộn ngang.

---

### Task 6: Web — đăng nhập thử, danh sách nhóm trống, bảo vệ phiên

**Files:**
- Create: `apps/web/src/lib/api.ts`, `apps/web/src/lib/session.ts`, `apps/web/src/lib/dev-shapes.ts`, `apps/web/src/app/providers.tsx`, `apps/web/src/app/dev-login/page.tsx`
- Modify: `apps/web/src/app/layout.tsx` (bọc `Providers`), `apps/web/src/app/page.tsx` (thay trang trưng bày bằng danh sách nhóm)

**Interfaces:**
- Consumes: `MeResponse`, `DevUsersResponse`, `ErrorResponse`, `UserDto` từ `@songphang/contract`; `MemberShape`, `Button`, `Card`, `vi`, `t`, `ShapeCode`, `ColorCode` (Task 5); các endpoint của Task 4.
- Produces:
  - `class ApiError extends Error { status: number; code: string; requestId: string | null }`
  - `apiFetch<T>(path: string, schema: ZodType<T>, init?: RequestInit): Promise<T>` — gọi `/api/v1${path}` với `credentials: "include"`; phản hồi được kiểm bằng `schema`; phản hồi lỗi ném `ApiError` đọc từ `ErrorResponse`; thân không phải JSON hoặc mất mạng ném `ApiError` với `code: "NETWORK"` và `status: 0`.
  - `apiSend(path: string, init: RequestInit): Promise<void>` — cho yêu cầu trả 204; cùng cách xử lý lỗi.
  - `useMe(): UseQueryResult<UserDto, ApiError>` — khoá truy vấn `["me"]`; không thử lại khi lỗi 401.
  - `useLogout(): UseMutationResult<void, ApiError, void>` — gọi `POST /auth/logout`, xoá cache, chuyển tới `/dev-login`.
  - `loginPath(returnTo: string): string` — trả `/dev-login?next=<đã mã hoá>`.
  - `safeNext(raw: string | null): string` — trả `raw` nếu nó bắt đầu bằng đúng một dấu `/` và không chứa `\`; ngược lại trả `/`.
  - `devShapeFor(index: number): { shape: ShapeCode; color: ColorCode }` — 0 → circle/mint, 1 → diamond/sky, 2 → squircle/coral, 3 → leaf/lilac; lặp theo `index % 4`.

Hành vi màn hình:

| Màn hình | Hành vi |
|---|---|
| `/dev-login` | Tiêu đề `devLogin.title` (độ đậm 900, 32px), dòng `devLogin.hint`; lưới 2 cột, mỗi người một `<button>` gồm `MemberShape` cỡ 84 và tên, `aria-label` là `devLogin.enterAs`; bấm thì `POST /dev/login`, thành công chuyển tới `safeNext(next)`. Đang tải: khung xương. API trả lỗi cho `/dev/users` (kể cả 404 khi đăng nhập thử bị tắt): `common.loadError` và nút `common.retry`. |
| `/` | Đang tải: khung xương. 401: chuyển tới `loginPath("/")`. Lỗi khác: `common.loadError` và nút `common.retry`. Có người dùng: bố cục theo màn hình GE1 — dòng `groups.greeting` (14px, màu `muted`), tiêu đề `groups.title` (độ đậm 900, 32px), ở góc phải một `<button>` chứa hình tròn mint cỡ 52 mang chữ cái đầu, `aria-label` là `common.logout`, bấm để đăng xuất; giữa trang là trạng thái trống: `groups.emptyTitle` (độ đậm 800), `groups.emptyHint` (màu `muted`); đáy trang là `Button` `primary` cỡ `lg` chiếm hết bề ngang với chữ `groups.create`, đang `disabled` (tạo nhóm thuộc mốc 1A). Lề trang 20px; khối nội dung rộng tối đa 430px, căn giữa. |

- [ ] **Step 1: Viết `api.ts`, `session.ts`, `dev-shapes.ts`, `providers.tsx`**

- [ ] **Step 2: Viết trang `/dev-login` và thay trang `/`**

Cả hai là client component. Trang `/dev-login` bọc phần dùng `useSearchParams` trong `Suspense`.

- [ ] **Step 3: `pnpm check`**

Run: `pnpm check`
Expected: không lỗi.

- [ ] **Step 4: Tự chạy thử**

Với API và web đang chạy:

`curl -si localhost:3000/api/v1/health`
Expected: 200 (rewrite hoạt động).

Trên trình duyệt:
1. Mở `http://localhost:3000` khi chưa đăng nhập → được chuyển tới `/dev-login?next=%2F`.
2. Bấm "Minh" → về `/`, thấy "Chào Minh", "Nhóm của bạn", "Bạn chưa có nhóm nào".
3. Tải lại trang → vẫn là Minh.
4. Bấm hình tròn ở góc phải → về `/dev-login`; mở lại `/` → lại bị chuyển về `/dev-login`.
5. Mở `http://localhost:3000/dev-login?next=//example.com`, bấm một người → về `/`, không rời khỏi `localhost`.
6. Dừng API, tải lại `/` → thấy thông điệp lỗi và nút "Thử lại"; không bị chuyển về trang đăng nhập. Bật lại API, bấm "Thử lại" → trang hiện bình thường.

Nếu không có công cụ mở trình duyệt, ghi các bước này vào mục "Chưa kiểm được" và chạy phần kiểm được bằng `curl`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(web): dang nhap thu, danh sach nhom trong, bao ve phien"
```

**Kiểm tay cho chủ dự án**
1. Mở `http://localhost:3000` → tự được đưa tới trang "Đăng nhập thử" có bốn hình.
2. Bấm "Minh" → thấy "Chào Minh" và "Nhóm của bạn"; đặt cạnh màn hình 1 trên canvas: lời chào, tiêu đề và hình tròn chữ M khớp vị trí, cỡ chữ, màu.
3. Nút "Tạo nhóm" màu xám, không bấm được.
4. Mở một cửa sổ ẩn danh, đăng nhập "Lan" → cửa sổ kia vẫn là Minh.
5. Bấm hình tròn chữ M → về trang đăng nhập; bấm nút quay lại của trình duyệt → vẫn không vào được trang nhóm.
6. Dùng phím Tab đi qua bốn nút ở trang đăng nhập thử, nhấn Enter trên một nút → đăng nhập được.

---

### Task 7: Một lệnh khởi động và tài liệu chạy

**Files:**
- Modify: `package.json` (script `dev`, `build`)
- Create: `README.md`

**Interfaces:**
- Consumes: mọi thứ từ Task 1 đến Task 6.
- Produces:
  - `pnpm dev` = `docker compose up -d --wait db && pnpm db:migrate && pnpm db:seed && pnpm -r --parallel dev` (API ở `:4000`, web ở `:3000`).
  - `pnpm build` = build mọi gói có script `build`.

- [ ] **Step 1: Thêm script `dev`, `build` và viết README**

README có ba mục: yêu cầu (Node ≥ 24, pnpm, Docker), chạy lần đầu (`cp .env.example .env`, `pnpm install`, `pnpm dev`, mở `http://localhost:3000`), và các lệnh thường dùng (`pnpm check`, `pnpm build`, `docker compose down`, cách xoá sạch dữ liệu bằng `docker compose down -v`).

- [ ] **Step 2: `pnpm check` và `pnpm build`**

Run: `pnpm check && pnpm build`
Expected: cả hai không lỗi, không cảnh báo về kiểu.

- [ ] **Step 3: Tự chạy thử từ trạng thái sạch (Review Focus 4)**

Run: dừng mọi tiến trình, `docker compose down -v`, rồi `pnpm dev`.
Expected: Postgres lên, migration và seed chạy, API và web khởi động; không có lỗi trong đầu ra.

Run: dừng bằng Ctrl+C, chạy `pnpm dev` lần nữa.
Expected: khởi động lại không lỗi; `curl -s localhost:3000/api/v1/dev/users` vẫn trả đúng bốn người.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(repo): mot lenh khoi dong va README"
```

**Kiểm tay cho chủ dự án — tiêu chí hoàn thành giai đoạn 0**
1. Chạy `docker compose down -v` rồi `pnpm dev` → mọi thứ khởi động không lỗi.
2. Mở `http://localhost:3000`, chọn "Minh" → thấy "Chào Minh", "Nhóm của bạn", "Bạn chưa có nhóm nào", nút "Tạo nhóm" ở đáy; nền tím nhạt, phông Be Vietnam Pro.
3. Dừng rồi chạy lại `pnpm dev`, tải lại trang → vẫn đăng nhập là Minh.
4. Làm theo README trên một cửa sổ terminal mới, không dùng kiến thức nào ngoài README → chạy được.

---

## Ngoài phạm vi của kế hoạch này

Những thứ dưới đây thuộc các mốc sau và không được làm ở đây: nhóm, thành viên, giao dịch và mọi logic tiền (`packages/core`, mốc 1A); đăng nhập Google, đăng ký bằng email và mật khẩu, bảng `user_identities` (mốc 1B); ô gõ nhanh (mốc 1D); Caddy, HTTPS, tên miền, sao lưu, dịch vụ gửi thư (bước "Đưa lên máy chủ"); sinh client Swift và Kotlin từ OpenAPI (giai đoạn 5); giới hạn tần suất (có từ mốc 1B, khi có endpoint đăng nhập thật).
