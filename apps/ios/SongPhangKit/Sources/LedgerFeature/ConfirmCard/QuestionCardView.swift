import DesignSystem
public import Domain
public import SwiftUI

public struct QuestionCardView: View {
  private let groupId: ExpenseGroup.ID
  private let initialReading: QuickEntryReading
  private let members: [Member]
  private let transactionsRepository: any TransactionsRepository
  private let isDisabled: Bool
  private let onEdit: (QuickEntryReading) -> Void
  private let onSave: (QuickEntryReading) -> Void

  @State private var selectedIds: [Member.ID] = []
  @State private var descriptionText: String
  @State private var previewShares: [MemberAmount]?
  @State private var previewWarnings: [TransactionWarning] = []
  @State private var isPreviewing = false
  @State private var previewError = false

  public init(
    groupId: ExpenseGroup.ID,
    reading: QuickEntryReading,
    members: [Member],
    transactionsRepository: any TransactionsRepository,
    isDisabled: Bool = false,
    onEdit: @escaping (QuickEntryReading) -> Void,
    onSave: @escaping (QuickEntryReading) -> Void
  ) {
    self.groupId = groupId
    self.initialReading = reading
    self.members = members
    self.transactionsRepository = transactionsRepository
    self.isDisabled = isDisabled
    self.onEdit = onEdit
    self.onSave = onSave
    self._descriptionText = State(initialValue: reading.draft.description ?? "")
    self._previewShares = State(initialValue: reading.shares)
  }

  private var countIssue: QuickEntryReading.Issue? {
    initialReading.issues.first(where: { $0.code == .countMismatch })
  }

  private var ambiguousIssue: QuickEntryReading.Issue? {
    initialReading.issues.first(where: { $0.code == .memberAmbiguous })
  }

  private var isDescriptionMissing: Bool {
    initialReading.issues.contains(where: { $0.code == .descriptionMissing })
  }

