import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct BalancesView: View {
  @Bindable private var model: BalancesModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onBackToGroups: () -> Void
  private let onOpenSettle: (SuggestedTransfer) -> Void

  public init(
    model: BalancesModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onBackToGroups: @escaping () -> Void,
    onOpenSettle: @escaping (SuggestedTransfer) -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onBackToGroups = onBackToGroups
    self.onOpenSettle = onOpenSettle
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
    SPScreenHeader(
      title: data.group.name,
      onBack: onBack
    )

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
    let canEdit =
      isEmailVerified
      && data.group.role.canWrite
      && model.refreshError != .offline

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

      if !ownTransfers.isEmpty {
        ForEach(ownTransfers) { transfer in
          OwnSettlementCardView(
            transfer: transfer,
            members: data.members,
            canEdit: canEdit,
            onSettle: { onOpenSettle(transfer) }
          )
        }
        if !otherTransfers.isEmpty {
          OtherSettlementsSection(
            transfers: otherTransfers,
            members: data.members,
            canEdit: canEdit,
            onSettle: onOpenSettle
          )
        }
      } else {
        ForEach(sortedTransfers) { transfer in
          SettlementCardView(
            transfer: transfer,
            members: data.members,
            myMemberId: myMemberId,
            canEdit: canEdit,
            onSettle: { onOpenSettle(transfer) }
          )
        }
      }

      BalanceBarsSection(
        balances: data.balances.balances,
        members: data.members
      )
      .id("balance-bars")
    }
  }
}

private struct OwnSettlementCardView: View {
  let transfer: SuggestedTransfer
  let members: [Member]
  let canEdit: Bool
  let onSettle: () -> Void

  var body: some View {
    if let toMember = members.first(where: { $0.id == transfer.toMemberId }) {
      VStack(spacing: 12) {
        MemberShapeView(
          shape: toMember.shape,
          color: toMember.color,
          name: toMember.name,
          size: 84
        )
        Text(L10n.t("balances.youPayMember", ["name": toMember.name]))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
        MoneyText(
          transfer.amount,
          style: .amountOnly,
          font: Typography.heroNumber,
          color: Tokens.ink
        )
        if canEdit {
          SPButton(
            L10n.tr("balances.paid"),
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
  let myMemberId: Member.ID?
  let canEdit: Bool
  let onSettle: () -> Void

  var body: some View {
    if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
      let toMember = members.first(where: { $0.id == transfer.toMemberId })
    {
      let other = transfer.fromMemberId == myMemberId ? toMember : fromMember
      let caption: String = {
        if transfer.fromMemberId == myMemberId {
          return L10n.t("balances.youPayMember", ["name": toMember.name])
        } else if transfer.toMemberId == myMemberId {
          return L10n.t("balances.memberPaysYou", ["name": fromMember.name])
        } else {
          return L10n.t(
            "balances.memberPaysMember",
            ["from": fromMember.name, "to": toMember.name]
          )
        }
      }()

      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 16) {
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
        if canEdit {
          SPButton(
            transfer.toMemberId == myMemberId
              ? L10n.tr("balances.received")
              : L10n.tr("balances.record"),
            variant: .accent,
            size: .lg,
            isFullWidth: true,
            action: onSettle
          )
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
  let canEdit: Bool
  let onSettle: (SuggestedTransfer) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("balances.othersTitle"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      ForEach(transfers) { transfer in
        if let fromMember = members.first(where: { $0.id == transfer.fromMemberId }),
          let toMember = members.first(where: { $0.id == transfer.toMemberId })
        {
          HStack(spacing: 8) {
            MemberShapeView(
              shape: fromMember.shape,
              color: fromMember.color,
              name: fromMember.name,
              size: 28,
              showInitial: false
            )
            Text(
              L10n.t(
                "balances.memberPaysMember",
                ["from": fromMember.name, "to": toMember.name]
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

            if canEdit {
              Button(L10n.tr("balances.record")) {
                onSettle(transfer)
              }
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 44)
              .background(Tokens.sunken, in: Capsule())
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
