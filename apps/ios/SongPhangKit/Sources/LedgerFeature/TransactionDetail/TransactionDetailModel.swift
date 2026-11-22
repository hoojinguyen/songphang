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
  public let attachmentsRepository: (any AttachmentsRepository)?
  private let currentUserProvider: (@Sendable () -> User?)?
  private let onUnauthorized: (@Sendable () -> Void)?

  public init(
    groupId: ExpenseGroup.ID,
    transactionId: LedgerTransaction.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    categoriesRepository: any CategoriesRepository,
    transactionsRepository: any TransactionsRepository,
    attachmentsRepository: (any AttachmentsRepository)? = nil,
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
    self.currentUserProvider = currentUserProvider
    self.onUnauthorized = onUnauthorized
  }

  public func loadAttachment(id: Attachment.ID) async throws -> Data {
    guard let attachmentsRepository else { return Data() }
    return try await attachmentsRepository.content(groupId: groupId, attachmentId: id)
  }

  public func load() async {
    state = .loading
    actionError = nil
    do throws(AppError) {
      let g = try await groupsRepository.group(id: groupId)
      let tx = try await transactionsRepository.transaction(groupId: groupId, id: transactionId)
      let mems = try await membersRepository.members(groupId: groupId)
      let cats = try await categoriesRepository.list(groupId: groupId)
      let user = currentUserProvider?()
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
    } catch {
      if case .unauthorized = error {
        onUnauthorized?()
      }
      state = .failed(error)
    }
  }

  public func loadComments(initial: Bool = false) async {
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
      if initial {
        comments = res.comments
      } else {
        comments.append(contentsOf: res.comments)
      }
      commentsNextCursor = res.nextCursor
    } catch {
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
      if case .loaded(var cur) = state {
        cur.transaction = updated
        state = .loaded(cur)
      }
    } catch {
      actionError = error
    }
  }
}
