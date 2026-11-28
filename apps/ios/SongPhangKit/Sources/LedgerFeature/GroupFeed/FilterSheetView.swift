import DesignSystem
import Domain
import SwiftUI

struct FilterSheetView: View {
  let members: [Member]
  let categories: [GroupCategory]
  let initialFilter: TransactionFilter
  let onApply: (TransactionFilter) -> Void
  let onClear: () -> Void
  let onDismiss: () -> Void

  @State private var memberId: Member.ID?
  @State private var builtinCategory: TransactionCategory?
  @State private var customCategoryId: GroupCategory.ID?
  @State private var uncategorized: Bool
  @State private var spendingOnly: Bool
  @State private var transactionType: TransactionType?
  @State private var hasFromDate: Bool
  @State private var fromDate: Date
  @State private var hasToDate: Bool
  @State private var toDate: Date

  init(
    members: [Member],
    categories: [GroupCategory],
    initialFilter: TransactionFilter,
    onApply: @escaping (TransactionFilter) -> Void,
    onClear: @escaping () -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.members = members
    self.categories = categories
    self.initialFilter = initialFilter
    self.onApply = onApply
    self.onClear = onClear
    self.onDismiss = onDismiss

    _memberId = State(initialValue: initialFilter.memberId)
    _builtinCategory = State(initialValue: initialFilter.category)
    _customCategoryId = State(initialValue: initialFilter.categoryId)
    _uncategorized = State(initialValue: initialFilter.uncategorized)
    _spendingOnly = State(initialValue: initialFilter.spendingOnly)
    _transactionType = State(initialValue: initialFilter.type)
    _hasFromDate = State(initialValue: initialFilter.from != nil)
    _fromDate = State(
      initialValue: FilterDateHelper.parseCalendarDate(initialFilter.from) ?? Date()
    )
    _hasToDate = State(initialValue: initialFilter.to != nil)
    _toDate = State(
      initialValue: FilterDateHelper.parseCalendarDate(initialFilter.to) ?? Date()
    )
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          memberSection()
          categorySection()
          typeSection()
          dateRangeSection()
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("filter.button"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          SheetCancelButton(action: onDismiss)
        }
      }
      .safeAreaInset(edge: .bottom) {
        HStack(spacing: 12) {
          SPButton(L10n.tr("filter.clear"), variant: .surface, isFullWidth: true) {
            onClear()
            onDismiss()
          }
          SPButton(L10n.tr("filter.apply"), variant: .primary, isFullWidth: true) {
            let fromStr = hasFromDate ? FilterDateHelper.formatCalendarDate(fromDate) : nil
            let toStr = hasToDate ? FilterDateHelper.formatCalendarDate(toDate) : nil
            let next = TransactionFilter(
              query: initialFilter.query,
              memberId: memberId,
              category: builtinCategory,
              categoryId: customCategoryId,
              uncategorized: uncategorized,
              spendingOnly: (transactionType == .transfer || transactionType != nil)
                ? false
                : spendingOnly,
              type: transactionType,
              from: fromStr,
              to: toStr,
              cycleId: initialFilter.cycleId
            )
            onApply(next)
            onDismiss()
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Tokens.bg)
      }
    }
    .spSheet(.half)
  }

  private func memberSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("filter.member"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      FlowPillWrap {
        ForEach(members) { member in
          let isSelected = (memberId == member.id)
          filterPill(title: member.name, dotColor: nil, isSelected: isSelected) {
            memberId = isSelected ? nil : member.id
          }
        }
      }
    }
  }

  private func categorySection() -> some View {
    let visibleCustom = categories.filter { !$0.archived || $0.id == customCategoryId }
    return VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("filter.category"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      FlowPillWrap {
        ForEach(TransactionCategory.allCases, id: \.self) { cat in
          let isSelected = (builtinCategory == cat && customCategoryId == nil && !uncategorized)
          filterPill(
            title: CategoryDisplay.localizedName(for: cat),
            dotColor: nil,
            isSelected: isSelected
          ) {
            builtinCategory = isSelected ? nil : cat
            customCategoryId = nil
            uncategorized = false
          }
        }

        ForEach(visibleCustom) { custom in
          let isSelected = (customCategoryId == custom.id)
          filterPill(
            title: CategoryDisplay.displayName(for: custom),
            dotColor: Tokens.color(for: custom.color),
            isSelected: isSelected
          ) {
            customCategoryId = isSelected ? nil : custom.id
            builtinCategory = nil
            uncategorized = false
          }
        }

        filterPill(
          title: L10n.tr("stats.uncategorised"),
          dotColor: nil,
          isSelected: uncategorized
        ) {
          uncategorized.toggle()
          if uncategorized {
            builtinCategory = nil
            customCategoryId = nil
          }
        }
      }
    }
  }

  private func typeSection() -> some View {
    let types: [(type: TransactionType, label: String)] = [
      (.expense, L10n.tr("expenseForm.typeExpense")),
      (.transfer, L10n.tr("expenseForm.typeTransfer")),
      (.income, L10n.tr("expenseForm.typeIncome")),
    ]
    return VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("filter.type"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      FlowPillWrap {
        ForEach(types, id: \.type.code) { item in
          let isSelected = (transactionType == item.type)
          filterPill(title: item.label, dotColor: nil, isSelected: isSelected) {
            transactionType = isSelected ? nil : item.type
            if transactionType != nil {
              spendingOnly = false
            }
          }
        }
      }
    }
  }

  private func dateRangeSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Toggle(isOn: $hasFromDate) {
          Text(L10n.tr("filter.fromDate"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
        }
        .tint(Tokens.credit)

        if hasFromDate {
          DatePicker(
            L10n.tr("filter.fromDate"),
            selection: $fromDate,
            displayedComponents: [.date]
          )
          .labelsHidden()
          .onChange(of: fromDate) { _, next in
            if hasToDate && toDate < next {
              toDate = next
            }
          }
        }
      }
      .padding(14)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

      VStack(alignment: .leading, spacing: 6) {
        Toggle(isOn: $hasToDate) {
          Text(L10n.tr("filter.toDate"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
        }
        .tint(Tokens.credit)

        if hasToDate {
          DatePicker(
            L10n.tr("filter.toDate"),
            selection: $toDate,
            in: (hasFromDate ? fromDate : Date.distantPast)...,
            displayedComponents: [.date]
          )
          .labelsHidden()
        }
      }
      .padding(14)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
  }

  private func filterPill(
    title: String,
    dotColor: Color?,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let dotColor {
          Circle().fill(dotColor).frame(width: 10, height: 10)
        }
        Text(title)
          .font(Typography.captionBold)
          .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
      }
      .padding(.horizontal, 14)
      .frame(minHeight: 44)
      .background(isSelected ? Tokens.ink : Tokens.surface, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct FlowPillWrap: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > 0 && x + size.width > maxWidth {
        x = 0
        y += rowHeight + spacing
        rowHeight = 0
      }
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }
    return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
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

private enum FilterDateHelper {
  private static var gregorian: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    return cal
  }

  static func formatCalendarDate(_ date: Date) -> String {
    let comps = gregorian.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
  }

  static func parseCalendarDate(_ raw: String?) -> Date? {
    guard let raw else { return nil }
    let parts = raw.split(separator: "-")
    guard parts.count == 3,
      let y = Int(parts[0]),
      let m = Int(parts[1]),
      let d = Int(parts[2])
    else { return nil }
    return gregorian.date(from: DateComponents(year: y, month: m, day: d))
  }
}
