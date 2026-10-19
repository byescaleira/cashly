import CashlyAnalytics
import CashlyDomain
import CashlyGame
import Foundation

extension WebSnapshot {
    mutating func addSections(
        repositories: Repositories, context: Context, overview: CashlyOverview,
        catalog: CashlySnapshot
    ) async {
        let month = YearMonth(context.today)
        let game = await Self.game(repositories: repositories, context: context)
        var ledger = game?.ledger
        if ledger == nil {
            ledger = try? await RepositoriesLedgerSource(repositories: repositories)
                .ledger(today: context.today)
        }
        if let ledger {
            daily = Self.daily(ledger, month: month)
            forecast = Forecast(ledger)
        }
        categories = Self.categories(overview, catalog: catalog.categories)
        tags = Self.tags(overview, catalog: catalog.tags)
        if let months = try? await Self.months(
            repositories.dashboard, month: month, current: overview)
        {
            history = months.map { MonthTotals(month: $0.month, overview: $0.overview) }
            savings = Savings(overview, months: months.map(\.overview))
        }
        score = Score(overview)
        journey = game.map { Journey(GameEngine.progress($0), context: context) }
    }

    static func game(repositories: Repositories, context: Context) async -> GameSnapshot? {
        guard context.includesJourney else { return nil }
        return try? await RepositoriesGameSource(repositories: repositories, guides: context.guides)
            .snapshot(today: context.today)
    }

    static func daily(_ ledger: LedgerSnapshot, month: YearMonth) -> [Day] {
        let calendar = CashlyCalendar.current
        let today = min(calendar.component(.day, from: ledger.today), month.dayCount)
        let totals = (0...today).map { ledger.spent(in: month, throughDay: $0) }
        return (1...today).map { day in
            Day(
                date: WebDay.string(
                    calendar.date(byAdding: .day, value: day - 1, to: month.startDate)
                        ?? month.startDate),
                spent: Money(minorUnits: totals[day] - totals[day - 1]).doubleValue)
        }
    }

    static func categories(_ overview: CashlyOverview, catalog: [CashlyDomain.Category])
        -> [CategorySpending]?
    {
        let total = overview.expensesTotal.minorUnits
        guard total > 0 else { return nil }
        let known = Dictionary(
            catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let shown = overview.categoryExpenses
            .compactMap { id, money in
                known[id].flatMap { money.minorUnits > 0 ? ($0, money.minorUnits) : nil }
            }
            .sorted { ($0.1, $1.0.name) > ($1.1, $0.0.name) }
            .prefix(categoryLimit)
        var items = shown.map { category, spent in
            CategorySpending(
                name: category.name, symbol: category.icon,
                color: WebPalette.name(for: category.color), spent: spent, total: total)
        }
        let rest = total - shown.reduce(0) { $0 + $1.1 }
        if rest > 0 {
            items.append(
                CategorySpending(
                    name: String(appLocalized: "Other"), symbol: otherSymbol, color: otherColor,
                    spent: rest, total: total))
        }
        return items.isEmpty ? nil : items
    }

    static func tags(_ overview: CashlyOverview, catalog: [Tag]) -> [TagSpending]? {
        let items =
            catalog
            .compactMap { tag -> (Tag, Int64)? in
                let spent = overview.tagExpenses[tag.id, default: .zero].minorUnits
                return spent > 0 ? (tag, spent) : nil
            }
            .sorted { ($0.1, $1.0.name) > ($1.1, $0.0.name) }
            .prefix(tagLimit)
            .map { tag, spent in
                TagSpending(
                    name: tag.name, spent: Money(minorUnits: spent).doubleValue,
                    count: overview.tagCounts[tag.id, default: 0])
            }
        return items.isEmpty ? nil : Array(items)
    }

    static func months(
        _ dashboard: any DashboardRepository, month: YearMonth, current: CashlyOverview
    ) async throws -> [(month: YearMonth, overview: CashlyOverview)] {
        var items: [(month: YearMonth, overview: CashlyOverview)] = []
        for offset in (1..<historyLength).reversed() {
            let past = month.adding(months: -offset)
            items.append((past, try await dashboard.overview(query: TransactionQuery(month: past))))
        }
        items.append((month, current))
        let first = items.firstIndex { !$0.overview.isEmpty } ?? items.count - 1
        return Array(items[first...])
    }
}

extension WebSnapshot.CategorySpending {
    init(name: String, symbol: String, color: String, spent: Int64, total: Int64) {
        self.init(
            name: name, symbol: symbol, color: color, spent: Money(minorUnits: spent).doubleValue,
            share: WebSnapshot.Month.rounded(Double(spent) / Double(total)))
    }
}

extension WebSnapshot.Forecast {
    init?(_ ledger: LedgerSnapshot) {
        let planned = ledger.budgeted(in: ledger.currentMonth)
        guard planned > 0, let projection = MonthPace.projection(ledger) else { return nil }
        let gap = projection.projected - planned
        self.init(
            spent: Money(minorUnits: projection.projected).doubleValue,
            available: Money(minorUnits: -gap).doubleValue,
            outcome: gap > 0 ? .over : gap < 0 ? .under : .onPlan,
            planned: Money(minorUnits: planned).doubleValue)
    }
}

extension WebSnapshot.MonthTotals {
    init(month: YearMonth, overview: CashlyOverview) {
        self.init(
            month: String(format: "%04d-%02d", month.year, month.month),
            planned: overview.budgetsTotal.doubleValue, spent: overview.expensesTotal.doubleValue,
            income: overview.incomeTotal.doubleValue)
    }
}

extension WebSnapshot.Savings {
    init?(_ overview: CashlyOverview, months: [CashlyOverview]) {
        guard let rate = overview.savingRate else { return nil }
        let rates = months.compactMap(\.savingRate)
        self.init(
            saved: overview.netTotal.doubleValue, rate: WebSnapshot.Month.rounded(rate),
            averageRate: WebSnapshot.Month.rounded(
                rates.reduce(0, +) / Double(max(rates.count, 1))))
    }
}

extension WebSnapshot.Score {
    init(_ overview: CashlyOverview) {
        let health = BudgetHealth(
            usage: BudgetUsage(spent: overview.expensesTotal, budgeted: overview.budgetsTotal))
        self.init(
            value: health.score, max: BudgetHealth.maximumScore, label: health.level.title,
            detail: health.level.summary)
    }
}

extension CashlyOverview {
    var isEmpty: Bool {
        budgetsTotal.minorUnits == 0 && expensesTotal.minorUnits == 0
            && incomeTotal.minorUnits == 0
    }

    var savingRate: Double? {
        incomeTotal.minorUnits > 0
            ? Double(netTotal.minorUnits) / Double(incomeTotal.minorUnits) : nil
    }
}
