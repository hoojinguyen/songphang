import DesignSystem
public import Domain
public import Foundation
public import SwiftUI

public struct EditableManualExtra: Sendable, Equatable, Identifiable {
  public enum InputMode: String, Sendable, Hashable, CaseIterable {
    case percent
    case amount
  }

  public let id: UUID
  public var kind: ReceiptExtraKind
  public var label: String
  public var mode: InputMode
  public var percentText: String
  public var amountText: String

  public init(
    id: UUID = UUID(),
    kind: ReceiptExtraKind,
    label: String,
    mode: InputMode,
    percentText: String = "",
    amountText: String = ""
  ) {
    self.id = id
    self.kind = kind
    self.label = label
    self.mode = mode
    self.percentText = percentText
    self.amountText = amountText
  }

  public static let maxExtras = 6

  public static func isValidRatePercent(_ raw: String) -> Bool {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.range(of: #"^\d{1,2}(\.\d{1,2})?$"#, options: .regularExpression) != nil else {
      return false
    }
    let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
    let whole = Int(parts[0]) ?? 0
    let fracStr =
      parts.count > 1 ? String(parts[1]).padding(toLength: 2, withPad: "0", startingAt: 0) : "00"
    let frac = Int(fracStr) ?? 0
    return (whole * 100 + frac) >= 1
  }

  public func toPreviewItem() -> PreviewExtrasItem? {
    let trimmedLabel = String(label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
    let resolvedLabel = trimmedLabel.isEmpty ? kind.localizedTitle : trimmedLabel
    switch mode {
    case .percent:
      let normalized =
        percentText
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: ".")
      guard Self.isValidRatePercent(normalized) else { return nil }
      return PreviewExtrasItem(kind: kind, label: resolvedLabel, ratePercent: normalized)
    case .amount:
      let digits = amountText.filter { $0.isWholeNumber && $0.isASCII }
      guard !digits.isEmpty, let money = MoneyFormat.parseInput(digits) else { return nil }
      return PreviewExtrasItem(kind: kind, label: resolvedLabel, amount: money)
    }
  }
}

public struct ManualExtrasCardView: View {
  @Binding private var extras: [EditableManualExtra]
  @Binding private var allocation: ExtrasAllocation
  private let baseAmount: Money
  private let preview: PreviewExtrasResult?
  private let isPreviewCurrent: Bool
  private let previewError: AppError?
  private let onChange: () -> Void

