import DesignSystem
public import Domain
public import Foundation
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct BalancesView: View {
  @Bindable private var model: BalancesModel
  private let showHeader: Bool
  private let currentUserId: User.ID?
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onBackToGroups: () -> Void
  private let onOpenPay: ((SuggestedTransfer, Member, Member) -> Void)?
  private let onOpenSettle: (SuggestedTransfer) -> Void
  private let onOpenFund: ((ExpenseGroup.ID) -> Void)?
  private let onCreateFund: (() -> Void)?
  private let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  private let onOpenShareCard: (() -> Void)?
  private let onOpenGuestLink: (() -> Void)?
  private let onOpenTransaction: ((LedgerTransaction.ID) -> Void)?
  private let onViewCycleExpenses: ((SettlementCycle.ID) -> Void)?

  @State private var isCloseCycleSheetOpen = false
  @State private var selectedBreakdownMemberId: Member.ID?
  @State private var subTabTapTick = 0
  @Namespace private var subTabNamespace

  public init(
    model: BalancesModel,
    showHeader: Bool = true,
    currentUserId: User.ID? = nil,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onBackToGroups: @escaping () -> Void,
    onOpenPay: ((SuggestedTransfer, Member, Member) -> Void)? = nil,
    onOpenSettle: @escaping (SuggestedTransfer) -> Void,
    onOpenFund: ((ExpenseGroup.ID) -> Void)? = nil,
    onCreateFund: (() -> Void)? = nil,
    loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)? = nil,
    onOpenShareCard: (() -> Void)? = nil,
    onOpenGuestLink: (() -> Void)? = nil,
    onOpenTransaction: ((LedgerTransaction.ID) -> Void)? = nil,
    onViewCycleExpenses: ((SettlementCycle.ID) -> Void)? = nil
  ) {
    self.model = model
    self.showHeader = showHeader
    self.currentUserId = currentUserId
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onBackToGroups = onBackToGroups
    self.onOpenPay = onOpenPay
    self.onOpenSettle = onOpenSettle
    self.onOpenFund = onOpenFund
    self.onCreateFund = onCreateFund
    self.loadAttachment = loadAttachment
    self.onOpenShareCard = onOpenShareCard
    self.onOpenGuestLink = onOpenGuestLink
    self.onOpenTransaction = onOpenTransaction
    self.onViewCycleExpenses = onViewCycleExpenses
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if model.refreshError != nil {
            OfflineBanner()
          }

          if model.isNotFound {
            VStack(spacing: 16) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
              SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBackToGroups)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 64)
          } else {
            switch model.state {
            case .loading:
              VStack(spacing: 16) {
                BalanceCardSkeleton()
                SkeletonBar(height: 44, cornerRadius: 22)
                  .spSkeletonShimmer()
                MemberRowSkeleton()
                MemberRowSkeleton()
                MemberRowSkeleton()
              }

            case .failed:
              LoadError {
                Task { await model.load() }
              }

            case .loaded(let data):
              loadedContent(data: data)
            }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .modifier(
        ConditionalBalancesNavBar(
          isEnabled: showHeader,
          title: model.state.value?.group.name ?? ""
        )
      )
      .task {
        if model.state.value == nil {
          await model.load()
        }
        #if DEBUG
          let args = ProcessInfo.processInfo.arguments
          if args.contains("--balances-subtab-vault") {
            model.selectedSubTab = .vault
          } else if args.contains("--balances-subtab-cycles") {
            model.selectedSubTab = .cycles
          }
          if args.contains("--open-breakdown"),
            let firstDebtor = model.state.value?.balances.transfers.first?.fromMemberId
              ?? model.state.value?.breakdowns?.breakdowns.first?.memberId
          {
            selectedBreakdownMemberId = firstDebtor
          }
          if args.contains("--open-close-cycle") {
            isCloseCycleSheetOpen = true
          }
          if args.contains("--exercise-all-settled") {
            model.triggerAllSettledCelebrationForExercise()
          }
        #endif
        if ProcessInfo.processInfo.arguments.contains("--scroll-bars") {
          proxy.scrollTo("balance-bars", anchor: .bottom)
        }
      }
      .task {
        await model.listenForEvents(onRemoved: onBackToGroups)
      }
      .sheet(isPresented: $isCloseCycleSheetOpen) {
        if let data = model.state.value, let overview = data.cyclesOverview {
          CloseCycleSheetView(
            currentPeriod: overview.currentPeriod,
            nextCycleNumber: (overview.cycles.first?.cycleNumber ?? 0) + 1,
            isClosing: model.isClosingCycle,
            errorMessage: model.cycleErrorMessage,
            onConfirm: { title in
              let closed = await model.closeCycle(title: title)
              if closed {
                isCloseCycleSheetOpen = false
                model.selectedSubTab = .cycles
              }
            },
            onDismiss: { isCloseCycleSheetOpen = false }
          )
        }
      }
      .sheet(
        item: Binding<MemberDebtBreakdown?>(
          get: {
            guard let memberId = selectedBreakdownMemberId else { return nil }
            return model.state.value?.breakdowns?.breakdowns.first { $0.memberId == memberId }
          },
          set: { next in
            selectedBreakdownMemberId = next?.memberId
          }
        )
      ) { breakdown in
        if let data = model.state.value, let result = data.breakdowns {
          let hhBreakdown = result.householdBreakdowns.first {
            $0.memberIds.contains(breakdown.memberId)
          }
          let transferMemberIds =
            hhBreakdown.map { Set($0.memberIds) } ?? Set([breakdown.memberId])
          MemberBreakdownSheetView(
            breakdown: breakdown,
            householdBreakdown: hhBreakdown,
            focusLabel: result.resolvedFocus.label,
            memberTransfers: data.balances.transfers.filter {
              transferMemberIds.contains($0.fromMemberId)
            },
            members: data.members,
            onDismiss: { selectedBreakdownMemberId = nil }
          )
        }
      }
    }
  }

  @ViewBuilder
  private func loadedContent(data: BalancesViewData) -> some View {
    if let noticeText = model.reminderNotice ?? noticeMessage {
      SPCard(tone: .accent, padding: 14) {
        Text(noticeText)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.onAccent)
      }
    }

    if let pendingLoadError = model.pendingLoadError {
      Text(pendingLoadError)
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.debt)
    }

    if let error = model.settlementError {
      Text(errorMessage(for: error))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
    }

    let hasTransactions = !data.transactions.isEmpty
    let myMemberId = data.group.myMemberId
    let sortedTransfers = data.balances.transfers.sorted { first, second in
      let firstInvolvesMe = isTransferOnMySide(first, myMemberId: myMemberId)
      let secondInvolvesMe = isTransferOnMySide(second, myMemberId: myMemberId)
      if firstInvolvesMe == secondInvolvesMe { return false }
      return firstInvolvesMe && !secondInvolvesMe
    }
    let ownTransfers = sortedTransfers.filter {
      isFromMySide($0, myMemberId: myMemberId)
    }
    let otherTransfers = sortedTransfers.filter {
      !isFromMySide($0, myMemberId: myMemberId)
    }
    let isOffline = model.refreshError == .offline
    let canWrite = isEmailVerified && data.group.role.canWrite && !isOffline

    let matchedPendingIds = Set(sortedTransfers.compactMap { $0.pendingSettlement?.id })
    let unmatchedPending = data.pendingRequests.filter {
      $0.status == .pending && !matchedPendingIds.contains($0.id)
    }

    if let fund = data.balances.fund {
      FundBlockView(fund: fund, members: data.members) {
        onOpenFund?(model.groupId)
      }
    } else if canWrite, let onCreateFund {
      SPButton(
        L10n.tr("fund.createEntry"),
        variant: .surface,
        isFullWidth: true,
        action: onCreateFund
      )
    }

    subTabBar(data: data)

    switch model.selectedSubTab {
    case .toPay:
      toPayTabContent(
        data: data,
        hasTransactions: hasTransactions,
        myMemberId: myMemberId,
        sortedTransfers: sortedTransfers,
        ownTransfers: ownTransfers,
        otherTransfers: otherTransfers,
        unmatchedPending: unmatchedPending,
        isOffline: isOffline,
        canWrite: canWrite
      )
    case .vault:
      SettlementVaultSectionView(
        page: data.vault,
        selectedFilter: model.vaultFilter,
        members: data.members,
        isLoading: model.isLoadingVault,
        isLoadingMore: model.isLoadingMoreVault,
        errorMessage: model.vaultError,
        loadAttachment: loadAttachment,
        onSelectFilter: { next in
          Task { await model.selectVaultFilter(next) }
        },
        onLoadMore: {
          Task { await model.loadMoreVaultIfNeeded() }
        },
        onOpenTransaction: onOpenTransaction
      )
    case .cycles:
      SettlementCyclesSectionView(
        overview: data.cyclesOverview,
        isOwner: data.group.role.isOwner,
        isArchived: data.group.isArchived,
        isOffline: isOffline,
        isReopening: model.isReopeningCycle,
        errorMessage: model.cycleErrorMessage,
        onViewCycleExpenses: onViewCycleExpenses,
        onReopenLatest: { cycleId in
          Task { await model.reopenLatestCycle(cycleId) }
        }
      )
    }
  }

  @ViewBuilder
  private func subTabBar(data: BalancesViewData) -> some View {
    let pendingCount = data.vault?.summary.pendingCount ?? 0
    let cycleCount = data.cyclesOverview?.cycles.count ?? 0
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        subTabPill(
          tab: .toPay,
          title: L10n.tr("balances.subTabs.toPay"),
          badge: nil,
          isSelected: model.selectedSubTab == .toPay
        ) {
          subTabTapTick &+= 1
          model.selectedSubTab = .toPay
        }
        subTabPill(
          tab: .vault,
          title: L10n.tr("balances.subTabs.vault"),
          badge: pendingCount > 0 ? pendingCount : nil,
          isSelected: model.selectedSubTab == .vault
        ) {
          subTabTapTick &+= 1
          model.selectedSubTab = .vault
        }
        subTabPill(
          tab: .cycles,
          title: L10n.tr("balances.subTabs.cycles"),
          badge: cycleCount > 0 ? cycleCount : nil,
          isSelected: model.selectedSubTab == .cycles
        ) {
          subTabTapTick &+= 1
          model.selectedSubTab = .cycles
        }
      }
      .padding(4)
      .background(Tokens.surface, in: Capsule())
      .spAnimation(Motion.quick, value: model.selectedSubTab)
      .spFeedback(.selection, trigger: subTabTapTick)
    }
  }

  private func subTabPill(
    tab: BalancesSubTab,
    title: String,
    badge: Int?,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Text(title)
          .font(Typography.captionBold)
          .foregroundStyle(isSelected ? Tokens.onInk : Tokens.ink)
        if let badge {
          Text("\(badge)")
            .font(Typography.captionBold)
            .foregroundStyle(isSelected ? Tokens.onAccent : Tokens.onInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isSelected ? Tokens.accent : Tokens.ink, in: Capsule())
        }
      }
      .padding(.horizontal, 14)
      .frame(minHeight: 40)
      .background {
        if isSelected {
          Capsule()
            .fill(Tokens.ink)
            .matchedGeometryEffect(id: "balancesSubTabPill", in: subTabNamespace)
        }
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func toPayTabContent(
    data: BalancesViewData,
    hasTransactions: Bool,
    myMemberId: Member.ID?,
    sortedTransfers: [SuggestedTransfer],
    ownTransfers: [SuggestedTransfer],
    otherTransfers: [SuggestedTransfer],
    unmatchedPending: [SettlementRequest],
    isOffline: Bool,
    canWrite: Bool
  ) -> some View {
    if let myMemberId,
      let myBalance = data.balances.balances.first(where: { $0.memberId == myMemberId })
    {
      let myHousehold = data.balances.households.first(where: {
        $0.memberIds.contains(myMemberId)
      })
      let repName = myHousehold.flatMap { hh in
        data.members.first(where: { $0.id == hh.representativeMemberId })?.name
      }
      personalNetHeroCard(
        balance: myHousehold?.netBalance ?? myBalance.balance,
        individualBalance: myHousehold != nil ? myBalance.balance : nil,
        householdName: myHousehold?.name,
        settledThroughName: (myHousehold?.representativeMemberId != myMemberId) ? repName : nil,
        canViewBreakdown: data.breakdowns?.breakdowns.contains(where: { $0.memberId == myMemberId })
          == true,
        onViewBreakdown: { selectedBreakdownMemberId = myMemberId }
      )
    }

    quickActionBar(data: data, isOffline: isOffline)

    #if DEBUG
      let forceAllSettled = ProcessInfo.processInfo.arguments.contains("--exercise-all-settled")
    #else
      let forceAllSettled = false
    #endif
    if !hasTransactions {
      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("balances.emptyTitle"))
          .font(Typography.pageTitle)
          .foregroundStyle(Tokens.ink)
        Text(L10n.tr("balances.emptyHint"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)
      }
      .padding(.vertical, 48)
    } else if sortedTransfers.isEmpty || forceAllSettled {
      AllSettledSection(
        recorded: data.transactions.filter { $0.type == .transfer },
        members: data.members,
        myMemberId: myMemberId,
        celebrationTick: model.allSettledCelebrationTick,
        onBackToGroup: onBack
      )
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text(
          L10n.t(
            ownTransfers.isEmpty ? "balances.headline" : "balances.youPayHeadline",
            [
              "count": String(
                ownTransfers.isEmpty ? sortedTransfers.count : ownTransfers.count
              )
            ]
          )
        )
        .font(Typography.pageTitle)
        .foregroundStyle(Tokens.ink)

        Text(
          ownTransfers.isEmpty
            ? (data.balances.minimized
              ? L10n.tr("balances.collectHint")
              : L10n.tr("balances.pairwiseHint"))
            : L10n.tr("balances.youPayHint")
        )
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.muted)
      }

      let remindableCount = sortedTransfers.filter { transfer in
        guard let from = data.members.first(where: { $0.id == transfer.fromMemberId }),
          let to = data.members.first(where: { $0.id == transfer.toMemberId })
        else { return false }
        return canRemindTransfer(
          transfer: transfer,
          from: from,
          to: to,
          myMemberId: myMemberId,
          role: data.group.role,
          verified: isEmailVerified
        )
      }.count

      if remindableCount >= 2 {
        SPButton(
          L10n.tr("reminders.remindAll"),
          variant: .surface,
          size: .md,
          isFullWidth: true,
          isDisabled: isOffline || !model.hasCurrentPaymentDetails,
          isPending: model.isSendingReminder
        ) {
          Task { await model.sendAllReminders() }
        }
      }

      let hasBreakdowns = data.breakdowns != nil
      let inspectBreakdown: ((Member.ID) -> Void)? =
        hasBreakdowns ? { memberId in selectedBreakdownMemberId = memberId } : nil

      if !ownTransfers.isEmpty {
        ForEach(ownTransfers) { transfer in
          OwnSettlementCardView(
            transfer: transfer,
            members: data.members,
            group: data.group,
            isEmailVerified: isEmailVerified,
            isOffline: isOffline,
            canOpenAction: !isOffline
              && (onOpenPay != nil ? model.hasCurrentPaymentDetails : canWrite),
            opensPay: onOpenPay != nil,
            isResolvingSettlement: model.isResolvingSettlement,
            loadAttachment: loadAttachment,
            onSettle: { openTransfer(transfer, members: data.members) },
            onResolvePending: { pending, fromName, decision in
              Task {
                await model.resolveSettlement(
                  requestId: pending.id,
                  amount: pending.amount,
                  fromName: fromName,
                  decision: decision
                )
              }
            },
            onInspectBreakdown: inspectBreakdown
          )
        }
        if !otherTransfers.isEmpty {
          OtherSettlementsSection(
            transfers: otherTransfers,
            members: data.members,
            group: data.group,
            isEmailVerified: isEmailVerified,
            isOffline: isOffline,
            canOpenAction: !isOffline
              && (onOpenPay != nil ? model.hasCurrentPaymentDetails : canWrite),
            opensPay: onOpenPay != nil,
            isResolvingSettlement: model.isResolvingSettlement,
            hasCurrentPaymentDetails: model.hasCurrentPaymentDetails,
            isSendingReminder: model.isSendingReminder,
            loadAttachment: loadAttachment,
            onSettle: { openTransfer($0, members: data.members) },
            onResolvePending: { pending, fromName, decision in
              Task {
                await model.resolveSettlement(
                  requestId: pending.id,
                  amount: pending.amount,
                  fromName: fromName,
                  decision: decision
                )
              }
            },
            onRemind: { from, to in
              Task { await model.sendReminder(fromMember: from, toMember: to) }
            },
            onInspectBreakdown: inspectBreakdown
          )
        }
      } else {
        ForEach(sortedTransfers) { transfer in
          SettlementCardView(
            transfer: transfer,
            members: data.members,
            group: data.group,
            isEmailVerified: isEmailVerified,
            isOffline: isOffline,
            canOpenAction: !isOffline
              && (onOpenPay != nil ? model.hasCurrentPaymentDetails : canWrite),
            opensPay: onOpenPay != nil,
            isResolvingSettlement: model.isResolvingSettlement,
            hasCurrentPaymentDetails: model.hasCurrentPaymentDetails,
            isSendingReminder: model.isSendingReminder,
            loadAttachment: loadAttachment,
            onSettle: { openTransfer(transfer, members: data.members) },
            onResolvePending: { pending, fromName, decision in
              Task {
                await model.resolveSettlement(
                  requestId: pending.id,
                  amount: pending.amount,
                  fromName: fromName,
                  decision: decision
                )
              }
            },
            onRemind: { from, to in
              Task { await model.sendReminder(fromMember: from, toMember: to) }
            },
            onInspectBreakdown: inspectBreakdown
          )
        }
      }

      if !data.balances.households.isEmpty {
        HouseholdBarsSection(
          households: data.balances.households,
          members: data.members,
          onSelectHousehold: { hh in
            if hasBreakdowns {
              selectedBreakdownMemberId = hh.representativeMemberId
            }
          }
        )
      }

      BalanceBarsSection(
        balances: data.balances.balances,
        members: data.members,
        onSelectMember: inspectBreakdown
      )
      .id("balance-bars")
    }

    if !unmatchedPending.isEmpty {
      unmatchedPendingSection(
        requests: unmatchedPending,
        data: data,
        isOffline: isOffline
      )
    }
  }

  private func personalNetHeroCard(
    balance: Money,
    individualBalance: Money? = nil,
    householdName: String? = nil,
    settledThroughName: String? = nil,
    canViewBreakdown: Bool,
    onViewBreakdown: @escaping () -> Void
  ) -> some View {
    let statusLabel: String =
      if balance.isPositive {
        L10n.tr("feed.owedToYou")
      } else if balance.isNegative {
        L10n.tr("feed.youOwe")
      } else {
        L10n.tr("feed.settled")
      }
    let tint =
      balance.isPositive ? Tokens.credit : (balance.isNegative ? Tokens.debt : Tokens.ink)
    return SPCard(padding: 16) {
      AdaptiveStack(
        horizontalAlignment: .center,
        verticalAlignment: .leading,
        horizontalSpacing: 12,
        verticalSpacing: 12
      ) {
        VStack(alignment: .leading, spacing: 3) {
          if let householdName {
            Text(householdName)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
          }
          Text(statusLabel)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
          MoneyText(
            balance.magnitude,
            role: .hero,
            font: Typography.sectionTitle,
            color: tint
          )
          if let individualBalance {
            Text(
              L10n.t(
                "households.personalShareTemplate",
                ["amount": MoneyFormat.full(individualBalance)]
              )
            )
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
          }
          if let settledThroughName, !settledThroughName.isEmpty {
            Text(L10n.t("households.settledThroughTemplate", ["name": settledThroughName]))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if canViewBreakdown {
          Button(L10n.tr("breakdown.viewAction"), action: onViewBreakdown)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Tokens.sunken, in: Capsule())
            .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  private func quickActionBar(data: BalancesViewData, isOffline: Bool) -> some View {
    let canClose =
      isEmailVerified && data.group.role.canWrite && !data.group.isArchived
      && data.cyclesOverview != nil
    let closeDisabled =
      isOffline || (data.cyclesOverview?.currentPeriod.countedTransactionCount ?? 0) == 0
    let hasGuest = data.group.role.canWrite && onOpenGuestLink != nil
    if onOpenShareCard != nil || hasGuest || canClose {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          if let onOpenShareCard {
            quickActionChip(title: L10n.tr("shareCard.openAction"), icon: "square.and.arrow.up") {
              onOpenShareCard()
            }
          }
          if hasGuest, let onOpenGuestLink {
            quickActionChip(title: L10n.tr("guestLink.title"), icon: "link") {
              onOpenGuestLink()
            }
          }
          if canClose {
            quickActionChip(
              title: L10n.tr("cycles.closeAction"),
              icon: "lock.rectangle",
              isDisabled: closeDisabled
            ) {
              model.cycleErrorMessage = nil
              isCloseCycleSheetOpen = true
            }
          }
        }
        .padding(.horizontal, 20)
      }
      .padding(.horizontal, -20)
    }
  }

  private func quickActionChip(
    title: String,
    icon: String,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: icon)
        .font(Typography.captionBold)
        .foregroundStyle(isDisabled ? Tokens.muted : Tokens.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Tokens.surface, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
  }

  private var noticeMessage: String? {
    switch model.settlementNotice {
    case .confirmed(let amount, let fromName):
      L10n.t("pay.confirmedNotice", ["amount": MoneyFormat.full(amount), "from": fromName])
    case .rejected:
      L10n.tr("pay.rejectedNotice")
    case .alreadyResolved:
      L10n.tr("pay.alreadyResolved")
    case .none:
      nil
    }
  }

  private func errorMessage(for error: AppError) -> String {
    if case .api(_, 403) = error {
      return L10n.tr("common.forbidden")
    }
    return L10n.tr("common.saveError")
  }

  private func openTransfer(_ transfer: SuggestedTransfer, members: [Member]) {
    if let onOpenPay,
      let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
      let toMember = members.first(where: { $0.id == transfer.toMemberId })
    {
      onOpenPay(transfer, fromMember, toMember)
    } else {
      onOpenSettle(transfer)
    }
  }

  private func unmatchedPendingSection(
    requests: [SettlementRequest],
    data: BalancesViewData,
    isOffline: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(requests) { request in
        if let from = data.members.first(where: { $0.id == request.fromMemberId }),
          let to = data.members.first(where: { $0.id == request.toMemberId })
        {
          let canResolve =
            data.group.role.isOwner
            || data.group.myMemberId == to.id
            || (data.group.role == .editor && !to.claimed)
          let canCancel =
            (currentUserId != nil && request.createdByUserId == currentUserId)
            || data.group.myMemberId == from.id
          PendingSettlementCard(
            amount: request.amount,
            fromName: from.name,
            toName: to.name,
            channel: request.channel,
            note: request.note,
            proofAttachmentId: request.proofAttachment?.id,
            loadAttachment: loadAttachment,
            canResolve: canResolve,
            canCancel: canCancel,
            isDisabled: !isEmailVerified || isOffline,
            isPending: model.isResolvingSettlement,
            onConfirm: {
              Task {
                await model.resolveSettlement(
                  requestId: request.id,
                  amount: request.amount,
                  fromName: from.name,
                  decision: .confirm
                )
              }
            },
            onReject: {
              Task {
                await model.resolveSettlement(
                  requestId: request.id,
                  amount: request.amount,
                  fromName: from.name,
                  decision: .reject
                )
              }
            },
            onCancel: {
              Task {
                await model.resolveSettlement(
                  requestId: request.id,
                  amount: request.amount,
                  fromName: from.name,
                  decision: .cancel
                )
              }
            }
          )
        }
      }
    }
    .padding(20)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
  }
}

private func isFromMySide(_ transfer: SuggestedTransfer, myMemberId: Member.ID?) -> Bool {
  guard let myMemberId else { return false }
  if transfer.fromMemberId == myMemberId { return true }
  return transfer.fromHousehold?.memberIds.contains(myMemberId) == true
}

private func isTransferOnMySide(_ transfer: SuggestedTransfer, myMemberId: Member.ID?) -> Bool {
  guard let myMemberId else { return false }
  if transfer.fromMemberId == myMemberId || transfer.toMemberId == myMemberId { return true }
  if transfer.fromHousehold?.memberIds.contains(myMemberId) == true { return true }
  if transfer.toHousehold?.memberIds.contains(myMemberId) == true { return true }
  return false
}

private func transferActionLabel(
  transfer: SuggestedTransfer,
  myMemberId: Member.ID?,
  role: Role,
  opensPay: Bool
) -> String {
  let isMineToPay = isFromMySide(transfer, myMemberId: myMemberId)
  if !opensPay {
    if isMineToPay { return L10n.tr("balances.paid") }
    return transfer.toMemberId == myMemberId
      ? L10n.tr("balances.received")
      : L10n.tr("balances.record")
  }
  if isMineToPay {
    return L10n.tr("feed.pay")
  }
  return role.canWrite ? L10n.tr("balances.record") : L10n.tr("feed.view")
}

private func canResolvePending(
  toMember: Member,
  group: ExpenseGroup
) -> Bool {
  group.role.isOwner
    || group.myMemberId == toMember.id
    || (group.role == .editor && !toMember.claimed)
}

private func canCancelPending(
  pending: PendingSettlement,
  fromMember: Member,
  group: ExpenseGroup
) -> Bool {
  pending.createdByMe || group.myMemberId == fromMember.id
}

private func transferPartyLabel(
  member: Member,
  household: HouseholdTransferRef?
) -> String {
  if let household {
    return "\(member.name) (\(L10n.t("households.representativeBadge", ["name": household.name])))"
  }
  return member.name
}

private func transferRowCaption(
  transfer: SuggestedTransfer,
  from: Member,
  to: Member,
  amount: Money,
  myMemberId: Member.ID?,
  includeAmountForFund: Bool = false
) -> String {
  if from.kind == .fund {
    return L10n.t(
      "balances.fundRefundsMember", ["to": to.name, "amount": MoneyFormat.full(amount)])
  }
  if to.kind == .fund {
    return L10n.t(
      "balances.memberContributesToFund", ["from": from.name, "amount": MoneyFormat.full(amount)])
  }
  let fromLabel = transferPartyLabel(member: from, household: transfer.fromHousehold)
  let toLabel = transferPartyLabel(member: to, household: transfer.toHousehold)
  if isFromMySide(transfer, myMemberId: myMemberId) {
    return L10n.t("balances.youPayMember", ["name": toLabel])
  }
  if from.id == myMemberId {
    return L10n.t("balances.youPayMember", ["name": toLabel])
  }
  if to.id == myMemberId {
    return L10n.t("balances.memberPaysYou", ["name": fromLabel])
  }
  _ = includeAmountForFund
  return L10n.t("balances.memberPaysMember", ["from": fromLabel, "to": toLabel])
}

private struct OwnSettlementCardView: View {
  let transfer: SuggestedTransfer
  let members: [Member]
  let group: ExpenseGroup
  let isEmailVerified: Bool
  let isOffline: Bool
  let canOpenAction: Bool
  let opensPay: Bool
  let isResolvingSettlement: Bool
  let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  let onSettle: () -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void
  let onInspectBreakdown: ((Member.ID) -> Void)?

  var body: some View {
    if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
      let toMember = members.first(where: { $0.id == transfer.toMemberId })
    {
      VStack(spacing: 12) {
        MemberShapeView(member: toMember, size: 84)
        Text(
          transferRowCaption(
            transfer: transfer,
            from: fromMember,
            to: toMember,
            amount: transfer.amount,
            myMemberId: group.myMemberId
          )
        )
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
        MoneyText(
          transfer.amount,
          style: .amountOnly,
          font: Typography.heroNumber,
          color: Tokens.ink
        )
        if let pending = transfer.pendingSettlement {
          PendingSettlementCard(
            amount: pending.amount,
            fromName: fromMember.name,
            toName: toMember.name,
            channel: pending.channel,
            note: pending.note,
            proofAttachmentId: pending.proofAttachmentId,
            loadAttachment: loadAttachment,
            canResolve: canResolvePending(toMember: toMember, group: group),
            canCancel: canCancelPending(pending: pending, fromMember: fromMember, group: group),
            isDisabled: !isEmailVerified || isOffline,
            isPending: isResolvingSettlement,
            onConfirm: { onResolvePending(pending, fromMember.name, .confirm) },
            onReject: { onResolvePending(pending, fromMember.name, .reject) },
            onCancel: { onResolvePending(pending, fromMember.name, .cancel) }
          )
        } else if canOpenAction {
          SPButton(
            transferActionLabel(
              transfer: transfer,
              myMemberId: group.myMemberId,
              role: group.role,
              opensPay: opensPay
            ),
            variant: .accent,
            size: .lg,
            isFullWidth: true,
            action: onSettle
          )
        }
        if fromMember.kind == .person, let onInspectBreakdown {
          Button(L10n.tr("breakdown.viewAction")) {
            onInspectBreakdown(fromMember.id)
          }
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .buttonStyle(.plain)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(20)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
    }
  }
}

private struct SettlementCardView: View {
  let transfer: SuggestedTransfer
  let members: [Member]
  let group: ExpenseGroup
  let isEmailVerified: Bool
  let isOffline: Bool
  let canOpenAction: Bool
  let opensPay: Bool
  let isResolvingSettlement: Bool
  let hasCurrentPaymentDetails: Bool
  let isSendingReminder: Bool
  let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  let onSettle: () -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void
  let onRemind: (Member, Member) -> Void
  let onInspectBreakdown: ((Member.ID) -> Void)?
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
      let toMember = members.first(where: { $0.id == transfer.toMemberId })
    {
      let myMemberId = group.myMemberId
      let rowLayout =
        dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
        : AnyLayout(HStackLayout(spacing: 16))
      let other = isFromMySide(transfer, myMemberId: myMemberId) ? toMember : fromMember
      let caption = transferRowCaption(
        transfer: transfer,
        from: fromMember,
        to: toMember,
        amount: transfer.amount,
        myMemberId: myMemberId
      )

      VStack(alignment: .leading, spacing: 16) {
        rowLayout {
          MemberShapeView(member: other, size: 76)
          VStack(alignment: .leading, spacing: 4) {
            Text(caption)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            MoneyText(
              transfer.amount,
              style: .amountOnly,
              font: Typography.sectionTitle,
              color: Tokens.ink
            )
          }
        }
        if let pending = transfer.pendingSettlement {
          PendingSettlementCard(
            amount: pending.amount,
            fromName: fromMember.name,
            toName: toMember.name,
            channel: pending.channel,
            note: pending.note,
            proofAttachmentId: pending.proofAttachmentId,
            loadAttachment: loadAttachment,
            canResolve: canResolvePending(toMember: toMember, group: group),
            canCancel: canCancelPending(pending: pending, fromMember: fromMember, group: group),
            isDisabled: !isEmailVerified || isOffline,
            isPending: isResolvingSettlement,
            onConfirm: { onResolvePending(pending, fromMember.name, .confirm) },
            onReject: { onResolvePending(pending, fromMember.name, .reject) },
            onCancel: { onResolvePending(pending, fromMember.name, .cancel) }
          )
        } else {
          let showRemind = canRemindTransfer(
            transfer: transfer,
            from: fromMember,
            to: toMember,
            myMemberId: myMemberId,
            role: group.role,
            verified: isEmailVerified
          )
          if showRemind {
            AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 8) {
              if canOpenAction {
                SPButton(
                  transferActionLabel(
                    transfer: transfer,
                    myMemberId: myMemberId,
                    role: group.role,
                    opensPay: opensPay
                  ),
                  variant: .accent,
                  size: .lg,
                  isFullWidth: true,
                  action: onSettle
                )
              }
              SPButton(
                L10n.tr("reminders.remind"),
                variant: .surface,
                size: .lg,
                isFullWidth: true,
                isDisabled: isOffline || !hasCurrentPaymentDetails,
                isPending: isSendingReminder,
                action: { onRemind(fromMember, toMember) }
              )
            }
          } else if canOpenAction {
            SPButton(
              transferActionLabel(
                transfer: transfer,
                myMemberId: myMemberId,
                role: group.role,
                opensPay: opensPay
              ),
              variant: .accent,
              size: .lg,
              isFullWidth: true,
              action: onSettle
            )
          }
        }
        if fromMember.kind == .person, let onInspectBreakdown {
          Button(L10n.tr("breakdown.viewAction")) {
            onInspectBreakdown(fromMember.id)
          }
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .buttonStyle(.plain)
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
    }
  }
}

private struct OtherSettlementsSection: View {
  let transfers: [SuggestedTransfer]
  let members: [Member]
  let group: ExpenseGroup
  let isEmailVerified: Bool
  let isOffline: Bool
  let canOpenAction: Bool
  let opensPay: Bool
  let isResolvingSettlement: Bool
  let hasCurrentPaymentDetails: Bool
  let isSendingReminder: Bool
  let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  let onSettle: (SuggestedTransfer) -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void
  let onRemind: (Member, Member) -> Void
  let onInspectBreakdown: ((Member.ID) -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("balances.othersTitle"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      ForEach(transfers) { transfer in
        if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
          let toMember = members.first(where: { $0.id == transfer.toMemberId })
        {
          VStack(alignment: .leading, spacing: 10) {
            AdaptiveStack(
              horizontalAlignment: .center,
              verticalAlignment: .leading,
              horizontalSpacing: 8,
              verticalSpacing: 8
            ) {
              HStack(spacing: 8) {
                MemberShapeView(member: fromMember, size: 28)
                Text(
                  transferRowCaption(
                    transfer: transfer,
                    from: fromMember,
                    to: toMember,
                    amount: transfer.amount,
                    myMemberId: group.myMemberId
                  )
                )
                .font(Typography.caption)
                .foregroundStyle(Tokens.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
              }

              HStack(spacing: 8) {
                MoneyText(
                  transfer.amount,
                  role: .primary,
                  font: Typography.subheadlineBold,
                  color: Tokens.ink
                )

                let showRemind = canRemindTransfer(
                  transfer: transfer,
                  from: fromMember,
                  to: toMember,
                  myMemberId: group.myMemberId,
                  role: group.role,
                  verified: isEmailVerified
                )

                if transfer.pendingSettlement == nil {
                  if canOpenAction {
                    Button(
                      transferActionLabel(
                        transfer: transfer,
                        myMemberId: group.myMemberId,
                        role: group.role,
                        opensPay: opensPay
                      )
                    ) {
                      onSettle(transfer)
                    }
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Tokens.sunken, in: Capsule())
                    .buttonStyle(.plain)
                  }

                  if showRemind {
                    Button(L10n.tr("reminders.remind")) {
                      onRemind(fromMember, toMember)
                    }
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Tokens.sunken, in: Capsule())
                    .buttonStyle(.plain)
                    .disabled(isOffline || !hasCurrentPaymentDetails || isSendingReminder)
                  }
                }
              }
            }

            if let pending = transfer.pendingSettlement {
              PendingSettlementCard(
                amount: pending.amount,
                fromName: fromMember.name,
                toName: toMember.name,
                channel: pending.channel,
                note: pending.note,
                proofAttachmentId: pending.proofAttachmentId,
                loadAttachment: loadAttachment,
                canResolve: canResolvePending(toMember: toMember, group: group),
                canCancel: canCancelPending(
                  pending: pending, fromMember: fromMember, group: group),
                isDisabled: !isEmailVerified || isOffline,
                isPending: isResolvingSettlement,
                onConfirm: { onResolvePending(pending, fromMember.name, .confirm) },
                onReject: { onResolvePending(pending, fromMember.name, .reject) },
                onCancel: { onResolvePending(pending, fromMember.name, .cancel) }
              )
            }
            if fromMember.kind == .person, let onInspectBreakdown {
              Button(L10n.tr("breakdown.viewAction")) {
                onInspectBreakdown(fromMember.id)
              }
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
    .padding(20)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
  }
}

private struct AllSettledSection: View {
  let recorded: [LedgerTransaction]
  let members: [Member]
  let myMemberId: Member.ID?
  let celebrationTick: Int
  let onBackToGroup: () -> Void

  @State private var hapticBeatTick = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      ZStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 12) {
          Text(L10n.tr("balances.allSettledTitle"))
            .font(Typography.heroNumber)
            .foregroundStyle(Tokens.onAccent)
          Text(L10n.tr("balances.allSettledHint"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.onAccent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 40, style: .continuous))

        if celebrationTick > 0 {
          ShapeBurst(members: members, trigger: celebrationTick)
            .allowsHitTesting(false)
            .padding(.top, -16)
        }
      }
      .spFeedback(.success, trigger: hapticBeatTick)
      .task(id: celebrationTick) {
        guard celebrationTick > 0 else { return }
        SoundPlayer.shared.play(.chord)
        hapticBeatTick &+= 1
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }
        hapticBeatTick &+= 1
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }
        hapticBeatTick &+= 1
      }

      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: 20
      ) {
        ForEach(members) { member in
          VStack(spacing: 8) {
            MemberShapeView(member: member, size: 72)
            Text(PersonName.display(member: member, currentMemberId: myMemberId))
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
            MoneyText(
              .zero,
              role: .primary,
              font: Typography.body,
              color: Tokens.ink
            )
          }
        }
      }
      .padding(20)
      .background(
        Tokens.surface,
        in: RoundedRectangle(cornerRadius: Tokens.radiusCard, style: .continuous)
      )

      if !recorded.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text(L10n.t("balances.recordedTitle", ["count": String(recorded.count)]))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)

          ForEach(Array(recorded.prefix(5))) { transaction in
            if let fromId = transaction.payers.first?.memberId,
              let toId = transaction.shares.first?.memberId,
              let fromMember = members.first(where: { $0.id == fromId }),
              let toMember = members.first(where: { $0.id == toId })
            {
              let text: String = {
                if fromMember.id == myMemberId {
                  return L10n.t("balances.youPaidMember", ["name": toMember.name])
                } else if toMember.id == myMemberId {
                  return L10n.t("balances.memberPaidYou", ["name": fromMember.name])
                } else {
                  return L10n.t(
                    "balances.memberPaidMember",
                    ["from": fromMember.name, "to": toMember.name]
                  )
                }
              }()

              AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 4) {
                HStack(spacing: 8) {
                  MemberShapeView(member: fromMember, size: 28)
                  Text(text)
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                MoneyText(
                  transaction.amount,
                  role: .primary,
                  font: Typography.captionBold,
                  color: Tokens.ink
                )
              }
            }
          }
        }
        .padding(20)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
      }

      SPButton(
        L10n.tr("balances.backToGroup"),
        variant: .primary,
        size: .lg,
        isFullWidth: true,
        action: onBackToGroup
      )
    }
  }
}

