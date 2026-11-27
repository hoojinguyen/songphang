import DesignSystem
import Domain
import PhotosUI
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct ReceiptReviewView: View {
  @Bindable private var model: ReceiptReviewModel
  private let onBack: () -> Void

  @State private var retakePhotoItem: PhotosPickerItem?
  @State private var isRetakeCameraPresented = false

  public init(
    model: ReceiptReviewModel,
    onBack: @escaping () -> Void
  ) {
    self.model = model
    self.onBack = onBack
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        switch model.state {
        case .loading:
          SPScreenHeader(
            title: L10n.tr("receipts.title"),
            backLabel: L10n.tr("common.back"),
            onBack: onBack
          )
          LoadingSkeleton(rowCount: 3, rowHeight: 96)

        case .failed:
          SPScreenHeader(
            title: L10n.tr("receipts.title"),
            backLabel: L10n.tr("common.back"),
            onBack: onBack
          )
          LoadError {
            Task { await model.load(defaultTitle: L10n.tr("receipts.title")) }
          }

        case .loaded(let data):
          if !model.hasTimedOut
            && (data.scan.status == .queued || data.scan.status == .processing)
          {
            pendingView(attachmentId: data.scan.attachmentId)
          } else if data.scan.status == .failed
            || (model.hasTimedOut && data.scan.status != .done)
          {
            failedView(scan: data.scan)
          } else {
            doneView(data: data)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 28)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .task {
      if model.state.value == nil {
        await model.load(defaultTitle: L10n.tr("receipts.title"))
      }
    }
    .onDisappear {
      model.stopPolling()
    }
    .onChange(of: retakePhotoItem) { _, item in
      guard let item else { return }
      retakePhotoItem = nil
      Task {
        if let bytes = try? await item.loadTransferable(type: Data.self) {
          await model.retake(rawImageData: bytes, defaultTitle: L10n.tr("receipts.title"))
        }
      }
    }
    .fullScreenCover(isPresented: $isRetakeCameraPresented) {
      CameraPickerView(
        onCapture: { raw in
          isRetakeCameraPresented = false
          Task {
            await model.retake(rawImageData: raw, defaultTitle: L10n.tr("receipts.title"))
          }
        },
        onCancel: {
          isRetakeCameraPresented = false
        }
      )
      .ignoresSafeArea()
    }
  }

  @ViewBuilder
  private func pendingView(attachmentId: Attachment.ID) -> some View {
    SPScreenHeader(
      title: L10n.tr("receipts.title"),
      backLabel: L10n.tr("common.cancel"),
      onBack: onBack
    )
    RemoteAttachmentThumbnail(attachmentId: attachmentId, size: 96, cornerRadius: 20) { id in
      try await model.attachmentsRepository.content(groupId: model.groupId, attachmentId: id)
    }
    HStack(spacing: 10) {
      ProgressView()
      Text(L10n.tr("receipts.reading"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
    }
  }

  @ViewBuilder
  private func failedView(scan: ReceiptScan) -> some View {
    let notAReceipt = scan.errorCode == "NOT_A_RECEIPT"
    SPScreenHeader(
      title: L10n.tr("receipts.title"),
      backLabel: L10n.tr("common.cancel"),
      onBack: onBack
    )
    RemoteAttachmentThumbnail(attachmentId: scan.attachmentId, size: 96, cornerRadius: 20) { id in
      try await model.attachmentsRepository.content(groupId: model.groupId, attachmentId: id)
    }

    SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 12) {
        Text(notAReceipt ? L10n.tr("receipts.notAReceipt") : L10n.tr("receipts.failed"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        if let imgErr = model.retakeImageError {
          Text(UploadErrorFormatter.message(for: imgErr))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        } else if let err = model.retakeError {
          Text(UploadErrorFormatter.message(for: err))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        }

        HStack(spacing: 10) {
          if notAReceipt {
            PhotosPicker(
              selection: $retakePhotoItem,
              matching: .images,
              photoLibrary: .shared()
            ) {
              Text(L10n.tr("receipts.retake"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.surface)
                .padding(.horizontal, 16)
                .frame(minHeight: 46)
                .background(Tokens.ink, in: Capsule())
            }
            .disabled(model.isRetaking)

            if ReceiptCameraCapability.isCameraAvailable {
              SPButton(
                L10n.tr("receipts.takePhoto"),
                variant: .surface,
                isDisabled: model.isRetaking
              ) {
                Task {
                  if await ReceiptCameraCapability.requestCameraAccessIfNeeded() {
                    isRetakeCameraPresented = true
                  }
                }
              }
            }
          } else {
            SPButton(
              L10n.tr("receipts.retry"),
              variant: .primary,
              isDisabled: model.isRetaking,
              isPending: model.isRetaking
            ) {
              Task {
                await model.rescanExistingAttachment(defaultTitle: L10n.tr("receipts.title"))
              }
            }
          }

          SPButton(
            L10n.tr("receipts.manualEntry"),
            variant: .surface,
            isDisabled: model.isRetaking
          ) {
            model.openManualFallback()
          }
        }
      }
    }
  }

  @ViewBuilder
  private func doneView(data: ReceiptReviewModel.ScreenData) -> some View {
    let people = model.activePeople(from: data.members)
    let payers = model.payerOptions(from: data.members)
    let computedAmount = model.isPreviewCurrent ? model.itemsPreview?.computedAmount : nil

    VStack(alignment: .leading, spacing: 4) {
      SPScreenHeader(
        title: L10n.tr("receipts.title"),
        backLabel: L10n.tr("common.cancel"),
        onBack: onBack
      )
      Text(L10n.tr("receipts.aiNote"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)
    }

    HStack(alignment: .top, spacing: 12) {
      RemoteAttachmentThumbnail(attachmentId: data.scan.attachmentId, size: 80, cornerRadius: 20) {
        id in
        try await model.attachmentsRepository.content(groupId: model.groupId, attachmentId: id)
      }

      VStack(spacing: 8) {
        TextField(
          L10n.tr("receipts.descriptionLabel"),
          text: Binding(
            get: { model.descriptionText },
            set: { model.descriptionText = String($0.prefix(200)) }
          )
        )
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel(L10n.tr("receipts.descriptionLabel"))

        TextField(L10n.tr("ios.receipts.datePlaceholder"), text: $model.occurredOn)
          .font(Typography.body)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 14)
          .frame(height: 44)
          .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          .accessibilityLabel(L10n.tr("receipts.dateLabel"))
      }
    }

    if let mismatch = model.mismatchInfo {
      mismatchCard(computed: mismatch.computed, printedTotal: mismatch.printedTotal)
    }

    ReceiptItemsAssignmentView(
      draft: $model.itemsDraft,
      activePeople: people,
      preview: model.itemsPreview,
      isPreviewCurrent: model.isPreviewCurrent,
      previewError: model.previewError,
      onChange: { model.schedulePreview() }
    )

    Text(
      computedAmount.map { MoneyFormat.full($0) } ?? L10n.tr("common.pendingValue")
    )
    .font(Typography.heroNumber)
    .foregroundStyle(Tokens.ink)
    .frame(maxWidth: .infinity)
    .padding(16)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

    payerPicker(options: payers)

    if let submitError = model.submitError {
      Text(
        submitError == .api(code: "FORBIDDEN", status: 403)
          ? L10n.tr("common.forbidden")
          : L10n.tr("common.saveError")
      )
      .font(Typography.captionBold)
      .foregroundStyle(Tokens.debt)
    }

    SPButton(
      L10n.tr("receipts.save"),
      variant: .accent,
      size: .lg,
      isFullWidth: true,
      isDisabled: !model.canSave,
      isPending: model.isSubmitting
    ) {
      Task { await model.save() }
    }
  }

  @ViewBuilder
  private func mismatchCard(computed: Money, printedTotal: Money) -> some View {
    let extrasFull = model.itemsDraft.isExtrasFull
    let printedPending = !model.isPreviewCurrent
    VStack(alignment: .leading, spacing: 10) {
      Text(
        L10n.t(
          "receipts.mismatch",
          [
            "computed": MoneyFormat.full(computed),
            "total": MoneyFormat.full(printedTotal),
          ]
        )
      )
      .font(Typography.subheadlineBold)
      .foregroundStyle(Tokens.ink)

      if extrasFull {
        Text(L10n.tr("receipts.maxExtras"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }

      HStack(spacing: 10) {
        SPButton(
          L10n.t("receipts.useAmount", ["amount": MoneyFormat.full(computed)]),
          variant: .surface
        ) {
          model.useComputedTotal()
        }
        SPButton(
          L10n.t("receipts.useAmount", ["amount": MoneyFormat.full(printedTotal)]),
          variant: .primary,
          isDisabled: extrasFull || printedPending
        ) {
          model.applyPrintedTotal(adjustmentLabel: L10n.tr("receipts.mismatchExtraLabel"))
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.phraseAmount, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func payerPicker(options: [Member]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(L10n.tr("receipts.paidBy"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(options) { member in
            let activePayer = model.payerId == member.id
            Button {
              model.payerId = member.id
            } label: {
              HStack(spacing: 6) {
                MemberShapeView(
                  shape: member.shape,
                  color: member.color,
                  name: member.name,
                  size: 22,
                  showInitial: false
                )
                Text(member.name)
                  .font(Typography.captionBold)
              }
              .foregroundStyle(activePayer ? Tokens.surface : Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 44)
              .background(activePayer ? Tokens.ink : Tokens.sunken, in: Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .padding(14)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }
}

#if DEBUG
  #Preview("Receipt Review Done") {
    let world = FakeWorld(preset: .tripStep4)
    ReceiptReviewView(
      model: ReceiptReviewModel(
        groupId: TripScenario.groupId,
        scanId: FakeWorld.sampleReceiptScanId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        attachmentsRepository: FakeAttachmentsRepository(world: world),
        receiptScansRepository: FakeReceiptScansRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        onSaved: {},
        onManualFallback: { _ in }
      ),
      onBack: {}
    )
  }
#endif
