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

  public init(
    isEnabled: Binding<Bool>,
    mode: Binding<RecurringMode>,
    frequency: Binding<RecurringFrequency>,
    dayOfWeek: Binding<Int>,
    dayOfMonth: Binding<Int>,
    monthOfYear: Binding<Int>
  ) {
    self._isEnabled = isEnabled
    self._mode = mode
    self._frequency = frequency
    self._dayOfWeek = dayOfWeek
    self._dayOfMonth = dayOfMonth
    self._monthOfYear = monthOfYear
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
            modeChip(title: L10n.tr("recurring.modeFixedDesc"), target: .fixed)
            modeChip(title: L10n.tr("recurring.modeVariableDesc"), target: .variable)
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

  private func modeChip(title: String, target: RecurringMode) -> some View {
    let selected = mode == target
    return Button {
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
    switch day {
    case 1: return "Thứ 2"
    case 2: return "Thứ 3"
    case 3: return "Thứ 4"
    case 4: return "Thứ 5"
    case 5: return "Thứ 6"
    case 6: return "Thứ 7"
    default: return "Chủ nhật"
    }
  }
}
