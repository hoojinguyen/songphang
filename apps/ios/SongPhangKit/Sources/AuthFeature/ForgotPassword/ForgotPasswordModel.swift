public import Domain
public import Observation

@Observable
public final class ForgotPasswordModel {
  public var email = ""
  public private(set) var isSubmitting = false
  public private(set) var isSubmitted = false
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
    AuthErrorMessages.message(for: submitError)
  }

  public func submit() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    do throws(AppError) {
      try await repository.requestPasswordReset(email: email)
      isSubmitted = true
    } catch {
      submitError = error
    }
  }
}
