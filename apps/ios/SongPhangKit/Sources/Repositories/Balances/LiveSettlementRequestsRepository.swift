public import Domain
import Foundation
import GeneratedAPI

public struct LiveSettlementRequestsRepository: SettlementRequestsRepository {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func list(
    groupId: ExpenseGroup.ID,
    status: SettlementRequestStatus?
  ) async throws(AppError) -> [SettlementRequest] {
    let queryStatus:
      Operations
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests
        .Input.Query.statusPayload?
    switch status {
    case .pending:
      queryStatus = .pending
    case .confirmed:
      queryStatus = .confirmed
    case .rejected:
      queryStatus = .rejected
    case .cancelled:
      queryStatus = .cancelled
    case .unknown, .none:
      queryStatus = nil
    }

    var allRequests: [SettlementRequest] = []
    var currentCursor: String?
    var visitedCursors = Set<String>()

    while true {
      let page = try await fetchPage(
        groupId: groupId,
        queryStatus: queryStatus,
        cursor: currentCursor
      )
      allRequests.append(contentsOf: page.requests)
      guard let next = page.nextCursor, !next.isEmpty, !visitedCursors.contains(next) else {
        break
      }
      visitedCursors.insert(next)
      currentCursor = next
    }

    return allRequests
  }

  private func fetchPage(
    groupId: ExpenseGroup.ID,
    queryStatus: Operations
      .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests
      .Input.Query.statusPayload?,
    cursor: String?
  ) async throws(AppError) -> (requests: [SettlementRequest], nextCursor: String?) {
    let baseURL = environment.configuration.apiBaseURL
      .appendingPathComponent("groups")
      .appendingPathComponent(groupId.rawValue)
      .appendingPathComponent("settlement-requests")
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    var queryItems: [URLQueryItem] = []
    if let queryStatus {
      queryItems.append(URLQueryItem(name: "status", value: queryStatus.rawValue))
    }
    if let cursor, !cursor.isEmpty {
      queryItems.append(URLQueryItem(name: "cursor", value: cursor))
    }
    if !queryItems.isEmpty {
      components?.queryItems = queryItems
    }
    var request = URLRequest(url: components?.url ?? baseURL)
    request.httpMethod = "GET"

    do {
      let (data, http, snapshot) = try await environment.performAuthorizedDataRequest(request)
      guard (200..<300).contains(http.statusCode) else {
        let code = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      let raw = try JSONDecoder().decode(RawSettlementRequestsResponse.self, from: data)
      return (requests: raw.requests.map { $0.toDomain() }, nextCursor: raw.nextCursor)
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func request(
    groupId: ExpenseGroup.ID,
    transfer: SuggestedTransfer,
    channel: PaymentChannel?,
    note: String?,
    proofAttachmentId: Attachment.ID?,
    idempotencyKey: String
  ) async throws(AppError) {
    do {
      let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests(
          .init(
            path: .init(groupId: groupId.rawValue),
            headers: .init(idempotency_hyphen_key: idempotencyKey),
            body: .json(
              .init(
                amount: Int(transfer.amount.amount),
                channel: LiveSettlementVaultMapping.encodePaymentChannel(channel),
                fromMemberId: transfer.fromMemberId.rawValue,
                note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil,
                proofAttachmentId: proofAttachmentId?.rawValue,
                toMemberId: transfer.toMemberId.rawValue
              )
            )
          )
        )
      switch output {
      case .created:
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

  public func resolve(
    groupId: ExpenseGroup.ID,
    requestId: String,
    decision: SettlementDecision
  ) async throws(AppError) {
    do {
      switch decision {
      case .confirm:
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests_sol__lcub_id_rcub__sol_confirm(
            .init(path: .init(groupId: groupId.rawValue, id: requestId))
          )
        switch output {
        case .ok:
          return
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      case .reject:
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests_sol__lcub_id_rcub__sol_reject(
            .init(path: .init(groupId: groupId.rawValue, id: requestId))
          )
        switch output {
        case .ok:
          return
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      case .cancel:
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests_sol__lcub_id_rcub__sol_cancel(
            .init(path: .init(groupId: groupId.rawValue, id: requestId))
          )
        switch output {
        case .ok:
          return
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  private static func formatISO(_ date: Date) -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  private struct RawSettlementRequest: Codable, Sendable {
    struct RawCreator: Codable, Sendable {
      let id: String
      let name: String
    }

    let id: String
    let fromMemberId: String
    let toMemberId: String
    let amount: Int64
    let status: String
    let channel: String?
    let note: String?
    let proofAttachment: ReceiptMapping.RawAttachment?
    let transactionId: String?
    let createdBy: RawCreator?
    let resolvedBy: RawCreator?
    let createdAt: String
    let resolvedAt: String?

    func toDomain() -> SettlementRequest {
      SettlementRequest(
        id: id,
        fromMemberId: Member.ID(fromMemberId),
        toMemberId: Member.ID(toMemberId),
        amount: Money(amount),
        status: SettlementRequestStatus(code: status),
        channel: channel.map(PaymentChannel.init(code:)),
        note: note,
        proofAttachment: proofAttachment?.toDomain(),
        transactionId: transactionId.map(LedgerTransaction.ID.init),
        createdByUserId: createdBy.map { User.ID($0.id) },
        createdByName: createdBy?.name,
        resolvedByUserId: resolvedBy.map { User.ID($0.id) },
        resolvedByName: resolvedBy?.name,
        createdAt: createdAt,
        resolvedAt: resolvedAt
      )
    }
  }

  private struct RawSettlementRequestsResponse: Codable, Sendable {
    let requests: [RawSettlementRequest]
    let nextCursor: String?
  }

  private static func decodeResilientRequests(from data: Data) throws -> [SettlementRequest] {
    try JSONDecoder().decode(RawSettlementRequestsResponse.self, from: data)
      .requests.map { $0.toDomain() }
  }
}
