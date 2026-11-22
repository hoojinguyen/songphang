public import Domain
import Foundation
import GeneratedAPI

public final class LiveCategoriesRepository: CategoriesRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func lastKnownCategories(groupId: ExpenseGroup.ID) async -> [GroupCategory]? {
    await environment.snapshots.read(.categories(groupId.rawValue)) { data in
      try CategoryMapping.decodeSnapshot(from: data)
    }
  }

  public func list(groupId: ExpenseGroup.ID) async throws(AppError) -> [GroupCategory] {
    let scope = await environment.snapshots.currentScope()
    let groupGen = await environment.snapshots.groupGeneration(for: groupId.rawValue)
    do {
      let categories: [GroupCategory] = try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_categories(
            .init(path: .init(groupId: groupId.rawValue))
          )
        switch output {
        case .ok(let ok):
          return try ok.body.json.categories.map(CategoryMapping.mapCategory)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try CategoryMapping.decodeResilientList(from: data)
      }

      if let scope, let encoded = CategoryMapping.encodeSnapshot(categories) {
        await environment.snapshots.writeData(
          encoded,
          for: .categories(groupId.rawValue),
          scope: scope,
          groupGeneration: groupGen
        )
      }
      return categories
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func create(
    groupId: ExpenseGroup.ID,
    name: String,
    color: MemberColor,
    key: IdempotencyKey
  ) async throws(AppError) -> GroupCategory {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_categories(
            .init(
              path: .init(groupId: groupId.rawValue),
              headers: .init(idempotency_hyphen_key: key.rawValue),
              body: .json(
                .init(
                  color: CategoryMapping.encodeCreateColor(color),
                  name: name
                )
              )
            )
          )
        switch output {
        case .created(let created):
          return CategoryMapping.mapCategory(try created.body.json.category)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try CategoryMapping.decodeResilientSingle(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func update(
    groupId: ExpenseGroup.ID,
    categoryId: GroupCategory.ID,
    name: String?,
    color: MemberColor?
  ) async throws(AppError) -> GroupCategory {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .patch_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_categories_sol__lcub_id_rcub_(
            .init(
              path: .init(groupId: groupId.rawValue, id: categoryId.rawValue),
              body: .json(
                .init(
                  color: color.map(CategoryMapping.encodeUpdateColor),
                  name: name
                )
              )
            )
          )
        switch output {
        case .ok(let ok):
          return CategoryMapping.mapCategory(try ok.body.json.category)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try CategoryMapping.decodeResilientSingle(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func archive(
    groupId: ExpenseGroup.ID,
    categoryId: GroupCategory.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_categories_sol__lcub_id_rcub_(
          .init(path: .init(groupId: groupId.rawValue, id: categoryId.rawValue))
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
}
