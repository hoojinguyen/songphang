# Sòng Phẳng — Phase 7 Implementation Plan — Overview

> **For the implementation agent:** read `AGENTS.md`, the spec, `../2026-11-15-common.md`, then this file. Work through the stage files in order without stopping between tasks.

**Goal:** Everything that must be true before strangers use the product: an identity and a landing page, recorded consent and personal-data rights, limits against abuse, alerts and verified backups, and a security self-audit with a brief for an independent reviewer.

**Architecture:** Additions around the existing system: static pages in the web app; a consent gate as one API middleware; one limits module; an `ErrorReporter` interface; operator commands as scripts in `packages/db`; documents under `docs/security/` and `docs/runbooks/`.

**Tech Stack:** unchanged. **No new library.**

**Spec:** `docs/superpowers/specs/2026-11-15-phase-7-public-release-design.md`

**Prompt placeholders:** `<SPEC>` the spec above; `<PLAN>` `docs/superpowers/plans/2026-11-15-phase-7`; `<BRANCH>` `phase-7`; `<LAST TASK>` `7E.3`.

## Stage files

| Order | File | Tasks | Adds |
|---|---|---|---|
| 0 | `../2026-11-15-common.md` | 0 | Re-baseline |
| 1 | `7a-7b-identity-and-data.md` | 7A.1–7A.2, 7B.1–7B.4 | Landing page, legal pages, consent, export, retention |
| 2 | `7c-7e-limits-ops-security.md` | 7C.1–7C.3, 7D.1–7D.3, 7E.1–7E.3 | Limits, operator commands, alerts, backup checks, audit |

## Constraints for this phase

- **Requires the server step.** If `infra/compose.prod.yml` is absent, stop after the re-baseline and record why; this is the one case where a run stops.
- The legal texts come from the advisor. You place them, you do not write or reword them. Where a text describes a feature of a phase that is not merged, leave the text unchanged and list the mismatch under "Not verified" for the advisor.
- The landing and legal pages make no request to any third party and set no cookie.
- An alert, a log line and an `admin_log` row never contain an email address, a name, an amount, a request body or a header value.
- Operator scripts are run on the server by the owner. They take no input from the network.
- Files you may write under `docs/`: the run files, `docs/security/self-audit.md`, `docs/security/review-brief.md`, `docs/runbooks/recovery.md`, `docs/runbooks/incident.md`.
- Features of unmerged phases are skipped where a task says "needs phase N".

## Review Focus

1. **The consent gate has a hole.** A gated account reaches group data through some route the middleware does not cover. → 7B.2.
2. **An export containing someone else's data.** → 7B.3.
3. **A limit or the signup brake reveals whether an email has an account.** → 7C.1.
4. **A retention job deletes the wrong rows.** → 7B.4.
5. **An alert that leaks personal data, or floods.** → 7D.1.
