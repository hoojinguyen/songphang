#if DEBUG
  public import Domain

  public nonisolated enum LargeScenario {
    public static let groupId = TripScenario.groupId
    public static let group = TripScenario.group(forStep: 4, role: .owner)
    public static let members = TripScenario.members
    public static let balances = TripScenario.step4Balances

    public static let transactions: [LedgerTransaction] = {
      let templates = [
        TripScenario.t4Transaction,
        TripScenario.t3Transaction,
        TripScenario.t2Transaction,
        TripScenario.t1Transaction,
      ]
      var rows: [LedgerTransaction] = []
      rows.reserveCapacity(500)
      var index = 0
      while index < 500 {
        for template in templates where rows.count < 500 {
          var row = template
          let number = index + 1
          row = LedgerTransaction(
            id: LedgerTransaction.ID("large-tx-\(number)"),
            type: template.type,
            description: "\(template.description) #\(number)",
            amount: template.amount,
            currency: template.currency,
            occurredAt: "2026-11-10T12:00:00.000Z",
            category: template.category,
            payers: template.payers,
            split: template.split,
            shares: template.shares,
            version: 1,
            updatedBy: template.updatedBy,
            createdBy: template.createdBy,
            createdAt: template.createdAt,
            updatedAt: template.updatedAt,
            deletedAt: nil
          )
          rows.append(row)
          index += 1
        }
      }
      return rows
    }()
  }
#endif
