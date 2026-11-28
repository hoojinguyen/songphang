public import Domain
public import Foundation
public import SwiftUI

public struct ProofBadgeView: View {
  private let attachmentId: Attachment.ID?
  private let size: CGFloat
  private let loadContent: (@Sendable (Attachment.ID) async throws -> Data)?

  public init(
    attachmentId: Attachment.ID?,
    size: CGFloat = 28,
    loadContent: (@Sendable (Attachment.ID) async throws -> Data)? = nil
  ) {
    self.attachmentId = attachmentId
    self.size = size
    self.loadContent = loadContent
  }

  public var body: some View {
    if let attachmentId, let loadContent {
      RemoteAttachmentThumbnail(
        attachmentId: attachmentId,
        size: size,
        cornerRadius: 8,
        loadContent: loadContent
      )
      .accessibilityLabel(L10n.tr("settlementProof.viewProof"))
    } else {
      HStack(spacing: 4) {
        Image(systemName: "photo")
          .spIconFont(size: 11, weight: .semibold, relativeTo: .caption2)
        Text(L10n.tr("settlementProof.hasProof"))
          .font(Typography.captionBold)
      }
      .foregroundStyle(Tokens.ink)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(Tokens.sunken, in: Capsule())
    }
  }
}
