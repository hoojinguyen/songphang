public import DesignSystem
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
  public let initialAttachmentId: Attachment.ID?
  public let initialRecurringExpense: RecurringExpense?
  public let initialRecurringDueAction: OverviewRecurringDueAction?
  public let idempotencyKey: IdempotencyKey

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  public let categoriesRepository: any CategoriesRepository
  public let attachmentsRepository: any AttachmentsRepository
  private let recurringExpensesRepository: (any RecurringExpensesRepository)?
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
  public var paymentChannel: PaymentChannel?
  public var paymentNote: String?
  public var occurredAtDate: Date = Date()
  public var attachments: [Attachment] = []
  public private(set) var isUploadingAttachment = false
  public private(set) var attachmentError: AppError?
  public private(set) var attachmentImageError: ReceiptImageError?
  public private(set) var isAttachmentLimitError = false
  public var splitState: SplitEditorState = SplitEditorState(members: [])
  public var isSplitEditorOpen = false
  public var isUnparsedBannerDismissed = false

  public var manualExtras: [EditableManualExtra] = []
  public var extrasAllocation: ExtrasAllocation = .equal
  public private(set) var extrasPreview: PreviewExtrasResult?
  public private(set) var isExtrasPreviewCurrent = false
  public private(set) var extrasPreviewError: AppError?

  public var isRecurringEnabled = false
  public var recurringMode: RecurringMode = .fixed
  public var recurringFrequency: RecurringFrequency = .monthly
  public var recurringDayOfWeek: Int = 1
  public var recurringDayOfMonth: Int = 1
  public var recurringMonthOfYear: Int = 1
  private var resolvedRecurringExpense: RecurringExpense?

  public private(set) var previewShares: [MemberAmount] = []
  public private(set) var previewWarnings: [TransactionWarning] = []
  public private(set) var itemsPreview: ItemsPreview?
  public private(set) var isItemsPreviewCurrent = false
  public private(set) var itemsPreviewError: AppError?
  public private(set) var isPreviewPending = false
  public private(set) var previewError: AppError?

  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?
  public private(set) var conflictTransaction: LedgerTransaction?
  public private(set) var isDeleting = false
  public private(set) var deleteError: AppError?

  private var previewTask: Task<Void, Never>?
  private var itemsPreviewTask: Task<Void, Never>?
  private var extrasPreviewTask: Task<Void, Never>?

  public init(
    groupId: ExpenseGroup.ID,
    editingTransactionId: LedgerTransaction.ID? = nil,
    initialReading: QuickEntryReading? = nil,
    initialTransferFrom: Member.ID? = nil,
    initialTransferTo: Member.ID? = nil,
    initialAttachmentId: Attachment.ID? = nil,
    initialRecurringExpense: RecurringExpense? = nil,
    initialRecurringDueAction: OverviewRecurringDueAction? = nil,
    initialSplitEditorOpen: Bool = false,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    categoriesRepository: any CategoriesRepository,
    attachmentsRepository: any AttachmentsRepository,
    recurringExpensesRepository: (any RecurringExpensesRepository)? = nil,
    onSaved: @escaping () -> Void,
    onDeleted: @escaping (LedgerTransaction.ID) -> Void = { _ in }
  ) {
    self.groupId = groupId
    self.editingTransactionId = editingTransactionId
    self.initialReading = initialReading
    self.initialTransferFrom = initialTransferFrom
    self.initialTransferTo = initialTransferTo
    self.initialAttachmentId = initialAttachmentId
    self.initialRecurringExpense = initialRecurringExpense
    self.initialRecurringDueAction = initialRecurringDueAction
    self.resolvedRecurringExpense = initialRecurringExpense
    self.idempotencyKey = IdempotencyKey()
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.categoriesRepository = categoriesRepository
    self.attachmentsRepository = attachmentsRepository
    self.recurringExpensesRepository = recurringExpensesRepository
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

  public var hasManualExtras: Bool {
    transactionType == .expense && splitState.method != .items && !manualExtras.isEmpty
  }

  public var effectiveAmount: Money {
    if transactionType == .expense && splitState.method == .items {
      return isItemsPreviewCurrent ? (itemsPreview?.computedAmount ?? .zero) : .zero
    }
    if hasManualExtras {
      return isExtrasPreviewCurrent ? (extrasPreview?.computedAmount ?? .zero) : .zero
    }
    return amount
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
      if resolvedRecurringExpense == nil,
        let dueAction = initialRecurringDueAction,
        let list = try? await recurringExpensesRepository?.list(groupId: groupId)
      {
        resolvedRecurringExpense = list.first(where: { $0.id == dueAction.id })
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
      let netExtras = tx.split.extras.reduce(Int64(0)) { sum, extra in
        sum + (extra.kind == .discount ? -extra.amount.amount : extra.amount.amount)
      }
      let baseAmt =
        (!tx.split.extras.isEmpty && tx.amount.amount > netExtras)
        ? Money(tx.amount.amount - netExtras)
        : tx.amount
      amountText = MoneyFormat.amount(baseAmt)
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
      paymentChannel = tx.paymentChannel
      paymentNote = tx.paymentNote
      attachments = tx.attachments
      splitState = SplitEditorState(
        members: people,
        initial: tx.split,
        defaultItemTitle: L10n.tr("receipts.title"),
        initialAmount: baseAmt
      )
      if case .items = tx.split {
        manualExtras = []
        extrasAllocation = .equal
      } else {
        manualExtras = Self.editableManualExtras(from: tx.split.extras)
        extrasAllocation = tx.split.extrasAllocation ?? .equal
      }
      previewShares = tx.shares
      if splitState.method == .items {
        scheduleItemsPreview()
      } else if !manualExtras.isEmpty {
        scheduleExtrasPreview()
      }
    } else if let recurring = resolvedRecurringExpense {
      transactionType = .expense
      descriptionText = recurring.description
      if let amt = recurring.amount {
        let netExtras = recurring.splitTemplate.extras.reduce(Int64(0)) { sum, extra in
          sum + (extra.kind == .discount ? -extra.amount.amount : extra.amount.amount)
        }
        let baseAmt =
          (!recurring.splitTemplate.extras.isEmpty && amt.amount > netExtras)
          ? Money(amt.amount - netExtras)
          : amt
        amountText = MoneyFormat.amount(baseAmt)
      }
      category = recurring.category
      categoryId = recurring.categoryId
      let templatePayers = recurring.payersTemplate.map(\.memberId)
      payerIds = templatePayers.isEmpty ? (defaultMyId.map { [$0] } ?? []) : templatePayers
      splitState = SplitEditorState(
        members: people,
        initial: recurring.splitTemplate,
        defaultItemTitle: L10n.tr("receipts.title"),
        initialAmount: recurring.amount ?? .zero
      )
      if case .items = recurring.splitTemplate {
        manualExtras = []
        extrasAllocation = .equal
      } else {
        manualExtras = Self.editableManualExtras(from: recurring.splitTemplate.extras)
        extrasAllocation = recurring.splitTemplate.extrasAllocation ?? .equal
      }
      if splitState.method == .items {
        scheduleItemsPreview()
      } else if !manualExtras.isEmpty && amount.isPositive {
        scheduleExtrasPreview()
      }
    } else if let dueAction = initialRecurringDueAction {
      transactionType = .expense
      descriptionText = dueAction.description
      if let suggested = dueAction.suggestedAmount {
        amountText = MoneyFormat.amount(suggested)
      }
      payerIds = [dueAction.payerMemberId]
      splitState = SplitEditorState(
        members: people,
        initial: nil,
        defaultItemTitle: L10n.tr("receipts.title"),
        initialAmount: dueAction.suggestedAmount ?? .zero
      )
    } else if let reading = initialReading {
      transactionType = .expense
      if let amt = reading.draft.amount {
        amountText = MoneyFormat.amount(amt)
      }
      descriptionText = reading.draft.description ?? ""
      category = reading.draft.category
      categoryId = reading.draft.categoryId
      if !reading.draft.payers.isEmpty {
        payerIds = reading.draft.payers.map(\.memberId)
      } else if let defaultMyId {
        payerIds = [defaultMyId]
      }
      transferFrom = defaultMyId
      transferTo = nil
      attachments =
        initialAttachmentId.map {
          [Attachment(id: $0, contentType: "image/jpeg", byteSize: 1)]
        } ?? []
      splitState = SplitEditorState(
        members: people,
        initial: reading.draft.split,
        defaultItemTitle: L10n.tr("receipts.title"),
        initialAmount: reading.draft.amount ?? .zero
      )
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
      attachments =
        initialAttachmentId.map {
          [Attachment(id: $0, contentType: "image/jpeg", byteSize: 1)]
        } ?? []
      splitState = SplitEditorState(
        members: people,
        initial: nil,
        defaultItemTitle: L10n.tr("receipts.title"),
        initialAmount: .zero
      )
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
      if splitState.method == .items {
        splitState.changeMode(.equal, members: sharerMembers)
      }
    }
    schedulePreview()
  }

  public func uploadAttachment(rawImageData: Data) async {
    guard !isUploadingAttachment else { return }
    attachmentError = nil
    attachmentImageError = nil
    isAttachmentLimitError = false
    guard attachments.count < 3 else {
      isAttachmentLimitError = true
      return
    }
    isUploadingAttachment = true
    defer { isUploadingAttachment = false }
    do {
      let prepared = try await ReceiptImageProcessor.prepareJPEG(from: rawImageData)
      let uploaded = try await attachmentsRepository.upload(
        groupId: groupId,
        data: prepared,
        filename: "hoa-don.jpg",
        contentType: "image/jpeg"
      )
      attachments.append(uploaded)
    } catch let imgError as ReceiptImageError {
      attachmentImageError = imgError
    } catch let appError as AppError {
      attachmentError = appError
    } catch {
      attachmentError = .unexpected
    }
  }

  public func removeAttachment(id: Attachment.ID) {
    attachmentError = nil
    attachmentImageError = nil
    isAttachmentLimitError = false
    attachments.removeAll { $0.id == id }
  }

  public func scheduleItemsPreview() {
    itemsPreviewTask?.cancel()
    guard transactionType == .expense, splitState.method == .items else {
      itemsPreview = nil
      isItemsPreviewCurrent = false
      return
    }
    isItemsPreviewCurrent = false
    guard let payload = splitState.itemsDraft.buildPayload() else {
      itemsPreview = nil
      return
    }
    itemsPreviewTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await refreshItemsPreviewNow(items: payload.items, extras: payload.extras)
    }
  }

  private func refreshItemsPreviewNow(
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra]
  ) async {
    itemsPreviewError = nil
    do throws(AppError) {
      let result = try await transactionsRepository.previewItems(
        groupId: groupId,
        items: items,
        extras: extras,
        extrasAllocation: splitState.itemsDraft.extrasAllocation,
        targetTotal: nil
      )
      guard !Task.isCancelled else { return }
      itemsPreview = result
      isItemsPreviewCurrent = true
      if result.computedAmount.isPositive {
        amountText = MoneyFormat.amount(result.computedAmount)
      }
      schedulePreview()
    } catch {
      itemsPreviewError = error
      isItemsPreviewCurrent = false
    }
  }

  public func scheduleExtrasPreview() {
    extrasPreviewTask?.cancel()
    guard hasManualExtras else {
      extrasPreview = nil
      isExtrasPreviewCurrent = false
      extrasPreviewError = nil
      schedulePreview()
      return
    }
    let validItems = manualExtras.compactMap { $0.toPreviewItem() }
    guard amount.isPositive, validItems.count == manualExtras.count, !validItems.isEmpty else {
      extrasPreview = nil
      isExtrasPreviewCurrent = false
      return
    }
    isExtrasPreviewCurrent = false
    let baseAmt = amount
    let alloc = extrasAllocation
    let splitSpec = splitState.resolvedSplit(from: activeMembers, totalAmount: baseAmt)
    let editingId = state.value?.editingTransaction?.id
    let payersPayload: [PreviewExtrasPayer]? = {
      guard !payerIds.isEmpty else { return nil }
      if payerIds.count == 1 {
        return [PreviewExtrasPayer(memberId: payerIds[0], amount: nil)]
      }
      return payerIds.map { id in
        PreviewExtrasPayer(memberId: id, amount: MoneyFormat.parseInput(payerAmounts[id] ?? ""))
      }
    }()
    extrasPreviewTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await refreshExtrasPreviewNow(
        input: PreviewExtrasInput(
          baseAmount: baseAmt,
          extras: validItems,
          extrasAllocation: alloc,
          payers: payersPayload,
          payerMemberId: payerIds.count == 1 ? payerIds.first : nil,
          split: splitSpec,
          transactionId: editingId
        )
      )
    }
  }

  private func refreshExtrasPreviewNow(input: PreviewExtrasInput) async {
    extrasPreviewError = nil
    do throws(AppError) {
      let result = try await transactionsRepository.previewExtras(
        groupId: groupId,
        input: input
      )
      guard !Task.isCancelled else { return }
      extrasPreview = result
      isExtrasPreviewCurrent = true
      if let shares = result.shares {
        previewShares = shares
      }
      previewWarnings = result.warnings
      previewError = nil
      isPreviewPending = false
    } catch {
      extrasPreviewError = error
      isExtrasPreviewCurrent = false
    }
  }

  public func updateAmountText(_ raw: String) {
    let digits = raw.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      amountText = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      amountText = MoneyFormat.amount(parsed)
    }
    if hasManualExtras {
      scheduleExtrasPreview()
    } else {
      schedulePreview()
    }
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
    if hasManualExtras {
      scheduleExtrasPreview()
    } else {
      schedulePreview()
    }
  }

  public func setPayerAmount(_ text: String, for id: Member.ID) {
    let digits = text.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      payerAmounts[id] = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      payerAmounts[id] = MoneyFormat.amount(parsed)
    }
    if hasManualExtras {
      scheduleExtrasPreview()
    } else {
      schedulePreview()
    }
  }

  public func toggleSharer(_ id: Member.ID) {
    splitState.toggle(id, members: sharerMembers)
    if hasManualExtras {
      scheduleExtrasPreview()
    } else {
      schedulePreview()
    }
  }

  public func setTransferFrom(_ id: Member.ID) {
    transferFrom = id
    if transferTo == id {
      transferTo = nil
    }
  }

  public func buildDraft() -> TransactionDraft? {
    let amt = effectiveAmount
    guard amt.isPositive else { return nil }
    let occurredAtIso =
      state.value?.editingTransaction?.occurredAt
      ?? Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(occurredAtDate)
    let attachmentIdList: [Attachment.ID]? =
      (state.value?.editingTransaction != nil || !attachments.isEmpty)
      ? attachments.map(\.id)
      : nil

    if transactionType == .transfer {
      guard let from = transferFrom, let to = transferTo, from != to else {
        return nil
      }
      let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedNote = paymentNote?.trimmingCharacters(in: .whitespacesAndNewlines)
      return .transfer(
        TransactionDraft.TransferPayload(
          amount: amt,
          occurredAt: occurredAtIso,
          fromMemberId: from,
          toMemberId: to,
          description: trimmed.isEmpty ? nil : trimmed,
          attachmentIds: attachmentIdList,
          paymentChannel: paymentChannel,
          paymentNote: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
      )
    }

    if transactionType == .expense && splitState.method == .items {
      guard isItemsPreviewCurrent,
        let preview = itemsPreview,
        preview.issues.isEmpty,
        !preview.shares.isEmpty,
        preview.computedAmount.isPositive
      else { return nil }
    } else if hasManualExtras {
      let validCount = manualExtras.compactMap { $0.toPreviewItem() }.count
      guard amount.isPositive,
        validCount == manualExtras.count,
        isExtrasPreviewCurrent,
        let preview = extrasPreview,
        preview.issues.isEmpty,
        preview.computedAmount.isPositive
      else { return nil }
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

    let splitBaseAmount = hasManualExtras ? amount : amt
    guard
      let baseSplit = splitState.resolvedSplit(from: activeMembers, totalAmount: splitBaseAmount)
    else {
      return nil
    }
    let resolvedSplit: SplitSpec = {
      if hasManualExtras, isExtrasPreviewCurrent, let preview = extrasPreview {
        return baseSplit.withExtras(preview.resolvedExtras, allocation: extrasAllocation)
      }
      return baseSplit
    }()

    let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
    let desc = trimmed.isEmpty ? headerTitle : trimmed
    let isCreatingExpense =
      state.value?.editingTransaction == nil && transactionType == .expense
    let recurringExpenseId =
      isCreatingExpense
      ? (resolvedRecurringExpense?.id ?? initialRecurringDueAction?.id)
      : nil
    let inlineRecurring: CreateInlineRecurringInput? =
      (isCreatingExpense && recurringExpenseId == nil && isRecurringEnabled)
      ? CreateInlineRecurringInput(
        mode: recurringMode,
        frequency: recurringFrequency,
        dayOfWeek: recurringFrequency == .weekly ? recurringDayOfWeek : nil,
        dayOfMonth: recurringFrequency != .weekly ? recurringDayOfMonth : nil,
        monthOfYear: recurringFrequency == .yearly ? recurringMonthOfYear : nil
      )
      : nil

    return .split(
      TransactionDraft.SplitPayload(
        isIncome: transactionType == .income,
        description: desc,
        amount: amt,
        occurredAt: occurredAtIso,
        category: categoryId == nil ? category : nil,
        categoryId: categoryId,
        payers: resolvedPayers,
        split: resolvedSplit,
        attachmentIds: attachmentIdList,
        recurringExpenseId: recurringExpenseId,
        recurring: inlineRecurring
      )
    )
  }

  public var canSubmit: Bool {
    guard conflictTransaction == nil, !isSubmitting, !isUploadingAttachment,
      let draft = buildDraft()
    else {
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
    if hasManualExtras {
      isPreviewPending = false
      previewError = nil
      return
    }
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
    if hasManualExtras {
      scheduleExtrasPreview()
      return
    }
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
      fundPaid = effectiveAmount
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

  private static func editableManualExtras(from extras: [SplitSpec.ItemsExtra])
    -> [EditableManualExtra]
  {
    extras.map { extra in
      if let rate = extra.ratePercent, !rate.isEmpty {
        return EditableManualExtra(
          kind: extra.kind,
          label: extra.label,
          mode: .percent,
          percentText: rate,
          amountText: ""
        )
      }
      return EditableManualExtra(
        kind: extra.kind,
        label: extra.label,
        mode: .amount,
        percentText: "",
        amountText: MoneyFormat.amount(extra.amount)
      )
    }
  }
}
