import Accessibility
import Foundation
public import SwiftUI

public struct ToastMessage: Identifiable, Equatable, Sendable {
  public let id: UUID
  public let text: String
  public let actionLabel: String?
  public let action: (@MainActor @Sendable () -> Void)?
  public let autoDismissDelay: Duration?

  public init(
    id: UUID = UUID(),
    text: String,
    actionLabel: String? = nil,
    action: (@MainActor @Sendable () -> Void)? = nil,
    autoDismissDelay: Duration? = .seconds(3)
  ) {
    self.id = id
    self.text = text
    self.actionLabel = actionLabel
    self.action = action
    self.autoDismissDelay = autoDismissDelay
  }

  public static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
    lhs.id == rhs.id && lhs.text == rhs.text && lhs.actionLabel == rhs.actionLabel
      && lhs.autoDismissDelay == rhs.autoDismissDelay
  }
}

public struct ConfirmationToast: View {
  private let message: ToastMessage
  private let onDismiss: () -> Void

  public init(message: ToastMessage, onDismiss: @escaping () -> Void = {}) {
    self.message = message
    self.onDismiss = onDismiss
  }

  public var body: some View {
    HStack(spacing: 12) {
      Text(message.text)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.onInk)
        .frame(maxWidth: .infinity, alignment: .leading)

      if let actionLabel = message.actionLabel, let action = message.action {
        Button {
          action()
          onDismiss()
        } label: {
          Text(actionLabel)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.accent)
            .padding(.horizontal, 10)
            .frame(minHeight: 36)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .background(Tokens.ink, in: Capsule())
    .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 6)
    .accessibilityElement(children: .combine)
  }
}

private struct ConfirmationToastModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Binding var message: ToastMessage?
  let bottomPadding: CGFloat

  func body(content: Content) -> some View {
    let reduced = Motion.isReduced(reduceMotion)
    content
      .overlay(alignment: .bottom) {
        if let current = message {
          ConfirmationToast(message: current) {
            dismissToast()
          }
          .padding(.horizontal, 20)
          .padding(.bottom, bottomPadding)
          .transition(
            reduced
              ? .opacity
              : .move(edge: .bottom).combined(with: .opacity)
          )
          .task(id: current.id) {
            let announcement =
              current.actionLabel.map { "\(current.text). \($0)" } ?? current.text
            AccessibilityNotification.Announcement(announcement).post()
            if let delay = current.autoDismissDelay {
              try? await Task.sleep(for: delay)
              guard !Task.isCancelled, message?.id == current.id else { return }
              dismissToast()
            }
          }
        }
      }
      .spAnimation(Motion.smooth, value: message)
  }

  private func dismissToast() {
    Motion.withAnimation(Motion.smooth, reduceMotion: reduceMotion) {
      message = nil
    }
  }
}

extension View {
  public func confirmationToast(
    _ message: Binding<ToastMessage?>,
    bottomPadding: CGFloat = 12
  ) -> some View {
    modifier(ConfirmationToastModifier(message: message, bottomPadding: bottomPadding))
  }
}

#if DEBUG
  #Preview("ConfirmationToast") {
    VStack {
      Spacer()
      ConfirmationToast(
        message: ToastMessage(text: "Đã tạo Đà Lạt 2", actionLabel: "Hoàn tác", action: {})
      )
      .padding(20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Tokens.bg)
  }
#endif
