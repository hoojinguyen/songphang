import DesignSystem
import Domain
import SwiftUI

struct CommentThreadView: View {
  let comments: [Comment]
  let role: Role
  let verified: Bool
  let isFetching: Bool
  let hasNextPage: Bool
  let onLoadMore: () -> Void
  let onDeleteComment: (Comment.ID) -> Void

  private func formattedDate(for iso: String) -> String {
    let day = LedgerDateLabels.dayLabel(for: iso)
    let time = LedgerDateLabels.timeLabel(for: iso)
    return time.isEmpty ? day : "\(day) · \(time)"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if comments.isEmpty {
        if isFetching {
          ShapeLoader()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
          Text(L10n.tr("transactionView.noComments"))
            .font(Typography.body)
            .foregroundStyle(Tokens.muted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
        }
      } else {
        ForEach(comments) { comment in
          let canDelete = verified && (comment.mine || role == .owner)
          VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
              Text(comment.authorName)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)

              Spacer()

              Text(formattedDate(for: comment.createdAt))
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }

            Text(comment.body)
              .font(Typography.body)
              .foregroundStyle(Tokens.ink)
              .frame(maxWidth: .infinity, alignment: .leading)

            if canDelete {
              Button {
                onDeleteComment(comment.id)
              } label: {
                Text(L10n.tr("transactionView.deleteComment"))
                  .font(Typography.captionBold)
                  .foregroundStyle(Tokens.muted)
              }
              .padding(.top, 4)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Tokens.surface)
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }

        if hasNextPage {
          SPButton(
            L10n.tr("transactionView.loadMoreComments"),
            variant: .surface,
            isFullWidth: true,
            isDisabled: isFetching
          ) {
            onLoadMore()
          }
        }
      }
    }
  }
}
