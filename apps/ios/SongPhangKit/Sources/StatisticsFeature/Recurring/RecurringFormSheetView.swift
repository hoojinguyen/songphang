import DesignSystem
public import Domain
public import SwiftUI

private enum RecurringSplitMethod: String, CaseIterable {
  case equal
  case shares
  case percent
  case exact
  case items

  var label: String {
    switch self {
    case .equal: return L10n.tr("split.modeEqual")
    case .shares: return L10n.tr("split.modeShares")
    case .percent: return L10n.tr("split.modePercent")
    case .exact: return L10n.tr("split.modeExact")
    case .items: return L10n.tr("split.methodItems")
    }
  }
}

struct RecurringFormSheetView: View {
  let members: [Member]
  let editing: RecurringExpense?
  let isPending: Bool
  let error: AppError?
  let onSaveCreate: (CreateRecurringExpenseInput) async -> Void
  let onSaveUpdate: (RecurringExpense.ID, UpdateRecurringExpenseInput) async -> Void
  let onDismiss: () -> Void

  private let initialDescriptionText: String
  private let initialAmountText: String
  private let initialMode: RecurringMode
  private let initialFrequency: RecurringFrequency
  private let initialDayOfWeek: Int
  private let initialDayOfMonth: Int
  private let initialMonthOfYear: Int
  private let initialPayerIds: [Member.ID]
  private let initialPayerAmountsText: [Member.ID: String]
  private let initialSplitMethod: RecurringSplitMethod
  private let initialSharerIds: [Member.ID]
  private let initialMemberValues: [Member.ID: String]

  @State private var descriptionText: String
  @State private var amountText: String
  @State private var mode: RecurringMode
  @State private var frequency: RecurringFrequency
  @State private var dayOfWeek: Int
  @State private var dayOfMonth: Int
  @State private var monthOfYear: Int
  @State private var payerIds: [Member.ID]
  @State private var payerAmountsText: [Member.ID: String]
  @State private var splitMethod: RecurringSplitMethod
  @State private var sharerIds: [Member.ID]
  @State private var memberValues: [Member.ID: String]

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

    let initDescription = editing?.description ?? ""
    let initAmount = editing?.amount.map { MoneyFormat.amount($0) } ?? ""
    let initMode = editing?.mode ?? .fixed
    let initFreq = editing?.frequency ?? .monthly
    let initDow = editing?.dayOfWeek ?? 1
    let initDom = editing?.dayOfMonth ?? 1
    let initMoy = editing?.monthOfYear ?? 1

    self.initialDescriptionText = initDescription
    self.initialAmountText = initAmount
    self.initialMode = initMode
    self.initialFrequency = initFreq
    self.initialDayOfWeek = initDow
    self.initialDayOfMonth = initDom
    self.initialMonthOfYear = initMoy

    self._descriptionText = State(initialValue: initDescription)
    self._amountText = State(initialValue: initAmount)
    self._mode = State(initialValue: initMode)
    self._frequency = State(initialValue: initFreq)
    self._dayOfWeek = State(initialValue: initDow)
    self._dayOfMonth = State(initialValue: initDom)
    self._monthOfYear = State(initialValue: initMoy)

    let initialPayers = editing?.payersTemplate.map(\.memberId) ?? []
    let resolvedPayerIds =
      !initialPayers.isEmpty
      ? initialPayers
      : (activePayers.first.map { [$0.id] } ?? [])
    self.initialPayerIds = resolvedPayerIds
    self._payerIds = State(initialValue: resolvedPayerIds)
    let initialPayerAmounts = Dictionary(
      uniqueKeysWithValues: (editing?.payersTemplate ?? []).compactMap { entry in
        entry.amount.map { (entry.memberId, MoneyFormat.amount($0)) }
      }
    )
    self.initialPayerAmountsText = initialPayerAmounts
    self._payerAmountsText = State(initialValue: initialPayerAmounts)

