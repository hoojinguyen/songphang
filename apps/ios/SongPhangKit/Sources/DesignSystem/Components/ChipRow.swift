public import SwiftUI

public struct ChipRow<Data: RandomAccessCollection, ChipContent: View>: View
where Data.Element: Identifiable {
  private let items: Data
  private let spacing: CGFloat
  private let chipContent: (Data.Element) -> ChipContent

  @State private var containerWidth: CGFloat = 0
  @State private var chipWidths: [AnyHashable: CGFloat] = [:]

  public init(
    _ items: Data,
    spacing: CGFloat = 8,
    @ViewBuilder chipContent: @escaping (Data.Element) -> ChipContent
  ) {
    self.items = items
    self.spacing = spacing
    self.chipContent = chipContent
  }

  private var needsHorizontalScroll: Bool {
    if items.count > 4 {
      return true
    }
    guard containerWidth > 0 else { return false }
    let widestChip = items.compactMap { chipWidths[AnyHashable($0.id)] }.max() ?? 0
    return widestChip > containerWidth
  }

  public var body: some View {
    Group {
      if !needsHorizontalScroll {
        ChipWrapLayout(spacing: spacing) {
          ForEach(items) { item in
            chipContent(item)
              .fixedSize(horizontal: true, vertical: false)
              .onGeometryChange(for: CGFloat.self) { proxy in
                ceil(proxy.size.width)
              } action: { chipWidth in
                let key = AnyHashable(item.id)
                if chipWidths[key] != chipWidth {
                  chipWidths[key] = chipWidth
                }
              }
          }
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          PeekingChipHStackLayout(containerWidth: containerWidth, spacing: spacing) {
            ForEach(items) { item in
              chipContent(item)
                .fixedSize(horizontal: true, vertical: false)
                .onGeometryChange(for: CGFloat.self) { proxy in
                  ceil(proxy.size.width)
                } action: { chipWidth in
                  let key = AnyHashable(item.id)
                  if chipWidths[key] != chipWidth {
                    chipWidths[key] = chipWidth
                  }
                }
            }
          }
        }
      }
    }
    .onGeometryChange(for: CGFloat.self) { proxy in
      floor(proxy.size.width)
    } action: { next in
      if abs(next - containerWidth) >= 1 {
        containerWidth = next
      }
    }
  }
}

public struct SPChipItem: Identifiable, Hashable, Sendable {
  public let id: String
  public let label: String

  public init(id: String, label: String) {
    self.id = id
    self.label = label
  }
}

public struct SPChipButton: View {
  private let label: String
  private let isSelected: Bool
  private let isDisabled: Bool
  private let action: () -> Void

  public init(
    _ label: String,
    isSelected: Bool,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.label = label
    self.isSelected = isSelected
    self.isDisabled = isDisabled
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      Text(label)
        .font(Typography.captionBold)
        .foregroundStyle(isSelected ? Tokens.onInk : Tokens.ink)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 14)
        .frame(minHeight: 40)
        .background(isSelected ? Tokens.ink : Tokens.surface, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct ChipWrapLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0
    var usedWidth: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > 0 && x + size.width > maxWidth {
        x = 0
        y += rowHeight + spacing
        rowHeight = 0
      }
      usedWidth = max(usedWidth, x + size.width)
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }
    return CGSize(width: maxWidth.isFinite ? maxWidth : usedWidth, height: y + rowHeight)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var x = bounds.minX
    var y = bounds.minY
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > bounds.minX && x + size.width > bounds.maxX {
        x = bounds.minX
        y += rowHeight + spacing
        rowHeight = 0
      }
      subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }
  }
}

// Sizes/spaces chips >= natural width so when horizontal scrolling is needed,
// the chip crossing the right edge shows roughly half its width (never 0% or truncated).
private struct PeekingChipHStackLayout: Layout {
  let containerWidth: CGFloat
  let spacing: CGFloat

