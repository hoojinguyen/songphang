import AuthenticationServices
import CryptoKit
public import Domain
public import Foundation
import Security
import UIKit

public enum GoogleAuthCallback: Sendable, Equatable {
  case code(String)
  case error(AppError)

  public static func parse(_ url: URL) -> GoogleAuthCallback? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme?.lowercased() == "songphang",
      components.host?.lowercased() == "auth",
      components.path.isEmpty || components.path == "/"
    else {
      return nil
    }
    let items = components.queryItems ?? []
    guard items.count == 1, let item = items.first, let value = item.value else {
      return nil
    }
    switch item.name {
    case "code":
      guard isValidExchangeCode(value) else { return nil }
      return .code(value)
    case "error":
      switch value {
      case "google_unverified":
        return .error(.api(code: "GOOGLE_UNVERIFIED", status: 400))
      case "google":
        return .error(.api(code: "GOOGLE_FAILED", status: 400))
      default:
        return nil
      }
    default:
      return nil
    }
  }

  private static func isValidExchangeCode(_ code: String) -> Bool {
    guard code.count == 43 else { return false }
    return code.unicodeScalars.allSatisfy { scalar in
      (scalar >= "A" && scalar <= "Z")
        || (scalar >= "a" && scalar <= "z")
        || (scalar >= "0" && scalar <= "9")
        || scalar == "-"
        || scalar == "_"
    }
  }
}

enum GoogleAuthCoordinator {
  private struct PKCEPair: Sendable {
    let verifier: String
    let challenge: String

    static func generate() throws(AppError) -> PKCEPair {
      var bytes = [UInt8](repeating: 0, count: 32)
      let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
      guard status == errSecSuccess else {
        throw .unexpected
      }
      let verifier = base64URL(Data(bytes))
      let digest = SHA256.hash(data: Data(verifier.utf8))
      let challenge = base64URL(Data(digest))
      return PKCEPair(verifier: verifier, challenge: challenge)
    }

    private static func base64URL(_ data: Data) -> String {
      data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    }
  }

  @MainActor
  private final class PresentationAnchorProvider: NSObject,
    ASWebAuthenticationPresentationContextProviding
  {
    private let anchor: UIWindow

    init(anchor: UIWindow) {
      self.anchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
      anchor
    }
  }

  static func authorize(webBaseURL: URL) async throws(AppError) -> (
    code: String, codeVerifier: String
  ) {
    let pkce = try PKCEPair.generate()
    guard var components = URLComponents(url: webBaseURL, resolvingAgainstBaseURL: false) else {
      throw .unexpected
    }
    let trimmedPath =
      components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(trimmedPath)/api/v1/auth/google"
    components.queryItems = [
      URLQueryItem(name: "client", value: "ios"),
      URLQueryItem(name: "code_challenge", value: pkce.challenge),
    ]
    guard let startURL = components.url else {
      throw .unexpected
    }

    let callbackURL = try await runWebSession(url: startURL)
    guard let parsed = GoogleAuthCallback.parse(callbackURL) else {
      throw .api(code: "GOOGLE_FAILED", status: 400)
    }
    switch parsed {
    case .code(let code):
      return (code: code, codeVerifier: pkce.verifier)
    case .error(let appError):
      throw appError
    }
  }

  @MainActor
  private static func runWebSession(url: URL) async throws(AppError) -> URL {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard
      let anchor = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
        ?? scenes.flatMap(\.windows).first
        ?? scenes.first.map(UIWindow.init(windowScene:))
    else {
      throw .unexpected
    }

    let provider = PresentationAnchorProvider(anchor: anchor)
    do {
      return try await withCheckedThrowingContinuation { continuation in
        let session = ASWebAuthenticationSession(
          url: url,
          callbackURLScheme: "songphang"
        ) { callbackURL, error in
          if let error {
            if let authError = error as? ASWebAuthenticationSessionError,
              authError.code == .canceledLogin
            {
              continuation.resume(throwing: AppError.api(code: "AUTH_CANCELLED", status: 0))
            } else {
              continuation.resume(throwing: AppError.api(code: "GOOGLE_FAILED", status: 400))
            }
            return
          }
          guard let callbackURL else {
            continuation.resume(throwing: AppError.api(code: "GOOGLE_FAILED", status: 400))
            return
          }
          continuation.resume(returning: callbackURL)
        }
        session.presentationContextProvider = provider
        session.prefersEphemeralWebBrowserSession = true
        if !session.start() {
          continuation.resume(throwing: AppError.api(code: "GOOGLE_FAILED", status: 400))
        }
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw .api(code: "GOOGLE_FAILED", status: 400)
    }
  }
}
