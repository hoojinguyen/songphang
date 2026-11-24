import AVFoundation
import DesignSystem
public import Domain
import PhotosUI
public import SwiftUI
import UIKit

struct CameraPickerView: UIViewControllerRepresentable {
  let onCapture: (Data) -> Void
  let onCancel: () -> Void

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate
  {
    private let onCapture: (Data) -> Void
    private let onCancel: () -> Void

    init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
      self.onCapture = onCapture
      self.onCancel = onCancel
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      onCancel()
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage,
        let jpeg = image.jpegData(compressionQuality: 0.95)
      {
        onCapture(jpeg)
      } else {
        onCancel()
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onCapture: onCapture, onCancel: onCancel)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

enum UploadErrorFormatter {
  static func message(for error: any Error) -> String {
    if let imgError = error as? ReceiptImageError {
      switch imgError {
      case .tooLarge: return L10n.tr("receipts.fileTooLarge")
      case .notAnImage: return L10n.tr("receipts.notAnImage")
      }
    }
    if let appError = error as? AppError {
      switch appError {
      case .rateLimited: return L10n.tr("attachments.rateLimited")
      case .api(let code, let status):
        if status == 413 || code == "UPLOAD_TOO_LARGE" {
          return L10n.tr("receipts.fileTooLarge")
        }
        switch code {
        case "UPLOAD_NOT_AN_IMAGE":
          return L10n.tr("receipts.notAnImage")
        case "STORAGE_QUOTA_EXCEEDED":
          return L10n.tr("attachments.quotaExceeded")
        case "AI_QUOTA_EXCEEDED":
          return L10n.tr("receipts.dailyLimit")
        default:
          return L10n.tr("common.saveError")
        }
      default:
        return L10n.tr("common.saveError")
      }
    }
    return L10n.tr("receipts.notAnImage")
  }
}

public enum ReceiptCameraCapability {
  public static var isCameraAvailable: Bool {
    UIImagePickerController.isSourceTypeAvailable(.camera)
  }

  public static func requestCameraAccessIfNeeded() async -> Bool {
    guard isCameraAvailable else { return false }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      return true
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
      return false
    @unknown default:
      return false
    }
  }
}

public struct ReceiptCaptureSheet: View {
  private let groupId: ExpenseGroup.ID
  private let attachmentsRepository: any AttachmentsRepository
  private let receiptScansRepository: any ReceiptScansRepository
  private let onScanStarted: (ReceiptScan) -> Void
  private let onManualFallback: (Attachment.ID?) -> Void
  private let onDismiss: () -> Void

  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isCameraPresented = false
  @State private var isBusy = false
  @State private var errorMessage: String?
  @State private var fallbackAttachmentId: Attachment.ID?
  @State private var isCameraDenied = false

  public init(
    groupId: ExpenseGroup.ID,
    attachmentsRepository: any AttachmentsRepository,
    receiptScansRepository: any ReceiptScansRepository,
    onScanStarted: @escaping (ReceiptScan) -> Void,
    onManualFallback: @escaping (Attachment.ID?) -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.groupId = groupId
    self.attachmentsRepository = attachmentsRepository
    self.receiptScansRepository = receiptScansRepository
    self.onScanStarted = onScanStarted
    self.onManualFallback = onManualFallback
    self.onDismiss = onDismiss
  }

  public var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text(L10n.tr("receipts.cameraLabel"))
          .font(Typography.screenHeaderTitle)
          .foregroundStyle(Tokens.ink)

        Text(L10n.tr("receipts.aiNote"))
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.muted)

        if isBusy {
          HStack(spacing: 12) {
            ProgressView()
            Text(L10n.tr("receipts.uploading"))
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }

        if let errorMessage {
          SPCard(tone: .surface, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
              Text(errorMessage)
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.coral)
              SPButton(
                L10n.tr("receipts.manualEntry"),
                variant: .surface,
                isFullWidth: true
              ) {
                onManualFallback(fallbackAttachmentId)
              }
            }
          }
        }

        if isCameraDenied {
          Text(L10n.tr("receipts.failed"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }

        if ReceiptCameraCapability.isCameraAvailable {
          SPButton(
            L10n.tr("receipts.takePhoto"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: isBusy
          ) {
            Task {
              let granted = await ReceiptCameraCapability.requestCameraAccessIfNeeded()
              if granted {
                isCameraPresented = true
              } else {
                isCameraDenied = true
              }
            }
          }
        }

        PhotosPicker(
          selection: $selectedPhotoItem,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Text(L10n.tr("receipts.pickLibrary"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Tokens.surface, in: Capsule())
        }
        .disabled(isBusy)

        SPButton(
          L10n.tr("common.cancel"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: isBusy,
          action: onDismiss
        )

        Spacer(minLength: 0)
      }
      .padding(20)
      .background(Tokens.bg.ignoresSafeArea())
      .onChange(of: selectedPhotoItem) { _, item in
        guard let item else { return }
        selectedPhotoItem = nil
        Task { await handlePickedItem(item) }
      }
      .fullScreenCover(isPresented: $isCameraPresented) {
        CameraPickerView(
          onCapture: { rawData in
            isCameraPresented = false
            Task { await processAndScan(rawData: rawData) }
          },
          onCancel: {
            isCameraPresented = false
          }
        )
        .ignoresSafeArea()
      }
    }
  }

  private func handlePickedItem(_ item: PhotosPickerItem) async {
    do {
      guard let rawData = try await item.loadTransferable(type: Data.self) else {
        errorMessage = L10n.tr("receipts.notAnImage")
        return
      }
      await processAndScan(rawData: rawData)
    } catch {
      errorMessage = L10n.tr("receipts.notAnImage")
    }
  }

  private func processAndScan(rawData: Data) async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    fallbackAttachmentId = nil
    defer { isBusy = false }

    do {
      let prepared = try await ReceiptImageProcessor.prepareJPEG(from: rawData)
      let attachment = try await attachmentsRepository.upload(
        groupId: groupId,
        data: prepared,
        filename: "hoa-don.jpg",
        contentType: "image/jpeg"
      )
      fallbackAttachmentId = attachment.id
      let scan = try await receiptScansRepository.start(
        groupId: groupId,
        attachmentId: attachment.id,
        key: IdempotencyKey()
      )
      onScanStarted(scan)
    } catch {
      errorMessage = UploadErrorFormatter.message(for: error)
    }
  }
}