  private var isComplete: Bool {
    if ambiguousIssue != nil && selectedIds.count != 1 {
      return false
    }
    if let countIssue, selectedIds.count != (countIssue.count ?? 0) {
      return false
    }
    if isDescriptionMissing
      && descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return false
    }
    return true
  }

  private var effectiveReading: QuickEntryReading {
    let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
    let resolvedDescription =
      isDescriptionMissing
      ? (trimmedDescription.isEmpty ? nil : trimmedDescription)
      : initialReading.draft.description

    let resolvedSplit: SplitSpec? = {
      if let countIssue {
        guard selectedIds.count == (countIssue.count ?? 0) else { return nil }
        let orderedIds = members.filter { selectedIds.contains($0.id) }.map(\.id)
        return .equal(members: orderedIds)
      }
      return initialReading.draft.split
    }()

    let ready = isComplete && previewShares != nil && !isPreviewing && !previewError
    return QuickEntryReading(
      status: ready ? .ok : .needsInput,
      text: initialReading.text,
      draft: QuickEntryReading.Draft(
        description: resolvedDescription,
        amount: initialReading.draft.amount,
        payers: initialReading.draft.payers,
        split: resolvedSplit,
        category: initialReading.draft.category,
        categoryId: initialReading.draft.categoryId
      ),
      shares: isComplete ? previewShares : initialReading.shares,
      spans: initialReading.spans,
      issues: ready ? [] : initialReading.issues,
      reader: initialReading.reader,
      moreDrafts: initialReading.moreDrafts
    )
  }

  public var body: some View {
    let effective = effectiveReading
    let neededCount = countIssue?.count ?? 0
    let saveButtonLabel: String? =
      (countIssue != nil && selectedIds.count < neededCount)
      ? L10n.t("compose.chooseMore", ["count": String(neededCount - selectedIds.count)])
      : nil
    let ready = effective.status == .ok

    ConfirmationCardView(
      reading: effective,
      members: members,
      isDisabled: isDisabled || !ready,
      isBudgetOver: ready && previewWarnings.contains(.budgetOver),
      saveLabel: saveButtonLabel,
      onEdit: { onEdit(effective) },
      onSave: { onSave(effective) }
    ) {
      VStack(alignment: .leading, spacing: 12) {
        if let ambiguousIssue {
          let candidates = members.filter { ambiguousIssue.candidates.contains($0.id) }
          let word = sliceText(
            initialReading.text,
            start: ambiguousIssue.start,
            end: ambiguousIssue.end
          )
          ChoicePanelView(
            members: candidates,
            selectedIds: selectedIds,
            targetCount: 1,
            title: word.isEmpty
              ? L10n.tr("compose.whoPaid")
              : L10n.t("compose.whichMember", ["word": word]),
            reason: word.isEmpty
              ? L10n.tr("compose.nothingSaved")
              : L10n.t("compose.memberReason", ["word": word]),
            onToggle: { id in
              selectedIds = [id]
            }
          )
        } else if let countIssue {
          let candidates = members.filter {
            $0.kind == .person && countIssue.candidates.contains($0.id)
          }
          let activeTotal = members.filter { $0.active && $0.kind == .person }.count
          let target = countIssue.count ?? 0
          ChoicePanelView(
            members: candidates,
            selectedIds: selectedIds,
            targetCount: target,
            title: L10n.t("compose.whichPeople", ["count": String(target)]),
            reason: L10n.t("compose.countReason", ["total": String(activeTotal)]),
            onToggle: { id in
              if selectedIds.contains(id) {
                selectedIds.removeAll { $0 == id }
              } else if selectedIds.count < target {
                selectedIds.append(id)
              }
            }
          )
        }

        if isDescriptionMissing && ambiguousIssue == nil {
          SPTextField(
            label: L10n.tr("compose.descriptionPrompt"),
            text: $descriptionText
          )
        }

        if previewError {
          Text(L10n.tr("common.loadError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
        }
      }
    }
    .onChange(of: selectedIds) { _, _ in
      Task { await updatePreviewIfComplete() }
    }
    .onChange(of: descriptionText) { _, _ in
      Task { await updatePreviewIfComplete() }
    }
  }

  private func updatePreviewIfComplete() async {
    guard isComplete else { return }
    let current = effectiveReading
    guard let amount = current.draft.amount,
      let split = current.draft.split
    else { return }
    let description = current.draft.description ?? L10n.tr("expenseForm.title")
    let draft = TransactionDraft.split(
      TransactionDraft.SplitPayload(
        isIncome: false,
        description: description,
        amount: amount,
        occurredAt: "2026-11-16T15:00:00.000Z",
        category: current.draft.category,
        categoryId: current.draft.categoryId,
        payers: current.draft.payers,
        split: split
      )
    )
    isPreviewing = true
    previewError = false
    defer { isPreviewing = false }
    do throws(AppError) {
      let preview = try await transactionsRepository.preview(groupId: groupId, draft: draft)
      previewShares = preview.shares
      previewWarnings = preview.warnings
    } catch {
      previewError = true
    }
  }

  private func sliceText(_ text: String, start: Int, end: Int) -> String {
    let chars = Array(text)
    guard start >= 0, end <= chars.count, start < end else { return "" }
    return String(chars[start..<end])
  }
}

private struct ChoicePanelView: View {
  let members: [Member]
  let selectedIds: [Member.ID]
  let targetCount: Int
  let title: String
  let reason: String
  let onToggle: (Member.ID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
        Spacer()
        Text(
          L10n.t(
            "compose.chosen",
            [
              "selected": String(selectedIds.count),
              "count": String(targetCount),
            ]
          )
        )
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
      }

      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
        spacing: 8
      ) {
        ForEach(members) { member in
          let isSelected = selectedIds.contains(member.id)
          let isDisabled =
            targetCount != 1
            && selectedIds.count >= targetCount
            && !isSelected

          Button {
            onToggle(member.id)
          } label: {
            VStack(spacing: 4) {
              MemberShapeView(
                shape: member.shape,
                color: member.color,
                name: member.name,
                size: 52
              )
              Text(member.name)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
              RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                  isSelected ? Tokens.ink : Color.clear,
                  lineWidth: 3
                )
            )
            .opacity(isDisabled ? 0.5 : 1.0)
          }
          .buttonStyle(.plain)
          .disabled(isDisabled)
        }
      }

      Text(reason)
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
    }
    .padding(16)
    .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
  }
}
