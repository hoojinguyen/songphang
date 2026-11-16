public import Domain
import Foundation
public import Observation

@Observable
public final class CreateGroupModel {
  public struct AddedMember: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String? = nil, name: String) {
      self.id = id ?? UUID().uuidString
      self.name = name
    }
  }

  public var name = ""
  public var addedMembers: [AddedMember] = []
  public private(set) var isSubmitting = false
  public private(set) var submitError: AppError?
  public let idempotencyKey: IdempotencyKey

  private let repository: any GroupsRepository
  private let onCreated: (ExpenseGroup.ID) -> Void

  public init(
    repository: any GroupsRepository,
    onCreated: @escaping (ExpenseGroup.ID) -> Void
  ) {
    self.repository = repository
    self.onCreated = onCreated
    self.idempotencyKey = IdempotencyKey()
  }

  public var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public var canSubmit: Bool {
    !trimmedName.isEmpty && !isSubmitting
  }

  public func addMember(_ rawName: String) {
    let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, addedMembers.count < 99 else { return }
    addedMembers.append(AddedMember(name: trimmed))
  }

  public func removeMember(at index: Int) {
    guard addedMembers.indices.contains(index) else { return }
    addedMembers.remove(at: index)
  }

  public func submit() async {
    guard canSubmit else { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }
    do throws(AppError) {
      let created = try await repository.create(
        name: trimmedName,
        memberNames: addedMembers.map(\.name),
        key: idempotencyKey
      )
      onCreated(created.id)
    } catch {
      submitError = error
    }
  }
}
