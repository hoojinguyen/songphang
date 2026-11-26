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
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(FlexibleISO8601DateTranscoder().encode(date))
      }
      let body = Components.Schemas.UpdateTransactionRequest(
        value1: TransactionMapping.encodeUpdateRequest(draft),
        value2: .init(version: version)
      )
      let encodedBody = try encoder.encode(body)
      let url = environment.configuration.apiBaseURL
        .appendingPathComponent("groups")
        .appendingPathComponent(groupId.rawValue)
        .appendingPathComponent("transactions")
        .appendingPathComponent(id.rawValue)
      var request = URLRequest(url: url)
      request.httpMethod = "PATCH"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      if case .split(let payload) = draft, payload.category == nil, payload.categoryId == nil {
        guard var json = try JSONSerialization.jsonObject(with: encodedBody) as? [String: Any]
        else { throw AppError.unexpected }
        json["category"] = NSNull()
        json["categoryId"] = NSNull()
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
      } else if case .transfer(let payload) = draft,
        payload.paymentChannel == nil
          || payload.paymentNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
      {
        guard var json = try JSONSerialization.jsonObject(with: encodedBody) as? [String: Any]
        else { throw AppError.unexpected }
        if payload.paymentChannel == nil {
          json["paymentChannel"] = NSNull()
        }
        let trimmedNote = payload.paymentNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNote?.isEmpty != false {
          json["paymentNote"] = NSNull()
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
      } else {
        request.httpBody = encodedBody
      }
      let (data, http, snapshot) = try await environment.performAuthorizedDataRequest(request)
      guard http.statusCode == 200 else {
        let code = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      return try TransactionMapping.decodeResilientDetail(from: data)
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

  public func comments(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> (comments: [Comment], nextCursor: String?) {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_comments(
            .init(
              path: .init(groupId: groupId.rawValue, id: id.rawValue),
              query: .init(cursor: cursor, limit: limit)
            )
          )
        switch output {
        case .ok(let ok):
          let body = try ok.body.json
          return (body.comments.map(TransactionMapping.mapComment), body.nextCursor)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try TransactionMapping.decodeResilientComments(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func addComment(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    body: String,
    key: IdempotencyKey
  ) async throws(AppError) -> Comment {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_comments(
          .init(
            path: .init(groupId: groupId.rawValue, id: id.rawValue),
            headers: .init(idempotency_hyphen_key: key.rawValue),
            body: .json(.init(body: body))
          )
        )
      switch output {
      case .created(let created):
        let body = try created.body.json
        return TransactionMapping.mapComment(body.comment)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func deleteComment(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    commentId: Comment.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_comments_sol__lcub_commentId_rcub_(
          .init(
            path: .init(groupId: groupId.rawValue, id: id.rawValue, commentId: commentId.rawValue))
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

  public func openDispute(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    reason: String
  ) async throws(AppError) -> LedgerTransaction.TransactionDispute {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_dispute(
          .init(
            path: .init(groupId: groupId.rawValue, id: id.rawValue),
            body: .json(.init(reason: reason))
          )
        )
      switch output {
      case .created(let created):
        let body = try created.body.json
        guard let dispute = TransactionMapping.mapDispute(body.dispute) else {
          throw AppError.unexpected
        }
        return dispute
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func resolveDispute(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_dispute_sol_resolve(
          .init(path: .init(groupId: groupId.rawValue, id: id.rawValue))
        )
      switch output {
      case .ok:
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

  public func approve(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID
  ) async throws(AppError) -> LedgerTransaction {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_approve(
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
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func reject(
    groupId: ExpenseGroup.ID,
    id: LedgerTransaction.ID,
    note: String?
  ) async throws(AppError) -> LedgerTransaction {
    do {
      let body: Components.Schemas.ApproveRejectTransactionRequest? = note.map { .init(note: $0) }
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transactions_sol__lcub_id_rcub__sol_reject(
          .init(
            path: .init(groupId: groupId.rawValue, id: id.rawValue),
            body: body.map { .json($0) }
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
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
