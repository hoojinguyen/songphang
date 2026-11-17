import SwiftUI
import UIKit

// Screens hide the system back button, which also disables the edge-swipe back gesture.
// This hidden controller becomes the gesture's delegate while its screen is visible.
struct PopGestureEnabler: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> Controller { Controller() }

  func updateUIViewController(_ uiViewController: Controller, context: Context) {}

  final class Controller: UIViewController, UIGestureRecognizerDelegate {
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      (navigationController?.viewControllers.count ?? 0) > 1
    }
  }
}
