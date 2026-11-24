#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public func listGroups(status: GroupListStatus?) async throws(AppError) -> [ExpenseGroup] {
      try await simulateNetwork()
      let all = groupOrder.compactMap { groupsById[$0] }
      switch status {
      case .active:
        return all.filter { !$0.isArchived }
      case .archived:
        return all.filter { $0.isArchived }
      case nil:
        return all
      }
    }

    public func archiveGroup(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      guard var group = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      group.archivedAt = Date()
      groupsById[id] = group
      return group
    }

    public func unarchiveGroup(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      guard var group = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      group.archivedAt = nil
      groupsById[id] = group
      return group
    }

    public func cloneGroup(
      id: ExpenseGroup.ID,
      name: String,
      copyPaymentMethods: Bool,
      copyCategories: Bool,
      key: IdempotencyKey
    ) async throws(AppError) -> ExpenseGroup {
      try await simulateNetwork()
      guard let source = groupsById[id] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      seenIdempotencyKeys.insert(key)
      let newId = ExpenseGroup.ID("cloned-\(UUID().uuidString.prefix(8))")
      let cloned = ExpenseGroup(
        id: newId,
        name: name,
        currency: source.currency,
        memberCount: source.memberCount,
        previewMembers: source.previewMembers,
        myBalance: .zero,
        minimizeDebts: source.minimizeDebts,
        defaultRole: source.defaultRole,
        role: .owner,
        myMemberId: source.myMemberId,
        muted: false,
        reminderIntervalDays: nil,
        approvalThreshold: source.approvalThreshold,
        ownerName: currentUser?.name ?? "Minh",
        createdAt: Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(Date()),
        archivedAt: nil,
        pendingActionCount: 0
      )
      groupsById[newId] = cloned
      groupOrder.insert(newId, at: 0)
      if let members = membersByGroup[id] {
        membersByGroup[newId] = members
      }
      balancesByGroup[newId] = GroupBalances(balances: [], transfers: [])
      transactionsByGroup[newId] = []
      return cloned
    }

    public func lastKnownOverview() -> OverviewSummary? {
      guard behavior.hasSnapshot else { return nil }
      return buildOverviewSummary()
    }

    public func fetchOverview() async throws(AppError) -> OverviewSummary {
      try await simulateNetwork()
      return buildOverviewSummary()
    }

    private func buildOverviewSummary() -> OverviewSummary {
      let allGroups = groupOrder.compactMap { groupsById[$0] }
      let activeGroups = allGroups.filter { !$0.isArchived }

      var totalOwedToMe: Int64 = 0
      var totalIOwe: Int64 = 0

      var groupBalances: [OverviewGroupBalance] = []
      for group in allGroups {
        let bal = group.myBalance
        if bal.amount > 0 {
          totalOwedToMe += bal.amount
        } else if bal.amount < 0 {
          totalIOwe += -bal.amount
        }
        groupBalances.append(
          OverviewGroupBalance(
            groupId: group.id,
            groupName: group.name,
            myBalance: bal,
            role: group.role,
            archivedAt: group.archivedAt,
            memberCount: group.memberCount,
            previewMembers: group.previewMembers
          )
        )
      }

      let netBalance = Money(totalOwedToMe - totalIOwe)

      var pendingActions: [OverviewPendingAction] = []
      for group in activeGroups {
        if let txs = transactionsByGroup[group.id] {
          for tx in txs {
            if tx.approval.status == LedgerTransaction.TransactionApproval.Status.pending {
              pendingActions.append(
                OverviewPendingAction(
                  id: OverviewPendingAction.ID("approval-\(tx.id.rawValue)"),
                  kind: .expenseApproval,
                  groupId: group.id,
                  groupName: group.name,
                  transactionId: tx.id,
                  description: tx.description,
                  amount: tx.amount,
                  occurredAt: tx.occurredAt,
                  actorName: tx.createdBy?.name ?? "Thành viên"
                )
              )
            }
          }
        }
      }

      return OverviewSummary(
        totalOwedToMe: Money(totalOwedToMe),
        totalIOwe: Money(totalIOwe),
        netBalance: netBalance,
        pendingActions: pendingActions,
        groupBalances: groupBalances
      )
    }

    public func fetchPersonalTransactions(
      cursor: String?,
      limit: Int,
      type: TransactionType?,
      groupId: ExpenseGroup.ID?,
      query: String?
    ) async throws(AppError) -> PersonalTransactionsPage {
      try await simulateNetwork()
      var results: [PersonalTransaction] = []

      let targetGroups =
        groupId != nil
        ? groupOrder.filter { $0 == groupId }.compactMap { groupsById[$0] }
        : groupOrder.compactMap { groupsById[$0] }

      for group in targetGroups {
        if let txs = transactionsByGroup[group.id] {
          for tx in txs {
            if let type, tx.type != type { continue }
            if let query, !query.isEmpty {
              if !tx.description.localizedCaseInsensitiveContains(query) {
                continue
              }
            }
            results.append(
              PersonalTransaction(
                transactionId: tx.id,
                groupId: group.id,
                groupName: group.name,
                type: tx.type,
                description: tx.description,
                amount: tx.amount,
                myDelta: tx.myDelta ?? tx.amount,
                occurredAt: tx.occurredAt,
                category: tx.category,
                payerSummary: tx.payers.first.map { _ in "Người trả" } ?? ""
              )
            )
          }
        }
      }

      let paged = Array(results.prefix(limit))
      let nextCursor = results.count > limit ? "next-cursor" : nil
      return PersonalTransactionsPage(items: paged, nextCursor: nextCursor)
    }
  }
#endif
