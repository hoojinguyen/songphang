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
  private final class SessionHolder: NSObject,
    ASWebAuthenticationPresentationContextProviding
  {
    private let anchor: UIWindow
    private var session: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, any Error>?

    init(anchor: UIWindow, continuation: CheckedContinuation<URL, any Error>) {
      self.anchor = anchor
      self.continuation = continuation
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
      anchor
    }

    func start(url: URL) {
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: "songphang"
      ) { [weak self] callbackURL, error in
        Task { @MainActor [weak self] in
          self?.handleCompletion(callbackURL: callbackURL, error: error)
        }
      }
      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = true
      self.session = session
      if !session.start() {
        finish(.failure(AppError.api(code: "GOOGLE_FAILED", status: 400)))
      }
    }

    private func handleCompletion(callbackURL: URL?, error: (any Error)?) {
      if let error {
        if let authError = error as? ASWebAuthenticationSessionError,
          authError.code == .canceledLogin
        {
          finish(.failure(AppError.api(code: "AUTH_CANCELLED", status: 0)))
        } else {
          finish(.failure(AppError.api(code: "GOOGLE_FAILED", status: 400)))
        }
        return
      }
      guard let callbackURL else {
        finish(.failure(AppError.api(code: "GOOGLE_FAILED", status: 400)))
        return
      }
      finish(.success(callbackURL))
    }

    private func finish(_ result: Result<URL, any Error>) {
      guard let cont = continuation else { return }
      continuation = nil
      session = nil
      cont.resume(with: result)
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

    var retainedHolder: SessionHolder?
    // Keep the holder alive until the continuation resumes; ASWebAuthenticationSession does not self-retain and its context provider is weak.
    defer { _ = retainedHolder }

    do {
      return try await withCheckedThrowingContinuation { continuation in
        let holder = SessionHolder(anchor: anchor, continuation: continuation)
        retainedHolder = holder
        holder.start(url: url)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw .api(code: "GOOGLE_FAILED", status: 400)
    }
  }
}
