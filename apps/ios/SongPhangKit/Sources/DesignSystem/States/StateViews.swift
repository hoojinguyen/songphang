public import SwiftUI

public struct LoadingSkeleton: View {
  private let rowCount: Int
  private let rowHeight: CGFloat

  public init(rowCount: Int = 3, rowHeight: CGFloat = 72) {
    self.rowCount = rowCount
    self.rowHeight = rowHeight
  }

  public var body: some View {
    VStack(spacing: 12) {
      ForEach(0..<rowCount, id: \.self) { _ in
        VStack(alignment: .leading, spacing: 10) {
          SkeletonBar(width: 140, height: 14, cornerRadius: 7)
          SkeletonBar(height: 12, cornerRadius: 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .spSkeletonShimmer()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.tr("ios.common.loading"))
  }
}

public struct LoadError: View {
  private let message: String
  private let retryTitle: String
  private let isRetrying: Bool
  private let onRetry: () -> Void

  public init(
    message: String = L10n.tr("common.loadError"),
    retryTitle: String = L10n.tr("common.retry"),
    isRetrying: Bool = false,
    onRetry: @escaping () -> Void
  ) {
    self.message = message
    self.retryTitle = retryTitle
    self.isRetrying = isRetrying
    self.onRetry = onRetry
  }

  public var body: some View {
    VStack(spacing: 12) {
      Text(message)
        .font(Typography.body)
        .foregroundStyle(Tokens.ink)
        .multilineTextAlignment(.center)

      SPButton(
        retryTitle,
        variant: .primary,
        isDisabled: isRetrying,
        isPending: isRetrying,
        action: onRetry
      )
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
  }
}

public struct EmptyState<Leading: View, Action: View>: View {
  private let title: String
  private let subtitle: String?
  private let leading: Leading
  private let action: Action

  public init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder leading: () -> Leading,
    @ViewBuilder action: () -> Action
  ) {
    self.title = title
    self.subtitle = subtitle
    self.leading = leading()
    self.action = action()
  }

  public var body: some View {
    VStack(spacing: 16) {
      leading
      Text(title)
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)
        .multilineTextAlignment(.center)
      if let subtitle {
        Text(subtitle)
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
          .multilineTextAlignment(.center)
      }
      action
    }
    .frame(maxWidth: .infinity)
    .padding(24)
  }
}

extension EmptyState where Leading == EmptyView, Action == EmptyView {
  public init(title: String, subtitle: String? = nil, noActionReason: String) {
    _ = noActionReason
    self.init(
      title: title,
      subtitle: subtitle,
      leading: { EmptyView() },
      action: { EmptyView() }
    )
  }
}

extension EmptyState where Action == EmptyView {
  public init(
    title: String,
    subtitle: String? = nil,
    noActionReason: String,
    @ViewBuilder leading: () -> Leading
  ) {
    _ = noActionReason
    self.init(
      title: title,
      subtitle: subtitle,
      leading: leading,
      action: { EmptyView() }
    )
  }
}

extension EmptyState where Leading == EmptyView {
  public init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder action: () -> Action
  ) {
    self.init(
      title: title,
      subtitle: subtitle,
      leading: { EmptyView() },
      action: action
    )
  }
}

public struct OfflineBanner: View {
  private let sinceTimeText: String?

  public init(sinceTimeText: String? = nil) {
    self.sinceTimeText = sinceTimeText
  }

  public var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "wifi.slash")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Tokens.onInk)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(L10n.tr("offline.banner"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.onInk)
        if let sinceTimeText {
          Text(L10n.t("offline.since", ["time": sinceTimeText]))
            .font(Typography.caption)
            .foregroundStyle(Tokens.onInkMuted)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.ink)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
}
