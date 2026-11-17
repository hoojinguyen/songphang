import DesignSystem
import Domain

enum AuthErrorMessages {
  static func message(for error: AppError?) -> String? {
    guard let error else { return nil }
    switch error {
    case .rateLimited:
      return L10n.tr("login.tooMany")
    case .api(let code, _):
      switch code {
      case "RATE_LIMITED":
        return L10n.tr("login.tooMany")
      case "INVALID_CREDENTIALS":
        return L10n.tr("login.invalidCredentials")
      case "WEAK_PASSWORD":
        return L10n.tr("auth.tooShort")
      default:
        return L10n.tr("common.saveError")
      }
    default:
      return L10n.tr("common.saveError")
    }
  }

  static func passwordValidationError(_ password: String) -> String? {
    if password.count < 10 {
      return L10n.tr("auth.tooShort")
    }
    if password.count > 128 {
      return L10n.tr("auth.passwordTooLong")
    }
    return nil
  }
}
