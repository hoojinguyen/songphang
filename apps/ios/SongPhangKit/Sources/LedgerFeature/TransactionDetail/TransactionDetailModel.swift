import DesignSystem
public import Domain
public import Foundation
public import Observation

public struct TransactionDetailData: Sendable, Hashable {
  public var group: ExpenseGroup
  public var transaction: LedgerTransaction
  public var members: [Member]
  public var categories: [GroupCategory]
  public var currentUser: User?

  public init(
    group: ExpenseGroup,
    transaction: LedgerTransaction,
    members: [Member],
    categories: [GroupCategory],
    currentUser: User?
  ) {
    self.group = group
    self.transaction = transaction
    self.members = members
    self.categories = categories
    self.currentUser = currentUser
  }
}

@Observable
public final class TransactionDetailModel: Sendable {
  public let groupId: ExpenseGroup.ID
  public let transactionId: LedgerTransaction.ID

  public private(set) var state: Loadable<TransactionDetailData> = .loading
  public private(set) var comments: [Comment] = []
  public private(set) var isFetchingComments = false
  public private(set) var isFetchingNextComments = false
  public private(set) var commentsNextCursor: String?
  public private(set) var commentsError: AppError?
  public private(set) var isPerformingAction = false
  public private(set) var actionError: AppError?
  public var successToast: String?

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let categoriesRepository: any CategoriesRepository
  private let transactionsRepository: any TransactionsRepository
  private let eventsRepository: (any GroupEventsRepository)?
  public let attachmentsRepository: (any AttachmentsRepository)?
  private let currentUserProvider: (@Sendable () -> User?)?
  private let onUnauthorized: (@Sendable () -> Void)?
  private var pendingSilentRefresh = false
  private var refreshGeneration: UInt64 = 0

  public init(
    groupId: ExpenseGroup.ID,
    transactionId: LedgerTransaction.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    categoriesRepository: any CategoriesRepository,
    transactionsRepository: any TransactionsRepository,
    attachmentsRepository: (any AttachmentsRepository)? = nil,
    eventsRepository: (any GroupEventsRepository)? = nil,
    currentUserProvider: (@Sendable () -> User?)? = nil,
    onUnauthorized: (@Sendable () -> Void)? = nil
  ) {
    self.groupId = groupId
    self.transactionId = transactionId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.categoriesRepository = categoriesRepository
    self.transactionsRepository = transactionsRepository
    self.attachmentsRepository = attachmentsRepository
    self.eventsRepository = eventsRepository
    self.currentUserProvider = currentUserProvider
    self.onUnauthorized = onUnauthorized
  }

  public func loadAttachment(id: Attachment.ID) async throws -> Data {
    guard let attachmentsRepository else { return Data() }
    return try await attachmentsRepository.content(groupId: groupId, attachmentId: id)
  }

  public func load() async {
    let gen = refreshGeneration &+ 1
    refreshGeneration = gen
    state = .loading
    actionError = nil
    do throws(AppError) {
      let g = try await groupsRepository.group(id: groupId)
      let tx = try await transactionsRepository.transaction(groupId: groupId, id: transactionId)
      let mems = try await membersRepository.members(groupId: groupId)
      let cats = try await categoriesRepository.list(groupId: groupId)
      let user = currentUserProvider?()
      guard refreshGeneration == gen, !Task.isCancelled else { return }
      state = .loaded(
        TransactionDetailData(
          group: g,
          transaction: tx,
          members: mems,
          categories: cats,
          currentUser: user
        )
      )
      await loadComments(initial: true)
      if pendingSilentRefresh {
        pendingSilentRefresh = false
        await refreshSilently(resources: nil)
      }
    } catch {
      guard refreshGeneration == gen, !Task.isCancelled else { return }
      if case .unauthorized = error {
        onUnauthorized?()
      }
      state = .failed(error)
    }
  }

  public func listenForEvents(onRemoved: @escaping () -> Void) async {
    guard let eventsRepository else { return }
    let stream = eventsRepository.events(groupId: groupId)
    for await event in stream {
      if Task.isCancelled { return }
      switch event {
      case .removed:
        onRemoved()
        return
      case .reconnected:
        await refreshSilently(resources: nil)
      case .changed(let resources):
        await refreshSilently(resources: resources)
      }
    }
  }

