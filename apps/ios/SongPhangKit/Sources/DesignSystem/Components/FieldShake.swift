public import SwiftUI

private struct FieldShakeModifier<Trigger: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let trigger: Trigger
  let cornerRadius: CGFloat

  @State private var horizontalOffset: CGFloat = 0
  @State private var showsErrorOutline = false
  @State private var shakeTask: Task<Void, Never>?

  func body(content: Content) -> some View {
    content
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(showsErrorOutline ? Tokens.debt : Color.clear, lineWidth: 2)
          .allowsHitTesting(false)
      )
      .offset(x: horizontalOffset)
      .spFeedback(.warning, trigger: trigger)
      .onChange(of: trigger) { _, _ in
        runShake()
      }
      .onDisappear {
        shakeTask?.cancel()
      }
  }

  private func runShake() {
    shakeTask?.cancel()
    let reduced = Motion.isReduced(reduceMotion)
    if reduced {
      horizontalOffset = 0
      showsErrorOutline = true
      shakeTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(1200))
        guard !Task.isCancelled else { return }
        showsErrorOutline = false
      }
      return
    }

    showsErrorOutline = true
    shakeTask = Task { @MainActor in
      let offsets: [CGFloat] = [-9, 9, -6, 6, 0]
      for step in offsets {
        guard !Task.isCancelled else { return }
        Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
          horizontalOffset = step
        }
        try? await Task.sleep(for: .milliseconds(65))
      }
      try? await Task.sleep(for: .milliseconds(700))
      guard !Task.isCancelled else { return }
      Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
        showsErrorOutline = false
      }
    }
  }
}

extension View {
  public func fieldShake<Trigger: Equatable>(
    trigger: Trigger,
    cornerRadius: CGFloat = 22
  ) -> some View {
    modifier(FieldShakeModifier(trigger: trigger, cornerRadius: cornerRadius))
  }
}

#if DEBUG
  #Preview("FieldShake") {
    @Previewable @State var tick = 0
    VStack(spacing: 16) {
      Text("0 đ")
        .font(Typography.displayNumber)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .fieldShake(trigger: tick)
      SPButton("Lắc ô nhập", variant: .primary) {
        tick &+= 1
      }
    }
    .padding(20)
    .background(Tokens.bg)
  }
#endif
