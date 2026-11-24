#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public func listNotifications(cursor: String?, limit: Int) async throws(AppError) -> (
      notifications: [AppNotification], nextCursor: String?
    ) {
      try await simulateNetwork()
      return (storedNotifications, nil)
    }

    public func unreadNotificationCount() async throws(AppError) -> Int {
      try await simulateNetwork()
      return storedNotifications.filter { !$0.read }.count
    }

    public func markNotificationsRead(ids: [AppNotification.ID]) async throws(AppError) {
      try await simulateNetwork()
      let idSet = Set(ids)
      storedNotifications = storedNotifications.map { notif in
        if idSet.contains(notif.id) {
          return AppNotification(
            id: notif.id,
            kind: notif.kind,
            groupId: notif.groupId,
            groupName: notif.groupName,
            read: true,
            createdAt: notif.createdAt,
            payload: notif.payload,
            target: notif.target
          )
        }
        return notif
      }
    }

    public func markAllNotificationsRead() async throws(AppError) {
      try await simulateNetwork()
      storedNotifications = storedNotifications.map { notif in
        AppNotification(
          id: notif.id,
          kind: notif.kind,
          groupId: notif.groupId,
          groupName: notif.groupName,
          read: true,
          createdAt: notif.createdAt,
          payload: notif.payload,
          target: notif.target
        )
      }
    }

    public func getNotificationSettings() async throws(AppError) -> NotificationSettings {
      try await simulateNetwork()
      return notificationSettings
    }

    public func updateNotificationSettings(emailImmediate: Bool?, emailDigest: Bool?)
      async throws(AppError) -> NotificationSettings
    {
      try await simulateNetwork()
      let updated = NotificationSettings(
        emailImmediate: emailImmediate ?? notificationSettings.emailImmediate,
        emailDigest: emailDigest ?? notificationSettings.emailDigest
      )
      self.notificationSettings = updated
      return updated
    }

    public func sendReminder(
      groupId: ExpenseGroup.ID,
      fromMemberId: Member.ID,
      toMemberId: Member.ID
    ) async throws(AppError) -> SendReminderResult {
      try await simulateNetwork()
      return SendReminderResult(
        reminded: [ReminderPair(fromMemberId: fromMemberId, toMemberId: toMemberId)],
        skipped: []
      )
    }

    public func sendAllReminders(groupId: ExpenseGroup.ID) async throws(AppError)
      -> SendReminderResult
    {
      try await simulateNetwork()
      return SendReminderResult(reminded: [], skipped: [])
    }

    public func setGroupMuted(id: ExpenseGroup.ID, muted: Bool) async throws(AppError) -> Bool {
      try await simulateNetwork()
      if var group = groupsById[id] {
        group.muted = muted
        groupsById[id] = group
      }
      return muted
    }
  }
#endif