    let initialMethod = Self.method(from: editing?.splitTemplate)
    self.initialSplitMethod = initialMethod
    self._splitMethod = State(initialValue: initialMethod)
    let defaultSharers = Self.participantIds(from: editing?.splitTemplate) ?? activePeople.map(\.id)
    self.initialSharerIds = defaultSharers
    self._sharerIds = State(initialValue: defaultSharers)
    let initValues = Self.initialValues(from: editing?.splitTemplate)
    self.initialMemberValues = initValues
    self._memberValues = State(initialValue: initValues)
  }

  private var isDirty: Bool {
    descriptionText != initialDescriptionText
      || amountText != initialAmountText
      || mode != initialMode
      || frequency != initialFrequency
      || dayOfWeek != initialDayOfWeek
      || dayOfMonth != initialDayOfMonth
      || monthOfYear != initialMonthOfYear
      || payerIds != initialPayerIds
      || payerAmountsText != initialPayerAmountsText
      || splitMethod != initialSplitMethod
      || sharerIds != initialSharerIds
      || memberValues != initialMemberValues
  }

  private static func method(from split: SplitSpec?) -> RecurringSplitMethod {
    guard let split else { return .equal }
    switch split {
    case .equal: return .equal
    case .shares: return .shares
    case .percent: return .percent
    case .exact: return .exact
    case .items: return .items
    }
  }

  private static func initialValues(from split: SplitSpec?) -> [Member.ID: String] {
    guard let split else { return [:] }
    switch split {
    case .equal, .items:
      return [:]
    case .shares(let entries, _, _):
      return Dictionary(uniqueKeysWithValues: entries.map { ($0.memberId, $0.weight) })
    case .percent(let entries, _, _):
      return Dictionary(uniqueKeysWithValues: entries.map { ($0.memberId, $0.percent) })
    case .exact(_, let entries, _, _, _):
      return Dictionary(
        uniqueKeysWithValues: entries.map { ($0.memberId, MoneyFormat.amount($0.amount)) }
      )
    }
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

  private var displayedPayerOptions: [Member] {
    let activeIds = Set(payerOptions.map(\.id))
    let inactiveSelected = members.filter { !activeIds.contains($0.id) && payerIds.contains($0.id) }
    return payerOptions + inactiveSelected
  }

  private var displayedSharerOptions: [Member] {
    let activeIds = Set(activePeople.map(\.id))
    let inactiveSelected = members.filter {
      !activeIds.contains($0.id) && sharerIds.contains($0.id)
    }
    return activePeople + inactiveSelected
  }

  private var availableSplitMethods: [RecurringSplitMethod] {
    if mode == .variable {
      return [.equal, .shares, .percent]
    }
    if editing?.splitTemplate != nil, case .items = editing?.splitTemplate {
      return [.equal, .shares, .percent, .exact, .items]
    }
    return [.equal, .shares, .percent, .exact]
  }

  private var parsedAmount: Money? {
    let digits = amountText.filter { $0.isWholeNumber && $0.isASCII }
    guard !digits.isEmpty else { return nil }
    return MoneyFormat.parseInput(digits)
  }

  private var canSave: Bool {
    guard !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !payerIds.isEmpty,
      !sharerIds.isEmpty,
      !isPending
    else { return false }
    let activeMemberIds = Set(members.filter(\.active).map(\.id))
    guard payerIds.allSatisfy({ activeMemberIds.contains($0) }),
      sharerIds.allSatisfy({ activeMemberIds.contains($0) })
    else { return false }
    if mode == .fixed {
      guard let total = parsedAmount, total.isPositive else { return false }
      if payerIds.count > 1 {
        let sum = payerIds.reduce(Money.zero) { acc, id in
          acc + (MoneyFormat.parseInput(payerAmountsText[id] ?? "") ?? .zero)
        }
        guard
          payerIds.allSatisfy({
            (MoneyFormat.parseInput(payerAmountsText[$0] ?? "")?.isPositive) == true
          }),
          sum == total
        else { return false }
      }
    }
    return buildSplitSpec() != nil
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
            .onChange(of: mode) { _, next in
              if next == .variable {
                if payerIds.count > 1 {
                  payerIds = Array(payerIds.prefix(1))
                }
                if splitMethod == .exact || splitMethod == .items {
                  splitMethod = .equal
                }
              }
            }
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
              .monospacedDigit()
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
                      .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
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
            let inactivePayerIds = Set(
              displayedPayerOptions.filter { !$0.active }.map(\.id)
            )
            MemberPicker(
              title: L10n.tr("recurring.payerLabel"),
              members: displayedPayerOptions,
              selection: Binding(
                get: { Set(payerIds) },
                set: { next in
                  let ordered = displayedPayerOptions.map(\.id).filter { next.contains($0) }
                  if mode == .variable {
                    if let first = ordered.first(where: { !payerIds.contains($0) })
                      ?? ordered.first,
                      displayedPayerOptions.first(where: { $0.id == first })?.active == true
                    {
                      payerIds = [first]
                    } else if ordered.isEmpty
                      && payerIds.allSatisfy({ inactivePayerIds.contains($0) })
                    {
                      payerIds = []
                    }
                  } else {
                    let activeOrdered = ordered.filter { id in
                      displayedPayerOptions.first(where: { $0.id == id })?.active == true
                        || payerIds.contains(id)
                    }
                    let clearedOnlyInactive =
                      activeOrdered.isEmpty
                      && payerIds.allSatisfy { inactivePayerIds.contains($0) }
                    if !activeOrdered.isEmpty || clearedOnlyInactive {
                      payerIds = activeOrdered
                    }
                  }
                }
              ),
              mode: mode == .variable ? .single : .multiple,
              warningMemberIds: inactivePayerIds
            )

            if mode == .fixed && payerIds.count > 1 {
              ForEach(displayedPayerOptions.filter { payerIds.contains($0.id) }) { payer in
                HStack(spacing: 8) {
                  Text(payer.name)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(Tokens.ink)
                  Spacer()
                  TextField(
                    "0",
                    text: Binding(
                      get: { payerAmountsText[payer.id] ?? "" },
                      set: { next in
                        let digits = next.filter { $0.isWholeNumber && $0.isASCII }
                        if digits.isEmpty {
                          payerAmountsText[payer.id] = ""
                        } else if let money = MoneyFormat.parseInput(digits) {
                          payerAmountsText[payer.id] = MoneyFormat.amount(money)
                        }
                      }
                    )
                  )
                  .keyboardType(.numberPad)
                  .multilineTextAlignment(.trailing)
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
                  .monospacedDigit()
                  .frame(width: 110)
                  .padding(.horizontal, 10)
                  .frame(minHeight: 36)
                  .background(
                    Tokens.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                ForEach(availableSplitMethods, id: \.self) { methodOption in
                  let selected = splitMethod == methodOption
                  Button {
                    splitMethod = methodOption
                  } label: {
                    Text(methodOption.label)
                      .font(Typography.captionBold)
                      .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
                      .padding(.horizontal, 12)
                      .frame(minHeight: 36)
                      .background(selected ? Tokens.ink : Tokens.surface, in: Capsule())
                  }
                  .buttonStyle(.plain)
                }
              }
            }
            if splitMethod != .items {
              let inactiveSharerIds = Set(
                displayedSharerOptions.filter { !$0.active }.map(\.id)
              )
              MemberPicker(
                title: L10n.tr("expenseForm.sharersTitle"),
                members: displayedSharerOptions,
                selection: Binding(
                  get: { Set(sharerIds) },
                  set: { next in
                    let activeOrPreviouslySelected = displayedSharerOptions.filter {
                      $0.active || sharerIds.contains($0.id)
                    }.map(\.id)
                    sharerIds = activeOrPreviouslySelected.filter { next.contains($0) }
                  }
                ),
                mode: .multiple,
                allowsEmptySelection: true,
                warningMemberIds: inactiveSharerIds
              )

              if splitMethod != .equal {
                ForEach(displayedSharerOptions.filter { sharerIds.contains($0.id) }) { member in
                  HStack(spacing: 8) {
                    Text(member.name)
                      .font(Typography.subheadlineBold)
                      .foregroundStyle(Tokens.ink)
                    Spacer()
                    TextField(
                      splitMethod == .shares ? member.defaultWeight : "0",
                      text: Binding(
                        get: {
                          memberValues[member.id]
                            ?? (splitMethod == .shares ? member.defaultWeight : "")
                        },
                        set: { memberValues[member.id] = $0 }
                      )
                    )
                    .keyboardType(splitMethod == .exact ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(Tokens.ink)
                    .monospacedDigit()
                    .frame(width: 110)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 36)
                    .background(
                      Tokens.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                  }
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
            .foregroundStyle(Tokens.debt)
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
          SheetCancelButton(action: onDismiss)
            .disabled(isPending)
        }
      }
    }
    .spSheet(.form, embedsNavigationStack: true)
    .discardGuard(isDirty: isDirty, isPending: isPending, onDiscard: onDismiss)
  }

  private static func parseHundredths(_ raw: String) -> Int? {
    let trimmed =
      raw
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")
    guard !trimmed.isEmpty else { return nil }
    let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count <= 2 else { return nil }
    let wholePart = String(parts[0])
    guard !wholePart.isEmpty, wholePart.count <= 3,
      wholePart.allSatisfy({ $0.isWholeNumber && $0.isASCII })
    else { return nil }
    let fracPart = parts.count == 2 ? String(parts[1]) : ""
    guard fracPart.count <= 2,
      fracPart.allSatisfy({ $0.isWholeNumber && $0.isASCII })
    else { return nil }
    let paddedFrac: String
    switch fracPart.count {
    case 0: paddedFrac = "00"
    case 1: paddedFrac = fracPart + "0"
    default: paddedFrac = fracPart
    }
    return Int(wholePart + paddedFrac)
  }

  private func buildSplitSpec() -> SplitSpec? {
    let existingExtras = editing?.splitTemplate.extras ?? []
    let existingAllocation = editing?.splitTemplate.extrasAllocation
    let canAttachExistingExtras: Bool = {
      guard !existingExtras.isEmpty else { return false }
      if mode == .variable { return true }
      return parsedAmount != nil && parsedAmount == editing?.amount
    }()

    let expectedBaseAmount: Money? = {
      guard let parsedAmount, parsedAmount.isPositive else { return nil }
      guard canAttachExistingExtras else { return parsedAmount }
      let netExtras = existingExtras.reduce(Int64(0)) { acc, extra in
        acc + (extra.kind == .discount ? -extra.amount.amount : extra.amount.amount)
      }
      let base = parsedAmount.amount - netExtras
      return base > 0 ? Money(base) : nil
    }()

    let base: SplitSpec? = {
      switch splitMethod {
      case .equal:
        guard !sharerIds.isEmpty else { return nil }
        return .equal(members: sharerIds)
      case .shares:
        var hasPositiveWeight = false
        let entries = sharerIds.compactMap { id -> SplitSpec.ShareWeightEntry? in
          let fallbackWeight = members.first(where: { $0.id == id })?.defaultWeight ?? "1"
          let raw = (memberValues[id] ?? fallbackWeight)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
          guard let hundredths = Self.parseHundredths(raw) else { return nil }
          if hundredths > 0 { hasPositiveWeight = true }
          return SplitSpec.ShareWeightEntry(memberId: id, weight: raw)
        }
        guard entries.count == sharerIds.count, !entries.isEmpty, hasPositiveWeight else {
          return nil
        }
        return .shares(entries: entries)
      case .percent:
        var sumHundredths = 0
        let entries = sharerIds.compactMap { id -> SplitSpec.PercentEntry? in
          let raw = (memberValues[id] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
          guard let hundredths = Self.parseHundredths(raw) else { return nil }
          sumHundredths += hundredths
          return SplitSpec.PercentEntry(memberId: id, percent: raw)
        }
        guard entries.count == sharerIds.count, !entries.isEmpty, sumHundredths == 10_000 else {
          return nil
        }
        return .percent(entries: entries)
      case .exact:
        guard !sharerIds.isEmpty else { return nil }
        var sumAmount: Int64 = 0
        var entries: [SplitSpec.ExactEntry] = []
        for id in sharerIds {
          let raw = (memberValues[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          if raw.isEmpty { continue }
          guard let amt = MoneyFormat.parseInput(raw), !amt.isNegative else { return nil }
          sumAmount += amt.amount
          entries.append(SplitSpec.ExactEntry(memberId: id, amount: amt))
        }
        if let expectedBaseAmount {
          guard sumAmount <= expectedBaseAmount.amount else { return nil }
          if entries.count == sharerIds.count && sumAmount != expectedBaseAmount.amount {
            return nil
          }
        }
        let remainder: ExactRemainderMode =
          entries.count < sharerIds.count ? .equalAmongBlank : .none
        return .exact(members: sharerIds, entries: entries, remainder: remainder)
      case .items:
        if case .items(let items, let extras, let allocation) = editing?.splitTemplate {
          return .items(items: items, extras: extras, extrasAllocation: allocation)
        }
        return nil
      }
    }()

    guard let base else { return nil }
    if case .items = base { return base }
    if canAttachExistingExtras {
      return base.withExtras(existingExtras, allocation: existingAllocation)
    }
    return base
  }

  private func submit() async {
    guard !payerIds.isEmpty, let split = buildSplitSpec() else { return }
    let trimmed = String(
      descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
    let payers: [RecurringPayerTemplateEntry]
    if mode == .variable {
      payers = [RecurringPayerTemplateEntry(memberId: payerIds[0], amount: nil)]
    } else if payerIds.count == 1 {
      payers = [RecurringPayerTemplateEntry(memberId: payerIds[0], amount: parsedAmount)]
    } else {
      payers = payerIds.compactMap { id in
        guard let amt = MoneyFormat.parseInput(payerAmountsText[id] ?? ""), amt.isPositive else {
          return nil
        }
        return RecurringPayerTemplateEntry(memberId: id, amount: amt)
      }
      guard payers.count == payerIds.count else { return }
    }
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
    let clamped = (1...7).contains(day) ? day : 7
    return L10n.tr("ios.recurring.weekday.\(clamped)")
  }
}
