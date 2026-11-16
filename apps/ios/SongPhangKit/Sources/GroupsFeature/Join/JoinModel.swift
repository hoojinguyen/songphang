public import Domain
import Foundation
public import Observation

@Observable
public final class JoinModel {
  public let token: String
  public let accountName: String
  public let idempotencyKey: IdempotencyKey

  public private(set) var preview: Loadable<InvitePreview> = .loading
  public var selectedMemberId: Member.ID?
  public var isNewMember = false
  public var newMemberName: String
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?

  private let repository: any InvitesRepository
  private let onJoined: (ExpenseGroup.ID) -> Void

  public init(
    token: String,
    accountName: String,
    repository: any InvitesRepository,
    onJoined: @escaping (ExpenseGroup.ID) -> Void
  ) {
    self.token = token
    self.accountName = accountName
    self.newMemberName = accountName
    self.repository = repository
    self.onJoined = onJoined
    self.idempotencyKey = IdempotencyKey()
  }

  public func load() async {
    preview = .loading
    do throws(AppError) {
      let fetched = try await repository.preview(token: token)
      if fetched.alreadyJoined {
        onJoined(fetched.groupId)
        return
      }
      if selectedMemberId == nil && !isNewMember {
        selectedMemberId =
          fetched.members.first(where: {
            !$0.claimed && Self.normalizeName($0.name) == Self.normalizeName(accountName)
          })?.id
      }
      preview = .loaded(fetched)
    } catch {
      preview = .failed(error)
    }
  }

  public var selectedMember: InvitePreview.PreviewMember? {
    guard !isNewMember, let selectedMemberId, let p = preview.value else { return nil }
    return p.members.first(where: { $0.id == selectedMemberId && !$0.claimed })
  }

  public var chosenName: String {
    if isNewMember {
      return newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return selectedMember?.name ?? ""
  }

  public var canSubmit: Bool {
    !chosenName.isEmpty && !isSubmitting && (isNewMember || selectedMember != nil)
  }

  public func selectExistingMember(_ memberId: Member.ID) {
    selectedMemberId = memberId
    isNewMember = false
  }

  public func chooseNewMember() {
    isNewMember = true
    selectedMemberId = nil
  }

  public func submit() async {
    guard canSubmit else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    let choice: JoinChoice
    if isNewMember {
      choice = .newMember(name: chosenName)
    } else if let member = selectedMember {
      choice = .existingMember(member.id)
    } else {
      return
    }
    do throws(AppError) {
      let groupId = try await repository.join(
        token: token,
        choice: choice,
        key: idempotencyKey
      )
      onJoined(groupId)
    } catch {
      submitError = error
      if case .api("MEMBER_ALREADY_CLAIMED", _) = error {
        selectedMemberId = nil
        await load()
      }
    }
  }

  public static func normalizeName(_ name: String) -> String {
    name
      .folding(
        options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi")
      )
      .replacingOccurrences(of: "đ", with: "d")
      .replacingOccurrences(of: "Đ", with: "d")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }
}
