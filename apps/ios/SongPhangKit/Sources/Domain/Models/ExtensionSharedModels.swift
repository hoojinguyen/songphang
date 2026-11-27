public import Foundation

public struct WidgetRecentGroup: Sendable, Hashable, Codable {
  public let id: String
  public let name: String
  public let myBalance: Int64

  public init(id: String, name: String, myBalance: Int64) {
    self.id = id
    self.name = name
    self.myBalance = myBalance
  }
}

public struct WidgetSnapshot: Sendable, Hashable, Codable {
  public var isSignedIn: Bool
  public var appearanceMode: String
  public var hideAmounts: Bool
  public var totalOwedToMe: Int64
  public var totalIOwe: Int64
  public var netBalance: Int64
  public var pendingActionCount: Int
  public var recentGroup: WidgetRecentGroup?
  public var updatedAt: Date

  public init(
    isSignedIn: Bool,
    appearanceMode: String = "system",
    hideAmounts: Bool = false,
    totalOwedToMe: Int64 = 0,
    totalIOwe: Int64 = 0,
    netBalance: Int64 = 0,
    pendingActionCount: Int = 0,
    recentGroup: WidgetRecentGroup? = nil,
    updatedAt: Date = Date()
  ) {
    self.isSignedIn = isSignedIn
    self.appearanceMode = appearanceMode
    self.hideAmounts = hideAmounts
    self.totalOwedToMe = totalOwedToMe
    self.totalIOwe = totalIOwe
    self.netBalance = netBalance
    self.pendingActionCount = pendingActionCount
    self.recentGroup = recentGroup
    self.updatedAt = updatedAt
  }
}

public struct ShareGroupItem: Sendable, Hashable, Codable, Identifiable {
  public let id: String
  public let name: String
  public let role: String
  public let receiptReadingEnabled: Bool
  public let hasLinkedMember: Bool?

  public init(
    id: String,
    name: String,
    role: String,
    receiptReadingEnabled: Bool,
    hasLinkedMember: Bool? = nil
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.receiptReadingEnabled = receiptReadingEnabled
    self.hasLinkedMember = hasLinkedMember
  }

  public var canCreateExpense: Bool {
    role == "owner" || role == "editor"
  }

  public var canUploadTransferProof: Bool {
    if role == "owner" || role == "editor" {
      return true
    }
    if role == "viewer" {
      return hasLinkedMember ?? false
    }
    return false
  }
}

public struct ShareGroupsSnapshot: Sendable, Hashable, Codable {
  public var isSignedIn: Bool
  public var appearanceMode: String
  public var recentGroupId: String?
  public var groups: [ShareGroupItem]

  public init(
    isSignedIn: Bool,
    appearanceMode: String = "system",
    recentGroupId: String? = nil,
    groups: [ShareGroupItem] = []
  ) {
    self.isSignedIn = isSignedIn
    self.appearanceMode = appearanceMode
    self.recentGroupId = recentGroupId
    self.groups = groups
  }
}

public struct ShareInboxManifest: Sendable, Hashable, Codable, Identifiable {
  public enum Mode: String, Sendable, Hashable, Codable {
    case expense
    case transferProof = "transfer_proof"
  }

  public var id: String { batchId }
  public let batchId: String
  public let createdAt: Date
  public let groupId: String
  public let groupName: String
  public let mode: Mode
  public let attachmentIds: [String]
  public let receiptScanId: String?
  public let localImageFilenames: [String]

  public init(
    batchId: String,
    createdAt: Date = Date(),
    groupId: String,
    groupName: String,
    mode: Mode,
    attachmentIds: [String],
    receiptScanId: String? = nil,
    localImageFilenames: [String] = []
  ) {
    self.batchId = batchId
    self.createdAt = createdAt
    self.groupId = groupId
    self.groupName = groupName
    self.mode = mode
    self.attachmentIds = attachmentIds
    self.receiptScanId = receiptScanId
    self.localImageFilenames = localImageFilenames
  }
}
