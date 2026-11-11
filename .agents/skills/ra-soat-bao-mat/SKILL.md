---
name: ra-soat-bao-mat
description: Use before reporting any code change complete in Sòng Phẳng and when reviewing code. Security checklist for API, database, sessions, web, and configuration; every relevant item must be checked against the actual diff, not memory.
---

# Security review

Run this on the current change's diff (`git diff` or `git show`). For every relevant item, open and inspect the exact code; do not answer “looks fine” from memory. Skip items unrelated to the change.

If you find an issue, fix it when it is in task scope; otherwise record it under “Out of scope” in the report. If you are unsure whether something is safe, stop and ask.

## 1. Secrets and configuration

- [ ] No password, key, session token, or real connection string exists in code, configuration, or committed files. Run `git diff --cached` and read every added line.
- [ ] `.env` is not committed; `.env.example` contains only fake or local-only values.
- [ ] New environment variables are declared in the configuration schema and included in `.env.example`.
- [ ] Passwords, session tokens, cookies, `Authorization` headers, and entire request bodies are not logged.

## 2. Input data

- [ ] Every used request body, path parameter, query parameter, and header passes through a Zod schema before reaching logic.
- [ ] Strings have length limits; numbers have range limits; arrays have item-count limits.
- [ ] IDs from the client are checked to belong to the calling user's group or user, not merely to exist.
- [ ] No client value is used as a column name, table name, file path, or system command.

## 3. Authentication and sessions

- [ ] Authenticated endpoints use `requireUser` middleware. Public endpoints are intentional and documented in the API specification.
- [ ] Session tokens are generated with `node:crypto`, are at least 32 bytes, and are stored only as hashes.
- [ ] Session cookies have `HttpOnly`, `SameSite=Lax`, `Path=/`, and `Secure` in production.
- [ ] Logout, password changes, and password resets invalidate the sessions that must be invalidated.
- [ ] Development-only paths (`/dev/*`) do not exist when `APP_ENV=production`.
- [ ] Passwords are hashed only with a password-specific algorithm through a library; do not implement it or use SHA/MD5 for passwords.
- [ ] Secret comparisons use constant-time comparison (`timingSafeEqual`) or lookup by hash.

## 4. Authorization

- [ ] Every endpoint with `groupId` passes through shared authorization middleware with the minimum role required by the API specification.
- [ ] A person outside the group receives 404; a group member without permission receives 403.
- [ ] No query reads group data without a `group_id` condition.
- [ ] Group-owner-only operations are checked on the server, not merely hidden in the web UI.

## 5. Database

- [ ] Every query uses Drizzle or parameters. No SQL string is concatenated from variables.
- [ ] A write across multiple tables is inside one transaction.
- [ ] New integrity constraints (unique, foreign key, `CHECK`) are in a migration, not only in code.

## 6. Responses and errors

- [ ] Error responses contain no stack trace, SQL, file path, or table name.
- [ ] Responses do not return extra fields: no `tokenHash`, `passwordHash`, another group's email, or internal columns.
- [ ] Registration, login, and password reset do not reveal whether an email has an account.
- [ ] Enumeration-prone endpoints (login, registration, email sending, invitation lookup) have rate limits when required by the specification.

## 7. Web

- [ ] No `dangerouslySetInnerHTML`, `eval`, `new Function`, or HTML constructed from strings.
- [ ] Parameter-based redirects (`next`, `redirect`) accept only internal paths: exactly one leading `/` and no `\`.
- [ ] External links opened in a new tab have `rel="noopener noreferrer"`.
- [ ] Session tokens, passwords, and sensitive data are not stored in `localStorage` or `sessionStorage`.
- [ ] Write requests go to the same-origin API; origin checks are not disabled on the server.

## 8. Dependencies

- [ ] No new library was added without approval.
- [ ] `pnpm audit --prod` reports no new high or critical vulnerability caused by this change. If it does, report it; do not upgrade a major version yourself.
- [ ] The dependency lockfile (`pnpm-lock.yaml`) is committed with the change.

## Add to the report

Add one line to “Exercise results”:

```
Security review: checked relevant items <numbers>; <“no issues found” or issues and how they were handled>
```
