import DesignSystem
import Domain
import SwiftUI
import WidgetKit

struct SongPhangWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct OverviewWidgetView: View {
  let entry: SongPhangWidgetEntry
  @Environment(\.widgetFamily) private var family

  private var colorSchemeOverride: ColorScheme? {
    switch entry.snapshot.appearanceMode {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  private var overviewURL: URL {
    URL(string: "songphang://overview") ?? URL(filePath: "/")
  }

  private var netStatusLabel: String {
    if entry.snapshot.hideAmounts {
      return L10n.tr("ios.widget.amountsHidden")
    }
    if entry.snapshot.netBalance > 0 {
      return L10n.tr("ios.widget.owedToMe")
    }
    if entry.snapshot.netBalance < 0 {
      return L10n.tr("ios.widget.iOwe")
    }
    return L10n.tr("ios.widget.settled")
  }

  private var netBalanceColor: Color {
    if entry.snapshot.hideAmounts {
      return Tokens.ink
    }
    if entry.snapshot.netBalance > 0 {
      return Tokens.credit
    }
    if entry.snapshot.netBalance < 0 {
      return Tokens.debt
    }
    return Tokens.ink
  }

  var body: some View {
    Group {
      if !entry.snapshot.isSignedIn {
        signedOutContent
      } else if family == .systemSmall {
        smallContent
      } else {
        mediumContent
      }
    }
    .preferredColorScheme(colorSchemeOverride)
    .containerBackground(for: .widget) {
      Tokens.bg
    }
  }

  private var signedOutContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.tr("ios.widget.signedOutHint"))
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)
      Spacer()
      Text(L10n.tr("ios.widget.tapToOpen"))
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(overviewURL)
  }

  private var smallContent: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("SÒNG PHẲNG")
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.muted)
          .lineLimit(1)
        Spacer()
        if entry.snapshot.pendingActionCount > 0 {
          Text(
            L10n.t(
              "ios.widget.pendingActions",
              ["count": String(entry.snapshot.pendingActionCount)]
            )
          )
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.onAccent)
          .lineLimit(1)
          .padding(.horizontal, 7)
          .padding(.vertical, 2)
          .background(Tokens.accent, in: Capsule())
        }
      }

      Text(netStatusLabel)
        .font(Typography.caption)
        .foregroundStyle(Tokens.muted)
        .lineLimit(1)

      if entry.snapshot.hideAmounts {
        Text(L10n.tr("ios.widget.amountsHidden"))
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
      } else {
        MoneyText(
          Money(abs(entry.snapshot.netBalance)),
          style: .full,
          font: Typography.sectionTitle,
          color: netBalanceColor
        )
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      }

      Spacer(minLength: 4)

      if let recent = entry.snapshot.recentGroup {
        Text(recent.name)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
          .lineLimit(1)
      }

      let quickAddURL =
        entry.snapshot.recentGroup.flatMap {
          URL(string: "songphang://group/\($0.id)/quick-entry")
        } ?? overviewURL
      Link(destination: quickAddURL) {
        Text(L10n.tr("ios.widget.addExpenseCta"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.onAccent)
          .lineLimit(1)
          .frame(maxWidth: .infinity, minHeight: 30)
          .background(Tokens.accent, in: Capsule())
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(overviewURL)
  }

  private var mediumContent: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(netStatusLabel)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)

          if entry.snapshot.hideAmounts {
            Text(L10n.tr("ios.widget.amountsHidden"))
              .font(Typography.sectionTitle)
              .foregroundStyle(Tokens.ink)
          } else {
            MoneyText(
              Money(abs(entry.snapshot.netBalance)),
              style: .full,
              font: Typography.sectionTitle,
              color: netBalanceColor
            )
            .lineLimit(1)
            .minimumScaleFactor(0.75)
          }
        }

        Spacer(minLength: 8)

        VStack(alignment: .trailing, spacing: 4) {
          if let recent = entry.snapshot.recentGroup {
            Text(recent.name)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
              .lineLimit(1)
          }
          if !entry.snapshot.hideAmounts {
            HStack(spacing: 8) {
              Text(MoneyFormat.compact(Money(entry.snapshot.totalOwedToMe)))
                .font(Typography.captionBold)
                .monospacedDigit()
                .foregroundStyle(Tokens.credit)
              Text(MoneyFormat.compact(Money(entry.snapshot.totalIOwe)))
                .font(Typography.captionBold)
                .monospacedDigit()
                .foregroundStyle(Tokens.debt)
            }
          }
        }
      }

      Spacer(minLength: 0)

      if let recent = entry.snapshot.recentGroup {
        HStack(spacing: 8) {
          actionPill(
            title: L10n.tr("ios.widget.quickEntry"),
            url: URL(string: "songphang://group/\(recent.id)/quick-entry") ?? overviewURL,
            highlighted: true
          )
          actionPill(
            title: L10n.tr("ios.widget.manualOrBill"),
            url: URL(string: "songphang://group/\(recent.id)/expense-new") ?? overviewURL,
            highlighted: false
          )
          actionPill(
            title: L10n.tr("ios.widget.balances"),
            url: URL(string: "songphang://group/\(recent.id)/balances") ?? overviewURL,
            highlighted: false
          )
        }
      } else {
        Text(L10n.tr("ios.widget.tapToOpen"))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(overviewURL)
  }

  private func actionPill(title: String, url: URL, highlighted: Bool) -> some View {
    Link(destination: url) {
      Text(title)
        .font(Typography.captionBold)
        .foregroundStyle(highlighted ? Tokens.onAccent : Tokens.ink)
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
          highlighted ? Tokens.accent : Tokens.surface,
          in: Capsule()
        )
    }
  }
}

#if DEBUG
  #Preview("Small Signed In", as: .systemSmall) {
    SongPhangOverviewWidget()
  } timeline: {
    SongPhangWidgetEntry(
      date: Date(),
      snapshot: WidgetSnapshot(
        isSignedIn: true,
        appearanceMode: "light",
        hideAmounts: false,
        totalOwedToMe: 450_000,
        totalIOwe: 120_000,
        netBalance: 330_000,
        pendingActionCount: 1,
        recentGroup: WidgetRecentGroup(
          id: "00000000-0000-7000-8000-000000000001",
          name: "Đà Lạt 3N2Đ",
          myBalance: 330_000
        )
      )
    )
  }

  #Preview("Medium Hide Amounts Dark", as: .systemMedium) {
    SongPhangOverviewWidget()
  } timeline: {
    SongPhangWidgetEntry(
      date: Date(),
      snapshot: WidgetSnapshot(
        isSignedIn: true,
        appearanceMode: "dark",
        hideAmounts: true,
        totalOwedToMe: 450_000,
        totalIOwe: 120_000,
        netBalance: 330_000,
        pendingActionCount: 0,
        recentGroup: WidgetRecentGroup(
          id: "00000000-0000-7000-8000-000000000001",
          name: "Đà Lạt 3N2Đ",
          myBalance: 330_000
        )
      )
    )
  }
#endif
