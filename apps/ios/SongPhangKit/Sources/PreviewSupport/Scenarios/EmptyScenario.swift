#if DEBUG
  public import Domain

  public nonisolated enum EmptyScenario {
    // Transcribed from fixtures/01-me.json
    public static let user = User(
      id: User.ID("01a1e491-7216-7bb1-8048-06f98325653f"),
      email: "minh@dev.songphang.local",
      name: "Minh",
      avatarUrl: nil,
      emailVerified: true,
      hasPassword: false
    )

    public static let groups: [ExpenseGroup] = []
  }
#endif
