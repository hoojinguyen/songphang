import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct SignInView: View {
  @Bindable private var model: SignInModel
  private let onOpenRegister: () -> Void
  private let onOpenForgotPassword: () -> Void
  @FocusState private var isPasswordFocused: Bool

  public init(
    model: SignInModel,
    onOpenRegister: @escaping () -> Void,
    onOpenForgotPassword: @escaping () -> Void
  ) {
    self.model = model
    self.onOpenRegister = onOpenRegister
    self.onOpenForgotPassword = onOpenForgotPassword
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LoginShapesView()

        Text(L10n.tr("login.headline"))
          .font(Typography.pageTitle)
          .foregroundStyle(Tokens.ink)
          .fixedSize(horizontal: false, vertical: true)

        switch model.features {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 64)
        case .failed:
          LoadError {
            Task { await model.load() }
          }
        case .loaded(let serverFeatures):
          loadedContent(serverFeatures)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task {
      if case .loading = model.features {
        await model.load()
      }
    }
  }

  @ViewBuilder
  private func loadedContent(_ serverFeatures: ServerFeatures) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      if serverFeatures.apple {
        Button {
          Task { await model.signInWithApple() }
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "apple.logo")
              .spIconFont(size: 18, weight: .bold, relativeTo: .headline)
              .accessibilityHidden(true)
            Text(L10n.tr("ios.login.apple"))
              .font(Typography.bodyBold)
          }
          .foregroundStyle(Tokens.surface)
          .frame(maxWidth: .infinity, minHeight: Tokens.controlLargeHeight)
          .background(Tokens.ink)
          .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(model.isSubmitting)
      }

      if serverFeatures.google {
        SPButton(
          L10n.tr("login.google"),
          variant: .surface,
          size: .lg,
          isFullWidth: true,
          isDisabled: model.isSubmitting
        ) {
          Task { await model.signInWithGoogle() }
        }
      }

      SPTextField(
        label: L10n.tr("auth.email"),
        text: $model.email,
        kind: .email,
        maxLength: 254,
        onSubmit: { isPasswordFocused = true },
        submitLabel: .next
      )

      SPTextField(
        label: L10n.tr("auth.password"),
        text: $model.password,
        kind: .password,
        maxLength: 1024,
        onSubmit: { Task { await model.submitEmailPassword() } },
        focus: $isPasswordFocused
      )

      if let errorMessage = AuthErrorMessages.message(for: model.submitError) {
        Text(errorMessage)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      SPButton(
        L10n.tr("login.submit"),
        variant: .primary,
        size: .lg,
        isFullWidth: true,
        isPending: model.isSubmitting
      ) {
        Task { await model.submitEmailPassword() }
      }

      HStack {
        Button(action: onOpenRegister) {
          Text(L10n.tr("login.register"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)

        Spacer()

        Button(action: onOpenForgotPassword) {
          Text(L10n.tr("login.forgot"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4, signedIn: false)
    SignInView(
      model: SignInModel(repository: FakeAuthRepository(world: world), onSignedIn: { _ in }),
      onOpenRegister: {},
      onOpenForgotPassword: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10)),
      signedIn: false
    )
    SignInView(
      model: SignInModel(repository: FakeAuthRepository(world: world), onSignedIn: { _ in }),
      onOpenRegister: {},
      onOpenForgotPassword: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline),
      signedIn: false
    )
    SignInView(
      model: SignInModel(repository: FakeAuthRepository(world: world), onSignedIn: { _ in }),
      onOpenRegister: {},
      onOpenForgotPassword: {}
    )
  }
#endif
