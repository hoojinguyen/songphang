import DesignSystem
import Domain
import Repositories
import SwiftUI

struct ShareExtensionView: View {
  let extensionItems: [NSExtensionItem]
  let onOpenURL: (URL) -> Void
  let onClose: () -> Void

  @State private var isLoading = true
  @State private var hasSession = false
  @State private var groups: [ShareGroupItem] = []
  @State private var selectedGroupId: String = ""
  @State private var purpose: ShareInboxManifest.Mode = .expense
  @State private var preparedImages: [Data] = []
  @State private var isSubmitting = false
  @State private var errorMessage: String?
  @State private var finishedWaitingForOpen = false
  @State private var appearanceMode = "system"

  private var selectedGroup: ShareGroupItem? {
    groups.first { $0.id == selectedGroupId } ?? groups.first
  }

  private var eligibleGroups: [ShareGroupItem] {
    groups.filter { $0.canCreateExpense || $0.canUploadTransferProof }
  }

  private var colorSchemeOverride: ColorScheme? {
    switch appearanceMode {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          VStack(spacing: 16) {
            ProgressView()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !hasSession {
          signedOutCard
        } else if eligibleGroups.isEmpty {
          noGroupsCard
        } else if finishedWaitingForOpen {
          finishedCard
        } else {
          formContent
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("ios.shareExtension.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L10n.tr("ios.shareExtension.close"), action: onClose)
        }
      }
    }
    .preferredColorScheme(colorSchemeOverride)
    .task {
      await prepare()
    }
  }

  private var signedOutCard: some View {
    SPCard(padding: 20) {
      VStack(alignment: .leading, spacing: 14) {
        Text(L10n.tr("ios.shareExtension.signInRequired"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        SPButton(L10n.tr("ios.shareExtension.close"), variant: .primary, isFullWidth: true) {
          onClose()
        }
      }
    }
  }

  private var noGroupsCard: some View {
    SPCard(padding: 20) {
      VStack(alignment: .leading, spacing: 14) {
        Text(L10n.tr("ios.shareExtension.noEligibleGroups"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        SPButton(L10n.tr("ios.shareExtension.close"), variant: .primary, isFullWidth: true) {
          onClose()
        }
      }
    }
  }

  private var finishedCard: some View {
    SPCard(padding: 20) {
      VStack(alignment: .leading, spacing: 14) {
        Text(L10n.t("ios.shareExtension.openAppToFinish", ["name": selectedGroup?.name ?? ""]))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
        SPButton(L10n.tr("ios.shareExtension.done"), variant: .primary, isFullWidth: true) {
          onClose()
        }
      }
    }
  }

  private var formContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SPCard(padding: 16) {
          VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("ios.shareExtension.groupPickerLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            ForEach(eligibleGroups) { group in
              let isSelected = (selectedGroup?.id == group.id)
              Button {
                selectedGroupId = group.id
                if !group.canCreateExpense && purpose == .expense {
                  purpose = .transferProof
                }
              } label: {
                HStack {
                  Text(group.name)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(Tokens.ink)
                  Spacer()
                  Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Tokens.ink : Tokens.muted)
                }
                .padding(.vertical, 6)
              }
              .buttonStyle(.plain)
            }
          }
        }

        if let group = selectedGroup {
          SPCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
              if group.canCreateExpense {
                purposeOption(
                  mode: .expense,
                  title: L10n.tr("ios.shareExtension.purposeExpense"),
                  subtitle: L10n.tr("ios.shareExtension.purposeExpenseSubtitle")
                )
              }
              if group.canUploadTransferProof {
                purposeOption(
                  mode: .transferProof,
                  title: L10n.tr("ios.shareExtension.purposeTransferProof"),
                  subtitle: L10n.tr("ios.shareExtension.purposeTransferProofSubtitle")
                )
              }
            }
          }
        }

        if !preparedImages.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
              ForEach(Array(preparedImages.enumerated()), id: \.offset) { _, data in
                if let uiImage = UIImage(data: data) {
                  Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
              }
            }
          }
        }

        if let errorMessage {
          Text(errorMessage)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
        }

        SPButton(
          L10n.tr("ios.shareExtension.uploadAndContinue"),
          variant: .accent,
          size: .lg,
          isFullWidth: true,
          isDisabled: selectedGroup == nil || preparedImages.isEmpty || isSubmitting,
          isPending: isSubmitting
        ) {
          Task { await uploadAndFinish() }
        }
      }
    }
  }

  private func purposeOption(
    mode: ShareInboxManifest.Mode,
    title: String,
    subtitle: String
  ) -> some View {
    let isSelected = purpose == mode
    return Button {
      purpose = mode
    } label: {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(isSelected ? Tokens.ink : Tokens.muted)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Text(subtitle)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        Spacer()
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }

  private func prepare() async {
    let snapshot = ExtensionSharedStore.shared.readShareGroups()
    let env = LiveAPIEnvironment(configuration: Self.bundleConfiguration())
    let hasToken = await env.hasStoredToken()
    appearanceMode = snapshot?.appearanceMode ?? "system"

    if hasToken, let snapshot, snapshot.isSignedIn {
      hasSession = true
      groups = snapshot.groups
      if let recent = snapshot.recentGroupId,
        let match = eligibleGroups.first(where: { $0.id == recent })
      {
        selectedGroupId = match.id
      } else {
        selectedGroupId = eligibleGroups.first?.id ?? ""
      }
      if let group = selectedGroup, !group.canCreateExpense {
        purpose = .transferProof
      }
      preparedImages = await ShareImageNormalizer.extractAndNormalize(from: extensionItems)
    } else {
      hasSession = false
    }
    isLoading = false
  }

  private func uploadAndFinish() async {
    guard let group = selectedGroup, !preparedImages.isEmpty, !isSubmitting else { return }
    isSubmitting = true
    errorMessage = nil
    defer { isSubmitting = false }

    let batchId = UUID().uuidString.lowercased()
    let env = LiveAPIEnvironment(configuration: Self.bundleConfiguration())
    let attachmentsRepo = LiveAttachmentsRepository(environment: env)
    let scansRepo = LiveReceiptScansRepository(environment: env)
    let groupId = ExpenseGroup.ID(group.id)
    let uploadPurpose: AttachmentUploadPurpose =
      purpose == .expense ? .expense : .transferProof

    var uploadedIds: [String] = []
    var localFilenames: [String] = []

    do {
      for (index, jpegData) in preparedImages.enumerated() {
        let uploaded = try await attachmentsRepo.upload(
          groupId: groupId,
          data: jpegData,
          filename: "share-\(index + 1).jpg",
          contentType: "image/jpeg",
          purpose: uploadPurpose
        )
        uploadedIds.append(uploaded.id.rawValue)
      }

      var scanId: String?
      if purpose == .expense,
        uploadedIds.count == 1,
        group.receiptReadingEnabled,
        let firstId = uploadedIds.first
      {
        let scan = try? await scansRepo.start(
          groupId: groupId,
          attachmentId: Attachment.ID(firstId),
          key: IdempotencyKey()
        )
        scanId = scan?.id.rawValue
      }

      let manifest = ShareInboxManifest(
        batchId: batchId,
        groupId: group.id,
        groupName: group.name,
        mode: purpose,
        attachmentIds: uploadedIds,
        receiptScanId: scanId,
        localImageFilenames: localFilenames
      )
      ExtensionSharedStore.shared.writeShareInboxManifest(manifest)
    } catch {
      if let batchDir = ExtensionSharedStore.shared.shareInboxBatchDirectory(batchId: batchId) {
        try? FileManager.default.createDirectory(at: batchDir, withIntermediateDirectories: true)
        for (index, jpegData) in preparedImages.enumerated() {
          let filename = "image-\(index + 1).jpg"
          let fileURL = batchDir.appending(path: filename)
          if (try? jpegData.write(
            to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]))
            != nil
          {
            localFilenames.append(filename)
          }
        }
      }
      guard !localFilenames.isEmpty else {
        errorMessage = L10n.tr("common.saveError")
        return
      }
      let manifest = ShareInboxManifest(
        batchId: batchId,
        groupId: group.id,
        groupName: group.name,
        mode: purpose,
        attachmentIds: [],
        receiptScanId: nil,
        localImageFilenames: localFilenames
      )
      ExtensionSharedStore.shared.writeShareInboxManifest(manifest)
    }

    if let deepLink = URL(string: "songphang://share-import/\(batchId)") {
      onOpenURL(deepLink)
    }
    finishedWaitingForOpen = true
  }

  private static func bundleConfiguration() -> APIConfiguration {
    let info = Bundle.main.infoDictionary
    let rawAPI = (info?["API_BASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let rawWeb = (info?["WEB_BASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    #if DEBUG
      let fallbackAPI = URL(string: "http://127.0.0.1:4000/api/v1")
      let fallbackWeb = URL(string: "http://localhost:3000")
    #else
      let fallbackAPI: URL? = nil
      let fallbackWeb: URL? = nil
    #endif
    let apiURL =
      rawAPI.flatMap { !$0.isEmpty && !$0.contains("$(") ? URL(string: $0) : nil }
      ?? fallbackAPI
      ?? URL(filePath: "/")
    let webURL =
      rawWeb.flatMap { !$0.isEmpty && !$0.contains("$(") ? URL(string: $0) : nil }
      ?? fallbackWeb
      ?? URL(filePath: "/")
    let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    return APIConfiguration(
      apiBaseURL: apiURL,
      webBaseURL: webURL,
      appVersion: version,
      deviceName: "ShareExtension"
    )
  }
}
