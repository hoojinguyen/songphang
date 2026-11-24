import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct SettleView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Bindable private var model: SettleModel
  private let isEmailVerified: Bool
  private let onCancel: () -> Void
  private let onBackToGroups: () -> Void

  public init(
    model: SettleModel,
    isEmailVerified: Bool = true,
    onCancel: @escaping () -> Void,
    onBackToGroups: @escaping () -> Void = {}
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onCancel = onCancel
    self.onBackToGroups = onBackToGroups
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        switch model.state {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 110)

        case .failed(let error):
          if case .api(_, 404) = error {
            VStack(spacing: 16) {
              Text(L10n.tr("common.groupNotFound"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onBackToGroups)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 64)
          } else {
            LoadError {
              Task { await model.load() }
            }
          }

        case .loaded(let data):
          if data.group.role == .viewer {
            VStack(spacing: 16) {
              Text(L10n.tr("common.forbidden"))
                .font(Typography.bodyBold)
              SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 64)
          } else {
            loadedContent(data: data)
          }
        }
      }
      .padding(20)
      .scaleEffect(model.isRecorded ? 0.95 : 1.0)
      .opacity(model.isRecorded ? 0.0 : 1.0)
      .animation(
        reduceMotion ? nil : .spring(duration: 0.2, bounce: 0.15),
        value: model.isRecorded
      )
    }
    .background(Tokens.bg.ignoresSafeArea())
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if isEmailVerified, case .loaded(let data) = model.state, data.group.role != .viewer {
        submitButton
      }
    }
    .navigationBarBackButtonHidden(true)
    .task {
      if model.state.value == nil {
        await model.load()
      }
    }
  }

  private var submitButton: some View {
    let currentAmount = model.amount ?? .zero
    return SPButton(
      L10n.t("settle.submit", ["amount": MoneyFormat.full(currentAmount)]),
      variant: .accent,
      size: .lg,
      isFullWidth: true,
      isDisabled: !currentAmount.isPositive,
      isPending: model.isSubmitting
    ) {
      Task { await model.submit(reduceMotion: reduceMotion) }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(Tokens.bg)
  }

  @ViewBuilder
  private func loadedContent(data: SettleModel.ScreenData) -> some View {
    let myMemberId = data.group.myMemberId
    // Read here so the field re-renders when the model reformats the typed digits.
    let amountText = model.amountText
    let title: String = {
      if data.toMember.id == myMemberId {
        return L10n.tr("settle.titleReceived")
      } else if data.fromMember.id == myMemberId {
        return L10n.tr("settle.titlePaid")
      } else {
        return L10n.tr("settle.title")
      }
    }()

    SPScreenHeader(
      title: title,
      backLabel: L10n.tr("common.cancel"),
      onBack: onCancel
    )

    HStack(spacing: 20) {
      VStack(spacing: 12) {
        MemberShapeView(
          shape: data.fromMember.shape,
          color: data.fromMember.color,
          name: data.fromMember.name,
          size: 104
        )
        Text(data.fromMember.id == myMemberId ? L10n.tr("common.you") : data.fromMember.name)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      Image(systemName: "arrow.right")
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(Tokens.ink)

      VStack(spacing: 12) {
        MemberShapeView(
          shape: data.toMember.shape,
          color: data.toMember.color,
          name: data.toMember.name,
          size: 104
        )
        Text(data.toMember.id == myMemberId ? L10n.tr("common.you") : data.toMember.name)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 40, style: .continuous))

    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.t("settle.amountLabel", ["name": data.fromMember.name]))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      SettleAmountField(
        value: amountText,
        label: L10n.t("settle.amountLabel", ["name": data.fromMember.name]),
        isDisabled: model.isSubmitting,
        onChange: { model.updateAmountText($0) }
      )
    }

    Text(L10n.t("settle.partialHint", ["name": data.fromMember.name]))
      .font(Typography.caption)
      .foregroundStyle(Tokens.muted)

    HStack(spacing: 8) {
      dayButton(label: L10n.tr("settle.today"), selection: .today)
      dayButton(label: L10n.tr("settle.yesterday"), selection: .yesterday)
      dayButton(label: L10n.tr("settle.otherDay"), selection: .other)
    }
    .disabled(model.isSubmitting)
    .accessibilityLabel(L10n.tr("expenseForm.occurredAtLabel"))

    if model.daySelection == .other {
      DatePicker(
        L10n.tr("settle.otherDay"),
        selection: $model.customDate,
        displayedComponents: [.date]
      )
      .labelsHidden()
      .disabled(model.isSubmitting)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
      .background(Tokens.surface, in: Capsule())
    }

    if let amt = model.amount, amt.isPositive, amt == data.debt {
      Text(L10n.t("settle.clears", ["name": data.fromMember.name]))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          Tokens.phraseSplit,
          in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
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

    if !isEmailVerified {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
  }

  private func dayButton(label: String, selection: SettleModel.DaySelection) -> some View {
    let isSelected = (model.daySelection == selection)
    return Button {
      model.daySelection = selection
    } label: {
      Text(label)
        .font(Typography.subheadlineBold)
        .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
          isSelected ? Tokens.ink : Tokens.surface,
          in: Capsule()
        )
    }
    .buttonStyle(.plain)
  }
}

private struct SettleAmountField: View {
  let value: String
  let label: String
  let isDisabled: Bool
  let onChange: (String) -> Void
  @State private var text: String
  @FocusState private var isFocused: Bool

  init(value: String, label: String, isDisabled: Bool, onChange: @escaping (String) -> Void) {
    self.value = value
    self.label = label
    self.isDisabled = isDisabled
    self.onChange = onChange
    self._text = State(initialValue: value)
  }

  // The field keeps its own text so the model's reformatted value is written back
  // after each keystroke; a direct binding left the raw typed text on screen.
  var body: some View {
    TextField("0", text: $text)
      .keyboardType(.numberPad)
      .focused($isFocused)
      .disabled(isDisabled)
      .multilineTextAlignment(.center)
      .font(.system(size: 44, weight: .black))
      .foregroundStyle(Tokens.ink)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, minHeight: 92)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(Tokens.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
              .strokeBorder(Tokens.ink, lineWidth: 3)
          )
      )
      .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
      .onTapGesture {
        if !isDisabled {
          isFocused = true
        }
      }
      .onChange(of: text) { _, newText in
        if newText != value { onChange(newText) }
      }
      .onChange(of: value) { _, newValue in
        if text != newValue { text = newValue }
      }
      .accessibilityLabel(label)
  }
}

#if DEBUG
  #Preview("Settle Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    SettleView(
      model: SettleModel(
        groupId: TripScenario.groupId,
        fromMemberId: TripScenario.thuId,
        toMemberId: TripScenario.minhId,
        initialAmount: Money(210_000),
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        balancesRepository: FakeBalancesRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        onSaved: {}
      ),
      onCancel: {}
    )
  }
#endif
