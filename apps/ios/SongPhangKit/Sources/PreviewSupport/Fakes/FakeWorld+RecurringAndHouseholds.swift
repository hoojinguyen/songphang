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

    private static func nextDueDateVN(
      frequency: RecurringFrequency,
      dayOfWeek: Int?,
      dayOfMonth: Int?,
      monthOfYear: Int?,
      afterVN: String,
      inclusive: Bool
    ) -> String {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt
      let formatter = DateFormatter()
      formatter.calendar = calendar
      formatter.timeZone = calendar.timeZone
      formatter.dateFormat = "yyyy-MM-dd"
      guard let anchorDate = formatter.date(from: afterVN) else { return afterVN }

      var cursor =
        inclusive
        ? anchorDate : (calendar.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate)
      for _ in 0..<800 {
        let comps = calendar.dateComponents([.month, .day, .weekday], from: cursor)
        guard let month = comps.month, let day = comps.day,
          let sysWeekday = comps.weekday
        else { break }
        let isoDow = ((sysWeekday + 5) % 7) + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: cursor)?.count ?? 30
        switch frequency {
        case .weekly:
          if isoDow == (dayOfWeek ?? 1) {
            return formatter.string(from: cursor)
          }
        case .monthly:
          let clamped = min(max(1, dayOfMonth ?? 1), daysInMonth)
          if day == clamped {
            return formatter.string(from: cursor)
          }
        case .quarterly:
          let clamped = min(max(1, dayOfMonth ?? 1), daysInMonth)
          if month == 1 || month == 4 || month == 7 || month == 10, day == clamped {
            return formatter.string(from: cursor)
          }
        case .yearly:
          let targetMonth = min(max(1, monthOfYear ?? 1), 12)
          let clamped = min(max(1, dayOfMonth ?? 1), daysInMonth)
          if month == targetMonth, day == clamped {
            return formatter.string(from: cursor)
          }
        case .unknown:
          return formatter.string(from: cursor)
        }
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
        cursor = nextDay
      }
      return afterVN
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
      let nextDue = Self.nextDueDateVN(
        frequency: input.frequency,
        dayOfWeek: input.dayOfWeek,
        dayOfMonth: input.dayOfMonth,
        monthOfYear: input.monthOfYear,
        afterVN: "2026-11-26",
        inclusive: true
      )
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
        nextDueDate: nextDue
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
      let wasActive = list[idx].active
      if let mode = input.mode { list[idx].mode = mode }
      if let active = input.active {
        list[idx].active = active
        if active { list[idx].pauseReason = nil }
      }
      if !list[idx].active || list[idx].mode == .fixed {
        list[idx].pendingDueDate = nil
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
      var scheduleChanged = false
      if let freq = input.frequency {
        list[idx].frequency = freq
        scheduleChanged = true
      }
      if case .set(let dow) = input.dayOfWeek {
        list[idx].dayOfWeek = dow
        scheduleChanged = true
      } else if case .clear = input.dayOfWeek {
        list[idx].dayOfWeek = nil
        scheduleChanged = true
      }
      if case .set(let dom) = input.dayOfMonth {
        list[idx].dayOfMonth = dom
        scheduleChanged = true
      } else if case .clear = input.dayOfMonth {
        list[idx].dayOfMonth = nil
        scheduleChanged = true
      }
      if case .set(let moy) = input.monthOfYear {
        list[idx].monthOfYear = moy
        scheduleChanged = true
      } else if case .clear = input.monthOfYear {
        list[idx].monthOfYear = nil
        scheduleChanged = true
      }
      let resumingStale = !wasActive && list[idx].active && list[idx].nextDueDate < "2026-11-26"
      if scheduleChanged || resumingStale {
        list[idx].nextDueDate = Self.nextDueDateVN(
          frequency: list[idx].frequency,
          dayOfWeek: list[idx].dayOfWeek,
          dayOfMonth: list[idx].dayOfMonth,
          monthOfYear: list[idx].monthOfYear,
          afterVN: "2026-11-26",
          inclusive: true
        )
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
        list[idx].nextDueDate = Self.nextDueDateVN(
          frequency: list[idx].frequency,
          dayOfWeek: list[idx].dayOfWeek,
          dayOfMonth: list[idx].dayOfMonth,
          monthOfYear: list[idx].monthOfYear,
          afterVN: list[idx].nextDueDate,
          inclusive: false
        )
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
      let trimmedName = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
      let memberIdSet = Set(input.memberIds)
      let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
      guard list.count < 30,
        !trimmedName.isEmpty,
        trimmedName.count <= 50,
        input.memberIds.count >= 2,
        input.memberIds.count <= 20,
        memberIdSet.count == input.memberIds.count,
        input.memberIds.allSatisfy({ memberById[$0]?.kind == .person }),
        input.memberIds.contains(input.representativeMemberId),
        memberById[input.representativeMemberId]?.active == true
      else {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      if members.contains(where: { memberIdSet.contains($0.id) && $0.householdId != nil }) {
        throw .householdMemberConflict
      }
      seenIdempotencyKeys.insert(key)
      let household = Household(
        id: Household.ID(UUID().uuidString.lowercased()),
        name: trimmedName,
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
      let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
      let resultingName =
        input.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? list[idx].name
      let resultingMemberIds = input.memberIds ?? list[idx].memberIds
      let resultingRepId = input.representativeMemberId ?? list[idx].representativeMemberId
      let resultingSet = Set(resultingMemberIds)
      guard !resultingName.isEmpty,
        resultingName.count <= 50,
        resultingMemberIds.count >= 2,
        resultingMemberIds.count <= 20,
        resultingSet.count == resultingMemberIds.count,
        resultingMemberIds.allSatisfy({ memberById[$0]?.kind == .person }),
        resultingSet.contains(resultingRepId),
        memberById[resultingRepId]?.active == true
      else {
        throw .api(code: "VALIDATION_FAILED", status: 400)
      }
      if members.contains(where: {
        resultingSet.contains($0.id) && $0.householdId != nil && $0.householdId != id
      }) {
        throw .householdMemberConflict
      }
      if input.memberIds != nil {
        for mIdx in members.indices {
          if members[mIdx].householdId == id && !resultingSet.contains(members[mIdx].id) {
            members[mIdx].householdId = nil
          } else if resultingSet.contains(members[mIdx].id) {
            members[mIdx].householdId = id
          }
        }
        list[idx].memberIds = resultingMemberIds
      }
      list[idx].representativeMemberId = resultingRepId
      list[idx].name = resultingName
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
