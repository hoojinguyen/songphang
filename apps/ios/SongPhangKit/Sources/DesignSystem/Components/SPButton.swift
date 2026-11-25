public import SwiftUI

public struct SPButton: View {
  public enum Variant: Sendable {
    case primary
    case accent
    case surface
  }

  public enum Size: Sendable {
    case md
    case lg
  }

  private let title: String
  private let variant: Variant
  private let size: Size
  private let isFullWidth: Bool
  private let isDisabled: Bool
  private let isOfflineBlocked: Bool
  private let isPending: Bool
  private let action: () -> Void

  public init(
    _ title: String,
    variant: Variant = .primary,
    size: Size = .md,
    isFullWidth: Bool = false,
    isDisabled: Bool = false,
    isOfflineBlocked: Bool = false,
    isPending: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.variant = variant
    self.size = size
    self.isFullWidth = isFullWidth
    self.isDisabled = isDisabled
    self.isOfflineBlocked = isOfflineBlocked
    self.isPending = isPending
    self.action = action
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Button(action: action) {
        HStack(spacing: 8) {
          if isPending {
            ProgressView()
              .tint(effectiveForegroundColor)
          }
          Text(title)
            .font(Typography.bodyBold)
            .foregroundStyle(effectiveForegroundColor)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .frame(minWidth: 44, minHeight: controlHeight)
        .background(effectiveBackgroundColor)
        .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .disabled(isDisabled || isOfflineBlocked || isPending)

      if isOfflineBlocked {
        Text(L10n.tr("offline.writeDisabled"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
    }
  }

  private var controlHeight: CGFloat {
    switch size {
    case .md:
      return Tokens.controlMediumHeight
    case .lg:
      return Tokens.controlLargeHeight
    }
  }

  private var isInactive: Bool {
    isDisabled || isOfflineBlocked || isPending
  }

  private var effectiveBackgroundColor: Color {
    if isInactive {
      return Tokens.sunken
    }
    switch variant {
    case .primary:
      return Tokens.ink
    case .accent:
      return Tokens.accent
    case .surface:
      return Tokens.surface
    }
  }

  private var effectiveForegroundColor: Color {
    if isInactive {
      return Tokens.muted
    }
    switch variant {
    case .primary:
      return Tokens.onInk
    case .accent:
      return Tokens.onAccent
    case .surface:
      return Tokens.ink
    }
  }
}
