import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct PaymentDetailsView: View {
  @Bindable private var model: PaymentDetailsModel
  private let isOffline: Bool
  private let onDismiss: () -> Void

  @State private var isPickingBank = false
  @State private var bankQuery = ""

  public init(
    model: PaymentDetailsModel,
    isOffline: Bool = false,
    onDismiss: @escaping () -> Void
  ) {
    self.model = model
    self.isOffline = isOffline
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SPScreenHeader(
          title: L10n.tr("payment.title"),
          backIcon: .close,
          onBack: onDismiss
        )

        Text(L10n.t("payment.hint", ["name": model.member.name]))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)

        SPCard {
          VStack(alignment: .leading, spacing: 14) {
            bankSelector

            SPTextField(
              label: L10n.tr("payment.accountNumber"),
              text: $model.accountNumber,
              error: model.hasInvalidAccountNumberCharacters
                ? L10n.tr("payment.invalidAccount") : nil,
              maxLength: 19
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()

            SPTextField(
              label: L10n.tr("payment.accountName"),
              text: Binding(
                get: { model.accountName },
                set: { model.updateAccountName($0) }
              ),
              maxLength: 50
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()

            SPTextField(
              label: L10n.tr("payment.momo"),
              text: $model.momo,
              maxLength: 32
            )
            .keyboardType(.phonePad)

            SPTextField(
              label: L10n.tr("payment.zalopay"),
              text: $model.zalopay,
              maxLength: 32
            )
            .keyboardType(.phonePad)

            SPButton(
              L10n.tr("compose.save"),
              variant: .primary,
              size: .lg,
              isFullWidth: true,
              isOfflineBlocked: isOffline,
              isPending: model.isSaving
            ) {
              Task {
                if await model.save() {
                  onDismiss()
                }
              }
            }

            if let errorMessage = model.errorMessage {
              Text(errorMessage)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
            } else if model.saved {
              Text(L10n.tr("payment.saved"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
            }
          }
        }
      }
      .padding(20)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .disabled(model.isSaving)
    .sheet(isPresented: $isPickingBank) {
      bankPickerSheet
    }
  }

  private var bankSelector: some View {
    let selectedBank = PaymentBanks.entries.first(where: { $0.bin == model.bin })
    return VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("payment.bank"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      HStack(spacing: 8) {
        Button {
          bankQuery = ""
          isPickingBank = true
        } label: {
          HStack {
            Text(selectedBank?.shortName ?? L10n.tr("payment.bank"))
              .font(Typography.bodyBold)
              .foregroundStyle(selectedBank == nil ? Tokens.muted : Tokens.ink)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(Tokens.muted)
              .accessibilityHidden(true)
          }
          .padding(.horizontal, 16)
          .frame(minHeight: 56)
          .background(Tokens.bg)
          .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("payment.bank"))

        if !model.bin.isEmpty {
          Button {
            model.bin = ""
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(Tokens.ink)
              .frame(width: 44, height: 56)
              .background(Tokens.sunken)
              .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.tr("common.cancel"))
        }
      }
    }
  }

  private var bankPickerSheet: some View {
    let foldedQuery = Self.foldForSearch(bankQuery.trimmingCharacters(in: .whitespacesAndNewlines))
    let filtered = PaymentBanks.entries.filter { bank in
      guard !foldedQuery.isEmpty else { return true }
      let target = Self.foldForSearch("\(bank.shortName) \(bank.fullName) \(bank.bin)")
      return target.contains(foldedQuery)
    }

    return VStack(alignment: .leading, spacing: 16) {
      SPScreenHeader(
        title: L10n.tr("payment.bank"),
        backIcon: .close,
        onBack: { isPickingBank = false }
      )

      SPTextField(
        label: L10n.tr("payment.bank"),
        text: $bankQuery,
        maxLength: 100
      )

      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(filtered) { bank in
            Button {
              model.bin = bank.bin
              isPickingBank = false
            } label: {
              VStack(alignment: .leading, spacing: 2) {
                Text(bank.shortName)
                  .font(Typography.bodyBold)
                  .foregroundStyle(Tokens.ink)
                Text("\(bank.fullName) · \(bank.bin)")
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(14)
              .background(Tokens.surface)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
          }
        }
      }

      SPButton(
        L10n.tr("common.cancel"),
        variant: .surface,
        isFullWidth: true
      ) {
        isPickingBank = false
      }
    }
    .padding(20)
    .background(Tokens.bg.ignoresSafeArea())
  }

  private static func foldForSearch(_ value: String) -> String {
    let replacedD =
      value
      .replacingOccurrences(of: "đ", with: "d")
      .replacingOccurrences(of: "Đ", with: "d")
    let folded = replacedD.applyingTransform(.stripDiacritics, reverse: false) ?? replacedD
    return folded.lowercased()
  }
}

#if DEBUG
  #Preview("Payment Details Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    let member = Member(
      id: TripScenario.minhId,
      name: "Minh",
      position: 0,
      shape: .circle,
      color: .mint,
      isMe: true,
      claimed: true,
      paymentMethods: [
        .bank(
          BankPayment(
            bin: "970436",
            name: "Vietcombank",
            accountNumber: "0123456789",
            accountName: "NGUYEN VAN MINH"
          )),
        .momo(phone: "0901234567"),
      ]
    )
    PaymentDetailsView(
      model: PaymentDetailsModel(
        groupId: TripScenario.groupId,
        member: member,
        repository: FakeMembersRepository(world: world)
      ),
      onDismiss: {}
    )
  }

  #Preview("Payment Details Empty") {
    let world = FakeWorld(preset: .tripStep4)
    PaymentDetailsView(
      model: PaymentDetailsModel(
        groupId: TripScenario.groupId,
        member: TripScenario.members[1],
        repository: FakeMembersRepository(world: world)
      ),
      onDismiss: {}
    )
  }

  #Preview("Payment Details Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline)
    )
    PaymentDetailsView(
      model: PaymentDetailsModel(
        groupId: TripScenario.groupId,
        member: TripScenario.members[0],
        repository: FakeMembersRepository(world: world)
      ),
      isOffline: true,
      onDismiss: {}
    )
  }
#endif
