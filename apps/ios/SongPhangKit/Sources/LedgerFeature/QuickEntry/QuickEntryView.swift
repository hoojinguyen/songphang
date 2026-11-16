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
    .navigationBarBackButtonHidden(true)
    .task {
      if model.state.value == nil {
        await model.load()
      }
    }
  }

  @ViewBuilder
  private func composeBody(data: QuickEntryModel.ScreenData) -> some View {
    let activeMembers = data.members.filter(\.active)
    SPScreenHeader(
      title: L10n.tr("compose.title"),
      subtitle: data.group.name,
      backLabel: L10n.tr("common.cancel"),
      onBack: onCancel
    )
    .padding(.horizontal, 20)
    .padding(.top, 8)

    ScrollView {
      VStack(spacing: 16) {
        if let reading = model.reading,
          !model.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          Group {
            switch reading.status {
            case .needsInput:
              QuestionCardView(
                groupId: model.groupId,
                reading: reading,
                members: activeMembers,
                transactionsRepository: model.transactionsRepository,
                isDisabled: !model.isCurrentReadingUpToDate || model.isSaving,
                onEdit: { resolved in
                  model.openManualEdit(with: resolved)
                },
                onSave: { resolved in
                  Task { await model.save(chosen: resolved, reduceMotion: reduceMotion) }
                }
              )
              .id(reading.text)

            case .ok:
              ConfirmationCardView(
                reading: reading,
                members: activeMembers,
                isDisabled: !model.isCurrentReadingUpToDate || model.isSaving,
                onEdit: {
                  model.openManualEdit()
                },
                onSave: {
                  Task { await model.save(reduceMotion: reduceMotion) }
                }
              )

            case .unparsed, .unknown:
              EmptyView()
            }
          }
          .scaleEffect(model.isCollapsing ? 0.92 : 1.0)
          .opacity(model.isCollapsing ? 0.0 : 1.0)
          .animation(
            reduceMotion ? nil : .spring(duration: 0.25, bounce: 0.15),
            value: model.isCollapsing
          )
          .animation(
            reduceMotion ? nil : .spring(duration: 0.28, bounce: 0.2),
            value: reading.text
          )
        }

        if model.parseError != nil {
          Text(L10n.tr("common.loadError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
        }

        if model.saveError != nil {
          Text(L10n.tr("common.saveError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.coral)
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
    .padding(12)
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
