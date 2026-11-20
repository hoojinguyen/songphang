public import Domain
public import Foundation
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
  public let webBaseURL: URL
  public let appVersion: String
  public let appStoreURL: URL?
  public let makeSessionInvalidations: @Sendable () -> AsyncStream<Void>

  #if DEBUG
    public let world: FakeWorld?
  #endif

  public static func live(configuration: APIConfiguration) -> AppDependencies {
    let environment = LiveAPIEnvironment(configuration: configuration)
    #if DEBUG
      return AppDependencies(
        auth: LiveAuthRepository(environment: environment),
        groups: LiveGroupsRepository(environment: environment),
        members: LiveMembersRepository(environment: environment),
        invites: LiveInvitesRepository(environment: environment),
        transactions: LiveTransactionsRepository(environment: environment),
        balances: LiveBalancesRepository(environment: environment),
        activity: LiveActivityRepository(environment: environment),
        quickEntry: LiveQuickEntryRepository(environment: environment),
        groupEvents: LiveGroupEventsRepository(environment: environment),
        liveConfiguration: configuration,
        webBaseURL: configuration.webBaseURL,
        appVersion: configuration.appVersion,
        appStoreURL: configuration.appStoreURL,
        makeSessionInvalidations: { environment.sessionInvalidations() },
        world: nil
      )
    #else
      return AppDependencies(
        auth: LiveAuthRepository(environment: environment),
        groups: LiveGroupsRepository(environment: environment),
        members: LiveMembersRepository(environment: environment),
        invites: LiveInvitesRepository(environment: environment),
        transactions: LiveTransactionsRepository(environment: environment),
        balances: LiveBalancesRepository(environment: environment),
        activity: LiveActivityRepository(environment: environment),
        quickEntry: LiveQuickEntryRepository(environment: environment),
        groupEvents: LiveGroupEventsRepository(environment: environment),
        liveConfiguration: configuration,
        webBaseURL: configuration.webBaseURL,
        appVersion: configuration.appVersion,
        appStoreURL: configuration.appStoreURL,
        makeSessionInvalidations: { environment.sessionInvalidations() }
      )
    #endif
  }

  #if DEBUG
    public static func scripted(
      world: FakeWorld,
      webBaseURL: URL = URL(string: "http://localhost:3000") ?? URL(filePath: "/"),
      appVersion: String = "1.0.0"
    ) -> AppDependencies {
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
        webBaseURL: webBaseURL,
        appVersion: appVersion,
        appStoreURL: nil,
        makeSessionInvalidations: { AsyncStream { _ in } },
        world: world
      )
    }
  #endif
}
