import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct FundView: View {
  @Bindable private var model: FundModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onContribute: (Member.ID) -> Void
  private let onWithdraw: (Member.ID) -> Void
  private let onDeleted: () -> Void

  public init(
    model: FundModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onContribute: @escaping (Member.ID) -> Void,
    onWithdraw: @escaping (Member.ID) -> Void,
    onDeleted: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onContribute = onContribute
    self.onWithdraw = onWithdraw
    self.onDeleted = onDeleted
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        switch model.state {
        case .loading:
          SPScreenHeader(title: L10n.tr("fund.defaultName"), onBack: onBack)
          LoadingSkeleton(rowCount: 3, rowHeight: 112)

        case .failed(let error):
          SPScreenHeader(title: L10n.tr("fund.defaultName"), onBack: onBack)
          if case .api(_, 404) = error {
            VStack(spacing: 12) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.back"), variant: .surface, action: onBack)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
          } else {
            LoadError {
              Task { await model.load() }
            }
          }

        case .loaded(let data):
          if let fund = data.balances.fund {
            SPScreenHeader(title: fund.name, onBack: onBack)
            loadedContent(data: data, fund: fund)
          } else {
            SPScreenHeader(title: L10n.tr("fund.defaultName"), onBack: onBack)
            EmptyState(title: L10n.tr("fund.noContributions"))
            SPButton(L10n.tr("common.back"), variant: .surface, isFullWidth: true, action: onBack)
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
      await model.load()
    }
  }

  @ViewBuilder
  private func loadedContent(data: FundModel.ScreenData, fund: FundSummary) -> some View {
    let people = data.members.filter { $0.kind == .person }
    let holder = fund.holderMemberId.flatMap { id in people.first(where: { $0.id == id }) }
    let canWrite = data.group.role.canWrite && isEmailVerified && !model.isOffline

    VStack(spacing: 8) {
      FundShapeView(name: fund.name, size: 40)

      Text(fund.cash.isNegative ? L10n.tr("fund.negativeLabel") : L10n.tr("fund.remainingLabel"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)

      MoneyText(
        fund.cash.magnitude,
        style: .full,
        font: .system(size: 42, weight: .black),
        color: Tokens.ink
      )

      if let holder {
        Text(L10n.t("fund.holderLine", ["name": holder.name]))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }

      if !fund.active {
        Text(L10n.tr("fund.inactiveTag"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(Tokens.surface.opacity(0.85), in: Capsule())
      }
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 40, style: .continuous))

    if canWrite && fund.active {
      HStack(spacing: 10) {
        SPButton(L10n.tr("fund.contributeButton"), variant: .primary, isFullWidth: true) {
          onContribute(fund.memberId)
        }
        SPButton(L10n.tr("fund.withdrawButton"), variant: .surface, isFullWidth: true) {
          onWithdraw(fund.memberId)
        }
      }
    }

    contributionsCard(fund: fund, people: people)

    if data.group.role.canWrite && isEmailVerified {
      settingsCard(fund: fund, people: people, isOffline: model.isOffline)
    }
  }

  private func contributionsCard(fund: FundSummary, people: [Member]) -> some View {
    SPCard(tone: .surface, padding: 20) {
      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.tr("fund.contributionsTitle"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        if fund.contributions.isEmpty {
          Text(L10n.tr("fund.noContributions"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.muted)
        } else {
          ForEach(fund.contributions) { entry in
            if let person = people.first(where: { $0.id == entry.memberId }) {
              HStack(spacing: 12) {
                MemberShapeView(
                  shape: person.shape,
                  color: person.color,
                  name: person.name,
                  size: 32
                )
                Text(person.name)
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
                Spacer(minLength: 8)
                MoneyText(
                  entry.amount,
                  style: .full,
                  font: Typography.subheadlineBold,
                  color: Tokens.ink
                )
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func settingsCard(fund: FundSummary, people: [Member], isOffline: Bool) -> some View {
    let trimmed = model.nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    let isDirty = trimmed != fund.name || model.holderDraftId != fund.holderMemberId
    let isDisabled = isOffline || model.isPerformingAction

    return SPCard(tone: .surface, padding: 20) {
      VStack(alignment: .leading, spacing: 14) {
        SPTextField(
          label: L10n.tr("fund.nameLabel"),
          text: $model.nameDraft,
          maxLength: 50
        )

        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("fund.holderLabel"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              holderChip(
                title: L10n.tr("fund.noHolder"),
                isSelected: model.holderDraftId == nil,
                isDisabled: isDisabled
              ) {
                model.holderDraftId = nil
              }

              ForEach(people) { person in
                holderChip(
                  title: person.name,
                  isSelected: model.holderDraftId == person.id,
                  isDisabled: isDisabled
                ) {
                  model.holderDraftId = person.id
                }
              }
            }
          }
        }

        SPButton(
          L10n.tr("fund.saveButton"),
          variant: .primary,
          isFullWidth: true,
          isDisabled: isDisabled || trimmed.isEmpty || !isDirty,
          isPending: model.isPerformingAction
        ) {
          Task { await model.saveSettings() }
        }

        SPButton(
          fund.active ? L10n.tr("fund.closeButton") : L10n.tr("fund.reopenButton"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: isDisabled
        ) {
          Task { await model.toggleActive() }
        }

        Button {
          Task { await model.deleteFund(onDeleted: onDeleted) }
        } label: {
          Text(L10n.tr("fund.deleteButton"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Tokens.debtSoft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)

        if let error = model.actionError {
          Text(errorText(for: error))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func errorText(for error: AppError) -> String {
    switch error {
    case .api("FUND_NOT_EMPTY", _):
      return L10n.tr("fund.closeNonEmpty")
    case .api("MEMBER_HAS_TRANSACTIONS", _):
      return L10n.tr("fund.hasTransactions")
    case .api(_, 403):
      return L10n.tr("common.forbidden")
    default:
      return L10n.tr("common.saveError")
    }
  }

  private func holderChip(
    title: String,
    isSelected: Bool,
    isDisabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(Typography.captionBold)
        .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(isSelected ? Tokens.ink : Tokens.bg, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4, hasFundAndBudget: true)
    FundView(
      model: FundModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        fundRepository: FakeFundRepository(world: world)
      ),
      onBack: {},
      onContribute: { _ in },
      onWithdraw: { _ in },
      onDeleted: {}
    )
  }

  #Preview("Empty") {
    let world = FakeWorld(preset: .tripStep0)
    FundView(
      model: FundModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        fundRepository: FakeFundRepository(world: world)
      ),
      onBack: {},
      onContribute: { _ in },
      onWithdraw: { _ in },
      onDeleted: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    FundView(
      model: FundModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        fundRepository: FakeFundRepository(world: world)
      ),
      onBack: {},
      onContribute: { _ in },
      onWithdraw: { _ in },
      onDeleted: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    FundView(
      model: FundModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        fundRepository: FakeFundRepository(world: world)
      ),
      onBack: {},
      onContribute: { _ in },
      onWithdraw: { _ in },
      onDeleted: {}
    )
  }
#endif
