import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
public import SwiftUI

public enum QRCodeMatrixRenderer {
  private static let context = CIContext()

  public static func cgImage(from payload: String, scale: CGFloat = 10) -> CGImage? {
    guard !payload.isEmpty else { return nil }
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(payload.utf8)
    filter.correctionLevel = "M"
    guard let code = filter.outputImage else { return nil }

    let quietZone = code.extent.insetBy(dx: -2, dy: -2)
    let background = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
      .cropped(to: quietZone)
    let image =
      code
      .composited(over: background)
      .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    return context.createCGImage(image, from: image.extent)
  }
}

public struct QRCodeMatrixView: View {
  private let payload: String
  private let size: CGFloat
  private let accessibilityLabelText: String

  public init(
    payload: String,
    size: CGFloat = 120,
    accessibilityLabel: String = ""
  ) {
    self.payload = payload
    self.size = size
    self.accessibilityLabelText = accessibilityLabel
  }

  public var body: some View {
    Group {
      if let cgImage = QRCodeMatrixRenderer.cgImage(from: payload) {
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
    .padding(8)
    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabelText)
  }
}
