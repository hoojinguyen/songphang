import DesignSystem
public import Domain
public import SwiftUI

public struct CreateFundSheetView: View {
  private let groupId: ExpenseGroup.ID
  private let people: [Member]
  private let fundRepository: any FundRepository
  private let isOffline: Bool
  private let onCreated: () -> Void
  private let onDismiss: () -> Void
  private let onUnauthorized: () -> Void

  private let initialHolderMemberId: Member.ID?

  @State private var name: String = L10n.tr("fund.defaultName")
  @State private var holderMemberId: Member.ID?
  @State private var key = IdempotencyKey()
  @State private var isSubmitting = false
  @State private var errorMessage: String?

  public init(
    groupId: ExpenseGroup.ID,
    people: [Member],
    fundRepository: any FundRepository,
    isOffline: Bool = false,
    onCreated: @escaping () -> Void,
    onDismiss: @escaping () -> Void,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.people = people
    self.fundRepository = fundRepository
    self.isOffline = isOffline
    self.onCreated = onCreated
    self.onDismiss = onDismiss
    self.onUnauthorized = onUnauthorized
    let firstId = people.first?.id
    self.initialHolderMemberId = firstId
    _holderMemberId = State(initialValue: firstId)
  }

  private var isDirty: Bool {
    name != L10n.tr("fund.defaultName") || holderMemberId != initialHolderMemberId
  }

  public var body: some View {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          SPTextField(
            label: L10n.tr("fund.nameLabel"),
            text: $name,
            maxLength: 50
          )

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("fund.holderLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                holderPill(title: L10n.tr("fund.noHolder"), selected: holderMemberId == nil) {
                  holderMemberId = nil
                }
                ForEach(people) { person in
                  holderPill(title: person.name, selected: holderMemberId == person.id) {
                    holderMemberId = person.id
                  }
                }
              }
            }
          }

          if let errorMessage {
            Text(errorMessage)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
          }

          SPButton(
            L10n.tr("fund.createSubmit"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: isOffline || isSubmitting || trimmed.isEmpty,
            isPending: isSubmitting
          ) {
            Task { await submit(name: trimmed) }
          }
        }
        .padding(20)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("fund.createEntry"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          SheetCancelButton(action: onDismiss)
            .disabled(isSubmitting)
        }
      }
    }
    .spSheet(.half, embedsNavigationStack: true)
    .discardGuard(isDirty: isDirty && !isSubmitting, onDiscard: onDismiss)
  }

  private func holderPill(title: String, selected: Bool, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Text(title)
        .font(Typography.captionBold)
        .foregroundStyle(selected ? Tokens.surface : Tokens.ink)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(selected ? Tokens.ink : Tokens.surface, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  private func submit(name: String) async {
    guard !isSubmitting else { return }
    isSubmitting = true
    errorMessage = nil
    let currentKey = key
    defer { isSubmitting = false }
    do throws(AppError) {
      _ = try await fundRepository.create(
        groupId: groupId,
        name: name,
        holderMemberId: holderMemberId,
        key: currentKey
      )
      onCreated()
    } catch {
      if error == .unauthorized {
        onUnauthorized()
        return
      }
      key = IdempotencyKey()
      if case .api(_, 403) = error {
        errorMessage = L10n.tr("common.forbidden")
      } else {
        errorMessage = L10n.tr("common.saveError")
      }
    }
  }
}
