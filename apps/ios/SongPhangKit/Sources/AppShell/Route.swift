public import Domain

public enum Route: Hashable, Sendable {
  case register
  case forgotPassword
  case account
  case createGroup
  case joinGroup(token: String)
  case guestShare(token: String)
  case groupFeed(groupId: ExpenseGroup.ID, initialFilter: TransactionFilter? = nil)
  case groupBalances(groupId: ExpenseGroup.ID)
  case groupStats(groupId: ExpenseGroup.ID)
  case groupActivity(groupId: ExpenseGroup.ID)
  case groupMembers(groupId: ExpenseGroup.ID)
  case groupFund(groupId: ExpenseGroup.ID)
  case groupSettings(groupId: ExpenseGroup.ID)
  case quickEntry(groupId: ExpenseGroup.ID, initialSentence: String?)
  case newTransactionForm(
    groupId: ExpenseGroup.ID,
    initialReading: QuickEntryReading? = nil,
    initialTransferFrom: Member.ID? = nil,
    initialTransferTo: Member.ID? = nil,
    initialAttachmentId: Attachment.ID? = nil,
    initialRecurringExpense: RecurringExpense? = nil,
    initialRecurringDueAction: OverviewRecurringDueAction? = nil
  )
  case editTransaction(groupId: ExpenseGroup.ID, transactionId: LedgerTransaction.ID)
  case transactionDetail(groupId: ExpenseGroup.ID, transactionId: LedgerTransaction.ID)
  case receiptReview(groupId: ExpenseGroup.ID, scanId: ReceiptScan.ID)
  case settle(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    initialAmount: Money
  )
  case notifications
  case personalLedger
  #if DEBUG
    case debugGallery
  #endif
}
