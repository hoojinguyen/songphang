import DesignSystem
public import Domain
public import SwiftUI

#if DEBUG
  import PreviewSupport
#endif

public struct PersonalLedgerView: View {
  @Bindable private var model: PersonalLedgerModel
  private let onBack: () -> Void
  private let onOpenTransaction: (ExpenseGroup.ID, LedgerTransaction.ID) -> Void

  public init(
    model: PersonalLedgerModel,
    onBack: @escaping () -> Void,
    onOpenTransaction: @escaping (ExpenseGroup.ID, LedgerTransaction.ID) -> Void
  ) {
    self.model = model
    self.onBack = onBack
    self.onOpenTransaction = onOpenTransaction
  }

  public var body: some View {
    VStack(spacing: 0) {
      SPScreenHeader(
        title: L10n.tr("ledger.title"),
        onBack: onBack
      )
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 12)

      searchAndFiltersBar
        .padding(.horizontal, 20)
        .padding(.bottom, 12)

      ScrollView {
        LazyVStack(spacing: 12) {
          if model.isLoading && model.items.isEmpty {
            LoadingSkeleton(rowCount: 5, rowHeight: 76)
              .padding(.top, 12)
          } else if model.items.isEmpty {
            emptyView
          } else {
            itemsList
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
      .refreshable {
        await model.loadInitial()
      }
    }
    .background(Tokens.bg.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .task {
      if model.items.isEmpty {
        await model.loadInitial()
      }
    }
  }

  private var searchAndFiltersBar: some View {
    VStack(spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Tokens.muted)

        TextField(L10n.tr("ledger.searchPlaceholder"), text: $model.query)
          .font(Typography.body)
          .foregroundStyle(Tokens.ink)
          .onSubmit {
            Task { await model.loadInitial() }
          }

        if !model.query.isEmpty {
          Button {
            model.query = ""
            Task { await model.loadInitial() }
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(Tokens.muted)
          }
        }
      }
      .padding(.horizontal, 16)
      .frame(height: 44)
      .background(Tokens.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          typeFilterChip(title: L10n.tr("common.all"), type: nil)
          typeFilterChip(title: L10n.tr("common.expense"), type: .expense)
          typeFilterChip(title: L10n.tr("common.income"), type: .income)
          typeFilterChip(title: L10n.tr("common.transfer"), type: .transfer)
        }
      }
    }
  }

  private func typeFilterChip(title: String, type: TransactionType?) -> some View {
    let isSelected = model.selectedType == type
    return Button {
      Task {
        await model.updateFilters(type: .some(type))
      }
    } label: {
      Text(title)
        .font(Typography.captionBold)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Tokens.accent : Tokens.surface)
        .foregroundStyle(Tokens.ink)
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  private var emptyView: some View {
    VStack(spacing: 12) {
      Text(L10n.tr("overview.emptyTransactions"))
        .font(Typography.sectionTitle)
        .foregroundStyle(Tokens.ink)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }

  private var itemsList: some View {
    ForEach(model.items) { tx in
      Button {
        onOpenTransaction(tx.groupId, tx.transactionId)
      } label: {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(tx.groupName)
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)

            Text(tx.description)
              .font(Typography.bodyBold)
              .foregroundStyle(Tokens.ink)
              .lineLimit(1)
          }

          Spacer(minLength: 8)

          if tx.myDelta.isZero {
            Text(L10n.tr("ledger.notParticipating"))
              .font(Typography.captionBold)
              .foregroundStyle(Tokens.muted)
          } else {
            MoneyText(
              tx.myDelta,
              style: .signed,
              font: Typography.subheadlineBold,
              color: tx.myDelta.isPositive
                ? Tokens.credit
                : (tx.myDelta.isNegative ? Tokens.debt : Tokens.ink)
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      }
      .buttonStyle(.plain)
      .onAppear {
        if tx.id == model.items.last?.id && model.hasMore {
          Task { await model.loadMore() }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("PersonalLedger") {
    let world = FakeWorld(preset: .tripStep4)
    PersonalLedgerView(
      model: PersonalLedgerModel(repository: FakeOverviewRepository(world: world)),
      onBack: {},
      onOpenTransaction: { _, _ in }
    )
  }
#endif
