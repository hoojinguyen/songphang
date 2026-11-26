import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class SettleModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var fromMember: Member
    public var toMember: Member
    public var debt: Money
  }

  public enum DaySelection: Sendable, Equatable {
    case today
    case yesterday
    case other
  }

  public let groupId: ExpenseGroup.ID
  public let fromMemberId: Member.ID
  public let toMemberId: Member.ID
  public let initialAmount: Money
  public private(set) var idempotencyKey: IdempotencyKey

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let balancesRepository: any BalancesRepository
  private let transactionsRepository: any TransactionsRepository
  public let attachmentsRepository: (any AttachmentsRepository)?
  private let onSaved: () -> Void
  private var capturedOccurredAt: String?

  public private(set) var state: Loadable<ScreenData> = .loading
  public var amountText: String {
    didSet {
      if amountText != oldValue {
        resetIntent()
      }
    }
  }
  public var daySelection: DaySelection = .today {
    didSet {
      if daySelection != oldValue {
        resetIntent()
      }
    }
  }
  public var customDate: Date = Date() {
    didSet {
      if customDate != oldValue {
        resetIntent()
      }
    }
  }
  public var channel: PaymentChannel? = nil {
    didSet {
      if channel != oldValue {
        resetIntent()
      }
    }
  }
  public var note: String = "" {
    didSet {
      if note.count > 120 {
        note = String(note.prefix(120))
      }
      if note != oldValue {
        resetIntent()
      }
    }
  }
  public private(set) var attachments: [Attachment] = []
  public private(set) var isUploadingProof = false
  public private(set) var proofError: String?
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?
  public var isRecorded = false

  private func resetIntent() {
    guard !isSubmitting else { return }
    capturedOccurredAt = nil
    idempotencyKey = IdempotencyKey()
    submitError = nil
  }

  public init(
    groupId: ExpenseGroup.ID,
    fromMemberId: Member.ID,
    toMemberId: Member.ID,
    initialAmount: Money,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    balancesRepository: any BalancesRepository,
    transactionsRepository: any TransactionsRepository,
    attachmentsRepository: (any AttachmentsRepository)? = nil,
    onSaved: @escaping () -> Void
  ) {
    self.groupId = groupId
    self.fromMemberId = fromMemberId
    self.toMemberId = toMemberId
    self.initialAmount = initialAmount
    self.idempotencyKey = IdempotencyKey()
    self.amountText = MoneyFormat.amount(initialAmount)
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.balancesRepository = balancesRepository
    self.transactionsRepository = transactionsRepository
    self.attachmentsRepository = attachmentsRepository
    self.onSaved = onSaved
  }

  public var amount: Money? {
    MoneyFormat.parseInput(amountText)
  }

  public func load() async {
    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedBalances = balancesRepository.balances(groupId: groupId)

      let (group, members, balances) = try await (
        fetchedGroup, fetchedMembers, fetchedBalances
      )
      guard let from = members.first(where: { $0.id == fromMemberId }),
        let to = members.first(where: { $0.id == toMemberId }),
        from.id != to.id
      else {
        state = .failed(.api(code: "NOT_FOUND", status: 404))
        return
      }
      let fromBalance =
        balances.balances.first(where: { $0.memberId == from.id })?.balance ?? .zero
      let debt = Money.zero - fromBalance
      state = .loaded(
        ScreenData(
          group: group,
          fromMember: from,
          toMember: to,
          debt: debt
        )
      )
    } catch let error as AppError {
      state = .failed(error)
    } catch {
      state = .failed(.unexpected)
    }
  }

  public func updateAmountText(_ raw: String) {
    guard !isSubmitting else { return }
    let digits = raw.filter { $0.isWholeNumber && $0.isASCII }
    if digits.isEmpty {
      amountText = ""
    } else if let parsed = MoneyFormat.parseInput(digits) {
      amountText = MoneyFormat.amount(parsed)
    }
  }

  public func uploadProofImage(rawData: Data) async {
    guard let attachmentsRepository, !isUploadingProof, !isSubmitting, attachments.count < 3 else {
      return
    }
    proofError = nil
    isUploadingProof = true
    defer { isUploadingProof = false }
    do {
      let prepared = try await ReceiptImageProcessor.prepareJPEG(from: rawData)
      let uploaded = try await attachmentsRepository.upload(
        groupId: groupId,
        data: prepared,
        filename: "chung-tu.jpg",
        contentType: "image/jpeg",
        purpose: .transferProof
      )
      attachments.append(uploaded)
      resetIntent()
    } catch let imgError as ReceiptImageError {
      proofError =
        imgError == .tooLarge
        ? L10n.tr("receipts.tooLarge")
        : L10n.tr("receipts.notAnImage")
    } catch let appError as AppError {
      switch appError {
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

  public func removeProofAttachment(id: Attachment.ID) {
    guard !isSubmitting else { return }
    attachments.removeAll { $0.id == id }
    proofError = nil
    resetIntent()
  }

  public func loadAttachment(id: Attachment.ID) async throws -> Data {
    guard let attachmentsRepository else { return Data() }
    return try await attachmentsRepository.content(groupId: groupId, attachmentId: id)
  }

  public func submit(reduceMotion: Bool = false) async {
    guard let amt = amount, amt.isPositive, !isSubmitting, !isUploadingProof else { return }
    isSubmitting = true
    submitError = nil

    let occurredAt: String
    if let capturedOccurredAt {
      occurredAt = capturedOccurredAt
    } else {
      let targetDate: Date
      switch daySelection {
      case .today:
        targetDate = Date.now
      case .yesterday:
        targetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
      case .other:
        targetDate = customDate
      }
      let formatted = Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(targetDate)
      capturedOccurredAt = formatted
      occurredAt = formatted
    }

    let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
    let draft = TransactionDraft.transfer(
      TransactionDraft.TransferPayload(
        amount: amt,
        occurredAt: occurredAt,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        attachmentIds: attachments.isEmpty ? nil : attachments.map(\.id),
        paymentChannel: channel,
        paymentNote: trimmedNote.isEmpty ? nil : trimmedNote
      )
    )

    let submitKey = idempotencyKey
    do throws(AppError) {
      _ = try await transactionsRepository.create(
        groupId: groupId,
        draft: draft,
        key: submitKey
      )
      capturedOccurredAt = nil
      isRecorded = true
      if !reduceMotion {
        try? await Task.sleep(for: .milliseconds(200))
      }
      isSubmitting = false
      onSaved()
    } catch {
      isSubmitting = false
      submitError = error
    }
  }
}
