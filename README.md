# Sòng Phẳng

## Requirements

- Node.js 24.7 or later (native Argon2 is required).
- pnpm 11.21.0, matching the root `packageManager` field.
- Docker with Docker Compose installed and the Docker daemon running.
- Available local ports: 3000 for the web app, 4000 for the API, and 54329 for PostgreSQL.

## First run

From the repository root:

```sh
cp .env.example .env
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) and choose the development sign-in link, then Minh.

`pnpm dev` waits for PostgreSQL to become healthy, applies migrations, seeds the four development users, and starts the API and web app. Migrations and seed operations can run repeatedly without creating duplicate users.

Press Ctrl+C to stop the API and web app. PostgreSQL continues running in Docker. Run `pnpm dev` again to restart the application; existing data and valid login sessions are preserved.

Keep `.env` local and out of Git. `.env.example` contains configuration values intended only for local development.

## Common commands

| Command                  | Purpose                                                                          |
| ------------------------ | -------------------------------------------------------------------------------- |
| `pnpm dev`               | Start PostgreSQL, migrate and seed the database, then start the API and web app. |
| `pnpm check`             | Run linting and strict TypeScript checks across the workspace.                   |
| `pnpm build`             | Build every workspace package that defines a `build` script.                     |
| `pnpm db:migrate`        | Apply database migrations; PostgreSQL must be running.                           |
| `pnpm db:check-balances` | Check ledger totals and group balances after changing or importing expenses.     |
| `pnpm db:seed`           | Insert missing development users; PostgreSQL must be running and migrated.       |
| `docker compose down`    | Stop and remove the database container while preserving its data volume.         |

**Reset local data:** stop the application with Ctrl+C, then run:

```sh
docker compose down -v
pnpm dev
```

`docker compose down -v` deletes the local PostgreSQL data volume, including all users and sessions. The next `pnpm dev` creates a fresh database with the four development users. Omit `-v` when you want to preserve data.

## Phase 1 features

- Email/password accounts, verification/reset mail, optional Google sign-in, invite links/QR, roles and live updates.
- Integer-only expense/income/transfer ledgers with equal, exact, weighted and percentage splits, balances and settlements.
- Vietnamese sentence entry, clarification/manual hand-off, version-safe editing, undo/history, group deletion and offline read state.

## Development mail and optional Google sign-in

Mail is printed by the API process to its development console. Read the verification/reset link there and open it locally; no mail delivery service is called. Treat these links as secrets and do not copy them into Git or reports. A production configuration without a real mailer is refused.

`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are optional; keep real values only in the local `.env`. Without both, the Google button/routes are disabled. The local callback is `http://localhost:3000/api/v1/auth/google/callback`. Google sign-in remains unverified until an OAuth app exists and the manual checklist has been completed.

Run `pnpm db:check-balances` after changing ledger data. Success ends with `All groups balanced`.
