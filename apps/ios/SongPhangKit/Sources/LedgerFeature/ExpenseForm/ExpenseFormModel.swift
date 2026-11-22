import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class ExpenseFormModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var categories: [GroupCategory]
    public var balances: GroupBalances
    public var editingTransaction: LedgerTransaction?
  }

  public let groupId: ExpenseGroup.ID
  public let editingTransactionId: LedgerTransaction.ID?
  public let initialReading: QuickEntryReading?
  public let initialTransferFrom: Member.ID?
  public let initialTransferTo: Member.ID?
  public let idempotencyKey: IdempotencyKey

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  public let categoriesRepository: any CategoriesRepository
  private let onSaved: () -> Void
  private let onDeleted: (LedgerTransaction.ID) -> Void

  public private(set) var state: Loadable<ScreenData> = .loading
  public var transactionType: TransactionType = .expense
  public var amountText: String = ""
  public var descriptionText: String = ""
  public var category: TransactionCategory?
  public var categoryId: GroupCategory.ID?
  public var payerIds: [Member.ID] = []
  public var payerAmounts: [Member.ID: String] = [:]
  public var transferFrom: Member.ID?
  public var transferTo: Member.ID?
  public var occurredAtDate: Date = Date()
  public var splitState: SplitEditorState = SplitEditorState(members: [])
  public var isSplitEditorOpen = false
  public var isUnparsedBannerDismissed = false

  public private(set) var previewShares: [MemberAmount] = []
  public private(set) var previewWarnings: [TransactionWarning] = []
  public private(set) var isPreviewPending = false
  public private(set) var previewError: AppError?

  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?
  public private(set) var conflictTransaction: LedgerTransaction?
  public private(set) var isDeleting = false
  public private(set) var deleteError: AppError?

  private var previewTask: Task<Void, Never>?

  public init(
    groupId: ExpenseGroup.ID,
    editingTransactionId: LedgerTransaction.ID? = nil,
    initialReading: QuickEntryReading? = nil,
    initialTransferFrom: Member.ID? = nil,
    initialTransferTo: Member.ID? = nil,
    initialSplitEditorOpen: Bool = false,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    categoriesRepository: any CategoriesRepository,
    onSaved: @escaping () -> Void,
    onDeleted: @escaping (LedgerTransaction.ID) -> Void = { _ in }
  ) {
    self.groupId = groupId
    self.editingTransactionId = editingTransactionId
    self.initialReading = initialReading
    self.initialTransferFrom = initialTransferFrom
    self.initialTransferTo = initialTransferTo
    self.idempotencyKey = IdempotencyKey()
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.categoriesRepository = categoriesRepository
    self.onSaved = onSaved
    self.onDeleted = onDeleted
    self.isSplitEditorOpen =
      initialSplitEditorOpen
      || (editingTransactionId == nil
        && (initialReading?.issues.contains(where: { $0.code == .sumMismatch }) ?? false))
  }

  public var amount: Money {
    MoneyFormat.parseInput(amountText) ?? .zero
  }

  public var activeMembers: [Member] {
    guard let data = state.value else { return [] }
    if data.editingTransaction != nil {
      return data.members
    }
    return data.members.filter(\.active)
  }

  public var sharerMembers: [Member] {
    activeMembers.filter { $0.kind == .person }
  }

  public var payerMembers: [Member] {
    let people = sharerMembers
    if let fund = activeMembers.first(where: { $0.kind == .fund }) {
      return people + [fund]
    }
    return people
  }

  public var transferMembers: [Member] {
    activeMembers
  }

  public var headerTitle: String {
    let isEditing = (state.value?.editingTransaction != nil)
    if isEditing {
      switch transactionType {
      case .income: return L10n.tr("expenseForm.titleEditIncome")
      case .transfer: return L10n.tr("expenseForm.titleEditTransfer")
      default: return L10n.tr("expenseForm.titleEdit")
      }
    } else {
      switch transactionType {
      case .income: return L10n.tr("expenseForm.titleIncome")
      case .transfer: return L10n.tr("expenseForm.titleTransfer")
      default: return L10n.tr("expenseForm.title")
      }
    }
  }

  public var saveButtonTitle: String {
    if state.value?.editingTransaction != nil {
      return L10n.tr("expenseForm.saveChanges")
    }
    switch transactionType {
    case .transfer: return L10n.tr("expenseForm.saveTransfer")
    case .income: return L10n.tr("expenseForm.saveIncome")
    default: return L10n.tr("expenseForm.save")
    }
  }

  public func load() async {
    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedCategories = categoriesRepository.list(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)
      let (group, members, categories, balances) = try await (
        fetchedGroup,
        fetchedMembers,
        fetchedCategories,
        fetchedBalances
      )
      let editingTx: LedgerTransaction?
      if let editingTransactionId {
        editingTx = try await transactionsRepository.transaction(
          groupId: groupId,
          id: editingTransactionId
        )
      } else {
        editingTx = nil
      }
      let data = ScreenData(
        group: group,
        members: members,
        categories: categories,
        balances: balances,
        editingTransaction: editingTx
      )
      state = .loaded(data)
      configureFields(data: data)
      await refreshPreviewNow()
    } catch let error as AppError {
      state = .failed(error)
    } catch {
      state = .failed(.unexpected)
    }
  }

  private func configureFields(data: ScreenData) {
    let people = sharerMembers
    let defaultMyId =
      people.contains(where: { $0.id == data.group.myMemberId })
      ? data.group.myMemberId
      : people.first?.id

    if let tx = data.editingTransaction {
      transactionType = tx.type
      amountText = MoneyFormat.amount(tx.amount)
      descriptionText = tx.description
      category = tx.category
      categoryId = tx.categoryId
      payerIds = tx.payers.map(\.memberId)
      var pMap: [Member.ID: String] = [:]
      for p in tx.payers {
        pMap[p.memberId] = MoneyFormat.amount(p.amount)
      }
      payerAmounts = pMap
      transferFrom = tx.payers.first?.memberId ?? defaultMyId
      transferTo = tx.shares.first?.memberId
      splitState = SplitEditorState(members: people, initial: tx.split)
      previewShares = tx.shares
    } else if let reading = initialReading {
      transactionType = .expense
      if let amt = reading.draft.amount {
        amountText = MoneyFormat.amount(amt)
      }
      descriptionText = reading.draft.description ?? ""
      category = nil
      categoryId = nil
      if !reading.draft.payers.isEmpty {
        payerIds = reading.draft.payers.map(\.memberId)
      } else if let defaultMyId {
        payerIds = [defaultMyId]
      }
      transferFrom = defaultMyId
      transferTo = nil
      splitState = SplitEditorState(members: people, initial: reading.draft.split)
      previewShares = reading.shares ?? []
    } else {
      let isFundTransferPrefill = (initialTransferFrom != nil || initialTransferTo != nil)
      transactionType = isFundTransferPrefill ? .transfer : .expense
      amountText = ""
      descriptionText = ""
      category = nil
      categoryId = nil
      payerIds = defaultMyId.map { [$0] } ?? []
      transferFrom = initialTransferFrom ?? defaultMyId
      transferTo = initialTransferTo
      splitState = SplitEditorState(members: people, initial: nil)
      previewShares = []
    }
  }

  public func selectBuiltinCategory(_ next: TransactionCategory?) {
    category = next
    if next != nil {
      categoryId = nil
    }
  }

  public func selectCustomCategory(_ id: GroupCategory.ID?) {
    categoryId = id
    if id != nil {
      category = nil
    }
  }

  public func updateCategories(_ next: [GroupCategory]) {
    if case .loaded(var current) = state {
      current.categories = next
      state = .loaded(current)
    }
  }

  public func setType(_ next: TransactionType) {
    transactionType = next
    if next == .income {
      let defaultId = state.value?.group.myMemberId ?? payerIds.first
      payerIds = defaultId.map { [$0] } ?? []
    }
    schedulePreview()
  }

  public func updateAmountText(_ raw: String) {
    let digits = raw.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      amountText = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      amountText = MoneyFormat.amount(parsed)
    }
    schedulePreview()
  }

  public func appendThousands() {
    updateAmountText(amountText + "000")
  }

  public func togglePayer(_ id: Member.ID) {
    if transactionType == .income {
      payerIds = [id]
    } else if payerIds.contains(id) {
      payerIds.removeAll { $0 == id }
    } else {
      payerIds.append(id)
    }
    schedulePreview()
  }

  public func setPayerAmount(_ text: String, for id: Member.ID) {
    let digits = text.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      payerAmounts[id] = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      payerAmounts[id] = MoneyFormat.amount(parsed)
    }
    schedulePreview()
  }

  public func toggleSharer(_ id: Member.ID) {
    splitState.toggle(id, members: sharerMembers)
    schedulePreview()
  }

  public func setTransferFrom(_ id: Member.ID) {
    transferFrom = id
    if transferTo == id {
      transferTo = nil
    }
  }

  public func buildDraft() -> TransactionDraft? {
    let amt = amount
    guard amt.isPositive else { return nil }
    let occurredAtIso =
      state.value?.editingTransaction?.occurredAt
      ?? Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(occurredAtDate)

    if transactionType == .transfer {
      guard let from = transferFrom, let to = transferTo, from != to else {
        return nil
      }
      let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
      return .transfer(
        TransactionDraft.TransferPayload(
          amount: amt,
          occurredAt: occurredAtIso,
          fromMemberId: from,
          toMemberId: to,
          description: trimmed.isEmpty ? nil : trimmed
        )
      )
    }

    guard !payerIds.isEmpty else { return nil }
    let resolvedPayers: [MemberAmount]
    if payerIds.count == 1 {
      resolvedPayers = [MemberAmount(memberId: payerIds[0], amount: amt)]
    } else {
      var list: [MemberAmount] = []
      var sum = Money.zero
      for id in payerIds {
        guard let pAmt = MoneyFormat.parseInput(payerAmounts[id] ?? ""), pAmt.isPositive else {
          return nil
        }
        list.append(MemberAmount(memberId: id, amount: pAmt))
        sum = sum + pAmt
      }
      guard sum == amt else { return nil }
      resolvedPayers = list
    }

    guard let resolvedSplit = splitState.resolvedSplit(from: activeMembers, totalAmount: amt)
    else {
      return nil
    }

    let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
    let desc = trimmed.isEmpty ? headerTitle : trimmed
    return .split(
      TransactionDraft.SplitPayload(
        isIncome: transactionType == .income,
        description: desc,
        amount: amt,
        occurredAt: occurredAtIso,
        category: categoryId == nil ? category : nil,
        categoryId: categoryId,
        payers: resolvedPayers,
        split: resolvedSplit
      )
    )
  }

  public var canSubmit: Bool {
    guard conflictTransaction == nil, !isSubmitting, let draft = buildDraft() else {
      return false
    }
    if transactionType != .transfer
      && descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return false
    }
    _ = draft
    return true
  }

  public func schedulePreview() {
    previewTask?.cancel()
    guard transactionType != .transfer, buildDraft() != nil else {
      isPreviewPending = false
      previewError = nil
      return
    }
    isPreviewPending = true
    previewTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await refreshPreviewNow()
    }
  }

  public func refreshPreviewNow() async {
    guard transactionType != .transfer, let draft = buildDraft() else {
      isPreviewPending = false
      previewWarnings = []
      return
    }
    isPreviewPending = true
    previewError = nil
    defer { isPreviewPending = false }
    do throws(AppError) {
      let preview = try await transactionsRepository.preview(groupId: groupId, draft: draft)
      previewShares = preview.shares
      previewWarnings = preview.warnings
    } catch {
      previewError = error
    }
  }

  public func fundOverdrawnAmount() -> Money? {
    guard previewWarnings.contains(.fundOverdrawn),
      let fund = state.value?.balances.fund,
      payerIds.contains(fund.memberId)
    else { return nil }
    let fundPaid: Money
    if payerIds.count == 1 {
      fundPaid = amount
    } else {
      fundPaid = MoneyFormat.parseInput(payerAmounts[fund.memberId] ?? "") ?? .zero
    }
    let positiveCash = fund.cash.isPositive ? fund.cash : .zero
    let overdraft = fundPaid - positiveCash
    return overdraft.isPositive ? overdraft : nil
  }

  public func submit() async {
    guard let draft = buildDraft(), !isSubmitting else { return }
    if transactionType != .transfer
      && descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return
    }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }

    do throws(AppError) {
      if let editingTx = state.value?.editingTransaction {
        _ = try await transactionsRepository.update(
          groupId: groupId,
          id: editingTx.id,
          draft: draft,
          version: editingTx.version
        )
      } else {
        _ = try await transactionsRepository.create(
          groupId: groupId,
          draft: draft,
          key: idempotencyKey
        )
      }
      onSaved()
    } catch {
      if error == .conflict, let editingId = state.value?.editingTransaction?.id {
        if let latest = try? await transactionsRepository.transaction(
          groupId: groupId,
          id: editingId
        ) {
          conflictTransaction = latest
        } else if var fallback = state.value?.editingTransaction {
          fallback.version += 1
          conflictTransaction = fallback
        }
      } else {
        submitError = error
      }
    }
  }

  public func reloadWithConflict() {
    guard let latest = conflictTransaction, var data = state.value else { return }
    data.editingTransaction = latest
    state = .loaded(data)
    conflictTransaction = nil
    submitError = nil
    configureFields(data: data)
  }

  public func simulateConflictForExercise() {
    guard var current = state.value?.editingTransaction else { return }
    current.version += 1
    current.description = "\(current.description) (đã sửa)"
    conflictTransaction = current
  }

  public func deleteTransaction() async {
    guard let editingId = state.value?.editingTransaction?.id, !isDeleting else { return }
    isDeleting = true
    deleteError = nil
    defer { isDeleting = false }

    do throws(AppError) {
      try await transactionsRepository.delete(groupId: groupId, id: editingId)
      onDeleted(editingId)
    } catch {
      deleteError = error
    }
  }
}
