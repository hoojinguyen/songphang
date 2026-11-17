public import SwiftUI

public struct SPTextField: View {
  public enum FieldKind: Sendable {
    case text
    case email
    case password
  }

  private let label: String
  @Binding private var text: String
  private let kind: FieldKind
  private let placeholder: String
  private let error: String?
  private let hint: String?
  private let maxLength: Int?
  private let onSubmit: (() -> Void)?
  private let submitLabel: SubmitLabel?
  private let externalFocus: FocusState<Bool>.Binding?
  @FocusState private var internalFocus: Bool

  private var focus: FocusState<Bool>.Binding { externalFocus ?? $internalFocus }

  public init(
    label: String,
    text: Binding<String>,
    kind: FieldKind = .text,
    placeholder: String = "",
    error: String? = nil,
    hint: String? = nil,
    maxLength: Int? = nil,
    onSubmit: (() -> Void)? = nil,
    submitLabel: SubmitLabel? = nil,
    focus: FocusState<Bool>.Binding? = nil
  ) {
    self.label = label
    self._text = text
    self.kind = kind
    self.placeholder = placeholder
    self.error = error
    self.hint = hint
    self.maxLength = maxLength
    self.onSubmit = onSubmit
    self.submitLabel = submitLabel
    self.externalFocus = focus
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)

      Group {
        switch kind {
        case .password:
          SecureField(placeholder, text: $text)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        case .email:
          TextField(placeholder, text: $text)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        case .text:
          TextField(placeholder, text: $text)
        }
      }
      .focused(focus)
      .submitLabel(submitLabel ?? (onSubmit == nil ? .done : .go))
      .onSubmit { onSubmit?() }
      .font(Typography.bodyBold)
      .foregroundStyle(Tokens.ink)
      .padding(.horizontal, 16)
      .frame(minHeight: 56)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .strokeBorder(Tokens.muted.opacity(0.35), lineWidth: 1.5)
      )
      .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
      .onTapGesture { focus.wrappedValue = true }
      .onChange(of: text) { _, newValue in
        if let maxLength, newValue.count > maxLength {
          text = String(newValue.prefix(maxLength))
        }
      }
      .accessibilityLabel(label)

      if let error {
        Text(error)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
      } else if let hint {
        Text(hint)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
      }
    }
  }
}
