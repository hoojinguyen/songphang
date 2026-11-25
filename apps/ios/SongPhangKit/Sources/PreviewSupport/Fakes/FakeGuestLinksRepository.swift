#if DEBUG
  public import Domain
  public import Foundation

  public nonisolated struct FakeGuestLinksRepository: GuestLinksRepository {
    private let world: FakeWorld

    public init(world: FakeWorld) {
      self.world = world
    }

    public func status(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
      try await world.guestLinkStatus(groupId: groupId)
    }

    public func createOrRotate(
      groupId: ExpenseGroup.ID,
      rotate: Bool
    ) async throws(AppError) -> GuestLink {
      try await world.createOrRotateGuestLink(groupId: groupId, rotate: rotate)
    }

    public func revoke(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
      try await world.revokeGuestLink(groupId: groupId)
    }

    public func fetchGuestGroup(
      token: String,
      cycleId: TransactionCycleFilter?,
      cursor: String?,
      limit: Int
    ) async throws(AppError) -> GuestGroupSnapshot {
      try await world.fetchGuestGroup(
        token: token,
        cycleId: cycleId,
        cursor: cursor,
        limit: limit
      )
    }

    public func fetchGuestAttachmentData(
      token: String,
      attachmentId: Attachment.ID
    ) async throws(AppError) -> Data {
      try await world.fetchGuestAttachmentData(token: token, attachmentId: attachmentId)
    }
  }
#endif
