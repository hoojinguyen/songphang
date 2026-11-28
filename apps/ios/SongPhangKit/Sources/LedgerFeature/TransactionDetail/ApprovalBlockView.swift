import DesignSystem
import Domain
import SwiftUI

struct ApprovalBlockView: View {
  let approval: LedgerTransaction.TransactionApproval
  let ownerName: String
  let role: Role
  let verified: Bool
  let deleted: Bool
  let isPending: Bool
  let onApprove: () -> Void
  let onReject: (String?) -> Void

  @State private var isRejectSheetOpen = false
  @State private var rejectNote = ""

  var body: some View {
    if deleted || approval.status == .none || approval.status == .approved {
      EmptyView()
    } else if approval.status == .rejected {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.t("approval.rejectedTitle", ["owner": ownerName]))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.onAccent)

        if let note = approval.note, !note.isEmpty {
          Text(note)
            .font(Typography.body)
            .foregroundStyle(Tokens.onAccent)
        }
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.coral)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    } else if approval.status == .pending {
      VStack(alignment: .leading, spacing: 14) {
        Text(L10n.t("approval.pendingBanner", ["owner": ownerName]))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.onAccent)

        if role == .owner && verified {
          HStack(spacing: 10) {
            Button {
              onApprove()
            } label: {
              Text(L10n.tr("approval.approve"))
                .font(Typography.bodyBold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Tokens.surface)
                .foregroundStyle(Tokens.ink)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(isPending)

            Button {
              rejectNote = ""
              isRejectSheetOpen = true
            } label: {
              Text(L10n.tr("approval.reject"))
                .font(Typography.bodyBold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Tokens.onAccent.opacity(0.14))
                .foregroundStyle(Tokens.onAccent)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(isPending)
          }
        }
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.accent)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .sheet(isPresented: $isRejectSheetOpen) {
        NavigationStack {
          ScrollView {
            VStack(alignment: .leading, spacing: 16) {
              SPTextField(
                label: L10n.tr("approval.rejectNoteLabel"),
                text: $rejectNote,
                maxLength: 300
              )

              SPButton(
                L10n.tr("approval.reject"),
                variant: .primary,
                size: .lg,
                isFullWidth: true,
                isDisabled: isPending,
                isPending: isPending
              ) {
                let note = rejectNote.trimmingCharacters(in: .whitespacesAndNewlines)
                onReject(note.isEmpty ? nil : note)
                rejectNote = ""
                isRejectSheetOpen = false
              }
            }
            .padding(20)
            .spFittedSheetContent()
          }
          .background(Tokens.bg.ignoresSafeArea())
          .navigationTitle(L10n.tr("approval.rejectTitle"))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              SheetCancelButton {
                rejectNote = ""
                isRejectSheetOpen = false
              }
              .disabled(isPending)
            }
          }
        }
        .spSheet(.fitted, embedsNavigationStack: true)
        .discardGuard(
          isDirty: !rejectNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPending,
          onDiscard: {
            rejectNote = ""
            isRejectSheetOpen = false
          }
        )
      }
    }
  }
}
