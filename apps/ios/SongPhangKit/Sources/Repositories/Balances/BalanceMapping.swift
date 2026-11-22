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
          amount: Money(Int64($0.amount)),
          paymentMethods: $0.payTo.map(mapPaymentMethod),
          purpose: $0.purpose,
          pendingSettlement: $0.pendingRequest.map {
            PendingSettlement(
              id: $0.id,
              amount: Money(Int64($0.amount)),
              createdByMe: $0.createdByMe
            )
          }
        )
      },
      fund: dto.fund.map(mapFund)
    )
  }

  static func mapFund(_ dto: Components.Schemas.FundSummary) -> FundSummary {
    FundSummary(
      memberId: Member.ID(dto.memberId),
      name: dto.name,
      holderMemberId: dto.holderMemberId.map(Member.ID.init),
      active: dto.active,
      cash: Money(Int64(dto.cash)),
      contributions: dto.contributions.map {
        FundContribution(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      }
    )
  }

  private static func mapPaymentMethod(
    _ method: Components.Schemas.BalancesResponse.transfersPayloadPayload.payToPayloadPayload
  ) -> PaymentMethod {
    switch method {
    case .case1(let bank):
      .bank(
        BankPayment(
          bin: bank.bankBin,
          name: bank.bankShortName,
          accountNumber: bank.accountNumber,
          accountName: bank.accountName,
          qrPayload: bank.qrPayload
        )
      )
    case .case2(let wallet):
      .momo(phone: wallet.phone)
    case .case3(let wallet):
      .zalopay(phone: wallet.phone)
    }
  }

  struct RawPaymentMethod: Codable, Sendable {
    let kind: String
    let bankBin: String?
    let bankShortName: String?
    let accountNumber: String?
    let accountName: String?
    let qrPayload: String?
    let phone: String?

    init(method: PaymentMethod) {
      switch method {
      case .bank(let bank):
        self.kind = "bank"
        self.bankBin = bank.bin
        self.bankShortName = bank.name
        self.accountNumber = bank.accountNumber
        self.accountName = bank.accountName
        self.qrPayload = bank.qrPayload
        self.phone = nil
      case .momo(let phone):
        self.kind = "momo"
        self.bankBin = nil
        self.bankShortName = nil
        self.accountNumber = nil
        self.accountName = nil
        self.qrPayload = nil
        self.phone = phone
      case .zalopay(let phone):
        self.kind = "zalopay"
        self.bankBin = nil
        self.bankShortName = nil
        self.accountNumber = nil
        self.accountName = nil
        self.qrPayload = nil
        self.phone = phone
      }
    }

    func toDomain() -> PaymentMethod? {
      switch kind {
      case "bank":
        guard let bankBin, let bankShortName, let accountNumber, let accountName else {
          return nil
        }
        return .bank(
          BankPayment(
            bin: bankBin,
            name: bankShortName,
            accountNumber: accountNumber,
            accountName: accountName,
            qrPayload: qrPayload
          )
        )
      case "momo":
        guard let phone else { return nil }
        return .momo(phone: phone)
      case "zalopay":
        guard let phone else { return nil }
        return .zalopay(phone: phone)
      default:
        return nil
      }
    }
  }

  struct RawPendingSettlement: Codable, Sendable {
    let id: String
    let amount: Int64
    let createdByMe: Bool
  }

  struct RawFundContribution: Codable, Sendable {
    let memberId: String
    let amount: Int64
  }

  struct RawFundSummary: Codable, Sendable {
    let memberId: String
    let name: String
    let holderMemberId: String?
    let active: Bool
    let cash: Int64
    let contributions: [RawFundContribution]

    init(fund: FundSummary) {
      self.memberId = fund.memberId.rawValue
      self.name = fund.name
      self.holderMemberId = fund.holderMemberId?.rawValue
      self.active = fund.active
      self.cash = fund.cash.amount
      self.contributions = fund.contributions.map {
        RawFundContribution(memberId: $0.memberId.rawValue, amount: $0.amount.amount)
      }
    }

    func toDomain() -> FundSummary {
      FundSummary(
        memberId: Member.ID(memberId),
        name: name,
        holderMemberId: holderMemberId.map(Member.ID.init),
        active: active,
        cash: Money(cash),
        contributions: contributions.map {
          FundContribution(memberId: Member.ID($0.memberId), amount: Money($0.amount))
        }
      )
    }
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
      let payTo: [RawPaymentMethod]?
      let purpose: String?
      let pendingRequest: RawPendingSettlement?
    }

    let currency: String
    let minimized: Bool
    let balances: [RawBalance]
    let transfers: [RawTransfer]
    let fund: RawFundSummary?

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
            amount: Money($0.amount),
            paymentMethods: ($0.payTo ?? []).compactMap { $0.toDomain() },
            purpose: $0.purpose,
            pendingSettlement: $0.pendingRequest.map {
              PendingSettlement(
                id: $0.id,
                amount: Money($0.amount),
                createdByMe: $0.createdByMe
              )
            }
          )
        },
        fund: fund?.toDomain()
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
          amount: $0.amount.amount,
          payTo: $0.paymentMethods.map(RawPaymentMethod.init),
          purpose: $0.purpose,
          pendingRequest: $0.pendingSettlement.map {
            RawPendingSettlement(
              id: $0.id,
              amount: $0.amount.amount,
              createdByMe: $0.createdByMe
            )
          }
        )
      },
      fund: value.fund.map(RawFundSummary.init)
    )
    return try? JSONEncoder().encode(payload)
  }
}
