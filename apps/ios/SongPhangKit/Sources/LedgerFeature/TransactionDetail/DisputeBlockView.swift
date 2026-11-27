import DesignSystem
import Domain
import SwiftUI

struct DisputeBlockView: View {
  let dispute: LedgerTransaction.TransactionDispute?
  let role: Role
  let verified: Bool
  let deleted: Bool
  let isPending: Bool
  let onOpenDispute: (String) async -> Bool
  let onResolveDispute: () -> Void

  @State private var isDisputeSheetOpen = false
  @State private var disputeReason = ""
  @State private var submissionError: String? = nil

  var body: some View {
    if let dispute {
      VStack(alignment: .leading, spacing: 12) {
        Text(L10n.t("transactionView.disputedBy", ["name": dispute.openedByName]))
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.onAccent)

        Text(dispute.reason)
          .font(Typography.body)
          .foregroundStyle(Tokens.onAccent)

        if verified && (dispute.mine || role == .owner) {
          Button {
            onResolveDispute()
          } label: {
            Text(L10n.tr("transactionView.resolveDispute"))
              .font(Typography.bodyBold)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(Tokens.surface)
              .foregroundStyle(Tokens.ink)
              .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
          }
          .disabled(isPending)
        }
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.coral)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    } else if !deleted && verified {
      Button {
        disputeReason = ""
        submissionError = nil
        isDisputeSheetOpen = true
      } label: {
        Text(L10n.tr("transactionView.openDispute"))
          .font(Typography.bodyBold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Tokens.surface)
          .foregroundStyle(Tokens.ink)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      .disabled(isPending)
      .sheet(isPresented: $isDisputeSheetOpen) {
        NavigationStack {
          ScrollView {
            VStack(alignment: .leading, spacing: 16) {
              SPTextField(
                label: L10n.tr("transactionView.disputeReasonLabel"),
                text: $disputeReason,
                error: submissionError,
                maxLength: 500
              )

              HStack(spacing: 12) {
                SPButton(
                  L10n.tr("transactionView.disputeCancel"),
                  variant: .surface,
                  isFullWidth: true
                ) {
                  isDisputeSheetOpen = false
                }

                let trimmed = disputeReason.trimmingCharacters(in: .whitespacesAndNewlines)
                SPButton(
                  L10n.tr("transactionView.send"),
                  variant: .primary,
                  isFullWidth: true,
                  isDisabled: trimmed.isEmpty || isPending,
                  isPending: isPending
                ) {
                  Task {
                    submissionError = nil
                    if await onOpenDispute(trimmed) {
                      disputeReason = ""
                      submissionError = nil
                      isDisputeSheetOpen = false
                    } else {
                      submissionError = L10n.tr("common.saveError")
                    }
                  }
                }
              }
            }
            .padding(20)
          }
          .background(Tokens.bg.ignoresSafeArea())
          .navigationTitle(L10n.tr("transactionView.disputeTitle"))
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.medium, .large])
          .onChange(of: disputeReason) { _, _ in
            if submissionError != nil {
              submissionError = nil
            }
          }
        }
      }
    }
  }
}
