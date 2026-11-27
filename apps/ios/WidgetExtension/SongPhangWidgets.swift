import DesignSystem
import Domain
import SwiftUI
import WidgetKit

struct SongPhangWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> SongPhangWidgetEntry {
    SongPhangWidgetEntry(
      date: Date(),
      snapshot: WidgetSnapshot(
        isSignedIn: false,
        hideAmounts: true
      )
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SongPhangWidgetEntry) -> Void) {
    let snapshot =
      ExtensionSharedStore.shared.readWidgetSnapshot()
      ?? WidgetSnapshot(isSignedIn: false)
    completion(SongPhangWidgetEntry(date: Date(), snapshot: snapshot))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<SongPhangWidgetEntry>) -> Void
  ) {
    let snapshot =
      ExtensionSharedStore.shared.readWidgetSnapshot()
      ?? WidgetSnapshot(isSignedIn: false)
    let entry = SongPhangWidgetEntry(date: Date(), snapshot: snapshot)
    let nextUpdate = Date().addingTimeInterval(30 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
  }
}

struct SongPhangOverviewWidget: Widget {
  let kind = "SongPhangOverviewWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SongPhangWidgetProvider()) { entry in
      OverviewWidgetView(entry: entry)
    }
    .configurationDisplayName("Sòng Phẳng")
    .description(L10n.tr("ios.widget.galleryDescription"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct SongPhangWidgets: WidgetBundle {
  init() {
    Typography.registerFontsIfAvailable()
  }

  var body: some Widget {
    SongPhangOverviewWidget()
  }
}
