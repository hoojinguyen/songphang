import Domain
import Foundation
import GeneratedAPI

enum TransactionMapping {
  static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  static func parseISO(_ value: String) -> Date {
    if let parsed = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value) {
      return parsed
    }
    if let parsed = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(value) {
      return parsed
    }
    return Date()
  }

  static func mapSplitInput(_ dto: Components.Schemas.SplitInput) -> SplitSpec {
    switch dto {
    case .case1(let eq):
      return .equal(members: eq.members.map(Member.ID.init))
    case .case2(let ex):
      return .exact(
        members: ex.members.map(Member.ID.init),
        entries: ex.entries.map {
          SplitSpec.ExactEntry(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
        },
        remainder: ExactRemainderMode(code: ex.remainder.rawValue)
      )
    case .case3(let sh):
      return .shares(
        entries: sh.entries.map {
          SplitSpec.ShareWeightEntry(memberId: Member.ID($0.memberId), weight: $0.weight)
        }
      )
    case .case4(let pct):
      return .percent(
        entries: pct.entries.map {
          SplitSpec.PercentEntry(memberId: Member.ID($0.memberId), percent: $0.percent)
        }
      )
    case .case5(let items):
      return .items(
        items: items.items.map {
          SplitSpec.ItemEntry(
            name: $0.name,
            amount: Money(Int64($0.amount)),
            memberIds: $0.memberIds.map(Member.ID.init)
          )
        },
        extras: items.extras.map {
          SplitSpec.ItemsExtra(
            kind: ReceiptExtraKind(code: $0.kind.rawValue),
            label: $0.label,
            amount: Money(Int64($0.amount))
          )
        }
      )
    }
  }

  static func encodeSplitInput(_ spec: SplitSpec) -> Components.Schemas.SplitInput {
    switch spec {
    case .equal(let members):
      return .case1(.init(members: members.map(\.rawValue), method: .equal))
    case .exact(let members, let entries, let remainder):
      let remPayload: Components.Schemas.SplitInput.Case2Payload.remainderPayload = {
        switch remainder {
        case .equalAmongBlank: return .equal_among_blank
        case .equalAmongAll: return .equal_among_all
        default: return .none
        }
      }()
      return .case2(
        .init(
          entries: entries.map {
            .init(amount: Int($0.amount.amount), memberId: $0.memberId.rawValue)
          },
          members: members.map(\.rawValue),
          method: .exact,
          remainder: remPayload
        )
      )
    case .shares(let entries):
      return .case3(
        .init(
          entries: entries.map { .init(memberId: $0.memberId.rawValue, weight: $0.weight) },
          method: .shares
        )
      )
    case .percent(let entries):
      return .case4(
        .init(
          entries: entries.map { .init(memberId: $0.memberId.rawValue, percent: $0.percent) },
          method: .percent
        )
      )
    case .items(let items, let extras):
      return .case5(
        .init(
          extras: extras.map { extra in
            let kind: Components.Schemas.SplitInput.Case5Payload.extrasPayloadPayload.kindPayload =
              {
                switch extra.kind {
                case .tax: return .tax
                case .service: return .service
                case .discount: return .discount
                case .other, .unknown: return .other
                }
              }()
            return .init(amount: Int(extra.amount.amount), kind: kind, label: extra.label)
          },
          items: items.map {
            .init(
              amount: Int($0.amount.amount),
              memberIds: $0.memberIds.map(\.rawValue),
              name: $0.name
            )
          },
          method: .items
        )
      )
    }
  }

  static func mapCategory(_ raw: String?) -> TransactionCategory? {
    guard let raw, !raw.isEmpty else { return nil }
    return TransactionCategory(code: raw)
  }

  static func encodeCategory(
    _ category: TransactionCategory?
  ) -> Components.Schemas.SplitTransactionRequest.categoryPayload? {
    guard let category else { return nil }
    switch category {
    case .food: return .food
    case .transport: return .transport
    case .lodging: return .lodging
    case .shopping: return .shopping
    case .entertainment: return .entertainment
    case .bills: return .bills
    case .other: return .other
    case .unknown: return nil
    }
  }

  static func encodeFilterCategory(
    _ category: TransactionCategory?
  ) -> Operations.get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions.Input.Query
    .categoryPayload?
  {
    guard let category else { return nil }
    switch category {
    case .food: return .food
    case .transport: return .transport
    case .lodging: return .lodging
    case .shopping: return .shopping
    case .entertainment: return .entertainment
    case .bills: return .bills
    case .other: return .other
    case .unknown: return nil
    }
  }

  static func encodeFilterType(
    _ type: TransactionType?
  ) -> Operations.get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions.Input.Query
    ._typePayload?
  {
    guard let type else { return nil }
    switch type {
    case .expense: return .expense
    case .income: return .income
    case .transfer: return .transfer
    case .unknown: return nil
    }
  }

  static func makeQuery(
    filter: TransactionFilter?,
    cursor: String?
  ) -> Operations.get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions.Input.Query
  {
    guard let filter, !filter.isEmpty else {
      return .init(cursor: cursor, limit: 20)
    }
    let hasCustomOrUncategorized = filter.categoryId != nil || filter.uncategorized
    return .init(
      cursor: cursor,
      limit: 20,
      q: filter.query,
      memberId: filter.memberId?.rawValue,
      category: hasCustomOrUncategorized ? nil : encodeFilterCategory(filter.category),
      categoryId: filter.uncategorized ? nil : filter.categoryId?.rawValue,
      uncategorized: filter.uncategorized ? ._true : nil,
      spendingOnly: (filter.spendingOnly && filter.type != .transfer) ? ._true : nil,
      _type: encodeFilterType(filter.type),
      from: filter.from,
      to: filter.to
    )
  }

  static func mapApproval(_ dto: Components.Schemas.TransactionApprovalDto)
    -> LedgerTransaction.TransactionApproval
  {
    let status: LedgerTransaction.TransactionApproval.Status = {
      switch dto.status {
      case .none: return .none
      case .pending: return .pending
      case .approved: return .approved
      case .rejected: return .rejected
      }
    }()
    return LedgerTransaction.TransactionApproval(
      status: status,
      note: dto.note,
      decidedByName: dto.decidedByName,
      decidedAt: dto.decidedAt.map(formatISO)
    )
  }

  static func mapDispute(_ dto: Components.Schemas.TransactionDisputeDto?) -> LedgerTransaction
    .TransactionDispute?
  {
    guard let dto else { return nil }
    return LedgerTransaction.TransactionDispute(
      id: LedgerTransaction.TransactionDispute.ID(dto.id),
      reason: dto.reason,
      openedByName: dto.openedByName,
      openedAt: formatISO(dto.openedAt),
      mine: dto.mine
    )
  }

  static func mapComment(_ dto: Components.Schemas.CommentDto) -> Comment {
    Comment(
      id: Comment.ID(dto.id),
      body: dto.body,
      authorName: dto.authorName,
      createdAt: formatISO(dto.createdAt),
      mine: dto.mine
    )
  }

  static func mapListItem(_ dto: Components.Schemas.TransactionListItemDto) -> LedgerTransaction {
    LedgerTransaction(
      id: LedgerTransaction.ID(dto.id),
      type: TransactionType(code: dto._type.rawValue),
      description: dto.description,
      amount: Money(Int64(dto.amount)),
      currency: dto.currency.rawValue,
      occurredAt: formatISO(dto.occurredAt),
      category: mapCategory(dto.category?.rawValue),
      categoryId: dto.categoryId.map(GroupCategory.ID.init),
      payers: dto.payers.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      split: mapSplitInput(dto.split),
      shares: dto.shares.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      version: dto.version,
      updatedBy: dto.updatedBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      createdBy: dto.createdBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      createdAt: formatISO(dto.createdAt),
      updatedAt: formatISO(dto.updatedAt),
      deletedAt: dto.deletedAt.map(formatISO),
      attachmentCount: dto.attachmentCount,
      approval: mapApproval(dto.approval),
      dispute: mapDispute(dto.dispute),
      commentCount: dto.commentCount,
      myDelta: dto.myDelta.map { Money(Int64($0)) }
    )
  }

  static func mapDetail(
    _ dto: Components.Schemas.TransactionDto,
    warnings: [TransactionWarning] = []
  ) -> LedgerTransaction {
    LedgerTransaction(
      id: LedgerTransaction.ID(dto.id),
      type: TransactionType(code: dto._type.rawValue),
      description: dto.description,
      amount: Money(Int64(dto.amount)),
      currency: dto.currency.rawValue,
      occurredAt: formatISO(dto.occurredAt),
      category: mapCategory(dto.category?.rawValue),
      categoryId: dto.categoryId.map(GroupCategory.ID.init),
      payers: dto.payers.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      split: mapSplitInput(dto.split),
      shares: dto.shares.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      version: dto.version,
      updatedBy: dto.updatedBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      createdBy: dto.createdBy.map {
        LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name)
      },
      createdAt: formatISO(dto.createdAt),
      updatedAt: formatISO(dto.updatedAt),
      deletedAt: dto.deletedAt.map(formatISO),
      warnings: warnings,
      attachments: dto.attachments.map(ReceiptMapping.mapAttachment),
      attachmentCount: dto.attachments.count,
      approval: mapApproval(dto.approval),
      dispute: mapDispute(dto.dispute),
      commentCount: dto.commentCount,
      myDelta: dto.myDelta.map { Money(Int64($0)) }
    )
  }

  static func encodeSplitPayload(
    _ payload: TransactionDraft.SplitPayload
  ) -> Components.Schemas.SplitTransactionRequest {
    Components.Schemas.SplitTransactionRequest(
      amount: Int(payload.amount.amount),
      attachmentIds: payload.attachmentIds?.map(\.rawValue),
      category: payload.categoryId == nil ? encodeCategory(payload.category) : nil,
      categoryId: payload.categoryId?.rawValue,
      description: payload.description,
      occurredAt: parseISO(payload.occurredAt),
      payers: payload.payers.map {
        .init(amount: Int($0.amount.amount), memberId: $0.memberId.rawValue)
      },
      split: encodeSplitInput(payload.split),
      _type: payload.isIncome ? .income : .expense
    )
  }

  static func encodeCreateRequest(
    _ draft: TransactionDraft
  ) -> Components.Schemas.CreateTransactionRequest {
    switch draft {
    case .split(let payload):
      let splitReq = encodeSplitPayload(payload)
      return payload.isIncome ? .income(splitReq) : .expense(splitReq)
    case .transfer(let payload):
      let transferReq = Components.Schemas.TransferRequest(
        amount: Int(payload.amount.amount),
        attachmentIds: payload.attachmentIds?.map(\.rawValue),
        description: payload.description,
        fromMemberId: payload.fromMemberId.rawValue,
        occurredAt: parseISO(payload.occurredAt),
        toMemberId: payload.toMemberId.rawValue,
        _type: .transfer
      )
      return .transfer(transferReq)
    }
  }

  static func encodeUpdateSplitPayload(
    _ payload: TransactionDraft.SplitPayload
  ) -> Components.Schemas.UpdateSplitTransactionRequest {
    Components.Schemas.UpdateSplitTransactionRequest(
      amount: Int(payload.amount.amount),
      attachmentIds: payload.attachmentIds?.map(\.rawValue),
      category: payload.categoryId == nil
        ? encodeCategory(payload.category).flatMap { .init(rawValue: $0.rawValue) }
        : nil,
      categoryId: payload.categoryId?.rawValue,
      description: payload.description,
      occurredAt: parseISO(payload.occurredAt),
      payers: payload.payers.map {
        .init(amount: Int($0.amount.amount), memberId: $0.memberId.rawValue)
      },
      split: encodeSplitInput(payload.split),
      _type: payload.isIncome ? .income : .expense
    )
  }

  static func encodeUpdateRequest(
    _ draft: TransactionDraft
  ) -> Components.Schemas.UpdateTransactionRequest.Value1Payload {
    switch draft {
    case .split(let payload):
      let splitReq = encodeUpdateSplitPayload(payload)
      return payload.isIncome ? .income(splitReq) : .expense(splitReq)
    case .transfer(let payload):
      let transferReq = Components.Schemas.TransferRequest(
        amount: Int(payload.amount.amount),
        attachmentIds: payload.attachmentIds?.map(\.rawValue),
        description: payload.description,
        fromMemberId: payload.fromMemberId.rawValue,
        occurredAt: parseISO(payload.occurredAt),
        toMemberId: payload.toMemberId.rawValue,
        _type: .transfer
      )
      return .transfer(transferReq)
    }
  }

  // MARK: - Resilient snapshot & unknown-enum decoders

  struct RawMemberAmount: Codable, Sendable {
    let memberId: String
    let amount: Int64
  }

  struct RawActorRef: Codable, Sendable {
    let id: String
    let name: String
  }

  struct RawSplitSpec: Codable, Sendable {
    struct RawExact: Codable, Sendable {
      let memberId: String
      let amount: Int64
    }
    struct RawWeight: Codable, Sendable {
      let memberId: String
      let weight: String
    }
    struct RawPercent: Codable, Sendable {
      let memberId: String
      let percent: String
    }
    struct RawItem: Codable, Sendable {
      let name: String?
      let amount: Int64?
      let memberIds: [String]
    }
    struct RawExtra: Codable, Sendable {
      let kind: String
      let label: String
      let amount: Int64
    }

    let method: String
    let members: [String]?
    let remainder: String?
    let exactEntries: [RawExact]?
    let weightEntries: [RawWeight]?
    let percentEntries: [RawPercent]?
    let items: [RawItem]?
    let extras: [RawExtra]?

    enum CodingKeys: String, CodingKey {
      case method, members, remainder, entries, items, extras
    }

    init(from decoder: any Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      self.method = try c.decode(String.self, forKey: .method)
      self.members = try c.decodeIfPresent([String].self, forKey: .members)
      self.remainder = try c.decodeIfPresent(String.self, forKey: .remainder)
      self.items = try c.decodeIfPresent([RawItem].self, forKey: .items)
      self.extras = try c.decodeIfPresent([RawExtra].self, forKey: .extras)
      switch method {
      case "exact":
        self.exactEntries = try c.decodeIfPresent([RawExact].self, forKey: .entries)
        self.weightEntries = nil
        self.percentEntries = nil
      case "shares":
        self.exactEntries = nil
        self.weightEntries = try c.decodeIfPresent([RawWeight].self, forKey: .entries)
        self.percentEntries = nil
      case "percent":
        self.exactEntries = nil
        self.weightEntries = nil
        self.percentEntries = try c.decodeIfPresent([RawPercent].self, forKey: .entries)
      default:
        self.exactEntries = nil
        self.weightEntries = nil
        self.percentEntries = nil
      }
    }

    init(spec: SplitSpec) {
      switch spec {
      case .equal(let members):
        self.method = "equal"
        self.members = members.map(\.rawValue)
        self.remainder = nil
        self.exactEntries = nil
        self.weightEntries = nil
        self.percentEntries = nil
        self.items = nil
        self.extras = nil
      case .exact(let members, let entries, let remainder):
        self.method = "exact"
        self.members = members.map(\.rawValue)
        self.remainder = remainder.code
        self.exactEntries = entries.map {
          RawExact(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
        }
        self.weightEntries = nil
        self.percentEntries = nil
        self.items = nil
        self.extras = nil
      case .shares(let entries):
        self.method = "shares"
        self.members = nil
        self.remainder = nil
        self.exactEntries = nil
        self.weightEntries = entries.map {
          RawWeight(memberId: $0.memberId.rawValue, weight: $0.weight)
        }
        self.percentEntries = nil
        self.items = nil
        self.extras = nil
      case .percent(let entries):
        self.method = "percent"
        self.members = nil
        self.remainder = nil
        self.exactEntries = nil
        self.weightEntries = nil
        self.percentEntries = entries.map {
          RawPercent(memberId: $0.memberId.rawValue, percent: $0.percent)
        }
        self.items = nil
        self.extras = nil
      case .items(let entries, let extraEntries):
        self.method = "items"
        self.members = nil
        self.remainder = nil
        self.exactEntries = nil
        self.weightEntries = nil
        self.percentEntries = nil
        self.items = entries.map {
          RawItem(name: $0.name, amount: $0.amount.amount, memberIds: $0.memberIds.map(\.rawValue))
        }
        self.extras = extraEntries.map {
          RawExtra(kind: $0.kind.code, label: $0.label, amount: $0.amount.amount)
        }
      }
    }

    func encode(to encoder: any Encoder) throws {
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encode(method, forKey: .method)
      try c.encodeIfPresent(members, forKey: .members)
      try c.encodeIfPresent(remainder, forKey: .remainder)
      if let exactEntries { try c.encode(exactEntries, forKey: .entries) }
      if let weightEntries { try c.encode(weightEntries, forKey: .entries) }
      if let percentEntries { try c.encode(percentEntries, forKey: .entries) }
      if let items { try c.encode(items, forKey: .items) }
      if let extras { try c.encode(extras, forKey: .extras) }
    }

    func toDomain() -> SplitSpec {
      switch method {
      case "exact":
        return .exact(
          members: (members ?? []).map(Member.ID.init),
          entries: (exactEntries ?? []).map {
            SplitSpec.ExactEntry(memberId: Member.ID($0.memberId), amount: Money($0.amount))
          },
          remainder: ExactRemainderMode(code: remainder ?? "none")
        )
      case "shares":
        return .shares(
          entries: (weightEntries ?? []).map {
            SplitSpec.ShareWeightEntry(memberId: Member.ID($0.memberId), weight: $0.weight)
          }
        )
      case "percent":
        return .percent(
          entries: (percentEntries ?? []).map {
            SplitSpec.PercentEntry(memberId: Member.ID($0.memberId), percent: $0.percent)
          }
        )
      case "items":
        return .items(
          items: (items ?? []).map {
            SplitSpec.ItemEntry(
              name: $0.name ?? "",
              amount: Money($0.amount ?? 0),
              memberIds: $0.memberIds.map(Member.ID.init)
            )
          },
          extras: (extras ?? []).map {
            SplitSpec.ItemsExtra(
              kind: ReceiptExtraKind(code: $0.kind),
              label: $0.label,
              amount: Money($0.amount)
            )
          }
        )
      default:
        return .equal(members: (members ?? []).map(Member.ID.init))
      }
    }
  }

  struct RawApproval: Codable, Sendable {
    let status: String
    let note: String?
    let decidedByName: String?
    let decidedAt: String?

    func toDomain() -> LedgerTransaction.TransactionApproval {
      let statusEnum: LedgerTransaction.TransactionApproval.Status = {
        switch status {
        case "pending": return .pending
        case "approved": return .approved
        case "rejected": return .rejected
        default: return .none
        }
      }()
      return LedgerTransaction.TransactionApproval(
        status: statusEnum,
        note: note,
        decidedByName: decidedByName,
        decidedAt: decidedAt
      )
    }

    init(approval: LedgerTransaction.TransactionApproval) {
      self.status = approval.status.rawValue
      self.note = approval.note
      self.decidedByName = approval.decidedByName
      self.decidedAt = approval.decidedAt
    }
  }

  struct RawDispute: Codable, Sendable {
    let id: String
    let reason: String
    let openedByName: String
    let openedAt: String
    let mine: Bool

    func toDomain() -> LedgerTransaction.TransactionDispute {
      LedgerTransaction.TransactionDispute(
        id: LedgerTransaction.TransactionDispute.ID(id),
        reason: reason,
        openedByName: openedByName,
        openedAt: openedAt,
        mine: mine
      )
    }

    init(dispute: LedgerTransaction.TransactionDispute) {
      self.id = dispute.id.rawValue
      self.reason = dispute.reason
      self.openedByName = dispute.openedByName
      self.openedAt = dispute.openedAt
      self.mine = dispute.mine
    }
  }

  struct RawTransaction: Codable, Sendable {
    let id: String
    let type: String
    let description: String
    let amount: Int64
    let currency: String
    let occurredAt: String
    let category: String?
    let categoryId: String?
    let payers: [RawMemberAmount]
    let split: RawSplitSpec
    let shares: [RawMemberAmount]
    let version: Int
    let updatedBy: RawActorRef?
    let createdBy: RawActorRef?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let attachments: [ReceiptMapping.RawAttachment]?
    let attachmentCount: Int?
    let approval: RawApproval?
    let dispute: RawDispute?
    let commentCount: Int?
    let myDelta: Int64?

    func toDomain() -> LedgerTransaction {
      let decodedAttachments = (attachments ?? []).map { $0.toDomain() }
      return LedgerTransaction(
        id: LedgerTransaction.ID(id),
        type: TransactionType(code: type),
        description: description,
        amount: Money(amount),
        currency: currency,
        occurredAt: occurredAt,
        category: TransactionMapping.mapCategory(category),
        categoryId: categoryId.map(GroupCategory.ID.init),
        payers: payers.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        },
        split: split.toDomain(),
        shares: shares.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        },
        version: version,
        updatedBy: updatedBy.map { LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name) },
        createdBy: createdBy.map { LedgerTransaction.ActorRef(id: User.ID($0.id), name: $0.name) },
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        attachments: decodedAttachments,
        attachmentCount: attachmentCount ?? decodedAttachments.count,
        approval: approval?.toDomain() ?? .init(),
        dispute: dispute?.toDomain(),
        commentCount: commentCount ?? 0,
        myDelta: myDelta.map(Money.init)
      )
    }

    init(tx: LedgerTransaction) {
      self.id = tx.id.rawValue
      self.type = tx.type.code
      self.description = tx.description
      self.amount = tx.amount.amount
      self.currency = tx.currency
      self.occurredAt = tx.occurredAt
      self.category = tx.category?.code
      self.categoryId = tx.categoryId?.rawValue
      self.payers = tx.payers.map {
        RawMemberAmount(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
      }
      self.split = RawSplitSpec(spec: tx.split)
      self.shares = tx.shares.map {
        RawMemberAmount(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
      }
      self.version = tx.version
      self.updatedBy = tx.updatedBy.map { RawActorRef(id: $0.id.rawValue, name: $0.name) }
      self.createdBy = tx.createdBy.map { RawActorRef(id: $0.id.rawValue, name: $0.name) }
      self.createdAt = tx.createdAt
      self.updatedAt = tx.updatedAt
      self.deletedAt = tx.deletedAt
      self.attachments =
        tx.attachments.isEmpty ? nil : tx.attachments.map(ReceiptMapping.RawAttachment.init)
      self.attachmentCount = tx.attachmentCount
      self.approval = RawApproval(approval: tx.approval)
      self.dispute = tx.dispute.map(RawDispute.init)
      self.commentCount = tx.commentCount
      self.myDelta = tx.myDelta?.amount
    }
  }

  struct RawTransactionsPage: Codable, Sendable {
    let transactions: [RawTransaction]
    let nextCursor: String?
  }

  struct RawTransactionResponse: Codable, Sendable {
    let transaction: RawTransaction
    let warnings: [String]?
  }

  struct RawComment: Codable, Sendable {
    let id: String
    let body: String
    let authorName: String
    let createdAt: String
    let mine: Bool

    func toDomain() -> Comment {
      Comment(
        id: Comment.ID(id),
        body: body,
        authorName: authorName,
        createdAt: createdAt,
        mine: mine
      )
    }
  }

  struct RawCommentsResponse: Codable, Sendable {
    let comments: [RawComment]
    let nextCursor: String?
  }

  static func decodeResilientPage(from data: Data) throws -> Page<LedgerTransaction> {
    let raw = try JSONDecoder().decode(RawTransactionsPage.self, from: data)
    return Page(items: raw.transactions.map { $0.toDomain() }, nextCursor: raw.nextCursor)
  }

  static func encodePageSnapshot(_ page: Page<LedgerTransaction>) -> Data? {
    let payload = RawTransactionsPage(
      transactions: page.items.map(RawTransaction.init),
      nextCursor: page.nextCursor
    )
    return try? JSONEncoder().encode(payload)
  }

  static func decodeResilientDetail(from data: Data) throws -> LedgerTransaction {
    let raw = try JSONDecoder().decode(RawTransactionResponse.self, from: data)
    var tx = raw.transaction.toDomain()
    tx.warnings = (raw.warnings ?? []).map { TransactionWarning(code: $0) }
    return tx
  }

  static func decodeResilientComments(from data: Data) throws -> (
    comments: [Comment], nextCursor: String?
  ) {
    let raw = try JSONDecoder().decode(RawCommentsResponse.self, from: data)
    return (raw.comments.map { $0.toDomain() }, raw.nextCursor)
  }

  static func decodeResilientComment(from data: Data) throws -> Comment {
    struct SingleCommentResponse: Codable {
      let comment: RawComment
    }
    let raw = try JSONDecoder().decode(SingleCommentResponse.self, from: data)
    return raw.comment.toDomain()
  }

  static func decodeResilientDispute(from data: Data) throws -> LedgerTransaction.TransactionDispute
  {
    struct DisputeResponse: Codable {
      let dispute: RawDispute
    }
    let raw = try JSONDecoder().decode(DisputeResponse.self, from: data)
    return raw.dispute.toDomain()
  }
}
