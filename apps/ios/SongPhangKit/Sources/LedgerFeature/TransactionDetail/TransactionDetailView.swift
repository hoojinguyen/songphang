import DesignSystem
public import Domain
public import SwiftUI

public struct TransactionDetailView: View {
  private let model: TransactionDetailModel
  private let verifyEmailBanner: AnyView?
  private let onBack: () -> Void
  private let onOpenEdit: (ExpenseGroup.ID, LedgerTransaction.ID) -> Void
  private let onRemoved: () -> Void

  public init(
    model: TransactionDetailModel,
    verifyEmailBanner: AnyView? = nil,
    onBack: @escaping () -> Void,
    onOpenEdit: @escaping (ExpenseGroup.ID, LedgerTransaction.ID) -> Void,
    onRemoved: @escaping () -> Void
  ) {
    self.model = model
    self.verifyEmailBanner = verifyEmailBanner
    self.onBack = onBack
    self.onOpenEdit = onOpenEdit
    self.onRemoved = onRemoved
  }

  public var body: some View {
    VStack(spacing: 0) {
      switch model.state {
      case .loading:
        SPScreenHeader(title: "", onBack: onBack)
        Spacer()
        ProgressView()
        Spacer()
      case .failed(let error):
        SPScreenHeader(title: "", onBack: onBack)
        Spacer()
        VStack(spacing: 12) {
          Text(
            error == .api(code: "NOT_FOUND", status: 404)
              ? L10n.tr("common.groupNotFound") : L10n.tr("common.loadError")
          )
          .font(Typography.bodyBold)
          .foregroundStyle(Tokens.ink)

          SPButton(L10n.tr("common.retry"), variant: .primary) {
            Task { await model.load() }
          }
        }
        .padding(20)
        Spacer()
      case .loaded(let data):
        let isVerified = data.currentUser?.emailVerified ?? true
        let canEdit = data.group.role != .viewer && isVerified && data.transaction.deletedAt == nil

        SPScreenHeader(
          title: data.transaction.description,
          subtitle: data.group.name,
          onBack: onBack
        ) {
          if canEdit {
            Button {
              onOpenEdit(data.group.id, data.transaction.id)
            } label: {
              Text(L10n.tr("transactionView.editLink"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Tokens.surface, in: Capsule())
            }
          }
        }

        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            if !isVerified, let verifyEmailBanner {
              verifyEmailBanner
            }

            TransactionSummaryView(
              transaction: data.transaction,
              members: data.members,
              categories: data.categories,
              loadAttachment: { id in
                try await model.loadAttachment(id: id)
              }
            )

            ApprovalBlockView(
              approval: data.transaction.approval,
              ownerName: data.group.ownerName,
              role: data.group.role,
              verified: isVerified,
              deleted: data.transaction.deletedAt != nil,
              isPending: model.isPerformingAction,
              onApprove: {
                Task { await model.approve() }
              },
              onReject: { note in
                Task { await model.reject(note: note) }
              }
            )

            DisputeBlockView(
              dispute: data.transaction.dispute,
              role: data.group.role,
              verified: isVerified,
              deleted: data.transaction.deletedAt != nil,
              isPending: model.isPerformingAction,
              onOpenDispute: { reason in
                await model.openDispute(reason: reason)
              },
              onResolveDispute: {
                Task { await model.resolveDispute() }
              }
            )

            CommentThreadView(
              comments: model.comments,
              role: data.group.role,
              verified: isVerified,
              isFetching: model.isFetchingComments,
              hasNextPage: model.commentsNextCursor != nil,
              onLoadMore: {
                Task { await model.loadComments() }
              },
              onDeleteComment: { id in
                Task { await model.deleteComment(id: id) }
              }
            )

            if model.actionError != nil {
              Text(L10n.tr("common.saveError"))
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .padding(.horizontal, 4)
            }

            if let successToast = model.successToast {
              Text(successToast)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.onAccent)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                  Tokens.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
        }

        CommentFieldView(
          verified: isVerified,
          isPending: model.isPerformingAction,
          onSend: { body in
            Task { _ = await model.addComment(body: body) }
          }
        )
      }
    }
    .background(Tokens.bg.ignoresSafeArea())
    .task {
      await model.load()
    }
    .task(id: model.transactionId) {
      await model.listenForEvents {
        onRemoved()
      }
    }
  }
}
