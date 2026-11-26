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

  @State private var mode: ShareCardMode = .summary
  @State private var selectedTheme: ColorScheme = .light
  @State private var includeExpenses = false
  @State private var selectedTargetMemberId: Member.ID?
  @State private var caption = ""
  @State private var guestLink: GuestLink?
  @State private var exportedImage: UIImage?
  @State private var copiedImage = false
  @State private var savedToPhotos = false
  @State private var saveErrorMessage: String?

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
            selectedTheme = .dark
          }
          if args.contains("--sharecard-reminder") {
            mode = .reminder
            selectedTargetMemberId = data.balances.transfers.first?.fromMemberId
          }
        #endif
        if let loadGuestLink {
          guestLink = await loadGuestLink()
        }
        rerenderImage()
      }
      .onChange(of: mode) { _, _ in rerenderImage() }
      .onChange(of: selectedTheme) { _, _ in rerenderImage() }
      .onChange(of: includeExpenses) { _, _ in rerenderImage() }
      .onChange(of: selectedTargetMemberId) { _, _ in rerenderImage() }
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

      Picker("", selection: $selectedTheme) {
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
    let debtorIds = Set(data.balances.transfers.map(\.fromMemberId))
    let debtors = data.members.filter { debtorIds.contains($0.id) }
    return HStack {
      Text(L10n.tr("shareCard.targetLabel"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
      Spacer()
      Picker(L10n.tr("shareCard.targetLabel"), selection: $selectedTargetMemberId) {
        Text(L10n.tr("shareCard.targetAll")).tag(Member.ID?.none)
        ForEach(debtors) { member in
          Text(member.name).tag(Member.ID?.some(member.id))
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
            .foregroundStyle(caption == text ? Tokens.surface : Tokens.ink)
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

      if let pngItem = makeTransferablePNG() {
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
          isFullWidth: true
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
    let expenseTxs = data.transactions.filter {
      $0.type == .expense && $0.deletedAt == nil
        && (focusCycle == nil ? true : $0.cycleId == focusCycle?.id)
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
      ?? Money(expenseTxs.reduce(0) { $0 + $1.amount.amount })
    let expenseCount =
      focusCycle?.expenseCount
      ?? data.cyclesOverview?.currentPeriod.expenseCount
      ?? expenseTxs.count

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

    let scopedTransfers: [SuggestedTransfer] =
      if mode == .reminder, let selectedTargetMemberId {
        data.balances.transfers.filter { $0.fromMemberId == selectedTargetMemberId }
      } else {
        data.balances.transfers
      }

    let transferRows: [ShareCardContent.TransferRow] = scopedTransfers.compactMap { transfer in
      guard let from = membersById[transfer.fromMemberId],
        let to = membersById[transfer.toMemberId]
      else { return nil }
      return ShareCardContent.TransferRow(
        fromName: from.name,
        toName: to.name,
        amount: transfer.amount,
        purpose: transfer.purpose ?? "",
        paymentMethods: transfer.paymentMethods
      )
    }

    let recentExpenses: [ShareCardContent.ExpenseRow] = expenseTxs.prefix(6).map { tx in
      let payerName =
        tx.payers.first.flatMap { membersById[$0.memberId]?.name } ?? ""
      return ShareCardContent.ExpenseRow(
        title: tx.description,
        payerName: payerName,
        amount: tx.amount
      )
    }

    let targetBreakdown: MemberDebtBreakdown? =
      if mode == .reminder, let selectedTargetMemberId {
        data.breakdowns?.breakdowns.first { $0.memberId == selectedTargetMemberId }
      } else {
        nil
      }

    let staticQR: String? = data.balances.transfers
      .flatMap(\.paymentMethods)
      .compactMap { method -> String? in
        if case .bank(let bank) = method {
          return bank.accountQrPayload
        }
        return nil
      }
      .first

    return ShareCardContent(
      mode: mode,
      groupName: data.group.name,
      periodLabel: periodLabel,
      dateRangeLabel: dateRangeLabel,
      totalExpense: totalExpense,
      expenseCount: expenseCount,
      balances: balanceRows,
      transfers: transferRows,
      includeExpenses: includeExpenses,
      recentExpenses: recentExpenses,
      targetBreakdown: targetBreakdown,
      customCaption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
      guestShareURL: guestLink?.active == true ? guestLink?.url : nil,
      summaryStaticQRPayload: staticQR
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
    exportedImage = renderImage()
  }

  @MainActor
  private func makeTransferablePNG() -> ShareCardPNG? {
    guard let image = exportedImage ?? renderImage(),
      let pngData = image.pngData()
    else { return nil }
    return ShareCardPNG(image: image, data: pngData)
  }

  private func savePNGToPhotos() async {
    saveErrorMessage = nil
    guard let png = makeTransferablePNG() else { return }
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
