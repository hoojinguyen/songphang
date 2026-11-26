public import Domain
import Foundation
import GeneratedAPI

public final class LiveHouseholdsRepository: HouseholdsRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [Household] {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_households(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return try ok.body.json.households.map(Self.mapDto)
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
    input: CreateHouseholdInput,
    key: IdempotencyKey
  ) async throws(AppError) -> Household {
    do {
      let body = Components.Schemas.CreateHouseholdRequest(
        memberIds: input.memberIds.map(\.rawValue),
        name: input.name,
        representativeMemberId: input.representativeMemberId.rawValue
      )
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_households(
          .init(
            path: .init(groupId: groupId.rawValue),
            headers: .init(idempotency_hyphen_key: key.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .created(let created):
        return Self.mapDto(try created.body.json.household)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    groupId: ExpenseGroup.ID,
    id: Household.ID,
    input: UpdateHouseholdInput
  ) async throws(AppError) -> Household {
    do {
      let body = Components.Schemas.UpdateHouseholdRequest(
        memberIds: input.memberIds?.map(\.rawValue),
        name: input.name,
        representativeMemberId: input.representativeMemberId?.rawValue
      )
      let output = try await environment.client
        .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_households_sol__lcub_householdId_rcub_(
          .init(
            path: .init(groupId: groupId.rawValue, householdId: id.rawValue),
            body: .json(body)
          )
        )
      switch output {
      case .ok(let ok):
        return Self.mapDto(try ok.body.json.household)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(groupId: ExpenseGroup.ID, id: Household.ID) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_households_sol__lcub_householdId_rcub_(
          .init(path: .init(groupId: groupId.rawValue, householdId: id.rawValue))
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

  private static func mapDto(_ dto: Components.Schemas.HouseholdDto) -> Household {
    Household(
      id: Household.ID(dto.id),
      name: dto.name,
      representativeMemberId: Member.ID(dto.representativeMemberId),
      memberIds: dto.memberIds.map(Member.ID.init),
      createdAt: TransactionMapping.formatISO(dto.createdAt),
      updatedAt: TransactionMapping.formatISO(dto.updatedAt)
    )
  }
}
