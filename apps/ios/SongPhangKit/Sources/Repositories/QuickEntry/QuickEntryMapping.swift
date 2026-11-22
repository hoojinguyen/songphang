import Domain
import Foundation
import GeneratedAPI

enum QuickEntryMapping {
  static func mapSpanKind(_ raw: String) -> QuickEntryReading.SpanKind {
    switch raw {
    case "amount": return .amount
    case "description": return .description
    case "payer": return .payer
    case "equal": return .equal
    case "exact": return .exact
    case "remainder": return .remainder
    default: return .unknown(raw)
    }
  }

  static func mapIssueCode(_ raw: String) -> QuickEntryReading.IssueCode {
    switch raw {
    case "AMOUNT_MISSING": return .amountMissing
    case "DESCRIPTION_MISSING": return .descriptionMissing
    case "MEMBER_AMBIGUOUS": return .memberAmbiguous
    case "MEMBER_UNKNOWN": return .memberUnknown
    case "FUND_CANNOT_SHARE": return .fundCannotShare
    case "COUNT_MISMATCH": return .countMismatch
    case "SUM_MISMATCH": return .sumMismatch
    case "TEXT_NOT_UNDERSTOOD": return .textNotUnderstood
    default: return .unknown(raw)
    }
  }

  static func mapResponse(_ dto: Components.Schemas.ParseResponse) -> QuickEntryReading {
    let draft = QuickEntryReading.Draft(
      description: dto.draft.description,
      amount: dto.draft.amount.map { Money(Int64($0)) },
      payers: dto.draft.payers.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      split: TransactionMapping.mapSplitInput(dto.draft.split)
    )
    let shares = dto.shares?.map {
      MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
    }
    let spans = dto.spans.map {
      QuickEntryReading.Span(start: $0.start, end: $0.end, kind: mapSpanKind($0.kind.rawValue))
    }
    let issues = dto.issues.map { issue in
      QuickEntryReading.Issue(
        code: mapIssueCode(issue.code.rawValue),
        start: issue.start,
        end: issue.end,
        candidates: issue.candidates.map(Member.ID.init),
        count: issue.count.flatMap { Int(exactly: $0) },
        expected: issue.expected.flatMap { Int64(exactly: $0) }.map(Money.init),
        actual: issue.actual.flatMap { Int64(exactly: $0) }.map(Money.init)
      )
    }
    return QuickEntryReading(
      status: QuickEntryReading.Status(code: dto.status.rawValue),
      text: dto.text,
      draft: draft,
      shares: shares,
      spans: spans,
      issues: issues
    )
  }

  // MARK: - Resilient fallback for additive enum values

  struct RawParseResponse: Decodable, Sendable {
    struct RawDraft: Decodable, Sendable {
      let description: String?
      let amount: Int64?
      let payers: [TransactionMapping.RawMemberAmount]
      let split: TransactionMapping.RawSplitSpec?
    }

    struct RawSpan: Decodable, Sendable {
      let start: Int
      let end: Int
      let kind: String
    }

    struct RawIssue: Decodable, Sendable {
      let code: String
      let start: Int
      let end: Int
      let candidates: [String]
      let count: Int?
      let expected: Int64?
      let actual: Int64?
    }

    let status: String
    let text: String
    let draft: RawDraft
    let shares: [TransactionMapping.RawMemberAmount]?
    let spans: [RawSpan]
    let issues: [RawIssue]

    func toDomain() -> QuickEntryReading {
      QuickEntryReading(
        status: QuickEntryReading.Status(code: status),
        text: text,
        draft: QuickEntryReading.Draft(
          description: draft.description,
          amount: draft.amount.map(Money.init),
          payers: draft.payers.map {
            MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
          },
          split: draft.split?.toDomain()
        ),
        shares: shares?.map {
          MemberAmount(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        },
        spans: spans.map {
          QuickEntryReading.Span(
            start: $0.start,
            end: $0.end,
            kind: QuickEntryMapping.mapSpanKind($0.kind)
          )
        },
        issues: issues.map {
          QuickEntryReading.Issue(
            code: QuickEntryMapping.mapIssueCode($0.code),
            start: $0.start,
            end: $0.end,
            candidates: $0.candidates.map(Member.ID.init),
            count: $0.count,
            expected: $0.expected.map(Money.init),
            actual: $0.actual.map(Money.init)
          )
        }
      )
    }
  }

  static func decodeResilient(from data: Data) throws -> QuickEntryReading {
    try JSONDecoder().decode(RawParseResponse.self, from: data).toDomain()
  }
}
