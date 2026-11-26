import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class PayModel {
  public static let maxTransferAmount: Int64 = 999_999_999_999

  public let transfer: SuggestedTransfer
  public let fromMember: Member
  public let toMember: Member
  public let groupId: ExpenseGroup.ID
  public let myMemberId: Member.ID?
  public let role: Role
  public let isEmailVerified: Bool
  private let isFromHouseholdMember: Bool

  public private(set) var isSubmitting = false
  public private(set) var submitted = false
  public private(set) var notice: String?
  public private(set) var error: AppError?
  public var channel: PaymentChannel?
  public var note: String = "" {
    didSet {
      if note.count > 120 {
        note = String(note.prefix(120))
      }
    }
  }
  public private(set) var proofAttachment: Attachment?
  public private(set) var isUploadingProof = false
  public private(set) var proofError: String?

  private let repository: any SettlementRequestsRepository
  private let uploadProof: (@Sendable (Data, String, String) async throws(AppError) -> Attachment)?
  public let loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)?
  private let idempotencyKey = UUID().uuidString
  private let onReload: () async -> Void
  private let onUnauthorized: () -> Void

  public init(
    transfer: SuggestedTransfer,
    fromMember: Member,
    toMember: Member,
    groupId: ExpenseGroup.ID,
    myMemberId: Member.ID?,
    role: Role,
    isEmailVerified: Bool,
    isFromHouseholdMember: Bool = false,
    repository: any SettlementRequestsRepository,
    uploadProof: (@Sendable (Data, String, String) async throws(AppError) -> Attachment)? = nil,
    loadAttachment: (@Sendable (Attachment.ID) async throws -> Data)? = nil,
    onReload: @escaping () async -> Void = {},
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.transfer = transfer
    self.fromMember = fromMember
    self.toMember = toMember
    self.groupId = groupId
    self.myMemberId = myMemberId
    self.role = role
    self.isEmailVerified = isEmailVerified
    self.isFromHouseholdMember = isFromHouseholdMember
    self.repository = repository
    self.uploadProof = uploadProof
    self.loadAttachment = loadAttachment
    self.onReload = onReload
    self.onUnauthorized = onUnauthorized
    self.channel = Self.defaultChannel(for: transfer.paymentMethods)
  }

  private static func defaultChannel(for methods: [PaymentMethod]) -> PaymentChannel? {
    guard let first = methods.first else { return nil }
    switch first {
    case .bank: return .bank
    case .momo: return .momo
    case .zalopay: return .zalopay
    }
  }

  public var payAmount: Money {
    Money(min(transfer.amount.amount, Self.maxTransferAmount))
  }

  public var isPartial: Bool {
    transfer.amount.amount > Self.maxTransferAmount
  }

  public var mayCreate: Bool {
    role.canWrite || myMemberId == fromMember.id || isFromHouseholdMember
  }

  public var canEdit: Bool {
    isEmailVerified && role.canWrite
  }

  public var canAddDetails: Bool {
    isEmailVerified && (role.canWrite || myMemberId == toMember.id)
  }

  public var canResolve: Bool {
    role.isOwner || myMemberId == toMember.id || (role == .editor && !toMember.claimed)
  }

  public var canCancel: Bool {
    (transfer.pendingSettlement?.createdByMe ?? false) || myMemberId == fromMember.id
  }

  var errorMessage: String? {
    guard let error else { return nil }
    if case .api(_, 403) = error {
      return L10n.tr("common.forbidden")
    }
    return L10n.tr("common.saveError")
  }

  func uploadProofImage(rawData: Data) async {
    guard let uploadProof, !isUploadingProof, !isSubmitting else { return }
    proofError = nil
    isUploadingProof = true
    defer { isUploadingProof = false }
    do {
      let prepared = try await ReceiptImageProcessor.prepareJPEG(from: rawData)
      proofAttachment = try await uploadProof(prepared, "chung-tu.jpg", "image/jpeg")
    } catch let imgError as ReceiptImageError {
      proofError =
        imgError == .tooLarge
        ? L10n.tr("receipts.fileTooLarge")
        : L10n.tr("receipts.notAnImage")
    } catch let appError as AppError {
      switch appError {
      case .unauthorized:
        onUnauthorized()
      case .rateLimited:
        proofError = L10n.tr("attachments.rateLimited")
      case .api("STORAGE_QUOTA_EXCEEDED", _):
        proofError = L10n.tr("attachments.quotaExceeded")
      default:
        proofError = L10n.tr("common.saveError")
      }
    } catch {
      proofError = L10n.tr("common.saveError")
    }
  }

  func removeProofAttachment() {
    proofAttachment = nil
    proofError = nil
  }

  func submitReport(onDone: () -> Void) async {
    guard isEmailVerified, !isSubmitting, !submitted, !isUploadingProof else { return }
    isSubmitting = true
    error = nil
    notice = nil
    defer { isSubmitting = false }
    let cappedTransfer = SuggestedTransfer(
      fromMemberId: transfer.fromMemberId,
      toMemberId: transfer.toMemberId,
      amount: payAmount,
      paymentMethods: transfer.paymentMethods,
      purpose: transfer.purpose,
      pendingSettlement: transfer.pendingSettlement
    )
    let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      try await repository.request(
        groupId: groupId,
        transfer: cappedTransfer,
        channel: channel,
        note: trimmedNote.isEmpty ? nil : trimmedNote,
        proofAttachmentId: proofAttachment?.id,
        idempotencyKey: idempotencyKey
      )
      submitted = true
      notice = L10n.t("pay.reportedNotice", ["to": toMember.name])
      await onReload()
      onDone()
    } catch {
      await handleMutationError(error, onConflictDone: onDone)
    }
  }

  func resolvePending(
    _ pending: PendingSettlement,
    decision: SettlementDecision,
    onDone: () -> Void
  ) async {
    guard isEmailVerified, !isSubmitting else { return }
    isSubmitting = true
    error = nil
    notice = nil
    defer { isSubmitting = false }
    do {
      try await repository.resolve(groupId: groupId, requestId: pending.id, decision: decision)
      switch decision {
      case .confirm:
        notice = L10n.t(
          "pay.confirmedNotice",
          ["amount": MoneyFormat.full(pending.amount), "from": fromMember.name]
        )
      case .reject:
        notice = L10n.tr("pay.rejectedNotice")
      case .cancel:
        break
      }
      await onReload()
      onDone()
    } catch {
      await handleMutationError(error, onConflictDone: onDone)
    }
  }

  private func handleMutationError(_ error: AppError, onConflictDone: () -> Void) async {
    if error == .unauthorized {
      onUnauthorized()
      return
    }
    if error == .conflict || isConflictAPIError(error) {
      notice = L10n.tr("pay.alreadyResolved")
      await onReload()
      onConflictDone()
      return
    }
    self.error = error
  }

  private func isConflictAPIError(_ error: AppError) -> Bool {
    if case .api(_, 409) = error { return true }
    return false
  }
}
