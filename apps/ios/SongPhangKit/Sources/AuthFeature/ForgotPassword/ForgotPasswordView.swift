import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct ForgotPasswordView: View {
  @Bindable private var model: ForgotPasswordModel
  private let onBackToSignIn: () -> Void

  public init(model: ForgotPasswordModel, onBackToSignIn: @escaping () -> Void) {
    self.model = model
    self.onBackToSignIn = onBackToSignIn
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if model.isSubmitted {
          Text(L10n.tr("forgotPassword.submitted"))
            .font(Typography.body)
            .foregroundStyle(Tokens.ink)
        } else {
          VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr("forgotPassword.hint"))
              .font(Typography.body)
              .foregroundStyle(Tokens.ink)

            SPTextField(
              label: L10n.tr("auth.email"),
              text: $model.email,
              kind: .email,
              maxLength: 254
            )

            if let errorMessage = model.displayedError {
              Text(errorMessage)
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
            }

            SPButton(
              L10n.tr("forgotPassword.submit"),
              variant: .primary,
              size: .lg,
              isFullWidth: true,
              isPending: model.isSubmitting
            ) {
              Task { await model.submit() }
            }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationTitle(L10n.tr("forgotPassword.title"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#if DEBUG
  #Preview("Forgot Password") {
    let world = FakeWorld(preset: .tripStep4, signedIn: false)
    ForgotPasswordView(
      model: ForgotPasswordModel(repository: FakeAuthRepository(world: world)),
      onBackToSignIn: {}
    )
  }
#endif
