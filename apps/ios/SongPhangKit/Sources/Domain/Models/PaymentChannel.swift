public enum PaymentChannel: Sendable, Hashable, CaseIterable {
  case bank
  case momo
  case zalopay
  case cash
  case unknown(String)

  public static var allCases: [PaymentChannel] {
    [.bank, .momo, .zalopay, .cash]
  }

  public init(code: String) {
    switch code {
    case "bank": self = .bank
    case "momo": self = .momo
    case "zalopay": self = .zalopay
    case "cash": self = .cash
    default: self = .unknown(code)
    }
  }

  public var code: String {
    switch self {
    case .bank: return "bank"
    case .momo: return "momo"
    case .zalopay: return "zalopay"
    case .cash: return "cash"
    case .unknown(let raw): return raw
    }
  }
}

public enum AttachmentUploadPurpose: String, Sendable, Hashable {
  case expense
  case transferProof = "transfer_proof"
}
