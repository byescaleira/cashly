import CashlyDomain
import Foundation

public struct DailyAllowance: Analysis {
    public static let id: AnalysisID = "daily-allowance"
    public static let title = "Quanto posso gastar por dia"
    public static let detail =
        "O que sobra do planejado, menos as contas que ainda vão cair, dividido pelos dias restantes."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let budgeted = ledger.budgeted(in: month)
        guard budgeted > 0 else { return nil }
        let expenses = ledger.postings(in: month).filter(\.isExpense)
        let spent = expenses.filter { $0.date <= ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let upcoming = expenses.filter { $0.date > ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let daysLeft = month.dayCount - day + 1
        let free = budgeted - spent - upcoming
        let daily = free > 0 ? free / Int64(daysLeft) : 0
        let summary =
            free > 0
            ? "Dá para gastar \(Formatting.money(daily)) por dia nos próximos \(daysLeft) dias."
            : "O planejado do mês já foi usado, contando as contas que ainda vão cair."
        return result(
            ledger, summary: summary,
            metrics: [
                .money("daily", "Por dia", minorUnits: daily),
                .money("free", "Livre no mês", minorUnits: free),
                .money("upcoming", "Contas por vir", minorUnits: upcoming),
                Metric(
                    key: "daysLeft", label: "Dias restantes", value: Double(daysLeft), unit: .days),
            ],
            method: "(Planejado − gasto − contas futuras do mês) ÷ dias restantes",
            confidence: .certain)
    }
}
