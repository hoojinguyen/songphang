public import Domain
public import SwiftUI

public enum ShareCardMode: String, Sendable, Hashable, CaseIterable {
  case summary
  case reminder
}

public struct ShareCardContent: Sendable, Equatable {
  public struct HouseholdRow: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let representativeName: String
    public let balance: Money

    public init(id: String, name: String, representativeName: String, balance: Money) {
      self.id = id
      self.name = name
      self.representativeName = representativeName
      self.balance = balance
    }
  }

  public struct BalanceRow: Sendable, Equatable, Identifiable {
    public var id: String { name + "-\(balance.amount)" }
    public let name: String
    public let shape: MemberShape
    public let color: MemberColor
    public let balance: Money

    public init(name: String, shape: MemberShape, color: MemberColor, balance: Money) {
      self.name = name
      self.shape = shape
      self.color = color
      self.balance = balance
    }
  }

  public struct TransferRow: Sendable, Equatable, Identifiable {
    public var id: String { "\(fromName)->\(toName)-\(amount.amount)" }
    public let fromName: String
    public let toName: String
    public let amount: Money
    public let purpose: String
    public let paymentMethods: [PaymentMethod]

    public init(
      fromName: String,
      toName: String,
      amount: Money,
      purpose: String,
      paymentMethods: [PaymentMethod]
    ) {
      self.fromName = fromName
      self.toName = toName
      self.amount = amount
      self.purpose = purpose
      self.paymentMethods = paymentMethods
    }
  }

  public struct ExpenseRow: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let payerName: String
    public let amount: Money

    public init(id: String = UUID().uuidString, title: String, payerName: String, amount: Money) {
      self.id = id
      self.title = title
      self.payerName = payerName
      self.amount = amount
    }
  }

  public struct SummaryBankDetails: Sendable, Equatable {
    public let receiverName: String
    public let bankShortName: String
    public let accountNumber: String
    public let accountName: String
    public let accountQrPayload: String

    public init(
      receiverName: String,
      bankShortName: String,
      accountNumber: String,
      accountName: String,
      accountQrPayload: String
    ) {
      self.receiverName = receiverName
      self.bankShortName = bankShortName
      self.accountNumber = accountNumber
      self.accountName = accountName
      self.accountQrPayload = accountQrPayload
    }
  }

  public let mode: ShareCardMode
  public let groupName: String
  public let periodLabel: String
  public let dateRangeLabel: String
  public let totalExpense: Money
  public let expenseCount: Int
  public let balances: [BalanceRow]
  public let households: [HouseholdRow]
  public let transfers: [TransferRow]
  public let debtorAllocationTransfers: [TransferRow]
  public let isSingleTransferReminder: Bool
  public let includeExpenses: Bool
  public let recentExpenses: [ExpenseRow]
  public let targetBreakdown: MemberDebtBreakdown?
  public let customCaption: String
  public let guestShareURL: String?
  public let summaryBankDetails: SummaryBankDetails?

  public init(
    mode: ShareCardMode,
    groupName: String,
    periodLabel: String,
    dateRangeLabel: String,
    totalExpense: Money,
    expenseCount: Int,
    balances: [BalanceRow],
    households: [HouseholdRow] = [],
    transfers: [TransferRow],
    debtorAllocationTransfers: [TransferRow] = [],
    isSingleTransferReminder: Bool = false,
    includeExpenses: Bool,
    recentExpenses: [ExpenseRow],
    targetBreakdown: MemberDebtBreakdown? = nil,
    customCaption: String = "",
    guestShareURL: String? = nil,
    summaryBankDetails: SummaryBankDetails? = nil
  ) {
    self.mode = mode
    self.groupName = groupName
    self.periodLabel = periodLabel
    self.dateRangeLabel = dateRangeLabel
    self.totalExpense = totalExpense
    self.expenseCount = expenseCount
    self.balances = balances
    self.households = households
    self.transfers = transfers
    self.debtorAllocationTransfers = debtorAllocationTransfers
    self.isSingleTransferReminder = isSingleTransferReminder
    self.includeExpenses = includeExpenses
    self.recentExpenses = recentExpenses
    self.targetBreakdown = targetBreakdown
    self.customCaption = customCaption
    self.guestShareURL = guestShareURL
    self.summaryBankDetails = summaryBankDetails
  }
}

public struct ShareCardCanvasView: View {
  private let content: ShareCardContent

