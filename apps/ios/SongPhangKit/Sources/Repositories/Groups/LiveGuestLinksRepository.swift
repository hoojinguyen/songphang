public import Domain
public import Foundation
import GeneratedAPI

public final class LiveGuestLinksRepository: GuestLinksRepository, Sendable {
  private let environment: LiveAPIEnvironment

  public init(environment: LiveAPIEnvironment) {
    self.environment = environment
  }

  public func status(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_guest_hyphen_link(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return Self.mapGuestLink(try ok.body.json.guestLink)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func createOrRotate(
    groupId: ExpenseGroup.ID,
    rotate: Bool
  ) async throws(AppError) -> GuestLink {
    do {
      let output = try await environment.client
        .post_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_guest_hyphen_link(
          .init(
            path: .init(groupId: groupId.rawValue),
            body: .json(.init(rotate: rotate))
          )
        )
      switch output {
      case .ok(let ok):
        return Self.mapGuestLink(try ok.body.json.guestLink)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func revoke(groupId: ExpenseGroup.ID) async throws(AppError) -> GuestLink {
    do {
      let output = try await environment.client
        .delete_sol_api_sol_v1_sol_groups_sol__lcub_groupId_rcub__sol_guest_hyphen_link(
          .init(path: .init(groupId: groupId.rawValue))
        )
      switch output {
      case .ok(let ok):
        return Self.mapGuestLink(try ok.body.json.guestLink)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(statusCode: status, payload: payload)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func fetchGuestGroup(
    token: String,
    cycleId: TransactionCycleFilter?,
    cursor: String?,
    limit: Int
  ) async throws(AppError) -> GuestGroupSnapshot {
    let queryCycle:
      Operations.get_sol_api_sol_v1_sol_guest_hyphen_links_sol__lcub_token_rcub_.Input.Query
        .cycleIdPayload? =
        cycleId.map { selection in
          switch selection {
          case .current: return .init(value1: .current)
          case .cycle(let id): return .init(value2: id.rawValue)
          }
        }
    do {
      let output = try await environment.client
        .get_sol_api_sol_v1_sol_guest_hyphen_links_sol__lcub_token_rcub_(
          .init(
            path: .init(token: token),
            query: .init(cycleId: queryCycle, cursor: cursor, limit: limit)
          )
        )
      switch output {
      case .ok(let ok):
        return Self.mapGuestGroup(try ok.body.json)
      case .undocumented(let status, let payload):
        throw await environment.errorMapper.mapUndocumented(
          statusCode: status,
          payload: payload,
          clearSessionOnUnauthorized: false
        )
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  public func fetchGuestAttachmentData(
    token: String,
    attachmentId: Attachment.ID
  ) async throws(AppError) -> Data {
    let url = environment.configuration.apiBaseURL
      .appendingPathComponent("guest-links")
      .appendingPathComponent(token)
      .appendingPathComponent("attachments")
      .appendingPathComponent(attachmentId.rawValue)

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(environment.configuration.appVersion, forHTTPHeaderField: "X-App-Version")

    do {
      let (data, response) = try await environment.urlSession.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw AppError.unexpected
      }
      guard (200..<300).contains(http.statusCode) else {
        let code = (try? JSONDecoder().decode(APIErrorPayload.self, from: data))?.error.code
        throw await environment.errorMapper.mapStatus(
          statusCode: http.statusCode,
          code: code,
          clearSessionOnUnauthorized: false
        )
      }
      return data
    } catch let error as AppError {
      throw error
    } catch {
      throw environment.errorMapper.mapTransportError(error)
    }
  }

  private static func mapGuestLink(_ dto: Components.Schemas.GuestLinkDto) -> GuestLink {
    GuestLink(
      active: dto.active,
      url: dto.url,
      createdAt: dto.createdAt.map(LiveSettlementCyclesRepository.formatISO)
    )
  }

  private static func mapGuestGroup(
    _ dto: Components.Schemas.GuestGroupViewResponse
  ) -> GuestGroupSnapshot {
    let selectedCycle: TransactionCycleFilter = {
      if let id = dto.selectedCycleId.value2 {
        return .cycle(SettlementCycle.ID(id))
      }
      return .current
    }()

    return GuestGroupSnapshot(
      group: GuestGroupInfo(
        id: ExpenseGroup.ID(dto.group.id),
        name: dto.group.name,
        currency: dto.group.currency.rawValue,
        minimized: dto.group.minimized,
        archivedAt: dto.group.archivedAt.map(LiveSettlementCyclesRepository.formatISO)
      ),
      members: dto.members.map {
        GuestMember(
          id: Member.ID($0.id),
          name: $0.name,
          kind: MemberKind(code: $0.kind.rawValue),
          active: $0.active,
          shape: MemberShape(code: $0.shape.rawValue),
          color: MemberColor(code: $0.color.rawValue)
        )
      },
      cycles: dto.cycles.map(LiveSettlementCyclesRepository.mapCycle),
      selectedCycleId: selectedCycle,
      currentPeriod: LiveSettlementCyclesRepository.mapCurrentPeriod(dto.currentPeriod),
      balances: dto.balances.map {
        Balance(memberId: Member.ID($0.memberId), balance: Money(Int64($0.balance)))
      },
      transfers: dto.transfers.map {
        GuestTransfer(
          fromMemberId: Member.ID($0.fromMemberId),
          toMemberId: Member.ID($0.toMemberId),
          amount: Money(Int64($0.amount)),
          purpose: $0.purpose,
          paymentMethods: $0.payTo.map(mapGuestPaymentMethod)
        )
      },
      fund: dto.fund.map(BalanceMapping.mapFund),
      resolvedFocus: LiveMemberBreakdownsMapping.mapResolvedFocus(dto.resolvedFocus),
      breakdowns: dto.breakdowns.map(LiveMemberBreakdownsMapping.mapBreakdown),
      transactions: Page(
        items: dto.transactions.items.map(mapGuestTransaction),
        nextCursor: dto.transactions.nextCursor
      )
    )
  }

  private static func mapGuestPaymentMethod(
    _ method: Components.Schemas.GuestGroupViewResponse.transfersPayloadPayload.payToPayloadPayload
  ) -> PaymentMethod {
    switch method {
    case .case1(let bank):
      .bank(
        BankPayment(
          bin: bank.bankBin,
          name: bank.bankShortName,
          accountNumber: bank.accountNumber,
          accountName: bank.accountName,
          qrPayload: bank.qrPayload,
          accountQrPayload: bank.accountQrPayload
        )
      )
    case .case2(let wallet):
      .momo(phone: wallet.phone)
    case .case3(let wallet):
      .zalopay(phone: wallet.phone)
    }
  }

  private static func mapGuestTransaction(
    _ dto: Components.Schemas.GuestTransactionDto
  ) -> GuestTransaction {
    GuestTransaction(
      id: LedgerTransaction.ID(dto.id),
      type: TransactionType(code: dto._type.rawValue),
      description: dto.description,
      amount: Money(Int64(dto.amount)),
      currency: dto.currency.rawValue,
      occurredAt: LiveSettlementCyclesRepository.formatISO(dto.occurredAt),
      category: TransactionMapping.mapCategory(dto.category?.rawValue),
      categoryId: dto.categoryId.map(GroupCategory.ID.init),
      categoryName: dto.categoryName,
      categoryColor: dto.categoryColor.map { MemberColor(code: $0.rawValue) },
      payers: dto.payers.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      shares: dto.shares.map {
        MemberAmount(memberId: Member.ID($0.memberId), amount: Money(Int64($0.amount)))
      },
      split: TransactionMapping.mapSplitInput(dto.split),
      paymentChannel: LiveSettlementVaultMapping.mapPaymentChannel(dto.paymentChannel),
      paymentNote: dto.paymentNote,
      cycleId: dto.cycleId.map(SettlementCycle.ID.init),
      attachments: dto.attachments.map(ReceiptMapping.mapAttachment)
    )
  }
}
