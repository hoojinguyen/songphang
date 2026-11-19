public import Domain
import Foundation
import GeneratedAPI

public final class LiveGroupsRepository: GroupsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownGroups() async -> [ExpenseGroup]? {
    await environment.snapshots.read(.groups) { data in
      try GroupMapping.decodeResilientGroups(from: data)
    }
  }

  public func groups() async throws(AppError) -> [ExpenseGroup] {
    let scope = await environment.snapshots.currentScope()
    do {
      let list: [ExpenseGroup] = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client.get_sol_api_sol_v1_sol_groups(.init())
        switch output {
        case .ok(let ok):
          return try ok.body.json.groups.map(GroupMapping.mapSummary)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try GroupMapping.decodeResilientGroups(from: data)
      }

      if let scope, let encoded = GroupMapping.encodeGroupsSnapshot(list) {
        await environment.snapshots.writeData(encoded, for: .groups, scope: scope)
      }
      return list
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func lastKnownGroup(id: ExpenseGroup.ID) async -> ExpenseGroup? {
    await environment.snapshots.read(.group(id.rawValue)) { data in
      try GroupMapping.decodeResilientGroup(from: data)
    }
  }

  public func group(id: ExpenseGroup.ID) async throws(AppError) -> ExpenseGroup {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: id.rawValue)
    do {
      let detail: ExpenseGroup = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub_(
            .init(path: .init(groupId: id.rawValue))
          )
        switch output {
        case .ok(let ok):
          return GroupMapping.mapDetail(try ok.body.json.group)
        case .undocumented(let status, let payload):
          if status == 404 {
            await environment.snapshots.invalidateGroup(id.rawValue)
          }
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try GroupMapping.decodeResilientGroup(from: data)
      }

      if let scope, let encoded = GroupMapping.encodeGroupSnapshot(detail) {
        await environment.snapshots.writeData(
          encoded,
          for: .group(id.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return detail
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func create(
    name: String,
    memberNames: [String],
    key: IdempotencyKey
  ) async throws(AppError) -> ExpenseGroup {
    let scope = await environment.snapshots.currentScope()
    do {
      let body = Components.Schemas.CreateGroupRequest(
        memberNames: memberNames.isEmpty ? nil : memberNames,
        name: name
      )
      let detail: ExpenseGroup = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client.post_sol_api_sol_v1_sol_groups(
          .init(
            headers: .init(idempotency_hyphen_key: key.rawValue),
            body: .json(body)
          )
        )
        switch output {
        case .created(let created):
          return GroupMapping.mapDetail(try created.body.json.group)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try GroupMapping.decodeResilientGroup(from: data)
      }

      if let scope, let encoded = GroupMapping.encodeGroupSnapshot(detail) {
        let groupGen = await environment.snapshots.groupGeneration(for: detail.id.rawValue)
        await environment.snapshots.writeData(
          encoded,
          for: .group(detail.id.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return detail
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    id: ExpenseGroup.ID,
    input: UpdateGroupInput
  ) async throws(AppError) -> ExpenseGroup {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: id.rawValue)
    let defaultRolePayload: Components.Schemas.UpdateGroupRequest.defaultRolePayload? = {
      switch input.defaultRole {
      case .editor: return .editor
      case .viewer: return .viewer
      default: return nil
      }
    }()
    do {
      let body = Components.Schemas.UpdateGroupRequest(
        defaultRole: defaultRolePayload,
        minimizeDebts: input.minimizeDebts,
        name: input.name
      )
      let detail: ExpenseGroup = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub_(
            .init(
              path: .init(groupId: id.rawValue),
              body: .json(body)
            )
          )
        switch output {
        case .ok(let ok):
          return GroupMapping.mapDetail(try ok.body.json.group)
        case .undocumented(let status, let payload):
          if status == 404 {
            await environment.snapshots.invalidateGroup(id.rawValue)
          }
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try GroupMapping.decodeResilientGroup(from: data)
      }

      if let scope, let encoded = GroupMapping.encodeGroupSnapshot(detail) {
        await environment.snapshots.writeData(
          encoded,
          for: .group(id.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return detail
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(id: ExpenseGroup.ID, confirmName: String) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub_(
          .init(
            path: .init(groupId: id.rawValue),
            body: .json(.init(name: confirmName))
          )
        )
      switch output {
      case .noContent:
        await environment.snapshots.invalidateGroup(id.rawValue)
        return
      case .undocumented(let status, let payload):
        if status == 404 {
          await environment.snapshots.invalidateGroup(id.rawValue)
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
