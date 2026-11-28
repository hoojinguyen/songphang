import Foundation
public import SwiftUI
import UIKit

public enum SheetSize: Sendable, Hashable {
  case fitted
  case half
  case form
}

private struct SPSheetContentHeightKey: PreferenceKey {
  static let defaultValue: CGFloat? = nil

  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    if let next = nextValue() {
      value = max(value ?? 0, next)
    }
  }
}

struct SPSheetDismissAction: Equatable {
  let id: UUID
  let perform: () -> Void

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension EnvironmentValues {
  @Entry var spSheetDismissAction: SPSheetDismissAction? = nil
}

public struct SheetCloseButton: View {
  @Environment(\.spSheetDismissAction) private var dismissAction
  private let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button {
      if let dismissAction {
        dismissAction.perform()
      } else {
        action()
      }
    } label: {
      Image(systemName: "xmark")
        .spIconFont(size: 15, weight: .bold, relativeTo: .subheadline)
        .foregroundStyle(Tokens.ink)
        .frame(minWidth: 36, minHeight: 36)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(L10n.tr("ios.common.close"))
  }
}

public struct SheetCancelButton: View {
  @Environment(\.spSheetDismissAction) private var dismissAction
  private let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button {
      if let dismissAction {
        dismissAction.perform()
      } else {
        action()
      }
    } label: {
      Text(L10n.tr("common.cancel"))
        .font(Typography.body)
        .foregroundStyle(Tokens.ink)
    }
  }
}

private struct SPFittedMeasuredModifier: ViewModifier {
  let chromeAllowance: CGFloat

  func body(content: Content) -> some View {
    content.onGeometryChange(for: CGFloat.self) { proxy in
      ceil(proxy.size.height)
    } action: { _ in
    }
    .background(
      GeometryReader { proxy in
        Color.clear.preference(
          key: SPSheetContentHeightKey.self,
          value: ceil(proxy.size.height + chromeAllowance)
        )
      }
    )
  }
}

private struct SPSheetModifier: ViewModifier {
  let size: SheetSize
  let expandable: Bool
  let embedsNavigationStack: Bool

  // Start at medium-equivalent height until first intrinsic geometry pass completes.
  @State private var measuredHeight: CGFloat = 320

  private var maxSheetHeight: CGFloat {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    let screenHeight = scene?.screen.bounds.height ?? 852
    return max(360, floor(screenHeight * 0.86))
  }

  private var detents: Set<PresentationDetent> {
    switch size {
    case .fitted:
      let target = max(180, measuredHeight)
      if target >= maxSheetHeight {
        return [.large]
      }
      if expandable {
        return [.height(target), .large]
      }
      return [.height(target)]
    case .half:
      return [.medium, .large]
    case .form:
      return [.large]
    }
  }

  func body(content: Content) -> some View {
    Group {
      if size == .fitted && !embedsNavigationStack {
        // Measure intrinsic height inside fixedSize(vertical: true) so measured height
        // never depends on the sheet detent height (cannot oscillate), falling back to
        // ScrollView when Dynamic Type exceeds the sheet cap.
        ViewThatFits(in: .vertical) {
          measuredPlainContent(content)
          ScrollView {
            measuredPlainContent(content)
          }
        }
      } else {
        content
      }
    }
    .onPreferenceChange(SPSheetContentHeightKey.self) { next in
      guard let next, next > 0 else { return }
      updateMeasuredHeight(next)
    }
    .presentationDetents(detents)
    .presentationDragIndicator(.visible)
  }

  private func measuredPlainContent(_ content: Content) -> some View {
    content
      .fixedSize(horizontal: false, vertical: true)
      .onGeometryChange(for: CGFloat.self) { proxy in
        ceil(proxy.size.height + 28)
      } action: { next in
        updateMeasuredHeight(next)
      }
  }

  private func updateMeasuredHeight(_ next: CGFloat) {
    guard next > 0, abs(next - measuredHeight) >= 2 else { return }
    measuredHeight = next
  }
}

private struct SPDiscardGuardModifier: ViewModifier {
  let isDirty: Bool
  let isPending: Bool
  let onDiscard: () -> Void
  @State private var cleanId = UUID()
  @State private var dirtyId = UUID()
  @State private var lockedId = UUID()
  @State private var isShowingConfirmation = false

  func body(content: Content) -> some View {
    let activeId = isPending ? lockedId : (isDirty ? dirtyId : cleanId)
    content
      .interactiveDismissDisabled(isDirty || isPending)
      .environment(
        \.spSheetDismissAction,
        SPSheetDismissAction(id: activeId) {
          guard !isPending else { return }
          if isDirty {
            isShowingConfirmation = true
          } else {
            onDiscard()
          }
        }
      )
      .confirmationDialog(
        L10n.tr("ios.sheet.discardTitle"),
        isPresented: $isShowingConfirmation,
        titleVisibility: .visible
      ) {
        Button(L10n.tr("ios.sheet.discardConfirm"), role: .destructive) {
          onDiscard()
        }
        Button(L10n.tr("common.cancel"), role: .cancel) {}
      }
  }
}

extension View {
  public func spSheet(
    _ size: SheetSize,
    expandable: Bool = false,
    embedsNavigationStack: Bool = false
  ) -> some View {
    modifier(
      SPSheetModifier(
        size: size,
        expandable: expandable,
        embedsNavigationStack: embedsNavigationStack
      )
    )
  }

  public func spFittedSheetContent(chromeAllowance: CGFloat = 76) -> some View {
    modifier(SPFittedMeasuredModifier(chromeAllowance: chromeAllowance))
  }

  public func discardGuard(
    isDirty: Bool,
    isPending: Bool = false,
    onDiscard: @escaping () -> Void
  ) -> some View {
    modifier(SPDiscardGuardModifier(isDirty: isDirty, isPending: isPending, onDiscard: onDiscard))
  }
}

#if DEBUG
  #Preview("Fitted Short Sheet") {
    Color.clear
      .sheet(isPresented: .constant(true)) {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            SheetCloseButton {}
            Spacer()
          }
          Text("Nhân bản nhóm?")
            .font(Typography.sectionTitle)
          Text(" Giữ danh sách 4 thành viên và thông tin nhận tiền, không chép các khoản chi cũ.")
            .font(Typography.subheadline)
            .foregroundStyle(Tokens.muted)
          SPButton("Nhân bản", variant: .accent, isFullWidth: true) {}
        }
        .padding(20)
        .spSheet(.fitted)
      }
  }

  #Preview("Fitted Long Content AX5") {
    Color.clear
      .sheet(isPresented: .constant(true)) {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            SheetCancelButton {}
            Spacer()
          }
          Text("Xoá nhóm này?")
            .font(Typography.sectionTitle)
          Text(
            "Mọi khoản chi, số dư, đợt đã chốt và chứng từ chuyển khoản sẽ bị xoá vĩnh viễn cho tất cả thành viên."
          )
          .font(Typography.body)
          .foregroundStyle(Tokens.muted)
          SPButton("Xoá nhóm", variant: .primary, isFullWidth: true) {}
        }
        .padding(20)
        .spSheet(.fitted)
        .discardGuard(isDirty: true, onDiscard: {})
        .environment(\.dynamicTypeSize, .accessibility5)
      }
  }
#endif
