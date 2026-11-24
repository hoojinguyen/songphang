public import Domain
import Foundation
public import Observation

@Observable
public final class QuickEntryModel {
  public struct ScreenData: Sendable, Equatable {
    public var group: ExpenseGroup
    public var members: [Member]
    public var categories: [GroupCategory]

    public init(
      group: ExpenseGroup,
      members: [Member],
      categories: [GroupCategory] = []
    ) {
      self.group = group
      self.members = members
      self.categories = categories
    }
  }

  public struct QueuedDraft: Sendable, Hashable {
    public let idempotencyKey: IdempotencyKey
    public let occurredAt: String
    public var item: QuickEntryReading.ParsedDraft

    public init(
      idempotencyKey: IdempotencyKey = IdempotencyKey(),
      occurredAt: String,
      item: QuickEntryReading.ParsedDraft
    ) {
      self.idempotencyKey = idempotencyKey
      self.occurredAt = occurredAt
      self.item = item
    }
  }

  public let groupId: ExpenseGroup.ID
  private let canUseAI: Bool
  private let groupsRepository: any GroupsRepository
  private let membersRepository: any MembersRepository
  private let categoriesRepository: (any CategoriesRepository)?
  private let quickEntryRepository: any QuickEntryRepository
  public let transactionsRepository: any TransactionsRepository
  private let onSaved: () -> Void
  private let onDraftSaved: () -> Void
  private let onSkippedToFeed: () -> Void
  private let onOpenManualForm: (QuickEntryReading?) -> Void

  public private(set) var state: Loadable<ScreenData> = .loading
  public var sentence: String
  public private(set) var reading: QuickEntryReading?
  public private(set) var draftQueue: [QueuedDraft] = []
  public private(set) var currentDraftIndex: Int = 0
  private var parsedReader: QuickEntryReading.ReaderKind = .rules
  private var parsedSpans: [QuickEntryReading.Span] = []
  private var parsedText: String = ""
  public private(set) var isParsing = false
  public private(set) var isSlowReading = false
  public private(set) var parseError: AppError?
  public private(set) var previewWarnings: [TransactionWarning] = []
  public private(set) var isSaving = false
  public private(set) var saveError: AppError?
  public var isCollapsing = false

  private var debounceTask: Task<Void, Never>?
  private var slowTimerTask: Task<Void, Never>?
  private var parseGeneration = 0
  private var keysBySentence: [String: IdempotencyKey] = [:]

  public init(
    groupId: ExpenseGroup.ID,
    initialSentence: String? = nil,
    canUseAI: Bool = false,
    groupsRepository: any GroupsRepository,
    membersRepository: any MembersRepository,
    categoriesRepository: (any CategoriesRepository)? = nil,
    quickEntryRepository: any QuickEntryRepository,
    transactionsRepository: any TransactionsRepository,
    onSaved: @escaping () -> Void,
    onDraftSaved: @escaping () -> Void = {},
    onSkippedToFeed: (() -> Void)? = nil,
    onOpenManualForm: @escaping (QuickEntryReading?) -> Void
  ) {
    self.groupId = groupId
    self.sentence = initialSentence ?? ""
    self.canUseAI = canUseAI
    self.groupsRepository = groupsRepository
    self.membersRepository = membersRepository
    self.categoriesRepository = categoriesRepository
    self.quickEntryRepository = quickEntryRepository
    self.transactionsRepository = transactionsRepository
    self.onSaved = onSaved
    self.onDraftSaved = onDraftSaved
    self.onSkippedToFeed = onSkippedToFeed ?? onSaved
    self.onOpenManualForm = onOpenManualForm
  }

  public var isCurrentReadingUpToDate: Bool {
    guard let reading else { return false }
    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
    return reading.text == trimmed && !isParsing
  }

  public var isMultiDraft: Bool {
    draftQueue.count > 1
  }

  public var hasNextDraft: Bool {
    currentDraftIndex + 1 < draftQueue.count
  }

