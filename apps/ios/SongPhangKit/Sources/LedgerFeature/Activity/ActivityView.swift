import DesignSystem
import Domain
public import Foundation
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct ActivityView: View {
  @Bindable private var model: ActivityModel
  private let isEmailVerified: Bool
  private let onBack: () -> Void
  private let referenceDate: Date

  public init(
    model: ActivityModel,
    isEmailVerified: Bool = true,
    onBack: @escaping () -> Void,
    referenceDate: Date = Date()
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBack = onBack
    self.referenceDate = referenceDate
  }

  public var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 16) {
        if model.refreshError != nil {
          OfflineBanner()
        }

        SPScreenHeader(
          title: L10n.tr("activity.title"),
          subtitle: model.state.value?.group.name ?? "",
          onBack: onBack
        )

        Text(L10n.tr("activity.headline"))
          .font(Typography.pageTitle)
          .foregroundStyle(Tokens.ink)

        if model.isNotFound {
          Text(L10n.tr("common.groupNotFound"))
            .font(Typography.body)
            .foregroundStyle(Tokens.ink)
        } else {
          switch model.state {
          case .loading:
            LoadingSkeleton(rowCount: 3, rowHeight: 110)

          case .failed:
            LoadError {
              Task { await model.load() }
            }

          case .loaded(let data):
            if data.items.isEmpty {
              Text(L10n.tr("activity.empty"))
                .font(Typography.body)
                .foregroundStyle(Tokens.ink)
            } else {
              let canRestore =
                data.group.role.canWrite
                && isEmailVerified
              ForEach(Array(data.items.enumerated()), id: \.element.id) { index, entry in
                let label = LedgerDateLabels.dayLabel(for: entry.createdAt, now: referenceDate)
                let previousLabel: String? =
                  index > 0
                  ? LedgerDateLabels.dayLabel(
                    for: data.items[index - 1].createdAt,
                    now: referenceDate
                  )
                  : nil

                if previousLabel != label {
                  Text(label)
                    .font(Typography.captionBold)
                    .foregroundStyle(Tokens.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                ActivityRowView(
                  entry: entry,
                  members: data.members,
                  canRestore: canRestore,
                  isRestoring: model.restoringEntityId == entry.entityId,
                  hasRestoreError: model.restoreErrorEntityId == entry.entityId,
                  onRestore: { entityId in
                    Task { await model.restore(entityId: entityId) }
                  }
                )
                .task {
                  await model.loadNextPageIfNeeded(currentItem: entry)
                }
              }

              if model.isFetchingNextPage {
                Text(L10n.tr("activity.loadingOlder"))
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
                  .frame(maxWidth: .infinity, alignment: .center)
              }

              if model.hasNextPageError {
                LoadError(isRetrying: model.isFetchingNextPage) {
                  Task { await model.retryNextPage() }
                }
              }
            }
          }
        }
      }
      .padding(20)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .overlay(alignment: .bottom) {
      if let toast = model.toastMessage {
        Text(toast)
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.surface)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Tokens.ink, in: Capsule())
          .padding(.bottom, 20)
      }
    }
    .navigationBarBackButtonHidden(true)
    .task {
      if model.state.value == nil {
        await model.load()
      }
    }
  }
}

private struct ActivityRowView: View {
  let entry: ActivityItem
  let members: [Member]
  let canRestore: Bool
  let isRestoring: Bool
  let hasRestoreError: Bool
  let onRestore: (String) -> Void

  var body: some View {
    let actorMember = members.first(where: { $0.id == entry.actor?.memberId })
    let description = ActivitySentenceFormatter.describe(entry: entry, members: members)

    HStack(alignment: .top, spacing: 12) {
      if let actorMember {
        MemberShapeView(
          shape: actorMember.shape,
          color: actorMember.color,
          name: actorMember.name,
          size: 40,
          showInitial: false
        )
      } else {
        Circle()
          .fill(Tokens.sunken)
          .frame(width: 40, height: 40)
      }

      VStack(alignment: .leading, spacing: 8) {
        sentenceText(parts: description.parts)
          .font(Typography.subheadline)
          .foregroundStyle(Tokens.ink)
          .fixedSize(horizontal: false, vertical: true)

        if !description.chips.isEmpty {
          ChangeChipsView(chips: description.chips)
        }

        if entry.canRestore, canRestore, let entityId = entry.entityId {
          SPButton(
            L10n.tr("activity.restoreButton"),
            variant: .primary,
            isDisabled: isRestoring
          ) {
            onRestore(entityId)
          }
        }

        if hasRestoreError {
          Text(L10n.tr("common.saveError"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.debt)
        }

        Text(LedgerDateLabels.timeLabel(for: entry.createdAt))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func sentenceText(parts: [ActivityTextPart]) -> Text {
    var combined = Text("")
    for part in parts {
      let segment =
        part.bold
        ? Text(part.text).fontWeight(.heavy)
        : Text(part.text)
      combined = Text("\(combined)\(segment)")
    }
    return combined
  }
}

private struct ChangeChipsView: View {
  let chips: [ActivityChangeChip]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(chips) { chip in
        HStack(spacing: 4) {
          if chips.count > 1 {
            Text(chip.field)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
          }
          Text(chip.before)
            .strikethrough()
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
              Tokens.bg,
              in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )

          Text("→")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .accessibilityHidden(true)

          Text(chip.after)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
              Tokens.phraseAmount,
              in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Activity Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    let model = ActivityModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      activityRepository: FakeActivityRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    ActivityView(model: model, onBack: {})
  }

  #Preview("Activity Empty") {
    let world = FakeWorld(preset: .empty)
    let model = ActivityModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      activityRepository: FakeActivityRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    ActivityView(model: model, onBack: {})
  }

  #Preview("Activity Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(60), hasSnapshot: false)
    )
    let model = ActivityModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      activityRepository: FakeActivityRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    ActivityView(model: model, onBack: {})
  }

  #Preview("Activity Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    let model = ActivityModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      activityRepository: FakeActivityRepository(world: world),
      transactionsRepository: FakeTransactionsRepository(world: world)
    )
    ActivityView(model: model, onBack: {})
  }
#endif
