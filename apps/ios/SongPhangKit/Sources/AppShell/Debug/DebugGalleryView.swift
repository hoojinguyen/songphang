import DesignSystem
import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct DebugGalleryView: View {
  public enum SectionTab: String, CaseIterable {
    case tokens = "Tokens"
    case shapes = "Shapes"
    case components = "Components"
  }

  @State private var selectedTab: SectionTab

  public init() {
    let args = ProcessInfo.processInfo.arguments
    if args.contains("--gallery-shapes") {
      _selectedTab = State(initialValue: .shapes)
    } else if args.contains("--gallery-components") {
      _selectedTab = State(initialValue: .components)
    } else {
      _selectedTab = State(initialValue: .tokens)
    }
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Sòng Phẳng — Design System")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)
          .fixedSize(horizontal: false, vertical: true)

        Picker("Section", selection: $selectedTab) {
          ForEach(SectionTab.allCases, id: \.self) { tab in
            Text(tab.rawValue).tag(tab)
          }
        }
        .pickerStyle(.segmented)

        switch selectedTab {
        case .tokens:
          moneySection
          tokensSection
        case .shapes:
          shapesSection
        case .components:
          buttonsSection
          statesSection
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Tokens.bg.ignoresSafeArea())
  }

  private var tokensSection: some View {
    SPCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Tokens")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        ForEach(Tokens.allNamedColors, id: \.name) { entry in
          ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
              swatchView(entry.color)
              Text(entry.name)
                .font(Typography.subheadlineBold)
                .foregroundStyle(Tokens.ink)
              Spacer(minLength: 8)
              Text(entry.hex)
                .font(Typography.caption.monospaced())
                .foregroundStyle(Tokens.muted)
            }
            VStack(alignment: .leading, spacing: 4) {
              HStack(spacing: 12) {
                swatchView(entry.color)
                Text(entry.name)
                  .font(Typography.subheadlineBold)
                  .foregroundStyle(Tokens.ink)
              }
              Text(entry.hex)
                .font(Typography.caption.monospaced())
                .foregroundStyle(Tokens.muted)
            }
          }
        }
      }
    }
  }

  private func swatchView(_ color: Color) -> some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(color)
      .frame(width: 44, height: 32)
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(Tokens.ink.opacity(0.15), lineWidth: 1)
      )
  }

  private var shapesSection: some View {
    SPCard {
      VStack(alignment: .leading, spacing: 16) {
        Text("Member Shapes (24, 44, 96 pt)")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        ForEach(Array(MemberShape.allCases.enumerated()), id: \.offset) { _, shape in
          VStack(alignment: .leading, spacing: 12) {
            Text(shape.code)
              .font(Typography.subheadlineBold)
              .foregroundStyle(Tokens.muted)

            ForEach([CGFloat(24), CGFloat(44), CGFloat(96)], id: \.self) { size in
              VStack(alignment: .leading, spacing: 6) {
                Text("\(Int(size)) pt")
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 12) {
                    ForEach(Array(MemberColor.allCases.enumerated()), id: \.offset) { _, color in
                      MemberShapeView(
                        shape: shape,
                        color: color,
                        initial: "Minh",
                        size: size
                      )
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  private var moneySection: some View {
    SPCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Money Formatting")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        #if DEBUG
          let values = PreviewSamples.sampleMoneyValues
        #else
          let values: [Money] = [
            Money(0), Money(1000), Money(150_000), Money(999_999_999_999),
          ]
        #endif

        ForEach(values, id: \.self) { value in
          ViewThatFits(in: .horizontal) {
            HStack {
              MoneyText(value, style: .full, font: Typography.bodyBold)
              Spacer(minLength: 8)
              Text("compact: \(MoneyFormat.compact(value))")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
            VStack(alignment: .leading, spacing: 4) {
              MoneyText(value, style: .full, font: Typography.bodyBold)
              Text("compact: \(MoneyFormat.compact(value))")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
          }
        }
      }
    }
  }

  private var buttonsSection: some View {
    SPCard(tone: .sunken) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Buttons")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        SPButton("Chính (Primary)", variant: .primary, isFullWidth: true) {}
        SPButton("Nhấn (Accent)", variant: .accent, isFullWidth: true) {}
        SPButton("Nền (Surface)", variant: .surface, isFullWidth: true) {}
        SPButton("Cỡ lớn (Large)", variant: .accent, size: .lg, isFullWidth: true) {}
        SPButton("Đang mất mạng", variant: .primary, isFullWidth: true, isOfflineBlocked: true) {}
      }
    }
  }

  private var statesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("States")
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      OfflineBanner(sinceTimeText: "21:30")

      SPCard {
        LoadingSkeleton(rowCount: 2, rowHeight: 56)
      }

      SPCard {
        LoadError(onRetry: {})
      }

      SPCard {
        EmptyState(title: "Bạn chưa có nhóm nào") {
          MemberShapeView(shape: .circle, color: .mint, initial: "Minh", size: 56)
        } action: {
          SPButton("Tạo nhóm", variant: .accent) {}
        }
      }
    }
  }
}
