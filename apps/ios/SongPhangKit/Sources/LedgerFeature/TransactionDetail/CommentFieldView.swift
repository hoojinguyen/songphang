import DesignSystem
import SwiftUI

struct CommentFieldView: View {
  let verified: Bool
  let isPending: Bool
  let onSend: (String) -> Void

  @State private var text = ""

  var body: some View {
    if !verified {
      EmptyView()
    } else {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      let canSend = !trimmed.isEmpty && !isPending

      HStack(alignment: .center, spacing: 10) {
        TextField(
          L10n.tr("transactionView.commentPlaceholder"),
          text: $text,
          axis: .vertical
        )
        .textFieldStyle(.plain)
        .lineLimit(1...4)
        .font(Typography.body)
        .foregroundStyle(Tokens.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

        Button {
          guard canSend else { return }
          let bodyToSend = trimmed
          text = ""
          onSend(bodyToSend)
        } label: {
          Image(systemName: "arrow.up")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(canSend ? Tokens.surface : Tokens.muted)
            .frame(width: 40, height: 40)
            .background(canSend ? Tokens.ink : Tokens.surface)
            .clipShape(Circle())
        }
        .disabled(!canSend)
        .accessibilityLabel(L10n.tr("transactionView.send"))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(Tokens.bg)
    }
  }
}
