#if DEBUG
  public import Domain
  public import Foundation

  extension FakeWorld {
    public nonisolated static let defaultTripCategories: [GroupCategory] = [
      GroupCategory(
        id: GroupCategory.ID("00000000-0000-7000-8000-000000000901"),
        name: "Cà phê",
        color: .coral
      ),
      GroupCategory(
        id: GroupCategory.ID("00000000-0000-7000-8000-000000000902"),
        name: "Quà lưu niệm",
        color: .lilac
      ),
    ]

    public func lastKnownCategories(groupId: ExpenseGroup.ID) -> [GroupCategory]? {
      guard behavior.hasSnapshot else { return nil }
      return categoriesByGroup[groupId] ?? []
    }

    public func listCategories(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupCategory] {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      return categoriesByGroup[groupId] ?? []
    }

    public func createCategory(
      groupId: ExpenseGroup.ID,
      name: String,
      color: MemberColor,
      key: IdempotencyKey
    ) async throws(AppError) -> GroupCategory {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      let list = categoriesByGroup[groupId] ?? []
      if seenIdempotencyKeys.contains(key), let existing = list.last {
        return existing
      }
      let live = list.filter { !$0.archived }
      if live.count >= 30 {
        throw .api(code: "LIMIT_REACHED", status: 409)
      }
      if live.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
        throw .api(code: "CATEGORY_EXISTS", status: 409)
      }
      seenIdempotencyKeys.insert(key)
      let created = GroupCategory(
        id: GroupCategory.ID(UUID().uuidString.lowercased()),
        name: name,
        color: color,
        archived: false
      )
      categoriesByGroup[groupId] = list + [created]
      return created
    }

    public func updateCategory(
      groupId: ExpenseGroup.ID,
      categoryId: GroupCategory.ID,
      name: String?,
      color: MemberColor?
    ) async throws(AppError) -> GroupCategory {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = categoriesByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == categoryId }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      if let name,
        list.contains(where: {
          !$0.archived
            && $0.id != categoryId
            && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        })
      {
        throw .api(code: "CATEGORY_EXISTS", status: 409)
      }
      if let name { list[idx].name = name }
      if let color { list[idx].color = color }
      categoriesByGroup[groupId] = list
      return list[idx]
    }

    public func archiveCategory(
      groupId: ExpenseGroup.ID,
      categoryId: GroupCategory.ID
    ) async throws(AppError) {
      try await simulateNetwork()
      guard let group = groupsById[groupId] else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      guard group.role.canWrite else {
        throw .api(code: "FORBIDDEN", status: 403)
      }
      var list = categoriesByGroup[groupId] ?? []
      guard let idx = list.firstIndex(where: { $0.id == categoryId }) else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      list[idx].archived = true
      categoriesByGroup[groupId] = list
    }

    public func fetchStats(
      groupId: ExpenseGroup.ID,
      from: String?,
      to: String?
    ) async throws(AppError) -> GroupStats {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let transactions = transactionsByGroup[groupId] ?? []
      if transactions.isEmpty || (from == "2020-01-01" && to == "2020-01-31") {
        return GroupStats(
          from: from ?? "2026-11-01",
          to: to ?? "2026-11-30",
          bucket: .day,
          total: .zero,
          byCategory: [],
          byMember: [],
          byBucket: []
        )
      }
      return GroupStats(
        from: from ?? "2026-11-10",
        to: to ?? "2026-11-10",
        bucket: .day,
        total: Money(1_599_999),
        byCategory: [
          CategoryStat(category: .lodging, amount: Money(1_200_000)),
          CategoryStat(category: .food, amount: Money(300_000)),
          CategoryStat(category: .transport, amount: Money(99_999)),
        ],
        byMember: [
          MemberStat(memberId: TripScenario.minhId, paid: Money(1_200_000), share: Money(600_000)),
          MemberStat(memberId: TripScenario.lanId, paid: Money(300_000), share: Money(370_000)),
          MemberStat(memberId: TripScenario.hungId, paid: Money(99_999), share: Money(369_999)),
          MemberStat(memberId: TripScenario.thuId, paid: Money(0), share: Money(260_000)),
        ],
        byBucket: [
          TimeBucketStat(start: "2026-11-10", amount: Money(1_599_999))
        ]
      )
    }

    public func exportCSV(groupId: ExpenseGroup.ID) async throws(AppError) -> Data {
      try await simulateNetwork()
      guard groupsById[groupId] != nil else {
        throw .api(code: "NOT_FOUND", status: 404)
      }
      let csv = """
        Ngày,Loại,Mô tả,Danh mục,Tổng tiền,Người trả
        2026-11-10,Chi tiêu,Khách sạn,Lưu trú,1200000,"Minh: 800000; Lan: 400000"
        2026-11-10,Chi tiêu,Lẩu,Ăn uống,300000,Minh
        """
      var bytes = Data([0xEF, 0xBB, 0xBF])
      bytes.append(Data(csv.utf8))
      return bytes
    }
  }
#endif
