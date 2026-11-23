import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

@MainActor
enum PaymentQRCode {
  private static let context = CIContext()
  private static var cachedPayload: String?
  private static var cachedImage: CGImage?

  static func render(payload: String) -> CGImage? {
    if let cachedPayload, cachedPayload == payload,
      let cachedImage
    {
      return cachedImage
    }

    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(payload.utf8)
    filter.correctionLevel = "M"
    guard let code = filter.outputImage else { return nil }

    let quietZone = code.extent.insetBy(dx: -4, dy: -4)
    let background = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
      .cropped(to: quietZone)
    let image = code.composited(over: background)
      .transformed(by: CGAffineTransform(scaleX: 12, y: 12))
    guard let cgImage = context.createCGImage(image, from: image.extent) else {
      return nil
    }
    cachedPayload = payload
    cachedImage = cgImage
    return cgImage
  }
}
