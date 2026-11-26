public import Domain
public import SwiftUI

extension PaymentChannel {
  public var localizedTitle: String {
    switch self {
    case .bank: return L10n.tr("settlementProof.channelBank")
    case .momo: return L10n.tr("settlementProof.channelMomo")
    case .zalopay: return L10n.tr("settlementProof.channelZalopay")
    case .cash: return L10n.tr("settlementProof.channelCash")
    case .unknown(let raw): return raw
    }
  }
}

public struct PaymentChannelBadge: View {
  private let channel: PaymentChannel

  public init(_ channel: PaymentChannel) {
    self.channel = channel
  }

  public var body: some View {
    Text(channel.localizedTitle)
      .font(Typography.captionBold)
      .foregroundStyle(Tokens.ink)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(Tokens.sunken, in: Capsule())
  }
}

public struct ChannelPillPicker: View {
  @Binding private var selection: PaymentChannel?
  private let isDisabled: Bool

  public init(selection: Binding<PaymentChannel?>, isDisabled: Bool = false) {
    self._selection = selection
    self.isDisabled = isDisabled
  }

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(PaymentChannel.allCases, id: \.self) { channel in
          let isSelected = selection == channel
          Button {
            Haptics.light()
            selection = isSelected ? nil : channel
          } label: {
            Text(channel.localizedTitle)
              .font(Typography.captionBold)
              .foregroundStyle(isSelected ? Tokens.onInk : Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(
                isSelected ? Tokens.ink : Tokens.sunken,
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .disabled(isDisabled)
        }
      }
    }
  }
}
