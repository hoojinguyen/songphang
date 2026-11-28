public import Domain
public import SwiftUI

public struct MemberPicker: View {
  public enum Mode: Sendable, Hashable {
    case single
    case multiple
  }

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding private var selection: Set<Member.ID>

  private let title: String
  private let members: [Member]
  private let mode: Mode
  private let currentMemberId: Member.ID?
  private let allowsEmptySelection: Bool
  private let isDisabled: Bool

  public init(
    title: String,
    members: [Member],
    selection: Binding<Set<Member.ID>>,
    mode: Mode = .multiple,
    currentMemberId: Member.ID? = nil,
    allowsEmptySelection: Bool = false,
    isDisabled: Bool = false
  ) {
    self.title = title
    self.members = members
    self._selection = selection
    self.mode = mode
    self.currentMemberId = currentMemberId
    self.allowsEmptySelection = allowsEmptySelection
    self.isDisabled = isDisabled
  }

  public init(
    title: String,
    members: [Member],
    selectedId: Binding<Member.ID?>,
    currentMemberId: Member.ID? = nil,
    allowsEmptySelection: Bool = false,
    isDisabled: Bool = false
  ) {
    self.init(
      title: title,
      members: members,
      selection: Binding(
        get: {
          if let id = selectedId.wrappedValue {
            return [id]
          }
          return []
        },
        set: { next in
          selectedId.wrappedValue = next.first
        }
      ),
      mode: .single,
      currentMemberId: currentMemberId,
      allowsEmptySelection: allowsEmptySelection,
      isDisabled: isDisabled
    )
  }

  public init(
    title: String,
    members: [Member],
    selectedId: Binding<Member.ID>,
    currentMemberId: Member.ID? = nil,
    isDisabled: Bool = false
  ) {
    self.init(
      title: title,
      members: members,
      selection: Binding(
        get: { [selectedId.wrappedValue] },
        set: { next in
          if let first = next.first {
            selectedId.wrappedValue = first
          }
        }
      ),
      mode: .single,
      currentMemberId: currentMemberId,
      allowsEmptySelection: false,
      isDisabled: isDisabled
    )
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if !title.isEmpty {
        Text(title)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }

      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: 8) {
          ForEach(members) { member in
            accessibilityRow(for: member)
          }
        }
      } else {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
          ForEach(members) { member in
            gridOption(for: member)
          }
        }
      }
    }
    .spAnimation(Motion.quick, value: selection)
    .spFeedback(.selection, trigger: selection)
  }

  private func displayName(for member: Member) -> String {
    let isCurrent = member.isMe || (currentMemberId != nil && member.id == currentMemberId)
    return isCurrent ? L10n.tr("common.you") : member.name
  }

  private func accessibilityText(for member: Member, isSelected: Bool) -> String {
    let label = displayName(for: member)
    return isSelected ? L10n.t("ios.memberPicker.selected", ["name": label]) : label
  }

  private func toggle(_ id: Member.ID) {
    switch mode {
    case .single:
      if selection.contains(id) {
        if allowsEmptySelection {
          selection.removeAll()
        }
      } else {
        selection = [id]
      }
    case .multiple:
      if selection.contains(id) {
        if allowsEmptySelection || selection.count > 1 {
          selection.remove(id)
        }
      } else {
        selection.insert(id)
      }
    }
  }

  private func gridOption(for member: Member) -> some View {
    let isSelected = selection.contains(member.id)
    let label = displayName(for: member)
    return Button {
      toggle(member.id)
    } label: {
      VStack(spacing: 6) {
        MemberShapeView(member: member, size: 44)
        Text(label)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity, minHeight: 84)
      .background(isSelected ? Tokens.surface : Tokens.sunken)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .strokeBorder(isSelected ? Tokens.ink : Color.clear, lineWidth: 2.5)
      )
      .opacity(isSelected ? 1.0 : 0.72)
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText(for: member, isSelected: isSelected))
    .accessibilityAddTraits(.isButton)
  }

  private func accessibilityRow(for member: Member) -> some View {
    let isSelected = selection.contains(member.id)
    let label = displayName(for: member)
    return Button {
      toggle(member.id)
    } label: {
      HStack(spacing: 12) {
        MemberShapeView(member: member, size: 44)
        Text(label)
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)
          .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .spIconFont(size: 22, weight: .bold, relativeTo: .title3)
          .foregroundStyle(isSelected ? Tokens.ink : Tokens.muted)
      }
      .padding(14)
      .frame(maxWidth: .infinity, minHeight: 60)
      .background(isSelected ? Tokens.surface : Tokens.sunken)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .strokeBorder(isSelected ? Tokens.ink : Color.clear, lineWidth: 2.5)
      )
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText(for: member, isSelected: isSelected))
    .accessibilityAddTraits(.isButton)
  }
}

#if DEBUG
  private enum MemberPickerPreviewSamples {
    static let fourMembers: [Member] = [
      Member(
        id: Member.ID("m1"), name: "Minh", position: 0, shape: .circle, color: .mint,
        isMe: true, claimed: true
      ),
      Member(
        id: Member.ID("m2"), name: "Lan", position: 1, shape: .diamond, color: .sky,
        isMe: false, claimed: true
      ),
      Member(
        id: Member.ID("m3"), name: "Hùng", position: 2, shape: .squircle, color: .coral,
        isMe: false, claimed: false
      ),
      Member(
        id: Member.ID("m4"), name: "Thu", position: 3, shape: .leaf, color: .lilac,
        isMe: false, claimed: false
      ),
    ]
  }

  #Preview("MemberPicker Default") {
    MemberPicker(
      title: "Ai trả?",
      members: MemberPickerPreviewSamples.fourMembers,
      selection: .constant([Member.ID("m1")]),
      mode: .single
    )
    .padding(20)
    .background(Tokens.bg)
  }

  #Preview("MemberPicker Many & Dark") {
    let extra = [
      Member(
        id: Member.ID("m5"), name: "Khánh", position: 4, shape: .circle, color: .coral,
        isMe: false, claimed: true
      ),
      Member(
        id: Member.ID("m6"), name: "Phúc", position: 5, shape: .diamond, color: .lilac,
        isMe: false, claimed: false
      ),
    ]
    MemberPicker(
      title: "Chia cho ai?",
      members: MemberPickerPreviewSamples.fourMembers + extra,
      selection: .constant([Member.ID("m1"), Member.ID("m2"), Member.ID("m5")]),
      mode: .multiple
    )
    .padding(20)
    .background(Tokens.bg)
    .preferredColorScheme(.dark)
  }

  #Preview("MemberPicker AX5") {
    MemberPicker(
      title: "Món này của ai?",
      members: MemberPickerPreviewSamples.fourMembers,
      selection: .constant([Member.ID("m1"), Member.ID("m3")]),
      mode: .multiple
    )
    .padding(20)
    .background(Tokens.bg)
    .environment(\.dynamicTypeSize, .accessibility5)
  }
#endif