  public func refreshSilently(resources: [String]? = nil) async {
    guard case .loaded = state else {
      pendingSilentRefresh = true
      return
    }
    let gen = refreshGeneration &+ 1
    refreshGeneration = gen
    let shouldReloadAll = resources == nil
    do throws(AppError) {
      let fetchedGroup =
        (shouldReloadAll || resources?.contains("group") == true)
        ? try await groupsRepository.group(id: groupId) : nil
      let fetchedMembers =
        (shouldReloadAll || resources?.contains("members") == true)
        ? try await membersRepository.members(groupId: groupId) : nil
      let fetchedCategories =
        (shouldReloadAll || resources?.contains("categories") == true)
        ? try await categoriesRepository.list(groupId: groupId) : nil

      var fetchedTx: LedgerTransaction?
      var fetchedCommentsRes: (comments: [Comment], nextCursor: String?)?
      if shouldReloadAll
        || resources?.contains("transactions") == true
        || resources?.contains("comments") == true
        || resources?.contains("attachments") == true
      {
        fetchedTx = try await transactionsRepository.transaction(
          groupId: groupId,
          id: transactionId
        )
        let previouslyLoadedCount = comments.count
        var accumulated: [Comment] = []
        var nextCursor: String? = nil
        let page1 = try await transactionsRepository.comments(
          groupId: groupId,
          id: transactionId,
          cursor: nil,
          limit: 50
        )
        accumulated.append(contentsOf: page1.comments)
        nextCursor = page1.nextCursor

        while let cursor = nextCursor, accumulated.count < previouslyLoadedCount {
          let nextPage = try await transactionsRepository.comments(
            groupId: groupId,
            id: transactionId,
            cursor: cursor,
            limit: 50
          )
          accumulated.append(contentsOf: nextPage.comments)
          nextCursor = nextPage.nextCursor
        }

        fetchedCommentsRes = (comments: accumulated, nextCursor: nextCursor)
      }

      guard !Task.isCancelled, refreshGeneration == gen, case .loaded(var current) = state else {
        return
      }
      if let fetchedGroup { current.group = fetchedGroup }
      if let fetchedMembers { current.members = fetchedMembers }
      if let fetchedCategories { current.categories = fetchedCategories }
      if let fetchedTx { current.transaction = fetchedTx }
      current.currentUser = currentUserProvider?()
      state = .loaded(current)

      if let fetchedCommentsRes {
        comments = fetchedCommentsRes.comments
        commentsNextCursor = fetchedCommentsRes.nextCursor
        commentsError = nil
      }
    } catch {
      guard refreshGeneration == gen, !Task.isCancelled else { return }
      if case .unauthorized = error {
        onUnauthorized?()
      }
    }
  }

  public func loadComments(initial: Bool = false) async {
    let gen = refreshGeneration
    guard !isFetchingComments else { return }
    if initial {
      isFetchingComments = true
      commentsError = nil
    } else {
      guard commentsNextCursor != nil, !isFetchingNextComments else { return }
      isFetchingNextComments = true
    }
    defer {
      isFetchingComments = false
      isFetchingNextComments = false
    }

    do throws(AppError) {
      let cursor = initial ? nil : commentsNextCursor
      let res = try await transactionsRepository.comments(
        groupId: groupId,
        id: transactionId,
        cursor: cursor,
        limit: 50
      )
      guard refreshGeneration == gen, !Task.isCancelled else { return }
      if initial {
        comments = res.comments
      } else {
        comments.append(contentsOf: res.comments)
      }
      commentsNextCursor = res.nextCursor
    } catch {
      guard refreshGeneration == gen, !Task.isCancelled else { return }
      if case .unauthorized = error {
        onUnauthorized?()
      }
      commentsError = error
    }
  }

  public func addComment(body: String) async -> Bool {
    guard !isPerformingAction else { return false }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      let key = IdempotencyKey(rawValue: UUID().uuidString)
      let comment = try await transactionsRepository.addComment(
        groupId: groupId,
        id: transactionId,
        body: body,
        key: key
      )
      refreshGeneration += 1
      comments.append(comment)
      if case .loaded(var cur) = state {
        cur.transaction.commentCount += 1
        state = .loaded(cur)
      }
      return true
    } catch {
      actionError = error
      return false
    }
  }

  public func deleteComment(id: Comment.ID) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      try await transactionsRepository.deleteComment(
        groupId: groupId,
        id: transactionId,
        commentId: id
      )
      refreshGeneration += 1
      comments.removeAll(where: { $0.id == id })
      if case .loaded(var cur) = state {
        cur.transaction.commentCount = max(0, cur.transaction.commentCount - 1)
        state = .loaded(cur)
      }
    } catch {
      actionError = error
    }
  }

  public func openDispute(reason: String) async -> Bool {
    guard !isPerformingAction else { return false }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      let dispute = try await transactionsRepository.openDispute(
        groupId: groupId,
        id: transactionId,
        reason: reason
      )
      refreshGeneration += 1
      if case .loaded(var cur) = state {
        cur.transaction.dispute = dispute
        state = .loaded(cur)
      }
      return true
    } catch {
      actionError = error
      return false
    }
  }

  public func resolveDispute() async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      try await transactionsRepository.resolveDispute(groupId: groupId, id: transactionId)
      refreshGeneration += 1
      if case .loaded(var cur) = state {
        cur.transaction.dispute = nil
        state = .loaded(cur)
      }
      successToast = L10n.tr("transactionView.disputeResolved")
    } catch {
      actionError = error
    }
  }

  public func approve() async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      let updated = try await transactionsRepository.approve(groupId: groupId, id: transactionId)
      refreshGeneration += 1
      if case .loaded(var cur) = state {
        cur.transaction = updated
        state = .loaded(cur)
      }
    } catch {
      actionError = error
    }
  }

  public func reject(note: String?) async {
    guard !isPerformingAction else { return }
    isPerformingAction = true
    actionError = nil
    defer { isPerformingAction = false }

    do throws(AppError) {
      let updated = try await transactionsRepository.reject(
        groupId: groupId,
        id: transactionId,
        note: note
      )
      refreshGeneration += 1
      if case .loaded(var cur) = state {
        cur.transaction = updated
        state = .loaded(cur)
      }
    } catch {
      actionError = error
    }
  }
}
