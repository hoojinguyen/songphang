import DesignSystem
public import Domain
public import SwiftUI

public struct RecurringInlineCardView: View {
  @Binding private var isEnabled: Bool
  @Binding private var mode: RecurringMode
  @Binding private var frequency: RecurringFrequency
  @Binding private var dayOfWeek: Int
  @Binding private var dayOfMonth: Int
  @Binding private var monthOfYear: Int
  private let canVariable: Bool

  public init(
    isEnabled: Binding<Bool>,
    mode: Binding<RecurringMode>,
    frequency: Binding<RecurringFrequency>,
    dayOfWeek: Binding<Int>,
    dayOfMonth: Binding<Int>,
    monthOfYear: Binding<Int>,
    canVariable: Bool = true
  ) {
    self._isEnabled = isEnabled
    self._mode = mode
    self._frequency = frequency
    self._dayOfWeek = dayOfWeek
    self._dayOfMonth = dayOfMonth
    self._monthOfYear = monthOfYear
    self.canVariable = canVariable
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Toggle(isOn: $isEnabled) {
        Text(L10n.tr("recurring.toggleLabel"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
      .tint(Tokens.ink)

      if isEnabled {
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("recurring.modeLabel"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          HStack(spacing: 8) {
            modeChip(title: L10n.tr("recurring.modeFixedDesc"), target: .fixed, disabled: false)
            modeChip(
              title: L10n.tr("recurring.modeVariableDesc"),
              target: .variable,
              disabled: !canVariable
            )
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("recurring.frequencyLabel"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                let selected = frequency == freq
                Button {
                  frequency = freq
                } label: {
                  Text(freqTitle(freq))
                    .font(Typography.captionBold)
                    .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(selected ? Tokens.ink : Tokens.sunken, in: Capsule())
                }
                .buttonStyle(.plain)
              }
            }
          }
        }

        if frequency == .weekly {
          Stepper(value: $dayOfWeek, in: 1...7) {
            Text("\(L10n.tr("recurring.dayOfWeekLabel")): \(dayOfWeekLabel(dayOfWeek))")
              .font(Typography.subheadline)
              .foregroundStyle(Tokens.ink)
          }
        } else {
          Stepper(value: $dayOfMonth, in: 1...31) {
            Text("\(L10n.tr("recurring.dayOfMonthLabel")): \(dayOfMonth)")
              .font(Typography.subheadline)
              .foregroundStyle(Tokens.ink)
          }
          if frequency == .yearly {
            Stepper(value: $monthOfYear, in: 1...12) {
              Text("\(L10n.tr("recurring.monthOfYearLabel")): \(monthOfYear)")
                .font(Typography.subheadline)
                .foregroundStyle(Tokens.ink)
            }
          }
        }
      }
    }
    .padding(14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func modeChip(title: String, target: RecurringMode, disabled: Bool) -> some View {
    let effectiveMode = canVariable ? mode : .fixed
    let selected = effectiveMode == target
    return Button {
      guard !disabled else { return }
      mode = target
    } label: {
      Text(title)
        .font(Typography.captionBold)
        .foregroundStyle(selected ? Tokens.onInk : Tokens.ink)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
          selected ? Tokens.ink : Tokens.sunken,
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
    .buttonStyle(.plain)
    .disabled(disabled)
    .opacity(disabled ? 0.45 : 1)
  }

  private func freqTitle(_ freq: RecurringFrequency) -> String {
    switch freq {
    case .weekly: return L10n.tr("recurring.freqWeekly")
    case .monthly: return L10n.tr("recurring.freqMonthly")
    case .quarterly: return L10n.tr("recurring.freqQuarterly")
    case .yearly: return L10n.tr("recurring.freqYearly")
    case .unknown(let raw): return raw
    }
  }

  private func dayOfWeekLabel(_ day: Int) -> String {
    let clamped = (1...7).contains(day) ? day : 7
    return L10n.tr("ios.recurring.weekday.\(clamped)")
  }
}
