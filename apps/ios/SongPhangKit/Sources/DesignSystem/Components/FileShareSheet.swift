public import SwiftUI
import UIKit

public struct ShareFileItem: Identifiable, Sendable {
  public let id = UUID()
  public let url: URL

  public init(url: URL) {
    self.url = url
  }
}

public struct FileShareSheet: UIViewControllerRepresentable {
  private let url: URL
  private let onComplete: () -> Void

  public init(url: URL, onComplete: @escaping () -> Void) {
    self.url = url
    self.onComplete = onComplete
  }

  public func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    controller.completionWithItemsHandler = { _, _, _, _ in
      try? FileManager.default.removeItem(at: url)
      onComplete()
    }
    return controller
  }

  public func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}
