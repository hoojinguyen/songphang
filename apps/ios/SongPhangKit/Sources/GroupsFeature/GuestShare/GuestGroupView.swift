import DesignSystem
import Domain
public import SwiftUI
import UIKit

#if DEBUG
  import PreviewSupport
#endif

public struct GuestGroupView: View {
  @Bindable private var model: GuestGroupModel
  private let showsCloseButton: Bool
  private let onClose: () -> Void

  @State private var expandedTransferId: String?
  @State private var selectedBreakdownMemberId: Member.ID?
  @State private var selectedTransaction: GuestTransaction?

  public init(
    model: GuestGroupModel,
    showsCloseButton: Bool = false,
    onClose: @escaping () -> Void
  ) {
    self.model = model
    self.showsCloseButton = showsCloseButton
    self.onClose = onClose
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        topReadOnlyBanner

        if model.isNotFound {
          revokedCard
        } else {
          switch model.state {
          case .loading:
            LoadingSkeleton(rowCount: 4, rowHeight: 96)
          case .failed:
            LoadError {
              Task { await model.load() }
            }
          case .loaded(let snapshot):
            loadedContent(snapshot: snapshot)
          }
        }
      }
      .padding(20)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if showsCloseButton {
        ToolbarItem(placement: .cancellationAction) {
          SheetCloseButton(action: onClose)
        }
      }
    }
    .task {
      if model.state.value == nil {
        await model.load()
      }
    }
    .sheet(
      item: Binding<MemberDebtBreakdown?>(
        get: {
          guard let id = selectedBreakdownMemberId else { return nil }
          return model.state.value?.breakdowns.first { $0.memberId == id }
        },
        set: { selectedBreakdownMemberId = $0?.memberId }
      )
    ) { breakdown in
      if let snapshot = model.state.value {
        let hhBreakdown = snapshot.householdBreakdowns.first {
          $0.memberIds.contains(breakdown.memberId)
        }
        let transferIds = hhBreakdown.map { Set($0.memberIds) } ?? Set([breakdown.memberId])
        GuestBreakdownSheet(
          breakdown: breakdown,
          householdBreakdown: hhBreakdown,
          focusLabel: snapshot.resolvedFocus.label,
          transfers: snapshot.transfers.filter { transferIds.contains($0.fromMemberId) },
          members: snapshot.members,
          onDismiss: { selectedBreakdownMemberId = nil }
        )
      }
    }
    .sheet(item: $selectedTransaction) { tx in
      if let snapshot = model.state.value {
        GuestTransactionDetailSheet(
          transaction: tx,
          members: snapshot.members,
          loadAttachment: { id in
            try await model.loadAttachment(id: id)
          },
          onDismiss: { selectedTransaction = nil }
        )
      }
    }
  }

  private var topReadOnlyBanner: some View {
    HStack(spacing: 8) {
      Text(L10n.tr("guestLink.readonlyBadge"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.onAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Tokens.accent, in: Capsule())
      Spacer()
    }
  }

  private var revokedCard: some View {
    SPCard(padding: 20) {
      VStack(alignment: .leading, spacing: 14) {
        Text(L10n.tr("guestLink.invalidOrRevoked"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        SPButton(
          showsCloseButton ? L10n.tr("ios.common.close") : L10n.tr("common.back"),
          variant: .primary,
          isFullWidth: true,
          action: onClose
        )
      }
    }
  }

  @ViewBuilder
  private func loadedContent(snapshot: GuestGroupSnapshot) -> some View {
    Text(snapshot.group.name)
      .font(Typography.pageTitle)
      .foregroundStyle(Tokens.ink)

    if model.refreshError != nil {
      SPCard(padding: 12) {
        HStack(spacing: 12) {
          Text(L10n.tr("common.loadError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
          Spacer()
          SPButton(L10n.tr("common.retry"), variant: .surface, size: .md) {
            Task { await model.load() }
          }
        }
      }
    }

    if snapshot.group.archivedAt != nil {
      Text(L10n.tr("groups.archivedBanner"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Tokens.surface, in: Capsule())
    }

    if !snapshot.cycles.isEmpty {
      cyclePicker(snapshot: snapshot)
    }

    if let fund = snapshot.fund {
      SPCard(padding: 16) {
        HStack {
          Text(fund.name)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Spacer()
          MoneyText(
            fund.cash,
            style: .full,
            font: Typography.bodyBold,
            color: fund.cash.isNegative ? Tokens.debt : Tokens.credit
          )
        }
      }
    }

    transfersSection(snapshot: snapshot)
    balancesSection(snapshot: snapshot)
    transactionsSection(snapshot: snapshot)
  }

  private func cyclePicker(snapshot: GuestGroupSnapshot) -> some View {
    Menu {
      Button {
        Task { await model.selectCycle(.current) }
      } label: {
        Label(
          "\(L10n.tr("cycles.currentPeriod")) (\(snapshot.currentPeriod.expenseCount))",
          systemImage: snapshot.selectedCycleId == .current ? "checkmark" : ""
        )
      }
      Divider()
      ForEach(snapshot.cycles) { cycle in
        Button {
          Task { await model.selectCycle(.cycle(cycle.id)) }
        } label: {
          Label(
            cycle.title,
            systemImage: snapshot.selectedCycleId == .cycle(cycle.id) ? "checkmark" : ""
          )
        }
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "calendar")
          .spIconFont(size: 12, weight: .semibold, relativeTo: .caption)
          .accessibilityHidden(true)
        Text(snapshot.resolvedFocus.label)
          .font(Typography.captionBold)
        Image(systemName: "chevron.down")
          .spIconFont(size: 10, weight: .bold, relativeTo: .caption2)
          .accessibilityHidden(true)
      }
      .foregroundStyle(Tokens.ink)
      .padding(.horizontal, 12)
      .frame(minHeight: 38)
      .background(Tokens.surface, in: Capsule())
    }
  }

  private func transfersSection(snapshot: GuestGroupSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("balances.subTabs.toPay"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      if snapshot.transfers.isEmpty {
        SPCard {
          Text(L10n.tr("feed.settled"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.credit)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      } else {
        ForEach(snapshot.transfers) { transfer in
          transferCard(transfer, snapshot: snapshot)
        }
      }
    }
  }

  private func transferCard(_ transfer: GuestTransfer, snapshot: GuestGroupSnapshot) -> some View {
    let from = snapshot.members.first(where: { $0.id == transfer.fromMemberId })
    let to = snapshot.members.first(where: { $0.id == transfer.toMemberId })
    let isExpanded = expandedTransferId == transfer.id

    return SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 10) {
          if let from {
            MemberShapeView(
              shape: from.shape,
              color: from.color,
              name: from.name,
              size: 32
            )
          }
          VStack(alignment: .leading, spacing: 2) {
            let fromLabel: String = {
              let name = from?.name ?? ""
              if let hh = transfer.fromHousehold {
                return "\(name) (\(L10n.t("households.representativeBadge", ["name": hh.name])))"
              }
              return name
            }()
            let toLabel: String = {
              let name = to?.name ?? ""
              if let hh = transfer.toHousehold {
                return "\(name) (\(L10n.t("households.representativeBadge", ["name": hh.name])))"
              }
              return name
            }()
            Text("\(fromLabel) → \(toLabel)")
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
            if snapshot.breakdowns.contains(where: { $0.memberId == transfer.fromMemberId }) {
              Button(L10n.tr("breakdown.viewAction")) {
                selectedBreakdownMemberId = transfer.fromMemberId
              }
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
              .buttonStyle(.plain)
            }
          }
          Spacer(minLength: 8)
          MoneyText(
            transfer.amount,
            style: .full,
            font: Typography.bodyBold,
            color: Tokens.ink
          )
        }

        if !transfer.paymentMethods.isEmpty {
          Button(isExpanded ? L10n.tr("pay.hideDetails") : L10n.tr("pay.showDetails")) {
            expandedTransferId = isExpanded ? nil : transfer.id
          }
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .buttonStyle(.plain)
        }

        if isExpanded {
          paymentDetailsBlock(transfer: transfer)
        }
      }
    }
  }

  private func paymentDetailsBlock(transfer: GuestTransfer) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Array(transfer.paymentMethods.enumerated()), id: \.offset) { _, method in
        switch method {
        case .bank(let bank):
          VStack(alignment: .leading, spacing: 8) {
            if let qrPayload = bank.qrPayload ?? bank.accountQrPayload {
              HStack {
                Spacer()
                QRCodeMatrixView(payload: qrPayload, size: 140, accessibilityLabel: bank.name)
                Spacer()
              }
            }
            Text("\(bank.name) · \(bank.accountName)")
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            copyableRow(
              id: "bank-\(transfer.id)-\(bank.accountNumber)",
              label: L10n.tr("payment.accountNumber"),
              value: bank.accountNumber
            )
          }
        case .momo(let phone):
          copyableRow(
            id: "momo-\(transfer.id)-\(phone)",
            label: L10n.tr("payment.momo"),
            value: L10n.t("pay.momoRow", ["phone": phone])
          )
        case .zalopay(let phone):
          copyableRow(
            id: "zalopay-\(transfer.id)-\(phone)",
            label: L10n.tr("payment.zalopay"),
            value: L10n.t("pay.zalopayRow", ["phone": phone])
          )
        }
      }

      copyableRow(
        id: "purpose-\(transfer.id)",
        label: L10n.tr("pay.purpose"),
        value: transfer.purpose
      )
    }
    .padding(12)
    .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func copyableRow(id: String, label: String, value: String) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Text(value)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }
      Spacer(minLength: 8)
      CopyButton(
        value: value,
        label: L10n.tr("pay.copy"),
        accessibilityLabel: "\(L10n.tr("pay.copy")) \(label)"
      )
    }
  }

  private func balancesSection(snapshot: GuestGroupSnapshot) -> some View {
    let ordered = snapshot.balances.sorted { $0.balance > $1.balance }
    return VStack(alignment: .leading, spacing: 14) {
      if !snapshot.households.isEmpty {
        SPCard(padding: 16) {
          VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("households.byHouseholdTitle"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)
            ForEach(snapshot.households) { hh in
              let repName =
                snapshot.members.first(where: { $0.id == hh.representativeMemberId })?.name ?? ""
              Button {
                selectedBreakdownMemberId = hh.representativeMemberId
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(hh.name)
                      .font(Typography.captionBold)
                      .foregroundStyle(Tokens.ink)
                    if !repName.isEmpty {
                      Text(L10n.t("households.representativeBadge", ["name": repName]))
                        .font(Typography.caption)
                        .foregroundStyle(Tokens.muted)
                    }
                  }
                  Spacer()
                  MoneyText(
                    hh.netBalance,
                    style: .signed,
                    font: Typography.captionBold,
                    color: hh.netBalance.isPositive
                      ? Tokens.credit
                      : (hh.netBalance.isNegative ? Tokens.debt : Tokens.ink)
                  )
                }
              }
              .buttonStyle(.plain)
            }
          }
        }
      }

      SPCard(padding: 16) {
        VStack(alignment: .leading, spacing: 12) {
          Text(L10n.tr("balances.groupBalanceTitle"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          ForEach(ordered) { item in
            if let member = snapshot.members.first(where: { $0.id == item.memberId }),
              member.active || !item.balance.isZero
            {
              Button {
                selectedBreakdownMemberId = member.id
              } label: {
                HStack {
                  MemberShapeView(
                    shape: member.shape,
                    color: member.color,
                    name: member.name,
                    size: 28
                  )
                  Text(member.name)
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.ink)
                  Spacer()
                  MoneyText(
                    item.balance,
                    style: .signed,
                    font: Typography.captionBold,
                    color: item.balance.isPositive
                      ? Tokens.credit
                      : (item.balance.isNegative ? Tokens.debt : Tokens.ink)
                  )
                }
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }

  private func transactionsSection(snapshot: GuestGroupSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("groupSegments.expenses"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      if snapshot.transactions.items.isEmpty {
        SPCard {
          Text(L10n.tr("feed.emptyTitle"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      } else {
        ForEach(snapshot.transactions.items) { tx in
          Button {
            selectedTransaction = tx
          } label: {
            SPCard(padding: 14) {
              HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                  Text(tx.description)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(Tokens.ink)
                    .lineLimit(1)
                  HStack(spacing: 6) {
                    Text(DayLabelFormat.dayLabel(for: tx.occurredAt))
                      .font(Typography.caption)
                      .foregroundStyle(Tokens.muted)
                    if let channel = tx.paymentChannel {
                      PaymentChannelBadge(channel)
                    }
                    if !tx.attachments.isEmpty {
                      Image(systemName: "photo")
                        .spIconFont(size: 11, weight: .semibold, relativeTo: .caption2)
                        .foregroundStyle(Tokens.muted)
                    }
                  }
                }
                Spacer(minLength: 8)
                MoneyText(
                  tx.amount,
                  style: .full,
                  font: Typography.subheadlineBold,
                  color: Tokens.ink
                )
              }
            }
          }
          .buttonStyle(.plain)
        }

        if snapshot.transactions.nextCursor != nil {
          SPButton(
            L10n.tr("notifications.loadMore"),
            variant: .surface,
            isFullWidth: true,
            isPending: model.isLoadingMore
          ) {
            Task { await model.loadMoreIfNeeded() }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Guest Group Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    GuestGroupView(
      model: GuestGroupModel(
        token: "preview-guest-token-0123456789abcdef",
        guestLinksRepository: FakeGuestLinksRepository(world: world)
      ),
      onClose: {}
    )
  }

  #Preview("Guest Group Revoked") {
    let world = FakeWorld(preset: .tripStep4)
    GuestGroupView(
      model: GuestGroupModel(
        token: "revoked-token",
        guestLinksRepository: FakeGuestLinksRepository(world: world)
      ),
      onClose: {}
    )
  }
#endif
