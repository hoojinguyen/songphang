public import Domain
public import SwiftUI

public struct CategoryManagementSection: View {
  private let groupId: ExpenseGroup.ID
  private let categories: [GroupCategory]
  private let categoriesRepository: any CategoriesRepository
  private let isDisabled: Bool
  private let onChanged: ([GroupCategory]) -> Void
  private let onUnauthorized: () -> Void

  @State private var newName = ""
  @State private var newColor: MemberColor = .mint
  @State private var createKey = IdempotencyKey()
  @State private var isBusy = false
  @State private var errorMessage: String?

  public init(
    groupId: ExpenseGroup.ID,
    categories: [GroupCategory],
    categoriesRepository: any CategoriesRepository,
    isDisabled: Bool = false,
    onChanged: @escaping ([GroupCategory]) -> Void,
    onUnauthorized: @escaping () -> Void = {}
  ) {
    self.groupId = groupId
    self.categories = categories
    self.categoriesRepository = categoriesRepository
    self.isDisabled = isDisabled
    self.onChanged = onChanged
    self.onUnauthorized = onUnauthorized
  }

  public var body: some View {
    let live = categories.filter { !$0.archived }
    let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)

    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.tr("categories.title"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)

      if !live.isEmpty {
        VStack(spacing: 8) {
          ForEach(live) { category in
            CategoryRowItemView(
              category: category,
              isDisabled: isDisabled || isBusy,
              onSave: { updatedName, updatedColor in
                await update(category: category, name: updatedName, color: updatedColor)
              },
              onArchive: {
                await archive(category: category)
              }
            )
          }
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        SPTextField(
          label: L10n.tr("categories.nameLabel"),
          text: $newName,
          maxLength: 30
        )

        CategoryColorSwatchesView(
          selected: $newColor,
          isDisabled: isDisabled || isBusy
        )

        SPButton(
          L10n.tr("categories.add"),
          variant: .surface,
          isFullWidth: true,
          isDisabled: isDisabled || isBusy || trimmedNew.isEmpty,
          isPending: isBusy
        ) {
          Task { await createCategory(name: trimmedNew) }
        }
      }

      if let errorMessage {
        Text(errorMessage)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }

  private func createCategory(name: String) async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    let key = createKey
    defer {
      isBusy = false
      createKey = IdempotencyKey()
    }
    do throws(AppError) {
      _ = try await categoriesRepository.create(
        groupId: groupId,
        name: name,
        color: newColor,
        key: key
      )
      newName = ""
      let refreshed = try await categoriesRepository.list(groupId: groupId)
      onChanged(refreshed)
    } catch {
      handleError(error)
    }
  }

  private func update(category: GroupCategory, name: String?, color: MemberColor?) async -> Bool {
    guard !isBusy else { return false }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do throws(AppError) {
      _ = try await categoriesRepository.update(
        groupId: groupId,
        categoryId: category.id,
        name: name,
        color: color
      )
      let refreshed = try await categoriesRepository.list(groupId: groupId)
      onChanged(refreshed)
      return true
    } catch {
      handleError(error)
      return false
    }
  }

  private func archive(category: GroupCategory) async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do throws(AppError) {
      try await categoriesRepository.archive(groupId: groupId, categoryId: category.id)
      let refreshed = try await categoriesRepository.list(groupId: groupId)
      onChanged(refreshed)
    } catch {
      handleError(error)
    }
  }

  private func handleError(_ error: AppError) {
    if error == .unauthorized {
      onUnauthorized()
      return
    }
    switch error {
    case .api("CATEGORY_EXISTS", _):
      errorMessage = L10n.tr("categories.duplicate")
    case .api("LIMIT_REACHED", _):
      errorMessage = L10n.tr("categories.limitReached")
    case .api(_, 403):
      errorMessage = L10n.tr("common.forbidden")
    default:
      errorMessage = L10n.tr("common.saveError")
    }
  }
}

private struct CategoryColorSwatchesView: View {
  @Binding var selected: MemberColor
  let isDisabled: Bool

  var body: some View {
    HStack(spacing: 8) {
      ForEach(MemberColor.allCases, id: \.self) { color in
        let isSelected = (selected == color)
        Button {
          selected = color
        } label: {
          Circle()
            .fill(Tokens.color(for: color))
            .frame(width: 22, height: 22)
            .frame(width: 44, height: 44)
            .background(isSelected ? Tokens.surface : Tokens.bg, in: Circle())
            .overlay {
              if isSelected {
                Circle().strokeBorder(Tokens.ink, lineWidth: 2)
              }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(
          L10n.t("categories.colorLabel", ["color": CategoryDisplay.localizedColorName(for: color)])
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
      }
    }
  }
}

private struct CategoryRowItemView: View {
  let category: GroupCategory
  let isDisabled: Bool
  let onSave: (String?, MemberColor?) async -> Bool
  let onArchive: () async -> Void

  @State private var isEditing = false
  @State private var nameDraft = ""
  @State private var colorDraft: MemberColor = .mint

  var body: some View {
    if isEditing {
      let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
      let nameChanged = trimmed != category.name
      let colorChanged = colorDraft != category.color

      VStack(alignment: .leading, spacing: 10) {
        TextField("", text: $nameDraft)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 14)
          .frame(minHeight: 44)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .onChange(of: nameDraft) { _, next in
            if next.count > 30 { nameDraft = String(next.prefix(30)) }
          }
          .accessibilityLabel(L10n.tr("categories.nameLabel"))

        CategoryColorSwatchesView(selected: $colorDraft, isDisabled: isDisabled)

        HStack(spacing: 8) {
          SPButton(
            L10n.tr("common.cancel"),
            variant: .surface,
            isFullWidth: true,
            isDisabled: isDisabled
          ) {
            isEditing = false
          }
          SPButton(
            L10n.tr("categories.saveName"),
            variant: .primary,
            isFullWidth: true,
            isDisabled: isDisabled || trimmed.isEmpty || (!nameChanged && !colorChanged)
          ) {
            Task {
              let saved = await onSave(
                nameChanged ? trimmed : nil,
                colorChanged ? colorDraft : nil
              )
              if saved { isEditing = false }
            }
          }
        }
      }
      .padding(12)
      .background(Tokens.bg)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    } else {
      HStack(spacing: 12) {
        Circle()
          .fill(Tokens.color(for: category.color))
          .frame(width: 14, height: 14)

        Button {
          nameDraft = category.name
          colorDraft = category.color
          isEditing = true
        } label: {
          Text(category.name)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.t("categories.edit", ["name": category.name]))

        Button(L10n.tr("categories.archive")) {
          Task { await onArchive() }
        }
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .disabled(isDisabled)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(Tokens.bg)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
  }
}
