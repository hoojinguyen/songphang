public import SwiftUI

public struct SPCard<Content: View>: View {
  public enum Tone: Sendable {
    case surface
    case accent
    case sunken
  }

  private let tone: Tone
  private let padding: CGFloat
  private let content: Content

  public init(
    tone: Tone = .surface,
    padding: CGFloat = 24,
    @ViewBuilder content: () -> Content
  ) {
    self.tone = tone
    self.padding = padding
    self.content = content()
  }

  public var body: some View {
    content
      .foregroundStyle(tone == .accent ? Tokens.onAccent : Tokens.ink)
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: Tokens.radiusCard, style: .continuous))
  }

  private var backgroundColor: Color {
    switch tone {
    case .surface:
      return Tokens.surface
    case .accent:
      return Tokens.accent
    case .sunken:
      return Tokens.sunken
    }
  }
}
