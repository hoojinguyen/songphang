import CoreGraphics
public import Foundation
import ImageIO
import UniformTypeIdentifiers

public nonisolated enum ReceiptImageError: Error, Sendable, Equatable {
  case notAnImage
  case tooLarge
}

public nonisolated enum ReceiptImageProcessor {
  public static let maxLongestEdge = 2000
  public static let jpegQuality = 0.85
  public static let maxByteSize = 5_242_880

  public static func prepareJPEG(from data: Data) async throws(ReceiptImageError) -> Data {
    let result = await Task.detached(priority: .userInitiated) {
      () -> Result<Data, ReceiptImageError> in
      do throws(ReceiptImageError) {
        return .success(try prepareJPEGSync(from: data))
      } catch {
        return .failure(error)
      }
    }.value
    switch result {
    case .success(let jpeg): return jpeg
    case .failure(let error): throw error
    }
  }

  public static func prepareJPEGSync(from data: Data) throws(ReceiptImageError) -> Data {
    guard !data.isEmpty,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let rawWidth = properties[kCGImagePropertyPixelWidth] as? Int,
      let rawHeight = properties[kCGImagePropertyPixelHeight] as? Int,
      rawWidth > 0,
      rawHeight > 0
    else {
      throw .notAnImage
    }

    let longest = max(rawWidth, rawHeight)
    let targetLongest = min(maxLongestEdge, longest)
    let thumbOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: targetLongest,
    ]
    guard
      let decoded = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary),
      decoded.width > 0,
      decoded.height > 0
    else {
      throw .notAnImage
    }

    // Draw onto an opaque RGB bitmap so transparent PNGs/WebPs encode cleanly with no alpha or source metadata.
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
    guard
      let context = CGContext(
        data: nil,
        width: decoded.width,
        height: decoded.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      )
    else {
      throw .notAnImage
    }
    let rect = CGRect(x: 0, y: 0, width: decoded.width, height: decoded.height)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(rect)
    context.draw(decoded, in: rect)

    guard let flattened = context.makeImage(),
      let outputData = CFDataCreateMutable(nil, 0),
      let destination = CGImageDestinationCreateWithData(
        outputData,
        UTType.jpeg.identifier as CFString,
        1,
        nil
      )
    else {
      throw .notAnImage
    }

    let destOptions: [CFString: Any] = [
      kCGImageDestinationLossyCompressionQuality: jpegQuality
    ]
    CGImageDestinationAddImage(destination, flattened, destOptions as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
      throw .notAnImage
    }

    let result = outputData as Data
    guard !result.isEmpty, result.count <= maxByteSize else {
      throw .tooLarge
    }
    return result
  }
}
