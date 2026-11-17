import DesignSystem
import SwiftUI
import UIKit

// Pushed screens scroll their content under the status bar and Dynamic Island;
// this opaque strip keeps the clock and island readable.
struct StatusBarCover: View {
  var body: some View {
    Tokens.bg
      .frame(height: Self.topInset)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .ignoresSafeArea(edges: .top)
      .allowsHitTesting(false)
  }

  private static var topInset: CGFloat {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    return scene?.keyWindow?.safeAreaInsets.top ?? 0
  }
}
