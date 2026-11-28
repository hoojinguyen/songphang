import DesignSystem
public import Domain
import Foundation
public import Observation

@Observable
public final class PaymentDetailsModel {
  public let groupId: ExpenseGroup.ID
  public let member: Member
  public var bin = ""
  public var accountNumber = ""
  public var accountName = ""
  public var momo = ""
  public var zalopay = ""
  public private(set) var isSaving = false
  public private(set) var saved = false
  public private(set) var validationError: String?
  public private(set) var saveError: AppError?

  private let initialBin: String
  private let initialAccountNumber: String
  private let initialAccountName: String
  private let initialMomo: String
  private let initialZalopay: String

  private let repository: any MembersRepository
  private let onSaved: () -> Void
  private let onUnauthorized: () -> Void

  public init(
    groupId: ExpenseGroup.ID,
    member: Member,
    repository: any MembersRepository,
    onSaved: @escaping () -> Void = {},
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.member = member
    self.repository = repository
    self.onSaved = onSaved
    self.onUnauthorized = onUnauthorized

    var initBin = ""
    var initAccountNumber = ""
    var initAccountName = ""
    var initMomo = ""
    var initZalopay = ""

    for method in member.paymentMethods {
      switch method {
      case .bank(let bank):
        initBin = bank.bin
        initAccountNumber = bank.accountNumber
        initAccountName = bank.accountName
      case .momo(let phone):
        initMomo = phone
      case .zalopay(let phone):
        initZalopay = phone
      }
    }

    self.initialBin = initBin
    self.initialAccountNumber = initAccountNumber
    self.initialAccountName = initAccountName
    self.initialMomo = initMomo
    self.initialZalopay = initZalopay
    self.bin = initBin
    self.accountNumber = initAccountNumber
    self.accountName = initAccountName
    self.momo = initMomo
    self.zalopay = initZalopay
  }

  var hasUnsavedChanges: Bool {
    !saved
      && (bin != initialBin
        || accountNumber != initialAccountNumber
        || accountName != initialAccountName
        || momo != initialMomo
        || zalopay != initialZalopay)
  }

  var hasInvalidAccountNumberCharacters: Bool {
    let trimmed = accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return trimmed.range(of: "^[A-Za-z0-9]+$", options: .regularExpression) == nil
  }

  var errorMessage: String? {
    if let validationError { return validationError }
    guard let saveError else { return nil }
    if case .api(_, 403) = saveError {
      return L10n.tr("common.forbidden")
    }
    return L10n.tr("common.saveError")
  }

  func updateAccountName(_ raw: String) {
    let replacedD =
      raw
      .replacingOccurrences(of: "đ", with: "d")
      .replacingOccurrences(of: "Đ", with: "D")
    let folded = replacedD.applyingTransform(.stripDiacritics, reverse: false) ?? replacedD
    accountName = String(folded.uppercased(with: Locale(identifier: "vi_VN")).prefix(50))
  }

  func save() async -> Bool {
    guard !isSaving else { return false }
    saved = false
    validationError = nil
    saveError = nil

    let trimmedNumber = accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedMomo = Self.normalizePhone(momo)
    let trimmedZalo = Self.normalizePhone(zalopay)

    var methods: [PaymentMethod] = []
    if !trimmedNumber.isEmpty {
      guard let bank = PaymentBanks.entries.first(where: { $0.bin == bin }) else {
        validationError = L10n.tr("common.saveError")
        return false
      }
      guard trimmedNumber.range(of: "^[A-Za-z0-9]{4,19}$", options: .regularExpression) != nil
      else {
        validationError = L10n.tr("payment.invalidAccount")
        return false
      }
      guard !trimmedName.isEmpty else {
        validationError = L10n.tr("common.saveError")
        return false
      }
      methods.append(
        .bank(
          BankPayment(
            bin: bank.bin,
            name: bank.shortName,
            accountNumber: trimmedNumber,
            accountName: trimmedName
          )
        )
      )
    }

    if !momo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      guard Self.isValidPhone(trimmedMomo) else {
        validationError = L10n.tr("payment.invalidPhone")
        return false
      }
      methods.append(.momo(phone: trimmedMomo))
    }

    if !zalopay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      guard Self.isValidPhone(trimmedZalo) else {
        validationError = L10n.tr("payment.invalidPhone")
        return false
      }
      methods.append(.zalopay(phone: trimmedZalo))
    }

    isSaving = true
    defer { isSaving = false }
    do {
      try await repository.replacePaymentMethods(
        groupId: groupId,
        memberId: member.id,
        methods: methods
      )
      saved = true
      onSaved()
      return true
    } catch {
      if error == .unauthorized {
        onUnauthorized()
      } else {
        saveError = error
      }
      return false
    }
  }

  private static func normalizePhone(_ value: String) -> String {
    let compact =
      value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: ".", with: "")
    if compact.hasPrefix("+84") {
      return "0" + compact.dropFirst(3)
    }
    if compact.hasPrefix("84") {
      return "0" + compact.dropFirst(2)
    }
    return compact
  }

  private static func isValidPhone(_ value: String) -> Bool {
    value.range(of: "^0\\d{9}$", options: .regularExpression) != nil
  }
}
