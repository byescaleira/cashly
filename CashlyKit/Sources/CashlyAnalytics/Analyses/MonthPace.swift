import CashlyDomain
import Foundation

public struct MonthPace: Analysis {
    public static let id: AnalysisID = "month-pace"
    public static let title = "Previsão do mês"
    public static let detail =
        "Em quanto o mês deve fechar: o que já saiu, as contas já agendadas e o que você costuma gastar até o fim do mês."
    public static let version = 2

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let day = CashlyCalendar.current.component(.day, from: ledger.today)
        let expenses = ledger.postings(in: month).filter(\.isExpense)
        let spent = expenses.filter { $0.date <= ledger.today }.reduce(0) { $0 + $1.minorUnits }
        let scheduled = expenses.filter { $0.date > ledger.today }.reduce(0) { $0 + $1.minorUnits }
        guard spent > 0 || scheduled > 0 else { return nil }
        let history = (1...6).map { month.adding(months: -$0) }.filter(ledger.hasActivity(in:))
        let typicalRest: Int64
        let method: String
        if history.isEmpty {
            typicalRest = Int64(
                (Double(spent) / Double(day) * Double(month.dayCount - day)).rounded())
            method = "Gasto até hoje dividido pelos dias passados, vezes os dias que faltam"
        } else {
            let rests = history.map {
                Double(
                    ledger.spent(in: $0, throughDay: $0.dayCount)
                        - ledger.spent(in: $0, throughDay: day))
            }
            typicalRest = Int64((Statistics.median(rests) ?? 0).rounded())
            method = "Gasto até hoje + mediana do que saiu depois deste dia nos últimos meses"
        }
        let remaining = max(scheduled, typicalRest)
        let projected = spent + remaining
        let budgeted = ledger.budgeted(in: month)
        var metrics: [Metric] = [
            .money("spent", "Já gasto", minorUnits: spent),
            .money("remaining", "Ainda deve sair", minorUnits: remaining),
            .money("scheduled", "Contas agendadas", minorUnits: scheduled),
            .money("projected", "Previsão do mês", minorUnits: projected),
            Metric(key: "elapsedDays", label: "Dias passados", value: Double(day), unit: .days),
        ]
        var summary = "O mês deve fechar em \(Formatting.money(projected))."
        if budgeted > 0 {
            metrics.append(.money("budgeted", "Planejado", minorUnits: budgeted))
            let difference = projected - budgeted
            summary +=
                difference > 0
                ? " Isso passa \(Formatting.money(difference)) do planejado."
                : " Ainda sobram \(Formatting.money(-difference)) do planejado."
        }
        let confidence: Provenance.Confidence =
            history.count >= 3 ? .high : history.isEmpty ? (day < 10 ? .low : .medium) : .medium
        return result(
            ledger, summary: summary, metrics: metrics, method: method, confidence: confidence)
    }
}