private struct HouseholdBarsSection: View {
  let households: [HouseholdBalance]
  let members: [Member]
  var onSelectHousehold: ((HouseholdBalance) -> Void)? = nil

  var body: some View {
    let largest = max(
      1,
      households.map { $0.netBalance.magnitude.amount }.max() ?? 1
    )
    let ordered = households.sorted { $0.netBalance > $1.netBalance }

    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.tr("households.byHouseholdTitle"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      ForEach(ordered) { hh in
        householdRowView(hh, largest: largest)
      }
    }
    .padding(20)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
  }

  @ViewBuilder
  private func householdRowView(_ hh: HouseholdBalance, largest: Int64) -> some View {
    let rep = members.first(where: { $0.id == hh.representativeMemberId })
    let barColor = rep.map { Tokens.color(for: $0.color) } ?? Tokens.ink
    let negativeMagnitude = hh.netBalance.isNegative ? Double(hh.netBalance.magnitude.amount) : 0
    let positiveMagnitude = !hh.netBalance.isNegative ? Double(hh.netBalance.magnitude.amount) : 0
    let row = VStack(alignment: .leading, spacing: 6) {
      AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          Text(hh.name)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
          if let rep {
            Text(L10n.t("households.representativeBadge", ["name": rep.name]))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        MoneyText(
          hh.netBalance,
          style: .signed,
          font: Typography.captionBold,
          color: hh.netBalance.isPositive
            ? Tokens.credit
            : (hh.netBalance.isNegative ? Tokens.debt : Tokens.ink)
        )
      }

      HStack(spacing: 2) {
        ProgressView(value: negativeMagnitude, total: Double(largest))
          .progressViewStyle(HalfBalanceBarStyle(color: barColor, anchor: .trailing))

        ProgressView(value: positiveMagnitude, total: Double(largest))
          .progressViewStyle(HalfBalanceBarStyle(color: barColor, anchor: .leading))
      }
      .frame(height: 14)
      .background(Tokens.sunken, in: Capsule())

      HStack(spacing: 8) {
        ForEach(hh.memberBalances) { mb in
          if let member = members.first(where: { $0.id == mb.memberId }) {
            HStack(spacing: 2) {
              Text("\(member.name):")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
              MoneyText(
                mb.balance,
                style: .signed,
                font: Typography.caption,
                color: Tokens.muted
              )
            }
          }
        }
      }
    }
    if let onSelectHousehold {
      Button {
        onSelectHousehold(hh)
      } label: {
        row
      }
      .buttonStyle(.plain)
    } else {
      row
    }
  }
}

