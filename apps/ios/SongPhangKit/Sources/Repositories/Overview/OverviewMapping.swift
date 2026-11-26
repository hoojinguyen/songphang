import Domain
import Foundation
import GeneratedAPI

enum OverviewMapping {
  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func mapSummary(_ dto: Components.Schemas.OverviewResponse) -> OverviewSummary {
    let pendingActions: [OverviewPendingAction] = dto.pendingActions.map { action in
      switch action {
      case .settlement_confirmation(let settlement):
        return OverviewPendingAction(
          id: OverviewPendingAction.ID(settlement.id),
          kind: .settlementConfirmation,
          groupId: ExpenseGroup.ID(settlement.groupId),
          groupName: settlement.groupName,
          transactionId: nil,
          description: settlement.description,
          amount: Money(Int64(settlement.amount)),
          occurredAt: formatISO(settlement.createdAt),
          actorName: settlement.actorName
        )
      case .expense_approval(let approval):
        return OverviewPendingAction(
          id: OverviewPendingAction.ID(approval.id),
          kind: .expenseApproval,
          groupId: ExpenseGroup.ID(approval.groupId),
          groupName: approval.groupName,
          transactionId: nil,
          description: approval.description,
          amount: Money(Int64(approval.amount)),
          occurredAt: formatISO(approval.createdAt),
          actorName: approval.actorName
        )
      }
    }

    let groupBalances: [OverviewGroupBalance] = dto.groupBalances.map { gb in
      OverviewGroupBalance(
        groupId: ExpenseGroup.ID(gb.groupId),
        groupName: gb.groupName,
        myBalance: Money(Int64(gb.myBalance)),
        myIndividualBalance: gb.myIndividualBalance.map { Money(Int64($0)) },
        householdName: gb.householdName,
        role: Role(code: gb.role.rawValue),
        archivedAt: gb.archivedAt,
        memberCount: gb.memberCount,
        previewMembers: gb.previewMembers.map { p in
          ExpenseGroup.PreviewMember(
            id: Member.ID(p.id),
            name: p.name,
            shape: MemberShape(code: p.shape.rawValue),
            color: MemberColor(code: p.color.rawValue)
          )
        }
      )
    }

    let dueRecurringActions: [OverviewRecurringDueAction] = (dto.dueRecurringActions ?? []).map {
      action in
      OverviewRecurringDueAction(
        id: RecurringExpense.ID(action.id),
        groupId: ExpenseGroup.ID(action.groupId),
        groupName: action.groupName,
        description: action.description,
        dueDate: action.dueDate,
        suggestedAmount: action.suggestedAmount.map { Money(Int64($0)) },
        payerMemberId: Member.ID(action.payerMemberId),
        payerName: action.payerName
      )
    }

    return OverviewSummary(
      totalOwedToMe: Money(Int64(dto.totalOwedToMe)),
      totalIOwe: Money(Int64(dto.totalIOwe)),
      netBalance: Money(Int64(dto.netBalance)),
      pendingActions: pendingActions,
      groupBalances: groupBalances,
      dueRecurringCount: dto.dueRecurringCount ?? dueRecurringActions.count,
      dueRecurringActions: dueRecurringActions
    )
  }

  static func mapPersonalTransaction(
    _ dto: Components.Schemas.PersonalTransactionDto
  ) -> PersonalTransaction {
    PersonalTransaction(
      transactionId: LedgerTransaction.ID(dto.id),
      groupId: ExpenseGroup.ID(dto.groupId),
      groupName: dto.groupName,
      type: TransactionType(code: dto._type.rawValue),
      description: dto.description,
      amount: Money(Int64(dto.amount)),
      myDelta: Money(Int64(dto.myDelta)),
      occurredAt: formatISO(dto.occurredAt),
      category: dto.category.flatMap { TransactionCategory(code: $0.rawValue) },
      payerSummary: dto.payerSummary
    )
  }

  // MARK: - Resilient snapshot decoding / encoding

  struct RawPreviewMember: Codable, Sendable {
    let id: String
    let name: String
    let shape: String
    let color: String
  }

  struct RawPendingAction: Codable, Sendable {
    let id: String
    let kind: String
    let groupId: String
    let groupName: String
    let transactionId: String?
    let description: String
    let amount: Int64
    let occurredAt: String
    let actorName: String

    func toDomain() -> OverviewPendingAction {
      OverviewPendingAction(
        id: OverviewPendingAction.ID(id),
        kind: OverviewPendingActionKind(raw: kind),
        groupId: ExpenseGroup.ID(groupId),
        groupName: groupName,
        transactionId: transactionId.map(LedgerTransaction.ID.init),
        description: description,
        amount: Money(amount),
        occurredAt: occurredAt,
        actorName: actorName
      )
    }
  }

