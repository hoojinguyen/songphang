import Accessibility
public import SwiftUI
import UIKit

public struct CopyButton: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isCopied = false
  @State private var feedbackTick = 0
  @State private var resetTask: Task<Void, Never>?

  private let value: String?
  private let label: String?
  private let customAccessibilityLabel: String?
  private let onCopyImage: (() -> UIImage?)?

  public init(
    value: String,
    label: String? = nil,
    accessibilityLabel: String? = nil
  ) {
    self.value = value
    self.label = label
    self.customAccessibilityLabel = accessibilityLabel
    self.onCopyImage = nil
  }

  public init(
    label: String? = nil,
    accessibilityLabel: String? = nil,
    onCopyImage: @escaping () -> UIImage?
  ) {
    self.value = nil
    self.label = label
    self.customAccessibilityLabel = accessibilityLabel
    self.onCopyImage = onCopyImage
  }

  public var body: some View {
    Button {
      copyToPasteboard()
    } label: {
      HStack(spacing: 6) {
        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
          .spIconFont(size: 15, weight: .bold, relativeTo: .subheadline)
          .contentTransition(
            Motion.isReduced(reduceMotion) ? .identity : .symbolEffect(.replace)
          )

        if let label {
          Text(isCopied ? L10n.tr("ios.copy.announced") : label)
            .font(Typography.captionBold)
            .lineLimit(1)
        }
      }
      .foregroundStyle(isCopied ? Tokens.credit : Tokens.ink)
      .padding(.horizontal, label == nil ? 10 : 12)
      .frame(minWidth: 44, minHeight: 44)
      .background(Tokens.sunken, in: Capsule())
    }
    .buttonStyle(.plain)
    .spAnimation(Motion.quick, value: isCopied)
    .spFeedback(.selection, trigger: feedbackTick)
    .accessibilityLabel(resolvedAccessibilityLabel)
    .onDisappear {
      resetTask?.cancel()
    }
  }

  private var resolvedAccessibilityLabel: String {
    if isCopied {
      return L10n.tr("ios.copy.announced")
    }
    if let customAccessibilityLabel {
      return customAccessibilityLabel
    }
    if let label {
      return label
    }
    return L10n.tr("pay.copy")
  }

  private func copyToPasteboard() {
    if let onCopyImage {
      guard let image = onCopyImage() else { return }
      UIPasteboard.general.image = image
    } else if let value {
      UIPasteboard.general.string = value
    } else {
      return
    }
    feedbackTick &+= 1
    AccessibilityNotification.Announcement(L10n.tr("ios.copy.announced")).post()

    resetTask?.cancel()
    Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
      isCopied = true
    }
    resetTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled else { return }
      Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
        isCopied = false
      }
    }
  }
}

#if DEBUG
  #Preview("CopyButton States") {
    HStack(spacing: 12) {
      CopyButton(value: "0123456789")
      CopyButton(value: "https://songphang.vn/j/abc", label: "Sao chép")
    }
    .padding(20)
    .background(Tokens.bg)
  }
#endif
