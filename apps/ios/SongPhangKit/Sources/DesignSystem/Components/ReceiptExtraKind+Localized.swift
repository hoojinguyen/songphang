public import Domain

extension ReceiptExtraKind {
  public var localizedTitle: String {
    switch self {
    case .tax: return L10n.tr("receipts.extrasKinds.tax")
    case .service: return L10n.tr("receipts.extrasKinds.service")
    case .shipping: return L10n.tr("extras.kindShipping")
    case .discount: return L10n.tr("receipts.extrasKinds.discount")
    case .other, .unknown: return L10n.tr("receipts.extrasKinds.other")
    }
  }
}
