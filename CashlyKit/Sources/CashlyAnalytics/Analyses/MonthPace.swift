import CashlyDomain
import Foundation

public struct MonthPace: Analysis {
    public static let id: AnalysisID = "month-pace"
    public static let title = "Ritmo do mês"
    public static let detail = "Em quanto o mês fecha se os gastos continuarem no ritmo de agora."
    public static let version = 1

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let spent = ledger.postings(in: month)
            .filter { $0.isExpense && $0.date <= ledger.today }
            .reduce(0) { $0 + $1.minorUnits }
        guard spent > 0 else { return nil }
        let projected = Int64((Double(spent) / Double(day) * Double(month.dayCount)).rounded())
        let budgeted = ledger.budgeted(in: month)
        var metrics: [Metric] = [
            .money("spent", "Gasto até hoje", minorUnits: spent),
            .money("projected", "Fechamento projetado", minorUnits: projected),
            Metric(key: "elapsedDays", label: "Dias passados", value: Double(day), unit: .days),
        ]
        var summary = "No ritmo atual, o mês fecha em \(Formatting.money(projected))."
        if budgeted > 0 {
            metrics.append(.money("budgeted", "Planejado", minorUnits: budgeted))
            let difference = projected - budgeted
            summary +=
                difference > 0
                ? " Isso passa \(Formatting.money(difference)) do planejado."
                : " Ainda sobram \(Formatting.money(-difference)) do planejado."
        }
        return result(
            ledger, summary: summary, metrics: metrics,
            method: "Gasto até hoje dividido pelos dias passados, vezes os dias do mês",
            confidence: day < 7 ? .low : day < 15 ? .medium : .high)
    }
}
