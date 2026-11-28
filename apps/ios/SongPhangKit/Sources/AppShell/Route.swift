public import Domain
public import Foundation

public enum Route: Hashable, Sendable {
  public enum SettingsSectionAnchor: String, Hashable, Sendable {
    case categories
  }

  case register
  case forgotPassword
  case account
  case createGroup
  case joinGroup(token: String)
  case guestShare(token: String)
  case groupFeed(
    groupId: ExpenseGroup.ID,
    initialFilter: TransactionFilter? = nil,
    initialToast: String? = nil
  )
  case groupBalances(
    groupId: ExpenseGroup.ID,
    initialTransferProofAttachmentId: Attachment.ID? = nil
  )
  case groupStats(groupId: ExpenseGroup.ID)
  case groupActivity(groupId: ExpenseGroup.ID)
  case groupMembers(groupId: ExpenseGroup.ID)
  case groupFund(groupId: ExpenseGroup.ID)
  case groupSettings(groupId: ExpenseGroup.ID, initialSection: SettingsSectionAnchor? = nil)
  case quickEntry(groupId: ExpenseGroup.ID, initialSentence: String?)
  case newTransactionForm(
    groupId: ExpenseGroup.ID,
    initialReading: QuickEntryReading? = nil,
    initialTransferFrom: Member.ID? = nil,
    initialTransferTo: Member.ID? = nil,
    initialAttachmentId: Attachment.ID? = nil,
    initialAttachmentIds: [Attachment.ID] = [],
    initialPendingImageDatas: [Data] = [],
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

  public var associatedGroupId: ExpenseGroup.ID? {
    switch self {
    case .groupFeed(let groupId, _, _),
      .groupBalances(let groupId, _),
      .groupStats(let groupId),
      .groupActivity(let groupId),
      .groupMembers(let groupId),
      .groupFund(let groupId),
      .groupSettings(let groupId, _),
      .quickEntry(let groupId, _),
      .newTransactionForm(let groupId, _, _, _, _, _, _, _, _),
      .editTransaction(let groupId, _),
      .transactionDetail(let groupId, _),
      .receiptReview(let groupId, _),
      .settle(let groupId, _, _, _):
      return groupId
    case .register, .forgotPassword, .account, .createGroup, .joinGroup, .guestShare,
      .notifications, .personalLedger:
      return nil
    #if DEBUG
      case .debugGallery:
        return nil
    #endif
    }
  }
}
