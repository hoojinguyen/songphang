import DesignSystem
import Domain
public import SwiftUI
import UIKit

#if canImport(WidgetKit)
  import WidgetKit
#endif

#if DEBUG
  import PreviewSupport
#endif

public struct AccountView: View {
  @Bindable private var model: AccountModel
  private let onBack: (() -> Void)?
  @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.system
    .rawValue
  @AppStorage(FeedbackSettings.soundEnabledKey) private var isSoundEnabled = true
  @AppStorage(FeedbackSettings.hapticsEnabledKey) private var isHapticsEnabled = true
  @State private var hideWidgetAmounts = ExtensionSharedStore.shared.readWidgetHideAmounts()

  public init(model: AccountModel, onBack: (() -> Void)? = nil) {
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

    appearanceCard

    soundAndHapticsCard

    widgetPrivacyCard

    if user.hasPassword {
      changePasswordCard
    }

    if model.pushFeatureEnabled {
      pushSettingsCard(user)
    }

    if model.telegramFeatureEnabled {
      TelegramAccountCardView(
        model: model,
        email: user.email,
        emailVerified: user.emailVerified
      )
    }

    notificationSettingsCard

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

  private var appearanceCard: some View {
    let selectedMode = AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    return VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("appearance.title"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      SPSegmentedControl(
        label: L10n.tr("appearance.title"),
        options: AppearanceMode.allCases.map {
          SPSegmentedControl.Option(value: $0.rawValue, label: L10n.tr($0.labelKey))
        },
        value: selectedMode.rawValue
      ) { nextValue in
        appearanceModeRaw = nextValue
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
  }

  private var soundAndHapticsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("ios.feedback.sectionTitle"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      Toggle(isOn: $isSoundEnabled) {
        Text(L10n.tr("ios.feedback.sound"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)
      }
      .tint(Tokens.credit)

      Toggle(isOn: $isHapticsEnabled) {
        Text(L10n.tr("ios.feedback.haptics"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)
      }
      .tint(Tokens.credit)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
  }

  private var widgetPrivacyCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(
        isOn: Binding(
          get: { hideWidgetAmounts },
          set: { newValue in
            hideWidgetAmounts = newValue
            ExtensionSharedStore.shared.writeWidgetHideAmounts(newValue)
            #if canImport(WidgetKit)
              WidgetCenter.shared.reloadAllTimelines()
            #endif
          }
        )
      ) {
        VStack(alignment: .leading, spacing: 2) {
          Text(L10n.tr("ios.widget.hideAmountsTitle"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
          Text(L10n.tr("ios.widget.hideAmountsSubtitle"))
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
      }
      .tint(Tokens.credit)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
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
      .tint(Tokens.credit)

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

  private func pushSettingsCard(_ user: User) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("ios.push.sectionTitle"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      switch model.pushStatus {
      case .notDetermined:
        Text(L10n.tr("ios.push.promptBody"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
        SPButton(
          L10n.tr("ios.push.enable"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: model.isOffline
        ) {
          Task { await model.enablePushNotifications() }
        }
      case .authorized:
        Text(L10n.tr("ios.push.enabledStatus"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
      case .denied:
        Text(L10n.tr("ios.push.deniedStatus"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          SPButton(
            L10n.tr("ios.push.openSettings"),
            variant: .surface,
            isFullWidth: true
          ) {
            UIApplication.shared.open(settingsURL)
          }
        }
      }

      Toggle(
        isOn: Binding(
          get: { user.hidePushContent },
          set: { newValue in
            Task { await model.setHidePushContent(newValue) }
          }
        )
      ) {
        Text(L10n.tr("ios.push.hideContent"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)
      }
      .tint(Tokens.credit)
      .disabled(model.isOffline || model.isSavingPushSettings)

      if let pushSettingsError = model.pushSettingsError {
        Text(pushSettingsError)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
  }

  private var notificationSettingsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("notifications.emailSettingsTitle"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      switch model.notificationSettings {
      case .loading:
        LoadingSkeleton(rowCount: 2, rowHeight: 40)
      case .failed:
        LoadError {
          Task { await model.load() }
        }
      case .loaded(let settings):
        Toggle(
          isOn: Binding(
            get: { settings.emailImmediate },
            set: { newValue in
              Task { await model.updateNotificationSettings(emailImmediate: newValue) }
            }
          )
        ) {
          Text(L10n.tr("notifications.emailImmediate"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.ink)
        }
        .tint(Tokens.credit)
        .disabled(model.isOffline || model.isUpdatingNotificationSettings)

        Toggle(
          isOn: Binding(
            get: { settings.emailDigest },
            set: { newValue in
              Task { await model.updateNotificationSettings(emailDigest: newValue) }
            }
          )
        ) {
          Text(L10n.tr("notifications.emailDigest"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.ink)
        }
        .tint(Tokens.credit)
        .disabled(model.isOffline || model.isUpdatingNotificationSettings)
      }

      if let error = model.notificationSettingsError {
        Text(error)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
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
