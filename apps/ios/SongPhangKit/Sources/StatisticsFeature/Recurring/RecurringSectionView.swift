import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct RecurringSectionView: View {
  @Bindable private var model: RecurringExpensesModel
  private let members: [Member]
  private let canWrite: Bool
  private let onCompleteDue: (RecurringExpense) -> Void

  @State private var isCreating = false
  @State private var editingItem: RecurringExpense?
  @State private var deleteTarget: RecurringExpense?

  public init(
    model: RecurringExpensesModel,
    members: [Member],
    canWrite: Bool,
    onCompleteDue: @escaping (RecurringExpense) -> Void
  ) {
    self.model = model
    self.members = members
    self.canWrite = canWrite
    self.onCompleteDue = onCompleteDue
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.tr("recurring.sectionTitle"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
        Spacer()
        if canWrite {
          Button {
            isCreating = true
          } label: {
            Text(L10n.tr("recurring.createAction"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(Tokens.surface, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }

      if let err = model.mutationError {
        Text(
          err == .recurringMemberInactive
            ? L10n.tr("recurring.pausedMemberInvalid")
            : L10n.tr("common.saveError")
        )
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.coral)
      }

      switch model.state {
      case .loading:
        LoadingSkeleton(rowCount: 2, rowHeight: 84)
      case .failed:
        LoadError {
          Task { await model.load() }
        }
      case .loaded(let items):
        if items.isEmpty {
          SPCard(tone: .surface, padding: 20) {
            Text(L10n.tr("recurring.empty"))
              .font(Typography.subheadline)
              .foregroundStyle(Tokens.muted)
              .frame(maxWidth: .infinity, alignment: .center)
          }
        } else {
          ForEach(items) { item in
            recurringCard(item)
          }
        }
      }
    }
    .sheet(isPresented: $isCreating) {
      RecurringFormSheetView(
        members: members,
        editing: nil,
        isPending: model.isMutating,
        error: model.mutationError,
        onSaveCreate: { input in
          let ok = await model.create(input)
          if ok { isCreating = false }
        },
        onSaveUpdate: { _, _ in },
        onDismiss: { isCreating = false }
      )
    }
    .sheet(item: $editingItem) { item in
      RecurringFormSheetView(
        members: members,
        editing: item,
        isPending: model.isMutating,
        error: model.mutationError,
        onSaveCreate: { _ in },
        onSaveUpdate: { id, input in
          let ok = await model.update(id: id, input: input)
          if ok { editingItem = nil }
        },
        onDismiss: { editingItem = nil }
      )
    }
    .confirmationDialog(
      L10n.tr("recurring.deleteAction"),
      isPresented: Binding(
        get: { deleteTarget != nil },
        set: { if !$0 { deleteTarget = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let target = deleteTarget {
        Button(L10n.tr("recurring.deleteAction"), role: .destructive) {
          deleteTarget = nil
          Task { await model.delete(target) }
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        deleteTarget = nil
      }
    }
  }

  private func recurringCard(_ item: RecurringExpense) -> some View {
    SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 8) {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.description)
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)

            HStack(spacing: 6) {
              Text(frequencyLabel(item.frequency))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.muted)
              Text("·")
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.muted)
              Text(
                item.mode == .fixed
                  ? L10n.tr("recurring.modeFixed")
                  : L10n.tr("recurring.modeVariable")
              )
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
            }
          }

          Spacer()

          if let amount = item.amount {
            MoneyText(
              amount,
              style: .full,
              font: Typography.subheadlineBold,
              color: Tokens.ink
            )
          }

          if canWrite {
            Menu {
              Button(L10n.tr("recurring.editTitle")) {
                editingItem = item
              }
              Button(
                item.active ? L10n.tr("recurring.pause") : L10n.tr("recurring.resume")
              ) {
                Task { await model.toggleActive(item) }
              }
              Button(L10n.tr("recurring.deleteAction"), role: .destructive) {
                deleteTarget = item
              }
            } label: {
              Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Tokens.ink)
                .frame(width: 32, height: 32)
                .background(Tokens.sunken, in: Circle())
            }
          }
        }

        if !item.active {
          let bannerText =
            item.pauseReason == .memberInvalid
            ? L10n.tr("recurring.pausedMemberInvalid")
            : L10n.tr("recurring.pausedBadge")
          Text(bannerText)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
              item.pauseReason == .memberInvalid ? Tokens.debtSoft : Tokens.sunken,
              in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }

        if let pendingDue = item.pendingDueDate {
          Text(L10n.t("recurring.pendingDueTemplate", ["date": Self.formatVNDate(pendingDue)]))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.onAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Tokens.accent, in: Capsule())

          if canWrite {
            HStack(spacing: 8) {
              SPButton(L10n.tr("recurring.enterAmount"), variant: .primary, size: .md) {
                onCompleteDue(item)
              }
              SPButton(L10n.tr("recurring.skipThisPeriod"), variant: .surface, size: .md) {
                Task { await model.skip(item) }
              }
            }
          }
        } else {
          HStack(spacing: 8) {
            Text(L10n.t("recurring.nextDueTemplate", ["date": Self.formatVNDate(item.nextDueDate)]))
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            Spacer()
            if canWrite && item.active {
              Button {
                Task { await model.skip(item) }
              } label: {
                Text(L10n.tr("recurring.skipNextPeriod"))
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
                  .padding(.horizontal, 10)
                  .frame(minHeight: 32)
                  .background(Tokens.sunken, in: Capsule())
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }

  private func frequencyLabel(_ frequency: RecurringFrequency) -> String {
    switch frequency {
    case .weekly: return L10n.tr("recurring.freqWeekly")
    case .monthly: return L10n.tr("recurring.freqMonthly")
    case .quarterly: return L10n.tr("recurring.freqQuarterly")
    case .yearly: return L10n.tr("recurring.freqYearly")
    case .unknown(let raw): return raw
    }
  }

  private static func formatVNDate(_ iso: String) -> String {
    let parts = iso.split(separator: "-")
    guard parts.count == 3 else { return iso }
    return "\(parts[2])/\(parts[1])/\(parts[0])"
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    let model = RecurringExpensesModel(
      groupId: TripScenario.groupId,
      repository: FakeRecurringExpensesRepository(world: world)
    )
    ScrollView {
      RecurringSectionView(
        model: model,
        members: TripScenario.members,
        canWrite: true,
        onCompleteDue: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
    .task { await model.load() }
  }

  #Preview("Empty") {
    let world = FakeWorld(preset: .tripStep0)
    let model = RecurringExpensesModel(
      groupId: TripScenario.groupId,
      repository: FakeRecurringExpensesRepository(world: world)
    )
    ScrollView {
      RecurringSectionView(
        model: model,
        members: [],
        canWrite: true,
        onCompleteDue: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
    .task { await model.load() }
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10), hasSnapshot: false)
    )
    let model = RecurringExpensesModel(
      groupId: TripScenario.groupId,
      repository: FakeRecurringExpensesRepository(world: world)
    )
    ScrollView {
      RecurringSectionView(
        model: model,
        members: TripScenario.members,
        canWrite: true,
        onCompleteDue: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
    .task { await model.load() }
  }

  #Preview("Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline, hasSnapshot: false)
    )
    let model = RecurringExpensesModel(
      groupId: TripScenario.groupId,
      repository: FakeRecurringExpensesRepository(world: world)
    )
    ScrollView {
      RecurringSectionView(
        model: model,
        members: TripScenario.members,
        canWrite: true,
        onCompleteDue: { _ in }
      )
      .padding(20)
    }
    .background(Tokens.bg)
    .task { await model.load() }
  }
#endif
