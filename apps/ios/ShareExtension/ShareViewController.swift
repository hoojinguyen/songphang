import DesignSystem
import SwiftUI
import UIKit

@objc(ShareViewController)
final class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    Typography.registerFontsIfAvailable()

    let extensionItems =
      (extensionContext?.inputItems as? [NSExtensionItem]) ?? []

    let rootView = ShareExtensionView(
      extensionItems: extensionItems,
      onOpenURL: { [weak self] url in
        self?.openContainingApp(url: url)
      },
      onClose: { [weak self] in
        self?.extensionContext?.completeRequest(returningItems: nil)
      }
    )

    let host = UIHostingController(rootView: rootView)
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    host.didMove(toParent: self)
  }

  private func openContainingApp(url: URL) {
    extensionContext?.open(url) { [weak self] success in
      if success {
        self?.extensionContext?.completeRequest(returningItems: nil)
      }
    }
  }
}
