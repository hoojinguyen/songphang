public import DesignSystem
public import Domain
public import Foundation
public import Observation

@Observable
public final class ReceiptReviewModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var scan: ReceiptScan
  }

  public let groupId: ExpenseGroup.ID
  public private(set) var scanId: ReceiptScan.ID

  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  public let attachmentsRepository: any AttachmentsRepository
  private let receiptScansRepository: any ReceiptScansRepository
  private let transactionsRepository: any TransactionsRepository
  private let onSaved: () -> Void
  private let onManualFallback: (Attachment.ID) -> Void
  private let onUnauthorized: () -> Void

  public private(set) var state: Loadable<ScreenData> = .loading
  public private(set) var hasTimedOut = false
  public private(set) var isRetaking = false
  public private(set) var retakeError: AppError?
  public private(set) var retakeImageError: ReceiptImageError?
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?

  public var descriptionText = ""
  public var occurredOn = ReceiptReviewModel.todayVietnamDate()
  public var itemsDraft = ItemsSplitDraft()
  public var payerId: Member.ID?
  public var mismatchDismissed = false

  public private(set) var itemsPreview: ItemsPreview?
  public private(set) var isPreviewCurrent = false
  public private(set) var previewError: AppError?

  private var initializedScanId: ReceiptScan.ID?
  private var saveKey = IdempotencyKey()
  private var pollTask: Task<Void, Never>?
  private var previewDebounceTask: Task<Void, Never>?

  public init(
    groupId: ExpenseGroup.ID,
    scanId: ReceiptScan.ID,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    attachmentsRepository: any AttachmentsRepository,
    receiptScansRepository: any ReceiptScansRepository,
    transactionsRepository: any TransactionsRepository,
    onSaved: @escaping () -> Void,
    onManualFallback: @escaping (Attachment.ID) -> Void,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.scanId = scanId
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.attachmentsRepository = attachmentsRepository
    self.receiptScansRepository = receiptScansRepository
    self.transactionsRepository = transactionsRepository
    self.onSaved = onSaved
    self.onManualFallback = onManualFallback
    self.onUnauthorized = onUnauthorized
  }

  public func activePeople(from members: [Member]) -> [Member] {
    members.filter { $0.active && $0.kind == .person }
  }

  public func payerOptions(from members: [Member]) -> [Member] {
    let people = activePeople(from: members)
    if let fund = members.first(where: { $0.active && $0.kind == .fund }) {
      return people + [fund]
    }
    return people
  }

  public func load(defaultTitle: String) async {
    pollTask?.cancel()
    state = .loading
    hasTimedOut = false
    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      async let fetchedScan = receiptScansRepository.scan(groupId: groupId, id: scanId)
      let (group, members, scan) = try await (fetchedGroup, fetchedMembers, fetchedScan)
      applyLoaded(group: group, members: members, scan: scan, defaultTitle: defaultTitle)
      if scan.status == .queued || scan.status == .processing {
        startPolling(defaultTitle: defaultTitle)
      }
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      state = .failed(error)
    } catch {
      state = .failed(.unexpected)
    }
  }

  public func schedulePreview() {
    previewDebounceTask?.cancel()
    isPreviewCurrent = false
    guard case .loaded(let data) = state, data.scan.status == .done else {
      return
    }
    guard let payload = itemsDraft.buildPayload() else {
      itemsPreview = nil
      return
    }
    let targetTotal = data.scan.reading?.total
    previewDebounceTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await runPreview(items: payload.items, extras: payload.extras, targetTotal: targetTotal)
    }
  }

  public func refreshPreviewNow() async {
    previewDebounceTask?.cancel()
    guard case .loaded(let data) = state,
      data.scan.status == .done,
      let payload = itemsDraft.buildPayload()
    else { return }
    await runPreview(
      items: payload.items,
      extras: payload.extras,
      targetTotal: data.scan.reading?.total
    )
  }

  public var mismatchInfo: (computed: Money, printedTotal: Money)? {
    guard case .loaded(let data) = state,
      !mismatchDismissed,
      data.scan.flags.contains(.totalMismatch),
      !data.scan.flags.contains(.noItems),
      let scanComputed = data.scan.computed,
      let printedTotal = data.scan.reading?.total
    else { return nil }

    let currentComputed = isPreviewCurrent ? itemsPreview?.computedAmount : nil
    if currentComputed == printedTotal {
      return nil
    }
    return (currentComputed ?? scanComputed, printedTotal)
  }

  public func useComputedTotal() {
    mismatchDismissed = true
  }

  public func applyPrintedTotal(adjustmentLabel: String) {
    guard isPreviewCurrent,
      let adjustment = itemsPreview?.targetAdjustment,
      !itemsDraft.isExtrasFull
    else { return }
    itemsDraft.addAdjustmentExtra(
      kind: adjustment.kind,
      label: adjustmentLabel,
      amount: adjustment.amount
    )
    mismatchDismissed = true
    schedulePreview()
  }

  public var canSave: Bool {
    guard case .loaded(let data) = state,
      data.scan.status == .done,
      !isSubmitting,
      mismatchInfo == nil,
      isPreviewCurrent,
      let preview = itemsPreview,
      preview.issues.isEmpty,
      !preview.shares.isEmpty,
      preview.computedAmount.isPositive,
      payerId != nil,
      !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      Self.isValidCalendarDate(occurredOn),
      itemsDraft.buildPayload() != nil
    else { return false }
    return true
  }

  public func save() async {
    guard canSave,
      case .loaded(let data) = state,
      let payload = itemsDraft.buildPayload(),
      let preview = itemsPreview,
      let payerId
    else { return }

    let trimmedDescription = String(
      descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200)
    )
    guard let occurredAt = Self.vietnamNoonISO(for: occurredOn) else { return }

    let draft = TransactionDraft.split(
      TransactionDraft.SplitPayload(
        isIncome: false,
        description: trimmedDescription,
        amount: preview.computedAmount,
        occurredAt: occurredAt,
        category: nil,
        categoryId: nil,
        payers: [MemberAmount(memberId: payerId, amount: preview.computedAmount)],
        split: .items(items: payload.items, extras: payload.extras),
        attachmentIds: [data.scan.attachmentId]
      )
    )

    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }

    do throws(AppError) {
      _ = try await transactionsRepository.create(
        groupId: groupId,
        draft: draft,
        key: saveKey
      )
      onSaved()
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      submitError = error
    }
  }

  public func retake(rawImageData: Data, defaultTitle: String) async {
    guard !isRetaking else { return }
    isRetaking = true
    retakeError = nil
    retakeImageError = nil
    defer { isRetaking = false }

    do {
      let prepared = try await ReceiptImageProcessor.prepareJPEG(from: rawImageData)
      let attachment = try await attachmentsRepository.upload(
        groupId: groupId,
        data: prepared,
        filename: "hoa-don.jpg",
        contentType: "image/jpeg"
      )
      let started = try await receiptScansRepository.start(
        groupId: groupId,
        attachmentId: attachment.id,
        key: IdempotencyKey()
      )
      switchToScan(started, defaultTitle: defaultTitle)
    } catch let imgError as ReceiptImageError {
      retakeImageError = imgError
    } catch let error as AppError {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      retakeError = error
    } catch {
      retakeError = .unexpected
    }
  }

  public func rescanExistingAttachment(defaultTitle: String) async {
    guard !isRetaking, case .loaded(let data) = state else { return }
    isRetaking = true
    retakeError = nil
    retakeImageError = nil
    defer { isRetaking = false }

    do {
      let bytes = try await attachmentsRepository.content(
        groupId: groupId,
        attachmentId: data.scan.attachmentId
      )
      let attachment = try await attachmentsRepository.upload(
        groupId: groupId,
        data: bytes,
        filename: "hoa-don.jpg",
        contentType: "image/jpeg"
      )
      let started = try await receiptScansRepository.start(
        groupId: groupId,
        attachmentId: attachment.id,
        key: IdempotencyKey()
      )
      switchToScan(started, defaultTitle: defaultTitle)
    } catch let error {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      retakeError = error
    }
  }

  public func openManualFallback() {
    guard case .loaded(let data) = state else { return }
    onManualFallback(data.scan.attachmentId)
  }

  public func stopPolling() {
    pollTask?.cancel()
    pollTask = nil
    previewDebounceTask?.cancel()
  }

  // MARK: - Helpers

  private func switchToScan(_ next: ReceiptScan, defaultTitle: String) {
    pollTask?.cancel()
    scanId = next.id
    saveKey = IdempotencyKey()
    initializedScanId = nil
    hasTimedOut = false
    if case .loaded(var data) = state {
      applyLoaded(group: data.group, members: data.members, scan: next, defaultTitle: defaultTitle)
      data.scan = next
      if next.status == .queued || next.status == .processing {
        startPolling(defaultTitle: defaultTitle)
      }
    }
  }

  private func applyLoaded(
    group: ExpenseGroup,
    members: [Member],
    scan: ReceiptScan,
    defaultTitle: String
  ) {
    state = .loaded(ScreenData(group: group, members: members, scan: scan))
    guard scan.status == .done, initializedScanId != scan.id else { return }

    let merchant = scan.reading?.merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = (merchant?.isEmpty == false) ? (merchant ?? defaultTitle) : defaultTitle
    descriptionText = title
    if let occurred = scan.reading?.occurredOn, Self.isValidCalendarDate(occurred) {
      occurredOn = occurred
    } else {
      occurredOn = Self.todayVietnamDate()
    }
    itemsDraft = ItemsSplitDraft(scan: scan, fallbackTitle: defaultTitle)
    let options = payerOptions(from: members)
    payerId =
      options.first(where: { $0.id == group.myMemberId })?.id ?? options.first?.id
    mismatchDismissed = false
    initializedScanId = scan.id
    schedulePreview()
  }

  private func startPolling(defaultTitle: String) {
    pollTask?.cancel()
    pollTask = Task {
      let deadline = ContinuousClock.now + .seconds(60)
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        if ContinuousClock.now >= deadline {
          hasTimedOut = true
          return
        }
        do throws(AppError) {
          let updated = try await receiptScansRepository.scan(groupId: groupId, id: scanId)
          guard case .loaded(let current) = state else { return }
          applyLoaded(
            group: current.group,
            members: current.members,
            scan: updated,
            defaultTitle: defaultTitle
          )
          if updated.status == .done || updated.status == .failed {
            return
          }
        } catch let error {
          if error == .unauthorized {
            onUnauthorized()
            return
          }
          state = .failed(error)
          return
        }
      }
    }
  }

  private func runPreview(
    items: [SplitSpec.ItemEntry],
    extras: [SplitSpec.ItemsExtra],
    targetTotal: Money?
  ) async {
    previewError = nil
    do throws(AppError) {
      let result = try await transactionsRepository.previewItems(
        groupId: groupId,
        items: items,
        extras: extras,
        targetTotal: targetTotal
      )
      guard !Task.isCancelled else { return }
      itemsPreview = result
      isPreviewCurrent = true
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      previewError = error
      isPreviewCurrent = false
    }
  }

  public static func todayVietnamDate() -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
    let comps = calendar.dateComponents([.year, .month, .day], from: .now)
    let y = comps.year ?? 2026
    let m = comps.month ?? 1
    let d = comps.day ?? 1
    return String(format: "%04d-%02d-%02d", y, m, d)
  }

  public static func isValidCalendarDate(_ value: String) -> Bool {
    guard value.count == 10 else { return false }
    let parts = value.split(separator: "-")
    guard parts.count == 3,
      let y = Int(parts[0]), parts[0].count == 4,
      let m = Int(parts[1]), parts[1].count == 2,
      let d = Int(parts[2]), parts[2].count == 2
    else { return false }
    var comps = DateComponents()
    comps.year = y
    comps.month = m
    comps.day = d
    comps.hour = 12
    comps.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
    guard let date = cal.date(from: comps) else { return false }
    let check = cal.dateComponents([.year, .month, .day], from: date)
    return check.year == y && check.month == m && check.day == d
  }

  public static func vietnamNoonISO(for yyyyMMdd: String) -> String? {
    guard isValidCalendarDate(yyyyMMdd) else { return nil }
    let isoWithOffset = "\(yyyyMMdd)T12:00:00+07:00"
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime]
    guard let date = parser.date(from: isoWithOffset) else { return nil }
    return Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }
}
