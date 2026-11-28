import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct QuickEntryView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Bindable private var model: QuickEntryModel
  private let isEmailVerified: Bool
  private let onCancel: () -> Void
  @FocusState private var isSentenceFocused: Bool

  public init(
    model: QuickEntryModel,
    isEmailVerified: Bool = true,
    onCancel: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onCancel = onCancel
  }

  public var body: some View {
    VStack(spacing: 16) {
      switch model.state {
      case .loading:
        LoadingSkeleton(rowCount: 3, rowHeight: 110)
          .padding(20)
        Spacer()

      case .failed(let error):
        if case .api(_, 404) = error {
          VStack(spacing: 16) {
            Spacer()
            Text(L10n.tr("common.groupNotFound"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.backToGroups"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else {
          VStack {
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
            Spacer()
            Text(L10n.tr("common.forbidden"))
              .font(Typography.bodyBold)
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else if !isEmailVerified {
          VStack(spacing: 16) {
            SPCard(tone: .accent, padding: 20) {
              Text(L10n.tr("verify.banner"))
                .font(Typography.subheadlineBold)
            }
            SPButton(L10n.tr("common.back"), variant: .surface, action: onCancel)
            Spacer()
          }
          .padding(20)
        } else {
          composeBody(data: data)
        }
      }
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationTitle(L10n.tr("compose.title"))
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if model.state.value == nil {
        await model.load()
      }
      isSentenceFocused = true
    }
  }

  @ViewBuilder
  private func composeBody(data: QuickEntryModel.ScreenData) -> some View {
    let activeMembers = data.members.filter(\.active)

    ScrollView {
      VStack(spacing: 16) {
        Text(data.group.name)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.muted)
          .frame(maxWidth: .infinity, alignment: .leading)
        if let reading = model.reading,
          !model.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          let isInteractive = QuickEntryModel.isRuleInteractiveQuestion(
            status: reading.status,
            issues: reading.issues,
            reader: reading.reader
          )
          let indexLabel: String? =
            model.isMultiDraft
            ? L10n.t(
              "compose.draftIndex",
              [
                "index": String(model.currentDraftIndex + 1),
                "count": String(model.draftQueue.count),
              ]
            )
            : nil
          let saveLabel: String? =
            (model.isMultiDraft && model.hasNextDraft) ? L10n.tr("compose.saveAndNext") : nil

          Group {
            if isInteractive {
              QuestionCardView(
                groupId: model.groupId,
                reading: reading,
                members: activeMembers,
                categories: data.categories,
                transactionsRepository: model.transactionsRepository,
                isDisabled: !model.isCurrentReadingUpToDate || model.isSaving,
                indexLabel: indexLabel,
                saveLabel: saveLabel,
                skipLabel: model.isMultiDraft ? L10n.tr("compose.skipDraft") : nil,
                onEdit: { resolved in
                  model.openManualEdit(with: resolved)
                },
                onSave: { resolved in
                  Task { await model.save(chosen: resolved, reduceMotion: reduceMotion) }
                },
                onSkip: model.isMultiDraft ? { model.skipDraft() } : nil
              )
              .id("\(reading.text):\(model.currentDraftIndex)")
            } else if reading.status == .ok {
              ConfirmationCardView(
                reading: reading,
                members: activeMembers,
                categories: data.categories,
                isDisabled: !model.isCurrentReadingUpToDate || model.isSaving,
                isBudgetOver: model.isCurrentReadingUpToDate
                  && model.previewWarnings.contains(.budgetOver),
                indexLabel: indexLabel,
                saveLabel: saveLabel,
                skipLabel: model.isMultiDraft ? L10n.tr("compose.skipDraft") : nil,
                onEdit: {
                  model.openManualEdit()
                },
                onSave: {
                  Task { await model.save(reduceMotion: reduceMotion) }
                },
                onSkip: model.isMultiDraft ? { model.skipDraft() } : nil
              )
              .id("\(reading.text):\(model.currentDraftIndex)")
            }
          }
          .scaleEffect(Motion.isReduced(reduceMotion) ? 1.0 : (model.isCollapsing ? 0.92 : 1.0))
          .opacity(model.isCollapsing ? 0.0 : 1.0)
          .spAnimation(Motion.quick, value: model.isCollapsing)
          .spAnimation(Motion.bounce, value: reading.text)
        }

        if model.isSlowReading {
          Text(L10n.tr("compose.reading"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.muted)
        }

        if model.parseError != nil {
          Text(L10n.tr("common.loadError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        }

        if model.saveError != nil {
          Text(L10n.tr("common.saveError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
    }

    Button {
      model.openManualEdit()
    } label: {
      Text(L10n.tr("feed.manualEntry"))
        .font(Typography.bodyBold)
        .foregroundStyle(Tokens.ink)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 20)

    HStack(alignment: .bottom, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        if let reading = model.reading,
          reading.reader != .ai,
          reading.text == model.sentence.trimmingCharacters(in: .whitespacesAndNewlines),
          !reading.spans.isEmpty
        {
          HighlightedSentenceView(text: reading.text, spans: reading.spans)
        }

        TextField(
          L10n.tr("compose.inputLabel"),
          text: Binding(
            get: { model.sentence },
            set: { model.updateSentence($0) }
          ),
          axis: .vertical
        )
        .font(Typography.body)
        .foregroundStyle(Tokens.ink)
        .lineLimit(1...3)
        .focused($isSentenceFocused)
        .onSubmit {
          model.sendImmediately()
        }
        .accessibilityLabel(L10n.tr("compose.inputLabel"))
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        model.sendImmediately()
      } label: {
        Image(systemName: "arrow.up")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Tokens.surface)
          .frame(width: 52, height: 52)
          .background(
            model.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              ? Tokens.sunken
              : Tokens.ink,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .disabled(model.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      .accessibilityLabel(L10n.tr("compose.send"))
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .padding(12)
    .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .onTapGesture { isSentenceFocused = true }
    .background(
      RoundedRectangle(cornerRadius: 30, style: .continuous)
        .fill(Tokens.surface)
        .overlay(
          RoundedRectangle(cornerRadius: 30, style: .continuous)
            .strokeBorder(Tokens.ink, lineWidth: 3)
        )
    )
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
  }
}

#if DEBUG
  #Preview("QuickEntry Ok") {
    let world = FakeWorld(preset: .tripStep4)
    QuickEntryView(
      model: QuickEntryModel(
        groupId: TripScenario.groupId,
        initialSentence: "cà phê 180k chia 4",
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        quickEntryRepository: FakeQuickEntryRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        onSaved: {},
        onOpenManualForm: { _ in }
      ),
      onCancel: {}
    )
  }

  #Preview("QuickEntry Needs Input") {
    let world = FakeWorld(preset: .tripStep4)
    QuickEntryView(
      model: QuickEntryModel(
        groupId: TripScenario.groupId,
        initialSentence: "cà phê 180k chia 3",
        groupsRepository: FakeGroupsRepository(world: world),
        membersRepository: FakeMembersRepository(world: world),
        quickEntryRepository: FakeQuickEntryRepository(world: world),
        transactionsRepository: FakeTransactionsRepository(world: world),
        onSaved: {},
        onOpenManualForm: { _ in }
      ),
      onCancel: {}
    )
  }
#endif
