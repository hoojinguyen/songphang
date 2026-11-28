import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct RegisterView: View {
  @Bindable private var model: RegisterModel
  private let onBackToSignIn: () -> Void

  public init(model: RegisterModel, onBackToSignIn: @escaping () -> Void) {
    self.model = model
    self.onBackToSignIn = onBackToSignIn
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if model.isSubmitted {
          VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr("register.submittedTitle"))
              .font(Typography.pageTitle)
              .foregroundStyle(Tokens.ink)

            Text(L10n.tr("register.submittedBody"))
              .font(Typography.body)
              .foregroundStyle(Tokens.ink)

            SPButton(
              L10n.tr("login.submit"),
              variant: .primary,
              size: .lg,
              isFullWidth: true,
              action: onBackToSignIn
            )
          }
        } else {
          VStack(alignment: .leading, spacing: 16) {
            SPTextField(
              label: L10n.tr("register.name"),
              text: $model.name,
              maxLength: 51
            )

            SPTextField(
              label: L10n.tr("auth.email"),
              text: $model.email,
              kind: .email,
              maxLength: 254
            )

            SPTextField(
              label: L10n.tr("auth.password"),
              text: $model.password,
              kind: .password,
              hint: L10n.tr("register.passwordHint"),
              maxLength: 1024
            )

            if let errorMessage = model.displayedError {
              Text(errorMessage)
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
            }

            SPButton(
              L10n.tr("register.title"),
              variant: .primary,
              size: .lg,
              isFullWidth: true,
              isPending: model.isSubmitting
            ) {
              Task { await model.submit() }
            }

            Button(action: onBackToSignIn) {
              Text(L10n.tr("register.login"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationTitle(L10n.tr("register.title"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#if DEBUG
  #Preview("Register Form") {
    let world = FakeWorld(preset: .tripStep4, signedIn: false)
    RegisterView(
      model: RegisterModel(repository: FakeAuthRepository(world: world)),
      onBackToSignIn: {}
    )
  }

  #Preview("Register Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .rateLimited),
      signedIn: false
    )
    RegisterView(
      model: RegisterModel(repository: FakeAuthRepository(world: world)),
      onBackToSignIn: {}
    )
  }
#endif
