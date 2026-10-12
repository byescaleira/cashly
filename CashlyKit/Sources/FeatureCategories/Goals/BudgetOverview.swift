import CashlyDomain
import Foundation

public struct BudgetProgress: Identifiable, Hashable, Sendable {
    public enum Group: Int, CaseIterable, Sendable {
        case over, attention, onTrack, untouched

        var title: String {
            switch self {
            case .over: "Passaram do limite"
            case .attention: "Perto do limite"
            case .onTrack: "No caminho"
            case .untouched: "Sem gastos ainda"
            }
        }

        var detail: String {
            switch self {
            case .over: "O gasto já é maior que o planejado."
            case .attention: "Já usaram 80% ou mais do planejado."
            case .onTrack: "O gasto está dentro do planejado."
            case .untouched: "Nenhum gasto registrado neste período."
            }
        }
    }

    public let budget: Budget
    public let planned: Double
    public let spent: Double

    public init(budget: Budget, planned: Double, spent: Double) {
        self.budget = budget
        self.planned = planned
        self.spent = spent
    }

    public var id: String { budget.id }
    public var remaining: Double { planned - spent }
    public var ratio: Double { planned > 0 ? spent / planned : (spent > 0 ? 1.01 : 0) }

    public var group: Group {
        if spent <= 0 { return .untouched }
        if ratio > 1 { return .over }
        if ratio >= 0.8 { return .attention }
        return .onTrack
    }
}

public struct BudgetOverview: Sendable {
    public let items: [BudgetProgress]
    public let totalSpent: Double
    public let month: YearMonth?
    public let today: Date

    public init(items: [BudgetProgress], totalSpent: Double, month: YearMonth?, today: Date = .now)
    {
        self.items = items
        self.totalSpent = totalSpent
        self.month = month
        self.today = today
    }

    public var planned: Double { items.reduce(0) { $0 + $1.planned } }
    public var spent: Double { items.reduce(0) { $0 + $1.spent } }
    public var remaining: Double { planned - spent }
    public var ratio: Double { planned > 0 ? spent / planned : 0 }
    public var unbudgeted: Double { max(totalSpent - spent, 0) }

    public var counts: [(group: BudgetProgress.Group, count: Int)] {
        groups.map { ($0.group, $0.items.count) }
    }

    public var groups: [(group: BudgetProgress.Group, items: [BudgetProgress])] {
        BudgetProgress.Group.allCases.compactMap { group in
            let items = items.filter { $0.group == group }.sorted { $0.ratio > $1.ratio }
            return items.isEmpty ? nil : (group, items)
        }
    }

    public var daysLeft: Int? {
        guard let month, month == YearMonth(today) else { return nil }
        let day = CashlyCalendar.current.component(.day, from: today)
        return month.dayCount - day + 1
    }

    public var dailyAllowance: Double? {
        guard let daysLeft, daysLeft > 0, remaining > 0 else { return nil }
        return remaining / Double(daysLeft)
    }
}