private struct BalanceBarsSection: View {
  let balances: [Balance]
  let members: [Member]
  var onSelectMember: ((Member.ID) -> Void)? = nil

  var body: some View {
    let largest = max(
      1,
      balances.map { $0.balance.magnitude.amount }.max() ?? 1
    )
    let ordered = balances.sorted { $0.balance > $1.balance }

    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.tr("balances.groupBalanceTitle"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      ForEach(ordered) { item in
        if let member = members.first(where: { $0.id == item.memberId }),
          member.active || !item.balance.isZero
        {
          let row = VStack(alignment: .leading, spacing: 4) {
            AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 2) {
              HStack(spacing: 4) {
                Text(member.name)
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
                if !member.active {
                  Text(L10n.tr("balances.inactiveTag"))
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.muted)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              MoneyText(
                item.balance,
                style: .signed,
                font: Typography.captionBold,
                color: Tokens.ink
              )
            }

            HStack(spacing: 0) {
              ProgressView(
                value: item.balance.isNegative ? Double(item.balance.magnitude.amount) : 0,
                total: Double(largest)
              )
              .progressViewStyle(
                HalfBalanceBarStyle(color: Tokens.color(for: member.color), anchor: .trailing)
              )

              ProgressView(
                value: !item.balance.isNegative ? Double(item.balance.magnitude.amount) : 0,
                total: Double(largest)
              )
              .progressViewStyle(
                HalfBalanceBarStyle(color: Tokens.color(for: member.color), anchor: .leading)
              )
            }
            .frame(height: 14)
            .background(Tokens.sunken, in: Capsule())
          }
          if member.kind == .person, let onSelectMember {
            Button {
              onSelectMember(member.id)
            } label: {
              row
            }
            .buttonStyle(.plain)
          } else {
            row
          }
        }
      }
    }
    .padding(20)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
  }
}

