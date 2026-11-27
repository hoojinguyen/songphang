import DesignSystem
import Domain
import Foundation
import UIKit

#if canImport(WidgetKit)
  import WidgetKit
#endif

@MainActor
enum ExtensionStateSync {
  static func syncSignedIn(
    overview: OverviewSummary?,
    groups: [ExpenseGroup],
    features: ServerFeatures?,
    appearanceMode: String
  ) {
    let activeGroups = groups.filter { !$0.isArchived }
    let fallbackGroups: [OverviewGroupBalance] = (overview?.groupBalances ?? []).filter {
      $0.archivedAt == nil
    }
    let recentGroupWidget: WidgetRecentGroup? =
      activeGroups.first.map {
        WidgetRecentGroup(id: $0.id.rawValue, name: $0.name, myBalance: $0.myBalance.amount)
      }
      ?? fallbackGroups.first.map {
        WidgetRecentGroup(
          id: $0.groupId.rawValue,
          name: $0.groupName,
          myBalance: $0.myBalance.amount
        )
      }
    let hideAmounts = ExtensionSharedStore.shared.readWidgetHideAmounts()

    let widgetSnapshot = WidgetSnapshot(
      isSignedIn: true,
      appearanceMode: appearanceMode,
      hideAmounts: hideAmounts,
      totalOwedToMe: overview?.totalOwedToMe.amount ?? 0,
      totalIOwe: overview?.totalIOwe.amount ?? 0,
      netBalance: overview?.netBalance.amount ?? 0,
      pendingActionCount: (overview?.pendingActions.count ?? 0)
        + (overview?.dueRecurringCount ?? 0),
      recentGroup: recentGroupWidget,
      updatedAt: Date()
    )
    ExtensionSharedStore.shared.writeWidgetSnapshot(widgetSnapshot)

    let shareItems: [ShareGroupItem] =
      if !activeGroups.isEmpty {
        activeGroups.map { group in
          ShareGroupItem(
            id: group.id.rawValue,
            name: group.name,
            role: group.role.code,
            receiptReadingEnabled: features?.receiptReading ?? false,
            hasLinkedMember: group.myMemberId != nil
          )
        }
      } else {
        fallbackGroups.map { gb in
          ShareGroupItem(
            id: gb.groupId.rawValue,
            name: gb.groupName,
            role: gb.role.code,
            receiptReadingEnabled: features?.receiptReading ?? false,
            hasLinkedMember: gb.myMemberId != nil
          )
        }
      }

    let shareGroupsSnapshot = ShareGroupsSnapshot(
      isSignedIn: true,
      appearanceMode: appearanceMode,
      recentGroupId: recentGroupWidget?.id,
      groups: shareItems
    )
    ExtensionSharedStore.shared.writeShareGroups(shareGroupsSnapshot)

    if let recent = activeGroups.first {
      syncShortcutItems(id: recent.id, name: recent.name, canWrite: recent.role.canWrite)
    } else if let fallback = fallbackGroups.first {
      syncShortcutItems(
        id: fallback.groupId,
        name: fallback.groupName,
        canWrite: fallback.role.canWrite
      )
    } else {
      UIApplication.shared.shortcutItems = []
    }
    reloadWidgets()
  }

  static func clearSignedOut() {
    ExtensionSharedStore.shared.clearAll()
    UIApplication.shared.shortcutItems = []
    reloadWidgets()
  }

  static func reloadWidgets() {
    #if canImport(WidgetKit)
      WidgetCenter.shared.reloadAllTimelines()
    #endif
  }

  private static func syncShortcutItems(
    id: ExpenseGroup.ID,
    name: String,
    canWrite: Bool
  ) {
    let userInfo: [String: any NSSecureCoding] = [
      "groupId": id.rawValue as NSString
    ]
    var items: [UIApplicationShortcutItem] = []
    if canWrite {
      items.append(
        UIApplicationShortcutItem(
          type: ShortcutEventBridge.ShortcutKind.quickEntry.rawValue,
          localizedTitle: L10n.tr("ios.shortcuts.quickEntry"),
          localizedSubtitle: name,
          icon: UIApplicationShortcutIcon(systemImageName: "bolt.fill"),
          userInfo: userInfo
        )
      )
      items.append(
        UIApplicationShortcutItem(
          type: ShortcutEventBridge.ShortcutKind.expenseNew.rawValue,
          localizedTitle: L10n.tr("ios.shortcuts.expenseNew"),
          localizedSubtitle: name,
          icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
          userInfo: userInfo
        )
      )
    }
    items.append(
      UIApplicationShortcutItem(
        type: ShortcutEventBridge.ShortcutKind.balances.rawValue,
        localizedTitle: L10n.tr("ios.shortcuts.balances"),
        localizedSubtitle: name,
        icon: UIApplicationShortcutIcon(systemImageName: "arrow.left.arrow.right.circle.fill"),
        userInfo: userInfo
      )
    )
    UIApplication.shared.shortcutItems = items
  }
}
