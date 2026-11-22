public import Domain
import Foundation
import GeneratedAPI

public final class LiveMembersRepository: MembersRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownMembers(groupId: ExpenseGroup.ID) async -> [Member]? {
    await environment.snapshots.read(.members(groupId.rawValue)) { data in
      try MemberMapping.decodeResilientMembers(from: data)
    }
  }

  public func members(groupId: ExpenseGroup.ID) async throws(AppError) -> [Member] {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let list: [Member] = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members(
            .init(path: .init(groupId: groupId.rawValue))
          )
        switch output {
        case .ok(let ok):
          return try ok.body.json.members.map(MemberMapping.mapMember)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try MemberMapping.decodeResilientMembers(from: data)
      }

      if let scope, let encoded = MemberMapping.encodeMembersSnapshot(list) {
        await environment.snapshots.writeData(
          encoded,
          for: .members(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return list
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func lastKnownGroupUsers(groupId: ExpenseGroup.ID) async -> [GroupUser]? {
    await environment.snapshots.read(.groupUsers(groupId.rawValue)) { data in
      try MemberMapping.decodeResilientGroupUsers(from: data)
    }
  }

  public func groupUsers(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupUser] {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let list: [GroupUser] = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_users(
            .init(path: .init(groupId: groupId.rawValue))
          )
        switch output {
        case .ok(let ok):
          return try ok.body.json.users.map(MemberMapping.mapGroupUser)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try MemberMapping.decodeResilientGroupUsers(from: data)
      }

      if let scope, let encoded = MemberMapping.encodeGroupUsersSnapshot(list) {
        await environment.snapshots.writeData(
          encoded,
          for: .groupUsers(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return list
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func create(
    groupId: ExpenseGroup.ID,
    name: String,
    key: IdempotencyKey
  ) async throws(AppError) -> Member {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members(
            .init(
              path: .init(groupId: groupId.rawValue),
              headers: .init(idempotency_hyphen_key: key.rawValue),
              body: .json(.init(name: name))
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
    memberId: Member.ID,
    input: UpdateMemberInput
  ) async throws(AppError) -> Member {
    do {
      let body = Components.Schemas.UpdateMemberRequest(
        active: input.active,
        defaultWeight: input.defaultWeight,
        name: input.name
      )
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members_sol__lcub_memberId_rcub_(
            .init(
              path: .init(groupId: groupId.rawValue, memberId: memberId.rawValue),
              body: .json(body)
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

  public func replacePaymentMethods(
    groupId: ExpenseGroup.ID,
    memberId: Member.ID,
    methods: [PaymentMethod]
  ) async throws(AppError) {
    typealias Input = Operations
      .put_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members_sol__lcub_memberId_rcub__sol_payment_hyphen_methods
      .Input
    let payload = methods.map { method -> Input.Body.jsonPayload.methodsPayloadPayload in
      switch method {
      case .bank(let bank):
        .case1(
          .init(
            accountName: bank.accountName, accountNumber: bank.accountNumber,
            bankBin: bank.bin, kind: .bank
          ))
      case .momo(let phone):
        .case2(.init(kind: .momo, phone: phone))
      case .zalopay(let phone):
        .case3(.init(kind: .zalopay, phone: phone))
      }
    }
    do {
      let output = try await environment.client
        .put_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members_sol__lcub_memberId_rcub__sol_payment_hyphen_methods(
          .init(
            path: .init(groupId: groupId.rawValue, memberId: memberId.rawValue),
            body: .json(.init(methods: payload)))
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

  public func delete(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_members_sol__lcub_memberId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, memberId: memberId.rawValue))
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

  public func chooseMyMember(groupId: ExpenseGroup.ID, memberId: Member.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .put_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_me_sol_member(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(.init(memberId: memberId.rawValue))
          )
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

  public func updateUserRole(
    groupId: ExpenseGroup.ID,
    userId: User.ID,
    role: Role
  ) async throws(AppError) {
    let payloadRole: Components.Schemas.UpdateGroupUserRequest.rolePayload
    switch role {
    case .editor:
      payloadRole = .editor
    case .viewer:
      payloadRole = .viewer
    default:
      throw .api(code: "VALIDATION_FAILED", status: 400)
    }
    do {
      let output = try await environment.client
        .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_users_sol__lcub_userId_rcub_(
          .init(
            path: .init(groupId: groupId.rawValue, userId: userId.rawValue),
            body: .json(.init(role: payloadRole))
          )
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

  public func removeUser(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_users_sol__lcub_userId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, userId: userId.rawValue))
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

  public func transferOwnership(groupId: ExpenseGroup.ID, userId: User.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_transfer_hyphen_ownership(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(.init(userId: userId.rawValue))
          )
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

  public func leaveGroup(groupId: ExpenseGroup.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_leave(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .noContent:
        await environment.snapshots.invalidateGroup(groupId.rawValue)
        return
      case .undocumented(let status, let payload):
        if status == 404 {
          await environment.snapshots.invalidateGroup(groupId.rawValue)
        }
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
