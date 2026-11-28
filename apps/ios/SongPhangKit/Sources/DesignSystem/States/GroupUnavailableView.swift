public import SwiftUI

public struct GroupUnavailableView: View {
  public enum Kind: Sendable, Hashable {
    case notFound
    case forbidden
  }

  private let kind: Kind
  private let onBackToGroups: () -> Void

  public init(kind: Kind, onBackToGroups: @escaping () -> Void) {
    self.kind = kind
    self.onBackToGroups = onBackToGroups
  }

  public var body: some View {
    VStack(spacing: 20) {
      Spacer(minLength: 24)

      Image(systemName: kind == .notFound ? "questionmark.circle" : "lock.circle")
        .spIconFont(size: 48, weight: .bold, relativeTo: .largeTitle)
        .foregroundStyle(Tokens.muted)
        .accessibilityHidden(true)

      Text(kind == .notFound ? L10n.tr("common.groupNotFound") : L10n.tr("common.forbidden"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .multilineTextAlignment(.center)

      SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBackToGroups)

      Spacer(minLength: 24)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Tokens.bg.ignoresSafeArea())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#if DEBUG
  #Preview("Not Found") {
    NavigationStack {
      GroupUnavailableView(kind: .notFound, onBackToGroups: {})
    }
  }

  #Preview("Forbidden") {
    NavigationStack {
      GroupUnavailableView(kind: .forbidden, onBackToGroups: {})
    }
  }
#endif
