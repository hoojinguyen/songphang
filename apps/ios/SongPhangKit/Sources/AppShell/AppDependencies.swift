public import Domain

#if DEBUG
  public import PreviewSupport
#endif

public struct AppDependencies: Sendable {
  public let auth: any AuthRepository
  public let groups: any GroupsRepository
  public let members: any MembersRepository
  public let invites: any InvitesRepository
  public let transactions: any TransactionsRepository
  public let balances: any BalancesRepository
  public let activity: any ActivityRepository
  public let quickEntry: any QuickEntryRepository
  public let groupEvents: any GroupEventsRepository

  #if DEBUG
    public let world: FakeWorld

    public static func scripted(world: FakeWorld) -> AppDependencies {
      AppDependencies(
        auth: FakeAuthRepository(world: world),
        groups: FakeGroupsRepository(world: world),
        members: FakeMembersRepository(world: world),
        invites: FakeInvitesRepository(world: world),
        transactions: FakeTransactionsRepository(world: world),
        balances: FakeBalancesRepository(world: world),
        activity: FakeActivityRepository(world: world),
        quickEntry: FakeQuickEntryRepository(world: world),
        groupEvents: FakeGroupEventsRepository(world: world),
        world: world
      )
    }
  #else
    #error("Live repositories arrive in the integration stage")
  #endif
}
