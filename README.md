# Sòng Phẳng

## Requirements

- Node.js 24 or later.
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

Open [http://localhost:3000](http://localhost:3000) and select Minh to view the empty groups screen.

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
