import DesignSystem
public import Domain
public import Observation
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

@Observable
public final class VerifyEmailBannerModel {
  public private(set) var isSending = false
  public private(set) var isResent = false
  public private(set) var resendError: AppError?

  private let repository: any AuthRepository

  public init(repository: any AuthRepository) {
    self.repository = repository
  }

  public var errorMessage: String? {
    AuthErrorMessages.message(for: resendError)
  }

  public func resend() async {
    guard !isSending else { return }
    isSending = true
    resendError = nil
    defer { isSending = false }
    do throws(AppError) {
      try await repository.resendVerification()
      isResent = true
    } catch {
      resendError = error
    }
  }
}

public struct VerifyEmailBannerView: View {
  private let model: VerifyEmailBannerModel

  public init(model: VerifyEmailBannerModel) {
    self.model = model
  }

  public var body: some View {
    SPCard(tone: .accent, padding: 20) {
      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.onAccent)

        SPButton(
          L10n.tr("verify.resend"),
          variant: .surface,
          isPending: model.isSending
        ) {
          Task { await model.resend() }
        }

        if model.isResent {
          Text(L10n.tr("verify.resent"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.onAccent)
        }

        if let errorMessage = model.errorMessage {
          Text(errorMessage)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.onAccent)
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Verify Email Banner") {
    let world = FakeWorld(preset: .tripStep4)
    VerifyEmailBannerView(
      model: VerifyEmailBannerModel(repository: FakeAuthRepository(world: world))
    )
    .padding()
    .background(Tokens.bg)
  }
#endif
