#if DEBUG
  public import Domain

  public nonisolated enum PreviewSamples {
    public static let sampleMoneyValues: [Money] = [
      Money(0),
      Money(1000),
      Money(150_000),
      Money(999_999_999_999),
    ]

    public static let user = TripScenario.user
    public static let unverifiedUser = User(
      id: TripScenario.userId,
      email: "minh@dev.songphang.local",
      name: "Minh",
      avatarUrl: nil,
      emailVerified: false,
      hasPassword: true
    )
    public static let group = TripScenario.group(forStep: 4)
    public static let members = TripScenario.members
    public static let groupUsers = TripScenario.groupUsers
    public static let invite = TripScenario.invite
    public static let invitePreview = TripScenario.invitePreview
    public static let transactions = TripScenario.transactions(forStep: 4)
    public static let balances = TripScenario.step4Balances
    public static let activity = TripScenario.activityItems

    public static let sampleCycle = SettlementCycle(
      id: SettlementCycle.ID("01a1e4bd-ce10-7000-8000-000000000c01"),
      cycleNumber: 1,
      title: "Đợt 1",
      startedAt: "2026-11-10T00:00:00.000Z",
      closedAt: "2026-11-16T15:00:00.000Z",
      closedBy: TripScenario.actorMinh,
      expenseCount: 3,
      totalExpenseAmount: Money(1_599_999),
      snapshot: SettlementCycle.Snapshot(
        balances: [
          SettlementCycle.BalanceSnapshot(
            memberId: TripScenario.minhId,
            name: "Minh",
            shape: .circle,
            color: .mint,
            balance: Money(500_001)
          ),
          SettlementCycle.BalanceSnapshot(
            memberId: TripScenario.lanId,
            name: "Lan",
            shape: .diamond,
            color: .sky,
            balance: Money(-120_000)
          ),
          SettlementCycle.BalanceSnapshot(
            memberId: TripScenario.hungId,
            name: "Hùng",
            shape: .squircle,
            color: .coral,
            balance: Money(-170_001)
          ),
          SettlementCycle.BalanceSnapshot(
            memberId: TripScenario.thuId,
            name: "Thu",
            shape: .leaf,
            color: .lilac,
            balance: Money(-210_000)
          ),
        ],
        transfers: [
          SettlementCycle.TransferSnapshot(
            fromMemberId: TripScenario.thuId,
            fromName: "Thu",
            toMemberId: TripScenario.minhId,
            toName: "Minh",
            amount: Money(210_000)
          )
        ],
        fundBalance: nil
      )
    )

    public static let sampleBreakdowns = MemberBreakdownsResult(
      hasClosedCycles: true,
      resolvedFocus: MemberBreakdownsResolvedFocus(
        kind: .cycle,
        cycleId: sampleCycle.id,
        label: "Đợt 1"
      ),
      breakdowns: [
        MemberDebtBreakdown(
          memberId: TripScenario.thuId,
          memberName: "Thu",
          shape: .leaf,
          color: .lilac,
          carryOverBalance: .zero,
          focusExpenseDelta: Money(-210_000),
          focusTransferDelta: .zero,
          postCycleDelta: .zero,
          netBalance: Money(-210_000),
          lines: [
            MemberBreakdownLine(
              transactionId: TripScenario.t2Transaction.id,
              type: .expense,
              description: "Khách sạn",
              occurredAt: TripScenario.t2Transaction.occurredAt,
              totalAmount: Money(1_200_000),
              payerSummary: "Minh, Lan",
              memberPaid: .zero,
              memberShare: Money(240_000),
              delta: Money(-240_000),
              isPostCloseoutTransfer: false
            ),
            MemberBreakdownLine(
              transactionId: TripScenario.t3Transaction.id,
              type: .income,
              description: "Hoàn cọc",
              occurredAt: TripScenario.t3Transaction.occurredAt,
              totalAmount: Money(200_000),
              payerSummary: "Lan",
              memberPaid: .zero,
              memberShare: Money(50_000),
              delta: Money(50_000),
              isPostCloseoutTransfer: false
            ),
            MemberBreakdownLine(
              transactionId: TripScenario.t4Transaction.id,
              type: .expense,
              description: "Vé",
              occurredAt: TripScenario.t4Transaction.occurredAt,
              totalAmount: Money(99_999),
              payerSummary: "Hùng",
              memberPaid: .zero,
              memberShare: Money(20_000),
              delta: Money(-20_000),
              isPostCloseoutTransfer: false
            ),
          ]
        )
      ]
    )

    public static let sampleGuestLink = GuestLink(
      active: true,
      url: "http://localhost:3000/share/sampleGuestShareToken1234567890abcdefghijk",
      createdAt: "2026-11-26T00:00:00.000Z"
    )
  }
#endif
