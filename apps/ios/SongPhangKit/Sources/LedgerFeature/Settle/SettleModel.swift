import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class SettleModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var fromMember: Member
    public var toMember: Member
    public var debt: Money
  }

  public enum DaySelection: Sendable, Equatable {
    case today
    case yesterday
    case other
  }

  public let groupId: ExpenseGroup.ID
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let initialAmount: Money
  public let idempotencyKey: IdempotencyKey

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  private let onSaved: () -> Void

  public private(set) var state: Loadable<ScreenData> = .loading
  public var amountText: String
  public var daySelection: DaySelection = .today
  public var customDate: Date = Date()
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?
  public var isRecorded = false

  public init(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    initialAmount: Money,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    onSaved: @escaping () -> Void
  ) {
    self.groupId = groupId
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.initialAmount = initialAmount
    self.idempotencyKey = IdempotencyKey()
    self.amountText = MoneyFormat.amount(initialAmount)
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.onSaved = onSaved
  }

  public var amount: Money? {
    MoneyFormat.parseInput(amountText)
  }

  public func load() async {
    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)

      let (group, members, balances) = try await (
        fetchedGroup, fetchedMembers, fetchedBalances
      )
      guard let from = members.first(where: { $0.id == fromMemberId }),
        let to = members.first(where: { $0.id == toMemberId }),
        from.id != to.id
      else {
        state = .failed(.api(code: "NOT_FOUND", status: 404))
        return
      }
      let fromBalance =
        balances.balances.first(where: { $0.memberId == from.id })?.balance ?? .zero
      let debt = Money.zero - fromBalance
      state = .loaded(
        ScreenData(
          group: group,
          fromMember: from,
          toMember: to,
          debt: debt
        )
      )
    } catch let error as AppError {
      state = .failed(error)
    } catch {
      state = .failed(.unexpected)
    }
  }

  public func updateAmountText(_ raw: String) {
    let digits = raw.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      amountText = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      amountText = MoneyFormat.amount(parsed)
    }
  }

  public func submit(reduceMotion: Bool = false) async {
    guard let amt = amount, amt.isPositive, !isSubmitting else { return }
    isSubmitting = true
    submitError = nil

    let targetDate: Date
    switch daySelection {
    case .today:
      targetDate = Date.now
    case .yesterday:
      targetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
    case .other:
      targetDate = customDate
    }
    let occurredAt = Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(targetDate)

    let draft = TransactionDraft.transfer(
      TransactionDraft.TransferPayload(
        amount: amt,
        occurredAt: occurredAt,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId
      )
    )

    do throws(AppError) {
      _ = try await transactionsRepository.create(
        groupId: groupId,
        draft: draft,
        key: idempotencyKey
      )
      isRecorded = true
      if !reduceMotion {
        try? await Task.sleep(for: .milliseconds(200))
      }
      isSubmitting = false
      onSaved()
    } catch {
      isSubmitting = false
      submitError = error
    }
  }
}
