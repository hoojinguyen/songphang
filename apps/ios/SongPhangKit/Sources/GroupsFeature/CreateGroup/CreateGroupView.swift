import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct CreateGroupView: View {
  @Bindable private var model: CreateGroupModel
  private let creatorName: String
  private let onBack: () -> Void

  public init(
    model: CreateGroupModel,
    creatorName: String,
    onBack: @escaping () -> Void
  ) {
    self.model = model
    self.creatorName = creatorName
    self.onBack = onBack
  }

  private func appearanceAt(_ index: Int) -> (shape: MemberShape, color: MemberColor) {
    let pairs = MemberAppearancePalette.pairs
    return pairs[index % pairs.count]
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          SPScreenHeader(
            title: L10n.tr("newGroup.title"),
            onBack: onBack
          )

          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("newGroup.nameLabel"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            TextField("", text: $model.name)
              .font(Typography.pageTitle)
              .foregroundStyle(Tokens.ink)
              .padding(.horizontal, 20)
              .frame(minHeight: 72)
              .background(Tokens.surface)
              .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
              .onChange(of: model.name) { _, newValue in
                if newValue.count > 80 {
                  model.name = String(newValue.prefix(80))
                }
              }
              .accessibilityLabel(L10n.tr("newGroup.nameLabel"))
          }

          Text(L10n.tr("newGroup.membersTitle"))
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)

          HStack(spacing: 12) {
            MemberShapeView(
              shape: .circle,
              color: .mint,
              name: creatorName,
              size: 44
            )
            Text(creatorName)
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
            Spacer()
            Text(L10n.tr("newGroup.creatorTag"))
              .font(Typography.subheadline)
              .foregroundStyle(Tokens.muted)
          }

          ForEach(Array(model.addedMembers.enumerated()), id: \.element.id) { index, item in
            let pair = appearanceAt(index + 1)
            HStack(spacing: 12) {
              MemberShapeView(
                shape: pair.shape,
                color: pair.color,
                name: item.name,
                size: 44
              )
              Text(item.name)
                .font(Typography.bodyBold)
                .foregroundStyle(Tokens.ink)
              Spacer()
              Button {
                model.removeMember(at: index)
              } label: {
                Image(systemName: "xmark")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundStyle(Tokens.ink)
                  .frame(width: 44, height: 44)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(L10n.t("newGroup.removeMember", ["name": item.name]))
            }
            .id("member_\(item.id)")
          }

          let usedPairs = (0...model.addedMembers.count).map { appearanceAt($0) }
          NewMemberInputRow(
            appearance: MemberAppearancePalette.nextAppearance(
              usedPairs: usedPairs,
              position: model.addedMembers.count + 1
            ),
            label: L10n.tr("newGroup.newMemberLabel"),
            addLabel: L10n.tr("newGroup.add"),
            isDisabled: model.addedMembers.count >= 99 || model.isSubmitting
          ) { newName in
            model.addMember(newName)
          }
          .id("newMemberInputRow")

          Text(L10n.tr("newGroup.hint"))
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          if model.submitError != nil {
            Text(L10n.tr("common.saveError"))
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.debt)
              .id("validationErrorBanner")
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Tokens.bg.ignoresSafeArea())
      .safeAreaInset(edge: .bottom, spacing: 0) {
        submitBar
      }
      .navigationBarBackButtonHidden(true)
      .onChange(of: model.addedMembers.count) { oldCount, newCount in
        if newCount > oldCount {
          withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo("newMemberInputRow", anchor: .bottom)
          }
        }
      }
      .onChange(of: model.submitError != nil) { _, hasError in
        if hasError {
          withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo("validationErrorBanner", anchor: .bottom)
          }
        }
      }
    }
  }

  private var submitBar: some View {
    VStack(alignment: .leading, spacing: 8) {
      if model.submitError != nil {
        Text(L10n.tr("common.saveError"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)
      }

      let submitLabel =
        model.addedMembers.isEmpty
        ? L10n.tr("newGroup.submitOne")
        : L10n.t("newGroup.submitMany", ["count": String(model.addedMembers.count + 1)])

      SPButton(
        submitLabel,
        variant: .accent,
        size: .lg,
        isFullWidth: true,
        isDisabled: !model.canSubmit,
        isPending: model.isSubmitting
      ) {
        Task { await model.submit() }
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(Tokens.bg)
  }
}

#if DEBUG
  #Preview("Create Group") {
    let world = FakeWorld(preset: .tripStep4)
    CreateGroupView(
      model: CreateGroupModel(
        repository: FakeGroupsRepository(world: world),
        onCreated: { _ in }
      ),
      creatorName: "Minh",
      onBack: {}
    )
  }

  #Preview("Create Group Failed") {
    let world = FakeWorld(
      preset: .tripStep4,
      behavior: FakeBehavior(failure: .offline)
    )
    CreateGroupView(
      model: CreateGroupModel(
        repository: FakeGroupsRepository(world: world),
        onCreated: { _ in }
      ),
      creatorName: "Minh",
      onBack: {}
    )
  }
#endif
