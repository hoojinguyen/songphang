import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct GroupFeedView: View {
  @Bindable private var model: GroupFeedModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let onOpenMembers: (ExpenseGroup.ID) -> Void
  private let onOpenBalances: (ExpenseGroup.ID) -> Void
  private let onOpenStats: (ExpenseGroup.ID) -> Void
  private let onOpenQuickEntry: (ExpenseGroup.ID, String?) -> Void
  private let onOpenNewTransactionForm: (ExpenseGroup.ID) -> Void
  private let onOpenEditTransaction: (ExpenseGroup.ID, LedgerTransaction.ID) -> Void
  private let onOpenReceiptCapture: ((ExpenseGroup.ID) -> Void)?
  private let onRemovedFromGroup: () -> Void
  @State private var isFilterSheetOpen = false

  public init(
    model: GroupFeedModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    onOpenMembers: @escaping (ExpenseGroup.ID) -> Void,
    onOpenBalances: @escaping (ExpenseGroup.ID) -> Void,
    onOpenStats: @escaping (ExpenseGroup.ID) -> Void,
    onOpenQuickEntry: @escaping (ExpenseGroup.ID, String?) -> Void,
    onOpenNewTransactionForm: @escaping (ExpenseGroup.ID) -> Void,
    onOpenEditTransaction: @escaping (ExpenseGroup.ID, LedgerTransaction.ID) -> Void,
    onOpenReceiptCapture: ((ExpenseGroup.ID) -> Void)? = nil,
    onRemovedFromGroup: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.onOpenMembers = onOpenMembers
    self.onOpenBalances = onOpenBalances
    self.onOpenStats = onOpenStats
    self.onOpenQuickEntry = onOpenQuickEntry
    self.onOpenNewTransactionForm = onOpenNewTransactionForm
    self.onOpenEditTransaction = onOpenEditTransaction
    self.onOpenReceiptCapture = onOpenReceiptCapture
    self.onRemovedFromGroup = onRemovedFromGroup
  }

  public var body: some View {
    VStack(spacing: 12) {
      if model.refreshError != nil {
        OfflineBanner()
          .padding(.horizontal, 20)
      }

      switch model.state {
      case .loading:
        VStack(spacing: 16) {
          LoadingSkeleton(rowCount: 3, rowHeight: 110)
          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)

      case .failed(let error):
        if case .api(_, 404) = error {
          VStack(spacing: 16) {
            Spacer()
            Text(L10n.tr("common.groupNotFound"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBack)
            Spacer()
          }
          .padding(.horizontal, 20)
        } else {
          VStack {
            Spacer()
            LoadError {
              Task { await model.load() }
            }
            Spacer()
          }
          .padding(.horizontal, 20)
        }

      case .loaded(let data):
        loadedContent(data)
      }
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task(id: model.lastDeletedTransactionId) {
      guard model.lastDeletedTransactionId != nil else { return }
      try? await Task.sleep(for: .seconds(6))
      if !Task.isCancelled { model.lastDeletedTransactionId = nil }
    }
    .overlay(alignment: .bottom) {
      if model.lastDeletedTransactionId != nil {
        HStack(spacing: 12) {
          Text(L10n.tr("expenseForm.deleted"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.surface)
          Button(L10n.tr("expenseForm.undo")) {
            Task {
              await model.undoDelete(
                restoredMessage: L10n.tr("expenseForm.restored"),
                errorMessage: L10n.tr("common.saveError")
              )
            }
          }
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.accent)
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Tokens.ink, in: Capsule())
        .padding(.bottom, 84)
      } else if let toast = model.toastMessage {
        Text(toast)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.surface)
          .padding(.horizontal, 20)
          .padding(.vertical, 14)
          .background(Tokens.ink, in: Capsule())
          .padding(.bottom, 84)
      }
    }
    .navigationBarBackButtonHidden(true)
    .sheet(isPresented: $isFilterSheetOpen) {
      if let data = model.state.value {
        FilterSheetView(
          members: data.members,
          categories: data.categories,
          initialFilter: model.filter,
          onApply: { next in
            Task { await model.applyFilter(next) }
          },
          onClear: {
            Task { await model.clearFilter() }
          },
          onDismiss: { isFilterSheetOpen = false }
        )
      }
    }
    .task {
      await model.load()
    }
    .task {
      await model.listenForEvents(onRemoved: onRemovedFromGroup)
    }
  }

  @ViewBuilder
  private func loadedContent(_ data: GroupFeedModel.ScreenData) -> some View {
    let myBalance =
      data.balances.balances.first(where: { $0.memberId == data.group.myMemberId })?.balance
      ?? .zero
    let canEdit = data.group.role.canWrite && isEmailVerified

    SPScreenHeader(
      title: data.group.name,
      onBack: onBack
    ) {
      Button {
        onOpenMembers(model.groupId)
      } label: {
        HStack(spacing: 2) {
          ForEach(Array(data.members.prefix(4))) { member in
            MemberShapeView(
              shape: member.shape,
              color: member.color,
              name: member.name,
              size: 24,
              showInitial: false
            )
          }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(Tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityLabel(L10n.tr("feed.membersLink"))
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)

    FeedBalanceBlockView(balance: myBalance) {
      onOpenBalances(model.groupId)
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .padding(.horizontal, 20)

    if data.budget?.state == .near || data.budget?.state == .over {
      BudgetBannerView(budget: data.budget) {
        onOpenStats(model.groupId)
      }
      .padding(.horizontal, 20)
    }

    if data.group.myMemberId == nil {
      Button {
        onOpenMembers(model.groupId)
      } label: {
        Text(L10n.tr("feed.chooseShape"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(Tokens.surface)
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 20)
    }

    HStack(spacing: 16) {
      if data.group.role.canWrite {
        Button {
          onOpenMembers(model.groupId)
        } label: {
          Text(L10n.tr("feed.inviteLink"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .frame(minHeight: 36)
        }
        .buttonStyle(.plain)
      }

      Button {
        onOpenStats(model.groupId)
      } label: {
        Text(L10n.tr("feed.tripTotal"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .frame(minHeight: 36)
      }
      .buttonStyle(.plain)
    }

    if !data.transactions.isEmpty || !model.filter.isEmpty {
      VStack(spacing: 8) {
        FeedSearchBarView(
          text: $model.searchText,
          hasModalFilters: model.filter.hasModalFilters,
          onSearchChange: { next in model.updateSearchText(next) },
          onOpenFilters: { isFilterSheetOpen = true }
        )
        FeedFilterChipsView(
          filter: model.filter,
          members: data.members,
          categories: data.categories,
          onChange: { next in
            Task { await model.applyFilter(next) }
          },
          onClear: {
            Task { await model.clearFilter() }
          }
        )
      }
      .padding(.horizontal, 20)
    }

    if data.transactions.isEmpty {
      if model.filter.isEmpty {
        FeedEmptyStreamView(
          members: data.members,
          canInvite: data.group.role.canWrite,
          onSelectSample: { sentence in
            onOpenQuickEntry(model.groupId, sentence)
          },
          onOpenMembers: {
            onOpenMembers(model.groupId)
          }
        )
        .padding(.horizontal, 20)
      } else {
        FeedNoMatchView {
          Task { await model.clearFilter() }
        }
        .padding(.horizontal, 20)
      }
    } else {
      streamList(data: data, canEdit: canEdit)
    }

    if isEmailVerified {
      FeedEntryBarView(
        isOffline: model.isOffline,
        isReadOnly: !data.group.role.canWrite,
        onOpenReceiptCapture: onOpenReceiptCapture.map { handler in
          { handler(model.groupId) }
        },
        onOpenManualForm: {
          onOpenNewTransactionForm(model.groupId)
        },
        onOpenQuickEntry: {
          onOpenQuickEntry(model.groupId, nil)
        }
      )
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
      .padding(.horizontal, 20)
      .padding(.bottom, 12)
    } else {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 12)
    }
  }

  private func streamList(data: GroupFeedModel.ScreenData, canEdit: Bool) -> some View {
    let chronological = Array(data.transactions.reversed())
    return ScrollViewReader { proxy in
      ZStack(alignment: .bottom) {
        ScrollView {
          LazyVStack(spacing: 12) {
            if data.nextCursor != nil {
              Color.clear
                .frame(height: 1)
                .onAppear {
                  Task { await model.loadNextPageIfNeeded() }
                }
            }

            if model.isLoadingMore {
              Text(L10n.tr("feed.loadingOlder"))
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
                .padding(.vertical, 8)
            }

            if model.loadMoreError != nil {
              LoadError(isRetrying: model.isLoadingMore) {
                Task { await model.loadNextPageIfNeeded() }
              }
            }

            ForEach(Array(chronological.enumerated()), id: \.element.id) { index, tx in
              let day = LedgerDateLabels.dayLabel(for: tx.occurredAt)
              let prevDay =
                index > 0
                ? LedgerDateLabels.dayLabel(for: chronological[index - 1].occurredAt)
                : nil

              if day != prevDay {
                Text(day)
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.muted)
                  .padding(.vertical, 4)
              }

              FeedTransactionRowView(
                transaction: tx,
                members: data.members,
                categories: data.categories,
                myMemberId: data.group.myMemberId,
                canEdit: canEdit
              ) {
                onOpenEditTransaction(model.groupId, tx.id)
              }
              .id(tx.id)
              .onAppear {
                if index < chronological.count - 2 {
                  model.isScrolledAwayFromBottom = true
                } else {
                  model.isScrolledAwayFromBottom = false
                }
              }
            }

            Button {
              onOpenBalances(model.groupId)
            } label: {
              Text(L10n.tr("feed.whoOwesWho"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(Tokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 8)
        }
        .task {
          if ProcessInfo.processInfo.arguments.contains("--auto-scroll-large") {
            while model.state.value?.nextCursor != nil {
              await model.loadNextPageIfNeeded()
            }
            if let rows = model.state.value?.transactions.reversed() {
              let list = Array(rows)
              var idx = 0
              while idx < list.count {
                withAnimation(.linear(duration: 0.08)) {
                  proxy.scrollTo(list[idx].id, anchor: .bottom)
                }
                try? await Task.sleep(for: .milliseconds(60))
                idx += 25
              }
              if let last = list.last {
                withAnimation(.linear(duration: 0.08)) {
                  proxy.scrollTo(last.id, anchor: .bottom)
                }
              }
            }
          }
        }

        if model.hasNewItemsPill {
          Button {
            model.hasNewItemsPill = false
            if let newest = chronological.last {
              withAnimation {
                proxy.scrollTo(newest.id, anchor: .bottom)
              }
            }
          } label: {
            Text(L10n.tr("feed.newItems"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.surface)
              .padding(.horizontal, 20)
              .frame(minHeight: 44)
              .background(Tokens.ink)
              .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
          }
          .buttonStyle(.plain)
          .padding(.bottom, 12)
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    GroupFeedView(
      model: GroupFeedModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        eventsRepository: FakeGroupEventsRepository(world: world)
      ),
      onBack: {},
      onOpenMembers: { _ in },
      onOpenBalances: { _ in },
      onOpenStats: { _ in },
      onOpenQuickEntry: { _, _ in },
      onOpenNewTransactionForm: { _ in },
      onOpenEditTransaction: { _, _ in },
      onRemovedFromGroup: {}
    )
  }

  #Preview("Empty") {
    let world = FakeWorld(preset: .tripStep0)
    GroupFeedView(
      model: GroupFeedModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        eventsRepository: FakeGroupEventsRepository(world: world)
      ),
      onBack: {},
      onOpenMembers: { _ in },
      onOpenBalances: { _ in },
      onOpenStats: { _ in },
      onOpenQuickEntry: { _, _ in },
      onOpenNewTransactionForm: { _ in },
      onOpenEditTransaction: { _, _ in },
      onRemovedFromGroup: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    GroupFeedView(
      model: GroupFeedModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        eventsRepository: FakeGroupEventsRepository(world: world)
      ),
      onBack: {},
      onOpenMembers: { _ in },
      onOpenBalances: { _ in },
      onOpenStats: { _ in },
      onOpenQuickEntry: { _, _ in },
      onOpenNewTransactionForm: { _ in },
      onOpenEditTransaction: { _, _ in },
      onRemovedFromGroup: {}
    )
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    GroupFeedView(
      model: GroupFeedModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        budgetRepository: FakeBudgetRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        eventsRepository: FakeGroupEventsRepository(world: world)
      ),
      onBack: {},
      onOpenMembers: { _ in },
      onOpenBalances: { _ in },
      onOpenStats: { _ in },
      onOpenQuickEntry: { _, _ in },
      onOpenNewTransactionForm: { _ in },
      onOpenEditTransaction: { _, _ in },
      onRemovedFromGroup: {}
    )
  }
#endif
