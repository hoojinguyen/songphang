import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct NotificationsView: View {
  @Bindable private var model: NotificationsModel
  @State private var isNavigatingToTarget = false
  private let onBack: (() -> Void)?
  private let onUnreadSynced: (() -> Void)?
  private let onSelectTarget: (AppNotification.Target) -> Void

  public init(
    model: NotificationsModel,
    onBack: (() -> Void)? = nil,
    onUnreadSynced: (() -> Void)? = nil,
    onSelectTarget: @escaping (AppNotification.Target) -> Void
  ) {
    self.model = model
    self.onBack = onBack
    self.onUnreadSynced = onUnreadSynced
    self.onSelectTarget = onSelectTarget
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if model.markError != nil {
          Text(L10n.tr("common.saveError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 4)
        }

        switch model.state {
        case .loading:
          LoadingSkeleton(rowCount: 4, rowHeight: 80)

        case .failed:
          LoadError {
            Task { await model.load() }
          }

        case .loaded(let data):
          if data.notifications.isEmpty {
            VStack(spacing: 12) {
              Text(L10n.tr("notifications.empty"))
                .font(Typography.body)
                .foregroundStyle(Tokens.muted)
                .padding(.vertical, 48)
            }
            .frame(maxWidth: .infinity)
          } else {
            LazyVStack(spacing: 8) {
              ForEach(data.notifications) { item in
                NotificationRowView(
                  notification: item,
                  onSelect: { notification in
                    isNavigatingToTarget = true
                    model.markOneRead(notification) {
                      onUnreadSynced?()
                    }
                    onSelectTarget(notification.target)
                  }
                )
              }
            }

            if model.nextPageError != nil {
              VStack(spacing: 8) {
                Text(L10n.tr("common.loadError"))
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
                Button(action: {
                  Task { await model.fetchNextPage() }
                }) {
                  Text(L10n.tr("common.retry"))
                    .font(Typography.captionBold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Tokens.surface)
                    .foregroundStyle(Tokens.ink)
                    .clipShape(Capsule())
                }
              }
              .frame(maxWidth: .infinity)
              .padding(.top, 8)
            } else if data.nextCursor != nil {
              Button(action: {
                Task { await model.fetchNextPage() }
              }) {
                HStack(spacing: 8) {
                  if model.isFetchingNextPage {
                    ProgressView()
                  }
                  Text(L10n.tr("notifications.loadMore"))
                    .font(Typography.bodyBold)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Tokens.surface)
                .foregroundStyle(Tokens.ink)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
              }
              .disabled(model.isFetchingNextPage)
              .padding(.top, 8)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationTitle(L10n.tr("notifications.title"))
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      if model.hasUnread {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await model.markAllRead() }
          } label: {
            Text(L10n.tr("notifications.markAll"))
              .font(Typography.captionBold)
          }
          .disabled(model.isMarkingAll)
        }
      }
    }
    .onAppear {
      isNavigatingToTarget = false
    }
    .task {
      await model.load()
    }
    .onDisappear {
      if !isNavigatingToTarget {
        onBack?()
      }
    }
  }
}

#if DEBUG
  #Preview("NotificationsView - Loaded") {
    let world = FakeWorld()
    let repo = FakeNotificationsRepository(world: world)
    let model = NotificationsModel(repository: repo)
    NotificationsView(
      model: model,
      onBack: {},
      onSelectTarget: { _ in }
    )
  }
#endif
