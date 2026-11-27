import DesignSystem
public import Domain
import Foundation
public import Observation

@Observable
public final class RegisterModel {
  public var name = ""
  public var email = ""
  public var password = ""
  public private(set) var isSubmitting = false
  public private(set) var isSubmitted = false
  public private(set) var clientError: String?
  public private(set) var submitError: AppError?

  private let repository: any AuthRepository

  public init(
    repository: any AuthRepository,
    initialSubmitted: Bool = false
  ) {
    self.repository = repository
    self.isSubmitted = initialSubmitted
  }

  public var displayedError: String? {
    clientError ?? AuthErrorMessages.message(for: submitError)
  }

  public func submit() async {
    guard !isSubmitting else { return }
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedName.count > 50 {
      clientError = L10n.tr("ios.auth.nameMaxLength")
      return
    }
    if let passwordError = AuthErrorMessages.passwordValidationError(password) {
      clientError = passwordError
      return
    }
    clientError = nil
    submitError = nil
    isSubmitting = true
    defer { isSubmitting = false }
    do throws(AppError) {
      try await repository.register(email: email, name: trimmedName, password: password)
      isSubmitted = true
    } catch {
      submitError = error
    }
  }
}
