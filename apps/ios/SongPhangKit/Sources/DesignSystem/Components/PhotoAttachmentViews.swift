public import Domain
public import SwiftUI
import UIKit

public struct RemoteAttachmentThumbnail: View {
  private let attachmentId: Attachment.ID
  private let size: CGFloat
  private let cornerRadius: CGFloat
  private let loadContent: @Sendable (Attachment.ID) async throws -> Data

  @State private var image: UIImage?
  @State private var isViewerPresented = false

  public init(
    attachmentId: Attachment.ID,
    size: CGFloat = 64,
    cornerRadius: CGFloat = 16,
    loadContent: @escaping @Sendable (Attachment.ID) async throws -> Data
  ) {
    self.attachmentId = attachmentId
    self.size = size
    self.cornerRadius = cornerRadius
    self.loadContent = loadContent
  }

  public var body: some View {
    Button {
      isViewerPresented = true
    } label: {
      Group {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          ZStack {
            Tokens.sunken
            Image(systemName: "photo")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(Tokens.muted)
          }
        }
      }
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(L10n.tr("attachments.viewPhoto"))
    .task(id: attachmentId) {
      image = nil
      guard let data = try? await loadContent(attachmentId),
        !Task.isCancelled,
        let decoded = UIImage(data: data)
      else { return }
      image = decoded
    }
    .fullScreenCover(isPresented: $isViewerPresented) {
      PhotoViewerSheet(attachmentId: attachmentId, initialImage: image, loadContent: loadContent) {
        isViewerPresented = false
      }
    }
  }
}

public struct PhotoViewerSheet: View {
  private let attachmentId: Attachment.ID
  private let loadContent: @Sendable (Attachment.ID) async throws -> Data
  private let onClose: () -> Void

  @State private var image: UIImage?
  @State private var isLoading = false

  public init(
    attachmentId: Attachment.ID,
    initialImage: UIImage? = nil,
    loadContent: @escaping @Sendable (Attachment.ID) async throws -> Data,
    onClose: @escaping () -> Void
  ) {
    self.attachmentId = attachmentId
    self._image = State(initialValue: initialImage)
    self.loadContent = loadContent
    self.onClose = onClose
  }

  public var body: some View {
    ZStack(alignment: .topTrailing) {
      Color(red: 0.08, green: 0.075, blue: 0.10).ignoresSafeArea()

      VStack {
        Spacer(minLength: 0)
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(20)
        } else if isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Image(systemName: "photo")
            .font(.system(size: 40, weight: .bold))
            .foregroundStyle(Color.white.opacity(0.6))
        }
        Spacer(minLength: 0)
      }

      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(Color.white.opacity(0.2), in: Circle())
      }
      .buttonStyle(.plain)
      .padding(20)
      .accessibilityLabel(L10n.tr("attachments.closePhoto"))
    }
    .task(id: attachmentId) {
      if image != nil { return }
      isLoading = true
      defer { isLoading = false }
      if let data = try? await loadContent(attachmentId),
        !Task.isCancelled,
        let decoded = UIImage(data: data)
      {
        image = decoded
      }
    }
  }
}

public struct PhotoRowView<AddControl: View>: View {
  private let attachments: [Attachment]
  private let readOnly: Bool
  private let isUploading: Bool
  private let errorMessage: String?
  private let loadContent: @Sendable (Attachment.ID) async throws -> Data
  private let onRemove: ((Attachment.ID) -> Void)?
  private let addControl: AddControl

  public init(
    attachments: [Attachment],
    readOnly: Bool = false,
    isUploading: Bool = false,
    errorMessage: String? = nil,
    loadContent: @escaping @Sendable (Attachment.ID) async throws -> Data,
    onRemove: ((Attachment.ID) -> Void)? = nil,
    @ViewBuilder addControl: () -> AddControl
  ) {
    self.attachments = attachments
    self.readOnly = readOnly
    self.isUploading = isUploading
    self.errorMessage = errorMessage
    self.loadContent = loadContent
    self.onRemove = onRemove
    self.addControl = addControl()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(L10n.tr("attachments.label"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
        Spacer(minLength: 8)
        if !readOnly {
          addControl
        }
      }

      if !attachments.isEmpty {
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 64), spacing: 12)],
          alignment: .leading,
          spacing: 12
        ) {
          ForEach(attachments) { attachment in
            ZStack(alignment: .topTrailing) {
              RemoteAttachmentThumbnail(
                attachmentId: attachment.id,
                size: 64,
                cornerRadius: 16,
                loadContent: loadContent
              )
              if !readOnly, let onRemove {
                Button {
                  onRemove(attachment.id)
                } label: {
                  Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Tokens.onInk)
                    .frame(width: 24, height: 24)
                    .background(Tokens.ink, in: Circle())
                    .frame(width: 44, height: 44, alignment: .topTrailing)
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
                .accessibilityLabel(L10n.tr("attachments.removePhoto"))
              }
            }
          }
        }
      }

      if isUploading {
        Text(L10n.tr("receipts.uploading"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }

      if !readOnly, attachments.count >= 3, errorMessage == nil {
        Text(L10n.tr("attachments.maxLimit"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }

      if let errorMessage {
        Text(errorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.debt)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }
}
