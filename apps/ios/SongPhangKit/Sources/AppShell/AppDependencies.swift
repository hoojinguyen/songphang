public import Domain
public import Repositories

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
  public let liveConfiguration: APIConfiguration?

  #if DEBUG
    public let world: FakeWorld?

    public static func live(configuration: APIConfiguration) -> AppDependencies {
      let environment = LiveAPIEnvironment(configuration: configuration)
      return AppDependencies(
        auth: GatedAuthRepository(environment: environment),
        groups: GatedGroupsRepository(),
        members: GatedMembersRepository(),
        invites: GatedInvitesRepository(),
        transactions: GatedTransactionsRepository(),
        balances: GatedBalancesRepository(),
        activity: GatedActivityRepository(),
        quickEntry: GatedQuickEntryRepository(),
        groupEvents: GatedGroupEventsRepository(),
        liveConfiguration: configuration,
        world: nil
      )
    }

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
        liveConfiguration: nil,
        world: world
      )
    }
  #else
    #error("Live repositories arrive in the integration stage")
  #endif
}
