import AppShell
import DesignSystem
import SwiftUI

@main
struct SongPhangApp: App {
  init() {
    Typography.registerFontsIfAvailable()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}
