public import Domain
import Foundation
public import Observation

@Observable
public final class QuickEntryModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
  }

  public let groupId: ExpenseGroup.ID
  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let quickEntryRepository: any QuickEntryRepository
  public let transactionsRepository: any TransactionsRepository
  private let onSaved: () -> Void
  private let onOpenManualForm: (QuickEntryReading?) -> Void

  public private(set) var state: Loadable<ScreenData> = .loading
  public var sentence: String
  public private(set) var reading: QuickEntryReading?
  public private(set) var isParsing = false
  public private(set) var parseError: AppError?
  public private(set) var isSaving = false
  public private(set) var saveError: AppError?
  public var isCollapsing = false

  private var debounceTask: Task<Void, Never>?
  private var keysBySentence: [String: IdempotencyKey] = [:]

  public init(
    groupId: ExpenseGroup.ID,
    initialSentence: String? = nil,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    quickEntryRepository: any QuickEntryRepository,
    transactionsRepository: any TransactionsRepository,
    onSaved: @escaping () -> Void,
    onOpenManualForm: @escaping (QuickEntryReading?) -> Void
  ) {
    self.groupId = groupId
    self.sentence = initialSentence ?? ""
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.quickEntryRepository = quickEntryRepository
    self.transactionsRepository = transactionsRepository
    self.onSaved = onSaved
    self.onOpenManualForm = onOpenManualForm
  }

  public var isCurrentReadingUpToDate: Bool {
    guard let reading else { return false }
    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
    return reading.text == trimmed && !isParsing
  }

  public func load() async {
    if let cachedGroup = await groupsRepository.lastKnownGroup(id: groupId),
      let cachedMembers = await membersRepository.lastKnownMembers(groupId: groupId)
    {
      state = .loaded(ScreenData(group: cachedGroup, members: cachedMembers))
    } else if case .failed = state {
      state = .loading
    }

    do {
      async let fetchedGroup = groupsRepository.group(id: groupId)
      async let fetchedMembers = membersRepository.members(groupId: groupId)
      let (g, m) = try await (fetchedGroup, fetchedMembers)
      state = .loaded(ScreenData(group: g, members: m))
      if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        await parseNow(text: sentence)
      }
    } catch let error as AppError {
      if state.value == nil {
        state = .failed(error)
      }
    } catch {
      if state.value == nil {
        state = .failed(.unexpected)
      }
    }
  }

  public func updateSentence(_ newValue: String) {
    let sanitized =
      newValue
      .replacingOccurrences(of: "\r", with: " ")
      .replacingOccurrences(of: "\n", with: " ")
    let clipped = String(sanitized.prefix(300))
    guard clipped != sentence else { return }
    sentence = clipped
    debounceTask?.cancel()
    let trimmed = clipped.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      reading = nil
      parseError = nil
      isParsing = false
      return
    }
    debounceTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await parseNow(text: trimmed)
    }
  }

  public func sendImmediately() {
    debounceTask?.cancel()
    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    Task {
      await parseNow(text: trimmed)
    }
  }

  public func parseNow(text: String) async {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    isParsing = true
    parseError = nil
    defer { isParsing = false }

    do throws(AppError) {
      let result = try await quickEntryRepository.parse(groupId: groupId, text: trimmed)
      reading = result
      if result.status == .unparsed {
        onOpenManualForm(result)
      }
    } catch {
      parseError = error
    }
  }

  public func openManualEdit(with chosen: QuickEntryReading? = nil) {
    let target = chosen ?? (isCurrentReadingUpToDate ? reading : nil)
    onOpenManualForm(target)
  }

  public func save(chosen: QuickEntryReading? = nil, reduceMotion: Bool = false) async {
    guard let target = chosen ?? reading,
      target.status == .ok,
      let amount = target.draft.amount,
      let split = target.draft.split,
      let description = target.draft.description,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !isSaving
    else { return }

    let key: IdempotencyKey
    if let existingKey = keysBySentence[target.text] {
      key = existingKey
    } else {
      let newKey = IdempotencyKey()
      keysBySentence[target.text] = newKey
      key = newKey
    }

    let occurredAt = Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(Date.now)
    let draft = TransactionDraft.split(
      TransactionDraft.SplitPayload(
        isIncome: false,
        description: description,
        amount: amount,
        occurredAt: occurredAt,
        category: nil,
        payers: target.draft.payers,
        split: split
      )
    )

    isSaving = true
    saveError = nil
    do throws(AppError) {
      _ = try await transactionsRepository.create(
        groupId: groupId,
        draft: draft,
        key: key
      )
      isCollapsing = true
      if !reduceMotion {
        try? await Task.sleep(for: .milliseconds(250))
      }
      isSaving = false
      onSaved()
    } catch {
      isSaving = false
      saveError = error
    }
  }
}
