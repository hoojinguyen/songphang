import Foundation
import OpenAPIRuntime

struct FlexibleISO8601DateTranscoder: DateTranscoder, Sendable {
  func encode(_ date: Date) throws -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  func decode(_ dateString: String) throws -> Date {
    if let parsed = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true)
      .parse(dateString)
    {
      return parsed
    }
    return try Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(dateString)
  }
}
