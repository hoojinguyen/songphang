import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct OverviewView: View {
  private let model: OverviewModel
  private let user: User
  private let unreadNotificationCount: Int
  private let onOpenGroup: (ExpenseGroup.ID) -> Void
  private let onOpenBalances: ((ExpenseGroup.ID) -> Void)?
  private let onOpenTransaction: (ExpenseGroup.ID, LedgerTransaction.ID) -> Void
  private let onOpenPersonalLedger: () -> Void
  private let onOpenNotifications: (() -> Void)?
  private let onOpenAccount: () -> Void

  public init(
    model: OverviewModel,
    user: User,
    unreadNotificationCount: Int = 0,
    onOpenGroup: @escaping (ExpenseGroup.ID) -> Void,
    onOpenBalances: ((ExpenseGroup.ID) -> Void)? = nil,
    onOpenTransaction: @escaping (ExpenseGroup.ID, LedgerTransaction.ID) -> Void,
    onOpenPersonalLedger: @escaping () -> Void,
    onOpenNotifications: (() -> Void)? = nil,
    onOpenAccount: @escaping () -> Void
  ) {
    self.model = model
    self.user = user
    self.unreadNotificationCount = unreadNotificationCount
    self.onOpenGroup = onOpenGroup
    self.onOpenBalances = onOpenBalances
    self.onOpenTransaction = onOpenTransaction
    self.onOpenPersonalLedger = onOpenPersonalLedger
    self.onOpenNotifications = onOpenNotifications
    self.onOpenAccount = onOpenAccount
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        headerView

        switch model.overview {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 120)
        case .failed:
          LoadError(isRetrying: model.isRefreshing) {
            Task { await model.load() }
          }
        case .loaded(let summary):
          heroCard(summary)

          if !summary.pendingActions.isEmpty {
            pendingActionsSection(summary.pendingActions)
          }

          if !summary.groupBalances.isEmpty {
            groupBalancesSection(summary.groupBalances)
          }

          recentTransactionsSection
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .refreshable {
      await model.load()
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task {
      await model.load()
    }
  }

  private var headerView: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.t("groups.greeting", ["name": user.name]))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
        Text(L10n.tr("overview.title"))
          .font(Typography.pageTitle)
          .foregroundStyle(Tokens.ink)
      }
      Spacer()
      HStack(spacing: 8) {
        if let onOpenNotifications {
          NotificationBellButton(unreadCount: unreadNotificationCount, onOpen: onOpenNotifications)
        }
        Button(action: onOpenAccount) {
          MemberShapeView(
            shape: .circle,
            color: .mint,
            name: user.name,
            size: 52
          )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("account.title"))
      }
    }
  }

  private func heroCard(_ summary: OverviewSummary) -> some View {
    let isAllSettled =
      summary.netBalance.isZero && summary.totalOwedToMe.isZero && summary.totalIOwe.isZero

    return VStack(alignment: .leading, spacing: 12) {
      if isAllSettled {
        Text(L10n.tr("overview.allSettled"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
      } else {
        Text(L10n.tr("overview.netBalance"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)

        MoneyText(
          summary.netBalance,
          style: .signed,
          font: Typography.heroNumber,
          color: Tokens.ink
        )

        Divider()
          .background(Tokens.ink.opacity(0.15))

        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr("overview.totalOwedToMe"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            MoneyText(
              summary.totalOwedToMe,
              style: .full,
              font: Typography.sectionTitle,
              color: Tokens.ink
            )
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 4) {
            Text(L10n.tr("overview.totalIOwe"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            MoneyText(
              summary.totalIOwe,
              style: .full,
              font: Typography.sectionTitle,
              color: Tokens.ink
            )
          }
        }
      }
    }
    .padding(22)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.accent)
    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
  }

  private func pendingActionsSection(_ actions: [OverviewPendingAction]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("overview.pendingActions"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      ForEach(actions) { action in
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text(action.groupName)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            Spacer()
            MoneyText(action.amount, style: .full, font: Typography.subheadlineBold)
          }

          Text(action.description)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)

          let buttonTitle: String = {
            switch action.kind {
            case .settlementConfirmation:
              return L10n.tr("overview.confirmSettlement")
            case .expenseApproval:
              return L10n.tr("overview.approveExpense")
            case .unknown:
              return L10n.tr("groups.needsAction")
            }
          }()

          SPButton(buttonTitle, variant: .primary) {
            switch action.kind {
            case .settlementConfirmation:
              if let onOpenBalances {
                onOpenBalances(action.groupId)
              } else {
                onOpenGroup(action.groupId)
              }
            case .expenseApproval:
              if let txId = action.transactionId {
                onOpenTransaction(action.groupId, txId)
              } else {
                onOpenGroup(action.groupId)
              }
            case .unknown:
              onOpenGroup(action.groupId)
            }
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
    }
  }

  private func groupBalancesSection(_ balances: [OverviewGroupBalance]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("overview.groupBalances"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      ForEach(balances) { gb in
        Button {
          onOpenGroup(gb.groupId)
        } label: {
          HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 4) {
                ForEach(gb.previewMembers) { p in
                  MemberShapeView(
                    shape: p.shape,
                    color: p.color,
                    name: p.name,
                    size: 22
                  )
                }
                if gb.memberCount > 4 {
                  Text(L10n.t("groups.moreMembers", ["count": String(gb.memberCount - 4)]))
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.ink)
                }
              }

              Text(gb.groupName)
                .font(Typography.screenHeaderTitle)
                .foregroundStyle(Tokens.ink)
            }

            Spacer(minLength: 8)

            MoneyText(
              gb.myBalance,
              style: .signed,
              font: Typography.screenHeaderTitle,
              color: gb.myBalance.isPositive
                ? Tokens.credit
                : (gb.myBalance.isNegative ? Tokens.debt : Tokens.ink)
            )
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var recentTransactionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.tr("overview.recentTransactions"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
        Spacer()
      }

      if model.recentTransactions.isEmpty {
        Text(L10n.tr("overview.emptyTransactions"))
          .font(Typography.body)
          .foregroundStyle(Tokens.muted)
          .padding(.vertical, 8)
      } else {
        ForEach(model.recentTransactions) { tx in
          PersonalTransactionRowView(
            transaction: tx,
            verticalPadding: 12,
            cornerRadius: 20
          ) {
            onOpenTransaction(tx.groupId, tx.transactionId)
          }
        }
      }

      SPButton(
        L10n.tr("overview.viewAllTransactions"),
        variant: .surface,
        isFullWidth: true,
        action: onOpenPersonalLedger
      )
    }
  }
}

#if DEBUG
  #Preview("Overview") {
    let world = FakeWorld(preset: .tripStep4)
    OverviewView(
      model: OverviewModel(repository: FakeOverviewRepository(world: world)),
      user: PreviewSamples.user,
      onOpenGroup: { _ in },
      onOpenTransaction: { _, _ in },
      onOpenPersonalLedger: {},
      onOpenAccount: {}
    )
  }
#endif
