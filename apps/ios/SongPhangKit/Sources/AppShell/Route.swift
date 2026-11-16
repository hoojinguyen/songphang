public import Domain

public enum Route: Hashable, Sendable {
  case register
  case forgotPassword
  case account
  case createGroup
  case joinGroup(token: String)
  case groupFeed(groupId: ExpenseGroup.ID)
  case groupBalances(groupId: ExpenseGroup.ID)
  case groupActivity(groupId: ExpenseGroup.ID)
  case groupMembers(groupId: ExpenseGroup.ID)
  case groupSettings(groupId: ExpenseGroup.ID)
  case quickEntry(groupId: ExpenseGroup.ID, initialSentence: String?)
  case newTransactionForm(groupId: ExpenseGroup.ID, initialReading: QuickEntryReading? = nil)
  case editTransaction(groupId: ExpenseGroup.ID, transactionId: LedgerTransaction.ID)
  case settle(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    initialAmount: Money
  )
  case debugGallery
}
