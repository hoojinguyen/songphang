import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum PaymentQRCode: Sendable {
  private final class Storage: @unchecked Sendable {
    let context = CIContext()
    let lock = NSLock()
    var cachedPayload: String?
    var cachedImage: CGImage?
  }

  private static let storage = Storage()

  static func render(payload: String) -> CGImage? {
    storage.lock.lock()
    defer { storage.lock.unlock() }

    if let cachedPayload = storage.cachedPayload, cachedPayload == payload,
      let cachedImage = storage.cachedImage
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
    guard let cgImage = storage.context.createCGImage(image, from: image.extent) else {
      return nil
    }
    storage.cachedPayload = payload
    storage.cachedImage = cgImage
    return cgImage
  }
}
