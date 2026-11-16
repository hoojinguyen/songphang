public import Domain
public import Observation

@Observable
public final class SignInModel {
  public private(set) var features: Loadable<ServerFeatures> = .loading
  public var email = ""
  public var password = ""
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?

  private let repository: any AuthRepository
  private let onSignedIn: (User) -> Void

  public init(
    repository: any AuthRepository,
    initialEmail: String = "",
    initialPassword: String = "",
    initialSubmitError: AppError? = nil,
    onSignedIn: @escaping (User) -> Void
  ) {
    self.repository = repository
    self.email = initialEmail
    self.password = initialPassword
    self.submitError = initialSubmitError
    self.onSignedIn = onSignedIn
  }

  public func load() async {
    features = .loading
    do throws(AppError) {
      let result = try await repository.serverFeatures()
      features = .loaded(result)
    } catch {
      features = .failed(error)
    }
  }

  public func submitEmailPassword() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    do throws(AppError) {
      let user = try await repository.signIn(email: email, password: password)
      onSignedIn(user)
    } catch {
      submitError = error
    }
  }

  public func signInWithApple() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    do throws(AppError) {
      let user = try await repository.signInWithApple()
      onSignedIn(user)
    } catch {
      submitError = error
    }
  }

  public func signInWithGoogle() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    do throws(AppError) {
      let user = try await repository.signInWithGoogle()
      onSignedIn(user)
    } catch {
      submitError = error
    }
  }
}
