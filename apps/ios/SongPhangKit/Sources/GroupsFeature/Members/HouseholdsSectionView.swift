import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct HouseholdsSectionView: View {
  @Bindable private var model: MembersModel
  private let households: [Household]
  private let members: [Member]
  private let canWrite: Bool

  @State private var isCreating = false
  @State private var editingHousehold: Household?
  @State private var ungroupTarget: Household?

  public init(
    model: MembersModel,
    households: [Household],
    members: [Member],
    canWrite: Bool
  ) {
    self.model = model
    self.households = households
    self.members = members
    self.canWrite = canWrite
  }

  private var activePeople: [Member] {
    members.filter { $0.active && $0.kind == .person }
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.tr("households.sectionTitle"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
        Spacer()
        if canWrite && activePeople.count >= 2 {
          Button {
            isCreating = true
          } label: {
            Text(L10n.tr("households.createAction"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 12)
              .frame(minHeight: 36)
              .background(Tokens.surface, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }

      Text(L10n.tr("households.sectionHint"))
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)

      if households.isEmpty {
        SPCard(tone: .surface, padding: 18) {
          Text(L10n.tr("households.empty"))
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.muted)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      } else {
        ForEach(households) { household in
          householdCard(household)
        }
      }
    }
    .sheet(isPresented: $isCreating) {
      HouseholdFormSheetView(
        members: activePeople,
        existingHouseholds: households,
        editing: nil,
        isPending: model.isPerformingAction,
        error: model.householdError,
        onSaveCreate: { name, repId, memberIds in
          let ok = await model.createHousehold(
            name: name,
            representativeMemberId: repId,
            memberIds: memberIds
          )
          if ok { isCreating = false }
        },
        onSaveUpdate: { _, _ in },
        onDismiss: { isCreating = false }
      )
    }
    .sheet(item: $editingHousehold) { household in
      HouseholdFormSheetView(
        members: activePeople,
        existingHouseholds: households,
        editing: household,
        isPending: model.isPerformingAction,
        error: model.householdError,
        onSaveCreate: { _, _, _ in },
        onSaveUpdate: { id, input in
          let ok = await model.updateHousehold(id: id, input: input)
          if ok { editingHousehold = nil }
        },
        onDismiss: { editingHousehold = nil }
      )
    }
    .confirmationDialog(
      L10n.tr("households.ungroupAction"),
      isPresented: Binding(
        get: { ungroupTarget != nil },
        set: { if !$0 { ungroupTarget = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let target = ungroupTarget {
        Button(L10n.tr("households.ungroupAction"), role: .destructive) {
          ungroupTarget = nil
          Task { await model.deleteHousehold(id: target.id) }
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        ungroupTarget = nil
      }
    } message: {
      Text(L10n.tr("households.ungroupConfirm"))
    }
  }

  private func householdCard(_ household: Household) -> some View {
    let householdMembers = household.memberIds.compactMap { id in
      members.first(where: { $0.id == id })
    }
    let repName =
      members.first(where: { $0.id == household.representativeMemberId })?.name ?? ""

    return SPCard(tone: .surface, padding: 16) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
          Text(household.name)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
          Spacer()
          if canWrite {
            Button(L10n.tr("households.editAction")) {
              editingHousehold = household
            }
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background(Tokens.sunken, in: Capsule())
            .buttonStyle(.plain)

            Button {
              ungroupTarget = household
            } label: {
              Image(systemName: "trash")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Tokens.muted)
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.tr("households.ungroupAction"))
          }
        }

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(householdMembers) { member in
              HStack(spacing: 6) {
                MemberShapeView(
                  shape: member.shape,
                  color: member.color,
                  name: member.name,
                  size: 20,
                  showInitial: false
                )
                Text(member.name)
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.ink)
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(Tokens.sunken, in: Capsule())
            }
          }
        }

        if !repName.isEmpty {
          Text(L10n.t("households.representativeBadge", ["name": repName]))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Tokens.accent, in: Capsule())
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Households Empty") {
    let world = FakeWorld(preset: .tripStep4)
    let model = MembersModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      invitesRepository: FakeInvitesRepository(world: world),
      householdsRepository: FakeHouseholdsRepository(world: world)
    )
    ScrollView {
      HouseholdsSectionView(
        model: model,
        households: [],
        members: TripScenario.members,
        canWrite: true
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }

  #Preview("Households Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    let model = MembersModel(
      groupId: TripScenario.groupId,
      groupsRepository: FakeGroupsRepository(world: world),
      membersRepository: FakeMembersRepository(world: world),
      balancesRepository: FakeBalancesRepository(world: world),
      invitesRepository: FakeInvitesRepository(world: world),
      householdsRepository: FakeHouseholdsRepository(world: world)
    )
    let sample = Household(
      id: Household.ID("hh-1"),
      name: "Nhà Minh & Lan",
      representativeMemberId: TripScenario.minhId,
      memberIds: [TripScenario.minhId, TripScenario.lanId]
    )
    ScrollView {
      HouseholdsSectionView(
        model: model,
        households: [sample],
        members: TripScenario.members,
        canWrite: true
      )
      .padding(20)
    }
    .background(Tokens.bg)
  }
#endif
