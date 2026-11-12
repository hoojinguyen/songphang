# Phase 1 run — decisions

Written by the implementation agent. One entry for every decision the spec and the plan did not make. The advisor reads this file first during review; the project owner confirms or changes each entry afterwards.

Entry format:

```
## D<number> — <short title> (task <id>)
Problem: …
Options: …
Choice: …
Reason: …
```

A new library adds: License, Maintenance, Added size.


## D1 — Safe accumulated money (task 1A.1)
Problem: Safe individual inputs can produce unsafe totals when accumulated.
Options: Accumulate as numbers; accumulate as BigInt and check the final number range.
Choice: BigInt for sums and pair netting, with RangeError for unsafe outputs; reject empty IDs as invalid identifiers.
Reason: Preserve exact integer money without silently rounding an accumulated result.

## D2 — Offline workspace installation (task 1A.1)
Problem: The task requests pnpm install while external services are forbidden.
Options: Contact the package registry; use the local package store offline.
Choice: Run pnpm install --offline and do not run the network-backed pnpm audit.
Reason: This package adds no dependencies; the run must not contact external services.

## D3 — Retain ledger authorship when accounts are deleted (task 1A.2)
Problem: Nullable created_by/updated_by foreign keys must allow account deletion while preserving ledger history.
Options: Default restrictive foreign keys; ON DELETE SET NULL.
Choice: SET NULL for group and transaction authors.
Reason: The approved account-deletion requirement retains members and transactions.

## D4 — Link existing dependency-free workspace without registry access (task 1A.3)
Problem: pnpm exec previously auto-installed and installation can trigger registry metadata lookups.
Options: Run package-manager install; add the workspace dependency, its deterministic lockfile link and local node_modules symlink directly.
Choice: Add only the local core workspace link manually.
Reason: No external dependency resolution is needed or allowed.

## D5 — Preserve source-extension imports for web contract (task 1A.7)
Problem: Browser compilation cannot resolve the .js exports added to the source-only contract package in earlier API tasks.
Options: Add bundler aliases; follow phase-0 .ts imports in contract.
Choice: Use .ts extensions throughout contract imports/exports, matching existing exports.
Reason: Source-only workspace exports must resolve in both Next.js and Node/tsx without new configuration.

## D6 — Split new-group member rows (task 1A.7)
Problem: The creation page exceeds 150 lines when the ordered member list is inline.
Options: Keep the oversized page; extract the member list beside the existing group components.
Choice: Add NewGroupMembers.tsx in the approved groups directory and keep the page responsible for submission.
Reason: Separate member editing from screen loading and submission without a new abstraction layer.
