public import Domain
import Foundation

public enum PersonName {
  public static func display(name: String, isCurrentUser: Bool) -> String {
    isCurrentUser ? L10n.tr("common.you") : name
  }

  public static func display(member: Member, currentMemberId: Member.ID? = nil) -> String {
    let isCurrent = member.isMe || (currentMemberId != nil && member.id == currentMemberId)
    return display(name: member.name, isCurrentUser: isCurrent)
  }
}
