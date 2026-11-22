#if DEBUG
  public import Domain
  import Foundation

  extension FakeWorld {
    public func listNotifications(cursor: String?, limit: Int) -> (
      notifications: [AppNotification], nextCursor: String?
    ) {
      let sampleNotifications = [
        AppNotification(
          id: AppNotification.ID("00000000-0000-7000-8000-000000000901"),
          kind: "expense_added",
          groupId: ExpenseGroup.ID("00000000-0000-7000-8000-000000000001"),
          groupName: "Đà Lạt 2026",
          read: false,
          createdAt: "2026-11-22T10:00:00.000Z",
          payload: .expenseAdded(
            actorName: "Lan",
            groupName: "Đà Lạt 2026",
            transactionId: "00000000-0000-7000-8000-000000000101",
            description: "Cà phê",
            share: Money(50_000)
          ),
          target: .transaction(
            groupId: ExpenseGroup.ID("00000000-0000-7000-8000-000000000001"),
            transactionId: "00000000-0000-7000-8000-000000000101"
          )
        ),
        AppNotification(
          id: AppNotification.ID("00000000-0000-7000-8000-000000000902"),
          kind: "settlement_requested",
          groupId: ExpenseGroup.ID("00000000-0000-7000-8000-000000000001"),
          groupName: "Đà Lạt 2026",
          read: true,
          createdAt: "2026-11-21T15:30:00.000Z",
          payload: .settlementRequested(
            actorName: "Hoa",
            groupName: "Đà Lạt 2026",
            amount: Money(120_000)
          ),
          target: .balances(groupId: ExpenseGroup.ID("00000000-0000-7000-8000-000000000001"))
        ),
      ]
      return (sampleNotifications, nil)
    }

    public func unreadNotificationCount() -> Int {
      1
    }

    public func markNotificationsRead(ids: [AppNotification.ID]) {}

    public func markAllNotificationsRead() {}

    public func getNotificationSettings() -> NotificationSettings {
      NotificationSettings(emailImmediate: true, emailDigest: false)
    }

    public func updateNotificationSettings(emailImmediate: Bool?, emailDigest: Bool?)
      -> NotificationSettings
    {
      NotificationSettings(
        emailImmediate: emailImmediate ?? true,
        emailDigest: emailDigest ?? false
      )
    }

    public func sendReminder(
      groupId: ExpenseGroup.ID,
      fromMemberId: Member.ID,
      toMemberId: Member.ID
    ) -> SendReminderResult {
      SendReminderResult(
        reminded: [ReminderPair(fromMemberId: fromMemberId, toMemberId: toMemberId)],
        skipped: []
      )
    }

    public func sendAllReminders(groupId: ExpenseGroup.ID) -> SendReminderResult {
      SendReminderResult(reminded: [], skipped: [])
    }

    public func setGroupMuted(id: ExpenseGroup.ID, muted: Bool) -> Bool {
      muted
    }
  }
#endif
