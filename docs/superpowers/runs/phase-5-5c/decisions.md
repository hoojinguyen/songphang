# phase-5-5c — Run Decisions

## Earlier Phases on `main` (`ba2bfb4`)

- Phase 0–4, Phase 5 (iOS), Wave 5.5A (UI/UX v2 & Cross-group foundation), and Wave 5.5B (Settlement proofs, Vault, cycles & sharing, PR #4) are all merged on `main`.
- No tasks in Wave 5.5C are skipped.

## Re-baseline

| Plan's name | Real name and location | Status |
|---|---|---|
| `packages/core/src/{split,split-items,settlements,notification-text,index}.ts` | Same paths | Exists |
| `packages/db/src/{schema-groups,schema-transactions,reminders,groups,members,fund,index}.ts` | Same paths | Exists |
| `packages/db/drizzle.config.ts` | Same path | Exists (migrations `0000`..`0032` present) |
| `packages/contract/src/{transaction,error,jobs,member,group,balance,member-breakdown,guest-link,overview,index}.ts` & `openapi.json` | Same paths | Exists |
| `apps/api/src/app.ts`, `routes/transactions.ts`, `services/*` | Same paths | Exists |
| `apps/worker/src/{main,mail-templates}.ts` | Same paths | Exists |
| `apps/web/src/messages/vi.ts`, `lib/*`, `components/*`, `app/g/[groupId]/*` | Same paths | Exists |
| `apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings` | Same path | Exists |
| `apps/ios/SongPhangKit/Sources/Domain/Models/AppError.swift` | `apps/ios/SongPhangKit/Sources/Domain/AppError.swift` | Moved one level up in `Domain/` (noted for Stage 5.5C.3) |
| All other `apps/ios/` paths listed in `5-5c-3-ios.md` | Same paths | Exists |
| `docs/04-adr.md`, `docs/superpowers/plans/2026-11-15-common.md` | Same paths | Exists |

## Baseline Failures

- None. All baseline checks (`pnpm check`, `pnpm contract:check`, `pnpm build`, `./apps/ios/Scripts/check-strings.sh`, `xcrun swift-format lint --strict --recursive apps/ios`, Simulator Debug `xcodebuild`, and disposable-DB smoke check) passed on `2b556de`.
