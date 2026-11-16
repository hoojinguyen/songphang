public struct QuickEntryReading: Sendable, Hashable {
  public enum Status: Sendable, Hashable {
    case ok
    case needsInput
    case unparsed
    case unknown(String)

    public init(code: String) {
      switch code {
      case "ok": self = .ok
      case "needs_input": self = .needsInput
      case "unparsed": self = .unparsed
      default: self = .unknown(code)
      }
    }
  }

  public struct Draft: Sendable, Hashable {
    public var description: String?
    public var amount: Money?
    public var payers: [MemberAmount]
    public var split: SplitSpec?

    public init(
      description: String?,
      amount: Money?,
      payers: [MemberAmount],
      split: SplitSpec?
    ) {
      self.description = description
      self.amount = amount
      self.payers = payers
      self.split = split
    }
  }

  public enum SpanKind: Sendable, Hashable {
    case amount
    case description
    case payer
    case equal
    case exact
    case remainder
    case unknown(String)
  }

  public struct Span: Sendable, Hashable {
    public let start: Int
    public let end: Int
    public let kind: SpanKind

    public init(start: Int, end: Int, kind: SpanKind) {
      self.start = start
      self.end = end
      self.kind = kind
    }
  }

  public enum IssueCode: Sendable, Hashable {
    case amountMissing
    case descriptionMissing
    case memberAmbiguous
    case memberUnknown
    case countMismatch
    case sumMismatch
    case textNotUnderstood
    case unknown(String)
  }

  public struct Issue: Sendable, Hashable {
    public let code: IssueCode
    public let start: Int
    public let end: Int
    public let candidates: [Member.ID]
    public let count: Int?
    public let expected: Money?
    public let actual: Money?

    public init(
      code: IssueCode,
      start: Int,
      end: Int,
      candidates: [Member.ID] = [],
      count: Int? = nil,
      expected: Money? = nil,
      actual: Money? = nil
    ) {
      self.code = code
      self.start = start
      self.end = end
      self.candidates = candidates
      self.count = count
      self.expected = expected
      self.actual = actual
    }
  }

  public let status: Status
  public let text: String
  public var draft: Draft
  public var shares: [MemberAmount]?
  public let spans: [Span]
  public let issues: [Issue]

  public init(
    status: Status,
    text: String,
    draft: Draft,
    shares: [MemberAmount]? = nil,
    spans: [Span],
    issues: [Issue]
  ) {
    self.status = status
    self.text = text
    self.draft = draft
    self.shares = shares
    self.spans = spans
    self.issues = issues
  }
}
