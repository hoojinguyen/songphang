#if DEBUG
  public import Domain

  public nonisolated enum TripScenario {
    // Transcribed from fixtures/01-me.json, 03-group-create.json, 05-group.json, 06-members.json, 07-users.json, 08-invite.json, 45-invite-preview.json
    public static let userId = User.ID("01a1e491-7216-7bb1-8048-06f98325653f")
    public static let lanUserId = User.ID("01a1e491-7216-7bb1-8048-06f983256540")
    public static let groupId = ExpenseGroup.ID("01a1e4bd-cc25-70c6-860e-275da20487f1")

    public static let minhId = Member.ID("01a1e4bd-cc28-78ec-ad3c-e455610b60ff")
    public static let lanId = Member.ID("01a1e4bd-cc2b-79cd-952d-547466dcfcd5")
    public static let hungId = Member.ID("01a1e4bd-cc2d-7e66-888f-34564633c78d")
    public static let thuId = Member.ID("01a1e4bd-cc30-7cba-91a9-e810bb195d04")

    public static let user = User(
      id: userId,
      email: "minh@dev.songphang.local",
      name: "Minh",
      avatarUrl: nil,
      emailVerified: true,
      hasPassword: true
    )

    public static let previewMembers: [ExpenseGroup.PreviewMember] = [
      ExpenseGroup.PreviewMember(id: minhId, name: "Minh", shape: .circle, color: .mint),
      ExpenseGroup.PreviewMember(id: lanId, name: "Lan", shape: .diamond, color: .sky),
      ExpenseGroup.PreviewMember(id: hungId, name: "Hùng", shape: .squircle, color: .coral),
      ExpenseGroup.PreviewMember(id: thuId, name: "Thu", shape: .leaf, color: .lilac),
    ]

    public static let members: [Member] = [
      Member(
        id: minhId,
        name: "Minh",
        active: true,
        defaultWeight: "1.00",
        position: 0,
        shape: .circle,
        color: .mint,
        isMe: true,
        claimed: true
      ),
      Member(
        id: lanId,
        name: "Lan",
        active: true,
        defaultWeight: "1.00",
        position: 1,
        shape: .diamond,
        color: .sky,
        isMe: false,
        claimed: false
      ),
      Member(
        id: hungId,
        name: "Hùng",
        active: true,
        defaultWeight: "1.00",
        position: 2,
        shape: .squircle,
        color: .coral,
        isMe: false,
        claimed: false
      ),
      Member(
        id: thuId,
        name: "Thu",
        active: true,
        defaultWeight: "1.00",
        position: 3,
        shape: .leaf,
        color: .lilac,
        isMe: false,
        claimed: false
      ),
    ]

    public static let groupUsers: [GroupUser] = [
      GroupUser(
        userId: userId,
        name: "Minh",
        role: .owner,
        memberId: minhId,
        isMe: true
      ),
      GroupUser(
        userId: lanUserId,
        name: "Lan",
        role: .editor,
        memberId: lanId,
        isMe: false
      ),
    ]

    public static let invite = Invite(
      token: "cr4mVLzhGoDywLbfhf5-OLpgPc4mNq8NL4y5xNUyeXI",
      active: true,
      url: "http://localhost:3000/join/cr4mVLzhGoDywLbfhf5-OLpgPc4mNq8NL4y5xNUyeXI"
    )

    // Transcribed from fixtures/45-invite-preview.json
    public static let invitePreview = InvitePreview(
      groupId: groupId,
      groupName: "Đà Lạt 3N2Đ",
      ownerName: "Minh",
      memberCount: 4,
      transactionCount: 4,
      members: [
        InvitePreview.PreviewMember(
          id: minhId,
          name: "Minh",
          shape: .circle,
          color: .mint,
          claimed: true,
          balance: nil
        ),
        InvitePreview.PreviewMember(
          id: lanId,
          name: "Lan",
          shape: .diamond,
          color: .sky,
          claimed: false,
          balance: Money(-120_000)
        ),
        InvitePreview.PreviewMember(
          id: hungId,
          name: "Hùng",
          shape: .squircle,
          color: .coral,
          claimed: false,
          balance: Money(-170_001)
        ),
        InvitePreview.PreviewMember(
          id: thuId,
          name: "Thu",
          shape: .leaf,
          color: .lilac,
          claimed: false,
          balance: Money(-210_000)
        ),
      ],
      alreadyJoined: false
    )

    public static let actorMinh = LedgerTransaction.ActorRef(id: userId, name: "Minh")

    // T1: Transcribed from fixtures/11-t1-preview.json and 12-t1-create.json
    public static let t1Shares: [MemberAmount] = [
      MemberAmount(memberId: minhId, amount: Money(120_000)),
      MemberAmount(memberId: lanId, amount: Money(100_000)),
      MemberAmount(memberId: hungId, amount: Money(80_000)),
    ]

    public static let t1Transaction = LedgerTransaction(
      id: LedgerTransaction.ID("01a1e4bd-cd05-71db-abbb-1bda1779a259"),
      type: .expense,
      description: "Lẩu",
      amount: Money(300_000),
      currency: "VND",
      occurredAt: "2026-11-10T12:00:00.000Z",
      category: .food,
      payers: [
        MemberAmount(memberId: minhId, amount: Money(300_000))
      ],
      split: .exact(
        members: [minhId, lanId, hungId],
        entries: [
          SplitSpec.ExactEntry(memberId: minhId, amount: Money(80_000)),
          SplitSpec.ExactEntry(memberId: lanId, amount: Money(60_000)),
          SplitSpec.ExactEntry(memberId: hungId, amount: Money(40_000)),
        ],
        remainder: .equalAmongAll
      ),
      shares: t1Shares,
      version: 1,
      updatedBy: actorMinh,
      createdBy: actorMinh,
      createdAt: "2026-11-16T14:23:26.466Z",
      updatedAt: "2026-11-16T14:23:26.466Z",
      deletedAt: nil
    )

    // T2: Transcribed from fixtures/15-t2-preview.json and 16-t2-create.json
    public static let t2Shares: [MemberAmount] = [
      MemberAmount(memberId: minhId, amount: Money(480_000)),
      MemberAmount(memberId: lanId, amount: Money(240_000)),
      MemberAmount(memberId: hungId, amount: Money(240_000)),
      MemberAmount(memberId: thuId, amount: Money(240_000)),
    ]

    public static let t2Transaction = LedgerTransaction(
      id: LedgerTransaction.ID("01a1e4bd-cd5d-7fb3-9437-3b97e2f381fe"),
      type: .expense,
      description: "Khách sạn",
      amount: Money(1_200_000),
      currency: "VND",
      occurredAt: "2026-11-10T12:00:00.000Z",
      category: .lodging,
      payers: [
        MemberAmount(memberId: minhId, amount: Money(800_000)),
        MemberAmount(memberId: lanId, amount: Money(400_000)),
      ],
      split: .shares(
        entries: [
          SplitSpec.ShareWeightEntry(memberId: minhId, weight: "2"),
          SplitSpec.ShareWeightEntry(memberId: lanId, weight: "1"),
          SplitSpec.ShareWeightEntry(memberId: hungId, weight: "1"),
          SplitSpec.ShareWeightEntry(memberId: thuId, weight: "1"),
        ]
      ),
      shares: t2Shares,
      version: 1,
      updatedBy: actorMinh,
      createdBy: actorMinh,
      createdAt: "2026-11-16T14:23:26.554Z",
      updatedAt: "2026-11-16T14:23:26.554Z",
      deletedAt: nil
    )

    // T3: Transcribed from fixtures/19-t3-preview.json and 20-t3-create.json
    public static let t3Shares: [MemberAmount] = [
      MemberAmount(memberId: minhId, amount: Money(50_000)),
      MemberAmount(memberId: lanId, amount: Money(50_000)),
      MemberAmount(memberId: hungId, amount: Money(50_000)),
      MemberAmount(memberId: thuId, amount: Money(50_000)),
    ]

    public static let t3Transaction = LedgerTransaction(
      id: LedgerTransaction.ID("01a1e4bd-cdb4-799a-899c-fdb2c366b5a2"),
      type: .income,
      description: "Hoàn cọc",
      amount: Money(200_000),
      currency: "VND",
      occurredAt: "2026-11-10T12:00:00.000Z",
      category: nil,
      payers: [
        MemberAmount(memberId: lanId, amount: Money(200_000))
      ],
      split: .equal(members: [minhId, lanId, hungId, thuId]),
      shares: t3Shares,
      version: 1,
      updatedBy: actorMinh,
      createdBy: actorMinh,
      createdAt: "2026-11-16T14:23:26.641Z",
      updatedAt: "2026-11-16T14:23:26.641Z",
      deletedAt: nil
    )

    // T4: Transcribed from fixtures/23-t4-preview.json and 24-t4-create.json
    public static let t4Shares: [MemberAmount] = [
      MemberAmount(memberId: minhId, amount: Money(49_999)),
      MemberAmount(memberId: lanId, amount: Money(30_000)),
      MemberAmount(memberId: thuId, amount: Money(20_000)),
    ]

    public static let t4Transaction = LedgerTransaction(
      id: LedgerTransaction.ID("01a1e4bd-ce0b-72e9-8a78-0e0ee8f04bdc"),
      type: .expense,
      description: "Vé",
      amount: Money(99_999),
      currency: "VND",
      occurredAt: "2026-11-10T12:00:00.000Z",
      category: .transport,
      payers: [
        MemberAmount(memberId: hungId, amount: Money(99_999))
      ],
      split: .percent(
        entries: [
          SplitSpec.PercentEntry(memberId: minhId, percent: "50"),
          SplitSpec.PercentEntry(memberId: lanId, percent: "30"),
          SplitSpec.PercentEntry(memberId: thuId, percent: "20"),
        ]
      ),
      shares: t4Shares,
      version: 1,
      updatedBy: actorMinh,
      createdBy: actorMinh,
      createdAt: "2026-11-16T14:23:26.728Z",
      updatedAt: "2026-11-16T14:23:26.728Z",
      deletedAt: nil
    )

    // Step 0 balances: transcribed from fixtures/10-step0-balances.json
    public static let step0Balances = GroupBalances(
      currency: "VND",
      minimized: true,
      balances: [
        Balance(memberId: minhId, balance: Money(0)),
        Balance(memberId: lanId, balance: Money(0)),
        Balance(memberId: hungId, balance: Money(0)),
        Balance(memberId: thuId, balance: Money(0)),
      ],
      transfers: []
    )

    // Step 1 balances: transcribed from fixtures/14-step1-balances.json
    public static let step1Balances = GroupBalances(
      currency: "VND",
      minimized: true,
      balances: [
        Balance(memberId: minhId, balance: Money(180_000)),
        Balance(memberId: lanId, balance: Money(-100_000)),
        Balance(memberId: hungId, balance: Money(-80_000)),
        Balance(memberId: thuId, balance: Money(0)),
      ],
      transfers: [
        SuggestedTransfer(fromMemberId: lanId, toMemberId: minhId, amount: Money(100_000)),
        SuggestedTransfer(fromMemberId: hungId, toMemberId: minhId, amount: Money(80_000)),
      ]
    )

    // Step 2 balances: transcribed from fixtures/18-step2-balances.json
    public static let step2Balances = GroupBalances(
      currency: "VND",
      minimized: true,
      balances: [
        Balance(memberId: minhId, balance: Money(500_000)),
        Balance(memberId: lanId, balance: Money(60_000)),
        Balance(memberId: hungId, balance: Money(-320_000)),
        Balance(memberId: thuId, balance: Money(-240_000)),
      ],
      transfers: [
        SuggestedTransfer(fromMemberId: hungId, toMemberId: minhId, amount: Money(320_000)),
        SuggestedTransfer(fromMemberId: thuId, toMemberId: minhId, amount: Money(180_000)),
        SuggestedTransfer(fromMemberId: thuId, toMemberId: lanId, amount: Money(60_000)),
      ]
    )

    // Step 3 balances: transcribed from fixtures/22-step3-balances.json
    public static let step3Balances = GroupBalances(
      currency: "VND",
      minimized: true,
      balances: [
        Balance(memberId: minhId, balance: Money(550_000)),
        Balance(memberId: lanId, balance: Money(-90_000)),
        Balance(memberId: hungId, balance: Money(-270_000)),
        Balance(memberId: thuId, balance: Money(-190_000)),
      ],
      transfers: [
        SuggestedTransfer(fromMemberId: hungId, toMemberId: minhId, amount: Money(270_000)),
        SuggestedTransfer(fromMemberId: thuId, toMemberId: minhId, amount: Money(190_000)),
        SuggestedTransfer(fromMemberId: lanId, toMemberId: minhId, amount: Money(90_000)),
      ]
    )

    // Step 4 balances: transcribed from fixtures/26-step4-balances.json
    public static let step4Balances = GroupBalances(
      currency: "VND",
      minimized: true,
      balances: [
        Balance(memberId: minhId, balance: Money(500_001)),
        Balance(memberId: lanId, balance: Money(-120_000)),
        Balance(memberId: hungId, balance: Money(-170_001)),
        Balance(memberId: thuId, balance: Money(-210_000)),
      ],
      transfers: [
        SuggestedTransfer(fromMemberId: thuId, toMemberId: minhId, amount: Money(210_000)),
        SuggestedTransfer(fromMemberId: hungId, toMemberId: minhId, amount: Money(170_001)),
        SuggestedTransfer(fromMemberId: lanId, toMemberId: minhId, amount: Money(120_000)),
      ]
    )

    public static func transactions(forStep step: Int) -> [LedgerTransaction] {
      switch step {
      case 0:
        return []
      case 1:
        return [t1Transaction]
      case 2:
        return [t2Transaction, t1Transaction]
      case 3:
        return [t3Transaction, t2Transaction, t1Transaction]
      default:
        return [t4Transaction, t3Transaction, t2Transaction, t1Transaction]
      }
    }

    public static func balances(forStep step: Int) -> GroupBalances {
      switch step {
      case 0:
        return step0Balances
      case 1:
        return step1Balances
      case 2:
        return step2Balances
      case 3:
        return step3Balances
      default:
        return step4Balances
      }
    }

    public static func group(forStep step: Int, role: Role = .owner) -> ExpenseGroup {
      let stepBalances = balances(forStep: step)
      let myBalance =
        stepBalances.balances.first(where: { $0.memberId == minhId })?.balance ?? .zero
      return ExpenseGroup(
        id: groupId,
        name: "Đà Lạt 3N2Đ",
        currency: "VND",
        memberCount: 4,
        previewMembers: previewMembers,
        myBalance: myBalance,
        minimizeDebts: true,
        defaultRole: .editor,
        role: role,
        myMemberId: minhId,
        createdAt: "2026-11-16T14:23:26.244Z"
      )
    }

    // Activity: transcribed from fixtures/28-activity.json
    public static let activityActorMinh = ActivityItem.Actor(
      userId: userId,
      name: "Minh",
      memberId: minhId
    )

    public static let activityItems: [ActivityItem] = [
      ActivityItem(
        id: ActivityItem.ID("01a1e4bd-ce0e-7df7-9d87-d9922e05553b"),
        actor: activityActorMinh,
        action: "create",
        entityType: .transaction,
        entityId: t4Transaction.id.rawValue,
        summary: "Vé",
        before: nil,
        after: ActivityItem.SnapshotValues(
          transactionType: .expense,
          amount: Money(99_999),
          description: "Vé",
          occurredAt: "2026-11-10T12:00:00.000Z",
          category: .transport,
          payers: t4Transaction.payers,
          shares: t4Shares,
          split: t4Transaction.split
        ),
        createdAt: "2026-11-16T14:23:26.728Z",
        canRestore: false
      ),
      ActivityItem(
        id: ActivityItem.ID("01a1e4bd-cdb7-7bf4-b418-cf2ef12c6b77"),
        actor: activityActorMinh,
        action: "create",
        entityType: .transaction,
        entityId: t3Transaction.id.rawValue,
        summary: "Hoàn cọc",
        before: nil,
        after: ActivityItem.SnapshotValues(
          transactionType: .income,
          amount: Money(200_000),
          description: "Hoàn cọc",
          occurredAt: "2026-11-10T12:00:00.000Z",
          category: nil,
          payers: t3Transaction.payers,
          shares: t3Shares,
          split: t3Transaction.split
        ),
        createdAt: "2026-11-16T14:23:26.641Z",
        canRestore: false
      ),
      ActivityItem(
        id: ActivityItem.ID("01a1e4bd-cd60-7627-9d1a-39f160602085"),
        actor: activityActorMinh,
        action: "create",
        entityType: .transaction,
        entityId: t2Transaction.id.rawValue,
        summary: "Khách sạn",
        before: nil,
        after: ActivityItem.SnapshotValues(
          transactionType: .expense,
          amount: Money(1_200_000),
          description: "Khách sạn",
          occurredAt: "2026-11-10T12:00:00.000Z",
          category: .lodging,
          payers: t2Transaction.payers,
          shares: t2Shares,
          split: t2Transaction.split
        ),
        createdAt: "2026-11-16T14:23:26.554Z",
        canRestore: false
      ),
      ActivityItem(
        id: ActivityItem.ID("01a1e4bd-cd08-799f-a3ef-23a19450d319"),
        actor: activityActorMinh,
        action: "create",
        entityType: .transaction,
        entityId: t1Transaction.id.rawValue,
        summary: "Lẩu",
        before: nil,
        after: ActivityItem.SnapshotValues(
          transactionType: .expense,
          amount: Money(300_000),
          description: "Lẩu",
          occurredAt: "2026-11-10T12:00:00.000Z",
          category: .food,
          payers: t1Transaction.payers,
          shares: t1Shares,
          split: t1Transaction.split
        ),
        createdAt: "2026-11-16T14:23:26.466Z",
        canRestore: false
      ),
      ActivityItem(
        id: ActivityItem.ID("01a1e4bd-cc35-7f3e-925e-b3aed3a3384d"),
        actor: activityActorMinh,
        action: "create",
        entityType: .group,
        entityId: groupId.rawValue,
        summary: "Đà Lạt 3N2Đ",
        before: nil,
        after: ActivityItem.SnapshotValues(
          memberCount: 4
        ),
        createdAt: "2026-11-16T14:23:26.244Z",
        canRestore: false
      ),
    ]
  }
#endif
