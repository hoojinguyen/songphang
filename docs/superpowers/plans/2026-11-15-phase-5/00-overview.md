# Sòng Phẳng Phase 5 (iOS) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for the continuous phase run described in AGENTS.md §12. Use the project's execute-task and security-review skills for each implementation task. Track the checkboxes in the run record.
>
> **Status (2026-11-19):** The owner approved the design at `d40c649` and this plan at `eac8aa7`. Antigravity owns implementation. Codex owns advisor review. The owner owns acceptance and merge.

**Goal:** Deliver the shared iOS/web expense-splitting journey on a local iPhone Simulator after 5B, then bring iOS to feature parity with the web and prepare Release for owner-led TestFlight verification.

**Architecture:** Evolve the existing 5U SwiftUI app under `apps/ios/`. The API owns permissions and all official money values. The Swift package isolates OpenAPI-generated types, transport, Keychain and snapshots behind the existing domain protocols. AppShell composes live repositories for the default Debug run and Release.

**Tech stack:** Swift 6, SwiftUI, iOS 26 minimum, Apple Swift OpenAPI Generator/Runtime/URLSession, system Apple/Google authentication surfaces, existing Hono/Zod/PostgreSQL/worker stack.

**Spec:** [Phase 5 design](../../specs/2026-11-15-phase-5-ios-design.md), [iOS architecture](../../specs/2026-11-16-ios-codebase-architecture-design.md), [5U handoff](../../runs/ios-ui/progress.md) and [common phase rules](../2026-11-15-common.md).

## Global Constraints

- One repository and one branch, `phase-5`, created by the advisor after authorization. The workstation baseline at planning is `d40c649`, based on the Phase 4 merge `22a16fb`.
- No automated tests, test libraries or committed acceptance assertion scripts. Exercises are manual UI, shell and HTTP operations. Document actual observations and scrub credentials, auth codes and personal data from evidence.
- Use disposable databases and storage directories with local adapters. No real provider calls, account creation outside local fixtures, deployment, archive, upload, or push by the agent. Real AI verification stays deferred until all phases including iOS are done.
- Keep v1 additive. Preserve existing cookie clients, role rules, request/response shapes and Zod validation. Outsiders receive 404 for group resources. The only new dependencies in this plan are the three Apple OpenAPI packages. Pin the resolved stable versions.
- Keep money as integer đồng. Split previews, countable approval state, balances, funds and QR payloads come from the server. Preserve idempotency per create form and edit version checks.
- Keep the module graph of the architecture design. No generated DTOs or credentials in feature targets. SwiftUI views use the existing Vietnamese web copy and one String Catalog. Preserve Dynamic Type, VoiceOver, Reduce Motion and native navigation.
- `apps/ios/AGENTS.md` governs edits inside iOS. Cross-stack work is bounded by each task's Files section. Advisor owns standing-document amendments. The run agent records needed corrections and evidence for review.
- The run progresses under AGENTS.md §12. The 5B owner handoff is a pinned, independently reproducible checkpoint. Its owner acceptance can be recorded at that revision or during the final replay. Follow up on all findings before final owner acceptance.

## Review Focus

| Risk | Owning exercise |
|---|---|
| Late reads or events revive data from a revoked session or removed group | 5B.1–5B.4: revoke or remove while requests and SSE are active, then relaunch and switch accounts. |
| A generated client fails on a new value or drives a destructive action using an unknown enum | 5A.1 and 5B.2: exercise compatible additions in a scratch snapshot and unknown-value decoding in the live mapping path. |
| Ledger differs between iOS and web after retry, stale edit, approval or a settlement | 5B.4–5B.5, 5D.1 and 5D.6: compare API snapshots, transaction IDs and role-specific outcomes. |
| A provider callback, notification or link crosses a session or group boundary | 5C.1–5C.6 and 5D.7: exercise replay, foreign links, device/session loss, and wrong-session Telegram confirmation. |
| Green builds hide missing journeys or unavailable external checks | Task 0 and 5E.2: reconcile every baseline row against evidence, reporting local and external results independently. |

## Files and stage order

| Order | Plan | Tasks and owned work |
|---|---|---|
| 0–5A | [5a-api.md](5a-api.md) | Task 0 inventories live API, web and 5U. 5A.1–5A.3 own the route-registry snapshot, feature version metadata, sessions and API gate. |
| 5B | [5b-5e-app.md](5b-5e-app.md) | 5B.1–5B.5 own the native client, core live screens and **early Simulator ↔ web acceptance**. |
| 5C | [5c-integrations.md](5c-integrations.md) | 5C.1–5C.6 own Google and Apple sign-in, push device/worker/app, and native invite delivery with associated domains. |
| 5D–5E | [5b-5e-app.md](5b-5e-app.md) | 5D.1–5D.7 own Phase 2–4 parity, including receipt capture. 5E.1–5E.2 own Release, the owner runbook and **final parity acceptance**. |

**Handoff inputs:** `<SPEC>` = `docs/superpowers/specs/2026-11-15-phase-5-ios-design.md`; `<PLAN>` = this directory; `<BRANCH>` = `phase-5`; `<LAST TASK>` = `5E.2`. Run artifacts live in `docs/superpowers/runs/phase-5/`. Use the common prompt with this stage table and the Phase 5 Task 0 below.

**Advisor work:** After owner authorization, create the phase branch and initial run records. Own the spec §9 amendments to ADR-014/029/030/032, API spec, database design, SRS and root agent rules. Mark additions as planned until verified and reconcile the standing docs with the reviewed implementation before merge.

## Verification and evidence

- Per task, run `pnpm check`. For Swift changes run the two iOS commands below and compile existing previews in Debug. Exercise the task locally, run security-review where code changes, and record reproduction, observations and exact failures in `progress.md`. Commit the task and its evidence together.
- At each stage boundary, run `pnpm check`, `pnpm build`, the iOS Debug build and lint, the complete route/role matrix for the current route inventory, the acceptance replay for every earlier merged phase and completed stage, capability-off checks and `pnpm db:check-balances` (expected `All groups balanced`). Keep expected refusals separate from gate failures. Follow AGENTS.md §12 on failed gates. Report the exact omitted cases if prior evidence cannot be replayed.
- Use the same evidence schema at each stage: stage and SHA, fixture and commands, expected and observed results, route/role and journey coverage counts, screenshots and performance recordings, issues and verification gaps. Record actual iOS results from 5B onward for the architecture §8.3 measures on a 500-transaction fixture. When a trace cannot be captured on Simulator, include the tool output. Do not infer first-content time from an executable-load interval.
- The 5B handoff belongs in `handoff-5b.md`, with screenshots under `screens/5b/`. The full parity inventory belongs in `parity-matrix.md`. The final handoff in `manual-checks.md` identifies the tested revision, local pass/fail, owner-only checks and an owner result field.

```sh
xcodebuild -project apps/ios/SongPhang.xcodeproj -scheme SongPhang \
  -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun swift-format lint --strict --recursive apps/ios
```
