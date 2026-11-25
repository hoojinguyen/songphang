public import Domain
public import Foundation
public import PhotosUI
public import SwiftUI

public struct TransferProofInputSection: View {
  @Binding private var channel: PaymentChannel?
  @Binding private var note: String
  private let attachments: [Attachment]
  private let maxAttachments: Int
  private let isDisabled: Bool
  private let isUploading: Bool
  private let errorMessage: String?
  private let loadContent: (@Sendable (Attachment.ID) async throws -> Data)?
  private let onUploadData: (Data) async -> Void
  private let onRemoveAttachment: (Attachment.ID) -> Void

  @State private var pickedPhotoItem: PhotosPickerItem?

  public init(
    channel: Binding<PaymentChannel?>,
    note: Binding<String>,
    attachments: [Attachment],
    maxAttachments: Int = 1,
    isDisabled: Bool = false,
    isUploading: Bool = false,
    errorMessage: String? = nil,
    loadContent: (@Sendable (Attachment.ID) async throws -> Data)? = nil,
    onUploadData: @escaping (Data) async -> Void,
    onRemoveAttachment: @escaping (Attachment.ID) -> Void
  ) {
    self._channel = channel
    self._note = note
    self.attachments = attachments
    self.maxAttachments = maxAttachments
    self.isDisabled = isDisabled
    self.isUploading = isUploading
    self.errorMessage = errorMessage
    self.loadContent = loadContent
    self.onUploadData = onUploadData
    self.onRemoveAttachment = onRemoveAttachment
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("settlementProof.channelLabel"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
        ChannelPillPicker(selection: $channel, isDisabled: isDisabled)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("settlementProof.photoLabel"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)

        if !attachments.isEmpty {
          HStack(spacing: 10) {
            ForEach(attachments) { attachment in
              ZStack(alignment: .topTrailing) {
                if let loadContent {
                  RemoteAttachmentThumbnail(
                    attachmentId: attachment.id,
                    size: 64,
                    cornerRadius: 16,
                    loadContent: loadContent
                  )
                } else {
                  RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Tokens.sunken)
                    .frame(width: 64, height: 64)
                    .overlay {
                      Image(systemName: "photo")
                        .foregroundStyle(Tokens.muted)
                    }
                }

                Button {
                  onRemoveAttachment(attachment.id)
                } label: {
                  Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Tokens.onInk)
                    .frame(width: 24, height: 24)
                    .background(Tokens.ink, in: Circle())
                    .frame(width: 44, height: 44, alignment: .topTrailing)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .offset(x: 8, y: -8)
                .accessibilityLabel(L10n.tr("settlementProof.removePhoto"))
              }
            }
          }
        }

        if attachments.count < maxAttachments {
          PhotosPicker(
            selection: $pickedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
          ) {
            HStack(spacing: 8) {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 15, weight: .semibold))
              Text(L10n.tr("settlementProof.attachPhoto"))
                .font(Typography.subheadlineBold)
            }
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Tokens.sunken, in: Capsule())
          }
          .disabled(isDisabled || isUploading)
          .onChange(of: pickedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
              if let rawData = try? await newItem.loadTransferable(type: Data.self) {
                await onUploadData(rawData)
              }
              pickedPhotoItem = nil
            }
          }
        }

        if isUploading {
          Text(L10n.tr("receipts.uploading"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }

        if let errorMessage {
          Text(errorMessage)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(L10n.tr("settlementProof.noteLabel"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)

        let placeholder = L10n.tr("settlementProof.notePlaceholder")
        TextField(
          placeholder,
          text: $note,
          prompt: Text(placeholder).foregroundStyle(Tokens.placeholder)
        )
        .font(Typography.subheadline)
        .foregroundStyle(Tokens.ink)
        .disabled(isDisabled)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: note) { _, newValue in
          if newValue.count > 120 {
            note = String(newValue.prefix(120))
          }
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}
