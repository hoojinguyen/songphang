import DesignSystem
import Domain
import PhotosUI
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct ExpenseFormView: View {
  @Bindable private var model: ExpenseFormModel
  private let isEmailVerified: Bool
  private let onCancel: () -> Void
  @FocusState private var isDescriptionFocused: Bool
  @State private var isManagingCategories = false
  @State private var pickedPhotoItem: PhotosPickerItem?

  public init(
    model: ExpenseFormModel,
    isEmailVerified: Bool = true,
    onCancel: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onCancel = onCancel
  }

  public var body: some View {
    Group {
      switch model.state {
      case .loading:
        ScrollView {
          LoadingSkeleton(rowCount: 3, rowHeight: 110)
            .padding(20)
        }

      case .failed(let error):
        if case .api(_, 404) = error {
          VStack(spacing: 16) {
            SPScreenHeader(title: "", backLabel: L10n.tr("common.back"), onBack: onCancel)
            Spacer()
            Text(L10n.tr("common.groupNotFound"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else {
          VStack {
            SPScreenHeader(title: "", backLabel: L10n.tr("common.back"), onBack: onCancel)
            Spacer()
            LoadError {
              Task { await model.load() }
            }
            Spacer()
          }
          .padding(20)
        }

      case .loaded(let data):
        if data.group.role == .viewer {
          VStack(spacing: 16) {
            SPScreenHeader(title: "", backLabel: L10n.tr("common.back"), onBack: onCancel)
            Spacer()
            Text(L10n.tr("common.forbidden"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else if !isEmailVerified {
          VStack(spacing: 16) {
            SPScreenHeader(title: "", backLabel: L10n.tr("common.back"), onBack: onCancel)
            SPCard(tone: .accent, padding: 20) {
              Text(L10n.tr("verify.banner"))
                .font(Typography.subheadlineBold)
            }
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else if let editingTx = data.editingTransaction, editingTx.deletedAt != nil {
          VStack(spacing: 16) {
            SPScreenHeader(title: "", backLabel: L10n.tr("common.back"), onBack: onCancel)
            Spacer()
            Text(L10n.tr("expenseForm.deletedNotice"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else if model.isSplitEditorOpen {
          let active = model.sharerMembers
          let payerNames = model.payerMembers.filter { model.payerIds.contains($0.id) }
            .map(\.name)
            .joined(separator: ", ")
          SplitEditorView(
            splitState: Binding(
              get: { model.splitState },
              set: {
                model.splitState = $0
                model.schedulePreview()
                if $0.method == .items {
                  model.scheduleItemsPreview()
                }
              }
            ),
            members: active,
            amount: model.effectiveAmount,
            description: model.descriptionText.isEmpty ? model.headerTitle : model.descriptionText,
            payerLine: L10n.t("expenseForm.payerAmountLabel", ["name": payerNames]),
            shares: model.previewShares,
            isPreviewPending: model.isPreviewPending,
            allowItems: model.transactionType == .expense,
            itemsPreview: model.itemsPreview,
            isItemsPreviewCurrent: model.isItemsPreviewCurrent,
            itemsPreviewError: model.itemsPreviewError,
            onItemsChange: {
              model.scheduleItemsPreview()
            },
            onDone: { model.isSplitEditorOpen = false }
          )
        } else {
          formContent(data: data)
        }
      }
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .sheet(isPresented: $isManagingCategories) {
      NavigationStack {
        ScrollView {
          CategoryManagementSection(
            groupId: model.groupId,
            categories: model.state.value?.categories ?? [],
            categoriesRepository: model.categoriesRepository,
            onChanged: { updated in
              model.updateCategories(updated)
            }
          )
          .padding(20)
        }
        .background(Tokens.bg.ignoresSafeArea())
        .navigationTitle(L10n.tr("categories.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(L10n.tr("common.back")) {
              isManagingCategories = false
            }
          }
        }
      }
      .presentationDetents([.medium, .large])
    }
    .task {
      if model.state.value == nil {
        await model.load()
      }
      if ProcessInfo.processInfo.arguments.contains("--simulate-conflict") {
        model.simulateConflictForExercise()
      }
    }
  }

  @ViewBuilder
  private func formContent(data: ExpenseFormModel.ScreenData) -> some View {
    let active = model.sharerMembers
    let myMemberId = data.group.myMemberId
    let isEditing = (data.editingTransaction != nil)

    VStack(spacing: 0) {
      Group {
        if isEditing {
          SPScreenHeader(
            title: model.headerTitle,
            backLabel: L10n.tr("common.cancel"),
            onBack: onCancel
          )
        } else {
          SPScreenHeader(
            title: model.headerTitle,
            backLabel: L10n.tr("common.cancel"),
            onBack: onCancel
          ) {
            TypeSwitchView(
              value: model.transactionType,
              onChange: { model.setType($0) }
            )
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 6)

      scrollingForm(data: data, active: active, myMemberId: myMemberId, isEditing: isEditing)
    }
    // The member grids are four columns wide and cannot reflow at accessibility sizes.
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }

  @ViewBuilder
  private func scrollingForm(
    data: ExpenseFormModel.ScreenData,
    active: [Member],
    myMemberId: Member.ID?,
    isEditing: Bool
  ) -> some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          if !isEditing, let reading = model.initialReading, !model.isUnparsedBannerDismissed {
            UnparsedBannerView(
              reading: reading,
              activeCount: active.count,
              onDismiss: { model.isUnparsedBannerDismissed = true }
            )
          }

          AmountFieldView(
            value: model.amountText,
            onChange: { model.updateAmountText($0) },
            onAddThousands: { model.appendThousands() }
          )

          TextField(
            model.transactionType == .transfer
              ? L10n.tr("expenseForm.descriptionTransferPlaceholder")
              : L10n.tr("expenseForm.descriptionPlaceholder"),
            text: $model.descriptionText
          )
          .focused($isDescriptionFocused)
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 16)
          .frame(height: 56)
          .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
          .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
          .onTapGesture { isDescriptionFocused = true }
          .accessibilityLabel(L10n.tr("expenseForm.descriptionLabel"))

          if model.transactionType == .transfer {
            TransferFieldsView(
              members: model.transferMembers,
              fromId: model.transferFrom,
              toId: model.transferTo,
              onFrom: { model.setTransferFrom($0) },
              onTo: { model.transferTo = $0 }
            )
          } else {
            CategoryPickerView(
              categories: data.categories,
              selected: model.category,
              selectedCustomId: model.categoryId,
              onSelect: { model.selectBuiltinCategory($0) },
              onSelectCustom: { model.selectCustomCategory($0) },
              onManageCategories: { isManagingCategories = true }
            )

            VStack(alignment: .leading, spacing: 8) {
              Text(
                model.transactionType == .income
                  ? L10n.tr("expenseForm.receiverTitle")
                  : L10n.tr("expenseForm.payerTitle")
              )
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.ink)

              MemberToggleGridView(
                members: model.payerMembers,
                selectedIds: model.payerIds,
                disabledIds: [],
                isCaptionDimmed: false,
                captionFor: { member in
                  if member.kind == .fund {
                    return L10n.t("fund.payerOption", ["name": member.name])
                  }
                  return member.id == myMemberId ? L10n.tr("common.you") : member.name
                },
                onToggle: { model.togglePayer($0) }
              )
            }
            .padding(12)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))

            if model.payerIds.count > 1 {
              PayerAmountsView(
                members: model.payerMembers.filter { model.payerIds.contains($0.id) },
                values: model.payerAmounts,
                totalAmount: model.amount,
                onChange: { id, val in model.setPayerAmount(val, for: id) }
              )
            }

            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(L10n.tr("expenseForm.sharersTitle"))
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
                Spacer()
                Button {
                  model.isSplitEditorOpen = true
                } label: {
                  Text(
                    L10n.t(
                      "split.change",
                      ["method": model.splitState.method.methodName]
                    )
                  )
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
                  .padding(.horizontal, 12)
                  .frame(minHeight: 44)
                  .background(
                    Tokens.phraseSplit,
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                  )
                }
                .buttonStyle(.plain)
              }

              MemberToggleGridView(
                members: active,
                selectedIds: model.splitState.ids,
                disabledIds: [],
                isCaptionDimmed: model.isPreviewPending,
                captionFor: { member in
                  guard model.splitState.ids.contains(member.id) else {
                    return member.name
                  }
                  if model.previewError == nil,
                    let share = model.previewShares.first(where: { $0.memberId == member.id })
                  {
                    return MoneyFormat.amount(share.amount)
                  }
                  return L10n.tr("common.pendingValue")
                },
                onToggle: { model.toggleSharer($0) }
              )

              if model.splitState.ids.isEmpty {
                Text(L10n.tr("expenseForm.needSharer"))
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
            }
            .padding(12)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr("expenseForm.occurredAtLabel"))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            DatePicker(
              L10n.tr("expenseForm.occurredAtLabel"),
              selection: $model.occurredAtDate,
              displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
          }

          PhotoRowView(
            attachments: model.attachments,
            readOnly: false,
            isUploading: model.isUploadingAttachment,
            errorMessage: photoRowErrorMessage,
            loadContent: { attachmentId in
              try await model.attachmentsRepository.content(
                groupId: model.groupId,
                attachmentId: attachmentId
              )
            },
            onRemove: { attachmentId in
              model.removeAttachment(id: attachmentId)
            }
          ) {
            if model.attachments.count >= 3 {
              Text("+ \(L10n.tr("attachments.add"))")
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.muted)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(Tokens.sunken, in: Capsule())
                .opacity(0.5)
            } else {
              PhotosPicker(
                selection: $pickedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
              ) {
                HStack(spacing: 6) {
                  Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                  Text(L10n.tr("attachments.add"))
                    .font(Typography.captionBold)
                }
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(Tokens.sunken, in: Capsule())
              }
              .disabled(model.isUploadingAttachment)
            }
          }
          .onChange(of: pickedPhotoItem) { _, item in
            guard let item else { return }
            pickedPhotoItem = nil
            Task {
              if let rawData = try? await item.loadTransferable(type: Data.self) {
                await model.uploadAttachment(rawImageData: rawData)
              }
            }
          }

          if let submitError = model.submitError {
            Text(
              submitError == .api(code: "FORBIDDEN", status: 403)
                ? L10n.tr("common.forbidden")
                : L10n.tr("common.saveError")
            )
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
          }

          if model.previewError != nil {
            Text(L10n.tr("common.loadError"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.coral)
          }

          if model.transactionType != .transfer, model.amount.isPositive {
            if let overdraft = model.fundOverdrawnAmount() {
              SPCard(tone: .accent, padding: 14) {
                Text(L10n.t("fund.overdrawnWarning", ["amount": MoneyFormat.full(overdraft)]))
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
              }
            }

            if model.previewWarnings.contains(.budgetOver) {
              Text(L10n.tr("budget.overWarning"))
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                  Tokens.coral, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            SplitStatusBannerView(
              status: model.splitState.status(
                from: active,
                totalAmount: model.effectiveAmount,
                itemsPreview: model.itemsPreview,
                isItemsPreviewCurrent: model.isItemsPreviewCurrent
              )
            )
          }

          if let conflict = model.conflictTransaction {
            ConflictNoticeView(
              current: conflict,
              onReload: { model.reloadWithConflict() }
            )
            .id("conflict-notice")
          }

          if model.deleteError != nil {
            Text(L10n.tr("common.saveError"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.coral)
          }

          if isEditing {
            Button {
              Task { await model.deleteTransaction() }
            } label: {
              Text(L10n.tr("expenseForm.delete"))
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Tokens.debtSoft, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(model.isDeleting)
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        saveButton
      }
      .onChange(of: model.conflictTransaction) { _, newValue in
        if newValue != nil {
          proxy.scrollTo("conflict-notice", anchor: .bottom)
        }
      }
    }
  }
}

extension ExpenseFormView {
  private var photoRowErrorMessage: String? {
    if model.isAttachmentLimitError {
      return L10n.tr("attachments.maxLimit")
    }
    if let imgErr = model.attachmentImageError {
      return UploadErrorFormatter.message(for: imgErr)
    }
    if let err = model.attachmentError {
      return UploadErrorFormatter.message(for: err)
    }
    return nil
  }

  private var saveButton: some View {
    SPButton(
      model.saveButtonTitle,
      variant: .accent,
      size: .lg,
      isFullWidth: true,
      isDisabled: !model.canSubmit,
      isPending: model.isSubmitting
    ) {
      Task { await model.submit() }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(Tokens.bg)
  }
}

#if DEBUG
  #Preview("New Expense Form") {
    let world = FakeWorld(preset: .tripStep4)
    ExpenseFormView(
      model: ExpenseFormModel(
        groupId: TripScenario.groupId,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        attachmentsRepository: FakeAttachmentsRepository(world: world),
        onSaved: {}
      ),
      onCancel: {}
    )
  }

  #Preview("Edit Transaction Form") {
    let world = FakeWorld(preset: .tripStep4)
    ExpenseFormView(
      model: ExpenseFormModel(
        groupId: TripScenario.groupId,
        editingTransactionId: TripScenario.t1Transaction.id,
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        categoriesRepository: FakeCategoriesRepository(world: world),
        attachmentsRepository: FakeAttachmentsRepository(world: world),
        onSaved: {}
      ),
      onCancel: {}
    )
  }
#endif
