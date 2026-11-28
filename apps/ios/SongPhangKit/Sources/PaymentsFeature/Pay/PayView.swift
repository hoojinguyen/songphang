import DesignSystem
import Domain
import Photos
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

public struct PayView: View {
  @Bindable private var model: PayModel
  private let isOffline: Bool
  private let onBack: () -> Void
  private let onAddDetails: (() -> Void)?
  private let onRecordDirectly: (() -> Void)?
  private let onFinished: (String?) -> Void

  @State private var copiedAmount = false
  @State private var copiedField: String?
  @State private var photoResult: Bool?

  public init(
    model: PayModel,
    isOffline: Bool = false,
    onBack: @escaping () -> Void,
    onAddDetails: (() -> Void)? = nil,
    onRecordDirectly: (() -> Void)? = nil,
    onFinished: @escaping (String?) -> Void = { _ in }
  ) {
    self.model = model
    self.isOffline = isOffline
    self.onBack = onBack
    self.onAddDetails = onAddDetails
    self.onRecordDirectly = onRecordDirectly
    self.onFinished = onFinished
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if isOffline {
            OfflineBanner()
          }

          membersBanner
          amountHeader
          paymentMethodsSection
          footerSection
        }
        .padding(20)
        .spFittedSheetContent()
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.t("pay.title", ["to": model.toMember.name]))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if model.mayCreate && model.isEmailVerified && model.transfer.pendingSettlement == nil
            && !model.submitted
          {
            SheetCancelButton(action: onBack)
              .disabled(model.isSubmitting)
          } else {
            SheetCloseButton(action: onBack)
          }
        }
      }
    }
    .spSheet(.fitted, expandable: true, embedsNavigationStack: true)
    .discardGuard(
      isDirty: model.hasUnsavedProofDraft && !model.isSubmitting,
      onDiscard: onBack
    )
  }

  private var membersBanner: some View {
    HStack(spacing: 16) {
      Spacer(minLength: 0)
      memberBadge(model.fromMember)
      Image(systemName: "arrow.right")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Tokens.ink)
        .accessibilityHidden(true)
      memberBadge(model.toMember)
      Spacer(minLength: 0)
    }
    .padding(16)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
  }

  private func memberBadge(_ member: Member) -> some View {
    VStack(spacing: 8) {
      MemberShapeView(
        shape: member.shape,
        color: member.color,
        name: member.name,
        size: 56
      )
      Text(member.id == model.myMemberId ? L10n.tr("common.you") : member.name)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }
  }

  private var amountHeader: some View {
    VStack(spacing: 8) {
      MoneyText(
        model.payAmount,
        style: .full,
        font: Typography.heroNumber,
        color: Tokens.ink
      )
      Button {
        UIPasteboard.general.string = String(model.payAmount.amount)
        copiedAmount = true
        Task {
          try? await Task.sleep(for: .seconds(2))
          copiedAmount = false
        }
      } label: {
        Text(L10n.tr(copiedAmount ? "pay.copied" : "pay.copyAmount"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 16)
          .frame(minHeight: 44)
          .background(Tokens.surface, in: Capsule())
      }
      .buttonStyle(.plain)

      if model.isPartial {
        Text(
          L10n.t(
            "pay.partialNote",
            [
              "amount": MoneyFormat.full(model.payAmount),
              "total": MoneyFormat.full(model.transfer.amount),
            ]
          )
        )
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
        .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private var paymentMethodsSection: some View {
    if model.transfer.paymentMethods.isEmpty {
      SPCard {
        VStack(spacing: 12) {
          Text(L10n.t("pay.noDetails", ["to": model.toMember.name]))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
            .multilineTextAlignment(.center)

          if model.canAddDetails, let onAddDetails {
            SPButton(L10n.tr("pay.addDetails"), variant: .surface, action: onAddDetails)
          }
        }
        .frame(maxWidth: .infinity)
      }
    } else {
      let bank = model.transfer.paymentMethods.compactMap { method -> BankPayment? in
        if case .bank(let b) = method { return b }
        return nil
      }.first
      let wallets = model.transfer.paymentMethods.filter {
        if case .bank = $0 { return false }
        return true
      }

      if let bank {
        if let payload = bank.qrPayload, let qrImage = PaymentQRCode.render(payload: payload) {
          SPCard {
            VStack(spacing: 12) {
              Image(decorative: qrImage, scale: 1)
                .interpolation(.none)
                .resizable()
                .frame(width: 240, height: 240)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.t("pay.title", ["to": model.toMember.name]))

              Text(L10n.tr("pay.qrHint"))
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
                .multilineTextAlignment(.center)

              SPButton(L10n.tr("ios.pay.saveQR"), variant: .surface) {
                Task { await saveQRCode(qrImage) }
              }

              if let photoResult {
                Text(L10n.tr(photoResult ? "ios.pay.saveQRSucceeded" : "ios.pay.saveQRFailed"))
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
              }
            }
            .frame(maxWidth: .infinity)
          }
        }

        SPCard {
          VStack(alignment: .leading, spacing: 10) {
            copyRow(id: "bank", title: L10n.tr("payment.bank"), value: bank.name)
            copyRow(
              id: "accountNumber",
              title: L10n.tr("payment.accountNumber"),
              value: bank.accountNumber
            )
            copyRow(
              id: "accountName",
              title: L10n.tr("payment.accountName"),
              value: bank.accountName
            )
            if let purpose = model.transfer.purpose, !purpose.isEmpty {
              copyRow(id: "purpose", title: L10n.tr("pay.purpose"), value: purpose)
            }
          }
        }
      }

      if !wallets.isEmpty {
        SPCard {
          VStack(alignment: .leading, spacing: 10) {
            ForEach(wallets, id: \.self) { wallet in
              switch wallet {
              case .momo(let phone):
                copyRow(
                  id: "momo",
                  title: "",
                  value: L10n.t("pay.momoRow", ["phone": phone]),
                  copyValue: phone
                )
              case .zalopay(let phone):
                copyRow(
                  id: "zalopay",
                  title: "",
                  value: L10n.t("pay.zalopayRow", ["phone": phone]),
                  copyValue: phone
                )
              case .bank:
                EmptyView()
              }
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var footerSection: some View {
    VStack(spacing: 12) {
      if let pending = model.transfer.pendingSettlement {
        PendingSettlementCard(
          amount: pending.amount,
          fromName: model.fromMember.name,
          toName: model.toMember.name,
          channel: pending.channel,
          note: pending.note,
          proofAttachmentId: pending.proofAttachmentId,
          loadAttachment: model.loadAttachment,
          canResolve: model.canResolve,
          canCancel: model.canCancel,
          isDisabled: !model.isEmailVerified || isOffline,
          isPending: model.isSubmitting,
          onConfirm: {
            Task {
              await model.resolvePending(pending, decision: .confirm) {
                onFinished(model.notice)
              }
            }
          },
          onReject: {
            Task {
              await model.resolvePending(pending, decision: .reject) {
                onFinished(model.notice)
              }
            }
          },
          onCancel: {
            Task {
              await model.resolvePending(pending, decision: .cancel) {
                onFinished(model.notice)
              }
            }
          }
        )
      } else {
        if model.mayCreate && model.isEmailVerified {
          TransferProofInputSection(
            channel: $model.channel,
            note: $model.note,
            attachments: model.proofAttachment.map { [$0] } ?? [],
            maxAttachments: 1,
            isDisabled: isOffline || model.isSubmitting || model.submitted,
            isUploading: model.isUploadingProof,
            errorMessage: model.proofError,
            loadContent: model.loadAttachment,
            onUploadData: { data in
              await model.uploadProofImage(rawData: data)
            },
            onRemoveAttachment: { _ in
              model.removeProofAttachment()
            }
          )
        }

        if model.canEdit, let onRecordDirectly {
          Button(L10n.tr("pay.recordDirect"), action: onRecordDirectly)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .underline()
            .frame(minHeight: 44)
            .disabled(isOffline || model.isUploadingProof)
        }

        if let errorMessage = model.errorMessage {
          Text(errorMessage)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .multilineTextAlignment(.center)
        }

        if let notice = model.notice {
          Text(notice)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .multilineTextAlignment(.center)
        }

        if model.mayCreate {
          if model.isEmailVerified {
            SPButton(
              L10n.tr("pay.reportedButton"),
              variant: .primary,
              size: .lg,
              isFullWidth: true,
              isDisabled: model.submitted || model.isUploadingProof,
              isOfflineBlocked: isOffline,
              isPending: model.isSubmitting
            ) {
              Task {
                await model.submitReport {
                  onFinished(model.notice)
                }
              }
            }
          } else {
            SPCard(tone: .accent, padding: 16) {
              Text(L10n.tr("verify.banner"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.onAccent)
            }
          }
        }
      }
    }
  }

  private func copyRow(id: String, title: String, value: String, copyValue: String? = nil)
    -> some View
  {
    let targetCopy = copyValue ?? value
    let isCopied = copiedField == id
    return HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        if !title.isEmpty {
          Text(title)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        Text(value)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .textSelection(.enabled)
      }
      Spacer(minLength: 0)
      Button {
        UIPasteboard.general.string = targetCopy
        copiedField = id
        Task {
          try? await Task.sleep(for: .seconds(2))
          if copiedField == id { copiedField = nil }
        }
      } label: {
        Text(L10n.tr(isCopied ? "pay.copied" : "pay.copy"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .frame(minHeight: 44)
          .background(Tokens.sunken, in: Capsule())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(title.isEmpty ? L10n.tr("pay.copy") : "\(L10n.tr("pay.copy")) \(title)")
    }
  }

  private func saveQRCode(_ image: CGImage) async {
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      photoResult = false
      return
    }
    guard let data = UIImage(cgImage: image).pngData() else {
      photoResult = false
      return
    }
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
      }
      photoResult = true
    } catch {
      photoResult = false
    }
  }
}

#if DEBUG
  #Preview("Pay Loaded QR + Wallets") {
    let world = FakeWorld(preset: .tripStep4)
    let transfer = SuggestedTransfer(
      fromMemberId: TripScenario.lanId,
      toMemberId: TripScenario.minhId,
      amount: Money(150_000),
      paymentMethods: [
        .bank(
          BankPayment(
            bin: "970436",
            name: "Vietcombank",
            accountNumber: "0123456789",
            accountName: "NGUYEN VAN MINH",
            qrPayload:
              "00020101021238570010A00000072701270006970436011001234567890208QRIBFTTA530370454061500005802VN62180814SP Lan tra Minh6304A1B2"
          )),
        .momo(phone: "0901234567"),
      ],
      purpose: "SP Lan tra Minh"
    )
    PayView(
      model: PayModel(
        transfer: transfer,
        fromMember: TripScenario.members[1],
        toMember: TripScenario.members[0],
        groupId: TripScenario.groupId,
        myMemberId: TripScenario.lanId,
        role: .editor,
        isEmailVerified: true,
        repository: FakeSettlementRequestsRepository(world: world)
      ),
      onBack: {},
      onRecordDirectly: {}
    )
  }

  #Preview("Pay No Details") {
    let world = FakeWorld(preset: .tripStep4)
    let transfer = SuggestedTransfer(
      fromMemberId: TripScenario.lanId,
      toMemberId: TripScenario.minhId,
      amount: Money(150_000)
    )
    PayView(
      model: PayModel(
        transfer: transfer,
        fromMember: TripScenario.members[1],
        toMember: TripScenario.members[0],
        groupId: TripScenario.groupId,
        myMemberId: TripScenario.lanId,
        role: .editor,
        isEmailVerified: true,
        repository: FakeSettlementRequestsRepository(world: world)
      ),
      onBack: {},
      onAddDetails: {},
      onRecordDirectly: {}
    )
  }

  #Preview("Pay Pending Request") {
    let world = FakeWorld(preset: .tripStep4)
    let transfer = SuggestedTransfer(
      fromMemberId: TripScenario.lanId,
      toMemberId: TripScenario.minhId,
      amount: Money(150_000),
      pendingSettlement: PendingSettlement(
        id: "req-1",
        amount: Money(150_000),
        createdByMe: false
      )
    )
    PayView(
      model: PayModel(
        transfer: transfer,
        fromMember: TripScenario.members[1],
        toMember: TripScenario.members[0],
        groupId: TripScenario.groupId,
        myMemberId: TripScenario.minhId,
        role: .owner,
        isEmailVerified: true,
        repository: FakeSettlementRequestsRepository(world: world)
      ),
      onBack: {}
    )
  }

  #Preview("Pay Failed Offline") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline)
    )
    let transfer = SuggestedTransfer(
      fromMemberId: TripScenario.lanId,
      toMemberId: TripScenario.minhId,
      amount: Money(150_000)
    )
    PayView(
      model: PayModel(
        transfer: transfer,
        fromMember: TripScenario.members[1],
        toMember: TripScenario.members[0],
        groupId: TripScenario.groupId,
        myMemberId: TripScenario.lanId,
        role: .editor,
        isEmailVerified: true,
        repository: FakeSettlementRequestsRepository(world: world)
      ),
      isOffline: true,
      onBack: {},
      onRecordDirectly: {}
    )
  }
#endif
