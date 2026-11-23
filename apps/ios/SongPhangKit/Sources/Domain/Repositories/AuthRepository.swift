public protocol AuthRepository: Sendable {
  func lastKnownUser() async -> User?
  func currentUser() async throws(AppError) -> User?
  func signIn(email: String, password: String) async throws(AppError) -> User
  func signInWithGoogle() async throws(AppError) -> User
  func signInWithApple() async throws(AppError) -> User
  func register(email: String, name: String, password: String) async throws(AppError)
  func requestPasswordReset(email: String) async throws(AppError)
  func resendVerification() async throws(AppError)
  func changePassword(
    currentPassword: String,
    newPassword: String,
    revokeOtherSessions: Bool
  ) async throws(AppError)
  func deleteAccount(email: String) async throws(AppError)
  func sessions() async throws(AppError) -> [UserSession]
  func revokeSession(id: UserSession.ID) async throws(AppError)
  func serverFeatures() async throws(AppError) -> ServerFeatures
  func sessionGeneration() async -> UInt64
  func signOut() async throws(AppError)
}
