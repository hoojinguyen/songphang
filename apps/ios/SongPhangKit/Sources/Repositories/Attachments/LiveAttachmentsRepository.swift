public import Domain
public import Foundation
import GeneratedAPI

public final class LiveAttachmentsRepository: AttachmentsRepository, Sendable {
  private struct UploadErrorPayload: Decodable {
    struct Details: Decodable {
      let reason: String?
    }
    struct Inner: Decodable {
      let code: String
      let details: Details?
    }
    let error: Inner
  }

  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func upload(
    groupId: ExpenseGroup.ID,
    data: Data,
    filename: String,
    contentType: String,
    purpose: AttachmentUploadPurpose
  ) async throws(AppError) -> Attachment {
    let baseURL = environment.configuration.apiBaseURL
      .appendingPathComponent("groups")
      .appendingPathComponent(groupId.rawValue)
      .appendingPathComponent("attachments")
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    if purpose == .transferProof {
      components?.queryItems = [URLQueryItem(name: "purpose", value: purpose.rawValue)]
    }
    let url = components?.url ?? baseURL

    let boundary = "songphang-\(UUID().uuidString)"
    let safeName =
      filename
      .replacingOccurrences(of: "\"", with: "")
      .replacingOccurrences(of: "\r", with: "")
      .replacingOccurrences(of: "\n", with: "")
    let resolvedName = safeName.isEmpty ? "receipt.jpg" : safeName

    var body = Data()
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(
      Data(
        "Content-Disposition: form-data; name=\"file\"; filename=\"\(resolvedName)\"\r\n".utf8
      )
    )
    body.append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
    body.append(data)
    body.append(Data("\r\n--\(boundary)--\r\n".utf8))

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(
      "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    do {
      let (responseData, http, snapshot) = try await environment.performAuthorizedUploadRequest(
        request
      )
      guard (200..<300).contains(http.statusCode) else {
        let decoded = try? JSONDecoder().decode(UploadErrorPayload.self, from: responseData)
        let reason = decoded?.error.details?.reason
        if http.statusCode == 413 || reason == "too_large" {
          throw AppError.api(code: "UPLOAD_TOO_LARGE", status: http.statusCode)
        }
        if reason == "not_an_image" {
          throw AppError.api(code: "UPLOAD_NOT_AN_IMAGE", status: http.statusCode)
        }
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: decoded?.error.code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      return try ReceiptMapping.decodeResilientAttachment(from: responseData)
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func content(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID
  ) async throws(AppError) -> Data {
    let url = environment.configuration.apiBaseURL
      .appendingPathComponent("groups")
      .appendingPathComponent(groupId.rawValue)
      .appendingPathComponent("attachments")
      .appendingPathComponent(attachmentId.rawValue)
      .appendingPathComponent("content")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (responseData, http, snapshot) = try await environment.performAuthorizedDataRequest(
        request
      )
      guard (200..<300).contains(http.statusCode) else {
        let decoded = try? JSONDecoder().decode(UploadErrorPayload.self, from: responseData)
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: decoded?.error.code,
          sessionGeneration: snapshot.token != nil ? snapshot.generation : nil
        )
      }
      return responseData
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func delete(
    groupId: ExpenseGroup.ID,
    attachmentId: Attachment.ID
  ) async throws(AppError) {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_attachments_sol__lcub_id_rcub_(
          .init(path: .init(groupId: groupId.rawValue, id: attachmentId.rawValue))
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
