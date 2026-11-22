import DesignSystem
import SwiftUI

struct PushPermissionSheet: View {
  let onEnable: () -> Void
  let onLater: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Spacer(minLength: 8)

      Text(L10n.tr("ios.push.promptTitle"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)
        .fixedSize(horizontal: false, vertical: true)

      Text(L10n.tr("ios.push.promptBody"))
        .font(Typography.body)
        .foregroundStyle(Tokens.muted)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 12)

      VStack(spacing: 12) {
        SPButton(
          L10n.tr("ios.push.enable"),
          variant: .primary,
          size: .lg,
          isFullWidth: true,
          action: onEnable
        )
        SPButton(
          L10n.tr("ios.push.later"),
          variant: .surface,
          size: .lg,
          isFullWidth: true,
          action: onLater
        )
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Tokens.bg.ignoresSafeArea())
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
}
