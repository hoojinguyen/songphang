import DesignSystem
public import Domain
public import SwiftUI

public struct HighlightedSentenceView: View {
  private let text: String
  private let spans: [QuickEntryReading.Span]

  public init(text: String, spans: [QuickEntryReading.Span]) {
    self.text = text
    self.spans = spans
  }

  public var body: some View {
    let segments = buildSegments()
    FlowSentenceLayout(spacing: 0) {
      ForEach(segments) { segment in
        if let color = segment.backgroundColor {
          Text(segment.text)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(segment.accessibilityLabel ?? segment.text)
        } else {
          Text(segment.text)
            .font(Typography.body)
            .foregroundStyle(Tokens.ink)
        }
      }
    }
  }

  private struct Segment: Identifiable {
    let id: Int
    let text: String
    let backgroundColor: Color?
    let accessibilityLabel: String?
  }

  private func buildSegments() -> [Segment] {
    let chars = Array(text)
    guard !chars.isEmpty else { return [] }
    var cursor = 0
    var result: [Segment] = []
    var nextId = 0

    let sortedSpans = spans.sorted { $0.start < $1.start }
    for span in sortedSpans {
      guard span.start >= cursor, span.end <= chars.count, span.start < span.end else {
        continue
      }
      if span.start > cursor {
        let gapText = String(chars[cursor..<span.start])
        result.append(
          Segment(id: nextId, text: gapText, backgroundColor: nil, accessibilityLabel: nil)
        )
        nextId += 1
      }
      let spanText = String(chars[span.start..<span.end])
      let bg = color(for: span.kind)
      let labelPrefix = kindLabel(for: span.kind)
      let a11y = labelPrefix.map { "\($0): \(spanText)" }
      result.append(
        Segment(id: nextId, text: spanText, backgroundColor: bg, accessibilityLabel: a11y)
      )
      nextId += 1
      cursor = span.end
    }

    if cursor < chars.count {
      let tail = String(chars[cursor..<chars.count])
      result.append(
        Segment(id: nextId, text: tail, backgroundColor: nil, accessibilityLabel: nil)
      )
    }
    return result
  }

  private func color(for kind: QuickEntryReading.SpanKind) -> Color? {
    switch kind {
    case .amount: return Tokens.phraseAmount
    case .payer: return Tokens.phrasePayer
    case .equal, .exact: return Tokens.phraseSplit
    case .remainder: return Tokens.phraseRest
    case .description, .unknown: return nil
    }
  }

  private func kindLabel(for kind: QuickEntryReading.SpanKind) -> String? {
    switch kind {
    case .amount: return L10n.tr("compose.kindAmount")
    case .payer: return L10n.tr("compose.kindPayer")
    case .equal, .exact: return L10n.tr("compose.kindSplit")
    case .remainder: return L10n.tr("compose.kindRest")
    case .description, .unknown: return nil
    }
  }
}

private struct FlowSentenceLayout: Layout {
  var spacing: CGFloat = 0

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ()
  ) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0
    var maxUsedWidth: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > 0 && x + size.width > maxWidth {
        x = 0
        y += rowHeight + 4
        rowHeight = 0
      }
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
      maxUsedWidth = max(maxUsedWidth, x)
    }
    return CGSize(width: min(maxUsedWidth, maxWidth), height: y + rowHeight)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal _: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ()
  ) {
    var x = bounds.minX
    var y = bounds.minY
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > bounds.minX && x + size.width > bounds.maxX {
        x = bounds.minX
        y += rowHeight + 4
        rowHeight = 0
      }
      subview.place(
        at: CGPoint(x: x, y: y),
        anchor: .topLeading,
        proposal: ProposedViewSize(size)
      )
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }
  }
}
