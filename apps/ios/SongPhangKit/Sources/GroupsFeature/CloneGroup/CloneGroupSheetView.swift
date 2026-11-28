import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct CloneGroupSheetView: View {
  private let group: ExpenseGroup
  private let repository: any GroupsRepository
  private let initialNameDraft: String
  private let onDismiss: () -> Void
  private let onCloned: (ExpenseGroup) -> Void

  @State private var nameDraft: String
  @State private var copyPaymentMethods = true
  @State private var copyCategories = false
  @State private var isSubmitting = false
  @State private var errorMessage: String?
  @State private var idempotencyKey = IdempotencyKey()

  public init(
    group: ExpenseGroup,
    repository: any GroupsRepository,
    onDismiss: @escaping () -> Void,
    onCloned: @escaping (ExpenseGroup) -> Void
  ) {
    self.group = group
    self.repository = repository
    self.onDismiss = onDismiss
    self.onCloned = onCloned
    let suffix = L10n.tr("ios.groups.cloneSuffix")
    let maxBase = 80 - suffix.count
    let base = String(group.name.prefix(maxBase)).trimmingCharacters(in: .whitespaces)
    let initial = "\(base)\(suffix)"
    self.initialNameDraft = initial
    self._nameDraft = State(initialValue: initial)
  }

  private var isDirty: Bool {
    nameDraft != initialNameDraft || !copyPaymentMethods || copyCategories
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("clone.nameLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            TextField("", text: $nameDraft)
              .font(Typography.sectionTitle)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 20)
              .frame(minHeight: 56)
              .background(Tokens.surface)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
              .accessibilityLabel(L10n.tr("clone.nameLabel"))
          }

          VStack(spacing: 16) {
            Toggle(isOn: $copyPaymentMethods) {
              Text(L10n.tr("clone.copyPaymentMethods"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
            }
            .tint(Tokens.credit)

            Toggle(isOn: $copyCategories) {
              Text(L10n.tr("clone.copyCategories"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
            }
            .tint(Tokens.credit)
          }
          .padding(20)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

          if let errorMessage {
            Text(errorMessage)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.debt)
          }

          let trimmedDraft = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
          SPButton(
            L10n.tr("clone.submit"),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            isDisabled: isSubmitting || trimmedDraft.isEmpty || trimmedDraft.count > 80,
            isPending: isSubmitting
          ) {
            submitClone()
          }
        }
        .padding(20)
        .spFittedSheetContent()
      }
      .background(Tokens.bg.ignoresSafeArea())
      .navigationTitle(L10n.tr("clone.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          SheetCancelButton {
            if !isSubmitting {
              onDismiss()
            }
          }
          .disabled(isSubmitting)
        }
      }
    }
    .spSheet(.fitted, embedsNavigationStack: true)
    .discardGuard(
      isDirty: isDirty && !isSubmitting,
      onDiscard: {
        if !isSubmitting {
          onDismiss()
        }
      }
    )
  }

  private func submitClone() {
    let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= 80 else { return }
    isSubmitting = true
    errorMessage = nil
    Task {
      do throws(AppError) {
        let cloned = try await repository.clone(
          groupId: group.id,
          name: trimmed,
          copyPaymentMethods: copyPaymentMethods,
          copyCategories: copyCategories,
          idempotencyKey: idempotencyKey
        )
        isSubmitting = false
        onCloned(cloned)
      } catch {
        isSubmitting = false
        errorMessage = L10n.tr("common.saveError")
      }
    }
  }
}
