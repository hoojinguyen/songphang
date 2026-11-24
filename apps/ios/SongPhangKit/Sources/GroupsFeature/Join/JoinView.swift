import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct JoinView: View {
  @Bindable private var model: JoinModel
  private let isEmailVerified: Bool
  private let onBackToGroups: () -> Void

  public init(
    model: JoinModel,
    isEmailVerified: Bool = true,
    onBackToGroups: @escaping () -> Void
  ) {
    self.model = model
    self.isEmailVerified = isEmailVerified
    self.onBackToGroups = onBackToGroups
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        switch model.preview {
        case .loading:
          LoadingSkeleton(rowCount: 3, rowHeight: 110)

        case .failed(let error):
          if Self.isInvalidInviteError(error) {
            VStack(spacing: 20) {
              Text(L10n.tr("join.invalidTitle"))
                .font(Typography.pageTitle)
                .foregroundStyle(Tokens.ink)
                .multilineTextAlignment(.center)
              Text(L10n.tr("join.invalidHint"))
                .font(Typography.body)
                .foregroundStyle(Tokens.ink)
                .multilineTextAlignment(.center)
              SPButton(
                L10n.tr("common.backToGroups"),
                variant: .primary,
                isFullWidth: true,
                action: onBackToGroups
              )
            }
            .padding(.vertical, 60)
          } else {
            LoadError {
              Task { await model.load() }
            }
          }

        case .loaded(let preview):
          loadedContent(preview)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 28)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task {
      await model.load()
    }
  }

  private static func isInvalidInviteError(_ error: AppError) -> Bool {
    guard case .api(let code, _) = error else { return false }
    return code == "INVITE_INVALID"
  }

  @ViewBuilder
  private func loadedContent(_ preview: InvitePreview) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.t("join.invitedBy", ["name": preview.ownerName]))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.muted)

      Text(preview.groupName)
        .font(Typography.pageTitle)
        .foregroundStyle(Tokens.ink)

      Text(
        L10n.t(
          "join.summary",
          [
            "members": String(preview.memberCount),
            "count": String(preview.transactionCount),
          ]
        )
      )
      .font(Typography.subheadline)
      .foregroundStyle(Tokens.muted)
    }

    Text(L10n.tr("join.question"))
      .font(Typography.bodyBold)
      .foregroundStyle(Tokens.ink)

    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(preview.members) { member in
        claimCell(for: member)
      }
    }

    if model.isNewMember {
      SPTextField(
        label: L10n.tr("join.newMemberLabel"),
        text: $model.newMemberName,
        maxLength: 50
      )
    } else {
      Button {
        model.chooseNewMember()
      } label: {
        Text(L10n.tr("join.newMember"))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 60)
          .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
              .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
              .foregroundStyle(Tokens.muted)
          )
      }
      .buttonStyle(.plain)
    }

    if let selected = model.selectedMember {
      balanceHint(for: selected)
    }

    if let error = model.submitError {
      let message =
        if case .api("MEMBER_ALREADY_CLAIMED", _) = error {
          L10n.tr("join.claimedMeanwhile")
        } else {
          L10n.tr("common.saveError")
        }
      Text(message)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
    }

    if isEmailVerified {
      SPButton(
        L10n.t("join.submit", ["name": model.chosenName]),
        variant: .accent,
        size: .lg,
        isFullWidth: true,
        isDisabled: !model.canSubmit,
        isPending: model.isSubmitting
      ) {
        Task { await model.submit() }
      }
    } else {
      SPCard(tone: .accent, padding: 20) {
        Text(L10n.tr("verify.banner"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }
    }
  }

  private func claimCell(for member: InvitePreview.PreviewMember) -> some View {
    let isSelected = !model.isNewMember && model.selectedMemberId == member.id
    let subtitle =
      member.claimed
      ? L10n.tr("join.claimed")
      : JoinModel.normalizeName(member.name) == JoinModel.normalizeName(model.accountName)
        ? L10n.tr("join.sameName")
        : L10n.tr("join.unclaimed")

    return Button {
      model.selectExistingMember(member.id)
    } label: {
      VStack(spacing: 8) {
        MemberShapeView(
          shape: member.shape,
          color: member.color,
          name: member.name,
          size: 84
        )
        .opacity(member.claimed ? 0.55 : 1.0)

        Text(member.name)
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

        Text(subtitle)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
          .multilineTextAlignment(.center)
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .background(member.claimed ? Tokens.sunken : Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 36, style: .continuous)
          .stroke(isSelected ? Tokens.ink : Color.clear, lineWidth: 3)
      )
    }
    .buttonStyle(.plain)
    .disabled(member.claimed)
  }

  private func balanceHint(for member: InvitePreview.PreviewMember) -> some View {
    let bal = member.balance ?? .zero
    let text: String
    if bal.isNegative {
      text = L10n.t("join.owes", ["name": member.name, "amount": MoneyFormat.full(bal.magnitude)])
    } else if bal.isPositive {
      text = L10n.t(
        "join.isOwed", ["name": member.name, "amount": MoneyFormat.full(bal.magnitude)])
    } else {
      text = L10n.t("join.even", ["name": member.name])
    }

    return Text(text)
      .font(Typography.captionBold)
      .foregroundStyle(Tokens.ink)
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
  }
}

#if DEBUG
  #Preview("Loaded") {
    let world = FakeWorld(preset: .tripStep4)
    JoinView(
      model: JoinModel(
        token: TripScenario.invite.token,
        accountName: "Lan",
        repository: FakeInvitesRepository(world: world),
        onJoined: { _ in }
      ),
      onBackToGroups: {}
    )
  }

  #Preview("Invalid Link") {
    let world = FakeWorld(preset: .tripStep4)
    JoinView(
      model: JoinModel(
        token: "invalid-token",
        accountName: "Lan",
        repository: FakeInvitesRepository(world: world),
        onJoined: { _ in }
      ),
      onBackToGroups: {}
    )
  }

  #Preview("Loading") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(latency: .seconds(10))
    )
    JoinView(
      model: JoinModel(
        token: TripScenario.invite.token,
        accountName: "Lan",
        repository: FakeInvitesRepository(world: world),
        onJoined: { _ in }
      ),
      onBackToGroups: {}
    )
  }
#endif
