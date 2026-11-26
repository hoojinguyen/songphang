import DesignSystem
import Domain
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

public struct GuestLinkSheetView: View {
  @Bindable private var model: GuestLinkSheetModel
  private let isOffline: Bool
  private let isArchived: Bool
  private let onDismiss: () -> Void

  @State private var copiedLink = false
  @State private var isConfirmingRevoke = false

  public init(
    model: GuestLinkSheetModel,
    isOffline: Bool = false,
    isArchived: Bool = false,
    onDismiss: @escaping () -> Void
  ) {
    self.model = model
    self.isOffline = isOffline
    self.isArchived = isArchived
    self.onDismiss = onDismiss
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          switch model.state {
          case .loading:
            LoadingSkeleton(rowCount: 2, rowHeight: 96)

          case .failed:
            LoadError {
              Task { await model.load() }
            }

          case .loaded(let link):
            content(link: link)
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("guestLink.fullTitle"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.tr("split.done"), action: onDismiss)
        }
      }
      .task {
        if model.state.value == nil {
          await model.load()
        }
      }
      .confirmationDialog(
        L10n.tr("guestLink.revokeAction"),
        isPresented: $isConfirmingRevoke,
        titleVisibility: .visible
      ) {
        Button(L10n.tr("guestLink.revokeAction"), role: .destructive) {
          copiedLink = false
          Task { await model.revoke() }
        }
      }
    }
  }

  @ViewBuilder
  private func content(link: GuestLink) -> some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("guestLink.readonlyBadge"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.onAccent)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Tokens.accent, in: Capsule())

        Text(L10n.tr("guestLink.description"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
      }
    }

    if let actionError = model.actionError {
      Text(actionError)
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.debt)
    }

    if link.active, let rawURL = link.url {
      VStack(alignment: .leading, spacing: 14) {
        Text(rawURL)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        HStack(spacing: 10) {
          SPButton(
            copiedLink ? L10n.tr("guestLink.copied") : L10n.tr("guestLink.copyAction"),
            variant: .primary,
            size: .md,
            isFullWidth: true
          ) {
            UIPasteboard.general.string = rawURL
            Haptics.light()
            copiedLink = true
          }

          if let shareURL = URL(string: rawURL) {
            ShareLink(item: shareURL) {
              Text(L10n.tr("invite.share"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 20)
                .frame(minHeight: Tokens.controlMediumHeight)
                .background(Tokens.surface, in: Capsule())
            }
            .buttonStyle(.plain)
          }
        }

        HStack(spacing: 10) {
          if !isArchived {
            SPButton(
              L10n.tr("guestLink.rotateAction"),
              variant: .surface,
              size: .md,
              isFullWidth: true,
              isOfflineBlocked: isOffline,
              isPending: model.isPerformingAction
            ) {
              copiedLink = false
              Task { await model.enableOrRotate(rotate: true) }
            }
          }

          SPButton(
            L10n.tr("guestLink.revokeAction"),
            variant: .surface,
            size: .md,
            isFullWidth: true,
            isOfflineBlocked: isOffline,
            isPending: model.isPerformingAction
          ) {
            isConfirmingRevoke = true
          }
        }
      }
      .padding(16)
      .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    } else if !isArchived {
      SPButton(
        L10n.tr("guestLink.enableAction"),
        variant: .accent,
        size: .lg,
        isFullWidth: true,
        isOfflineBlocked: isOffline,
        isPending: model.isPerformingAction
      ) {
        copiedLink = false
        Task { await model.enableOrRotate(rotate: false) }
      }
    } else {
      SPCard(padding: 16) {
        Text(L10n.tr("groups.archivedBanner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.muted)
      }
    }
  }
}

#if DEBUG
  #Preview("Guest Link Active") {
    let world = FakeWorld(preset: .tripStep4)
    GuestLinkSheetView(
      model: GuestLinkSheetModel(
        groupId: TripScenario.groupId,
        guestLinksRepository: FakeGuestLinksRepository(world: world)
      ),
      onDismiss: {}
    )
  }

  #Preview("Guest Link Inactive") {
    let world = FakeWorld(preset: .tripStep0)
    GuestLinkSheetView(
      model: GuestLinkSheetModel(
        groupId: TripScenario.groupId,
        guestLinksRepository: FakeGuestLinksRepository(world: world)
      ),
      onDismiss: {}
    )
  }
#endif
