import Foundation
import OpenAPIURLSession

enum BearerURLSession {
  static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.httpShouldSetCookies = false
    configuration.httpCookieAcceptPolicy = .never
    configuration.httpCookieStorage = nil
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.waitsForConnectivity = false
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 60
    return URLSession(configuration: configuration)
  }

  static func makeStreamingSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.httpShouldSetCookies = false
    configuration.httpCookieAcceptPolicy = .never
    configuration.httpCookieStorage = nil
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.waitsForConnectivity = false
    configuration.timeoutIntervalForRequest = 90
    configuration.timeoutIntervalForResource = 0
    return URLSession(configuration: configuration)
  }

  static func makeTransport(session: URLSession) -> URLSessionTransport {
    URLSessionTransport(configuration: .init(session: session))
  }
}
