import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ShareImageNormalizer {
  static let maxImages = 3
  static let maxByteCount = 5 * 1024 * 1024
  private static let maxPixelSize = 2048

  static func extractAndNormalize(from extensionItems: [NSExtensionItem]) async -> [Data] {
    var providers: [NSItemProvider] = []
    for item in extensionItems {
      for provider in item.attachments ?? [] {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
          providers.append(provider)
          if providers.count >= maxImages {
            break
          }
        }
      }
      if providers.count >= maxImages {
        break
      }
    }

    var results: [Data] = []
    for provider in providers {
      if let raw = await loadImageData(from: provider),
        let jpeg = normalizeJPEG(from: raw)
      {
        results.append(jpeg)
      }
    }
    return results
  }

  private static func loadImageData(from provider: NSItemProvider) async -> Data? {
    await withCheckedContinuation { continuation in
      provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
        if let data {
          continuation.resume(returning: data)
          return
        }
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
          if let url = item as? URL, let fileData = try? Data(contentsOf: url) {
            continuation.resume(returning: fileData)
          } else if let direct = item as? Data {
            continuation.resume(returning: direct)
          } else {
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }

  static func normalizeJPEG(from rawData: Data) -> Data? {
    let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let source = CGImageSourceCreateWithData(rawData as CFData, sourceOptions as CFDictionary)
    else {
      return nil
    }

    let thumbOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]
    guard
      let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary)
    else {
      return nil
    }

    let qualities: [CGFloat] = [0.85, 0.72, 0.58, 0.45]
    for quality in qualities {
      let mutableData = NSMutableData()
      guard
        let destination = CGImageDestinationCreateWithData(
          mutableData,
          UTType.jpeg.identifier as CFString,
          1,
          nil
        )
      else {
        return nil
      }
      let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
      CGImageDestinationAddImage(destination, image, props as CFDictionary)
      if CGImageDestinationFinalize(destination), mutableData.length <= maxByteCount {
        return mutableData as Data
      }
    }
    return nil
  }
}
