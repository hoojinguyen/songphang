import Domain
public import SwiftUI

public struct LoginShapesView: View {
  public init() {}

  public var body: some View {
    ZStack(alignment: .topLeading) {
      MemberShapeView(
        shape: .circle,
        color: .mint,
        name: L10n.tr("showcase.members.minh"),
        size: 112
      )
      .offset(x: 6, y: 24)

      MemberShapeView(
        shape: .diamond,
        color: .sky,
        name: L10n.tr("showcase.members.lan"),
        size: 100
      )
      .offset(x: 104, y: 0)

      MemberShapeView(
        shape: .squircle,
        color: .coral,
        name: L10n.tr("showcase.members.hung"),
        size: 88
      )
      .offset(x: 136, y: 100)

      MemberShapeView(
        shape: .leaf,
        color: .lilac,
        name: L10n.tr("showcase.members.thu"),
        size: 74
      )
      .offset(x: 44, y: 140)
    }
    .frame(width: 260, height: 220, alignment: .topLeading)
    .frame(maxWidth: .infinity)
    .accessibilityHidden(true)
  }
}

public struct SPScreenHeader<Trailing: View>: View {
  public enum BackIcon: Sendable {
    case back
    case close
  }

  private let title: String
  private let subtitle: String?
  private let backLabel: String
  private let backIcon: BackIcon
  private let onBack: (() -> Void)?
  private let trailing: Trailing
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  public init(
    title: String,
    subtitle: String? = nil,
    backLabel: String = L10n.tr("common.back"),
    backIcon: BackIcon = .back,
    onBack: (() -> Void)? = nil,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.subtitle = subtitle
    self.backLabel = backLabel
    self.backIcon = backIcon
    self.onBack = onBack
    self.trailing = trailing()
  }

  public var body: some View {
    // At accessibility sizes the title needs the full width, so the parts stack.
    let layout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
      : AnyLayout(HStackLayout(spacing: 12))
    layout {
      if let onBack {
        Button(action: onBack) {
          Image(systemName: backIcon == .back ? "chevron.left" : "xmark")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Tokens.ink)
            .frame(width: 48, height: 48)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(backLabel)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(Typography.screenHeaderTitle)
          .foregroundStyle(Tokens.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        if let subtitle {
          Text(subtitle)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      trailing
    }
  }
}

extension SPScreenHeader where Trailing == EmptyView {
  public init(
    title: String,
    subtitle: String? = nil,
    backLabel: String = L10n.tr("common.back"),
    backIcon: BackIcon = .back,
    onBack: (() -> Void)? = nil
  ) {
    self.init(
      title: title,
      subtitle: subtitle,
      backLabel: backLabel,
      backIcon: backIcon,
      onBack: onBack,
      trailing: { EmptyView() }
    )
  }
}
