import DesignSystem
public import Domain
public import SwiftUI

struct RecurringFormSheetView: View {
  let members: [Member]
  let editing: RecurringExpense?
  let isPending: Bool
  let error: AppError?
  let onSaveCreate: (CreateRecurringExpenseInput) async -> Void
  let onSaveUpdate: (RecurringExpense.ID, UpdateRecurringExpenseInput) async -> Void
  let onDismiss: () -> Void

  @State private var descriptionText: String
  @State private var amountText: String
  @State private var mode: RecurringMode
  @State private var frequency: RecurringFrequency
  @State private var dayOfWeek: Int
  @State private var dayOfMonth: Int
  @State private var monthOfYear: Int
  @State private var payerId: Member.ID?
  @State private var sharerIds: [Member.ID]

  init(
    members: [Member],
    editing: RecurringExpense?,
    isPending: Bool,
    error: AppError?,
    onSaveCreate: @escaping (CreateRecurringExpenseInput) async -> Void,
    onSaveUpdate: @escaping (RecurringExpense.ID, UpdateRecurringExpenseInput) async -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.members = members
    self.editing = editing
    self.isPending = isPending
    self.error = error
    self.onSaveCreate = onSaveCreate
    self.onSaveUpdate = onSaveUpdate
    self.onDismiss = onDismiss

    let activePeople = members.filter { $0.active && $0.kind == .person }
    let activePayers = activePeople + members.filter { $0.active && $0.kind == .fund }

    self._descriptionText = State(initialValue: editing?.description ?? "")
    self._amountText = State(
      initialValue: editing?.amount.map { MoneyFormat.amount($0) } ?? ""
    )
    self._mode = State(initialValue: editing?.mode ?? .fixed)
    self._frequency = State(initialValue: editing?.frequency ?? .monthly)
    self._dayOfWeek = State(initialValue: editing?.dayOfWeek ?? 1)
    self._dayOfMonth = State(initialValue: editing?.dayOfMonth ?? 1)
    self._monthOfYear = State(initialValue: editing?.monthOfYear ?? 1)
    self._payerId = State(
      initialValue: editing?.payersTemplate.first?.memberId ?? activePayers.first?.id
    )
    let defaultSharers = Self.participantIds(from: editing?.splitTemplate) ?? activePeople.map(\.id)
    self._sharerIds = State(initialValue: defaultSharers)
  }

  private static func participantIds(from split: SplitSpec?) -> [Member.ID]? {
    guard let split else { return nil }
    switch split {
    case .equal(let members, _, _), .exact(let members, _, _, _, _):
      return members
    case .shares(let entries, _, _):
      return entries.map(\.memberId)
    case .percent(let entries, _, _):
      return entries.map(\.memberId)
    case .items(let items, _, _):
      return Array(Set(items.flatMap(\.memberIds)))
    }
  }

  private var activePeople: [Member] {
    members.filter { $0.active && $0.kind == .person }
  }

  private var payerOptions: [Member] {
    activePeople + members.filter { $0.active && $0.kind == .fund }
  }

  private var parsedAmount: Money? {
    let digits = amountText.filter { $0.isWholeNumber && $0.isASCII }
    guard !digits.isEmpty else { return nil }
    return MoneyFormat.parseInput(digits)
  }

