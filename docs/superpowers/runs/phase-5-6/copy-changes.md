# phase-5-6 — Copy Changes (ADR-044)

Every string added, changed or removed on iOS in this run. Phase 5.9 applies these rows to `apps/web/src/messages/vi.ts`. `apps/ios/Scripts/check-strings.sh` allows a difference only for a key listed in this table.

| Key | Old value | New value | Reason |
|---|---|---|---|
| `ios.feedback.sectionTitle` | (added) | `Âm thanh và rung` | Spec §7.4 & Task 5.6.A.2: Account setting section title |
| `ios.feedback.sound` | (added) | `Âm thanh` | Spec §7.4 & Task 5.6.A.2: Sound toggle label |
| `ios.feedback.haptics` | (added) | `Rung` | Spec §7.4 & Task 5.6.A.2: Haptics toggle label |
| `ios.sheet.discardTitle` | (added) | `Bỏ thay đổi?` | Task 5.6.A.4: Unsaved-changes discard confirmation dialog title |
| `ios.sheet.discardConfirm` | (added) | `Bỏ` | Task 5.6.A.4: Unsaved-changes destructive confirm action |
| `ios.memberPicker.selected` | (added) | `{name}, đã chọn` | Task 5.6.A.5: VoiceOver selected label in `MemberPicker` |
| `ios.copy.announced` | (added) | `Đã sao chép` | Spec §10.3 & Task 5.6.A.6: `CopyButton` VoiceOver announcement and copied state label |
| `ios.groups.createdToast` | (added) | `Đã tạo {name}` | Spec §4.4 & Task 5.6.B.3: Confirmation toast shown after cloning a group |
| `groups.owedToYou` | `đồng bạn được nhận` | `bạn được nhận` | Spec §11.2 & Task 5.6.C.4: Remove redundant `"đồng"` next to formatted `MoneyText` amount on featured group card |
| `groups.youOwe` | `đồng bạn cần trả` | `bạn cần trả` | Spec §11.2 & Task 5.6.C.4: Remove redundant `"đồng"` next to formatted `MoneyText` amount on featured group card |
| `split.unitMoney` | `đồng` | `đ` | Spec §11.2 & Task 5.6.C.4: Replace `"đồng"` unit suffix in split editor with `"đ"` matching `MoneyFormat` |
| `ios.common.clear` | (added) | `Xoá` | Task 5.6.C.4: VoiceOver accessibility label for search clear button in `PersonalLedgerView` |
| `ios.newGroup.namePlaceholder` | (added) | `Đà Lạt cuối tuần` | Spec §11.2 & Task 5.6.C.4: Group name field placeholder in `CreateGroupView` |
