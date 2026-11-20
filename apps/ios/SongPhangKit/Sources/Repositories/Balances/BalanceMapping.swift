import Domain
import Foundation
import GeneratedAPI

enum BalanceMapping {
  static func mapBalances(_ dto: Components.Schemas.BalancesResponse) -> GroupBalances {
    GroupBalances(
      currency: dto.currency.rawValue,
      minimized: dto.minimized,
      balances: dto.balances.map {
        Balance(memberId: Member.ID($0.memberId), balance: Money(Int64($0.balance)))
      },
      transfers: dto.transfers.map {
        SuggestedTransfer(
          fromMemberId: Member.ID($0.fromMemberId),
          toMemberId: Member.ID($0.toMemberId),
          amount: Money(Int64($0.amount))
        )
      }
    )
  }

  struct RawBalancesResponse: Codable, Sendable {
    struct RawBalance: Codable, Sendable {
      let memberId: String
      let balance: Int64
    }
    struct RawTransfer: Codable, Sendable {
      let fromMemberId: String
      let toMemberId: String
      let amount: Int64
    }

    let currency: String
    let minimized: Bool
    let balances: [RawBalance]
    let transfers: [RawTransfer]

    func toDomain() -> GroupBalances {
      GroupBalances(
        currency: currency,
        minimized: minimized,
        balances: balances.map {
          Balance(memberId: Member.ID($0.memberId), balance: Money($0.balance))
        },
        transfers: transfers.map {
          SuggestedTransfer(
            fromMemberId: Member.ID($0.fromMemberId),
            toMemberId: Member.ID($0.toMemberId),
            amount: Money($0.amount)
          )
        }
      )
    }
  }

  static func decodeResilientBalances(from data: Data) throws -> GroupBalances {
    try JSONDecoder().decode(RawBalancesResponse.self, from: data).toDomain()
  }

  static func encodeBalancesSnapshot(_ value: GroupBalances) -> Data? {
    let payload = RawBalancesResponse(
      currency: value.currency,
      minimized: value.minimized,
      balances: value.balances.map {
        RawBalancesResponse.RawBalance(
          memberId: $0.memberId.rawValue,
          balance: $0.balance.amount
        )
      },
      transfers: value.transfers.map {
        RawBalancesResponse.RawTransfer(
          fromMemberId: $0.fromMemberId.rawValue,
          toMemberId: $0.toMemberId.rawValue,
          amount: $0.amount.amount
        )
      }
    )
    return try? JSONEncoder().encode(payload)
  }
}
