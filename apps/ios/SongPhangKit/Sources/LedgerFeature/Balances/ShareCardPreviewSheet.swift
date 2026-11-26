import DesignSystem
public import Domain
import Photos
public import SwiftUI
import UIKit
import UniformTypeIdentifiers

#if DEBUG
  import PreviewSupport
#endif

public struct ShareCardPreviewSheet: View {
  private let data: BalancesViewData
  private let loadGuestLink: (@Sendable () async -> GuestLink?)?
  private let onDismiss: () -> Void

  @Environment(\.colorScheme) private var systemColorScheme
  @State private var mode: ShareCardMode = .summary
  @State private var selectedThemeOverride: ColorScheme?
  @State private var includeExpenses = false
  @State private var selectedTransferId: SuggestedTransfer.ID?
  @State private var caption = ""
  @State private var guestLink: GuestLink?
  @State private var exportedImage: UIImage?
  @State private var transferablePNG: ShareCardPNG?
  @State private var copiedImage = false
  @State private var savedToPhotos = false
  @State private var saveErrorMessage: String?

  private var selectedTheme: ColorScheme {
    selectedThemeOverride ?? systemColorScheme
  }

  public init(
    data: BalancesViewData,
    loadGuestLink: (@Sendable () async -> GuestLink?)? = nil,
    onDismiss: @escaping () -> Void
  ) {
    self.data = data
    self.loadGuestLink = loadGuestLink
    self.onDismiss = onDismiss
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          controlsSection
          previewSection
          actionButtons
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("shareCard.openAction"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.tr("split.done"), action: onDismiss)
        }
      }
      .task {
        #if DEBUG
          let args = ProcessInfo.processInfo.arguments
          if args.contains("--sharecard-dark") {
            selectedThemeOverride = .dark
          }
          if args.contains("--sharecard-reminder") {
            mode = .reminder
            selectedTransferId = data.balances.transfers.first?.id
          }
        #endif
        rerenderImage()
        if let loadGuestLink {
          guestLink = await loadGuestLink()
        }
      }
      .onChange(of: mode) { _, _ in rerenderImage() }
      .onChange(of: selectedThemeOverride) { _, _ in rerenderImage() }
      .onChange(of: systemColorScheme) { _, _ in rerenderImage() }
      .onChange(of: includeExpenses) { _, _ in rerenderImage() }
      .onChange(of: selectedTransferId) { _, _ in rerenderImage() }
      .onChange(of: caption) { _, _ in rerenderImage() }
      .onChange(of: guestLink) { _, _ in rerenderImage() }
    }
  }

  private var controlsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Picker("", selection: $mode) {
        Text(L10n.tr("shareCard.modeSummary")).tag(ShareCardMode.summary)
        Text(L10n.tr("shareCard.modeReminder")).tag(ShareCardMode.reminder)
      }
      .pickerStyle(.segmented)

      Picker(
        "",
        selection: Binding(
          get: { selectedTheme },
          set: { selectedThemeOverride = $0 }
        )
      ) {
        Text(L10n.tr("shareCard.themeLight")).tag(ColorScheme.light)
        Text(L10n.tr("shareCard.themeDark")).tag(ColorScheme.dark)
      }
      .pickerStyle(.segmented)

      if mode == .summary {
        Toggle(L10n.tr("shareCard.includeExpenses"), isOn: $includeExpenses)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .tint(Tokens.ink)
      } else {
        targetPicker
      }

      captionControls
    }
    .padding(16)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  private var targetPicker: some View {
    let membersById = Dictionary(uniqueKeysWithValues: data.members.map { ($0.id, $0) })
    return HStack {
      Text(L10n.tr("shareCard.targetLabel"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
      Spacer()
      Picker(L10n.tr("shareCard.targetLabel"), selection: $selectedTransferId) {
        Text(L10n.tr("shareCard.targetAll")).tag(SuggestedTransfer.ID?.none)
        ForEach(data.balances.transfers) { transfer in
          let fromName = membersById[transfer.fromMemberId]?.name ?? ""
          let toName = membersById[transfer.toMemberId]?.name ?? ""
          Text("\(fromName) → \(toName) · \(MoneyFormat.full(transfer.amount))")
            .tag(SuggestedTransfer.ID?.some(transfer.id))
        }
      }
      .labelsHidden()
    }
  }

  private var captionControls: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("shareCard.captionLabel"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(["shareCard.preset1", "shareCard.preset2", "shareCard.preset3"], id: \.self) {
            key in
            let text = L10n.tr(key)
            Button(text) {
              caption = String(text.prefix(100))
            }
            .font(Typography.captionBold)
            .foregroundStyle(caption == text ? Tokens.onInk : Tokens.ink)
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
            .background(caption == text ? Tokens.ink : Tokens.sunken, in: Capsule())
            .buttonStyle(.plain)
          }
        }
      }

      TextField(L10n.tr("shareCard.captionLabel"), text: $caption)
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onChange(of: caption) { _, newValue in
          if newValue.count > 100 {
            caption = String(newValue.prefix(100))
          }
        }
    }
  }

  private var previewSection: some View {
    VStack(spacing: 8) {
      if let exportedImage {
        Image(uiImage: exportedImage)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      } else {
        ShareCardCanvasView(content: currentCardContent)
          .environment(\.colorScheme, selectedTheme)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
    }
  }

  private var actionButtons: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let saveErrorMessage {
        Text(saveErrorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
      }

      if let pngItem = transferablePNG {
        ShareLink(
          item: pngItem,
          preview: SharePreview(data.group.name, image: Image(uiImage: pngItem.image))
        ) {
          Text(L10n.tr("shareCard.shareImage"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.onAccent)
            .frame(maxWidth: .infinity, minHeight: Tokens.controlMediumHeight)
            .background(Tokens.accent, in: Capsule())
        }
        .buttonStyle(.plain)
      }

      HStack(spacing: 10) {
        SPButton(
          savedToPhotos ? L10n.tr("split.done") : L10n.tr("shareCard.downloadPng"),
          variant: .surface,
          size: .md,
          isFullWidth: true,
          isDisabled: savedToPhotos
        ) {
          Task { await savePNGToPhotos() }
        }

        SPButton(
          copiedImage ? L10n.tr("shareCard.copiedImage") : L10n.tr("shareCard.copyImage"),
          variant: .surface,
          size: .md,
          isFullWidth: true
        ) {
          if let image = exportedImage ?? renderImage() {
            UIPasteboard.general.image = image
            Haptics.light()
            copiedImage = true
          }
        }
      }
    }
  }

  private var currentCardContent: ShareCardContent {
    let membersById = Dictionary(uniqueKeysWithValues: data.members.map { ($0.id, $0) })
    let focusCycle: SettlementCycle? =
      if data.breakdowns?.resolvedFocus.kind == .cycle,
        let focusCycleId = data.breakdowns?.resolvedFocus.cycleId
      {
        data.cyclesOverview?.cycles.first { $0.id == focusCycleId }
      } else {
        nil
      }
    let resolvedFocus = data.breakdowns?.resolvedFocus
    let expenseTxs = data.transactions.filter { tx in
      guard tx.type == .expense && tx.deletedAt == nil else { return false }
      if let focusCycle {
        return tx.cycleId == focusCycle.id
      }
      if resolvedFocus?.kind == .current || data.cyclesOverview?.cycles.isEmpty == false {
        return tx.cycleId == nil
      }
      return true
    }
    let periodLabel =
      data.breakdowns?.resolvedFocus.label ?? L10n.tr("cycles.currentPeriod")
    let dateRangeLabel: String =
      if let focusCycle {
        "\(LedgerDateLabels.dayLabel(for: focusCycle.startedAt)) – \(LedgerDateLabels.dayLabel(for: focusCycle.closedAt))"
      } else if let startedAt = data.cyclesOverview?.currentPeriod.startedAt {
        LedgerDateLabels.dayLabel(for: startedAt)
      } else if let firstDate = expenseTxs.last?.occurredAt {
        LedgerDateLabels.dayLabel(for: firstDate)
      } else {
        ""
      }

    let totalExpense =
      focusCycle?.totalExpenseAmount
      ?? data.cyclesOverview?.currentPeriod.totalExpenseAmount
      ?? .zero
    let expenseCount =
      focusCycle?.expenseCount
      ?? data.cyclesOverview?.currentPeriod.expenseCount
      ?? 0

    let balanceRows: [ShareCardContent.BalanceRow] = data.balances.balances
      .sorted { $0.balance > $1.balance }
      .compactMap { bal in
        guard let member = membersById[bal.memberId], member.active || !bal.balance.isZero else {
          return nil
        }
        return ShareCardContent.BalanceRow(
          name: member.name,
          shape: member.shape,
          color: member.color,
          balance: bal.balance
        )
      }

    let selectedTransfer: SuggestedTransfer? =
      if mode == .reminder, let selectedTransferId {
        data.balances.transfers.first { $0.id == selectedTransferId }
      } else {
        nil
      }

    let scopedTransfers: [SuggestedTransfer] =
      if let selectedTransfer {
        [selectedTransfer]
      } else {
        data.balances.transfers
      }

    let transferRows: [ShareCardContent.TransferRow] = scopedTransfers.compactMap { transfer in
      mapTransferRow(transfer, membersById: membersById)
    }

    let debtorAllocationTransfers: [ShareCardContent.TransferRow] =
      if let selectedTransfer {
        data.balances.transfers
          .filter { $0.fromMemberId == selectedTransfer.fromMemberId }
          .compactMap { mapTransferRow($0, membersById: membersById) }
      } else {
        []
      }

    let recentExpenses: [ShareCardContent.ExpenseRow] = expenseTxs.map { tx in
      let payerName =
        tx.payers.first.flatMap { membersById[$0.memberId]?.name } ?? ""
      return ShareCardContent.ExpenseRow(
        id: tx.id.rawValue,
        title: tx.description,
        payerName: payerName,
        amount: tx.amount
      )
    }

    let targetBreakdown: MemberDebtBreakdown? =
      if let selectedTransfer {
        data.breakdowns?.breakdowns.first { $0.memberId == selectedTransfer.fromMemberId }
      } else {
        nil
      }

    let summaryBankDetails: ShareCardContent.SummaryBankDetails? =
      resolveSingleReceiverBankDetails(
        transfers: scopedTransfers,
        membersById: membersById
      )

    let householdRows: [ShareCardContent.HouseholdRow] = data.balances.households.map { hh in
      ShareCardContent.HouseholdRow(
        name: hh.name,
        representativeName: membersById[hh.representativeMemberId]?.name ?? "",
        balance: hh.netBalance
      )
    }

    return ShareCardContent(
      mode: mode,
      groupName: data.group.name,
      periodLabel: periodLabel,
      dateRangeLabel: dateRangeLabel,
      totalExpense: totalExpense,
      expenseCount: expenseCount,
      balances: balanceRows,
      households: householdRows,
      transfers: transferRows,
      debtorAllocationTransfers: debtorAllocationTransfers,
      isSingleTransferReminder: selectedTransfer != nil,
      includeExpenses: includeExpenses,
      recentExpenses: recentExpenses,
      targetBreakdown: targetBreakdown,
      customCaption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
      guestShareURL: guestLink?.active == true ? guestLink?.url : nil,
      summaryBankDetails: summaryBankDetails
    )
  }

  private func mapTransferRow(
    _ transfer: SuggestedTransfer,
    membersById: [Member.ID: Member]
  ) -> ShareCardContent.TransferRow? {
    guard let from = membersById[transfer.fromMemberId],
      let to = membersById[transfer.toMemberId]
    else { return nil }
    let fromLabel: String = {
      if let hh = transfer.fromHousehold {
        return "\(hh.name) (\(L10n.t("households.representativeBadge", ["name": from.name])))"
      }
      return from.name
    }()
    let toLabel: String = {
      if let hh = transfer.toHousehold {
        return "\(hh.name) (\(L10n.t("households.representativeBadge", ["name": to.name])))"
      }
      return to.name
    }()
    return ShareCardContent.TransferRow(
      fromName: fromLabel,
      toName: toLabel,
      amount: transfer.amount,
      purpose: transfer.purpose ?? "",
      paymentMethods: transfer.paymentMethods
    )
  }

  private func resolveSingleReceiverBankDetails(
    transfers: [SuggestedTransfer],
    membersById: [Member.ID: Member]
  ) -> ShareCardContent.SummaryBankDetails? {
    let receiverIds = Set(transfers.map(\.toMemberId))
    guard receiverIds.count == 1,
      let singleReceiverId = receiverIds.first,
      let receiver = membersById[singleReceiverId]
    else { return nil }

    let bank =
      transfers
      .flatMap(\.paymentMethods)
      .compactMap { method -> BankPayment? in
        if case .bank(let details) = method { return details }
        return nil
      }
      .first

    guard let bank, let accountQr = bank.accountQrPayload, !accountQr.isEmpty else {
      return nil
    }
    return ShareCardContent.SummaryBankDetails(
      receiverName: receiver.name,
      bankShortName: bank.name,
      accountNumber: bank.accountNumber,
      accountName: bank.accountName,
      accountQrPayload: accountQr
    )
  }

  @MainActor
  private func renderImage() -> UIImage? {
    let view = ShareCardCanvasView(content: currentCardContent)
      .frame(width: 390)
      .environment(\.colorScheme, selectedTheme)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0
    return renderer.uiImage
  }

  @MainActor
  private func rerenderImage() {
    copiedImage = false
    savedToPhotos = false
    saveErrorMessage = nil
    let image = renderImage()
    exportedImage = image
    if let image, let pngData = image.pngData() {
      transferablePNG = ShareCardPNG(image: image, data: pngData)
    } else {
      transferablePNG = nil
    }
  }

  @MainActor
  private func makeTransferablePNG() -> ShareCardPNG? {
    guard let image = exportedImage ?? renderImage(),
      let pngData = image.pngData()
    else { return nil }
    return ShareCardPNG(image: image, data: pngData)
  }

  private func savePNGToPhotos() async {
    guard !savedToPhotos else { return }
    saveErrorMessage = nil
    guard let png = transferablePNG ?? makeTransferablePNG() else { return }
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      saveErrorMessage = L10n.tr("common.saveError")
      return
    }
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("songphang-share-\(UUID().uuidString).png")
    do {
      try png.data.write(to: tempURL, options: .atomic)
      defer { try? FileManager.default.removeItem(at: tempURL) }
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempURL)
      }
      Haptics.light()
      savedToPhotos = true
    } catch {
      saveErrorMessage = L10n.tr("common.saveError")
    }
  }
}

private struct ShareCardPNG: Transferable {
  let image: UIImage
  let data: Data

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .png) { item in
      item.data
    }
  }
}

#if DEBUG
  #Preview("Share Card Summary") {
    let world = FakeWorld(preset: .tripStep4)
    ShareCardPreviewSheet(
      data: BalancesViewData(
        group: TripScenario.group(forStep: 4, role: .owner),
        members: TripScenario.members,
        balances: TripScenario.step4Balances,
        transactions: [
          TripScenario.t1Transaction,
          TripScenario.t2Transaction,
          TripScenario.t3Transaction,
          TripScenario.t4Transaction,
        ]
      ),
      loadGuestLink: {
        try? await FakeGuestLinksRepository(world: world).status(groupId: TripScenario.groupId)
      },
      onDismiss: {}
    )
  }
#endif
