import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct AccountView: View {
  @Bindable private var model: AccountModel
  private let onBack: () -> Void

  public init(model: AccountModel, onBack: @escaping () -> Void) {
    self.model = model
    self.onBack = onBack
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        SPScreenHeader(
          title: L10n.tr("account.title"),
          onBack: onBack
        )

        switch model.user {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 96)

        case .failed:
          LoadError {
            Task { await model.load() }
          }

        case .loaded(let user):
          loadedContent(user)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .task {
      await model.load()
    }
  }

  @ViewBuilder
  private func loadedContent(_ user: User) -> some View {
    HStack(spacing: 12) {
      MemberShapeView(
        shape: .circle,
        color: .mint,
        name: user.name,
        size: 52
      )
      VStack(alignment: .leading, spacing: 2) {
        Text(user.name)
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        Text(user.email)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
      Spacer(minLength: 0)
    }
    .padding(20)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

    if user.hasPassword {
      changePasswordCard
    }

    SessionsSectionView(
      sessions: model.sessions,
      revokingSessionId: model.revokingSessionId,
      revokeError: model.revokeSessionError,
      isOffline: model.isOffline,
      onRetry: { Task { await model.reloadSessions() } },
      onRevoke: { session in Task { await model.revokeSession(session) } }
    )

    SPButton(
      L10n.tr("common.logout"),
      variant: .surface,
      size: .lg,
      isFullWidth: true,
      isPending: model.isSigningOut
    ) {
      Task { await model.signOut() }
    }

    if let signOutError = model.signOutError {
      Text(signOutError)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }

    deleteAccountCard(email: user.email)
  }

  private var changePasswordCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("account.changePassword"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      SPTextField(
        label: L10n.tr("account.currentPassword"),
        text: $model.currentPassword,
        kind: .password,
        maxLength: 1024
      )

      SPTextField(
        label: L10n.tr("account.newPassword"),
        text: $model.newPassword,
        kind: .password,
        maxLength: 1024
      )

      Toggle(isOn: $model.revokeOtherSessions) {
        Text(L10n.tr("account.revokeOthers"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)
      }
      .tint(Tokens.ink)

      if let passwordError = model.passwordError {
        Text(passwordError)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      if model.passwordSaved {
        Text(L10n.tr("account.passwordChanged"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      SPButton(
        L10n.tr("account.savePassword"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: model.isOffline,
        isPending: model.isSavingPassword
      ) {
        Task { await model.savePassword() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
  }

  private func deleteAccountCard(email: String) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("account.delete"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      Text(L10n.tr("account.deleteHint"))
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.ink)

      SPTextField(
        label: L10n.tr("auth.email"),
        text: $model.deleteConfirmationEmail,
        kind: .email,
        maxLength: 254
      )

      if let deleteError = model.deleteError {
        Text(deleteError)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      SPButton(
        L10n.tr("account.delete"),
        variant: .primary,
        isFullWidth: true,
        isDisabled: model.isOffline || model.deleteConfirmationEmail != email
          || model.isDeletingAccount,
        isPending: model.isDeletingAccount
      ) {
        Task { await model.deleteAccount() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.debtSoft)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    AccountView(
      model: AccountModel(
        repository: FakeAuthRepository(world: world),
        initialUser: PreviewSamples.user,
        onSignedOut: {}
      ),
      onBack: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    AccountView(
      model: AccountModel(
        repository: FakeAuthRepository(world: world),
        onSignedOut: {}
      ),
      onBack: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    AccountView(
      model: AccountModel(
        repository: FakeAuthRepository(world: world),
        onSignedOut: {}
      ),
      onBack: {}
    )
  }
#endif