  private var canSave: Bool {
    guard !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      payerId != nil,
      !sharerIds.isEmpty,
      !isPending
    else { return false }
    if mode == .fixed {
      return parsedAmount?.isPositive == true
    }
    return true
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("recurring.titleLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            TextField(
              L10n.tr("expenseForm.descriptionPlaceholder"),
              text: $descriptionText
            )
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          }

          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("recurring.modeLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            Picker("", selection: $mode) {
              Text(L10n.tr("recurring.modeFixed")).tag(RecurringMode.fixed)
              Text(L10n.tr("recurring.modeVariable")).tag(RecurringMode.variable)
            }
            .pickerStyle(.segmented)
          }

          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("recurring.amountLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            HStack(spacing: 6) {
              TextField(
                "0",
                text: Binding(
                  get: { amountText },
                  set: { next in
                    let digits = next.filter { $0.isWholeNumber && $0.isASCII }
                    if digits.isEmpty {
                      amountText = ""
                    } else if let parsed = MoneyFormat.parseInput(digits) {
                      amountText = MoneyFormat.amount(parsed)
                    }
                  }
                )
              )
              .keyboardType(.numberPad)
              .font(Typography.sectionTitle)
              .foregroundStyle(Tokens.ink)

              Text(L10n.tr("common.currency"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.muted)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          }

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("recurring.frequencyLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                  let selected = frequency == freq
                  Button {
                    frequency = freq
                  } label: {
                    Text(freqTitle(freq))
                      .font(Typography.captionBold)
                      .foregroundStyle(selected ? Tokens.surface : Tokens.ink)
                      .padding(.horizontal, 12)
                      .frame(minHeight: 36)
                      .background(selected ? Tokens.ink : Tokens.surface, in: Capsule())
                  }
                  .buttonStyle(.plain)
                }
              }
            }

            if frequency == .weekly {
              Stepper(value: $dayOfWeek, in: 1...7) {
                Text("\(L10n.tr("recurring.dayOfWeekLabel")): \(dayOfWeekLabel(dayOfWeek))")
                  .font(Typography.subheadline)
              }
            } else {
              Stepper(value: $dayOfMonth, in: 1...31) {
                Text("\(L10n.tr("recurring.dayOfMonthLabel")): \(dayOfMonth)")
                  .font(Typography.subheadline)
              }
              if frequency == .yearly {
                Stepper(value: $monthOfYear, in: 1...12) {
                  Text("\(L10n.tr("recurring.monthOfYearLabel")): \(monthOfYear)")
                    .font(Typography.subheadline)
                }
              }
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("recurring.payerLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(payerOptions) { member in
                  let selected = payerId == member.id
                  Button {
                    payerId = member.id
                  } label: {
                    Text(member.name)
                      .font(Typography.captionBold)
                      .foregroundStyle(selected ? Tokens.surface : Tokens.ink)
                      .padding(.horizontal, 12)
                      .frame(minHeight: 36)
                      .background(selected ? Tokens.ink : Tokens.surface, in: Capsule())
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("recurring.splitLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(activePeople) { member in
                  let selected = sharerIds.contains(member.id)
                  Button {
                    if selected {
                      sharerIds.removeAll { $0 == member.id }
                    } else {
                      sharerIds.append(member.id)
                    }
                  } label: {
                    Text(member.name)
                      .font(Typography.captionBold)
                      .foregroundStyle(selected ? Tokens.surface : Tokens.ink)
                      .padding(.horizontal, 12)
                      .frame(minHeight: 36)
                      .background(selected ? Tokens.ink : Tokens.surface, in: Capsule())
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }

          if let error {
            Text(
              error == .recurringMemberInactive
                ? L10n.tr("recurring.pausedMemberInvalid")
                : L10n.tr("common.saveError")
            )
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
          }

          SPButton(
            L10n.tr("recurring.saveAction"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: !canSave,
            isPending: isPending
          ) {
            Task { await submit() }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(
        editing == nil
          ? L10n.tr("recurring.createTitle")
          : L10n.tr("recurring.editTitle")
      )
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L10n.tr("common.cancel"), action: onDismiss)
        }
      }
    }
  }

  private func submit() async {
    guard let payerId else { return }
    let trimmed = String(
      descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
    let split = SplitSpec.equal(members: sharerIds)
    let payers = [RecurringPayerTemplateEntry(memberId: payerId, amount: nil)]
    let resolvedAmount =
      (mode == .variable && parsedAmount?.isPositive != true) ? nil : parsedAmount
    let dow = frequency == .weekly ? dayOfWeek : nil
    let dom = frequency != .weekly ? dayOfMonth : nil
    let moy = frequency == .yearly ? monthOfYear : nil

    if let editing {
      await onSaveUpdate(
        editing.id,
        UpdateRecurringExpenseInput(
          mode: mode,
          description: trimmed,
          amount: resolvedAmount.map { .set($0) } ?? .clear,
          payersTemplate: payers,
          splitTemplate: split,
          frequency: frequency,
          dayOfWeek: dow.map { .set($0) } ?? .clear,
          dayOfMonth: dom.map { .set($0) } ?? .clear,
          monthOfYear: moy.map { .set($0) } ?? .clear
        )
      )
    } else {
      await onSaveCreate(
        CreateRecurringExpenseInput(
          mode: mode,
          description: trimmed,
          amount: resolvedAmount,
          payersTemplate: payers,
          splitTemplate: split,
          frequency: frequency,
          dayOfWeek: dow,
          dayOfMonth: dom,
          monthOfYear: moy
        )
      )
    }
  }

  private func freqTitle(_ freq: RecurringFrequency) -> String {
    switch freq {
    case .weekly: return L10n.tr("recurring.freqWeekly")
    case .monthly: return L10n.tr("recurring.freqMonthly")
    case .quarterly: return L10n.tr("recurring.freqQuarterly")
    case .yearly: return L10n.tr("recurring.freqYearly")
    case .unknown(let raw): return raw
    }
  }

  private func dayOfWeekLabel(_ day: Int) -> String {
    switch day {
    case 1: return "Thứ 2"
    case 2: return "Thứ 3"
    case 3: return "Thứ 4"
    case 4: return "Thứ 5"
    case 5: return "Thứ 6"
    case 6: return "Thứ 7"
    default: return "Chủ nhật"
    }
  }
}
