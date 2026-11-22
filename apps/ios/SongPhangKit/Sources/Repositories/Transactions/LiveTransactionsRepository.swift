public import Domain
import Foundation
import GeneratedAPI

public final class LiveTransactionsRepository: TransactionsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownFirstPage(groupId: ExpenseGroup.ID) async -> Page<LedgerTransaction>? {
    await environment.snapshots.read(.feedFirstPage(groupId.rawValue)) { data in
      try TransactionMapping.decodeResilientPage(from: data)
    }
  }

  public func page(
    groupId: ExpenseGroup.ID,
    filter: TransactionFilter?,
    cursor: String?
  ) async throws(AppError) -> Page<LedgerTransaction> {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let query = TransactionMapping.makeQuery(filter: filter, cursor: cursor)
      let pageResult: Page<LedgerTransaction> = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions(
            .init(
              path: .init(groupId: groupId.rawValue),
              query: query
            )
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          return Page(
            items: body.transactions.map(TransactionMapping.mapListItem),
            nextCursor: body.nextCursor
          )
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientPage(from: data)
      }

      let isUnfiltered = filter?.isEmpty ?? true
      if cursor == nil, isUnfiltered, let scope,
        let encoded = TransactionMapping.encodePageSnapshot(pageResult)
      {
        await environment.snapshots.writeData(
          encoded,
          for: .feedFirstPage(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return pageResult
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func transaction(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub_(
            .init(path: .init(groupId: groupId.rawValue, id: id.rawValue))
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          let warnings = (body.warnings ?? []).map { TransactionWarning(code: $0.rawValue) }
          return TransactionMapping.mapDetail(body.transaction, warnings: warnings)
        case .undocumented(let status, let payload):
          // Do NOT invalidate the group on a child-transaction 404 alone.
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientDetail(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func preview(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft
  ) async throws(AppError) -> SharePreview {
    guard case .split(let payload) = draft else {
      throw .api(code: "VALIDATION_FAILED", status: 400)
    }
    do {
      let body = Components.Schemas.PreviewTransactionRequest(
        value1: TransactionMapping.encodeSplitPayload(payload),
        value2: .init(transactionId: nil)
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol_preview(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .ok(let ok):
        let json = try ok.body.json
        let shares = json.shares.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
        }
        let warnings = (json.warnings ?? []).map {
          TransactionWarning(code: $0.rawValue)
        }
        return SharePreview(shares: shares, warnings: warnings)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func previewItems(
    groupId: ExpenseGroup.ID,
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra],
    targetTotal: Money?
  ) async throws(AppError) -> ItemsPreview {
    do {
      let body = Components.Schemas.PreviewItemsRequest(
        extras: extras.map {
          .init(
            amount: Int($0.amount.amount),
            kind: ReceiptMapping.encodeExtraKind($0.kind),
            label: $0.label
          )
        },
        items: items.map {
          .init(
            amount: Int($0.amount.amount),
            memberIds: $0.memberIds.map(\.rawValue),
            name: $0.name
          )
        },
        targetTotal: targetTotal.map { Int($0.amount) }
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol_items_sol_preview(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .ok(let ok):
        return ReceiptMapping.mapItemsPreview(try ok.body.json)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func create(
    groupId: ExpenseGroup.ID,
    draft: TransactionDraft,
    key: IdempotencyKey
  ) async throws(AppError) -> LedgerTransaction {
    do {
      let body = TransactionMapping.encodeCreateRequest(draft)
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions(
            .init(
              path: .init(groupId: groupId.rawValue),
              headers: .init(idempotency_hyphen_key: key.rawValue),
              body: .json(body)
            )
          )
        switch output {
        case .created(let created):
          let body = try created.body.json
          let warnings = (body.warnings ?? []).map { TransactionWarning(code: $0.rawValue) }
          return TransactionMapping.mapDetail(body.transaction, warnings: warnings)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientDetail(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    draft: TransactionDraft,
    version: Int
  ) async throws(AppError) -> LedgerTransaction {
    do {
      let createReq = TransactionMapping.encodeCreateRequest(draft)
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub_(
            .init(
              path: .init(groupId: groupId.rawValue, id: id.rawValue),
              body: .json(.init(value1: createReq, value2: .init(version: version)))
            )
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          let warnings = (body.warnings ?? []).map { TransactionWarning(code: $0.rawValue) }
          return TransactionMapping.mapDetail(body.transaction, warnings: warnings)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientDetail(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(groupId: ExpenseGroup.ID, id: LedgerTransaction.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub_(
          .init(path: .init(groupId: groupId.rawValue, id: id.rawValue))
        )
      switch output {
      case .noContent:
        return
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func restore(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_restore(
            .init(path: .init(groupId: groupId.rawValue, id: id.rawValue))
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          let warnings = (body.warnings ?? []).map { TransactionWarning(code: $0.rawValue) }
          return TransactionMapping.mapDetail(body.transaction, warnings: warnings)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientDetail(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
