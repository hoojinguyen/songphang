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

      if let scope {
        await environment.snapshots.reconcileGroups(
          keeping: Set(list.map(\.id.rawValue)),
          scope: scope
        )
        if let encoded = GroupMapping.encodeGroupsSnapshot(list) {
          await environment.snapshots.writeData(encoded, for: .groups, scope: scope)
        }
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
          return GroupMapping.mapDetail(
            try ok.body.json.group,
            reminderIntervalDays: GroupMapping.extractReminderIntervalDays(
              from: ResponseBodyCapture.box?.read()
            )
          )
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
          return GroupMapping.mapDetail(
            try created.body.json.group,
            reminderIntervalDays: GroupMapping.extractReminderIntervalDays(
              from: ResponseBodyCapture.box?.read()
            )
          )
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

    if input.reminderInterval != .unchanged || input.approvalThreshold != .unchanged {
      let detail = try await patchGroupRaw(id: id, input: input)
      if let scope, let encoded = GroupMapping.encodeGroupSnapshot(detail) {
        await environment.snapshots.writeData(
          encoded,
          for: .group(id.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return detail
    }

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
          return GroupMapping.mapDetail(
            try ok.body.json.group,
            reminderIntervalDays: GroupMapping.extractReminderIntervalDays(
              from: ResponseBodyCapture.box?.read()
            )
          )
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

  public func setMuted(id: ExpenseGroup.ID, muted: Bool) async throws(AppError) -> Bool {
    do {
      let output = try await environment.client
        .put_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_me_sol_muted(
          .init(
            path: .init(groupId: id.rawValue),
            body: .json(.init(muted: muted))
          )
        )
      switch output {
      case .ok(let ok):
        return try ok.body.json.muted
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  private func patchGroupRaw(
    id: ExpenseGroup.ID,
    input: UpdateGroupInput
  ) async throws(AppError) -> ExpenseGroup {
    var payload: [String: Any] = [:]
    if let name = input.name { payload["name"] = name }
    if let min = input.minimizeDebts { payload["minimizeDebts"] = min }
    if let def = input.defaultRole { payload["defaultRole"] = def.code }
    switch input.reminderInterval {
    case .unchanged: break
    case .off: payload["reminderIntervalDays"] = NSNull()
    case .interval(let days): payload["reminderIntervalDays"] = days
    }
    switch input.approvalThreshold {
    case .unchanged: break
    case .off: payload["approvalThreshold"] = NSNull()
    case .threshold(let money): payload["approvalThreshold"] = money.amount
    }

    let url = environment.configuration.apiBaseURL
      .appendingPathComponent("groups")
      .appendingPathComponent(id.rawValue)
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
      let (data, http, snapshot) = try await environment.performAuthorizedDataRequest(request)
      guard http.statusCode == 200 else {
        let code = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      return try GroupMapping.decodeResilientGroup(from: data)
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
