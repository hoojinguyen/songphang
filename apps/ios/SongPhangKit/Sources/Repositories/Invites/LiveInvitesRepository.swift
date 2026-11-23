public import Domain
import Foundation
import GeneratedAPI

public final class LiveInvitesRepository: InvitesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  /// Invite links and tokens are intentionally excluded from disk snapshots (AD §8.1).
  public func lastKnownInvite(groupId _: ExpenseGroup.ID) async -> Invite? {
    nil
  }

  public func invite(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_invite(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return InviteMapping.mapInvite(try ok.body.json.invite)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func setActive(groupId: ExpenseGroup.ID, active: Bool) async throws(AppError) -> Invite {
    do {
      let output = try await environment.client
        .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_invite(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(.init(active: active))
          )
        )
      switch output {
      case .ok(let ok):
        return InviteMapping.mapInvite(try ok.body.json.invite)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func rotate(groupId: ExpenseGroup.ID) async throws(AppError) -> Invite {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_invite_sol_rotate(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return InviteMapping.mapInvite(try ok.body.json.invite)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func preview(token: String) async throws(AppError) -> InvitePreview {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_invites_sol__lcub_token_rcub_(
            .init(path: .init(token: token))
          )
        switch output {
        case .ok(let ok):
          return InviteMapping.mapPreview(try ok.body.json)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try InviteMapping.decodeResilientPreview(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func join(
    token: String,
    choice: JoinChoice,
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup.ID {
    let requestBody: Components.Schemas.JoinRequest
    switch choice {
    case .existingMember(let memberId):
      requestBody = Components.Schemas.JoinRequest(
        value1: .init(memberId: memberId.rawValue),
        value2: nil
      )
    case .newMember(let name):
      requestBody = Components.Schemas.JoinRequest(
        value1: nil,
        value2: .init(newMemberName: name)
      )
    }

    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_invites_sol__lcub_token_rcub__sol_join(
          .init(
            path: .init(token: token),
            headers: .init(idempotency_hyphen_key: key.rawValue),
            body: .json(requestBody)
          )
        )
      switch output {
      case .ok(let ok):
        let groupId = ExpenseGroup.ID(try ok.body.json.groupId)
        await environment.snapshots.recordActiveGroup(groupId.rawValue)
        return groupId
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
