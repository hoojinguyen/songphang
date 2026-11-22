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

    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests(
            .init(
              path: .init(groupId: groupId.rawValue),
              query: .init(status: queryStatus)
            )
          )
        switch output {
        case .ok(let ok):
          return try ok.body.json.requests.map(Self.mapRequest)
        case .undocumented(let statusCode, let payload):
          throw await environment.errorMapper.mapUndocumented(
            statusCode: statusCode,
            payload: payload
          )
        }
      } fallback: { data in
        try Self.decodeResilientRequests(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func request(
    groupId: ExpenseGroup.ID,
    transfer: SuggestedTransfer,
    idempotencyKey: String
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_settlement_hyphen_requests(
          .init(
            path: .init(groupId: groupId.rawValue),
            headers: .init(idempotency_hyphen_key: idempotencyKey),
            body: .json(
              .init(
                amount: Int(transfer.amount.amount),
                fromMemberId: transfer.fromMemberId.rawValue,
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

  private static func mapRequest(_ dto: Components.Schemas.SettlementRequestDto)
    -> SettlementRequest
  {
    SettlementRequest(
      id: dto.id,
      fromMemberId: Member.ID(dto.fromMemberId),
      toMemberId: Member.ID(dto.toMemberId),
      amount: Money(Int64(dto.amount)),
      status: SettlementRequestStatus(code: dto.status.rawValue),
      transactionId: dto.transactionId.map(LedgerTransaction.ID.init),
      createdByUserId: dto.createdBy.map { User.ID($0.id) },
      createdByName: dto.createdBy?.name,
      createdAt: formatISO(dto.createdAt),
      resolvedAt: dto.resolvedAt.map(formatISO)
    )
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
    let transactionId: String?
    let createdBy: RawCreator?
    let createdAt: String
    let resolvedAt: String?

    func toDomain() -> SettlementRequest {
      SettlementRequest(
        id: id,
        fromMemberId: Member.ID(fromMemberId),
        toMemberId: Member.ID(toMemberId),
        amount: Money(amount),
        status: SettlementRequestStatus(code: status),
        transactionId: transactionId.map(LedgerTransaction.ID.init),
        createdByUserId: createdBy.map { User.ID($0.id) },
        createdByName: createdBy?.name,
        createdAt: createdAt,
        resolvedAt: resolvedAt
      )
    }
  }

  private struct RawSettlementRequestsResponse: Codable, Sendable {
    let requests: [RawSettlementRequest]
  }

  private static func decodeResilientRequests(from data: Data) throws -> [SettlementRequest] {
    try JSONDecoder().decode(RawSettlementRequestsResponse.self, from: data)
      .requests.map { $0.toDomain() }
  }
}
