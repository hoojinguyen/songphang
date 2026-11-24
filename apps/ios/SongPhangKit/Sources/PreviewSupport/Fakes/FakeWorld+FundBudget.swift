#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public nonisolated static let sampleFund = FundSummary(
      memberId: Member.ID("00000000-0000-7000-8000-000000000888"),
      name: "Quỹ chung",
      holderMemberId: TripScenario.minhId,
      active: true,
      cash: Money(350_000),
      contributions: [
        FundContribution(memberId: TripScenario.minhId, amount: Money(200_000)),
        FundContribution(memberId: TripScenario.lanId, amount: Money(150_000)),
      ]
    )

    public nonisolated static let sampleBudgetNear = GroupBudget(
      period: .total,
      amount: Money(2_000_000),
      spent: Money(1_700_000),
      state: .near
    )

    public func seedSampleFundAndBudget(groupId: ExpenseGroup.ID = TripScenario.groupId) {
      let fundMember = Member(
        id: Self.sampleFund.memberId,
        name: Self.sampleFund.name,
        kind: .fund,
        fundHolderMemberId: Self.sampleFund.holderMemberId,
        active: true,
        position: 99,
        shape: .unknown("fund"),
        color: .unknown("sun"),
        isMe: false,
        claimed: false
      )
      var list = membersByGroup[groupId] ?? []
      if !list.contains(where: { $0.id == fundMember.id }) {
        list.append(fundMember)
        membersByGroup[groupId] = list
      }
      if let bal = balancesByGroup[groupId] {
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: bal.balances,
          transfers: bal.transfers,
          fund: Self.sampleFund
        )
      }
      budgetsByGroup[groupId] = Self.sampleBudgetNear
    }

    public func createFund(
      groupId: ExpenseGroup.ID,
      name: String?,
      holderMemberId: Member.ID?,
      key: IdempotencyKey
    ) async throws(AppError) -> Member {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = membersByGroup[groupId] ?? []
      if let existing = list.first(where: { $0.kind == .fund }) {
        if seenIdempotencyKeys.contains(key) {
          return existing
        }
        throw .api(code: "FUND_EXISTS", status: 409)
      }
      seenIdempotencyKeys.insert(key)
      let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
      let fundName = (trimmed?.isEmpty == false) ? (trimmed ?? "Quỹ chung") : "Quỹ chung"
      let fundMember = Member(
        id: Self.sampleFund.memberId,
        name: fundName,
        kind: .fund,
        fundHolderMemberId: holderMemberId,
        active: true,
        position: (list.last?.position ?? 0) + 1,
        shape: .unknown("fund"),
        color: .unknown("sun"),
        isMe: false,
        claimed: false
      )
      list.append(fundMember)
      membersByGroup[groupId] = list
      if let bal = balancesByGroup[groupId] {
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: bal.balances,
          transfers: bal.transfers,
          fund: FundSummary(
            memberId: fundMember.id,
            name: fundMember.name,
            holderMemberId: holderMemberId,
            active: true,
            cash: .zero,
            contributions: []
          )
        )
      }
      return fundMember
    }

    public func updateFund(
      groupId: ExpenseGroup.ID,
      name: String?,
      holder: FundHolderUpdate,
      active: Bool?
    ) async throws(AppError) -> Member {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = membersByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.kind == .fund }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if active == false, let fundSummary = balancesByGroup[groupId]?.fund,
        fundSummary.cash != .zero
      {
        throw .api(code: "FUND_NOT_EMPTY", status: 422)
      }
      if let name { list[idx].name = name }
      switch holder {
      case .unchanged: break
      case .set(let id): list[idx].fundHolderMemberId = id
      case .clear: list[idx].fundHolderMemberId = nil
      }
      if let active { list[idx].active = active }
      membersByGroup[groupId] = list
      if let bal = balancesByGroup[groupId], let existingFund = bal.fund {
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: bal.balances,
          transfers: bal.transfers,
          fund: FundSummary(
            memberId: existingFund.memberId,
            name: list[idx].name,
            holderMemberId: list[idx].fundHolderMemberId,
            active: list[idx].active,
            cash: existingFund.cash,
            contributions: existingFund.contributions
          )
        )
      }
      return list[idx]
    }

    public func deleteFund(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = membersByGroup[groupId] ?? []
      guard let fundMember = list.first(where: { $0.kind == .fund }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let hasTx = (transactionsByGroup[groupId] ?? []).contains { tx in
        tx.payers.contains(where: { $0.memberId == fundMember.id })
          || tx.shares.contains(where: { $0.memberId == fundMember.id })
      }
      if hasTx {
        throw .api(code: "MEMBER_HAS_TRANSACTIONS", status: 409)
      }
      list.removeAll { $0.id == fundMember.id }
      membersByGroup[groupId] = list
      if let bal = balancesByGroup[groupId] {
        balancesByGroup[groupId] = GroupBalances(
          currency: bal.currency,
          minimized: bal.minimized,
          balances: bal.balances,
          transfers: bal.transfers,
          fund: nil
        )
      }
    }

    public func lastKnownBudget(groupId: ExpenseGroup.ID) -> GroupBudget? {
      guard behavior.hasSnapshot else { return nil }
      return budgetsByGroup[groupId]
    }

    public func fetchBudget(groupId: ExpenseGroup.ID) async throws(AppError) -> GroupBudget? {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return budgetsByGroup[groupId]
    }

    public func setBudget(
      groupId: ExpenseGroup.ID,
      period: BudgetPeriod,
      amount: Money
    ) async throws(AppError) -> GroupBudget {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.isOwner else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      let saved = GroupBudget(
        period: period,
        amount: amount,
        spent: budgetsByGroup[groupId]?.spent ?? .zero,
        state: .ok
      )
      budgetsByGroup[groupId] = saved
      return saved
    }

    public func deleteBudget(groupId: ExpenseGroup.ID) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.isOwner else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      budgetsByGroup.removeValue(forKey: groupId)
    }
  }
#endif