  public static func isRuleInteractiveQuestion(
    status: QuickEntryReading.Status,
    issues: [QuickEntryReading.Issue],
    reader: QuickEntryReading.ReaderKind
  ) -> Bool {
    guard reader != .ai, status == .needsInput else { return false }
    return issues.contains { issue in
      switch issue.code {
      case .memberAmbiguous, .countMismatch, .descriptionMissing:
        return true
      case .amountMissing, .memberUnknown, .fundCannotShare, .sumMismatch, .textNotUnderstood,
        .unknown:
        return false
      }
    }
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
      async let fetchedCategories = fetchCategoriesSilently()
      let (g, m, c) = try await (fetchedGroup, fetchedMembers, fetchedCategories)
      state = .loaded(ScreenData(group: g, members: m, categories: c))
      if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        await parseNow(text: sentence, explicitSend: false)
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

  private func fetchCategoriesSilently() async -> [GroupCategory] {
    guard let categoriesRepository else { return [] }
    return (try? await categoriesRepository.list(groupId: groupId)) ?? []
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
    slowTimerTask?.cancel()
    parseGeneration += 1
    isSlowReading = false
    let trimmed = clipped.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      reading = nil
      draftQueue = []
      currentDraftIndex = 0
      parsedText = ""
      parsedSpans = []
      parsedReader = .rules
      parseError = nil
      previewWarnings = []
      isParsing = false
      return
    }
    debounceTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await parseNow(text: trimmed, explicitSend: false)
    }
  }

  public func sendImmediately() {
    debounceTask?.cancel()
    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    Task {
      await parseNow(text: trimmed, explicitSend: true)
    }
  }

  public func parseNow(text: String, explicitSend: Bool = false) async {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    parseGeneration += 1
    let gen = parseGeneration
    slowTimerTask?.cancel()
    isSlowReading = false
    isParsing = true
    parseError = nil
    previewWarnings = []

    slowTimerTask = Task {
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled, gen == self.parseGeneration, self.isParsing else { return }
      self.isSlowReading = true
    }

    do throws(AppError) {
      let useAI = explicitSend && canUseAI
      let result = try await quickEntryRepository.parse(
        groupId: groupId,
        text: trimmed,
        ai: useAI
      )
      guard gen == parseGeneration else { return }
      slowTimerTask?.cancel()
      isSlowReading = false
      isParsing = false

      let baseOccurredAt = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        .format(Date.now)
      let baseDrafts =
        [
          QuickEntryReading.ParsedDraft(
            status: result.status,
            draft: result.draft,
            issues: result.issues,
            shares: result.shares
          )
        ] + result.moreDrafts
      draftQueue = baseDrafts.map { QueuedDraft(occurredAt: baseOccurredAt, item: $0) }
      currentDraftIndex = 0
      parsedReader = result.reader
      parsedSpans = result.reader == .ai ? [] : result.spans
      parsedText = result.text

      await activateCurrentDraft(explicitSend: explicitSend)
    } catch {
      guard gen == parseGeneration else { return }
      slowTimerTask?.cancel()
      isSlowReading = false
      isParsing = false
      parseError = error
    }
  }

  private func activateCurrentDraft(explicitSend: Bool) async {
    guard draftQueue.indices.contains(currentDraftIndex) else {
      reading = nil
      return
    }
    let queued = draftQueue[currentDraftIndex]
    let current = QuickEntryReading(
      status: queued.item.status,
      text: parsedText,
      draft: queued.item.draft,
      shares: queued.item.shares,
      spans: parsedReader == .ai ? [] : parsedSpans,
      issues: queued.item.issues,
      reader: parsedReader,
      moreDrafts: []
    )
    reading = current
    previewWarnings = []

    let awaitingSendForAI =
      !explicitSend && canUseAI && parsedReader == .rules && queued.item.status == .unparsed
    let isInteractive = Self.isRuleInteractiveQuestion(
      status: queued.item.status,
      issues: queued.item.issues,
      reader: parsedReader
    )

    if queued.item.status != .ok && !isInteractive && !awaitingSendForAI {
      onOpenManualForm(current)
      return
    }

    if queued.item.status == .ok,
      let amount = queued.item.draft.amount,
      let split = queued.item.draft.split,
      let description = queued.item.draft.description,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      let draft = TransactionDraft.split(
        TransactionDraft.SplitPayload(
          isIncome: false,
          description: description,
          amount: amount,
          occurredAt: queued.occurredAt,
          category: queued.item.draft.category,
          categoryId: queued.item.draft.categoryId,
          payers: queued.item.draft.payers,
          split: split
        )
      )
      if let preview = try? await transactionsRepository.preview(groupId: groupId, draft: draft) {
        if reading?.text == parsedText && draftQueue.indices.contains(currentDraftIndex) {
          previewWarnings = preview.warnings
          reading?.shares = preview.shares
        }
      }
    }
  }

  public func skipDraft() {
    guard !isSaving, !draftQueue.isEmpty else { return }
    if hasNextDraft {
      currentDraftIndex += 1
      Task { await activateCurrentDraft(explicitSend: true) }
    } else {
      onSkippedToFeed()
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

    let activeQueued =
      (target.text == parsedText && draftQueue.indices.contains(currentDraftIndex))
      ? draftQueue[currentDraftIndex]
      : nil

    let key: IdempotencyKey
    if let queuedKey = activeQueued?.idempotencyKey {
      key = queuedKey
    } else if let existingKey = keysBySentence[target.text] {
      key = existingKey
    } else {
      let newKey = IdempotencyKey()
      keysBySentence[target.text] = newKey
      key = newKey
    }

    let occurredAt =
      activeQueued?.occurredAt
      ?? Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(Date.now)
    let draft = TransactionDraft.split(
      TransactionDraft.SplitPayload(
        isIncome: false,
        description: description,
        amount: amount,
        occurredAt: occurredAt,
        category: target.draft.category,
        categoryId: target.draft.categoryId,
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
      if hasNextDraft {
        isSaving = false
        currentDraftIndex += 1
        onDraftSaved()
        await activateCurrentDraft(explicitSend: true)
      } else {
        isCollapsing = true
        if !reduceMotion {
          try? await Task.sleep(for: .milliseconds(250))
        }
        isSaving = false
        onSaved()
      }
    } catch {
      isSaving = false
      saveError = error
    }
  }
}
