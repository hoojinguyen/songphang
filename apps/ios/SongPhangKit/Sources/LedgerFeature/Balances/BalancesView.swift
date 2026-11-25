import DesignSystem
public import Domain
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
    onCreateFund: (() -> Void)? = nil
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
              LoadingSkeleton(rowCount: 3, rowHeight: 110)

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
      .navigationBarBackButtonHidden(true)
      .task {
        if model.state.value == nil {
          await model.load()
        }
        if ProcessInfo.processInfo.arguments.contains("--scroll-bars") {
          proxy.scrollTo("balance-bars", anchor: .bottom)
        }
      }
    }
  }

  @ViewBuilder
  private func loadedContent(data: BalancesViewData) -> some View {
    if showHeader {
      SPScreenHeader(
        title: data.group.name,
        onBack: onBack
      )
    }

    if let noticeText = model.reminderNotice ?? noticeMessage {
      SPCard(tone: .accent, padding: 14) {
        Text(noticeText)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }

    if let error = model.settlementError {
      Text(errorMessage(for: error))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
    }

    let hasTransactions = !data.transactions.isEmpty
    let myMemberId = data.group.myMemberId
    let sortedTransfers = data.balances.transfers.sorted { first, second in
      let firstInvolvesMe = (first.fromMemberId == myMemberId || first.toMemberId == myMemberId)
      let secondInvolvesMe = (second.fromMemberId == myMemberId || second.toMemberId == myMemberId)
      if firstInvolvesMe == secondInvolvesMe { return false }
      return firstInvolvesMe && !secondInvolvesMe
    }
    let ownTransfers = sortedTransfers.filter { $0.fromMemberId == myMemberId }
    let otherTransfers = sortedTransfers.filter { $0.fromMemberId != myMemberId }
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
    } else if sortedTransfers.isEmpty {
      AllSettledSection(
        recorded: data.transactions.filter { $0.type == .transfer },
        members: data.members,
        myMemberId: myMemberId,
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
            }
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
            }
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
            }
          )
        }
      }

      BalanceBarsSection(
        balances: data.balances.balances,
        members: data.members
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

private func transferActionLabel(
  transfer: SuggestedTransfer,
  myMemberId: Member.ID?,
  role: Role,
  opensPay: Bool
) -> String {
  if !opensPay {
    if transfer.fromMemberId == myMemberId { return L10n.tr("balances.paid") }
    return transfer.toMemberId == myMemberId
      ? L10n.tr("balances.received")
      : L10n.tr("balances.record")
  }
  if transfer.fromMemberId == myMemberId {
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

private func transferRowCaption(
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
  if from.id == myMemberId {
    return L10n.t("balances.youPayMember", ["name": to.name])
  }
  if to.id == myMemberId {
    return L10n.t("balances.memberPaysYou", ["name": from.name])
  }
  _ = includeAmountForFund
  return L10n.t("balances.memberPaysMember", ["from": from.name, "to": to.name])
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
  let onSettle: () -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void

  var body: some View {
    if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
      let toMember = members.first(where: { $0.id == transfer.toMemberId })
    {
      VStack(spacing: 12) {
        MemberShapeView(
          shape: toMember.shape,
          color: toMember.color,
          name: toMember.name,
          size: 84
        )
        Text(
          transferRowCaption(
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
  let onSettle: () -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void
  let onRemind: (Member, Member) -> Void
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
      let other = transfer.fromMemberId == myMemberId ? toMember : fromMember
      let caption = transferRowCaption(
        from: fromMember,
        to: toMember,
        amount: transfer.amount,
        myMemberId: myMemberId
      )

      VStack(alignment: .leading, spacing: 16) {
        rowLayout {
          MemberShapeView(
            shape: other.shape,
            color: other.color,
            name: other.name,
            size: 76
          )
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
            HStack(spacing: 8) {
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
                isFullWidth: !canOpenAction,
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
  let onSettle: (SuggestedTransfer) -> Void
  let onResolvePending: (PendingSettlement, String, SettlementDecision) -> Void
  let onRemind: (Member, Member) -> Void

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
            HStack(spacing: 8) {
              MemberShapeView(
                shape: fromMember.shape,
                color: fromMember.color,
                name: fromMember.name,
                size: 28,
                showInitial: false
              )
              Text(
                transferRowCaption(
                  from: fromMember,
                  to: toMember,
                  amount: transfer.amount,
                  myMemberId: group.myMemberId
                )
              )
              .font(Typography.caption)
              .foregroundStyle(Tokens.ink)
              .frame(maxWidth: .infinity, alignment: .leading)

              MoneyText(
                transfer.amount,
                style: .full,
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

            if let pending = transfer.pendingSettlement {
              PendingSettlementCard(
                amount: pending.amount,
                fromName: fromMember.name,
                toName: toMember.name,
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
  let onBackToGroup: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("balances.allSettledTitle"))
          .font(Typography.heroNumber)
          .foregroundStyle(Tokens.ink)
        Text(L10n.tr("balances.allSettledHint"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 40, style: .continuous))

      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: 20
      ) {
        ForEach(members) { member in
          VStack(spacing: 8) {
            MemberShapeView(
              shape: member.shape,
              color: member.color,
              name: member.name,
              size: 72
            )
            Text(member.id == myMemberId ? L10n.tr("common.you") : member.name)
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
            MoneyText(
              .zero,
              style: .full,
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

              HStack(spacing: 8) {
                MemberShapeView(
                  shape: fromMember.shape,
                  color: fromMember.color,
                  name: fromMember.name,
                  size: 28,
                  showInitial: false
                )
                Text(text)
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.ink)
                  .frame(maxWidth: .infinity, alignment: .leading)
                MoneyText(
                  transaction.amount,
                  style: .full,
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

private struct BalanceBarsSection: View {
  let balances: [Balance]
  let members: [Member]

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
          VStack(alignment: .leading, spacing: 4) {
            HStack {
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
              Spacer()
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
