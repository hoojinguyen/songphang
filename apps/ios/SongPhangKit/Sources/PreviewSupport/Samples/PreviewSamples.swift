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
  }
#endif
