public import Domain
import Foundation
import GeneratedAPI

public final class LiveFundRepository: FundRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func create(
    groupId: ExpenseGroup.ID,
    name: String?,
    holderMemberId: Member.ID?,
    key: IdempotencyKey
  ) async throws(AppError) -> Member {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_fund(
            .init(
              path: .init(groupId: groupId.rawValue),
              headers: .init(idempotency_hyphen_key: key.rawValue),
              body: .json(.init(holderMemberId: holderMemberId?.rawValue, name: name))
            )
          )
        switch output {
        case .created(let created):
          return MemberMapping.mapMember(try created.body.json.member)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try MemberMapping.decodeResilientMember(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    groupId: ExpenseGroup.ID,
    name: String?,
    holder: FundHolderUpdate,
    active: Bool?
  ) async throws(AppError) -> Member {
    if case .clear = holder {
      return try await patchClearingHolder(groupId: groupId, name: name, active: active)
    }
    let holderMemberId: String? =
      switch holder {
      case .unchanged: nil
      case .set(let id): id.rawValue
      case .clear: nil
      }
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_fund(
            .init(
              path: .init(groupId: groupId.rawValue),
              body: .json(
                .init(
                  active: active,
                  holderMemberId: holderMemberId,
                  name: name
                )
              )
            )
          )
        switch output {
        case .ok(let ok):
          return MemberMapping.mapMember(try ok.body.json.member)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try MemberMapping.decodeResilientMember(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(groupId: ExpenseGroup.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_fund(
          .init(path: .init(groupId: groupId.rawValue))
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

  private func patchClearingHolder(
    groupId: ExpenseGroup.ID,
    name: String?,
    active: Bool?
  ) async throws(AppError) -> Member {
    var payload: [String: Any] = ["holderMemberId": NSNull()]
    if let name { payload["name"] = name }
    if let active { payload["active"] = active }

    let url = environment.configuration.apiBaseURL
      .appendingPathComponent("groups")
      .appendingPathComponent(groupId.rawValue)
      .appendingPathComponent("fund")
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
      let (data, http, snapshot) = try await environment.performAuthorizedDataRequest(request)
      guard (200..<300).contains(http.statusCode) else {
        let code = try? JSONDecoder().decode(APIErrorPayload.self, from: data).error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      return try MemberMapping.decodeResilientMember(from: data)
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