  public init(
    extras: Binding<[EditableManualExtra]>,
    allocation: Binding<ExtrasAllocation>,
    baseAmount: Money,
    preview: PreviewExtrasResult?,
    isPreviewCurrent: Bool,
    previewError: AppError?,
    onChange: @escaping () -> Void
  ) {
    self._extras = extras
    self._allocation = allocation
    self.baseAmount = baseAmount
    self.preview = preview
    self.isPreviewCurrent = isPreviewCurrent
    self.previewError = previewError
    self.onChange = onChange
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("extras.cardTitle"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      quickChipsRow

      if extras.count >= EditableManualExtra.maxExtras {
        Text(L10n.tr("extras.maxExtras"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }

      if !extras.isEmpty {
        ForEach(Array(extras.enumerated()), id: \.element.id) { index, _ in
          extraRow(at: index)
        }

        allocationPicker

        Divider().overlay(Tokens.borderSubtle)

        totalsFooter
      }
    }
    .padding(14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func supportsPercent(_ kind: ReceiptExtraKind) -> Bool {
    kind == .tax || kind == .service || kind == .discount
  }

  private var quickChipsRow: some View {
    let presets: [(String, ReceiptExtraKind, String, EditableManualExtra.InputMode, String)] = [
      (L10n.tr("extras.chipVat8"), .tax, L10n.tr("extras.kindTax"), .percent, "8"),
      (L10n.tr("extras.chipVat10"), .tax, L10n.tr("extras.kindTax"), .percent, "10"),
      (L10n.tr("extras.chipService5"), .service, L10n.tr("extras.kindService"), .percent, "5"),
      (L10n.tr("extras.chipShipping"), .shipping, L10n.tr("extras.kindShipping"), .amount, ""),
      (L10n.tr("extras.chipDiscount"), .discount, L10n.tr("extras.kindDiscount"), .amount, ""),
      (L10n.tr("extras.chipOther"), .other, L10n.tr("extras.kindOther"), .amount, ""),
    ]
    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(Array(presets.enumerated()), id: \.offset) { _, preset in
          Button {
            guard extras.count < EditableManualExtra.maxExtras else { return }
            let item = EditableManualExtra(
              kind: preset.1,
              label: preset.2,
              mode: preset.3,
              percentText: preset.3 == .percent ? preset.4 : "",
              amountText: ""
            )
            extras.append(item)
            onChange()
          } label: {
            Text(preset.0)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 38)
              .background(Tokens.sunken, in: Capsule())
          }
          .buttonStyle(.plain)
          .disabled(extras.count >= EditableManualExtra.maxExtras)
          .opacity(extras.count >= EditableManualExtra.maxExtras ? 0.45 : 1)
        }
      }
    }
  }

  @ViewBuilder
  private func extraRow(at index: Int) -> some View {
    let binding = $extras[index]
    let resolvedAmount: Money? = {
      guard isPreviewCurrent, let preview, index < preview.resolvedExtras.count else {
        return nil
      }
      return preview.resolvedExtras[index].amount
    }()

    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Menu {
          ForEach(ReceiptExtraKind.allCases, id: \.self) { kind in
            Button(kind.localizedTitle) {
              binding.wrappedValue.kind = kind
              if !supportsPercent(kind) {
                binding.wrappedValue.mode = .amount
                binding.wrappedValue.percentText = ""
              }
              onChange()
            }
          }
        } label: {
          Text(binding.wrappedValue.kind.localizedTitle)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .frame(minHeight: 40)
            .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        TextField(
          binding.wrappedValue.kind.localizedTitle,
          text: Binding(
            get: { binding.wrappedValue.label },
            set: { next in
              binding.wrappedValue.label = String(next.prefix(40))
              onChange()
            }
          )
        )
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 10)
        .frame(minHeight: 40)
        .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        Button {
          extras.remove(at: index)
          onChange()
        } label: {
          Image(systemName: "trash")
            .spIconFont(size: 15, weight: .semibold, relativeTo: .subheadline)
            .foregroundStyle(Tokens.muted)
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("extras.remove"))
      }

      HStack(spacing: 8) {
        if supportsPercent(binding.wrappedValue.kind) {
          Picker(
            "",
            selection: Binding(
              get: { binding.wrappedValue.mode },
              set: { next in
                binding.wrappedValue.mode = next
                onChange()
              }
            )
          ) {
            Text(L10n.tr("extras.modePercent")).tag(EditableManualExtra.InputMode.percent)
            Text(L10n.tr("extras.modeAmount")).tag(EditableManualExtra.InputMode.amount)
          }
          .pickerStyle(.segmented)
          .frame(width: 120)
        }

        if binding.wrappedValue.mode == .percent {
          HStack(spacing: 4) {
            TextField(
              "0",
              text: Binding(
                get: { binding.wrappedValue.percentText },
                set: { next in
                  let normalized = next.replacingOccurrences(of: ",", with: ".")
                  if normalized.isEmpty
                    || normalized.range(
                      of: #"^\d{0,2}(\.\d{0,2})?$"#, options: .regularExpression) != nil
                  {
                    binding.wrappedValue.percentText = normalized
                    onChange()
                  }
                }
              )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .font(Typography.subheadlineBold)
            .monospacedDigit()
            .foregroundStyle(Tokens.ink)
            .accessibilityLabel(L10n.tr("extras.percentLabel"))

            Text("%")
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
          }
          .padding(.horizontal, 10)
          .frame(minHeight: 40)
          .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
          HStack(spacing: 4) {
            TextField(
              "0",
              text: Binding(
                get: { binding.wrappedValue.amountText },
                set: { next in
                  let digits = next.filter { $0.isWholeNumber && $0.isASCII }
                  if digits.isEmpty {
                    binding.wrappedValue.amountText = ""
                  } else if let money = MoneyFormat.parseInput(digits) {
                    binding.wrappedValue.amountText = MoneyFormat.amount(money)
                  }
                  onChange()
                }
              )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .font(Typography.subheadlineBold)
            .monospacedDigit()
            .foregroundStyle(Tokens.ink)
            .accessibilityLabel(L10n.tr("extras.amountLabel"))

            Text(L10n.tr("common.currency"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
          }
          .padding(.horizontal, 10)
          .frame(minHeight: 40)
          .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        if let resolvedAmount {
          let signed =
            binding.wrappedValue.kind == .discount
            ? Money(-resolvedAmount.amount)
            : resolvedAmount
          MoneyText(
            signed,
            style: .signed,
            font: Typography.captionBold,
            color: binding.wrappedValue.kind == .discount ? Tokens.credit : Tokens.muted
          )
        }
      }
    }
    .padding(10)
    .background(
      Tokens.sunken.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var allocationPicker: some View {
    HStack(spacing: 6) {
      allocationChip(title: L10n.tr("extras.allocEqual"), target: .equal)
      allocationChip(title: L10n.tr("extras.allocProportional"), target: .proportional)
    }
  }

  private func allocationChip(title: String, target: ExtrasAllocation) -> some View {
    let selected = allocation == target
    return Button {
      allocation = target
      onChange()
    } label: {
      Text(title)
        .font(Typography.captionBold)
        .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(selected ? Tokens.ink : Tokens.sunken, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  private var totalsFooter: some View {
    VStack(spacing: 6) {
      HStack {
        Text(L10n.tr("extras.goodsSubtotal"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer()
        MoneyText(baseAmount, style: .full, font: Typography.captionBold, color: Tokens.ink)
      }

      HStack {
        Text(L10n.tr("extras.cardTitle"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer()
        if isPreviewCurrent, let preview {
          MoneyText(
            preview.netExtras,
            style: .signed,
            font: Typography.captionBold,
            color: preview.netExtras.isNegative ? Tokens.credit : Tokens.ink
          )
        } else {
          Text(L10n.tr("common.pendingValue"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }
      }

      HStack {
        Text(L10n.tr("extras.totalPayment"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
        Spacer()
        if isPreviewCurrent, let preview {
          MoneyText(
            preview.computedAmount,
            style: .full,
            font: Typography.sectionTitle,
            color: Tokens.ink
          )
        } else {
          Text(L10n.tr("common.pendingValue"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
        }
      }

      if previewError != nil || (isPreviewCurrent && preview?.issues.isEmpty == false) {
        Text(L10n.tr("receipts.invalidTotal"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
