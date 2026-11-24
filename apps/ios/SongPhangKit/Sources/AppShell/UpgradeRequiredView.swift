import DesignSystem
import Domain
import Foundation
public import SwiftUI

public struct UpgradeRequiredView: View {
  private let appStoreURL: URL?
  @Environment(\.openURL) private var openURL

  public init(appStoreURL: URL?) {
    self.appStoreURL = appStoreURL
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Spacer(minLength: 24)

      LoginShapesView()

      Text(L10n.tr("ios.upgrade.body"))
        .font(Typography.pageTitle)
        .foregroundStyle(Tokens.ink)
        .fixedSize(horizontal: false, vertical: true)

      SPButton(
        L10n.tr("ios.upgrade.openAppStore"),
        variant: .primary,
        size: .lg,
        isFullWidth: true,
        isDisabled: appStoreURL == nil
      ) {
        if let appStoreURL {
          openURL(appStoreURL)
        }
      }

      Spacer(minLength: 24)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 32)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Tokens.bg.ignoresSafeArea())
  }
}

#if DEBUG
  #Preview("Upgrade Required (No Store URL)") {
    UpgradeRequiredView(appStoreURL: nil)
  }

  #Preview("Upgrade Required (Configured Store URL)") {
    UpgradeRequiredView(appStoreURL: URL(string: "https://apps.apple.com/app/id0000000000"))
  }
#endif
