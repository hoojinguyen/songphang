import DesignSystem
public import Domain
import Foundation
public import Observation

public struct ActivityViewData: Sendable, Equatable {
  public var group: ExpenseGroup
  public var members: [Member]
  public var items: [ActivityItem]
  public var nextCursor: String?

  public init(
    group: ExpenseGroup,
    members: [Member],
    items: [ActivityItem],
    nextCursor: String?
  ) {
    self.group = group
    self.members = members
    self.items = items
    self.nextCursor = nextCursor
  }
}

@Observable
public final class ActivityModel {
  public let groupId: ExpenseGroup.ID
  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let activityRepository: any ActivityRepository
  private let transactionsRepository: any TransactionsRepository
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<ActivityViewData> = .loading
  public private(set) var refreshError: AppError?
  public private(set) var isNotFound = false
  public private(set) var isFetchingNextPage = false
  public private(set) var hasNextPageError = false
  public private(set) var restoringEntityId: String?
  public private(set) var restoreErrorEntityId: String?
  public var toastMessage: String?

  public init(
    groupId: ExpenseGroup.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    activityRepository: any ActivityRepository,
    transactionsRepository: any TransactionsRepository,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.activityRepository = activityRepository
    self.transactionsRepository = transactionsRepository
    self.onUnauthorized = onUnauthorized
  }

  public func load() async {
    isNotFound = false
    if let cachedGroup = await groupsRepository.lastKnownGroup(id: groupId),
      let cachedMembers = await membersRepository.lastKnownMembers(groupId: groupId),
      let cachedPage = await activityRepository.lastKnownFirstPage(groupId: groupId)
    {
      state = .loaded(
        ActivityViewData(
          group: cachedGroup,
          members: cachedMembers,
          items: cachedPage.items,
          nextCursor: cachedPage.nextCursor
        )
      )
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedPage = activityRepository.page(groupId: groupId, cursor: nil)

      let (group, members, firstPage) = try await (
        fetchedGroup, fetchedMembers, fetchedPage
      )
      state = .loaded(
        ActivityViewData(
          group: group,
          members: members,
          items: firstPage.items,
          nextCursor: firstPage.nextCursor
        )
      )
      refreshError = nil
    } catch let error as AppError {
      handleError(error)
    } catch {
      handleError(.unexpected)
    }
  }

  public func loadNextPageIfNeeded(currentItem: ActivityItem) async {
    guard let data = state.value,
      let cursor = data.nextCursor,
      !isFetchingNextPage
    else {
      return
    }
    let thresholdIndex = max(0, data.items.count - 3)
    guard let itemIndex = data.items.firstIndex(where: { $0.id == currentItem.id }),
      itemIndex >= thresholdIndex
    else {
      return
    }
    await fetchNextPage(cursor: cursor)
  }

  public func retryNextPage() async {
    guard let cursor = state.value?.nextCursor, !isFetchingNextPage else { return }
    await fetchNextPage(cursor: cursor)
  }

  private func fetchNextPage(cursor: String) async {
    isFetchingNextPage = true
    hasNextPageError = false
    defer { isFetchingNextPage = false }

    do throws(AppError) {
      let nextPage = try await activityRepository.page(groupId: groupId, cursor: cursor)
      guard var data = state.value else { return }
      let existingIds = Set(data.items.map(\.id))
      let uniqueNew = nextPage.items.filter { !existingIds.contains($0.id) }
      data.items.append(contentsOf: uniqueNew)
      data.nextCursor = nextPage.nextCursor
      state = .loaded(data)
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      hasNextPageError = true
    }
  }

  public func restore(entityId: String) async {
    guard restoringEntityId == nil else { return }
    restoringEntityId = entityId
    restoreErrorEntityId = nil
    defer { restoringEntityId = nil }

    do throws(AppError) {
      _ = try await transactionsRepository.restore(
        groupId: groupId,
        id: LedgerTransaction.ID(entityId)
      )
      toastMessage = L10n.tr("expenseForm.restored")
      await load()
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      restoreErrorEntityId = entityId
    }
  }

  private func handleError(_ error: AppError) {
    if error == .unauthorized {
      onUnauthorized()
      return
    }
    if case .api(_, 404) = error {
      isNotFound = true
      state = .failed(error)
      return
    }
    if case .loaded = state {
      refreshError = error
    } else {
      state = .failed(error)
    }
  }
}
