import DesignSystem
import Domain
import Foundation
import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

struct SettlementVaultSectionView: View {
  private let page: SettlementVaultPage?
  private let selectedFilter: SettlementVaultFilter
  private let members: [Member]
  private let isLoading: Bool
  private let isLoadingMore: Bool
  private let errorMessage: String?
  private let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  private let onSelectFilter: (SettlementVaultFilter) -> Void
  private let onLoadMore: () -> Void
  private let onOpenTransaction: ((LedgerTransaction.ID) -> Void)?

  init(
    page: SettlementVaultPage?,
    selectedFilter: SettlementVaultFilter,
    members: [Member],
    isLoading: Bool = false,
    isLoadingMore: Bool = false,
    errorMessage: String? = nil,
    loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)? = nil,
    onSelectFilter: @escaping (SettlementVaultFilter) -> Void,
    onLoadMore: @escaping () -> Void = {},
    onOpenTransaction: ((LedgerTransaction.ID) -> Void)? = nil
  ) {
    self.page = page
    self.selectedFilter = selectedFilter
    self.members = members
    self.isLoading = isLoading
    self.isLoadingMore = isLoadingMore
    self.errorMessage = errorMessage
    self.loadAttachment = loadAttachment
    self.onSelectFilter = onSelectFilter
    self.onLoadMore = onLoadMore
    self.onOpenTransaction = onOpenTransaction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let summary = page?.summary {
        summaryStrip(summary)
      }

      filterChips

      if let errorMessage {
        Text(errorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
      }

      if isLoading {
        LoadingSkeleton(rowCount: 3, rowHeight: 84)
      } else if let items = page?.items, !items.isEmpty {
        LazyVStack(spacing: 12) {
          ForEach(items) { item in
            vaultRow(item)
          }
        }

        if page?.nextCursor != nil {
          SPButton(
            L10n.tr("notifications.loadMore"),
            variant: .surface,
            isFullWidth: true,
            isPending: isLoadingMore,
            action: onLoadMore
          )
        }
      } else {
        SPCard {
          Text(L10n.tr("vault.empty"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        }
      }
    }
  }

  private func summaryStrip(_ summary: SettlementVaultSummary) -> some View {
    SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text(L10n.tr("vault.confirmedTotal"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
          Spacer()
          MoneyText(
            summary.confirmedTotalAmount,
            style: .full,
            font: Typography.bodyBold,
            color: Tokens.credit
          )
        }
        HStack(spacing: 12) {
          summaryPill(
            title: L10n.tr("vault.statusPending"),
            count: summary.pendingCount,
            fg: Tokens.warning,
            bg: Tokens.warningSoft
          )
          summaryPill(
            title: L10n.tr("settlementProof.hasProof"),
            count: summary.proofCount,
            fg: Tokens.ink,
            bg: Tokens.sunken
          )
        }
      }
    }
  }

  private func summaryPill(title: String, count: Int, fg: Color, bg: Color) -> some View {
    HStack(spacing: 6) {
      Text(title)
        .font(Typography.caption)
        .foregroundStyle(fg)
      Text("\(count)")
        .font(Typography.captionBold)
        .foregroundStyle(fg)
        .monospacedDigit()
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(bg, in: Capsule())
  }

  private var filterChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(SettlementVaultFilter.allCases, id: \.self) { filter in
          let isSelected = selectedFilter == filter
          Button {
            onSelectFilter(filter)
          } label: {
            Text(filterLabel(filter))
              .font(Typography.captionBold)
              .foregroundStyle(isSelected ? Tokens.onInk : Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(
                isSelected ? Tokens.ink : Tokens.surface,
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
    }
    .spFeedback(.selection, trigger: selectedFilter)
  }

  private func vaultRow(_ item: SettlementVaultItem) -> some View {
    let fromMember = members.first(where: { $0.id == item.fromMemberId })
    let toMember = members.first(where: { $0.id == item.toMemberId })
    let title = "\(fromMember?.name ?? "—") → \(toMember?.name ?? "—")"
    let canOpenTx =
      item.status == .confirmed && item.transactionId != nil && onOpenTransaction != nil

    let headerRow = HStack(spacing: 10) {
      if let fromMember {
        MemberShapeView(
          shape: fromMember.shape,
          color: fromMember.color,
          name: fromMember.name,
          size: 28,
          showInitial: false
        )
      }
      Image(systemName: "arrow.right")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Tokens.muted)
      if let toMember {
        MemberShapeView(
          shape: toMember.shape,
          color: toMember.color,
          name: toMember.name,
          size: 28,
          showInitial: false
        )
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .lineLimit(1)
        Text(LedgerDateLabels.dayLabel(for: item.occurredAt))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }

      Spacer(minLength: 8)

      MoneyText(
        item.amount,
        style: .full,
        font: Typography.subheadlineBold,
        color: Tokens.ink
      )
    }

    return SPCard(padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        if canOpenTx, let txId = item.transactionId {
          Button {
            onOpenTransaction?(txId)
          } label: {
            headerRow
          }
          .buttonStyle(.plain)
        } else {
          headerRow
        }

        HStack(alignment: .center, spacing: 8) {
          statusBadge(item.status)

          if let channel = item.channel {
            PaymentChannelBadge(channel)
          }

          if let note = item.note, !note.isEmpty {
            Text("“\(note)”")
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
              .lineLimit(2)
          }

          Spacer(minLength: 4)

          if !item.attachments.isEmpty {
            HStack(spacing: 6) {
              ForEach(item.attachments) { att in
                if let loadAttachment {
                  RemoteAttachmentThumbnail(
                    attachmentId: att.id,
                    size: 44,
                    cornerRadius: 12,
                    loadContent: loadAttachment
                  )
                  .accessibilityLabel(L10n.tr("settlementProof.viewProof"))
                } else {
                  ProofBadgeView(attachmentId: nil)
                }
              }
            }
          }
        }
      }
    }
  }

  private func statusBadge(_ status: SettlementRequestStatus) -> some View {
    let style: (label: String, fg: Color, bg: Color) = {
      switch status {
      case .pending:
        return (L10n.tr("vault.statusPending"), Tokens.warning, Tokens.warningSoft)
      case .confirmed:
        return (L10n.tr("vault.statusConfirmed"), Tokens.credit, Tokens.creditSoft)
      case .rejected:
        return (L10n.tr("vault.statusRejected"), Tokens.muted, Tokens.sunken)
      case .cancelled:
        return (L10n.tr("vault.statusCancelled"), Tokens.muted, Tokens.sunken)
      case .unknown(let raw):
        return (raw, Tokens.muted, Tokens.sunken)
      }
    }()
    return Text(style.label)
      .font(Typography.captionBold)
      .foregroundStyle(style.fg)
      .padding(.horizontal, 9)
      .padding(.vertical, 3)
      .background(style.bg, in: Capsule())
  }

  private func filterLabel(_ filter: SettlementVaultFilter) -> String {
    switch filter {
    case .all: return L10n.tr("vault.filterAll")
    case .pending: return L10n.tr("vault.statusPending")
    case .confirmed: return L10n.tr("vault.statusConfirmed")
    case .withProof: return L10n.tr("settlementProof.hasProof")
    }
  }
}

#if DEBUG
  #Preview("Vault Loaded") {
    let samplePage = SettlementVaultPage(
      items: [
        SettlementVaultItem(
          id: "vault-1",
          kind: .request,
          status: .pending,
          fromMemberId: TripScenario.lanId,
          toMemberId: TripScenario.minhId,
          amount: Money(120_000),
          channel: .bank,
          note: "Chuyển khoản VCB",
          occurredAt: "2026-11-25T10:00:00.000Z"
        ),
        SettlementVaultItem(
          id: "vault-2",
          kind: .transfer,
          status: .confirmed,
          transactionId: LedgerTransaction.ID("tx-1"),
          fromMemberId: TripScenario.thuId,
          toMemberId: TripScenario.minhId,
          amount: Money(210_000),
          channel: .momo,
          note: "Gửi tiền sân",
          occurredAt: "2026-11-24T18:00:00.000Z"
        ),
      ],
      summary: SettlementVaultSummary(
        pendingCount: 1,
        confirmedCount: 1,
        confirmedTotalAmount: Money(210_000),
        proofCount: 0
      )
    )
    ScrollView {
      SettlementVaultSectionView(
        page: samplePage,
        selectedFilter: .all,
        members: TripScenario.members,
        onSelectFilter: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }

  #Preview("Vault Empty") {
    ScrollView {
      SettlementVaultSectionView(
        page: SettlementVaultPage(
          items: [],
          summary: SettlementVaultSummary(
            pendingCount: 0,
            confirmedCount: 0,
            confirmedTotalAmount: .zero,
            proofCount: 0
          )
        ),
        selectedFilter: .all,
        members: TripScenario.members,
        onSelectFilter: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }
#endif