  struct RawGroupBalance: Codable, Sendable {
    let groupId: String
    let groupName: String
    let myBalance: Int64
    let myIndividualBalance: Int64?
    let householdName: String?
    let role: String
    let archivedAt: String?
    let memberCount: Int
    let previewMembers: [RawPreviewMember]

    func toDomain() -> OverviewGroupBalance {
      OverviewGroupBalance(
        groupId: ExpenseGroup.ID(groupId),
        groupName: groupName,
        myBalance: Money(myBalance),
        myIndividualBalance: myIndividualBalance.map(Money.init),
        householdName: householdName,
        role: Role(code: role),
        archivedAt: archivedAt.flatMap(ISO8601Support.parse),
        memberCount: memberCount,
        previewMembers: previewMembers.map { p in
          ExpenseGroup.PreviewMember(
            id: Member.ID(p.id),
            name: p.name,
            shape: MemberShape(code: p.shape),
            color: MemberColor(code: p.color)
          )
        }
      )
    }
  }

  struct RawRecurringDueAction: Codable, Sendable {
    let id: String
    let groupId: String
    let groupName: String
    let description: String
    let dueDate: String
    let suggestedAmount: Int64?
    let payerMemberId: String
    let payerName: String

    func toDomain() -> OverviewRecurringDueAction {
      OverviewRecurringDueAction(
        id: RecurringExpense.ID(id),
        groupId: ExpenseGroup.ID(groupId),
        groupName: groupName,
        description: description,
        dueDate: dueDate,
        suggestedAmount: suggestedAmount.map(Money.init),
        payerMemberId: Member.ID(payerMemberId),
        payerName: payerName
      )
    }
  }

  struct RawOverviewSummary: Codable, Sendable {
    let totalOwedToMe: Int64
    let totalIOwe: Int64
    let netBalance: Int64
    let pendingActions: [RawPendingAction]
    let groupBalances: [RawGroupBalance]
    let dueRecurringCount: Int?
    let dueRecurringActions: [RawRecurringDueAction]?

    func toDomain() -> OverviewSummary {
      let actions = (dueRecurringActions ?? []).map { $0.toDomain() }
      return OverviewSummary(
        totalOwedToMe: Money(totalOwedToMe),
        totalIOwe: Money(totalIOwe),
        netBalance: Money(netBalance),
        pendingActions: pendingActions.map { $0.toDomain() },
        groupBalances: groupBalances.map { $0.toDomain() },
        dueRecurringCount: dueRecurringCount ?? actions.count,
        dueRecurringActions: actions
      )
    }
  }

  static func decodeResilientOverview(from data: Data) throws -> OverviewSummary {
    try JSONDecoder().decode(RawOverviewSummary.self, from: data).toDomain()
  }

  static func encodeOverviewSnapshot(_ summary: OverviewSummary) -> Data? {
    let payload = RawOverviewSummary(
      totalOwedToMe: summary.totalOwedToMe.amount,
      totalIOwe: summary.totalIOwe.amount,
      netBalance: summary.netBalance.amount,
      pendingActions: summary.pendingActions.map { a in
        RawPendingAction(
          id: a.id.rawValue,
          kind: a.kind.rawValue,
          groupId: a.groupId.rawValue,
          groupName: a.groupName,
          transactionId: a.transactionId?.rawValue,
          description: a.description,
          amount: a.amount.amount,
          occurredAt: a.occurredAt,
          actorName: a.actorName
        )
      },
      groupBalances: summary.groupBalances.map { gb in
        RawGroupBalance(
          groupId: gb.groupId.rawValue,
          groupName: gb.groupName,
          myBalance: gb.myBalance.amount,
          myIndividualBalance: gb.myIndividualBalance?.amount,
          householdName: gb.householdName,
          role: gb.role.code,
          archivedAt: gb.archivedAt.map { formatISO($0) },
          memberCount: gb.memberCount,
          previewMembers: gb.previewMembers.map { p in
            RawPreviewMember(
              id: p.id.rawValue,
              name: p.name,
              shape: p.shape.code,
              color: p.color.code
            )
          }
        )
      },
      dueRecurringCount: summary.dueRecurringCount,
      dueRecurringActions: summary.dueRecurringActions.map { action in
        RawRecurringDueAction(
          id: action.id.rawValue,
          groupId: action.groupId.rawValue,
          groupName: action.groupName,
          description: action.description,
          dueDate: action.dueDate,
          suggestedAmount: action.suggestedAmount?.amount,
          payerMemberId: action.payerMemberId.rawValue,
          payerName: action.payerName
        )
      }
    )
    return try? JSONEncoder().encode(payload)
  }
}
