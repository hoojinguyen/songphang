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
          .foregroundStyle(Tokens.ink)

        if let note = approval.note, !note.isEmpty {
          Text(note)
            .font(Typography.body)
            .foregroundStyle(Tokens.ink)
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
          .foregroundStyle(Tokens.ink)

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
                .background(Tokens.surface.opacity(0.4))
                .foregroundStyle(Tokens.ink)
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
          VStack(alignment: .leading, spacing: 16) {
            SPTextField(
              label: L10n.tr("approval.rejectNoteLabel"),
              text: $rejectNote
            )

            Spacer()

            HStack(spacing: 12) {
              SPButton(
                L10n.tr("approval.rejectCancel"),
                variant: .surface,
                isFullWidth: true
              ) {
                isRejectSheetOpen = false
              }

              SPButton(
                L10n.tr("approval.reject"),
                variant: .surface,
                isFullWidth: true,
                isDisabled: isPending,
                isPending: isPending
              ) {
                let note = rejectNote.trimmingCharacters(in: .whitespacesAndNewlines)
                onReject(note.isEmpty ? nil : note)
                isRejectSheetOpen = false
              }
            }
          }
          .padding(20)
          .navigationTitle(L10n.tr("approval.rejectTitle"))
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.height(280)])
        }
      }
    }
  }
}