  public init(content: ShareCardContent) {
    self.content = content
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      headerCard

      switch content.mode {
      case .summary:
        summaryBody
      case .reminder:
        reminderBody
      }

      if !content.customCaption.isEmpty {
        captionCard
      }

      if let guestURL = content.guestShareURL, !guestURL.isEmpty {
        guestFooter(url: guestURL)
      }
    }
    .padding(20)
    .frame(width: 390, alignment: .leading)
    .background(Tokens.bg)
  }

  private var headerCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        Text(L10n.tr("common.appName"))
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.onAccent)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Tokens.accent, in: Capsule())

        Text(content.periodLabel)
          .font(Typography.captionBold)
          .foregroundStyle(Tokens.ink)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Tokens.sunken, in: Capsule())
      }

      Text(content.groupName)
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)

      HStack {
        Text(content.dateRangeLabel)
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
        Spacer()
        Text("\(content.expenseCount) \(L10n.tr("groupSegments.expenses").lowercased())")
          .font(Typography.captionBold)
          .monospacedDigit()
          .foregroundStyle(Tokens.muted)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  @ViewBuilder
  private var summaryBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(L10n.tr("shareCard.modeSummary"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)
      MoneyText(
        content.totalExpense,
        style: .full,
        font: Typography.heroNumber,
        color: Tokens.ink
      )
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

    if !content.balances.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        Text(L10n.tr("balances.groupBalanceTitle"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)

        ForEach(content.balances) { row in
          HStack(spacing: 8) {
            MemberShapeView(
              shape: row.shape,
              color: row.color,
              name: row.name,
              size: 24,
              showInitial: false
            )
            Text(row.name)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            Spacer()
            MoneyText(
              row.balance,
              style: .signed,
              font: Typography.captionBold,
              color: row.balance.isPositive
                ? Tokens.credit
                : (row.balance.isNegative ? Tokens.debt : Tokens.ink)
            )
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    if !content.households.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        Text(L10n.tr("households.byHouseholdTitle"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)

        ForEach(content.households) { hh in
          HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
              Text(hh.name)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
              if !hh.representativeName.isEmpty {
                Text(L10n.t("households.representativeBadge", ["name": hh.representativeName]))
                  .font(Typography.caption)
                  .foregroundStyle(Tokens.muted)
              }
            }
            Spacer()
            MoneyText(
              hh.balance,
              style: .signed,
              font: Typography.captionBold,
              color: hh.balance.isPositive
                ? Tokens.credit
                : (hh.balance.isNegative ? Tokens.debt : Tokens.ink)
            )
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    if !content.transfers.isEmpty {
      transfersListCard(
        title: L10n.tr("balances.subTabs.toPay"),
        transfers: content.transfers,
        showExactQR: false,
        showPaymentSummaryLines: content.summaryBankDetails == nil
      )
    }

    if content.includeExpenses && !content.recentExpenses.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.tr("groupSegments.expenses"))
          .font(Typography.subheadlineBold)
          .foregroundStyle(Tokens.ink)

        ForEach(content.recentExpenses.prefix(15)) { expense in
          HStack {
            VStack(alignment: .leading, spacing: 1) {
              Text(expense.title)
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)
              Text(expense.payerName)
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
            Spacer(minLength: 8)
            MoneyText(
              expense.amount,
              style: .full,
              font: Typography.captionBold,
              color: Tokens.ink
            )
          }
        }

        if content.recentExpenses.count > 15 {
          Text("+\(content.recentExpenses.count - 15)")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    if let details = content.summaryBankDetails {
      HStack(spacing: 12) {
        QRCodeMatrixView(
          payload: details.accountQrPayload,
          size: 88,
          accessibilityLabel: details.bankShortName
        )
        VStack(alignment: .leading, spacing: 3) {
          Text(details.receiverName)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Text(details.bankShortName)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
          Text(details.accountNumber)
            .font(Typography.caption)
            .foregroundStyle(Tokens.ink)
          Text(details.accountName)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
  }

  @ViewBuilder
  private var reminderBody: some View {
    if let breakdown = content.targetBreakdown {
      breakdownSummaryCard(breakdown: breakdown)

      if let targeted = content.transfers.first,
        abs(breakdown.netBalance.amount) != targeted.amount.amount,
        !content.debtorAllocationTransfers.isEmpty
      {
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("breakdown.transferAllocation"))
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          ForEach(content.debtorAllocationTransfers) { allocation in
            HStack {
              Text("\(allocation.fromName) → \(allocation.toName)")
                .font(Typography.captionBold)
                .foregroundStyle(Tokens.ink)
              Spacer(minLength: 8)
              MoneyText(
                allocation.amount,
                style: .full,
                font: Typography.captionBold,
                color: Tokens.ink
              )
            }
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
    }

    if !content.transfers.isEmpty {
      transfersListCard(
        title: L10n.tr("balances.subTabs.toPay"),
        transfers: content.transfers,
        showExactQR: content.isSingleTransferReminder,
        showPaymentSummaryLines: !content.isSingleTransferReminder
      )
    }

    if !content.isSingleTransferReminder, let details = content.summaryBankDetails {
      HStack(spacing: 12) {
        QRCodeMatrixView(
          payload: details.accountQrPayload,
          size: 88,
          accessibilityLabel: details.bankShortName
        )
        VStack(alignment: .leading, spacing: 3) {
          Text(details.receiverName)
            .font(Typography.subheadlineBold)
            .foregroundStyle(Tokens.ink)
          Text(details.bankShortName)
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.ink)
          Text(details.accountNumber)
            .font(Typography.caption)
            .foregroundStyle(Tokens.ink)
          Text(details.accountName)
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
  }

  private func breakdownSummaryCard(breakdown: MemberDebtBreakdown) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        MemberShapeView(
          shape: breakdown.shape,
          color: breakdown.color,
          name: breakdown.memberName,
          size: 36
        )
        VStack(alignment: .leading, spacing: 2) {
          Text(breakdown.memberName)
            .font(Typography.bodyBold)
            .foregroundStyle(Tokens.ink)
          Text(L10n.tr("breakdown.currentBalance"))
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
        }
        Spacer()
        MoneyText(
          breakdown.netBalance,
          style: .signed,
          font: Typography.sectionTitle,
          color: breakdown.netBalance.isNegative ? Tokens.debt : Tokens.credit
        )
      }

      if !breakdown.carryOverBalance.isZero {
        HStack {
          Text(L10n.tr("breakdown.carryOver"))
            .font(Typography.caption)
            .foregroundStyle(Tokens.muted)
          Spacer()
          MoneyText(
            breakdown.carryOverBalance,
            style: .signed,
            font: Typography.captionBold,
            color: Tokens.ink
          )
        }
      }

      if !breakdown.lines.isEmpty {
        Divider().overlay(Tokens.borderSubtle)
        ForEach(breakdown.lines.prefix(12)) { line in
          HStack {
            Text(line.description)
              .font(Typography.caption)
              .foregroundStyle(Tokens.ink)
              .lineLimit(1)
            Spacer(minLength: 8)
            MoneyText(
              line.delta,
              style: .signed,
              font: Typography.captionBold,
              color: line.delta.isNegative ? Tokens.debt : Tokens.credit
            )
          }
        }
        if breakdown.lines.count > 12 {
          Text("+\(breakdown.lines.count - 12)")
            .font(Typography.captionBold)
            .foregroundStyle(Tokens.muted)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  private func transfersListCard(
    title: String,
    transfers: [ShareCardContent.TransferRow],
    showExactQR: Bool,
    showPaymentSummaryLines: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(Typography.subheadlineBold)
        .foregroundStyle(Tokens.ink)

      ForEach(transfers) { transfer in
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("\(transfer.fromName) → \(transfer.toName)")
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            Spacer(minLength: 8)
            MoneyText(
              transfer.amount,
              style: .full,
              font: Typography.subheadlineBold,
              color: Tokens.ink
            )
          }

          if showExactQR {
            exactPaymentDetails(for: transfer)
          } else if showPaymentSummaryLines {
            compactPaymentSummary(for: transfer)
          }
        }
        .padding(10)
        .background(Tokens.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  @ViewBuilder
  private func exactPaymentDetails(for transfer: ShareCardContent.TransferRow) -> some View {
    ForEach(Array(transfer.paymentMethods.prefix(2).enumerated()), id: \.offset) { _, method in
      switch method {
      case .bank(let bank):
        HStack(spacing: 10) {
          if let payload = bank.qrPayload ?? bank.accountQrPayload {
            QRCodeMatrixView(payload: payload, size: 84, accessibilityLabel: bank.name)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(transfer.toName)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            Text(bank.name)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.ink)
            Text(bank.accountNumber)
              .font(Typography.caption)
              .foregroundStyle(Tokens.ink)
            Text(bank.accountName)
              .font(Typography.caption)
              .foregroundStyle(Tokens.muted)
            if !transfer.purpose.isEmpty {
              Text("\(L10n.tr("pay.purpose")): \(transfer.purpose)")
                .font(Typography.caption)
                .foregroundStyle(Tokens.muted)
            }
          }
        }
      case .momo(let phone):
        Text(L10n.t("pay.momoRow", ["phone": phone]))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      case .zalopay(let phone):
        Text(L10n.t("pay.zalopayRow", ["phone": phone]))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
    }
  }

  @ViewBuilder
  private func compactPaymentSummary(for transfer: ShareCardContent.TransferRow) -> some View {
    ForEach(Array(transfer.paymentMethods.prefix(2).enumerated()), id: \.offset) { _, method in
      switch method {
      case .bank(let bank):
        Text("\(bank.name) · \(bank.accountNumber) · \(bank.accountName)")
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      case .momo(let phone):
        Text(L10n.t("pay.momoRow", ["phone": phone]))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      case .zalopay(let phone):
        Text(L10n.t("pay.zalopayRow", ["phone": phone]))
          .font(Typography.caption)
          .foregroundStyle(Tokens.muted)
      }
    }
  }

  private var captionCard: some View {
    Text(content.customCaption)
      .font(Typography.subheadlineBold)
      .foregroundStyle(Tokens.onAccent)
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Tokens.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private func guestFooter(url: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(L10n.tr("guestLink.fullTitle"))
        .font(Typography.captionBold)
        .foregroundStyle(Tokens.muted)
      Text(url)
        .font(Typography.caption)
        .foregroundStyle(Tokens.ink)
        .lineLimit(2)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}
