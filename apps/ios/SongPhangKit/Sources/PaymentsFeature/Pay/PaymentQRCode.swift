import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum PaymentQRCode {
  static func render(payload: String) -> CGImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(payload.utf8)
    filter.correctionLevel = "M"
    guard let code = filter.outputImage else { return nil }

    let quietZone = code.extent.insetBy(dx: -4, dy: -4)
    let background = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
      .cropped(to: quietZone)
    let image = code.composited(over: background)
      .transformed(by: CGAffineTransform(scaleX: 12, y: 12))
    return CIContext().createCGImage(image, from: image.extent)
  }
}
