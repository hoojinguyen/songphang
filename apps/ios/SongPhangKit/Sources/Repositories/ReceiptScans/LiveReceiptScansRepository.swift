public import Domain
import Foundation
import GeneratedAPI

public final class LiveReceiptScansRepository: ReceiptScansRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func start(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID,
    key: IdempotencyKey
  ) async throws(AppError) -> ReceiptScan {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_receipt_hyphen_scans(
            .init(
              path: .init(groupId: groupId.rawValue),
              headers: .init(idempotency_hyphen_key: key.rawValue),
              body: .json(.init(attachmentId: attachmentId.rawValue))
            )
          )
        switch output {
        case .ok(let ok):
          return ReceiptMapping.mapReceiptScan(try ok.body.json.scan)
        case .created(let created):
          return ReceiptMapping.mapReceiptScan(try created.body.json.scan)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try ReceiptMapping.decodeResilientScan(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func scan(
    groupId: ExpenseGroup.ID,
    id: ReceiptScan.ID
  ) async throws(AppError) -> ReceiptScan {
    do {
      return try await ResponseBodyCapture.withCapture {
        let output = try await environment.client
          .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_receipt_hyphen_scans_sol__lcub_id_rcub_(
            .init(path: .init(groupId: groupId.rawValue, id: id.rawValue))
          )
        switch output {
        case .ok(let ok):
          return ReceiptMapping.mapReceiptScan(try ok.body.json.scan)
        case .undocumented(let status, let payload):
          throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
        }
      } fallback: { data in
        try ReceiptMapping.decodeResilientScan(from: data)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }
}
