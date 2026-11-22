import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct StatsView: View {
  @Bindable private var model: StatsModel
  private let onBack: () -> Void
  private let onOpenFilteredFeed: (TransactionFilter) -> Void
  @State private var shareItem: ShareFileItem?

  public init(
    model: StatsModel,
    onBack: @escaping () -> Void,
    onOpenFilteredFeed: @escaping (TransactionFilter) -> Void
  ) {
    self.model = model
    self.onBack = onBack
    self.onOpenFilteredFeed = onOpenFilteredFeed
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        switch model.state {
        case .loading:
          SPScreenHeader(title: L10n.tr("stats.title"), onBack: onBack)
          LoadingSkeleton(rowCount: 4, rowHeight: 96)

        case .failed(let error):
          SPScreenHeader(title: L10n.tr("stats.title"), onBack: onBack)
          if case .api(_, 404) = error {
            VStack(spacing: 12) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
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
          SPScreenHeader(title: L10n.tr("stats.title"), onBack: onBack)
          loadedContent(data)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 28)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .sheet(item: $shareItem) { item in
      FileShareSheet(url: item.url) {
        shareItem = nil
      }
      .presentationDetents([.medium, .large])
    }
    .task {
      await model.load()
    }
  }

  @ViewBuilder
  private func loadedContent(_ data: StatsModel.ScreenData) -> some View {
    periodChipsSection()

    if model.period == .custom {
      customDatePickerCard()
    }

    SPCard(tone: .accent, padding: 20) {
      VStack(alignment: .leading, spacing: 6) {
        MoneyText(
          data.stats.total,
          style: .full,
          font: Typography.heroNumber,
          color: Tokens.ink
        )
        if let budget = data.budget, budget.state == .near || budget.state == .over {
          let periodLabel =
            budget.period == .month
            ? L10n.tr("budget.periodMonth")
            : L10n.tr("budget.periodTotal")
          let statusLabel =
            budget.state == .over
            ? L10n.t("budget.overBanner", ["over": MoneyFormat.full(budget.spent - budget.amount)])
            : L10n.t(
              "budget.nearBanner",
              [
                "spent": MoneyFormat.full(budget.spent),
                "amount": MoneyFormat.full(budget.amount),
              ]
            )
          Text("\(periodLabel) · \(statusLabel)")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }

    let isStatsEmpty = data.stats.byBucket.isEmpty && data.stats.byCategory.isEmpty
    if isStatsEmpty {
      SPCard(tone: .surface, padding: 24) {
        Text(L10n.tr("stats.empty"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.muted)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    } else {
      byCategorySection(data: data)
      byMemberSection(data: data)
      byTimeSection(data: data)
    }

    SPButton(
      L10n.tr("stats.exportCsv"),
      variant: .surface,
      isFullWidth: true,
      isDisabled: model.isOffline || model.isExportingCSV,
      isPending: model.isExportingCSV
    ) {
      Task {
        if let url = await model.exportCSVFile() {
          shareItem = ShareFileItem(url: url)
        }
      }
    }

    if model.exportError != nil {
      Text(L10n.tr("common.loadError"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.ink)
    }
  }

  private func periodChipsSection() -> some View {
    let options: [(period: StatsPeriod, label: String)] = [
      (.all, L10n.tr("stats.all")),
      (.thisMonth, L10n.tr("stats.thisMonth")),
      (.lastMonth, L10n.tr("stats.lastMonth")),
      (.custom, L10n.tr("stats.custom")),
    ]
    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(options, id: \.period) { item in
          let isSelected = (model.period == item.period)
          Button {
            Task { await model.selectPeriod(item.period) }
          } label: {
            Text(item.label)
              .font(Typography.captionBold)
              .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
              .padding(.horizontal, 16)
              .frame(minHeight: 44)
              .background(isSelected ? Tokens.ink : Tokens.surface, in: Capsule())
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
    }
  }

  private func customDatePickerCard() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      DatePicker(
        L10n.tr("filter.fromDate"),
        selection: $model.customFromDate,
        displayedComponents: [.date]
      )
      .font(Typography.subheadlineBold)
      .onChange(of: model.customFromDate) { _, _ in
        Task { await model.applyCustomDates() }
      }

      DatePicker(
        L10n.tr("filter.toDate"),
        selection: $model.customToDate,
        in: model.customFromDate...,
        displayedComponents: [.date]
      )
      .font(Typography.subheadlineBold)
      .onChange(of: model.customToDate) { _, _ in
        Task { await model.applyCustomDates() }
      }
    }
    .padding(16)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  private func byCategorySection(data: StatsModel.ScreenData) -> some View {
    let maxCategory = data.stats.byCategory.map(\.amount).max() ?? .zero
    return SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.tr("stats.byCategory"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 8)
          .padding(.bottom, 4)

        ForEach(data.stats.byCategory) { entry in
          let custom = entry.categoryId.flatMap { id in
            data.categories.first(where: { $0.id == id })
          }
          let label: String =
            if let cat = entry.category {
              CategoryDisplay.localizedName(for: cat)
            } else if let custom {
              custom.name
            } else {
              L10n.tr("stats.uncategorised")
            }
          let fillColor = custom.map { Tokens.color(for: $0.color) } ?? Tokens.ink

          StatsBarRowView(
            label: label,
            amount: entry.amount,
            maxAmount: maxCategory,
            fillColor: fillColor
          ) {
            onOpenFilteredFeed(model.filterForCategory(entry, range: data.periodRange))
          }
        }
      }
    }
  }

  private func byMemberSection(data: StatsModel.ScreenData) -> some View {
    let maxMember =
      data.stats.byMember.flatMap { [$0.paid, $0.share] }.max() ?? .zero
    return SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.tr("stats.byMember"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 8)
          .padding(.bottom, 4)

        ForEach(data.stats.byMember) { entry in
          if let member = data.members.first(where: { $0.id == entry.memberId }) {
            MemberStatsRowView(
              memberName: member.name,
              paid: entry.paid,
              share: entry.share,
              maxAmount: maxMember
            ) {
              onOpenFilteredFeed(model.filterForMember(entry, range: data.periodRange))
            }
          }
        }
      }
    }
  }

  private func byTimeSection(data: StatsModel.ScreenData) -> some View {
    let maxBucket = data.stats.byBucket.map(\.amount).max() ?? .zero
    return SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.tr("stats.byTime"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 8)
          .padding(.bottom, 4)

        ForEach(data.stats.byBucket) { entry in
          StatsBarRowView(
            label: StatsDateHelper.formatBucketLabel(start: entry.start, bucket: data.stats.bucket),
            amount: entry.amount,
            maxAmount: maxBucket,
            fillColor: Tokens.sky
          ) {
            onOpenFilteredFeed(
              model.filterForBucket(
                entry,
                bucketType: data.stats.bucket,
                range: data.periodRange
              )
            )
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4, hasFundAndBudget: true)
    StatsView(
      model: StatsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        statisticsRepository: FakeStatisticsRepository(world: world)
      ),
      onBack: {},
      onOpenFilteredFeed: { _ in }
    )
  }

  #Preview("Empty") {
    let world = FakeWorld(preset: .tripStep0)
    StatsView(
      model: StatsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        statisticsRepository: FakeStatisticsRepository(world: world)
      ),
      onBack: {},
      onOpenFilteredFeed: { _ in }
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    StatsView(
      model: StatsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        statisticsRepository: FakeStatisticsRepository(world: world)
      ),
      onBack: {},
      onOpenFilteredFeed: { _ in }
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    StatsView(
      model: StatsModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        statisticsRepository: FakeStatisticsRepository(world: world)
      ),
      onBack: {},
      onOpenFilteredFeed: { _ in }
    )
  }
#endif
