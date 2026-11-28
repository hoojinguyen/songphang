# phase-5-6 — Copy Changes (ADR-044)

Every string added, changed or removed on iOS in this run. Phase 5.9 applies these rows to `apps/web/src/messages/vi.ts`. `apps/ios/Scripts/check-strings.sh` allows a difference only for a key listed in this table.

| Key | Old value | New value | Reason |
|---|---|---|---|
| `ios.feedback.sectionTitle` | (added) | `Âm thanh và rung` | Spec §7.4 & Task 5.6.A.2: Account setting section title |
| `ios.feedback.sound` | (added) | `Âm thanh` | Spec §7.4 & Task 5.6.A.2: Sound toggle label |
| `ios.feedback.haptics` | (added) | `Rung` | Spec §7.4 & Task 5.6.A.2: Haptics toggle label |
| `ios.sheet.discardTitle` | (added) | `Bỏ thay đổi?` | Task 5.6.A.4: Unsaved-changes discard confirmation dialog title |
| `ios.sheet.discardConfirm` | (added) | `Bỏ` | Task 5.6.A.4: Unsaved-changes destructive confirm action |