private struct HalfBalanceBarStyle: ProgressViewStyle {
  let color: Color
  let anchor: UnitPoint

  func makeBody(configuration: Configuration) -> some View {
    let fraction = CGFloat(configuration.fractionCompleted ?? 0)
    Capsule()
      .fill(color)
      .scaleEffect(x: fraction, y: 1, anchor: anchor)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct ConditionalBalancesNavBar: ViewModifier {
  let isEnabled: Bool
  let title: String

  func body(content: Content) -> some View {
    if isEnabled {
      content
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    } else {
      content
    }
  }
}

#if DEBUG
  #Preview("Balances Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    let model = BalancesModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    BalancesView(model: model, onBack: {}, onBackToGroups: {}, onOpenSettle: { _ in })
  }

  #Preview("Balances Empty") {
    let world = FakeWorld(preset: .tripStep0)
    let model = BalancesModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    BalancesView(model: model, onBack: {}, onBackToGroups: {}, onOpenSettle: { _ in })
  }

  #Preview("Balances Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(60), hasSnapshot: false)
    )
    let model = BalancesModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    BalancesView(model: model, onBack: {}, onBackToGroups: {}, onOpenSettle: { _ in })
  }

  #Preview("Balances Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    let model = BalancesModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    BalancesView(model: model, onBack: {}, onBackToGroups: {}, onOpenSettle: { _ in })
  }
#endif
