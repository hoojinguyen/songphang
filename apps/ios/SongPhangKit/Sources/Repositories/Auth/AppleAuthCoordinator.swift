import AuthenticationServices
import CryptoKit
import Domain
import Foundation
import Security
import UIKit

struct AppleAuthorizationPayload: Sendable {
  let identityToken: String
  let rawNonce: String
  let authorizationCode: String
  let name: String?
}

enum AppleAuthCoordinator {
  @MainActor
  private final class Delegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
  {
    private let anchor: UIWindow
    private var controller: ASAuthorizationController?
    private var continuation: CheckedContinuation<AppleAuthorizationPayload, any Error>?
    private let rawNonce: String

    init(
      anchor: UIWindow,
      rawNonce: String,
      continuation: CheckedContinuation<AppleAuthorizationPayload, any Error>
    ) {
      self.anchor = anchor
      self.rawNonce = rawNonce
      self.continuation = continuation
    }

    func start(request: ASAuthorizationAppleIDRequest) {
      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      self.controller = controller
      controller.performRequests()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
      anchor
    }

    func authorizationController(
      controller: ASAuthorizationController,
      didCompleteWithAuthorization authorization: ASAuthorization
    ) {
      guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
        let tokenData = credential.identityToken,
        let identityToken = String(data: tokenData, encoding: .utf8),
        let codeData = credential.authorizationCode,
        let authorizationCode = String(data: codeData, encoding: .utf8),
        !identityToken.isEmpty,
        !authorizationCode.isEmpty
      else {
        finish(.failure(AppError.api(code: "APPLE_FAILED", status: 400)))
        return
      }
      let formattedName: String? = credential.fullName.flatMap { components in
        let text = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : String(text.prefix(50))
      }
      finish(
        .success(
          AppleAuthorizationPayload(
            identityToken: identityToken,
            rawNonce: rawNonce,
            authorizationCode: authorizationCode,
            name: formattedName
          )
        )
      )
    }

    func authorizationController(
      controller: ASAuthorizationController,
      didCompleteWithError error: any Error
    ) {
      if let authError = error as? ASAuthorizationError, authError.code == .canceled {
        finish(.failure(AppError.api(code: "AUTH_CANCELLED", status: 0)))
      } else {
        finish(.failure(AppError.api(code: "APPLE_FAILED", status: 400)))
      }
    }

    private func finish(_ result: Result<AppleAuthorizationPayload, any Error>) {
      guard let cont = continuation else { return }
      continuation = nil
      controller = nil
      cont.resume(with: result)
    }
  }

  static func authorize() async throws(AppError) -> AppleAuthorizationPayload {
    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw .unexpected
    }
    let rawNonce = Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    let digest = SHA256.hash(data: Data(rawNonce.utf8))
    let hashedNonce = digest.map { String(format: "%02x", $0) }.joined()

    do {
      return try await startOnMainActor(rawNonce: rawNonce, hashedNonce: hashedNonce)
    } catch let error as AppError {
      throw error
    } catch {
      throw .api(code: "APPLE_FAILED", status: 400)
    }
  }

  @MainActor
  private static func startOnMainActor(
    rawNonce: String,
    hashedNonce: String
  ) async throws -> AppleAuthorizationPayload {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard
      let anchor = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
        ?? scenes.flatMap(\.windows).first
        ?? scenes.first.map(UIWindow.init(windowScene:))
    else {
      throw AppError.unexpected
    }

    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = hashedNonce

    var retainedDelegate: Delegate?
    // Keep the delegate alive until the continuation resumes; ASAuthorizationController references its delegate and context provider weakly.
    defer { _ = retainedDelegate }

    return try await withCheckedThrowingContinuation { continuation in
      let delegate = Delegate(anchor: anchor, rawNonce: rawNonce, continuation: continuation)
      retainedDelegate = delegate
      delegate.start(request: request)
    }
  }
}
