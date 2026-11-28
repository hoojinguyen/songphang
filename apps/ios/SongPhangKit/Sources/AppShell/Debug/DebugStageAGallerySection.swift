#if DEBUG
  import DesignSystem
  import Domain
  public import SwiftUI

  struct DebugStageAGallerySection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var toastMessage: ToastMessage?

    @State private var segmentValue = "feed"
    @State private var motionExpanded = false
    @State private var selectionFeedbackTick = 0
    @State private var successFeedbackTick = 0
    @State private var warningFeedbackTick = 0
    @State private var activeSheetDemo: SheetDemoKind?
    @State private var dirtySheetDraft = ""
    @State private var selectedMembers: Set<Member.ID> = [Member.ID("m1"), Member.ID("m2")]
    @State private var selectedChipId = "c1"
    @State private var burstTrigger = 0
    @State private var shakeTrigger = 0
    @State private var heroSampleMoney = Money(500_000)

    private enum SheetDemoKind: String, Identifiable {
      case fitted
      case half
      case form
      var id: String { rawValue }
    }

    private static let demoMembers: [Member] = [
      Member(
        id: Member.ID("m1"), name: "Minh", position: 0, shape: .circle, color: .mint,
        isMe: true, claimed: true
      ),
      Member(
        id: Member.ID("m2"), name: "Lan", position: 1, shape: .diamond, color: .sky,
        isMe: false, claimed: true
      ),
      Member(
        id: Member.ID("m3"), name: "Hùng", position: 2, shape: .squircle, color: .coral,
        isMe: false, claimed: false
      ),
      Member(
        id: Member.ID("m4"), name: "Thu", position: 3, shape: .leaf, color: .lilac,
        isMe: false, claimed: false
      ),
    ]

    private static let sixChips: [SPChipItem] = [
      SPChipItem(id: "c1", label: "Tất cả"),
      SPChipItem(id: "c2", label: "Ăn uống"),
      SPChipItem(id: "c3", label: "Di chuyển"),
      SPChipItem(id: "c4", label: "Chỗ ở"),
      SPChipItem(id: "c5", label: "Vé tham quan"),
      SPChipItem(id: "c6", label: "Mua sắm"),
    ]

    var body: some View {
      VStack(alignment: .leading, spacing: 18) {
        motionAndMoneyCard
        feedbackAndSheetsCard
        pickersChipsAndBadgesCard
        actionsAndCelebrationCard
        skeletonsAndEmptyCard
      }
      .spFeedback(.selection, trigger: selectionFeedbackTick)
      .spFeedback(.success, trigger: successFeedbackTick)
      .spFeedback(.warning, trigger: warningFeedbackTick)
      .sheet(item: $activeSheetDemo) { kind in
        sheetDemoContent(for: kind)
      }
    }

    private var motionAndMoneyCard: some View {
      SPCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Motion & Money Roles")
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)

          SPSegmentedControl(
            label: "Tab mẫu",
            options: [
              .init(value: "feed", label: "Chi tiêu"),
              .init(value: "balances", label: "Thanh toán"),
              .init(value: "stats", label: "Thống kê"),
            ],
            value: segmentValue,
            onChange: { segmentValue = $0 }
          )

          AdaptiveStack(horizontalSpacing: 12, verticalSpacing: 8) {
            Circle()
              .fill(Tokens.mint)
              .frame(width: motionExpanded ? 44 : 28, height: motionExpanded ? 44 : 28)
              .spAnimation(Motion.bounce, value: motionExpanded)
            SPButton("Đổi nhịp", variant: .surface) {
              Motion.withAnimation(Motion.bounce, reduceMotion: reduceMotion) {
                motionExpanded.toggle()
              }
            }
            SPButton("+125k", variant: .accent) {
              heroSampleMoney = heroSampleMoney + Money(125_000)
            }
          }

          MoneyText(heroSampleMoney, role: .hero)
          AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 6) {
            MoneyText(Money(320_000), role: .primary)
            MoneyText(Money(80_000), role: .secondary)
          }
        }
      }
    }

    private var feedbackAndSheetsCard: some View {
      SPCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Sounds, Haptics & Sheets")
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)

          AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 8) {
            SPButton("Coin", variant: .surface) { SoundPlayer.shared.play(.coin) }
            SPButton("Ting", variant: .surface) { SoundPlayer.shared.play(.ting) }
            SPButton("Chord", variant: .surface) { SoundPlayer.shared.play(.chord) }
          }

          AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 8) {
            SPButton("Rung chọn", variant: .surface) { selectionFeedbackTick &+= 1 }
            SPButton("Rung xong", variant: .surface) { successFeedbackTick &+= 1 }
            SPButton("Rung báo", variant: .surface) { warningFeedbackTick &+= 1 }
          }

          AdaptiveStack(horizontalSpacing: 8, verticalSpacing: 8) {
            SPButton("Sheet vừa", variant: .primary) { activeSheetDemo = .fitted }
            SPButton("Sheet nửa", variant: .surface) { activeSheetDemo = .half }
            SPButton("Sheet biểu mẫu", variant: .surface) { activeSheetDemo = .form }
          }
        }
      }
    }

    private var pickersChipsAndBadgesCard: some View {
      SPCard {
        VStack(alignment: .leading, spacing: 14) {
          HStack(spacing: 8) {
            Text("Picker, Chips & Badge")
              .font(Typography.sectionTitle)
              .foregroundStyle(Tokens.ink)
            CountBadge(count: 0)
            CountBadge(count: 3)
            CountBadge(count: 12, isSelected: true)
          }

          MemberPicker(
            title: "Chia cho ai?",
            members: Self.demoMembers,
            selection: $selectedMembers,
            mode: .multiple
          )

          ChipRow(Array(Self.sixChips.prefix(3))) { chip in
            SPChipButton(chip.label, isSelected: selectedChipId == chip.id) {
              selectedChipId = chip.id
            }
          }

          ChipRow(Self.sixChips) { chip in
            SPChipButton(chip.label, isSelected: selectedChipId == chip.id) {
              selectedChipId = chip.id
            }
          }
        }
      }
    }

    private var actionsAndCelebrationCard: some View {
      SPCard {
        VStack(alignment: .leading, spacing: 14) {
          Text("Copy, Toast, Shake, Loader & Burst")
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)

          AdaptiveStack(horizontalSpacing: 10, verticalSpacing: 10) {
            CopyButton(value: "19036888999011", label: "Sao chép STK")
            SPButton("Hiện thông báo", variant: .surface) {
              toastMessage = ToastMessage(
                text: "Đã tạo Đà Lạt cuối tuần",
                actionLabel: "Hoàn tác",
                action: {}
              )
            }
          }

          HStack(spacing: 10) {
            Text("0 đ")
              .font(Typography.sectionTitle)
              .foregroundStyle(Tokens.muted)
              .padding(.horizontal, 16)
              .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
              .background(Tokens.sunken, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
              .fieldShake(trigger: shakeTrigger, cornerRadius: 20)
            SPButton("Lắc ô", variant: .primary) {
              shakeTrigger &+= 1
            }
          }

          ShapeLoader()
          ShapeBurst(members: Self.demoMembers, trigger: burstTrigger)
          SPButton("Phát hiệu ứng nổ hình", variant: .surface) {
            burstTrigger &+= 1
          }
        }
      }
    }

    private var skeletonsAndEmptyCard: some View {
      VStack(alignment: .leading, spacing: 14) {
        Text("Skeletons & EmptyState")
          .font(Typography.sectionTitle)
          .foregroundStyle(Tokens.ink)

        BalanceCardSkeleton()
        LinkRowSkeleton()
        SearchFieldSkeleton()
        TransactionRowSkeleton()
        MemberRowSkeleton()

        SPCard {
          EmptyState(
            title: "Chưa có giao dịch quỹ",
            subtitle: "Chủ nhóm sẽ ghi nhận khi có đóng góp.",
            noActionReason: "Viewer role cannot record fund contributions"
          )
        }
      }
    }

    @ViewBuilder
    private func sheetDemoContent(for kind: SheetDemoKind) -> some View {
      switch kind {
      case .fitted:
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            SheetCloseButton { activeSheetDemo = nil }
            Spacer()
          }
          Text("Sheet tự co theo nội dung")
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)
          Text("Chiều cao khớp vừa khít nội dung ở mọi cỡ chữ.")
            .font(Typography.body)
            .foregroundStyle(Tokens.muted)
        }
        .padding(20)
        .spSheet(.fitted)
      case .half:
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            SheetCloseButton { activeSheetDemo = nil }
            Spacer()
          }
          Text("Sheet nửa màn hình")
            .font(Typography.sectionTitle)
            .foregroundStyle(Tokens.ink)
        }
        .padding(20)
        .spSheet(.half)
      case .form:
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            SheetCancelButton { activeSheetDemo = nil }
            Spacer()
          }
          TextField("Đà Lạt cuối tuần", text: $dirtySheetDraft)
            .font(Typography.body)
            .padding(14)
            .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(20)
        .spSheet(.form)
        .discardGuard(isDirty: !dirtySheetDraft.isEmpty) {
          dirtySheetDraft = ""
          activeSheetDemo = nil
        }
      }
    }
  }
#endif
