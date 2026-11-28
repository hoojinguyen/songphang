import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct GroupFeedView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Bindable private var model: GroupFeedModel
  private let showHeader: Bool
  private let isEmailVerified: Bool
  private let unreadNotificationCount: Int
  private let onBack: () -> Void
  private let onOpenMembers: (ExpenseGroup.ID) -> Void
  private let onOpenBalances: (ExpenseGroup.ID) -> Void
  private let onOpenStats: (ExpenseGroup.ID) -> Void
  private let onOpenQuickEntry: (ExpenseGroup.ID, String?) -> Void
  private let onOpenNewTransactionForm: (ExpenseGroup.ID) -> Void
  private let onOpenEditTransaction: (ExpenseGroup.ID, LedgerTransaction.ID) -> Void
  private let onOpenTransactionDetail: ((ExpenseGroup.ID, LedgerTransaction.ID) -> Void)?
  private let onOpenReceiptCapture: ((ExpenseGroup.ID) -> Void)?
  private let onOpenNotifications: (() -> Void)?
  private let onRemovedFromGroup: () -> Void
  @State private var isFilterSheetOpen = false
  @State private var rowActionFeedbackTick = 0

  public init(
    model: GroupFeedModel,
    showHeader: Bool = true,
    isEmailVerified: Bool = true,
    unreadNotificationCount: Int = 0,
    onBack: @escaping () -> Void,
    onOpenMembers: @escaping (ExpenseGroup.ID) -> Void,
    onOpenBalances: @escaping (ExpenseGroup.ID) -> Void,
    onOpenStats: @escaping (ExpenseGroup.ID) -> Void,
    onOpenQuickEntry: @escaping (ExpenseGroup.ID, String?) -> Void,
    onOpenNewTransactionForm: @escaping (ExpenseGroup.ID) -> Void,
    onOpenEditTransaction: @escaping (ExpenseGroup.ID, LedgerTransaction.ID) -> Void,
    onOpenTransactionDetail: ((ExpenseGroup.ID, LedgerTransaction.ID) -> Void)? = nil,
    onOpenReceiptCapture: ((ExpenseGroup.ID) -> Void)? = nil,
    onOpenNotifications: (() -> Void)? = nil,
    onRemovedFromGroup: @escaping () -> Void
  ) {
    self.model = model
    self.showHeader = showHeader
    self.isEmailVerified = isEmailVerified
    self.unreadNotificationCount = unreadNotificationCount
    self.onBack = onBack
    self.onOpenMembers = onOpenMembers
    self.onOpenBalances = onOpenBalances
    self.onOpenStats = onOpenStats
    self.onOpenQuickEntry = onOpenQuickEntry
    self.onOpenNewTransactionForm = onOpenNewTransactionForm
    self.onOpenEditTransaction = onOpenEditTransaction
    self.onOpenTransactionDetail = onOpenTransactionDetail
    self.onOpenReceiptCapture = onOpenReceiptCapture
    self.onOpenNotifications = onOpenNotifications
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
        ScrollView {
          VStack(spacing: 12) {
            BalanceCardSkeleton()
            LinkRowSkeleton()
            SearchFieldSkeleton()
            TransactionRowSkeleton()
            TransactionRowSkeleton()
            TransactionRowSkeleton()
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
        }
        .scrollDisabled(true)

        composerBar(isPendingLoad: true, group: nil)

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
    .spFeedback(.selection, trigger: rowActionFeedbackTick)
    .confirmationToast(feedToastBinding, bottomPadding: 84)
    .modifier(
      ConditionalFeedNavBar(
        isEnabled: showHeader,
        title: model.state.value?.group.name ?? "",
        members: model.state.value?.members ?? [],
        groupId: model.groupId,
        unreadNotificationCount: unreadNotificationCount,
        onOpenNotifications: onOpenNotifications,
        onOpenMembers: onOpenMembers
      )
    )
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
      #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--open-filter-sheet") {
          isFilterSheetOpen = true
        }
      #endif
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

    FeedBalanceBlockView(
      balance: myBalance,
      individualBalance: data.group.myIndividualBalance,
      householdName: data.group.householdName
    ) {
      onOpenBalances(model.groupId)
    }
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

    let hasSearchOrModal =
      !data.transactions.isEmpty || model.filter.query != nil || model.filter.hasModalFilters
    let hasCycles = data.cyclesOverview?.cycles.isEmpty == false

    if hasSearchOrModal || hasCycles {
      VStack(spacing: 8) {
        if hasSearchOrModal {
          FeedSearchBarView(
            text: $model.searchText,
            hasModalFilters: model.filter.hasModalFilters,
            activeModalFilterCount: model.filter.activeModalFilterCount,
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
        if let cyclesOverview = data.cyclesOverview, !cyclesOverview.cycles.isEmpty {
          CycleFilterChipView(
            overview: cyclesOverview,
            selectedCycle: model.filter.cycleId,
            onSelectCycle: { next in
              Task { await model.selectCycle(next) }
            }
          )
        }
      }
      .padding(.horizontal, 20)
    }

    if data.transactions.isEmpty {
      let isEmptyCurrentOrUnfiltered =
        model.filter.query == nil && !model.filter.hasModalFilters
        && (model.filter.cycleId == nil || model.filter.cycleId == .current)
      if isEmptyCurrentOrUnfiltered {
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

    composerBar(isPendingLoad: false, group: data.group)
  }

  private var feedToastBinding: Binding<ToastMessage?> {
    Binding(
      get: {
        if let deletedId = model.lastDeletedTransactionId {
          return ToastMessage(
            id: model.undoToastPresentationId,
            text: L10n.tr("expenseForm.deleted"),
            actionLabel: L10n.tr("expenseForm.undo"),
            action: {
              Task {
                await model.undoDelete(
                  id: deletedId,
                  restoredMessage: L10n.tr("expenseForm.restored"),
                  errorMessage: L10n.tr("common.saveError")
                )
              }
            },
            autoDismissDelay: .seconds(6)
          )
        }
        if let text = model.toastMessage {
          return ToastMessage(id: model.toastPresentationId, text: text)
        }
        return nil
      },
      set: { next in
        if next == nil {
          model.lastDeletedTransactionId = nil
          model.toastMessage = nil
        }
      }
    )
  }

  @ViewBuilder
  private func composerBar(isPendingLoad: Bool, group: ExpenseGroup?) -> some View {
    if isPendingLoad {
      FeedEntryBarView(
        isOffline: false,
        isReadOnly: false,
        isPendingLoad: true,
        onOpenReceiptCapture: onOpenReceiptCapture.map { handler in
          { handler(model.groupId) }
        },
        onOpenManualForm: {},
        onOpenQuickEntry: {}
      )
      .padding(.horizontal, 20)
      .padding(.bottom, 12)
    } else if isEmailVerified {
      if group?.isArchived == true {
        Text(L10n.tr("groups.archivedBanner"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .padding(.horizontal, 20)
          .padding(.bottom, 12)
      } else {
        FeedEntryBarView(
          isOffline: model.isOffline,
          isReadOnly: group?.role.canWrite != true,
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
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
      }
    } else {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.onAccent)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 12)
    }
  }

  private func streamList(data: GroupFeedModel.ScreenData, canEdit: Bool) -> some View {
    let chronological = Array(data.transactions.reversed())
    return ScrollViewReader { proxy in
      ZStack(alignment: .bottom) {
        List {
          if data.nextCursor != nil {
            Color.clear
              .frame(height: 1)
              .listRowInsets(EdgeInsets())
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
              .onAppear {
                Task { await model.loadNextPageIfNeeded() }
              }
          }

          if model.isLoadingMore {
            Text(L10n.tr("feed.loadingOlder"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
              .frame(maxWidth: .infinity, alignment: .center)
              .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }

          if model.loadMoreError != nil {
            LoadError(isRetrying: model.isLoadingMore) {
              Task { await model.loadNextPageIfNeeded() }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            FeedTransactionRowView(
              transaction: tx,
              members: data.members,
              categories: data.categories,
              myMemberId: data.group.myMemberId,
              canEdit: canEdit,
              loadAttachment: { id in
                try await model.loadAttachment(id: id)
              }
            ) {
              if let onOpenTransactionDetail {
                onOpenTransactionDetail(model.groupId, tx.id)
              } else {
                onOpenEditTransaction(model.groupId, tx.id)
              }
            }
            .id(tx.id)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .leading) {
              if !data.group.isArchived && !model.isOffline && canEdit
                && tx.approval.status != .rejected
              {
                Button {
                  rowActionFeedbackTick &+= 1
                  onOpenEditTransaction(model.groupId, tx.id)
                } label: {
                  Label(L10n.tr("transactionView.editLink"), systemImage: "pencil")
                }
                .tint(Color(red: 0.18, green: 0.45, blue: 0.85))
              }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              if !data.group.isArchived && !model.isOffline && canEdit {
                Button(role: .destructive) {
                  rowActionFeedbackTick &+= 1
                  Task {
                    await model.deleteTransaction(
                      tx.id,
                      successMessage: L10n.tr("expenseForm.deleted"),
                      errorMessage: L10n.tr("common.saveError")
                    )
                  }
                } label: {
                  Label(L10n.tr("members.delete"), systemImage: "trash")
                }
              }
              Button {
                rowActionFeedbackTick &+= 1
                if let onOpenTransactionDetail {
                  onOpenTransactionDetail(model.groupId, tx.id)
                } else {
                  onOpenEditTransaction(model.groupId, tx.id)
                }
              } label: {
                Label(L10n.tr("ios.common.detail"), systemImage: "info.circle")
              }
              .tint(Color(red: 0.32, green: 0.30, blue: 0.38))
            }
            .contextMenu {
              if !data.group.isArchived && !model.isOffline && canEdit
                && tx.approval.status != .rejected
              {
                Button {
                  rowActionFeedbackTick &+= 1
                  onOpenEditTransaction(model.groupId, tx.id)
                } label: {
                  Label(L10n.tr("transactionView.editLink"), systemImage: "pencil")
                }
              }
              if !data.group.isArchived && !model.isOffline && canEdit {
                Button(role: .destructive) {
                  rowActionFeedbackTick &+= 1
                  Task {
                    await model.deleteTransaction(
                      tx.id,
                      successMessage: L10n.tr("expenseForm.deleted"),
                      errorMessage: L10n.tr("common.saveError")
                    )
                  }
                } label: {
                  Label(L10n.tr("members.delete"), systemImage: "trash")
                }
              }
              Button {
                rowActionFeedbackTick &+= 1
                if let onOpenTransactionDetail {
                  onOpenTransactionDetail(model.groupId, tx.id)
                } else {
                  onOpenEditTransaction(model.groupId, tx.id)
                }
              } label: {
                Label(L10n.tr("ios.common.detail"), systemImage: "info.circle")
              }
            }
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
          .frame(maxWidth: .infinity, alignment: .center)
          .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 16, trailing: 20))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .task {
          if ProcessInfo.processInfo.arguments.contains("--auto-scroll-large") {
            while model.state.value?.nextCursor != nil {
              await model.loadNextPageIfNeeded()
            }
            if let rows = model.state.value?.transactions.reversed() {
              let list = Array(rows)
              var idx = 0
              while idx < list.count {
                Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
                  proxy.scrollTo(list[idx].id, anchor: .bottom)
                }
                try? await Task.sleep(for: .milliseconds(60))
                idx += 25
              }
              if let last = list.last {
                Motion.withAnimation(Motion.quick, reduceMotion: reduceMotion) {
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
              Motion.withAnimation(Motion.smooth, reduceMotion: reduceMotion) {
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

private struct ConditionalFeedNavBar: ViewModifier {
  let isEnabled: Bool
  let title: String
  let members: [Member]
  let groupId: ExpenseGroup.ID
  let unreadNotificationCount: Int
  let onOpenNotifications: (() -> Void)?
  let onOpenMembers: (ExpenseGroup.ID) -> Void

  func body(content: Content) -> some View {
    if isEnabled {
      content
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .topBarTrailing) {
            if let onOpenNotifications {
              NotificationBellButton(
                unreadCount: unreadNotificationCount,
                onOpen: onOpenNotifications
              )
            }
            Button {
              onOpenMembers(groupId)
            } label: {
              HStack(spacing: 2) {
                ForEach(Array(members.prefix(4))) { member in
                  MemberShapeView(member: member, size: 22)
                }
              }
            }
            .accessibilityLabel(L10n.tr("feed.membersLink"))
          }
        }
    } else {
      content
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
