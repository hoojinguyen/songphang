#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    // MARK: - Recurring Expenses

    public func listRecurringExpenses(
      groupId: ExpenseGroup.ID
    ) async throws(AppError) -> [RecurringExpense] {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return recurringExpensesByGroup[groupId] ?? []
    }

    public func createRecurringExpense(
      groupId: ExpenseGroup.ID,
      input: CreateRecurringExpenseInput,
      key: IdempotencyKey
    ) async throws(AppError) -> RecurringExpense {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = recurringExpensesByGroup[groupId] ?? []
      if seenIdempotencyKeys.contains(key), let existing = list.first {
        return existing
      }
      seenIdempotencyKeys.insert(key)
      let created = RecurringExpense(
        id: RecurringExpense.ID(UUID().uuidString.lowercased()),
        groupId: groupId,
        mode: input.mode,
        active: true,
        description: input.description,
        amount: input.amount,
        category: input.category,
        categoryId: input.categoryId,
        payersTemplate: input.payersTemplate,
        splitTemplate: input.splitTemplate,
        frequency: input.frequency,
        dayOfWeek: input.dayOfWeek,
        dayOfMonth: input.dayOfMonth,
        monthOfYear: input.monthOfYear,
        nextDueDate: "2026-12-05"
      )
      list.insert(created, at: 0)
      recurringExpensesByGroup[groupId] = list
      return created
    }

    public func updateRecurringExpense(
      groupId: ExpenseGroup.ID,
      id: RecurringExpense.ID,
      input: UpdateRecurringExpenseInput
    ) async throws(AppError) -> RecurringExpense {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = recurringExpensesByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == id }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let mode = input.mode { list[idx].mode = mode }
      if let active = input.active {
        list[idx].active = active
        if active { list[idx].pauseReason = nil }
      }
      if let desc = input.description { list[idx].description = desc }
      if case .set(let amt) = input.amount {
        list[idx].amount = amt
      } else if case .clear = input.amount {
        list[idx].amount = nil
      }
      if case .set(let cat) = input.category {
        list[idx].category = cat
      } else if case .clear = input.category {
        list[idx].category = nil
      }
      if case .set(let catId) = input.categoryId {
        list[idx].categoryId = catId
      } else if case .clear = input.categoryId {
        list[idx].categoryId = nil
      }
      if let payers = input.payersTemplate { list[idx].payersTemplate = payers }
      if let split = input.splitTemplate { list[idx].splitTemplate = split }
      if let freq = input.frequency { list[idx].frequency = freq }
      if case .set(let dow) = input.dayOfWeek {
        list[idx].dayOfWeek = dow
      } else if case .clear = input.dayOfWeek {
        list[idx].dayOfWeek = nil
      }
      if case .set(let dom) = input.dayOfMonth {
        list[idx].dayOfMonth = dom
      } else if case .clear = input.dayOfMonth {
        list[idx].dayOfMonth = nil
      }
      if case .set(let moy) = input.monthOfYear {
        list[idx].monthOfYear = moy
      } else if case .clear = input.monthOfYear {
        list[idx].monthOfYear = nil
      }
      recurringExpensesByGroup[groupId] = list
      return list[idx]
    }

    public func deleteRecurringExpense(
      groupId: ExpenseGroup.ID,
      id: RecurringExpense.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = recurringExpensesByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == id }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      list.remove(at: idx)
      recurringExpensesByGroup[groupId] = list
    }

    public func skipRecurringExpense(
      groupId: ExpenseGroup.ID,
      id: RecurringExpense.ID
    ) async throws(AppError) -> RecurringExpense {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = recurringExpensesByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == id }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if list[idx].pendingDueDate != nil {
        list[idx].pendingDueDate = nil
      } else {
        list[idx].nextDueDate = "2027-01-05"
      }
      recurringExpensesByGroup[groupId] = list
      return list[idx]
    }

    // MARK: - Households

    public func listHouseholds(groupId: ExpenseGroup.ID) async throws(AppError) -> [Household] {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return householdsByGroup[groupId] ?? []
    }

    public func createHousehold(
      groupId: ExpenseGroup.ID,
      input: CreateHouseholdInput,
      key: IdempotencyKey
    ) async throws(AppError) -> Household {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = householdsByGroup[groupId] ?? []
      if seenIdempotencyKeys.contains(key), let existing = list.first {
        return existing
      }
      var members = membersByGroup[groupId] ?? []
      let memberIdSet = Set(input.memberIds)
      if members.contains(where: { memberIdSet.contains($0.id) && $0.householdId != nil }) {
        throw .householdMemberConflict
      }
      guard input.memberIds.count >= 2,
        input.memberIds.contains(input.representativeMemberId),
        members.first(where: { $0.id == input.representativeMemberId })?.active == true
      else {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      seenIdempotencyKeys.insert(key)
      let household = Household(
        id: Household.ID(UUID().uuidString.lowercased()),
        name: input.name,
        representativeMemberId: input.representativeMemberId,
        memberIds: input.memberIds
      )
      for idx in members.indices where memberIdSet.contains(members[idx].id) {
        members[idx].householdId = household.id
      }
      membersByGroup[groupId] = members
      list.append(household)
      householdsByGroup[groupId] = list
      return household
    }

    public func updateHousehold(
      groupId: ExpenseGroup.ID,
      id: Household.ID,
      input: UpdateHouseholdInput
    ) async throws(AppError) -> Household {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = householdsByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == id }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      var members = membersByGroup[groupId] ?? []
      if let newMemberIds = input.memberIds {
        let newSet = Set(newMemberIds)
        if members.contains(where: {
          newSet.contains($0.id) && $0.householdId != nil && $0.householdId != id
        }) {
          throw .householdMemberConflict
        }
        for mIdx in members.indices {
          if members[mIdx].householdId == id && !newSet.contains(members[mIdx].id) {
            members[mIdx].householdId = nil
          } else if newSet.contains(members[mIdx].id) {
            members[mIdx].householdId = id
          }
        }
        list[idx].memberIds = newMemberIds
      }
      if let repId = input.representativeMemberId {
        guard list[idx].memberIds.contains(repId),
          members.first(where: { $0.id == repId })?.active == true
        else {
          throw .api(code: "VALIDATION_FAILED", status: 400)
        }
        list[idx].representativeMemberId = repId
      }
      if let name = input.name {
        list[idx].name = name
      }
      membersByGroup[groupId] = members
      householdsByGroup[groupId] = list
      return list[idx]
    }

    public func deleteHousehold(
      groupId: ExpenseGroup.ID,
      id: Household.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      guard !group.isArchived else {
        throw .groupArchived
      }
      var list = householdsByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == id }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      list.remove(at: idx)
      householdsByGroup[groupId] = list
      if var members = membersByGroup[groupId] {
        for mIdx in members.indices where members[mIdx].householdId == id {
          members[mIdx].householdId = nil
        }
        membersByGroup[groupId] = members
      }
    }
  }
#endif
