import CoreImage
import CoreImage.CIFilterBuiltins
public import Domain
public import SwiftUI
import UIKit

public struct SPSegmentedControl: View {
  public struct Option: Sendable, Hashable, Identifiable {
    public var id: String { value }
    public let value: String
    public let label: String
    public init(value: String, label: String) {
      self.value = value
      self.label = label
    }
  }

  private let label: String
  private let options: [Option]
  private let value: String
  private let isDisabled: Bool
  private let onChange: (String) -> Void

  public init(
    label: String,
    options: [Option],
    value: String,
    isDisabled: Bool = false,
    onChange: @escaping (String) -> Void
  ) {
    self.label = label
    self.options = options
    self.value = value
    self.isDisabled = isDisabled
    self.onChange = onChange
  }

  public var body: some View {
    HStack(spacing: 4) {
      ForEach(options) { option in
        let isSelected = option.value == value
        Button {
          onChange(option.value)
        } label: {
          Text(option.label)
            .font(Typography.subheadlineBold)
            .foregroundStyle(isSelected ? Tokens.surface : Tokens.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Tokens.ink : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
      }
    }
    .padding(4)
    .background(Tokens.sunken)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .accessibilityElement(children: .contain)
    .accessibilityLabel(label)
  }
}

public struct SPSwitch: View {
  private let checked: Bool
  private let label: String
  private let isDisabled: Bool
  private let onChange: (Bool) -> Void

  public init(
    checked: Bool,
    label: String,
    isDisabled: Bool = false,
    onChange: @escaping (Bool) -> Void
  ) {
    self.checked = checked
    self.label = label
    self.isDisabled = isDisabled
    self.onChange = onChange
  }

  public var body: some View {
    Button {
      onChange(!checked)
    } label: {
      HStack {
        if checked { Spacer(minLength: 0) }
        Circle()
          .fill(checked ? Tokens.accent : Tokens.surface)
          .frame(width: 36, height: 36)
        if !checked { Spacer(minLength: 0) }
      }
      .padding(4)
      .frame(width: 64, height: 44)
      .background(checked ? Tokens.ink : Tokens.sunken)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .accessibilityLabel(label)
    .accessibilityValue(checked ? "1" : "0")
  }
}

public struct SPQRCodeView: View {
  private let payload: String
  private let label: String
  private let size: CGFloat

  public init(payload: String, label: String, size: CGFloat = 96) {
    self.payload = payload
    self.label = label
    self.size = size
  }

  public var body: some View {
    Group {
      if let cgImage = Self.makeQRImage(from: payload) {
        Image(decorative: cgImage, scale: 1.0)
          .interpolation(.none)
          .resizable()
          .scaledToFit()
      } else {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Tokens.sunken)
      }
    }
    .frame(width: size, height: size)
    .padding(10)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
  }

  private static func makeQRImage(from string: String) -> CGImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage else { return nil }
    let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
    return context.createCGImage(scaled, from: scaled.extent)
  }
}

public enum MemberAppearancePalette {
  public static let pairs: [(shape: MemberShape, color: MemberColor)] = {
    let shapes: [MemberShape] = [.circle, .diamond, .squircle, .leaf]
    let colors: [MemberColor] = [.mint, .sky, .coral, .lilac]
    var result: [(shape: MemberShape, color: MemberColor)] = []
    for index in 0..<16 {
      let shapeIndex = index % 4
      let colorIndex = (index + (index / 4)) % 4
      result.append((shapes[shapeIndex], colors[colorIndex]))
    }
    return result
  }()

  public static func nextAppearance(
    usedPairs: [(shape: MemberShape, color: MemberColor)],
    position: Int
  ) -> (shape: MemberShape, color: MemberColor) {
    if let unused = pairs.first(where: { pair in
      !usedPairs.contains(where: { $0.shape == pair.shape && $0.color == pair.color })
    }) {
      return unused
    }
    let idx = ((position % 16) + 16) % 16
    return pairs[idx]
  }
}

public struct NewMemberInputRow: View {
  private let appearance: (shape: MemberShape, color: MemberColor)
  private let label: String
  private let addLabel: String
  private let isDisabled: Bool
  private let onAdd: (String) -> Void

  @State private var name = ""

  public init(
    appearance: (shape: MemberShape, color: MemberColor),
    label: String = L10n.tr("newGroup.newMemberLabel"),
    addLabel: String = L10n.tr("newGroup.add"),
    isDisabled: Bool = false,
    onAdd: @escaping (String) -> Void
  ) {
    self.appearance = appearance
    self.label = label
    self.addLabel = addLabel
    self.isDisabled = isDisabled
    self.onAdd = onAdd
  }

  public var body: some View {
    HStack(spacing: 8) {
      MemberShapeView(
        shape: appearance.shape,
        color: appearance.color,
        name: name,
        size: 44
      )

      TextField(label, text: $name)
        .font(Typography.screenHeaderTitle)
        .foregroundStyle(Tokens.ink)
        .disabled(isDisabled)
        .onChange(of: name) { _, newValue in
          if newValue.count > 50 {
            name = String(newValue.prefix(50))
          }
        }
        .onSubmit {
          submit()
        }
        .accessibilityLabel(label)

      SPButton(
        addLabel,
        variant: .surface,
        isDisabled: isDisabled || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ) {
        submit()
      }
    }
    .padding(8)
    .background(Tokens.surface)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 30, style: .continuous)
        .stroke(Tokens.ink, lineWidth: 3)
    )
  }

  private func submit() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isDisabled else { return }
    onAdd(trimmed)
    name = ""
  }
}
