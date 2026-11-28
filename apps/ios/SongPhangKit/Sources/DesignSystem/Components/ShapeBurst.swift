public import Domain
public import SwiftUI

public struct ShapeBurst: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var stage: BurstStage = .compact

  private let members: [Member]
  private let trigger: Int
  private let shapeSize: CGFloat

  private enum BurstStage: Equatable {
    case compact
    case expanded
    case settled
  }

  public init(members: [Member], trigger: Int = 0, shapeSize: CGFloat = 36) {
    self.members = Array(members.prefix(6))
    self.trigger = trigger
    self.shapeSize = shapeSize
  }

  public var body: some View {
    let reduced = Motion.isReduced(reduceMotion)
    ZStack {
      ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
        let vector = offset(for: index, total: members.count, stage: reduced ? .settled : stage)
        MemberShapeView(member: member, size: shapeSize)
          .offset(x: vector.width, y: vector.height)
          .scaleEffect(scale(for: reduced ? .settled : stage))
      }
    }
    .frame(height: shapeSize * 2.2)
    .frame(maxWidth: .infinity)
    .accessibilityHidden(true)
    .task(id: trigger) {
      guard !Motion.isReduced(reduceMotion) else {
        stage = .settled
        return
      }
      stage = .compact
      Motion.withAnimation(Motion.bounce, reduceMotion: reduceMotion) {
        stage = .expanded
      }
      try? await Task.sleep(for: .milliseconds(450))
      guard !Task.isCancelled else { return }
      Motion.withAnimation(Motion.smooth, reduceMotion: reduceMotion) {
        stage = .settled
      }
    }
  }

  private func scale(for current: BurstStage) -> CGFloat {
    switch current {
    case .compact:
      return 0.55
    case .expanded:
      return 1.12
    case .settled:
      return 1.0
    }
  }

  private func offset(for index: Int, total: Int, stage: BurstStage) -> CGSize {
    guard total > 1 else {
      let y: CGFloat = stage == .expanded ? -16 : 0
      return CGSize(width: 0, height: y)
    }
    let center = CGFloat(total - 1) / 2.0
    let relative = CGFloat(index) - center
    let arch = abs(relative) * 4 - 8
    switch stage {
    case .compact:
      return CGSize(width: relative * 10, height: 10)
    case .expanded:
      return CGSize(width: relative * (shapeSize + 14), height: arch - 14)
    case .settled:
      return CGSize(width: relative * (shapeSize + 6), height: arch * 0.5)
    }
  }
}

#if DEBUG
  #Preview("ShapeBurst") {
    let samples = [
      Member(
        id: Member.ID("m1"), name: "Minh", position: 0, shape: .circle, color: .mint,
        isMe: true, claimed: true
      ),
      Member(
        id: Member.ID("m2"), name: "Lan", position: 1, shape: .diamond, color: .sky,
        isMe: false, claimed: true
      ),
      Member(
        id: Member.ID("m3"), name: "Hùng", position: 2, shape: .squircle, color: .coral,
        isMe: false, claimed: false
      ),
      Member(
        id: Member.ID("m4"), name: "Thu", position: 3, shape: .leaf, color: .lilac,
        isMe: false, claimed: true
      ),
    ]
    ShapeBurst(members: samples)
      .padding(24)
      .background(Tokens.bg)
  }
#endif