  private func computePlacements(subviews: Subviews) -> (
    origins: [CGFloat], sizes: [CGSize], totalWidth: CGFloat, maxHeight: CGFloat
  ) {
    let naturalSizes = subviews.map { $0.sizeThatFits(.unspecified) }
    let maxHeight = naturalSizes.map(\.height).max() ?? 0
    guard !naturalSizes.isEmpty else {
      return ([], [], 0, 0)
    }

    let naturalTotal =
      naturalSizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, naturalSizes.count - 1)) * spacing

    var effectiveSpacing = spacing
    if containerWidth > 80 && naturalTotal > containerWidth {
      var x: CGFloat = 0
      var peekIndex: Int?
      for (index, size) in naturalSizes.enumerated() {
        let end = x + size.width
        if end > containerWidth {
          peekIndex = index
          break
        }
        x = end + spacing
      }
      if let p = peekIndex, p > 0 {
        let peekWidth = naturalSizes[p].width
        let visible = containerWidth - x
        let ratio = peekWidth > 0 ? (visible / peekWidth) : 0.5
        if ratio < 0.35 || ratio > 0.68 {
          // Shift chip p's origin so 50% of chip p sits inside containerWidth without shrinking chips.
          let targetOrigin: CGFloat
          if ratio > 0.68 {
            targetOrigin = containerWidth - 0.5 * peekWidth
          } else if p > 1 {
            // Pull the previous chip p-1 to be the half-visible chip by widening gaps slightly.
            let prevWidth = naturalSizes[p - 1].width
            let desiredPrevOrigin = containerWidth - 0.5 * prevWidth
            let precedingWidths = naturalSizes[0..<(p - 1)].reduce(0) { $0 + $1.width }
            let extra = max(0, desiredPrevOrigin - precedingWidths) / CGFloat(p - 1)
            effectiveSpacing = max(spacing, extra)
            targetOrigin = -1
          } else {
            targetOrigin = -1
          }
          if targetOrigin > x {
            let precedingWidths = naturalSizes[0..<p].reduce(0) { $0 + $1.width }
            effectiveSpacing = max(spacing, (targetOrigin - precedingWidths) / CGFloat(p))
          }
        }
      }
    }

    var origins: [CGFloat] = []
    var cursor: CGFloat = 0
    for (idx, size) in naturalSizes.enumerated() {
      origins.append(cursor)
      cursor += size.width
      if idx < naturalSizes.count - 1 {
        cursor += effectiveSpacing
      }
    }
    return (origins, naturalSizes, cursor, maxHeight)
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = computePlacements(subviews: subviews)
    return CGSize(width: result.totalWidth, height: result.maxHeight)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let result = computePlacements(subviews: subviews)
    for (index, subview) in subviews.enumerated() {
      let size = result.sizes[index]
      let y = bounds.minY + (result.maxHeight - size.height) * 0.5
      subview.place(
        at: CGPoint(x: bounds.minX + result.origins[index], y: y),
        proposal: ProposedViewSize(size)
      )
    }
  }
}

#if DEBUG
  #Preview("ChipRow Wrap (<= 4)") {
    let items = [
      SPChipItem(id: "1", label: "Hằng tuần"),
      SPChipItem(id: "2", label: "Hằng tháng"),
      SPChipItem(id: "3", label: "Hằng quý"),
      SPChipItem(id: "4", label: "Hằng năm"),
    ]
    ChipRow(items) { item in
      SPChipButton(item.label, isSelected: item.id == "2") {}
    }
    .padding(20)
    .background(Tokens.bg)
  }

  #Preview("ChipRow Peek (> 4)") {
    let items = [
      SPChipItem(id: "1", label: "Ăn uống"),
      SPChipItem(id: "2", label: "Đi lại"),
      SPChipItem(id: "3", label: "Chỗ ở"),
      SPChipItem(id: "4", label: "Mua sắm"),
      SPChipItem(id: "5", label: "Giải trí"),
      SPChipItem(id: "6", label: "Hoá đơn"),
    ]
    ChipRow(items) { item in
      SPChipButton(item.label, isSelected: item.id == "1") {}
    }
    .padding(20)
    .background(Tokens.bg)
  }

  #Preview("ChipRow AX5 Dark") {
    let items = [
      SPChipItem(id: "1", label: "Tất cả"),
      SPChipItem(id: "2", label: "Chờ xác nhận"),
      SPChipItem(id: "3", label: "Đã xác nhận"),
      SPChipItem(id: "4", label: "Có chứng từ"),
      SPChipItem(id: "5", label: "Đợt 1"),
    ]
    ChipRow(items) { item in
      SPChipButton(item.label, isSelected: item.id == "2") {}
    }
    .padding(20)
    .background(Tokens.bg)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility5)
  }
#endif
